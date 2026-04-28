/// Relation entity model.
///
/// Represents connections between entities.
/// Design: 03-data-model-specification.md Section 2.5
library;

/// Status of a relation.
enum RelationStatus {
  /// Relation proposed by system.
  proposed,

  /// Relation confirmed by user or policy.
  confirmed;

  /// Create from string.
  static RelationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'proposed':
        return RelationStatus.proposed;
      case 'confirmed':
        return RelationStatus.confirmed;
      default:
        return RelationStatus.proposed;
    }
  }
}

/// Relation represents connections between entities.
class Relation {
  /// Unique identifier.
  final String relationId;

  /// Source entity ID.
  final String fromEntityId;

  /// Target entity ID.
  final String toEntityId;

  /// Relation type: owns, works_for, supplies, located_at, part_of, etc.
  final String relationType;

  /// Relation status.
  final RelationStatus status;

  /// When the relation started being valid.
  final DateTime? validFrom;

  /// When the relation stopped being valid.
  final DateTime? validTo;

  /// Supporting evidence references.
  final List<String> evidenceRefs;

  /// Additional attributes for the relation.
  final Map<String, dynamic> attributes;

  /// When the relation was created.
  final DateTime createdAt;

  /// When the relation was last updated.
  final DateTime? updatedAt;

  const Relation({
    required this.relationId,
    required this.fromEntityId,
    required this.toEntityId,
    required this.relationType,
    this.status = RelationStatus.proposed,
    this.validFrom,
    this.validTo,
    this.evidenceRefs = const [],
    this.attributes = const {},
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON.
  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      relationId: json['relationId'] as String? ?? '',
      fromEntityId: json['fromEntityId'] as String? ?? '',
      toEntityId: json['toEntityId'] as String? ?? '',
      relationType: json['relationType'] as String? ?? '',
      status:
          RelationStatus.fromString(json['status'] as String? ?? 'proposed'),
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : null,
      validTo: json['validTo'] != null
          ? DateTime.parse(json['validTo'] as String)
          : null,
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'relationId': relationId,
      'fromEntityId': fromEntityId,
      'toEntityId': toEntityId,
      'relationType': relationType,
      'status': status.name,
      if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
      if (validTo != null) 'validTo': validTo!.toIso8601String(),
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      if (attributes.isNotEmpty) 'attributes': attributes,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  Relation copyWith({
    String? relationId,
    String? fromEntityId,
    String? toEntityId,
    String? relationType,
    RelationStatus? status,
    DateTime? validFrom,
    DateTime? validTo,
    List<String>? evidenceRefs,
    Map<String, dynamic>? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Relation(
      relationId: relationId ?? this.relationId,
      fromEntityId: fromEntityId ?? this.fromEntityId,
      toEntityId: toEntityId ?? this.toEntityId,
      relationType: relationType ?? this.relationType,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the relation is currently valid.
  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return true;
  }

  /// Check if relation is confirmed.
  bool get isConfirmed => status == RelationStatus.confirmed;

  /// Confirm this relation.
  Relation confirm() {
    return copyWith(
      status: RelationStatus.confirmed,
      updatedAt: DateTime.now(),
    );
  }

  /// End this relation.
  Relation end({DateTime? endDate}) {
    return copyWith(
      validTo: endDate ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Common relation types.
abstract class RelationTypes {
  /// Ownership relation.
  static const String owns = 'owns';

  /// Employment relation.
  static const String worksFor = 'works_for';

  /// Supply chain relation.
  static const String supplies = 'supplies';

  /// Location relation.
  static const String locatedAt = 'located_at';

  /// Hierarchical relation.
  static const String partOf = 'part_of';

  /// Manages relation.
  static const String manages = 'manages';

  /// Reports to relation.
  static const String reportsTo = 'reports_to';

  /// Created by relation.
  static const String createdBy = 'created_by';

  /// Assigned to relation.
  static const String assignedTo = 'assigned_to';

  /// Related to (general).
  static const String relatedTo = 'related_to';
}
