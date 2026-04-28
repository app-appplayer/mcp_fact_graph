/// EvaluationRun entity for L3 SkillOps Layer.
///
/// Represents a deterministic evaluation execution record.
/// Reference: 03-data-model-specification.md Section 2.16.5
library;

/// EvaluationRun represents a deterministic evaluation execution.
///
/// Records the results of evaluating against a rubric with full
/// reproducibility (same inputs + versions = same outputs).
class EvaluationRun {
  /// Unique evaluation run identifier.
  final String evaluationId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Rubric ID used for evaluation.
  final String rubricId;

  /// Rubric version used for evaluation.
  /// Reference: Design Section 2.16.5 - reproducibility.
  final String rubricVersion;

  /// Policy version used for evaluation context.
  /// Reference: Design Section 2.16.5 - reproducibility.
  final String policyVersion;

  /// Point-in-time snapshot for reproducibility.
  /// Reference: Design Section 2.16.5 - time-travel queries.
  final DateTime asOf;

  /// Time period this evaluation covers.
  /// Reference: Design Section 2.16.5 - periodic evaluations.
  final Period? period;

  /// Complete input snapshot.
  /// Reference: Design Section 2.16.5 - EvaluationInput.
  final EvaluationInput input;

  /// Complete output snapshot.
  /// Reference: Design Section 2.16.5 - EvaluationOutput.
  final EvaluationOutput output;

  /// Idempotency key for deduplication.
  /// Reference: Design Section 2.16.5 - idempotent operations.
  final String idempotencyKey;

  /// Evaluation status.
  final EvaluationStatus status;

  /// When this evaluation was created.
  final DateTime createdAt;

  /// When evaluation completed.
  final DateTime? completedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EvaluationRun({
    required this.evaluationId,
    required this.workspaceId,
    required this.rubricId,
    required this.rubricVersion,
    required this.policyVersion,
    required this.asOf,
    this.period,
    this.input = const EvaluationInput(targetType: ''),
    this.output = const EvaluationOutput(),
    this.idempotencyKey = '',
    this.status = EvaluationStatus.running,
    required this.createdAt,
    this.completedAt,
    this.metadata = const {},
  });

