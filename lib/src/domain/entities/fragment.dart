/// Fragment entity for L0 Evidence Layer.
///
/// Represents extracted fields from evidence.
library;

/// Fragment represents an extracted piece of data from evidence.
///
/// Fragments are created through rule-based extraction, OCR, or LLM analysis.
/// Each fragment has a confidence score and may be proposed or confirmed.
class Fragment {
  /// Unique fragment identifier.
  final String fragmentId;

  /// Parent evidence ID.
  final String evidenceId;

  /// Field name/type (e.g., 'amount', 'date', 'merchant').
  final String field;

  /// Extracted value.
  final dynamic value;

  /// Normalized value (if applicable).
  final dynamic normalizedValue;

  /// Data type of the value.
  final FragmentValueType valueType;

  /// Confidence score (0.0 to 1.0).
  final double confidence;

  /// Extraction method used.
  final ExtractionMethod method;

  /// Fragment status.
  final FragmentStatus status;

  /// Position in source (if applicable).
  final SourcePosition? position;

  /// When this fragment was extracted.
  final DateTime extractedAt;

  /// User who confirmed this fragment (if confirmed).
  final String? confirmedBy;

  /// When this fragment was confirmed.
  final DateTime? confirmedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Fragment({
    required this.fragmentId,
    required this.evidenceId,
    required this.field,
    required this.value,
    this.normalizedValue,
    this.valueType = FragmentValueType.string,
    required this.confidence,
    this.method = ExtractionMethod.rule,
    this.status = FragmentStatus.proposed,
    this.position,
    required this.extractedAt,
    this.confirmedBy,
    this.confirmedAt,
    this.metadata = const {},
  });

  factory Fragment.fromJson(Map<String, dynamic> json) {
    return Fragment(
      fragmentId: json['fragmentId'] as String? ?? '',
      evidenceId: json['evidenceId'] as String? ?? '',
      field: json['field'] as String? ?? '',
      value: json['value'],
      normalizedValue: json['normalizedValue'],
      valueType:
          FragmentValueType.fromString(json['valueType'] as String? ?? 'string'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      method:
          ExtractionMethod.fromString(json['method'] as String? ?? 'rule'),
      status:
          FragmentStatus.fromString(json['status'] as String? ?? 'proposed'),
      position: json['position'] != null
          ? SourcePosition.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      extractedAt: json['extractedAt'] != null
          ? DateTime.parse(json['extractedAt'] as String)
          : DateTime.now(),
      confirmedBy: json['confirmedBy'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fragmentId': fragmentId,
      'evidenceId': evidenceId,
      'field': field,
      'value': value,
      if (normalizedValue != null) 'normalizedValue': normalizedValue,
      'valueType': valueType.name,
      'confidence': confidence,
      'method': method.name,
      'status': status.name,
      if (position != null) 'position': position!.toJson(),
      'extractedAt': extractedAt.toIso8601String(),
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  Fragment copyWith({
    String? fragmentId,
    String? evidenceId,
    String? field,
    dynamic value,
    dynamic normalizedValue,
    FragmentValueType? valueType,
    double? confidence,
    ExtractionMethod? method,
    FragmentStatus? status,
    SourcePosition? position,
    DateTime? extractedAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Fragment(
      fragmentId: fragmentId ?? this.fragmentId,
      evidenceId: evidenceId ?? this.evidenceId,
      field: field ?? this.field,
      value: value ?? this.value,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      valueType: valueType ?? this.valueType,
      confidence: confidence ?? this.confidence,
      method: method ?? this.method,
      status: status ?? this.status,
      position: position ?? this.position,
      extractedAt: extractedAt ?? this.extractedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if fragment is high confidence.
  bool get isHighConfidence => confidence >= 0.9;

  /// Check if fragment is confirmed.
  bool get isConfirmed => status == FragmentStatus.confirmed;

  @override
  String toString() =>
      'Fragment($fragmentId, field: $field, confidence: $confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fragment && fragmentId == other.fragmentId;

  @override
  int get hashCode => fragmentId.hashCode;
}

/// Types of fragment values.
enum FragmentValueType {
  string,
  number,
  boolean,
  date,
  datetime,
  currency,
  percentage,
  object,
  array,
  unknown;

  static FragmentValueType fromString(String value) {
    return FragmentValueType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FragmentValueType.unknown,
    );
  }
}

/// Extraction methods.
enum ExtractionMethod {
  /// Rule-based extraction.
  rule,

  /// Regex pattern matching.
  regex,

  /// OCR (Optical Character Recognition).
  ocr,

  /// Parser-based extraction.
  parser,

  /// LLM-based extraction.
  llm,

  /// User-provided.
  manual,

  /// Unknown method.
  unknown;

  static ExtractionMethod fromString(String value) {
    return ExtractionMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExtractionMethod.unknown,
    );
  }
}

/// Fragment status.
enum FragmentStatus {
  /// Proposed by extraction.
  proposed,

  /// Confirmed by user or system.
  confirmed,

  /// Rejected.
  rejected,

  /// Superseded by another fragment.
  superseded;

  static FragmentStatus fromString(String value) {
    return FragmentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FragmentStatus.proposed,
    );
  }
}

/// Position in source content.
class SourcePosition {
  /// Start offset (characters or pixels).
  final int start;

  /// End offset.
  final int end;

  /// Line number (for text).
  final int? line;

  /// Column number (for text).
  final int? column;

  /// Bounding box (for images).
  final BoundingBox? boundingBox;

  const SourcePosition({
    required this.start,
    required this.end,
    this.line,
    this.column,
    this.boundingBox,
  });

  factory SourcePosition.fromJson(Map<String, dynamic> json) {
    return SourcePosition(
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      line: json['line'] as int?,
      column: json['column'] as int?,
      boundingBox: json['boundingBox'] != null
          ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      if (line != null) 'line': line,
      if (column != null) 'column': column,
      if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
    };
  }
}

/// Bounding box for image regions.
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
