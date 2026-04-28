/// Fact entity for L1 FactGraph Layer.
///
/// Represents confirmed facts in the graph.
/// Reference: 03-data-model-specification.md Section 2.6
library;

/// Fact represents a confirmed fact in the fact graph.
///
/// Facts are created when candidates are confirmed and promoted.
class Fact {
  /// Unique fact identifier.
  final String factId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Fact type (expense, schedule, task, transaction, etc.).
  final String factType;

  /// Fact summary/title.
  final String summary;

  /// Finalized field values.
  /// Reference: Design Section 2.6 - payload.
  final Map<String, dynamic> payload;

  /// Fact timestamp (when the fact occurred).
  final DateTime occurredAt;

  /// Fact status.
  final FactStatus status;

  /// Source candidate ID.
  final String candidateId;

  /// Source evidence IDs.
  final List<String> evidenceRefs;

  /// Related entity IDs.
  final List<String> entityRefs;

  /// When this fact was created in the system.
  final DateTime createdAt;

  /// Policy version used for confirmation.
  final String? policyVersion;

  /// ID of the fact this supersedes (correction chain).
  final String? supersedes;

  /// ID of the fact cluster this fact belongs to.
  final String? factClusterId;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Fact({
    required this.factId,
    required this.workspaceId,
    required this.factType,
    required this.summary,
    this.payload = const {},
    required this.occurredAt,
    this.status = FactStatus.confirmed,
    required this.candidateId,
    this.evidenceRefs = const [],
    this.entityRefs = const [],
    required this.createdAt,
    this.policyVersion,
    this.supersedes,
    this.factClusterId,
    this.metadata = const {},
  });

  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      factId: json['factId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      factType: json['factType'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : DateTime.now(),
      status: FactStatus.fromString(json['status'] as String? ?? 'confirmed'),
      candidateId: json['candidateId'] as String? ?? '',
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entityRefs: (json['entityRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String?,
      supersedes: json['supersedes'] as String?,
      factClusterId: json['factClusterId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factId': factId,
      'workspaceId': workspaceId,
      'factType': factType,
      'summary': summary,
      if (payload.isNotEmpty) 'payload': payload,
      'occurredAt': occurredAt.toIso8601String(),
      'status': status.name,
      'candidateId': candidateId,
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      if (entityRefs.isNotEmpty) 'entityRefs': entityRefs,
      'createdAt': createdAt.toIso8601String(),
      if (policyVersion != null) 'policyVersion': policyVersion,
      if (supersedes != null) 'supersedes': supersedes,
      if (factClusterId != null) 'factClusterId': factClusterId,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Fact copyWith({
    String? factId,
    String? workspaceId,
    String? factType,
    String? summary,
    Map<String, dynamic>? payload,
    DateTime? occurredAt,
    FactStatus? status,
    String? candidateId,
    List<String>? evidenceRefs,
    List<String>? entityRefs,
    DateTime? createdAt,
    String? policyVersion,
    String? supersedes,
    String? factClusterId,
    Map<String, dynamic>? metadata,
  }) {
    return Fact(
      factId: factId ?? this.factId,
      workspaceId: workspaceId ?? this.workspaceId,
      factType: factType ?? this.factType,
      summary: summary ?? this.summary,
      payload: payload ?? this.payload,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
      candidateId: candidateId ?? this.candidateId,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      entityRefs: entityRefs ?? this.entityRefs,
      createdAt: createdAt ?? this.createdAt,
      policyVersion: policyVersion ?? this.policyVersion,
      supersedes: supersedes ?? this.supersedes,
      factClusterId: factClusterId ?? this.factClusterId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'Fact($factId, type: $factType, summary: $summary)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Fact && factId == other.factId;

  @override
  int get hashCode => factId.hashCode;
}

/// Backward compatibility alias.
@Deprecated('Use Fact instead')
typedef Event = Fact;

/// Fact status.
enum FactStatus {
  /// Confirmed fact.
  confirmed,

  /// Reclassified (correction exists).
  reclassified,

  /// Archived.
  archived;

  static FactStatus fromString(String value) {
    return FactStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FactStatus.confirmed,
    );
  }
}

/// Backward compatibility alias.
@Deprecated('Use FactStatus instead')
typedef EventStatus = FactStatus;

// Domain-layer FactEdge, FactEdgeType, EdgeTargetType removed per design §2.17.
// Use graph-layer EdgeType from graph/fact_edge.dart instead.
