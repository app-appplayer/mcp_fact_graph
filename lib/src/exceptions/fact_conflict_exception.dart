/// FactConflictException - Raised by the FactGraph consistency checker.
///
/// C4. Thrown by `FactsPortAdapter.writeFacts` when a newly submitted
/// fact conflicts with an existing record: either a duplicate
/// factId, or a triple (entityId + factType + valueJson) whose
/// validity window overlaps a stored fact with a different value.
library;

/// Exception raised when a candidate fact violates consistency rules.
class FactConflictException implements Exception {
  /// The offending fact's identifier (may be reused if the conflict
  /// stems from a duplicate id).
  final String factId;

  /// Human-readable explanation of the conflict.
  final String reason;

  const FactConflictException(this.factId, this.reason);

  @override
  String toString() => 'FactConflictException($factId): $reason';
}
