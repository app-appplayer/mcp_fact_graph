/// Candidate entity for L1 FactGraph Layer.
///
/// Represents a potential fact or event before confirmation.
library;

/// Candidate represents an assembled fact/event pending confirmation.
///
/// Candidates are created by merging fragments and can be confirmed
/// to become Events/Facts in the graph.
class Candidate {
  /// Unique candidate identifier.
  final String candidateId;

  /// Object type (expense, schedule, task, etc.).
  final String objectType;

  /// Candidate status.
  final CandidateStatus status;

  /// Fragment IDs that compose this candidate.
  final List<String> fragmentIds;

  /// Evidence IDs associated with this candidate.
  final List<String> evidenceIds;

  /// Assembled fields from fragments.
  final Map<String, CandidateField> fields;

  /// Overall confidence (min of field confidences).
  final double confidence;

  /// Unresolved issues preventing confirmation.
  final List<UnresolvedIssue> unresolvedIssues;

  /// When this candidate was created.
  final DateTime createdAt;

  /// When this candidate was last updated.
  final DateTime updatedAt;

  /// When this candidate was confirmed (if confirmed).
  final DateTime? confirmedAt;

  /// Resulting entity/event IDs after confirmation.
  final List<String>? resultingIds;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Candidate({
    required this.candidateId,
    required this.objectType,
    this.status = CandidateStatus.open,
    this.fragmentIds = const [],
    this.evidenceIds = const [],
    this.fields = const {},
    required this.confidence,
    this.unresolvedIssues = const [],
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.resultingIds,
    this.metadata = const {},
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      candidateId: json['candidateId'] as String? ?? '',
      objectType: json['objectType'] as String? ?? '',
      status: CandidateStatus.fromString(json['status'] as String? ?? 'open'),
      fragmentIds: (json['fragmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      evidenceIds: (json['evidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              CandidateField.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      unresolvedIssues: (json['unresolvedIssues'] as List<dynamic>?)
              ?.map((e) => UnresolvedIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      resultingIds: (json['resultingIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'objectType': objectType,
      'status': status.name,
      if (fragmentIds.isNotEmpty) 'fragmentIds': fragmentIds,
      if (evidenceIds.isNotEmpty) 'evidenceIds': evidenceIds,
      if (fields.isNotEmpty)
        'fields': fields.map((k, v) => MapEntry(k, v.toJson())),
      'confidence': confidence,
      if (unresolvedIssues.isNotEmpty)
        'unresolvedIssues': unresolvedIssues.map((u) => u.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (resultingIds != null) 'resultingIds': resultingIds,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Candidate copyWith({
    String? candidateId,
    String? objectType,
    CandidateStatus? status,
    List<String>? fragmentIds,
    List<String>? evidenceIds,
    Map<String, CandidateField>? fields,
    double? confidence,
    List<UnresolvedIssue>? unresolvedIssues,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    List<String>? resultingIds,
    Map<String, dynamic>? metadata,
  }) {
    return Candidate(
      candidateId: candidateId ?? this.candidateId,
      objectType: objectType ?? this.objectType,
      status: status ?? this.status,
      fragmentIds: fragmentIds ?? this.fragmentIds,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      fields: fields ?? this.fields,
      confidence: confidence ?? this.confidence,
      unresolvedIssues: unresolvedIssues ?? this.unresolvedIssues,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      resultingIds: resultingIds ?? this.resultingIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if candidate is ready for confirmation.
  bool get isReadyForConfirmation =>
      status == CandidateStatus.open && unresolvedIssues.isEmpty;

  /// Check if candidate has required fields.
  bool hasRequiredFields(List<String> requiredFields) {
    return requiredFields.every((f) => fields.containsKey(f));
  }

  @override
  String toString() =>
      'Candidate($candidateId, type: $objectType, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Candidate && candidateId == other.candidateId;

  @override
  int get hashCode => candidateId.hashCode;
}

/// Candidate status.
enum CandidateStatus {
  /// Open for editing/merging.
  open,

  /// Pending review.
  pendingReview,

  /// Confirmed (promoted to event/fact).
  confirmed,

  /// Rejected.
  rejected,

  /// Merged into another candidate.
  merged,

  /// Split into multiple candidates.
  split;

  static CandidateStatus fromString(String value) {
    return CandidateStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CandidateStatus.open,
    );
  }
}

/// A field in a candidate with value and confidence.
class CandidateField {
  /// Field value.
  final dynamic value;

  /// Confidence score.
  final double confidence;

  /// Source fragment ID.
  final String? sourceFragmentId;

  /// Whether this field is confirmed.
  final bool confirmed;

  const CandidateField({
    required this.value,
    required this.confidence,
    this.sourceFragmentId,
    this.confirmed = false,
  });

  factory CandidateField.fromJson(Map<String, dynamic> json) {
    return CandidateField(
      value: json['value'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sourceFragmentId: json['sourceFragmentId'] as String?,
      confirmed: json['confirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'confidence': confidence,
      if (sourceFragmentId != null) 'sourceFragmentId': sourceFragmentId,
      if (confirmed) 'confirmed': confirmed,
    };
  }
}

/// An unresolved issue preventing candidate confirmation.
class UnresolvedIssue {
  /// Issue code.
  final String code;

  /// Issue type.
  final IssueType type;

  /// Affected field (if applicable).
  final String? field;

  /// Issue description.
  final String description;

  /// Suggested resolution.
  final String? suggestion;

  const UnresolvedIssue({
    required this.code,
    required this.type,
    this.field,
    required this.description,
    this.suggestion,
  });

  factory UnresolvedIssue.fromJson(Map<String, dynamic> json) {
    return UnresolvedIssue(
      code: json['code'] as String? ?? '',
      type: IssueType.fromString(json['type'] as String? ?? 'unknown'),
      field: json['field'] as String?,
      description: json['description'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type.name,
      if (field != null) 'field': field,
      'description': description,
      if (suggestion != null) 'suggestion': suggestion,
    };
  }
}

/// Types of unresolved issues.
enum IssueType {
  /// Missing required field.
  missingField,

  /// Low confidence value.
  lowConfidence,

  /// Conflicting values.
  conflict,

  /// Entity not resolved.
  entityUnresolved,

  /// Relation unclear.
  relationUnclear,

  /// Policy violation.
  policyViolation,

  /// Unknown issue.
  unknown;

  static IssueType fromString(String value) {
    return IssueType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IssueType.unknown,
    );
  }
}
