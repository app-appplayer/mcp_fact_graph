/// Evidence Service - L0 Layer operations.
///
/// Handles evidence ingestion, fragment extraction, and evidence management.
library;

import '../domain/entities/evidence.dart';
import '../domain/entities/fragment.dart';
import '../ports/storage_port.dart';
import 'ingestion_source.dart';

/// Service for L0 Evidence Layer operations.
class EvidenceService {
  /// Evidence storage port.
  final EvidenceStoragePort _storage;

  /// Fragment extractor port.
  final FragmentExtractorPort? _extractor;

  EvidenceService({
    required EvidenceStoragePort storage,
    FragmentExtractorPort? extractor,
  })  : _storage = storage,
        _extractor = extractor;

  /// Ingest new evidence.
  Future<Evidence> ingestEvidence(IngestionInput input) async {
    final evidenceId = _generateId('ev');
    final contentHash = _computeHash(input.content);

    final now = DateTime.now();
    final evidence = Evidence(
      evidenceId: evidenceId,
      workspaceId: input.workspaceId,
      sourceType: input.sourceType,
      content: input.content,
      contentHash: contentHash,
      source: SourceInfo(
        name: input.sourceId,
        attributes: input.metadata,
      ),
      createdAt: now,
      ingestedAt: now,
      status: EvidenceStatus.pending,
      fragmentIds: const [],
      metadata: input.metadata,
    );

    await _storage.saveEvidence(evidence);
    return evidence;
  }

  /// Extract fragments from evidence.
  Future<List<Fragment>> extractFragments(
    String evidenceId, {
    ExtractionConfig? config,
  }) async {
    if (_extractor == null) {
      throw StateError('Fragment extractor not configured');
    }

    final evidence = await _storage.getEvidence(evidenceId);
    if (evidence == null) {
      throw ArgumentError('Evidence not found: $evidenceId');
    }

    final extractionConfig = config ?? const ExtractionConfig();
    final fragments = await _extractor!.extract(evidence, extractionConfig);

    await _storage.saveFragments(fragments);

    // Update evidence with fragment IDs
    final updatedEvidence = evidence.copyWith(
      fragmentIds: fragments.map((f) => f.fragmentId).toList(),
      status: EvidenceStatus.extracted,
    );
    await _storage.saveEvidence(updatedEvidence);

    return fragments;
  }

  /// Get evidence by ID.
  Future<Evidence?> getEvidence(String evidenceId) {
    return _storage.getEvidence(evidenceId);
  }

  /// Query evidence.
  Future<List<Evidence>> queryEvidence(EvidenceQuery query) {
    return _storage.queryEvidence(query);
  }

  /// Get fragments for evidence.
  Future<List<Fragment>> getFragments(String evidenceId) {
    return _storage.getFragments(evidenceId);
  }

  /// Confirm a fragment.
  Future<Fragment> confirmFragment(
    String evidenceId,
    String fragmentId,
  ) async {
    final fragments = await _storage.getFragments(evidenceId);
    final fragment = fragments.firstWhere(
      (f) => f.fragmentId == fragmentId,
      orElse: () => throw ArgumentError('Fragment not found: $fragmentId'),
    );

    final confirmedFragment = fragment.copyWith(
      status: FragmentStatus.confirmed,
    );

    await _storage.saveFragments([confirmedFragment]);
    return confirmedFragment;
  }

  /// Reject a fragment.
  Future<Fragment> rejectFragment(
    String evidenceId,
    String fragmentId,
  ) async {
    final fragments = await _storage.getFragments(evidenceId);
    final fragment = fragments.firstWhere(
      (f) => f.fragmentId == fragmentId,
      orElse: () => throw ArgumentError('Fragment not found: $fragmentId'),
    );

    final rejectedFragment = fragment.copyWith(
      status: FragmentStatus.rejected,
    );

    await _storage.saveFragments([rejectedFragment]);
    return rejectedFragment;
  }

  /// Delete evidence and associated fragments.
  Future<void> deleteEvidence(String evidenceId) async {
    await _storage.deleteEvidence(evidenceId);
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs() % 10000;
    return '${prefix}_${timestamp}_$random';
  }

  String _computeHash(String content) {
    // Simple hash for now - should use crypto package in production
    return content.hashCode.toRadixString(16);
  }
}
