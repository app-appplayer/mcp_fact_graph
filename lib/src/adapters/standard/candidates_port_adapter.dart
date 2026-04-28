/// CandidatesPortAdapter - Implements mcp_bundle's capability `CandidatesPort`.
///
/// MOD-INFRA-015. Creates, queries, and reviews candidates via
/// [FactGraphService] + [CandidateStoragePort]. Converts between
/// `bundle.CandidateRecord` and internal `Candidate`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/candidate.dart' as local;
import '../../ports/storage_port.dart' as storage;
import '../../services/candidate_deduplicator.dart';
import '../../services/fact_graph_service.dart';

/// Implements `bundle.CandidatesPort` on top of `FactGraphService` and
/// `CandidateStoragePort`.
class CandidatesPortAdapter implements bundle.CandidatesPort {
  final FactGraphService _factGraphService;
  final storage.CandidateStoragePort _candidateStoragePort;
  final String _defaultWorkspaceId;
  final String _defaultPolicyVersion;
  final CandidateDeduplicator? _deduplicator;

  CandidatesPortAdapter({
    required FactGraphService factGraphService,
    required storage.CandidateStoragePort candidateStoragePort,
    String defaultWorkspaceId = 'default',
    String defaultPolicyVersion = 'v1',
    CandidateDeduplicator? deduplicator,
  })  : _factGraphService = factGraphService,
        _candidateStoragePort = candidateStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId,
        _defaultPolicyVersion = defaultPolicyVersion,
        _deduplicator = deduplicator;

  @override
  Future<List<String>> createCandidates(
    List<bundle.CandidateRecord> candidates,
  ) async {
    final created = <String>[];
    for (final record in candidates) {
      final internal = _recordToInternal(record);
      final dedup = _deduplicator;
      if (dedup != null) {
        final existingId = await dedup.findDuplicate(internal);
        if (existingId != null) {
          // Content-hash match — reuse the existing candidate id and
          // skip persistence of the duplicate.
          created.add(existingId);
          continue;
        }
      }
      await _candidateStoragePort.saveCandidate(internal);
      created.add(internal.candidateId);
    }
    return created;
  }

  @override
  Future<List<bundle.CandidateRecord>> getPendingCandidates(
    String workspaceId, {
    int? limit,
  }) async {
    final query = storage.CandidateQuery(
      workspaceId: workspaceId,
      status: local.CandidateStatus.open,
      limit: limit,
    );
    final results = await _candidateStoragePort.queryCandidates(query);
    return results
        .map((c) => _internalToRecord(c, workspaceIdFallback: workspaceId))
        .toList();
  }

  @override
  Future<void> confirmCandidate(
    String candidateId, {
    String? reviewerId,
  }) async {
    await _factGraphService.confirmCandidate(
      candidateId,
      policyVersion: _defaultPolicyVersion,
    );
    if (reviewerId != null) {
      final candidate = await _candidateStoragePort.getCandidate(candidateId);
      if (candidate != null) {
        final audit = [
          ...candidate.auditTrail,
          local.AuditEntry(
            timestamp: DateTime.now(),
            action: 'confirmed',
            sourceId: reviewerId,
          ),
        ];
        await _candidateStoragePort.saveCandidate(
          candidate.copyWith(auditTrail: audit),
        );
      }
    }
  }

  @override
  Future<void> rejectCandidate(
    String candidateId,
    String reason, {
    String? reviewerId,
  }) async {
    final candidate = await _candidateStoragePort.getCandidate(candidateId);
    if (candidate == null) {
      throw StateError('Candidate not found: $candidateId');
    }
    final audit = [
      ...candidate.auditTrail,
      local.AuditEntry(
        timestamp: DateTime.now(),
        action: 'rejected',
        sourceId: reviewerId ?? 'system',
        reason: reason,
      ),
    ];
    final updated = candidate.copyWith(
      status: local.CandidateStatus.rejected,
      auditTrail: audit,
      updatedAt: DateTime.now(),
    );
    await _candidateStoragePort.saveCandidate(updated);
  }

  // ---- Conversion helpers ----

  local.Candidate _recordToInternal(bundle.CandidateRecord record) {
    final fields = <String, local.CandidateField>{};
    record.content.forEach((k, v) {
      fields[k] = local.CandidateField(value: v, confidence: 1.0);
    });
    final candidate = local.Candidate(
      candidateId: record.id.isEmpty ? _generateId('cand') : record.id,
      workspaceId: record.workspaceId.isEmpty
          ? _defaultWorkspaceId
          : record.workspaceId,
      objectType: record.type,
      status: _toLocalStatus(record.status),
      fields: fields,
      evidenceIds: List<String>.from(record.evidenceRefs),
      confidence: record.confidence ?? 0.5,
      auditTrail: [
        local.AuditEntry(
          timestamp: record.createdAt,
          action: 'created',
          sourceId: 'bundle',
        ),
      ],
      createdAt: record.createdAt,
      updatedAt: record.createdAt,
    );
    // Stamp the content hash so future dedup lookups are O(n) over a
    // single metadata field instead of recomputing from fieldBag.
    final dedup = _deduplicator;
    if (dedup != null) {
      final hash = dedup.contentHash(candidate);
      return candidate.copyWith(
        metadata: {
          ...candidate.metadata,
          CandidateDeduplicator.hashMetadataKey: hash,
        },
      );
    }
    return candidate;
  }

  bundle.CandidateRecord _internalToRecord(
    local.Candidate candidate, {
    String workspaceIdFallback = 'default',
  }) {
    final content = <String, dynamic>{};
    candidate.fields.forEach((k, v) => content[k] = v.value);
    return bundle.CandidateRecord(
      id: candidate.candidateId,
      workspaceId: candidate.workspaceId.isEmpty
          ? workspaceIdFallback
          : candidate.workspaceId,
      type: candidate.objectType,
      content: content,
      status: _toBundleStatus(candidate.status),
      evidenceRefs: List<String>.from(candidate.evidenceIds),
      confidence: candidate.confidence,
      createdAt: candidate.createdAt,
    );
  }

  local.CandidateStatus _toLocalStatus(bundle.CandidateStatus s) {
    switch (s) {
      case bundle.CandidateStatus.pending:
        return local.CandidateStatus.open;
      case bundle.CandidateStatus.confirmed:
        return local.CandidateStatus.confirmed;
      case bundle.CandidateStatus.rejected:
        return local.CandidateStatus.rejected;
    }
  }

  bundle.CandidateStatus _toBundleStatus(local.CandidateStatus s) {
    switch (s) {
      case local.CandidateStatus.confirmed:
      case local.CandidateStatus.promoted:
        return bundle.CandidateStatus.confirmed;
      case local.CandidateStatus.rejected:
      case local.CandidateStatus.orphaned:
        return bundle.CandidateStatus.rejected;
      default:
        return bundle.CandidateStatus.pending;
    }
  }

  String _generateId(String prefix) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${ts}';
  }
}
