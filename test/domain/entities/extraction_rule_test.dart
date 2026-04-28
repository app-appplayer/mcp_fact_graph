import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('RuleType', () {
    test('fromString valid values', () {
      expect(RuleType.fromString('regex'), equals(RuleType.regex));
      expect(RuleType.fromString('parser'), equals(RuleType.parser));
      expect(RuleType.fromString('template'), equals(RuleType.template));
      expect(RuleType.fromString('ocrregion'), equals(RuleType.ocrRegion));
      expect(RuleType.fromString('ocr_region'), equals(RuleType.ocrRegion));
      expect(RuleType.fromString('dictionary'), equals(RuleType.dictionary));
    });

    test('fromString is case-insensitive', () {
      expect(RuleType.fromString('REGEX'), equals(RuleType.regex));
      expect(RuleType.fromString('Parser'), equals(RuleType.parser));
      expect(RuleType.fromString('TEMPLATE'), equals(RuleType.template));
      expect(RuleType.fromString('OcrRegion'), equals(RuleType.ocrRegion));
      expect(RuleType.fromString('OCR_REGION'), equals(RuleType.ocrRegion));
      expect(RuleType.fromString('DICTIONARY'), equals(RuleType.dictionary));
    });

    test('fromString returns regex for invalid values', () {
      expect(RuleType.fromString('unknown'), equals(RuleType.regex));
      expect(RuleType.fromString(''), equals(RuleType.regex));
      expect(RuleType.fromString('invalid'), equals(RuleType.regex));
    });
  });

  group('RuleStatus', () {
    test('fromString valid values', () {
      expect(RuleStatus.fromString('active'), equals(RuleStatus.active));
      expect(RuleStatus.fromString('disabled'), equals(RuleStatus.disabled));
      expect(
        RuleStatus.fromString('deprecated'),
        equals(RuleStatus.deprecated),
      );
    });

    test('fromString is case-insensitive', () {
      expect(RuleStatus.fromString('ACTIVE'), equals(RuleStatus.active));
      expect(RuleStatus.fromString('Disabled'), equals(RuleStatus.disabled));
      expect(
        RuleStatus.fromString('DEPRECATED'),
        equals(RuleStatus.deprecated),
      );
    });

    test('fromString returns active for invalid values', () {
      expect(RuleStatus.fromString('unknown'), equals(RuleStatus.active));
      expect(RuleStatus.fromString(''), equals(RuleStatus.active));
    });
  });

  group('ExtractionRule', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 12, 0);

    test('constructor with required fields', () {
      final rule = ExtractionRule(
        ruleId: 'rule-1',
        name: 'Amount Extractor',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\$[\d,]+\.?\d*',
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.ruleId, equals('rule-1'));
      expect(rule.name, equals('Amount Extractor'));
      expect(rule.description, isNull);
      expect(rule.sourceType, equals('text'));
      expect(rule.targetField, equals('amount'));
      expect(rule.ruleType, equals(RuleType.regex));
      expect(rule.pattern, equals(r'\$[\d,]+\.?\d*'));
      expect(rule.config, isNull);
      expect(rule.accuracy, equals(0.0));
      expect(rule.usageCount, equals(0));
      expect(rule.failureCount, equals(0));
      expect(rule.status, equals(RuleStatus.active));
      expect(rule.derivedFrom, isNull);
      expect(rule.sampleEvidenceIds, isEmpty);
      expect(rule.workspaceId, isNull);
      expect(rule.createdAt, equals(now));
      expect(rule.updatedAt, equals(now));
    });

    test('constructor with all fields', () {
      final rule = ExtractionRule(
        ruleId: 'rule-2',
        name: 'Date Extractor',
        description: 'Extracts dates from receipts',
        sourceType: 'image',
        targetField: 'date',
        ruleType: RuleType.ocrRegion,
        pattern: r'\d{4}-\d{2}-\d{2}',
        config: {'region': 'top-right', 'dpi': 300},
        accuracy: 0.95,
        usageCount: 100,
        failureCount: 5,
        status: RuleStatus.active,
        derivedFrom: 'llm-suggestion-1',
        sampleEvidenceIds: ['ev-1', 'ev-2'],
        workspaceId: 'ws-1',
        createdAt: now,
        updatedAt: later,
      );

      expect(rule.ruleId, equals('rule-2'));
      expect(rule.name, equals('Date Extractor'));
      expect(rule.description, equals('Extracts dates from receipts'));
      expect(rule.sourceType, equals('image'));
      expect(rule.targetField, equals('date'));
      expect(rule.ruleType, equals(RuleType.ocrRegion));
      expect(rule.pattern, equals(r'\d{4}-\d{2}-\d{2}'));
      expect(rule.config, equals({'region': 'top-right', 'dpi': 300}));
      expect(rule.accuracy, equals(0.95));
      expect(rule.usageCount, equals(100));
      expect(rule.failureCount, equals(5));
      expect(rule.status, equals(RuleStatus.active));
      expect(rule.derivedFrom, equals('llm-suggestion-1'));
      expect(rule.sampleEvidenceIds, equals(['ev-1', 'ev-2']));
      expect(rule.workspaceId, equals('ws-1'));
      expect(rule.createdAt, equals(now));
      expect(rule.updatedAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'ruleId': 'rule-3',
        'name': 'Merchant Extractor',
        'description': 'Extracts merchant names',
        'sourceType': 'text',
        'targetField': 'merchant',
        'ruleType': 'template',
        'pattern': 'Merchant: {name}',
        'config': {'caseSensitive': false},
        'accuracy': 0.88,
        'usageCount': 50,
        'failureCount': 7,
        'status': 'disabled',
        'derivedFrom': 'llm-2',
        'sampleEvidenceIds': ['ev-3', 'ev-4'],
        'workspaceId': 'ws-2',
        'createdAt': '2024-01-15T10:30:00.000',
        'updatedAt': '2024-01-16T12:00:00.000',
      };

      final rule = ExtractionRule.fromJson(json);

      expect(rule.ruleId, equals('rule-3'));
      expect(rule.name, equals('Merchant Extractor'));
      expect(rule.description, equals('Extracts merchant names'));
      expect(rule.sourceType, equals('text'));
      expect(rule.targetField, equals('merchant'));
      expect(rule.ruleType, equals(RuleType.template));
      expect(rule.pattern, equals('Merchant: {name}'));
      expect(rule.config, equals({'caseSensitive': false}));
      expect(rule.accuracy, equals(0.88));
      expect(rule.usageCount, equals(50));
      expect(rule.failureCount, equals(7));
      expect(rule.status, equals(RuleStatus.disabled));
      expect(rule.derivedFrom, equals('llm-2'));
      expect(rule.sampleEvidenceIds, equals(['ev-3', 'ev-4']));
      expect(rule.workspaceId, equals('ws-2'));
      expect(
        rule.createdAt,
        equals(DateTime.parse('2024-01-15T10:30:00.000')),
      );
      expect(
        rule.updatedAt,
        equals(DateTime.parse('2024-01-16T12:00:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final rule = ExtractionRule.fromJson({});

      expect(rule.ruleId, equals(''));
      expect(rule.name, equals(''));
      expect(rule.description, isNull);
      expect(rule.sourceType, equals('text'));
      expect(rule.targetField, equals(''));
      expect(rule.ruleType, equals(RuleType.regex));
      expect(rule.pattern, equals(''));
      expect(rule.config, isNull);
      expect(rule.accuracy, equals(0.0));
      expect(rule.usageCount, equals(0));
      expect(rule.failureCount, equals(0));
      expect(rule.status, equals(RuleStatus.active));
      expect(rule.derivedFrom, isNull);
      expect(rule.sampleEvidenceIds, isEmpty);
      expect(rule.workspaceId, isNull);
      expect(rule.createdAt, isA<DateTime>());
      expect(rule.updatedAt, isA<DateTime>());
    });

    test('fromJson with null dates defaults to now', () {
      final before = DateTime.now();
      final rule = ExtractionRule.fromJson({
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        rule.createdAt.isAfter(before) ||
            rule.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        rule.createdAt.isBefore(after) ||
            rule.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('toJson populated', () {
      final rule = ExtractionRule(
        ruleId: 'rule-4',
        name: 'Category Extractor',
        description: 'Extracts categories',
        sourceType: 'file',
        targetField: 'category',
        ruleType: RuleType.dictionary,
        pattern: 'lookup:categories',
        config: {'dictFile': 'cats.json'},
        accuracy: 0.92,
        usageCount: 200,
        failureCount: 18,
        status: RuleStatus.deprecated,
        derivedFrom: 'llm-3',
        sampleEvidenceIds: ['ev-5'],
        workspaceId: 'ws-3',
        createdAt: now,
        updatedAt: later,
      );

      final json = rule.toJson();

      expect(json['ruleId'], equals('rule-4'));
      expect(json['name'], equals('Category Extractor'));
      expect(json['description'], equals('Extracts categories'));
      expect(json['sourceType'], equals('file'));
      expect(json['targetField'], equals('category'));
      expect(json['ruleType'], equals('dictionary'));
      expect(json['pattern'], equals('lookup:categories'));
      expect(json['config'], equals({'dictFile': 'cats.json'}));
      expect(json['accuracy'], equals(0.92));
      expect(json['usageCount'], equals(200));
      expect(json['failureCount'], equals(18));
      expect(json['status'], equals('deprecated'));
      expect(json['derivedFrom'], equals('llm-3'));
      expect(json['sampleEvidenceIds'], equals(['ev-5']));
      expect(json['workspaceId'], equals('ws-3'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final rule = ExtractionRule(
        ruleId: 'rule-5',
        name: 'Simple Rule',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        createdAt: now,
        updatedAt: now,
      );

      final json = rule.toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('config'), isFalse);
      expect(json.containsKey('derivedFrom'), isFalse);
      expect(json.containsKey('sampleEvidenceIds'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // Always-present fields
      expect(json.containsKey('ruleId'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('sourceType'), isTrue);
      expect(json.containsKey('targetField'), isTrue);
      expect(json.containsKey('ruleType'), isTrue);
      expect(json.containsKey('pattern'), isTrue);
      expect(json.containsKey('accuracy'), isTrue);
      expect(json.containsKey('usageCount'), isTrue);
      expect(json.containsKey('failureCount'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final original = ExtractionRule(
        ruleId: 'rule-6',
        name: 'Original',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(
        ruleId: 'rule-7',
        name: 'Modified',
        description: 'A description',
        sourceType: 'image',
        targetField: 'date',
        ruleType: RuleType.parser,
        pattern: r'\d{4}-\d{2}-\d{2}',
        config: {'x': 1},
        accuracy: 0.99,
        usageCount: 50,
        failureCount: 2,
        status: RuleStatus.disabled,
        derivedFrom: 'llm-x',
        sampleEvidenceIds: ['ev-a'],
        workspaceId: 'ws-x',
        createdAt: later,
        updatedAt: later,
      );

      expect(modified.ruleId, equals('rule-7'));
      expect(modified.name, equals('Modified'));
      expect(modified.description, equals('A description'));
      expect(modified.sourceType, equals('image'));
      expect(modified.targetField, equals('date'));
      expect(modified.ruleType, equals(RuleType.parser));
      expect(modified.pattern, equals(r'\d{4}-\d{2}-\d{2}'));
      expect(modified.config, equals({'x': 1}));
      expect(modified.accuracy, equals(0.99));
      expect(modified.usageCount, equals(50));
      expect(modified.failureCount, equals(2));
      expect(modified.status, equals(RuleStatus.disabled));
      expect(modified.derivedFrom, equals('llm-x'));
      expect(modified.sampleEvidenceIds, equals(['ev-a']));
      expect(modified.workspaceId, equals('ws-x'));
      expect(modified.createdAt, equals(later));
      expect(modified.updatedAt, equals(later));

      // Original unchanged
      expect(original.ruleId, equals('rule-6'));
      expect(original.name, equals('Original'));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = ExtractionRule(
        ruleId: 'rule-8',
        name: 'Unchanged',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.ruleId, equals(original.ruleId));
      expect(copy.name, equals(original.name));
      expect(copy.description, equals(original.description));
      expect(copy.sourceType, equals(original.sourceType));
      expect(copy.targetField, equals(original.targetField));
      expect(copy.ruleType, equals(original.ruleType));
      expect(copy.pattern, equals(original.pattern));
      expect(copy.config, equals(original.config));
      expect(copy.accuracy, equals(original.accuracy));
      expect(copy.usageCount, equals(original.usageCount));
      expect(copy.failureCount, equals(original.failureCount));
      expect(copy.status, equals(original.status));
      expect(copy.derivedFrom, equals(original.derivedFrom));
      expect(copy.sampleEvidenceIds, equals(original.sampleEvidenceIds));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('isActive getter', () {
      final activeRule = ExtractionRule(
        ruleId: 'rule-9',
        name: 'Active',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        status: RuleStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      expect(activeRule.isActive, isTrue);

      final disabledRule = activeRule.copyWith(status: RuleStatus.disabled);
      expect(disabledRule.isActive, isFalse);

      final deprecatedRule = activeRule.copyWith(status: RuleStatus.deprecated);
      expect(deprecatedRule.isActive, isFalse);
    });

    test('isHighAccuracy getter', () {
      final highAccuracy = ExtractionRule(
        ruleId: 'rule-10',
        name: 'High',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        accuracy: 0.9,
        createdAt: now,
        updatedAt: now,
      );
      expect(highAccuracy.isHighAccuracy, isTrue);

      final aboveThreshold = highAccuracy.copyWith(accuracy: 0.95);
      expect(aboveThreshold.isHighAccuracy, isTrue);

      final belowThreshold = highAccuracy.copyWith(accuracy: 0.89);
      expect(belowThreshold.isHighAccuracy, isFalse);
    });

    test('totalAttempts getter', () {
      final rule = ExtractionRule(
        ruleId: 'rule-11',
        name: 'Total',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        usageCount: 80,
        failureCount: 20,
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.totalAttempts, equals(100));
    });

    test('successRate getter', () {
      // With attempts
      final rule = ExtractionRule(
        ruleId: 'rule-12',
        name: 'Rate',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        usageCount: 80,
        failureCount: 20,
        createdAt: now,
        updatedAt: now,
      );
      expect(rule.successRate, equals(0.8));

      // With zero attempts
      final zeroRule = ExtractionRule(
        ruleId: 'rule-13',
        name: 'Zero',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        usageCount: 0,
        failureCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      expect(zeroRule.successRate, equals(0.0));
    });

    test('recordSuccess updates counts and accuracy', () {
      final rule = ExtractionRule(
        ruleId: 'rule-14',
        name: 'Success',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        usageCount: 9,
        failureCount: 1,
        accuracy: 0.9,
        createdAt: now,
        updatedAt: now,
      );

      final updated = rule.recordSuccess();

      expect(updated.usageCount, equals(10));
      expect(updated.failureCount, equals(1));
      // New accuracy: 10 / (10+1) = 10/11
      expect(updated.accuracy, closeTo(10 / 11, 0.001));
      // updatedAt should be updated
      expect(updated.updatedAt.isAfter(now) || updated.updatedAt.isAtSameMomentAs(now), isTrue);
    });

    test('recordSuccess from zero counts', () {
      final rule = ExtractionRule(
        ruleId: 'rule-14b',
        name: 'FromZero',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        createdAt: now,
        updatedAt: now,
      );

      final updated = rule.recordSuccess();

      expect(updated.usageCount, equals(1));
      expect(updated.failureCount, equals(0));
      expect(updated.accuracy, equals(1.0));
    });

    test('recordFailure updates counts and accuracy', () {
      final rule = ExtractionRule(
        ruleId: 'rule-15',
        name: 'Failure',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        usageCount: 9,
        failureCount: 0,
        accuracy: 1.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = rule.recordFailure();

      expect(updated.usageCount, equals(9));
      expect(updated.failureCount, equals(1));
      // New accuracy: 9 / (9+1) = 0.9
      expect(updated.accuracy, equals(0.9));
    });

    test('recordFailure from zero counts', () {
      final rule = ExtractionRule(
        ruleId: 'rule-15b',
        name: 'FailZero',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        createdAt: now,
        updatedAt: now,
      );

      final updated = rule.recordFailure();

      expect(updated.usageCount, equals(0));
      expect(updated.failureCount, equals(1));
      expect(updated.accuracy, equals(0.0));
    });

    test('disable changes status to disabled', () {
      final rule = ExtractionRule(
        ruleId: 'rule-16',
        name: 'Active Rule',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        status: RuleStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final disabled = rule.disable();

      expect(disabled.status, equals(RuleStatus.disabled));
      expect(disabled.isActive, isFalse);
      // Other fields unchanged
      expect(disabled.ruleId, equals('rule-16'));
      expect(disabled.name, equals('Active Rule'));
    });

    test('deprecate changes status to deprecated', () {
      final rule = ExtractionRule(
        ruleId: 'rule-17',
        name: 'Old Rule',
        sourceType: 'text',
        targetField: 'amount',
        ruleType: RuleType.regex,
        pattern: r'\d+',
        status: RuleStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final deprecated = rule.deprecate();

      expect(deprecated.status, equals(RuleStatus.deprecated));
      expect(deprecated.isActive, isFalse);
      // Other fields unchanged
      expect(deprecated.ruleId, equals('rule-17'));
    });
  });
}
