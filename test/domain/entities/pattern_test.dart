import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // PatternScope enum
  // =========================================================================
  group('PatternScope', () {
    test('has all expected values', () {
      expect(PatternScope.values, contains(PatternScope.person));
      expect(PatternScope.values, contains(PatternScope.team));
      expect(PatternScope.values, contains(PatternScope.project));
      expect(PatternScope.values, contains(PatternScope.global));
      expect(PatternScope.values.length, equals(4));
    });

    test('fromString returns correct value for all variants', () {
      expect(PatternScope.fromString('person'), equals(PatternScope.person));
      expect(PatternScope.fromString('team'), equals(PatternScope.team));
      expect(PatternScope.fromString('project'), equals(PatternScope.project));
      expect(PatternScope.fromString('global'), equals(PatternScope.global));
    });

    test('fromString returns person for invalid values', () {
      expect(PatternScope.fromString('unknown'), equals(PatternScope.person));
      expect(PatternScope.fromString(''), equals(PatternScope.person));
      expect(PatternScope.fromString('PERSON'), equals(PatternScope.person));
    });
  });

  // =========================================================================
  // PatternStatus enum
  // =========================================================================
  group('PatternStatus', () {
    test('has all expected values', () {
      expect(PatternStatus.values, contains(PatternStatus.observed));
      expect(PatternStatus.values, contains(PatternStatus.proposed));
      expect(PatternStatus.values, contains(PatternStatus.confirmed));
      expect(PatternStatus.values, contains(PatternStatus.rejected));
      expect(PatternStatus.values, contains(PatternStatus.merged));
      expect(PatternStatus.values, contains(PatternStatus.codified));
      expect(PatternStatus.values, contains(PatternStatus.deprecated));
      expect(PatternStatus.values, contains(PatternStatus.archived));
      expect(PatternStatus.values.length, equals(8));
    });

    test('fromString returns correct value for all variants', () {
      expect(
          PatternStatus.fromString('observed'), equals(PatternStatus.observed));
      expect(
          PatternStatus.fromString('proposed'), equals(PatternStatus.proposed));
      expect(PatternStatus.fromString('confirmed'),
          equals(PatternStatus.confirmed));
      expect(
          PatternStatus.fromString('rejected'), equals(PatternStatus.rejected));
      expect(PatternStatus.fromString('merged'), equals(PatternStatus.merged));
      expect(
          PatternStatus.fromString('codified'), equals(PatternStatus.codified));
      expect(PatternStatus.fromString('deprecated'),
          equals(PatternStatus.deprecated));
      expect(
          PatternStatus.fromString('archived'), equals(PatternStatus.archived));
    });

    test('fromString returns proposed for invalid values', () {
      expect(
          PatternStatus.fromString('unknown'), equals(PatternStatus.proposed));
      expect(PatternStatus.fromString(''), equals(PatternStatus.proposed));
      expect(PatternStatus.fromString('CONFIRMED'),
          equals(PatternStatus.proposed));
    });
  });

  // =========================================================================
  // Pattern entity
  // =========================================================================
  group('Pattern', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);

    test('constructor with required fields only', () {
      final pattern = Pattern(
        patternId: 'pat-1',
        workspaceId: 'ws-1',
        name: 'Morning Coffee',
        description: 'Daily morning coffee purchase',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(pattern.patternId, equals('pat-1'));
      expect(pattern.workspaceId, equals('ws-1'));
      expect(pattern.name, equals('Morning Coffee'));
      expect(pattern.description, equals('Daily morning coffee purchase'));
      expect(pattern.scope, equals(PatternScope.person));
      expect(pattern.features, isEmpty);
      expect(pattern.supportingFactIds, isEmpty);
      expect(pattern.evidenceRefs, isEmpty);
      expect(pattern.confidence, equals(0.0));
      expect(pattern.validFrom, isNull);
      expect(pattern.validTo, isNull);
      expect(pattern.lastObservedAt, equals(now));
      expect(pattern.status, equals(PatternStatus.proposed));
      expect(pattern.derivedFrom, isNull);
      expect(pattern.createdAt, equals(now));
      expect(pattern.updatedAt, equals(now));
      expect(pattern.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final validFrom = DateTime(2024, 1, 1);
      final validTo = DateTime(2024, 12, 31);

      final pattern = Pattern(
        patternId: 'pat-2',
        workspaceId: 'ws-2',
        name: 'Weekly Standup',
        description: 'Recurring team meeting pattern',
        scope: PatternScope.team,
        features: {'frequency': 'weekly', 'duration': 30},
        supportingFactIds: ['fact-1', 'fact-2'],
        evidenceRefs: ['ev-1', 'ev-2'],
        confidence: 0.95,
        validFrom: validFrom,
        validTo: validTo,
        lastObservedAt: now,
        status: PatternStatus.confirmed,
        derivedFrom: 'llm-suggestion-1',
        createdAt: now,
        updatedAt: later,
        metadata: {'source': 'auto-detection'},
      );

      expect(pattern.patternId, equals('pat-2'));
      expect(pattern.workspaceId, equals('ws-2'));
      expect(pattern.name, equals('Weekly Standup'));
      expect(pattern.description, equals('Recurring team meeting pattern'));
      expect(pattern.scope, equals(PatternScope.team));
      expect(pattern.features, equals({'frequency': 'weekly', 'duration': 30}));
      expect(pattern.supportingFactIds, equals(['fact-1', 'fact-2']));
      expect(pattern.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(pattern.confidence, equals(0.95));
      expect(pattern.validFrom, equals(validFrom));
      expect(pattern.validTo, equals(validTo));
      expect(pattern.lastObservedAt, equals(now));
      expect(pattern.status, equals(PatternStatus.confirmed));
      expect(pattern.derivedFrom, equals('llm-suggestion-1'));
      expect(pattern.createdAt, equals(now));
      expect(pattern.updatedAt, equals(later));
      expect(pattern.metadata, equals({'source': 'auto-detection'}));
    });

    test('fromJson complete', () {
      final json = {
        'patternId': 'pat-3',
        'workspaceId': 'ws-3',
        'name': 'Expense Pattern',
        'description': 'Recurring expense',
        'scope': 'global',
        'features': {'category': 'food'},
        'supportingFactIds': ['f-1', 'f-2'],
        'evidenceRefs': ['ev-1'],
        'confidence': 0.85,
        'validFrom': '2024-01-01T00:00:00.000',
        'validTo': '2024-12-31T23:59:59.000',
        'lastObservedAt': '2024-06-15T10:00:00.000',
        'status': 'codified',
        'derivedFrom': 'llm-1',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-07-15T10:00:00.000',
        'metadata': {'priority': 'high'},
      };

      final pattern = Pattern.fromJson(json);

      expect(pattern.patternId, equals('pat-3'));
      expect(pattern.workspaceId, equals('ws-3'));
      expect(pattern.name, equals('Expense Pattern'));
      expect(pattern.description, equals('Recurring expense'));
      expect(pattern.scope, equals(PatternScope.global));
      expect(pattern.features, equals({'category': 'food'}));
      expect(pattern.supportingFactIds, equals(['f-1', 'f-2']));
      expect(pattern.evidenceRefs, equals(['ev-1']));
      expect(pattern.confidence, equals(0.85));
      expect(pattern.validFrom, equals(DateTime.parse('2024-01-01T00:00:00.000')));
      expect(pattern.validTo, equals(DateTime.parse('2024-12-31T23:59:59.000')));
      expect(pattern.lastObservedAt, equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(pattern.status, equals(PatternStatus.codified));
      expect(pattern.derivedFrom, equals('llm-1'));
      expect(pattern.createdAt, equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(pattern.updatedAt, equals(DateTime.parse('2024-07-15T10:00:00.000')));
      expect(pattern.metadata, equals({'priority': 'high'}));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final pattern = Pattern.fromJson(json);

      expect(pattern.patternId, equals(''));
      expect(pattern.workspaceId, equals('default'));
      expect(pattern.name, equals(''));
      expect(pattern.description, equals(''));
      expect(pattern.scope, equals(PatternScope.person));
      expect(pattern.features, isEmpty);
      expect(pattern.supportingFactIds, isEmpty);
      expect(pattern.evidenceRefs, isEmpty);
      expect(pattern.confidence, equals(0.0));
      expect(pattern.validFrom, isNull);
      expect(pattern.validTo, isNull);
      expect(pattern.status, equals(PatternStatus.proposed));
      expect(pattern.derivedFrom, isNull);
      expect(pattern.metadata, isEmpty);
    });

    test('toJson populated', () {
      final validFrom = DateTime(2024, 1, 1);
      final validTo = DateTime(2024, 12, 31);

      final pattern = Pattern(
        patternId: 'pat-4',
        workspaceId: 'ws-4',
        name: 'Full Pattern',
        description: 'All fields populated',
        scope: PatternScope.project,
        features: {'key': 'value'},
        supportingFactIds: ['fact-1'],
        evidenceRefs: ['ev-1'],
        confidence: 0.75,
        validFrom: validFrom,
        validTo: validTo,
        lastObservedAt: now,
        status: PatternStatus.observed,
        derivedFrom: 'llm-2',
        createdAt: now,
        updatedAt: later,
        metadata: {'tag': 'test'},
      );

      final json = pattern.toJson();

      expect(json['patternId'], equals('pat-4'));
      expect(json['workspaceId'], equals('ws-4'));
      expect(json['name'], equals('Full Pattern'));
      expect(json['description'], equals('All fields populated'));
      expect(json['scope'], equals('project'));
      expect(json['features'], equals({'key': 'value'}));
      expect(json['supportingFactIds'], equals(['fact-1']));
      expect(json['evidenceRefs'], equals(['ev-1']));
      expect(json['confidence'], equals(0.75));
      expect(json['validFrom'], equals(validFrom.toIso8601String()));
      expect(json['validTo'], equals(validTo.toIso8601String()));
      expect(json['lastObservedAt'], equals(now.toIso8601String()));
      expect(json['status'], equals('observed'));
      expect(json['derivedFrom'], equals('llm-2'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(later.toIso8601String()));
      expect(json['metadata'], equals({'tag': 'test'}));
    });

    test('toJson excludes empty/null fields', () {
      final pattern = Pattern(
        patternId: 'pat-5',
        workspaceId: 'ws-5',
        name: 'Minimal',
        description: 'No optional fields',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = pattern.toJson();

      expect(json.containsKey('features'), isFalse);
      expect(json.containsKey('supportingFactIds'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('validFrom'), isFalse);
      expect(json.containsKey('validTo'), isFalse);
      expect(json.containsKey('derivedFrom'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // These should always be present
      expect(json.containsKey('patternId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('scope'), isTrue);
      expect(json.containsKey('confidence'), isTrue);
      expect(json.containsKey('lastObservedAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = Pattern(
        patternId: 'pat-6',
        workspaceId: 'ws-6',
        name: 'Original Name',
        description: 'Original Description',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final newValidFrom = DateTime(2024, 3, 1);
      final newValidTo = DateTime(2024, 9, 1);

      final copy = original.copyWith(
        name: 'New Name',
        description: 'New Description',
        scope: PatternScope.global,
        features: {'updated': true},
        supportingFactIds: ['new-fact-1'],
        evidenceRefs: ['new-ev-1'],
        confidence: 0.99,
        validFrom: newValidFrom,
        validTo: newValidTo,
        status: PatternStatus.confirmed,
        derivedFrom: 'new-llm',
        metadata: {'changed': true},
      );

      // Unchanged fields
      expect(copy.patternId, equals('pat-6'));
      expect(copy.workspaceId, equals('ws-6'));
      expect(copy.lastObservedAt, equals(now));
      expect(copy.createdAt, equals(now));
      expect(copy.updatedAt, equals(now));

      // Changed fields
      expect(copy.name, equals('New Name'));
      expect(copy.description, equals('New Description'));
      expect(copy.scope, equals(PatternScope.global));
      expect(copy.features, equals({'updated': true}));
      expect(copy.supportingFactIds, equals(['new-fact-1']));
      expect(copy.evidenceRefs, equals(['new-ev-1']));
      expect(copy.confidence, equals(0.99));
      expect(copy.validFrom, equals(newValidFrom));
      expect(copy.validTo, equals(newValidTo));
      expect(copy.status, equals(PatternStatus.confirmed));
      expect(copy.derivedFrom, equals('new-llm'));
      expect(copy.metadata, equals({'changed': true}));
    });

    test('copyWith with no arguments returns equivalent pattern', () {
      final original = Pattern(
        patternId: 'pat-7',
        workspaceId: 'ws-7',
        name: 'No Change',
        description: 'Same pattern',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.patternId, equals(original.patternId));
      expect(copy.name, equals(original.name));
      expect(copy.description, equals(original.description));
      expect(copy.scope, equals(original.scope));
      expect(copy.confidence, equals(original.confidence));
    });

    test('isActive getter returns true only for confirmed status', () {
      final confirmedPattern = Pattern(
        patternId: 'pat-active',
        workspaceId: 'ws-1',
        name: 'Confirmed',
        description: 'Active pattern',
        status: PatternStatus.confirmed,
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final proposedPattern = Pattern(
        patternId: 'pat-inactive',
        workspaceId: 'ws-1',
        name: 'Proposed',
        description: 'Inactive pattern',
        status: PatternStatus.proposed,
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final observedPattern = Pattern(
        patternId: 'pat-inactive2',
        workspaceId: 'ws-1',
        name: 'Observed',
        description: 'Also inactive pattern',
        status: PatternStatus.observed,
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(confirmedPattern.isActive, isTrue);
      expect(proposedPattern.isActive, isFalse);
      expect(observedPattern.isActive, isFalse);
    });

    test('isHighConfidence getter checks confidence >= 0.8', () {
      Pattern makePattern(double confidence) => Pattern(
            patternId: 'pat-conf',
            workspaceId: 'ws-1',
            name: 'Conf Test',
            description: 'Confidence test',
            confidence: confidence,
            lastObservedAt: now,
            createdAt: now,
            updatedAt: now,
          );

      expect(makePattern(0.8).isHighConfidence, isTrue);
      expect(makePattern(0.9).isHighConfidence, isTrue);
      expect(makePattern(1.0).isHighConfidence, isTrue);
      expect(makePattern(0.79).isHighConfidence, isFalse);
      expect(makePattern(0.0).isHighConfidence, isFalse);
    });

    test('toString returns expected format', () {
      final pattern = Pattern(
        patternId: 'pat-str',
        workspaceId: 'ws-1',
        name: 'ToString Test',
        description: 'Testing toString',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final str = pattern.toString();
      expect(str, equals('Pattern(pat-str, name: ToString Test)'));
    });

    test('equality compares by patternId', () {
      final pattern1 = Pattern(
        patternId: 'pat-eq',
        workspaceId: 'ws-1',
        name: 'Pattern A',
        description: 'First',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final pattern2 = Pattern(
        patternId: 'pat-eq',
        workspaceId: 'ws-2',
        name: 'Pattern B',
        description: 'Second',
        lastObservedAt: later,
        createdAt: later,
        updatedAt: later,
      );

      final pattern3 = Pattern(
        patternId: 'pat-different',
        workspaceId: 'ws-1',
        name: 'Pattern A',
        description: 'First',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(pattern1 == pattern2, isTrue);
      expect(pattern1 == pattern3, isFalse);
      expect(pattern1.hashCode, equals(pattern2.hashCode));
      expect(pattern1.hashCode, isNot(equals(pattern3.hashCode)));
    });

    test('equality with identical reference', () {
      final pattern = Pattern(
        patternId: 'pat-id',
        workspaceId: 'ws-1',
        name: 'Self',
        description: 'Identical test',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(pattern == pattern, isTrue);
    });

    test('equality with non-Pattern object', () {
      final pattern = Pattern(
        patternId: 'pat-id',
        workspaceId: 'ws-1',
        name: 'Type check',
        description: 'Non-pattern comparison',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(pattern == Object(), isFalse);
    });

    test('fromJson then toJson roundtrip', () {
      final json = {
        'patternId': 'pat-rt',
        'workspaceId': 'ws-rt',
        'name': 'Roundtrip',
        'description': 'Test roundtrip',
        'scope': 'team',
        'features': {'key': 'value'},
        'supportingFactIds': ['f-1'],
        'evidenceRefs': ['e-1'],
        'confidence': 0.75,
        'validFrom': '2024-01-01T00:00:00.000',
        'validTo': '2024-12-31T00:00:00.000',
        'lastObservedAt': '2024-06-15T10:00:00.000',
        'status': 'confirmed',
        'derivedFrom': 'llm-x',
        'createdAt': '2024-06-01T00:00:00.000',
        'updatedAt': '2024-06-15T00:00:00.000',
        'metadata': {'round': 'trip'},
      };

      final pattern = Pattern.fromJson(json);
      final result = pattern.toJson();

      expect(result['patternId'], equals(json['patternId']));
      expect(result['workspaceId'], equals(json['workspaceId']));
      expect(result['name'], equals(json['name']));
      expect(result['scope'], equals(json['scope']));
      expect(result['features'], equals(json['features']));
      expect(result['confidence'], equals(json['confidence']));
      expect(result['status'], equals(json['status']));
      expect(result['derivedFrom'], equals(json['derivedFrom']));
    });

    test('fromJson with null dates uses DateTime.now()', () {
      final before = DateTime.now();
      final pattern = Pattern.fromJson({
        'patternId': 'p',
        'lastObservedAt': null,
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        pattern.lastObservedAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        pattern.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        pattern.updatedAt
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('Pattern constructor stores createdAt field', () {
      final t = DateTime(2024, 3, 15);
      final pattern = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        lastObservedAt: t,
        createdAt: t,
        updatedAt: t,
      );
      expect(pattern.createdAt, equals(t));
    });

    test('fromJson with validFrom and validTo present', () {
      final pattern = Pattern.fromJson({
        'patternId': 'p',
        'validFrom': '2024-01-01T00:00:00.000',
        'validTo': '2024-12-31T00:00:00.000',
        'lastObservedAt': '2024-06-15T00:00:00.000',
        'createdAt': '2024-06-15T00:00:00.000',
        'updatedAt': '2024-06-15T00:00:00.000',
      });

      expect(pattern.validFrom, equals(DateTime(2024, 1, 1)));
      expect(pattern.validTo, equals(DateTime(2024, 12, 31)));
    });

    test('fromJson with validFrom and validTo null', () {
      final pattern = Pattern.fromJson({
        'patternId': 'p',
        'validFrom': null,
        'validTo': null,
        'lastObservedAt': '2024-06-15T00:00:00.000',
        'createdAt': '2024-06-15T00:00:00.000',
        'updatedAt': '2024-06-15T00:00:00.000',
      });

      expect(pattern.validFrom, isNull);
      expect(pattern.validTo, isNull);
    });

    test('toJson validFrom and validTo serialized when present', () {
      final validFrom = DateTime(2024, 1, 1);
      final validTo = DateTime(2024, 12, 31);
      final pattern = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        validFrom: validFrom,
        validTo: validTo,
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = pattern.toJson();
      expect(json['validFrom'], equals(validFrom.toIso8601String()));
      expect(json['validTo'], equals(validTo.toIso8601String()));
    });

    test('toJson derivedFrom present when set', () {
      final pattern = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        derivedFrom: 'llm-1',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = pattern.toJson();
      expect(json['derivedFrom'], equals('llm-1'));
    });

    test('toJson metadata present when non-empty', () {
      final pattern = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        metadata: const {'key': 'val'},
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = pattern.toJson();
      expect(json['metadata'], equals({'key': 'val'}));
    });

    test('copyWith each field individually', () {
      final base = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final newTime = DateTime(2025, 1, 1);

      expect(base.copyWith(patternId: 'x').patternId, equals('x'));
      expect(base.copyWith(workspaceId: 'x').workspaceId, equals('x'));
      expect(base.copyWith(name: 'x').name, equals('x'));
      expect(base.copyWith(description: 'x').description, equals('x'));
      expect(
        base.copyWith(scope: PatternScope.global).scope,
        equals(PatternScope.global),
      );
      expect(
        base.copyWith(features: const {'a': 1}).features,
        equals({'a': 1}),
      );
      expect(
        base.copyWith(supportingFactIds: const ['f1']).supportingFactIds,
        equals(['f1']),
      );
      expect(
        base.copyWith(evidenceRefs: const ['e1']).evidenceRefs,
        equals(['e1']),
      );
      expect(base.copyWith(confidence: 0.99).confidence, equals(0.99));
      expect(
        base.copyWith(validFrom: newTime).validFrom,
        equals(newTime),
      );
      expect(
        base.copyWith(validTo: newTime).validTo,
        equals(newTime),
      );
      expect(
        base.copyWith(lastObservedAt: newTime).lastObservedAt,
        equals(newTime),
      );
      expect(
        base.copyWith(status: PatternStatus.archived).status,
        equals(PatternStatus.archived),
      );
      expect(
        base.copyWith(derivedFrom: 'x').derivedFrom,
        equals('x'),
      );
      expect(
        base.copyWith(createdAt: newTime).createdAt,
        equals(newTime),
      );
      expect(
        base.copyWith(updatedAt: newTime).updatedAt,
        equals(newTime),
      );
      expect(
        base.copyWith(metadata: const {'m': 1}).metadata,
        equals({'m': 1}),
      );
    });

    test('copyWith all fields at once', () {
      final base = Pattern(
        patternId: 'p',
        workspaceId: 'ws',
        name: 'n',
        description: 'd',
        lastObservedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final newTime = DateTime(2025, 6, 1);

      final copy = base.copyWith(
        patternId: 'new-p',
        workspaceId: 'new-ws',
        name: 'new-n',
        description: 'new-d',
        scope: PatternScope.team,
        features: const {'x': 1},
        supportingFactIds: const ['f'],
        evidenceRefs: const ['e'],
        confidence: 0.5,
        validFrom: newTime,
        validTo: newTime,
        lastObservedAt: newTime,
        status: PatternStatus.merged,
        derivedFrom: 'llm',
        createdAt: newTime,
        updatedAt: newTime,
        metadata: const {'m': true},
      );

      expect(copy.patternId, equals('new-p'));
      expect(copy.workspaceId, equals('new-ws'));
      expect(copy.name, equals('new-n'));
      expect(copy.description, equals('new-d'));
      expect(copy.scope, equals(PatternScope.team));
      expect(copy.features, equals({'x': 1}));
      expect(copy.supportingFactIds, equals(['f']));
      expect(copy.evidenceRefs, equals(['e']));
      expect(copy.confidence, equals(0.5));
      expect(copy.validFrom, equals(newTime));
      expect(copy.validTo, equals(newTime));
      expect(copy.lastObservedAt, equals(newTime));
      expect(copy.status, equals(PatternStatus.merged));
      expect(copy.derivedFrom, equals('llm'));
      expect(copy.createdAt, equals(newTime));
      expect(copy.updatedAt, equals(newTime));
      expect(copy.metadata, equals({'m': true}));
    });

    test('Pattern with all status values via fromJson', () {
      for (final status in PatternStatus.values) {
        final pattern = Pattern.fromJson({
          'patternId': 'p',
          'status': status.name,
          'lastObservedAt': '2024-01-01T00:00:00.000',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        });
        expect(pattern.status, equals(status));
      }
    });

    test('Pattern with all scope values via fromJson', () {
      for (final scope in PatternScope.values) {
        final pattern = Pattern.fromJson({
          'patternId': 'p',
          'scope': scope.name,
          'lastObservedAt': '2024-01-01T00:00:00.000',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        });
        expect(pattern.scope, equals(scope));
      }
    });
  });

  // =========================================================================
  // PatternStatus enum value coverage
  // =========================================================================
  group('PatternStatus enum values', () {
    test('all status values accessible by name', () {
      expect(PatternStatus.observed.name, equals('observed'));
      expect(PatternStatus.proposed.name, equals('proposed'));
      expect(PatternStatus.confirmed.name, equals('confirmed'));
      expect(PatternStatus.rejected.name, equals('rejected'));
      expect(PatternStatus.merged.name, equals('merged'));
      expect(PatternStatus.codified.name, equals('codified'));
      expect(PatternStatus.deprecated.name, equals('deprecated'));
      expect(PatternStatus.archived.name, equals('archived'));
    });

    test('fromString maps each value correctly', () {
      for (final status in PatternStatus.values) {
        expect(PatternStatus.fromString(status.name), equals(status));
      }
    });
  });

  // =========================================================================
  // PatternScope enum value coverage
  // =========================================================================
  group('PatternScope enum values', () {
    test('all scope values accessible by name', () {
      expect(PatternScope.person.name, equals('person'));
      expect(PatternScope.team.name, equals('team'));
      expect(PatternScope.project.name, equals('project'));
      expect(PatternScope.global.name, equals('global'));
    });

    test('fromString maps each value correctly', () {
      for (final scope in PatternScope.values) {
        expect(PatternScope.fromString(scope.name), equals(scope));
      }
    });
  });
}
