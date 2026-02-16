/// Skill entity for L3 SkillOps Layer.
///
/// Represents executable skills that can be triggered by patterns.
library;

/// Skill represents an executable capability.
///
/// Skills are triggered by patterns and perform specific actions.
class Skill {
  /// Unique skill identifier.
  final String skillId;

  /// Skill name.
  final String name;

  /// Skill description.
  final String description;

  /// Skill category.
  final SkillCategory category;

  /// Skill version.
  final String version;

  /// Input schema (JSON Schema format).
  final Map<String, dynamic> inputSchema;

  /// Output schema (JSON Schema format).
  final Map<String, dynamic> outputSchema;

  /// Trigger conditions.
  final List<SkillTrigger> triggers;

  /// Required capabilities/permissions.
  final List<String> requiredCapabilities;

  /// Dependencies on other skills.
  final List<String> dependsOn;

  /// Execution configuration.
  final SkillExecutionConfig executionConfig;

  /// Skill status.
  final SkillStatus status;

  /// When skill was created.
  final DateTime createdAt;

  /// When skill was last updated.
  final DateTime updatedAt;

  /// Associated rubric ID for evaluation.
  final String? rubricId;

  /// Execution statistics.
  final SkillStats? stats;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Skill({
    required this.skillId,
    required this.name,
    required this.description,
    required this.category,
    this.version = '1.0.0',
    this.inputSchema = const {},
    this.outputSchema = const {},
    this.triggers = const [],
    this.requiredCapabilities = const [],
    this.dependsOn = const [],
    this.executionConfig = const SkillExecutionConfig(),
    this.status = SkillStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.rubricId,
    this.stats,
    this.metadata = const {},
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      skillId: json['skillId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: SkillCategory.fromString(
          json['category'] as String? ?? 'utility'),
      version: json['version'] as String? ?? '1.0.0',
      inputSchema: json['inputSchema'] as Map<String, dynamic>? ?? {},
      outputSchema: json['outputSchema'] as Map<String, dynamic>? ?? {},
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => SkillTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requiredCapabilities: (json['requiredCapabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dependsOn: (json['dependsOn'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      executionConfig: json['executionConfig'] != null
          ? SkillExecutionConfig.fromJson(
              json['executionConfig'] as Map<String, dynamic>)
          : const SkillExecutionConfig(),
      status: SkillStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      rubricId: json['rubricId'] as String?,
      stats: json['stats'] != null
          ? SkillStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'name': name,
      'description': description,
      'category': category.name,
      'version': version,
      if (inputSchema.isNotEmpty) 'inputSchema': inputSchema,
      if (outputSchema.isNotEmpty) 'outputSchema': outputSchema,
      if (triggers.isNotEmpty)
        'triggers': triggers.map((t) => t.toJson()).toList(),
      if (requiredCapabilities.isNotEmpty)
        'requiredCapabilities': requiredCapabilities,
      if (dependsOn.isNotEmpty) 'dependsOn': dependsOn,
      'executionConfig': executionConfig.toJson(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (rubricId != null) 'rubricId': rubricId,
      if (stats != null) 'stats': stats!.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Skill copyWith({
    String? skillId,
    String? name,
    String? description,
    SkillCategory? category,
    String? version,
    Map<String, dynamic>? inputSchema,
    Map<String, dynamic>? outputSchema,
    List<SkillTrigger>? triggers,
    List<String>? requiredCapabilities,
    List<String>? dependsOn,
    SkillExecutionConfig? executionConfig,
    SkillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rubricId,
    SkillStats? stats,
    Map<String, dynamic>? metadata,
  }) {
    return Skill(
      skillId: skillId ?? this.skillId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      inputSchema: inputSchema ?? this.inputSchema,
      outputSchema: outputSchema ?? this.outputSchema,
      triggers: triggers ?? this.triggers,
      requiredCapabilities: requiredCapabilities ?? this.requiredCapabilities,
      dependsOn: dependsOn ?? this.dependsOn,
      executionConfig: executionConfig ?? this.executionConfig,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rubricId: rubricId ?? this.rubricId,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if skill is available for execution.
  bool get isAvailable => status == SkillStatus.active;

  @override
  String toString() => 'Skill($skillId, name: $name, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Skill && skillId == other.skillId;

  @override
  int get hashCode => skillId.hashCode;
}

/// Skill categories.
enum SkillCategory {
  /// Data analysis skill.
  analysis,

  /// Data transformation skill.
  transformation,

  /// Summarization skill.
  summarization,

  /// Search/retrieval skill.
  retrieval,

  /// Generation skill.
  generation,

  /// Validation skill.
  validation,

  /// Notification skill.
  notification,

  /// Integration skill.
  integration,

  /// Utility skill.
  utility;

  static SkillCategory fromString(String value) {
    return SkillCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillCategory.utility,
    );
  }
}

/// Skill status.
enum SkillStatus {
  /// Active and available.
  active,

  /// Under development.
  development,

  /// Disabled.
  disabled,

  /// Deprecated.
  deprecated;

  static SkillStatus fromString(String value) {
    return SkillStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillStatus.active,
    );
  }
}

/// Skill trigger configuration.
class SkillTrigger {
  /// Trigger type.
  final TriggerType type;

  /// Pattern ID to match (for pattern triggers).
  final String? patternId;

  /// Event types to trigger on.
  final List<String> eventTypes;

  /// Schedule expression (for scheduled triggers).
  final String? schedule;

  /// Condition expression.
  final String? condition;

  /// Priority (higher = more priority).
  final int priority;

  const SkillTrigger({
    required this.type,
    this.patternId,
    this.eventTypes = const [],
    this.schedule,
    this.condition,
    this.priority = 0,
  });

  factory SkillTrigger.fromJson(Map<String, dynamic> json) {
    return SkillTrigger(
      type: TriggerType.fromString(json['type'] as String? ?? 'manual'),
      patternId: json['patternId'] as String?,
      eventTypes: (json['eventTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      schedule: json['schedule'] as String?,
      condition: json['condition'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (patternId != null) 'patternId': patternId,
      if (eventTypes.isNotEmpty) 'eventTypes': eventTypes,
      if (schedule != null) 'schedule': schedule,
      if (condition != null) 'condition': condition,
      'priority': priority,
    };
  }
}

/// Trigger types.
enum TriggerType {
  /// Manual invocation.
  manual,

  /// Pattern-based trigger.
  pattern,

  /// Event-based trigger.
  event,

  /// Scheduled trigger.
  scheduled,

  /// Webhook trigger.
  webhook;

  static TriggerType fromString(String value) {
    return TriggerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TriggerType.manual,
    );
  }
}

/// Skill execution configuration.
class SkillExecutionConfig {
  /// Timeout in milliseconds.
  final int timeoutMs;

  /// Maximum retries.
  final int maxRetries;

  /// Retry delay in milliseconds.
  final int retryDelayMs;

  /// Whether to run async.
  final bool async;

  /// Maximum concurrent executions.
  final int maxConcurrent;

  /// Rate limit (calls per minute).
  final int? rateLimit;

  const SkillExecutionConfig({
    this.timeoutMs = 30000,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.async = false,
    this.maxConcurrent = 1,
    this.rateLimit,
  });

  factory SkillExecutionConfig.fromJson(Map<String, dynamic> json) {
    return SkillExecutionConfig(
      timeoutMs: json['timeoutMs'] as int? ?? 30000,
      maxRetries: json['maxRetries'] as int? ?? 3,
      retryDelayMs: json['retryDelayMs'] as int? ?? 1000,
      async: json['async'] as bool? ?? false,
      maxConcurrent: json['maxConcurrent'] as int? ?? 1,
      rateLimit: json['rateLimit'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeoutMs': timeoutMs,
      'maxRetries': maxRetries,
      'retryDelayMs': retryDelayMs,
      'async': async,
      'maxConcurrent': maxConcurrent,
      if (rateLimit != null) 'rateLimit': rateLimit,
    };
  }
}

/// Skill execution statistics.
class SkillStats {
  /// Total executions.
  final int totalExecutions;

  /// Successful executions.
  final int successCount;

  /// Failed executions.
  final int failureCount;

  /// Average duration in milliseconds.
  final double avgDurationMs;

  /// Last execution time.
  final DateTime? lastExecutedAt;

  /// Last error message.
  final String? lastError;

  const SkillStats({
    this.totalExecutions = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.avgDurationMs = 0.0,
    this.lastExecutedAt,
    this.lastError,
  });

  factory SkillStats.fromJson(Map<String, dynamic> json) {
    return SkillStats(
      totalExecutions: json['totalExecutions'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0.0,
      lastExecutedAt: json['lastExecutedAt'] != null
          ? DateTime.parse(json['lastExecutedAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExecutions': totalExecutions,
      'successCount': successCount,
      'failureCount': failureCount,
      'avgDurationMs': avgDurationMs,
      if (lastExecutedAt != null)
        'lastExecutedAt': lastExecutedAt!.toIso8601String(),
      if (lastError != null) 'lastError': lastError,
    };
  }

  /// Success rate.
  double get successRate =>
      totalExecutions > 0 ? successCount / totalExecutions : 0.0;
}
