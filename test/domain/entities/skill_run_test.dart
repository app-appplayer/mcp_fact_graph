import 'package:test/test.dart';
// Import skill_run.dart directly to access GateAction (hidden in barrel)
import 'package:mcp_fact_graph/src/domain/entities/skill_run.dart';

void main() {
  // =========================================================================
  // SkillRunStatus enum tests
  // =========================================================================
  group('SkillRunStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(
        SkillRunStatus.fromString('running'),
        equals(SkillRunStatus.running),
      );
      expect(
        SkillRunStatus.fromString('completed'),
        equals(SkillRunStatus.completed),
      );
      expect(
        SkillRunStatus.fromString('failed'),
        equals(SkillRunStatus.failed),
      );
      expect(
        SkillRunStatus.fromString('blocked'),
        equals(SkillRunStatus.blocked),
      );
    });

    test('fromString returns running for invalid value', () {
      expect(
        SkillRunStatus.fromString('unknown'),
        equals(SkillRunStatus.running),
      );
      expect(SkillRunStatus.fromString(''), equals(SkillRunStatus.running));
      expect(
        SkillRunStatus.fromString('COMPLETED'),
        equals(SkillRunStatus.running),
      );
    });

    test('has all expected values', () {
      expect(SkillRunStatus.values, hasLength(4));
      expect(SkillRunStatus.values, contains(SkillRunStatus.running));
      expect(SkillRunStatus.values, contains(SkillRunStatus.completed));
      expect(SkillRunStatus.values, contains(SkillRunStatus.failed));
      expect(SkillRunStatus.values, contains(SkillRunStatus.blocked));
    });
  });

  // =========================================================================
  // StepStatus enum tests
  // =========================================================================
  group('StepStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(StepStatus.fromString('pending'), equals(StepStatus.pending));
      expect(StepStatus.fromString('running'), equals(StepStatus.running));
      expect(StepStatus.fromString('completed'), equals(StepStatus.completed));
      expect(StepStatus.fromString('failed'), equals(StepStatus.failed));
      expect(StepStatus.fromString('skipped'), equals(StepStatus.skipped));
    });

    test('fromString returns pending for invalid value', () {
      expect(StepStatus.fromString('unknown'), equals(StepStatus.pending));
      expect(StepStatus.fromString(''), equals(StepStatus.pending));
      expect(StepStatus.fromString('RUNNING'), equals(StepStatus.pending));
    });

    test('has all expected values', () {
      expect(StepStatus.values, hasLength(5));
      expect(StepStatus.values, contains(StepStatus.pending));
      expect(StepStatus.values, contains(StepStatus.running));
      expect(StepStatus.values, contains(StepStatus.completed));
      expect(StepStatus.values, contains(StepStatus.failed));
      expect(StepStatus.values, contains(StepStatus.skipped));
    });
  });

  // =========================================================================
  // GateAction enum tests (from skill_run.dart)
  // =========================================================================
  group('GateAction (skill_run.dart)', () {
    test('fromString returns correct value for all valid values', () {
      expect(GateAction.fromString('block'), equals(GateAction.block));
      expect(GateAction.fromString('warn'), equals(GateAction.warn));
      expect(GateAction.fromString('log'), equals(GateAction.log));
    });

    test('fromString returns warn for invalid value', () {
      // Note: skill_run.dart GateAction defaults to warn, unlike skill.dart
      expect(GateAction.fromString('unknown'), equals(GateAction.warn));
      expect(GateAction.fromString(''), equals(GateAction.warn));
    });

    test('has all expected values', () {
      expect(GateAction.values, hasLength(3));
      expect(GateAction.values, contains(GateAction.block));
      expect(GateAction.values, contains(GateAction.warn));
      expect(GateAction.values, contains(GateAction.log));
    });
  });

  // =========================================================================
  // StepExecution tests
  // =========================================================================
  group('StepExecution', () {
    final fixedStart = DateTime(2024, 6, 15, 10, 0);
    final fixedFinish = DateTime(2024, 6, 15, 10, 2);

    test('constructor with required fields only', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
      );

      expect(step.stepId, equals('step-1'));
      expect(step.stepName, equals('Parse'));
      expect(step.order, equals(1));
      expect(step.startedAt, equals(fixedStart));
      expect(step.finishedAt, isNull);
      expect(step.status, equals(StepStatus.pending));
      expect(step.outputs, isNull);
      expect(step.failureReason, isNull);
      expect(step.tokensUsed, equals(0));
    });

    test('constructor with all fields', () {
      final step = StepExecution(
        stepId: 'step-2',
        stepName: 'Transform',
        order: 2,
        startedAt: fixedStart,
        finishedAt: fixedFinish,
        status: StepStatus.completed,
        outputs: const {'result': 'data'},
        failureReason: null,
        tokensUsed: 150,
      );

      expect(step.stepId, equals('step-2'));
      expect(step.stepName, equals('Transform'));
      expect(step.order, equals(2));
      expect(step.startedAt, equals(fixedStart));
      expect(step.finishedAt, equals(fixedFinish));
      expect(step.status, equals(StepStatus.completed));
      expect(step.outputs, equals({'result': 'data'}));
      expect(step.failureReason, isNull);
      expect(step.tokensUsed, equals(150));
    });

    test('fromJson with complete data', () {
      final json = {
        'stepId': 'step-1',
        'stepName': 'Parse',
        'order': 1,
        'startedAt': '2024-06-15T10:00:00.000',
        'finishedAt': '2024-06-15T10:02:00.000',
        'status': 'completed',
        'outputs': {'key': 'value'},
        'failureReason': 'timeout',
        'tokensUsed': 200,
      };
      final step = StepExecution.fromJson(json);

      expect(step.stepId, equals('step-1'));
      expect(step.stepName, equals('Parse'));
      expect(step.order, equals(1));
      expect(step.startedAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(step.finishedAt, equals(DateTime(2024, 6, 15, 10, 2)));
      expect(step.status, equals(StepStatus.completed));
      expect(step.outputs, equals({'key': 'value'}));
      expect(step.failureReason, equals('timeout'));
      expect(step.tokensUsed, equals(200));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final step = StepExecution.fromJson({});
      final after = DateTime.now();

      expect(step.stepId, equals(''));
      expect(step.stepName, equals(''));
      expect(step.order, equals(0));
      expect(
        step.startedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        step.startedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(step.finishedAt, isNull);
      expect(step.status, equals(StepStatus.pending));
      expect(step.outputs, isNull);
      expect(step.failureReason, isNull);
      expect(step.tokensUsed, equals(0));
    });

    test('fromJson with null fields uses defaults', () {
      final step = StepExecution.fromJson({
        'stepId': null,
        'stepName': null,
        'order': null,
        'startedAt': null,
        'finishedAt': null,
        'status': null,
        'outputs': null,
        'failureReason': null,
        'tokensUsed': null,
      });

      expect(step.stepId, equals(''));
      expect(step.stepName, equals(''));
      expect(step.order, equals(0));
      expect(step.finishedAt, isNull);
      expect(step.status, equals(StepStatus.pending));
      expect(step.outputs, isNull);
      expect(step.failureReason, isNull);
      expect(step.tokensUsed, equals(0));
    });

    test('toJson with all fields populated', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
        finishedAt: fixedFinish,
        status: StepStatus.completed,
        outputs: const {'data': 'result'},
        failureReason: 'reason',
        tokensUsed: 100,
      );
      final json = step.toJson();

      expect(json['stepId'], equals('step-1'));
      expect(json['stepName'], equals('Parse'));
      expect(json['order'], equals(1));
      expect(json['startedAt'], equals(fixedStart.toIso8601String()));
      expect(json['finishedAt'], equals(fixedFinish.toIso8601String()));
      expect(json['status'], equals('completed'));
      expect(json['outputs'], equals({'data': 'result'}));
      expect(json['failureReason'], equals('reason'));
      expect(json['tokensUsed'], equals(100));
    });

    test('toJson excludes null/zero fields', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
      );
      final json = step.toJson();

      expect(json.containsKey('finishedAt'), isFalse);
      expect(json.containsKey('outputs'), isFalse);
      expect(json.containsKey('failureReason'), isFalse);
      expect(json.containsKey('tokensUsed'), isFalse);
      // Required fields always present
      expect(json.containsKey('stepId'), isTrue);
      expect(json.containsKey('stepName'), isTrue);
      expect(json.containsKey('order'), isTrue);
      expect(json.containsKey('startedAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.running,
      );
      final copy = original.copyWith(
        status: StepStatus.completed,
        finishedAt: fixedFinish,
        outputs: {'result': 'done'},
        tokensUsed: 50,
      );

      expect(copy.status, equals(StepStatus.completed));
      expect(copy.finishedAt, equals(fixedFinish));
      expect(copy.outputs, equals({'result': 'done'}));
      expect(copy.tokensUsed, equals(50));
      // Unchanged
      expect(copy.stepId, equals('step-1'));
      expect(copy.stepName, equals('Parse'));
      expect(copy.order, equals(1));
      expect(copy.startedAt, equals(fixedStart));
      expect(copy.failureReason, isNull);
    });

    test('copyWith with no arguments returns equivalent step', () {
      final original = StepExecution(
        stepId: 'step-1',
        stepName: 'Test',
        order: 1,
        startedAt: fixedStart,
      );
      final copy = original.copyWith();

      expect(copy.stepId, equals(original.stepId));
      expect(copy.stepName, equals(original.stepName));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = StepExecution(
        stepId: 'step-1',
        stepName: 'Old',
        order: 1,
        startedAt: fixedStart,
      );
      final newTime = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        stepId: 'new-step',
        stepName: 'New',
        order: 99,
        startedAt: newTime,
        finishedAt: newTime,
        status: StepStatus.failed,
        outputs: {'x': 1},
        failureReason: 'err',
        tokensUsed: 999,
      );

      expect(copy.stepId, equals('new-step'));
      expect(copy.stepName, equals('New'));
      expect(copy.order, equals(99));
      expect(copy.startedAt, equals(newTime));
      expect(copy.finishedAt, equals(newTime));
      expect(copy.status, equals(StepStatus.failed));
      expect(copy.outputs, equals({'x': 1}));
      expect(copy.failureReason, equals('err'));
      expect(copy.tokensUsed, equals(999));
    });

    test('duration getter returns duration when finished', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
        finishedAt: fixedFinish,
      );

      expect(step.duration, isNotNull);
      expect(step.duration!.inMinutes, equals(2));
    });

    test('duration getter returns null when not finished', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
      );

      expect(step.duration, isNull);
    });

    test('isComplete getter', () {
      final completed = StepExecution(
        stepId: 's-1',
        stepName: 'Done',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.completed,
      );
      final running = StepExecution(
        stepId: 's-2',
        stepName: 'Running',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.running,
      );

      expect(completed.isComplete, isTrue);
      expect(running.isComplete, isFalse);
    });

    test('isFailed getter', () {
      final failed = StepExecution(
        stepId: 's-1',
        stepName: 'Failed',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.failed,
      );
      final completed = StepExecution(
        stepId: 's-2',
        stepName: 'Done',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.completed,
      );

      expect(failed.isFailed, isTrue);
      expect(completed.isFailed, isFalse);
    });

    test('toString returns expected format', () {
      final step = StepExecution(
        stepId: 'step-1',
        stepName: 'Parse',
        order: 1,
        startedAt: fixedStart,
        status: StepStatus.running,
      );
      final str = step.toString();

      expect(str, contains('StepExecution'));
      expect(str, contains('step-1'));
      expect(str, contains('running'));
    });

    test('equality compares by stepId', () {
      final step1 = StepExecution(
        stepId: 'step-1',
        stepName: 'A',
        order: 1,
        startedAt: fixedStart,
      );
      final step2 = StepExecution(
        stepId: 'step-1',
        stepName: 'B',
        order: 2,
        startedAt: fixedFinish,
      );
      final step3 = StepExecution(
        stepId: 'step-999',
        stepName: 'A',
        order: 1,
        startedAt: fixedStart,
      );

      expect(step1 == step2, isTrue);
      expect(step1 == step3, isFalse);
      expect(step1.hashCode, equals(step2.hashCode));
    });
  });

  // =========================================================================
  // GateCheck tests
  // =========================================================================
  group('GateCheck', () {
    final fixedTime = DateTime(2024, 6, 15, 10, 0);

    test('constructor with required fields only', () {
      final gate = GateCheck(
        gateId: 'gate-1',
        gateName: 'Accuracy',
        condition: 'accuracy >= 0.9',
        checkedAt: fixedTime,
        passed: true,
      );

      expect(gate.gateId, equals('gate-1'));
      expect(gate.gateName, equals('Accuracy'));
      expect(gate.condition, equals('accuracy >= 0.9'));
      expect(gate.checkedAt, equals(fixedTime));
      expect(gate.passed, isTrue);
      expect(gate.failureReason, isNull);
      expect(gate.actionTaken, equals(GateAction.warn));
      expect(gate.evaluatedValue, isNull);
    });

    test('constructor with all fields', () {
      final gate = GateCheck(
        gateId: 'gate-2',
        gateName: 'Format',
        condition: 'format == "json"',
        checkedAt: fixedTime,
        passed: false,
        failureReason: 'Invalid format: xml',
        actionTaken: GateAction.block,
        evaluatedValue: 'xml',
      );

      expect(gate.gateId, equals('gate-2'));
      expect(gate.gateName, equals('Format'));
      expect(gate.condition, equals('format == "json"'));
      expect(gate.checkedAt, equals(fixedTime));
      expect(gate.passed, isFalse);
      expect(gate.failureReason, equals('Invalid format: xml'));
      expect(gate.actionTaken, equals(GateAction.block));
      expect(gate.evaluatedValue, equals('xml'));
    });

    test('fromJson with complete data', () {
      final json = {
        'gateId': 'gate-1',
        'gateName': 'Accuracy',
        'condition': 'score > 0.8',
        'checkedAt': '2024-06-15T10:00:00.000',
        'passed': false,
        'failureReason': 'Score too low',
        'actionTaken': 'block',
        'evaluatedValue': 0.5,
      };
      final gate = GateCheck.fromJson(json);

      expect(gate.gateId, equals('gate-1'));
      expect(gate.gateName, equals('Accuracy'));
      expect(gate.condition, equals('score > 0.8'));
      expect(gate.checkedAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(gate.passed, isFalse);
      expect(gate.failureReason, equals('Score too low'));
      expect(gate.actionTaken, equals(GateAction.block));
      expect(gate.evaluatedValue, equals(0.5));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final gate = GateCheck.fromJson({});
      final after = DateTime.now();

      expect(gate.gateId, equals(''));
      expect(gate.gateName, equals(''));
      expect(gate.condition, equals(''));
      expect(
        gate.checkedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        gate.checkedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(gate.passed, isFalse);
      expect(gate.failureReason, isNull);
      expect(gate.actionTaken, equals(GateAction.warn));
      expect(gate.evaluatedValue, isNull);
    });

    test('fromJson with null fields uses defaults', () {
      final gate = GateCheck.fromJson({
        'gateId': null,
        'gateName': null,
        'condition': null,
        'checkedAt': null,
        'passed': null,
        'failureReason': null,
        'actionTaken': null,
        'evaluatedValue': null,
      });

      expect(gate.gateId, equals(''));
      expect(gate.gateName, equals(''));
      expect(gate.condition, equals(''));
      expect(gate.passed, isFalse);
      expect(gate.failureReason, isNull);
      expect(gate.actionTaken, equals(GateAction.warn));
      expect(gate.evaluatedValue, isNull);
    });

    test('toJson with all fields populated', () {
      final gate = GateCheck(
        gateId: 'gate-1',
        gateName: 'Check',
        condition: 'x > 0',
        checkedAt: fixedTime,
        passed: true,
        failureReason: 'reason',
        actionTaken: GateAction.log,
        evaluatedValue: 42,
      );
      final json = gate.toJson();

      expect(json['gateId'], equals('gate-1'));
      expect(json['gateName'], equals('Check'));
      expect(json['condition'], equals('x > 0'));
      expect(json['checkedAt'], equals(fixedTime.toIso8601String()));
      expect(json['passed'], isTrue);
      expect(json['failureReason'], equals('reason'));
      expect(json['actionTaken'], equals('log'));
      expect(json['evaluatedValue'], equals(42));
    });

    test('toJson excludes null fields', () {
      final gate = GateCheck(
        gateId: 'gate-1',
        gateName: 'Check',
        condition: 'x > 0',
        checkedAt: fixedTime,
        passed: true,
      );
      final json = gate.toJson();

      expect(json.containsKey('failureReason'), isFalse);
      expect(json.containsKey('evaluatedValue'), isFalse);
      // Required fields always present
      expect(json.containsKey('gateId'), isTrue);
      expect(json.containsKey('gateName'), isTrue);
      expect(json.containsKey('condition'), isTrue);
      expect(json.containsKey('checkedAt'), isTrue);
      expect(json.containsKey('passed'), isTrue);
      expect(json.containsKey('actionTaken'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = GateCheck(
        gateId: 'gate-1',
        gateName: 'Original',
        condition: 'x > 0',
        checkedAt: fixedTime,
        passed: true,
      );
      final copy = original.copyWith(
        passed: false,
        failureReason: 'Failed check',
        actionTaken: GateAction.block,
      );

      expect(copy.passed, isFalse);
      expect(copy.failureReason, equals('Failed check'));
      expect(copy.actionTaken, equals(GateAction.block));
      // Unchanged
      expect(copy.gateId, equals('gate-1'));
      expect(copy.gateName, equals('Original'));
      expect(copy.condition, equals('x > 0'));
      expect(copy.checkedAt, equals(fixedTime));
      expect(copy.evaluatedValue, isNull);
    });

    test('copyWith with no arguments returns equivalent gate check', () {
      final original = GateCheck(
        gateId: 'gate-1',
        gateName: 'Test',
        condition: 'x',
        checkedAt: fixedTime,
        passed: true,
      );
      final copy = original.copyWith();

      expect(copy.gateId, equals(original.gateId));
      expect(copy.passed, equals(original.passed));
    });

    test('copyWith all fields', () {
      final original = GateCheck(
        gateId: 'gate-1',
        gateName: 'Old',
        condition: 'old',
        checkedAt: fixedTime,
        passed: true,
      );
      final newTime = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        gateId: 'new-gate',
        gateName: 'New',
        condition: 'new',
        checkedAt: newTime,
        passed: false,
        failureReason: 'err',
        actionTaken: GateAction.log,
        evaluatedValue: 'val',
      );

      expect(copy.gateId, equals('new-gate'));
      expect(copy.gateName, equals('New'));
      expect(copy.condition, equals('new'));
      expect(copy.checkedAt, equals(newTime));
      expect(copy.passed, isFalse);
      expect(copy.failureReason, equals('err'));
      expect(copy.actionTaken, equals(GateAction.log));
      expect(copy.evaluatedValue, equals('val'));
    });

    test('toString returns expected format', () {
      final gate = GateCheck(
        gateId: 'gate-1',
        gateName: 'Accuracy',
        condition: 'score > 0.8',
        checkedAt: fixedTime,
        passed: true,
        actionTaken: GateAction.warn,
      );
      final str = gate.toString();

      expect(str, contains('GateCheck'));
      expect(str, contains('gate-1'));
      expect(str, contains('true'));
      expect(str, contains('warn'));
    });

    test('equality compares by gateId', () {
      final gate1 = GateCheck(
        gateId: 'gate-1',
        gateName: 'A',
        condition: 'x',
        checkedAt: fixedTime,
        passed: true,
      );
      final gate2 = GateCheck(
        gateId: 'gate-1',
        gateName: 'B',
        condition: 'y',
        checkedAt: fixedTime,
        passed: false,
      );
      final gate3 = GateCheck(
        gateId: 'gate-999',
        gateName: 'A',
        condition: 'x',
        checkedAt: fixedTime,
        passed: true,
      );

      expect(gate1 == gate2, isTrue);
      expect(gate1 == gate3, isFalse);
      expect(gate1.hashCode, equals(gate2.hashCode));
    });
  });

  // =========================================================================
  // SkillRun tests
  // =========================================================================
  group('SkillRun', () {
    final fixedStart = DateTime(2024, 6, 15, 10, 0);
    final fixedFinish = DateTime(2024, 6, 15, 10, 5);
    final fixedCreated = DateTime(2024, 6, 15, 9, 55);

    SkillRun createFullSkillRun() {
      return SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '2.0.0',
        contextId: 'ctx-1',
        traceId: 'trace-1',
        startedAt: fixedStart,
        finishedAt: fixedFinish,
        status: SkillRunStatus.completed,
        stepExecutions: [
          StepExecution(
            stepId: 'step-1',
            stepName: 'Parse',
            order: 1,
            startedAt: fixedStart,
            finishedAt: fixedFinish,
            status: StepStatus.completed,
            tokensUsed: 100,
          ),
          StepExecution(
            stepId: 'step-2',
            stepName: 'Failed Step',
            order: 2,
            startedAt: fixedStart,
            status: StepStatus.failed,
            failureReason: 'Error occurred',
          ),
        ],
        gateChecks: [
          GateCheck(
            gateId: 'gate-1',
            gateName: 'Quality',
            condition: 'score > 0.8',
            checkedAt: fixedFinish,
            passed: true,
          ),
          GateCheck(
            gateId: 'gate-2',
            gateName: 'Format',
            condition: 'format ok',
            checkedAt: fixedFinish,
            passed: false,
            actionTaken: GateAction.block,
            failureReason: 'Invalid format',
          ),
          GateCheck(
            gateId: 'gate-3',
            gateName: 'Style',
            condition: 'style ok',
            checkedAt: fixedFinish,
            passed: false,
            actionTaken: GateAction.warn,
          ),
        ],
        inputs: const {'source': 'doc.pdf'},
        outputs: const {'result': 'extracted'},
        blockReason: null,
        artifactIds: const ['art-1', 'art-2'],
        totalTokensUsed: 500,
        llmCallsMade: 3,
        mcpCallsMade: 2,
        createdAt: fixedCreated,
        metadata: const {'version': '1.0'},
      );
    }

    test('constructor with required fields only', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );

      expect(run.runId, equals('sr-1'));
      expect(run.workspaceId, equals('ws-1'));
      expect(run.skillId, equals('skill-1'));
      expect(run.skillVersion, equals('1.0.0'));
      expect(run.contextId, isNull);
      expect(run.traceId, isNull);
      expect(run.startedAt, equals(fixedStart));
      expect(run.finishedAt, isNull);
      expect(run.status, equals(SkillRunStatus.running));
      expect(run.stepExecutions, isEmpty);
      expect(run.gateChecks, isEmpty);
      expect(run.inputs, isEmpty);
      expect(run.outputs, isNull);
      expect(run.blockReason, isNull);
      expect(run.artifactIds, isEmpty);
      expect(run.totalTokensUsed, equals(0));
      expect(run.llmCallsMade, equals(0));
      expect(run.mcpCallsMade, equals(0));
      expect(run.createdAt, equals(fixedCreated));
      expect(run.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final run = createFullSkillRun();

      expect(run.runId, equals('sr-1'));
      expect(run.workspaceId, equals('ws-1'));
      expect(run.skillId, equals('skill-1'));
      expect(run.skillVersion, equals('2.0.0'));
      expect(run.contextId, equals('ctx-1'));
      expect(run.traceId, equals('trace-1'));
      expect(run.startedAt, equals(fixedStart));
      expect(run.finishedAt, equals(fixedFinish));
      expect(run.status, equals(SkillRunStatus.completed));
      expect(run.stepExecutions, hasLength(2));
      expect(run.gateChecks, hasLength(3));
      expect(run.inputs, equals({'source': 'doc.pdf'}));
      expect(run.outputs, equals({'result': 'extracted'}));
      expect(run.blockReason, isNull);
      expect(run.artifactIds, equals(['art-1', 'art-2']));
      expect(run.totalTokensUsed, equals(500));
      expect(run.llmCallsMade, equals(3));
      expect(run.mcpCallsMade, equals(2));
      expect(run.createdAt, equals(fixedCreated));
      expect(run.metadata, equals({'version': '1.0'}));
    });

    test('fromJson with complete data', () {
      final json = {
        'runId': 'sr-1',
        'workspaceId': 'ws-1',
        'skillId': 'skill-1',
        'skillVersion': '2.0.0',
        'contextId': 'ctx-1',
        'traceId': 'trace-1',
        'startedAt': '2024-06-15T10:00:00.000',
        'finishedAt': '2024-06-15T10:05:00.000',
        'status': 'completed',
        'stepExecutions': [
          {
            'stepId': 'step-1',
            'stepName': 'Parse',
            'order': 1,
            'startedAt': '2024-06-15T10:00:00.000',
            'status': 'completed',
          },
        ],
        'gateChecks': [
          {
            'gateId': 'gate-1',
            'gateName': 'Quality',
            'condition': 'score > 0.8',
            'checkedAt': '2024-06-15T10:05:00.000',
            'passed': true,
          },
        ],
        'inputs': {'source': 'file.pdf'},
        'outputs': {'result': 'data'},
        'blockReason': 'blocked by gate',
        'artifactIds': ['art-1'],
        'totalTokensUsed': 300,
        'llmCallsMade': 2,
        'mcpCallsMade': 1,
        'createdAt': '2024-06-15T09:55:00.000',
        'metadata': {'tag': 'test'},
      };
      final run = SkillRun.fromJson(json);

      expect(run.runId, equals('sr-1'));
      expect(run.workspaceId, equals('ws-1'));
      expect(run.skillId, equals('skill-1'));
      expect(run.skillVersion, equals('2.0.0'));
      expect(run.contextId, equals('ctx-1'));
      expect(run.traceId, equals('trace-1'));
      expect(run.startedAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(run.finishedAt, equals(DateTime(2024, 6, 15, 10, 5)));
      expect(run.status, equals(SkillRunStatus.completed));
      expect(run.stepExecutions, hasLength(1));
      expect(run.stepExecutions[0].stepId, equals('step-1'));
      expect(run.gateChecks, hasLength(1));
      expect(run.gateChecks[0].passed, isTrue);
      expect(run.inputs, equals({'source': 'file.pdf'}));
      expect(run.outputs, equals({'result': 'data'}));
      expect(run.blockReason, equals('blocked by gate'));
      expect(run.artifactIds, equals(['art-1']));
      expect(run.totalTokensUsed, equals(300));
      expect(run.llmCallsMade, equals(2));
      expect(run.mcpCallsMade, equals(1));
      expect(run.createdAt, equals(DateTime(2024, 6, 15, 9, 55)));
      expect(run.metadata, equals({'tag': 'test'}));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final run = SkillRun.fromJson({});
      final after = DateTime.now();

      expect(run.runId, equals(''));
      expect(run.workspaceId, equals('default'));
      expect(run.skillId, equals(''));
      expect(run.skillVersion, equals('1.0.0'));
      expect(run.contextId, isNull);
      expect(run.traceId, isNull);
      expect(
        run.startedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(run.finishedAt, isNull);
      expect(run.status, equals(SkillRunStatus.running));
      expect(run.stepExecutions, isEmpty);
      expect(run.gateChecks, isEmpty);
      expect(run.inputs, isEmpty);
      expect(run.outputs, isNull);
      expect(run.blockReason, isNull);
      expect(run.artifactIds, isEmpty);
      expect(run.totalTokensUsed, equals(0));
      expect(run.llmCallsMade, equals(0));
      expect(run.mcpCallsMade, equals(0));
      expect(
        run.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(run.metadata, isEmpty);
    });

    test('fromJson with null optional fields', () {
      final json = {
        'runId': 'sr-1',
        'startedAt': '2024-01-01T00:00:00.000',
        'createdAt': '2024-01-01T00:00:00.000',
        'contextId': null,
        'traceId': null,
        'finishedAt': null,
        'stepExecutions': null,
        'gateChecks': null,
        'inputs': null,
        'outputs': null,
        'blockReason': null,
        'artifactIds': null,
        'metadata': null,
        'totalTokensUsed': null,
        'llmCallsMade': null,
        'mcpCallsMade': null,
      };
      final run = SkillRun.fromJson(json);

      expect(run.contextId, isNull);
      expect(run.traceId, isNull);
      expect(run.finishedAt, isNull);
      expect(run.stepExecutions, isEmpty);
      expect(run.gateChecks, isEmpty);
      expect(run.inputs, isEmpty);
      expect(run.outputs, isNull);
      expect(run.blockReason, isNull);
      expect(run.artifactIds, isEmpty);
      expect(run.metadata, isEmpty);
      expect(run.totalTokensUsed, equals(0));
      expect(run.llmCallsMade, equals(0));
      expect(run.mcpCallsMade, equals(0));
    });

    test('toJson with fully populated skill run', () {
      final run = createFullSkillRun();
      final json = run.toJson();

      expect(json['runId'], equals('sr-1'));
      expect(json['workspaceId'], equals('ws-1'));
      expect(json['skillId'], equals('skill-1'));
      expect(json['skillVersion'], equals('2.0.0'));
      expect(json['contextId'], equals('ctx-1'));
      expect(json['traceId'], equals('trace-1'));
      expect(json['startedAt'], equals(fixedStart.toIso8601String()));
      expect(json['finishedAt'], equals(fixedFinish.toIso8601String()));
      expect(json['status'], equals('completed'));
      expect(json['stepExecutions'], isA<List>());
      expect((json['stepExecutions'] as List), hasLength(2));
      expect(json['gateChecks'], isA<List>());
      expect((json['gateChecks'] as List), hasLength(3));
      expect(json['inputs'], equals({'source': 'doc.pdf'}));
      expect(json['outputs'], equals({'result': 'extracted'}));
      expect(json['artifactIds'], equals(['art-1', 'art-2']));
      expect(json['totalTokensUsed'], equals(500));
      expect(json['llmCallsMade'], equals(3));
      expect(json['mcpCallsMade'], equals(2));
      expect(json['createdAt'], equals(fixedCreated.toIso8601String()));
      expect(json['metadata'], equals({'version': '1.0'}));
    });

    test('toJson excludes empty/null/zero fields', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );
      final json = run.toJson();

      expect(json.containsKey('contextId'), isFalse);
      expect(json.containsKey('traceId'), isFalse);
      expect(json.containsKey('finishedAt'), isFalse);
      expect(json.containsKey('stepExecutions'), isFalse);
      expect(json.containsKey('gateChecks'), isFalse);
      expect(json.containsKey('inputs'), isFalse);
      expect(json.containsKey('outputs'), isFalse);
      expect(json.containsKey('blockReason'), isFalse);
      expect(json.containsKey('artifactIds'), isFalse);
      expect(json.containsKey('totalTokensUsed'), isFalse);
      expect(json.containsKey('llmCallsMade'), isFalse);
      expect(json.containsKey('mcpCallsMade'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Required fields always present
      expect(json.containsKey('runId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('skillId'), isTrue);
      expect(json.containsKey('skillVersion'), isTrue);
      expect(json.containsKey('startedAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = createFullSkillRun();
      final copy = original.copyWith(
        runId: 'sr-2',
        status: SkillRunStatus.failed,
        blockReason: 'Gate blocked',
        totalTokensUsed: 999,
      );

      expect(copy.runId, equals('sr-2'));
      expect(copy.status, equals(SkillRunStatus.failed));
      expect(copy.blockReason, equals('Gate blocked'));
      expect(copy.totalTokensUsed, equals(999));
      // Unchanged
      expect(copy.workspaceId, equals('ws-1'));
      expect(copy.skillId, equals('skill-1'));
      expect(copy.skillVersion, equals('2.0.0'));
      expect(copy.contextId, equals('ctx-1'));
      expect(copy.traceId, equals('trace-1'));
      expect(copy.startedAt, equals(fixedStart));
      expect(copy.finishedAt, equals(fixedFinish));
      expect(copy.stepExecutions, hasLength(2));
      expect(copy.gateChecks, hasLength(3));
      expect(copy.inputs, equals({'source': 'doc.pdf'}));
      expect(copy.outputs, equals({'result': 'extracted'}));
      expect(copy.artifactIds, equals(['art-1', 'art-2']));
      expect(copy.llmCallsMade, equals(3));
      expect(copy.mcpCallsMade, equals(2));
      expect(copy.metadata, equals({'version': '1.0'}));
    });

    test('copyWith with no arguments returns equivalent skill run', () {
      final original = createFullSkillRun();
      final copy = original.copyWith();

      expect(copy.runId, equals(original.runId));
      expect(copy.skillId, equals(original.skillId));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = createFullSkillRun();
      final newTime = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        runId: 'new-run',
        workspaceId: 'new-ws',
        skillId: 'new-skill',
        skillVersion: '9.0.0',
        contextId: 'new-ctx',
        traceId: 'new-trace',
        startedAt: newTime,
        finishedAt: newTime,
        status: SkillRunStatus.blocked,
        stepExecutions: const [],
        gateChecks: const [],
        inputs: const {'new': true},
        outputs: const {'new': 'out'},
        blockReason: 'new reason',
        artifactIds: const ['new-art'],
        totalTokensUsed: 1,
        llmCallsMade: 2,
        mcpCallsMade: 3,
        createdAt: newTime,
        metadata: const {'new-key': 'new-val'},
      );

      expect(copy.runId, equals('new-run'));
      expect(copy.workspaceId, equals('new-ws'));
      expect(copy.skillId, equals('new-skill'));
      expect(copy.skillVersion, equals('9.0.0'));
      expect(copy.contextId, equals('new-ctx'));
      expect(copy.traceId, equals('new-trace'));
      expect(copy.startedAt, equals(newTime));
      expect(copy.finishedAt, equals(newTime));
      expect(copy.status, equals(SkillRunStatus.blocked));
      expect(copy.stepExecutions, isEmpty);
      expect(copy.gateChecks, isEmpty);
      expect(copy.inputs, equals({'new': true}));
      expect(copy.outputs, equals({'new': 'out'}));
      expect(copy.blockReason, equals('new reason'));
      expect(copy.artifactIds, equals(['new-art']));
      expect(copy.totalTokensUsed, equals(1));
      expect(copy.llmCallsMade, equals(2));
      expect(copy.mcpCallsMade, equals(3));
      expect(copy.createdAt, equals(newTime));
      expect(copy.metadata, equals({'new-key': 'new-val'}));
    });

    test('duration getter returns duration when finished', () {
      final run = createFullSkillRun();

      expect(run.duration, isNotNull);
      expect(run.duration!.inMinutes, equals(5));
    });

    test('duration getter returns null when not finished', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );

      expect(run.duration, isNull);
    });

    test('isComplete getter', () {
      final completed = createFullSkillRun();
      final running = completed.copyWith(status: SkillRunStatus.running);

      expect(completed.isComplete, isTrue);
      expect(running.isComplete, isFalse);
    });

    test('isFailed getter', () {
      final failed =
          createFullSkillRun().copyWith(status: SkillRunStatus.failed);
      final completed = createFullSkillRun();

      expect(failed.isFailed, isTrue);
      expect(completed.isFailed, isFalse);
    });

    test('isBlocked getter', () {
      final blocked =
          createFullSkillRun().copyWith(status: SkillRunStatus.blocked);
      final completed = createFullSkillRun();

      expect(blocked.isBlocked, isTrue);
      expect(completed.isBlocked, isFalse);
    });

    test('isRunning getter', () {
      final running =
          createFullSkillRun().copyWith(status: SkillRunStatus.running);
      final completed = createFullSkillRun();

      expect(running.isRunning, isTrue);
      expect(completed.isRunning, isFalse);
    });

    test('completedStepsCount getter', () {
      final run = createFullSkillRun();
      // step-1 is completed, step-2 is failed
      expect(run.completedStepsCount, equals(1));
    });

    test('completedStepsCount with no steps', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );
      expect(run.completedStepsCount, equals(0));
    });

    test('failedStepsCount getter', () {
      final run = createFullSkillRun();
      // step-2 is failed
      expect(run.failedStepsCount, equals(1));
    });

    test('failedStepsCount with no steps', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );
      expect(run.failedStepsCount, equals(0));
    });

    test('passedGatesCount getter', () {
      final run = createFullSkillRun();
      // gate-1 passed, gate-2 and gate-3 did not
      expect(run.passedGatesCount, equals(1));
    });

    test('failedGatesCount getter', () {
      final run = createFullSkillRun();
      // gate-2 and gate-3 failed
      expect(run.failedGatesCount, equals(2));
    });

    test('blockingGates getter returns gates with block action', () {
      final run = createFullSkillRun();
      final blocking = run.blockingGates;

      // gate-2 failed with block action; gate-3 failed with warn action
      expect(blocking, hasLength(1));
      expect(blocking[0].gateId, equals('gate-2'));
      expect(blocking[0].actionTaken, equals(GateAction.block));
    });

    test('blockingGates with no blocking gates', () {
      final run = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
        gateChecks: [
          GateCheck(
            gateId: 'gate-1',
            gateName: 'Check',
            condition: 'x',
            checkedAt: fixedStart,
            passed: true,
          ),
        ],
      );

      expect(run.blockingGates, isEmpty);
    });

    test('toString returns expected format', () {
      final run = createFullSkillRun();
      final str = run.toString();

      expect(str, contains('SkillRun'));
      expect(str, contains('sr-1'));
      expect(str, contains('skill-1'));
      expect(str, contains('completed'));
      expect(str, contains('2'));
    });

    test('equality compares by runId', () {
      final run1 = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );
      final run2 = SkillRun(
        runId: 'sr-1',
        workspaceId: 'ws-2',
        skillId: 'skill-2',
        skillVersion: '2.0.0',
        startedAt: fixedFinish,
        createdAt: fixedCreated,
      );
      final run3 = SkillRun(
        runId: 'sr-999',
        workspaceId: 'ws-1',
        skillId: 'skill-1',
        skillVersion: '1.0.0',
        startedAt: fixedStart,
        createdAt: fixedCreated,
      );

      expect(run1 == run2, isTrue);
      expect(run1 == run3, isFalse);
      expect(run1.hashCode, equals(run2.hashCode));
    });

    test('fromJson roundtrip preserves data', () {
      final original = createFullSkillRun();
      final json = original.toJson();
      final restored = SkillRun.fromJson(json);

      expect(restored.runId, equals(original.runId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.skillId, equals(original.skillId));
      expect(restored.skillVersion, equals(original.skillVersion));
      expect(restored.contextId, equals(original.contextId));
      expect(restored.traceId, equals(original.traceId));
      expect(restored.status, equals(original.status));
      expect(
        restored.stepExecutions.length,
        equals(original.stepExecutions.length),
      );
      expect(
        restored.gateChecks.length,
        equals(original.gateChecks.length),
      );
      expect(restored.inputs, equals(original.inputs));
      expect(restored.outputs, equals(original.outputs));
      expect(restored.artifactIds, equals(original.artifactIds));
      expect(restored.totalTokensUsed, equals(original.totalTokensUsed));
      expect(restored.llmCallsMade, equals(original.llmCallsMade));
      expect(restored.mcpCallsMade, equals(original.mcpCallsMade));
      expect(restored.metadata, equals(original.metadata));
    });
  });
}
