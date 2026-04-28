/// Unit tests for [RetrievalPortAdapter] — MOD-INFRA-020.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('RetrievalPortAdapter', () {
    late InMemoryStorageContainer storage;
    late FactGraphService service;
    late RetrievalPortAdapter adapter;

    setUp(() async {
      storage = InMemoryStorageContainer();
      service = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
      adapter = RetrievalPortAdapter(
        factGraphService: service,
        defaultWorkspaceId: 'ws1',
        minScore: 0.1,
      );

      await storage.facts.saveFact(
        Fact(
          factId: 'fact-cafe',
          workspaceId: 'ws1',
          factType: 'expense',
          summary: 'Lunch at cafe with Alice',
          occurredAt: DateTime(2026, 4, 11),
          candidateId: '',
          createdAt: DateTime(2026, 4, 11),
          payload: const {'vendor': 'Cafe X'},
        ),
      );
    });

    test('listRetrievers returns the built-in default', () async {
      final retrievers = await adapter.listRetrievers();
      expect(retrievers, hasLength(1));
      expect(retrievers.first.id, 'factgraph.default');
    });

    test('queryKnowledge returns matching passages for a hit', () async {
      final result = await adapter.queryKnowledge(
        'cafe',
        filters: const {'workspaceId': 'ws1'},
      );
      expect(result.passages, isNotEmpty);
      expect(result.passages.first.id, 'fact-cafe');
    });

    test('queryKnowledge returns empty on total miss', () async {
      final result = await adapter.queryKnowledge(
        'unrelatedzzz',
        filters: const {'workspaceId': 'ws1'},
      );
      expect(result.passages, isEmpty);
    });

    test('queryKnowledge respects maxResults', () async {
      for (var i = 0; i < 5; i++) {
        await storage.facts.saveFact(
          Fact(
            factId: 'fact-$i',
            workspaceId: 'ws1',
            factType: 'expense',
            summary: 'cafe coffee event',
            occurredAt: DateTime(2026, 4, 11),
            candidateId: '',
            createdAt: DateTime(2026, 4, 11),
          ),
        );
      }
      final result = await adapter.queryKnowledge(
        'cafe',
        filters: const {'workspaceId': 'ws1'},
        maxResults: 2,
      );
      expect(result.passages.length, lessThanOrEqualTo(2));
    });
  });
}
