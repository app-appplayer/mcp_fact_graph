import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('VerifiableClaim', () {
    test('creates claim with required fields', () {
      final claim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-1',
        statement: 'The sky is blue',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim.claimId, equals('claim-1'));
      expect(claim.statement, equals('The sky is blue'));
      expect(claim.claimType, equals(ClaimType.fact));
      expect(claim.verificationStatus, equals(ClaimStatus.pending));
    });

    test('creates claim with all fields', () {
      final claim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-2',
        statement: 'Water boils at 100C',
        claimType: ClaimType.fact,
        subject: 'water',
        predicate: 'boils at',
        object: '100C',
        sourceContext: 'test context',
        confidence: 0.95,
        createdAt: DateTime(2024, 1, 1),
        supportingEvidenceIds: ['ev-1', 'ev-2'],
      );

      expect(claim.subject, equals('water'));
      expect(claim.predicate, equals('boils at'));
      expect(claim.object, equals('100C'));
      expect(claim.confidence, equals(0.95));
      expect(claim.supportingEvidenceIds.length, equals(2));
    });

    test('serializes and deserializes correctly', () {
      final original = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-3',
        statement: 'Test claim',
        claimType: ClaimType.temporal,
        createdAt: DateTime(2024, 6, 15),
      );

      final json = original.toJson();
      final restored = VerifiableClaim.fromJson(json);

      expect(restored.claimId, equals(original.claimId));
      expect(restored.statement, equals(original.statement));
      expect(restored.claimType, equals(original.claimType));
    });

    test('copyWith creates modified copy', () {
      final original = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-4',
        statement: 'Original statement',
        createdAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        statement: 'Modified statement',
        verificationStatus: ClaimStatus.supported,
      );

      expect(original.statement, equals('Original statement'));
      expect(modified.statement, equals('Modified statement'));
      expect(modified.verificationStatus, equals(ClaimStatus.supported));
    });

    test('isSupported returns correct value', () {
      final pendingClaim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-5',
        statement: 'Pending',
        createdAt: DateTime(2024, 1, 1),
      );

      final supportedClaim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-6',
        statement: 'Supported',
        verificationStatus: ClaimStatus.supported,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(pendingClaim.isSupported, isFalse);
      expect(supportedClaim.isSupported, isTrue);
    });

    test('isConflicting returns correct value', () {
      final conflictingClaim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-conflict',
        statement: 'Conflicting',
        verificationStatus: ClaimStatus.conflicting,
        createdAt: DateTime(2024, 1, 1),
      );

      final pendingClaim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-pending',
        statement: 'Pending',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(conflictingClaim.isConflicting, isTrue);
      expect(pendingClaim.isConflicting, isFalse);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final claim = VerifiableClaim.fromJson(json);

      expect(claim.claimId, equals(''));
      expect(claim.workspaceId, equals('default'));
      expect(claim.statement, equals(''));
      expect(claim.claimType, equals(ClaimType.fact));
      expect(claim.subject, isNull);
      expect(claim.predicate, isNull);
      expect(claim.object, isNull);
      expect(claim.sourceContext, isNull);
      expect(claim.responseId, isNull);
      expect(claim.verificationStatus, equals(ClaimStatus.pending));
      expect(claim.verificationResult, isNull);
      expect(claim.supportingEvidenceIds, isEmpty);
      expect(claim.contradictingEvidenceIds, isEmpty);
      expect(claim.confidence, equals(0.0));
      expect(claim.verifiedAt, isNull);
      expect(claim.metadata, isEmpty);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'claimId': 'claim-full',
        'workspaceId': 'ws-1',
        'statement': 'Earth revolves around Sun',
        'claimType': 'temporal',
        'subject': 'Earth',
        'predicate': 'revolves around',
        'object': 'Sun',
        'sourceContext': 'astronomy textbook',
        'responseId': 'resp-1',
        'verificationStatus': 'supported',
        'verificationResult': {
          'verdict': 'supported',
          'confidence': 0.99,
          'explanation': 'Well established fact',
        },
        'supportingEvidenceIds': ['ev-1', 'ev-2'],
        'contradictingEvidenceIds': ['ev-3'],
        'confidence': 0.99,
        'createdAt': '2024-03-15T10:00:00.000',
        'verifiedAt': '2024-03-15T11:00:00.000',
        'metadata': {'category': 'science'},
      };

      final claim = VerifiableClaim.fromJson(json);

      expect(claim.claimId, equals('claim-full'));
      expect(claim.workspaceId, equals('ws-1'));
      expect(claim.statement, equals('Earth revolves around Sun'));
      expect(claim.claimType, equals(ClaimType.temporal));
      expect(claim.subject, equals('Earth'));
      expect(claim.predicate, equals('revolves around'));
      expect(claim.object, equals('Sun'));
      expect(claim.sourceContext, equals('astronomy textbook'));
      expect(claim.responseId, equals('resp-1'));
      expect(claim.verificationStatus, equals(ClaimStatus.supported));
      expect(claim.verificationResult, isNotNull);
      expect(claim.verificationResult!.verdict, equals(VerificationVerdict.supported));
      expect(claim.supportingEvidenceIds, equals(['ev-1', 'ev-2']));
      expect(claim.contradictingEvidenceIds, equals(['ev-3']));
      expect(claim.confidence, equals(0.99));
      expect(claim.verifiedAt, equals(DateTime(2024, 3, 15, 11)));
      expect(claim.metadata, equals({'category': 'science'}));
    });

    test('toJson excludes null and empty fields', () {
      final claim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-min',
        statement: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = claim.toJson();

      expect(json.containsKey('subject'), isFalse);
      expect(json.containsKey('predicate'), isFalse);
      expect(json.containsKey('object'), isFalse);
      expect(json.containsKey('sourceContext'), isFalse);
      expect(json.containsKey('responseId'), isFalse);
      expect(json.containsKey('verificationResult'), isFalse);
      expect(json.containsKey('supportingEvidenceIds'), isFalse);
      expect(json.containsKey('contradictingEvidenceIds'), isFalse);
      expect(json.containsKey('verifiedAt'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes non-null and non-empty fields', () {
      final claim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-full-json',
        statement: 'Full claim',
        subject: 'subj',
        predicate: 'pred',
        object: 'obj',
        sourceContext: 'ctx',
        responseId: 'resp-1',
        verificationResult: const VerificationResult(
          verdict: VerificationVerdict.supported,
          confidence: 0.9,
          explanation: 'OK',
        ),
        supportingEvidenceIds: ['ev-1'],
        contradictingEvidenceIds: ['ev-2'],
        verifiedAt: DateTime(2024, 3, 15),
        metadata: {'k': 'v'},
        createdAt: DateTime(2024, 1, 1),
      );

      final json = claim.toJson();

      expect(json['subject'], equals('subj'));
      expect(json['predicate'], equals('pred'));
      expect(json['object'], equals('obj'));
      expect(json['sourceContext'], equals('ctx'));
      expect(json['responseId'], equals('resp-1'));
      expect(json['verificationResult'], isA<Map>());
      expect(json['supportingEvidenceIds'], equals(['ev-1']));
      expect(json['contradictingEvidenceIds'], equals(['ev-2']));
      expect(json['verifiedAt'], equals(DateTime(2024, 3, 15).toIso8601String()));
      expect(json['metadata'], equals({'k': 'v'}));
    });

    test('copyWith all parameters', () {
      final original = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-orig',
        statement: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2024, 6, 1);
      final modified = original.copyWith(
        claimId: 'claim-new',
        workspaceId: 'ws-2',
        statement: 'New',
        claimType: ClaimType.opinion,
        subject: 'subj',
        predicate: 'pred',
        object: 'obj',
        sourceContext: 'ctx',
        responseId: 'resp-1',
        verificationStatus: ClaimStatus.supported,
        verificationResult: const VerificationResult(
          verdict: VerificationVerdict.supported,
          confidence: 0.95,
          explanation: 'Confirmed',
        ),
        supportingEvidenceIds: ['ev-1'],
        contradictingEvidenceIds: ['ev-2'],
        confidence: 0.95,
        createdAt: newDate,
        verifiedAt: newDate,
        metadata: {'new': true},
      );

      expect(modified.claimId, equals('claim-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.statement, equals('New'));
      expect(modified.claimType, equals(ClaimType.opinion));
      expect(modified.subject, equals('subj'));
      expect(modified.predicate, equals('pred'));
      expect(modified.object, equals('obj'));
      expect(modified.sourceContext, equals('ctx'));
      expect(modified.responseId, equals('resp-1'));
      expect(modified.verificationStatus, equals(ClaimStatus.supported));
      expect(modified.verificationResult, isNotNull);
      expect(modified.supportingEvidenceIds, equals(['ev-1']));
      expect(modified.contradictingEvidenceIds, equals(['ev-2']));
      expect(modified.confidence, equals(0.95));
      expect(modified.createdAt, equals(newDate));
      expect(modified.verifiedAt, equals(newDate));
      expect(modified.metadata, equals({'new': true}));
    });

    test('toString returns expected format', () {
      final claim = VerifiableClaim(
        workspaceId: 'test-workspace',
        claimId: 'claim-str',
        statement: 'Test',
        verificationStatus: ClaimStatus.supported,
        createdAt: DateTime(2024, 1, 1),
      );

      final str = claim.toString();

      expect(str, contains('VerifiableClaim'));
      expect(str, contains('claim-str'));
      expect(str, contains('supported'));
    });

    test('equality based on claimId', () {
      final claim1 = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'same-id',
        statement: 'A',
        createdAt: DateTime(2024, 1, 1),
      );
      final claim2 = VerifiableClaim(
        workspaceId: 'ws-2',
        claimId: 'same-id',
        statement: 'B',
        createdAt: DateTime(2024, 1, 1),
      );
      final claim3 = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'diff-id',
        statement: 'A',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim1, equals(claim2));
      expect(claim1.hashCode, equals(claim2.hashCode));
      expect(claim1 == claim3, isFalse);
    });
  });

  group('ClaimType', () {
    test('fromString parses all values correctly', () {
      expect(ClaimType.fromString('fact'), equals(ClaimType.fact));
      expect(ClaimType.fromString('date'), equals(ClaimType.date));
      expect(ClaimType.fromString('amount'), equals(ClaimType.amount));
      expect(ClaimType.fromString('quantity'), equals(ClaimType.quantity));
      expect(ClaimType.fromString('category'), equals(ClaimType.category));
      expect(ClaimType.fromString('entity'), equals(ClaimType.entity));
      expect(ClaimType.fromString('relation'), equals(ClaimType.relation));
      expect(ClaimType.fromString('temporal'), equals(ClaimType.temporal));
      expect(ClaimType.fromString('causal'), equals(ClaimType.causal));
      expect(ClaimType.fromString('comparative'), equals(ClaimType.comparative));
      expect(ClaimType.fromString('quantitative'), equals(ClaimType.quantitative));
      expect(ClaimType.fromString('conclusion'), equals(ClaimType.conclusion));
      expect(ClaimType.fromString('recommendation'), equals(ClaimType.recommendation));
      expect(ClaimType.fromString('speculation'), equals(ClaimType.speculation));
      expect(ClaimType.fromString('observation'), equals(ClaimType.observation));
      expect(ClaimType.fromString('prediction'), equals(ClaimType.prediction));
      expect(ClaimType.fromString('opinion'), equals(ClaimType.opinion));
      expect(ClaimType.fromString('hypothetical'), equals(ClaimType.hypothetical));
    });

    test('fromString returns fact for unknown', () {
      expect(ClaimType.fromString('unknown'), equals(ClaimType.fact));
    });
  });

  group('ClaimStatus', () {
    test('fromString parses all values correctly', () {
      expect(ClaimStatus.fromString('pending'), equals(ClaimStatus.pending));
      expect(ClaimStatus.fromString('verifying'), equals(ClaimStatus.verifying));
      expect(ClaimStatus.fromString('supported'), equals(ClaimStatus.supported));
      expect(ClaimStatus.fromString('unsupported'), equals(ClaimStatus.unsupported));
      expect(ClaimStatus.fromString('conflicting'), equals(ClaimStatus.conflicting));
      expect(ClaimStatus.fromString('partiallySupported'), equals(ClaimStatus.partiallySupported));
      expect(ClaimStatus.fromString('unverifiable'), equals(ClaimStatus.unverifiable));
      expect(ClaimStatus.fromString('speculation'), equals(ClaimStatus.speculation));
    });

    test('fromString returns pending for unknown', () {
      expect(ClaimStatus.fromString('unknown'), equals(ClaimStatus.pending));
    });
  });

  group('VerificationResult', () {
    test('creates verification result with defaults', () {
      const result = VerificationResult(
        verdict: VerificationVerdict.supported,
        confidence: 0.9,
        explanation: 'Claim is supported by evidence',
      );

      expect(result.verdict, equals(VerificationVerdict.supported));
      expect(result.confidence, equals(0.9));
      expect(result.explanation, equals('Claim is supported by evidence'));
      expect(result.evidence, isEmpty);
      expect(result.alternatives, isEmpty);
      expect(result.durationMs, equals(0));
    });

    test('creates verification result with all fields', () {
      const result = VerificationResult(
        verdict: VerificationVerdict.partiallySupported,
        confidence: 0.7,
        explanation: 'Partially supported',
        evidence: [
          EvidenceReference(
            evidenceId: 'ev-1',
            evidenceType: 'document',
            relevance: 0.9,
            relation: EvidenceRelation.supports,
          ),
        ],
        alternatives: ['Alternative interpretation 1'],
        durationMs: 250,
      );

      expect(result.evidence, hasLength(1));
      expect(result.alternatives, equals(['Alternative interpretation 1']));
      expect(result.durationMs, equals(250));
    });

    test('serializes and deserializes correctly', () {
      const original = VerificationResult(
        verdict: VerificationVerdict.refuted,
        confidence: 0.8,
        explanation: 'Evidence contradicts claim',
        durationMs: 150,
      );

      final json = original.toJson();
      final restored = VerificationResult.fromJson(json);

      expect(restored.verdict, equals(original.verdict));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.explanation, equals(original.explanation));
      expect(restored.durationMs, equals(original.durationMs));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final result = VerificationResult.fromJson(json);

      expect(result.verdict, equals(VerificationVerdict.unknown));
      expect(result.confidence, equals(0.0));
      expect(result.explanation, equals(''));
      expect(result.evidence, isEmpty);
      expect(result.alternatives, isEmpty);
      expect(result.durationMs, equals(0));
    });

    test('fromJson parses evidence list', () {
      final json = {
        'verdict': 'supported',
        'confidence': 0.9,
        'explanation': 'Good',
        'evidence': [
          {
            'evidenceId': 'ev-1',
            'evidenceType': 'document',
            'relevance': 0.8,
            'relation': 'supports',
          },
        ],
        'alternatives': ['Alt 1', 'Alt 2'],
        'durationMs': 300,
      };

      final result = VerificationResult.fromJson(json);

      expect(result.evidence, hasLength(1));
      expect(result.evidence.first.evidenceId, equals('ev-1'));
      expect(result.alternatives, equals(['Alt 1', 'Alt 2']));
    });

    test('toJson excludes empty evidence and alternatives', () {
      const result = VerificationResult(
        verdict: VerificationVerdict.supported,
        confidence: 0.9,
        explanation: 'OK',
      );

      final json = result.toJson();

      expect(json.containsKey('evidence'), isFalse);
      expect(json.containsKey('alternatives'), isFalse);
    });

    test('toJson includes non-empty evidence and alternatives', () {
      const result = VerificationResult(
        verdict: VerificationVerdict.supported,
        confidence: 0.9,
        explanation: 'OK',
        evidence: [
          EvidenceReference(
            evidenceId: 'ev-1',
            evidenceType: 'doc',
          ),
        ],
        alternatives: ['Alt'],
      );

      final json = result.toJson();

      expect(json['evidence'], isA<List>());
      expect(json['alternatives'], equals(['Alt']));
    });
  });

  group('VerificationVerdict', () {
    test('fromString parses all values correctly', () {
      expect(VerificationVerdict.fromString('supported'), equals(VerificationVerdict.supported));
      expect(VerificationVerdict.fromString('partiallySupported'), equals(VerificationVerdict.partiallySupported));
      expect(VerificationVerdict.fromString('refuted'), equals(VerificationVerdict.refuted));
      expect(VerificationVerdict.fromString('conflicting'), equals(VerificationVerdict.conflicting));
      expect(VerificationVerdict.fromString('insufficientEvidence'), equals(VerificationVerdict.insufficientEvidence));
      expect(VerificationVerdict.fromString('unknown'), equals(VerificationVerdict.unknown));
    });

    test('fromString returns unknown for invalid', () {
      expect(VerificationVerdict.fromString('invalid'), equals(VerificationVerdict.unknown));
    });
  });

  group('EvidenceReference', () {
    test('creates evidence reference with defaults', () {
      const ref = EvidenceReference(
        evidenceId: 'ev-1',
        evidenceType: 'document',
      );

      expect(ref.evidenceId, equals('ev-1'));
      expect(ref.evidenceType, equals('document'));
      expect(ref.relevance, equals(0.0));
      expect(ref.relation, equals(EvidenceRelation.neutral));
      expect(ref.excerpt, isNull);
    });

    test('creates evidence reference with all fields', () {
      const ref = EvidenceReference(
        evidenceId: 'ev-1',
        evidenceType: 'document',
        relevance: 0.95,
        relation: EvidenceRelation.supports,
        excerpt: 'Some text',
      );

      expect(ref.evidenceId, equals('ev-1'));
      expect(ref.evidenceType, equals('document'));
      expect(ref.relevance, equals(0.95));
      expect(ref.relation, equals(EvidenceRelation.supports));
      expect(ref.excerpt, equals('Some text'));
    });

    test('serializes and deserializes correctly', () {
      const original = EvidenceReference(
        evidenceId: 'ev-2',
        evidenceType: 'entity',
        relevance: 0.75,
        relation: EvidenceRelation.contradicts,
        excerpt: 'Some text excerpt',
      );

      final json = original.toJson();
      final restored = EvidenceReference.fromJson(json);

      expect(restored.evidenceId, equals(original.evidenceId));
      expect(restored.evidenceType, equals(original.evidenceType));
      expect(restored.relevance, equals(original.relevance));
      expect(restored.relation, equals(original.relation));
      expect(restored.excerpt, equals(original.excerpt));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final ref = EvidenceReference.fromJson(json);

      expect(ref.evidenceId, equals(''));
      expect(ref.evidenceType, equals(''));
      expect(ref.relevance, equals(0.0));
      expect(ref.relation, equals(EvidenceRelation.neutral));
      expect(ref.excerpt, isNull);
    });

    test('toJson excludes null excerpt', () {
      const ref = EvidenceReference(
        evidenceId: 'ev-1',
        evidenceType: 'doc',
      );

      final json = ref.toJson();
      expect(json.containsKey('excerpt'), isFalse);
    });

    test('toJson includes non-null excerpt', () {
      const ref = EvidenceReference(
        evidenceId: 'ev-1',
        evidenceType: 'doc',
        excerpt: 'text',
      );

      final json = ref.toJson();
      expect(json['excerpt'], equals('text'));
    });
  });

  group('EvidenceRelation', () {
    test('fromString parses all values correctly', () {
      expect(EvidenceRelation.fromString('supports'), equals(EvidenceRelation.supports));
      expect(EvidenceRelation.fromString('contradicts'), equals(EvidenceRelation.contradicts));
      expect(EvidenceRelation.fromString('neutral'), equals(EvidenceRelation.neutral));
    });

    test('fromString returns neutral for invalid', () {
      expect(EvidenceRelation.fromString('invalid'), equals(EvidenceRelation.neutral));
    });
  });

  // =========================================================================
  // Additional coverage tests
  // =========================================================================
  group('VerifiableClaim additional coverage', () {
    test('constructor with metadata default', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-meta-default',
        statement: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );

      // metadata defaults to const {}
      expect(claim.metadata, isEmpty);
      expect(claim.metadata, isA<Map<String, dynamic>>());
    });

    test('fromJson with verificationResult', () {
      final json = {
        'claimId': 'claim-vr',
        'workspaceId': 'ws-1',
        'statement': 'Verified claim',
        'verificationResult': {
          'verdict': 'refuted',
          'confidence': 0.7,
          'explanation': 'Evidence contradicts',
          'evidence': [
            {
              'evidenceId': 'ev-1',
              'evidenceType': 'document',
              'relevance': 0.85,
              'relation': 'contradicts',
              'excerpt': 'Contradicting text',
            },
          ],
          'alternatives': ['Alt interpretation'],
          'durationMs': 500,
        },
        'contradictingEvidenceIds': ['ev-1', 'ev-2'],
        'verifiedAt': '2024-06-15T12:00:00.000',
        'createdAt': '2024-06-15T10:00:00.000',
      };

      final claim = VerifiableClaim.fromJson(json);

      expect(claim.verificationResult, isNotNull);
      expect(claim.verificationResult!.verdict, equals(VerificationVerdict.refuted));
      expect(claim.verificationResult!.confidence, equals(0.7));
      expect(claim.verificationResult!.evidence, hasLength(1));
      expect(claim.verificationResult!.evidence.first.excerpt, equals('Contradicting text'));
      expect(claim.verificationResult!.alternatives, equals(['Alt interpretation']));
      expect(claim.verificationResult!.durationMs, equals(500));
      expect(claim.contradictingEvidenceIds, equals(['ev-1', 'ev-2']));
      expect(claim.verifiedAt, equals(DateTime(2024, 6, 15, 12)));
    });

    test('copyWith preserves all fields when no arguments', () {
      final original = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-cw-all',
        statement: 'Test',
        claimType: ClaimType.causal,
        subject: 'subj',
        predicate: 'pred',
        object: 'obj',
        sourceContext: 'ctx',
        responseId: 'resp',
        verificationStatus: ClaimStatus.supported,
        verificationResult: const VerificationResult(
          verdict: VerificationVerdict.supported,
          confidence: 0.9,
          explanation: 'Good',
        ),
        supportingEvidenceIds: ['ev-1'],
        contradictingEvidenceIds: ['ev-2'],
        confidence: 0.85,
        createdAt: DateTime(2024, 1, 1),
        verifiedAt: DateTime(2024, 2, 1),
        metadata: {'k': 'v'},
      );

      final copy = original.copyWith();

      expect(copy.claimId, equals(original.claimId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.statement, equals(original.statement));
      expect(copy.claimType, equals(original.claimType));
      expect(copy.subject, equals(original.subject));
      expect(copy.predicate, equals(original.predicate));
      expect(copy.object, equals(original.object));
      expect(copy.sourceContext, equals(original.sourceContext));
      expect(copy.responseId, equals(original.responseId));
      expect(copy.verificationStatus, equals(original.verificationStatus));
      expect(copy.verificationResult, isNotNull);
      expect(copy.supportingEvidenceIds, equals(original.supportingEvidenceIds));
      expect(copy.contradictingEvidenceIds, equals(original.contradictingEvidenceIds));
      expect(copy.confidence, equals(original.confidence));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.verifiedAt, equals(original.verifiedAt));
      expect(copy.metadata, equals(original.metadata));
    });

    test('toJson with verificationResult including evidence', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-vr-json',
        statement: 'Full toJson test',
        verificationResult: const VerificationResult(
          verdict: VerificationVerdict.partiallySupported,
          confidence: 0.6,
          explanation: 'Partial',
          evidence: [
            EvidenceReference(
              evidenceId: 'ev-1',
              evidenceType: 'entity',
              relevance: 0.7,
              relation: EvidenceRelation.supports,
              excerpt: 'Supporting text',
            ),
          ],
          alternatives: ['Maybe this', 'Or that'],
          durationMs: 100,
        ),
        supportingEvidenceIds: ['ev-1'],
        contradictingEvidenceIds: ['ev-2'],
        confidence: 0.6,
        verifiedAt: DateTime(2024, 3, 1),
        metadata: {'source': 'test'},
        createdAt: DateTime(2024, 1, 1),
      );

      final json = claim.toJson();

      expect(json['verificationResult'], isA<Map>());
      final vrJson = json['verificationResult'] as Map<String, dynamic>;
      expect(vrJson['verdict'], equals('partiallySupported'));
      expect(vrJson['evidence'], isA<List>());
      expect((vrJson['evidence'] as List), hasLength(1));
      expect(vrJson['alternatives'], equals(['Maybe this', 'Or that']));
      expect(vrJson['durationMs'], equals(100));
      expect(json['supportingEvidenceIds'], equals(['ev-1']));
      expect(json['contradictingEvidenceIds'], equals(['ev-2']));
      expect(json['verifiedAt'], isNotNull);
      expect(json['metadata'], equals({'source': 'test'}));
    });

    test('equality with identical reference', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-self',
        statement: 'Self',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim == claim, isTrue);
    });

    test('equality with non-VerifiableClaim object', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-type',
        statement: 'Type check',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim == Object(), isFalse);
    });

    test('hashCode is based on claimId', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-hash',
        statement: 'Hash test',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim.hashCode, equals('claim-hash'.hashCode));
    });

    test('toString format', () {
      final claim = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-ts',
        statement: 'Test',
        verificationStatus: ClaimStatus.conflicting,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(claim.toString(),
          equals('VerifiableClaim(claim-ts, status: ClaimStatus.conflicting)'));
    });

    test('isSupported and isConflicting with various statuses', () {
      final unverifiable = VerifiableClaim(
        workspaceId: 'ws-1',
        claimId: 'claim-uv',
        statement: 'Unverifiable',
        verificationStatus: ClaimStatus.unverifiable,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(unverifiable.isSupported, isFalse);
      expect(unverifiable.isConflicting, isFalse);
    });
  });

  group('ClaimType additional', () {
    test('all enum values exist', () {
      expect(ClaimType.values, contains(ClaimType.fact));
      expect(ClaimType.values, contains(ClaimType.date));
      expect(ClaimType.values, contains(ClaimType.amount));
      expect(ClaimType.values, contains(ClaimType.quantity));
      expect(ClaimType.values, contains(ClaimType.category));
      expect(ClaimType.values, contains(ClaimType.entity));
      expect(ClaimType.values, contains(ClaimType.relation));
      expect(ClaimType.values, contains(ClaimType.temporal));
      expect(ClaimType.values, contains(ClaimType.causal));
      expect(ClaimType.values, contains(ClaimType.comparative));
      expect(ClaimType.values, contains(ClaimType.quantitative));
      expect(ClaimType.values, contains(ClaimType.conclusion));
      expect(ClaimType.values, contains(ClaimType.recommendation));
      expect(ClaimType.values, contains(ClaimType.speculation));
      expect(ClaimType.values, contains(ClaimType.observation));
      expect(ClaimType.values, contains(ClaimType.prediction));
      expect(ClaimType.values, contains(ClaimType.opinion));
      expect(ClaimType.values, contains(ClaimType.hypothetical));
      expect(ClaimType.values.length, equals(18));
    });
  });

  group('ClaimStatus additional', () {
    test('all enum values exist', () {
      expect(ClaimStatus.values, contains(ClaimStatus.pending));
      expect(ClaimStatus.values, contains(ClaimStatus.verifying));
      expect(ClaimStatus.values, contains(ClaimStatus.supported));
      expect(ClaimStatus.values, contains(ClaimStatus.unsupported));
      expect(ClaimStatus.values, contains(ClaimStatus.conflicting));
      expect(ClaimStatus.values, contains(ClaimStatus.partiallySupported));
      expect(ClaimStatus.values, contains(ClaimStatus.unverifiable));
      expect(ClaimStatus.values, contains(ClaimStatus.speculation));
      expect(ClaimStatus.values.length, equals(8));
    });
  });

  group('VerificationVerdict additional', () {
    test('all enum values exist', () {
      expect(VerificationVerdict.values, contains(VerificationVerdict.supported));
      expect(VerificationVerdict.values, contains(VerificationVerdict.partiallySupported));
      expect(VerificationVerdict.values, contains(VerificationVerdict.refuted));
      expect(VerificationVerdict.values, contains(VerificationVerdict.conflicting));
      expect(VerificationVerdict.values, contains(VerificationVerdict.insufficientEvidence));
      expect(VerificationVerdict.values, contains(VerificationVerdict.unknown));
      expect(VerificationVerdict.values.length, equals(6));
    });
  });

  group('VerificationResult additional', () {
    test('fromJson with full evidence list', () {
      final json = {
        'verdict': 'conflicting',
        'confidence': 0.5,
        'explanation': 'Mixed evidence',
        'evidence': [
          {
            'evidenceId': 'ev-1',
            'evidenceType': 'document',
            'relevance': 0.9,
            'relation': 'supports',
            'excerpt': 'Supporting text',
          },
          {
            'evidenceId': 'ev-2',
            'evidenceType': 'entity',
            'relevance': 0.8,
            'relation': 'contradicts',
          },
        ],
        'alternatives': ['Interpretation A', 'Interpretation B'],
        'durationMs': 750,
      };

      final result = VerificationResult.fromJson(json);

      expect(result.verdict, equals(VerificationVerdict.conflicting));
      expect(result.evidence, hasLength(2));
      expect(result.evidence[0].excerpt, equals('Supporting text'));
      expect(result.evidence[1].excerpt, isNull);
      expect(result.alternatives, hasLength(2));
      expect(result.durationMs, equals(750));
    });

    test('toJson with evidence and alternatives', () {
      const result = VerificationResult(
        verdict: VerificationVerdict.insufficientEvidence,
        confidence: 0.3,
        explanation: 'Not enough data',
        evidence: [
          EvidenceReference(
            evidenceId: 'ev-a',
            evidenceType: 'doc',
            relevance: 0.5,
            relation: EvidenceRelation.neutral,
          ),
        ],
        alternatives: ['Could be X'],
        durationMs: 200,
      );

      final json = result.toJson();

      expect(json['verdict'], equals('insufficientEvidence'));
      expect(json['evidence'], isA<List>());
      expect((json['evidence'] as List), hasLength(1));
      expect(json['alternatives'], equals(['Could be X']));
      expect(json['durationMs'], equals(200));
    });
  });

  group('EvidenceReference additional', () {
    test('toJson with all fields', () {
      const ref = EvidenceReference(
        evidenceId: 'ev-full',
        evidenceType: 'entity',
        relevance: 0.9,
        relation: EvidenceRelation.supports,
        excerpt: 'Full reference',
      );

      final json = ref.toJson();

      expect(json['evidenceId'], equals('ev-full'));
      expect(json['evidenceType'], equals('entity'));
      expect(json['relevance'], equals(0.9));
      expect(json['relation'], equals('supports'));
      expect(json['excerpt'], equals('Full reference'));
    });

    test('fromJson with all fields', () {
      final json = {
        'evidenceId': 'ev-parse',
        'evidenceType': 'document',
        'relevance': 0.75,
        'relation': 'contradicts',
        'excerpt': 'Parsed text',
      };

      final ref = EvidenceReference.fromJson(json);

      expect(ref.evidenceId, equals('ev-parse'));
      expect(ref.evidenceType, equals('document'));
      expect(ref.relevance, equals(0.75));
      expect(ref.relation, equals(EvidenceRelation.contradicts));
      expect(ref.excerpt, equals('Parsed text'));
    });
  });
}
