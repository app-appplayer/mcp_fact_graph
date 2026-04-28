/// Storage Port - Abstract interface for fact graph storage.
///
/// Defines contracts for persisting and querying fact graph data.
/// Reference: 03-data-model-specification.md, 05-storage-adapter-contract.md
library;

import '../domain/entities/evidence.dart';
import '../domain/entities/fragment.dart';
import '../domain/entities/candidate.dart';
import '../domain/entities/entity.dart';
import '../domain/entities/fact.dart';
import '../domain/entities/view.dart';
import '../domain/entities/context_bundle.dart';
import '../domain/entities/summary_node.dart';
import '../domain/entities/claim.dart';
import '../domain/entities/pattern.dart';
import '../domain/entities/skill.dart';
import '../domain/entities/rubric.dart';
import '../domain/entities/evaluation_run.dart';
import '../domain/entities/relation.dart';
import '../domain/entities/fact_cluster.dart';
import '../domain/entities/classification.dart';
import '../domain/entities/fact_policy.dart';
import '../domain/entities/automation.dart';
import '../domain/entities/run.dart';
import '../domain/entities/extraction_rule.dart';
import '../domain/entities/extraction_validator.dart';
import '../domain/entities/classifier_memory.dart';
import '../domain/entities/artifact.dart';

/// Port for evidence storage operations.
abstract class EvidenceStoragePort {
  /// Store evidence.
  Future<void> saveEvidence(Evidence evidence);

  /// Get evidence by ID.
  Future<Evidence?> getEvidence(String evidenceId);

  /// Query evidence.
  Future<List<Evidence>> queryEvidence(EvidenceQuery query);

  /// Delete evidence.
  Future<void> deleteEvidence(String evidenceId);

  /// Store fragments.
  Future<void> saveFragments(List<Fragment> fragments);

  /// Get fragments for evidence.
  Future<List<Fragment>> getFragments(String evidenceId);
}

/// Query for evidence.
class EvidenceQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by source type.
  final EvidenceSourceType? sourceType;

  /// Filter by status.
  final EvidenceStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const EvidenceQuery({
    this.workspaceId,
    this.sourceType,
    this.status,
    this.fromDate,
    this.toDate,
    this.limit,
    this.offset,
  });
}

/// Port for candidate storage operations.
abstract class CandidateStoragePort {
  /// Store candidate.
  Future<void> saveCandidate(Candidate candidate);

  /// Get candidate by ID.
  Future<Candidate?> getCandidate(String candidateId);

  /// Query candidates.
  Future<List<Candidate>> queryCandidates(CandidateQuery query);

  /// Update candidate status.
  Future<void> updateCandidateStatus(String candidateId, CandidateStatus status);

  /// Delete candidate.
  Future<void> deleteCandidate(String candidateId);
}

/// Query for candidates.
class CandidateQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by type.
  final String? candidateType;

  /// Filter by status.
  final CandidateStatus? status;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Include only candidates needing review.
  final bool? needsReview;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const CandidateQuery({
    this.workspaceId,
    this.candidateType,
    this.status,
    this.minConfidence,
    this.needsReview,
    this.limit,
    this.offset,
  });
}

/// Port for entity storage operations.
abstract class EntityStoragePort {
  /// Store entity.
  Future<void> saveEntity(Entity entity);

  /// Get entity by ID.
  Future<Entity?> getEntity(String entityId);

  /// Query entities.
  Future<List<Entity>> queryEntities(EntityQuery query);

  /// Find entities by name.
  Future<List<Entity>> findByName(String query);

  /// Get related entities.
  Future<List<Entity>> getRelated(String entityId);

  /// Delete entity.
  Future<void> deleteEntity(String entityId);
}

/// Query for entities.
class EntityQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by entity type.
  final String? entityType;

  /// Filter by status.
  final EntityStatus? status;

  /// Filter by name pattern.
  final String? namePattern;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Include entities with specific relation types.
  final List<String>? relationTypes;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const EntityQuery({
    this.workspaceId,
    this.entityType,
    this.status,
    this.namePattern,
    this.minConfidence,
    this.relationTypes,
    this.limit,
    this.offset,
  });
}

