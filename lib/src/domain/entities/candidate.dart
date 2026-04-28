/// Candidate entity for L1 FactGraph Layer.
///
/// Represents a potential fact or event before confirmation.
/// Reference: 03-data-model-specification.md Section 2.3
library;

/// Candidate represents an assembled fact/event pending confirmation.
///
/// Candidates are created by merging fragments and can be confirmed
/// to become Events/Facts in the graph.
class Candidate {
  /// Unique candidate identifier.
  final String candidateId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Object type (expense, schedule, task, etc.).
  final String objectType;

  /// Candidate status.
  final CandidateStatus status;

  /// Resolution state tracking.
  /// Reference: Design Section 2.3 - unresolved | partial | resolved
  final ResolutionState resolutionState;

  /// Fragment IDs that compose this candidate.
  final List<String> fragmentIds;

  /// Evidence IDs associated with this candidate.
  final List<String> evidenceIds;

  /// Assembled fields from fragments (detailed tracking).
  final Map<String, CandidateField> fields;

  /// Linked entity candidates.
  /// Reference: Design Section 2.3 - EntityLink
  final List<EntityLink> links;

  /// Merge/split history for audit trail.
  /// Reference: Design Section 2.3 - AuditEntry
  final List<AuditEntry> auditTrail;

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
    required this.workspaceId,
    required this.objectType,
    this.status = CandidateStatus.open,
    this.resolutionState = ResolutionState.unresolved,
    this.fragmentIds = const [],
    this.evidenceIds = const [],
    this.fields = const {},
    this.links = const [],
    this.auditTrail = const [],
    required this.confidence,
    this.unresolvedIssues = const [],
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.resultingIds,
    this.metadata = const {},
  });

  /// Get fieldBag as simple Map for design compatibility.
  /// Reference: Design Section 2.3 - fieldBag: Map<String, dynamic>
  Map<String, dynamic> get fieldBag =>
      fields.map((key, value) => MapEntry(key, value.value));

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      candidateId: json['candidateId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      objectType: json['objectType'] as String? ?? '',
      status: CandidateStatus.fromString(json['status'] as String? ?? 'open'),
      resolutionState: ResolutionState.fromString(
          json['resolutionState'] as String? ?? 'unresolved'),
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
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => EntityLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      auditTrail: (json['auditTrail'] as List<dynamic>?)
              ?.map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'workspaceId': workspaceId,
      'objectType': objectType,
      'status': status.name,
      'resolutionState': resolutionState.name,
      if (fragmentIds.isNotEmpty) 'fragmentIds': fragmentIds,
      if (evidenceIds.isNotEmpty) 'evidenceIds': evidenceIds,
      if (fields.isNotEmpty)
        'fields': fields.map((k, v) => MapEntry(k, v.toJson())),
      if (links.isNotEmpty) 'links': links.map((l) => l.toJson()).toList(),
      if (auditTrail.isNotEmpty)
        'auditTrail': auditTrail.map((a) => a.toJson()).toList(),
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
    String? workspaceId,
    String? objectType,
    CandidateStatus? status,
    ResolutionState? resolutionState,
    List<String>? fragmentIds,
    List<String>? evidenceIds,
    Map<String, CandidateField>? fields,
    List<EntityLink>? links,
    List<AuditEntry>? auditTrail,
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
      workspaceId: workspaceId ?? this.workspaceId,
      objectType: objectType ?? this.objectType,
      status: status ?? this.status,
      resolutionState: resolutionState ?? this.resolutionState,
      fragmentIds: fragmentIds ?? this.fragmentIds,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      fields: fields ?? this.fields,
      links: links ?? this.links,
      auditTrail: auditTrail ?? this.auditTrail,
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
/// Reference: Design Section 2.3 - open | qualifying | ready | confirmed | rejected | promoted | orphaned | merged
enum CandidateStatus {
  /// Initial state - awaiting fragments.
  open,

  /// Evaluation in progress.
  qualifying,

  /// All required fragments attached, awaiting confirmation.
  ready,

  /// Accepted as valid entity source.
  confirmed,

  /// Failed validation.
  rejected,

  /// Entity created from this candidate.
  promoted,

  /// Source evidence deleted (cascade).
  orphaned,

  /// Merged into another candidate.
  merged;

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

/// Resolution state for candidates.
/// Reference: Design Section 2.3 - Status vs ResolutionState Matrix
enum ResolutionState {
  /// No required fields present.
  unresolved,

  /// Some required fields present.
  partial,

  /// All required fields present.
  resolved;

  static ResolutionState fromString(String value) {
    return ResolutionState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ResolutionState.unresolved,
    );
  }
}

/// Entity link for candidate.
/// Reference: Design Section 2.3 - EntityLink
class EntityLink {
  /// Linked entity ID.
  final String entityId;

  /// Role of the entity (owner, vendor, project, etc.).
  final String role;

  /// Link status.
  final LinkStatus status;

  const EntityLink({
    required this.entityId,
    required this.role,
    this.status = LinkStatus.proposed,
  });

  factory EntityLink.fromJson(Map<String, dynamic> json) {
    return EntityLink(
      entityId: json['entityId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: LinkStatus.fromString(json['status'] as String? ?? 'proposed'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'role': role,
      'status': status.name,
    };
  }
}

/// Link status.
enum LinkStatus {
  /// Proposed link.
  proposed,

  /// Confirmed link.
  confirmed;

  static LinkStatus fromString(String value) {
    return LinkStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LinkStatus.proposed,
    );
  }
}

/// Audit entry for tracking candidate changes.
/// Reference: Design Section 2.3 - AuditEntry
class AuditEntry {
  /// When the action occurred.
  final DateTime timestamp;

  /// Action type (create, merge, split, update, confirm).
  final String action;

  /// Related candidate/fragment ID.
  final String? sourceId;

  /// Field changes.
  final Map<String, dynamic>? changes;

  /// Reason for the action.
  final String? reason;

  const AuditEntry({
    required this.timestamp,
    required this.action,
    this.sourceId,
    this.changes,
    this.reason,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      action: json['action'] as String? ?? '',
      sourceId: json['sourceId'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      if (sourceId != null) 'sourceId': sourceId,
      if (changes != null) 'changes': changes,
      if (reason != null) 'reason': reason,
    };
  }
}
