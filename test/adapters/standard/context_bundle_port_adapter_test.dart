/// Unit tests for [ContextBundlePortAdapter] — MOD-INFRA-019.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_bundle/src/ports/context_bundle_port.dart' as ctx;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('ContextBundlePortAdapter', () {
    late InMemoryStorageContainer storage;
    late ContextService contextService;
    late ContextBundlePortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      contextService = ContextService(
        storage: storage.context,
        factStorage: storage.facts,
      );
      adapter = ContextBundlePortAdapter(
        contextService: contextService,
        defaultWorkspaceId: 'ws1',
      );
    });

    test('buildContextBundle returns an empty bundle on fresh runtime', () async {
      final result = await adapter.buildContextBundle(
        const ctx.ContextBundleRequest(
          query: 'hello',
          workspaceId: 'ws1',
        ),
      );
      expect(result.events, isEmpty);
      expect(result.views, isEmpty);
    });

    test('buildContextBundle returns events when facts exist', () async {
      await storage.facts.saveFact(
        Fact(
          factId: 'fact-a',
          workspaceId: 'ws1',
          factType: 'expense',
          summary: 'lunch',
          occurredAt: DateTime(2026, 4, 11),
          candidateId: '',
          createdAt: DateTime(2026, 4, 11),
          payload: const {'amount': 5000},
        ),
      );
      final result = await adapter.buildContextBundle(
        const ctx.ContextBundleRequest(
          query: 'anything',
          workspaceId: 'ws1',
        ),
      );
      expect(result.events, hasLength(1));
      expect(result.events.first.id, 'fact-a');
    });

    test('buildContextBundle handles empty query without throwing', () async {
      final result = await adapter.buildContextBundle(
        const ctx.ContextBundleRequest(
          query: '',
          workspaceId: 'ws1',
        ),
      );
      expect(result, isA<bundle.ContextBundle>());
    });
  });
}
