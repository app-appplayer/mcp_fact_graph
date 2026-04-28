/// SummaryNode entity for L2 ContextOps Layer.
///
/// Represents cumulative summaries stored as graph nodes.
/// Reference: 03-data-model-specification.md Section 2.15.1
library;

/// SummaryNode represents a cumulative summary stored as a graph node.
///
/// Supports reproducibility via asOf and policyVersion fields.
class SummaryNode {
  /// Unique summary node identifier.
  final String summaryId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Summary text content.
  /// Reference: Design Section 2.15.1 - summaryText.
  final String summaryText;

  /// Fact IDs covered by this summary.
  /// Reference: Design Section 2.15.1 - coversFactIds.
  final List<String> coversFactIds;

  /// Point-in-time snapshot for reproducibility.
  /// Reference: Design Section 2.15.1 - enables time-travel queries.
  final DateTime asOf;

  /// Policy version used for generating this summary.
  /// Reference: Design Section 2.15.1 - enables reproducibility.
  final String policyVersion;

  /// ID of the summary this supersedes (latest summary pointer).
  /// Reference: Design Section 2.15.1 - supports incremental updates.
  final String? supersedes;

  /// Summary status.
  final SummaryStatus status;

  /// Summary scope.
  /// Reference: Design Section 2.15.1 - SummaryScope.
  final SummaryScope scope;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  /// When this summary was created.
  final DateTime createdAt;

  /// When this summary was last updated.
  final DateTime updatedAt;

  const SummaryNode({
    required this.summaryId,
    required this.workspaceId,
    required this.summaryText,
    this.coversFactIds = const [],
    required this.asOf,
    required this.policyVersion,
    this.supersedes,
    this.status = SummaryStatus.active,
    required this.scope,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SummaryNode.fromJson(Map<String, dynamic> json) {
    return SummaryNode(
      summaryId: json['summaryId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      summaryText: json['summaryText'] as String? ?? '',
      coversFactIds: (json['coversFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String? ?? '1.0.0',
      supersedes: json['supersedes'] as String?,
      status:
          SummaryStatus.fromString(json['status'] as String? ?? 'active'),
      scope: json['scope'] != null
          ? SummaryScope.fromJson(json['scope'] as Map<String, dynamic>)
          : const SummaryScope(scopeType: 'period'),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summaryId': summaryId,
      'workspaceId': workspaceId,
      'summaryText': summaryText,
      if (coversFactIds.isNotEmpty) 'coversFactIds': coversFactIds,
      'asOf': asOf.toIso8601String(),
      'policyVersion': policyVersion,
      if (supersedes != null) 'supersedes': supersedes,
      'status': status.name,
      'scope': scope.toJson(),
      if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SummaryNode copyWith({
    String? summaryId,
    String? workspaceId,
    String? summaryText,
    List<String>? coversFactIds,
    DateTime? asOf,
    String? policyVersion,
    String? supersedes,
    SummaryStatus? status,
    SummaryScope? scope,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SummaryNode(
      summaryId: summaryId ?? this.summaryId,
      workspaceId: workspaceId ?? this.workspaceId,
      summaryText: summaryText ?? this.summaryText,
      coversFactIds: coversFactIds ?? this.coversFactIds,
      asOf: asOf ?? this.asOf,
      policyVersion: policyVersion ?? this.policyVersion,
      supersedes: supersedes ?? this.supersedes,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'SummaryNode($summaryId, scope: ${scope.scopeType})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryNode && summaryId == other.summaryId;

  @override
  int get hashCode => summaryId.hashCode;
}

/// Summary status.
/// Reference: Design Section 2.15.1 - created | active | stale | refreshFail | archived
enum SummaryStatus {
  /// Newly created, generation pending.
  created,

  /// Current and valid.
  active,

  /// Source data changed, refresh needed.
  stale,

  /// Refresh attempted but failed.
  refreshFail,

  /// No longer maintained.
  archived;

  static SummaryStatus fromString(String value) {
    return SummaryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SummaryStatus.active,
    );
  }
}

/// Structured summary scope.
/// Reference: Design Section 2.15.1 - SummaryScope
class SummaryScope {
  /// Scope type (period, entity, project, topic).
  final String scopeType;

  /// Entity ID (if scoped to specific entity).
  final String? entityId;

  /// Time period (if scoped to time period).
  final SummaryPeriod? period;

  /// Topic/category ID (if scoped to topic).
  final String? topicId;

  const SummaryScope({
    required this.scopeType,
    this.entityId,
    this.period,
    this.topicId,
  });

  factory SummaryScope.fromJson(Map<String, dynamic> json) {
    return SummaryScope(
      scopeType: json['scopeType'] as String? ?? 'period',
      entityId: json['entityId'] as String?,
      period: json['period'] != null
          ? SummaryPeriod.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      topicId: json['topicId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scopeType': scopeType,
      if (entityId != null) 'entityId': entityId,
      if (period != null) 'period': period!.toJson(),
      if (topicId != null) 'topicId': topicId,
    };
  }
}

/// Simple period for summary time range.
class SummaryPeriod {
  /// Period start.
  final DateTime start;

  /// Period end.
  final DateTime end;

  const SummaryPeriod({
    required this.start,
    required this.end,
  });

  factory SummaryPeriod.fromJson(Map<String, dynamic> json) {
    return SummaryPeriod(
      start: json['start'] != null
          ? DateTime.parse(json['start'] as String)
          : DateTime.now(),
      end: json['end'] != null
          ? DateTime.parse(json['end'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  /// Duration of the period.
  Duration get duration => end.difference(start);
}
