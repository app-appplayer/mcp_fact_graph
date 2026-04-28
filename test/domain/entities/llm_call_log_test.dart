import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('LLMCallLog', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 12, 0);

    test('constructor with required fields', () {
      final log = LLMCallLog(
        callId: 'call-1',
        purpose: 'extraction',
        model: 'gpt-4',
        createdAt: now,
      );

      expect(log.callId, equals('call-1'));
      expect(log.purpose, equals('extraction'));
      expect(log.model, equals('gpt-4'));
      expect(log.inputTokens, equals(0));
      expect(log.outputTokens, equals(0));
      expect(log.cost, equals(0.0));
      expect(log.wasNecessary, isTrue);
      expect(log.alternativeRuleId, isNull);
      expect(log.request, isEmpty);
      expect(log.response, isEmpty);
      expect(log.latencyMs, isNull);
      expect(log.success, isTrue);
      expect(log.errorMessage, isNull);
      expect(log.workspaceId, isNull);
      expect(log.createdAt, equals(now));
    });

    test('constructor with all fields', () {
      final log = LLMCallLog(
        callId: 'call-2',
        purpose: 'classification',
        model: 'claude-3',
        inputTokens: 500,
        outputTokens: 200,
        cost: 0.035,
        wasNecessary: false,
        alternativeRuleId: 'rule-1',
        request: {'prompt': 'classify this'},
        response: {'result': 'expense'},
        latencyMs: 1200,
        success: true,
        errorMessage: null,
        workspaceId: 'ws-1',
        createdAt: now,
      );

      expect(log.callId, equals('call-2'));
      expect(log.purpose, equals('classification'));
      expect(log.model, equals('claude-3'));
      expect(log.inputTokens, equals(500));
      expect(log.outputTokens, equals(200));
      expect(log.cost, equals(0.035));
      expect(log.wasNecessary, isFalse);
      expect(log.alternativeRuleId, equals('rule-1'));
      expect(log.request, equals({'prompt': 'classify this'}));
      expect(log.response, equals({'result': 'expense'}));
      expect(log.latencyMs, equals(1200));
      expect(log.success, isTrue);
      expect(log.errorMessage, isNull);
      expect(log.workspaceId, equals('ws-1'));
      expect(log.createdAt, equals(now));
    });

    test('fromJson complete', () {
      final json = {
        'callId': 'call-3',
        'purpose': 'summary',
        'model': 'gpt-4-turbo',
        'inputTokens': 1000,
        'outputTokens': 300,
        'cost': 0.05,
        'wasNecessary': false,
        'alternativeRuleId': 'rule-2',
        'request': {'text': 'summarize this'},
        'response': {'summary': 'brief text'},
        'latencyMs': 800,
        'success': false,
        'errorMessage': 'Rate limit exceeded',
        'workspaceId': 'ws-2',
        'createdAt': '2024-01-15T10:30:00.000',
      };

      final log = LLMCallLog.fromJson(json);

      expect(log.callId, equals('call-3'));
      expect(log.purpose, equals('summary'));
      expect(log.model, equals('gpt-4-turbo'));
      expect(log.inputTokens, equals(1000));
      expect(log.outputTokens, equals(300));
      expect(log.cost, equals(0.05));
      expect(log.wasNecessary, isFalse);
      expect(log.alternativeRuleId, equals('rule-2'));
      expect(log.request, equals({'text': 'summarize this'}));
      expect(log.response, equals({'summary': 'brief text'}));
      expect(log.latencyMs, equals(800));
      expect(log.success, isFalse);
      expect(log.errorMessage, equals('Rate limit exceeded'));
      expect(log.workspaceId, equals('ws-2'));
      expect(
        log.createdAt,
        equals(DateTime.parse('2024-01-15T10:30:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final log = LLMCallLog.fromJson({});

      expect(log.callId, equals(''));
      expect(log.purpose, equals(''));
      expect(log.model, equals(''));
      expect(log.inputTokens, equals(0));
      expect(log.outputTokens, equals(0));
      expect(log.cost, equals(0.0));
      expect(log.wasNecessary, isTrue);
      expect(log.alternativeRuleId, isNull);
      expect(log.request, isEmpty);
      expect(log.response, isEmpty);
      expect(log.latencyMs, isNull);
      expect(log.success, isTrue);
      expect(log.errorMessage, isNull);
      expect(log.workspaceId, isNull);
      expect(log.createdAt, isA<DateTime>());
    });

    test('fromJson with null createdAt defaults to now', () {
      final before = DateTime.now();
      final log = LLMCallLog.fromJson({'createdAt': null});
      final after = DateTime.now();

      expect(
        log.createdAt.isAfter(before) ||
            log.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        log.createdAt.isBefore(after) ||
            log.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('toJson populated', () {
      final log = LLMCallLog(
        callId: 'call-4',
        purpose: 'extraction',
        model: 'gpt-4',
        inputTokens: 250,
        outputTokens: 100,
        cost: 0.02,
        wasNecessary: false,
        alternativeRuleId: 'rule-3',
        request: {'input': 'data'},
        response: {'output': 'result'},
        latencyMs: 500,
        success: false,
        errorMessage: 'Timeout',
        workspaceId: 'ws-3',
        createdAt: now,
      );

      final json = log.toJson();

      expect(json['callId'], equals('call-4'));
      expect(json['purpose'], equals('extraction'));
      expect(json['model'], equals('gpt-4'));
      expect(json['inputTokens'], equals(250));
      expect(json['outputTokens'], equals(100));
      expect(json['cost'], equals(0.02));
      expect(json['wasNecessary'], isFalse);
      expect(json['alternativeRuleId'], equals('rule-3'));
      expect(json['request'], equals({'input': 'data'}));
      expect(json['response'], equals({'output': 'result'}));
      expect(json['latencyMs'], equals(500));
      expect(json['success'], isFalse);
      expect(json['errorMessage'], equals('Timeout'));
      expect(json['workspaceId'], equals('ws-3'));
      expect(json['createdAt'], equals(now.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final log = LLMCallLog(
        callId: 'call-5',
        purpose: 'extraction',
        model: 'gpt-4',
        createdAt: now,
      );

      final json = log.toJson();

      expect(json.containsKey('alternativeRuleId'), isFalse);
      expect(json.containsKey('request'), isFalse);
      expect(json.containsKey('response'), isFalse);
      expect(json.containsKey('latencyMs'), isFalse);
      expect(json.containsKey('errorMessage'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // Always-present fields
      expect(json.containsKey('callId'), isTrue);
      expect(json.containsKey('purpose'), isTrue);
      expect(json.containsKey('model'), isTrue);
      expect(json.containsKey('inputTokens'), isTrue);
      expect(json.containsKey('outputTokens'), isTrue);
      expect(json.containsKey('cost'), isTrue);
      expect(json.containsKey('wasNecessary'), isTrue);
      expect(json.containsKey('success'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final original = LLMCallLog(
        callId: 'call-6',
        purpose: 'extraction',
        model: 'gpt-4',
        inputTokens: 100,
        outputTokens: 50,
        cost: 0.01,
        wasNecessary: true,
        request: {'a': 1},
        response: {'b': 2},
        success: true,
        createdAt: now,
      );

      final modified = original.copyWith(
        callId: 'call-7',
        purpose: 'classification',
        model: 'claude-3',
        inputTokens: 200,
        outputTokens: 75,
        cost: 0.02,
        wasNecessary: false,
        alternativeRuleId: 'rule-x',
        request: {'c': 3},
        response: {'d': 4},
        latencyMs: 999,
        success: false,
        errorMessage: 'Error occurred',
        workspaceId: 'ws-new',
        createdAt: later,
      );

      expect(modified.callId, equals('call-7'));
      expect(modified.purpose, equals('classification'));
      expect(modified.model, equals('claude-3'));
      expect(modified.inputTokens, equals(200));
      expect(modified.outputTokens, equals(75));
      expect(modified.cost, equals(0.02));
      expect(modified.wasNecessary, isFalse);
      expect(modified.alternativeRuleId, equals('rule-x'));
      expect(modified.request, equals({'c': 3}));
      expect(modified.response, equals({'d': 4}));
      expect(modified.latencyMs, equals(999));
      expect(modified.success, isFalse);
      expect(modified.errorMessage, equals('Error occurred'));
      expect(modified.workspaceId, equals('ws-new'));
      expect(modified.createdAt, equals(later));

      // Original unchanged
      expect(original.callId, equals('call-6'));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = LLMCallLog(
        callId: 'call-8',
        purpose: 'extraction',
        model: 'gpt-4',
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.callId, equals(original.callId));
      expect(copy.purpose, equals(original.purpose));
      expect(copy.model, equals(original.model));
      expect(copy.inputTokens, equals(original.inputTokens));
      expect(copy.outputTokens, equals(original.outputTokens));
      expect(copy.cost, equals(original.cost));
      expect(copy.wasNecessary, equals(original.wasNecessary));
      expect(copy.alternativeRuleId, equals(original.alternativeRuleId));
      expect(copy.request, equals(original.request));
      expect(copy.response, equals(original.response));
      expect(copy.latencyMs, equals(original.latencyMs));
      expect(copy.success, equals(original.success));
      expect(copy.errorMessage, equals(original.errorMessage));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.createdAt, equals(original.createdAt));
    });

    test('totalTokens getter', () {
      final log = LLMCallLog(
        callId: 'call-9',
        purpose: 'extraction',
        model: 'gpt-4',
        inputTokens: 500,
        outputTokens: 200,
        createdAt: now,
      );

      expect(log.totalTokens, equals(700));
    });

    test('totalTokens getter with zero tokens', () {
      final log = LLMCallLog(
        callId: 'call-9b',
        purpose: 'extraction',
        model: 'gpt-4',
        createdAt: now,
      );

      expect(log.totalTokens, equals(0));
    });

    test('wasUnnecessary getter', () {
      // Necessary call: wasNecessary = true
      final necessaryLog = LLMCallLog(
        callId: 'call-10',
        purpose: 'extraction',
        model: 'gpt-4',
        wasNecessary: true,
        createdAt: now,
      );
      expect(necessaryLog.wasUnnecessary, isFalse);

      // Unnecessary with alternative rule
      final unnecessaryLog = LLMCallLog(
        callId: 'call-11',
        purpose: 'extraction',
        model: 'gpt-4',
        wasNecessary: false,
        alternativeRuleId: 'rule-alt',
        createdAt: now,
      );
      expect(unnecessaryLog.wasUnnecessary, isTrue);

      // Not necessary but no alternative rule
      final noAltLog = LLMCallLog(
        callId: 'call-12',
        purpose: 'extraction',
        model: 'gpt-4',
        wasNecessary: false,
        createdAt: now,
      );
      expect(noAltLog.wasUnnecessary, isFalse);
    });

    test('failed getter', () {
      final successLog = LLMCallLog(
        callId: 'call-13',
        purpose: 'extraction',
        model: 'gpt-4',
        success: true,
        createdAt: now,
      );
      expect(successLog.failed, isFalse);

      final failedLog = LLMCallLog(
        callId: 'call-14',
        purpose: 'extraction',
        model: 'gpt-4',
        success: false,
        createdAt: now,
      );
      expect(failedLog.failed, isTrue);
    });
  });

  group('LLMCallPurpose', () {
    test('has all expected constants', () {
      expect(LLMCallPurpose.extraction, equals('extraction'));
      expect(LLMCallPurpose.classification, equals('classification'));
      expect(LLMCallPurpose.summary, equals('summary'));
      expect(LLMCallPurpose.response, equals('response'));
      expect(LLMCallPurpose.verification, equals('verification'));
      expect(LLMCallPurpose.patternMining, equals('pattern_mining'));
      expect(LLMCallPurpose.entityResolution, equals('entity_resolution'));
      expect(LLMCallPurpose.evaluation, equals('evaluation'));
    });
  });

  group('LLMCostAnalytics', () {
    final now = DateTime(2024, 1, 15, 10, 30);

    test('totalCost calculates sum', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.01,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'classification',
          model: 'gpt-4',
          cost: 0.02,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'summary',
          model: 'gpt-4',
          cost: 0.03,
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.totalCost(logs), closeTo(0.06, 0.001));
    });

    test('totalCost with empty list returns 0.0', () {
      expect(LLMCostAnalytics.totalCost([]), equals(0.0));
    });

    test('costByPurpose groups costs', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.01,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.02,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'classification',
          model: 'gpt-4',
          cost: 0.05,
          createdAt: now,
        ),
      ];

      final result = LLMCostAnalytics.costByPurpose(logs);

      expect(result['extraction'], closeTo(0.03, 0.001));
      expect(result['classification'], closeTo(0.05, 0.001));
      expect(result.length, equals(2));
    });

    test('costByPurpose with empty list returns empty map', () {
      expect(LLMCostAnalytics.costByPurpose([]), isEmpty);
    });

    test('unnecessaryCallCount counts correctly', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          wasNecessary: true,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          wasNecessary: false,
          alternativeRuleId: 'rule-1',
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'extraction',
          model: 'gpt-4',
          wasNecessary: false,
          alternativeRuleId: 'rule-2',
          createdAt: now,
        ),
        // Not necessary but no alternative rule: not counted as unnecessary
        LLMCallLog(
          callId: 'c4',
          purpose: 'extraction',
          model: 'gpt-4',
          wasNecessary: false,
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.unnecessaryCallCount(logs), equals(2));
    });

    test('unnecessaryCallCost sums unnecessary costs', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.10,
          wasNecessary: true,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.05,
          wasNecessary: false,
          alternativeRuleId: 'rule-1',
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'extraction',
          model: 'gpt-4',
          cost: 0.03,
          wasNecessary: false,
          alternativeRuleId: 'rule-2',
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.unnecessaryCallCost(logs), closeTo(0.08, 0.001));
    });

    test('averageLatency calculates correctly', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          latencyMs: 100,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          latencyMs: 200,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'extraction',
          model: 'gpt-4',
          latencyMs: 300,
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.averageLatency(logs), equals(200.0));
    });

    test('averageLatency skips logs without latency', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          latencyMs: 100,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'extraction',
          model: 'gpt-4',
          latencyMs: 300,
          createdAt: now,
        ),
      ];

      // Only c1 and c3 have latency: (100+300)/2 = 200
      expect(LLMCostAnalytics.averageLatency(logs), equals(200.0));
    });

    test('averageLatency returns 0.0 when no logs have latency', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.averageLatency(logs), equals(0.0));
    });

    test('averageLatency returns 0.0 for empty list', () {
      expect(LLMCostAnalytics.averageLatency([]), equals(0.0));
    });

    test('successRate calculates correctly', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          success: true,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c2',
          purpose: 'extraction',
          model: 'gpt-4',
          success: true,
          createdAt: now,
        ),
        LLMCallLog(
          callId: 'c3',
          purpose: 'extraction',
          model: 'gpt-4',
          success: false,
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.successRate(logs), closeTo(2 / 3, 0.01));
    });

    test('successRate returns 0.0 for empty list', () {
      expect(LLMCostAnalytics.successRate([]), equals(0.0));
    });

    test('successRate returns 1.0 when all succeed', () {
      final logs = [
        LLMCallLog(
          callId: 'c1',
          purpose: 'extraction',
          model: 'gpt-4',
          success: true,
          createdAt: now,
        ),
      ];

      expect(LLMCostAnalytics.successRate(logs), equals(1.0));
    });
  });
}
