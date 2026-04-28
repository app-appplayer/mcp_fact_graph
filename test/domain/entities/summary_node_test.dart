import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // SummaryStatus enum
  // =========================================================================
  group('SummaryStatus', () {
    test('has all expected values', () {
      expect(SummaryStatus.values, contains(SummaryStatus.created));
      expect(SummaryStatus.values, contains(SummaryStatus.active));
      expect(SummaryStatus.values, contains(SummaryStatus.stale));
      expect(SummaryStatus.values, contains(SummaryStatus.refreshFail));
      expect(SummaryStatus.values, contains(SummaryStatus.archived));
      expect(SummaryStatus.values.length, equals(5));
    });

    test('fromString returns correct value for all variants', () {
      expect(
          SummaryStatus.fromString('created'), equals(SummaryStatus.created));
      expect(SummaryStatus.fromString('active'), equals(SummaryStatus.active));
      expect(SummaryStatus.fromString('stale'), equals(SummaryStatus.stale));
      expect(SummaryStatus.fromString('refreshFail'),
          equals(SummaryStatus.refreshFail));
      expect(
          SummaryStatus.fromString('archived'), equals(SummaryStatus.archived));
    });

    test('fromString returns active for invalid values', () {
      expect(SummaryStatus.fromString('unknown'), equals(SummaryStatus.active));
      expect(SummaryStatus.fromString(''), equals(SummaryStatus.active));
      expect(SummaryStatus.fromString('ACTIVE'), equals(SummaryStatus.active));
    });
  });

  // =========================================================================
  // SummaryPeriod class
  // =========================================================================
  group('SummaryPeriod', () {
    final startDate = DateTime(2024, 1, 1);
    final endDate = DateTime(2024, 6, 30);

    test('constructor with required fields', () {
      final period = SummaryPeriod(start: startDate, end: endDate);

      expect(period.start, equals(startDate));
      expect(period.end, equals(endDate));
    });

    test('fromJson complete', () {
      final json = {
        'start': '2024-01-01T00:00:00.000',
        'end': '2024-06-30T00:00:00.000',
      };

      final period = SummaryPeriod.fromJson(json);

      expect(period.start, equals(DateTime.parse('2024-01-01T00:00:00.000')));
      expect(period.end, equals(DateTime.parse('2024-06-30T00:00:00.000')));
    });

    test('fromJson missing fields uses DateTime.now defaults', () {
      final json = <String, dynamic>{};

      final period = SummaryPeriod.fromJson(json);

      // Should default to DateTime.now() - verify it is a valid DateTime
      expect(period.start, isA<DateTime>());
      expect(period.end, isA<DateTime>());
    });

    test('toJson outputs correct format', () {
      final period = SummaryPeriod(start: startDate, end: endDate);
      final json = period.toJson();

      expect(json['start'], equals(startDate.toIso8601String()));
      expect(json['end'], equals(endDate.toIso8601String()));
    });

    test('duration getter calculates difference', () {
      final period = SummaryPeriod(start: startDate, end: endDate);

      final expectedDuration = endDate.difference(startDate);
      expect(period.duration, equals(expectedDuration));
    });

    test('duration getter with same start and end', () {
      final sameDate = DateTime(2024, 3, 15);
      final period = SummaryPeriod(start: sameDate, end: sameDate);

      expect(period.duration, equals(Duration.zero));
    });
  });

  // =========================================================================
  // SummaryScope class
  // =========================================================================
  group('SummaryScope', () {
    test('constructor with required fields only', () {
      const scope = SummaryScope(scopeType: 'period');

      expect(scope.scopeType, equals('period'));
      expect(scope.entityId, isNull);
      expect(scope.period, isNull);
      expect(scope.topicId, isNull);
    });

    test('constructor with all fields', () {
      final period =
          SummaryPeriod(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30));
      final scope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-1',
        period: period,
        topicId: 'topic-1',
      );

      expect(scope.scopeType, equals('entity'));
      expect(scope.entityId, equals('ent-1'));
      expect(scope.period, isNotNull);
      expect(scope.topicId, equals('topic-1'));
    });

    test('fromJson complete', () {
      final json = {
        'scopeType': 'topic',
        'entityId': 'ent-2',
        'period': {
          'start': '2024-01-01T00:00:00.000',
          'end': '2024-06-30T00:00:00.000',
        },
        'topicId': 'topic-2',
      };

      final scope = SummaryScope.fromJson(json);

      expect(scope.scopeType, equals('topic'));
      expect(scope.entityId, equals('ent-2'));
      expect(scope.period, isNotNull);
      expect(scope.period!.start,
          equals(DateTime.parse('2024-01-01T00:00:00.000')));
      expect(scope.topicId, equals('topic-2'));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final scope = SummaryScope.fromJson(json);

      expect(scope.scopeType, equals('period'));
      expect(scope.entityId, isNull);
      expect(scope.period, isNull);
      expect(scope.topicId, isNull);
    });

    test('toJson populated with all fields', () {
      final period =
          SummaryPeriod(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30));
      final scope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-3',
        period: period,
        topicId: 'topic-3',
      );

      final json = scope.toJson();

      expect(json['scopeType'], equals('entity'));
      expect(json['entityId'], equals('ent-3'));
      expect(json.containsKey('period'), isTrue);
      expect(json['topicId'], equals('topic-3'));
    });

    test('toJson excludes null fields', () {
      const scope = SummaryScope(scopeType: 'period');
      final json = scope.toJson();

      expect(json['scopeType'], equals('period'));
      expect(json.containsKey('entityId'), isFalse);
      expect(json.containsKey('period'), isFalse);
      expect(json.containsKey('topicId'), isFalse);
    });
  });

  // =========================================================================
  // SummaryNode entity
  // =========================================================================
  group('SummaryNode', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);
    const defaultScope = SummaryScope(scopeType: 'period');

    test('constructor with required fields only', () {
      final node = SummaryNode(
        summaryId: 'sum-1',
        workspaceId: 'ws-1',
        summaryText: 'Monthly summary of expenses',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      expect(node.summaryId, equals('sum-1'));
      expect(node.workspaceId, equals('ws-1'));
      expect(node.summaryText, equals('Monthly summary of expenses'));
      expect(node.coversFactIds, isEmpty);
      expect(node.asOf, equals(now));
      expect(node.policyVersion, equals('1.0.0'));
      expect(node.supersedes, isNull);
      expect(node.status, equals(SummaryStatus.active));
      expect(node.scope.scopeType, equals('period'));
      expect(node.metadata, isNull);
      expect(node.createdAt, equals(now));
      expect(node.updatedAt, equals(now));
    });

    test('constructor with all fields', () {
      final scope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-1',
        period: SummaryPeriod(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30)),
        topicId: 'topic-1',
      );

      final node = SummaryNode(
        summaryId: 'sum-2',
        workspaceId: 'ws-2',
        summaryText: 'Quarterly summary',
        coversFactIds: ['f-1', 'f-2', 'f-3'],
        asOf: now,
        policyVersion: '2.0.0',
        supersedes: 'sum-1',
        status: SummaryStatus.stale,
        scope: scope,
        metadata: {'generator': 'llm-v3'},
        createdAt: now,
        updatedAt: later,
      );

      expect(node.summaryId, equals('sum-2'));
      expect(node.coversFactIds, equals(['f-1', 'f-2', 'f-3']));
      expect(node.policyVersion, equals('2.0.0'));
      expect(node.supersedes, equals('sum-1'));
      expect(node.status, equals(SummaryStatus.stale));
      expect(node.scope.scopeType, equals('entity'));
      expect(node.scope.entityId, equals('ent-1'));
      expect(node.metadata, equals({'generator': 'llm-v3'}));
    });

    test('fromJson complete', () {
      final json = {
        'summaryId': 'sum-3',
        'workspaceId': 'ws-3',
        'summaryText': 'JSON summary',
        'coversFactIds': ['f-10', 'f-20'],
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '3.0.0',
        'supersedes': 'sum-2',
        'status': 'refreshFail',
        'scope': {
          'scopeType': 'topic',
          'topicId': 'topic-5',
        },
        'metadata': {'source': 'auto'},
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-07-15T10:00:00.000',
      };

      final node = SummaryNode.fromJson(json);

      expect(node.summaryId, equals('sum-3'));
      expect(node.workspaceId, equals('ws-3'));
      expect(node.summaryText, equals('JSON summary'));
      expect(node.coversFactIds, equals(['f-10', 'f-20']));
      expect(node.asOf, equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(node.policyVersion, equals('3.0.0'));
      expect(node.supersedes, equals('sum-2'));
      expect(node.status, equals(SummaryStatus.refreshFail));
      expect(node.scope.scopeType, equals('topic'));
      expect(node.scope.topicId, equals('topic-5'));
      expect(node.metadata, equals({'source': 'auto'}));
      expect(node.createdAt, equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(node.updatedAt, equals(DateTime.parse('2024-07-15T10:00:00.000')));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final node = SummaryNode.fromJson(json);

      expect(node.summaryId, equals(''));
      expect(node.workspaceId, equals('default'));
      expect(node.summaryText, equals(''));
      expect(node.coversFactIds, isEmpty);
      expect(node.policyVersion, equals('1.0.0'));
      expect(node.supersedes, isNull);
      expect(node.status, equals(SummaryStatus.active));
      expect(node.scope.scopeType, equals('period'));
      expect(node.metadata, isNull);
    });

    test('toJson populated', () {
      final scope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-4',
      );

      final node = SummaryNode(
        summaryId: 'sum-4',
        workspaceId: 'ws-4',
        summaryText: 'ToJson test',
        coversFactIds: ['f-1'],
        asOf: now,
        policyVersion: '1.0.0',
        supersedes: 'sum-3',
        status: SummaryStatus.archived,
        scope: scope,
        metadata: {'key': 'value'},
        createdAt: now,
        updatedAt: later,
      );

      final json = node.toJson();

      expect(json['summaryId'], equals('sum-4'));
      expect(json['workspaceId'], equals('ws-4'));
      expect(json['summaryText'], equals('ToJson test'));
      expect(json['coversFactIds'], equals(['f-1']));
      expect(json['asOf'], equals(now.toIso8601String()));
      expect(json['policyVersion'], equals('1.0.0'));
      expect(json['supersedes'], equals('sum-3'));
      expect(json['status'], equals('archived'));
      expect(json['scope'], isA<Map<String, dynamic>>());
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final node = SummaryNode(
        summaryId: 'sum-5',
        workspaceId: 'ws-5',
        summaryText: 'Minimal',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      final json = node.toJson();

      expect(json.containsKey('coversFactIds'), isFalse);
      expect(json.containsKey('supersedes'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Always present
      expect(json.containsKey('summaryId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('summaryText'), isTrue);
      expect(json.containsKey('asOf'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('scope'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('toJson excludes metadata when it is empty map', () {
      final node = SummaryNode(
        summaryId: 'sum-empty-meta',
        workspaceId: 'ws-1',
        summaryText: 'Empty metadata test',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        metadata: {},
        createdAt: now,
        updatedAt: now,
      );

      final json = node.toJson();
      // metadata is {} (not null) but empty, so should be excluded
      expect(json.containsKey('metadata'), isFalse);
    });

    test('copyWith modifies specified fields', () {
      final original = SummaryNode(
        summaryId: 'sum-6',
        workspaceId: 'ws-6',
        summaryText: 'Original text',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      final newScope = SummaryScope(scopeType: 'topic', topicId: 'tp-1');

      final copy = original.copyWith(
        summaryText: 'Updated text',
        coversFactIds: ['new-f-1'],
        policyVersion: '2.0.0',
        supersedes: 'sum-5',
        status: SummaryStatus.stale,
        scope: newScope,
        metadata: {'updated': true},
        updatedAt: later,
      );

      // Unchanged
      expect(copy.summaryId, equals('sum-6'));
      expect(copy.workspaceId, equals('ws-6'));
      expect(copy.asOf, equals(now));
      expect(copy.createdAt, equals(now));

      // Changed
      expect(copy.summaryText, equals('Updated text'));
      expect(copy.coversFactIds, equals(['new-f-1']));
      expect(copy.policyVersion, equals('2.0.0'));
      expect(copy.supersedes, equals('sum-5'));
      expect(copy.status, equals(SummaryStatus.stale));
      expect(copy.scope.scopeType, equals('topic'));
      expect(copy.metadata, equals({'updated': true}));
      expect(copy.updatedAt, equals(later));
    });

    test('toString returns expected format', () {
      final node = SummaryNode(
        summaryId: 'sum-str',
        workspaceId: 'ws-1',
        summaryText: 'ToString test',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      expect(node.toString(), equals('SummaryNode(sum-str, scope: period)'));
    });

    test('equality compares by summaryId', () {
      final node1 = SummaryNode(
        summaryId: 'sum-eq',
        workspaceId: 'ws-1',
        summaryText: 'Text A',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      final node2 = SummaryNode(
        summaryId: 'sum-eq',
        workspaceId: 'ws-2',
        summaryText: 'Text B',
        asOf: later,
        policyVersion: '2.0.0',
        scope: const SummaryScope(scopeType: 'topic'),
        createdAt: later,
        updatedAt: later,
      );

      final node3 = SummaryNode(
        summaryId: 'sum-different',
        workspaceId: 'ws-1',
        summaryText: 'Text A',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      expect(node1 == node2, isTrue);
      expect(node1 == node3, isFalse);
      expect(node1.hashCode, equals(node2.hashCode));
    });

    test('equality with identical reference', () {
      final node = SummaryNode(
        summaryId: 'sum-id',
        workspaceId: 'ws-1',
        summaryText: 'Self',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      expect(node == node, isTrue);
    });

    test('equality with non-SummaryNode object', () {
      final node = SummaryNode(
        summaryId: 'sum-id',
        workspaceId: 'ws-1',
        summaryText: 'Type check',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      expect(node == Object(), isFalse);
    });

    test('copyWith all parameters', () {
      final original = SummaryNode(
        summaryId: 'sum-orig',
        workspaceId: 'ws-orig',
        summaryText: 'Original',
        coversFactIds: ['f-1'],
        asOf: now,
        policyVersion: '1.0.0',
        supersedes: 'sum-prev',
        status: SummaryStatus.active,
        scope: defaultScope,
        metadata: {'k': 'v'},
        createdAt: now,
        updatedAt: now,
      );

      final newScope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-new',
        period: SummaryPeriod(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30)),
        topicId: 'topic-new',
      );

      final copy = original.copyWith(
        summaryId: 'sum-new',
        workspaceId: 'ws-new',
        summaryText: 'New text',
        coversFactIds: ['f-2', 'f-3'],
        asOf: later,
        policyVersion: '2.0.0',
        supersedes: 'sum-orig',
        status: SummaryStatus.stale,
        scope: newScope,
        metadata: {'new': true},
        createdAt: later,
        updatedAt: later,
      );

      expect(copy.summaryId, equals('sum-new'));
      expect(copy.workspaceId, equals('ws-new'));
      expect(copy.summaryText, equals('New text'));
      expect(copy.coversFactIds, equals(['f-2', 'f-3']));
      expect(copy.asOf, equals(later));
      expect(copy.policyVersion, equals('2.0.0'));
      expect(copy.supersedes, equals('sum-orig'));
      expect(copy.status, equals(SummaryStatus.stale));
      expect(copy.scope.scopeType, equals('entity'));
      expect(copy.scope.entityId, equals('ent-new'));
      expect(copy.scope.topicId, equals('topic-new'));
      expect(copy.metadata, equals({'new': true}));
      expect(copy.createdAt, equals(later));
      expect(copy.updatedAt, equals(later));
    });

    test('copyWith no arguments returns equivalent node', () {
      final original = SummaryNode(
        summaryId: 'sum-no-change',
        workspaceId: 'ws-1',
        summaryText: 'No change',
        asOf: now,
        policyVersion: '1.0.0',
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.summaryId, equals(original.summaryId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.summaryText, equals(original.summaryText));
      expect(copy.coversFactIds, equals(original.coversFactIds));
      expect(copy.asOf, equals(original.asOf));
      expect(copy.policyVersion, equals(original.policyVersion));
      expect(copy.supersedes, equals(original.supersedes));
      expect(copy.status, equals(original.status));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('fromJson without scope uses default scope', () {
      final json = {
        'summaryId': 'sum-no-scope',
        'workspaceId': 'ws-1',
        'summaryText': 'No scope provided',
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '1.0.0',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-15T10:00:00.000',
      };

      final node = SummaryNode.fromJson(json);

      // scope defaults to SummaryScope(scopeType: 'period')
      expect(node.scope.scopeType, equals('period'));
    });

    test('fromJson roundtrip preserves all data', () {
      final scope = SummaryScope(
        scopeType: 'topic',
        entityId: 'ent-rt',
        period: SummaryPeriod(start: DateTime(2024, 1, 1), end: DateTime(2024, 6, 30)),
        topicId: 'topic-rt',
      );

      final original = SummaryNode(
        summaryId: 'sum-rt',
        workspaceId: 'ws-rt',
        summaryText: 'Roundtrip test',
        coversFactIds: ['f-a', 'f-b'],
        asOf: now,
        policyVersion: '2.0.0',
        supersedes: 'sum-prev',
        status: SummaryStatus.refreshFail,
        scope: scope,
        metadata: {'round': 'trip'},
        createdAt: now,
        updatedAt: later,
      );

      final json = original.toJson();
      final restored = SummaryNode.fromJson(json);

      expect(restored.summaryId, equals(original.summaryId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.summaryText, equals(original.summaryText));
      expect(restored.coversFactIds, equals(original.coversFactIds));
      expect(restored.policyVersion, equals(original.policyVersion));
      expect(restored.supersedes, equals(original.supersedes));
      expect(restored.status, equals(original.status));
      expect(restored.scope.scopeType, equals(original.scope.scopeType));
      expect(restored.scope.entityId, equals(original.scope.entityId));
      expect(restored.scope.topicId, equals(original.scope.topicId));
      expect(restored.scope.period, isNotNull);
      expect(restored.metadata, equals(original.metadata));
    });

    test('toJson with status created', () {
      final node = SummaryNode(
        summaryId: 'sum-created',
        workspaceId: 'ws-1',
        summaryText: 'Created status test',
        asOf: now,
        policyVersion: '1.0.0',
        status: SummaryStatus.created,
        scope: defaultScope,
        createdAt: now,
        updatedAt: now,
      );

      final json = node.toJson();
      expect(json['status'], equals('created'));
    });
  });

  // =========================================================================
  // SummaryScope additional tests
  // =========================================================================
  group('SummaryScope additional', () {
    test('fromJson with only scopeType', () {
      final json = {'scopeType': 'entity'};
      final scope = SummaryScope.fromJson(json);

      expect(scope.scopeType, equals('entity'));
      expect(scope.entityId, isNull);
      expect(scope.period, isNull);
      expect(scope.topicId, isNull);
    });

    test('toJson with entityId only', () {
      const scope = SummaryScope(
        scopeType: 'entity',
        entityId: 'ent-only',
      );

      final json = scope.toJson();

      expect(json['scopeType'], equals('entity'));
      expect(json['entityId'], equals('ent-only'));
      expect(json.containsKey('period'), isFalse);
      expect(json.containsKey('topicId'), isFalse);
    });

    test('toJson with topicId only', () {
      const scope = SummaryScope(
        scopeType: 'topic',
        topicId: 'topic-only',
      );

      final json = scope.toJson();

      expect(json['scopeType'], equals('topic'));
      expect(json.containsKey('entityId'), isFalse);
      expect(json.containsKey('period'), isFalse);
      expect(json['topicId'], equals('topic-only'));
    });
  });

  // =========================================================================
  // SummaryPeriod additional tests
  // =========================================================================
  group('SummaryPeriod additional', () {
    test('constructor stores values', () {
      final start = DateTime(2024, 3, 1);
      final end = DateTime(2024, 3, 31);
      final period = SummaryPeriod(start: start, end: end);

      expect(period.start, equals(start));
      expect(period.end, equals(end));
      expect(period.duration.inDays, equals(30));
    });

    test('fromJson roundtrip', () {
      final original = SummaryPeriod(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );
      final json = original.toJson();
      final restored = SummaryPeriod.fromJson(json);

      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
      expect(restored.duration, equals(original.duration));
    });
  });
}
