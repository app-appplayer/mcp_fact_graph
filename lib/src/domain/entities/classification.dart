/// Classification entity model.
///
/// Represents operational categorization applied to targets.
/// Design: 03-data-model-specification.md Section 2.7
library;

/// Status of a classification.
enum ClassificationStatus {
  /// Classification proposed by system.
  proposed,

  /// Classification confirmed by user or policy.
  confirmed,

  /// Classification has been reclassified.
  reclassified;

  /// Create from string.
  static ClassificationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'proposed':
        return ClassificationStatus.proposed;
      case 'confirmed':
        return ClassificationStatus.confirmed;
      case 'reclassified':
        return ClassificationStatus.reclassified;
      default:
        return ClassificationStatus.proposed;
    }
  }
}

/// Classification represents operational categorization applied to targets.
class Classification {
  /// Unique identifier.
  final String classificationId;

  /// Target type: candidate, event.
  final String targetType;

  /// Target object ID.
  final String targetId;

  /// Classification system/taxonomy ID.
  final String taxonomyId;

  /// Specific category within the taxonomy.
  final String categoryId;

  /// Classification status.
  final ClassificationStatus status;

  /// Classification confidence (0.0 to 1.0).
  final double confidence;

  /// Reason for classification.
  final String? rationale;

  /// Applied policy version.
  final String policyVersion;

  /// Supporting evidence references.
  final List<String> evidenceRefs;

  /// When the classification was created.
  final DateTime createdAt;

  /// When the classification was last updated.
  final DateTime? updatedAt;

  /// Previous classification ID if reclassified.
  final String? previousClassificationId;

  const Classification({
    required this.classificationId,
    required this.targetType,
    required this.targetId,
    required this.taxonomyId,
    required this.categoryId,
    this.status = ClassificationStatus.proposed,
    this.confidence = 1.0,
    this.rationale,
    required this.policyVersion,
    this.evidenceRefs = const [],
    required this.createdAt,
    this.updatedAt,
    this.previousClassificationId,
  });

  /// Create from JSON.
  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      classificationId: json['classificationId'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      taxonomyId: json['taxonomyId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      status: ClassificationStatus.fromString(
          json['status'] as String? ?? 'proposed'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      rationale: json['rationale'] as String?,
      policyVersion: json['policyVersion'] as String? ?? '',
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      previousClassificationId: json['previousClassificationId'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'classificationId': classificationId,
      'targetType': targetType,
      'targetId': targetId,
      'taxonomyId': taxonomyId,
      'categoryId': categoryId,
      'status': status.name,
      'confidence': confidence,
      if (rationale != null) 'rationale': rationale,
      'policyVersion': policyVersion,
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (previousClassificationId != null)
        'previousClassificationId': previousClassificationId,
    };
  }

  /// Create a copy with modifications.
  Classification copyWith({
    String? classificationId,
    String? targetType,
    String? targetId,
    String? taxonomyId,
    String? categoryId,
    ClassificationStatus? status,
    double? confidence,
    String? rationale,
    String? policyVersion,
    List<String>? evidenceRefs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? previousClassificationId,
  }) {
    return Classification(
      classificationId: classificationId ?? this.classificationId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      taxonomyId: taxonomyId ?? this.taxonomyId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      rationale: rationale ?? this.rationale,
      policyVersion: policyVersion ?? this.policyVersion,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      previousClassificationId:
          previousClassificationId ?? this.previousClassificationId,
    );
  }

  /// Check if classification is confirmed.
  bool get isConfirmed => status == ClassificationStatus.confirmed;

  /// Check if classification is pending confirmation.
  bool get isPending => status == ClassificationStatus.proposed;

  /// Confirm this classification.
  Classification confirm() {
    return copyWith(
      status: ClassificationStatus.confirmed,
      updatedAt: DateTime.now(),
    );
  }

  /// Reclassify to a new category.
  Classification reclassify({
    required String newCategoryId,
    String? newRationale,
    double? newConfidence,
  }) {
    return copyWith(
      categoryId: newCategoryId,
      status: ClassificationStatus.reclassified,
      rationale: newRationale,
      confidence: newConfidence,
      updatedAt: DateTime.now(),
      previousClassificationId: classificationId,
    );
  }
}
