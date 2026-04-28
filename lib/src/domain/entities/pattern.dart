/// Pattern entity for L3 SkillOps Layer.
///
/// Represents recurring patterns discovered in the fact graph.
/// Reference: 03-data-model-specification.md Section 2.16.1
library;

/// Pattern represents a discovered recurring pattern.
///
/// Patterns emerge from analyzing facts and can be promoted to skills.
class Pattern {
  /// Unique pattern identifier.
  final String patternId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Pattern name.
  final String name;

  /// Pattern description.
  final String description;

  /// Pattern scope for context.
  /// Reference: Design Section 2.16.1 - person | team | project | global.
  final PatternScope scope;

  /// Observable characteristics of this pattern.
  /// Reference: Design Section 2.16.1 - features: Map<String, dynamic>.
  final Map<String, dynamic> features;

  /// Supporting fact IDs that contribute to this pattern.
  final List<String> supportingFactIds;

  /// Evidence references for traceability.
  /// Reference: Design Section 2.16.1 - List<String>.
  final List<String> evidenceRefs;

  /// Confidence score for pattern validity.
  final double confidence;

  /// Start of temporal validity.
  final DateTime? validFrom;

  /// End of temporal validity.
  final DateTime? validTo;

  /// Last time pattern was observed.
  final DateTime lastObservedAt;

  /// Pattern status.
  /// Reference: Design Section 2.16.1 - observed | proposed | confirmed | rejected | merged | codified | deprecated | archived
  final PatternStatus status;

  /// LLM suggestion that created this pattern.
  final String? derivedFrom;

  /// When this pattern was created.
  final DateTime createdAt;

  /// When this pattern was last updated.
  final DateTime updatedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Pattern({
    required this.patternId,
    required this.workspaceId,
    required this.name,
    required this.description,
    this.scope = PatternScope.person,
    this.features = const {},
    this.supportingFactIds = const [],
    this.evidenceRefs = const [],
    this.confidence = 0.0,
    this.validFrom,
    this.validTo,
    required this.lastObservedAt,
    this.status = PatternStatus.proposed,
    this.derivedFrom,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      patternId: json['patternId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scope: PatternScope.fromString(json['scope'] as String? ?? 'person'),
      features: json['features'] as Map<String, dynamic>? ?? {},
      supportingFactIds: (json['supportingFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : null,
      validTo: json['validTo'] != null
          ? DateTime.parse(json['validTo'] as String)
          : null,
      lastObservedAt: json['lastObservedAt'] != null
          ? DateTime.parse(json['lastObservedAt'] as String)
          : DateTime.now(),
      status:
          PatternStatus.fromString(json['status'] as String? ?? 'proposed'),
      derivedFrom: json['derivedFrom'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'scope': scope.name,
      if (features.isNotEmpty) 'features': Map<String, dynamic>.from(features),
      if (supportingFactIds.isNotEmpty) 'supportingFactIds': supportingFactIds,
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      'confidence': confidence,
      if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
      if (validTo != null) 'validTo': validTo!.toIso8601String(),
      'lastObservedAt': lastObservedAt.toIso8601String(),
      'status': status.name,
      if (derivedFrom != null) 'derivedFrom': derivedFrom,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Pattern copyWith({
    String? patternId,
    String? workspaceId,
    String? name,
    String? description,
    PatternScope? scope,
    Map<String, dynamic>? features,
    List<String>? supportingFactIds,
    List<String>? evidenceRefs,
    double? confidence,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? lastObservedAt,
    PatternStatus? status,
    String? derivedFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Pattern(
      patternId: patternId ?? this.patternId,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      features: features ?? this.features,
      supportingFactIds: supportingFactIds ?? this.supportingFactIds,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      confidence: confidence ?? this.confidence,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      status: status ?? this.status,
      derivedFrom: derivedFrom ?? this.derivedFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if pattern is confirmed and active.
  bool get isActive => status == PatternStatus.confirmed;

  /// Check if pattern has high confidence (>= 0.8).
  bool get isHighConfidence => confidence >= 0.8;

  @override
  String toString() => 'Pattern($patternId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pattern && patternId == other.patternId;

  @override
  int get hashCode => patternId.hashCode;
}

/// Pattern status.
/// Reference: Design Section 2.16.1 - observed | proposed | confirmed | rejected | merged | codified | deprecated | archived
enum PatternStatus {
  /// Mining output - initial observation.
  observed,

  /// Observation threshold met - pending confirmation.
  proposed,

  /// User confirms or confidence threshold met.
  confirmed,

  /// Failed validation.
  rejected,

  /// Duplicate found - merged into another pattern.
  merged,

  /// Skill generated from this pattern.
  codified,

  /// No longer relevant.
  deprecated,

  /// Cleanup - removed from active use.
  archived;

  static PatternStatus fromString(String value) {
    return PatternStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PatternStatus.proposed,
    );
  }
}

/// Pattern scope levels.
/// Reference: Design Section 2.16.1 - person | team | project | global
enum PatternScope {
  /// Person-specific pattern.
  person,

  /// Team-level pattern.
  team,

  /// Project-level pattern.
  project,

  /// Global pattern across all workspaces.
  global;

  static PatternScope fromString(String value) {
    return PatternScope.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PatternScope.person,
    );
  }
}
