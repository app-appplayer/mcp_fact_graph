/// Fragment entity for L0 Evidence Layer.
///
/// Represents extracted fields from evidence.
/// Reference: 03-data-model-specification.md Section 2.2
library;

/// Fragment represents an extracted piece of data from evidence.
///
/// Fragments are created through rule-based extraction, OCR, or LLM analysis.
/// Each fragment has a confidence score and may be proposed or confirmed.
/// Uses fields map for multi-field extraction (design-compliant).
class Fragment {
  /// Unique fragment identifier.
  final String fragmentId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Parent evidence ID.
  final String evidenceId;

  /// Extracted fields (design-compliant).
  /// Reference: Design Section 2.2 - fields: Map<String, dynamic>
  final Map<String, dynamic> fields;

  /// Confidence score (0.0 to 1.0).
  final double confidence;

  /// Extractor type used for extraction.
  /// Reference: Design Section 2.2 - ExtractorType.
  final ExtractorType extractor;

  /// Fragment status.
  final FragmentStatus status;

  /// When this fragment was created/extracted.
  final DateTime createdAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Fragment({
    required this.fragmentId,
    required this.workspaceId,
    required this.evidenceId,
    this.fields = const {},
    required this.confidence,
    this.extractor = ExtractorType.rule,
    this.status = FragmentStatus.proposed,
    required this.createdAt,
    this.metadata = const {},
  });

  factory Fragment.fromJson(Map<String, dynamic> json) {
    return Fragment(
      fragmentId: json['fragmentId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      evidenceId: json['evidenceId'] as String? ?? '',
      fields: json['fields'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      extractor:
          ExtractorType.fromString(json['extractor'] as String? ?? json['method'] as String? ?? 'rule'),
      status:
          FragmentStatus.fromString(json['status'] as String? ?? 'proposed'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fragmentId': fragmentId,
      'workspaceId': workspaceId,
      'evidenceId': evidenceId,
      if (fields.isNotEmpty) 'fields': fields,
      'confidence': confidence,
      'extractor': extractor.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Fragment copyWith({
    String? fragmentId,
    String? workspaceId,
    String? evidenceId,
    Map<String, dynamic>? fields,
    double? confidence,
    ExtractorType? extractor,
    FragmentStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Fragment(
      fragmentId: fragmentId ?? this.fragmentId,
      workspaceId: workspaceId ?? this.workspaceId,
      evidenceId: evidenceId ?? this.evidenceId,
      fields: fields ?? this.fields,
      confidence: confidence ?? this.confidence,
      extractor: extractor ?? this.extractor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if fragment is high confidence.
  bool get isHighConfidence => confidence >= 0.9;

  /// Check if fragment is confirmed.
  bool get isConfirmed => status == FragmentStatus.confirmed;

  @override
  String toString() =>
      'Fragment($fragmentId, confidence: $confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fragment && fragmentId == other.fragmentId;

  @override
  int get hashCode => fragmentId.hashCode;
}

/// Extractor types for fragment extraction.
/// Reference: Design Section 2.2 - ExtractorType: rule | ocr | llm | manual
enum ExtractorType {
  /// Rule-based extraction.
  rule,

  /// OCR (Optical Character Recognition).
  ocr,

  /// LLM-based extraction.
  llm,

  /// User-provided.
  manual;

  static ExtractorType fromString(String value) {
    return ExtractorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExtractorType.rule,
    );
  }
}

/// Backward compatibility alias.
@Deprecated('Use ExtractorType instead')
typedef ExtractionMethod = ExtractorType;

/// Fragment status.
/// Reference: Design Section 2.5 - proposed | confirmed | rejected
enum FragmentStatus {
  /// Proposed by extraction.
  proposed,

  /// Confirmed by user or system.
  confirmed,

  /// Rejected.
  rejected;

  static FragmentStatus fromString(String value) {
    return FragmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FragmentStatus.proposed,
    );
  }
}
