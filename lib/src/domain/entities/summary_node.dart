/// SummaryNode entity for L2 ContextOps Layer.
///
/// Represents cumulative summaries in a hierarchical structure.
library;

/// SummaryNode represents a hierarchical summary unit.
///
/// Summaries are organized in a tree structure for efficient retrieval.
class SummaryNode {
  /// Unique summary node identifier.
  final String nodeId;

  /// Summary type/category.
  final SummaryType summaryType;

  /// Summary title.
  final String title;

  /// Summary content.
  final String content;

  /// Summary scope/topic.
  final String? scope;

  /// Parent node ID (for hierarchy).
  final String? parentId;

  /// Child node IDs.
  final List<String> childIds;

  /// Source event IDs included in this summary.
  final List<String> sourceEventIds;

  /// Source entity IDs referenced.
  final List<String> sourceEntityIds;

  /// Time period covered.
  final SummaryPeriod? period;

  /// Summary level in hierarchy (0 = leaf).
  final int level;

  /// Token count of content.
  final int tokenCount;

  /// When this summary was created.
  final DateTime createdAt;

  /// When this summary was last updated.
  final DateTime updatedAt;

  /// Summary status.
  final SummaryStatus status;

  /// Version number.
  final int version;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const SummaryNode({
    required this.nodeId,
    required this.summaryType,
    required this.title,
    required this.content,
    this.scope,
    this.parentId,
    this.childIds = const [],
    this.sourceEventIds = const [],
    this.sourceEntityIds = const [],
    this.period,
    this.level = 0,
    this.tokenCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = SummaryStatus.current,
    this.version = 1,
    this.metadata = const {},
  });

  factory SummaryNode.fromJson(Map<String, dynamic> json) {
    return SummaryNode(
      nodeId: json['nodeId'] as String? ?? '',
      summaryType:
          SummaryType.fromString(json['summaryType'] as String? ?? 'general'),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scope: json['scope'] as String?,
      parentId: json['parentId'] as String?,
      childIds: (json['childIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sourceEventIds: (json['sourceEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sourceEntityIds: (json['sourceEntityIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      period: json['period'] != null
          ? SummaryPeriod.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      level: json['level'] as int? ?? 0,
      tokenCount: json['tokenCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      status:
          SummaryStatus.fromString(json['status'] as String? ?? 'current'),
      version: json['version'] as int? ?? 1,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'summaryType': summaryType.name,
      'title': title,
      'content': content,
      if (scope != null) 'scope': scope,
      if (parentId != null) 'parentId': parentId,
      if (childIds.isNotEmpty) 'childIds': childIds,
      if (sourceEventIds.isNotEmpty) 'sourceEventIds': sourceEventIds,
      if (sourceEntityIds.isNotEmpty) 'sourceEntityIds': sourceEntityIds,
      if (period != null) 'period': period!.toJson(),
      'level': level,
      'tokenCount': tokenCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'version': version,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  SummaryNode copyWith({
    String? nodeId,
    SummaryType? summaryType,
    String? title,
    String? content,
    String? scope,
    String? parentId,
    List<String>? childIds,
    List<String>? sourceEventIds,
    List<String>? sourceEntityIds,
    SummaryPeriod? period,
    int? level,
    int? tokenCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    SummaryStatus? status,
    int? version,
    Map<String, dynamic>? metadata,
  }) {
    return SummaryNode(
      nodeId: nodeId ?? this.nodeId,
      summaryType: summaryType ?? this.summaryType,
      title: title ?? this.title,
      content: content ?? this.content,
      scope: scope ?? this.scope,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? this.childIds,
      sourceEventIds: sourceEventIds ?? this.sourceEventIds,
      sourceEntityIds: sourceEntityIds ?? this.sourceEntityIds,
      period: period ?? this.period,
      level: level ?? this.level,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this is a root node.
  bool get isRoot => parentId == null;

  /// Check if this is a leaf node.
  bool get isLeaf => childIds.isEmpty;

  @override
  String toString() =>
      'SummaryNode($nodeId, type: $summaryType, level: $level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryNode && nodeId == other.nodeId;

  @override
  int get hashCode => nodeId.hashCode;
}

/// Summary types.
enum SummaryType {
  /// General purpose summary.
  general,

  /// Daily summary.
  daily,

  /// Weekly summary.
  weekly,

  /// Monthly summary.
  monthly,

  /// Topic-based summary.
  topical,

  /// Entity-centric summary.
  entity,

  /// Project/task summary.
  project,

  /// Conversation summary.
  conversation;

  static SummaryType fromString(String value) {
    return SummaryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SummaryType.general,
    );
  }
}

/// Summary status.
enum SummaryStatus {
  /// Current and valid.
  current,

  /// Needs refresh.
  stale,

  /// Being updated.
  updating,

  /// Archived.
  archived;

  static SummaryStatus fromString(String value) {
    return SummaryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SummaryStatus.current,
    );
  }
}

/// Summary time period.
class SummaryPeriod {
  /// Period start.
  final DateTime start;

  /// Period end.
  final DateTime end;

  /// Period granularity.
  final PeriodGranularity granularity;

  const SummaryPeriod({
    required this.start,
    required this.end,
    this.granularity = PeriodGranularity.custom,
  });

  factory SummaryPeriod.fromJson(Map<String, dynamic> json) {
    return SummaryPeriod(
      start: json['start'] != null
          ? DateTime.parse(json['start'] as String)
          : DateTime.now(),
      end: json['end'] != null
          ? DateTime.parse(json['end'] as String)
          : DateTime.now(),
      granularity: PeriodGranularity.fromString(
          json['granularity'] as String? ?? 'custom'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'granularity': granularity.name,
    };
  }

  /// Duration of the period.
  Duration get duration => end.difference(start);
}

/// Period granularity levels.
enum PeriodGranularity {
  hourly,
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom;

  static PeriodGranularity fromString(String value) {
    return PeriodGranularity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PeriodGranularity.custom,
    );
  }
}
