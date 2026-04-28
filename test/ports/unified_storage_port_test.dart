// Tests for unified storage port (CompositeStoragePort).

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal ports — accessed via src path since they are not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:mcp_fact_graph/src/ports/unified_storage_port.dart';

// Minimal mock implementations for required ports
class _MockEvidenceStoragePort implements EvidenceStoragePort {
  @override
  Future<void> saveEvidence(Evidence e) async {}
  @override
  Future<Evidence?> getEvidence(String id) async => null;
  @override
  Future<List<Evidence>> queryEvidence(EvidenceQuery q) async => [];
  @override
  Future<void> deleteEvidence(String id) async {}
  @override
  Future<void> saveFragments(List<Fragment> f) async {}
  @override
  Future<List<Fragment>> getFragments(String id) async => [];
}

class _MockCandidateStoragePort implements CandidateStoragePort {
  @override
  Future<void> saveCandidate(Candidate c) async {}
  @override
  Future<Candidate?> getCandidate(String id) async => null;
  @override
  Future<List<Candidate>> queryCandidates(CandidateQuery q) async => [];
  @override
  Future<void> updateCandidateStatus(String id, CandidateStatus s) async {}
  @override
  Future<void> deleteCandidate(String id) async {}
}

class _MockEntityStoragePort implements EntityStoragePort {
  @override
  Future<void> saveEntity(Entity e) async {}
  @override
  Future<Entity?> getEntity(String id) async => null;
  @override
  Future<List<Entity>> queryEntities(EntityQuery q) async => [];
  @override
  Future<List<Entity>> findByName(String q) async => [];
  @override
  Future<List<Entity>> getRelated(String id) async => [];
  @override
  Future<void> deleteEntity(String id) async {}
}

class _MockRelationStoragePort implements RelationStoragePort {
  @override
  Future<void> saveRelation(Relation r) async {}
  @override
  Future<Relation?> getRelation(String id) async => null;
  @override
  Future<List<Relation>> queryRelations(RelationQuery q) async => [];
  @override
  Future<List<Relation>> getRelationsForEntity(String id) async => [];
  @override
  Future<void> deleteRelation(String id) async {}
}

class _MockFactStoragePort implements FactStoragePort {
  @override
  Future<void> saveFact(Fact f) async {}
  @override
  Future<Fact?> getFact(String id) async => null;
  @override
  Future<List<Fact>> queryFacts(FactQuery q) async => [];
  @override
  Future<List<Fact>> getFactsForEntity(String id) async => [];
  @override
  Future<void> deleteFact(String id) async {}
}

class _MockFactClusterStoragePort implements FactClusterStoragePort {
  @override
  Future<void> saveFactCluster(FactCluster c) async {}
  @override
  Future<FactCluster?> getFactCluster(String id) async => null;
  @override
  Future<List<FactCluster>> queryFactClusters(FactClusterQuery q) async => [];
  @override
  Future<FactCluster?> getClusterForFact(String id) async => null;
  @override
  Future<void> deleteFactCluster(String id) async {}
}

class _MockClassificationStoragePort implements ClassificationStoragePort {
  @override
  Future<void> saveClassification(Classification c) async {}
  @override
  Future<Classification?> getClassification(String id) async => null;
  @override
  Future<List<Classification>> queryClassifications(
      ClassificationQuery q) async => [];
  @override
  Future<List<Classification>> getClassificationsForTarget(
      String t, String id) async => [];
  @override
  Future<void> deleteClassification(String id) async {}
}

class _MockPolicyStoragePort implements PolicyStoragePort {
  @override
  Future<void> savePolicy(FactPolicy p) async {}
  @override
  Future<FactPolicy?> getPolicy(String id) async => null;
  @override
  Future<FactPolicy?> getPolicyVersion(String id, String v) async => null;
  @override
  Future<List<FactPolicy>> queryPolicies(PolicyQuery q) async => [];
  @override
  Future<FactPolicy?> getActivePolicyForScope(String s, PolicyType t) async =>
      null;
  @override
  Future<void> deletePolicy(String id) async {}
}

class _MockViewStoragePort implements ViewStoragePort {
  @override
  Future<void> saveView(View v) async {}
  @override
  Future<View?> getView(String id) async => null;
  @override
  Future<List<View>> queryViews(ViewQuery q) async => [];
  @override
  Future<void> deleteView(String id) async {}
}

