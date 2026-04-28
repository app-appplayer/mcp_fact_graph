/// Unit tests for [PatternsPortAdapter] — MOD-INFRA-016.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/src/adapters/standard/patterns_port_adapter.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('PatternsPortAdapter', () {
    late InMemoryStorageContainer storage;
    late PatternsPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      adapter = PatternsPortAdapter(
        skillOpsStoragePort: storage.skillOps,
        defaultWorkspaceId: 'ws1',
      );
    });

    bundle.PatternRecord sampleRecord(String id) {
      return bundle.PatternRecord(
        id: id,
        workspaceId: 'ws1',
        type: 'expense-pattern',
        description: 'User buys coffee every morning',
        confidence: 0.8,
        frequency: 30,
        entityIds: const ['ent-alice'],
        features: const {'category': 'food'},
        detectedAt: DateTime(2026, 4, 11),
      );
    }

    test('storePattern → getPattern round-trip', () async {
      final id = await adapter.storePattern(sampleRecord('pat-1'));
      expect(id, 'pat-1');

      final fetched = await adapter.getPattern('pat-1');
      expect(fetched, isNotNull);
      expect(fetched!.type, 'expense-pattern');
      expect(fetched.frequency, 30);
      expect(fetched.entityIds, ['ent-alice']);
      expect(fetched.features['category'], 'food');
    });

    test('getPattern returns null on missing', () async {
      expect(await adapter.getPattern('missing'), isNull);
    });

    test('queryPatterns respects min-frequency filter', () async {
      await adapter.storePattern(sampleRecord('p-a'));
      await adapter.storePattern(
        bundle.PatternRecord(
          id: 'p-b',
          workspaceId: 'ws1',
          type: 'rare',
          description: 'rare',
          confidence: 0.1,
          frequency: 1,
          detectedAt: DateTime(2026, 4, 11),
        ),
      );

      final result = await adapter.queryPatterns(
        const bundle.PatternQuery(workspaceId: 'ws1', minFrequency: 10),
      );
      expect(result.map((r) => r.id), contains('p-a'));
      expect(result.map((r) => r.id), isNot(contains('p-b')));
    });
  });
}
