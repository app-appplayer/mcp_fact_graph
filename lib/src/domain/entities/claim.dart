/// VerifiableClaim entity for L2 ContextOps Layer.
///
/// Represents claims that need verification against the fact graph.
/// Internal implementation wrapping canonical Claim from mcp_bundle.
/// Reference: 03-data-model-specification.md Section 2.15.3
library;

/// VerifiableClaim represents an assertion to be verified against the fact graph.
///
/// This claim type has RDF-style subject/predicate/object structure
/// and full verification workflow support.
///
/// Note: For simple claims from skill execution, use Claim from mcp_bundle.
class VerifiableClaim {
  /// Unique claim identifier.
  final String claimId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// The claim text/statement.
  final String statement;

  /// Claim type/category (aligned with ClaimType from mcp_bundle).
  final ClaimType claimType;

  /// Subject of the claim (RDF-style).
  final String? subject;

  /// Predicate/relationship (RDF-style).
  final String? predicate;

  /// Object of the claim (RDF-style).
  final String? object;

  /// Source context (where the claim was made).
  final String? sourceContext;

  /// Source response ID.
  final String? responseId;

  /// Verification status (aligned with ClaimStatus from mcp_bundle).
  final ClaimStatus verificationStatus;

  /// Verification result.
  final VerificationResult? verificationResult;

  /// Supporting evidence IDs.
  final List<String> supportingEvidenceIds;

  /// Contradicting evidence IDs.
  final List<String> contradictingEvidenceIds;

  /// Confidence in verification.
  final double confidence;

  /// When the claim was extracted.
  final DateTime createdAt;

  /// When verification was performed.
  final DateTime? verifiedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const VerifiableClaim({
    required this.claimId,
    required this.workspaceId,
    required this.statement,
    this.claimType = ClaimType.fact,
    this.subject,
    this.predicate,
    this.object,
    this.sourceContext,
    this.responseId,
    this.verificationStatus = ClaimStatus.pending,
    this.verificationResult,
    this.supportingEvidenceIds = const [],
    this.contradictingEvidenceIds = const [],
    this.confidence = 0.0,
    required this.createdAt,
    this.verifiedAt,
    this.metadata = const {},
  });

