import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('DecisionType', () {
    test('fromString valid values', () {
      expect(
        DecisionType.fromString('classification'),
        equals(DecisionType.classification),
      );
      expect(DecisionType.fromString('merge'), equals(DecisionType.merge));
      expect(DecisionType.fromString('link'), equals(DecisionType.link));
      expect(DecisionType.fromString('split'), equals(DecisionType.split));
      expect(DecisionType.fromString('reject'), equals(DecisionType.reject));
      expect(DecisionType.fromString('confirm'), equals(DecisionType.confirm));
    });

    test('fromString is case-insensitive', () {
      expect(
        DecisionType.fromString('CLASSIFICATION'),
        equals(DecisionType.classification),
      );
      expect(DecisionType.fromString('Merge'), equals(DecisionType.merge));
      expect(DecisionType.fromString('LINK'), equals(DecisionType.link));
    });

    test('fromString returns confirm for invalid values', () {
      expect(DecisionType.fromString('unknown'), equals(DecisionType.confirm));
      expect(DecisionType.fromString(''), equals(DecisionType.confirm));
      expect(
        DecisionType.fromString('invalid'),
        equals(DecisionType.confirm),
      );
    });
  });

  group('DisambiguationDecision', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 12, 0);

    test('constructor with required fields', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-1',
        decisionType: DecisionType.merge,
        contextHash: 'hash-abc',
        createdAt: now,
        lastAppliedAt: now,
      );

      expect(decision.decisionId, equals('dec-1'));
      expect(decision.decisionType, equals(DecisionType.merge));
      expect(decision.contextHash, equals('hash-abc'));
      expect(decision.context, isEmpty);
      expect(decision.choice, isEmpty);
      expect(decision.rationale, isNull);
      expect(decision.applicationCount, equals(0));
      expect(decision.workspaceId, isNull);
      expect(decision.createdAt, equals(now));
      expect(decision.lastAppliedAt, equals(now));
    });

    test('constructor with all fields', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-2',
        decisionType: DecisionType.link,
        contextHash: 'hash-xyz',
        context: {'source': 'receipt', 'type': 'expense'},
        choice: {'projectId': 'proj-1'},
        rationale: 'Belongs to project X',
        applicationCount: 5,
        workspaceId: 'ws-1',
        createdAt: now,
        lastAppliedAt: later,
      );

      expect(decision.decisionId, equals('dec-2'));
      expect(decision.decisionType, equals(DecisionType.link));
      expect(decision.contextHash, equals('hash-xyz'));
      expect(decision.context, equals({'source': 'receipt', 'type': 'expense'}));
      expect(decision.choice, equals({'projectId': 'proj-1'}));
      expect(decision.rationale, equals('Belongs to project X'));
      expect(decision.applicationCount, equals(5));
      expect(decision.workspaceId, equals('ws-1'));
      expect(decision.createdAt, equals(now));
      expect(decision.lastAppliedAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'decisionId': 'dec-3',
        'decisionType': 'split',
        'contextHash': 'hash-123',
        'context': {'key': 'value'},
        'choice': {'action': 'split'},
        'rationale': 'Should be separate',
        'applicationCount': 3,
        'workspaceId': 'ws-2',
        'createdAt': '2024-01-15T10:30:00.000',
        'lastAppliedAt': '2024-01-16T12:00:00.000',
      };

      final decision = DisambiguationDecision.fromJson(json);

      expect(decision.decisionId, equals('dec-3'));
      expect(decision.decisionType, equals(DecisionType.split));
      expect(decision.contextHash, equals('hash-123'));
      expect(decision.context, equals({'key': 'value'}));
      expect(decision.choice, equals({'action': 'split'}));
      expect(decision.rationale, equals('Should be separate'));
      expect(decision.applicationCount, equals(3));
      expect(decision.workspaceId, equals('ws-2'));
      expect(decision.createdAt, equals(DateTime.parse('2024-01-15T10:30:00.000')));
      expect(
        decision.lastAppliedAt,
        equals(DateTime.parse('2024-01-16T12:00:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final decision = DisambiguationDecision.fromJson({});

      expect(decision.decisionId, equals(''));
      expect(decision.decisionType, equals(DecisionType.confirm));
      expect(decision.contextHash, equals(''));
      expect(decision.context, isEmpty);
      expect(decision.choice, isEmpty);
      expect(decision.rationale, isNull);
      expect(decision.applicationCount, equals(0));
      expect(decision.workspaceId, isNull);
      // createdAt and lastAppliedAt default to DateTime.now()
      expect(decision.createdAt, isA<DateTime>());
      expect(decision.lastAppliedAt, isA<DateTime>());
    });

    test('fromJson with null createdAt/lastAppliedAt defaults to now', () {
      final before = DateTime.now();
      final decision = DisambiguationDecision.fromJson({
        'createdAt': null,
        'lastAppliedAt': null,
      });
      final after = DateTime.now();

      // Verify dates fall within expected range
      expect(
        decision.createdAt.isAfter(before) ||
            decision.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        decision.createdAt.isBefore(after) ||
            decision.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('toJson populated', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-4',
        decisionType: DecisionType.reject,
        contextHash: 'hash-456',
        context: {'source': 'manual'},
        choice: {'rejected': true},
        rationale: 'Not valid data',
        applicationCount: 2,
        workspaceId: 'ws-3',
        createdAt: now,
        lastAppliedAt: later,
      );

      final json = decision.toJson();

      expect(json['decisionId'], equals('dec-4'));
      expect(json['decisionType'], equals('reject'));
      expect(json['contextHash'], equals('hash-456'));
      expect(json['context'], equals({'source': 'manual'}));
      expect(json['choice'], equals({'rejected': true}));
      expect(json['rationale'], equals('Not valid data'));
      expect(json['applicationCount'], equals(2));
      expect(json['workspaceId'], equals('ws-3'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['lastAppliedAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-5',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-789',
        createdAt: now,
        lastAppliedAt: now,
      );

      final json = decision.toJson();

      expect(json.containsKey('context'), isFalse);
      expect(json.containsKey('choice'), isFalse);
      expect(json.containsKey('rationale'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // These should always be present
      expect(json.containsKey('decisionId'), isTrue);
      expect(json.containsKey('decisionType'), isTrue);
      expect(json.containsKey('contextHash'), isTrue);
      expect(json.containsKey('applicationCount'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('lastAppliedAt'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final original = DisambiguationDecision(
        decisionId: 'dec-6',
        decisionType: DecisionType.merge,
        contextHash: 'hash-orig',
        context: {'a': 1},
        choice: {'b': 2},
        rationale: 'Original rationale',
        applicationCount: 1,
        workspaceId: 'ws-orig',
        createdAt: now,
        lastAppliedAt: now,
      );

      final modified = original.copyWith(
        decisionId: 'dec-7',
        decisionType: DecisionType.split,
        contextHash: 'hash-new',
        context: {'c': 3},
        choice: {'d': 4},
        rationale: 'New rationale',
        applicationCount: 10,
        workspaceId: 'ws-new',
        createdAt: later,
        lastAppliedAt: later,
      );

      expect(modified.decisionId, equals('dec-7'));
      expect(modified.decisionType, equals(DecisionType.split));
      expect(modified.contextHash, equals('hash-new'));
      expect(modified.context, equals({'c': 3}));
      expect(modified.choice, equals({'d': 4}));
      expect(modified.rationale, equals('New rationale'));
      expect(modified.applicationCount, equals(10));
      expect(modified.workspaceId, equals('ws-new'));
      expect(modified.createdAt, equals(later));
      expect(modified.lastAppliedAt, equals(later));

      // Original should remain unchanged
      expect(original.decisionId, equals('dec-6'));
      expect(original.decisionType, equals(DecisionType.merge));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = DisambiguationDecision(
        decisionId: 'dec-8',
        decisionType: DecisionType.classification,
        contextHash: 'hash-same',
        createdAt: now,
        lastAppliedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.decisionId, equals(original.decisionId));
      expect(copy.decisionType, equals(original.decisionType));
      expect(copy.contextHash, equals(original.contextHash));
      expect(copy.context, equals(original.context));
      expect(copy.choice, equals(original.choice));
      expect(copy.rationale, equals(original.rationale));
      expect(copy.applicationCount, equals(original.applicationCount));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.lastAppliedAt, equals(original.lastAppliedAt));
    });

    test('matchesContext returns true for matching hash', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-9',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-match',
        createdAt: now,
        lastAppliedAt: now,
      );

      expect(decision.matchesContext('hash-match'), isTrue);
      expect(decision.matchesContext('hash-other'), isFalse);
    });

    test('calculateContextSimilarity with empty contexts returns 0.0', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-10',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-a',
        createdAt: now,
        lastAppliedAt: now,
      );

      // Both empty
      expect(decision.calculateContextSimilarity({}), equals(0.0));

      // Other empty
      final decisionWithContext = decision.copyWith(
        context: {'key': 'value'},
      );
      expect(decisionWithContext.calculateContextSimilarity({}), equals(0.0));
    });

    test('calculateContextSimilarity with this context empty returns 0.0', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-empty',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-e',
        context: {},
        createdAt: now,
        lastAppliedAt: now,
      );

      expect(
        decision.calculateContextSimilarity({'key': 'value'}),
        equals(0.0),
      );
    });

    test('calculateContextSimilarity with matching values', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-11',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-b',
        context: {'type': 'expense', 'source': 'receipt', 'amount': 100},
        createdAt: now,
        lastAppliedAt: now,
      );

      // All matching
      final similarity = decision.calculateContextSimilarity({
        'type': 'expense',
        'source': 'receipt',
        'amount': 100,
      });
      expect(similarity, equals(1.0));

      // Partial match (2 of 3)
      final partialSimilarity = decision.calculateContextSimilarity({
        'type': 'expense',
        'source': 'receipt',
        'amount': 999,
      });
      expect(partialSimilarity, closeTo(2 / 3, 0.01));
    });

    test('calculateContextSimilarity with regex pattern matching', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-12',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-c',
        context: {r'type': r'^exp.*$'},
        createdAt: now,
        lastAppliedAt: now,
      );

      // Regex match: "expense" matches "^exp.*$"
      final similarity = decision.calculateContextSimilarity({
        'type': 'expense',
      });
      expect(similarity, equals(1.0));

      // Regex non-match
      final noMatch = decision.calculateContextSimilarity({
        'type': 'income',
      });
      expect(noMatch, equals(0.0));
    });

    test('calculateContextSimilarity with non-string, non-matching values', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-nonstr',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-ns',
        context: {'count': 42, 'flag': true},
        createdAt: now,
        lastAppliedAt: now,
      );

      // Different values (non-string branch, not equal)
      final similarity = decision.calculateContextSimilarity({
        'count': 99,
        'flag': false,
      });
      expect(similarity, equals(0.0));
    });

    test('calculateContextSimilarity with key not present in other context', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-missing',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-m',
        context: {'a': 'x', 'b': 'y'},
        createdAt: now,
        lastAppliedAt: now,
      );

      // Only one key present
      final similarity = decision.calculateContextSimilarity({'a': 'x'});
      expect(similarity, equals(0.5));
    });

    test('isApplicable with threshold', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-13',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-d',
        context: {
          'type': 'expense',
          'source': 'receipt',
          'amount': 100,
          'category': 'food',
          'vendor': 'starbucks',
        },
        createdAt: now,
        lastAppliedAt: now,
      );

      // 5 of 5 matching: 1.0 >= 0.8
      expect(
        decision.isApplicable({
          'type': 'expense',
          'source': 'receipt',
          'amount': 100,
          'category': 'food',
          'vendor': 'starbucks',
        }),
        isTrue,
      );

      // 4 of 5 matching: 0.8 >= 0.8
      expect(
        decision.isApplicable({
          'type': 'expense',
          'source': 'receipt',
          'amount': 100,
          'category': 'food',
          'vendor': 'different',
        }),
        isTrue,
      );

      // 3 of 5 matching: 0.6 < 0.8
      expect(
        decision.isApplicable({
          'type': 'expense',
          'source': 'receipt',
          'amount': 100,
          'category': 'transport',
          'vendor': 'different',
        }),
        isFalse,
      );

      // Custom threshold
      expect(
        decision.isApplicable(
          {
            'type': 'expense',
            'source': 'receipt',
            'amount': 100,
            'category': 'transport',
            'vendor': 'different',
          },
          threshold: 0.5,
        ),
        isTrue,
      );
    });

    test('recordApplication increments count and updates lastAppliedAt', () {
      final decision = DisambiguationDecision(
        decisionId: 'dec-14',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-e',
        applicationCount: 3,
        createdAt: now,
        lastAppliedAt: now,
      );

      final before = DateTime.now();
      final applied = decision.recordApplication();
      final after = DateTime.now();

      expect(applied.applicationCount, equals(4));
      expect(
        applied.lastAppliedAt.isAfter(before) ||
            applied.lastAppliedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        applied.lastAppliedAt.isBefore(after) ||
            applied.lastAppliedAt.isAtSameMomentAs(after),
        isTrue,
      );
      // Original unchanged
      expect(decision.applicationCount, equals(3));
    });

    test('isFrequentlyApplied getter', () {
      final lowCount = DisambiguationDecision(
        decisionId: 'dec-15',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-f',
        applicationCount: 4,
        createdAt: now,
        lastAppliedAt: now,
      );
      expect(lowCount.isFrequentlyApplied, isFalse);

      final exactThreshold = DisambiguationDecision(
        decisionId: 'dec-16',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-g',
        applicationCount: 5,
        createdAt: now,
        lastAppliedAt: now,
      );
      expect(exactThreshold.isFrequentlyApplied, isTrue);

      final highCount = DisambiguationDecision(
        decisionId: 'dec-17',
        decisionType: DecisionType.confirm,
        contextHash: 'hash-h',
        applicationCount: 10,
        createdAt: now,
        lastAppliedAt: now,
      );
      expect(highCount.isFrequentlyApplied, isTrue);
    });
  });

  group('ContextHasher', () {
    test('hash generates consistent hash for same input', () {
      final context = {'type': 'expense', 'amount': 100};
      final hash1 = ContextHasher.hash(context);
      final hash2 = ContextHasher.hash(context);

      expect(hash1, equals(hash2));
      expect(hash1, isA<String>());
      expect(hash1.isNotEmpty, isTrue);
    });

    test('hash generates different hashes for different inputs', () {
      final hash1 = ContextHasher.hash({'type': 'expense'});
      final hash2 = ContextHasher.hash({'type': 'income'});

      expect(hash1, isNot(equals(hash2)));
    });

    test('hash with empty map', () {
      final hash = ContextHasher.hash({});
      expect(hash, isA<String>());
      expect(hash.isNotEmpty, isTrue);
    });

    test('hash sorts keys for consistent output', () {
      final hash1 = ContextHasher.hash({'b': 2, 'a': 1});
      final hash2 = ContextHasher.hash({'a': 1, 'b': 2});

      expect(hash1, equals(hash2));
    });
  });
}
