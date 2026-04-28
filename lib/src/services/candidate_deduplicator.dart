/// CandidateDeduplicator - Content-hash based candidate dedup.
///
/// C5. Before persisting a new candidate, the adapter consults this
/// service to learn whether an equivalent record (identical content
/// within the same workspace + object type) already exists. When so,
/// the existing candidate id is reused and the new record is dropped.
///
/// The hash is derived from:
///   sha256("{objectType}:{workspaceId}:{stableContentJson}")
///
/// and stored on each candidate's metadata under `contentHash` so
/// lookups can be performed with a single pass over pending records.
library;

import 'dart:convert';

import '../domain/entities/candidate.dart';
import '../ports/storage_port.dart';

/// Content-hash deduplicator for candidate records.
class CandidateDeduplicator {
  final CandidateStoragePort _storage;

  /// Metadata key used to record the content hash on each candidate.
  static const String hashMetadataKey = 'contentHash';

  /// Master enable switch — when false, [findDuplicate] always
  /// returns null and [contentHash] still works (pure function).
  final bool enabled;

  CandidateDeduplicator({
    required CandidateStoragePort storage,
    this.enabled = true,
  }) : _storage = storage;

  /// Compute the canonical content hash for [candidate]. A stable
  /// FNV-1a 64-bit digest over the canonical UTF-8 payload — good
  /// enough for content-equality lookups without pulling in an extra
  /// crypto dependency. Formatted as a 16-character lowercase hex
  /// string.
  String contentHash(Candidate candidate) {
    final ordered = _stableFields(candidate);
    final payload =
        '${candidate.objectType}:${candidate.workspaceId}:$ordered';
    return _fnv1a64(utf8.encode(payload));
  }

  /// FNV-1a 64-bit hash. Returns 16-char lowercase hex.
  String _fnv1a64(List<int> bytes) {
    // Use BigInt to avoid JS 53-bit precision issues on the web
    // target. Arithmetic stays on the cold path (dedup check only),
    // so the cost is negligible.
    final prime = BigInt.parse('1099511628211');
    final mask = BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16);
    var hash = BigInt.parse('CBF29CE484222325', radix: 16);
    for (final b in bytes) {
      hash = hash ^ BigInt.from(b & 0xFF);
      hash = (hash * prime) & mask;
    }
    final hex = hash.toRadixString(16);
    return hex.padLeft(16, '0');
  }

  /// Locate an existing candidate with the same content hash. Returns
  /// its id, or null when no match exists (or dedup is disabled).
  Future<String?> findDuplicate(Candidate candidate) async {
    if (!enabled) return null;

    final hash = contentHash(candidate);
    final existing = await _storage.queryCandidates(
      CandidateQuery(
        workspaceId: candidate.workspaceId,
        candidateType: candidate.objectType,
      ),
    );
    for (final other in existing) {
      if (other.candidateId == candidate.candidateId) continue;
      if (other.metadata[hashMetadataKey] == hash) {
        return other.candidateId;
      }
    }
    return null;
  }

  /// Stable JSON serialisation of [Candidate.fieldBag] — keys sorted.
  String _stableFields(Candidate candidate) {
    final bag = candidate.fieldBag;
    final sortedKeys = bag.keys.toList()..sort();
    final ordered = <String, dynamic>{};
    for (final key in sortedKeys) {
      ordered[key] = bag[key];
    }
    return jsonEncode(ordered);
  }
}
