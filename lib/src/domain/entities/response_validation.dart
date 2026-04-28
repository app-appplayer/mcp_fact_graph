/// ResponseValidation entity for L2 ContextOps Layer.
///
/// Represents LLM response validation against the fact graph.
/// Validates claims extracted from LLM responses and identifies issues.
library;

import 'claim.dart';

/// Result of response validation.
enum ValidationResult {
  /// All claims passed validation.
  passed,

  /// One or more claims failed validation.
  failed,

  /// Needs human review.
  needsReview;

  static ValidationResult fromString(String value) {
    return ValidationResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ValidationResult.needsReview,
    );
  }
}

/// Types of validation issues.
enum ValidationIssueType {
  /// Claim lacks supporting evidence.
  missingEvidence,

  /// Claim contradicts known facts.
  contradiction,

  /// Claim appears to be hallucinated.
  hallucination,

  /// Claim is based on outdated information.
  outdated,

  /// Claim violates policy constraints.
  policyViolation;

  static ValidationIssueType fromString(String value) {
    return ValidationIssueType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ValidationIssueType.missingEvidence,
    );
  }
}

/// Severity of validation issues.
enum IssueSeverity {
  /// Blocking error that must be resolved.
  error,

  /// Warning that should be reviewed.
  warning,

  /// Informational notice.
  info;

  static IssueSeverity fromString(String value) {
    return IssueSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IssueSeverity.warning,
    );
  }
}

/// A single validation issue found during response validation.
class ValidationIssue {
  /// Unique issue identifier.
  final String issueId;

  /// Type of the issue.
  final ValidationIssueType issueType;

  /// Severity level.
  final IssueSeverity severity;

  /// Human-readable description of the issue.
  final String description;

  /// IDs of claims related to this issue.
  final List<String> relatedClaimIds;

  /// Suggested action to resolve the issue.
  final String? suggestedAction;

  const ValidationIssue({
    required this.issueId,
    required this.issueType,
    this.severity = IssueSeverity.warning,
    required this.description,
    this.relatedClaimIds = const [],
    this.suggestedAction,
  });

  factory ValidationIssue.fromJson(Map<String, dynamic> json) {
    return ValidationIssue(
      issueId: json['issueId'] as String? ?? '',
      issueType: ValidationIssueType.fromString(json['issueType'] as String? ?? ''),
      severity: IssueSeverity.fromString(json['severity'] as String? ?? ''),
      description: json['description'] as String? ?? '',
      relatedClaimIds: (json['relatedClaimIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suggestedAction: json['suggestedAction'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issueId': issueId,
      'issueType': issueType.name,
      'severity': severity.name,
      'description': description,
      if (relatedClaimIds.isNotEmpty) 'relatedClaimIds': relatedClaimIds,
      if (suggestedAction != null) 'suggestedAction': suggestedAction,
    };
  }

  ValidationIssue copyWith({
    String? issueId,
    ValidationIssueType? issueType,
    IssueSeverity? severity,
    String? description,
    List<String>? relatedClaimIds,
    String? suggestedAction,
  }) {
    return ValidationIssue(
      issueId: issueId ?? this.issueId,
      issueType: issueType ?? this.issueType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      relatedClaimIds: relatedClaimIds ?? this.relatedClaimIds,
      suggestedAction: suggestedAction ?? this.suggestedAction,
    );
  }

  @override
  String toString() => 'ValidationIssue($issueId, $issueType, $severity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationIssue && issueId == other.issueId;

  @override
  int get hashCode => issueId.hashCode;
}

/// ResponseValidation represents the result of validating an LLM response.
///
/// Contains the original response, extracted claims, validation issues,
/// and the overall validation result.
class ResponseValidation {
  /// Unique validation identifier.
  final String validationId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Original LLM response text.
  final String originalResponse;

  /// Claims extracted from the response.
  final List<VerifiableClaim> extractedClaims;

  /// Validation issues found.
  final List<ValidationIssue> issues;

  /// Overall validation result.
  final ValidationResult result;

  /// Response with unsupported claims marked/sanitized.
  final String? sanitizedResponse;

  /// Policy version used for validation.
  final String policyVersion;

  /// Point-in-time for fact graph queries.
  final DateTime asOf;

  /// When validation was performed.
  final DateTime createdAt;

  /// Duration of validation in milliseconds.
  final int durationMs;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const ResponseValidation({
    required this.validationId,
    required this.workspaceId,
    required this.originalResponse,
    this.extractedClaims = const [],
    this.issues = const [],
    this.result = ValidationResult.needsReview,
    this.sanitizedResponse,
    required this.policyVersion,
    required this.asOf,
    required this.createdAt,
    this.durationMs = 0,
    this.metadata = const {},
  });

  factory ResponseValidation.fromJson(Map<String, dynamic> json) {
    return ResponseValidation(
      validationId: json['validationId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      originalResponse: json['originalResponse'] as String? ?? '',
      extractedClaims: (json['extractedClaims'] as List<dynamic>?)
              ?.map((e) => VerifiableClaim.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => ValidationIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: ValidationResult.fromString(json['result'] as String? ?? ''),
      sanitizedResponse: json['sanitizedResponse'] as String?,
      policyVersion: json['policyVersion'] as String? ?? '',
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      durationMs: json['durationMs'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'validationId': validationId,
      'workspaceId': workspaceId,
      'originalResponse': originalResponse,
      if (extractedClaims.isNotEmpty)
        'extractedClaims': extractedClaims.map((e) => e.toJson()).toList(),
      if (issues.isNotEmpty) 'issues': issues.map((e) => e.toJson()).toList(),
      'result': result.name,
      if (sanitizedResponse != null) 'sanitizedResponse': sanitizedResponse,
      'policyVersion': policyVersion,
      'asOf': asOf.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'durationMs': durationMs,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  ResponseValidation copyWith({
    String? validationId,
    String? workspaceId,
    String? originalResponse,
    List<VerifiableClaim>? extractedClaims,
    List<ValidationIssue>? issues,
    ValidationResult? result,
    String? sanitizedResponse,
    String? policyVersion,
    DateTime? asOf,
    DateTime? createdAt,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    return ResponseValidation(
      validationId: validationId ?? this.validationId,
      workspaceId: workspaceId ?? this.workspaceId,
      originalResponse: originalResponse ?? this.originalResponse,
      extractedClaims: extractedClaims ?? this.extractedClaims,
      issues: issues ?? this.issues,
      result: result ?? this.result,
      sanitizedResponse: sanitizedResponse ?? this.sanitizedResponse,
      policyVersion: policyVersion ?? this.policyVersion,
      asOf: asOf ?? this.asOf,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if validation passed.
  bool get isPassed => result == ValidationResult.passed;

  /// Check if validation failed.
  bool get isFailed => result == ValidationResult.failed;

  /// Check if validation needs review.
  bool get needsReview => result == ValidationResult.needsReview;

  /// Get error-level issues.
  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == IssueSeverity.error).toList();

  /// Get warning-level issues.
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == IssueSeverity.warning).toList();

  /// Check if there are any error-level issues.
  bool get hasErrors => errors.isNotEmpty;

  /// Get count of supported claims.
  int get supportedClaimCount =>
      extractedClaims.where((c) => c.isSupported).length;

  /// Get count of conflicting claims.
  int get conflictingClaimCount =>
      extractedClaims.where((c) => c.isConflicting).length;

  @override
  String toString() =>
      'ResponseValidation($validationId, result: $result, claims: ${extractedClaims.length}, issues: ${issues.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseValidation && validationId == other.validationId;

  @override
  int get hashCode => validationId.hashCode;
}
