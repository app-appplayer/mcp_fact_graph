/// Evidence entity for L0 Evidence Layer.
///
/// Represents immutable original input data before any processing.
library;

/// Evidence represents the original, immutable input data.
///
/// This is the base layer (L0) of the fact graph architecture.
/// Evidence is never modified after creation - only fragments are extracted from it.
class Evidence {
  /// Unique evidence identifier.
  final String evidenceId;

  /// Type of the source (image, text, receipt, messenger, etc.).
  final EvidenceSourceType sourceType;

  /// Original content (could be base64 for images, text, etc.).
  final String content;

  /// Content hash for integrity verification.
  final String contentHash;

  /// MIME type of the content.
  final String? mimeType;

  /// Source metadata (where it came from).
  final SourceMetadata source;

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
    required this.sourceType,
    required this.content,
    required this.contentHash,
    this.mimeType,
    required this.source,
    required this.ingestedAt,
    this.status = EvidenceStatus.pending,
    this.fragmentIds = const [],
    this.metadata = const {},
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      evidenceId: json['evidenceId'] as String? ?? '',
      sourceType: EvidenceSourceType.fromString(
          json['sourceType'] as String? ?? 'unknown'),
      content: json['content'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      source: SourceMetadata.fromJson(
          json['source'] as Map<String, dynamic>? ?? {}),
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
      'sourceType': sourceType.name,
      'content': content,
      'contentHash': contentHash,
      if (mimeType != null) 'mimeType': mimeType,
      'source': source.toJson(),
      'ingestedAt': ingestedAt.toIso8601String(),
      'status': status.name,
      if (fragmentIds.isNotEmpty) 'fragmentIds': fragmentIds,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Evidence copyWith({
    String? evidenceId,
    EvidenceSourceType? sourceType,
    String? content,
    String? contentHash,
    String? mimeType,
    SourceMetadata? source,
    DateTime? ingestedAt,
    EvidenceStatus? status,
    List<String>? fragmentIds,
    Map<String, dynamic>? metadata,
  }) {
    return Evidence(
      evidenceId: evidenceId ?? this.evidenceId,
      sourceType: sourceType ?? this.sourceType,
      content: content ?? this.content,
      contentHash: contentHash ?? this.contentHash,
      mimeType: mimeType ?? this.mimeType,
      source: source ?? this.source,
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
enum EvidenceSourceType {
  /// Plain text input.
  text,

  /// Image (photo, screenshot).
  image,

  /// Receipt/invoice.
  receipt,

  /// Messenger chat.
  messenger,

  /// Email.
  email,

  /// Document (PDF, DOC, etc.).
  document,

  /// Audio recording.
  audio,

  /// Video recording.
  video,

  /// API response.
  api,

  /// File.
  file,

  /// Unknown source.
  unknown;

  static EvidenceSourceType fromString(String value) {
    return EvidenceSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvidenceSourceType.unknown,
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

/// Source metadata for evidence.
class SourceMetadata {
  /// Source name/identifier.
  final String name;

  /// Source URI.
  final String? uri;

  /// Source type description.
  final String? type;

  /// When the original was created/captured.
  final DateTime? capturedAt;

  /// Reliability score (0.0 to 1.0).
  final double? reliability;

  /// Additional source attributes.
  final Map<String, dynamic> attributes;

  const SourceMetadata({
    required this.name,
    this.uri,
    this.type,
    this.capturedAt,
    this.reliability,
    this.attributes = const {},
  });

  factory SourceMetadata.fromJson(Map<String, dynamic> json) {
    return SourceMetadata(
      name: json['name'] as String? ?? '',
      uri: json['uri'] as String?,
      type: json['type'] as String?,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : null,
      reliability: (json['reliability'] as num?)?.toDouble(),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (uri != null) 'uri': uri,
      if (type != null) 'type': type,
      if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
      if (reliability != null) 'reliability': reliability,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
  }
}