/// Port for fact storage operations.
abstract class FactStoragePort {
  /// Store fact.
  Future<void> saveFact(Fact fact);

  /// Get fact by ID.
  Future<Fact?> getFact(String factId);

  /// Query facts.
  Future<List<Fact>> queryFacts(FactQuery query);

  /// Get facts for entity.
  Future<List<Fact>> getFactsForEntity(String entityId);

  /// Delete fact.
  Future<void> deleteFact(String factId);
}

/// Backward compatibility alias.
@Deprecated('Use FactStoragePort instead')
typedef EventStoragePort = FactStoragePort;

/// Query for facts.
class FactQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by fact type.
  final String? factType;

  /// Filter by status.
  final FactStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Filter by entity IDs.
  final List<String>? entityIds;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const FactQuery({
    this.workspaceId,
    this.factType,
    this.status,
    this.fromDate,
    this.toDate,
    this.entityIds,
    this.limit,
    this.offset,
  });
}

/// Backward compatibility alias.
@Deprecated('Use FactQuery instead')
typedef EventQuery = FactQuery;

/// Port for view storage operations.
abstract class ViewStoragePort {
  /// Store view.
  Future<void> saveView(View view);

  /// Get view by ID.
  Future<View?> getView(String viewId);

  /// Query views.
  Future<List<View>> queryViews(ViewQuery query);

  /// Delete view.
  Future<void> deleteView(String viewId);
}

/// Query for views.
class ViewQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by view type.
  final String? viewType;

  /// Filter by status.
  final ViewStatus? status;

  /// Filter by scope.
  final String? scope;

  /// Limit results.
  final int? limit;

  const ViewQuery({
    this.workspaceId,
    this.viewType,
    this.status,
    this.scope,
    this.limit,
  });
}

/// Port for context storage operations.
abstract class ContextStoragePort {
  /// Store context bundle.
  Future<void> saveContextBundle(InternalContextBundle bundle);

  /// Get context bundle by ID.
  Future<InternalContextBundle?> getContextBundle(String bundleId);

  /// Query context bundles.
  Future<List<InternalContextBundle>> queryContextBundles(ContextBundleQuery query);

  /// Store summary node.
  Future<void> saveSummaryNode(SummaryNode node);

  /// Get summary node by ID.
  Future<SummaryNode?> getSummaryNode(String nodeId);

  /// Query summary nodes.
  Future<List<SummaryNode>> querySummaryNodes(SummaryNodeQuery query);

  /// Store verifiable claim.
  Future<void> saveClaim(VerifiableClaim claim);

  /// Get verifiable claim by ID.
  Future<VerifiableClaim?> getClaim(String claimId);

  /// Query verifiable claims.
  Future<List<VerifiableClaim>> queryClaims(ClaimQuery query);

  /// Get pending verifiable claims.
  Future<List<VerifiableClaim>> getPendingClaims();
}

/// Query for context bundles.
class ContextBundleQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by creation date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  const ContextBundleQuery({
    this.workspaceId,
    this.fromDate,
    this.toDate,
    this.limit,
  });
}

/// Query for summary nodes.
class SummaryNodeQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by status.
  final SummaryStatus? status;

  /// Filter by scope type.
  final String? scopeType;

  /// Limit results.
  final int? limit;

  const SummaryNodeQuery({
    this.workspaceId,
    this.status,
    this.scopeType,
    this.limit,
  });
}

/// Query for verifiable claims.
class ClaimQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by claim type.
  final ClaimType? claimType;

  /// Filter by verification status.
  final ClaimStatus? verificationStatus;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Filter by response ID.
  final String? responseId;

  /// Limit results.
  final int? limit;

  const ClaimQuery({
    this.workspaceId,
    this.claimType,
    this.verificationStatus,
    this.minConfidence,
    this.responseId,
    this.limit,
  });
}

/// Port for skill operations storage.
abstract class SkillOpsStoragePort {
  /// Store pattern.
  Future<void> savePattern(Pattern pattern);

  /// Get pattern by ID.
  Future<Pattern?> getPattern(String patternId);

  /// Query patterns.
  Future<List<Pattern>> queryPatterns(PatternQuery query);

