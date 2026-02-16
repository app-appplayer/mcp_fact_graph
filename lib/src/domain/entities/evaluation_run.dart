/// EvaluationRun entity for L3 SkillOps Layer.
///
/// Represents a single evaluation execution using a rubric.
library;

/// EvaluationRun represents a completed evaluation.
///
/// Records the results of evaluating skill output against a rubric.
class EvaluationRun {
  /// Unique evaluation run identifier.
  final String runId;

  /// Rubric ID used for evaluation.
  final String rubricId;

  /// Skill ID being evaluated.
  final String skillId;

  /// Skill execution ID.
  final String executionId;

  /// Input data for the skill.
  final Map<String, dynamic> input;

  /// Output data from the skill.
  final Map<String, dynamic> output;

  /// Dimension scores.
  final List<DimensionScore> dimensionScores;

  /// Overall score (0.0-1.0).
  final double overallScore;

  /// Whether evaluation passed.
  final bool passed;

  /// Evaluation status.
  final EvaluationStatus status;

  /// Evaluator (human ID or 'automated').
  final String evaluator;

  /// When evaluation started.
  final DateTime startedAt;

  /// When evaluation completed.
  final DateTime? completedAt;

  /// Duration in milliseconds.
  final int? durationMs;

  /// Feedback/comments.
  final String? feedback;

  /// Issues found during evaluation.
  final List<EvaluationIssue> issues;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EvaluationRun({
    required this.runId,
    required this.rubricId,
    required this.skillId,
    required this.executionId,
    this.input = const {},
    this.output = const {},
    this.dimensionScores = const [],
    this.overallScore = 0.0,
    this.passed = false,
    this.status = EvaluationStatus.pending,
    required this.evaluator,
    required this.startedAt,
    this.completedAt,
    this.durationMs,
    this.feedback,
    this.issues = const [],
    this.metadata = const {},
  });

