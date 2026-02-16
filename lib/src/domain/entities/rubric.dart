/// Rubric entity for L3 SkillOps Layer.
///
/// Represents evaluation rubrics for assessing skill outputs.
library;

/// Rubric represents evaluation criteria for skills.
///
/// Rubrics define how skill outputs should be evaluated.
class Rubric {
  /// Unique rubric identifier.
  final String rubricId;

  /// Rubric name.
  final String name;

  /// Rubric description.
  final String description;

  /// Rubric version.
  final String version;

  /// Evaluation dimensions.
  final List<RubricDimension> dimensions;

  /// Overall passing threshold (0.0-1.0).
  final double passingThreshold;

  /// Weighting strategy for dimensions.
  final WeightingStrategy weightingStrategy;

  /// Target skill IDs this rubric applies to.
  final List<String> targetSkillIds;

  /// Rubric status.
  final RubricStatus status;

  /// When rubric was created.
  final DateTime createdAt;

  /// When rubric was last updated.
  final DateTime updatedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Rubric({
    required this.rubricId,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.dimensions = const [],
    this.passingThreshold = 0.7,
    this.weightingStrategy = WeightingStrategy.equal,
    this.targetSkillIds = const [],
    this.status = RubricStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory Rubric.fromJson(Map<String, dynamic> json) {
    return Rubric(
      rubricId: json['rubricId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      dimensions: (json['dimensions'] as List<dynamic>?)
              ?.map((e) => RubricDimension.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      passingThreshold: (json['passingThreshold'] as num?)?.toDouble() ?? 0.7,
      weightingStrategy: WeightingStrategy.fromString(
          json['weightingStrategy'] as String? ?? 'equal'),
      targetSkillIds: (json['targetSkillIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: RubricStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rubricId': rubricId,
      'name': name,
      'description': description,
      'version': version,
      if (dimensions.isNotEmpty)
        'dimensions': dimensions.map((d) => d.toJson()).toList(),
      'passingThreshold': passingThreshold,
      'weightingStrategy': weightingStrategy.name,
      if (targetSkillIds.isNotEmpty) 'targetSkillIds': targetSkillIds,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Rubric copyWith({
    String? rubricId,
    String? name,
    String? description,
    String? version,
    List<RubricDimension>? dimensions,
    double? passingThreshold,
    WeightingStrategy? weightingStrategy,
    List<String>? targetSkillIds,
    RubricStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Rubric(
      rubricId: rubricId ?? this.rubricId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      dimensions: dimensions ?? this.dimensions,
      passingThreshold: passingThreshold ?? this.passingThreshold,
      weightingStrategy: weightingStrategy ?? this.weightingStrategy,
      targetSkillIds: targetSkillIds ?? this.targetSkillIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Total weight of all dimensions.
  double get totalWeight =>
      dimensions.fold(0.0, (sum, d) => sum + d.weight);

  @override
  String toString() => 'Rubric($rubricId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Rubric && rubricId == other.rubricId;

  @override
  int get hashCode => rubricId.hashCode;
}

/// Rubric status.
enum RubricStatus {
  /// Active rubric.
  active,

  /// Under development.
  draft,

  /// Disabled.
  disabled,

  /// Archived.
  archived;

  static RubricStatus fromString(String value) {
    return RubricStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RubricStatus.active,
    );
  }
}

/// Weighting strategies for dimension scores.
enum WeightingStrategy {
  /// Equal weight for all dimensions.
  equal,

  /// Custom weights per dimension.
  custom,

  /// Weight by importance ranking.
  ranked,

  /// Minimum of all dimensions.
  minimum;

  static WeightingStrategy fromString(String value) {
    return WeightingStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WeightingStrategy.equal,
    );
  }
}

/// Evaluation dimension within a rubric.
class RubricDimension {
  /// Dimension identifier.
  final String dimensionId;

  /// Dimension name.
  final String name;

  /// Dimension description.
  final String description;

  /// Weight (0.0-1.0 or custom).
  final double weight;

  /// Score levels.
  final List<ScoreLevel> levels;

  /// Evaluation type.
  final EvaluationType evaluationType;

  /// Whether this dimension is required.
  final bool required;

  const RubricDimension({
    required this.dimensionId,
    required this.name,
    required this.description,
    this.weight = 1.0,
    this.levels = const [],
    this.evaluationType = EvaluationType.manual,
    this.required = true,
  });

  factory RubricDimension.fromJson(Map<String, dynamic> json) {
    return RubricDimension(
      dimensionId: json['dimensionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => ScoreLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evaluationType: EvaluationType.fromString(
          json['evaluationType'] as String? ?? 'manual'),
      required: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimensionId': dimensionId,
      'name': name,
      'description': description,
      'weight': weight,
      if (levels.isNotEmpty) 'levels': levels.map((l) => l.toJson()).toList(),
      'evaluationType': evaluationType.name,
      'required': required,
    };
  }
}

/// Evaluation types.
enum EvaluationType {
  /// Manual evaluation.
  manual,

  /// Automated evaluation.
  automated,

  /// LLM-based evaluation.
  llmBased,

  /// Rule-based evaluation.
  ruleBased,

  /// Hybrid evaluation.
  hybrid;

  static EvaluationType fromString(String value) {
    return EvaluationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvaluationType.manual,
    );
  }
}

/// Score level definition.
class ScoreLevel {
  /// Numeric score (0.0-1.0).
  final double score;

  /// Level label.
  final String label;

  /// Level description.
  final String description;

  /// Example indicators.
  final List<String> indicators;

  const ScoreLevel({
    required this.score,
    required this.label,
    required this.description,
    this.indicators = const [],
  });

  factory ScoreLevel.fromJson(Map<String, dynamic> json) {
    return ScoreLevel(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'label': label,
      'description': description,
      if (indicators.isNotEmpty) 'indicators': indicators,
    };
  }
}
