/// SkillRun entity for L3 SkillOps Layer.
///
/// Represents the execution record of a skill, including step-by-step
/// execution tracking and quality gate results.
library;

/// Status of a skill run.
enum SkillRunStatus {
  /// Skill is currently running.
  running,

  /// Skill completed successfully.
  completed,

  /// Skill execution failed.
  failed,

  /// Skill was blocked by a quality gate.
  blocked;

  static SkillRunStatus fromString(String value) {
    return SkillRunStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillRunStatus.running,
    );
  }
}

/// Status of an individual step.
enum StepStatus {
  /// Step has not started.
  pending,

  /// Step is currently executing.
  running,

  /// Step completed successfully.
  completed,

  /// Step execution failed.
  failed,

  /// Step was skipped.
  skipped;

  static StepStatus fromString(String value) {
    return StepStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StepStatus.pending,
    );
  }
}

/// Action taken when a gate fails.
enum GateAction {
  /// Block execution.
  block,

  /// Warn but continue.
  warn,

  /// Log and continue.
  log;

  static GateAction fromString(String value) {
    return GateAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GateAction.warn,
    );
  }
}

/// Record of a single step execution.
class StepExecution {
  /// Step identifier.
  final String stepId;

  /// Step name.
  final String stepName;

  /// Step order in sequence.
  final int order;

  /// When the step started.
  final DateTime startedAt;

  /// When the step finished.
  final DateTime? finishedAt;

  /// Step status.
  final StepStatus status;

  /// Step outputs.
  final Map<String, dynamic>? outputs;

  /// Failure reason if failed.
  final String? failureReason;

  /// Tokens consumed by this step.
  final int tokensUsed;

  const StepExecution({
    required this.stepId,
    required this.stepName,
    required this.order,
    required this.startedAt,
    this.finishedAt,
    this.status = StepStatus.pending,
    this.outputs,
    this.failureReason,
    this.tokensUsed = 0,
  });

