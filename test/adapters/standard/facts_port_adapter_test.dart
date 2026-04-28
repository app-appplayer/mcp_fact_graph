/// Unit tests for [FactsPortAdapter] — MOD-INFRA-011.
///
/// Mirrors `docs/04_TEST/adapters/standard/01-facts-port-adapter.md`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('FactsPortAdapter', () {
    late InMemoryStorageContainer storage;
    late FactGraphService service;
    late FactsPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      service = FactGraphService(
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

    test('queryFacts returns empty on fresh storage', () async {
      final result = await adapter.queryFacts(
        const bundle.FactQuery(workspaceId: 'ws1'),
      );
      expect(result, isEmpty);
    });

    test('writeFacts → queryFacts round-trips id, type, content', () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'fact-1',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {'amount': 12500, 'vendor': 'Cafe X'},
          createdAt: DateTime(2026, 4, 11, 12),
        ),
      ]);

      final result = await adapter.queryFacts(
        const bundle.FactQuery(workspaceId: 'ws1'),
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'fact-1');
      expect(result.first.type, 'expense');
      expect(result.first.content['amount'], 12500);
    });

    test('getFact returns null when missing', () async {
      expect(await adapter.getFact('unknown'), isNull);
    });

    test('getFact returns a round-tripped record', () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'fact-2',
          workspaceId: 'ws1',
          type: 'schedule',
          content: const {'topic': 'standup'},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final fetched = await adapter.getFact('fact-2');
      expect(fetched, isNotNull);
      expect(fetched!.type, 'schedule');
      expect(fetched.content['topic'], 'standup');
    });

    test('deleteFacts removes the fact', () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'fact-3',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      await adapter.deleteFacts(['fact-3']);
      expect(await adapter.getFact('fact-3'), isNull);
    });

    test('queryFacts multi-type concatenates results', () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'f-1',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {},
          createdAt: DateTime(2026, 4, 11),
        ),
        bundle.FactRecord(
          id: 'f-2',
          workspaceId: 'ws1',
          type: 'schedule',
          content: const {},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final result = await adapter.queryFacts(
        const bundle.FactQuery(
          workspaceId: 'ws1',
          types: ['expense', 'schedule'],
        ),
      );
      final ids = result.map((r) => r.id).toSet();
      expect(ids, containsAll({'f-1', 'f-2'}));
    });

    test('writeFacts respects limit on queryFacts', () async {
      await adapter.writeFacts([
        for (var i = 0; i < 5; i++)
          bundle.FactRecord(
            id: 'f-$i',
            workspaceId: 'ws1',
            type: 'expense',
            content: const {},
            createdAt: DateTime(2026, 4, 11),
          ),
      ]);
      final result = await adapter.queryFacts(
        const bundle.FactQuery(workspaceId: 'ws1', limit: 2),
      );
      expect(result, hasLength(lessThanOrEqualTo(2)));
    });

    test('writeFacts propagates candidateId provenance via content hint',
        () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'fact-prov',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {
            'amount': 5000,
            'sourceCandidateId': 'cand-777',
          },
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final stored = await storage.facts.getFact('fact-prov');
      expect(stored, isNotNull);
      expect(stored!.candidateId, 'cand-777');
    });

    test('writeFacts propagates candidateId via sourceCandidateIds list',
        () async {
      await adapter.writeFacts([
        bundle.FactRecord(
          id: 'fact-prov-list',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {
            'amount': 5000,
            'sourceCandidateIds': ['cand-A', 'cand-B'],
          },
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final stored = await storage.facts.getFact('fact-prov-list');
      expect(stored, isNotNull);
      expect(stored!.candidateId, 'cand-A');
    });

    test('writeFacts with ConsistencyChecker rejects duplicate id',
        () async {
      final guarded = FactsPortAdapter(
        factGraphService: service,
        factStoragePort: storage.facts,
        defaultWorkspaceId: 'ws1',
        consistencyChecker: ConsistencyChecker(storage: storage.facts),
      );
      final record = bundle.FactRecord(
        id: 'fact-dup',
        workspaceId: 'ws1',
        type: 'expense',
        content: const {'amount': 1000},
        createdAt: DateTime(2026, 4, 11),
      );
      await guarded.writeFacts([record]);
      expect(
        () => guarded.writeFacts([record]),
        throwsA(isA<FactConflictException>()),
      );
    });
  });
}
