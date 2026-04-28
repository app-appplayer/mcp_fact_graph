/// InternalContextBundle entity for L2 ContextOps Layer.
///
/// Represents short context bundles for LLM interactions.
/// Reference: 03-data-model-specification.md Section 2.15.2
library;

import 'fact.dart';
import 'summary_node.dart';

/// InternalContextBundle represents an internal context bundle for LLM operations.
///
/// Extends the port-level ContextBundle (from mcp_bundle) with implementation
/// details for context generation.
/// Reference: Design Section 2.15.2
class InternalContextBundle {
  /// Unique bundle identifier.
  final String bundleId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Query or prompt this context is for.
  final String query;

  /// Confirmed facts (latest, supersedes reflected).
  /// Reference: Design Section 2.15.2 - List<Fact>.
  final List<Fact> facts;

  /// Relevant cumulative summaries.
  /// Reference: Design Section 2.15.2 - List<SummaryNode>.
  final List<SummaryNode> summaries;

  /// Evidence/content references.
  /// Reference: Design Section 2.15.2 - List<String>.
  final List<String> evidenceRefs;

  /// Unresolved items/conflicts requiring attention.
  /// Reference: Design Section 2.15.2 - OpenQuestion support.
  final List<OpenQuestion> openQuestions;

  /// Total token count estimate.
  final int tokenEstimate;

  /// Point-in-time snapshot for reproducibility.
  /// Reference: Design Section 2.15.2 - enables time-travel queries.
  final DateTime asOf;

  /// Policy version used for generating this bundle.
  /// Reference: Design Section 2.15.2 - enables reproducibility.
  final String policyVersion;

  /// Budget constraints for context generation.
  /// Reference: Design Section 2.15.2 - BundleBudget support.
  final BundleBudget budget;

  /// When this bundle was created.
  final DateTime createdAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const InternalContextBundle({
    required this.bundleId,
    required this.workspaceId,
    required this.query,
    this.facts = const [],
    this.summaries = const [],
    this.evidenceRefs = const [],
    this.openQuestions = const [],
    this.tokenEstimate = 0,
    required this.asOf,
    required this.policyVersion,
    this.budget = const BundleBudget(),
    required this.createdAt,
    this.metadata = const {},
  });

  factory InternalContextBundle.fromJson(Map<String, dynamic> json) {
    return InternalContextBundle(
      bundleId: json['bundleId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      query: json['query'] as String? ?? '',
      facts: (json['facts'] as List<dynamic>?)
              ?.map((e) => Fact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summaries: (json['summaries'] as List<dynamic>?)
              ?.map((e) => SummaryNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      openQuestions: (json['openQuestions'] as List<dynamic>?)
              ?.map((e) => OpenQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokenEstimate: json['tokenEstimate'] as int? ?? 0,
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      policyVersion: json['policyVersion'] as String? ?? '1.0.0',
      budget: json['budget'] != null
          ? BundleBudget.fromJson(json['budget'] as Map<String, dynamic>)
          : const BundleBudget(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bundleId': bundleId,
      'workspaceId': workspaceId,
      'query': query,
      if (facts.isNotEmpty)
        'facts': facts.map((f) => f.toJson()).toList(),
      if (summaries.isNotEmpty)
        'summaries': summaries.map((s) => s.toJson()).toList(),
      if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      if (openQuestions.isNotEmpty)
        'openQuestions': openQuestions.map((q) => q.toJson()).toList(),
      'tokenEstimate': tokenEstimate,
      'asOf': asOf.toIso8601String(),
      'policyVersion': policyVersion,
      'budget': budget.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  InternalContextBundle copyWith({
    String? bundleId,
    String? workspaceId,
    String? query,
    List<Fact>? facts,
    List<SummaryNode>? summaries,
    List<String>? evidenceRefs,
    List<OpenQuestion>? openQuestions,
    int? tokenEstimate,
    DateTime? asOf,
    String? policyVersion,
    BundleBudget? budget,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return InternalContextBundle(
      bundleId: bundleId ?? this.bundleId,
      workspaceId: workspaceId ?? this.workspaceId,
      query: query ?? this.query,
      facts: facts ?? this.facts,
      summaries: summaries ?? this.summaries,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      openQuestions: openQuestions ?? this.openQuestions,
      tokenEstimate: tokenEstimate ?? this.tokenEstimate,
      asOf: asOf ?? this.asOf,
      policyVersion: policyVersion ?? this.policyVersion,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if bundle is within token budget.
  bool get isWithinBudget => tokenEstimate <= budget.maxTokens;

  /// Check if bundle has unresolved questions.
  bool get hasOpenQuestions => openQuestions.isNotEmpty;

  @override
  String toString() =>
      'InternalContextBundle($bundleId, tokens: $tokenEstimate/${budget.maxTokens})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InternalContextBundle && bundleId == other.bundleId;

  @override
  int get hashCode => bundleId.hashCode;
}

/// Backward compatibility alias.
@Deprecated('Use InternalContextBundle instead')
typedef ContextBundle = InternalContextBundle;

/// OpenQuestion represents an unresolved item requiring attention.
///
/// Reference: 03-data-model-specification.md Section 2.15.2
class OpenQuestion {
  /// Unique question identifier.
  final String questionId;

  /// Question type (unresolved | conflict | missingEvidence).
  final String questionType;

  /// Description of what needs resolution.
  final String description;

  /// Related candidate/event IDs.
  final List<String> relatedIds;

  /// Standardized reason code.
  final String? reasonCode;

  const OpenQuestion({
    required this.questionId,
    required this.questionType,
    required this.description,
    this.relatedIds = const [],
    this.reasonCode,
  });

  factory OpenQuestion.fromJson(Map<String, dynamic> json) {
    return OpenQuestion(
      questionId: json['questionId'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'unresolved',
      description: json['description'] as String? ?? '',
      relatedIds: (json['relatedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reasonCode: json['reasonCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionType': questionType,
      'description': description,
      if (relatedIds.isNotEmpty) 'relatedIds': relatedIds,
      if (reasonCode != null) 'reasonCode': reasonCode,
    };
  }
}

/// BundleBudget defines constraints for context generation.
///
/// Reference: 03-data-model-specification.md Section 2.15.2
class BundleBudget {
  /// Maximum number of nodes to include.
  final int maxNodes;

  /// Maximum token count.
  final int maxTokens;

  /// Maximum sentences (for summaries).
  final int maxSentences;

  const BundleBudget({
    this.maxNodes = 100,
    this.maxTokens = 4096,
    this.maxSentences = 50,
  });

  factory BundleBudget.fromJson(Map<String, dynamic> json) {
    return BundleBudget(
      maxNodes: json['maxNodes'] as int? ?? 100,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      maxSentences: json['maxSentences'] as int? ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxNodes': maxNodes,
      'maxTokens': maxTokens,
      'maxSentences': maxSentences,
    };
  }

  BundleBudget copyWith({
    int? maxNodes,
    int? maxTokens,
    int? maxSentences,
  }) {
    return BundleBudget(
      maxNodes: maxNodes ?? this.maxNodes,
      maxTokens: maxTokens ?? this.maxTokens,
      maxSentences: maxSentences ?? this.maxSentences,
    );
  }
}
