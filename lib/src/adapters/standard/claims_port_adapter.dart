/// ClaimsPortAdapter - Implements mcp_bundle's capability `ClaimsPort`.
///
/// MOD-INFRA-012. Provides claim CRUD and a best-effort
/// `validateClaims` implementation via [ContextService]
/// + [ContextStoragePort]. Converts between the capability DTO
/// [bundle.Claim] and the internal [VerifiableClaim].
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/claim.dart' as local;
import '../../ports/storage_port.dart' as storage;
import '../../services/context_service.dart';

/// Implements `bundle.ClaimsPort` on top of `ContextService` and
/// `ContextStoragePort`.
class ClaimsPortAdapter implements bundle.ClaimsPort {
  // ignore: unused_field
  final ContextService _contextService;
  final storage.ContextStoragePort _contextStoragePort;
  final String _defaultWorkspaceId;

  ClaimsPortAdapter({
    required ContextService contextService,
    required storage.ContextStoragePort contextStoragePort,
    String defaultWorkspaceId = 'default',
  })  : _contextService = contextService,
        _contextStoragePort = contextStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<void> writeClaims(
    List<bundle.Claim> claims, {
    List<String>? evidenceRefs,
  }) async {
    for (final claim in claims) {
      final internal = _claimToInternal(
        claim,
        extraEvidenceRefs: evidenceRefs,
      );
      await _contextStoragePort.saveClaim(internal);
    }
  }

  @override
  Future<List<bundle.Claim>> queryClaims(bundle.ClaimQuery query) async {
    final statuses = query.statuses;
    final types = query.types;

    final collected = <local.VerifiableClaim>[];

    if ((statuses == null || statuses.isEmpty) &&
        (types == null || types.isEmpty)) {
      final internalQuery = storage.ClaimQuery(
        workspaceId: query.workspaceId,
        limit: query.limit,
      );
      collected.addAll(await _contextStoragePort.queryClaims(internalQuery));
    } else {
      final effectiveStatuses = <bundle.ClaimStatus?>[
        if (statuses == null || statuses.isEmpty) null else ...statuses,
      ];
      final effectiveTypes = <String?>[
        if (types == null || types.isEmpty) null else ...types,
      ];

      for (final statusVal in effectiveStatuses) {
        for (final typeVal in effectiveTypes) {
          final internalQuery = storage.ClaimQuery(
            workspaceId: query.workspaceId,
            claimType:
                typeVal == null ? null : _toLocalTypeFromName(typeVal),
            verificationStatus:
                statusVal == null ? null : _toLocalStatus(statusVal),
            limit: query.limit,
          );
          collected.addAll(await _contextStoragePort.queryClaims(internalQuery));
          if (query.limit != null && collected.length >= query.limit!) break;
        }
        if (query.limit != null && collected.length >= query.limit!) break;
      }
    }

    var result = collected;
    if (query.entityId != null) {
      result = result
          .where((c) =>
              c.subject == query.entityId || c.object == query.entityId)
          .toList();
    }
    if (query.limit != null && result.length > query.limit!) {
      result = result.take(query.limit!).toList();
    }
    return result.map(_internalToClaim).toList();
  }

  @override
  Future<bundle.ClaimValidationReport> validateClaims(
    List<bundle.Claim> claims, {
    DateTime? asOf,
    String? policyVersion,
  }) async {
    final entries = <bundle.ClaimValidationEntry>[];
    final issues = <String>[];

    for (final claim in claims) {
      try {
        // Phase 2 best-effort: persist and report current status.
        // Real verification requires a ClaimVerificationPort which
        // may not be wired in the Scenario A host.
        final internal = _claimToInternal(claim);
        await _contextStoragePort.saveClaim(internal);
        entries.add(
          bundle.ClaimValidationEntry(
            claimId: claim.id,
            status: claim.status,
            supportingRefs: List<String>.from(claim.evidenceRefs),
          ),
        );
      } catch (e) {
        entries.add(
          bundle.ClaimValidationEntry(
            claimId: claim.id,
            status: bundle.ClaimStatus.unverifiable,
            conflictReason: e.toString(),
          ),
        );
        issues.add(e.toString());
      }
    }

    final passed = entries.every((e) =>
        e.status == bundle.ClaimStatus.supported ||
        e.status == bundle.ClaimStatus.partiallySupported);

    return bundle.ClaimValidationReport(
      passed: passed,
      entries: entries,
      issues: issues,
    );
  }

