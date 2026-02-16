/// Claim entity for L2 ContextOps Layer.
///
/// Represents claims that need verification against the fact graph.
library;

/// Claim represents an assertion to be verified.
///
/// Claims are extracted from responses for fact-checking.
class Claim {
  /// Unique claim identifier.
  final String claimId;

  /// The claim text/statement.
  final String statement;

  /// Claim type/category.
  final ClaimType claimType;

  /// Subject of the claim.
  final String? subject;

  /// Predicate/relationship.
  final String? predicate;

  /// Object of the claim.
  final String? object;

  /// Source context (where the claim was made).
  final String? sourceContext;

  /// Source response ID.
  final String? responseId;

  /// Verification status.
  final VerificationStatus verificationStatus;

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

  const Claim({
    required this.claimId,
    required this.statement,
    this.claimType = ClaimType.factual,
    this.subject,
    this.predicate,
    this.object,
    this.sourceContext,
    this.responseId,
    this.verificationStatus = VerificationStatus.pending,
    this.verificationResult,
    this.supportingEvidenceIds = const [],
    this.contradictingEvidenceIds = const [],
    this.confidence = 0.0,
    required this.createdAt,
    this.verifiedAt,
    this.metadata = const {},
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      claimId: json['claimId'] as String? ?? '',
      statement: json['statement'] as String? ?? '',
      claimType:
          ClaimType.fromString(json['claimType'] as String? ?? 'factual'),
      subject: json['subject'] as String?,
      predicate: json['predicate'] as String?,
      object: json['object'] as String?,
      sourceContext: json['sourceContext'] as String?,
      responseId: json['responseId'] as String?,
      verificationStatus: VerificationStatus.fromString(
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

  Claim copyWith({
    String? claimId,
    String? statement,
    ClaimType? claimType,
    String? subject,
    String? predicate,
    String? object,
    String? sourceContext,
    String? responseId,
    VerificationStatus? verificationStatus,
    VerificationResult? verificationResult,
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    double? confidence,
    DateTime? createdAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Claim(
      claimId: claimId ?? this.claimId,
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

  /// Check if claim is verified.
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Check if claim is supported.
  bool get isSupported =>
      verificationResult?.verdict == VerificationVerdict.supported;

  /// Check if claim is refuted.
  bool get isRefuted =>
      verificationResult?.verdict == VerificationVerdict.refuted;

  @override
  String toString() => 'Claim($claimId, status: $verificationStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Claim && claimId == other.claimId;

  @override
  int get hashCode => claimId.hashCode;
}

/// Claim types.
enum ClaimType {
  /// Factual assertion (can be verified).
  factual,

  /// Temporal claim (about when something happened).
  temporal,

  /// Causal claim (about cause and effect).
  causal,

  /// Comparative claim.
  comparative,

  /// Quantitative claim (about numbers/amounts).
  quantitative,

  /// Opinion (cannot be verified).
  opinion,

  /// Hypothetical statement.
  hypothetical;

  static ClaimType fromString(String value) {
    return ClaimType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClaimType.factual,
    );
  }
}

/// Verification status.
enum VerificationStatus {
  /// Pending verification.
  pending,

  /// Currently being verified.
  verifying,

  /// Verification complete.
  verified,

  /// Unable to verify.
  unverifiable,

  /// Verification failed (error).
  failed;

  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

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
