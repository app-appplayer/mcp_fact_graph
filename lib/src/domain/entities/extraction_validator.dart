/// ExtractionValidator entity for LLM Call Reduction.
///
/// Defines validation rules for extracted facts before confirmation.
/// Reference: 03-data-model-specification.md Section 2.12.2
library;

/// ExtractionValidator defines validation rules for extracted facts.
///
/// Validators are applied to facts before confirmation to ensure
/// data quality and consistency.
class ExtractionValidator {
  /// Unique validator identifier.
  final String validatorId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Fact type this validator applies to.
  final String factType;

  /// Validation rule expressions.
  ///
  /// Examples:
  /// - `field != null` - Field existence
  /// - `length(field) >= N` - Minimum length
  /// - `inRange(field, min, max)` - Numeric range
  /// - `oneOf(field, values)` - Enum validation
  /// - `references(field, entityType)` - Entity reference
  final List<String> rules;

  /// Severity level of validation failures.
  final ValidatorSeverity severity;

  /// Whether this validator is active.
  final bool enabled;

  /// Custom error message for failures.
  final String? message;

  /// Other validator IDs that must pass first.
  final List<String>? dependencies;

  /// When this validator was created.
  final DateTime createdAt;

  /// When this validator was last updated.
  final DateTime updatedAt;

  const ExtractionValidator({
    required this.validatorId,
    required this.workspaceId,
    required this.factType,
    required this.rules,
    this.severity = ValidatorSeverity.error,
    this.enabled = true,
    this.message,
    this.dependencies,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExtractionValidator.fromJson(Map<String, dynamic> json) {
    return ExtractionValidator(
      validatorId: json['validatorId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      factType: json['factType'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      severity: ValidatorSeverity.fromString(
          json['severity'] as String? ?? 'error'),
      enabled: json['enabled'] as bool? ?? true,
      message: json['message'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'validatorId': validatorId,
      'workspaceId': workspaceId,
      'factType': factType,
      'rules': rules,
      'severity': severity.name,
      'enabled': enabled,
      if (message != null) 'message': message,
      if (dependencies != null && dependencies!.isNotEmpty)
        'dependencies': dependencies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ExtractionValidator copyWith({
    String? validatorId,
    String? workspaceId,
    String? factType,
    List<String>? rules,
    ValidatorSeverity? severity,
    bool? enabled,
    String? message,
    List<String>? dependencies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExtractionValidator(
      validatorId: validatorId ?? this.validatorId,
      workspaceId: workspaceId ?? this.workspaceId,
      factType: factType ?? this.factType,
      rules: rules ?? this.rules,
      severity: severity ?? this.severity,
      enabled: enabled ?? this.enabled,
      message: message ?? this.message,
      dependencies: dependencies ?? this.dependencies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this validator is active.
  bool get isActive => enabled;

  /// Check if this validator has dependencies.
  bool get hasDependencies =>
      dependencies != null && dependencies!.isNotEmpty;

  /// Enable this validator.
  ExtractionValidator enable() => copyWith(
        enabled: true,
        updatedAt: DateTime.now(),
      );

  /// Disable this validator.
  ExtractionValidator disable() => copyWith(
        enabled: false,
        updatedAt: DateTime.now(),
      );

  /// Add a rule.
  ExtractionValidator addRule(String rule) => copyWith(
        rules: [...rules, rule],
        updatedAt: DateTime.now(),
      );

  /// Remove a rule.
  ExtractionValidator removeRule(String rule) => copyWith(
        rules: rules.where((r) => r != rule).toList(),
        updatedAt: DateTime.now(),
      );

  @override
  String toString() =>
      'ExtractionValidator($validatorId, factType: $factType, severity: $severity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractionValidator && validatorId == other.validatorId;

  @override
  int get hashCode => validatorId.hashCode;
}

/// Severity levels for validation failures.
enum ValidatorSeverity {
  /// Validation failure blocks fact confirmation.
  error,

  /// Validation failure generates warning but allows confirmation.
  warning,

  /// Validation failure is logged but does not affect confirmation.
  info;

  static ValidatorSeverity fromString(String value) {
    return ValidatorSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ValidatorSeverity.error,
    );
  }
}

/// Result of running a validator.
class ValidationResult {
  /// Validator ID that produced this result.
  final String validatorId;

  /// Whether validation passed.
  final bool passed;

  /// Severity of the failure (if failed).
  final ValidatorSeverity? severity;

  /// Error message (if failed).
  final String? message;

  /// Rule that failed (if failed).
  final String? failedRule;

  /// When validation was performed.
  final DateTime validatedAt;

  const ValidationResult({
    required this.validatorId,
    required this.passed,
    this.severity,
    this.message,
    this.failedRule,
    required this.validatedAt,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      validatorId: json['validatorId'] as String? ?? '',
      passed: json['passed'] as bool? ?? false,
      severity: json['severity'] != null
          ? ValidatorSeverity.fromString(json['severity'] as String)
          : null,
      message: json['message'] as String?,
      failedRule: json['failedRule'] as String?,
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'validatorId': validatorId,
      'passed': passed,
      if (severity != null) 'severity': severity!.name,
      if (message != null) 'message': message,
      if (failedRule != null) 'failedRule': failedRule,
      'validatedAt': validatedAt.toIso8601String(),
    };
  }

  /// Check if this is an error-level failure.
  bool get isError => !passed && severity == ValidatorSeverity.error;

  /// Check if this is a warning-level failure.
  bool get isWarning => !passed && severity == ValidatorSeverity.warning;
}
