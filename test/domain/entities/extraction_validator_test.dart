import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart' hide ValidationResult;
// ValidationResult is hidden from barrel export; import directly with
// hide on barrel to avoid name collision with response_validation.dart
import 'package:mcp_fact_graph/src/domain/entities/extraction_validator.dart'
    show ValidationResult;

void main() {
  group('ValidatorSeverity', () {
    test('fromString valid values', () {
      expect(
        ValidatorSeverity.fromString('error'),
        equals(ValidatorSeverity.error),
      );
      expect(
        ValidatorSeverity.fromString('warning'),
        equals(ValidatorSeverity.warning),
      );
      expect(
        ValidatorSeverity.fromString('info'),
        equals(ValidatorSeverity.info),
      );
    });

    test('fromString returns error for invalid values', () {
      expect(
        ValidatorSeverity.fromString('unknown'),
        equals(ValidatorSeverity.error),
      );
      expect(
        ValidatorSeverity.fromString(''),
        equals(ValidatorSeverity.error),
      );
      expect(
        ValidatorSeverity.fromString('critical'),
        equals(ValidatorSeverity.error),
      );
    });
  });

  group('ExtractionValidator', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 12, 0);

    test('constructor with required fields', () {
      final validator = ExtractionValidator(
        validatorId: 'val-1',
        workspaceId: 'ws-1',
        factType: 'expense',
        rules: ['field != null', 'length(field) >= 1'],
        createdAt: now,
        updatedAt: now,
      );

      expect(validator.validatorId, equals('val-1'));
      expect(validator.workspaceId, equals('ws-1'));
      expect(validator.factType, equals('expense'));
      expect(validator.rules, equals(['field != null', 'length(field) >= 1']));
      expect(validator.severity, equals(ValidatorSeverity.error));
      expect(validator.enabled, isTrue);
      expect(validator.message, isNull);
      expect(validator.dependencies, isNull);
      expect(validator.createdAt, equals(now));
      expect(validator.updatedAt, equals(now));
    });

    test('constructor with all fields', () {
      final validator = ExtractionValidator(
        validatorId: 'val-2',
        workspaceId: 'ws-2',
        factType: 'income',
        rules: ['inRange(amount, 0, 100000)'],
        severity: ValidatorSeverity.warning,
        enabled: false,
        message: 'Amount out of expected range',
        dependencies: ['val-1'],
        createdAt: now,
        updatedAt: later,
      );

      expect(validator.validatorId, equals('val-2'));
      expect(validator.workspaceId, equals('ws-2'));
      expect(validator.factType, equals('income'));
      expect(validator.rules, equals(['inRange(amount, 0, 100000)']));
      expect(validator.severity, equals(ValidatorSeverity.warning));
      expect(validator.enabled, isFalse);
      expect(validator.message, equals('Amount out of expected range'));
      expect(validator.dependencies, equals(['val-1']));
      expect(validator.createdAt, equals(now));
      expect(validator.updatedAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'validatorId': 'val-3',
        'workspaceId': 'ws-3',
        'factType': 'transfer',
        'rules': ['field != null', 'references(field, account)'],
        'severity': 'warning',
        'enabled': false,
        'message': 'Invalid reference',
        'dependencies': ['val-dep-1', 'val-dep-2'],
        'createdAt': '2024-01-15T10:30:00.000',
        'updatedAt': '2024-01-16T12:00:00.000',
      };

      final validator = ExtractionValidator.fromJson(json);

      expect(validator.validatorId, equals('val-3'));
      expect(validator.workspaceId, equals('ws-3'));
      expect(validator.factType, equals('transfer'));
      expect(
        validator.rules,
        equals(['field != null', 'references(field, account)']),
      );
      expect(validator.severity, equals(ValidatorSeverity.warning));
      expect(validator.enabled, isFalse);
      expect(validator.message, equals('Invalid reference'));
      expect(validator.dependencies, equals(['val-dep-1', 'val-dep-2']));
      expect(
        validator.createdAt,
        equals(DateTime.parse('2024-01-15T10:30:00.000')),
      );
      expect(
        validator.updatedAt,
        equals(DateTime.parse('2024-01-16T12:00:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final validator = ExtractionValidator.fromJson({});

      expect(validator.validatorId, equals(''));
      expect(validator.workspaceId, equals('default'));
      expect(validator.factType, equals(''));
      expect(validator.rules, isEmpty);
      expect(validator.severity, equals(ValidatorSeverity.error));
      expect(validator.enabled, isTrue);
      expect(validator.message, isNull);
      expect(validator.dependencies, isNull);
      expect(validator.createdAt, isA<DateTime>());
      expect(validator.updatedAt, isA<DateTime>());
    });

    test('fromJson with null dates defaults to now', () {
      final before = DateTime.now();
      final validator = ExtractionValidator.fromJson({
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        validator.createdAt.isAfter(before) ||
            validator.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        validator.createdAt.isBefore(after) ||
            validator.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('toJson populated', () {
      final validator = ExtractionValidator(
        validatorId: 'val-4',
        workspaceId: 'ws-4',
        factType: 'expense',
        rules: ['field != null'],
        severity: ValidatorSeverity.info,
        enabled: false,
        message: 'Custom message',
        dependencies: ['dep-1'],
        createdAt: now,
        updatedAt: later,
      );

      final json = validator.toJson();

      expect(json['validatorId'], equals('val-4'));
      expect(json['workspaceId'], equals('ws-4'));
      expect(json['factType'], equals('expense'));
      expect(json['rules'], equals(['field != null']));
      expect(json['severity'], equals('info'));
      expect(json['enabled'], isFalse);
      expect(json['message'], equals('Custom message'));
      expect(json['dependencies'], equals(['dep-1']));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes null/empty optional fields', () {
      final validator = ExtractionValidator(
        validatorId: 'val-5',
        workspaceId: 'ws-5',
        factType: 'expense',
        rules: ['field != null'],
        createdAt: now,
        updatedAt: now,
      );

      final json = validator.toJson();

      expect(json.containsKey('message'), isFalse);
      expect(json.containsKey('dependencies'), isFalse);
      // Always-present fields
      expect(json.containsKey('validatorId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('factType'), isTrue);
      expect(json.containsKey('rules'), isTrue);
      expect(json.containsKey('severity'), isTrue);
      expect(json.containsKey('enabled'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('toJson excludes empty dependencies list', () {
      final validator = ExtractionValidator(
        validatorId: 'val-5b',
        workspaceId: 'ws-5',
        factType: 'expense',
        rules: ['field != null'],
        dependencies: [],
        createdAt: now,
        updatedAt: now,
      );

      final json = validator.toJson();

      // Empty dependencies should not appear
      expect(json.containsKey('dependencies'), isFalse);
    });

    test('copyWith creates modified copy', () {
      final original = ExtractionValidator(
        validatorId: 'val-6',
        workspaceId: 'ws-6',
        factType: 'expense',
        rules: ['field != null'],
        severity: ValidatorSeverity.error,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(
        validatorId: 'val-7',
        workspaceId: 'ws-7',
        factType: 'income',
        rules: ['inRange(amount, 0, 1000)'],
        severity: ValidatorSeverity.warning,
        enabled: false,
        message: 'Updated message',
        dependencies: ['dep-x'],
        createdAt: later,
        updatedAt: later,
      );

      expect(modified.validatorId, equals('val-7'));
      expect(modified.workspaceId, equals('ws-7'));
      expect(modified.factType, equals('income'));
      expect(modified.rules, equals(['inRange(amount, 0, 1000)']));
      expect(modified.severity, equals(ValidatorSeverity.warning));
      expect(modified.enabled, isFalse);
      expect(modified.message, equals('Updated message'));
      expect(modified.dependencies, equals(['dep-x']));
      expect(modified.createdAt, equals(later));
      expect(modified.updatedAt, equals(later));

      // Original unchanged
      expect(original.validatorId, equals('val-6'));
      expect(original.factType, equals('expense'));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = ExtractionValidator(
        validatorId: 'val-8',
        workspaceId: 'ws-8',
        factType: 'expense',
        rules: ['field != null'],
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.validatorId, equals(original.validatorId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.factType, equals(original.factType));
      expect(copy.rules, equals(original.rules));
      expect(copy.severity, equals(original.severity));
      expect(copy.enabled, equals(original.enabled));
      expect(copy.message, equals(original.message));
      expect(copy.dependencies, equals(original.dependencies));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('isActive getter', () {
      final enabled = ExtractionValidator(
        validatorId: 'val-9',
        workspaceId: 'ws-9',
        factType: 'expense',
        rules: [],
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(enabled.isActive, isTrue);

      final disabled = enabled.copyWith(enabled: false);
      expect(disabled.isActive, isFalse);
    });

    test('hasDependencies getter', () {
      // No dependencies (null)
      final noDeps = ExtractionValidator(
        validatorId: 'val-10',
        workspaceId: 'ws-10',
        factType: 'expense',
        rules: [],
        createdAt: now,
        updatedAt: now,
      );
      expect(noDeps.hasDependencies, isFalse);

      // Empty dependencies list
      final emptyDeps = noDeps.copyWith(dependencies: []);
      expect(emptyDeps.hasDependencies, isFalse);

      // With dependencies
      final withDeps = noDeps.copyWith(dependencies: ['dep-1']);
      expect(withDeps.hasDependencies, isTrue);
    });

    test('enable method', () {
      final disabled = ExtractionValidator(
        validatorId: 'val-11',
        workspaceId: 'ws-11',
        factType: 'expense',
        rules: [],
        enabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final enabled = disabled.enable();

      expect(enabled.enabled, isTrue);
      expect(enabled.isActive, isTrue);
      expect(enabled.validatorId, equals('val-11'));
    });

    test('disable method', () {
      final enabled = ExtractionValidator(
        validatorId: 'val-12',
        workspaceId: 'ws-12',
        factType: 'expense',
        rules: [],
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final disabled = enabled.disable();

      expect(disabled.enabled, isFalse);
      expect(disabled.isActive, isFalse);
      expect(disabled.validatorId, equals('val-12'));
    });

    test('addRule appends a rule', () {
      final validator = ExtractionValidator(
        validatorId: 'val-13',
        workspaceId: 'ws-13',
        factType: 'expense',
        rules: ['field != null'],
        createdAt: now,
        updatedAt: now,
      );

      final updated = validator.addRule('length(field) >= 5');

      expect(updated.rules, equals(['field != null', 'length(field) >= 5']));
      // Original unchanged
      expect(validator.rules, equals(['field != null']));
    });

    test('removeRule removes a specific rule', () {
      final validator = ExtractionValidator(
        validatorId: 'val-14',
        workspaceId: 'ws-14',
        factType: 'expense',
        rules: ['field != null', 'length(field) >= 5', 'inRange(x, 0, 10)'],
        createdAt: now,
        updatedAt: now,
      );

      final updated = validator.removeRule('length(field) >= 5');

      expect(updated.rules, equals(['field != null', 'inRange(x, 0, 10)']));
      // Original unchanged
      expect(validator.rules.length, equals(3));
    });

    test('removeRule with non-existent rule returns same rules', () {
      final validator = ExtractionValidator(
        validatorId: 'val-14b',
        workspaceId: 'ws-14',
        factType: 'expense',
        rules: ['field != null'],
        createdAt: now,
        updatedAt: now,
      );

      final updated = validator.removeRule('nonexistent');

      expect(updated.rules, equals(['field != null']));
    });

    test('toString', () {
      final validator = ExtractionValidator(
        validatorId: 'val-15',
        workspaceId: 'ws-15',
        factType: 'expense',
        rules: [],
        severity: ValidatorSeverity.warning,
        createdAt: now,
        updatedAt: now,
      );

      final str = validator.toString();

      expect(str, contains('val-15'));
      expect(str, contains('expense'));
      expect(str, contains('warning'));
    });

    test('equality based on validatorId', () {
      final v1 = ExtractionValidator(
        validatorId: 'val-16',
        workspaceId: 'ws-a',
        factType: 'expense',
        rules: ['rule-a'],
        createdAt: now,
        updatedAt: now,
      );

      final v2 = ExtractionValidator(
        validatorId: 'val-16',
        workspaceId: 'ws-b',
        factType: 'income',
        rules: ['rule-b'],
        createdAt: later,
        updatedAt: later,
      );

      final v3 = ExtractionValidator(
        validatorId: 'val-17',
        workspaceId: 'ws-a',
        factType: 'expense',
        rules: ['rule-a'],
        createdAt: now,
        updatedAt: now,
      );

      // Same validatorId -> equal
      expect(v1 == v2, isTrue);
      expect(v1.hashCode, equals(v2.hashCode));

      // Different validatorId -> not equal
      expect(v1 == v3, isFalse);
    });

    test('equality with identical reference', () {
      final v1 = ExtractionValidator(
        validatorId: 'val-18',
        workspaceId: 'ws-x',
        factType: 'expense',
        rules: [],
        createdAt: now,
        updatedAt: now,
      );

      // ignore: unrelated_type_equality_checks
      expect(v1 == v1, isTrue);
    });

    test('equality with non-ExtractionValidator object', () {
      final v1 = ExtractionValidator(
        validatorId: 'val-19',
        workspaceId: 'ws-x',
        factType: 'expense',
        rules: [],
        createdAt: now,
        updatedAt: now,
      );

      // ignore: unrelated_type_equality_checks
      expect(v1 == 'not-a-validator', isFalse);
    });
  });

  group('ValidationResult', () {
    final now = DateTime(2024, 1, 15, 10, 30);

    test('constructor with required fields (passed)', () {
      final result = ValidationResult(
        validatorId: 'val-1',
        passed: true,
        validatedAt: now,
      );

      expect(result.validatorId, equals('val-1'));
      expect(result.passed, isTrue);
      expect(result.severity, isNull);
      expect(result.message, isNull);
      expect(result.failedRule, isNull);
      expect(result.validatedAt, equals(now));
    });

    test('constructor with all fields (failed)', () {
      final result = ValidationResult(
        validatorId: 'val-2',
        passed: false,
        severity: ValidatorSeverity.error,
        message: 'Field is required',
        failedRule: 'field != null',
        validatedAt: now,
      );

      expect(result.validatorId, equals('val-2'));
      expect(result.passed, isFalse);
      expect(result.severity, equals(ValidatorSeverity.error));
      expect(result.message, equals('Field is required'));
      expect(result.failedRule, equals('field != null'));
      expect(result.validatedAt, equals(now));
    });

    test('fromJson complete', () {
      final json = {
        'validatorId': 'val-3',
        'passed': false,
        'severity': 'warning',
        'message': 'Value looks suspicious',
        'failedRule': 'inRange(amount, 0, 10000)',
        'validatedAt': '2024-01-15T10:30:00.000',
      };

      final result = ValidationResult.fromJson(json);

      expect(result.validatorId, equals('val-3'));
      expect(result.passed, isFalse);
      expect(result.severity, equals(ValidatorSeverity.warning));
      expect(result.message, equals('Value looks suspicious'));
      expect(result.failedRule, equals('inRange(amount, 0, 10000)'));
      expect(
        result.validatedAt,
        equals(DateTime.parse('2024-01-15T10:30:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final result = ValidationResult.fromJson({});

      expect(result.validatorId, equals(''));
      expect(result.passed, isFalse);
      expect(result.severity, isNull);
      expect(result.message, isNull);
      expect(result.failedRule, isNull);
      expect(result.validatedAt, isA<DateTime>());
    });

    test('fromJson with null validatedAt defaults to now', () {
      final before = DateTime.now();
      final result = ValidationResult.fromJson({'validatedAt': null});
      final after = DateTime.now();

      expect(
        result.validatedAt.isAfter(before) ||
            result.validatedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        result.validatedAt.isBefore(after) ||
            result.validatedAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('fromJson with null severity', () {
      final result = ValidationResult.fromJson({
        'validatorId': 'val-x',
        'passed': true,
        'severity': null,
      });

      expect(result.severity, isNull);
    });

    test('toJson populated', () {
      final result = ValidationResult(
        validatorId: 'val-4',
        passed: false,
        severity: ValidatorSeverity.error,
        message: 'Validation failed',
        failedRule: 'field != null',
        validatedAt: now,
      );

      final json = result.toJson();

      expect(json['validatorId'], equals('val-4'));
      expect(json['passed'], isFalse);
      expect(json['severity'], equals('error'));
      expect(json['message'], equals('Validation failed'));
      expect(json['failedRule'], equals('field != null'));
      expect(json['validatedAt'], equals(now.toIso8601String()));
    });

    test('toJson excludes null fields', () {
      final result = ValidationResult(
        validatorId: 'val-5',
        passed: true,
        validatedAt: now,
      );

      final json = result.toJson();

      expect(json.containsKey('severity'), isFalse);
      expect(json.containsKey('message'), isFalse);
      expect(json.containsKey('failedRule'), isFalse);
      // Always present
      expect(json.containsKey('validatorId'), isTrue);
      expect(json.containsKey('passed'), isTrue);
      expect(json.containsKey('validatedAt'), isTrue);
    });

    test('isError getter', () {
      final errorResult = ValidationResult(
        validatorId: 'val-6',
        passed: false,
        severity: ValidatorSeverity.error,
        validatedAt: now,
      );
      expect(errorResult.isError, isTrue);

      // Passed with error severity -> not isError
      final passedResult = ValidationResult(
        validatorId: 'val-7',
        passed: true,
        severity: ValidatorSeverity.error,
        validatedAt: now,
      );
      expect(passedResult.isError, isFalse);

      // Failed with warning severity -> not isError
      final warningResult = ValidationResult(
        validatorId: 'val-8',
        passed: false,
        severity: ValidatorSeverity.warning,
        validatedAt: now,
      );
      expect(warningResult.isError, isFalse);

      // Failed with null severity -> not isError
      final noSeverity = ValidationResult(
        validatorId: 'val-8b',
        passed: false,
        validatedAt: now,
      );
      expect(noSeverity.isError, isFalse);
    });

    test('isWarning getter', () {
      final warningResult = ValidationResult(
        validatorId: 'val-9',
        passed: false,
        severity: ValidatorSeverity.warning,
        validatedAt: now,
      );
      expect(warningResult.isWarning, isTrue);

      // Passed with warning severity -> not isWarning
      final passedResult = ValidationResult(
        validatorId: 'val-10',
        passed: true,
        severity: ValidatorSeverity.warning,
        validatedAt: now,
      );
      expect(passedResult.isWarning, isFalse);

      // Failed with error severity -> not isWarning
      final errorResult = ValidationResult(
        validatorId: 'val-11',
        passed: false,
        severity: ValidatorSeverity.error,
        validatedAt: now,
      );
      expect(errorResult.isWarning, isFalse);

      // Failed with null severity -> not isWarning
      final noSeverity = ValidationResult(
        validatorId: 'val-11b',
        passed: false,
        validatedAt: now,
      );
      expect(noSeverity.isWarning, isFalse);
    });
  });
}