class _MockAutomationStoragePort implements AutomationStoragePort {
  @override
  Future<void> saveAutomation(Automation a) async {}
  @override
  Future<Automation?> getAutomation(String id) async => null;
  @override
  Future<List<Automation>> queryAutomations(AutomationQuery q) async => [];
  @override
  Future<List<Automation>> getEnabledAutomations() async => [];
  @override
  Future<void> deleteAutomation(String id) async {}
}

class _MockRunStoragePort implements RunStoragePort {
  @override
  Future<void> saveRun(Run r) async {}
  @override
  Future<Run?> getRun(String id) async => null;
  @override
  Future<List<Run>> queryRuns(RunQuery q) async => [];
  @override
  Future<List<Run>> getRunsForAutomation(String id) async => [];
  @override
  Future<Run?> getRunByIdempotencyKey(String key) async => null;
  @override
  Future<void> deleteRun(String id) async {}
}

class _MockArtifactStoragePort implements ArtifactStoragePort {
  @override
  Future<void> saveArtifact(Artifact a) async {}
  @override
  Future<Artifact?> getArtifact(String id) async => null;
  @override
  Future<List<Artifact>> queryArtifacts(ArtifactQuery q) async => [];
  @override
  Future<List<Artifact>> getArtifactsForRun(String id) async => [];
  @override
  Future<void> deleteArtifact(String id) async {}
}

class _MockExtractionRuleStoragePort implements ExtractionRuleStoragePort {
  @override
  Future<void> saveExtractionRule(ExtractionRule r) async {}
  @override
  Future<ExtractionRule?> getExtractionRule(String id) async => null;
  @override
  Future<List<ExtractionRule>> queryExtractionRules(
      ExtractionRuleQuery q) async => [];
  @override
  Future<List<ExtractionRule>> getActiveRulesForSourceType(String t) async =>
      [];
  @override
  Future<void> deleteExtractionRule(String id) async {}
}

class _MockExtractionValidatorStoragePort
    implements ExtractionValidatorStoragePort {
  @override
  Future<void> saveExtractionValidator(ExtractionValidator v) async {}
  @override
  Future<ExtractionValidator?> getExtractionValidator(String id) async => null;
  @override
  Future<List<ExtractionValidator>> queryExtractionValidators(
      ExtractionValidatorQuery q) async => [];
  @override
  Future<List<ExtractionValidator>> getValidatorsForFactType(
      String t) async => [];
  @override
  Future<void> deleteExtractionValidator(String id) async {}
}

class _MockClassifierMemoryStoragePort implements ClassifierMemoryStoragePort {
  @override
  Future<void> saveClassifierMemory(ClassifierMemory m) async {}
  @override
  Future<ClassifierMemory?> getClassifierMemory(String id) async => null;
  @override
  Future<List<ClassifierMemory>> queryClassifierMemories(
      ClassifierMemoryQuery q) async => [];
  @override
  Future<List<ClassifierMemory>> findSimilarMemories(
      String t, Map<String, dynamic> f) async => [];
  @override
  Future<void> deleteClassifierMemory(String id) async {}
}

class _MockContextStoragePort implements ContextStoragePort {
  @override
  Future<void> saveContextBundle(InternalContextBundle b) async {}
  @override
  Future<InternalContextBundle?> getContextBundle(String id) async => null;
  @override
  Future<List<InternalContextBundle>> queryContextBundles(
      ContextBundleQuery q) async => [];
  @override
  Future<void> saveSummaryNode(SummaryNode n) async {}
  @override
  Future<SummaryNode?> getSummaryNode(String id) async => null;
  @override
  Future<List<SummaryNode>> querySummaryNodes(SummaryNodeQuery q) async => [];
  @override
  Future<void> saveClaim(VerifiableClaim c) async {}
  @override
  Future<VerifiableClaim?> getClaim(String id) async => null;
  @override
  Future<List<VerifiableClaim>> queryClaims(ClaimQuery q) async => [];
  @override
  Future<List<VerifiableClaim>> getPendingClaims() async => [];
}