  factory EvaluationRun.fromJson(Map<String, dynamic> json) {
    return EvaluationRun(
      evaluationId: json['evaluationId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      rubricId: json['rubricId'] as String? ?? '',
      rubricVersion: json['rubricVersion'] as String? ?? '1.0.0',
      policyVersion: json['policyVersion'] as String? ?? '1.0.0',
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      input: json['input'] != null
          ? EvaluationInput.fromJson(json['input'] as Map<String, dynamic>)
          : const EvaluationInput(targetType: ''),
      output: json['output'] != null
          ? EvaluationOutput.fromJson(json['output'] as Map<String, dynamic>)
          : const EvaluationOutput(),
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      status: EvaluationStatus.fromString(
          json['status'] as String? ?? 'running'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evaluationId': evaluationId,
      'workspaceId': workspaceId,
      'rubricId': rubricId,
      'rubricVersion': rubricVersion,
      'policyVersion': policyVersion,
      'asOf': asOf.toIso8601String(),
      if (period != null) 'period': period!.toJson(),
      'input': input.toJson(),
      'output': output.toJson(),
      if (idempotencyKey.isNotEmpty) 'idempotencyKey': idempotencyKey,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  EvaluationRun copyWith({
    String? evaluationId,
    String? workspaceId,
    String? rubricId,
    String? rubricVersion,
    String? policyVersion,
    DateTime? asOf,
    Period? period,
    EvaluationInput? input,
    EvaluationOutput? output,
    String? idempotencyKey,
    EvaluationStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EvaluationRun(
      evaluationId: evaluationId ?? this.evaluationId,
      workspaceId: workspaceId ?? this.workspaceId,
      rubricId: rubricId ?? this.rubricId,
      rubricVersion: rubricVersion ?? this.rubricVersion,
      policyVersion: policyVersion ?? this.policyVersion,
      asOf: asOf ?? this.asOf,
      period: period ?? this.period,
      input: input ?? this.input,
      output: output ?? this.output,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if evaluation is complete.
  bool get isComplete => status == EvaluationStatus.completed;

  @override
  String toString() =>
      'EvaluationRun($evaluationId, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationRun && evaluationId == other.evaluationId;

  @override
  int get hashCode => evaluationId.hashCode;
}

/// Evaluation status.
/// Reference: Design Section 2.16.5 - running | completed | failed
enum EvaluationStatus {
  /// Running.
  running,

  /// Completed.
  completed,

  /// Failed (error during evaluation).
  failed;

  static EvaluationStatus fromString(String value) {
    return EvaluationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvaluationStatus.running,
    );
  }
}

/// Simple period for evaluation time range.
/// Reference: Design Section 2.16.5 - Period.
class Period {
  /// Period start time.
  final DateTime start;

  /// Period end time.
  final DateTime end;

  const Period({
    required this.start,
    required this.end,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
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

/// Typed evaluation input snapshot.
/// Reference: Design Section 2.16.5 - EvaluationInput.
class EvaluationInput {
  /// Target type (fact, candidate, entity, period, skill_run).
  final String targetType;

  /// Specific target ID.
  final String? targetId;

  /// Fact IDs included.
  final List<String> factIds;

  /// View IDs included.
  final List<String> viewIds;

  /// Additional parameters.
  final Map<String, dynamic> params;

  const EvaluationInput({
    required this.targetType,
    this.targetId,
    this.factIds = const [],
    this.viewIds = const [],
    this.params = const {},
  });

  factory EvaluationInput.fromJson(Map<String, dynamic> json) {
    return EvaluationInput(
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String?,
      factIds: (json['factIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      viewIds: (json['viewIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      if (targetId != null) 'targetId': targetId,
      if (factIds.isNotEmpty) 'factIds': factIds,
      if (viewIds.isNotEmpty) 'viewIds': viewIds,
      if (params.isNotEmpty) 'params': params,
    };
  }
}

/// Typed evaluation output snapshot.
/// Reference: Design Section 2.16.5 - EvaluationOutput.
class EvaluationOutput {
  /// Per-dimension scores.
  final Map<String, double> dimensionScores;

  /// Weighted total score.
  final double totalScore;

  /// Grade label (A, B, C, etc.).
  final String grade;

  /// Detailed findings.
  final List<Finding> findings;

  /// Supporting evidence references.
  final List<String> evidenceRefs;

  /// Additional metrics.
  final Map<String, dynamic> metrics;

  const EvaluationOutput({
    this.dimensionScores = const {},
    this.totalScore = 0.0,
    this.grade = '',
    this.findings = const [],
    this.evidenceRefs = const [],
    this.metrics = const {},
  });

  factory EvaluationOutput.fromJson(Map<String, dynamic> json) {
    return EvaluationOutput(
      dimensionScores: (json['dimensionScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade'] as String? ?? '',
      findings: (json['findings'] as List<dynamic>?)
              ?.map((e) => Finding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dimensionScores.isNotEmpty) 'dimensionScores': dimensionScores,
      'totalScore': totalScore,
      'grade': grade,
      if (findings.isNotEmpty)
        'findings': findings.map((f) => f.toJson()).toList(),
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      if (metrics.isNotEmpty) 'metrics': metrics,
    };
  }
}

/// Detailed finding from evaluation.
/// Reference: Design Section 2.16.5 - Finding.
class Finding {
  /// Unique identifier.
  final String findingId;

  /// Finding type.
  final FindingType findingType;

  /// Related dimension ID.
  final String dimensionId;

  /// Finding description.
  final String description;

  /// Evidence references supporting this finding.
  final List<String> supportingRefs;

  /// Impact on score (optional).
  final double? impact;

  const Finding({
    required this.findingId,
    required this.findingType,
    required this.dimensionId,
    required this.description,
    this.supportingRefs = const [],
    this.impact,
  });

  factory Finding.fromJson(Map<String, dynamic> json) {
    return Finding(
      findingId: json['findingId'] as String? ?? '',
      findingType:
          FindingType.fromString(json['findingType'] as String? ?? 'observation'),
      dimensionId: json['dimensionId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      supportingRefs: (json['supportingRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      impact: (json['impact'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'findingId': findingId,
      'findingType': findingType.name,
      'dimensionId': dimensionId,
      'description': description,
      if (supportingRefs.isNotEmpty) 'supportingRefs': supportingRefs,
      if (impact != null) 'impact': impact,
    };
  }
}

/// Finding types.
/// Reference: Design Section 2.16.5.
enum FindingType {
  /// Positive aspect.
  strength,

  /// Area needing improvement.
  weakness,

  /// Neutral observation.
  observation,

  /// Suggested action.
  recommendation;

  static FindingType fromString(String value) {
    return FindingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FindingType.observation,
    );
  }
}
