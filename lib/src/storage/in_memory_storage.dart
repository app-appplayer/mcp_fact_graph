/// In-Memory Storage Adapter - Implements all storage ports for testing/development.
///
/// Provides in-memory implementations of all storage ports defined in
/// storage_port.dart for rapid prototyping and testing.
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
import '../domain/entities/artifact.dart';
import '../domain/entities/extraction_rule.dart';
import '../domain/entities/extraction_validator.dart';
import '../domain/entities/classifier_memory.dart';
import '../ports/storage_port.dart';

// =============================================================================
// InMemoryEvidenceStorage (L0)
// =============================================================================

/// In-memory implementation of EvidenceStoragePort.
class InMemoryEvidenceStorage implements EvidenceStoragePort {
  final Map<String, Evidence> _evidence = {};
  final Map<String, List<Fragment>> _fragments = {};

  @override
  Future<void> saveEvidence(Evidence evidence) async {
    _evidence[evidence.evidenceId] = evidence;
  }

  @override
  Future<Evidence?> getEvidence(String evidenceId) async {
    return _evidence[evidenceId];
  }

  @override
  Future<List<Evidence>> queryEvidence(EvidenceQuery query) async {
    var results = _evidence.values.toList();

    if (query.workspaceId != null) {
      results = results.where((e) => e.workspaceId == query.workspaceId).toList();
    }

    if (query.sourceType != null) {
      results = results.where((e) => e.sourceType == query.sourceType).toList();
    }

    if (query.status != null) {
      results = results.where((e) => e.status == query.status).toList();
    }

    if (query.fromDate != null) {
      results = results.where((e) => e.ingestedAt.isAfter(query.fromDate!)).toList();
    }

    if (query.toDate != null) {
      results = results.where((e) => e.ingestedAt.isBefore(query.toDate!)).toList();
    }

    if (query.offset != null) {
      results = results.skip(query.offset!).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> deleteEvidence(String evidenceId) async {
    _evidence.remove(evidenceId);
    _fragments.remove(evidenceId);
  }

  @override
  Future<void> saveFragments(List<Fragment> fragments) async {
    for (final fragment in fragments) {
      final evidenceId = fragment.evidenceId;
      _fragments.putIfAbsent(evidenceId, () => []).add(fragment);
    }
  }

  @override
  Future<List<Fragment>> getFragments(String evidenceId) async {
    return _fragments[evidenceId] ?? [];
  }

  void clear() {
    _evidence.clear();
    _fragments.clear();
  }

  int get evidenceCount => _evidence.length;
}

// =============================================================================
// InMemoryCandidateStorage (L1)
// =============================================================================

/// In-memory implementation of CandidateStoragePort.
class InMemoryCandidateStorage implements CandidateStoragePort {
  final Map<String, Candidate> _candidates = {};

  @override
  Future<void> saveCandidate(Candidate candidate) async {
    _candidates[candidate.candidateId] = candidate;
  }

  @override
  Future<Candidate?> getCandidate(String candidateId) async {
    return _candidates[candidateId];
  }

  @override
  Future<List<Candidate>> queryCandidates(CandidateQuery query) async {
    var results = _candidates.values.toList();

    if (query.workspaceId != null) {
      results = results.where((c) => c.workspaceId == query.workspaceId).toList();
    }

    if (query.candidateType != null) {
      results = results.where((c) => c.objectType == query.candidateType).toList();
    }

    if (query.status != null) {
      results = results.where((c) => c.status == query.status).toList();
    }

    if (query.minConfidence != null) {
      results = results.where((c) => c.confidence >= query.minConfidence!).toList();
    }

    if (query.needsReview == true) {
      results = results.where((c) =>
          c.status == CandidateStatus.open &&
          c.unresolvedIssues.isNotEmpty).toList();
    }

    if (query.offset != null) {
      results = results.skip(query.offset!).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> updateCandidateStatus(
      String candidateId, CandidateStatus status) async {
    final candidate = _candidates[candidateId];
    if (candidate != null) {
      _candidates[candidateId] = candidate.copyWith(status: status);
    }
  }

  @override
  Future<void> deleteCandidate(String candidateId) async {
    _candidates.remove(candidateId);
  }

  void clear() {
    _candidates.clear();
  }

  int get candidateCount => _candidates.length;
}

// =============================================================================
// InMemoryEntityStorage (L1)
// =============================================================================

/// In-memory implementation of EntityStoragePort.
class InMemoryEntityStorage implements EntityStoragePort {
  final Map<String, Entity> _entities = {};

  @override
  Future<void> saveEntity(Entity entity) async {
    _entities[entity.entityId] = entity;
  }

  @override
  Future<Entity?> getEntity(String entityId) async {
    return _entities[entityId];
  }

  @override
  Future<List<Entity>> queryEntities(EntityQuery query) async {
    var results = _entities.values.toList();

    if (query.workspaceId != null) {
      results = results.where((e) => e.workspaceId == query.workspaceId).toList();
    }

    if (query.entityType != null) {
      results = results.where((e) => e.type == query.entityType).toList();
    }

    if (query.status != null) {
      results = results.where((e) => e.status == query.status).toList();
    }

    if (query.namePattern != null) {
      final pattern = query.namePattern!.toLowerCase();
      results = results
          .where((e) => e.canonicalName.toLowerCase().contains(pattern))
          .toList();
    }

    if (query.minConfidence != null) {
      results = results.where((e) => e.confidence >= query.minConfidence!).toList();
    }

    if (query.offset != null) {
      results = results.skip(query.offset!).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<List<Entity>> findByName(String query) async {
    final lowerQuery = query.toLowerCase();
    return _entities.values
        .where((e) => e.canonicalName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<Entity>> getRelated(String entityId) async {
    // Without EntityRelation, use RelationStoragePort for relation queries.
    // This implementation returns empty for backward compatibility.
    return [];
  }

  @override
  Future<void> deleteEntity(String entityId) async {
    _entities.remove(entityId);
  }

  void clear() {
    _entities.clear();
  }

  int get entityCount => _entities.length;
}

// =============================================================================
// InMemoryFactStorage (L1)
// =============================================================================

/// In-memory implementation of FactStoragePort.
class InMemoryFactStorage implements FactStoragePort {
  final Map<String, Fact> _facts = {};
  final Map<String, Set<String>> _entityFactIndex = {};

  @override
  Future<void> saveFact(Fact fact) async {
    _facts[fact.factId] = fact;

    // Index by associated entity IDs
    for (final entityId in fact.entityRefs) {
      _entityFactIndex
          .putIfAbsent(entityId, () => {})
          .add(fact.factId);
    }
  }

  @override
  Future<Fact?> getFact(String factId) async {
    return _facts[factId];
  }

  @override
  Future<List<Fact>> queryFacts(FactQuery query) async {
    var results = _facts.values.toList();

    if (query.workspaceId != null) {
      results = results.where((f) => f.workspaceId == query.workspaceId).toList();
    }

    if (query.factType != null) {
      results = results.where((f) => f.factType == query.factType).toList();
    }

    if (query.status != null) {
      results = results.where((f) => f.status == query.status).toList();
    }

    if (query.fromDate != null) {
      results = results
          .where((f) => f.occurredAt.isAfter(query.fromDate!))
          .toList();
    }

    if (query.toDate != null) {
      results = results
          .where((f) => f.occurredAt.isBefore(query.toDate!))
          .toList();
    }

    if (query.entityIds != null && query.entityIds!.isNotEmpty) {
      results = results.where((f) {
        return f.entityRefs.any((id) => query.entityIds!.contains(id));
      }).toList();
    }

    if (query.offset != null) {
      results = results.skip(query.offset!).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<List<Fact>> getFactsForEntity(String entityId) async {
    final factIds = _entityFactIndex[entityId] ?? {};
    return factIds.map((id) => _facts[id]).whereType<Fact>().toList();
  }

  @override
  Future<void> deleteFact(String factId) async {
    final fact = _facts.remove(factId);
    if (fact != null) {
      for (final entityId in fact.entityRefs) {
        _entityFactIndex[entityId]?.remove(factId);
      }
    }
  }

  void clear() {
    _facts.clear();
    _entityFactIndex.clear();
  }

  int get factCount => _facts.length;
}

/// Backward compatibility alias.
@Deprecated('Use InMemoryFactStorage instead')
typedef InMemoryEventStorage = InMemoryFactStorage;

// =============================================================================
// InMemoryViewStorage (L1)
// =============================================================================

/// In-memory implementation of ViewStoragePort.
class InMemoryViewStorage implements ViewStoragePort {
  final Map<String, View> _views = {};

  @override
  Future<void> saveView(View view) async {
    _views[view.viewId] = view;
  }

  @override
  Future<View?> getView(String viewId) async {
    return _views[viewId];
  }

  @override
  Future<List<View>> queryViews(ViewQuery query) async {
    var results = _views.values.toList();

    if (query.workspaceId != null) {
      results = results.where((v) => v.workspaceId == query.workspaceId).toList();
    }

    if (query.viewType != null) {
      results = results.where((v) => v.viewType == query.viewType).toList();
    }

    if (query.status != null) {
      results = results.where((v) => v.status == query.status).toList();
    }

    if (query.scope != null) {
      results = results.where((v) => v.scope == query.scope).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> deleteView(String viewId) async {
    _views.remove(viewId);
  }

  void clear() {
    _views.clear();
  }

  int get viewCount => _views.length;
}

// =============================================================================
// InMemoryContextStorage (L2)
// =============================================================================

/// In-memory implementation of ContextStoragePort.
class InMemoryContextStorage implements ContextStoragePort {
  final Map<String, InternalContextBundle> _contextBundles = {};
  final Map<String, SummaryNode> _summaryNodes = {};
  final Map<String, VerifiableClaim> _claims = {};

  @override
  Future<void> saveContextBundle(InternalContextBundle bundle) async {
    _contextBundles[bundle.bundleId] = bundle;
  }

  @override
  Future<InternalContextBundle?> getContextBundle(String bundleId) async {
    return _contextBundles[bundleId];
  }

  @override
  Future<List<InternalContextBundle>> queryContextBundles(ContextBundleQuery query) async {
    var results = _contextBundles.values.toList();

    if (query.workspaceId != null) {
      results = results.where((b) => b.workspaceId == query.workspaceId).toList();
    }

    if (query.fromDate != null) {
      results = results.where((b) => b.createdAt.isAfter(query.fromDate!)).toList();
    }

    if (query.toDate != null) {
      results = results.where((b) => b.createdAt.isBefore(query.toDate!)).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> saveSummaryNode(SummaryNode node) async {
    _summaryNodes[node.summaryId] = node;
  }

  @override
  Future<SummaryNode?> getSummaryNode(String nodeId) async {
    return _summaryNodes[nodeId];
  }

  @override
  Future<List<SummaryNode>> querySummaryNodes(SummaryNodeQuery query) async {
    var results = _summaryNodes.values.toList();

    if (query.workspaceId != null) {
      results = results.where((s) => s.workspaceId == query.workspaceId).toList();
    }

    if (query.status != null) {
      results = results.where((s) => s.status == query.status).toList();
    }

    if (query.scopeType != null) {
      results = results.where((s) => s.scope.scopeType == query.scopeType).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> saveClaim(VerifiableClaim claim) async {
    _claims[claim.claimId] = claim;
  }

  @override
  Future<VerifiableClaim?> getClaim(String claimId) async {
    return _claims[claimId];
  }

  @override
  Future<List<VerifiableClaim>> queryClaims(ClaimQuery query) async {
    var results = _claims.values.toList();

    if (query.workspaceId != null) {
      results = results.where((c) => c.workspaceId == query.workspaceId).toList();
    }

    if (query.claimType != null) {
      results = results.where((c) => c.claimType == query.claimType).toList();
    }

    if (query.verificationStatus != null) {
      results = results
          .where((c) => c.verificationStatus == query.verificationStatus)
          .toList();
    }

    if (query.minConfidence != null) {
      results = results.where((c) => c.confidence >= query.minConfidence!).toList();
    }

    if (query.responseId != null) {
      results = results.where((c) => c.responseId == query.responseId).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<List<VerifiableClaim>> getPendingClaims() async {
    return _claims.values
        .where((c) => c.verificationStatus == ClaimStatus.pending)
        .toList();
  }

  void clear() {
    _contextBundles.clear();
    _summaryNodes.clear();
    _claims.clear();
  }

  int get contextBundleCount => _contextBundles.length;
  int get summaryNodeCount => _summaryNodes.length;
  int get claimCount => _claims.length;
}

// =============================================================================
// InMemorySkillOpsStorage (L3)
// =============================================================================

/// In-memory implementation of SkillOpsStoragePort.
class InMemorySkillOpsStorage implements SkillOpsStoragePort {
  final Map<String, Pattern> _patterns = {};
  final Map<String, Skill> _skills = {};
  final Map<String, Rubric> _rubrics = {};
  final Map<String, EvaluationRun> _evaluationRuns = {};
  final Map<String, Set<String>> _skillEvaluations = {};

  @override
  Future<void> savePattern(Pattern pattern) async {
    _patterns[pattern.patternId] = pattern;
  }

  @override
  Future<Pattern?> getPattern(String patternId) async {
    return _patterns[patternId];
  }

  @override
  Future<List<Pattern>> queryPatterns(PatternQuery query) async {
    var results = _patterns.values.toList();

    if (query.workspaceId != null) {
      results = results.where((p) => p.workspaceId == query.workspaceId).toList();
    }

    if (query.status != null) {
      results = results.where((p) => p.status == query.status).toList();
    }

    if (query.minConfidence != null) {
      results = results.where((p) => p.confidence >= query.minConfidence!).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<List<Pattern>> getActivePatterns() async {
    return _patterns.values
        .where((p) => p.status == PatternStatus.confirmed)
        .toList();
  }

  @override
  Future<void> saveSkill(Skill skill) async {
    _skills[skill.skillId] = skill;
  }

  @override
  Future<Skill?> getSkill(String skillId) async {
    return _skills[skillId];
  }

  @override
  Future<List<Skill>> querySkills(SkillQuery query) async {
    var results = _skills.values.toList();

    if (query.workspaceId != null) {
      results = results.where((s) => s.workspaceId == query.workspaceId).toList();
    }

    if (query.status != null) {
      results = results.where((s) => s.status == query.status).toList();
    }

    if (query.namePattern != null) {
      final pattern = query.namePattern!.toLowerCase();
      results = results
          .where((s) => s.name.toLowerCase().contains(pattern))
          .toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> saveRubric(Rubric rubric) async {
    _rubrics[rubric.rubricId] = rubric;
  }

  @override
  Future<Rubric?> getRubric(String rubricId) async {
    return _rubrics[rubricId];
  }

  @override
  Future<List<Rubric>> queryRubrics(RubricQuery query) async {
    var results = _rubrics.values.toList();

    if (query.workspaceId != null) {
      results = results.where((r) => r.workspaceId == query.workspaceId).toList();
    }

    if (query.status != null) {
      results = results.where((r) => r.status == query.status).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<void> saveEvaluationRun(EvaluationRun run) async {
    _evaluationRuns[run.evaluationId] = run;

    // Index by target ID from input for skill-based lookups
    final targetId = run.input.targetId;
    if (targetId != null) {
      _skillEvaluations.putIfAbsent(targetId, () => {}).add(run.evaluationId);
    }
  }

  @override
  Future<EvaluationRun?> getEvaluationRun(String runId) async {
    return _evaluationRuns[runId];
  }

  @override
  Future<List<EvaluationRun>> queryEvaluationRuns(EvaluationRunQuery query) async {
    var results = _evaluationRuns.values.toList();

    if (query.workspaceId != null) {
      results = results.where((r) => r.workspaceId == query.workspaceId).toList();
    }

    if (query.rubricId != null) {
      results = results.where((r) => r.rubricId == query.rubricId).toList();
    }

    if (query.status != null) {
      results = results.where((r) => r.status == query.status).toList();
    }

    if (query.fromDate != null) {
      results = results.where((r) => r.createdAt.isAfter(query.fromDate!)).toList();
    }

    if (query.toDate != null) {
      results = results.where((r) => r.createdAt.isBefore(query.toDate!)).toList();
    }

    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }

    return results;
  }

  @override
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(String skillId) async {
    final runIds = _skillEvaluations[skillId] ?? {};
    return runIds
        .map((id) => _evaluationRuns[id])
        .whereType<EvaluationRun>()
        .toList();
  }

  void clear() {
    _patterns.clear();
    _skills.clear();
    _rubrics.clear();
    _evaluationRuns.clear();
    _skillEvaluations.clear();
  }

  int get patternCount => _patterns.length;
  int get skillCount => _skills.length;
  int get rubricCount => _rubrics.length;
  int get evaluationRunCount => _evaluationRuns.length;
}

// =============================================================================
// InMemoryStorageContainer
// =============================================================================

// =============================================================================
// InMemoryRelationStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of RelationStoragePort.
class InMemoryRelationStorage implements RelationStoragePort {
  final Map<String, Relation> _relations = {};

  @override
  Future<void> saveRelation(Relation relation) async {
    _relations[relation.relationId] = relation;
  }

  @override
  Future<Relation?> getRelation(String relationId) async =>
      _relations[relationId];

  @override
  Future<List<Relation>> queryRelations(RelationQuery query) async {
    var results = _relations.values.toList();
    if (query.workspaceId != null) {
      results = results
          .where((r) =>
              (r.attributes['workspaceId'] as String?) == query.workspaceId)
          .toList();
    }
    if (query.fromEntityId != null) {
      results =
          results.where((r) => r.fromEntityId == query.fromEntityId).toList();
    }
    if (query.toEntityId != null) {
      results =
          results.where((r) => r.toEntityId == query.toEntityId).toList();
    }
    if (query.relationType != null) {
      results =
          results.where((r) => r.relationType == query.relationType).toList();
    }
    if (query.status != null) {
      results = results.where((r) => r.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Relation>> getRelationsForEntity(String entityId) async {
    return _relations.values
        .where((r) => r.fromEntityId == entityId || r.toEntityId == entityId)
        .toList();
  }

  @override
  Future<void> deleteRelation(String relationId) async {
    _relations.remove(relationId);
  }

  void clear() {
    _relations.clear();
  }

  int get relationCount => _relations.length;
}

// =============================================================================
// InMemoryFactClusterStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of FactClusterStoragePort.
class InMemoryFactClusterStorage implements FactClusterStoragePort {
  final Map<String, FactCluster> _clusters = {};
  final Map<String, String> _factToCluster = {};

  @override
  Future<void> saveFactCluster(FactCluster cluster) async {
    _clusters[cluster.factClusterId] = cluster;
  }

  @override
  Future<FactCluster?> getFactCluster(String clusterId) async =>
      _clusters[clusterId];

  @override
  Future<List<FactCluster>> queryFactClusters(FactClusterQuery query) async {
    var results = _clusters.values.toList();
    if (query.factType != null) {
      results = results.where((c) => c.factType == query.factType).toList();
    }
    if (query.status != null) {
      results = results.where((c) => c.status == query.status).toList();
    }
    if (query.minConfidence != null) {
      results =
          results.where((c) => c.confidence >= query.minConfidence!).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<FactCluster?> getClusterForFact(String factId) async {
    final clusterId = _factToCluster[factId];
    if (clusterId == null) return null;
    return _clusters[clusterId];
  }

  @override
  Future<void> deleteFactCluster(String clusterId) async {
    _clusters.remove(clusterId);
    _factToCluster.removeWhere((_, v) => v == clusterId);
  }

  /// Manually map a fact to its cluster (used by tests wiring a cluster).
  void indexFact(String factId, String clusterId) {
    _factToCluster[factId] = clusterId;
  }

  void clear() {
    _clusters.clear();
    _factToCluster.clear();
  }

  int get factClusterCount => _clusters.length;
}

// =============================================================================
// InMemoryClassificationStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of ClassificationStoragePort.
class InMemoryClassificationStorage implements ClassificationStoragePort {
  final Map<String, Classification> _classifications = {};

  @override
  Future<void> saveClassification(Classification classification) async {
    _classifications[classification.classificationId] = classification;
  }

  @override
  Future<Classification?> getClassification(String classificationId) async =>
      _classifications[classificationId];

  @override
  Future<List<Classification>> queryClassifications(
      ClassificationQuery query) async {
    var results = _classifications.values.toList();
    if (query.targetType != null) {
      results =
          results.where((c) => c.targetType == query.targetType).toList();
    }
    if (query.taxonomyId != null) {
      results =
          results.where((c) => c.taxonomyId == query.taxonomyId).toList();
    }
    if (query.categoryId != null) {
      results =
          results.where((c) => c.categoryId == query.categoryId).toList();
    }
    if (query.status != null) {
      results = results.where((c) => c.status == query.status).toList();
    }
    if (query.minConfidence != null) {
      results =
          results.where((c) => c.confidence >= query.minConfidence!).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Classification>> getClassificationsForTarget(
    String targetType,
    String targetId,
  ) async {
    return _classifications.values
        .where((c) => c.targetType == targetType && c.targetId == targetId)
        .toList();
  }

  @override
  Future<void> deleteClassification(String classificationId) async {
    _classifications.remove(classificationId);
  }

  void clear() {
    _classifications.clear();
  }

  int get classificationCount => _classifications.length;
}

// =============================================================================
// InMemoryPolicyStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of PolicyStoragePort.
class InMemoryPolicyStorage implements PolicyStoragePort {
  final Map<String, FactPolicy> _policies = {};

  @override
  Future<void> savePolicy(FactPolicy policy) async {
    _policies[policy.policyId] = policy;
  }

  @override
  Future<FactPolicy?> getPolicy(String policyId) async => _policies[policyId];

  @override
  Future<FactPolicy?> getPolicyVersion(String policyId, String version) async {
    final policy = _policies[policyId];
    if (policy == null || policy.version != version) return null;
    return policy;
  }

  @override
  Future<List<FactPolicy>> queryPolicies(PolicyQuery query) async {
    var results = _policies.values.toList();
    if (query.policyType != null) {
      results = results.where((p) => p.type == query.policyType).toList();
    }
    if (query.scope != null) {
      results = results.where((p) => p.scope == query.scope).toList();
    }
    if (query.activeOnly == true) {
      results = results.where(_isPolicyActive).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<FactPolicy?> getActivePolicyForScope(
    String scope,
    PolicyType type,
  ) async {
    for (final p in _policies.values) {
      if (p.scope == scope && p.type == type && _isPolicyActive(p)) {
        return p;
      }
    }
    return null;
  }

  bool _isPolicyActive(FactPolicy p) {
    final now = DateTime.now();
    if (now.isBefore(p.effectiveFrom)) return false;
    if (p.effectiveTo != null && now.isAfter(p.effectiveTo!)) return false;
    return true;
  }

  @override
  Future<void> deletePolicy(String policyId) async {
    _policies.remove(policyId);
  }

  void clear() {
    _policies.clear();
  }

  int get policyCount => _policies.length;
}

// =============================================================================
// InMemoryAutomationStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of AutomationStoragePort.
class InMemoryAutomationStorage implements AutomationStoragePort {
  final Map<String, Automation> _automations = {};

  @override
  Future<void> saveAutomation(Automation automation) async {
    _automations[automation.jobId] = automation;
  }

  @override
  Future<Automation?> getAutomation(String jobId) async =>
      _automations[jobId];

  @override
  Future<List<Automation>> queryAutomations(AutomationQuery query) async {
    var results = _automations.values.toList();
    if (query.triggerType != null) {
      results =
          results.where((a) => a.trigger == query.triggerType).toList();
    }
    if (query.enabled != null) {
      results = results.where((a) => a.enabled == query.enabled).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Automation>> getEnabledAutomations() async {
    return _automations.values.where((a) => a.enabled).toList();
  }

  @override
  Future<void> deleteAutomation(String jobId) async {
    _automations.remove(jobId);
  }

  void clear() {
    _automations.clear();
  }

  int get automationCount => _automations.length;
}

// =============================================================================
// InMemoryRunStorage (L1) — Phase 2 extension
// =============================================================================

/// In-memory implementation of RunStoragePort.
class InMemoryRunStorage implements RunStoragePort {
  final Map<String, Run> _runs = {};

  @override
  Future<void> saveRun(Run run) async {
    _runs[run.runId] = run;
  }

  @override
  Future<Run?> getRun(String runId) async => _runs[runId];

  @override
  Future<List<Run>> queryRuns(RunQuery query) async {
    var results = _runs.values.toList();
    if (query.workspaceId != null) {
      results =
          results.where((r) => r.workspaceId == query.workspaceId).toList();
    }
    if (query.jobId != null) {
      results = results.where((r) => r.jobId == query.jobId).toList();
    }
    if (query.status != null) {
      results = results.where((r) => r.status == query.status).toList();
    }
    if (query.fromDate != null) {
      results =
          results.where((r) => r.startedAt.isAfter(query.fromDate!)).toList();
    }
    if (query.toDate != null) {
      results =
          results.where((r) => r.startedAt.isBefore(query.toDate!)).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Run>> getRunsForAutomation(String jobId) async =>
      _runs.values.where((r) => r.jobId == jobId).toList();

  @override
  Future<Run?> getRunByIdempotencyKey(String idempotencyKey) async {
    for (final run in _runs.values) {
      if (run.idempotencyKey == idempotencyKey) return run;
    }
    return null;
  }

  @override
  Future<void> deleteRun(String runId) async {
    _runs.remove(runId);
  }

  void clear() {
    _runs.clear();
  }

  int get runCount => _runs.length;
}

// =============================================================================
// InMemoryArtifactStorage — Phase 2 extension
// =============================================================================

/// In-memory implementation of ArtifactStoragePort.
class InMemoryArtifactStorage implements ArtifactStoragePort {
  final Map<String, Artifact> _artifacts = {};

  @override
  Future<void> saveArtifact(Artifact artifact) async {
    _artifacts[artifact.artifactId] = artifact;
  }

  @override
  Future<Artifact?> getArtifact(String artifactId) async =>
      _artifacts[artifactId];

  @override
  Future<List<Artifact>> queryArtifacts(ArtifactQuery query) async {
    var results = _artifacts.values.toList();
    if (query.workspaceId != null) {
      results =
          results.where((a) => a.workspaceId == query.workspaceId).toList();
    }
    if (query.runId != null) {
      results = results
          .where((a) => (a.meta['runId'] as String?) == query.runId)
          .toList();
    }
    if (query.artifactType != null) {
      results =
          results.where((a) => a.type.name == query.artifactType).toList();
    }
    if (query.fromDate != null) {
      results =
          results.where((a) => a.createdAt.isAfter(query.fromDate!)).toList();
    }
    if (query.toDate != null) {
      results =
          results.where((a) => a.createdAt.isBefore(query.toDate!)).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Artifact>> getArtifactsForRun(String runId) async {
    return _artifacts.values
        .where((a) => (a.meta['runId'] as String?) == runId)
        .toList();
  }

  @override
  Future<void> deleteArtifact(String artifactId) async {
    _artifacts.remove(artifactId);
  }

  void clear() {
    _artifacts.clear();
  }

  int get artifactCount => _artifacts.length;
}

// =============================================================================
// InMemoryExtractionRuleStorage — Phase 2 extension
// =============================================================================

/// In-memory implementation of ExtractionRuleStoragePort.
class InMemoryExtractionRuleStorage implements ExtractionRuleStoragePort {
  final Map<String, ExtractionRule> _rules = {};

  @override
  Future<void> saveExtractionRule(ExtractionRule rule) async {
    _rules[rule.ruleId] = rule;
  }

  @override
  Future<ExtractionRule?> getExtractionRule(String ruleId) async =>
      _rules[ruleId];

  @override
  Future<List<ExtractionRule>> queryExtractionRules(
      ExtractionRuleQuery query) async {
    var results = _rules.values.toList();
    if (query.sourceType != null) {
      results =
          results.where((r) => r.sourceType == query.sourceType).toList();
    }
    if (query.targetField != null) {
      results =
          results.where((r) => r.targetField == query.targetField).toList();
    }
    if (query.ruleType != null) {
      results = results.where((r) => r.ruleType == query.ruleType).toList();
    }
    if (query.status != null) {
      results = results.where((r) => r.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<ExtractionRule>> getActiveRulesForSourceType(
      String sourceType) async {
    return _rules.values
        .where((r) =>
            r.sourceType == sourceType && r.status == RuleStatus.active)
        .toList();
  }

  @override
  Future<void> deleteExtractionRule(String ruleId) async {
    _rules.remove(ruleId);
  }

  void clear() {
    _rules.clear();
  }

  int get extractionRuleCount => _rules.length;
}

// =============================================================================
// InMemoryExtractionValidatorStorage — Phase 2 extension
// =============================================================================

/// In-memory implementation of ExtractionValidatorStoragePort.
class InMemoryExtractionValidatorStorage
    implements ExtractionValidatorStoragePort {
  final Map<String, ExtractionValidator> _validators = {};

  @override
  Future<void> saveExtractionValidator(ExtractionValidator validator) async {
    _validators[validator.validatorId] = validator;
  }

  @override
  Future<ExtractionValidator?> getExtractionValidator(
      String validatorId) async =>
      _validators[validatorId];

  @override
  Future<List<ExtractionValidator>> queryExtractionValidators(
      ExtractionValidatorQuery query) async {
    var results = _validators.values.toList();
    if (query.factType != null) {
      results = results.where((v) => v.factType == query.factType).toList();
    }
    if (query.severity != null) {
      results = results.where((v) => v.severity == query.severity).toList();
    }
    if (query.enabled != null) {
      results = results.where((v) => v.enabled == query.enabled).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<ExtractionValidator>> getValidatorsForFactType(
      String factType) async {
    return _validators.values.where((v) => v.factType == factType).toList();
  }

  @override
  Future<void> deleteExtractionValidator(String validatorId) async {
    _validators.remove(validatorId);
  }

  void clear() {
    _validators.clear();
  }

  int get extractionValidatorCount => _validators.length;
}

// =============================================================================
// InMemoryClassifierMemoryStorage — Phase 2 extension
// =============================================================================

/// In-memory implementation of ClassifierMemoryStoragePort.
class InMemoryClassifierMemoryStorage implements ClassifierMemoryStoragePort {
  final Map<String, ClassifierMemory> _memories = {};

  @override
  Future<void> saveClassifierMemory(ClassifierMemory memory) async {
    _memories[memory.memoryId] = memory;
  }

  @override
  Future<ClassifierMemory?> getClassifierMemory(String memoryId) async =>
      _memories[memoryId];

  @override
  Future<List<ClassifierMemory>> queryClassifierMemories(
      ClassifierMemoryQuery query) async {
    var results = _memories.values.toList();
    if (query.taxonomyId != null) {
      results =
          results.where((m) => m.taxonomyId == query.taxonomyId).toList();
    }
    if (query.categoryId != null) {
      results =
          results.where((m) => m.categoryId == query.categoryId).toList();
    }
    if (query.source != null) {
      results = results.where((m) => m.source == query.source).toList();
    }
    if (query.minConfidence != null) {
      results =
          results.where((m) => m.confidence >= query.minConfidence!).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<ClassifierMemory>> findSimilarMemories(
    String taxonomyId,
    Map<String, dynamic> features,
  ) async {
    // In-memory impl: return all memories for the taxonomy.
    // Real adapters should implement similarity scoring.
    return _memories.values
        .where((m) => m.taxonomyId == taxonomyId)
        .toList();
  }

  @override
  Future<void> deleteClassifierMemory(String memoryId) async {
    _memories.remove(memoryId);
  }

  void clear() {
    _memories.clear();
  }

  int get classifierMemoryCount => _memories.length;
}

// =============================================================================
// InMemoryStorageContainer
// =============================================================================

/// Container for all in-memory storage implementations.
///
/// Provides a unified entry point for creating all storage ports
/// for testing and development.
class InMemoryStorageContainer {
  final InMemoryEvidenceStorage evidence = InMemoryEvidenceStorage();
  final InMemoryCandidateStorage candidates = InMemoryCandidateStorage();
  final InMemoryEntityStorage entities = InMemoryEntityStorage();
  final InMemoryFactStorage facts = InMemoryFactStorage();
  final InMemoryViewStorage views = InMemoryViewStorage();
  final InMemoryContextStorage context = InMemoryContextStorage();
  final InMemorySkillOpsStorage skillOps = InMemorySkillOpsStorage();

  // Phase 2 additions — cover the 10 remaining storage ports so the
  // Scenario A host can wire `FactGraphRuntime.inMemory` without
  // reaching for package-private stubs.
  final InMemoryRelationStorage relations = InMemoryRelationStorage();
  final InMemoryFactClusterStorage factClusters =
      InMemoryFactClusterStorage();
  final InMemoryClassificationStorage classifications =
      InMemoryClassificationStorage();
  final InMemoryPolicyStorage policies = InMemoryPolicyStorage();
  final InMemoryAutomationStorage automations = InMemoryAutomationStorage();
  final InMemoryRunStorage runs = InMemoryRunStorage();
  final InMemoryArtifactStorage artifacts = InMemoryArtifactStorage();
  final InMemoryExtractionRuleStorage extractionRules =
      InMemoryExtractionRuleStorage();
  final InMemoryExtractionValidatorStorage extractionValidators =
      InMemoryExtractionValidatorStorage();
  final InMemoryClassifierMemoryStorage classifierMemories =
      InMemoryClassifierMemoryStorage();

  /// Clear all storage.
  void clear() {
    evidence.clear();
    candidates.clear();
    entities.clear();
    facts.clear();
    views.clear();
    context.clear();
    skillOps.clear();
    relations.clear();
    factClusters.clear();
    classifications.clear();
    policies.clear();
    automations.clear();
    runs.clear();
    artifacts.clear();
    extractionRules.clear();
    extractionValidators.clear();
    classifierMemories.clear();
  }

  /// Get storage statistics.
  Map<String, int> get stats => {
        'evidence': evidence.evidenceCount,
        'candidates': candidates.candidateCount,
        'entities': entities.entityCount,
        'facts': facts.factCount,
        'views': views.viewCount,
        'contextBundles': context.contextBundleCount,
        'summaryNodes': context.summaryNodeCount,
        'claims': context.claimCount,
        'patterns': skillOps.patternCount,
        'skills': skillOps.skillCount,
        'rubrics': skillOps.rubricCount,
        'evaluationRuns': skillOps.evaluationRunCount,
        'relations': relations.relationCount,
        'factClusters': factClusters.factClusterCount,
        'classifications': classifications.classificationCount,
        'policies': policies.policyCount,
        'automations': automations.automationCount,
        'runs': runs.runCount,
        'artifacts': artifacts.artifactCount,
        'extractionRules': extractionRules.extractionRuleCount,
        'extractionValidators':
            extractionValidators.extractionValidatorCount,
        'classifierMemories':
            classifierMemories.classifierMemoryCount,
      };
}
