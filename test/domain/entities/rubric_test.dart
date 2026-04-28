import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // RubricStatus enum tests
  // =========================================================================
  group('RubricStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(RubricStatus.fromString('draft'), equals(RubricStatus.draft));
      expect(RubricStatus.fromString('active'), equals(RubricStatus.active));
      expect(
        RubricStatus.fromString('deprecated'),
        equals(RubricStatus.deprecated),
      );
    });

    test('fromString returns active for invalid value', () {
      expect(RubricStatus.fromString('unknown'), equals(RubricStatus.active));
      expect(RubricStatus.fromString(''), equals(RubricStatus.active));
      expect(RubricStatus.fromString('ACTIVE'), equals(RubricStatus.active));
    });

    test('has all expected values', () {
      expect(RubricStatus.values, hasLength(3));
      expect(RubricStatus.values, contains(RubricStatus.draft));
      expect(RubricStatus.values, contains(RubricStatus.active));
      expect(RubricStatus.values, contains(RubricStatus.deprecated));
    });
  });

  // =========================================================================
  // MeasurementType enum tests
  // =========================================================================
  group('MeasurementType', () {
    test('fromString returns correct value for all valid values', () {
      expect(
        MeasurementType.fromString('numeric'),
        equals(MeasurementType.numeric),
      );
      expect(
        MeasurementType.fromString('categorical'),
        equals(MeasurementType.categorical),
      );
      expect(
        MeasurementType.fromString('boolean'),
        equals(MeasurementType.boolean),
      );
    });

    test('fromString returns numeric for invalid value', () {
      expect(
        MeasurementType.fromString('unknown'),
        equals(MeasurementType.numeric),
      );
      expect(MeasurementType.fromString(''), equals(MeasurementType.numeric));
    });

    test('has all expected values', () {
      expect(MeasurementType.values, hasLength(3));
      expect(MeasurementType.values, contains(MeasurementType.numeric));
      expect(MeasurementType.values, contains(MeasurementType.categorical));
      expect(MeasurementType.values, contains(MeasurementType.boolean));
    });
  });

  // =========================================================================
  // ScoreLevel tests
  // =========================================================================
  group('ScoreLevel', () {
    test('constructor with required fields', () {
      const level = ScoreLevel(
        label: 'Excellent',
        minScore: 0.9,
        maxScore: 1.0,
        description: 'Outstanding performance',
      );

      expect(level.label, equals('Excellent'));
      expect(level.minScore, equals(0.9));
      expect(level.maxScore, equals(1.0));
      expect(level.description, equals('Outstanding performance'));
      expect(level.indicators, isEmpty);
    });

    test('constructor with all fields', () {
      const level = ScoreLevel(
        label: 'Good',
        minScore: 0.7,
        maxScore: 0.89,
        description: 'Good performance',
        indicators: ['Meets expectations', 'Consistent quality'],
      );

      expect(level.label, equals('Good'));
      expect(level.minScore, equals(0.7));
      expect(level.maxScore, equals(0.89));
      expect(level.description, equals('Good performance'));
      expect(level.indicators, hasLength(2));
      expect(level.indicators, contains('Meets expectations'));
    });

    test('fromJson with complete data', () {
      final json = {
        'label': 'Excellent',
        'minScore': 0.9,
        'maxScore': 1.0,
        'description': 'Outstanding',
        'indicators': ['metric1', 'metric2'],
      };
      final level = ScoreLevel.fromJson(json);

      expect(level.label, equals('Excellent'));
      expect(level.minScore, equals(0.9));
      expect(level.maxScore, equals(1.0));
      expect(level.description, equals('Outstanding'));
      expect(level.indicators, equals(['metric1', 'metric2']));
    });

    test('fromJson with empty map uses defaults', () {
      final level = ScoreLevel.fromJson({});

      expect(level.label, equals(''));
      expect(level.minScore, equals(0.0));
      expect(level.maxScore, equals(1.0));
      expect(level.description, equals(''));
      expect(level.indicators, isEmpty);
    });

    test('fromJson with null fields uses defaults', () {
      final level = ScoreLevel.fromJson({
        'label': null,
        'minScore': null,
        'maxScore': null,
        'description': null,
        'indicators': null,
      });

      expect(level.label, equals(''));
      expect(level.minScore, equals(0.0));
      expect(level.maxScore, equals(1.0));
      expect(level.description, equals(''));
      expect(level.indicators, isEmpty);
    });

    test('toJson with populated fields', () {
      const level = ScoreLevel(
        label: 'Good',
        minScore: 0.7,
        maxScore: 0.89,
        description: 'Good performance',
        indicators: ['ind1'],
      );
      final json = level.toJson();

      expect(json['label'], equals('Good'));
      expect(json['minScore'], equals(0.7));
      expect(json['maxScore'], equals(0.89));
      expect(json['description'], equals('Good performance'));
      expect(json['indicators'], equals(['ind1']));
    });

    test('toJson excludes empty indicators', () {
      const level = ScoreLevel(
        label: 'Good',
        minScore: 0.7,
        maxScore: 0.89,
        description: 'Good performance',
      );
      final json = level.toJson();

      expect(json.containsKey('indicators'), isFalse);
    });
  });

  // =========================================================================
  // RubricDimension tests
  // =========================================================================
  group('RubricDimension', () {
    test('constructor with required fields only', () {
      const dim = RubricDimension(
        dimensionId: 'dim-1',
        name: 'Accuracy',
        description: 'Measures factual accuracy',
      );

      expect(dim.dimensionId, equals('dim-1'));
      expect(dim.name, equals('Accuracy'));
      expect(dim.description, equals('Measures factual accuracy'));
      expect(dim.measurementMethod, equals(''));
      expect(dim.measurementType, equals(MeasurementType.numeric));
      expect(dim.minScore, equals(0.0));
      expect(dim.maxScore, equals(1.0));
      expect(dim.levels, isEmpty);
      expect(dim.evidenceTypes, isEmpty);
    });

    test('constructor with all fields', () {
      const dim = RubricDimension(
        dimensionId: 'dim-2',
        name: 'Completeness',
        description: 'Coverage measure',
        measurementMethod: 'llm-evaluation',
        measurementType: MeasurementType.categorical,
        minScore: 1.0,
        maxScore: 5.0,
        levels: [
          ScoreLevel(
            label: 'Low',
            minScore: 1.0,
            maxScore: 2.0,
            description: 'Low quality',
          ),
        ],
        evidenceTypes: ['document', 'citation'],
      );

      expect(dim.dimensionId, equals('dim-2'));
      expect(dim.measurementMethod, equals('llm-evaluation'));
      expect(dim.measurementType, equals(MeasurementType.categorical));
      expect(dim.minScore, equals(1.0));
      expect(dim.maxScore, equals(5.0));
      expect(dim.levels, hasLength(1));
      expect(dim.levels[0].label, equals('Low'));
      expect(dim.evidenceTypes, equals(['document', 'citation']));
    });

    test('fromJson with complete data', () {
      final json = {
        'dimensionId': 'dim-1',
        'name': 'Accuracy',
        'description': 'Factual correctness',
        'measurementMethod': 'automated',
        'measurementType': 'boolean',
        'minScore': 0.0,
        'maxScore': 1.0,
        'levels': [
          {
            'label': 'Pass',
            'minScore': 0.5,
            'maxScore': 1.0,
            'description': 'Passed',
          },
        ],
        'evidenceTypes': ['fact'],
      };
      final dim = RubricDimension.fromJson(json);

      expect(dim.dimensionId, equals('dim-1'));
      expect(dim.name, equals('Accuracy'));
      expect(dim.description, equals('Factual correctness'));
      expect(dim.measurementMethod, equals('automated'));
      expect(dim.measurementType, equals(MeasurementType.boolean));
      expect(dim.minScore, equals(0.0));
      expect(dim.maxScore, equals(1.0));
      expect(dim.levels, hasLength(1));
      expect(dim.levels[0].label, equals('Pass'));
      expect(dim.evidenceTypes, equals(['fact']));
    });

    test('fromJson with empty map uses defaults', () {
      final dim = RubricDimension.fromJson({});

      expect(dim.dimensionId, equals(''));
      expect(dim.name, equals(''));
      expect(dim.description, equals(''));
      expect(dim.measurementMethod, equals(''));
      expect(dim.measurementType, equals(MeasurementType.numeric));
      expect(dim.minScore, equals(0.0));
      expect(dim.maxScore, equals(1.0));
      expect(dim.levels, isEmpty);
      expect(dim.evidenceTypes, isEmpty);
    });

    test('fromJson with null fields uses defaults', () {
      final dim = RubricDimension.fromJson({
        'dimensionId': null,
        'name': null,
        'description': null,
        'measurementMethod': null,
        'measurementType': null,
        'minScore': null,
        'maxScore': null,
        'levels': null,
        'evidenceTypes': null,
      });

      expect(dim.dimensionId, equals(''));
      expect(dim.name, equals(''));
      expect(dim.measurementMethod, equals(''));
      expect(dim.measurementType, equals(MeasurementType.numeric));
      expect(dim.minScore, equals(0.0));
      expect(dim.maxScore, equals(1.0));
      expect(dim.levels, isEmpty);
      expect(dim.evidenceTypes, isEmpty);
    });

    test('toJson with populated fields', () {
      const dim = RubricDimension(
        dimensionId: 'dim-1',
        name: 'Accuracy',
        description: 'Factual accuracy',
        measurementMethod: 'llm-eval',
        measurementType: MeasurementType.numeric,
        minScore: 0.0,
        maxScore: 10.0,
        levels: [
          ScoreLevel(
            label: 'High',
            minScore: 8.0,
            maxScore: 10.0,
            description: 'High accuracy',
          ),
        ],
        evidenceTypes: ['citation'],
      );
      final json = dim.toJson();

      expect(json['dimensionId'], equals('dim-1'));
      expect(json['name'], equals('Accuracy'));
      expect(json['description'], equals('Factual accuracy'));
      expect(json['measurementMethod'], equals('llm-eval'));
      expect(json['measurementType'], equals('numeric'));
      expect(json['minScore'], equals(0.0));
      expect(json['maxScore'], equals(10.0));
      expect(json['levels'], isA<List>());
      expect((json['levels'] as List), hasLength(1));
      expect(json['evidenceTypes'], equals(['citation']));
    });

    test('toJson excludes empty optional fields', () {
      const dim = RubricDimension(
        dimensionId: 'dim-1',
        name: 'Accuracy',
        description: 'Test',
      );
      final json = dim.toJson();

      expect(json.containsKey('measurementMethod'), isFalse);
      expect(json.containsKey('levels'), isFalse);
      expect(json.containsKey('evidenceTypes'), isFalse);
      // Required fields are always present
      expect(json.containsKey('dimensionId'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('measurementType'), isTrue);
      expect(json.containsKey('minScore'), isTrue);
      expect(json.containsKey('maxScore'), isTrue);
    });
  });

  // =========================================================================
  // Rubric tests
  // =========================================================================
  group('Rubric', () {
    final fixedTime = DateTime(2024, 6, 15, 10, 0);
    final fixedUpdate = DateTime(2024, 6, 20, 12, 0);

    Rubric createFullRubric() {
      return Rubric(
        rubricId: 'rubric-1',
        workspaceId: 'ws-1',
        name: 'Quality Assessment',
        description: 'Assesses output quality',
        version: '2.0.0',
        dimensions: const [
          RubricDimension(
            dimensionId: 'dim-1',
            name: 'Accuracy',
            description: 'Factual accuracy',
            measurementType: MeasurementType.numeric,
          ),
          RubricDimension(
            dimensionId: 'dim-2',
            name: 'Relevance',
            description: 'Context relevance',
            measurementType: MeasurementType.categorical,
          ),
        ],
        weights: const {'dim-1': 0.6, 'dim-2': 0.4},
        thresholds: const {'pass': 0.7, 'excellent': 0.9},
        policyBinding: 'policy-v1',
        status: RubricStatus.active,
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
        metadata: const {'category': 'quality'},
      );
    }

    test('constructor with required fields only', () {
      final rubric = Rubric(
        rubricId: 'rubric-1',
        workspaceId: 'ws-1',
        name: 'Test Rubric',
        description: 'A test rubric',
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
      );

      expect(rubric.rubricId, equals('rubric-1'));
      expect(rubric.workspaceId, equals('ws-1'));
      expect(rubric.name, equals('Test Rubric'));
      expect(rubric.description, equals('A test rubric'));
      expect(rubric.version, equals('1.0.0'));
      expect(rubric.dimensions, isEmpty);
      expect(rubric.weights, isEmpty);
      expect(rubric.thresholds, isEmpty);
      expect(rubric.policyBinding, isNull);
      expect(rubric.status, equals(RubricStatus.active));
      expect(rubric.createdAt, equals(fixedTime));
      expect(rubric.updatedAt, equals(fixedUpdate));
      expect(rubric.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final rubric = createFullRubric();

      expect(rubric.rubricId, equals('rubric-1'));
      expect(rubric.workspaceId, equals('ws-1'));
      expect(rubric.name, equals('Quality Assessment'));
      expect(rubric.description, equals('Assesses output quality'));
      expect(rubric.version, equals('2.0.0'));
      expect(rubric.dimensions, hasLength(2));
      expect(rubric.weights, hasLength(2));
      expect(rubric.weights['dim-1'], equals(0.6));
      expect(rubric.thresholds['pass'], equals(0.7));
      expect(rubric.policyBinding, equals('policy-v1'));
      expect(rubric.status, equals(RubricStatus.active));
      expect(rubric.metadata['category'], equals('quality'));
    });

    test('fromJson with complete data', () {
      final json = {
        'rubricId': 'rubric-1',
        'workspaceId': 'ws-1',
        'name': 'Quality Assessment',
        'description': 'Assesses quality',
        'version': '2.0.0',
        'dimensions': [
          {
            'dimensionId': 'dim-1',
            'name': 'Accuracy',
            'description': 'Factual',
            'measurementType': 'numeric',
          },
        ],
        'weights': {'dim-1': 0.6},
        'thresholds': {'pass': 0.7},
        'policyBinding': 'policy-v1',
        'status': 'active',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-20T12:00:00.000',
        'metadata': {'key': 'val'},
      };
      final rubric = Rubric.fromJson(json);

      expect(rubric.rubricId, equals('rubric-1'));
      expect(rubric.workspaceId, equals('ws-1'));
      expect(rubric.name, equals('Quality Assessment'));
      expect(rubric.version, equals('2.0.0'));
      expect(rubric.dimensions, hasLength(1));
      expect(rubric.dimensions[0].dimensionId, equals('dim-1'));
      expect(rubric.weights['dim-1'], equals(0.6));
      expect(rubric.thresholds['pass'], equals(0.7));
      expect(rubric.policyBinding, equals('policy-v1'));
      expect(rubric.status, equals(RubricStatus.active));
      expect(rubric.createdAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(rubric.updatedAt, equals(DateTime(2024, 6, 20, 12, 0)));
      expect(rubric.metadata['key'], equals('val'));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final rubric = Rubric.fromJson({});
      final after = DateTime.now();

      expect(rubric.rubricId, equals(''));
      expect(rubric.workspaceId, equals('default'));
      expect(rubric.name, equals(''));
      expect(rubric.description, equals(''));
      expect(rubric.version, equals('1.0.0'));
      expect(rubric.dimensions, isEmpty);
      expect(rubric.weights, isEmpty);
      expect(rubric.thresholds, isEmpty);
      expect(rubric.policyBinding, isNull);
      expect(rubric.status, equals(RubricStatus.active));
      expect(rubric.metadata, isEmpty);
      expect(
        rubric.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        rubric.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('fromJson with null optional fields', () {
      final json = {
        'rubricId': 'r-1',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'policyBinding': null,
        'dimensions': null,
        'weights': null,
        'thresholds': null,
        'metadata': null,
        'status': null,
        'version': null,
      };
      final rubric = Rubric.fromJson(json);

      expect(rubric.rubricId, equals('r-1'));
      expect(rubric.policyBinding, isNull);
      expect(rubric.dimensions, isEmpty);
      expect(rubric.weights, isEmpty);
      expect(rubric.thresholds, isEmpty);
      expect(rubric.metadata, isEmpty);
    });

    test('toJson with fully populated rubric', () {
      final rubric = createFullRubric();
      final json = rubric.toJson();

      expect(json['rubricId'], equals('rubric-1'));
      expect(json['workspaceId'], equals('ws-1'));
      expect(json['name'], equals('Quality Assessment'));
      expect(json['description'], equals('Assesses output quality'));
      expect(json['version'], equals('2.0.0'));
      expect(json['dimensions'], isA<List>());
      expect((json['dimensions'] as List), hasLength(2));
      expect(json['weights'], equals({'dim-1': 0.6, 'dim-2': 0.4}));
      expect(json['thresholds'], equals({'pass': 0.7, 'excellent': 0.9}));
      expect(json['policyBinding'], equals('policy-v1'));
      expect(json['status'], equals('active'));
      expect(json['createdAt'], equals(fixedTime.toIso8601String()));
      expect(json['updatedAt'], equals(fixedUpdate.toIso8601String()));
      expect(json['metadata'], equals({'category': 'quality'}));
    });

    test('toJson excludes empty/null fields', () {
      final rubric = Rubric(
        rubricId: 'rubric-1',
        workspaceId: 'ws-1',
        name: 'Test',
        description: 'Test rubric',
        createdAt: fixedTime,
        updatedAt: fixedUpdate,
      );
      final json = rubric.toJson();

      expect(json.containsKey('dimensions'), isFalse);
      expect(json.containsKey('weights'), isFalse);
      expect(json.containsKey('thresholds'), isFalse);
      expect(json.containsKey('policyBinding'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Required fields are always present
      expect(json.containsKey('rubricId'), isTrue);
      expect(json.containsKey('status'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = createFullRubric();
      final newTime = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        rubricId: 'rubric-2',
        name: 'Updated Rubric',
        status: RubricStatus.deprecated,
        version: '3.0.0',
        updatedAt: newTime,
      );

      expect(copy.rubricId, equals('rubric-2'));
      expect(copy.name, equals('Updated Rubric'));
      expect(copy.status, equals(RubricStatus.deprecated));
      expect(copy.version, equals('3.0.0'));
      expect(copy.updatedAt, equals(newTime));
      // Unchanged
      expect(copy.workspaceId, equals('ws-1'));
      expect(copy.description, equals('Assesses output quality'));
      expect(copy.dimensions, hasLength(2));
      expect(copy.weights, equals(original.weights));
      expect(copy.thresholds, equals(original.thresholds));
      expect(copy.policyBinding, equals('policy-v1'));
      expect(copy.metadata, equals(original.metadata));
    });

    test('copyWith with no arguments returns equivalent rubric', () {
      final original = createFullRubric();
      final copy = original.copyWith();

      expect(copy.rubricId, equals(original.rubricId));
      expect(copy.name, equals(original.name));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = createFullRubric();
      final newTime = DateTime(2025, 3, 1);
      final copy = original.copyWith(
        rubricId: 'new-id',
        workspaceId: 'new-ws',
        name: 'New Name',
        description: 'New Desc',
        version: '9.0.0',
        dimensions: const [],
        weights: const {'x': 1.0},
        thresholds: const {'min': 0.1},
        policyBinding: 'new-policy',
        status: RubricStatus.draft,
        createdAt: newTime,
        updatedAt: newTime,
        metadata: const {'new': true},
      );

      expect(copy.rubricId, equals('new-id'));
      expect(copy.workspaceId, equals('new-ws'));
      expect(copy.name, equals('New Name'));
      expect(copy.description, equals('New Desc'));
      expect(copy.version, equals('9.0.0'));
      expect(copy.dimensions, isEmpty);
      expect(copy.weights, equals({'x': 1.0}));
      expect(copy.thresholds, equals({'min': 0.1}));
      expect(copy.policyBinding, equals('new-policy'));
      expect(copy.status, equals(RubricStatus.draft));
      expect(copy.createdAt, equals(newTime));
      expect(copy.updatedAt, equals(newTime));
      expect(copy.metadata, equals({'new': true}));
    });

    test('isActive getter', () {
      final active = Rubric(
        rubricId: 'r-1',
        workspaceId: 'ws-1',
        name: 'Active',
        description: 'desc',
        status: RubricStatus.active,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final draft = Rubric(
        rubricId: 'r-2',
        workspaceId: 'ws-1',
        name: 'Draft',
        description: 'desc',
        status: RubricStatus.draft,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final deprecated = Rubric(
        rubricId: 'r-3',
        workspaceId: 'ws-1',
        name: 'Deprecated',
        description: 'desc',
        status: RubricStatus.deprecated,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(active.isActive, isTrue);
      expect(draft.isActive, isFalse);
      expect(deprecated.isActive, isFalse);
    });

    test('hasDimensions getter', () {
      final withDims = createFullRubric();
      final noDims = Rubric(
        rubricId: 'r-1',
        workspaceId: 'ws-1',
        name: 'No Dims',
        description: 'desc',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(withDims.hasDimensions, isTrue);
      expect(noDims.hasDimensions, isFalse);
    });

    test('getDimension returns matching dimension', () {
      final rubric = createFullRubric();

      final dim = rubric.getDimension('dim-1');
      expect(dim, isNotNull);
      expect(dim!.dimensionId, equals('dim-1'));
      expect(dim.name, equals('Accuracy'));

      final dim2 = rubric.getDimension('dim-2');
      expect(dim2, isNotNull);
      expect(dim2!.name, equals('Relevance'));
    });

    test('getDimension returns null for non-existent dimension', () {
      final rubric = createFullRubric();
      final dim = rubric.getDimension('non-existent');

      expect(dim, isNull);
    });

    test('getDimension returns null when no dimensions exist', () {
      final rubric = Rubric(
        rubricId: 'r-1',
        workspaceId: 'ws-1',
        name: 'Empty',
        description: 'desc',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final dim = rubric.getDimension('dim-1');

      expect(dim, isNull);
    });

    test('dimensionsByMeasurementType returns filtered list', () {
      final rubric = createFullRubric();

      final numericDims =
          rubric.dimensionsByMeasurementType(MeasurementType.numeric);
      expect(numericDims, hasLength(1));
      expect(numericDims[0].name, equals('Accuracy'));

      final categoricalDims =
          rubric.dimensionsByMeasurementType(MeasurementType.categorical);
      expect(categoricalDims, hasLength(1));
      expect(categoricalDims[0].name, equals('Relevance'));

      final booleanDims =
          rubric.dimensionsByMeasurementType(MeasurementType.boolean);
      expect(booleanDims, isEmpty);
    });

    test('toString returns expected format', () {
      final rubric = createFullRubric();
      final str = rubric.toString();

      expect(str, contains('Rubric'));
      expect(str, contains('rubric-1'));
      expect(str, contains('Quality Assessment'));
    });

    test('equality compares by rubricId', () {
      final rubric1 = Rubric(
        rubricId: 'rubric-1',
        workspaceId: 'ws-1',
        name: 'A',
        description: 'desc A',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final rubric2 = Rubric(
        rubricId: 'rubric-1',
        workspaceId: 'ws-2',
        name: 'B',
        description: 'desc B',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final rubric3 = Rubric(
        rubricId: 'rubric-999',
        workspaceId: 'ws-1',
        name: 'A',
        description: 'desc A',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(rubric1 == rubric2, isTrue);
      expect(rubric1 == rubric3, isFalse);
      expect(rubric1.hashCode, equals(rubric2.hashCode));
    });

    test('fromJson roundtrip preserves data', () {
      final original = createFullRubric();
      final json = original.toJson();
      final restored = Rubric.fromJson(json);

      expect(restored.rubricId, equals(original.rubricId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.version, equals(original.version));
      expect(restored.dimensions, hasLength(original.dimensions.length));
      expect(restored.weights, equals(original.weights));
      expect(restored.thresholds, equals(original.thresholds));
      expect(restored.policyBinding, equals(original.policyBinding));
      expect(restored.status, equals(original.status));
    });

    test('Rubric constructor stores metadata field', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        metadata: const {'key': 'val'},
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(rubric.metadata, equals({'key': 'val'}));
    });

    test('Rubric constructor stores createdAt and updatedAt', () {
      final t1 = DateTime(2024, 3, 1);
      final t2 = DateTime(2024, 4, 1);
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: t1,
        updatedAt: t2,
      );
      expect(rubric.createdAt, equals(t1));
      expect(rubric.updatedAt, equals(t2));
    });

    test('fromJson with createdAt/updatedAt null uses DateTime.now()', () {
      final before = DateTime.now();
      final rubric = Rubric.fromJson({
        'rubricId': 'r',
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        rubric.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        rubric.updatedAt
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('toJson includes metadata when non-empty', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        metadata: const {'k': 'v'},
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final json = rubric.toJson();
      expect(json['metadata'], equals({'k': 'v'}));
    });

    test('Rubric copyWith each field individually', () {
      final base = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final newTime = DateTime(2025, 1, 1);

      expect(base.copyWith(rubricId: 'x').rubricId, equals('x'));
      expect(base.copyWith(workspaceId: 'x').workspaceId, equals('x'));
      expect(base.copyWith(name: 'x').name, equals('x'));
      expect(base.copyWith(description: 'x').description, equals('x'));
      expect(base.copyWith(version: 'x').version, equals('x'));
      expect(
        base.copyWith(dimensions: const [
          RubricDimension(
            dimensionId: 'd',
            name: 'n',
            description: 'desc',
          ),
        ]).dimensions.length,
        equals(1),
      );
      expect(
        base.copyWith(weights: const {'d': 1.0}).weights,
        equals({'d': 1.0}),
      );
      expect(
        base.copyWith(thresholds: const {'pass': 0.5}).thresholds,
        equals({'pass': 0.5}),
      );
      expect(
        base.copyWith(policyBinding: 'pol').policyBinding,
        equals('pol'),
      );
      expect(
        base.copyWith(status: RubricStatus.draft).status,
        equals(RubricStatus.draft),
      );
      expect(base.copyWith(createdAt: newTime).createdAt, equals(newTime));
      expect(base.copyWith(updatedAt: newTime).updatedAt, equals(newTime));
      expect(
        base.copyWith(metadata: const {'m': 1}).metadata,
        equals({'m': 1}),
      );
    });

    test('Rubric isActive for all statuses', () {
      for (final status in RubricStatus.values) {
        final rubric = Rubric(
          rubricId: 'r',
          workspaceId: 'ws',
          name: 'n',
          description: 'd',
          status: status,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        expect(rubric.isActive, equals(status == RubricStatus.active));
      }
    });

    test('Rubric hasDimensions returns false for empty', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(rubric.hasDimensions, isFalse);
    });

    test('Rubric getDimension with exact match', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        dimensions: const [
          RubricDimension(
            dimensionId: 'dim-a',
            name: 'DimA',
            description: 'desc A',
          ),
        ],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final dim = rubric.getDimension('dim-a');
      expect(dim, isNotNull);
      expect(dim!.name, equals('DimA'));
    });

    test('Rubric dimensionsByMeasurementType returns empty for no matches', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        dimensions: const [
          RubricDimension(
            dimensionId: 'd1',
            name: 'n',
            description: 'desc',
            measurementType: MeasurementType.numeric,
          ),
        ],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final result =
          rubric.dimensionsByMeasurementType(MeasurementType.boolean);
      expect(result, isEmpty);
    });

    test('Rubric equality with identical reference', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(rubric == rubric, isTrue);
    });

    test('Rubric equality with non-Rubric object', () {
      final rubric = Rubric(
        rubricId: 'r',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(rubric == Object(), isFalse);
    });

    test('Rubric hashCode is based on rubricId', () {
      final r1 = Rubric(
        rubricId: 'same',
        workspaceId: 'ws1',
        name: 'n1',
        description: 'd1',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final r2 = Rubric(
        rubricId: 'same',
        workspaceId: 'ws2',
        name: 'n2',
        description: 'd2',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('Rubric toString format', () {
      final rubric = Rubric(
        rubricId: 'r-id',
        workspaceId: 'ws',
        name: 'My Rubric',
        description: 'd',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(
        rubric.toString(),
        equals('Rubric(r-id, name: My Rubric)'),
      );
    });

    test('Rubric with all status values via fromJson', () {
      for (final status in RubricStatus.values) {
        final rubric = Rubric.fromJson({
          'rubricId': 'r',
          'status': status.name,
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        });
        expect(rubric.status, equals(status));
      }
    });
  });

  // =========================================================================
  // RubricStatus enum value coverage
  // =========================================================================
  group('RubricStatus enum values', () {
    test('all status values accessible by name', () {
      expect(RubricStatus.draft.name, equals('draft'));
      expect(RubricStatus.active.name, equals('active'));
      expect(RubricStatus.deprecated.name, equals('deprecated'));
    });

    test('fromString maps each value correctly', () {
      for (final status in RubricStatus.values) {
        expect(RubricStatus.fromString(status.name), equals(status));
      }
    });
  });

  // =========================================================================
  // MeasurementType enum value coverage
  // =========================================================================
  group('MeasurementType enum values', () {
    test('all values accessible by name', () {
      expect(MeasurementType.numeric.name, equals('numeric'));
      expect(MeasurementType.categorical.name, equals('categorical'));
      expect(MeasurementType.boolean.name, equals('boolean'));
    });

    test('fromString maps each value correctly', () {
      for (final mt in MeasurementType.values) {
        expect(MeasurementType.fromString(mt.name), equals(mt));
      }
    });
  });

  // =========================================================================
  // Additional RubricDimension coverage
  // =========================================================================
  group('RubricDimension additional coverage', () {
    test('RubricDimension field declarations fully covered', () {
      const dim = RubricDimension(
        dimensionId: 'dim-full',
        name: 'Full Dimension',
        description: 'Full description',
        measurementMethod: 'method',
        measurementType: MeasurementType.categorical,
        minScore: 1.0,
        maxScore: 10.0,
        levels: [
          ScoreLevel(
            label: 'High',
            minScore: 8.0,
            maxScore: 10.0,
            description: 'High level',
            indicators: ['ind1', 'ind2'],
          ),
        ],
        evidenceTypes: ['document', 'citation'],
      );

      expect(dim.dimensionId, equals('dim-full'));
      expect(dim.name, equals('Full Dimension'));
      expect(dim.description, equals('Full description'));
      expect(dim.measurementMethod, equals('method'));
      expect(dim.measurementType, equals(MeasurementType.categorical));
      expect(dim.minScore, equals(1.0));
      expect(dim.maxScore, equals(10.0));
      expect(dim.levels, hasLength(1));
      expect(dim.levels[0].label, equals('High'));
      expect(dim.levels[0].indicators, hasLength(2));
      expect(dim.evidenceTypes, equals(['document', 'citation']));
    });

    test('RubricDimension toJson with measurementMethod present', () {
      const dim = RubricDimension(
        dimensionId: 'd',
        name: 'n',
        description: 'desc',
        measurementMethod: 'auto',
      );
      final json = dim.toJson();
      expect(json['measurementMethod'], equals('auto'));
    });

    test('RubricDimension toJson with levels present', () {
      const dim = RubricDimension(
        dimensionId: 'd',
        name: 'n',
        description: 'desc',
        levels: [
          ScoreLevel(
            label: 'L',
            minScore: 0.0,
            maxScore: 1.0,
            description: 'd',
          ),
        ],
      );
      final json = dim.toJson();
      expect(json['levels'], isA<List>());
      expect((json['levels'] as List), hasLength(1));
    });

    test('RubricDimension toJson with evidenceTypes present', () {
      const dim = RubricDimension(
        dimensionId: 'd',
        name: 'n',
        description: 'desc',
        evidenceTypes: ['fact'],
      );
      final json = dim.toJson();
      expect(json['evidenceTypes'], equals(['fact']));
    });

    test('RubricDimension fromJson with all measurement types', () {
      for (final mt in MeasurementType.values) {
        final dim = RubricDimension.fromJson({
          'dimensionId': 'd',
          'name': 'n',
          'description': 'desc',
          'measurementType': mt.name,
        });
        expect(dim.measurementType, equals(mt));
      }
    });
  });

  // =========================================================================
  // Additional ScoreLevel coverage
  // =========================================================================
  group('ScoreLevel additional coverage', () {
    test('ScoreLevel field declarations fully covered', () {
      const level = ScoreLevel(
        label: 'Excellent',
        minScore: 0.9,
        maxScore: 1.0,
        description: 'Outstanding performance',
        indicators: ['ind1', 'ind2', 'ind3'],
      );

      expect(level.label, equals('Excellent'));
      expect(level.minScore, equals(0.9));
      expect(level.maxScore, equals(1.0));
      expect(level.description, equals('Outstanding performance'));
      expect(level.indicators, hasLength(3));
    });

    test('ScoreLevel fromJson with indicators present', () {
      final level = ScoreLevel.fromJson({
        'label': 'Good',
        'minScore': 0.5,
        'maxScore': 0.8,
        'description': 'Good level',
        'indicators': ['a', 'b'],
      });
      expect(level.indicators, equals(['a', 'b']));
    });

    test('ScoreLevel fromJson with indicators null', () {
      final level = ScoreLevel.fromJson({
        'label': 'Low',
        'minScore': 0.0,
        'maxScore': 0.5,
        'description': 'Low level',
        'indicators': null,
      });
      expect(level.indicators, isEmpty);
    });

    test('ScoreLevel toJson with indicators present', () {
      const level = ScoreLevel(
        label: 'High',
        minScore: 0.8,
        maxScore: 1.0,
        description: 'High',
        indicators: ['x', 'y'],
      );
      final json = level.toJson();
      expect(json['indicators'], equals(['x', 'y']));
    });

    test('ScoreLevel toJson without indicators', () {
      const level = ScoreLevel(
        label: 'Low',
        minScore: 0.0,
        maxScore: 0.5,
        description: 'Low',
      );
      final json = level.toJson();
      expect(json.containsKey('indicators'), isFalse);
    });
  });
}
