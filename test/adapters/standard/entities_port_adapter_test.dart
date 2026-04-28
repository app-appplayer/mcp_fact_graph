/// Unit tests for [EntitiesPortAdapter] — MOD-INFRA-013.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('EntitiesPortAdapter', () {
    late InMemoryStorageContainer storage;
    late FactGraphService service;
    late EntitiesPortAdapter adapter;

    setUp(() async {
      storage = InMemoryStorageContainer();
      service = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
      adapter = EntitiesPortAdapter(
        factGraphService: service,
        entityStoragePort: storage.entities,
        defaultWorkspaceId: 'ws1',
      );

      final now = DateTime(2026, 4, 11);
      await storage.entities.saveEntity(
        Entity(
          entityId: 'ent-1',
          workspaceId: 'ws1',
          type: 'person',
          canonicalName: 'Alice',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await storage.entities.saveEntity(
        Entity(
          entityId: 'ent-2',
          workspaceId: 'ws1',
          type: 'person',
          canonicalName: 'Bob',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test('getEntity returns null for unknown id', () async {
      expect(await adapter.getEntity('missing'), isNull);
    });

    test('getEntity converts internal Entity → bundle.EntityRecord', () async {
      final record = await adapter.getEntity('ent-1');
      expect(record, isNotNull);
      expect(record!.id, 'ent-1');
      expect(record.name, 'Alice');
      expect(record.type, 'person');
    });

    test('queryEntities returns all persons', () async {
      final result = await adapter.queryEntities(
        const bundle.EntityQuery(workspaceId: 'ws1', types: ['person']),
      );
      expect(result.map((r) => r.id), containsAll({'ent-1', 'ent-2'}));
    });

    test('mergeEntities short-circuits on surviving==absorbed', () async {
      final record = await adapter.mergeEntities('ent-1', 'ent-1');
      expect(record.id, 'ent-1');
    });

    test('linkEntity is a no-op when relationStoragePort absent', () async {
      await adapter.linkEntity('ent-1', 'ent-2', 'knows');
      // Should not throw.
    });
  });
}