  @override
  Future<bundle.Claim?> getClaim(String id) async {
    final internal = await _contextStoragePort.getClaim(id);
    if (internal == null) return null;
    return _internalToClaim(internal);
  }

  @override
  Future<void> updateClaimStatus(
    String id,
    bundle.ClaimStatus status,
  ) async {
    final existing = await _contextStoragePort.getClaim(id);
    if (existing == null) {
      throw StateError('Claim not found: $id');
    }
    final updated = existing.copyWith(
      verificationStatus: _toLocalStatus(status),
    );
    await _contextStoragePort.saveClaim(updated);
  }

  // ---- Conversion helpers ----

  local.VerifiableClaim _claimToInternal(
    bundle.Claim claim, {
    List<String>? extraEvidenceRefs,
  }) {
    final evidence = <String>{
      ...claim.evidenceRefs,
      if (extraEvidenceRefs != null) ...extraEvidenceRefs,
    }.toList();
    return local.VerifiableClaim(
      claimId: claim.id,
      workspaceId: claim.workspaceId.isEmpty
          ? _defaultWorkspaceId
          : claim.workspaceId,
      statement: claim.text,
      claimType: _toLocalType(claim.type),
      subject: claim.subject,
      predicate: claim.predicate,
      object: claim.object,
      responseId: claim.sourceId,
      verificationStatus: _toLocalStatus(claim.status),
      supportingEvidenceIds: evidence,
      contradictingEvidenceIds: List<String>.from(claim.contradictingRefs),
      confidence: claim.confidence,
      createdAt: claim.createdAt ?? DateTime.now(),
      verifiedAt: claim.verifiedAt,
    );
  }

  bundle.Claim _internalToClaim(local.VerifiableClaim c) {
    return bundle.Claim(
      id: c.claimId,
      workspaceId: c.workspaceId,
      text: c.statement,
      type: _toBundleType(c.claimType),
      subject: c.subject,
      predicate: c.predicate,
      object: c.object,
      sourceId: c.responseId,
      evidenceRefs: List<String>.from(c.supportingEvidenceIds),
      contradictingRefs: List<String>.from(c.contradictingEvidenceIds),
      confidence: c.confidence,
      status: _toBundleStatus(c.verificationStatus),
      verifiedAt: c.verifiedAt,
      createdAt: c.createdAt,
    );
  }

  local.ClaimType _toLocalType(bundle.ClaimType t) {
    return local.ClaimType.values.firstWhere(
      (e) => e.name == t.name,
      orElse: () => local.ClaimType.fact,
    );
  }

  local.ClaimType _toLocalTypeFromName(String name) {
    return local.ClaimType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => local.ClaimType.fact,
    );
  }

  bundle.ClaimType _toBundleType(local.ClaimType t) {
    return bundle.ClaimType.values.firstWhere(
      (e) => e.name == t.name,
      orElse: () => bundle.ClaimType.fact,
    );
  }

  local.ClaimStatus _toLocalStatus(bundle.ClaimStatus s) {
    return local.ClaimStatus.values.firstWhere(
      (e) => e.name == s.name,
      orElse: () => local.ClaimStatus.pending,
    );
  }

  bundle.ClaimStatus _toBundleStatus(local.ClaimStatus s) {
    return bundle.ClaimStatus.values.firstWhere(
      (e) => e.name == s.name,
      orElse: () => bundle.ClaimStatus.pending,
    );
  }
}
