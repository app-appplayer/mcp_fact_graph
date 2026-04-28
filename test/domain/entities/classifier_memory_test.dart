import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('MemorySource', () {
    test('fromString valid values', () {
      expect(MemorySource.fromString('llm'), equals(MemorySource.llm));
      expect(MemorySource.fromString('user'), equals(MemorySource.user));
      expect(MemorySource.fromString('rule'), equals(MemorySource.rule));
    });

    test('fromString is case-insensitive', () {
      expect(MemorySource.fromString('LLM'), equals(MemorySource.llm));
      expect(MemorySource.fromString('User'), equals(MemorySource.user));
      expect(MemorySource.fromString('RULE'), equals(MemorySource.rule));
    });

    test('fromString returns llm for invalid values', () {
      expect(MemorySource.fromString('unknown'), equals(MemorySource.llm));
      expect(MemorySource.fromString(''), equals(MemorySource.llm));
      expect(MemorySource.fromString('invalid'), equals(MemorySource.llm));
    });
  });

  group('FeatureVector', () {
    test('constructor with defaults', () {
      const fv = FeatureVector();

      expect(fv.textFeatures, isEmpty);
      expect(fv.numericFeatures, isEmpty);
      expect(fv.entityFeatures, isEmpty);
      expect(fv.contextFeatures, isEmpty);
    });

    test('constructor with all fields', () {
      final fv = FeatureVector(
        textFeatures: {'keyword': 'coffee'},
        numericFeatures: {'amount': 5.50},
        entityFeatures: {'merchant': 'starbucks'},
        contextFeatures: {'time': 'morning'},
      );

      expect(fv.textFeatures, equals({'keyword': 'coffee'}));
      expect(fv.numericFeatures, equals({'amount': 5.50}));
      expect(fv.entityFeatures, equals({'merchant': 'starbucks'}));
      expect(fv.contextFeatures, equals({'time': 'morning'}));
    });

    test('fromJson complete', () {
      final json = {
        'textFeatures': {'keyword': 'lunch'},
        'numericFeatures': {'amount': 15.0},
        'entityFeatures': {'vendor': 'subway'},
        'contextFeatures': {'dayOfWeek': 'monday'},
      };

      final fv = FeatureVector.fromJson(json);

      expect(fv.textFeatures, equals({'keyword': 'lunch'}));
      expect(fv.numericFeatures, equals({'amount': 15.0}));
      expect(fv.entityFeatures, equals({'vendor': 'subway'}));
      expect(fv.contextFeatures, equals({'dayOfWeek': 'monday'}));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final fv = FeatureVector.fromJson({});

      expect(fv.textFeatures, isEmpty);
      expect(fv.numericFeatures, isEmpty);
      expect(fv.entityFeatures, isEmpty);
      expect(fv.contextFeatures, isEmpty);
    });

    test('toJson populated', () {
      final fv = FeatureVector(
        textFeatures: {'keyword': 'dinner'},
        numericFeatures: {'amount': 50.0},
        entityFeatures: {'restaurant': 'olive garden'},
        contextFeatures: {'time': 'evening'},
      );

      final json = fv.toJson();

      expect(json['textFeatures'], equals({'keyword': 'dinner'}));
      expect(json['numericFeatures'], equals({'amount': 50.0}));
      expect(json['entityFeatures'], equals({'restaurant': 'olive garden'}));
      expect(json['contextFeatures'], equals({'time': 'evening'}));
    });

    test('toJson excludes empty feature maps', () {
      const fv = FeatureVector(
        textFeatures: {},
        numericFeatures: {},
        entityFeatures: {},
        contextFeatures: {},
      );

      final json = fv.toJson();

      expect(json.containsKey('textFeatures'), isFalse);
      expect(json.containsKey('numericFeatures'), isFalse);
      expect(json.containsKey('entityFeatures'), isFalse);
      expect(json.containsKey('contextFeatures'), isFalse);
    });

    test('toJson with partial features', () {
      final fv = FeatureVector(
        textFeatures: {'k': 'v'},
        numericFeatures: {},
        entityFeatures: {'e': 'f'},
        contextFeatures: {},
      );

      final json = fv.toJson();

      expect(json.containsKey('textFeatures'), isTrue);
      expect(json.containsKey('numericFeatures'), isFalse);
      expect(json.containsKey('entityFeatures'), isTrue);
      expect(json.containsKey('contextFeatures'), isFalse);
    });

    test('copyWith creates modified copy', () {
      final original = FeatureVector(
        textFeatures: {'a': '1'},
        numericFeatures: {'b': 2},
        entityFeatures: {'c': '3'},
        contextFeatures: {'d': '4'},
      );

      final modified = original.copyWith(
        textFeatures: {'x': '10'},
        numericFeatures: {'y': 20},
        entityFeatures: {'z': '30'},
        contextFeatures: {'w': '40'},
      );

      expect(modified.textFeatures, equals({'x': '10'}));
      expect(modified.numericFeatures, equals({'y': 20}));
      expect(modified.entityFeatures, equals({'z': '30'}));
      expect(modified.contextFeatures, equals({'w': '40'}));

      // Original unchanged
      expect(original.textFeatures, equals({'a': '1'}));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = FeatureVector(
        textFeatures: {'a': '1'},
        numericFeatures: {'b': 2},
      );

      final copy = original.copyWith();

      expect(copy.textFeatures, equals(original.textFeatures));
      expect(copy.numericFeatures, equals(original.numericFeatures));
      expect(copy.entityFeatures, equals(original.entityFeatures));
      expect(copy.contextFeatures, equals(original.contextFeatures));
    });

    test('isEmpty getter', () {
      const empty = FeatureVector();
      expect(empty.isEmpty, isTrue);

      final withText = FeatureVector(textFeatures: {'k': 'v'});
      expect(withText.isEmpty, isFalse);

      final withNumeric = FeatureVector(numericFeatures: {'n': 1});
      expect(withNumeric.isEmpty, isFalse);

      final withEntity = FeatureVector(entityFeatures: {'e': 'v'});
      expect(withEntity.isEmpty, isFalse);

      final withContext = FeatureVector(contextFeatures: {'c': 'v'});
      expect(withContext.isEmpty, isFalse);
    });

    test('calculateSimilarity with both empty returns 0.0', () {
      const fv1 = FeatureVector();
      const fv2 = FeatureVector();

      expect(fv1.calculateSimilarity(fv2), equals(0.0));
    });

    test('calculateSimilarity with matching text features', () {
      final fv1 = FeatureVector(
        textFeatures: {'type': 'expense', 'category': 'food'},
      );
      final fv2 = FeatureVector(
        textFeatures: {'type': 'expense', 'category': 'food'},
      );

      expect(fv1.calculateSimilarity(fv2), equals(1.0));
    });

    test('calculateSimilarity with partial text matches', () {
      final fv1 = FeatureVector(
        textFeatures: {'type': 'expense', 'category': 'food'},
      );
      final fv2 = FeatureVector(
        textFeatures: {'type': 'expense', 'category': 'transport'},
      );

      expect(fv1.calculateSimilarity(fv2), equals(0.5));
    });

    test('calculateSimilarity with numeric features within tolerance', () {
      final fv1 = FeatureVector(
        numericFeatures: {'amount': 100.0},
      );
      // Within 10% tolerance: 100 +/- 10
      final fv2Within = FeatureVector(
        numericFeatures: {'amount': 105.0},
      );
      expect(fv1.calculateSimilarity(fv2Within), equals(1.0));

      // Outside 10% tolerance
      final fv2Outside = FeatureVector(
        numericFeatures: {'amount': 115.0},
      );
      expect(fv1.calculateSimilarity(fv2Outside), equals(0.0));
    });

    test('calculateSimilarity with numeric features exact match', () {
      final fv1 = FeatureVector(
        numericFeatures: {'amount': 50.0},
      );
      final fv2 = FeatureVector(
        numericFeatures: {'amount': 50.0},
      );

      expect(fv1.calculateSimilarity(fv2), equals(1.0));
    });

    test('calculateSimilarity with numeric features non-num values', () {
      final fv1 = FeatureVector(
        numericFeatures: {'amount': 'not-a-number'},
      );
      final fv2 = FeatureVector(
        numericFeatures: {'amount': 'also-not-a-number'},
      );

      // Non-num values skip the tolerance check, result in no match
      expect(fv1.calculateSimilarity(fv2), equals(0.0));
    });

    test('calculateSimilarity with numeric feature missing in other', () {
      final fv1 = FeatureVector(
        numericFeatures: {'amount': 100},
      );
      final fv2 = FeatureVector(
        numericFeatures: {},
      );

      // Key not present in other -> no match
      expect(fv1.calculateSimilarity(fv2), equals(0.0));
    });

    test('calculateSimilarity with entity features', () {
      final fv1 = FeatureVector(
        entityFeatures: {'merchant': 'starbucks', 'city': 'seattle'},
      );
      final fv2 = FeatureVector(
        entityFeatures: {'merchant': 'starbucks', 'city': 'portland'},
      );

      // 1 of 2 matches
      expect(fv1.calculateSimilarity(fv2), equals(0.5));
    });

    test('calculateSimilarity with context features', () {
      final fv1 = FeatureVector(
        contextFeatures: {'time': 'morning', 'source': 'email'},
      );
      final fv2 = FeatureVector(
        contextFeatures: {'time': 'morning', 'source': 'email'},
      );

      expect(fv1.calculateSimilarity(fv2), equals(1.0));
    });

    test('calculateSimilarity across all feature types', () {
      final fv1 = FeatureVector(
        textFeatures: {'type': 'expense'},
        numericFeatures: {'amount': 100.0},
        entityFeatures: {'merchant': 'starbucks'},
        contextFeatures: {'time': 'morning'},
      );
      final fv2 = FeatureVector(
        textFeatures: {'type': 'expense'},
        numericFeatures: {'amount': 100.0},
        entityFeatures: {'merchant': 'different'},
        contextFeatures: {'time': 'morning'},
      );

      // 3 of 4 match
      expect(fv1.calculateSimilarity(fv2), equals(0.75));
    });

    test('calculateSimilarity with missing key in other', () {
      final fv1 = FeatureVector(
        textFeatures: {'type': 'expense', 'extra': 'value'},
      );
      final fv2 = FeatureVector(
        textFeatures: {'type': 'expense'},
      );

      // 1 of 2 matches (extra key not in fv2)
      expect(fv1.calculateSimilarity(fv2), equals(0.5));
    });
  });

  group('ClassifierMemory', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 12, 0);
    final sampleFeatures = FeatureVector(
      textFeatures: {'type': 'expense'},
      numericFeatures: {'amount': 42.0},
    );

    test('constructor with required fields', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        features: sampleFeatures,
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      expect(memory.memoryId, equals('mem-1'));
      expect(memory.taxonomyId, equals('tax-1'));
      expect(memory.categoryId, equals('cat-1'));
      expect(memory.features.textFeatures, equals({'type': 'expense'}));
      expect(memory.confidence, equals(1.0));
      expect(memory.rationale, isNull);
      expect(memory.source, equals(MemorySource.llm));
      expect(memory.policyVersion, equals('v1.0'));
      expect(memory.evidenceRefs, isEmpty);
      expect(memory.matchCount, equals(0));
      expect(memory.workspaceId, isNull);
      expect(memory.createdAt, equals(now));
      expect(memory.lastMatchedAt, equals(now));
    });

    test('constructor with all fields', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-2',
        taxonomyId: 'tax-2',
        categoryId: 'cat-2',
        features: sampleFeatures,
        confidence: 0.85,
        rationale: 'Based on prior classification',
        source: MemorySource.user,
        policyVersion: 'v2.0',
        evidenceRefs: ['ev-1', 'ev-2'],
        matchCount: 10,
        workspaceId: 'ws-1',
        createdAt: now,
        lastMatchedAt: later,
      );

      expect(memory.memoryId, equals('mem-2'));
      expect(memory.taxonomyId, equals('tax-2'));
      expect(memory.categoryId, equals('cat-2'));
      expect(memory.confidence, equals(0.85));
      expect(memory.rationale, equals('Based on prior classification'));
      expect(memory.source, equals(MemorySource.user));
      expect(memory.policyVersion, equals('v2.0'));
      expect(memory.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(memory.matchCount, equals(10));
      expect(memory.workspaceId, equals('ws-1'));
      expect(memory.createdAt, equals(now));
      expect(memory.lastMatchedAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'memoryId': 'mem-3',
        'taxonomyId': 'tax-3',
        'categoryId': 'cat-3',
        'features': {
          'textFeatures': {'keyword': 'receipt'},
          'numericFeatures': {'total': 99.0},
        },
        'confidence': 0.92,
        'rationale': 'High confidence match',
        'source': 'user',
        'policyVersion': 'v3.0',
        'evidenceRefs': ['ev-3', 'ev-4'],
        'matchCount': 5,
        'workspaceId': 'ws-2',
        'createdAt': '2024-01-15T10:30:00.000',
        'lastMatchedAt': '2024-01-16T12:00:00.000',
      };

      final memory = ClassifierMemory.fromJson(json);

      expect(memory.memoryId, equals('mem-3'));
      expect(memory.taxonomyId, equals('tax-3'));
      expect(memory.categoryId, equals('cat-3'));
      expect(memory.features.textFeatures, equals({'keyword': 'receipt'}));
      expect(memory.features.numericFeatures, equals({'total': 99.0}));
      expect(memory.confidence, equals(0.92));
      expect(memory.rationale, equals('High confidence match'));
      expect(memory.source, equals(MemorySource.user));
      expect(memory.policyVersion, equals('v3.0'));
      expect(memory.evidenceRefs, equals(['ev-3', 'ev-4']));
      expect(memory.matchCount, equals(5));
      expect(memory.workspaceId, equals('ws-2'));
      expect(
        memory.createdAt,
        equals(DateTime.parse('2024-01-15T10:30:00.000')),
      );
      expect(
        memory.lastMatchedAt,
        equals(DateTime.parse('2024-01-16T12:00:00.000')),
      );
    });

    test('fromJson empty/missing fields uses defaults', () {
      final memory = ClassifierMemory.fromJson({});

      expect(memory.memoryId, equals(''));
      expect(memory.taxonomyId, equals(''));
      expect(memory.categoryId, equals(''));
      expect(memory.features.isEmpty, isTrue);
      expect(memory.confidence, equals(1.0));
      expect(memory.rationale, isNull);
      expect(memory.source, equals(MemorySource.llm));
      expect(memory.policyVersion, equals(''));
      expect(memory.evidenceRefs, isEmpty);
      expect(memory.matchCount, equals(0));
      expect(memory.workspaceId, isNull);
      expect(memory.createdAt, isA<DateTime>());
      expect(memory.lastMatchedAt, isA<DateTime>());
    });

    test('fromJson with null features creates empty FeatureVector', () {
      final memory = ClassifierMemory.fromJson({'features': null});

      expect(memory.features.isEmpty, isTrue);
    });

    test('fromJson with null dates defaults to now', () {
      final before = DateTime.now();
      final memory = ClassifierMemory.fromJson({
        'createdAt': null,
        'lastMatchedAt': null,
      });
      final after = DateTime.now();

      expect(
        memory.createdAt.isAfter(before) ||
            memory.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        memory.createdAt.isBefore(after) ||
            memory.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('toJson populated', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-4',
        taxonomyId: 'tax-4',
        categoryId: 'cat-4',
        features: sampleFeatures,
        confidence: 0.95,
        rationale: 'User confirmed',
        source: MemorySource.rule,
        policyVersion: 'v4.0',
        evidenceRefs: ['ev-5'],
        matchCount: 3,
        workspaceId: 'ws-3',
        createdAt: now,
        lastMatchedAt: later,
      );

      final json = memory.toJson();

      expect(json['memoryId'], equals('mem-4'));
      expect(json['taxonomyId'], equals('tax-4'));
      expect(json['categoryId'], equals('cat-4'));
      expect(json['features'], isA<Map<String, dynamic>>());
      expect(json['confidence'], equals(0.95));
      expect(json['rationale'], equals('User confirmed'));
      expect(json['source'], equals('rule'));
      expect(json['policyVersion'], equals('v4.0'));
      expect(json['evidenceRefs'], equals(['ev-5']));
      expect(json['matchCount'], equals(3));
      expect(json['workspaceId'], equals('ws-3'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['lastMatchedAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes empty/null fields', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-5',
        taxonomyId: 'tax-5',
        categoryId: 'cat-5',
        features: const FeatureVector(),
        source: MemorySource.llm,
        policyVersion: 'v5.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      final json = memory.toJson();

      expect(json.containsKey('rationale'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // Always-present fields
      expect(json.containsKey('memoryId'), isTrue);
      expect(json.containsKey('taxonomyId'), isTrue);
      expect(json.containsKey('categoryId'), isTrue);
      expect(json.containsKey('features'), isTrue);
      expect(json.containsKey('confidence'), isTrue);
      expect(json.containsKey('source'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('matchCount'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('lastMatchedAt'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final original = ClassifierMemory(
        memoryId: 'mem-6',
        taxonomyId: 'tax-6',
        categoryId: 'cat-6',
        features: sampleFeatures,
        confidence: 0.8,
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      final newFeatures = FeatureVector(
        textFeatures: {'new': 'feature'},
      );

      final modified = original.copyWith(
        memoryId: 'mem-7',
        taxonomyId: 'tax-7',
        categoryId: 'cat-7',
        features: newFeatures,
        confidence: 0.99,
        rationale: 'Updated',
        source: MemorySource.user,
        policyVersion: 'v2.0',
        evidenceRefs: ['ev-new'],
        matchCount: 50,
        workspaceId: 'ws-new',
        createdAt: later,
        lastMatchedAt: later,
      );

      expect(modified.memoryId, equals('mem-7'));
      expect(modified.taxonomyId, equals('tax-7'));
      expect(modified.categoryId, equals('cat-7'));
      expect(modified.features.textFeatures, equals({'new': 'feature'}));
      expect(modified.confidence, equals(0.99));
      expect(modified.rationale, equals('Updated'));
      expect(modified.source, equals(MemorySource.user));
      expect(modified.policyVersion, equals('v2.0'));
      expect(modified.evidenceRefs, equals(['ev-new']));
      expect(modified.matchCount, equals(50));
      expect(modified.workspaceId, equals('ws-new'));
      expect(modified.createdAt, equals(later));
      expect(modified.lastMatchedAt, equals(later));

      // Original unchanged
      expect(original.memoryId, equals('mem-6'));
      expect(original.confidence, equals(0.8));
    });

    test('copyWith with no arguments returns equivalent copy', () {
      final original = ClassifierMemory(
        memoryId: 'mem-8',
        taxonomyId: 'tax-8',
        categoryId: 'cat-8',
        features: sampleFeatures,
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.memoryId, equals(original.memoryId));
      expect(copy.taxonomyId, equals(original.taxonomyId));
      expect(copy.categoryId, equals(original.categoryId));
      expect(copy.features.textFeatures, equals(original.features.textFeatures));
      expect(copy.confidence, equals(original.confidence));
      expect(copy.rationale, equals(original.rationale));
      expect(copy.source, equals(original.source));
      expect(copy.policyVersion, equals(original.policyVersion));
      expect(copy.evidenceRefs, equals(original.evidenceRefs));
      expect(copy.matchCount, equals(original.matchCount));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.lastMatchedAt, equals(original.lastMatchedAt));
    });

    test('isHighConfidence getter', () {
      final high = ClassifierMemory(
        memoryId: 'mem-9',
        taxonomyId: 'tax-9',
        categoryId: 'cat-9',
        features: sampleFeatures,
        confidence: 0.9,
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );
      expect(high.isHighConfidence, isTrue);

      final above = high.copyWith(confidence: 0.95);
      expect(above.isHighConfidence, isTrue);

      final below = high.copyWith(confidence: 0.89);
      expect(below.isHighConfidence, isFalse);
    });

    test('matchSimilarity delegates to FeatureVector.calculateSimilarity', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-10',
        taxonomyId: 'tax-10',
        categoryId: 'cat-10',
        features: FeatureVector(
          textFeatures: {'type': 'expense', 'category': 'food'},
        ),
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      final otherFeatures = FeatureVector(
        textFeatures: {'type': 'expense', 'category': 'transport'},
      );

      // 1 of 2 matches
      expect(memory.matchSimilarity(otherFeatures), equals(0.5));
    });

    test('matches method with threshold', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-11',
        taxonomyId: 'tax-11',
        categoryId: 'cat-11',
        features: FeatureVector(
          textFeatures: {
            'type': 'expense',
            'category': 'food',
            'sub': 'coffee',
            'freq': 'daily',
            'loc': 'office',
          },
        ),
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      // 5/5 match = 1.0 >= 0.8 default threshold
      expect(
        memory.matches(FeatureVector(
          textFeatures: {
            'type': 'expense',
            'category': 'food',
            'sub': 'coffee',
            'freq': 'daily',
            'loc': 'office',
          },
        )),
        isTrue,
      );

      // 4/5 match = 0.8 >= 0.8 default threshold
      expect(
        memory.matches(FeatureVector(
          textFeatures: {
            'type': 'expense',
            'category': 'food',
            'sub': 'coffee',
            'freq': 'daily',
            'loc': 'home',
          },
        )),
        isTrue,
      );

      // 3/5 match = 0.6 < 0.8 default threshold
      expect(
        memory.matches(FeatureVector(
          textFeatures: {
            'type': 'expense',
            'category': 'food',
            'sub': 'coffee',
            'freq': 'weekly',
            'loc': 'home',
          },
        )),
        isFalse,
      );

      // With custom threshold: 3/5 = 0.6 >= 0.5
      expect(
        memory.matches(
          FeatureVector(
            textFeatures: {
              'type': 'expense',
              'category': 'food',
              'sub': 'coffee',
              'freq': 'weekly',
              'loc': 'home',
            },
          ),
          threshold: 0.5,
        ),
        isTrue,
      );
    });

    test('recordMatch increments matchCount and updates lastMatchedAt', () {
      final memory = ClassifierMemory(
        memoryId: 'mem-12',
        taxonomyId: 'tax-12',
        categoryId: 'cat-12',
        features: sampleFeatures,
        matchCount: 7,
        source: MemorySource.llm,
        policyVersion: 'v1.0',
        createdAt: now,
        lastMatchedAt: now,
      );

      final before = DateTime.now();
      final matched = memory.recordMatch();
      final after = DateTime.now();

      expect(matched.matchCount, equals(8));
      expect(
        matched.lastMatchedAt.isAfter(before) ||
            matched.lastMatchedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        matched.lastMatchedAt.isBefore(after) ||
            matched.lastMatchedAt.isAtSameMomentAs(after),
        isTrue,
      );

      // Original unchanged
      expect(memory.matchCount, equals(7));
    });
  });
}
