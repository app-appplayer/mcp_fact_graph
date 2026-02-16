/// Event entity for L1 FactGraph Layer.
///
/// Represents confirmed events/facts in the graph.
library;

/// Event represents a confirmed fact or event in the fact graph.
///
/// Events are created when candidates are confirmed and promoted.
class Event {
  /// Unique event identifier.
  final String eventId;

  /// Event type (expense, schedule, task, transaction, etc.).
  final String eventType;

  /// Event summary/title.
  final String summary;

  /// Event data/fields.
  final Map<String, dynamic> data;

  /// Event timestamp (when the event occurred).
  final DateTime occurredAt;

  /// Event status.
  final EventStatus status;

  /// Source candidate ID.
  final String candidateId;

  /// Source evidence IDs.
  final List<String> evidenceIds;

  /// Related entity IDs.
  final List<String> entityIds;

  /// Edge connections (eventId/entityId -> edge type).
  final List<EventEdge> edges;

  /// When this event was created in the system.
  final DateTime createdAt;

  /// When this event was last updated.
  final DateTime updatedAt;

  /// Policy version used for confirmation.
  final String? policyVersion;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Event({
    required this.eventId,
    required this.eventType,
    required this.summary,
    this.data = const {},
    required this.occurredAt,
    this.status = EventStatus.active,
    required this.candidateId,
    this.evidenceIds = const [],
    this.entityIds = const [],
    this.edges = const [],
    required this.createdAt,
    required this.updatedAt,
    this.policyVersion,
    this.metadata = const {},
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : DateTime.now(),
      status: EventStatus.fromString(json['status'] as String? ?? 'active'),
      candidateId: json['candidateId'] as String? ?? '',
      evidenceIds: (json['evidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      entityIds: (json['entityIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => EventEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'summary': summary,
      if (data.isNotEmpty) 'data': data,
      'occurredAt': occurredAt.toIso8601String(),
      'status': status.name,
      'candidateId': candidateId,
      if (evidenceIds.isNotEmpty) 'evidenceIds': evidenceIds,
      if (entityIds.isNotEmpty) 'entityIds': entityIds,
      if (edges.isNotEmpty) 'edges': edges.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (policyVersion != null) 'policyVersion': policyVersion,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Event copyWith({
    String? eventId,
    String? eventType,
    String? summary,
    Map<String, dynamic>? data,
    DateTime? occurredAt,
    EventStatus? status,
    String? candidateId,
    List<String>? evidenceIds,
    List<String>? entityIds,
    List<EventEdge>? edges,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? policyVersion,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      summary: summary ?? this.summary,
      data: data ?? this.data,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
      candidateId: candidateId ?? this.candidateId,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      entityIds: entityIds ?? this.entityIds,
      edges: edges ?? this.edges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      policyVersion: policyVersion ?? this.policyVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'Event($eventId, type: $eventType, summary: $summary)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Event && eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}

/// Event status.
enum EventStatus {
  /// Active event.
  active,

  /// Superseded by another event.
  superseded,

  /// Archived.
  archived,

  /// Deleted.
  deleted;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventStatus.active,
    );
  }
}

/// Edge connection from an event.
class EventEdge {
  /// Target ID (event or entity).
  final String targetId;

  /// Edge type.
  final EventEdgeType edgeType;

  /// Edge label/description.
  final String? label;

  /// Edge attributes.
  final Map<String, dynamic> attributes;

  const EventEdge({
    required this.targetId,
    required this.edgeType,
    this.label,
    this.attributes = const {},
  });

  factory EventEdge.fromJson(Map<String, dynamic> json) {
    return EventEdge(
      targetId: json['targetId'] as String? ?? '',
      edgeType:
          EventEdgeType.fromString(json['edgeType'] as String? ?? 'related'),
      label: json['label'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'edgeType': edgeType.name,
      if (label != null) 'label': label,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
  }
}

/// Edge types for event connections.
enum EventEdgeType {
  /// General relation.
  related,

  /// Supports/evidences.
  supports,

  /// Derived from.
  derivedFrom,

  /// Depends on.
  dependsOn,

  /// Supersedes.
  supersedes,

  /// Contradicts.
  contradicts,

  /// Part of.
  partOf,

  /// Caused by.
  causedBy,

  /// Causes.
  causes,

  /// References.
  references;

  static EventEdgeType fromString(String value) {
    return EventEdgeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventEdgeType.related,
    );
  }
}