  factory VerifiableClaim.fromJson(Map<String, dynamic> json) {
    return VerifiableClaim(
      claimId: json['claimId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      statement: json['statement'] as String? ?? '',
      claimType: ClaimType.fromString(
          json['claimType'] as String? ?? 'fact'),
      subject: json['subject'] as String?,
      predicate: json['predicate'] as String?,
      object: json['object'] as String?,
      sourceContext: json['sourceContext'] as String?,
      responseId: json['responseId'] as String?,
      verificationStatus: ClaimStatus.fromString(
          json['verificationStatus'] as String? ?? 'pending'),
      verificationResult: json['verificationResult'] != null
          ? VerificationResult.fromJson(
              json['verificationResult'] as Map<String, dynamic>)
          : null,
      supportingEvidenceIds: (json['supportingEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contradictingEvidenceIds:
          (json['contradictingEvidenceIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claimId': claimId,
      'workspaceId': workspaceId,
      'statement': statement,
      'claimType': claimType.name,
      if (subject != null) 'subject': subject,
      if (predicate != null) 'predicate': predicate,
      if (object != null) 'object': object,
      if (sourceContext != null) 'sourceContext': sourceContext,
      if (responseId != null) 'responseId': responseId,
      'verificationStatus': verificationStatus.name,
      if (verificationResult != null)
        'verificationResult': verificationResult!.toJson(),
      if (supportingEvidenceIds.isNotEmpty)
        'supportingEvidenceIds': supportingEvidenceIds,
      if (contradictingEvidenceIds.isNotEmpty)
        'contradictingEvidenceIds': contradictingEvidenceIds,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  VerifiableClaim copyWith({
    String? claimId,
    String? workspaceId,
    String? statement,
    ClaimType? claimType,
    String? subject,
    String? predicate,
    String? object,
    String? sourceContext,
    String? responseId,
    ClaimStatus? verificationStatus,
    VerificationResult? verificationResult,
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    double? confidence,
    DateTime? createdAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VerifiableClaim(
      claimId: claimId ?? this.claimId,
      workspaceId: workspaceId ?? this.workspaceId,
      statement: statement ?? this.statement,
      claimType: claimType ?? this.claimType,
      subject: subject ?? this.subject,
      predicate: predicate ?? this.predicate,
      object: object ?? this.object,
      sourceContext: sourceContext ?? this.sourceContext,
      responseId: responseId ?? this.responseId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationResult: verificationResult ?? this.verificationResult,
      supportingEvidenceIds:
          supportingEvidenceIds ?? this.supportingEvidenceIds,
      contradictingEvidenceIds:
          contradictingEvidenceIds ?? this.contradictingEvidenceIds,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if claim is supported.
  bool get isSupported =>
      verificationStatus == ClaimStatus.supported;

  /// Check if claim is conflicting.
  bool get isConflicting =>
      verificationStatus == ClaimStatus.conflicting;

  @override
  String toString() => 'VerifiableClaim($claimId, status: $verificationStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifiableClaim && claimId == other.claimId;

  @override
  int get hashCode => claimId.hashCode;
}

/// Claim type (aligned with ClaimType from mcp_bundle).
/// Reference: Design Section 2.15.3
enum ClaimType {
  // Factual types

  /// General factual claim.
  fact,

  /// Date/time claim.
  date,

  /// Monetary amount claim.
  amount,

  /// Numeric quantity claim.
  quantity,

  /// Classification claim.
  category,

  /// Entity reference claim.
  entity,

  /// Relationship claim.
  relation,

  /// Temporal claim (about when something happened).
  temporal,

  /// Causal claim (about cause and effect).
  causal,

  /// Comparative claim.
  comparative,

  /// Quantitative claim (about numbers/amounts).
  quantitative,

  // Derived types

  /// Derived conclusion.
  conclusion,

  /// Suggested action.
  recommendation,

  /// Uncertain claim.
  speculation,

  /// Observed pattern.
  observation,

  /// Future prediction.
  prediction,

  /// Opinion (subjective, cannot be verified).
  opinion,

  /// Hypothetical/conditional statement.
  hypothetical;

  static ClaimType fromString(String value) {
    return ClaimType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClaimType.fact,
    );
  }
}

/// Backward compatibility aliases.
@Deprecated('Use ClaimType instead')
typedef VerifiableClaimType = ClaimType;

/// Claim status (aligned with ClaimStatus from mcp_bundle).
/// Reference: Design Section 2.15.3
enum ClaimStatus {
  /// Pending verification.
  pending,

  /// Currently being verified.
  verifying,

  /// Validated with evidence.
  supported,

  /// No supporting evidence.
  unsupported,

  /// Contradicts existing facts.
  conflicting,

  /// Some evidence found.
  partiallySupported,

  /// Cannot be verified.
  unverifiable,

  /// Explicitly uncertain.
  speculation;

  static ClaimStatus fromString(String value) {
    return ClaimStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClaimStatus.pending,
    );
  }
}

/// Backward compatibility alias.
@Deprecated('Use ClaimStatus instead')
typedef VerificationStatus = ClaimStatus;

/// Verification result.
class VerificationResult {
  /// Verification verdict.
  final VerificationVerdict verdict;

  /// Confidence in verdict.
  final double confidence;

  /// Explanation of the verdict.
  final String explanation;

  /// Evidence used for verification.
  final List<EvidenceReference> evidence;

  /// Alternative interpretations.
  final List<String> alternatives;

  /// Verification duration in milliseconds.
  final int durationMs;

  const VerificationResult({
    required this.verdict,
    required this.confidence,
    required this.explanation,
    this.evidence = const [],
    this.alternatives = const [],
    this.durationMs = 0,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verdict: VerificationVerdict.fromString(
          json['verdict'] as String? ?? 'unknown'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map(
                  (e) => EvidenceReference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verdict': verdict.name,
      'confidence': confidence,
      'explanation': explanation,
      if (evidence.isNotEmpty)
        'evidence': evidence.map((e) => e.toJson()).toList(),
      if (alternatives.isNotEmpty) 'alternatives': alternatives,
      'durationMs': durationMs,
    };
  }
}

/// Verification verdict.
enum VerificationVerdict {
  /// Claim is supported by evidence.
  supported,

  /// Claim is partially supported.
  partiallySupported,

  /// Claim is refuted by evidence.
  refuted,

  /// Evidence is mixed/conflicting.
  conflicting,

  /// Not enough evidence.
  insufficientEvidence,

  /// Unable to determine.
  unknown;

  static VerificationVerdict fromString(String value) {
    return VerificationVerdict.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationVerdict.unknown,
    );
  }
}

/// Reference to evidence used in verification.
class EvidenceReference {
  /// Evidence ID.
  final String evidenceId;

  /// Evidence type (event, entity, document).
  final String evidenceType;

  /// Relevance to the claim.
  final double relevance;

  /// Whether it supports or contradicts.
  final EvidenceRelation relation;

  /// Relevant excerpt.
  final String? excerpt;

  const EvidenceReference({
    required this.evidenceId,
    required this.evidenceType,
    this.relevance = 0.0,
    this.relation = EvidenceRelation.neutral,
    this.excerpt,
  });

  factory EvidenceReference.fromJson(Map<String, dynamic> json) {
    return EvidenceReference(
      evidenceId: json['evidenceId'] as String? ?? '',
      evidenceType: json['evidenceType'] as String? ?? '',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      relation:
          EvidenceRelation.fromString(json['relation'] as String? ?? 'neutral'),
      excerpt: json['excerpt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'evidenceType': evidenceType,
      'relevance': relevance,
      'relation': relation.name,
      if (excerpt != null) 'excerpt': excerpt,
    };
  }
}

/// Evidence relation to claim.
enum EvidenceRelation {
  /// Supports the claim.
  supports,

  /// Contradicts the claim.
  contradicts,

  /// Neutral/unrelated.
  neutral;

  static EvidenceRelation fromString(String value) {
    return EvidenceRelation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvidenceRelation.neutral,
    );
  }
}
