import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // PolicyType enum tests
  // =========================================================================
  group('PolicyType', () {
    test('has all expected values', () {
      expect(PolicyType.values, contains(PolicyType.classification));
      expect(PolicyType.values, contains(PolicyType.evaluation));
      expect(PolicyType.values, contains(PolicyType.settlement));
      expect(PolicyType.values, contains(PolicyType.alert));
      expect(PolicyType.values.length, equals(4));
    });

    test('fromString valid values', () {
      expect(PolicyType.fromString('classification'),
          equals(PolicyType.classification));
      expect(
          PolicyType.fromString('evaluation'), equals(PolicyType.evaluation));
      expect(
          PolicyType.fromString('settlement'), equals(PolicyType.settlement));
      expect(PolicyType.fromString('alert'), equals(PolicyType.alert));
    });

    test('fromString is case-insensitive', () {
      expect(PolicyType.fromString('CLASSIFICATION'),
          equals(PolicyType.classification));
      expect(
          PolicyType.fromString('Evaluation'), equals(PolicyType.evaluation));
      expect(
          PolicyType.fromString('SETTLEMENT'), equals(PolicyType.settlement));
      expect(PolicyType.fromString('ALERT'), equals(PolicyType.alert));
    });

    test('fromString invalid returns default (classification)', () {
      expect(PolicyType.fromString('unknown'),
          equals(PolicyType.classification));
      expect(PolicyType.fromString(''), equals(PolicyType.classification));
      expect(PolicyType.fromString('invalid'),
          equals(PolicyType.classification));
    });
  });

  // =========================================================================
  // PolicyRule tests
  // =========================================================================
  group('PolicyRule', () {
    test('constructor with required fields only', () {
      final rule = PolicyRule(
        ruleId: 'rule-1',
        condition: 'amount > 100',
        action: 'escalate',
      );

      expect(rule.ruleId, equals('rule-1'));
      expect(rule.condition, equals('amount > 100'));
      expect(rule.action, equals('escalate'));
      expect(rule.priority, equals(0));
      expect(rule.params, isNull);
    });

    test('constructor with all fields', () {
      final rule = PolicyRule(
        ruleId: 'rule-2',
        condition: 'type == "expense"',
        action: 'classify',
        priority: 5,
        params: {'category': 'operational'},
      );

      expect(rule.ruleId, equals('rule-2'));
      expect(rule.condition, equals('type == "expense"'));
      expect(rule.action, equals('classify'));
      expect(rule.priority, equals(5));
      expect(rule.params, equals({'category': 'operational'}));
    });

    test('fromJson complete', () {
      final json = {
        'ruleId': 'rule-1',
        'condition': 'status == "pending"',
        'action': 'auto_approve',
        'priority': 10,
        'params': {'threshold': 50},
      };

      final rule = PolicyRule.fromJson(json);

      expect(rule.ruleId, equals('rule-1'));
      expect(rule.condition, equals('status == "pending"'));
      expect(rule.action, equals('auto_approve'));
      expect(rule.priority, equals(10));
      expect(rule.params, equals({'threshold': 50}));
    });

    test('fromJson empty/missing fields', () {
      final rule = PolicyRule.fromJson(<String, dynamic>{});

      expect(rule.ruleId, equals(''));
      expect(rule.condition, equals(''));
      expect(rule.action, equals(''));
      expect(rule.priority, equals(0));
      expect(rule.params, isNull);
    });

    test('toJson populated', () {
      final rule = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
        priority: 3,
        params: {'level': 'high'},
      );

      final json = rule.toJson();

      expect(json['ruleId'], equals('rule-1'));
      expect(json['condition'], equals('x > 0'));
      expect(json['action'], equals('alert'));
      expect(json['priority'], equals(3));
      expect(json['params'], equals({'level': 'high'}));
    });

    test('toJson excludes null params', () {
      final rule = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
      );

      final json = rule.toJson();

      expect(json.containsKey('ruleId'), isTrue);
      expect(json.containsKey('condition'), isTrue);
      expect(json.containsKey('action'), isTrue);
      expect(json.containsKey('priority'), isTrue);
      expect(json.containsKey('params'), isFalse);
    });

    test('copyWith modifies selected fields', () {
      final original = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
        priority: 1,
      );

      final copy = original.copyWith(
        action: 'escalate',
        priority: 5,
      );

      expect(copy.ruleId, equals('rule-1'));
      expect(copy.condition, equals('x > 0'));
      expect(copy.action, equals('escalate'));
      expect(copy.priority, equals(5));
      expect(copy.params, isNull);
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
      );

      final copy = original.copyWith();

      expect(copy.ruleId, equals(original.ruleId));
      expect(copy.condition, equals(original.condition));
      expect(copy.action, equals(original.action));
      expect(copy.priority, equals(original.priority));
      expect(copy.params, equals(original.params));
    });

    test('copyWith replaces all fields', () {
      final original = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
      );

      final copy = original.copyWith(
        ruleId: 'rule-new',
        condition: 'y < 10',
        action: 'log',
        priority: 99,
        params: {'new': true},
      );

      expect(copy.ruleId, equals('rule-new'));
      expect(copy.condition, equals('y < 10'));
      expect(copy.action, equals('log'));
      expect(copy.priority, equals(99));
      expect(copy.params, equals({'new': true}));
    });
  });

  // =========================================================================
  // FactPolicy tests
  // =========================================================================
  group('FactPolicy', () {
    final now = DateTime(2024, 6, 15, 10);
    final effectiveFrom = DateTime(2024, 1, 1);

    test('constructor with required fields only', () {
      final policy = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.classification,
        scope: 'workspace',
        effectiveFrom: effectiveFrom,
        createdAt: now,
      );

      expect(policy.policyId, equals('pol-1'));
      expect(policy.version, equals('1.0.0'));
      expect(policy.type, equals(PolicyType.classification));
      expect(policy.scope, equals('workspace'));
      expect(policy.rules, isEmpty);
      expect(policy.effectiveFrom, equals(effectiveFrom));
      expect(policy.effectiveTo, isNull);
      expect(policy.description, isNull);
      expect(policy.createdAt, equals(now));
      expect(policy.workspaceId, isNull);
    });

    test('constructor with all fields', () {
      final effectiveTo = DateTime(2025, 12, 31);
      final rule = PolicyRule(
        ruleId: 'rule-1',
        condition: 'amount > 0',
        action: 'classify',
      );
      final policy = FactPolicy(
        policyId: 'pol-2',
        version: '2.0.0',
        type: PolicyType.evaluation,
        scope: 'global',
        rules: [rule],
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        description: 'Evaluation policy for all workspaces',
        createdAt: now,
        workspaceId: 'ws-1',
      );

      expect(policy.policyId, equals('pol-2'));
      expect(policy.version, equals('2.0.0'));
      expect(policy.type, equals(PolicyType.evaluation));
      expect(policy.scope, equals('global'));
      expect(policy.rules, hasLength(1));
      expect(policy.rules.first.ruleId, equals('rule-1'));
      expect(policy.effectiveFrom, equals(effectiveFrom));
      expect(policy.effectiveTo, equals(effectiveTo));
      expect(
          policy.description, equals('Evaluation policy for all workspaces'));
      expect(policy.createdAt, equals(now));
      expect(policy.workspaceId, equals('ws-1'));
    });

    test('fromJson complete', () {
      final json = {
        'policyId': 'pol-1',
        'version': '1.2.3',
        'type': 'settlement',
        'scope': 'team',
        'rules': [
          {
            'ruleId': 'r1',
            'condition': 'c1',
            'action': 'a1',
            'priority': 1,
          },
          {
            'ruleId': 'r2',
            'condition': 'c2',
            'action': 'a2',
            'priority': 2,
          },
        ],
        'effectiveFrom': '2024-01-01T00:00:00.000',
        'effectiveTo': '2025-12-31T00:00:00.000',
        'description': 'Settlement rules',
        'createdAt': '2024-06-15T10:00:00.000',
        'workspaceId': 'ws-1',
      };

      final policy = FactPolicy.fromJson(json);

      expect(policy.policyId, equals('pol-1'));
      expect(policy.version, equals('1.2.3'));
      expect(policy.type, equals(PolicyType.settlement));
      expect(policy.scope, equals('team'));
      expect(policy.rules, hasLength(2));
      expect(policy.rules[0].ruleId, equals('r1'));
      expect(policy.rules[1].ruleId, equals('r2'));
      expect(policy.effectiveFrom, equals(DateTime(2024, 1, 1)));
      expect(policy.effectiveTo, equals(DateTime(2025, 12, 31)));
      expect(policy.description, equals('Settlement rules'));
      expect(policy.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(policy.workspaceId, equals('ws-1'));
    });

    test('fromJson empty/missing fields', () {
      final policy = FactPolicy.fromJson(<String, dynamic>{});

      expect(policy.policyId, equals(''));
      expect(policy.version, equals('1.0.0'));
      expect(policy.type, equals(PolicyType.classification));
      expect(policy.scope, equals(''));
      expect(policy.rules, isEmpty);
      expect(policy.effectiveFrom, isA<DateTime>());
      expect(policy.effectiveTo, isNull);
      expect(policy.description, isNull);
      expect(policy.createdAt, isA<DateTime>());
      expect(policy.workspaceId, isNull);
    });

    test('fromJson with null datetime fields', () {
      final policy = FactPolicy.fromJson({
        'effectiveFrom': null,
        'effectiveTo': null,
        'createdAt': null,
      });
      expect(policy.effectiveFrom, isA<DateTime>());
      expect(policy.effectiveTo, isNull);
      expect(policy.createdAt, isA<DateTime>());
    });

    test('toJson populated', () {
      final effectiveTo = DateTime(2025, 12, 31);
      final rule = PolicyRule(
        ruleId: 'rule-1',
        condition: 'x > 0',
        action: 'alert',
        priority: 1,
      );
      final policy = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.alert,
        scope: 'global',
        rules: [rule],
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        description: 'Alert policy',
        createdAt: now,
        workspaceId: 'ws-1',
      );

      final json = policy.toJson();

      expect(json['policyId'], equals('pol-1'));
      expect(json['version'], equals('1.0.0'));
      expect(json['type'], equals('alert'));
      expect(json['scope'], equals('global'));
      expect(json['rules'], isA<List>());
      expect((json['rules'] as List).length, equals(1));
      expect(json['effectiveFrom'], equals(effectiveFrom.toIso8601String()));
      expect(json['effectiveTo'], equals(effectiveTo.toIso8601String()));
      expect(json['description'], equals('Alert policy'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['workspaceId'], equals('ws-1'));
    });

    test('toJson excludes empty and null fields', () {
      final policy = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.classification,
        scope: 'workspace',
        effectiveFrom: effectiveFrom,
        createdAt: now,
      );

      final json = policy.toJson();

      expect(json.containsKey('rules'), isFalse);
      expect(json.containsKey('effectiveTo'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // Always-present fields
      expect(json.containsKey('policyId'), isTrue);
      expect(json.containsKey('version'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('scope'), isTrue);
      expect(json.containsKey('effectiveFrom'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final original = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.classification,
        scope: 'workspace',
        effectiveFrom: effectiveFrom,
        createdAt: now,
      );

      final copy = original.copyWith(
        version: '2.0.0',
        type: PolicyType.evaluation,
        description: 'Updated policy',
      );

      expect(copy.policyId, equals('pol-1'));
      expect(copy.version, equals('2.0.0'));
      expect(copy.type, equals(PolicyType.evaluation));
      expect(copy.description, equals('Updated policy'));
      expect(copy.scope, equals('workspace'));
      expect(copy.effectiveFrom, equals(effectiveFrom));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.classification,
        scope: 'workspace',
        effectiveFrom: effectiveFrom,
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.policyId, equals(original.policyId));
      expect(copy.version, equals(original.version));
      expect(copy.type, equals(original.type));
      expect(copy.scope, equals(original.scope));
      expect(copy.rules, equals(original.rules));
      expect(copy.effectiveFrom, equals(original.effectiveFrom));
      expect(copy.effectiveTo, equals(original.effectiveTo));
      expect(copy.description, equals(original.description));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.workspaceId, equals(original.workspaceId));
    });

    test('copyWith replaces all fields', () {
      final original = FactPolicy(
        policyId: 'pol-1',
        version: '1.0.0',
        type: PolicyType.classification,
        scope: 'workspace',
        effectiveFrom: effectiveFrom,
        createdAt: now,
      );

      final newDate = DateTime(2025, 6, 1);
      final newRule = PolicyRule(
        ruleId: 'new-rule',
        condition: 'new',
        action: 'new',
      );
      final copy = original.copyWith(
        policyId: 'pol-new',
        version: '9.0.0',
        type: PolicyType.alert,
        scope: 'new-scope',
        rules: [newRule],
        effectiveFrom: newDate,
        effectiveTo: newDate,
        description: 'New desc',
        createdAt: newDate,
        workspaceId: 'ws-new',
      );

      expect(copy.policyId, equals('pol-new'));
      expect(copy.version, equals('9.0.0'));
      expect(copy.type, equals(PolicyType.alert));
      expect(copy.scope, equals('new-scope'));
      expect(copy.rules, hasLength(1));
      expect(copy.effectiveFrom, equals(newDate));
      expect(copy.effectiveTo, equals(newDate));
      expect(copy.description, equals('New desc'));
      expect(copy.createdAt, equals(newDate));
      expect(copy.workspaceId, equals('ws-new'));
    });

    // -----------------------------------------------------------------------
    // Boolean getters / computed properties
    // -----------------------------------------------------------------------
    group('isCurrentlyEffective getter', () {
      test('returns true when within effective range (no end)', () {
        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          effectiveFrom: DateTime(2020, 1, 1),
          createdAt: now,
        );
        expect(policy.isCurrentlyEffective, isTrue);
      });

      test('returns true when within effective range (with end)', () {
        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          effectiveFrom: DateTime(2020, 1, 1),
          effectiveTo: DateTime(2099, 12, 31),
          createdAt: now,
        );
        expect(policy.isCurrentlyEffective, isTrue);
      });

      test('returns false when effectiveFrom is in the future', () {
        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          effectiveFrom: DateTime(2099, 1, 1),
          createdAt: now,
        );
        expect(policy.isCurrentlyEffective, isFalse);
      });

      test('returns false when effectiveTo is in the past', () {
        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          effectiveFrom: DateTime(2020, 1, 1),
          effectiveTo: DateTime(2020, 12, 31),
          createdAt: now,
        );
        expect(policy.isCurrentlyEffective, isFalse);
      });
    });

    group('sortedRules getter', () {
      test('returns rules sorted by priority', () {
        final ruleA = PolicyRule(
          ruleId: 'r-a',
          condition: 'c',
          action: 'a',
          priority: 10,
        );
        final ruleB = PolicyRule(
          ruleId: 'r-b',
          condition: 'c',
          action: 'a',
          priority: 1,
        );
        final ruleC = PolicyRule(
          ruleId: 'r-c',
          condition: 'c',
          action: 'a',
          priority: 5,
        );

        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          rules: [ruleA, ruleB, ruleC],
          effectiveFrom: effectiveFrom,
          createdAt: now,
        );

        final sorted = policy.sortedRules;

        expect(sorted[0].ruleId, equals('r-b'));
        expect(sorted[1].ruleId, equals('r-c'));
        expect(sorted[2].ruleId, equals('r-a'));
      });

      test('returns empty list for no rules', () {
        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          effectiveFrom: effectiveFrom,
          createdAt: now,
        );

        expect(policy.sortedRules, isEmpty);
      });

      test('does not mutate the original rules list', () {
        final ruleA = PolicyRule(
          ruleId: 'r-a',
          condition: 'c',
          action: 'a',
          priority: 10,
        );
        final ruleB = PolicyRule(
          ruleId: 'r-b',
          condition: 'c',
          action: 'a',
          priority: 1,
        );

        final policy = FactPolicy(
          policyId: 'pol-1',
          version: '1.0.0',
          type: PolicyType.classification,
          scope: 'workspace',
          rules: [ruleA, ruleB],
          effectiveFrom: effectiveFrom,
          createdAt: now,
        );

        // Get sorted rules
        policy.sortedRules;

        // Original order should be preserved
        expect(policy.rules[0].ruleId, equals('r-a'));
        expect(policy.rules[1].ruleId, equals('r-b'));
      });
    });
  });
}
