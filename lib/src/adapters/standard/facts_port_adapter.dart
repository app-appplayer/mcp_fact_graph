/// FactsPortAdapter - Implements mcp_bundle's capability `FactsPort`.
///
/// MOD-INFRA-011. Delegates reads and writes to the internal
/// [FactGraphService] and [FactStoragePort]; converts between
/// [bundle.FactRecord] and the internal [Fact] entity.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/fact.dart';
import '../../exceptions/fact_conflict_exception.dart';
import '../../ports/storage_port.dart' as local;
import '../../services/consistency_checker.dart';
import '../../services/fact_graph_service.dart';

/// Metadata key used to stamp candidateId on fact records when the
/// bundle-level `FactRecord` does not carry an explicit
/// `sourceCandidateIds` field. Allows hosts to propagate provenance
/// without a breaking change to the public bundle contract.
const String metadataSourceCandidateKey = 'sourceCandidateId';

/// Metadata key used when writing back a candidate hint in the
/// reverse direction.
const String metadataSourceCandidateListKey = 'sourceCandidateIds';

/// Implements the capability port `bundle.FactsPort` on top of
/// `FactGraphService` and `FactStoragePort`.
class FactsPortAdapter implements bundle.FactsPort {
  final FactGraphService _factGraphService;
  final local.FactStoragePort _factStoragePort;
  final String _defaultWorkspaceId;
  final ConsistencyChecker? _consistencyChecker;

  FactsPortAdapter({
    required FactGraphService factGraphService,
    required local.FactStoragePort factStoragePort,
    String defaultWorkspaceId = 'default',
    ConsistencyChecker? consistencyChecker,
  })  : _factGraphService = factGraphService,
        _factStoragePort = factStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId,
        _consistencyChecker = consistencyChecker;

  @override
  Future<List<bundle.FactRecord>> queryFacts(bundle.FactQuery query) async {
    final allResults = <Fact>[];
    final types = query.types;
    final range = query.period?.resolve();

    if (types == null || types.isEmpty) {
      final internal = local.FactQuery(
        workspaceId: query.workspaceId,
        fromDate: range?.start,
        toDate: range?.end,
        entityIds: query.entityId == null ? null : [query.entityId!],
        limit: query.limit,
      );
      allResults.addAll(await _factGraphService.queryFacts(internal));
    } else {
      for (final type in types) {
        final internal = local.FactQuery(
          workspaceId: query.workspaceId,
          factType: type,
          fromDate: range?.start,
          toDate: range?.end,
          entityIds: query.entityId == null ? null : [query.entityId!],
          limit: query.limit,
        );
        allResults.addAll(await _factGraphService.queryFacts(internal));
        if (query.limit != null && allResults.length >= query.limit!) {
          break;
        }
      }
    }

    var trimmed = allResults;
    if (query.limit != null && trimmed.length > query.limit!) {
      trimmed = trimmed.take(query.limit!).toList();
    }

    return trimmed.map(_factToRecord).toList();
  }

  @override
  Future<void> writeFacts(List<bundle.FactRecord> facts) async {
    for (final record in facts) {
      final fact = _recordToFact(record);
      final checker = _consistencyChecker;
      if (checker != null) {
        final conflict = await checker.check(fact);
        if (conflict != null) {
          throw FactConflictException(fact.factId, conflict.reason);
        }
      }
      await _factStoragePort.saveFact(fact);
    }
  }

  @override
  Future<bundle.FactRecord?> getFact(String id) async {
    final fact = await _factGraphService.getFact(id);
    if (fact == null) return null;
    return _factToRecord(fact);
  }

  @override
  Future<void> deleteFacts(List<String> ids) async {
    for (final id in ids) {
      await _factStoragePort.deleteFact(id);
    }
  }

  // ---- Conversion helpers ----

  bundle.FactRecord _factToRecord(Fact fact) {
    // Surface provenance via the content payload so downstream
    // consumers can correlate facts with their source candidate
    // even while the bundle FactRecord stays structurally stable.
    final content = Map<String, dynamic>.from(fact.payload);
    if (fact.candidateId.isNotEmpty) {
      content.putIfAbsent(metadataSourceCandidateKey, () => fact.candidateId);
    }
    return bundle.FactRecord(
      id: fact.factId,
      workspaceId: fact.workspaceId,
      type: fact.factType,
      entityId: fact.entityRefs.isEmpty ? null : fact.entityRefs.first,
      content: content,
      confidence: null,
      period:
          bundle.AbsolutePeriod(start: fact.occurredAt, end: fact.occurredAt),
      evidenceRefs: List<String>.from(fact.evidenceRefs),
      createdAt: fact.createdAt,
    );
  }

  Fact _recordToFact(bundle.FactRecord record) {
    final occurredAt = record.period?.resolve().start ?? DateTime.now();
    final candidateId = _resolveCandidateId(record);
    return Fact(
      factId: record.id,
      workspaceId: record.workspaceId.isEmpty
          ? _defaultWorkspaceId
          : record.workspaceId,
      factType: record.type,
      summary: '${record.type}: ${record.id}',
      payload: Map<String, dynamic>.from(record.content),
      occurredAt: occurredAt,
      status: FactStatus.confirmed,
      candidateId: candidateId,
      evidenceRefs: List<String>.from(record.evidenceRefs),
      entityRefs: record.entityId == null ? const [] : [record.entityId!],
      createdAt: record.createdAt,
    );
  }

  /// Resolve the source candidateId for a bundle FactRecord.
  ///
  /// Provenance hints may travel in three places (in priority order):
  ///   1. `content[metadataSourceCandidateListKey]` — explicit list,
  ///      first element wins.
  ///   2. `content[metadataSourceCandidateKey]` — single id string.
  ///   3. Empty string fallback (unknown provenance).
  String _resolveCandidateId(bundle.FactRecord record) {
    final list = record.content[metadataSourceCandidateListKey];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is String && first.isNotEmpty) return first;
    }
    final single = record.content[metadataSourceCandidateKey];
    if (single is String && single.isNotEmpty) return single;
    return '';
  }
}
