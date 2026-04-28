/// Artifact entity model.
///
/// Represents a generated output from report/view operations.
/// Design: 03-data-model-specification.md Section 2.14
library;

/// Type of artifact.
enum ArtifactType {
  /// Generated report.
  report,

  /// Data export.
  export,

  /// View snapshot.
  snapshot;

  /// Create from string.
  static ArtifactType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'report':
        return ArtifactType.report;
      case 'export':
        return ArtifactType.export;
      case 'snapshot':
        return ArtifactType.snapshot;
      default:
        return ArtifactType.report;
    }
  }
}

/// Context for artifact generation (for reproducibility).
class GenerationContext {
  /// Point-in-time used for data.
  final DateTime asOf;

  /// Policy version applied.
  final String policyVersion;

  /// Source view IDs.
  final List<String> inputViewIds;

  /// Source event IDs (if direct).
  final List<String> inputEventIds;

  /// Generation parameters.
  final Map<String, dynamic> params;

  /// Hash for exact reproducibility.
  final String queryHash;

  const GenerationContext({
    required this.asOf,
    required this.policyVersion,
    this.inputViewIds = const [],
    this.inputEventIds = const [],
    this.params = const {},
    required this.queryHash,
  });

  /// Create from JSON.
  factory GenerationContext.fromJson(Map<String, dynamic> json) {
    return GenerationContext(
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String? ?? '',
      inputViewIds: (json['inputViewIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      inputEventIds: (json['inputEventIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      params: json['params'] as Map<String, dynamic>? ?? {},
      queryHash: json['queryHash'] as String? ?? '',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'asOf': asOf.toIso8601String(),
      'policyVersion': policyVersion,
      if (inputViewIds.isNotEmpty) 'inputViewIds': inputViewIds,
      if (inputEventIds.isNotEmpty) 'inputEventIds': inputEventIds,
      if (params.isNotEmpty) 'params': params,
      'queryHash': queryHash,
    };
  }

  /// Create a copy with modifications.
  GenerationContext copyWith({
    DateTime? asOf,
    String? policyVersion,
    List<String>? inputViewIds,
    List<String>? inputEventIds,
    Map<String, dynamic>? params,
    String? queryHash,
  }) {
    return GenerationContext(
      asOf: asOf ?? this.asOf,
      policyVersion: policyVersion ?? this.policyVersion,
      inputViewIds: inputViewIds ?? this.inputViewIds,
      inputEventIds: inputEventIds ?? this.inputEventIds,
      params: params ?? this.params,
      queryHash: queryHash ?? this.queryHash,
    );
  }
}

/// Artifact represents a generated output from report/view operations.
class Artifact {
  /// Unique artifact identifier.
  final String artifactId;

  /// Type of artifact.
  final ArtifactType type;

  /// Format: json, markdown, html, pdf, csv.
  final String format;

  /// Reference to stored content.
  final String contentRef;

  /// Content size in bytes.
  final int sizeBytes;

  /// Human-readable title.
  final String? title;

  /// Generation metadata.
  final Map<String, dynamic> meta;

  /// Reproducibility context.
  final GenerationContext context;

  /// Workspace ID.
  final String? workspaceId;

  /// When the artifact was created.
  final DateTime createdAt;

  /// Auto-cleanup threshold.
  final DateTime? expiresAt;

  const Artifact({
    required this.artifactId,
    required this.type,
    required this.format,
    required this.contentRef,
    this.sizeBytes = 0,
    this.title,
    this.meta = const {},
    required this.context,
    this.workspaceId,
    required this.createdAt,
    this.expiresAt,
  });

  /// Create from JSON.
  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      artifactId: json['artifactId'] as String? ?? '',
      type: ArtifactType.fromString(json['type'] as String? ?? 'report'),
      format: json['format'] as String? ?? 'json',
      contentRef: json['contentRef'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      title: json['title'] as String?,
      meta: json['meta'] as Map<String, dynamic>? ?? {},
      context: json['context'] != null
          ? GenerationContext.fromJson(json['context'] as Map<String, dynamic>)
          : GenerationContext(
              asOf: DateTime.now(),
              policyVersion: '',
              queryHash: '',
            ),
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'artifactId': artifactId,
      'type': type.name,
      'format': format,
      'contentRef': contentRef,
      'sizeBytes': sizeBytes,
      if (title != null) 'title': title,
      if (meta.isNotEmpty) 'meta': meta,
      'context': context.toJson(),
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  Artifact copyWith({
    String? artifactId,
    ArtifactType? type,
    String? format,
    String? contentRef,
    int? sizeBytes,
    String? title,
    Map<String, dynamic>? meta,
    GenerationContext? context,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Artifact(
      artifactId: artifactId ?? this.artifactId,
      type: type ?? this.type,
      format: format ?? this.format,
      contentRef: contentRef ?? this.contentRef,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      title: title ?? this.title,
      meta: meta ?? this.meta,
      context: context ?? this.context,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if the artifact has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the artifact is still valid.
  bool get isValid => !isExpired;

  /// Check if this is a report.
  bool get isReport => type == ArtifactType.report;

  /// Check if this is an export.
  bool get isExport => type == ArtifactType.export;

  /// Check if this is a snapshot.
  bool get isSnapshot => type == ArtifactType.snapshot;

  /// Get size in human-readable format.
  String get humanReadableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Common artifact formats.
abstract class ArtifactFormat {
  /// JSON format.
  static const String json = 'json';

  /// Markdown format.
  static const String markdown = 'markdown';

  /// HTML format.
  static const String html = 'html';

  /// PDF format.
  static const String pdf = 'pdf';

  /// CSV format.
  static const String csv = 'csv';

  /// Excel format.
  static const String xlsx = 'xlsx';
}
