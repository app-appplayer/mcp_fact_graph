/// Unit tests for [ConsistencyChecker] — C4.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

Fact makeFact({
  required String id,
  String entity = 'ent-1',
  String type = 'expense',
  Map<String, dynamic> payload = const {'amount': 1000},
  DateTime? occurredAt,
}) {
  final t = occurredAt ?? DateTime(2026, 4, 14);
  return Fact(
    factId: id,
    workspaceId: 'ws1',
    factType: type,
    summary: '$type: $id',
    payload: payload,
    occurredAt: t,
    candidateId: 'cand-$id',
    entityRefs: [entity],
    createdAt: t,
  );
}

void main() {
  group('ConsistencyChecker', () {
    late InMemoryStorageContainer storage;
    late ConsistencyChecker checker;

    setUp(() {
      storage = InMemoryStorageContainer();
      checker = ConsistencyChecker(storage: storage.facts);
    });

    test('clears when no prior fact exists', () async {
      final report = await checker.check(makeFact(id: 'f-1'));
      expect(report, isNull);
    });

    test('duplicate factId yields duplicateId conflict', () async {
      await storage.facts.saveFact(makeFact(id: 'f-1'));
      final report = await checker.check(makeFact(id: 'f-1'));
      expect(report, isNotNull);
      expect(report!.kind, ConflictKind.duplicateId);
    });

    test('triple with matching payload does not conflict', () async {
      await storage.facts.saveFact(
        makeFact(id: 'f-1', payload: {'amount': 1000}),
      );
      final report = await checker.check(
        makeFact(id: 'f-2', payload: {'amount': 1000}),
      );
      expect(report, isNull);
    });

    test('overlapping triple with different payload conflicts', () async {
      await storage.facts.saveFact(
        makeFact(id: 'f-1', payload: {'amount': 1000}),
      );
      final report = await checker.check(
        makeFact(id: 'f-2', payload: {'amount': 2000}),
      );
      expect(report, isNotNull);
      expect(report!.kind, ConflictKind.tripleMismatch);
    });

    test('non-overlapping periods do not conflict', () async {
      await storage.facts.saveFact(
        makeFact(
          id: 'f-1',
          payload: {'amount': 1000},
          occurredAt: DateTime(2026, 4, 14),
        ),
      );
      final report = await checker.check(
        makeFact(
          id: 'f-2',
          payload: {'amount': 2000},
          occurredAt: DateTime(2026, 4, 15),
        ),
      );
      expect(report, isNull);
    });

    test('disabled checker never reports', () async {
      final off = ConsistencyChecker(storage: storage.facts, enabled: false);
      await storage.facts.saveFact(makeFact(id: 'f-1'));
      expect(await off.check(makeFact(id: 'f-1')), isNull);
    });
  });
}
