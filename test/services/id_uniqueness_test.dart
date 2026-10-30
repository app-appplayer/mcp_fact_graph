/// Ids made in quick succession must differ: a repeated id makes a store
/// replace the earlier record without an error.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:mcp_fact_graph/src/services/id_generator.dart';
import 'package:mcp_fact_graph/src/services/ingestion_source.dart';
import 'package:test/test.dart';

void main() {
  test('generateId gives distinct ids in a tight loop', () {
    final ids = {for (var i = 0; i < 5000; i++) generateId('x')};
    expect(ids, hasLength(5000));
  });

  test('generateId keeps the prefix_digits_digits shape', () {
    expect(generateId('cand'), matches(RegExp(r'^cand_\d+_\d+$')));
  });

  group('services', () {
    late InMemoryStorageContainer storage;
    late FactGraphService graph;
    late EvidenceService evidence;
    final now = DateTime.utc(2026, 1, 1);

    setUp(() {
      storage = InMemoryStorageContainer();
      graph = FactGraphService(
        candidateStorage: storage.candidates,
        entityStorage: storage.entities,
        factStorage: storage.facts,
        viewStorage: storage.views,
      );
      evidence = EvidenceService(storage: storage.evidence);
    });

    Fragment fragment(int i) => Fragment(
          fragmentId: 'f$i',
          workspaceId: 'ws',
          evidenceId: 'ev',
          fields: {'name': 'n$i'},
          confidence: 0.9,
          createdAt: now,
        );

    test('candidates made back to back are all stored', () async {
      final made = [
        for (var i = 0; i < 50; i++)
          await graph.createCandidate(
              workspaceId: 'ws', objectType: 'note', fragments: [fragment(i)]),
      ];
      expect(made.map((c) => c.candidateId).toSet(), hasLength(50));
      final stored = await storage.candidates
          .queryCandidates(const CandidateQuery(workspaceId: 'ws'));
      expect(stored, hasLength(50));
    });

    test('facts confirmed back to back are all stored', () async {
      final ids = <String>[];
      for (var i = 0; i < 50; i++) {
        final c = await graph.createCandidate(
            workspaceId: 'ws', objectType: 'note', fragments: [fragment(i)]);
        ids.add((await graph.confirmCandidate(c.candidateId)).factId!);
      }
      expect(ids.toSet(), hasLength(50));
      final stored =
          await storage.facts.queryFacts(const FactQuery(workspaceId: 'ws'));
      expect(stored, hasLength(50));
    });

    test('evidence ingested back to back is all stored', () async {
      final made = [
        for (var i = 0; i < 50; i++)
          await evidence.ingestEvidence(IngestionInput(
            workspaceId: 'ws',
            content: 'c$i',
            sourceId: 's',
            sourceType: EvidenceSourceType.text,
          )),
      ];
      expect(made.map((e) => e.evidenceId).toSet(), hasLength(50));
    });
  });
}
