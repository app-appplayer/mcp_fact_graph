import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // SkillStatus enum tests
  // =========================================================================
  group('SkillStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(SkillStatus.fromString('draft'), equals(SkillStatus.draft));
      expect(SkillStatus.fromString('testing'), equals(SkillStatus.testing));
      expect(SkillStatus.fromString('testFail'), equals(SkillStatus.testFail));
      expect(SkillStatus.fromString('active'), equals(SkillStatus.active));
      expect(
        SkillStatus.fromString('published'),
        equals(SkillStatus.published),
      );
      expect(
        SkillStatus.fromString('suspended'),
        equals(SkillStatus.suspended),
      );
      expect(
        SkillStatus.fromString('deprecated'),
        equals(SkillStatus.deprecated),
      );
    });

    test('fromString returns draft for invalid value', () {
      expect(SkillStatus.fromString('unknown'), equals(SkillStatus.draft));
      expect(SkillStatus.fromString(''), equals(SkillStatus.draft));
      expect(SkillStatus.fromString('ACTIVE'), equals(SkillStatus.draft));
    });

    test('has all expected values', () {
      expect(SkillStatus.values, hasLength(7));
      expect(SkillStatus.values, contains(SkillStatus.draft));
      expect(SkillStatus.values, contains(SkillStatus.testing));
      expect(SkillStatus.values, contains(SkillStatus.testFail));
      expect(SkillStatus.values, contains(SkillStatus.active));
      expect(SkillStatus.values, contains(SkillStatus.published));
      expect(SkillStatus.values, contains(SkillStatus.suspended));
      expect(SkillStatus.values, contains(SkillStatus.deprecated));
    });
  });

  // =========================================================================
  // GateAction enum tests (from skill.dart)
  // =========================================================================
  group('GateAction (skill.dart)', () {
    test('fromString returns correct value for all valid values', () {
      expect(GateAction.fromString('block'), equals(GateAction.block));
      expect(GateAction.fromString('warn'), equals(GateAction.warn));
      expect(GateAction.fromString('log'), equals(GateAction.log));
    });

    test('fromString returns block for invalid value', () {
      expect(GateAction.fromString('unknown'), equals(GateAction.block));
      expect(GateAction.fromString(''), equals(GateAction.block));
    });

    test('has all expected values', () {
      expect(GateAction.values, hasLength(3));
      expect(GateAction.values, contains(GateAction.block));
      expect(GateAction.values, contains(GateAction.warn));
      expect(GateAction.values, contains(GateAction.log));
    });
  });

  // =========================================================================
  // SkillStep tests
  // =========================================================================
  group('SkillStep', () {
    test('constructor with required fields only', () {
      const step = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Extract Data',
        description: 'Extract data from source',
      );

      expect(step.stepId, equals('step-1'));
      expect(step.order, equals(1));
      expect(step.name, equals('Extract Data'));
      expect(step.description, equals('Extract data from source'));
      expect(step.inputs, isEmpty);
      expect(step.outputs, isEmpty);
      expect(step.checkpointCondition, isNull);
      expect(step.failureHandler, isNull);
      expect(step.expectedDuration, isNull);
    });

    test('constructor with all fields', () {
      const step = SkillStep(
        stepId: 'step-2',
        order: 2,
        name: 'Transform',
        description: 'Transform extracted data',
        inputs: {'source': 'file.csv'},
        outputs: {'result': 'processed.json'},
        checkpointCondition: 'output.size > 0',
        failureHandler: 'retry',
        expectedDuration: Duration(seconds: 30),
      );

      expect(step.stepId, equals('step-2'));
      expect(step.order, equals(2));
      expect(step.name, equals('Transform'));
      expect(step.description, equals('Transform extracted data'));
      expect(step.inputs, equals({'source': 'file.csv'}));
      expect(step.outputs, equals({'result': 'processed.json'}));
      expect(step.checkpointCondition, equals('output.size > 0'));
      expect(step.failureHandler, equals('retry'));
      expect(step.expectedDuration, equals(const Duration(seconds: 30)));
    });

    test('fromJson with complete data', () {
      final json = {
        'stepId': 'step-1',
        'order': 1,
        'name': 'Extract',
        'description': 'Extract step',
        'inputs': {'src': 'data'},
        'outputs': {'out': 'result'},
        'checkpointCondition': 'valid == true',
        'failureHandler': 'skip',
        'expectedDurationMs': 5000,
      };
      final step = SkillStep.fromJson(json);

      expect(step.stepId, equals('step-1'));
      expect(step.order, equals(1));
      expect(step.name, equals('Extract'));
      expect(step.description, equals('Extract step'));
      expect(step.inputs, equals({'src': 'data'}));
      expect(step.outputs, equals({'out': 'result'}));
      expect(step.checkpointCondition, equals('valid == true'));
      expect(step.failureHandler, equals('skip'));
      expect(step.expectedDuration, equals(const Duration(milliseconds: 5000)));
    });

    test('fromJson with empty map uses defaults', () {
      final step = SkillStep.fromJson({});

      expect(step.stepId, equals(''));
      expect(step.order, equals(0));
      expect(step.name, equals(''));
      expect(step.description, equals(''));
      expect(step.inputs, isEmpty);
      expect(step.outputs, isEmpty);
      expect(step.checkpointCondition, isNull);
      expect(step.failureHandler, isNull);
      expect(step.expectedDuration, isNull);
    });

    test('fromJson with null fields uses defaults', () {
      final step = SkillStep.fromJson({
        'stepId': null,
        'order': null,
        'name': null,
        'description': null,
        'inputs': null,
        'outputs': null,
        'checkpointCondition': null,
        'failureHandler': null,
        'expectedDurationMs': null,
      });

      expect(step.stepId, equals(''));
      expect(step.order, equals(0));
      expect(step.name, equals(''));
      expect(step.description, equals(''));
      expect(step.inputs, isEmpty);
      expect(step.outputs, isEmpty);
      expect(step.checkpointCondition, isNull);
      expect(step.failureHandler, isNull);
      expect(step.expectedDuration, isNull);
    });

    test('toJson with all fields populated', () {
      const step = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Extract',
        description: 'Extract data',
        inputs: {'src': 'data'},
        outputs: {'out': 'result'},
        checkpointCondition: 'valid',
        failureHandler: 'retry',
        expectedDuration: Duration(seconds: 10),
      );
      final json = step.toJson();

      expect(json['stepId'], equals('step-1'));
      expect(json['order'], equals(1));
      expect(json['name'], equals('Extract'));
      expect(json['description'], equals('Extract data'));
      expect(json['inputs'], equals({'src': 'data'}));
      expect(json['outputs'], equals({'out': 'result'}));
      expect(json['checkpointCondition'], equals('valid'));
      expect(json['failureHandler'], equals('retry'));
      expect(json['expectedDurationMs'], equals(10000));
    });

    test('toJson excludes empty/null fields', () {
      const step = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Simple',
        description: 'Simple step',
      );
      final json = step.toJson();

      expect(json.containsKey('inputs'), isFalse);
      expect(json.containsKey('outputs'), isFalse);
      expect(json.containsKey('checkpointCondition'), isFalse);
      expect(json.containsKey('failureHandler'), isFalse);
      expect(json.containsKey('expectedDurationMs'), isFalse);
      // Required fields always present
      expect(json.containsKey('stepId'), isTrue);
      expect(json.containsKey('order'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('description'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      const original = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Original',
        description: 'Original step',
        inputs: {'a': 1},
      );
      final copy = original.copyWith(
        name: 'Updated',
        order: 2,
        checkpointCondition: 'new-condition',
      );

      expect(copy.name, equals('Updated'));
      expect(copy.order, equals(2));
      expect(copy.checkpointCondition, equals('new-condition'));
      // Unchanged
      expect(copy.stepId, equals('step-1'));
      expect(copy.description, equals('Original step'));
      expect(copy.inputs, equals({'a': 1}));
      expect(copy.outputs, isEmpty);
      expect(copy.failureHandler, isNull);
      expect(copy.expectedDuration, isNull);
    });

    test('copyWith with no arguments returns equivalent step', () {
      const original = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Test',
        description: 'Test step',
      );
      final copy = original.copyWith();

      expect(copy.stepId, equals(original.stepId));
      expect(copy.order, equals(original.order));
      expect(copy.name, equals(original.name));
    });

    test('copyWith all fields', () {
      const original = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Old',
        description: 'Old desc',
      );
      final copy = original.copyWith(
        stepId: 'new-step',
        order: 99,
        name: 'New',
        description: 'New desc',
        inputs: {'x': 1},
        outputs: {'y': 2},
        checkpointCondition: 'cond',
        failureHandler: 'handler',
        expectedDuration: const Duration(minutes: 5),
      );

      expect(copy.stepId, equals('new-step'));
      expect(copy.order, equals(99));
      expect(copy.name, equals('New'));
      expect(copy.description, equals('New desc'));
      expect(copy.inputs, equals({'x': 1}));
      expect(copy.outputs, equals({'y': 2}));
      expect(copy.checkpointCondition, equals('cond'));
      expect(copy.failureHandler, equals('handler'));
      expect(copy.expectedDuration, equals(const Duration(minutes: 5)));
    });

    test('toString returns expected format', () {
      const step = SkillStep(
        stepId: 'step-1',
        order: 1,
        name: 'Extract',
        description: 'Extract data',
      );
      final str = step.toString();

      expect(str, contains('SkillStep'));
      expect(str, contains('step-1'));
      expect(str, contains('1'));
      expect(str, contains('Extract'));
    });
  });

  // =========================================================================
  // QualityGate tests
  // =========================================================================
  group('QualityGate', () {
    test('constructor with required fields only', () {
      const gate = QualityGate(
        gateId: 'gate-1',
        name: 'Accuracy Check',
        condition: 'accuracy >= 0.9',
      );

      expect(gate.gateId, equals('gate-1'));
      expect(gate.name, equals('Accuracy Check'));
      expect(gate.condition, equals('accuracy >= 0.9'));
      expect(gate.onFailure, equals(GateAction.block));
      expect(gate.description, isNull);
    });

    test('constructor with all fields', () {
      const gate = QualityGate(
        gateId: 'gate-2',
        name: 'Format Check',
        condition: 'format == "json"',
        onFailure: GateAction.warn,
        description: 'Verifies output format',
      );

      expect(gate.gateId, equals('gate-2'));
      expect(gate.name, equals('Format Check'));
      expect(gate.condition, equals('format == "json"'));
      expect(gate.onFailure, equals(GateAction.warn));
      expect(gate.description, equals('Verifies output format'));
    });

    test('fromJson with complete data', () {
      final json = {
        'gateId': 'gate-1',
        'name': 'Quality Gate',
        'condition': 'score > 0.8',
        'onFailure': 'warn',
        'description': 'Quality check gate',
      };
      final gate = QualityGate.fromJson(json);

      expect(gate.gateId, equals('gate-1'));
      expect(gate.name, equals('Quality Gate'));
      expect(gate.condition, equals('score > 0.8'));
      expect(gate.onFailure, equals(GateAction.warn));
      expect(gate.description, equals('Quality check gate'));
    });

    test('fromJson with empty map uses defaults', () {
      final gate = QualityGate.fromJson({});

      expect(gate.gateId, equals(''));
      expect(gate.name, equals(''));
      expect(gate.condition, equals(''));
      expect(gate.onFailure, equals(GateAction.block));
      expect(gate.description, isNull);
    });

    test('fromJson with null fields uses defaults', () {
      final gate = QualityGate.fromJson({
        'gateId': null,
        'name': null,
        'condition': null,
        'onFailure': null,
        'description': null,
      });

      expect(gate.gateId, equals(''));
      expect(gate.name, equals(''));
      expect(gate.condition, equals(''));
      expect(gate.onFailure, equals(GateAction.block));
      expect(gate.description, isNull);
    });

    test('toJson with all fields populated', () {
      const gate = QualityGate(
        gateId: 'gate-1',
        name: 'Check',
        condition: 'x > 0',
        onFailure: GateAction.log,
        description: 'Log gate',
      );
      final json = gate.toJson();

      expect(json['gateId'], equals('gate-1'));
      expect(json['name'], equals('Check'));
      expect(json['condition'], equals('x > 0'));
      expect(json['onFailure'], equals('log'));
      expect(json['description'], equals('Log gate'));
    });

    test('toJson excludes null description', () {
      const gate = QualityGate(
        gateId: 'gate-1',
        name: 'Check',
        condition: 'x > 0',
      );
      final json = gate.toJson();

      expect(json.containsKey('description'), isFalse);
      // Required fields always present
      expect(json.containsKey('gateId'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('condition'), isTrue);
      expect(json.containsKey('onFailure'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      const original = QualityGate(
        gateId: 'gate-1',
        name: 'Original',
        condition: 'x > 0',
        onFailure: GateAction.block,
      );
      final copy = original.copyWith(
        name: 'Updated',
        onFailure: GateAction.warn,
        description: 'Added description',
      );

      expect(copy.name, equals('Updated'));
      expect(copy.onFailure, equals(GateAction.warn));
      expect(copy.description, equals('Added description'));
      // Unchanged
      expect(copy.gateId, equals('gate-1'));
      expect(copy.condition, equals('x > 0'));
    });

    test('copyWith with no arguments returns equivalent gate', () {
      const original = QualityGate(
        gateId: 'gate-1',
        name: 'Test',
        condition: 'x',
      );
      final copy = original.copyWith();

      expect(copy.gateId, equals(original.gateId));
      expect(copy.name, equals(original.name));
      expect(copy.condition, equals(original.condition));
    });

    test('copyWith all fields', () {
      const original = QualityGate(
        gateId: 'gate-1',
        name: 'Old',
        condition: 'old',
      );
      final copy = original.copyWith(
        gateId: 'new-gate',
        name: 'New',
        condition: 'new',
        onFailure: GateAction.log,
        description: 'New desc',
      );

      expect(copy.gateId, equals('new-gate'));
      expect(copy.name, equals('New'));
      expect(copy.condition, equals('new'));
      expect(copy.onFailure, equals(GateAction.log));
      expect(copy.description, equals('New desc'));
    });

    test('toString returns expected format', () {
      const gate = QualityGate(
        gateId: 'gate-1',
        name: 'Check',
        condition: 'x > 0',
      );
      final str = gate.toString();

      expect(str, contains('QualityGate'));
      expect(str, contains('gate-1'));
      expect(str, contains('Check'));
    });
  });

  // =========================================================================
  // Skill tests
  // =========================================================================
  group('Skill', () {
    final fixedTime = DateTime(2024, 6, 15, 10, 0);
    final fixedUpdate = DateTime(2024, 6, 20, 12, 0);

    Skill createFullSkill() {
      return Skill(
        skillId: 'skill-1',
        workspaceId: 'ws-1',
        name: 'Data Extraction',
        description: 'Extracts facts from documents',
        version: '2.0.0',
        steps: const [
          SkillStep(
            stepId: 'step-1',
            order: 1,
            name: 'Parse',
            description: 'Parse input',
          ),
          SkillStep(
            stepId: 'step-2',
            order: 2,
            name: 'Extract',
            description: 'Extract facts',
          ),
        ],
        requiredEvidenceTypes: const ['document', 'citation'],
        qualityGates: const [
          QualityGate(
            gateId: 'gate-1',
            name: 'Accuracy',
            condition: 'accuracy >= 0.9',
          ),
        ],
        owner: 'user-1',
        applicability: const ['research', 'analysis'],
        status: SkillStatus.active,
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
      );
    }

    test('constructor with required fields only', () {
      final skill = Skill(
        skillId: 'skill-1',
        workspaceId: 'ws-1',
        name: 'Test Skill',
        description: 'A test skill',
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
      );

      expect(skill.skillId, equals('skill-1'));
      expect(skill.workspaceId, equals('ws-1'));
      expect(skill.name, equals('Test Skill'));
      expect(skill.description, equals('A test skill'));
      expect(skill.version, equals('1.0.0'));
      expect(skill.steps, isEmpty);
      expect(skill.requiredEvidenceTypes, isEmpty);
      expect(skill.qualityGates, isEmpty);
      expect(skill.owner, isNull);
      expect(skill.applicability, isEmpty);
      expect(skill.status, equals(SkillStatus.draft));
      expect(skill.createdAt, equals(fixedTime));
      expect(skill.updatedAt, equals(fixedUpdate));
    });

    test('constructor with all fields', () {
      final skill = createFullSkill();

      expect(skill.skillId, equals('skill-1'));
      expect(skill.workspaceId, equals('ws-1'));
      expect(skill.name, equals('Data Extraction'));
      expect(skill.description, equals('Extracts facts from documents'));
      expect(skill.version, equals('2.0.0'));
      expect(skill.steps, hasLength(2));
      expect(skill.steps[0].name, equals('Parse'));
      expect(skill.requiredEvidenceTypes, equals(['document', 'citation']));
      expect(skill.qualityGates, hasLength(1));
      expect(skill.qualityGates[0].gateId, equals('gate-1'));
      expect(skill.owner, equals('user-1'));
      expect(skill.applicability, equals(['research', 'analysis']));
      expect(skill.status, equals(SkillStatus.active));
    });

    test('fromJson with complete data', () {
      final json = {
        'skillId': 'skill-1',
        'workspaceId': 'ws-1',
        'name': 'Data Extraction',
        'description': 'Extracts data',
        'version': '2.0.0',
        'steps': [
          {
            'stepId': 'step-1',
            'order': 1,
            'name': 'Parse',
            'description': 'Parse step',
          },
        ],
        'requiredEvidenceTypes': ['document'],
        'qualityGates': [
          {
            'gateId': 'gate-1',
            'name': 'Quality',
            'condition': 'score > 0.8',
            'onFailure': 'warn',
          },
        ],
        'owner': 'user-1',
        'applicability': ['research'],
        'status': 'active',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-20T12:00:00.000',
      };
      final skill = Skill.fromJson(json);

      expect(skill.skillId, equals('skill-1'));
      expect(skill.workspaceId, equals('ws-1'));
      expect(skill.name, equals('Data Extraction'));
      expect(skill.version, equals('2.0.0'));
      expect(skill.steps, hasLength(1));
      expect(skill.steps[0].stepId, equals('step-1'));
      expect(skill.requiredEvidenceTypes, equals(['document']));
      expect(skill.qualityGates, hasLength(1));
      expect(skill.qualityGates[0].onFailure, equals(GateAction.warn));
      expect(skill.owner, equals('user-1'));
      expect(skill.applicability, equals(['research']));
      expect(skill.status, equals(SkillStatus.active));
      expect(skill.createdAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(skill.updatedAt, equals(DateTime(2024, 6, 20, 12, 0)));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final skill = Skill.fromJson({});
      final after = DateTime.now();

      expect(skill.skillId, equals(''));
      expect(skill.workspaceId, equals('default'));
      expect(skill.name, equals(''));
      expect(skill.description, equals(''));
      expect(skill.version, equals('1.0.0'));
      expect(skill.steps, isEmpty);
      expect(skill.requiredEvidenceTypes, isEmpty);
      expect(skill.qualityGates, isEmpty);
      expect(skill.owner, isNull);
      expect(skill.applicability, isEmpty);
      expect(skill.status, equals(SkillStatus.draft));
      expect(
        skill.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        skill.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('fromJson with null optional fields', () {
      final json = {
        'skillId': 's-1',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'steps': null,
        'requiredEvidenceTypes': null,
        'qualityGates': null,
        'owner': null,
        'applicability': null,
        'version': null,
        'status': null,
      };
      final skill = Skill.fromJson(json);

      expect(skill.steps, isEmpty);
      expect(skill.requiredEvidenceTypes, isEmpty);
      expect(skill.qualityGates, isEmpty);
      expect(skill.owner, isNull);
      expect(skill.applicability, isEmpty);
    });

    test('toJson with fully populated skill', () {
      final skill = createFullSkill();
      final json = skill.toJson();

      expect(json['skillId'], equals('skill-1'));
      expect(json['workspaceId'], equals('ws-1'));
      expect(json['name'], equals('Data Extraction'));
      expect(json['description'], equals('Extracts facts from documents'));
      expect(json['version'], equals('2.0.0'));
      expect(json['steps'], isA<List>());
      expect((json['steps'] as List), hasLength(2));
      expect(
        json['requiredEvidenceTypes'],
        equals(['document', 'citation']),
      );
      expect(json['qualityGates'], isA<List>());
      expect((json['qualityGates'] as List), hasLength(1));
      expect(json['owner'], equals('user-1'));
      expect(json['applicability'], equals(['research', 'analysis']));
      expect(json['status'], equals('active'));
      expect(json['createdAt'], equals(fixedTime.toIso8601String()));
      expect(json['updatedAt'], equals(fixedUpdate.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final skill = Skill(
        skillId: 'skill-1',
        workspaceId: 'ws-1',
        name: 'Minimal',
        description: 'Minimal skill',
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
      );
      final json = skill.toJson();

      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('requiredEvidenceTypes'), isFalse);
      expect(json.containsKey('qualityGates'), isFalse);
      expect(json.containsKey('owner'), isFalse);
      expect(json.containsKey('applicability'), isFalse);
      // Required fields always present
      expect(json.containsKey('skillId'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('version'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = createFullSkill();
      final copy = original.copyWith(
        skillId: 'skill-2',
        name: 'Updated Skill',
        status: SkillStatus.deprecated,
        version: '3.0.0',
      );

      expect(copy.skillId, equals('skill-2'));
      expect(copy.name, equals('Updated Skill'));
      expect(copy.status, equals(SkillStatus.deprecated));
      expect(copy.version, equals('3.0.0'));
      // Unchanged
      expect(copy.workspaceId, equals('ws-1'));
      expect(copy.description, equals('Extracts facts from documents'));
      expect(copy.steps, hasLength(2));
      expect(copy.requiredEvidenceTypes, equals(['document', 'citation']));
      expect(copy.qualityGates, hasLength(1));
      expect(copy.owner, equals('user-1'));
      expect(copy.applicability, equals(['research', 'analysis']));
    });

    test('copyWith with no arguments returns equivalent skill', () {
      final original = createFullSkill();
      final copy = original.copyWith();

      expect(copy.skillId, equals(original.skillId));
      expect(copy.name, equals(original.name));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = createFullSkill();
      final newTime = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        skillId: 'new-id',
        workspaceId: 'new-ws',
        name: 'New Skill',
        description: 'New Desc',
        version: '9.0.0',
        steps: const [],
        requiredEvidenceTypes: const ['new-type'],
        qualityGates: const [],
        owner: 'new-owner',
        applicability: const ['new-ctx'],
        status: SkillStatus.suspended,
        createdAt: newTime,
        updatedAt: newTime,
      );

      expect(copy.skillId, equals('new-id'));
      expect(copy.workspaceId, equals('new-ws'));
      expect(copy.name, equals('New Skill'));
      expect(copy.description, equals('New Desc'));
      expect(copy.version, equals('9.0.0'));
      expect(copy.steps, isEmpty);
      expect(copy.requiredEvidenceTypes, equals(['new-type']));
      expect(copy.qualityGates, isEmpty);
      expect(copy.owner, equals('new-owner'));
      expect(copy.applicability, equals(['new-ctx']));
      expect(copy.status, equals(SkillStatus.suspended));
      expect(copy.createdAt, equals(newTime));
      expect(copy.updatedAt, equals(newTime));
    });

    test('isAvailable getter', () {
      final active = Skill(
        skillId: 's-1',
        workspaceId: 'ws-1',
        name: 'Active',
        description: 'desc',
        status: SkillStatus.active,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final draft = Skill(
        skillId: 's-2',
        workspaceId: 'ws-1',
        name: 'Draft',
        description: 'desc',
        status: SkillStatus.draft,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final published = Skill(
        skillId: 's-3',
        workspaceId: 'ws-1',
        name: 'Published',
        description: 'desc',
        status: SkillStatus.published,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(active.isAvailable, isTrue);
      expect(draft.isAvailable, isFalse);
      expect(published.isAvailable, isFalse);
    });

    test('toString returns expected format', () {
      final skill = createFullSkill();
      final str = skill.toString();

      expect(str, contains('Skill'));
      expect(str, contains('skill-1'));
      expect(str, contains('Data Extraction'));
    });

    test('equality compares by skillId', () {
      final skill1 = Skill(
        skillId: 'skill-1',
        workspaceId: 'ws-1',
        name: 'A',
        description: 'desc A',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final skill2 = Skill(
        skillId: 'skill-1',
        workspaceId: 'ws-2',
        name: 'B',
        description: 'desc B',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final skill3 = Skill(
        skillId: 'skill-999',
        workspaceId: 'ws-1',
        name: 'A',
        description: 'desc A',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(skill1 == skill2, isTrue);
      expect(skill1 == skill3, isFalse);
      expect(skill1.hashCode, equals(skill2.hashCode));
    });

    test('fromJson roundtrip preserves data', () {
      final original = createFullSkill();
      final json = original.toJson();
      final restored = Skill.fromJson(json);

      expect(restored.skillId, equals(original.skillId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.version, equals(original.version));
      expect(restored.steps, hasLength(original.steps.length));
      expect(
        restored.requiredEvidenceTypes,
        equals(original.requiredEvidenceTypes),
      );
      expect(restored.qualityGates, hasLength(original.qualityGates.length));
      expect(restored.owner, equals(original.owner));
      expect(restored.applicability, equals(original.applicability));
      expect(restored.status, equals(original.status));
    });

    test('fromJson with createdAt/updatedAt null uses DateTime.now()', () {
      final before = DateTime.now();
      final skill = Skill.fromJson({
        'skillId': 's-1',
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        skill.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        skill.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('Skill constructor stores createdAt and updatedAt', () {
      final t1 = DateTime(2024, 3, 1);
      final t2 = DateTime(2024, 4, 1);
      final skill = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: t1,
        updatedAt: t2,
      );

      expect(skill.createdAt, equals(t1));
      expect(skill.updatedAt, equals(t2));
    });

    test('toJson includes status name string', () {
      final skill = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        status: SkillStatus.testing,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final json = skill.toJson();
      expect(json['status'], equals('testing'));
    });

    test('Skill equality with non-Skill object returns false', () {
      final skill = Skill(
        skillId: 's-1',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(skill == Object(), isFalse);
    });

    test('Skill identical returns true', () {
      final skill = Skill(
        skillId: 's-1',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(skill == skill, isTrue);
    });
  });

  // =========================================================================
  // Additional SkillStep coverage
  // =========================================================================
  group('SkillStep additional coverage', () {
    test('SkillStep field declarations are covered by full construction', () {
      const step = SkillStep(
        stepId: 'sid',
        order: 5,
        name: 'Step Name',
        description: 'Step Desc',
        inputs: {'i': 1},
        outputs: {'o': 2},
        checkpointCondition: 'cond',
        failureHandler: 'fh',
        expectedDuration: Duration(minutes: 1),
      );

      expect(step.stepId, equals('sid'));
      expect(step.order, equals(5));
      expect(step.name, equals('Step Name'));
      expect(step.description, equals('Step Desc'));
      expect(step.inputs, equals({'i': 1}));
      expect(step.outputs, equals({'o': 2}));
      expect(step.checkpointCondition, equals('cond'));
      expect(step.failureHandler, equals('fh'));
      expect(step.expectedDuration, equals(const Duration(minutes: 1)));
    });

    test('SkillStep copyWith each field individually', () {
      const base = SkillStep(
        stepId: 'base',
        order: 0,
        name: 'base',
        description: 'base desc',
      );

      expect(base.copyWith(stepId: 'x').stepId, equals('x'));
      expect(base.copyWith(order: 10).order, equals(10));
      expect(base.copyWith(name: 'y').name, equals('y'));
      expect(base.copyWith(description: 'z').description, equals('z'));
      expect(base.copyWith(inputs: {'k': 'v'}).inputs, equals({'k': 'v'}));
      expect(base.copyWith(outputs: {'k': 'v'}).outputs, equals({'k': 'v'}));
      expect(
        base.copyWith(checkpointCondition: 'c').checkpointCondition,
        equals('c'),
      );
      expect(
        base.copyWith(failureHandler: 'fh').failureHandler,
        equals('fh'),
      );
      expect(
        base.copyWith(expectedDuration: const Duration(hours: 1)).expectedDuration,
        equals(const Duration(hours: 1)),
      );
    });

    test('SkillStep toString format', () {
      const step = SkillStep(
        stepId: 'abc',
        order: 3,
        name: 'My Step',
        description: 'desc',
      );
      expect(
        step.toString(),
        equals('SkillStep(abc, order: 3, name: My Step)'),
      );
    });
  });

  // =========================================================================
  // Additional QualityGate coverage
  // =========================================================================
  group('QualityGate additional coverage', () {
    test('QualityGate field declarations covered', () {
      const gate = QualityGate(
        gateId: 'gid',
        name: 'Gate Name',
        condition: 'x > 0',
        onFailure: GateAction.warn,
        description: 'desc',
      );

      expect(gate.gateId, equals('gid'));
      expect(gate.name, equals('Gate Name'));
      expect(gate.condition, equals('x > 0'));
      expect(gate.onFailure, equals(GateAction.warn));
      expect(gate.description, equals('desc'));
    });

    test('QualityGate fromJson with all onFailure variants', () {
      final blockGate = QualityGate.fromJson({
        'gateId': 'g1',
        'name': 'n',
        'condition': 'c',
        'onFailure': 'block',
      });
      expect(blockGate.onFailure, equals(GateAction.block));

      final warnGate = QualityGate.fromJson({
        'gateId': 'g2',
        'name': 'n',
        'condition': 'c',
        'onFailure': 'warn',
      });
      expect(warnGate.onFailure, equals(GateAction.warn));

      final logGate = QualityGate.fromJson({
        'gateId': 'g3',
        'name': 'n',
        'condition': 'c',
        'onFailure': 'log',
      });
      expect(logGate.onFailure, equals(GateAction.log));
    });

    test('QualityGate fromJson with description', () {
      final gate = QualityGate.fromJson({
        'gateId': 'g',
        'name': 'n',
        'condition': 'c',
        'description': 'a description',
      });
      expect(gate.description, equals('a description'));
    });

    test('QualityGate copyWith each field individually', () {
      const base = QualityGate(
        gateId: 'base',
        name: 'base',
        condition: 'base',
      );

      expect(base.copyWith(gateId: 'x').gateId, equals('x'));
      expect(base.copyWith(name: 'y').name, equals('y'));
      expect(base.copyWith(condition: 'z').condition, equals('z'));
      expect(
        base.copyWith(onFailure: GateAction.log).onFailure,
        equals(GateAction.log),
      );
      expect(
        base.copyWith(description: 'd').description,
        equals('d'),
      );
    });

    test('QualityGate toString format', () {
      const gate = QualityGate(
        gateId: 'gate-x',
        name: 'My Gate',
        condition: 'cond',
      );
      expect(
        gate.toString(),
        equals('QualityGate(gate-x, name: My Gate)'),
      );
    });
  });

  // =========================================================================
  // SkillStatus enum value coverage
  // =========================================================================
  group('SkillStatus enum values', () {
    test('all status values are accessible', () {
      expect(SkillStatus.draft.name, equals('draft'));
      expect(SkillStatus.testing.name, equals('testing'));
      expect(SkillStatus.testFail.name, equals('testFail'));
      expect(SkillStatus.active.name, equals('active'));
      expect(SkillStatus.published.name, equals('published'));
      expect(SkillStatus.suspended.name, equals('suspended'));
      expect(SkillStatus.deprecated.name, equals('deprecated'));
    });

    test('fromString with each status string', () {
      for (final status in SkillStatus.values) {
        expect(SkillStatus.fromString(status.name), equals(status));
      }
    });
  });

  // =========================================================================
  // GateAction enum value coverage
  // =========================================================================
  group('GateAction enum values', () {
    test('all action values are accessible', () {
      expect(GateAction.block.name, equals('block'));
      expect(GateAction.warn.name, equals('warn'));
      expect(GateAction.log.name, equals('log'));
    });

    test('fromString with each action string', () {
      for (final action in GateAction.values) {
        expect(GateAction.fromString(action.name), equals(action));
      }
    });
  });

  // =========================================================================
  // Additional Skill coverage for branches
  // =========================================================================
  group('Skill additional branch coverage', () {
    final fixedTime = DateTime(2024, 6, 15, 10, 0);

    test('Skill with all SkillStatus values via fromJson', () {
      for (final status in SkillStatus.values) {
        final skill = Skill.fromJson({
          'skillId': 's',
          'status': status.name,
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        });
        expect(skill.status, equals(status));
      }
    });

    test('Skill copyWith preserves all fields when no args given', () {
      final original = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        version: '1.0.0',
        steps: const [
          SkillStep(
            stepId: 'st',
            order: 1,
            name: 'step',
            description: 'desc',
          ),
        ],
        requiredEvidenceTypes: const ['et'],
        qualityGates: const [
          QualityGate(gateId: 'g', name: 'gn', condition: 'c'),
        ],
        owner: 'o',
        applicability: const ['a'],
        status: SkillStatus.active,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final copy = original.copyWith();

      expect(copy.skillId, equals(original.skillId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.name, equals(original.name));
      expect(copy.description, equals(original.description));
      expect(copy.version, equals(original.version));
      expect(copy.steps.length, equals(original.steps.length));
      expect(copy.requiredEvidenceTypes, equals(original.requiredEvidenceTypes));
      expect(copy.qualityGates.length, equals(original.qualityGates.length));
      expect(copy.owner, equals(original.owner));
      expect(copy.applicability, equals(original.applicability));
      expect(copy.status, equals(original.status));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('Skill copyWith each field individually', () {
      final base = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final newTime = DateTime(2025, 1, 1);

      expect(base.copyWith(skillId: 'x').skillId, equals('x'));
      expect(base.copyWith(workspaceId: 'x').workspaceId, equals('x'));
      expect(base.copyWith(name: 'x').name, equals('x'));
      expect(base.copyWith(description: 'x').description, equals('x'));
      expect(base.copyWith(version: 'x').version, equals('x'));
      expect(
        base.copyWith(steps: const [
          SkillStep(stepId: 'a', order: 1, name: 'b', description: 'c'),
        ]).steps.length,
        equals(1),
      );
      expect(
        base.copyWith(requiredEvidenceTypes: const ['e']).requiredEvidenceTypes,
        equals(['e']),
      );
      expect(
        base.copyWith(qualityGates: const [
          QualityGate(gateId: 'g', name: 'n', condition: 'c'),
        ]).qualityGates.length,
        equals(1),
      );
      expect(base.copyWith(owner: 'o').owner, equals('o'));
      expect(
        base.copyWith(applicability: const ['a']).applicability,
        equals(['a']),
      );
      expect(
        base.copyWith(status: SkillStatus.testing).status,
        equals(SkillStatus.testing),
      );
      expect(base.copyWith(createdAt: newTime).createdAt, equals(newTime));
      expect(base.copyWith(updatedAt: newTime).updatedAt, equals(newTime));
    });

    test('Skill toJson with conditional fields present', () {
      final skill = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        steps: const [
          SkillStep(stepId: 'st', order: 1, name: 'sn', description: 'sd'),
        ],
        requiredEvidenceTypes: const ['et'],
        qualityGates: const [
          QualityGate(gateId: 'g', name: 'gn', condition: 'gc'),
        ],
        owner: 'owner',
        applicability: const ['app'],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final json = skill.toJson();

      expect(json.containsKey('steps'), isTrue);
      expect(json.containsKey('requiredEvidenceTypes'), isTrue);
      expect(json.containsKey('qualityGates'), isTrue);
      expect(json.containsKey('owner'), isTrue);
      expect(json.containsKey('applicability'), isTrue);
    });

    test('Skill toJson conditional fields absent when empty/null', () {
      final skill = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final json = skill.toJson();

      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('requiredEvidenceTypes'), isFalse);
      expect(json.containsKey('qualityGates'), isFalse);
      expect(json.containsKey('owner'), isFalse);
      expect(json.containsKey('applicability'), isFalse);
    });

    test('Skill toJson with createdAt and updatedAt', () {
      final skill = Skill(
        skillId: 's',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final json = skill.toJson();

      expect(json['createdAt'], equals(fixedTime.toIso8601String()));
      expect(json['updatedAt'], equals(fixedTime.toIso8601String()));
    });

    test('SkillStep toJson conditional branches all covered', () {
      const withAll = SkillStep(
        stepId: 's',
        order: 1,
        name: 'n',
        description: 'd',
        inputs: {'a': 1},
        outputs: {'b': 2},
        checkpointCondition: 'c',
        failureHandler: 'f',
        expectedDuration: Duration(seconds: 5),
      );
      final jsonAll = withAll.toJson();
      expect(jsonAll.containsKey('inputs'), isTrue);
      expect(jsonAll.containsKey('outputs'), isTrue);
      expect(jsonAll.containsKey('checkpointCondition'), isTrue);
      expect(jsonAll.containsKey('failureHandler'), isTrue);
      expect(jsonAll.containsKey('expectedDurationMs'), isTrue);

      const withNone = SkillStep(
        stepId: 's',
        order: 1,
        name: 'n',
        description: 'd',
      );
      final jsonNone = withNone.toJson();
      expect(jsonNone.containsKey('inputs'), isFalse);
      expect(jsonNone.containsKey('outputs'), isFalse);
      expect(jsonNone.containsKey('checkpointCondition'), isFalse);
      expect(jsonNone.containsKey('failureHandler'), isFalse);
      expect(jsonNone.containsKey('expectedDurationMs'), isFalse);
    });

    test('QualityGate toJson with and without description', () {
      const withDesc = QualityGate(
        gateId: 'g',
        name: 'n',
        condition: 'c',
        description: 'desc',
      );
      expect(withDesc.toJson().containsKey('description'), isTrue);

      const withoutDesc = QualityGate(
        gateId: 'g',
        name: 'n',
        condition: 'c',
      );
      expect(withoutDesc.toJson().containsKey('description'), isFalse);
    });
  });
}
