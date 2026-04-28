/// DisambiguationDecision entity model.
///
/// Stores explicit user decisions for future automatic resolution.
/// Design: 03-data-model-specification.md Section 2.12.3
library;

/// Type of disambiguation decision.
enum DecisionType {
  /// Classification decision: "This is medical expense".
  classification,

  /// Merge decision: "These two are the same".
  merge,

  /// Link decision: "This expense belongs to project X".
  link,

  /// Split decision: "These should be separate".
  split,

  /// Reject decision: "This is not valid".
  reject,

  /// Confirm decision: "This interpretation is correct".
  confirm;

  /// Create from string.
  static DecisionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'classification':
        return DecisionType.classification;
      case 'merge':
        return DecisionType.merge;
      case 'link':
        return DecisionType.link;
      case 'split':
        return DecisionType.split;
      case 'reject':
        return DecisionType.reject;
      case 'confirm':
        return DecisionType.confirm;
      default:
        return DecisionType.confirm;
    }
  }
}

/// DisambiguationDecision stores explicit user decisions for future automatic resolution.
class DisambiguationDecision {
  /// Unique decision identifier.
  final String decisionId;

  /// Type of decision.
  final DecisionType decisionType;

  /// Hash of decision context (for fast matching).
  final String contextHash;

  /// Full context of the decision.
  final Map<String, dynamic> context;

  /// What was decided.
  final Map<String, dynamic> choice;

  /// User's explanation.
  final String? rationale;

  /// Times auto-applied.
  final int applicationCount;

  /// Workspace ID.
  final String? workspaceId;

  /// When the decision was created.
  final DateTime createdAt;

  /// When the decision was last applied.
  final DateTime lastAppliedAt;

  const DisambiguationDecision({
    required this.decisionId,
    required this.decisionType,
    required this.contextHash,
    this.context = const {},
    this.choice = const {},
    this.rationale,
    this.applicationCount = 0,
    this.workspaceId,
    required this.createdAt,
    required this.lastAppliedAt,
  });

  /// Create from JSON.
  factory DisambiguationDecision.fromJson(Map<String, dynamic> json) {
    return DisambiguationDecision(
      decisionId: json['decisionId'] as String? ?? '',
      decisionType:
          DecisionType.fromString(json['decisionType'] as String? ?? 'confirm'),
      contextHash: json['contextHash'] as String? ?? '',
      context: json['context'] as Map<String, dynamic>? ?? {},
      choice: json['choice'] as Map<String, dynamic>? ?? {},
      rationale: json['rationale'] as String?,
      applicationCount: json['applicationCount'] as int? ?? 0,
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastAppliedAt: json['lastAppliedAt'] != null
          ? DateTime.parse(json['lastAppliedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'decisionId': decisionId,
      'decisionType': decisionType.name,
      'contextHash': contextHash,
      if (context.isNotEmpty) 'context': context,
      if (choice.isNotEmpty) 'choice': choice,
      if (rationale != null) 'rationale': rationale,
      'applicationCount': applicationCount,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
      'lastAppliedAt': lastAppliedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  DisambiguationDecision copyWith({
    String? decisionId,
    DecisionType? decisionType,
    String? contextHash,
    Map<String, dynamic>? context,
    Map<String, dynamic>? choice,
    String? rationale,
    int? applicationCount,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? lastAppliedAt,
  }) {
    return DisambiguationDecision(
      decisionId: decisionId ?? this.decisionId,
      decisionType: decisionType ?? this.decisionType,
      contextHash: contextHash ?? this.contextHash,
      context: context ?? this.context,
      choice: choice ?? this.choice,
      rationale: rationale ?? this.rationale,
      applicationCount: applicationCount ?? this.applicationCount,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      lastAppliedAt: lastAppliedAt ?? this.lastAppliedAt,
    );
  }

  /// Check if this decision matches the given context hash.
  bool matchesContext(String otherContextHash) {
    return contextHash == otherContextHash;
  }

  /// Calculate context similarity.
  double calculateContextSimilarity(Map<String, dynamic> otherContext) {
    if (context.isEmpty || otherContext.isEmpty) return 0.0;

    var matches = 0;
    var total = 0;

    for (final key in context.keys) {
      total++;
      if (otherContext.containsKey(key)) {
        final thisValue = context[key];
        final otherValue = otherContext[key];
        if (thisValue == otherValue) {
          matches++;
        } else if (thisValue is String && otherValue is String) {
          // Pattern matching for string values
          if (thisValue.startsWith('^') && thisValue.endsWith('\$')) {
            final regex = RegExp(thisValue);
            if (regex.hasMatch(otherValue)) {
              matches++;
            }
          }
        }
      }
    }

    return total > 0 ? matches / total : 0.0;
  }

  /// Check if this decision is applicable to the given context.
  bool isApplicable(Map<String, dynamic> otherContext,
      {double threshold = 0.8}) {
    return calculateContextSimilarity(otherContext) >= threshold;
  }

  /// Record an application.
  DisambiguationDecision recordApplication() {
    return copyWith(
      applicationCount: applicationCount + 1,
      lastAppliedAt: DateTime.now(),
    );
  }

  /// Check if this decision has been frequently applied.
  bool get isFrequentlyApplied => applicationCount >= 5;
}

/// Helper for generating context hash.
abstract class ContextHasher {
  /// Generate a hash from context map.
  static String hash(Map<String, dynamic> context) {
    // Simple hash implementation - in production, use proper hashing
    final sortedKeys = context.keys.toList()..sort();
    final normalized =
        sortedKeys.map((k) => '$k:${context[k]}').join('|');
    return normalized.hashCode.toRadixString(16);
  }
}
