/// Unit tests for [CandidateDeduplicator] — C5.
library;

import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

Candidate makeCandidate({
  required String id,
  String workspace = 'ws1',
  String type = 'expense',
  Map<String, dynamic> content = const {'amount': 1000, 'vendor': 'Cafe X'},
}) {
  final now = DateTime(2026, 4, 14);
  final fields = <String, CandidateField>{};
  content.forEach((k, v) {
    fields[k] = CandidateField(value: v, confidence: 1.0);
  });
  return Candidate(
    candidateId: id,
    workspaceId: workspace,
    objectType: type,
    fields: fields,
    confidence: 1.0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CandidateDeduplicator', () {
    late InMemoryStorageContainer storage;
    late CandidateDeduplicator dedup;

    setUp(() {
      storage = InMemoryStorageContainer();
      dedup = CandidateDeduplicator(storage: storage.candidates);
    });

    test('contentHash is stable across equivalent candidates', () {
      final h1 = dedup.contentHash(makeCandidate(id: 'a'));
      final h2 = dedup.contentHash(makeCandidate(id: 'b'));
      expect(h1, equals(h2));
    });

    test('contentHash differs when content differs', () {
      final h1 = dedup.contentHash(
        makeCandidate(id: 'a', content: {'amount': 1000}),
      );
      final h2 = dedup.contentHash(
        makeCandidate(id: 'a', content: {'amount': 2000}),
      );
      expect(h1, isNot(equals(h2)));
    });

    test('findDuplicate returns null when none exist', () async {
      expect(
        await dedup.findDuplicate(makeCandidate(id: 'solo')),
        isNull,
      );
    });

    test('findDuplicate locates a stamped candidate with same content',
        () async {
      final original = makeCandidate(id: 'orig');
      final hash = dedup.contentHash(original);
      await storage.candidates.saveCandidate(
        original.copyWith(metadata: {
          CandidateDeduplicator.hashMetadataKey: hash,
        }),
      );
      final hit = await dedup.findDuplicate(
        makeCandidate(id: 'new', content: const {
          'amount': 1000,
          'vendor': 'Cafe X',
        }),
      );
      expect(hit, 'orig');
    });

    test('disabled dedup never finds duplicates', () async {
      final off =
          CandidateDeduplicator(storage: storage.candidates, enabled: false);
      final original = makeCandidate(id: 'orig');
      final hash = dedup.contentHash(original);
      await storage.candidates.saveCandidate(
        original.copyWith(metadata: {
          CandidateDeduplicator.hashMetadataKey: hash,
        }),
      );
      expect(await off.findDuplicate(makeCandidate(id: 'new')), isNull);
    });

    test('different workspaces do not collide', () {
      final a = dedup.contentHash(makeCandidate(id: 'a', workspace: 'ws1'));
      final b = dedup.contentHash(makeCandidate(id: 'b', workspace: 'ws2'));
      expect(a, isNot(equals(b)));
    });
  });
}
