import 'package:test/test.dart';
import 'package:mcp_fact_graph/src/domain/entities/evaluation_run.dart';

void main() {
  group('EvaluationStatus', () {
    test('has all expected values', () {
      expect(EvaluationStatus.values, contains(EvaluationStatus.running));
      expect(EvaluationStatus.values, contains(EvaluationStatus.completed));
      expect(EvaluationStatus.values, contains(EvaluationStatus.failed));
    });

    test('fromString returns correct value', () {
      expect(EvaluationStatus.fromString('running'), equals(EvaluationStatus.running));
      expect(EvaluationStatus.fromString('completed'), equals(EvaluationStatus.completed));
      expect(EvaluationStatus.fromString('failed'), equals(EvaluationStatus.failed));
    });

    test('fromString returns running for unknown values', () {
      expect(EvaluationStatus.fromString('unknown'), equals(EvaluationStatus.running));
    });
  });

  group('EvaluationInput', () {
    test('creates input with required fields', () {
      const input = EvaluationInput(targetType: 'skill_run');

      expect(input.targetType, equals('skill_run'));
      expect(input.targetId, isNull);
      expect(input.factIds, isEmpty);
      expect(input.viewIds, isEmpty);
      expect(input.params, isEmpty);
    });

    test('creates input with all fields', () {
      const input = EvaluationInput(
        targetType: 'fact',
        targetId: 'fact-1',
        factIds: ['fact-1', 'fact-2'],
        viewIds: ['view-1'],
        params: {'threshold': 0.8},
      );

      expect(input.targetType, equals('fact'));
      expect(input.targetId, equals('fact-1'));
      expect(input.factIds, equals(['fact-1', 'fact-2']));
      expect(input.viewIds, equals(['view-1']));
      expect(input.params['threshold'], equals(0.8));
    });

    test('serializes and deserializes correctly', () {
      const original = EvaluationInput(
        targetType: 'period',
        targetId: 'target-1',
        factIds: ['f-1'],
      );

      final json = original.toJson();
      final restored = EvaluationInput.fromJson(json);

      expect(restored.targetType, equals(original.targetType));
      expect(restored.targetId, equals(original.targetId));
      expect(restored.factIds, equals(original.factIds));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final input = EvaluationInput.fromJson(json);

      expect(input.targetType, equals(''));
      expect(input.targetId, isNull);
      expect(input.factIds, isEmpty);
      expect(input.viewIds, isEmpty);
      expect(input.params, isEmpty);
    });

    test('toJson excludes null and empty fields', () {
      const input = EvaluationInput(targetType: 'fact');

      final json = input.toJson();

      expect(json.containsKey('targetId'), isFalse);
      expect(json.containsKey('factIds'), isFalse);
      expect(json.containsKey('viewIds'), isFalse);
      expect(json.containsKey('params'), isFalse);
      expect(json['targetType'], equals('fact'));
    });

    test('toJson includes non-empty fields', () {
      const input = EvaluationInput(
        targetType: 'fact',
        targetId: 'target-1',
        factIds: ['f-1'],
        viewIds: ['v-1'],
        params: {'k': 'v'},
      );

      final json = input.toJson();

      expect(json['targetId'], equals('target-1'));
      expect(json['factIds'], equals(['f-1']));
      expect(json['viewIds'], equals(['v-1']));
      expect(json['params'], equals({'k': 'v'}));
    });
  });

  group('EvaluationOutput', () {
    test('creates output with defaults', () {
      const output = EvaluationOutput();

      expect(output.dimensionScores, isEmpty);
      expect(output.totalScore, equals(0.0));
      expect(output.grade, equals(''));
      expect(output.findings, isEmpty);
      expect(output.evidenceRefs, isEmpty);
    });

    test('creates output with all fields', () {
      const output = EvaluationOutput(
        dimensionScores: {'accuracy': 0.9, 'completeness': 0.8},
        totalScore: 0.85,
        grade: 'B',
        findings: [
          Finding(
            findingId: 'f-1',
            findingType: FindingType.strength,
            dimensionId: 'accuracy',
            description: 'Good accuracy',
          ),
        ],
        evidenceRefs: ['ev-1'],
        metrics: {'processed': 10},
      );

      expect(output.dimensionScores['accuracy'], equals(0.9));
      expect(output.totalScore, equals(0.85));
      expect(output.grade, equals('B'));
      expect(output.findings, hasLength(1));
      expect(output.evidenceRefs, equals(['ev-1']));
    });

    test('serializes and deserializes correctly', () {
      const original = EvaluationOutput(
        dimensionScores: {'acc': 0.95},
        totalScore: 0.95,
        grade: 'A',
      );

      final json = original.toJson();
      final restored = EvaluationOutput.fromJson(json);

      expect(restored.dimensionScores['acc'], equals(0.95));
      expect(restored.totalScore, equals(0.95));
      expect(restored.grade, equals('A'));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final output = EvaluationOutput.fromJson(json);

      expect(output.dimensionScores, isEmpty);
      expect(output.totalScore, equals(0.0));
      expect(output.grade, equals(''));
      expect(output.findings, isEmpty);
      expect(output.evidenceRefs, isEmpty);
      expect(output.metrics, isEmpty);
    });

    test('fromJson parses all fields', () {
      final json = {
        'dimensionScores': {'accuracy': 0.9, 'completeness': 0.8},
        'totalScore': 0.85,
        'grade': 'B',
        'findings': [
          {
            'findingId': 'f-1',
            'findingType': 'weakness',
            'dimensionId': 'completeness',
            'description': 'Missing data',
            'supportingRefs': ['ref-1'],
            'impact': -0.2,
          },
        ],
        'evidenceRefs': ['ev-1', 'ev-2'],
        'metrics': {'processed': 10, 'skipped': 2},
      };

      final output = EvaluationOutput.fromJson(json);

      expect(output.dimensionScores['accuracy'], equals(0.9));
      expect(output.dimensionScores['completeness'], equals(0.8));
      expect(output.totalScore, equals(0.85));
      expect(output.grade, equals('B'));
      expect(output.findings, hasLength(1));
      expect(output.findings.first.findingType, equals(FindingType.weakness));
      expect(output.findings.first.supportingRefs, equals(['ref-1']));
      expect(output.findings.first.impact, equals(-0.2));
      expect(output.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(output.metrics, equals({'processed': 10, 'skipped': 2}));
    });

    test('toJson excludes empty fields', () {
      const output = EvaluationOutput();

      final json = output.toJson();

      expect(json.containsKey('dimensionScores'), isFalse);
      expect(json.containsKey('findings'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('metrics'), isFalse);
      expect(json['totalScore'], equals(0.0));
      expect(json['grade'], equals(''));
    });

    test('toJson includes non-empty fields', () {
      const output = EvaluationOutput(
        dimensionScores: {'acc': 0.9},
        totalScore: 0.9,
        grade: 'A',
        findings: [
          Finding(
            findingId: 'f-1',
            findingType: FindingType.strength,
            dimensionId: 'acc',
            description: 'Good',
          ),
        ],
        evidenceRefs: ['ev-1'],
        metrics: {'count': 5},
      );

      final json = output.toJson();

      expect(json['dimensionScores'], equals({'acc': 0.9}));
      expect(json['findings'], isA<List>());
      expect((json['findings'] as List), hasLength(1));
      expect(json['evidenceRefs'], equals(['ev-1']));
      expect(json['metrics'], equals({'count': 5}));
    });
  });

  group('Finding', () {
    test('creates finding with required fields', () {
      const finding = Finding(
        findingId: 'f-1',
        findingType: FindingType.observation,
        dimensionId: 'dim-1',
        description: 'Test observation',
      );

      expect(finding.findingId, equals('f-1'));
      expect(finding.findingType, equals(FindingType.observation));
      expect(finding.dimensionId, equals('dim-1'));
      expect(finding.description, equals('Test observation'));
      expect(finding.supportingRefs, isEmpty);
      expect(finding.impact, isNull);
    });

    test('creates finding with all fields', () {
      const finding = Finding(
        findingId: 'f-2',
        findingType: FindingType.weakness,
        dimensionId: 'completeness',
        description: 'Missing required fields',
        supportingRefs: ['ref-1', 'ref-2'],
        impact: -0.3,
      );

      expect(finding.supportingRefs, hasLength(2));
      expect(finding.impact, equals(-0.3));
    });

    test('serializes and deserializes correctly', () {
      const original = Finding(
        findingId: 'f-3',
        findingType: FindingType.recommendation,
        dimensionId: 'perf',
        description: 'Optimize queries',
      );

      final json = original.toJson();
      final restored = Finding.fromJson(json);

      expect(restored.findingId, equals(original.findingId));
      expect(restored.findingType, equals(original.findingType));
      expect(restored.description, equals(original.description));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final finding = Finding.fromJson(json);

      expect(finding.findingId, equals(''));
      expect(finding.findingType, equals(FindingType.observation));
      expect(finding.dimensionId, equals(''));
      expect(finding.description, equals(''));
      expect(finding.supportingRefs, isEmpty);
      expect(finding.impact, isNull);
    });

    test('toJson excludes empty supportingRefs and null impact', () {
      const finding = Finding(
        findingId: 'f-4',
        findingType: FindingType.observation,
        dimensionId: 'dim-1',
        description: 'Observation',
      );

      final json = finding.toJson();

      expect(json.containsKey('supportingRefs'), isFalse);
      expect(json.containsKey('impact'), isFalse);
    });

    test('toJson includes non-empty supportingRefs and non-null impact', () {
      const finding = Finding(
        findingId: 'f-5',
        findingType: FindingType.weakness,
        dimensionId: 'dim-1',
        description: 'Weak area',
        supportingRefs: ['ref-1', 'ref-2'],
        impact: -0.5,
      );

      final json = finding.toJson();

      expect(json['supportingRefs'], equals(['ref-1', 'ref-2']));
      expect(json['impact'], equals(-0.5));
    });
  });

  group('FindingType', () {
    test('has all expected values', () {
      expect(FindingType.values, contains(FindingType.strength));
      expect(FindingType.values, contains(FindingType.weakness));
      expect(FindingType.values, contains(FindingType.observation));
      expect(FindingType.values, contains(FindingType.recommendation));
    });

    test('fromString returns correct value', () {
      expect(FindingType.fromString('strength'), equals(FindingType.strength));
      expect(FindingType.fromString('weakness'), equals(FindingType.weakness));
      expect(FindingType.fromString('observation'), equals(FindingType.observation));
      expect(FindingType.fromString('recommendation'), equals(FindingType.recommendation));
    });

    test('fromString returns observation for unknown', () {
      expect(FindingType.fromString('unknown'), equals(FindingType.observation));
    });
  });

  group('Period', () {
    test('creates period', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, equals(DateTime(2024, 1, 31)));
      expect(period.duration.inDays, equals(30));
    });

    test('serializes and deserializes correctly', () {
      final original = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 6, 30),
      );

      final json = original.toJson();
      final restored = Period.fromJson(json);

      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final period = Period.fromJson(json);

      // Should default to DateTime.now() - just verify it was created
      expect(period.start, isNotNull);
      expect(period.end, isNotNull);
    });
  });

  group('EvaluationRun', () {
    test('constructor creates instance with required fields', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(run.evaluationId, equals('run-1'));
      expect(run.workspaceId, equals('workspace-1'));
      expect(run.rubricId, equals('rubric-1'));
      expect(run.rubricVersion, equals('1.0.0'));
      expect(run.policyVersion, equals('1.0.0'));
      expect(run.input.targetType, equals(''));
      expect(run.output.totalScore, equals(0.0));
      expect(run.status, equals(EvaluationStatus.running));
      expect(run.completedAt, isNull);
      expect(run.metadata, isEmpty);
    });

    test('constructor creates instance with all fields', () {
      final now = DateTime(2024, 1, 15, 10, 0);
      final completedAt = DateTime(2024, 1, 15, 10, 5);

      final run = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        period: Period(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31)),
        input: const EvaluationInput(
          targetType: 'skill_run',
          targetId: 'skill-1',
          factIds: ['f-1'],
        ),
        output: const EvaluationOutput(
          dimensionScores: {'accuracy': 0.9},
          totalScore: 0.9,
          grade: 'A',
        ),
        idempotencyKey: 'rubric-1_1705312800000',
        status: EvaluationStatus.completed,
        createdAt: now,
        completedAt: completedAt,
        metadata: {'version': '1.0'},
      );

      expect(run.input.targetType, equals('skill_run'));
      expect(run.input.targetId, equals('skill-1'));
      expect(run.output.dimensionScores['accuracy'], equals(0.9));
      expect(run.output.totalScore, equals(0.9));
      expect(run.output.grade, equals('A'));
      expect(run.status, equals(EvaluationStatus.completed));
      expect(run.completedAt, equals(completedAt));
      expect(run.period, isNotNull);
      expect(run.idempotencyKey, equals('rubric-1_1705312800000'));
      expect(run.metadata, equals({'version': '1.0'}));
    });

    test('isComplete returns correct value', () {
      final now = DateTime.now();
      final completed = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        status: EvaluationStatus.completed,
        createdAt: now,
      );

      final pending = EvaluationRun(
        evaluationId: 'run-2',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        status: EvaluationStatus.running,
        createdAt: now,
      );

      expect(completed.isComplete, isTrue);
      expect(pending.isComplete, isFalse);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'evaluationId': 'run-1',
        'workspaceId': 'workspace-1',
        'rubricId': 'rubric-1',
        'rubricVersion': '1.0.0',
        'policyVersion': '1.0.0',
        'asOf': '2024-01-15T10:00:00.000',
        'input': {
          'targetType': 'fact',
          'targetId': 'fact-1',
          'factIds': ['f-1'],
        },
        'output': {
          'dimensionScores': {'acc': 0.85},
          'totalScore': 0.85,
          'grade': 'B',
        },
        'idempotencyKey': 'test-key',
        'status': 'completed',
        'createdAt': '2024-01-15T10:00:00.000',
        'completedAt': '2024-01-15T10:05:00.000',
        'metadata': {'reviewer': 'John'},
      };

      final run = EvaluationRun.fromJson(json);

      expect(run.evaluationId, equals('run-1'));
      expect(run.input.targetType, equals('fact'));
      expect(run.input.targetId, equals('fact-1'));
      expect(run.output.dimensionScores['acc'], equals(0.85));
      expect(run.output.totalScore, equals(0.85));
      expect(run.output.grade, equals('B'));
      expect(run.status, equals(EvaluationStatus.completed));
      expect(run.idempotencyKey, equals('test-key'));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final run = EvaluationRun.fromJson(json);

      expect(run.evaluationId, equals(''));
      expect(run.workspaceId, equals('default'));
      expect(run.input.targetType, equals(''));
      expect(run.output.totalScore, equals(0.0));
      expect(run.status, equals(EvaluationStatus.running));
    });

    test('toJson converts instance to JSON', () {
      final now = DateTime(2024, 1, 15, 10, 0);
      final completedAt = DateTime(2024, 1, 15, 10, 5);

      final run = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        input: const EvaluationInput(
          targetType: 'skill_run',
          targetId: 'target-1',
        ),
        output: const EvaluationOutput(
          dimensionScores: {'acc': 0.9},
          totalScore: 0.9,
          grade: 'A',
        ),
        idempotencyKey: 'test-key',
        status: EvaluationStatus.completed,
        createdAt: now,
        completedAt: completedAt,
        metadata: {'key': 'value'},
      );

      final json = run.toJson();

      expect(json['evaluationId'], equals('run-1'));
      expect(json['rubricId'], equals('rubric-1'));
      expect(json['input'], isA<Map>());
      expect(json['output'], isA<Map>());
      expect(json['status'], equals('completed'));
      expect(json['completedAt'], equals(completedAt.toIso8601String()));
      expect(json['idempotencyKey'], equals('test-key'));
    });

    test('toJson excludes empty and null fields', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final json = run.toJson();

      expect(json.containsKey('completedAt'), isFalse);
      expect(json.containsKey('period'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('copyWith creates copy with updated fields', () {
      final now = DateTime.now();
      final original = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        status: EvaluationStatus.running,
        createdAt: now,
      );

      final copy = original.copyWith(
        status: EvaluationStatus.completed,
        output: const EvaluationOutput(totalScore: 0.95, grade: 'A'),
      );

      expect(copy.evaluationId, equals('run-1'));
      expect(copy.status, equals(EvaluationStatus.completed));
      expect(copy.output.totalScore, equals(0.95));
    });

    test('toString returns expected string representation', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final str = run.toString();

      expect(str, contains('EvaluationRun'));
      expect(str, contains('run-1'));
    });

    test('fromJson with period', () {
      final json = {
        'evaluationId': 'run-period',
        'workspaceId': 'ws-1',
        'rubricId': 'rubric-1',
        'rubricVersion': '2.0.0',
        'policyVersion': '2.0.0',
        'asOf': '2024-01-15T10:00:00.000',
        'period': {
          'start': '2024-01-01T00:00:00.000',
          'end': '2024-01-31T23:59:59.000',
        },
        'status': 'failed',
        'createdAt': '2024-01-15T10:00:00.000',
      };

      final run = EvaluationRun.fromJson(json);

      expect(run.period, isNotNull);
      expect(run.period!.start, equals(DateTime(2024, 1, 1)));
      expect(run.period!.end, equals(DateTime(2024, 1, 31, 23, 59, 59)));
      expect(run.status, equals(EvaluationStatus.failed));
    });

    test('toJson includes period when present', () {
      final now = DateTime(2024, 1, 15, 10, 0);
      final run = EvaluationRun(
        evaluationId: 'run-with-period',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        period: Period(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31)),
        createdAt: now,
      );

      final json = run.toJson();

      expect(json['period'], isA<Map>());
      expect((json['period'] as Map)['start'], isNotNull);
      expect((json['period'] as Map)['end'], isNotNull);
    });

    test('toJson excludes empty idempotencyKey', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-empty-key',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final json = run.toJson();

      expect(json.containsKey('idempotencyKey'), isFalse);
    });

    test('copyWith all parameters', () {
      final now = DateTime(2024, 1, 1);
      final newDate = DateTime(2024, 6, 1);
      final original = EvaluationRun(
        evaluationId: 'run-orig',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final modified = original.copyWith(
        evaluationId: 'run-new',
        workspaceId: 'ws-2',
        rubricId: 'rubric-2',
        rubricVersion: '2.0.0',
        policyVersion: '2.0.0',
        asOf: newDate,
        period: Period(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30)),
        input: const EvaluationInput(targetType: 'period', targetId: 't-1'),
        output: const EvaluationOutput(totalScore: 0.95, grade: 'A'),
        idempotencyKey: 'new-key',
        status: EvaluationStatus.failed,
        createdAt: newDate,
        completedAt: newDate,
        metadata: {'updated': true},
      );

      expect(modified.evaluationId, equals('run-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.rubricId, equals('rubric-2'));
      expect(modified.rubricVersion, equals('2.0.0'));
      expect(modified.policyVersion, equals('2.0.0'));
      expect(modified.asOf, equals(newDate));
      expect(modified.period, isNotNull);
      expect(modified.input.targetType, equals('period'));
      expect(modified.input.targetId, equals('t-1'));
      expect(modified.output.totalScore, equals(0.95));
      expect(modified.output.grade, equals('A'));
      expect(modified.idempotencyKey, equals('new-key'));
      expect(modified.status, equals(EvaluationStatus.failed));
      expect(modified.createdAt, equals(newDate));
      expect(modified.completedAt, equals(newDate));
      expect(modified.metadata, equals({'updated': true}));
    });

    test('equality compares by evaluationId', () {
      final now = DateTime.now();
      final run1 = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final run2 = EvaluationRun(
        evaluationId: 'run-1',
        workspaceId: 'workspace-2',
        rubricId: 'rubric-2',
        rubricVersion: '2.0.0',
        policyVersion: '2.0.0',
        asOf: now,
        createdAt: now,
      );

      final run3 = EvaluationRun(
        evaluationId: 'run-2',
        workspaceId: 'workspace-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(run1 == run2, isTrue);
      expect(run1 == run3, isFalse);
      expect(run1.hashCode, equals(run2.hashCode));
    });

    test('equality with identical reference', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-self',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(run == run, isTrue);
    });

    test('equality with non-EvaluationRun object', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-type',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(run == Object(), isFalse);
    });

    test('hashCode is based on evaluationId', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-hash',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      expect(run.hashCode, equals('run-hash'.hashCode));
    });

    test('toString includes status', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'run-ts',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        status: EvaluationStatus.failed,
        createdAt: now,
      );

      expect(run.toString(), equals('EvaluationRun(run-ts, status: EvaluationStatus.failed)'));
    });

    test('isComplete returns false for failed', () {
      final now = DateTime.now();
      final failed = EvaluationRun(
        evaluationId: 'run-f',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        status: EvaluationStatus.failed,
        createdAt: now,
      );

      expect(failed.isComplete, isFalse);
    });

    test('fromJson with all fields including nested input and output', () {
      final json = {
        'evaluationId': 'run-full',
        'workspaceId': 'ws-full',
        'rubricId': 'rubric-full',
        'rubricVersion': '3.0.0',
        'policyVersion': '3.0.0',
        'asOf': '2024-06-15T10:00:00.000',
        'period': {
          'start': '2024-06-01T00:00:00.000',
          'end': '2024-06-30T00:00:00.000',
        },
        'input': {
          'targetType': 'candidate',
          'targetId': 'cand-1',
          'factIds': ['f-1', 'f-2'],
          'viewIds': ['v-1'],
          'params': {'threshold': 0.5},
        },
        'output': {
          'dimensionScores': {'accuracy': 0.95, 'coverage': 0.8},
          'totalScore': 0.875,
          'grade': 'A',
          'findings': [
            {
              'findingId': 'find-1',
              'findingType': 'strength',
              'dimensionId': 'accuracy',
              'description': 'High accuracy',
              'supportingRefs': ['ref-1'],
              'impact': 0.3,
            },
          ],
          'evidenceRefs': ['ev-1'],
          'metrics': {'count': 5},
        },
        'idempotencyKey': 'full-key',
        'status': 'completed',
        'createdAt': '2024-06-15T10:00:00.000',
        'completedAt': '2024-06-15T10:05:00.000',
        'metadata': {'full': true},
      };

      final run = EvaluationRun.fromJson(json);

      expect(run.evaluationId, equals('run-full'));
      expect(run.workspaceId, equals('ws-full'));
      expect(run.rubricVersion, equals('3.0.0'));
      expect(run.policyVersion, equals('3.0.0'));
      expect(run.period, isNotNull);
      expect(run.input.targetType, equals('candidate'));
      expect(run.input.targetId, equals('cand-1'));
      expect(run.input.factIds, equals(['f-1', 'f-2']));
      expect(run.input.viewIds, equals(['v-1']));
      expect(run.input.params, equals({'threshold': 0.5}));
      expect(run.output.dimensionScores['accuracy'], equals(0.95));
      expect(run.output.totalScore, equals(0.875));
      expect(run.output.grade, equals('A'));
      expect(run.output.findings, hasLength(1));
      expect(run.output.findings.first.impact, equals(0.3));
      expect(run.output.evidenceRefs, equals(['ev-1']));
      expect(run.output.metrics, equals({'count': 5}));
      expect(run.completedAt, isNotNull);
      expect(run.metadata, equals({'full': true}));
    });

    test('toJson with full output including findings', () {
      final now = DateTime(2024, 6, 15, 10, 0);
      final run = EvaluationRun(
        evaluationId: 'run-out',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        period: Period(start: DateTime(2024, 6, 1), end: DateTime(2024, 6, 30)),
        input: const EvaluationInput(
          targetType: 'fact',
          targetId: 'f-1',
          factIds: ['f-1'],
          viewIds: ['v-1'],
          params: {'k': 'v'},
        ),
        output: const EvaluationOutput(
          dimensionScores: {'acc': 0.9},
          totalScore: 0.9,
          grade: 'A',
          findings: [
            Finding(
              findingId: 'find-1',
              findingType: FindingType.strength,
              dimensionId: 'acc',
              description: 'Good',
              supportingRefs: ['ref-1'],
              impact: 0.5,
            ),
          ],
          evidenceRefs: ['ev-1'],
          metrics: {'count': 3},
        ),
        idempotencyKey: 'key-1',
        status: EvaluationStatus.completed,
        createdAt: now,
        completedAt: now,
        metadata: {'test': true},
      );

      final json = run.toJson();

      expect(json['period'], isA<Map>());
      expect(json['input'], isA<Map>());
      final inputJson = json['input'] as Map<String, dynamic>;
      expect(inputJson['targetId'], equals('f-1'));
      expect(inputJson['factIds'], equals(['f-1']));
      expect(inputJson['viewIds'], equals(['v-1']));
      expect(inputJson['params'], equals({'k': 'v'}));
      final outputJson = json['output'] as Map<String, dynamic>;
      expect(outputJson['dimensionScores'], equals({'acc': 0.9}));
      expect(outputJson['findings'], isA<List>());
      expect(outputJson['evidenceRefs'], equals(['ev-1']));
      expect(outputJson['metrics'], equals({'count': 3}));
      expect(json['idempotencyKey'], equals('key-1'));
      expect(json['completedAt'], isNotNull);
      expect(json['metadata'], equals({'test': true}));
    });

    test('fromJson roundtrip preserves data', () {
      final now = DateTime(2024, 6, 15, 10, 0);
      final original = EvaluationRun(
        evaluationId: 'run-rt',
        workspaceId: 'ws-rt',
        rubricId: 'rubric-rt',
        rubricVersion: '2.0.0',
        policyVersion: '2.0.0',
        asOf: now,
        period: Period(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30)),
        input: const EvaluationInput(
          targetType: 'entity',
          targetId: 'ent-1',
        ),
        output: const EvaluationOutput(
          totalScore: 0.8,
          grade: 'B',
        ),
        idempotencyKey: 'rt-key',
        status: EvaluationStatus.failed,
        createdAt: now,
        completedAt: now,
        metadata: {'rt': true},
      );

      final json = original.toJson();
      final restored = EvaluationRun.fromJson(json);

      expect(restored.evaluationId, equals(original.evaluationId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.rubricId, equals(original.rubricId));
      expect(restored.rubricVersion, equals(original.rubricVersion));
      expect(restored.policyVersion, equals(original.policyVersion));
      expect(restored.period, isNotNull);
      expect(restored.input.targetType, equals(original.input.targetType));
      expect(restored.output.totalScore, equals(original.output.totalScore));
      expect(restored.idempotencyKey, equals(original.idempotencyKey));
      expect(restored.status, equals(original.status));
      expect(restored.completedAt, isNotNull);
      expect(restored.metadata, equals(original.metadata));
    });

    test('toJson includes metadata when non-empty', () {
      final now = DateTime(2024, 1, 1);
      final run = EvaluationRun(
        evaluationId: 'run-meta',
        workspaceId: 'ws-1',
        rubricId: 'rubric-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
        metadata: {'key': 'value'},
      );

      final json = run.toJson();
      expect(json['metadata'], equals({'key': 'value'}));
    });
  });

  group('Period additional', () {
    test('duration getter', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 1),
      );
      expect(period.duration, equals(Duration.zero));
    });

    test('toJson roundtrip', () {
      final original = Period(
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );
      final json = original.toJson();
      final restored = Period.fromJson(json);

      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
      expect(restored.duration, equals(original.duration));
    });
  });

  group('EvaluationInput additional', () {
    test('fromJson with all fields', () {
      final json = {
        'targetType': 'skill_run',
        'targetId': 'sk-1',
        'factIds': ['f-1', 'f-2'],
        'viewIds': ['v-1', 'v-2'],
        'params': {'mode': 'strict', 'limit': 10},
      };

      final input = EvaluationInput.fromJson(json);

      expect(input.targetType, equals('skill_run'));
      expect(input.targetId, equals('sk-1'));
      expect(input.factIds, equals(['f-1', 'f-2']));
      expect(input.viewIds, equals(['v-1', 'v-2']));
      expect(input.params, equals({'mode': 'strict', 'limit': 10}));
    });
  });

  group('EvaluationOutput additional', () {
    test('fromJson with metrics', () {
      final json = {
        'dimensionScores': {'d1': 0.9},
        'totalScore': 0.9,
        'grade': 'A',
        'findings': [
          {
            'findingId': 'f-1',
            'findingType': 'recommendation',
            'dimensionId': 'd1',
            'description': 'Recommend improvement',
          },
        ],
        'evidenceRefs': ['ev-1'],
        'metrics': {'processed': 50, 'errors': 0},
      };

      final output = EvaluationOutput.fromJson(json);

      expect(output.dimensionScores, equals({'d1': 0.9}));
      expect(output.findings, hasLength(1));
      expect(output.findings.first.findingType, equals(FindingType.recommendation));
      expect(output.evidenceRefs, equals(['ev-1']));
      expect(output.metrics['processed'], equals(50));
    });
  });

  group('Finding additional', () {
    test('fromJson with all fields', () {
      final json = {
        'findingId': 'f-all',
        'findingType': 'strength',
        'dimensionId': 'dim-1',
        'description': 'Excellent',
        'supportingRefs': ['ref-1', 'ref-2'],
        'impact': 0.8,
      };

      final finding = Finding.fromJson(json);

      expect(finding.findingId, equals('f-all'));
      expect(finding.findingType, equals(FindingType.strength));
      expect(finding.dimensionId, equals('dim-1'));
      expect(finding.description, equals('Excellent'));
      expect(finding.supportingRefs, equals(['ref-1', 'ref-2']));
      expect(finding.impact, equals(0.8));
    });

    test('toJson roundtrip', () {
      const original = Finding(
        findingId: 'f-rt',
        findingType: FindingType.weakness,
        dimensionId: 'dim-1',
        description: 'Needs work',
        supportingRefs: ['ref-1'],
        impact: -0.3,
      );

      final json = original.toJson();
      final restored = Finding.fromJson(json);

      expect(restored.findingId, equals(original.findingId));
      expect(restored.findingType, equals(original.findingType));
      expect(restored.description, equals(original.description));
      expect(restored.supportingRefs, equals(original.supportingRefs));
      expect(restored.impact, equals(original.impact));
    });
  });

  group('EvaluationRun copyWith - output and status', () {
    test('copyWith overrides output field', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'eval-1',
        workspaceId: 'ws-1',
        rubricId: 'rub-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      const newOutput = EvaluationOutput(
        totalScore: 0.95,
        grade: 'A',
      );

      final updated = run.copyWith(output: newOutput);
      expect(updated.output.totalScore, equals(0.95));
      expect(updated.output.grade, equals('A'));
    });

    test('copyWith overrides status field', () {
      final now = DateTime.now();
      final run = EvaluationRun(
        evaluationId: 'eval-1',
        workspaceId: 'ws-1',
        rubricId: 'rub-1',
        rubricVersion: '1.0.0',
        policyVersion: '1.0.0',
        asOf: now,
        createdAt: now,
      );

      final updated = run.copyWith(status: EvaluationStatus.completed);
      expect(updated.status, equals(EvaluationStatus.completed));
    });
  });
}
