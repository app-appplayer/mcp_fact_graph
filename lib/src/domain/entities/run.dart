/// Run entity model.
///
/// Represents an execution log of automation with full reproducibility support.
/// Design: 03-data-model-specification.md Section 2.11
library;

/// Status of a run.
enum RunStatus {
  /// Run is currently executing.
  running,

  /// Run completed successfully.
  success,

  /// Run failed.
  failed,

  /// Run was skipped (e.g., idempotency).
  skipped;

  /// Create from string.
  static RunStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'running':
        return RunStatus.running;
      case 'success':
        return RunStatus.success;
      case 'failed':
        return RunStatus.failed;
      case 'skipped':
        return RunStatus.skipped;
      default:
        return RunStatus.running;
    }
  }
}

/// Complete input snapshot for reproducibility.
class RunInput {
  /// Point-in-time for data queries.
  final DateTime asOf;

  /// Time period if applicable.
  final Period? period;

  /// Scope filter.
  final String? scope;

  /// Policy version used.
  final String policyVersion;

  /// Views used as input.
  final List<String> inputViewIds;

  /// Events used as input.
  final List<String> inputEventIds;

  /// Additional parameters.
  final Map<String, dynamic> params;

  const RunInput({
    required this.asOf,
    this.period,
    this.scope,
    required this.policyVersion,
    this.inputViewIds = const [],
    this.inputEventIds = const [],
    this.params = const {},
  });