  factory EvaluationRun.fromJson(Map<String, dynamic> json) {
    return EvaluationRun(
      runId: json['runId'] as String? ?? '',
      rubricId: json['rubricId'] as String? ?? '',
      skillId: json['skillId'] as String? ?? '',
      executionId: json['executionId'] as String? ?? '',
      input: json['input'] as Map<String, dynamic>? ?? {},
      output: json['output'] as Map<String, dynamic>? ?? {},
      dimensionScores: (json['dimensionScores'] as List<dynamic>?)
              ?.map((e) => DimensionScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      status: EvaluationStatus.fromString(
          json['status'] as String? ?? 'pending'),
      evaluator: json['evaluator'] as String? ?? 'unknown',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      durationMs: json['durationMs'] as int?,
      feedback: json['feedback'] as String?,
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => EvaluationIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runId': runId,
      'rubricId': rubricId,
      'skillId': skillId,
      'executionId': executionId,
      if (input.isNotEmpty) 'input': input,
      if (output.isNotEmpty) 'output': output,
      if (dimensionScores.isNotEmpty)
        'dimensionScores': dimensionScores.map((d) => d.toJson()).toList(),
      'overallScore': overallScore,
      'passed': passed,
      'status': status.name,
      'evaluator': evaluator,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (durationMs != null) 'durationMs': durationMs,
      if (feedback != null) 'feedback': feedback,
      if (issues.isNotEmpty) 'issues': issues.map((i) => i.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  EvaluationRun copyWith({
    String? runId,
    String? rubricId,
    String? skillId,
    String? executionId,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    List<DimensionScore>? dimensionScores,
    double? overallScore,
    bool? passed,
    EvaluationStatus? status,
    String? evaluator,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMs,
    String? feedback,
    List<EvaluationIssue>? issues,
    Map<String, dynamic>? metadata,
  }) {
    return EvaluationRun(
      runId: runId ?? this.runId,
      rubricId: rubricId ?? this.rubricId,
      skillId: skillId ?? this.skillId,
      executionId: executionId ?? this.executionId,
      input: input ?? this.input,
      output: output ?? this.output,
      dimensionScores: dimensionScores ?? this.dimensionScores,
      overallScore: overallScore ?? this.overallScore,
      passed: passed ?? this.passed,
      status: status ?? this.status,
      evaluator: evaluator ?? this.evaluator,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMs: durationMs ?? this.durationMs,
      feedback: feedback ?? this.feedback,
      issues: issues ?? this.issues,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if evaluation is complete.
  bool get isComplete => status == EvaluationStatus.completed;

  /// Check if evaluation has critical issues.
  bool get hasCriticalIssues =>
      issues.any((i) => i.severity == IssueSeverity.critical);

  @override
  String toString() =>
      'EvaluationRun($runId, score: $overallScore, passed: $passed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationRun && runId == other.runId;

  @override
  int get hashCode => runId.hashCode;
}

/// Evaluation status.
enum EvaluationStatus {
  /// Pending evaluation.
  pending,

  /// In progress.
  inProgress,

  /// Completed.
  completed,

  /// Failed (error during evaluation).
  failed,

  /// Cancelled.
  cancelled;

  static EvaluationStatus fromString(String value) {
    return EvaluationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvaluationStatus.pending,
    );
  }
}

/// Score for a single dimension.
class DimensionScore {
  /// Dimension ID.
  final String dimensionId;

  /// Dimension name.
  final String dimensionName;

  /// Score (0.0-1.0).
  final double score;

  /// Weight applied.
  final double weight;

  /// Weighted score.
  final double weightedScore;

  /// Justification for the score.
  final String? justification;

  /// Evidence supporting the score.
  final List<String> evidence;

  const DimensionScore({
    required this.dimensionId,
    required this.dimensionName,
    required this.score,
    this.weight = 1.0,
    double? weightedScore,
    this.justification,
    this.evidence = const [],
  }) : weightedScore = weightedScore ?? score * weight;

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num?)?.toDouble() ?? 0.0;
    final weight = (json['weight'] as num?)?.toDouble() ?? 1.0;
    return DimensionScore(
      dimensionId: json['dimensionId'] as String? ?? '',
      dimensionName: json['dimensionName'] as String? ?? '',
      score: score,
      weight: weight,
      weightedScore: (json['weightedScore'] as num?)?.toDouble() ?? score * weight,
      justification: json['justification'] as String?,
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimensionId': dimensionId,
      'dimensionName': dimensionName,
      'score': score,
      'weight': weight,
      'weightedScore': weightedScore,
      if (justification != null) 'justification': justification,
      if (evidence.isNotEmpty) 'evidence': evidence,
    };
  }
}

/// Issue found during evaluation.
class EvaluationIssue {
  /// Issue type.
  final EvalIssueType issueType;

  /// Issue severity.
  final IssueSeverity severity;

  /// Related dimension ID.
  final String? dimensionId;

  /// Issue description.
  final String description;

  /// Suggested fix.
  final String? suggestion;

  /// Location in output (path or line).
  final String? location;

  const EvaluationIssue({
    required this.issueType,
    required this.severity,
    this.dimensionId,
    required this.description,
    this.suggestion,
    this.location,
  });

  factory EvaluationIssue.fromJson(Map<String, dynamic> json) {
    return EvaluationIssue(
      issueType: EvalIssueType.fromString(json['issueType'] as String? ?? 'other'),
      severity:
          IssueSeverity.fromString(json['severity'] as String? ?? 'minor'),
      dimensionId: json['dimensionId'] as String?,
      description: json['description'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issueType': issueType.name,
      'severity': severity.name,
      if (dimensionId != null) 'dimensionId': dimensionId,
      'description': description,
      if (suggestion != null) 'suggestion': suggestion,
      if (location != null) 'location': location,
    };
  }
}

/// Evaluation issue types.
enum EvalIssueType {
  /// Accuracy issue.
  accuracy,

  /// Completeness issue.
  completeness,

  /// Format issue.
  format,

  /// Performance issue.
  performance,

  /// Security issue.
  security,

  /// Other issue.
  other;

  static EvalIssueType fromString(String value) {
    return EvalIssueType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvalIssueType.other,
    );
  }
}

/// Issue severity levels.
enum IssueSeverity {
  /// Critical - blocks acceptance.
  critical,

  /// Major - significant impact.
  major,

  /// Minor - small impact.
  minor,

  /// Info - informational only.
  info;

  static IssueSeverity fromString(String value) {
    return IssueSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IssueSeverity.minor,
    );
  }
}
