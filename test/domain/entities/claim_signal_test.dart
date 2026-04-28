import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // ClaimSignalType enum
  // =========================================================================
  group('ClaimSignalType', () {
    test('has all expected values', () {
      expect(ClaimSignalType.values, contains(ClaimSignalType.positive));
      expect(ClaimSignalType.values, contains(ClaimSignalType.negative));
      expect(ClaimSignalType.values, contains(ClaimSignalType.conflict));
      expect(ClaimSignalType.values, contains(ClaimSignalType.pending));
      expect(ClaimSignalType.values.length, equals(4));
    });

    test('fromString returns correct value for all variants', () {
      expect(ClaimSignalType.fromString('positive'),
          equals(ClaimSignalType.positive));
      expect(ClaimSignalType.fromString('negative'),
          equals(ClaimSignalType.negative));
      expect(ClaimSignalType.fromString('conflict'),
          equals(ClaimSignalType.conflict));
      expect(ClaimSignalType.fromString('pending'),
          equals(ClaimSignalType.pending));
    });

    test('fromString returns pending for invalid values', () {
      expect(ClaimSignalType.fromString('unknown'),
          equals(ClaimSignalType.pending));
      expect(
          ClaimSignalType.fromString(''), equals(ClaimSignalType.pending));
      expect(ClaimSignalType.fromString('POSITIVE'),
          equals(ClaimSignalType.pending));
    });
  });

  // =========================================================================
  // ValidationOutcome class
  // =========================================================================
  group('ValidationOutcome', () {
    test('constructor with required fields only', () {
      const outcome = ValidationOutcome(isValid: true);

      expect(outcome.isValid, isTrue);
      expect(outcome.rejectionReason, isNull);
      expect(outcome.supportingFactIds, isEmpty);
      expect(outcome.contradictingFactIds, isEmpty);
      expect(outcome.evidenceStrength, equals(0.0));
    });

    test('constructor with all fields', () {
      const outcome = ValidationOutcome(
        isValid: false,
        rejectionReason: 'Contradicted by fact-5',
        supportingFactIds: ['f-1', 'f-2'],
        contradictingFactIds: ['f-5'],
        evidenceStrength: 0.85,
      );

      expect(outcome.isValid, isFalse);
      expect(outcome.rejectionReason, equals('Contradicted by fact-5'));
      expect(outcome.supportingFactIds, equals(['f-1', 'f-2']));
      expect(outcome.contradictingFactIds, equals(['f-5']));
      expect(outcome.evidenceStrength, equals(0.85));
    });

    test('fromJson complete', () {
      final json = {
        'isValid': true,
        'rejectionReason': 'None applicable',
        'supportingFactIds': ['f-10', 'f-20'],
        'contradictingFactIds': ['f-30'],
        'evidenceStrength': 0.92,
      };

      final outcome = ValidationOutcome.fromJson(json);

      expect(outcome.isValid, isTrue);
      expect(outcome.rejectionReason, equals('None applicable'));
      expect(outcome.supportingFactIds, equals(['f-10', 'f-20']));
      expect(outcome.contradictingFactIds, equals(['f-30']));
      expect(outcome.evidenceStrength, equals(0.92));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final outcome = ValidationOutcome.fromJson(json);

      expect(outcome.isValid, isFalse);
      expect(outcome.rejectionReason, isNull);
      expect(outcome.supportingFactIds, isEmpty);
      expect(outcome.contradictingFactIds, isEmpty);
      expect(outcome.evidenceStrength, equals(0.0));
    });

    test('toJson populated', () {
      const outcome = ValidationOutcome(
        isValid: false,
        rejectionReason: 'Weak evidence',
        supportingFactIds: ['f-1'],
        contradictingFactIds: ['f-2', 'f-3'],
        evidenceStrength: 0.3,
      );

      final json = outcome.toJson();

      expect(json['isValid'], isFalse);
      expect(json['rejectionReason'], equals('Weak evidence'));
      expect(json['supportingFactIds'], equals(['f-1']));
      expect(json['contradictingFactIds'], equals(['f-2', 'f-3']));
      expect(json['evidenceStrength'], equals(0.3));
    });

    test('toJson excludes empty/null fields', () {
      const outcome = ValidationOutcome(isValid: true);

      final json = outcome.toJson();

      expect(json.containsKey('isValid'), isTrue);
      expect(json.containsKey('evidenceStrength'), isTrue);
      expect(json.containsKey('rejectionReason'), isFalse);
      expect(json.containsKey('supportingFactIds'), isFalse);
      expect(json.containsKey('contradictingFactIds'), isFalse);
    });

    test('toString returns expected format', () {
      const outcome = ValidationOutcome(
        isValid: true,
        evidenceStrength: 0.9,
      );

      expect(outcome.toString(),
          equals('ValidationOutcome(isValid: true, strength: 0.9)'));
    });
  });

  // =========================================================================
  // ClaimFeatures class
  // =========================================================================
  group('ClaimFeatures', () {
    test('constructor with required fields only', () {
      const features = ClaimFeatures(
        claimType: 'fact',
        domain: 'finance',
        structuralPattern: 'X costs Y',
      );

      expect(features.claimType, equals('fact'));
      expect(features.domain, equals('finance'));
      expect(features.structuralPattern, equals('X costs Y'));
      expect(features.factTypes, isEmpty);
      expect(features.responseContext, isEmpty);
      expect(features.outcome.isValid, isFalse);
    });

    test('constructor with all fields', () {
      const outcome = ValidationOutcome(
        isValid: true,
        evidenceStrength: 0.8,
      );

      const features = ClaimFeatures(
        claimType: 'causal',
        domain: 'health',
        structuralPattern: 'X causes Y',
        factTypes: ['medical', 'research'],
        responseContext: {'model': 'gpt-4'},
        outcome: outcome,
      );

      expect(features.claimType, equals('causal'));
      expect(features.domain, equals('health'));
      expect(features.structuralPattern, equals('X causes Y'));
      expect(features.factTypes, equals(['medical', 'research']));
      expect(features.responseContext, equals({'model': 'gpt-4'}));
      expect(features.outcome.isValid, isTrue);
      expect(features.outcome.evidenceStrength, equals(0.8));
    });

    test('fromJson complete', () {
      final json = {
        'claimType': 'temporal',
        'domain': 'scheduling',
        'structuralPattern': 'X before Y',
        'factTypes': ['event', 'schedule'],
        'responseContext': {'source': 'calendar'},
        'outcome': {
          'isValid': true,
          'evidenceStrength': 0.75,
          'supportingFactIds': ['f-1'],
        },
      };

      final features = ClaimFeatures.fromJson(json);

      expect(features.claimType, equals('temporal'));
      expect(features.domain, equals('scheduling'));
      expect(features.structuralPattern, equals('X before Y'));
      expect(features.factTypes, equals(['event', 'schedule']));
      expect(features.responseContext, equals({'source': 'calendar'}));
      expect(features.outcome.isValid, isTrue);
      expect(features.outcome.evidenceStrength, equals(0.75));
      expect(features.outcome.supportingFactIds, equals(['f-1']));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final features = ClaimFeatures.fromJson(json);

      expect(features.claimType, equals(''));
      expect(features.domain, equals(''));
      expect(features.structuralPattern, equals(''));
      expect(features.factTypes, isEmpty);
      expect(features.responseContext, isEmpty);
      expect(features.outcome.isValid, isFalse);
    });

    test('toJson populated', () {
      const features = ClaimFeatures(
        claimType: 'relation',
        domain: 'business',
        structuralPattern: 'X works for Y',
        factTypes: ['org', 'person'],
        responseContext: {'query': 'who works where'},
        outcome: ValidationOutcome(
          isValid: true,
          evidenceStrength: 0.9,
          supportingFactIds: ['f-1'],
        ),
      );

      final json = features.toJson();

      expect(json['claimType'], equals('relation'));
      expect(json['domain'], equals('business'));
      expect(json['structuralPattern'], equals('X works for Y'));
      expect(json['factTypes'], equals(['org', 'person']));
      expect(json['responseContext'], equals({'query': 'who works where'}));
      expect(json['outcome'], isA<Map<String, dynamic>>());
      expect((json['outcome'] as Map)['isValid'], isTrue);
    });

    test('toJson excludes empty fields', () {
      const features = ClaimFeatures(
        claimType: 'fact',
        domain: 'general',
        structuralPattern: 'X is Y',
      );

      final json = features.toJson();

      expect(json.containsKey('factTypes'), isFalse);
      expect(json.containsKey('responseContext'), isFalse);
      // Always present
      expect(json.containsKey('claimType'), isTrue);
      expect(json.containsKey('domain'), isTrue);
      expect(json.containsKey('structuralPattern'), isTrue);
      expect(json.containsKey('outcome'), isTrue);
    });

    test('toString returns expected format', () {
      const features = ClaimFeatures(
        claimType: 'causal',
        domain: 'science',
        structuralPattern: 'X leads to Y',
      );

      expect(features.toString(),
          equals('ClaimFeatures(type: causal, domain: science, pattern: X leads to Y)'));
    });
  });

  // =========================================================================
  // ValidationContext class
  // =========================================================================
  group('ValidationContext', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);

    test('constructor with required fields only', () {
      final ctx = ValidationContext(
        validationId: 'val-1',
        queryType: 'factual',
        validatedAt: now,
        policyVersion: '1.0.0',
      );

      expect(ctx.validationId, equals('val-1'));
      expect(ctx.queryType, equals('factual'));
      expect(ctx.llmModel, isNull);
      expect(ctx.validatedAt, equals(now));
      expect(ctx.policyVersion, equals('1.0.0'));
      expect(ctx.metadata, isNull);
    });

    test('constructor with all fields', () {
      final ctx = ValidationContext(
        validationId: 'val-2',
        queryType: 'analytical',
        llmModel: 'gpt-4-turbo',
        validatedAt: now,
        policyVersion: '2.0.0',
        metadata: {'tokens': 1500},
      );

      expect(ctx.validationId, equals('val-2'));
      expect(ctx.queryType, equals('analytical'));
      expect(ctx.llmModel, equals('gpt-4-turbo'));
      expect(ctx.validatedAt, equals(now));
      expect(ctx.policyVersion, equals('2.0.0'));
      expect(ctx.metadata, equals({'tokens': 1500}));
    });

    test('fromJson complete', () {
      final json = {
        'validationId': 'val-3',
        'queryType': 'summary',
        'llmModel': 'claude-3',
        'validatedAt': '2024-06-15T10:00:00.000',
        'policyVersion': '3.0.0',
        'metadata': {'region': 'us-east'},
      };

      final ctx = ValidationContext.fromJson(json);

      expect(ctx.validationId, equals('val-3'));
      expect(ctx.queryType, equals('summary'));
      expect(ctx.llmModel, equals('claude-3'));
      expect(ctx.validatedAt, equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(ctx.policyVersion, equals('3.0.0'));
      expect(ctx.metadata, equals({'region': 'us-east'}));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final ctx = ValidationContext.fromJson(json);

      expect(ctx.validationId, equals(''));
      expect(ctx.queryType, equals(''));
      expect(ctx.llmModel, isNull);
      expect(ctx.policyVersion, equals('1.0.0'));
      expect(ctx.metadata, isNull);
    });

    test('toJson populated', () {
      final ctx = ValidationContext(
        validationId: 'val-4',
        queryType: 'extraction',
        llmModel: 'palm-2',
        validatedAt: now,
        policyVersion: '1.5.0',
        metadata: {'batch': true},
      );

      final json = ctx.toJson();

      expect(json['validationId'], equals('val-4'));
      expect(json['queryType'], equals('extraction'));
      expect(json['llmModel'], equals('palm-2'));
      expect(json['validatedAt'], equals(now.toIso8601String()));
      expect(json['policyVersion'], equals('1.5.0'));
      expect(json['metadata'], equals({'batch': true}));
    });

    test('toJson excludes null/empty fields', () {
      final ctx = ValidationContext(
        validationId: 'val-5',
        queryType: 'simple',
        validatedAt: now,
        policyVersion: '1.0.0',
      );

      final json = ctx.toJson();

      expect(json.containsKey('llmModel'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // Always present
      expect(json.containsKey('validationId'), isTrue);
      expect(json.containsKey('queryType'), isTrue);
      expect(json.containsKey('validatedAt'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
    });

    test('toJson excludes empty metadata map', () {
      final ctx = ValidationContext(
        validationId: 'val-empty-meta',
        queryType: 'test',
        validatedAt: now,
        policyVersion: '1.0.0',
        metadata: {},
      );

      final json = ctx.toJson();
      // metadata is {} (not null) but empty, so should be excluded
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toString returns expected format', () {
      final ctx = ValidationContext(
        validationId: 'val-str',
        queryType: 'factual',
        validatedAt: now,
        policyVersion: '1.0.0',
      );

      expect(ctx.toString(),
          equals('ValidationContext(validationId: val-str, queryType: factual)'));
    });
  });

  // =========================================================================
  // ClaimSignal entity
  // =========================================================================
  group('ClaimSignal', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);

    final sampleContext = ValidationContext(
      validationId: 'val-1',
      queryType: 'factual',
      validatedAt: now,
      policyVersion: '1.0.0',
    );

    const sampleFeatures = ClaimFeatures(
      claimType: 'fact',
      domain: 'finance',
      structuralPattern: 'X costs Y',
    );

    test('constructor with required fields only', () {
      final signal = ClaimSignal(
        signalId: 'sig-1',
        claimId: 'claim-1',
        type: ClaimSignalType.positive,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      expect(signal.signalId, equals('sig-1'));
      expect(signal.claimId, equals('claim-1'));
      expect(signal.type, equals(ClaimSignalType.positive));
      expect(signal.timestamp, equals(now));
      expect(signal.context.validationId, equals('val-1'));
      expect(signal.features.claimType, equals('fact'));
      expect(signal.signalStrength, equals(0.5));
      expect(signal.createdAt, equals(now));
    });

    test('constructor with all fields', () {
      final signal = ClaimSignal(
        signalId: 'sig-2',
        claimId: 'claim-2',
        type: ClaimSignalType.negative,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        signalStrength: 0.9,
        createdAt: later,
      );

      expect(signal.signalStrength, equals(0.9));
      expect(signal.createdAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'signalId': 'sig-3',
        'claimId': 'claim-3',
        'type': 'conflict',
        'timestamp': '2024-06-15T10:00:00.000',
        'context': {
          'validationId': 'val-2',
          'queryType': 'analytical',
          'llmModel': 'gpt-4',
          'validatedAt': '2024-06-15T10:00:00.000',
          'policyVersion': '2.0.0',
        },
        'features': {
          'claimType': 'causal',
          'domain': 'health',
          'structuralPattern': 'X causes Y',
          'factTypes': ['medical'],
          'outcome': {'isValid': true, 'evidenceStrength': 0.8},
        },
        'signalStrength': 0.75,
        'createdAt': '2024-07-15T10:00:00.000',
      };

      final signal = ClaimSignal.fromJson(json);

      expect(signal.signalId, equals('sig-3'));
      expect(signal.claimId, equals('claim-3'));
      expect(signal.type, equals(ClaimSignalType.conflict));
      expect(signal.timestamp,
          equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(signal.context.validationId, equals('val-2'));
      expect(signal.context.queryType, equals('analytical'));
      expect(signal.context.llmModel, equals('gpt-4'));
      expect(signal.features.claimType, equals('causal'));
      expect(signal.features.domain, equals('health'));
      expect(signal.features.factTypes, equals(['medical']));
      expect(signal.features.outcome.isValid, isTrue);
      expect(signal.signalStrength, equals(0.75));
      expect(signal.createdAt,
          equals(DateTime.parse('2024-07-15T10:00:00.000')));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final signal = ClaimSignal.fromJson(json);

      expect(signal.signalId, equals(''));
      expect(signal.claimId, equals(''));
      expect(signal.type, equals(ClaimSignalType.pending));
      expect(signal.context.validationId, equals(''));
      expect(signal.context.queryType, equals(''));
      expect(signal.features.claimType, equals(''));
      expect(signal.features.domain, equals(''));
      expect(signal.features.structuralPattern, equals(''));
      expect(signal.signalStrength, equals(0.5));
    });

    test('toJson populated', () {
      final signal = ClaimSignal(
        signalId: 'sig-4',
        claimId: 'claim-4',
        type: ClaimSignalType.positive,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        signalStrength: 0.88,
        createdAt: now,
      );

      final json = signal.toJson();

      expect(json['signalId'], equals('sig-4'));
      expect(json['claimId'], equals('claim-4'));
      expect(json['type'], equals('positive'));
      expect(json['timestamp'], equals(now.toIso8601String()));
      expect(json['context'], isA<Map<String, dynamic>>());
      expect((json['context'] as Map)['validationId'], equals('val-1'));
      expect(json['features'], isA<Map<String, dynamic>>());
      expect((json['features'] as Map)['claimType'], equals('fact'));
      expect(json['signalStrength'], equals(0.88));
      expect(json['createdAt'], equals(now.toIso8601String()));
    });

    test('copyWith modifies specified fields', () {
      final original = ClaimSignal(
        signalId: 'sig-5',
        claimId: 'claim-5',
        type: ClaimSignalType.pending,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        signalStrength: 0.5,
        createdAt: now,
      );

      final newContext = ValidationContext(
        validationId: 'val-new',
        queryType: 'updated',
        validatedAt: later,
        policyVersion: '3.0.0',
      );

      const newFeatures = ClaimFeatures(
        claimType: 'relation',
        domain: 'updated',
        structuralPattern: 'A relates B',
      );

      final copy = original.copyWith(
        type: ClaimSignalType.positive,
        context: newContext,
        features: newFeatures,
        signalStrength: 0.95,
      );

      // Unchanged
      expect(copy.signalId, equals('sig-5'));
      expect(copy.claimId, equals('claim-5'));
      expect(copy.timestamp, equals(now));
      expect(copy.createdAt, equals(now));

      // Changed
      expect(copy.type, equals(ClaimSignalType.positive));
      expect(copy.context.validationId, equals('val-new'));
      expect(copy.features.claimType, equals('relation'));
      expect(copy.signalStrength, equals(0.95));
    });

    test('copyWith with no arguments returns equivalent signal', () {
      final original = ClaimSignal(
        signalId: 'sig-6',
        claimId: 'claim-6',
        type: ClaimSignalType.negative,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.signalId, equals(original.signalId));
      expect(copy.claimId, equals(original.claimId));
      expect(copy.type, equals(original.type));
      expect(copy.signalStrength, equals(original.signalStrength));
    });

    test('toString returns expected format', () {
      final signal = ClaimSignal(
        signalId: 'sig-str',
        claimId: 'claim-str',
        type: ClaimSignalType.conflict,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        signalStrength: 0.7,
        createdAt: now,
      );

      expect(signal.toString(),
          equals('ClaimSignal(sig-str, type: ClaimSignalType.conflict, strength: 0.7)'));
    });

    test('equality compares by signalId', () {
      final signal1 = ClaimSignal(
        signalId: 'sig-eq',
        claimId: 'claim-1',
        type: ClaimSignalType.positive,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      final signal2 = ClaimSignal(
        signalId: 'sig-eq',
        claimId: 'claim-2',
        type: ClaimSignalType.negative,
        timestamp: later,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: later,
      );

      final signal3 = ClaimSignal(
        signalId: 'sig-different',
        claimId: 'claim-1',
        type: ClaimSignalType.positive,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      expect(signal1 == signal2, isTrue);
      expect(signal1 == signal3, isFalse);
      expect(signal1.hashCode, equals(signal2.hashCode));
    });

    test('equality with identical reference', () {
      final signal = ClaimSignal(
        signalId: 'sig-id',
        claimId: 'claim-id',
        type: ClaimSignalType.pending,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      expect(signal == signal, isTrue);
    });

    test('equality with non-ClaimSignal object', () {
      final signal = ClaimSignal(
        signalId: 'sig-id',
        claimId: 'claim-id',
        type: ClaimSignalType.pending,
        timestamp: now,
        context: sampleContext,
        features: sampleFeatures,
        createdAt: now,
      );

      expect(signal == Object(), isFalse);
    });
  });
}
