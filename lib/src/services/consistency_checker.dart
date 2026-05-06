/// ConsistencyChecker - Guard against duplicate or conflicting facts.
///
/// C4. Invoked by `FactsPortAdapter.writeFacts` before persistence.
/// Two classes of conflict are flagged:
///
/// 1. Duplicate factId — an existing fact already lives under the
///    same identifier.
/// 2. Triple conflict — a stored fact shares the candidate's
///    `(entityId, factType)` combination, its validity window
///    overlaps the candidate's, yet its `valueJson` differs.
///
/// The checker never mutates storage; it returns a `ConflictReport`
/// when a conflict is detected (or `null` when clear) and leaves the
/// throw/raise decision to its caller.
library;

import 'dart:convert';

import '../domain/entities/fact.dart';
import '../ports/storage_port.dart';

/// Conflict classification returned by [ConsistencyChecker.check].
enum ConflictKind {
  /// A fact with the same id already exists.
  duplicateId,

  /// A stored fact has the same (entity, factType) triple, overlapping
  /// period, but a different value payload.
  tripleMismatch,
}

/// Report describing the detected conflict.
class ConflictReport {
  /// Conflict category.
  final ConflictKind kind;

  /// Offending factId (the candidate's id).
  final String factId;

  /// The pre-existing fact that triggered the conflict.
  final Fact existing;

  /// Human-readable explanation.
  final String reason;

  const ConflictReport({
    required this.kind,
    required this.factId,
    required this.existing,
    required this.reason,
  });
}

/// Detects duplicate factId and triple conflicts before a write.
class ConsistencyChecker {
  final FactStoragePort _storage;

  /// Master enable switch — when false, [check] is a no-op.
  final bool enabled;

  ConsistencyChecker({
    required FactStoragePort storage,
    this.enabled = true,
  }) : _storage = storage;

  /// Check [candidate] against stored facts. Returns a
  /// [ConflictReport] on conflict, or `null` otherwise.
  Future<ConflictReport?> check(Fact candidate) async {
    if (!enabled) return null;

    // Rule 1: duplicate factId.
    final byId = await _storage.getFact(candidate.factId);
    if (byId != null) {
      return ConflictReport(
        kind: ConflictKind.duplicateId,
        factId: candidate.factId,
        existing: byId,
        reason: 'Duplicate factId: ${candidate.factId}',
      );
    }

    // Rule 2: triple conflict — same (entity, factType), overlapping
    // period, different value payload.
    if (candidate.entityRefs.isEmpty) {
      return null;
    }
    final candidateJson = _stableJson(candidate.payload);
    for (final entityId in candidate.entityRefs) {
      final siblings = await _storage.queryFacts(
        FactQuery(
          workspaceId: candidate.workspaceId,
          factType: candidate.factType,
          entityIds: [entityId],
        ),
      );
      for (final sibling in siblings) {
        if (sibling.factId == candidate.factId) continue;
        if (sibling.status == FactStatus.archived) continue;

        final siblingJson = _stableJson(sibling.payload);
        if (siblingJson == candidateJson) continue;
        if (!_periodsOverlap(sibling, candidate)) continue;

        return ConflictReport(
          kind: ConflictKind.tripleMismatch,
          factId: candidate.factId,
          existing: sibling,
          reason:
              'Triple conflict on entity $entityId / factType ${candidate.factType}: '
              'existing value differs and validity periods overlap',
        );
      }
    }
    return null;
  }

  /// Stable JSON serialization for value comparison. Keys are sorted
  /// so that maps with the same contents hash to the same string.
  String _stableJson(Map<String, dynamic> payload) {
    final sortedKeys = payload.keys.toList()..sort();
    final ordered = <String, dynamic>{};
    for (final key in sortedKeys) {
      ordered[key] = payload[key];
    }
    return jsonEncode(ordered);
  }

  /// Interpret both facts as point-in-time occurrences and flag
  /// overlap iff their `occurredAt` instants match to the microsecond.
  ///
  /// The in-memory model stores a single `occurredAt` timestamp per fact.
  /// Two records are treated as overlapping only when those instants are
  /// equal — so a steady stream of point events at distinct timestamps
  /// does not trigger spurious triple-mismatch conflicts. Calendar-day
  /// reduction (the previous heuristic) caused every same-day, same
  /// (entity, factType) record to collide regardless of the actual time
  /// gap, which made point-period lifecycle records (e.g., FlowBrain
  /// `agent.fork.assigned` mirrors) impossible to ingest with the
  /// consistency checker enabled.
  bool _periodsOverlap(Fact a, Fact b) {
    return a.occurredAt.isAtSameMomentAs(b.occurredAt);
  }
}
