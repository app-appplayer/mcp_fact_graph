/// ClassifierMemory entity model.
///
/// Stores successful classification decisions for pattern matching.
/// Design: 03-data-model-specification.md Section 2.12.2
library;

/// Source of the classification memory.
enum MemorySource {
  /// Classification by LLM.
  llm,

  /// Classification by user.
  user,

  /// Classification by rule.
  rule;

  /// Create from string.
  static MemorySource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'llm':
        return MemorySource.llm;
      case 'user':
        return MemorySource.user;
      case 'rule':
        return MemorySource.rule;
      default:
        return MemorySource.llm;
    }
  }
}

/// Feature vector for classification matching.
class FeatureVector {
  /// Text-based features (keywords, patterns).
  final Map<String, dynamic> textFeatures;

  /// Numeric features (amounts, quantities).
  final Map<String, dynamic> numericFeatures;

  /// Entity-related features.
  final Map<String, dynamic> entityFeatures;

  /// Context features (time, source, etc.).
  final Map<String, dynamic> contextFeatures;

  const FeatureVector({
    this.textFeatures = const {},
    this.numericFeatures = const {},
    this.entityFeatures = const {},
    this.contextFeatures = const {},
  });

  /// Create from JSON.
  factory FeatureVector.fromJson(Map<String, dynamic> json) {
    return FeatureVector(
      textFeatures: json['textFeatures'] as Map<String, dynamic>? ?? {},
      numericFeatures: json['numericFeatures'] as Map<String, dynamic>? ?? {},
      entityFeatures: json['entityFeatures'] as Map<String, dynamic>? ?? {},
      contextFeatures: json['contextFeatures'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (textFeatures.isNotEmpty) 'textFeatures': textFeatures,
      if (numericFeatures.isNotEmpty) 'numericFeatures': numericFeatures,
      if (entityFeatures.isNotEmpty) 'entityFeatures': entityFeatures,
      if (contextFeatures.isNotEmpty) 'contextFeatures': contextFeatures,
    };
  }

  /// Create a copy with modifications.
  FeatureVector copyWith({
    Map<String, dynamic>? textFeatures,
    Map<String, dynamic>? numericFeatures,
    Map<String, dynamic>? entityFeatures,
    Map<String, dynamic>? contextFeatures,
  }) {
    return FeatureVector(
      textFeatures: textFeatures ?? this.textFeatures,
      numericFeatures: numericFeatures ?? this.numericFeatures,
      entityFeatures: entityFeatures ?? this.entityFeatures,
      contextFeatures: contextFeatures ?? this.contextFeatures,
    );
  }

  /// Check if feature vector is empty.
  bool get isEmpty =>
      textFeatures.isEmpty &&
      numericFeatures.isEmpty &&
      entityFeatures.isEmpty &&
      contextFeatures.isEmpty;

  /// Calculate similarity with another feature vector.
  double calculateSimilarity(FeatureVector other) {
    var totalMatches = 0.0;
    var totalFeatures = 0.0;

    // Compare text features
    for (final key in textFeatures.keys) {
      totalFeatures++;
      if (other.textFeatures[key] == textFeatures[key]) {
        totalMatches++;
      }
    }

    // Compare numeric features with tolerance
    for (final key in numericFeatures.keys) {
      totalFeatures++;
      final thisValue = numericFeatures[key];
      final otherValue = other.numericFeatures[key];
      if (thisValue is num && otherValue is num) {
        // Use relative tolerance of 10%
        final tolerance = thisValue.abs() * 0.1;
        if ((thisValue - otherValue).abs() <= tolerance) {
          totalMatches++;
        }
      }
    }

    // Compare entity features
    for (final key in entityFeatures.keys) {
      totalFeatures++;
      if (other.entityFeatures[key] == entityFeatures[key]) {
        totalMatches++;
      }
    }

    // Compare context features
    for (final key in contextFeatures.keys) {
      totalFeatures++;
      if (other.contextFeatures[key] == contextFeatures[key]) {
        totalMatches++;
      }
    }

    if (totalFeatures == 0) return 0.0;
    return totalMatches / totalFeatures;
  }
}

/// ClassifierMemory stores successful classification decisions for pattern matching.
class ClassifierMemory {
  /// Unique memory identifier.
  final String memoryId;

