/// Evidence entity for L0 Evidence Layer.
///
/// Represents immutable original input data before any processing.
library;

// Import canonical SourceInfo from mcp_bundle
import 'package:mcp_bundle/ports.dart' show SourceInfo;

// Re-export for convenience
export 'package:mcp_bundle/ports.dart' show SourceInfo;

/// Backward compatibility alias for SourceInfo.
@Deprecated('Use SourceInfo instead')
typedef SourceMetadata = SourceInfo;

/// Evidence represents the original, immutable input data.
///
/// This is the base layer (L0) of the fact graph architecture.
/// Evidence is never modified after creation - only fragments are extracted from it.
class Evidence {
  /// Unique evidence identifier.
  final String evidenceId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Type of the source (image, text, receipt, messenger, etc.).
  final EvidenceSourceType sourceType;

  /// Original content (could be base64 for images, text, etc.).
  final String content;

  /// Content hash for integrity verification.
  final String contentHash;

  /// MIME type of the content.
  final String? mimeType;

  /// Source metadata (where it came from).
  final SourceInfo source;

  /// External reference (URL, file path, etc.).
  /// Reference: Design Section 2.2 - source tracking.
  final String? sourceRef;

  /// Internal storage reference (blob storage key).
  /// Reference: Design Section 2.2 - content storage.
  final String? contentRef;

  /// When the original content was captured/created.
  /// Reference: Design Section 2.2 - temporal tracking.
  final DateTime? timestamp;

  /// Creator/author of this evidence.
  /// Reference: Design Section 2.2 - provenance tracking.
  final String? author;

  /// When this evidence was created in the system.
  /// Reference: Design Section 2.2 - audit trail.
  final DateTime createdAt;

  /// When this evidence was ingested.
  final DateTime ingestedAt;

  /// Processing status.
  final EvidenceStatus status;

  /// Extracted fragments from this evidence.
  final List<String> fragmentIds;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Evidence({
    required this.evidenceId,
    required this.workspaceId,
    required this.sourceType,
    required this.content,
    required this.contentHash,
    this.mimeType,
    required this.source,
    this.sourceRef,
    this.contentRef,
    this.timestamp,
    this.author,
    required this.createdAt,
    required this.ingestedAt,
    this.status = EvidenceStatus.pending,
    this.fragmentIds = const [],
    this.metadata = const {},
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      evidenceId: json['evidenceId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      sourceType: EvidenceSourceType.fromString(
          json['sourceType'] as String? ?? 'unknown'),
      content: json['content'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      source: SourceInfo.fromJson(
          json['source'] as Map<String, dynamic>? ?? {}),
      sourceRef: json['sourceRef'] as String?,
      contentRef: json['contentRef'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      author: json['author'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      ingestedAt: json['ingestedAt'] != null
          ? DateTime.parse(json['ingestedAt'] as String)
          : DateTime.now(),
      status: EvidenceStatus.fromString(json['status'] as String? ?? 'pending'),
      fragmentIds: (json['fragmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'workspaceId': workspaceId,
      'sourceType': sourceType.name,
      'content': content,
      'contentHash': contentHash,
      if (mimeType != null) 'mimeType': mimeType,
      'source': source.toJson(),
      if (sourceRef != null) 'sourceRef': sourceRef,
      if (contentRef != null) 'contentRef': contentRef,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (author != null) 'author': author,
      'createdAt': createdAt.toIso8601String(),
      'ingestedAt': ingestedAt.toIso8601String(),
      'status': status.name,
      if (fragmentIds.isNotEmpty) 'fragmentIds': fragmentIds,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Evidence copyWith({
    String? evidenceId,
    String? workspaceId,
    EvidenceSourceType? sourceType,
    String? content,
    String? contentHash,
    String? mimeType,
    SourceInfo? source,
    String? sourceRef,
    String? contentRef,
    DateTime? timestamp,
    String? author,
    DateTime? createdAt,
    DateTime? ingestedAt,
    EvidenceStatus? status,
    List<String>? fragmentIds,
    Map<String, dynamic>? metadata,
  }) {
    return Evidence(
      evidenceId: evidenceId ?? this.evidenceId,
      workspaceId: workspaceId ?? this.workspaceId,
      sourceType: sourceType ?? this.sourceType,
      content: content ?? this.content,
      contentHash: contentHash ?? this.contentHash,
      mimeType: mimeType ?? this.mimeType,
      source: source ?? this.source,
      sourceRef: sourceRef ?? this.sourceRef,
      contentRef: contentRef ?? this.contentRef,
      timestamp: timestamp ?? this.timestamp,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      ingestedAt: ingestedAt ?? this.ingestedAt,
      status: status ?? this.status,
      fragmentIds: fragmentIds ?? this.fragmentIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'Evidence($evidenceId, type: ${sourceType.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Evidence && evidenceId == other.evidenceId;

  @override
  int get hashCode => evidenceId.hashCode;
}

/// Types of evidence sources.
/// Reference: Design Section 2.2 - text | image | file | message | api
enum EvidenceSourceType {
  /// Plain text input.
  text,

  /// Image (photo, screenshot).
  image,

  /// File (document, PDF, etc.).
  file,

  /// Message (chat, email, etc.).
  message,

  /// API response.
  api;

  static EvidenceSourceType fromString(String value) {
    return EvidenceSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvidenceSourceType.text,
    );
  }
}

/// Evidence processing status.
enum EvidenceStatus {
  /// Pending extraction.
  pending,

  /// Extraction in progress.
  processing,

  /// Extraction completed.
  extracted,

  /// Extraction failed.
  failed,

  /// Archived.
  archived;

  static EvidenceStatus fromString(String value) {
    return EvidenceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvidenceStatus.pending,
    );
  }
}
