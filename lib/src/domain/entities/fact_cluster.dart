/// FactCluster entity model.
///
/// Groups multiple Facts that represent the same real-world occurrence.
/// Reference: 03-data-model-specification.md Section 2.6.1
library;

/// Status of a fact cluster.
enum FactClusterStatus {
  /// Active cluster.
  active,

  /// Merged into another cluster.
  merged,

  /// Archived cluster.
  archived;

  /// Create from string.
  static FactClusterStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return FactClusterStatus.active;
      case 'merged':
        return FactClusterStatus.merged;
      case 'archived':
        return FactClusterStatus.archived;
      default:
        return FactClusterStatus.active;
    }
  }
}

/// Backward compatibility alias.
@Deprecated('Use FactClusterStatus instead')
typedef CanonicalStatus = FactClusterStatus;

/// Audit entry for cluster operations.
class FactClusterAuditEntry {
  /// When the action occurred.
  final DateTime timestamp;

  /// Action performed: create, add_member, remove_member, merge, set_primary.
  final String action;

  /// Related fact ID.
  final String? factId;

  /// Reason for the action.
  final String? reason;

  /// Actor: user, system, llm.
  final String? actor;

  const FactClusterAuditEntry({
    required this.timestamp,
    required this.action,
    this.factId,
    this.reason,
    this.actor,
  });

  /// Create from JSON.
  factory FactClusterAuditEntry.fromJson(Map<String, dynamic> json) {
    return FactClusterAuditEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String? ?? '',
      factId: json['factId'] as String?,
      reason: json['reason'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      if (factId != null) 'factId': factId,
      if (reason != null) 'reason': reason,
      if (actor != null) 'actor': actor,
    };
  }

  /// Create a copy with modifications.
  FactClusterAuditEntry copyWith({
    DateTime? timestamp,
    String? action,
    String? factId,
    String? reason,
    String? actor,
  }) {
    return FactClusterAuditEntry(
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      factId: factId ?? this.factId,
      reason: reason ?? this.reason,
      actor: actor ?? this.actor,
    );
  }
}

/// Backward compatibility alias.
@Deprecated('Use FactClusterAuditEntry instead')
typedef ClusterAuditEntry = FactClusterAuditEntry;

/// FactCluster groups multiple Facts that represent the same real-world occurrence.
class FactCluster {
  /// Unique identifier for this fact cluster.
  final String factClusterId;

  /// Fact type (same as member facts).
  final String factType;

  /// Current representative fact ID.
  final String primaryFactId;

  /// All facts in this cluster.
  final List<String> memberFactIds;

  /// Consolidated payload from all member facts.
  final Map<String, dynamic> mergedPayload;

  /// Status of this fact cluster.
  final FactClusterStatus status;

  /// Clustering confidence (0.0 to 1.0).
  final double confidence;

  /// If merged into another cluster, the target ID.
  final String? mergedInto;

  /// Clustering decision history.
  final List<FactClusterAuditEntry> auditTrail;

  /// When the fact cluster was created.
  final DateTime createdAt;

  /// When the fact cluster was last updated.
  final DateTime updatedAt;

  const FactCluster({
    required this.factClusterId,
    required this.factType,
    required this.primaryFactId,
    required this.memberFactIds,
    this.mergedPayload = const {},
    this.status = FactClusterStatus.active,
    this.confidence = 1.0,
    this.mergedInto,
    this.auditTrail = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON.
  factory FactCluster.fromJson(Map<String, dynamic> json) {
    return FactCluster(
      factClusterId: json['factClusterId'] as String? ?? '',
      factType: json['factType'] as String? ?? '',
      primaryFactId: json['primaryFactId'] as String? ?? '',
      memberFactIds: (json['memberFactIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mergedPayload: json['mergedPayload'] as Map<String, dynamic>? ?? {},
      status: FactClusterStatus.fromString(json['status'] as String? ?? 'active'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      mergedInto: json['mergedInto'] as String?,
      auditTrail: (json['auditTrail'] as List<dynamic>?)
              ?.map((e) => FactClusterAuditEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'factClusterId': factClusterId,
      'factType': factType,
      'primaryFactId': primaryFactId,
      'memberFactIds': memberFactIds,
      if (mergedPayload.isNotEmpty) 'mergedPayload': mergedPayload,
      'status': status.name,
      'confidence': confidence,
      if (mergedInto != null) 'mergedInto': mergedInto,
      if (auditTrail.isNotEmpty)
        'auditTrail': auditTrail.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  FactCluster copyWith({
    String? factClusterId,
    String? factType,
    String? primaryFactId,
    List<String>? memberFactIds,
    Map<String, dynamic>? mergedPayload,
    FactClusterStatus? status,
    double? confidence,
    String? mergedInto,
    List<FactClusterAuditEntry>? auditTrail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FactCluster(
      factClusterId: factClusterId ?? this.factClusterId,
      factType: factType ?? this.factType,
      primaryFactId: primaryFactId ?? this.primaryFactId,
      memberFactIds: memberFactIds ?? this.memberFactIds,
      mergedPayload: mergedPayload ?? this.mergedPayload,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      mergedInto: mergedInto ?? this.mergedInto,
      auditTrail: auditTrail ?? this.auditTrail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this cluster is active.
  bool get isActive => status == FactClusterStatus.active;

  /// Check if this cluster has multiple members.
  bool get hasMultipleMembers => memberFactIds.length > 1;

  /// Add a member fact to this cluster.
  FactCluster addMember(String factId, {String? reason, String? actor}) {
    if (memberFactIds.contains(factId)) {
      return this;
    }

    return copyWith(
      memberFactIds: [...memberFactIds, factId],
      auditTrail: [
        ...auditTrail,
        FactClusterAuditEntry(
          timestamp: DateTime.now(),
          action: 'add_member',
          factId: factId,
          reason: reason,
          actor: actor,
        ),
      ],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a member fact from this cluster.
  FactCluster removeMember(String factId, {String? reason, String? actor}) {
    if (!memberFactIds.contains(factId)) {
      return this;
    }

    final newMembers = memberFactIds.where((id) => id != factId).toList();
    final newPrimary = primaryFactId == factId
        ? (newMembers.isNotEmpty ? newMembers.first : primaryFactId)
        : primaryFactId;

    return copyWith(
      memberFactIds: newMembers,
      primaryFactId: newPrimary,
      auditTrail: [
        ...auditTrail,
        FactClusterAuditEntry(
          timestamp: DateTime.now(),
          action: 'remove_member',
          factId: factId,
          reason: reason,
          actor: actor,
        ),
      ],
      updatedAt: DateTime.now(),
    );
  }

  /// Set the primary fact.
  FactCluster setPrimary(String factId, {String? reason, String? actor}) {
    if (!memberFactIds.contains(factId)) {
      throw ArgumentError('Fact $factId is not a member of this cluster');
    }

    return copyWith(
      primaryFactId: factId,
      auditTrail: [
        ...auditTrail,
        FactClusterAuditEntry(
          timestamp: DateTime.now(),
          action: 'set_primary',
          factId: factId,
          reason: reason,
          actor: actor,
        ),
      ],
      updatedAt: DateTime.now(),
    );
  }
}

/// Backward compatibility alias.
@Deprecated('Use FactCluster instead')
typedef CanonicalEvent = FactCluster;
