/// Fact node representation in the knowledge graph.
library;

import 'package:mcp_bundle/mcp_bundle.dart';

/// A node in the fact graph representing a piece of knowledge.
class FactNode {
  FactNode({
    required this.id,
    required this.type,
    required this.content,
    this.claim,
    this.confidence,
    this.source,
    this.validFrom,
    this.validUntil,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  })  : metadata = metadata ?? {},
        tags = tags ?? [];

  /// Unique node identifier.
  final String id;

  /// Node type (e.g., 'fact', 'entity', 'concept', 'event').
  final NodeType type;

  /// Node content/data.
  final Map<String, dynamic> content;

  /// Associated claim (if this node represents a claim).
  final Claim? claim;

  /// Confidence score for this fact (0.0 to 1.0).
  final double? confidence;

  /// Source of this fact.
  final FactSource? source;

  /// When this fact became valid.
  final DateTime? validFrom;

  /// When this fact expires/became invalid.
  final DateTime? validUntil;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Tags for categorization.
  final List<String> tags;

  /// Check if node is currently valid.
  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  /// Get a property from content.
  dynamic getProperty(String name) => content[name];

  /// Check if node has a property.
  bool hasProperty(String name) => content.containsKey(name);

  /// Check if node has a specific tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Create from JSON.
  factory FactNode.fromJson(Map<String, dynamic> json) {
    return FactNode(
      id: json['id'] as String? ?? '',
      type: NodeType.fromString(json['type'] as String? ?? 'fact'),
      content: json['content'] as Map<String, dynamic>? ?? {},
      claim: json['claim'] != null
          ? Claim.fromJson(json['claim'] as Map<String, dynamic>)
          : null,
      confidence: json['confidence'] as double?,
      source: json['source'] != null
          ? FactSource.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        if (claim != null) 'claim': claim!.toJson(),
        if (confidence != null) 'confidence': confidence,
        if (source != null) 'source': source!.toJson(),
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (tags.isNotEmpty) 'tags': tags,
      };

  /// Create a copy with modifications.
  FactNode copyWith({
    String? id,
    NodeType? type,
    Map<String, dynamic>? content,
    Claim? claim,
    double? confidence,
    FactSource? source,
    DateTime? validFrom,
    DateTime? validUntil,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return FactNode(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      claim: claim ?? this.claim,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() => 'FactNode($id, type: ${type.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FactNode && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Types of nodes in the fact graph.
enum NodeType {
  /// A factual statement.
  fact,

  /// An entity (person, place, thing).
  entity,

  /// A concept or idea.
  concept,

  /// An event.
  event,

  /// A relationship descriptor.
  relationship,

  /// A rule or constraint.
  rule,

  /// A query or question.
  query,

  /// Unknown node type.
  unknown;

  static NodeType fromString(String value) {
    return NodeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NodeType.unknown,
    );
  }
}

/// Source information for a fact.
class FactSource {
  FactSource({
    required this.type,
    this.uri,
    this.name,
    this.timestamp,
    this.reliability,
  });

  /// Source type.
  final SourceType type;

  /// Source URI or identifier.
  final String? uri;

  /// Human-readable source name.
  final String? name;

  /// When the fact was sourced.
  final DateTime? timestamp;

  /// Reliability score (0.0 to 1.0).
  final double? reliability;

  factory FactSource.fromJson(Map<String, dynamic> json) {
    return FactSource(
      type: SourceType.fromString(json['type'] as String? ?? 'unknown'),
      uri: json['uri'] as String?,
      name: json['name'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      reliability: json['reliability'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (uri != null) 'uri': uri,
        if (name != null) 'name': name,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        if (reliability != null) 'reliability': reliability,
      };
}

/// Types of fact sources.
enum SourceType {
  /// User-provided input.
  user,

  /// External document.
  document,

  /// API or service.
  api,

  /// Database.
  database,

  /// Inference from other facts.
  inference,

  /// Unknown source.
  unknown;

  static SourceType fromString(String value) {
    return SourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SourceType.unknown,
    );
  }
}
