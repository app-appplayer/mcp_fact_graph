/// Unit tests for [SummariesPortAdapter] — MOD-INFRA-017.
library;

import 'package:mcp_fact_graph/src/adapters/standard/summaries_port_adapter.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('SummariesPortAdapter', () {
    late InMemoryStorageContainer storage;
    late SummariesPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      adapter = SummariesPortAdapter(
        contextStoragePort: storage.context,
        defaultWorkspaceId: 'ws1',
      );
    });

    test('getSummary returns null on fresh runtime', () async {
      expect(
        await adapter.getSummary('ent-1', 'rollup'),
        isNull,
      );
    });

    test('refreshSummary creates + persists a SummaryNode', () async {
      final record = await adapter.refreshSummary('ent-1', 'rollup');
      expect(record.entityId, 'ent-1');
      expect(record.type, 'rollup');
      expect(record.isStale, isFalse);
    });

    test('refreshSummary round-trips via getSummary', () async {
      await adapter.refreshSummary('ent-42', 'daily');
      final fetched = await adapter.getSummary('ent-42', 'daily');
      expect(fetched, isNotNull);
      expect(fetched!.entityId, 'ent-42');
    });

    test('markSummariesStale flips the stale bit', () async {
      await adapter.refreshSummary('ent-2', 'rollup');
      await adapter.markSummariesStale(['ent-2']);
      final stale = await adapter.getStaleSummaries();
      expect(stale.any((s) => s.entityId == 'ent-2'), isTrue);
    });

    test('getStaleSummaries returns empty when none stale', () async {
      await adapter.refreshSummary('ent-99', 'rollup');
      final stale = await adapter.getStaleSummaries();
      expect(stale, isEmpty);
    });
  });
}
