/// IdempotencyRecord entity model.
///
/// Prevents duplicate execution of operations.
/// Design: 03-data-model-specification.md Section 2.13
library;

/// Status of an idempotency record.
enum IdempotencyStatus {
  /// Operation is in progress.
  pending,

  /// Operation completed successfully.
  completed,

  /// Operation failed.
  failed;

  /// Create from string.
  static IdempotencyStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return IdempotencyStatus.pending;
      case 'completed':
        return IdempotencyStatus.completed;
      case 'failed':
        return IdempotencyStatus.failed;
      default:
        return IdempotencyStatus.pending;
    }
  }
}

/// IdempotencyRecord prevents duplicate execution of operations.
class IdempotencyRecord {
  /// Unique idempotency key.
  final String key;

  /// When the key was first used.
  final DateTime createdAt;

  /// When the key expires (optional TTL).
  final DateTime? expiresAt;

  /// Reference to the result (if cached).
  final String? resultRef;

  /// Operation status.
  final IdempotencyStatus status;

  /// Operation type.
  final String? operationType;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  const IdempotencyRecord({
    required this.key,
    required this.createdAt,
    this.expiresAt,
    this.resultRef,
    this.status = IdempotencyStatus.pending,
    this.operationType,
    this.metadata,
  });

  /// Create from JSON.
  factory IdempotencyRecord.fromJson(Map<String, dynamic> json) {
    return IdempotencyRecord(
      key: json['key'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      resultRef: json['resultRef'] as String?,
      status:
          IdempotencyStatus.fromString(json['status'] as String? ?? 'pending'),
      operationType: json['operationType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (resultRef != null) 'resultRef': resultRef,
      'status': status.name,
      if (operationType != null) 'operationType': operationType,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modifications.
  IdempotencyRecord copyWith({
    String? key,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? resultRef,
    IdempotencyStatus? status,
    String? operationType,
    Map<String, dynamic>? metadata,
  }) {
    return IdempotencyRecord(
      key: key ?? this.key,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      resultRef: resultRef ?? this.resultRef,
      status: status ?? this.status,
      operationType: operationType ?? this.operationType,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if the record has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the record is still valid.
  bool get isValid => !isExpired;

  /// Check if operation completed.
  bool get isCompleted => status == IdempotencyStatus.completed;

  /// Check if operation is pending.
  bool get isPending => status == IdempotencyStatus.pending;

  /// Check if operation failed.
  bool get isFailed => status == IdempotencyStatus.failed;

  /// Mark as completed.
  IdempotencyRecord complete({String? resultRef}) {
    return copyWith(
      status: IdempotencyStatus.completed,
      resultRef: resultRef,
    );
  }

  /// Mark as failed.
  IdempotencyRecord fail() {
    return copyWith(status: IdempotencyStatus.failed);
  }
}

/// Idempotency key generation strategies.
abstract class IdempotencyKeyStrategy {
  /// Time-based key: {jobId}:{period}.
  static const String timeBased = 'time-based';

  /// Content-based key: {operation}:{hash}.
  static const String contentBased = 'content-based';

  /// Request-based key: {user}:{request_id}.
  static const String requestBased = 'request-based';

  /// Generate a time-based key.
  static String generateTimeBased(String jobId, DateTime timestamp) {
    final dateStr = timestamp.toIso8601String().split('T').first;
    return '$jobId:$dateStr';
  }

  /// Generate a content-based key.
  static String generateContentBased(String operation, String contentHash) {
    return '$operation:$contentHash';
  }

  /// Generate a request-based key.
  static String generateRequestBased(String userId, String requestId) {
    return '$userId:$requestId';
  }
}