  /// Get active patterns.
  Future<List<Pattern>> getActivePatterns();

  /// Store skill.
  Future<void> saveSkill(Skill skill);

  /// Get skill by ID.
  Future<Skill?> getSkill(String skillId);

  /// Query skills.
  Future<List<Skill>> querySkills(SkillQuery query);

  /// Store rubric.
  Future<void> saveRubric(Rubric rubric);

  /// Get rubric by ID.
  Future<Rubric?> getRubric(String rubricId);

  /// Query rubrics.
  Future<List<Rubric>> queryRubrics(RubricQuery query);

  /// Store evaluation run.
  Future<void> saveEvaluationRun(EvaluationRun run);

  /// Get evaluation run by ID.
  Future<EvaluationRun?> getEvaluationRun(String runId);

  /// Query evaluation runs.
  Future<List<EvaluationRun>> queryEvaluationRuns(EvaluationRunQuery query);

  /// Get evaluation runs for skill.
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(String skillId);
}

/// Query for patterns.
class PatternQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by status.
  final PatternStatus? status;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Limit results.
  final int? limit;

  const PatternQuery({
    this.workspaceId,
    this.status,
    this.minConfidence,
    this.limit,
  });
}

/// Query for skills.
class SkillQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by status.
  final SkillStatus? status;

  /// Filter by name pattern.
  final String? namePattern;

  /// Limit results.
  final int? limit;

  const SkillQuery({
    this.workspaceId,
    this.status,
    this.namePattern,
    this.limit,
  });
}

/// Query for rubrics.
class RubricQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by status.
  final RubricStatus? status;

  /// Limit results.
  final int? limit;

  const RubricQuery({
    this.workspaceId,
    this.status,
    this.limit,
  });
}

/// Query for evaluation runs.
class EvaluationRunQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by rubric ID.
  final String? rubricId;

  /// Filter by status.
  final EvaluationStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  const EvaluationRunQuery({
    this.workspaceId,
    this.rubricId,
    this.status,
    this.fromDate,
    this.toDate,
    this.limit,
  });
}

// =============================================================================
// Additional Storage Ports for 100% Design Alignment
// Reference: 03-data-model-specification.md
// =============================================================================

/// Port for relation storage operations.
/// Reference: Design Section 2.5
abstract class RelationStoragePort {
  /// Store relation.
  Future<void> saveRelation(Relation relation);

  /// Get relation by ID.
  Future<Relation?> getRelation(String relationId);

  /// Query relations.
  Future<List<Relation>> queryRelations(RelationQuery query);

  /// Get relations for entity.
  Future<List<Relation>> getRelationsForEntity(String entityId);

  /// Delete relation.
  Future<void> deleteRelation(String relationId);
}

/// Query for relations.
class RelationQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by from entity ID.
  final String? fromEntityId;

  /// Filter by to entity ID.
  final String? toEntityId;

  /// Filter by relation type.
  final String? relationType;

  /// Filter by status.
  final RelationStatus? status;

  /// Limit results.
  final int? limit;

  const RelationQuery({
    this.workspaceId,
    this.fromEntityId,
    this.toEntityId,
    this.relationType,
    this.status,
    this.limit,
  });
}

/// Port for fact cluster storage operations.
/// Reference: Design Section 2.6.1
abstract class FactClusterStoragePort {
  /// Store fact cluster.
  Future<void> saveFactCluster(FactCluster cluster);

  /// Get fact cluster by ID.
  Future<FactCluster?> getFactCluster(String clusterId);

  /// Query fact clusters.
  Future<List<FactCluster>> queryFactClusters(FactClusterQuery query);

  /// Get cluster for fact.
  Future<FactCluster?> getClusterForFact(String factId);

  /// Delete fact cluster.
  Future<void> deleteFactCluster(String clusterId);
}

/// Query for fact clusters.
class FactClusterQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by fact type.
  final String? factType;

  /// Filter by status.
  final FactClusterStatus? status;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Limit results.
  final int? limit;

  const FactClusterQuery({
    this.workspaceId,
    this.factType,
    this.status,
    this.minConfidence,
    this.limit,
  });
}

