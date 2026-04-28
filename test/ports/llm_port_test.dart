// Tests for LLM port concrete classes.

import 'package:test/test.dart';
// Internal port — accessed via src path since it is not barrel-exported.
import 'package:mcp_fact_graph/src/ports/llm_port.dart';

void main() {
  group('EntityResolutionInput', () {
    test('creates with required parameters', () {
      const input = EntityResolutionInput(name: 'Alice');

      expect(input.name, equals('Alice'));
      expect(input.typeHint, isNull);
      expect(input.context, isNull);
      expect(input.attributes, isNull);
    });

    test('creates with all parameters', () {
      const input = EntityResolutionInput(
        name: 'Alice',
        typeHint: 'person',
        context: 'colleague at work',
        attributes: {'department': 'engineering'},
      );

      expect(input.name, equals('Alice'));
      expect(input.typeHint, equals('person'));
      expect(input.context, equals('colleague at work'));
      expect(input.attributes, equals({'department': 'engineering'}));
    });
  });

  group('EntityResolutionResult', () {
    test('creates with required parameters', () {
      const result = EntityResolutionResult(
        shouldCreate: false,
        confidence: 0.9,
      );

      expect(result.entityId, isNull);
      expect(result.shouldCreate, isFalse);
      expect(result.confidence, equals(0.9));
      expect(result.alternatives, isEmpty);
    });

    test('creates with entityId', () {
      const result = EntityResolutionResult(
        entityId: 'ent-1',
        shouldCreate: false,
        confidence: 0.95,
      );

      expect(result.entityId, equals('ent-1'));
      expect(result.shouldCreate, isFalse);
    });

    test('creates with alternatives', () {
      const result = EntityResolutionResult(
        shouldCreate: true,
        confidence: 0.5,
        alternatives: [
          EntityMatch(
            entityId: 'ent-1',
            name: 'Alice Smith',
            entityType: 'person',
            confidence: 0.7,
          ),
          EntityMatch(
            entityId: 'ent-2',
            name: 'Alice Jones',
            entityType: 'person',
            confidence: 0.6,
          ),
        ],
      );

      expect(result.alternatives, hasLength(2));
      expect(result.alternatives.first.entityId, equals('ent-1'));
      expect(result.alternatives.last.entityId, equals('ent-2'));
    });
  });

  group('EntityMatch', () {
    test('creates with required parameters', () {
      const match = EntityMatch(
        entityId: 'ent-1',
        name: 'Alice',
        entityType: 'person',
        confidence: 0.85,
      );

      expect(match.entityId, equals('ent-1'));
      expect(match.name, equals('Alice'));
      expect(match.entityType, equals('person'));
      expect(match.confidence, equals(0.85));
      expect(match.reason, isNull);
    });

    test('creates with reason', () {
      const match = EntityMatch(
        entityId: 'ent-1',
        name: 'Alice',
        entityType: 'person',
        confidence: 0.85,
        reason: 'Exact name match',
      );

      expect(match.reason, equals('Exact name match'));
    });
  });

  group('ClaimVerificationInput', () {
    test('creates with required parameters', () {
      const input = ClaimVerificationInput(
        claim: 'The sky is blue',
        evidence: ['Scientific observation confirms sky appears blue'],
      );

      expect(input.claim, equals('The sky is blue'));
      expect(input.evidence, hasLength(1));
      expect(input.context, isNull);
    });

    test('creates with context', () {
      const input = ClaimVerificationInput(
        claim: 'The sky is blue',
        evidence: ['Evidence 1', 'Evidence 2'],
        context: 'Weather discussion',
      );

      expect(input.context, equals('Weather discussion'));
      expect(input.evidence, hasLength(2));
    });
  });

  group('ClaimVerificationResult', () {
    test('creates with required parameters', () {
      const result = ClaimVerificationResult(
        verdict: 'supported',
        confidence: 0.9,
        explanation: 'Evidence supports the claim.',
      );

      expect(result.verdict, equals('supported'));
      expect(result.confidence, equals(0.9));
      expect(result.explanation, equals('Evidence supports the claim.'));
      expect(result.supportingIndices, isEmpty);
      expect(result.contradictingIndices, isEmpty);
    });

    test('creates with supporting and contradicting indices', () {
      const result = ClaimVerificationResult(
        verdict: 'partiallySupported',
        confidence: 0.6,
        explanation: 'Mixed evidence found.',
        supportingIndices: [0, 2],
        contradictingIndices: [1],
      );

      expect(result.supportingIndices, equals([0, 2]));
      expect(result.contradictingIndices, equals([1]));
    });
  });
}
