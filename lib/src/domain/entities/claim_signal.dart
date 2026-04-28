/// ClaimSignal entity for L2-L3 Bridge.
///
/// Represents signals generated from claim validation that feed into
/// pattern mining. Bridges the ContextOps (L2) and SkillOps (L3) layers.
/// Reference: 03-data-model-specification.md Section 2.15.3.2
library;

/// Type of claim signal.
enum ClaimSignalType {
  /// Positive signal - claim was validated/supported.
  positive,

  /// Negative signal - claim was refuted.
  negative,

  /// Conflict signal - claim has conflicting evidence.
  conflict,

  /// Pending signal - awaiting further validation.
  pending;

  static ClaimSignalType fromString(String value) {
    return ClaimSignalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClaimSignalType.pending,
    );
  }
}

/// Outcome details from claim validation.
/// Reference: Design Section 2.15.3.1 - ValidationOutcome (class, not enum).
class ValidationOutcome {
  /// Whether claim passed validation.
  final bool isValid;

  /// Reason if rejected.
  final String? rejectionReason;

  /// Facts that support this claim.
  final List<String> supportingFactIds;

  /// Facts that contradict this claim.
  final List<String> contradictingFactIds;

  /// Strength of evidence (0.0 to 1.0).
  final double evidenceStrength;

  const ValidationOutcome({
    required this.isValid,
    this.rejectionReason,
    this.supportingFactIds = const [],
    this.contradictingFactIds = const [],
    this.evidenceStrength = 0.0,
  });