  /// Classification taxonomy ID.
  final String taxonomyId;

  /// Confirmed category ID.
  final String categoryId;

  /// Input characteristics.
  final FeatureVector features;

  /// Classification confidence (0.0 to 1.0).
  final double confidence;

  /// Reason for classification.
  final String? rationale;

  /// Source of the classification.
  final MemorySource source;

  /// Policy version used.
  final String policyVersion;

  /// Supporting evidence references.
  final List<String> evidenceRefs;

  /// Times this pattern matched.
  final int matchCount;

  /// Workspace ID.
  final String? workspaceId;

  /// When the memory was created.
  final DateTime createdAt;

  /// When the pattern last matched.
  final DateTime lastMatchedAt;

  const ClassifierMemory({
    required this.memoryId,
    required this.taxonomyId,
    required this.categoryId,
    required this.features,
    this.confidence = 1.0,
    this.rationale,
    required this.source,
    required this.policyVersion,
    this.evidenceRefs = const [],
    this.matchCount = 0,
    this.workspaceId,
    required this.createdAt,
    required this.lastMatchedAt,
  });

  /// Create from JSON.
  factory ClassifierMemory.fromJson(Map<String, dynamic> json) {
    return ClassifierMemory(
      memoryId: json['memoryId'] as String? ?? '',
      taxonomyId: json['taxonomyId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      features: json['features'] != null
          ? FeatureVector.fromJson(json['features'] as Map<String, dynamic>)
          : const FeatureVector(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      rationale: json['rationale'] as String?,
      source: MemorySource.fromString(json['source'] as String? ?? 'llm'),
      policyVersion: json['policyVersion'] as String? ?? '',
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchCount: json['matchCount'] as int? ?? 0,
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastMatchedAt: json['lastMatchedAt'] != null
          ? DateTime.parse(json['lastMatchedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'memoryId': memoryId,
      'taxonomyId': taxonomyId,
      'categoryId': categoryId,
      'features': features.toJson(),
      'confidence': confidence,
      if (rationale != null) 'rationale': rationale,
      'source': source.name,
      'policyVersion': policyVersion,
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      'matchCount': matchCount,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      'lastMatchedAt': lastMatchedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  ClassifierMemory copyWith({
    String? memoryId,
    String? taxonomyId,
    String? categoryId,
    FeatureVector? features,
    double? confidence,
    String? rationale,
    MemorySource? source,
    String? policyVersion,
    List<String>? evidenceRefs,
    int? matchCount,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? lastMatchedAt,
  }) {
    return ClassifierMemory(
      memoryId: memoryId ?? this.memoryId,
      taxonomyId: taxonomyId ?? this.taxonomyId,
      categoryId: categoryId ?? this.categoryId,
      features: features ?? this.features,
      confidence: confidence ?? this.confidence,
      rationale: rationale ?? this.rationale,
      source: source ?? this.source,
      policyVersion: policyVersion ?? this.policyVersion,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      matchCount: matchCount ?? this.matchCount,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
    );
  }

  /// Check if this memory has high confidence.
  bool get isHighConfidence => confidence >= 0.9;

  /// Check similarity with another feature vector.
  double matchSimilarity(FeatureVector otherFeatures) {
    return features.calculateSimilarity(otherFeatures);
  }

  /// Check if this memory matches the given features.
  bool matches(FeatureVector otherFeatures, {double threshold = 0.8}) {
    return matchSimilarity(otherFeatures) >= threshold;
  }

  /// Record a match.
  ClassifierMemory recordMatch() {
    return copyWith(
      matchCount: matchCount + 1,
      lastMatchedAt: DateTime.now(),
    );
  }
}
