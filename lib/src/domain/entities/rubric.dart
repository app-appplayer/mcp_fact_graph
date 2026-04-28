/// Rubric entity for L3 SkillOps Layer.
///
/// Represents evaluation rubrics for assessing skill outputs.
/// Reference: 03-data-model-specification.md Section 2.16.4
library;

/// Rubric represents evaluation criteria for skills.
///
/// Rubrics define how skill outputs should be evaluated.
class Rubric {
  /// Unique rubric identifier.
  final String rubricId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Rubric name.
  final String name;

  /// Rubric description.
  final String description;

  /// Rubric version.
  final String version;

  /// Evaluation dimensions.
  final List<RubricDimension> dimensions;

  /// Dimension weights (dimensionId -> weight, sum = 1.0).
  /// Reference: Design Section 2.16.4 - weights.
  final Map<String, double> weights;

  /// Pass/fail/grade boundaries.
  /// Reference: Design Section 2.16.4 - thresholds.
  final Map<String, dynamic> thresholds;

  /// Policy binding reference (policy ID string).
  /// Reference: Design Section 2.16.4 - policyBinding.
  final String? policyBinding;

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
    required this.workspaceId,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.dimensions = const [],
    this.weights = const {},
    this.thresholds = const {},
    this.policyBinding,
    this.status = RubricStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory Rubric.fromJson(Map<String, dynamic> json) {
    return Rubric(
      rubricId: json['rubricId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      dimensions: (json['dimensions'] as List<dynamic>?)
              ?.map((e) => RubricDimension.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weights: (json['weights'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      thresholds: json['thresholds'] as Map<String, dynamic>? ?? {},
      policyBinding: json['policyBinding'] as String?,
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
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'version': version,
      if (dimensions.isNotEmpty)
        'dimensions': dimensions.map((d) => d.toJson()).toList(),
      if (weights.isNotEmpty) 'weights': weights,
      if (thresholds.isNotEmpty) 'thresholds': thresholds,
      if (policyBinding != null) 'policyBinding': policyBinding,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Rubric copyWith({
    String? rubricId,
    String? workspaceId,
    String? name,
    String? description,
    String? version,
    List<RubricDimension>? dimensions,
    Map<String, double>? weights,
    Map<String, dynamic>? thresholds,
    String? policyBinding,
    RubricStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Rubric(
      rubricId: rubricId ?? this.rubricId,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      dimensions: dimensions ?? this.dimensions,
      weights: weights ?? this.weights,
      thresholds: thresholds ?? this.thresholds,
      policyBinding: policyBinding ?? this.policyBinding,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if rubric is active.
  bool get isActive => status == RubricStatus.active;

  /// Check if rubric has dimensions defined.
  bool get hasDimensions => dimensions.isNotEmpty;

  /// Get dimension by ID.
  RubricDimension? getDimension(String dimensionId) {
    try {
      return dimensions.firstWhere((d) => d.dimensionId == dimensionId);
    } catch (_) {
      return null;
    }
  }

  /// Get dimensions for a specific measurement type.
  List<RubricDimension> dimensionsByMeasurementType(MeasurementType type) {
    return dimensions.where((d) => d.measurementType == type).toList();
  }

  @override
  String toString() => 'Rubric($rubricId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Rubric && rubricId == other.rubricId;

  @override
  int get hashCode => rubricId.hashCode;
}

/// Rubric status.
/// Reference: Design Section 2.16.4 - draft | active | deprecated
enum RubricStatus {
  /// Under development.
  draft,

  /// Active rubric.
  active,

  /// No longer recommended for use.
  deprecated;

  static RubricStatus fromString(String value) {
    return RubricStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RubricStatus.active,
    );
  }
}

/// Evaluation dimension within a rubric.
/// Reference: Design Section 2.16.4 - RubricDimension with measurementMethod.
class RubricDimension {
  /// Dimension identifier.
  final String dimensionId;

  /// Dimension name.
  final String name;

  /// Dimension description.
  final String description;

  /// How to measure this dimension.
  final String measurementMethod;

  /// Measurement type.
  final MeasurementType measurementType;

  /// Minimum possible score.
  final double minScore;

  /// Maximum possible score.
  final double maxScore;

  /// Score levels (grade descriptions).
  final List<ScoreLevel> levels;

  /// Evidence types needed for this dimension.
  final List<String> evidenceTypes;

  const RubricDimension({
    required this.dimensionId,
    required this.name,
    required this.description,
    this.measurementMethod = '',
    this.measurementType = MeasurementType.numeric,
    this.minScore = 0.0,
    this.maxScore = 1.0,
    this.levels = const [],
    this.evidenceTypes = const [],
  });

  factory RubricDimension.fromJson(Map<String, dynamic> json) {
    return RubricDimension(
      dimensionId: json['dimensionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      measurementMethod: json['measurementMethod'] as String? ?? '',
      measurementType: MeasurementType.fromString(
          json['measurementType'] as String? ?? 'numeric'),
      minScore: (json['minScore'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 1.0,
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => ScoreLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evidenceTypes: (json['evidenceTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimensionId': dimensionId,
      'name': name,
      'description': description,
      if (measurementMethod.isNotEmpty) 'measurementMethod': measurementMethod,
      'measurementType': measurementType.name,
      'minScore': minScore,
      'maxScore': maxScore,
      if (levels.isNotEmpty) 'levels': levels.map((l) => l.toJson()).toList(),
      if (evidenceTypes.isNotEmpty) 'evidenceTypes': evidenceTypes,
    };
  }
}

/// Measurement types for dimensions.
/// Reference: Design Section 2.16.4
enum MeasurementType {
  /// Numeric measurement.
  numeric,

  /// Categorical measurement.
  categorical,

  /// Boolean measurement.
  boolean;

  static MeasurementType fromString(String value) {
    return MeasurementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MeasurementType.numeric,
    );
  }
}

/// Score level definition.
/// Reference: Design Section 2.16.4 - score range with min/max.
class ScoreLevel {
  /// Level label (e.g., "Excellent", "Good", "Needs Improvement").
  final String label;

  /// Minimum score for this level.
  final double minScore;

  /// Maximum score for this level.
  final double maxScore;

  /// Level description.
  final String description;

  /// Observable indicators for this level.
  final List<String> indicators;

  const ScoreLevel({
    required this.label,
    required this.minScore,
    required this.maxScore,
    required this.description,
    this.indicators = const [],
  });

  factory ScoreLevel.fromJson(Map<String, dynamic> json) {
    return ScoreLevel(
      label: json['label'] as String? ?? '',
      minScore: (json['minScore'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 1.0,
      description: json['description'] as String? ?? '',
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'minScore': minScore,
      'maxScore': maxScore,
      'description': description,
      if (indicators.isNotEmpty) 'indicators': indicators,
    };
  }
}