  factory ValidationOutcome.fromJson(Map<String, dynamic> json) {
    return ValidationOutcome(
      isValid: json['isValid'] as bool? ?? false,
      rejectionReason: json['rejectionReason'] as String?,
      supportingFactIds: (json['supportingFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contradictingFactIds: (json['contradictingFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      evidenceStrength: (json['evidenceStrength'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (supportingFactIds.isNotEmpty) 'supportingFactIds': supportingFactIds,
      if (contradictingFactIds.isNotEmpty)
        'contradictingFactIds': contradictingFactIds,
      'evidenceStrength': evidenceStrength,
    };
  }

  @override
  String toString() =>
      'ValidationOutcome(isValid: $isValid, strength: $evidenceStrength)';
}

/// Features extracted from a claim for pattern mining.
/// Reference: Design Section 2.15.3.2 - ClaimFeatures.
class ClaimFeatures {
  /// Type of the claim (aligned with ClaimType).
  final String claimType;

  /// Domain of the claim.
  final String domain;

  /// Structural pattern (e.g., "X causes Y").
  final String structuralPattern;

  /// Fact types referenced.
  final List<String> factTypes;

  /// Response context where claim appeared.
  final Map<String, dynamic> responseContext;

  /// Validation outcome details.
  final ValidationOutcome outcome;

  const ClaimFeatures({
    required this.claimType,
    required this.domain,
    required this.structuralPattern,
    this.factTypes = const [],
    this.responseContext = const {},
    this.outcome = const ValidationOutcome(isValid: false),
  });

  factory ClaimFeatures.fromJson(Map<String, dynamic> json) {
    return ClaimFeatures(
      claimType: json['claimType'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      structuralPattern: json['structuralPattern'] as String? ?? '',
      factTypes: (json['factTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      responseContext: json['responseContext'] as Map<String, dynamic>? ?? {},
      outcome: json['outcome'] != null
          ? ValidationOutcome.fromJson(json['outcome'] as Map<String, dynamic>)
          : const ValidationOutcome(isValid: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claimType': claimType,
      'domain': domain,
      'structuralPattern': structuralPattern,
      if (factTypes.isNotEmpty) 'factTypes': factTypes,
      if (responseContext.isNotEmpty) 'responseContext': responseContext,
      'outcome': outcome.toJson(),
    };
  }

  @override
  String toString() => 'ClaimFeatures(type: $claimType, domain: $domain, '
      'pattern: $structuralPattern)';
}

/// Context in which a claim was validated.
/// Reference: Design Section 2.15.3.1 - ValidationContext.
class ValidationContext {
  /// Parent ResponseValidation ID.
  final String validationId;

  /// Type of query that generated the response.
  final String queryType;

  /// LLM model used (if applicable).
  final String? llmModel;

  /// When validation occurred.
  final DateTime validatedAt;

  /// Policy version used for validation.
  final String policyVersion;

  /// Additional context metadata.
  final Map<String, dynamic>? metadata;

  const ValidationContext({
    required this.validationId,
    required this.queryType,
    this.llmModel,
    required this.validatedAt,
    required this.policyVersion,
    this.metadata,
  });

  factory ValidationContext.fromJson(Map<String, dynamic> json) {
    return ValidationContext(
      validationId: json['validationId'] as String? ?? '',
      queryType: json['queryType'] as String? ?? '',
      llmModel: json['llmModel'] as String?,
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String? ?? '1.0.0',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'validationId': validationId,
      'queryType': queryType,
      if (llmModel != null) 'llmModel': llmModel,
      'validatedAt': validatedAt.toIso8601String(),
      'policyVersion': policyVersion,
      if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'ValidationContext(validationId: $validationId, queryType: $queryType)';
}

/// ClaimSignal represents a signal from claim validation for pattern mining.
///
/// These signals bridge L2 (ContextOps) claim validation with L3 (SkillOps)
/// pattern mining and learning.
/// Reference: Design Section 2.15.3.2
class ClaimSignal {
  /// Unique signal identifier.
  final String signalId;

  /// Source claim ID.
  final String claimId;

  /// Signal type.
  final ClaimSignalType type;

  /// When the signal was generated.
  final DateTime timestamp;

  /// Validation context.
  final ValidationContext context;

  /// Features extracted for pattern mining.
  final ClaimFeatures features;

  /// Signal strength (0.0 to 1.0).
  final double signalStrength;

  /// When the record was created.
  final DateTime createdAt;

  const ClaimSignal({
    required this.signalId,
    required this.claimId,
    required this.type,
    required this.timestamp,
    required this.context,
    required this.features,
    this.signalStrength = 0.5,
    required this.createdAt,
  });

  factory ClaimSignal.fromJson(Map<String, dynamic> json) {
    return ClaimSignal(
      signalId: json['signalId'] as String? ?? '',
      claimId: json['claimId'] as String? ?? '',
      type: ClaimSignalType.fromString(json['type'] as String? ?? ''),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      context: json['context'] != null
          ? ValidationContext.fromJson(json['context'] as Map<String, dynamic>)
          : ValidationContext(
              validationId: '',
              queryType: '',
              validatedAt: DateTime.now(),
              policyVersion: '1.0.0',
            ),
      features: json['features'] != null
          ? ClaimFeatures.fromJson(json['features'] as Map<String, dynamic>)
          : const ClaimFeatures(
              claimType: '', domain: '', structuralPattern: ''),
      signalStrength: (json['signalStrength'] as num?)?.toDouble() ?? 0.5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signalId': signalId,
      'claimId': claimId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'context': context.toJson(),
      'features': features.toJson(),
      'signalStrength': signalStrength,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ClaimSignal copyWith({
    String? signalId,
    String? claimId,
    ClaimSignalType? type,
    DateTime? timestamp,
    ValidationContext? context,
    ClaimFeatures? features,
    double? signalStrength,
    DateTime? createdAt,
  }) {
    return ClaimSignal(
      signalId: signalId ?? this.signalId,
      claimId: claimId ?? this.claimId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      features: features ?? this.features,
      signalStrength: signalStrength ?? this.signalStrength,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ClaimSignal($signalId, type: $type, strength: $signalStrength)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimSignal && signalId == other.signalId;

  @override
  int get hashCode => signalId.hashCode;
}