/// Port for classification storage operations.
/// Reference: Design Section 2.7
abstract class ClassificationStoragePort {
  /// Store classification.
  Future<void> saveClassification(Classification classification);

  /// Get classification by ID.
  Future<Classification?> getClassification(String classificationId);

  /// Query classifications.
  Future<List<Classification>> queryClassifications(ClassificationQuery query);

  /// Get classifications for target.
  Future<List<Classification>> getClassificationsForTarget(
    String targetType,
    String targetId,
  );

  /// Delete classification.
  Future<void> deleteClassification(String classificationId);
}

/// Query for classifications.
class ClassificationQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by target type.
  final String? targetType;

  /// Filter by taxonomy ID.
  final String? taxonomyId;

  /// Filter by category ID.
  final String? categoryId;

  /// Filter by status.
  final ClassificationStatus? status;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Limit results.
  final int? limit;

  const ClassificationQuery({
    this.workspaceId,
    this.targetType,
    this.taxonomyId,
    this.categoryId,
    this.status,
    this.minConfidence,
    this.limit,
  });
}

/// Port for policy storage operations.
/// Reference: Design Section 2.8
abstract class PolicyStoragePort {
  /// Store policy.
  Future<void> savePolicy(FactPolicy policy);

  /// Get policy by ID.
  Future<FactPolicy?> getPolicy(String policyId);

  /// Get policy by ID and version.
  Future<FactPolicy?> getPolicyVersion(String policyId, String version);

  /// Query policies.
  Future<List<FactPolicy>> queryPolicies(PolicyQuery query);

  /// Get active policy for scope.
  Future<FactPolicy?> getActivePolicyForScope(String scope, PolicyType type);

  /// Delete policy.
  Future<void> deletePolicy(String policyId);
}

/// Query for policies.
class PolicyQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by policy type.
  final PolicyType? policyType;

  /// Filter by scope.
  final String? scope;

  /// Filter by active only.
  final bool? activeOnly;

  /// Limit results.
  final int? limit;

  const PolicyQuery({
    this.workspaceId,
    this.policyType,
    this.scope,
    this.activeOnly,
    this.limit,
  });
}

/// Port for automation storage operations.
/// Reference: Design Section 2.10
abstract class AutomationStoragePort {
  /// Store automation.
  Future<void> saveAutomation(Automation automation);

  /// Get automation by ID.
  Future<Automation?> getAutomation(String jobId);

  /// Query automations.
  Future<List<Automation>> queryAutomations(AutomationQuery query);

  /// Get enabled automations.
  Future<List<Automation>> getEnabledAutomations();

  /// Delete automation.
  Future<void> deleteAutomation(String jobId);
}

/// Query for automations.
class AutomationQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by trigger type.
  final AutomationTriggerType? triggerType;

  /// Filter by enabled.
  final bool? enabled;

  /// Limit results.
  final int? limit;

  const AutomationQuery({
    this.workspaceId,
    this.triggerType,
    this.enabled,
    this.limit,
  });
}

/// Port for run storage operations.
/// Reference: Design Section 2.11
abstract class RunStoragePort {
  /// Store run.
  Future<void> saveRun(Run run);

  /// Get run by ID.
  Future<Run?> getRun(String runId);

  /// Query runs.
  Future<List<Run>> queryRuns(RunQuery query);

  /// Get runs for automation.
  Future<List<Run>> getRunsForAutomation(String jobId);

  /// Get run by idempotency key.
  Future<Run?> getRunByIdempotencyKey(String idempotencyKey);

  /// Delete run.
  Future<void> deleteRun(String runId);
}

/// Query for runs.
class RunQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by job ID.
  final String? jobId;

  /// Filter by status.
  final RunStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  const RunQuery({
    this.workspaceId,
    this.jobId,
    this.status,
    this.fromDate,
    this.toDate,
    this.limit,
  });
}

/// Port for extraction rule storage operations.
/// Reference: Design Section 2.12.1
abstract class ExtractionRuleStoragePort {
  /// Store extraction rule.
  Future<void> saveExtractionRule(ExtractionRule rule);

  /// Get extraction rule by ID.
  Future<ExtractionRule?> getExtractionRule(String ruleId);

