/// Unit tests for [CandidatesPortAdapter] — MOD-INFRA-015.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('CandidatesPortAdapter', () {
    late InMemoryStorageContainer storage;
    late FactGraphService service;
    late CandidatesPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      service = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
      adapter = CandidatesPortAdapter(
        factGraphService: service,
        candidateStoragePort: storage.candidates,
        defaultWorkspaceId: 'ws1',
      );
    });

    bundle.CandidateRecord sampleRecord(String id) {
      return bundle.CandidateRecord(
        id: id,
        workspaceId: 'ws1',
        type: 'expense',
        content: const {'amount': 5000},
        createdAt: DateTime(2026, 4, 11),
      );
    }

    test('createCandidates returns the created ids in order', () async {
      final created = await adapter.createCandidates([
        sampleRecord('cand-1'),
        sampleRecord('cand-2'),
      ]);
      expect(created, ['cand-1', 'cand-2']);
    });

    test('getPendingCandidates returns freshly created candidates', () async {
      await adapter.createCandidates([sampleRecord('cand-3')]);
      final pending = await adapter.getPendingCandidates('ws1');
      expect(pending.any((c) => c.id == 'cand-3'), isTrue);
    });

    test('rejectCandidate throws on missing id', () async {
      expect(
        () => adapter.rejectCandidate('missing', 'bad'),
        throwsStateError,
      );
    });

    test('rejectCandidate updates status and appends audit entry', () async {
      await adapter.createCandidates([sampleRecord('cand-rej')]);
      await adapter.rejectCandidate('cand-rej', 'duplicate', reviewerId: 'me');
      final stored = await storage.candidates.getCandidate('cand-rej');
      expect(stored, isNotNull);
      expect(stored!.auditTrail.last.action, 'rejected');
      expect(stored.auditTrail.last.reason, 'duplicate');
    });

    test('createCandidates with dedup reuses existing id on content match',
        () async {
      final dedupAdapter = CandidatesPortAdapter(
        factGraphService: service,
        candidateStoragePort: storage.candidates,
        defaultWorkspaceId: 'ws1',
        deduplicator: CandidateDeduplicator(storage: storage.candidates),
      );
      final first = await dedupAdapter.createCandidates([
        bundle.CandidateRecord(
          id: 'cand-orig',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {'amount': 12500},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      expect(first, ['cand-orig']);

      final second = await dedupAdapter.createCandidates([
        bundle.CandidateRecord(
          id: 'cand-duplicate',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {'amount': 12500},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      // The adapter returns the pre-existing id, not the new one.
      expect(second, ['cand-orig']);
      // Only one candidate actually persisted.
      expect(
        await storage.candidates.getCandidate('cand-duplicate'),
        isNull,
      );
    });
  });
}
