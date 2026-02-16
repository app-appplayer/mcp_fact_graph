/// Entity entity for L1 FactGraph Layer.
///
/// Represents resolved entities (persons, places, things) in the graph.
library;

/// Entity represents a resolved real-world object in the fact graph.
///
/// Entities are created through entity resolution from candidates.
class Entity {
  /// Unique entity identifier.
  final String entityId;

  /// Entity type (person, organization, place, thing, etc.).
  final String entityType;

  /// Canonical name.
  final String name;

  /// Alternative names/aliases.
  final List<String> aliases;

  /// Entity attributes.
  final Map<String, dynamic> attributes;

  /// Entity status.
  final EntityStatus status;

  /// Candidate IDs that contributed to this entity.
  final List<String> sourceCandidateIds;

  /// Related entities (entityId -> relation type).
  final Map<String, String> relations;

  /// When this entity was created.
  final DateTime createdAt;

  /// When this entity was last updated.
  final DateTime updatedAt;

  /// Confidence score for entity resolution.
  final double confidence;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Entity({
    required this.entityId,
    required this.entityType,
    required this.name,
    this.aliases = const [],
    this.attributes = const {},
    this.status = EntityStatus.active,
    this.sourceCandidateIds = const [],
    this.relations = const {},
    required this.createdAt,
    required this.updatedAt,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      entityId: json['entityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      status: EntityStatus.fromString(json['status'] as String? ?? 'active'),
      sourceCandidateIds: (json['sourceCandidateIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      relations: (json['relations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'name': name,
      if (aliases.isNotEmpty) 'aliases': aliases,
      if (attributes.isNotEmpty) 'attributes': attributes,
      'status': status.name,
      if (sourceCandidateIds.isNotEmpty)
        'sourceCandidateIds': sourceCandidateIds,
      if (relations.isNotEmpty) 'relations': relations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'confidence': confidence,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Entity copyWith({
    String? entityId,
    String? entityType,
    String? name,
    List<String>? aliases,
    Map<String, dynamic>? attributes,
    EntityStatus? status,
    List<String>? sourceCandidateIds,
    Map<String, String>? relations,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return Entity(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      attributes: attributes ?? this.attributes,
      status: status ?? this.status,
      sourceCandidateIds: sourceCandidateIds ?? this.sourceCandidateIds,
      relations: relations ?? this.relations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if entity matches a name or alias.
  bool matchesName(String query) {
    final lowerQuery = query.toLowerCase();
    if (name.toLowerCase().contains(lowerQuery)) return true;
    return aliases.any((a) => a.toLowerCase().contains(lowerQuery));
  }

  @override
  String toString() => 'Entity($entityId, type: $entityType, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Entity && entityId == other.entityId;

  @override
  int get hashCode => entityId.hashCode;
}

/// Entity status.
enum EntityStatus {
  /// Active entity.
  active,

  /// Merged into another entity.
  merged,

  /// Archived.
  archived,

  /// Deleted.
  deleted;

  static EntityStatus fromString(String value) {
    return EntityStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EntityStatus.active,
    );
  }
}