  /// Create from JSON.
  factory RunInput.fromJson(Map<String, dynamic> json) {
    return RunInput(
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      scope: json['scope'] as String?,
      policyVersion: json['policyVersion'] as String? ?? '',
      inputViewIds: (json['inputViewIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      inputEventIds: (json['inputEventIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'asOf': asOf.toIso8601String(),
      if (period != null) 'period': period!.toJson(),
      if (scope != null) 'scope': scope,
      'policyVersion': policyVersion,
      if (inputViewIds.isNotEmpty) 'inputViewIds': inputViewIds,
      if (inputEventIds.isNotEmpty) 'inputEventIds': inputEventIds,
      if (params.isNotEmpty) 'params': params,
    };
  }

  /// Create a copy with modifications.
  RunInput copyWith({
    DateTime? asOf,
    Period? period,
    String? scope,
    String? policyVersion,
    List<String>? inputViewIds,
    List<String>? inputEventIds,
    Map<String, dynamic>? params,
  }) {
    return RunInput(
      asOf: asOf ?? this.asOf,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      policyVersion: policyVersion ?? this.policyVersion,
      inputViewIds: inputViewIds ?? this.inputViewIds,
      inputEventIds: inputEventIds ?? this.inputEventIds,
      params: params ?? this.params,
    );
  }
}

/// Complete output snapshot for audit.
class RunOutput {
  /// Views created.
  final List<String> createdViewIds;

  /// Artifacts created.
  final List<String> createdArtifactIds;

  /// Events modified (if any).
  final List<String> modifiedEventIds;

  /// Execution metrics.
  final Map<String, dynamic> metrics;

  const RunOutput({
    this.createdViewIds = const [],
    this.createdArtifactIds = const [],
    this.modifiedEventIds = const [],
    this.metrics = const {},
  });

  /// Create from JSON.
  factory RunOutput.fromJson(Map<String, dynamic> json) {
    return RunOutput(
      createdViewIds: (json['createdViewIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdArtifactIds: (json['createdArtifactIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modifiedEventIds: (json['modifiedEventIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (createdViewIds.isNotEmpty) 'createdViewIds': createdViewIds,
      if (createdArtifactIds.isNotEmpty)
        'createdArtifactIds': createdArtifactIds,
      if (modifiedEventIds.isNotEmpty) 'modifiedEventIds': modifiedEventIds,
      if (metrics.isNotEmpty) 'metrics': metrics,
    };
  }

  /// Create a copy with modifications.
  RunOutput copyWith({
    List<String>? createdViewIds,
    List<String>? createdArtifactIds,
    List<String>? modifiedEventIds,
    Map<String, dynamic>? metrics,
  }) {
    return RunOutput(
      createdViewIds: createdViewIds ?? this.createdViewIds,
      createdArtifactIds: createdArtifactIds ?? this.createdArtifactIds,
      modifiedEventIds: modifiedEventIds ?? this.modifiedEventIds,
      metrics: metrics ?? this.metrics,
    );
  }
}

/// Log entry for a run.
class LogEntry {
  /// When the log entry was created.
  final DateTime timestamp;

  /// Log level: info, warn, error.
  final String level;

  /// Log message.
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  /// Create from JSON.
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'message': message,
    };
  }
}

/// Simple period representation for run input.
class Period {
  /// Start of the period.
  final DateTime start;

  /// End of the period.
  final DateTime end;

  /// Period type: day, week, month, year.
  final String? type;

  const Period({
    required this.start,
    required this.end,
    this.type,
  });

  /// Create from JSON.
  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      type: json['type'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      if (type != null) 'type': type,
    };
  }
}

/// Run represents an execution log of automation with full reproducibility.
class Run {
  /// Unique run identifier.
  final String runId;

  /// Parent automation job ID.
  final String jobId;

  /// When the run started.
  final DateTime startedAt;

  /// When the run finished.
  final DateTime? finishedAt;

  /// Run status.
  final RunStatus status;

  /// Idempotency key for deduplication.
  final String idempotencyKey;

  /// Complete input snapshot.
  final RunInput input;

  /// Complete output snapshot.
  final RunOutput? output;

  /// Execution logs.
  final List<LogEntry> logs;

  /// Generated artifact references.
  final List<String> artifacts;

  /// Error message if failed.
  final String? errorMessage;

  /// Workspace ID.
  final String? workspaceId;

  const Run({
    required this.runId,
    required this.jobId,
    required this.startedAt,
    this.finishedAt,
    this.status = RunStatus.running,
    required this.idempotencyKey,
    required this.input,
    this.output,
    this.logs = const [],
    this.artifacts = const [],
    this.errorMessage,
    this.workspaceId,
  });

  /// Create from JSON.
  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      runId: json['runId'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      status: RunStatus.fromString(json['status'] as String? ?? 'running'),
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      input: json['input'] != null
          ? RunInput.fromJson(json['input'] as Map<String, dynamic>)
          : RunInput(asOf: DateTime.now(), policyVersion: ''),
      output: json['output'] != null
          ? RunOutput.fromJson(json['output'] as Map<String, dynamic>)
          : null,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      artifacts: (json['artifacts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      errorMessage: json['errorMessage'] as String?,
      workspaceId: json['workspaceId'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'runId': runId,
      'jobId': jobId,
      'startedAt': startedAt.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      'status': status.name,
      'idempotencyKey': idempotencyKey,
      'input': input.toJson(),
      if (output != null) 'output': output!.toJson(),
      if (logs.isNotEmpty) 'logs': logs.map((l) => l.toJson()).toList(),
      if (artifacts.isNotEmpty) 'artifacts': artifacts,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (workspaceId != null) 'workspaceId': workspaceId,
    };
  }

  /// Create a copy with modifications.
  Run copyWith({
    String? runId,
    String? jobId,
    DateTime? startedAt,
    DateTime? finishedAt,
    RunStatus? status,
    String? idempotencyKey,
    RunInput? input,
    RunOutput? output,
    List<LogEntry>? logs,
    List<String>? artifacts,
    String? errorMessage,
    String? workspaceId,
  }) {
    return Run(
      runId: runId ?? this.runId,
      jobId: jobId ?? this.jobId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      input: input ?? this.input,
      output: output ?? this.output,
      logs: logs ?? this.logs,
      artifacts: artifacts ?? this.artifacts,
      errorMessage: errorMessage ?? this.errorMessage,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }

  /// Check if the run is still executing.
  bool get isRunning => status == RunStatus.running;

  /// Check if the run completed successfully.
  bool get isSuccess => status == RunStatus.success;

  /// Check if the run failed.
  bool get isFailed => status == RunStatus.failed;

  /// Get the duration of the run.
  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  /// Mark the run as completed with success.
  Run complete({RunOutput? output, List<String>? artifacts}) {
    return copyWith(
      status: RunStatus.success,
      finishedAt: DateTime.now(),
      output: output,
      artifacts: artifacts,
    );
  }

  /// Mark the run as failed.
  Run fail({required String errorMessage}) {
    return copyWith(
      status: RunStatus.failed,
      finishedAt: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Add a log entry.
  Run addLog(String level, String message) {
    return copyWith(
      logs: [
        ...logs,
        LogEntry(
          timestamp: DateTime.now(),
          level: level,
          message: message,
        ),
      ],
    );
  }
}
