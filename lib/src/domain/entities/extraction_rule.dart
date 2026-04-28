/// ExtractionRule entity model.
///
/// Stores patterns for extracting fields from evidence without LLM.
/// Design: 03-data-model-specification.md Section 2.12.1
library;

/// Type of extraction rule.
enum RuleType {
  /// Regular expression pattern.
  regex,

  /// Structured parser (JSON path, XPath).
  parser,

  /// Template matching.
  template,

  /// OCR with region hint.
  ocrRegion,

  /// Dictionary lookup.
  dictionary;

  /// Create from string.
  static RuleType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'regex':
        return RuleType.regex;
      case 'parser':
        return RuleType.parser;
      case 'template':
        return RuleType.template;
      case 'ocrregion':
      case 'ocr_region':
        return RuleType.ocrRegion;
      case 'dictionary':
        return RuleType.dictionary;
      default:
        return RuleType.regex;
    }
  }
}

/// Status of an extraction rule.
enum RuleStatus {
  /// Rule is active and can be used.
  active,

  /// Rule is disabled.
  disabled,

  /// Rule is deprecated.
  deprecated;

  /// Create from string.
  static RuleStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return RuleStatus.active;
      case 'disabled':
        return RuleStatus.disabled;
      case 'deprecated':
        return RuleStatus.deprecated;
      default:
        return RuleStatus.active;
    }
  }
}

/// ExtractionRule stores patterns for extracting fields from evidence without LLM.
class ExtractionRule {
  /// Unique rule identifier.
  final String ruleId;

  /// Human-readable name.
  final String name;

  /// Description of what this rule extracts.
  final String? description;

  /// Applicable source type: text, image, file.
  final String sourceType;

  /// Field to extract: amount, date, merchant, etc.
  final String targetField;

  /// Type of extraction rule.
  final RuleType ruleType;

  /// Regex, parser config, or template pattern.
  final String pattern;

  /// Type-specific configuration.
  final Map<String, dynamic>? config;

  /// Historical accuracy (0.0 to 1.0).
  final double accuracy;

  /// Times successfully used.
  final int usageCount;

  /// Times failed.
  final int failureCount;

  /// Rule status.
  final RuleStatus status;

  /// LLM suggestion that created this rule.
  final String? derivedFrom;

  /// Evidence used to create/validate.
  final List<String> sampleEvidenceIds;

  /// Workspace ID.
  final String? workspaceId;

  /// When the rule was created.
  final DateTime createdAt;

  /// When the rule was last updated.
  final DateTime updatedAt;

  const ExtractionRule({
    required this.ruleId,
    required this.name,
    this.description,
    required this.sourceType,
    required this.targetField,
    required this.ruleType,
    required this.pattern,
    this.config,
    this.accuracy = 0.0,
    this.usageCount = 0,
    this.failureCount = 0,
    this.status = RuleStatus.active,
    this.derivedFrom,
    this.sampleEvidenceIds = const [],
    this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON.
  factory ExtractionRule.fromJson(Map<String, dynamic> json) {
    return ExtractionRule(
      ruleId: json['ruleId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      sourceType: json['sourceType'] as String? ?? 'text',
      targetField: json['targetField'] as String? ?? '',
      ruleType: RuleType.fromString(json['ruleType'] as String? ?? 'regex'),
      pattern: json['pattern'] as String? ?? '',
      config: json['config'] as Map<String, dynamic>?,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      usageCount: json['usageCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      status: RuleStatus.fromString(json['status'] as String? ?? 'active'),
      derivedFrom: json['derivedFrom'] as String?,
      sampleEvidenceIds: (json['sampleEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'name': name,
      if (description != null) 'description': description,
      'sourceType': sourceType,
      'targetField': targetField,
      'ruleType': ruleType.name,
      'pattern': pattern,
      if (config != null) 'config': config,
      'accuracy': accuracy,
      'usageCount': usageCount,
      'failureCount': failureCount,
      'status': status.name,
      if (derivedFrom != null) 'derivedFrom': derivedFrom,
      if (sampleEvidenceIds.isNotEmpty) 'sampleEvidenceIds': sampleEvidenceIds,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  ExtractionRule copyWith({
    String? ruleId,
    String? name,
    String? description,
    String? sourceType,
    String? targetField,
    RuleType? ruleType,
    String? pattern,
    Map<String, dynamic>? config,
    double? accuracy,
    int? usageCount,
    int? failureCount,
    RuleStatus? status,
    String? derivedFrom,
    List<String>? sampleEvidenceIds,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExtractionRule(
      ruleId: ruleId ?? this.ruleId,
      name: name ?? this.name,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      targetField: targetField ?? this.targetField,
      ruleType: ruleType ?? this.ruleType,
      pattern: pattern ?? this.pattern,
      config: config ?? this.config,
      accuracy: accuracy ?? this.accuracy,
      usageCount: usageCount ?? this.usageCount,
      failureCount: failureCount ?? this.failureCount,
      status: status ?? this.status,
      derivedFrom: derivedFrom ?? this.derivedFrom,
      sampleEvidenceIds: sampleEvidenceIds ?? this.sampleEvidenceIds,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if rule is active.
  bool get isActive => status == RuleStatus.active;

  /// Check if rule has high accuracy.
  bool get isHighAccuracy => accuracy >= 0.9;

  /// Get total usage count.
  int get totalAttempts => usageCount + failureCount;

  /// Calculate success rate.
  double get successRate {
    if (totalAttempts == 0) return 0.0;
    return usageCount / totalAttempts;
  }

  /// Record a successful usage.
  ExtractionRule recordSuccess() {
    final newUsageCount = usageCount + 1;
    final newTotal = newUsageCount + failureCount;
    final newAccuracy = newTotal > 0 ? newUsageCount / newTotal : 0.0;

    return copyWith(
      usageCount: newUsageCount,
      accuracy: newAccuracy,
      updatedAt: DateTime.now(),
    );
  }

  /// Record a failure.
  ExtractionRule recordFailure() {
    final newFailureCount = failureCount + 1;
    final newTotal = usageCount + newFailureCount;
    final newAccuracy = newTotal > 0 ? usageCount / newTotal : 0.0;

    return copyWith(
      failureCount: newFailureCount,
      accuracy: newAccuracy,
      updatedAt: DateTime.now(),
    );
  }

  /// Disable this rule.
  ExtractionRule disable() {
    return copyWith(
      status: RuleStatus.disabled,
      updatedAt: DateTime.now(),
    );
  }

  /// Deprecate this rule.
  ExtractionRule deprecate() {
    return copyWith(
      status: RuleStatus.deprecated,
      updatedAt: DateTime.now(),
    );
  }
}
