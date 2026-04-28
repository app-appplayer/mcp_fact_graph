// Tests for EvidenceService - L0 Layer operations.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal contracts — accessed via src path since they are not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
// Ingestion contracts relocated from `src/ports/evidence_port.dart`
// to `src/services/ingestion_source.dart` in Phase 2.1.
import 'package:mcp_fact_graph/src/services/ingestion_source.dart';

// Mock implementation of EvidenceStoragePort
class MockEvidenceStoragePort implements EvidenceStoragePort {
  final Map<String, Evidence> _evidence = {};
  final Map<String, List<Fragment>> _fragments = {};

  @override
  Future<void> saveEvidence(Evidence evidence) async {
    _evidence[evidence.evidenceId] = evidence;
  }

  @override
  Future<Evidence?> getEvidence(String evidenceId) async {
    return _evidence[evidenceId];
  }

  @override
  Future<List<Evidence>> queryEvidence(EvidenceQuery query) async {
    var results = _evidence.values.toList();
    if (query.workspaceId != null) {
      results =
          results.where((e) => e.workspaceId == query.workspaceId).toList();
    }
    if (query.sourceType != null) {
      results =
          results.where((e) => e.sourceType == query.sourceType).toList();
    }
    if (query.status != null) {
      results = results.where((e) => e.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<void> deleteEvidence(String evidenceId) async {
    _evidence.remove(evidenceId);
    _fragments.remove(evidenceId);
  }

  @override
  Future<void> saveFragments(List<Fragment> fragments) async {
    for (final fragment in fragments) {
      _fragments.putIfAbsent(fragment.evidenceId, () => []);
      // Replace existing fragment or add new
      final existing = _fragments[fragment.evidenceId]!;
      final index =
          existing.indexWhere((f) => f.fragmentId == fragment.fragmentId);
      if (index >= 0) {
        existing[index] = fragment;
      } else {
        existing.add(fragment);
      }
    }
  }

  @override
  Future<List<Fragment>> getFragments(String evidenceId) async {
    return _fragments[evidenceId] ?? [];
  }
}

// Mock implementation of FragmentExtractorPort
class MockFragmentExtractorPort implements FragmentExtractorPort {
  List<Fragment>? extractResult;
  bool extractCalled = false;

  @override
  Future<List<Fragment>> extract(
      Evidence evidence, ExtractionConfig config) async {
    extractCalled = true;
    return extractResult ??
        [
          Fragment(
            fragmentId: 'frag_1',
            workspaceId: evidence.workspaceId,
            evidenceId: evidence.evidenceId,
            fields: const {'name': 'Test', 'amount': 100},
            confidence: 0.9,
            createdAt: DateTime.now(),
          ),
        ];
  }

  @override
  List<ExtractorType> get supportedMethods => [ExtractorType.llm];
}

void main() {
  group('EvidenceService', () {
    late MockEvidenceStoragePort storage;
    late MockFragmentExtractorPort extractor;
    late EvidenceService serviceWithExtractor;
    late EvidenceService serviceWithoutExtractor;

    setUp(() {
      storage = MockEvidenceStoragePort();
      extractor = MockFragmentExtractorPort();
      serviceWithExtractor = EvidenceService(
        storage: storage,
        extractor: extractor,
      );
      serviceWithoutExtractor = EvidenceService(
        storage: storage,
      );
    });

    group('ingestEvidence', () {
      test('creates evidence with correct properties', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
          metadata: const {'key': 'value'},
        );

        final evidence = await serviceWithExtractor.ingestEvidence(input);

        expect(evidence.evidenceId, startsWith('ev_'));
        expect(evidence.workspaceId, equals('ws-1'));
        expect(evidence.content, equals('Test content'));
        expect(evidence.sourceType, equals(EvidenceSourceType.text));
        expect(evidence.status, equals(EvidenceStatus.pending));
        expect(evidence.fragmentIds, isEmpty);
        expect(evidence.metadata, equals({'key': 'value'}));
        expect(evidence.source.name, equals('source-1'));
      });

      test('saves evidence to storage', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );

        final evidence = await serviceWithExtractor.ingestEvidence(input);
        final stored = await storage.getEvidence(evidence.evidenceId);

        expect(stored, isNotNull);
        expect(stored!.evidenceId, equals(evidence.evidenceId));
      });

      test('generates content hash', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );

        final evidence = await serviceWithExtractor.ingestEvidence(input);

        expect(evidence.contentHash, isNotEmpty);
      });
    });

    group('extractFragments', () {
      test('extracts fragments from evidence using extractor', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        final fragments =
            await serviceWithExtractor.extractFragments(evidence.evidenceId);

        expect(fragments, hasLength(1));
        expect(fragments.first.fragmentId, equals('frag_1'));
        expect(extractor.extractCalled, isTrue);
      });

      test('uses default ExtractionConfig when none provided', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        final fragments =
            await serviceWithExtractor.extractFragments(evidence.evidenceId);

        expect(fragments, isNotEmpty);
      });

      test('uses custom ExtractionConfig when provided', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        const config = ExtractionConfig(
          method: ExtractorType.llm,
          maxFragmentSize: 500,
        );
        final fragments = await serviceWithExtractor
            .extractFragments(evidence.evidenceId, config: config);

        expect(fragments, isNotEmpty);
      });

      test('updates evidence status and fragment IDs', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        await serviceWithExtractor.extractFragments(evidence.evidenceId);

        final updated = await storage.getEvidence(evidence.evidenceId);
        expect(updated!.status, equals(EvidenceStatus.extracted));
        expect(updated.fragmentIds, contains('frag_1'));
      });

      test('throws StateError when extractor not configured', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithoutExtractor.ingestEvidence(input);

        expect(
          () => serviceWithoutExtractor
              .extractFragments(evidence.evidenceId),
          throwsStateError,
        );
      });

      test('throws ArgumentError when evidence not found', () async {
        expect(
          () => serviceWithExtractor.extractFragments('nonexistent'),
          throwsArgumentError,
        );
      });
    });

    group('getEvidence', () {
      test('returns evidence when found', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        final result =
            await serviceWithExtractor.getEvidence(evidence.evidenceId);

        expect(result, isNotNull);
        expect(result!.evidenceId, equals(evidence.evidenceId));
      });

      test('returns null when not found', () async {
        final result =
            await serviceWithExtractor.getEvidence('nonexistent');

        expect(result, isNull);
      });
    });

    group('queryEvidence', () {
      test('returns matching evidence', () async {
        await serviceWithExtractor.ingestEvidence(IngestionInput(
          workspaceId: 'ws-1',
          content: 'Content 1',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        ));
        // Delay to ensure unique timestamp-based ID generation
        await Future.delayed(const Duration(milliseconds: 2));
        await serviceWithExtractor.ingestEvidence(IngestionInput(
          workspaceId: 'ws-2',
          content: 'Content 2',
          sourceId: 'source-2',
          sourceType: EvidenceSourceType.image,
        ));

        final results = await serviceWithExtractor
            .queryEvidence(const EvidenceQuery(workspaceId: 'ws-1'));

        expect(results, hasLength(1));
        expect(results.first.workspaceId, equals('ws-1'));
      });
    });

    group('getFragments', () {
      test('returns fragments for evidence', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor.extractFragments(evidence.evidenceId);

        final fragments =
            await serviceWithExtractor.getFragments(evidence.evidenceId);

        expect(fragments, hasLength(1));
      });

      test('returns empty list when no fragments', () async {
        final fragments =
            await serviceWithExtractor.getFragments('nonexistent');

        expect(fragments, isEmpty);
      });
    });

    group('confirmFragment', () {
      test('confirms a fragment', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor.extractFragments(evidence.evidenceId);

        final confirmed = await serviceWithExtractor.confirmFragment(
          evidence.evidenceId,
          'frag_1',
        );

        expect(confirmed.status, equals(FragmentStatus.confirmed));
        expect(confirmed.fragmentId, equals('frag_1'));
      });

      test('throws ArgumentError when fragment not found', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        expect(
          () => serviceWithExtractor.confirmFragment(
            evidence.evidenceId,
            'nonexistent',
          ),
          throwsArgumentError,
        );
      });
    });

    group('rejectFragment', () {
      test('rejects a fragment', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor.extractFragments(evidence.evidenceId);

        final rejected = await serviceWithExtractor.rejectFragment(
          evidence.evidenceId,
          'frag_1',
        );

        expect(rejected.status, equals(FragmentStatus.rejected));
        expect(rejected.fragmentId, equals('frag_1'));
      });

      test('throws ArgumentError when fragment not found', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        expect(
          () => serviceWithExtractor.rejectFragment(
            evidence.evidenceId,
            'nonexistent',
          ),
          throwsArgumentError,
        );
      });
    });

    group('deleteEvidence', () {
      test('deletes evidence from storage', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence = await serviceWithExtractor.ingestEvidence(input);

        await serviceWithExtractor.deleteEvidence(evidence.evidenceId);

        final result =
            await storage.getEvidence(evidence.evidenceId);
        expect(result, isNull);
      });
    });

    // Additional coverage tests targeting uncovered lines

    group('ingestEvidence - additional coverage', () {
      test('creates evidence without metadata (default empty map)', () async {
        final input = IngestionInput(
          workspaceId: 'ws-2',
          content: 'No metadata content',
          sourceId: 'source-2',
          sourceType: EvidenceSourceType.image,
        );

        final evidence =
            await serviceWithoutExtractor.ingestEvidence(input);

        expect(evidence.evidenceId, startsWith('ev_'));
        expect(evidence.workspaceId, equals('ws-2'));
        expect(evidence.sourceType, equals(EvidenceSourceType.image));
        expect(evidence.content, equals('No metadata content'));
        expect(evidence.contentHash, isNotEmpty);
        expect(evidence.source.name, equals('source-2'));
        expect(evidence.source.attributes, isEmpty);
        expect(evidence.createdAt, isNotNull);
        expect(evidence.ingestedAt, isNotNull);
        expect(evidence.status, equals(EvidenceStatus.pending));
        expect(evidence.fragmentIds, isEmpty);
        expect(evidence.metadata, isEmpty);
      });

      test('content hash is deterministic for same content', () async {
        final input1 = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Same content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );

        final evidence1 =
            await serviceWithExtractor.ingestEvidence(input1);
        await Future.delayed(const Duration(milliseconds: 2));

        final input2 = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Same content',
          sourceId: 'source-2',
          sourceType: EvidenceSourceType.text,
        );
        final evidence2 =
            await serviceWithExtractor.ingestEvidence(input2);

        // Same content produces same hash
        expect(evidence1.contentHash, equals(evidence2.contentHash));
        // But different IDs
        expect(evidence1.evidenceId, isNot(equals(evidence2.evidenceId)));
      });

      test('source info attributes come from metadata', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test',
          sourceId: 'src-1',
          sourceType: EvidenceSourceType.text,
          metadata: const {'key1': 'val1', 'key2': 42},
        );

        final evidence =
            await serviceWithExtractor.ingestEvidence(input);

        expect(evidence.source.attributes, equals({'key1': 'val1', 'key2': 42}));
      });
    });

    group('extractFragments - additional coverage', () {
      test('saves extracted fragments to storage', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithExtractor.ingestEvidence(input);

        final fragments = await serviceWithExtractor
            .extractFragments(evidence.evidenceId);

        // Verify fragments are saved in storage
        final storedFragments =
            await storage.getFragments(evidence.evidenceId);
        expect(storedFragments, hasLength(fragments.length));
        expect(storedFragments.first.fragmentId,
            equals(fragments.first.fragmentId));
      });

      test('updates evidence with all fragment IDs', () async {
        // Set up multi-fragment extractor result
        extractor.extractResult = [
          Fragment(
            fragmentId: 'frag_a',
            workspaceId: 'ws-1',
            evidenceId: 'will-be-overridden',
            fields: const {'name': 'Item A'},
            confidence: 0.8,
            createdAt: DateTime.now(),
          ),
          Fragment(
            fragmentId: 'frag_b',
            workspaceId: 'ws-1',
            evidenceId: 'will-be-overridden',
            fields: const {'name': 'Item B'},
            confidence: 0.7,
            createdAt: DateTime.now(),
          ),
        ];

        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Multi-fragment content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithExtractor.ingestEvidence(input);

        final fragments = await serviceWithExtractor
            .extractFragments(evidence.evidenceId);

        expect(fragments, hasLength(2));

        final updated =
            await storage.getEvidence(evidence.evidenceId);
        expect(updated!.fragmentIds, contains('frag_a'));
        expect(updated.fragmentIds, contains('frag_b'));
        expect(updated.status, equals(EvidenceStatus.extracted));
      });
    });

    group('confirmFragment - additional coverage', () {
      test('persists confirmed fragment status to storage', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor
            .extractFragments(evidence.evidenceId);

        final confirmed = await serviceWithExtractor.confirmFragment(
          evidence.evidenceId,
          'frag_1',
        );

        // Verify persisted in storage
        final storedFragments =
            await storage.getFragments(evidence.evidenceId);
        final found = storedFragments
            .firstWhere((f) => f.fragmentId == confirmed.fragmentId);
        expect(found.status, equals(FragmentStatus.confirmed));
      });
    });

    group('rejectFragment - additional coverage', () {
      test('persists rejected fragment status to storage', () async {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test content',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor
            .extractFragments(evidence.evidenceId);

        final rejected = await serviceWithExtractor.rejectFragment(
          evidence.evidenceId,
          'frag_1',
        );

        // Verify persisted in storage
        final storedFragments =
            await storage.getFragments(evidence.evidenceId);
        final found = storedFragments
            .firstWhere((f) => f.fragmentId == rejected.fragmentId);
        expect(found.status, equals(FragmentStatus.rejected));
      });
    });

    group('queryEvidence - additional coverage', () {
      test('returns all evidence with empty query', () async {
        await serviceWithExtractor.ingestEvidence(IngestionInput(
          workspaceId: 'ws-1',
          content: 'Content 1',
          sourceId: 'source-1',
          sourceType: EvidenceSourceType.text,
        ));
        await Future.delayed(const Duration(milliseconds: 2));
        await serviceWithExtractor.ingestEvidence(IngestionInput(
          workspaceId: 'ws-2',
          content: 'Content 2',
          sourceId: 'source-2',
          sourceType: EvidenceSourceType.text,
        ));

        final results = await serviceWithExtractor
            .queryEvidence(const EvidenceQuery());

        expect(results, hasLength(2));
      });
    });

    group('getFragments - additional coverage', () {
      test('returns all fragments after extraction', () async {
        // Use default extractor result (evidenceId matches evidence)
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'Test',
          sourceId: 'src-1',
          sourceType: EvidenceSourceType.text,
        );
        final evidence =
            await serviceWithExtractor.ingestEvidence(input);
        await serviceWithExtractor
            .extractFragments(evidence.evidenceId);

        final fragments =
            await serviceWithExtractor.getFragments(evidence.evidenceId);

        expect(fragments, hasLength(1));
        expect(fragments.first.fragmentId, equals('frag_1'));
        expect(fragments.first.confidence, equals(0.9));
      });
    });

    group('deleteEvidence - additional coverage', () {
      test('deleting non-existent evidence does not throw', () async {
        // Should complete without error
        await serviceWithExtractor.deleteEvidence('non-existent-id');
      });
    });
  });
}