  factory StepExecution.fromJson(Map<String, dynamic> json) {
    return StepExecution(
      stepId: json['stepId'] as String? ?? '',
      stepName: json['stepName'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      status: StepStatus.fromString(json['status'] as String? ?? ''),
      outputs: json['outputs'] as Map<String, dynamic>?,
      failureReason: json['failureReason'] as String?,
      tokensUsed: json['tokensUsed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'stepName': stepName,
      'order': order,
      'startedAt': startedAt.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      'status': status.name,
      if (outputs != null) 'outputs': outputs,
      if (failureReason != null) 'failureReason': failureReason,
      if (tokensUsed > 0) 'tokensUsed': tokensUsed,
    };
  }

  StepExecution copyWith({
    String? stepId,
    String? stepName,
    int? order,
    DateTime? startedAt,
    DateTime? finishedAt,
    StepStatus? status,
    Map<String, dynamic>? outputs,
    String? failureReason,
    int? tokensUsed,
  }) {
    return StepExecution(
      stepId: stepId ?? this.stepId,
      stepName: stepName ?? this.stepName,
      order: order ?? this.order,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      outputs: outputs ?? this.outputs,
      failureReason: failureReason ?? this.failureReason,
      tokensUsed: tokensUsed ?? this.tokensUsed,
    );
  }

  /// Get duration if finished.
  Duration? get duration =>
      finishedAt != null ? finishedAt!.difference(startedAt) : null;

  /// Check if step is complete.
  bool get isComplete => status == StepStatus.completed;

  /// Check if step failed.
  bool get isFailed => status == StepStatus.failed;

  @override
  String toString() => 'StepExecution($stepId, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepExecution && stepId == other.stepId;

  @override
  int get hashCode => stepId.hashCode;
}

/// Record of a quality gate check.
class GateCheck {
  /// Gate identifier.
  final String gateId;

  /// Gate name.
  final String gateName;

  /// Gate condition expression.
  final String condition;

  /// When the gate was checked.
  final DateTime checkedAt;

  /// Whether the gate passed.
  final bool passed;

  /// Failure reason if not passed.
  final String? failureReason;

  /// Action taken.
  final GateAction actionTaken;

  /// Evaluated value.
  final dynamic evaluatedValue;

  const GateCheck({
    required this.gateId,
    required this.gateName,
    required this.condition,
    required this.checkedAt,
    required this.passed,
    this.failureReason,
    this.actionTaken = GateAction.warn,
    this.evaluatedValue,
  });

  factory GateCheck.fromJson(Map<String, dynamic> json) {
    return GateCheck(
      gateId: json['gateId'] as String? ?? '',
      gateName: json['gateName'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      checkedAt: json['checkedAt'] != null
          ? DateTime.parse(json['checkedAt'] as String)
          : DateTime.now(),
      passed: json['passed'] as bool? ?? false,
      failureReason: json['failureReason'] as String?,
      actionTaken: GateAction.fromString(json['actionTaken'] as String? ?? ''),
      evaluatedValue: json['evaluatedValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gateId': gateId,
      'gateName': gateName,
      'condition': condition,
      'checkedAt': checkedAt.toIso8601String(),
      'passed': passed,
      if (failureReason != null) 'failureReason': failureReason,
      'actionTaken': actionTaken.name,
      if (evaluatedValue != null) 'evaluatedValue': evaluatedValue,
    };
  }

  GateCheck copyWith({
    String? gateId,
    String? gateName,
    String? condition,
    DateTime? checkedAt,
    bool? passed,
    String? failureReason,
    GateAction? actionTaken,
    dynamic evaluatedValue,
  }) {
    return GateCheck(
      gateId: gateId ?? this.gateId,
      gateName: gateName ?? this.gateName,
      condition: condition ?? this.condition,
      checkedAt: checkedAt ?? this.checkedAt,
      passed: passed ?? this.passed,
      failureReason: failureReason ?? this.failureReason,
      actionTaken: actionTaken ?? this.actionTaken,
      evaluatedValue: evaluatedValue ?? this.evaluatedValue,
    );
  }

  @override
  String toString() =>
      'GateCheck($gateId, passed: $passed, action: $actionTaken)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GateCheck && gateId == other.gateId;

  @override
  int get hashCode => gateId.hashCode;
}

/// SkillRun represents a single execution of a skill.
///
/// Tracks step-by-step execution, quality gate results, inputs/outputs,
/// and execution metrics.
class SkillRun {
  /// Unique run identifier.
  final String runId;

  /// Workspace identifier.
  final String workspaceId;

  /// ID of the skill being executed.
  final String skillId;

  /// Version of the skill.
  final String skillVersion;

  /// Context ID for this execution.
  final String? contextId;

  /// Trace ID for distributed tracing.
  final String? traceId;

  /// When execution started.
  final DateTime startedAt;

  /// When execution finished.
  final DateTime? finishedAt;

  /// Run status.
  final SkillRunStatus status;

  /// Step execution records.
  final List<StepExecution> stepExecutions;

  /// Quality gate check records.
  final List<GateCheck> gateChecks;

  /// Input values.
  final Map<String, dynamic> inputs;

  /// Output values.
  final Map<String, dynamic>? outputs;

  /// Block reason if blocked.
  final String? blockReason;

  /// IDs of artifacts generated.
  final List<String> artifactIds;

  /// Total tokens used.
  final int totalTokensUsed;

  /// Total LLM calls made.
  final int llmCallsMade;

  /// Total MCP calls made.
  final int mcpCallsMade;

  /// When the record was created.
  final DateTime createdAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const SkillRun({
    required this.runId,
    required this.workspaceId,
    required this.skillId,
    required this.skillVersion,
    this.contextId,
    this.traceId,
    required this.startedAt,
    this.finishedAt,
    this.status = SkillRunStatus.running,
    this.stepExecutions = const [],
    this.gateChecks = const [],
    this.inputs = const {},
    this.outputs,
    this.blockReason,
    this.artifactIds = const [],
    this.totalTokensUsed = 0,
    this.llmCallsMade = 0,
    this.mcpCallsMade = 0,
    required this.createdAt,
    this.metadata = const {},
  });

  factory SkillRun.fromJson(Map<String, dynamic> json) {
    return SkillRun(
      runId: json['runId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      skillId: json['skillId'] as String? ?? '',
      skillVersion: json['skillVersion'] as String? ?? '1.0.0',
      contextId: json['contextId'] as String?,
      traceId: json['traceId'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      status: SkillRunStatus.fromString(json['status'] as String? ?? ''),
      stepExecutions: (json['stepExecutions'] as List<dynamic>?)
              ?.map((e) => StepExecution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gateChecks: (json['gateChecks'] as List<dynamic>?)
              ?.map((e) => GateCheck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inputs: json['inputs'] as Map<String, dynamic>? ?? {},
      outputs: json['outputs'] as Map<String, dynamic>?,
      blockReason: json['blockReason'] as String?,
      artifactIds: (json['artifactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalTokensUsed: json['totalTokensUsed'] as int? ?? 0,
      llmCallsMade: json['llmCallsMade'] as int? ?? 0,
      mcpCallsMade: json['mcpCallsMade'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runId': runId,
      'workspaceId': workspaceId,
      'skillId': skillId,
      'skillVersion': skillVersion,
      if (contextId != null) 'contextId': contextId,
      if (traceId != null) 'traceId': traceId,
      'startedAt': startedAt.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      'status': status.name,
      if (stepExecutions.isNotEmpty)
        'stepExecutions': stepExecutions.map((e) => e.toJson()).toList(),
      if (gateChecks.isNotEmpty)
        'gateChecks': gateChecks.map((e) => e.toJson()).toList(),
      if (inputs.isNotEmpty) 'inputs': inputs,
      if (outputs != null) 'outputs': outputs,
      if (blockReason != null) 'blockReason': blockReason,
      if (artifactIds.isNotEmpty) 'artifactIds': artifactIds,
      if (totalTokensUsed > 0) 'totalTokensUsed': totalTokensUsed,
      if (llmCallsMade > 0) 'llmCallsMade': llmCallsMade,
      if (mcpCallsMade > 0) 'mcpCallsMade': mcpCallsMade,
      'createdAt': createdAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  SkillRun copyWith({
    String? runId,
    String? workspaceId,
    String? skillId,
    String? skillVersion,
    String? contextId,
    String? traceId,
    DateTime? startedAt,
    DateTime? finishedAt,
    SkillRunStatus? status,
    List<StepExecution>? stepExecutions,
    List<GateCheck>? gateChecks,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? outputs,
    String? blockReason,
    List<String>? artifactIds,
    int? totalTokensUsed,
    int? llmCallsMade,
    int? mcpCallsMade,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return SkillRun(
      runId: runId ?? this.runId,
      workspaceId: workspaceId ?? this.workspaceId,
      skillId: skillId ?? this.skillId,
      skillVersion: skillVersion ?? this.skillVersion,
      contextId: contextId ?? this.contextId,
      traceId: traceId ?? this.traceId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      stepExecutions: stepExecutions ?? this.stepExecutions,
      gateChecks: gateChecks ?? this.gateChecks,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      blockReason: blockReason ?? this.blockReason,
      artifactIds: artifactIds ?? this.artifactIds,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      llmCallsMade: llmCallsMade ?? this.llmCallsMade,
      mcpCallsMade: mcpCallsMade ?? this.mcpCallsMade,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get duration if finished.
  Duration? get duration =>
      finishedAt != null ? finishedAt!.difference(startedAt) : null;

  /// Check if run is complete.
  bool get isComplete => status == SkillRunStatus.completed;

  /// Check if run failed.
  bool get isFailed => status == SkillRunStatus.failed;

  /// Check if run is blocked.
  bool get isBlocked => status == SkillRunStatus.blocked;

  /// Check if run is still running.
  bool get isRunning => status == SkillRunStatus.running;

  /// Get completed steps count.
  int get completedStepsCount =>
      stepExecutions.where((s) => s.isComplete).length;

  /// Get failed steps count.
  int get failedStepsCount => stepExecutions.where((s) => s.isFailed).length;

  /// Get passed gates count.
  int get passedGatesCount => gateChecks.where((g) => g.passed).length;

  /// Get failed gates count.
  int get failedGatesCount => gateChecks.where((g) => !g.passed).length;

  /// Get blocking gates.
  List<GateCheck> get blockingGates => gateChecks
      .where((g) => !g.passed && g.actionTaken == GateAction.block)
      .toList();

  @override
  String toString() =>
      'SkillRun($runId, skill: $skillId, status: $status, steps: ${stepExecutions.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SkillRun && runId == other.runId;

  @override
  int get hashCode => runId.hashCode;
}
