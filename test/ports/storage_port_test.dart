// Tests for storage port query classes.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal port — accessed via src path since it is not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';

void main() {
  group('EvidenceQuery', () {
    test('creates with default values', () {
      const query = EvidenceQuery();

      expect(query.workspaceId, isNull);
      expect(query.sourceType, isNull);
      expect(query.status, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.limit, isNull);
      expect(query.offset, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = EvidenceQuery(
        workspaceId: 'ws-1',
        sourceType: EvidenceSourceType.text,
        status: EvidenceStatus.pending,
        fromDate: from,
        toDate: to,
        limit: 10,
        offset: 5,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.sourceType, equals(EvidenceSourceType.text));
      expect(query.status, equals(EvidenceStatus.pending));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.limit, equals(10));
      expect(query.offset, equals(5));
    });
  });

  group('CandidateQuery', () {
    test('creates with default values', () {
      const query = CandidateQuery();

      expect(query.workspaceId, isNull);
      expect(query.candidateType, isNull);
      expect(query.status, isNull);
      expect(query.minConfidence, isNull);
      expect(query.needsReview, isNull);
      expect(query.limit, isNull);
      expect(query.offset, isNull);
    });

    test('creates with all parameters', () {
      const query = CandidateQuery(
        workspaceId: 'ws-1',
        candidateType: 'expense',
        status: CandidateStatus.open,
        minConfidence: 0.7,
        needsReview: true,
        limit: 20,
        offset: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.candidateType, equals('expense'));
      expect(query.status, equals(CandidateStatus.open));
      expect(query.minConfidence, equals(0.7));
      expect(query.needsReview, isTrue);
      expect(query.limit, equals(20));
      expect(query.offset, equals(10));
    });
  });

  group('EntityQuery', () {
    test('creates with default values', () {
      const query = EntityQuery();

      expect(query.workspaceId, isNull);
      expect(query.entityType, isNull);
      expect(query.status, isNull);
      expect(query.namePattern, isNull);
      expect(query.minConfidence, isNull);
      expect(query.relationTypes, isNull);
      expect(query.limit, isNull);
      expect(query.offset, isNull);
    });

    test('creates with all parameters', () {
      const query = EntityQuery(
        workspaceId: 'ws-1',
        entityType: 'person',
        status: EntityStatus.active,
        namePattern: 'Alice',
        minConfidence: 0.8,
        relationTypes: ['colleague'],
        limit: 50,
        offset: 0,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.entityType, equals('person'));
      expect(query.status, equals(EntityStatus.active));
      expect(query.namePattern, equals('Alice'));
      expect(query.minConfidence, equals(0.8));
      expect(query.relationTypes, equals(['colleague']));
      expect(query.limit, equals(50));
      expect(query.offset, equals(0));
    });
  });

  group('FactQuery', () {
    test('creates with default values', () {
      const query = FactQuery();

      expect(query.workspaceId, isNull);
      expect(query.factType, isNull);
      expect(query.status, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.entityIds, isNull);
      expect(query.limit, isNull);
      expect(query.offset, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = FactQuery(
        workspaceId: 'ws-1',
        factType: 'expense',
        status: FactStatus.confirmed,
        fromDate: from,
        toDate: to,
        entityIds: const ['ent-1', 'ent-2'],
        limit: 100,
        offset: 0,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.factType, equals('expense'));
      expect(query.status, equals(FactStatus.confirmed));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.entityIds, equals(['ent-1', 'ent-2']));
      expect(query.limit, equals(100));
      expect(query.offset, equals(0));
    });
  });

  group('ViewQuery', () {
    test('creates with default values', () {
      const query = ViewQuery();

      expect(query.workspaceId, isNull);
      expect(query.viewType, isNull);
      expect(query.status, isNull);
      expect(query.scope, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ViewQuery(
        workspaceId: 'ws-1',
        viewType: 'weekly',
        status: ViewStatus.current,
        scope: 'all',
        limit: 5,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.viewType, equals('weekly'));
      expect(query.status, equals(ViewStatus.current));
      expect(query.scope, equals('all'));
      expect(query.limit, equals(5));
    });
  });

  group('ContextBundleQuery', () {
    test('creates with default values', () {
      const query = ContextBundleQuery();

      expect(query.workspaceId, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = ContextBundleQuery(
        workspaceId: 'ws-1',
        fromDate: from,
        toDate: to,
        limit: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.limit, equals(10));
    });
  });

  group('SummaryNodeQuery', () {
    test('creates with default values', () {
      const query = SummaryNodeQuery();

      expect(query.workspaceId, isNull);
      expect(query.status, isNull);
      expect(query.scopeType, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = SummaryNodeQuery(
        workspaceId: 'ws-1',
        status: SummaryStatus.active,
        scopeType: 'period',
        limit: 25,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.status, equals(SummaryStatus.active));
      expect(query.scopeType, equals('period'));
      expect(query.limit, equals(25));
    });
  });

  group('ClaimQuery', () {
    test('creates with default values', () {
      const query = ClaimQuery();

      expect(query.workspaceId, isNull);
      expect(query.claimType, isNull);
      expect(query.verificationStatus, isNull);
      expect(query.minConfidence, isNull);
      expect(query.responseId, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ClaimQuery(
        workspaceId: 'ws-1',
        claimType: ClaimType.fact,
        verificationStatus: ClaimStatus.supported,
        minConfidence: 0.9,
        responseId: 'resp-1',
        limit: 50,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.claimType, equals(ClaimType.fact));
      expect(query.verificationStatus, equals(ClaimStatus.supported));
      expect(query.minConfidence, equals(0.9));
      expect(query.responseId, equals('resp-1'));
      expect(query.limit, equals(50));
    });
  });

  group('PatternQuery', () {
    test('creates with default values', () {
      const query = PatternQuery();

      expect(query.workspaceId, isNull);
      expect(query.status, isNull);
      expect(query.minConfidence, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = PatternQuery(
        workspaceId: 'ws-1',
        status: PatternStatus.confirmed,
        minConfidence: 0.7,
        limit: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.status, equals(PatternStatus.confirmed));
      expect(query.minConfidence, equals(0.7));
      expect(query.limit, equals(10));
    });
  });

  group('SkillQuery', () {
    test('creates with default values', () {
      const query = SkillQuery();

      expect(query.workspaceId, isNull);
      expect(query.status, isNull);
      expect(query.namePattern, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = SkillQuery(
        workspaceId: 'ws-1',
        status: SkillStatus.active,
        namePattern: 'expense',
        limit: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.status, equals(SkillStatus.active));
      expect(query.namePattern, equals('expense'));
      expect(query.limit, equals(10));
    });
  });

  group('RubricQuery', () {
    test('creates with default values', () {
      const query = RubricQuery();

      expect(query.workspaceId, isNull);
      expect(query.status, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = RubricQuery(
        workspaceId: 'ws-1',
        status: RubricStatus.active,
        limit: 5,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.status, equals(RubricStatus.active));
      expect(query.limit, equals(5));
    });
  });

  group('EvaluationRunQuery', () {
    test('creates with default values', () {
      const query = EvaluationRunQuery();

      expect(query.workspaceId, isNull);
      expect(query.rubricId, isNull);
      expect(query.status, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = EvaluationRunQuery(
        workspaceId: 'ws-1',
        rubricId: 'rub-1',
        status: EvaluationStatus.completed,
        fromDate: from,
        toDate: to,
        limit: 100,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.rubricId, equals('rub-1'));
      expect(query.status, equals(EvaluationStatus.completed));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.limit, equals(100));
    });
  });

  group('RelationQuery', () {
    test('creates with default values', () {
      const query = RelationQuery();

      expect(query.workspaceId, isNull);
      expect(query.fromEntityId, isNull);
      expect(query.toEntityId, isNull);
      expect(query.relationType, isNull);
      expect(query.status, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = RelationQuery(
        workspaceId: 'ws-1',
        fromEntityId: 'ent-1',
        toEntityId: 'ent-2',
        relationType: 'colleague',
        status: RelationStatus.confirmed,
        limit: 50,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.fromEntityId, equals('ent-1'));
      expect(query.toEntityId, equals('ent-2'));
      expect(query.relationType, equals('colleague'));
      expect(query.status, equals(RelationStatus.confirmed));
      expect(query.limit, equals(50));
    });
  });

  group('FactClusterQuery', () {
    test('creates with default values', () {
      const query = FactClusterQuery();

      expect(query.workspaceId, isNull);
      expect(query.factType, isNull);
      expect(query.status, isNull);
      expect(query.minConfidence, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = FactClusterQuery(
        workspaceId: 'ws-1',
        factType: 'expense',
        status: FactClusterStatus.active,
        minConfidence: 0.6,
        limit: 20,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.factType, equals('expense'));
      expect(query.status, equals(FactClusterStatus.active));
      expect(query.minConfidence, equals(0.6));
      expect(query.limit, equals(20));
    });
  });

  group('ClassificationQuery', () {
    test('creates with default values', () {
      const query = ClassificationQuery();

      expect(query.workspaceId, isNull);
      expect(query.targetType, isNull);
      expect(query.taxonomyId, isNull);
      expect(query.categoryId, isNull);
      expect(query.status, isNull);
      expect(query.minConfidence, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ClassificationQuery(
        workspaceId: 'ws-1',
        targetType: 'fact',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.confirmed,
        minConfidence: 0.75,
        limit: 30,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.targetType, equals('fact'));
      expect(query.taxonomyId, equals('tax-1'));
      expect(query.categoryId, equals('cat-1'));
      expect(query.status, equals(ClassificationStatus.confirmed));
      expect(query.minConfidence, equals(0.75));
      expect(query.limit, equals(30));
    });
  });

  group('PolicyQuery', () {
    test('creates with default values', () {
      const query = PolicyQuery();

      expect(query.workspaceId, isNull);
      expect(query.policyType, isNull);
      expect(query.scope, isNull);
      expect(query.activeOnly, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = PolicyQuery(
        workspaceId: 'ws-1',
        policyType: PolicyType.classification,
        scope: 'global',
        activeOnly: true,
        limit: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.policyType, equals(PolicyType.classification));
      expect(query.scope, equals('global'));
      expect(query.activeOnly, isTrue);
      expect(query.limit, equals(10));
    });
  });

  group('AutomationQuery', () {
    test('creates with default values', () {
      const query = AutomationQuery();

      expect(query.workspaceId, isNull);
      expect(query.triggerType, isNull);
      expect(query.enabled, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = AutomationQuery(
        workspaceId: 'ws-1',
        triggerType: AutomationTriggerType.schedule,
        enabled: true,
        limit: 10,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.triggerType, equals(AutomationTriggerType.schedule));
      expect(query.enabled, isTrue);
      expect(query.limit, equals(10));
    });
  });

  group('RunQuery', () {
    test('creates with default values', () {
      const query = RunQuery();

      expect(query.workspaceId, isNull);
      expect(query.jobId, isNull);
      expect(query.status, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = RunQuery(
        workspaceId: 'ws-1',
        jobId: 'job-1',
        status: RunStatus.success,
        fromDate: from,
        toDate: to,
        limit: 50,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.jobId, equals('job-1'));
      expect(query.status, equals(RunStatus.success));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.limit, equals(50));
    });
  });

  group('ExtractionRuleQuery', () {
    test('creates with default values', () {
      const query = ExtractionRuleQuery();

      expect(query.workspaceId, isNull);
      expect(query.sourceType, isNull);
      expect(query.targetField, isNull);
      expect(query.ruleType, isNull);
      expect(query.status, isNull);
      expect(query.minAccuracy, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ExtractionRuleQuery(
        workspaceId: 'ws-1',
        sourceType: 'receipt',
        targetField: 'amount',
        ruleType: RuleType.regex,
        status: RuleStatus.active,
        minAccuracy: 0.9,
        limit: 20,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.sourceType, equals('receipt'));
      expect(query.targetField, equals('amount'));
      expect(query.ruleType, equals(RuleType.regex));
      expect(query.status, equals(RuleStatus.active));
      expect(query.minAccuracy, equals(0.9));
      expect(query.limit, equals(20));
    });
  });

  group('ExtractionValidatorQuery', () {
    test('creates with default values', () {
      const query = ExtractionValidatorQuery();

      expect(query.workspaceId, isNull);
      expect(query.factType, isNull);
      expect(query.severity, isNull);
      expect(query.enabled, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ExtractionValidatorQuery(
        workspaceId: 'ws-1',
        factType: 'expense',
        severity: ValidatorSeverity.error,
        enabled: true,
        limit: 15,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.factType, equals('expense'));
      expect(query.severity, equals(ValidatorSeverity.error));
      expect(query.enabled, isTrue);
      expect(query.limit, equals(15));
    });
  });

  group('ClassifierMemoryQuery', () {
    test('creates with default values', () {
      const query = ClassifierMemoryQuery();

      expect(query.workspaceId, isNull);
      expect(query.taxonomyId, isNull);
      expect(query.categoryId, isNull);
      expect(query.source, isNull);
      expect(query.minConfidence, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      const query = ClassifierMemoryQuery(
        workspaceId: 'ws-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        source: MemorySource.user,
        minConfidence: 0.8,
        limit: 40,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.taxonomyId, equals('tax-1'));
      expect(query.categoryId, equals('cat-1'));
      expect(query.source, equals(MemorySource.user));
      expect(query.minConfidence, equals(0.8));
      expect(query.limit, equals(40));
    });
  });

  group('ArtifactQuery', () {
    test('creates with default values', () {
      const query = ArtifactQuery();

      expect(query.workspaceId, isNull);
      expect(query.runId, isNull);
      expect(query.artifactType, isNull);
      expect(query.fromDate, isNull);
      expect(query.toDate, isNull);
      expect(query.limit, isNull);
    });

    test('creates with all parameters', () {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);

      final query = ArtifactQuery(
        workspaceId: 'ws-1',
        runId: 'run-1',
        artifactType: 'report',
        fromDate: from,
        toDate: to,
        limit: 25,
      );

      expect(query.workspaceId, equals('ws-1'));
      expect(query.runId, equals('run-1'));
      expect(query.artifactType, equals('report'));
      expect(query.fromDate, equals(from));
      expect(query.toDate, equals(to));
      expect(query.limit, equals(25));
    });
  });

  group('Query partial construction', () {
    // These tests ensure all constructor parameter lines are exercised
    // by constructing queries with various subsets of parameters.
    test('EvidenceQuery with status only', () {
      const query = EvidenceQuery(status: EvidenceStatus.extracted);
      expect(query.status, equals(EvidenceStatus.extracted));
      expect(query.workspaceId, isNull);
    });

    test('CandidateQuery with minConfidence only', () {
      const query = CandidateQuery(minConfidence: 0.5);
      expect(query.minConfidence, equals(0.5));
      expect(query.candidateType, isNull);
    });

    test('EntityQuery with minConfidence only', () {
      const query = EntityQuery(minConfidence: 0.6);
      expect(query.minConfidence, equals(0.6));
      expect(query.namePattern, isNull);
    });

    test('SummaryNodeQuery with scopeType only', () {
      const query = SummaryNodeQuery(scopeType: 'global');
      expect(query.scopeType, equals('global'));
      expect(query.status, isNull);
    });

    test('ClaimQuery with responseId only', () {
      const query = ClaimQuery(responseId: 'resp-1');
      expect(query.responseId, equals('resp-1'));
      expect(query.claimType, isNull);
    });

    test('PatternQuery with minConfidence only', () {
      const query = PatternQuery(minConfidence: 0.5);
      expect(query.minConfidence, equals(0.5));
      expect(query.status, isNull);
    });

    test('SkillQuery with namePattern only', () {
      const query = SkillQuery(namePattern: 'test');
      expect(query.namePattern, equals('test'));
      expect(query.status, isNull);
    });

    test('RubricQuery with status only', () {
      const query = RubricQuery(status: RubricStatus.draft);
      expect(query.status, equals(RubricStatus.draft));
      expect(query.workspaceId, isNull);
    });

    test('EvaluationRunQuery with toDate only', () {
      final to = DateTime(2024, 12, 31);
      final query = EvaluationRunQuery(toDate: to);
      expect(query.toDate, equals(to));
      expect(query.fromDate, isNull);
    });
  });

  group('Deprecated aliases', () {
    test('EventStoragePort is alias for FactStoragePort', () {
      // Verify the typedef exists and is assignable
      // ignore: deprecated_member_use
      expect(identical(EventStoragePort, FactStoragePort), isTrue);
    });

    test('EventQuery is alias for FactQuery', () {
      // ignore: deprecated_member_use
      expect(identical(EventQuery, FactQuery), isTrue);
    });
  });
}