class _MockSkillOpsStoragePort implements SkillOpsStoragePort {
  @override
  Future<void> savePattern(Pattern p) async {}
  @override
  Future<Pattern?> getPattern(String id) async => null;
  @override
  Future<List<Pattern>> queryPatterns(PatternQuery q) async => [];
  @override
  Future<List<Pattern>> getActivePatterns() async => [];
  @override
  Future<void> saveSkill(Skill s) async {}
  @override
  Future<Skill?> getSkill(String id) async => null;
  @override
  Future<List<Skill>> querySkills(SkillQuery q) async => [];
  @override
  Future<void> saveRubric(Rubric r) async {}
  @override
  Future<Rubric?> getRubric(String id) async => null;
  @override
  Future<List<Rubric>> queryRubrics(RubricQuery q) async => [];
  @override
  Future<void> saveEvaluationRun(EvaluationRun r) async {}
  @override
  Future<EvaluationRun?> getEvaluationRun(String id) async => null;
  @override
  Future<List<EvaluationRun>> queryEvaluationRuns(
      EvaluationRunQuery q) async => [];
  @override
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(String id) async => [];
}

void main() {
  group('CompositeStoragePort', () {
    late CompositeStoragePort port;

    setUp(() {
      port = CompositeStoragePort(
        evidence: _MockEvidenceStoragePort(),
        candidates: _MockCandidateStoragePort(),
        entities: _MockEntityStoragePort(),
        relations: _MockRelationStoragePort(),
        facts: _MockFactStoragePort(),
        factClusters: _MockFactClusterStoragePort(),
        classifications: _MockClassificationStoragePort(),
        policies: _MockPolicyStoragePort(),
        views: _MockViewStoragePort(),
        automations: _MockAutomationStoragePort(),
        runs: _MockRunStoragePort(),
        artifacts: _MockArtifactStoragePort(),
        extractionRules: _MockExtractionRuleStoragePort(),
        extractionValidators: _MockExtractionValidatorStoragePort(),
        classifierMemory: _MockClassifierMemoryStoragePort(),
        context: _MockContextStoragePort(),
        skillOps: _MockSkillOpsStoragePort(),
      );
    });

    group('initialize', () {
      test('completes without callback', () async {
        await port.initialize();
        // Should complete without error
      });

      test('calls callback when provided', () async {
        var called = false;
        final portWithCallback = CompositeStoragePort(
          evidence: _MockEvidenceStoragePort(),
          candidates: _MockCandidateStoragePort(),
          entities: _MockEntityStoragePort(),
          relations: _MockRelationStoragePort(),
          facts: _MockFactStoragePort(),
          factClusters: _MockFactClusterStoragePort(),
          classifications: _MockClassificationStoragePort(),
          policies: _MockPolicyStoragePort(),
          views: _MockViewStoragePort(),
          automations: _MockAutomationStoragePort(),
          runs: _MockRunStoragePort(),
          artifacts: _MockArtifactStoragePort(),
          extractionRules: _MockExtractionRuleStoragePort(),
          extractionValidators: _MockExtractionValidatorStoragePort(),
          classifierMemory: _MockClassifierMemoryStoragePort(),
          context: _MockContextStoragePort(),
          skillOps: _MockSkillOpsStoragePort(),
          onInitialize: () async {
            called = true;
          },
        );

        await portWithCallback.initialize();
        expect(called, isTrue);
      });
    });

    group('isReady', () {
      test('returns true without callback', () async {
        final ready = await port.isReady();
        expect(ready, isTrue);
      });

      test('calls callback when provided', () async {
        final portWithCallback = CompositeStoragePort(
          evidence: _MockEvidenceStoragePort(),
          candidates: _MockCandidateStoragePort(),
          entities: _MockEntityStoragePort(),
          relations: _MockRelationStoragePort(),
          facts: _MockFactStoragePort(),
          factClusters: _MockFactClusterStoragePort(),
          classifications: _MockClassificationStoragePort(),
          policies: _MockPolicyStoragePort(),
          views: _MockViewStoragePort(),
          automations: _MockAutomationStoragePort(),
          runs: _MockRunStoragePort(),
          artifacts: _MockArtifactStoragePort(),
          extractionRules: _MockExtractionRuleStoragePort(),
          extractionValidators: _MockExtractionValidatorStoragePort(),
          classifierMemory: _MockClassifierMemoryStoragePort(),
          context: _MockContextStoragePort(),
          skillOps: _MockSkillOpsStoragePort(),
          onIsReady: () async => false,
        );

        final ready = await portWithCallback.isReady();
        expect(ready, isFalse);
      });
    });

    group('runInTransaction', () {
      test('executes operation without callback', () async {
        final result = await port.runInTransaction(() async => 42);
        expect(result, equals(42));
      });

      test('calls callback when provided', () async {
        var transactionUsed = false;
        final portWithCallback = CompositeStoragePort(
          evidence: _MockEvidenceStoragePort(),
          candidates: _MockCandidateStoragePort(),
          entities: _MockEntityStoragePort(),
          relations: _MockRelationStoragePort(),
          facts: _MockFactStoragePort(),
          factClusters: _MockFactClusterStoragePort(),
          classifications: _MockClassificationStoragePort(),
          policies: _MockPolicyStoragePort(),
          views: _MockViewStoragePort(),
          automations: _MockAutomationStoragePort(),
          runs: _MockRunStoragePort(),
          artifacts: _MockArtifactStoragePort(),
          extractionRules: _MockExtractionRuleStoragePort(),
          extractionValidators: _MockExtractionValidatorStoragePort(),
          classifierMemory: _MockClassifierMemoryStoragePort(),
          context: _MockContextStoragePort(),
          skillOps: _MockSkillOpsStoragePort(),
          onTransaction: <T>(Future<T> Function() op) async {
            transactionUsed = true;
            return await op();
          },
        );

        final result =
            await portWithCallback.runInTransaction(() async => 'hello');
        expect(result, equals('hello'));
        expect(transactionUsed, isTrue);
      });
    });

    group('close', () {
      test('completes without callback', () async {
        await port.close();
        // Should complete without error
      });

      test('calls callback when provided', () async {
        var closed = false;
        final portWithCallback = CompositeStoragePort(
          evidence: _MockEvidenceStoragePort(),
          candidates: _MockCandidateStoragePort(),
          entities: _MockEntityStoragePort(),
          relations: _MockRelationStoragePort(),
          facts: _MockFactStoragePort(),
          factClusters: _MockFactClusterStoragePort(),
          classifications: _MockClassificationStoragePort(),
          policies: _MockPolicyStoragePort(),
          views: _MockViewStoragePort(),
          automations: _MockAutomationStoragePort(),
          runs: _MockRunStoragePort(),
          artifacts: _MockArtifactStoragePort(),
          extractionRules: _MockExtractionRuleStoragePort(),
          extractionValidators: _MockExtractionValidatorStoragePort(),
          classifierMemory: _MockClassifierMemoryStoragePort(),
          context: _MockContextStoragePort(),
          skillOps: _MockSkillOpsStoragePort(),
          onClose: () async {
            closed = true;
          },
        );

        await portWithCallback.close();
        expect(closed, isTrue);
      });
    });

    group('field accessors', () {
      test('exposes all storage ports', () {
        expect(port.evidence, isA<EvidenceStoragePort>());
        expect(port.candidates, isA<CandidateStoragePort>());
        expect(port.entities, isA<EntityStoragePort>());
        expect(port.relations, isA<RelationStoragePort>());
        expect(port.facts, isA<FactStoragePort>());
        expect(port.factClusters, isA<FactClusterStoragePort>());
        expect(port.classifications, isA<ClassificationStoragePort>());
        expect(port.policies, isA<PolicyStoragePort>());
        expect(port.views, isA<ViewStoragePort>());
        expect(port.automations, isA<AutomationStoragePort>());
        expect(port.runs, isA<RunStoragePort>());
        expect(port.artifacts, isA<ArtifactStoragePort>());
        expect(port.extractionRules, isA<ExtractionRuleStoragePort>());
        expect(
            port.extractionValidators, isA<ExtractionValidatorStoragePort>());
        expect(port.classifierMemory, isA<ClassifierMemoryStoragePort>());
        expect(port.context, isA<ContextStoragePort>());
        expect(port.skillOps, isA<SkillOpsStoragePort>());
      });
    });
  });
}