  /// Query extraction rules.
  Future<List<ExtractionRule>> queryExtractionRules(ExtractionRuleQuery query);

  /// Get active rules for source type.
  Future<List<ExtractionRule>> getActiveRulesForSourceType(String sourceType);

  /// Delete extraction rule.
  Future<void> deleteExtractionRule(String ruleId);
}

/// Query for extraction rules.
class ExtractionRuleQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by source type.
  final String? sourceType;

  /// Filter by target field.
  final String? targetField;

  /// Filter by rule type.
  final RuleType? ruleType;

  /// Filter by status.
  final RuleStatus? status;

  /// Filter by minimum accuracy.
  final double? minAccuracy;

  /// Limit results.
  final int? limit;

  const ExtractionRuleQuery({
    this.workspaceId,
    this.sourceType,
    this.targetField,
    this.ruleType,
    this.status,
    this.minAccuracy,
    this.limit,
  });
}

/// Port for extraction validator storage operations.
/// Reference: Design Section 2.12.2
abstract class ExtractionValidatorStoragePort {
  /// Store extraction validator.
  Future<void> saveExtractionValidator(ExtractionValidator validator);

  /// Get extraction validator by ID.
  Future<ExtractionValidator?> getExtractionValidator(String validatorId);

  /// Query extraction validators.
  Future<List<ExtractionValidator>> queryExtractionValidators(
    ExtractionValidatorQuery query,
  );

  /// Get validators for fact type.
  Future<List<ExtractionValidator>> getValidatorsForFactType(String factType);

  /// Delete extraction validator.
  Future<void> deleteExtractionValidator(String validatorId);
}

/// Query for extraction validators.
class ExtractionValidatorQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by fact type.
  final String? factType;

  /// Filter by severity.
  final ValidatorSeverity? severity;

  /// Filter by enabled.
  final bool? enabled;

  /// Limit results.
  final int? limit;

  const ExtractionValidatorQuery({
    this.workspaceId,
    this.factType,
    this.severity,
    this.enabled,
    this.limit,
  });
}

/// Port for classifier memory storage operations.
/// Reference: Design Section 2.12.3
abstract class ClassifierMemoryStoragePort {
  /// Store classifier memory.
  Future<void> saveClassifierMemory(ClassifierMemory memory);

  /// Get classifier memory by ID.
  Future<ClassifierMemory?> getClassifierMemory(String memoryId);

  /// Query classifier memories.
  Future<List<ClassifierMemory>> queryClassifierMemories(
    ClassifierMemoryQuery query,
  );

  /// Find similar memories for classification.
  Future<List<ClassifierMemory>> findSimilarMemories(
    String taxonomyId,
    Map<String, dynamic> features,
  );

  /// Delete classifier memory.
  Future<void> deleteClassifierMemory(String memoryId);
}

/// Query for classifier memories.
class ClassifierMemoryQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by taxonomy ID.
  final String? taxonomyId;

  /// Filter by category ID.
  final String? categoryId;

  /// Filter by source.
  final MemorySource? source;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Limit results.
  final int? limit;

  const ClassifierMemoryQuery({
    this.workspaceId,
    this.taxonomyId,
    this.categoryId,
    this.source,
    this.minConfidence,
    this.limit,
  });
}

/// Port for artifact storage operations.
/// Reference: Design Section 2.11 - Run artifacts
abstract class ArtifactStoragePort {
  /// Store artifact.
  Future<void> saveArtifact(Artifact artifact);

  /// Get artifact by ID.
  Future<Artifact?> getArtifact(String artifactId);

  /// Query artifacts.
  Future<List<Artifact>> queryArtifacts(ArtifactQuery query);

  /// Get artifacts for run.
  Future<List<Artifact>> getArtifactsForRun(String runId);

  /// Delete artifact.
  Future<void> deleteArtifact(String artifactId);
}

/// Query for artifacts.
class ArtifactQuery {
  /// Filter by workspace.
  final String? workspaceId;

  /// Filter by run ID.
  final String? runId;

  /// Filter by artifact type.
  final String? artifactType;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  const ArtifactQuery({
    this.workspaceId,
    this.runId,
    this.artifactType,
    this.fromDate,
    this.toDate,
    this.limit,
  });
}
