/// ContextBundle entity for L2 ContextOps Layer.
///
/// Represents short context bundles for LLM interactions.
library;

/// ContextBundle represents a curated context for LLM operations.
///
/// Bundles relevant facts, entities, and summaries for a specific query.
class ContextBundle {
  /// Unique bundle identifier.
  final String bundleId;

  /// Bundle purpose/type.
  final ContextPurpose purpose;

  /// Query or prompt this context is for.
  final String query;

  /// Included events (by ID).
  final List<String> eventIds;

  /// Included entities (by ID).
  final List<String> entityIds;

  /// Included summary nodes (by ID).
  final List<String> summaryIds;

  /// Raw context segments.
  final List<ContextSegment> segments;

  /// Total token count estimate.
  final int tokenCount;

  /// Maximum token budget.
  final int tokenBudget;

  /// Relevance scores for included items.
  final Map<String, double> relevanceScores;

  /// When this bundle was created.
  final DateTime createdAt;

  /// Bundle expiration time.
  final DateTime? expiresAt;

  /// Context selection strategy used.
  final SelectionStrategy strategy;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const ContextBundle({
    required this.bundleId,
    required this.purpose,
    required this.query,
    this.eventIds = const [],
    this.entityIds = const [],
    this.summaryIds = const [],
    this.segments = const [],
    this.tokenCount = 0,
    this.tokenBudget = 4096,
    this.relevanceScores = const {},
    required this.createdAt,
    this.expiresAt,
    this.strategy = SelectionStrategy.relevance,
    this.metadata = const {},
  });

  factory ContextBundle.fromJson(Map<String, dynamic> json) {
    return ContextBundle(
      bundleId: json['bundleId'] as String? ?? '',
      purpose: ContextPurpose.fromString(json['purpose'] as String? ?? 'query'),
      query: json['query'] as String? ?? '',
      eventIds: (json['eventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entityIds: (json['entityIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      summaryIds: (json['summaryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => ContextSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokenCount: json['tokenCount'] as int? ?? 0,
      tokenBudget: json['tokenBudget'] as int? ?? 4096,
      relevanceScores: (json['relevanceScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      strategy: SelectionStrategy.fromString(
          json['strategy'] as String? ?? 'relevance'),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bundleId': bundleId,
      'purpose': purpose.name,
      'query': query,
      if (eventIds.isNotEmpty) 'eventIds': eventIds,
      if (entityIds.isNotEmpty) 'entityIds': entityIds,
      if (summaryIds.isNotEmpty) 'summaryIds': summaryIds,
      if (segments.isNotEmpty)
        'segments': segments.map((s) => s.toJson()).toList(),
      'tokenCount': tokenCount,
      'tokenBudget': tokenBudget,
      if (relevanceScores.isNotEmpty) 'relevanceScores': relevanceScores,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'strategy': strategy.name,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  ContextBundle copyWith({
    String? bundleId,
    ContextPurpose? purpose,
    String? query,
    List<String>? eventIds,
    List<String>? entityIds,
    List<String>? summaryIds,
    List<ContextSegment>? segments,
    int? tokenCount,
    int? tokenBudget,
    Map<String, double>? relevanceScores,
    DateTime? createdAt,
    DateTime? expiresAt,
    SelectionStrategy? strategy,
    Map<String, dynamic>? metadata,
  }) {
    return ContextBundle(
      bundleId: bundleId ?? this.bundleId,
      purpose: purpose ?? this.purpose,
      query: query ?? this.query,
      eventIds: eventIds ?? this.eventIds,
      entityIds: entityIds ?? this.entityIds,
      summaryIds: summaryIds ?? this.summaryIds,
      segments: segments ?? this.segments,
      tokenCount: tokenCount ?? this.tokenCount,
      tokenBudget: tokenBudget ?? this.tokenBudget,
      relevanceScores: relevanceScores ?? this.relevanceScores,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      strategy: strategy ?? this.strategy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if bundle is within token budget.
  bool get isWithinBudget => tokenCount <= tokenBudget;

  /// Remaining token capacity.
  int get remainingTokens => tokenBudget - tokenCount;

  /// Check if bundle has expired.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  String toString() =>
      'ContextBundle($bundleId, purpose: $purpose, tokens: $tokenCount/$tokenBudget)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextBundle && bundleId == other.bundleId;

  @override
  int get hashCode => bundleId.hashCode;
}

/// Context purpose types.
enum ContextPurpose {
  /// Query answering.
  query,

  /// Summarization.
  summarization,

  /// Generation task.
  generation,

  /// Validation task.
  validation,

  /// Analysis task.
  analysis,

  /// Conversation context.
  conversation;

  static ContextPurpose fromString(String value) {
    return ContextPurpose.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContextPurpose.query,
    );
  }
}

/// Context selection strategies.
enum SelectionStrategy {
  /// Select by relevance score.
  relevance,

  /// Select most recent first.
  recency,

  /// Balanced relevance and recency.
  balanced,

  /// Diverse selection across topics.
  diversity,

  /// Manual/explicit selection.
  manual;

  static SelectionStrategy fromString(String value) {
    return SelectionStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SelectionStrategy.relevance,
    );
  }
}

/// A segment of context content.
class ContextSegment {
  /// Segment type.
  final SegmentType type;

  /// Source reference (event/entity/summary ID).
  final String sourceId;

  /// Segment content.
  final String content;

  /// Token count for this segment.
  final int tokenCount;

  /// Relevance score.
  final double relevance;

  /// Position/order in context.
  final int position;

  const ContextSegment({
    required this.type,
    required this.sourceId,
    required this.content,
    this.tokenCount = 0,
    this.relevance = 0.0,
    this.position = 0,
  });

  factory ContextSegment.fromJson(Map<String, dynamic> json) {
    return ContextSegment(
      type: SegmentType.fromString(json['type'] as String? ?? 'fact'),
      sourceId: json['sourceId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tokenCount: json['tokenCount'] as int? ?? 0,
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sourceId': sourceId,
      'content': content,
      'tokenCount': tokenCount,
      'relevance': relevance,
      'position': position,
    };
  }
}

/// Context segment types.
enum SegmentType {
  /// Fact/event content.
  fact,

  /// Entity description.
  entity,

  /// Summary content.
  summary,

  /// System instruction.
  instruction,

  /// Example content.
  example,

  /// User query/prompt.
  query;

  static SegmentType fromString(String value) {
    return SegmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SegmentType.fact,
    );
  }
}
