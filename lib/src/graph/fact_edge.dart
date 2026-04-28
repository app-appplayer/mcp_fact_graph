/// Fact edge representation connecting nodes in the knowledge graph.
library;

/// An edge connecting two nodes in the fact graph.
class FactEdge {
  FactEdge({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.targetId,
    this.label,
    this.weight,
    this.confidence,
    this.bidirectional = false,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? metadata,
  })  : properties = properties ?? {},
        metadata = metadata ?? {};

  /// Unique edge identifier.
  final String id;

  /// Edge type/relationship.
  final EdgeType type;

  /// Source node ID.
  final String sourceId;

  /// Target node ID.
  final String targetId;

  /// Human-readable label.
  final String? label;

  /// Edge weight/strength (0.0 to 1.0).
  final double? weight;

  /// Confidence score in this relationship (0.0 to 1.0).
  final double? confidence;

  /// Whether the relationship is bidirectional.
  final bool bidirectional;

  /// Edge properties.
  final Map<String, dynamic> properties;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Get a property value.
  dynamic getProperty(String name) => properties[name];

  /// Check if edge has a property.
  bool hasProperty(String name) => properties.containsKey(name);

  /// Check if this edge connects to a specific node.
  bool connectsTo(String nodeId) => sourceId == nodeId || targetId == nodeId;

  /// Get the other node ID given one end.
  String? getOtherNode(String nodeId) {
    if (sourceId == nodeId) return targetId;
    if (targetId == nodeId) return sourceId;
    return null;
  }

  /// Create from JSON.
  factory FactEdge.fromJson(Map<String, dynamic> json) {
    return FactEdge(
      id: json['id'] as String? ?? '',
      type: EdgeType.fromString(json['type'] as String? ?? 'relatesTo'),
      sourceId: json['sourceId'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      label: json['label'] as String?,
      weight: json['weight'] as double?,
      confidence: json['confidence'] as double?,
      bidirectional: json['bidirectional'] as bool? ?? false,
      properties: json['properties'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'sourceId': sourceId,
        'targetId': targetId,
        if (label != null) 'label': label,
        if (weight != null) 'weight': weight,
        if (confidence != null) 'confidence': confidence,
        if (bidirectional) 'bidirectional': bidirectional,
        if (properties.isNotEmpty) 'properties': properties,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  FactEdge copyWith({
    String? id,
    EdgeType? type,
    String? sourceId,
    String? targetId,
    String? label,
    double? weight,
    double? confidence,
    bool? bidirectional,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? metadata,
  }) {
    return FactEdge(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      weight: weight ?? this.weight,
      confidence: confidence ?? this.confidence,
      bidirectional: bidirectional ?? this.bidirectional,
      properties: properties ?? this.properties,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'FactEdge($id: $sourceId -[${type.name}]-> $targetId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FactEdge && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Types of edges in the fact graph.
/// Reference: 03-data-model-specification.md Section 2.17
enum EdgeType {
  // Evidence relationships

  /// Evidence/Fact supports Claim/Conclusion.
  supports,

  /// Fragment extracted from Evidence.
  extractedFrom,

  // Derivation relationships

  /// Summary/View/Report derived from Fact set.
  derivedFrom,

  /// Conclusion/View depends on Policy/Rubric/Assumption.
  dependsOn,

  // Update relationships

  /// New version supersedes old version.
  supersedes,

  /// Conflicting facts/claims.
  contradicts,

  // Entity relationships

  /// General entity relationship.
  relatesTo,

  /// Hierarchical relationship (DAG).
  partOf,

  /// Ownership relationship.
  ownedBy,

  // Skill relationships

  /// Skill/Rubric applied to Target.
  appliedTo,

  /// Output produced by Skill/Evaluation.
  producedBy,

  // Pattern relationships

  /// Pattern observed from Claim (mining input).
  observedFrom,

  /// Pattern promoted to Skill/Profile.
  promotedTo,

  /// Unknown relationship.
  unknown;

  static EdgeType fromString(String value) {
    return EdgeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EdgeType.unknown,
    );
  }

  /// Check if this edge type represents a hierarchical relationship.
  bool get isHierarchical => this == partOf || this == ownedBy;

  /// Check if this edge type is inherently bidirectional.
  bool get isSymmetric => this == relatesTo || this == contradicts;
}
