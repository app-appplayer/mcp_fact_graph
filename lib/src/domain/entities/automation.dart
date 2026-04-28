/// Automation entity model.
///
/// Defines scheduled or triggered actions.
/// Design: 03-data-model-specification.md Section 2.10
library;

/// Type of automation trigger.
enum AutomationTriggerType {
  /// Schedule-based trigger.
  schedule,

  /// Condition-based trigger.
  condition,

  /// Manual trigger.
  manual;

  /// Create from string.
  static AutomationTriggerType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'schedule':
        return AutomationTriggerType.schedule;
      case 'condition':
        return AutomationTriggerType.condition;
      case 'manual':
        return AutomationTriggerType.manual;
      default:
        return AutomationTriggerType.manual;
    }
  }
}

/// Schedule metadata for scheduled triggers.
class ScheduleMeta {
  /// Cron expression.
  final String cron;

  /// Timezone for schedule.
  final String timezone;

  const ScheduleMeta({
    required this.cron,
    this.timezone = 'UTC',
  });

  /// Create from JSON.
  factory ScheduleMeta.fromJson(Map<String, dynamic> json) {
    return ScheduleMeta(
      cron: json['cron'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'cron': cron,
      'timezone': timezone,
    };
  }

  /// Create a copy with modifications.
  ScheduleMeta copyWith({
    String? cron,
    String? timezone,
  }) {
    return ScheduleMeta(
      cron: cron ?? this.cron,
      timezone: timezone ?? this.timezone,
    );
  }
}

/// Retry policy configuration.
class RetryPolicy {
  /// Maximum number of retries.
  final int maxRetries;

  /// Backoff interval in seconds.
  final int backoffSeconds;

  /// Whether to use exponential backoff.
  final bool exponentialBackoff;

  const RetryPolicy({
    this.maxRetries = 3,
    this.backoffSeconds = 60,
    this.exponentialBackoff = true,
  });

  /// Create from JSON.
  factory RetryPolicy.fromJson(Map<String, dynamic> json) {
    return RetryPolicy(
      maxRetries: json['maxRetries'] as int? ?? 3,
      backoffSeconds: json['backoffSeconds'] as int? ?? 60,
      exponentialBackoff: json['exponentialBackoff'] as bool? ?? true,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'maxRetries': maxRetries,
      'backoffSeconds': backoffSeconds,
      'exponentialBackoff': exponentialBackoff,
    };
  }

  /// Create a copy with modifications.
  RetryPolicy copyWith({
    int? maxRetries,
    int? backoffSeconds,
    bool? exponentialBackoff,
  }) {
    return RetryPolicy(
      maxRetries: maxRetries ?? this.maxRetries,
      backoffSeconds: backoffSeconds ?? this.backoffSeconds,
      exponentialBackoff: exponentialBackoff ?? this.exponentialBackoff,
    );
  }

  /// Calculate backoff duration for given attempt.
  Duration getBackoffDuration(int attempt) {
    if (attempt < 0) return Duration.zero;
    if (!exponentialBackoff) {
      return Duration(seconds: backoffSeconds);
    }
    // Exponential backoff: backoffSeconds * 2^attempt
    final seconds = backoffSeconds * (1 << attempt);
    return Duration(seconds: seconds);
  }
}

/// Automation defines scheduled or triggered actions.
class Automation {
  /// Unique job identifier.
  final String jobId;

  /// Human-readable name.
  final String name;

  /// Description of what this automation does.
  final String? description;

  /// Trigger type.
  final AutomationTriggerType trigger;

  /// Condition expression for condition-based triggers.
  final String? condition;

  /// Action to execute.
  final String action;

  /// Whether the automation is enabled.
  final bool enabled;

  /// Schedule metadata for scheduled triggers.
  final ScheduleMeta? scheduleMeta;

  /// Strategy for generating idempotency keys.
  final String idempotencyKeyStrategy;

  /// Retry policy.
  final RetryPolicy retryPolicy;

  /// Workspace ID.
  final String? workspaceId;

  /// When the automation was created.
  final DateTime createdAt;

  /// When the automation was last updated.
  final DateTime updatedAt;

  /// When the automation last ran.
  final DateTime? lastRunAt;

  /// When the automation will next run.
  final DateTime? nextRunAt;

  const Automation({
    required this.jobId,
    required this.name,
    this.description,
    required this.trigger,
    this.condition,
    required this.action,
    this.enabled = true,
    this.scheduleMeta,
    this.idempotencyKeyStrategy = 'time-based',
    this.retryPolicy = const RetryPolicy(),
    this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.lastRunAt,
    this.nextRunAt,
  });

  /// Create from JSON.
  factory Automation.fromJson(Map<String, dynamic> json) {
    return Automation(
      jobId: json['jobId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      trigger: AutomationTriggerType.fromString(json['trigger'] as String? ?? 'manual'),
      condition: json['condition'] as String?,
      action: json['action'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      scheduleMeta: json['scheduleMeta'] != null
          ? ScheduleMeta.fromJson(json['scheduleMeta'] as Map<String, dynamic>)
          : null,
      idempotencyKeyStrategy:
          json['idempotencyKeyStrategy'] as String? ?? 'time-based',
      retryPolicy: json['retryPolicy'] != null
          ? RetryPolicy.fromJson(json['retryPolicy'] as Map<String, dynamic>)
          : const RetryPolicy(),
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      lastRunAt: json['lastRunAt'] != null
          ? DateTime.parse(json['lastRunAt'] as String)
          : null,
      nextRunAt: json['nextRunAt'] != null
          ? DateTime.parse(json['nextRunAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'name': name,
      if (description != null) 'description': description,
      'trigger': trigger.name,
      if (condition != null) 'condition': condition,
      'action': action,
      'enabled': enabled,
      if (scheduleMeta != null) 'scheduleMeta': scheduleMeta!.toJson(),
      'idempotencyKeyStrategy': idempotencyKeyStrategy,
      'retryPolicy': retryPolicy.toJson(),
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastRunAt != null) 'lastRunAt': lastRunAt!.toIso8601String(),
      if (nextRunAt != null) 'nextRunAt': nextRunAt!.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  Automation copyWith({
    String? jobId,
    String? name,
    String? description,
    AutomationTriggerType? trigger,
    String? condition,
    String? action,
    bool? enabled,
    ScheduleMeta? scheduleMeta,
    String? idempotencyKeyStrategy,
    RetryPolicy? retryPolicy,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
  }) {
    return Automation(
      jobId: jobId ?? this.jobId,
      name: name ?? this.name,
      description: description ?? this.description,
      trigger: trigger ?? this.trigger,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
      scheduleMeta: scheduleMeta ?? this.scheduleMeta,
      idempotencyKeyStrategy:
          idempotencyKeyStrategy ?? this.idempotencyKeyStrategy,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
    );
  }

  /// Check if automation is ready to run.
  bool get isReadyToRun {
    if (!enabled) return false;
    if (nextRunAt == null) return trigger == AutomationTriggerType.manual;
    return DateTime.now().isAfter(nextRunAt!);
  }

  /// Check if this is a scheduled automation.
  bool get isScheduled => trigger == AutomationTriggerType.schedule;

  /// Enable this automation.
  Automation enable() {
    return copyWith(
      enabled: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Disable this automation.
  Automation disable() {
    return copyWith(
      enabled: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as run.
  Automation markRun({DateTime? nextRun}) {
    return copyWith(
      lastRunAt: DateTime.now(),
      nextRunAt: nextRun,
      updatedAt: DateTime.now(),
    );
  }
}
