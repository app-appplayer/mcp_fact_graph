/// Attribution (`actor`), retraction and point-in-time queries (`asOf`).
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal storage port — not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:test/test.dart';

final t0 = DateTime.utc(2026, 1, 1);
DateTime day(int n) => t0.add(Duration(days: n));

Fact fact(
  String id, {
  DateTime? createdAt,
  FactStatus status = FactStatus.confirmed,
  String? supersedes,
  DateTime? retractedAt,
  Map<String, dynamic> payload = const {},
  List<String> entityRefs = const ['e1'],
}) =>
    Fact(
      factId: id,
      workspaceId: 'ws1',
      factType: 'decision',
      summary: id,
      payload: payload,
      occurredAt: t0,
      status: status,
      candidateId: 'c-$id',
      entityRefs: entityRefs,
      createdAt: createdAt ?? t0,
      supersedes: supersedes,
      retractedAt: retractedAt,
    );

void main() {
  group('Fact attribution fields', () {
    test('actor, retractedAt and retractedBy round-trip through JSON', () {
      final f = fact('a').copyWith(
        actor: 'user:jsha',
        retractedAt: day(3),
        retractedBy: 'user:jsha',
      );
      final back = Fact.fromJson(f.toJson());
      expect(back.actor, 'user:jsha');
      expect(back.status, FactStatus.confirmed);
      expect(back.isRetracted, isTrue);
      expect(back.retractedAt, day(3));
      expect(back.retractedBy, 'user:jsha');
    });

    test('unused fields are omitted from JSON and read back as null', () {
      final json = fact('a').toJson();
      expect(json.containsKey('actor'), isFalse);
      expect(json.containsKey('retractedAt'), isFalse);
      expect(json.containsKey('retractedBy'), isFalse);
      final back = Fact.fromJson(json);
      expect(back.actor, isNull);
      expect(back.retractedAt, isNull);
    });

    test('an older JSON without the new fields still loads', () {
      final back = Fact.fromJson({
        'factId': 'old',
        'status': 'archived',
        'candidateId': 'c',
      });
      expect(back.status, FactStatus.archived);
      expect(back.actor, isNull);
    });

    test('a fact is retracted exactly when retractedAt is set', () {
      expect(fact('a').isRetracted, isFalse);
      expect(fact('a', retractedAt: day(1)).isRetracted, isTrue);
    });

    test('the status set has no retracted member', () {
      expect(FactStatus.values.map((s) => s.name),
          ['confirmed', 'reclassified', 'archived']);
    });
  });

  group('InMemoryFactStorage.queryFacts', () {
    late InMemoryFactStorage store;
    setUp(() => store = InMemoryFactStorage());

    Future<List<String>> ids(FactQuery q) async =>
        (await store.queryFacts(q)).map((f) => f.factId).toList()..sort();

    test('without asOf, retracted facts are left out', () async {
      await store.saveFact(fact('live'));
      await store.saveFact(fact('gone',
          retractedAt: day(2)));
      expect(await ids(const FactQuery()), ['live']);
    });

    test('includeRetracted asks for them explicitly', () async {
      await store.saveFact(fact('live'));
      await store.saveFact(fact('gone', retractedAt: day(2)));
      expect(await ids(const FactQuery(includeRetracted: true)),
          ['gone', 'live']);
    });

    test('a retracted fact keeps its stored status', () async {
      await store.saveFact(fact('gone', retractedAt: day(2)));
      final all = await store.queryFacts(
          const FactQuery(includeRetracted: true));
      expect(all.single.status, FactStatus.confirmed);
    });

    test('asOf: a fact created after the instant is not visible', () async {
      await store.saveFact(fact('early', createdAt: day(1)));
      await store.saveFact(fact('late', createdAt: day(5)));
      expect(await ids(FactQuery(asOf: day(3))), ['early']);
      expect(await ids(FactQuery(asOf: day(5))), ['early', 'late']);
    });

    test('asOf: a retracted fact is visible before retractedAt only',
        () async {
      await store.saveFact(fact('r',
          createdAt: day(1),
          retractedAt: day(4)));
      expect(await ids(FactQuery(asOf: day(3))), ['r']);
      expect(await ids(FactQuery(asOf: day(4))), isEmpty);
      expect(await ids(FactQuery(asOf: day(9))), isEmpty);
    });

    test('asOf: a superseded fact is replaced from the superseder onward',
        () async {
      await store.saveFact(fact('v1', createdAt: day(1)));
      await store.saveFact(fact('v2', createdAt: day(5), supersedes: 'v1'));
      expect(await ids(FactQuery(asOf: day(3))), ['v1']);
      expect(await ids(FactQuery(asOf: day(5))), ['v2']);
      expect(await ids(FactQuery(asOf: day(9))), ['v2']);
    });

    test('asOf does not hide a fact because it is archived now', () async {
      await store.saveFact(
          fact('old', createdAt: day(1), status: FactStatus.archived));
      expect(await ids(FactQuery(asOf: day(3))), ['old']);
    });

    test('asOf combines with the other filters', () async {
      await store.saveFact(fact('a', createdAt: day(1)));
      await store.saveFact(fact('b', createdAt: day(1), entityRefs: ['e2']));
      expect(
          await ids(FactQuery(asOf: day(3), entityIds: const ['e2'])), ['b']);
    });
  });

  group('FactGraphService', () {
    late InMemoryStorageContainer storage;
    late FactGraphService service;

    setUp(() {
      storage = InMemoryStorageContainer();
      service = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
    });

    test('retractFact keeps provenance and records who and when', () async {
      await storage.facts.saveFact(fact('f1'));
      final r = await service.retractFact('f1',
          retractedBy: 'user:jsha', at: day(2));
      expect(r.isRetracted, isTrue);
      expect(r.status, FactStatus.confirmed);
      expect(r.retractedAt, day(2));
      expect(r.retractedBy, 'user:jsha');
      expect(r.candidateId, 'c-f1');
      expect((await storage.facts.getFact('f1'))!.isRetracted, isTrue);
    });

    test('retractFact on a retracted fact returns it unchanged', () async {
      await storage.facts.saveFact(fact('f1'));
      final first = await service.retractFact('f1', at: day(2));
      final again = await service.retractFact('f1', at: day(9));
      expect(again.retractedAt, first.retractedAt);
    });

    test('retractFact on an unknown id throws', () async {
      expect(() => service.retractFact('nope'), throwsArgumentError);
    });

    test('the retracted fact stays visible to an earlier asOf', () async {
      await storage.facts.saveFact(fact('f1', createdAt: day(1)));
      await service.retractFact('f1', at: day(4));
      final before = await service.queryFacts(FactQuery(asOf: day(3)));
      final after = await service.queryFacts(FactQuery(asOf: day(5)));
      expect(before.map((f) => f.factId), ['f1']);
      expect(after, isEmpty);
    });
  });

  group('ConsistencyChecker', () {
    test('a retracted sibling does not conflict', () async {
      final store = InMemoryFactStorage();
      await store.saveFact(fact('old',
          payload: {'v': 1},
          retractedAt: day(1)));
      final checker = ConsistencyChecker(storage: store);
      expect(await checker.check(fact('new', payload: {'v': 2})), isNull);
    });

    test('a live sibling with a different value still conflicts', () async {
      final store = InMemoryFactStorage();
      await store.saveFact(fact('old', payload: {'v': 1}));
      final checker = ConsistencyChecker(storage: store);
      expect(await checker.check(fact('new', payload: {'v': 2})), isNotNull);
    });
  });

  group('FactsPortAdapter honours asOf', () {
    late InMemoryStorageContainer storage;
    late FactsPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      final service = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
      adapter = FactsPortAdapter(
        factGraphService: service,
        factStoragePort: storage.facts,
        defaultWorkspaceId: 'ws1',
      );
    });

    test('a query with asOf sees the earlier state', () async {
      await storage.facts.saveFact(fact('f1', createdAt: day(1)));
      await storage.facts.saveFact(fact('f2', createdAt: day(5)));
      final early = await adapter
          .queryFacts(bundle.FactQuery(workspaceId: 'ws1', asOf: day(3)));
      final late = await adapter
          .queryFacts(bundle.FactQuery(workspaceId: 'ws1', asOf: day(9)));
      expect(early.map((r) => r.id), ['f1']);
      expect(late.map((r) => r.id).toSet(), {'f1', 'f2'});
    });

    test('a query without asOf leaves out retracted facts', () async {
      await storage.facts.saveFact(fact('live'));
      await storage.facts.saveFact(
          fact('gone', retractedAt: day(2)));
      final now =
          await adapter.queryFacts(const bundle.FactQuery(workspaceId: 'ws1'));
      expect(now.map((r) => r.id), ['live']);
    });
  });
}
