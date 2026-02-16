/// Pattern entity for L3 SkillOps Layer.
///
/// Represents recurring patterns discovered in the fact graph.
library;

/// Pattern represents a discovered recurring pattern.
///
/// Patterns emerge from analyzing events and can trigger skills.
class Pattern {
  /// Unique pattern identifier.
  final String patternId;

  /// Pattern name.
  final String name;

  /// Pattern description.
  final String description;

  /// Pattern type/category.
  final PatternType patternType;

  /// Pattern matching criteria.
  final PatternCriteria criteria;

  /// Frequency of occurrence.
  final PatternFrequency frequency;

  /// Example event IDs that match this pattern.
  final List<String> exampleEventIds;

  /// Associated entity types.
  final List<String> entityTypes;

  /// Confidence score for pattern validity.
  final double confidence;

  /// Number of matches found.
  final int matchCount;

  /// First observed date.
  final DateTime firstObserved;

  /// Last observed date.
  final DateTime lastObserved;

  /// Pattern status.
  final PatternStatus status;

  /// Associated skill IDs that can be triggered.
  final List<String> triggerSkillIds;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Pattern({
    required this.patternId,
    required this.name,
    required this.description,
    required this.patternType,
    required this.criteria,
    this.frequency = const PatternFrequency(),
    this.exampleEventIds = const [],
    this.entityTypes = const [],
    this.confidence = 0.0,
    this.matchCount = 0,
    required this.firstObserved,
    required this.lastObserved,
    this.status = PatternStatus.active,
    this.triggerSkillIds = const [],
    this.metadata = const {},
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      patternId: json['patternId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      patternType:
          PatternType.fromString(json['patternType'] as String? ?? 'recurring'),
      criteria: PatternCriteria.fromJson(
          json['criteria'] as Map<String, dynamic>? ?? {}),
      frequency: json['frequency'] != null
          ? PatternFrequency.fromJson(json['frequency'] as Map<String, dynamic>)
          : const PatternFrequency(),
      exampleEventIds: (json['exampleEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entityTypes: (json['entityTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      matchCount: json['matchCount'] as int? ?? 0,
      firstObserved: json['firstObserved'] != null
          ? DateTime.parse(json['firstObserved'] as String)
          : DateTime.now(),
      lastObserved: json['lastObserved'] != null
          ? DateTime.parse(json['lastObserved'] as String)
          : DateTime.now(),
      status:
          PatternStatus.fromString(json['status'] as String? ?? 'active'),
      triggerSkillIds: (json['triggerSkillIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'name': name,
      'description': description,
      'patternType': patternType.name,
      'criteria': criteria.toJson(),
      'frequency': frequency.toJson(),
      if (exampleEventIds.isNotEmpty) 'exampleEventIds': exampleEventIds,
      if (entityTypes.isNotEmpty) 'entityTypes': entityTypes,
      'confidence': confidence,
      'matchCount': matchCount,
      'firstObserved': firstObserved.toIso8601String(),
      'lastObserved': lastObserved.toIso8601String(),
      'status': status.name,
      if (triggerSkillIds.isNotEmpty) 'triggerSkillIds': triggerSkillIds,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Pattern copyWith({
    String? patternId,
    String? name,
    String? description,
    PatternType? patternType,
    PatternCriteria? criteria,
    PatternFrequency? frequency,
    List<String>? exampleEventIds,
    List<String>? entityTypes,
    double? confidence,
    int? matchCount,
    DateTime? firstObserved,
    DateTime? lastObserved,
    PatternStatus? status,
    List<String>? triggerSkillIds,
    Map<String, dynamic>? metadata,
  }) {
    return Pattern(
      patternId: patternId ?? this.patternId,
      name: name ?? this.name,
      description: description ?? this.description,
      patternType: patternType ?? this.patternType,
      criteria: criteria ?? this.criteria,
      frequency: frequency ?? this.frequency,
      exampleEventIds: exampleEventIds ?? this.exampleEventIds,
      entityTypes: entityTypes ?? this.entityTypes,
      confidence: confidence ?? this.confidence,
      matchCount: matchCount ?? this.matchCount,
      firstObserved: firstObserved ?? this.firstObserved,
      lastObserved: lastObserved ?? this.lastObserved,
      status: status ?? this.status,
      triggerSkillIds: triggerSkillIds ?? this.triggerSkillIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if pattern has enough evidence.
  bool get hasEnoughEvidence => matchCount >= 3 && confidence >= 0.7;

  /// Duration since first observed.
  Duration get observationSpan => lastObserved.difference(firstObserved);

  @override
  String toString() => 'Pattern($patternId, name: $name, type: $patternType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pattern && patternId == other.patternId;

  @override
  int get hashCode => patternId.hashCode;
}

/// Pattern types.
enum PatternType {
  /// Recurring event pattern.
  recurring,

  /// Sequential pattern (A then B).
  sequential,

  /// Co-occurrence pattern.
  coOccurrence,

  /// Anomaly pattern.
  anomaly,

  /// Trend pattern.
  trend,

  /// Seasonal pattern.
  seasonal,

  /// Behavioral pattern.
  behavioral;

  static PatternType fromString(String value) {
    return PatternType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PatternType.recurring,
    );
  }
}

/// Pattern status.
enum PatternStatus {
  /// Active pattern.
  active,

  /// Under evaluation.
  evaluating,

  /// Confirmed valid.
  confirmed,

  /// Deprecated/invalid.
  deprecated,

  /// Archived.
  archived;

  static PatternStatus fromString(String value) {
    return PatternStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PatternStatus.active,
    );
  }
}

/// Pattern matching criteria.
class PatternCriteria {
  /// Event types to match.
  final List<String> eventTypes;

  /// Entity types to match.
  final List<String> entityTypes;

  /// Required field conditions.
  final List<FieldCondition> conditions;

  /// Time window for pattern matching.
  final Duration? timeWindow;

  /// Minimum occurrences required.
  final int minOccurrences;

  /// Custom matching expression.
  final String? expression;

  const PatternCriteria({
    this.eventTypes = const [],
    this.entityTypes = const [],
    this.conditions = const [],
    this.timeWindow,
    this.minOccurrences = 1,
    this.expression,
  });

  factory PatternCriteria.fromJson(Map<String, dynamic> json) {
    return PatternCriteria(
      eventTypes: (json['eventTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entityTypes: (json['entityTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => FieldCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeWindow: json['timeWindowMs'] != null
          ? Duration(milliseconds: json['timeWindowMs'] as int)
          : null,
      minOccurrences: json['minOccurrences'] as int? ?? 1,
      expression: json['expression'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (eventTypes.isNotEmpty) 'eventTypes': eventTypes,
      if (entityTypes.isNotEmpty) 'entityTypes': entityTypes,
      if (conditions.isNotEmpty)
        'conditions': conditions.map((c) => c.toJson()).toList(),
      if (timeWindow != null) 'timeWindowMs': timeWindow!.inMilliseconds,
      'minOccurrences': minOccurrences,
      if (expression != null) 'expression': expression,
    };
  }
}

/// Field condition for pattern matching.
class FieldCondition {
  /// Field path.
  final String field;

  /// Comparison operator.
  final ConditionOperator operator;

  /// Value to compare.
  final dynamic value;

  const FieldCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    return FieldCondition(
      field: json['field'] as String? ?? '',
      operator: ConditionOperator.fromString(
          json['operator'] as String? ?? 'equals'),
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator.name,
      'value': value,
    };
  }
}

/// Condition operators.
enum ConditionOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  contains,
  startsWith,
  endsWith,
  matches,
  exists,
  notExists;

  static ConditionOperator fromString(String value) {
    return ConditionOperator.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConditionOperator.equals,
    );
  }
}

/// Pattern frequency statistics.
class PatternFrequency {
  /// Total occurrences.
  final int total;

  /// Daily average.
  final double dailyAverage;

  /// Weekly average.
  final double weeklyAverage;

  /// Monthly average.
  final double monthlyAverage;

  /// Trend direction.
  final TrendDirection trend;

  const PatternFrequency({
    this.total = 0,
    this.dailyAverage = 0.0,
    this.weeklyAverage = 0.0,
    this.monthlyAverage = 0.0,
    this.trend = TrendDirection.stable,
  });

  factory PatternFrequency.fromJson(Map<String, dynamic> json) {
    return PatternFrequency(
      total: json['total'] as int? ?? 0,
      dailyAverage: (json['dailyAverage'] as num?)?.toDouble() ?? 0.0,
      weeklyAverage: (json['weeklyAverage'] as num?)?.toDouble() ?? 0.0,
      monthlyAverage: (json['monthlyAverage'] as num?)?.toDouble() ?? 0.0,
      trend:
          TrendDirection.fromString(json['trend'] as String? ?? 'stable'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'dailyAverage': dailyAverage,
      'weeklyAverage': weeklyAverage,
      'monthlyAverage': monthlyAverage,
      'trend': trend.name,
    };
  }
}

/// Trend directions.
enum TrendDirection {
  increasing,
  decreasing,
  stable,
  volatile;

  static TrendDirection fromString(String value) {
    return TrendDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrendDirection.stable,
    );
  }
}
