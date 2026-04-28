import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // OpenQuestion class
  // =========================================================================
  group('OpenQuestion', () {
    test('constructor with required fields only', () {
      const q = OpenQuestion(
        questionId: 'q-1',
        questionType: 'unresolved',
        description: 'Missing deadline',
      );

      expect(q.questionId, equals('q-1'));
      expect(q.questionType, equals('unresolved'));
      expect(q.description, equals('Missing deadline'));
      expect(q.relatedIds, isEmpty);
      expect(q.reasonCode, isNull);
    });

    test('constructor with all fields', () {
      const q = OpenQuestion(
        questionId: 'q-2',
        questionType: 'conflict',
        description: 'Conflicting dates',
        relatedIds: ['cand-1', 'cand-2'],
        reasonCode: 'DATE_CONFLICT',
      );

      expect(q.questionId, equals('q-2'));
      expect(q.questionType, equals('conflict'));
      expect(q.description, equals('Conflicting dates'));
      expect(q.relatedIds, equals(['cand-1', 'cand-2']));
      expect(q.reasonCode, equals('DATE_CONFLICT'));
    });

    test('fromJson complete', () {
      final json = {
        'questionId': 'q-3',
        'questionType': 'missingEvidence',
        'description': 'No supporting docs',
        'relatedIds': ['ref-1', 'ref-2'],
        'reasonCode': 'NO_DOCS',
      };

      final q = OpenQuestion.fromJson(json);

      expect(q.questionId, equals('q-3'));
      expect(q.questionType, equals('missingEvidence'));
      expect(q.description, equals('No supporting docs'));
      expect(q.relatedIds, equals(['ref-1', 'ref-2']));
      expect(q.reasonCode, equals('NO_DOCS'));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final q = OpenQuestion.fromJson(json);

      expect(q.questionId, equals(''));
      expect(q.questionType, equals('unresolved'));
      expect(q.description, equals(''));
      expect(q.relatedIds, isEmpty);
      expect(q.reasonCode, isNull);
    });

    test('toJson populated', () {
      const q = OpenQuestion(
        questionId: 'q-4',
        questionType: 'conflict',
        description: 'Overlap detected',
        relatedIds: ['item-1'],
        reasonCode: 'OVERLAP',
      );

      final json = q.toJson();

      expect(json['questionId'], equals('q-4'));
      expect(json['questionType'], equals('conflict'));
      expect(json['description'], equals('Overlap detected'));
      expect(json['relatedIds'], equals(['item-1']));
      expect(json['reasonCode'], equals('OVERLAP'));
    });

    test('toJson excludes empty/null fields', () {
      const q = OpenQuestion(
        questionId: 'q-5',
        questionType: 'unresolved',
        description: 'Minimal question',
      );

      final json = q.toJson();

      expect(json.containsKey('relatedIds'), isFalse);
      expect(json.containsKey('reasonCode'), isFalse);
      expect(json.containsKey('questionId'), isTrue);
      expect(json.containsKey('questionType'), isTrue);
      expect(json.containsKey('description'), isTrue);
    });
  });

  // =========================================================================
  // BundleBudget class
  // =========================================================================
  group('BundleBudget', () {
    test('constructor with default values', () {
      const budget = BundleBudget();

      expect(budget.maxNodes, equals(100));
      expect(budget.maxTokens, equals(4096));
      expect(budget.maxSentences, equals(50));
    });

    test('constructor with custom values', () {
      const budget = BundleBudget(
        maxNodes: 200,
        maxTokens: 8192,
        maxSentences: 100,
      );

      expect(budget.maxNodes, equals(200));
      expect(budget.maxTokens, equals(8192));
      expect(budget.maxSentences, equals(100));
    });

    test('fromJson complete', () {
      final json = {
        'maxNodes': 50,
        'maxTokens': 2048,
        'maxSentences': 25,
      };

      final budget = BundleBudget.fromJson(json);

      expect(budget.maxNodes, equals(50));
      expect(budget.maxTokens, equals(2048));
      expect(budget.maxSentences, equals(25));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final budget = BundleBudget.fromJson(json);

      expect(budget.maxNodes, equals(100));
      expect(budget.maxTokens, equals(4096));
      expect(budget.maxSentences, equals(50));
    });

    test('toJson outputs all fields', () {
      const budget = BundleBudget(
        maxNodes: 75,
        maxTokens: 3000,
        maxSentences: 40,
      );

      final json = budget.toJson();

      expect(json['maxNodes'], equals(75));
      expect(json['maxTokens'], equals(3000));
      expect(json['maxSentences'], equals(40));
    });

    test('copyWith modifies specified fields', () {
      const original = BundleBudget(
        maxNodes: 100,
        maxTokens: 4096,
        maxSentences: 50,
      );

      final copy = original.copyWith(maxTokens: 8192, maxSentences: 80);

      expect(copy.maxNodes, equals(100));
      expect(copy.maxTokens, equals(8192));
      expect(copy.maxSentences, equals(80));
    });

    test('copyWith with no arguments returns equivalent budget', () {
      const original = BundleBudget(maxNodes: 10, maxTokens: 500, maxSentences: 5);
      final copy = original.copyWith();

      expect(copy.maxNodes, equals(original.maxNodes));
      expect(copy.maxTokens, equals(original.maxTokens));
      expect(copy.maxSentences, equals(original.maxSentences));
    });
  });

  // =========================================================================
  // InternalContextBundle entity
  // =========================================================================
  group('InternalContextBundle', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);

    test('constructor with required fields only', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-1',
        workspaceId: 'ws-1',
        query: 'What happened last week?',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(bundle.bundleId, equals('bun-1'));
      expect(bundle.workspaceId, equals('ws-1'));
      expect(bundle.query, equals('What happened last week?'));
      expect(bundle.facts, isEmpty);
      expect(bundle.summaries, isEmpty);
      expect(bundle.evidenceRefs, isEmpty);
      expect(bundle.openQuestions, isEmpty);
      expect(bundle.tokenEstimate, equals(0));
      expect(bundle.asOf, equals(now));
      expect(bundle.policyVersion, equals('1.0.0'));
      expect(bundle.budget.maxTokens, equals(4096));
      expect(bundle.createdAt, equals(now));
      expect(bundle.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final fact = Fact(
        factId: 'f-1',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Coffee',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      final summaryNode = SummaryNode(
        summaryId: 'sum-1',
        workspaceId: 'ws-1',
        summaryText: 'Weekly summary',
        asOf: now,
        policyVersion: '1.0.0',
        scope: const SummaryScope(scopeType: 'period'),
        createdAt: now,
        updatedAt: now,
      );

      const question = OpenQuestion(
        questionId: 'q-1',
        questionType: 'unresolved',
        description: 'Missing info',
      );

      const budget = BundleBudget(maxTokens: 8192);

      final bundle = InternalContextBundle(
        bundleId: 'bun-2',
        workspaceId: 'ws-2',
        query: 'Full bundle test',
        facts: [fact],
        summaries: [summaryNode],
        evidenceRefs: ['ev-1', 'ev-2'],
        openQuestions: [question],
        tokenEstimate: 1500,
        asOf: now,
        policyVersion: '2.0.0',
        budget: budget,
        createdAt: now,
        metadata: {'source': 'test'},
      );

      expect(bundle.facts.length, equals(1));
      expect(bundle.facts.first.factId, equals('f-1'));
      expect(bundle.summaries.length, equals(1));
      expect(bundle.summaries.first.summaryId, equals('sum-1'));
      expect(bundle.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(bundle.openQuestions.length, equals(1));
      expect(bundle.tokenEstimate, equals(1500));
      expect(bundle.budget.maxTokens, equals(8192));
      expect(bundle.metadata, equals({'source': 'test'}));
    });

    test('fromJson complete', () {
      final json = {
        'bundleId': 'bun-3',
        'workspaceId': 'ws-3',
        'query': 'JSON bundle test',
        'facts': [
          {
            'factId': 'f-1',
            'workspaceId': 'ws-1',
            'factType': 'meeting',
            'summary': 'Standup',
            'occurredAt': '2024-06-15T10:00:00.000',
            'candidateId': 'cand-1',
            'createdAt': '2024-06-15T10:00:00.000',
          }
        ],
        'summaries': [
          {
            'summaryId': 'sum-1',
            'workspaceId': 'ws-1',
            'summaryText': 'Summary',
            'asOf': '2024-06-15T10:00:00.000',
            'policyVersion': '1.0.0',
            'scope': {'scopeType': 'period'},
            'createdAt': '2024-06-15T10:00:00.000',
            'updatedAt': '2024-06-15T10:00:00.000',
          }
        ],
        'evidenceRefs': ['ev-1'],
        'openQuestions': [
          {
            'questionId': 'q-1',
            'questionType': 'conflict',
            'description': 'Test question',
          }
        ],
        'tokenEstimate': 2500,
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '3.0.0',
        'budget': {
          'maxNodes': 50,
          'maxTokens': 2048,
          'maxSentences': 20,
        },
        'createdAt': '2024-06-15T10:00:00.000',
        'metadata': {'key': 'val'},
      };

      final bundle = InternalContextBundle.fromJson(json);

      expect(bundle.bundleId, equals('bun-3'));
      expect(bundle.workspaceId, equals('ws-3'));
      expect(bundle.query, equals('JSON bundle test'));
      expect(bundle.facts.length, equals(1));
      expect(bundle.facts.first.factId, equals('f-1'));
      expect(bundle.summaries.length, equals(1));
      expect(bundle.summaries.first.summaryId, equals('sum-1'));
      expect(bundle.evidenceRefs, equals(['ev-1']));
      expect(bundle.openQuestions.length, equals(1));
      expect(bundle.openQuestions.first.questionId, equals('q-1'));
      expect(bundle.tokenEstimate, equals(2500));
      expect(bundle.policyVersion, equals('3.0.0'));
      expect(bundle.budget.maxNodes, equals(50));
      expect(bundle.budget.maxTokens, equals(2048));
      expect(bundle.budget.maxSentences, equals(20));
      expect(bundle.metadata, equals({'key': 'val'}));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final bundle = InternalContextBundle.fromJson(json);

      expect(bundle.bundleId, equals(''));
      expect(bundle.workspaceId, equals('default'));
      expect(bundle.query, equals(''));
      expect(bundle.facts, isEmpty);
      expect(bundle.summaries, isEmpty);
      expect(bundle.evidenceRefs, isEmpty);
      expect(bundle.openQuestions, isEmpty);
      expect(bundle.tokenEstimate, equals(0));
      expect(bundle.policyVersion, equals('1.0.0'));
      expect(bundle.budget.maxNodes, equals(100));
      expect(bundle.budget.maxTokens, equals(4096));
      expect(bundle.metadata, isEmpty);
    });

    test('toJson populated', () {
      final fact = Fact(
        factId: 'f-1',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Coffee',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      const question = OpenQuestion(
        questionId: 'q-1',
        questionType: 'unresolved',
        description: 'Missing info',
      );

      final summaryNode = SummaryNode(
        summaryId: 'sum-1',
        workspaceId: 'ws-1',
        summaryText: 'Summary',
        asOf: now,
        policyVersion: '1.0.0',
        scope: const SummaryScope(scopeType: 'period'),
        createdAt: now,
        updatedAt: now,
      );

      final bundle = InternalContextBundle(
        bundleId: 'bun-tj',
        workspaceId: 'ws-tj',
        query: 'ToJson test',
        facts: [fact],
        summaries: [summaryNode],
        evidenceRefs: ['ev-1'],
        openQuestions: [question],
        tokenEstimate: 1000,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 2048),
        createdAt: now,
        metadata: {'source': 'test'},
      );

      final json = bundle.toJson();

      expect(json['bundleId'], equals('bun-tj'));
      expect(json['workspaceId'], equals('ws-tj'));
      expect(json['query'], equals('ToJson test'));
      expect(json['facts'], isA<List>());
      expect((json['facts'] as List).length, equals(1));
      expect(json['summaries'], isA<List>());
      expect((json['summaries'] as List).length, equals(1));
      expect(json['evidenceRefs'], equals(['ev-1']));
      expect(json['openQuestions'], isA<List>());
      expect((json['openQuestions'] as List).length, equals(1));
      expect(json['tokenEstimate'], equals(1000));
      expect(json['asOf'], equals(now.toIso8601String()));
      expect(json['policyVersion'], equals('1.0.0'));
      expect(json['budget'], isA<Map<String, dynamic>>());
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['metadata'], equals({'source': 'test'}));
    });

    test('toJson excludes empty/null fields', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-min',
        workspaceId: 'ws-min',
        query: 'Minimal',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      final json = bundle.toJson();

      expect(json.containsKey('facts'), isFalse);
      expect(json.containsKey('summaries'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('openQuestions'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Always present
      expect(json.containsKey('bundleId'), isTrue);
      expect(json.containsKey('workspaceId'), isTrue);
      expect(json.containsKey('query'), isTrue);
      expect(json.containsKey('tokenEstimate'), isTrue);
      expect(json.containsKey('asOf'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('budget'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = InternalContextBundle(
        bundleId: 'bun-cw',
        workspaceId: 'ws-cw',
        query: 'Original query',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      final copy = original.copyWith(
        query: 'Updated query',
        tokenEstimate: 5000,
        policyVersion: '2.0.0',
        budget: const BundleBudget(maxTokens: 10000),
        metadata: {'updated': true},
      );

      // Unchanged
      expect(copy.bundleId, equals('bun-cw'));
      expect(copy.workspaceId, equals('ws-cw'));
      expect(copy.asOf, equals(now));
      expect(copy.createdAt, equals(now));

      // Changed
      expect(copy.query, equals('Updated query'));
      expect(copy.tokenEstimate, equals(5000));
      expect(copy.policyVersion, equals('2.0.0'));
      expect(copy.budget.maxTokens, equals(10000));
      expect(copy.metadata, equals({'updated': true}));
    });

    test('isWithinBudget getter checks token estimate against budget', () {
      final withinBudget = InternalContextBundle(
        bundleId: 'bun-b1',
        workspaceId: 'ws-1',
        query: 'Within budget',
        tokenEstimate: 4000,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 4096),
        createdAt: now,
      );

      final exactBudget = InternalContextBundle(
        bundleId: 'bun-b2',
        workspaceId: 'ws-1',
        query: 'Exact budget',
        tokenEstimate: 4096,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 4096),
        createdAt: now,
      );

      final overBudget = InternalContextBundle(
        bundleId: 'bun-b3',
        workspaceId: 'ws-1',
        query: 'Over budget',
        tokenEstimate: 5000,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 4096),
        createdAt: now,
      );

      expect(withinBudget.isWithinBudget, isTrue);
      expect(exactBudget.isWithinBudget, isTrue);
      expect(overBudget.isWithinBudget, isFalse);
    });

    test('hasOpenQuestions getter', () {
      final noQuestions = InternalContextBundle(
        bundleId: 'bun-q1',
        workspaceId: 'ws-1',
        query: 'No questions',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      final withQuestions = InternalContextBundle(
        bundleId: 'bun-q2',
        workspaceId: 'ws-1',
        query: 'Has questions',
        openQuestions: const [
          OpenQuestion(
            questionId: 'q-1',
            questionType: 'unresolved',
            description: 'Why?',
          ),
        ],
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(noQuestions.hasOpenQuestions, isFalse);
      expect(withQuestions.hasOpenQuestions, isTrue);
    });

    test('toString returns expected format', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-str',
        workspaceId: 'ws-1',
        query: 'Test',
        tokenEstimate: 1500,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 4096),
        createdAt: now,
      );

      expect(bundle.toString(),
          equals('InternalContextBundle(bun-str, tokens: 1500/4096)'));
    });

    test('equality compares by bundleId', () {
      final bundle1 = InternalContextBundle(
        bundleId: 'bun-eq',
        workspaceId: 'ws-1',
        query: 'Query A',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      final bundle2 = InternalContextBundle(
        bundleId: 'bun-eq',
        workspaceId: 'ws-2',
        query: 'Query B',
        asOf: later,
        policyVersion: '2.0.0',
        createdAt: later,
      );

      final bundle3 = InternalContextBundle(
        bundleId: 'bun-different',
        workspaceId: 'ws-1',
        query: 'Query A',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(bundle1 == bundle2, isTrue);
      expect(bundle1 == bundle3, isFalse);
      expect(bundle1.hashCode, equals(bundle2.hashCode));
    });

    test('equality with identical reference', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-id',
        workspaceId: 'ws-1',
        query: 'Self',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(bundle == bundle, isTrue);
    });

    test('equality with non-InternalContextBundle object', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-id',
        workspaceId: 'ws-1',
        query: 'Type check',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(bundle == Object(), isFalse);
    });

    test('hashCode is based on bundleId', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-hash',
        workspaceId: 'ws-1',
        query: 'Hash test',
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      expect(bundle.hashCode, equals('bun-hash'.hashCode));
    });

    test('copyWith all parameters', () {
      final fact = Fact(
        factId: 'f-orig',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Coffee',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      final summaryNode = SummaryNode(
        summaryId: 'sum-orig',
        workspaceId: 'ws-1',
        summaryText: 'Summary',
        asOf: now,
        policyVersion: '1.0.0',
        scope: const SummaryScope(scopeType: 'period'),
        createdAt: now,
        updatedAt: now,
      );

      final original = InternalContextBundle(
        bundleId: 'bun-cw-all',
        workspaceId: 'ws-1',
        query: 'Original',
        facts: [fact],
        summaries: [summaryNode],
        evidenceRefs: ['ev-1'],
        openQuestions: const [
          OpenQuestion(
            questionId: 'q-1',
            questionType: 'unresolved',
            description: 'Why?',
          ),
        ],
        tokenEstimate: 1000,
        asOf: now,
        policyVersion: '1.0.0',
        budget: const BundleBudget(maxTokens: 4096),
        createdAt: now,
        metadata: {'orig': true},
      );

      final newFact = Fact(
        factId: 'f-new',
        workspaceId: 'ws-2',
        factType: 'meeting',
        summary: 'Standup',
        occurredAt: later,
        candidateId: 'cand-2',
        createdAt: later,
      );

      final newSummary = SummaryNode(
        summaryId: 'sum-new',
        workspaceId: 'ws-2',
        summaryText: 'New summary',
        asOf: later,
        policyVersion: '2.0.0',
        scope: const SummaryScope(scopeType: 'topic'),
        createdAt: later,
        updatedAt: later,
      );

      final copy = original.copyWith(
        bundleId: 'bun-cw-new',
        workspaceId: 'ws-2',
        query: 'New query',
        facts: [newFact],
        summaries: [newSummary],
        evidenceRefs: ['ev-2', 'ev-3'],
        openQuestions: const [
          OpenQuestion(
            questionId: 'q-2',
            questionType: 'conflict',
            description: 'Conflict',
          ),
        ],
        tokenEstimate: 3000,
        asOf: later,
        policyVersion: '2.0.0',
        budget: const BundleBudget(maxTokens: 8192),
        createdAt: later,
        metadata: {'new': true},
      );

      expect(copy.bundleId, equals('bun-cw-new'));
      expect(copy.workspaceId, equals('ws-2'));
      expect(copy.query, equals('New query'));
      expect(copy.facts, hasLength(1));
      expect(copy.facts.first.factId, equals('f-new'));
      expect(copy.summaries, hasLength(1));
      expect(copy.summaries.first.summaryId, equals('sum-new'));
      expect(copy.evidenceRefs, equals(['ev-2', 'ev-3']));
      expect(copy.openQuestions, hasLength(1));
      expect(copy.openQuestions.first.questionId, equals('q-2'));
      expect(copy.tokenEstimate, equals(3000));
      expect(copy.asOf, equals(later));
      expect(copy.policyVersion, equals('2.0.0'));
      expect(copy.budget.maxTokens, equals(8192));
      expect(copy.createdAt, equals(later));
      expect(copy.metadata, equals({'new': true}));
    });

    test('copyWith no arguments returns equivalent bundle', () {
      final original = InternalContextBundle(
        bundleId: 'bun-no-change',
        workspaceId: 'ws-1',
        query: 'No change',
        tokenEstimate: 500,
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
        metadata: {'k': 'v'},
      );

      final copy = original.copyWith();

      expect(copy.bundleId, equals(original.bundleId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.query, equals(original.query));
      expect(copy.facts, equals(original.facts));
      expect(copy.summaries, equals(original.summaries));
      expect(copy.evidenceRefs, equals(original.evidenceRefs));
      expect(copy.openQuestions, equals(original.openQuestions));
      expect(copy.tokenEstimate, equals(original.tokenEstimate));
      expect(copy.asOf, equals(original.asOf));
      expect(copy.policyVersion, equals(original.policyVersion));
      expect(copy.budget.maxTokens, equals(original.budget.maxTokens));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.metadata, equals(original.metadata));
    });

    test('fromJson without budget uses default BundleBudget', () {
      final json = {
        'bundleId': 'bun-no-budget',
        'workspaceId': 'ws-1',
        'query': 'No budget',
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '1.0.0',
        'createdAt': '2024-06-15T10:00:00.000',
      };

      final bundle = InternalContextBundle.fromJson(json);

      expect(bundle.budget.maxNodes, equals(100));
      expect(bundle.budget.maxTokens, equals(4096));
      expect(bundle.budget.maxSentences, equals(50));
    });

    test('fromJson with openQuestions', () {
      final json = {
        'bundleId': 'bun-oq',
        'workspaceId': 'ws-1',
        'query': 'Questions test',
        'openQuestions': [
          {
            'questionId': 'q-1',
            'questionType': 'conflict',
            'description': 'Conflicting dates',
            'relatedIds': ['cand-1', 'cand-2'],
            'reasonCode': 'DATE_CONFLICT',
          },
          {
            'questionId': 'q-2',
            'questionType': 'missingEvidence',
            'description': 'No docs',
          },
        ],
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '1.0.0',
        'createdAt': '2024-06-15T10:00:00.000',
      };

      final bundle = InternalContextBundle.fromJson(json);

      expect(bundle.openQuestions, hasLength(2));
      expect(bundle.openQuestions[0].questionId, equals('q-1'));
      expect(bundle.openQuestions[0].relatedIds, equals(['cand-1', 'cand-2']));
      expect(bundle.openQuestions[0].reasonCode, equals('DATE_CONFLICT'));
      expect(bundle.openQuestions[1].questionId, equals('q-2'));
      expect(bundle.openQuestions[1].relatedIds, isEmpty);
      expect(bundle.openQuestions[1].reasonCode, isNull);
    });

    test('fromJson with summaries', () {
      final json = {
        'bundleId': 'bun-sum',
        'workspaceId': 'ws-1',
        'query': 'Summaries test',
        'summaries': [
          {
            'summaryId': 'sum-1',
            'workspaceId': 'ws-1',
            'summaryText': 'Weekly update',
            'asOf': '2024-06-15T10:00:00.000',
            'policyVersion': '1.0.0',
            'scope': {'scopeType': 'period'},
            'status': 'stale',
            'createdAt': '2024-06-15T10:00:00.000',
            'updatedAt': '2024-06-15T10:00:00.000',
          },
        ],
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': '1.0.0',
        'createdAt': '2024-06-15T10:00:00.000',
      };

      final bundle = InternalContextBundle.fromJson(json);

      expect(bundle.summaries, hasLength(1));
      expect(bundle.summaries.first.summaryId, equals('sum-1'));
      expect(bundle.summaries.first.status, equals(SummaryStatus.stale));
    });

    test('toJson with openQuestions', () {
      final bundle = InternalContextBundle(
        bundleId: 'bun-oq-json',
        workspaceId: 'ws-1',
        query: 'OQ toJson test',
        openQuestions: const [
          OpenQuestion(
            questionId: 'q-1',
            questionType: 'unresolved',
            description: 'Missing info',
            relatedIds: ['ref-1'],
            reasonCode: 'MISSING_INFO',
          ),
        ],
        asOf: now,
        policyVersion: '1.0.0',
        createdAt: now,
      );

      final json = bundle.toJson();

      expect(json['openQuestions'], isA<List>());
      final oqs = json['openQuestions'] as List;
      expect(oqs, hasLength(1));
      final oq = oqs.first as Map<String, dynamic>;
      expect(oq['questionId'], equals('q-1'));
      expect(oq['relatedIds'], equals(['ref-1']));
      expect(oq['reasonCode'], equals('MISSING_INFO'));
    });

    test('toJson roundtrip', () {
      final fact = Fact(
        factId: 'f-rt',
        workspaceId: 'ws-1',
        factType: 'expense',
        summary: 'Lunch',
        occurredAt: now,
        candidateId: 'cand-1',
        createdAt: now,
      );

      final summaryNode = SummaryNode(
        summaryId: 'sum-rt',
        workspaceId: 'ws-1',
        summaryText: 'RT Summary',
        asOf: now,
        policyVersion: '1.0.0',
        scope: const SummaryScope(scopeType: 'period'),
        createdAt: now,
        updatedAt: now,
      );

      final original = InternalContextBundle(
        bundleId: 'bun-rt',
        workspaceId: 'ws-rt',
        query: 'Roundtrip test',
        facts: [fact],
        summaries: [summaryNode],
        evidenceRefs: ['ev-1'],
        openQuestions: const [
          OpenQuestion(
            questionId: 'q-1',
            questionType: 'conflict',
            description: 'Test',
          ),
        ],
        tokenEstimate: 2000,
        asOf: now,
        policyVersion: '2.0.0',
        budget: const BundleBudget(maxNodes: 50, maxTokens: 8192, maxSentences: 25),
        createdAt: now,
        metadata: {'rt': true},
      );

      final json = original.toJson();
      final restored = InternalContextBundle.fromJson(json);

      expect(restored.bundleId, equals(original.bundleId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.query, equals(original.query));
      expect(restored.facts, hasLength(1));
      expect(restored.summaries, hasLength(1));
      expect(restored.evidenceRefs, equals(original.evidenceRefs));
      expect(restored.openQuestions, hasLength(1));
      expect(restored.tokenEstimate, equals(original.tokenEstimate));
      expect(restored.policyVersion, equals(original.policyVersion));
      expect(restored.budget.maxNodes, equals(50));
      expect(restored.budget.maxTokens, equals(8192));
      expect(restored.budget.maxSentences, equals(25));
      expect(restored.metadata, equals(original.metadata));
    });
  });

  // =========================================================================
  // BundleBudget additional tests
  // =========================================================================
  group('BundleBudget additional', () {
    test('copyWith all parameters', () {
      const original = BundleBudget(
        maxNodes: 100,
        maxTokens: 4096,
        maxSentences: 50,
      );

      final copy = original.copyWith(
        maxNodes: 200,
        maxTokens: 8192,
        maxSentences: 100,
      );

      expect(copy.maxNodes, equals(200));
      expect(copy.maxTokens, equals(8192));
      expect(copy.maxSentences, equals(100));
    });

    test('fromJson roundtrip', () {
      const original = BundleBudget(
        maxNodes: 75,
        maxTokens: 3000,
        maxSentences: 40,
      );

      final json = original.toJson();
      final restored = BundleBudget.fromJson(json);

      expect(restored.maxNodes, equals(original.maxNodes));
      expect(restored.maxTokens, equals(original.maxTokens));
      expect(restored.maxSentences, equals(original.maxSentences));
    });
  });

  // =========================================================================
  // OpenQuestion additional tests
  // =========================================================================
  group('OpenQuestion additional', () {
    test('fromJson roundtrip', () {
      const original = OpenQuestion(
        questionId: 'q-rt',
        questionType: 'conflict',
        description: 'Roundtrip question',
        relatedIds: ['id-1', 'id-2'],
        reasonCode: 'CONFLICT_CODE',
      );

      final json = original.toJson();
      final restored = OpenQuestion.fromJson(json);

      expect(restored.questionId, equals(original.questionId));
      expect(restored.questionType, equals(original.questionType));
      expect(restored.description, equals(original.description));
      expect(restored.relatedIds, equals(original.relatedIds));
      expect(restored.reasonCode, equals(original.reasonCode));
    });

    test('toJson with only required fields', () {
      const q = OpenQuestion(
        questionId: 'q-min',
        questionType: 'missingEvidence',
        description: 'Minimal',
      );

      final json = q.toJson();

      expect(json['questionId'], equals('q-min'));
      expect(json['questionType'], equals('missingEvidence'));
      expect(json['description'], equals('Minimal'));
      expect(json.containsKey('relatedIds'), isFalse);
      expect(json.containsKey('reasonCode'), isFalse);
    });
  });
}
