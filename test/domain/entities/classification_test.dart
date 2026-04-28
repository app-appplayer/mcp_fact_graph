import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // ClassificationStatus enum tests
  // =========================================================================
  group('ClassificationStatus', () {
    test('has all expected values', () {
      expect(ClassificationStatus.values,
          contains(ClassificationStatus.proposed));
      expect(ClassificationStatus.values,
          contains(ClassificationStatus.confirmed));
      expect(ClassificationStatus.values,
          contains(ClassificationStatus.reclassified));
      expect(ClassificationStatus.values.length, equals(3));
    });

    test('fromString valid values', () {
      expect(ClassificationStatus.fromString('proposed'),
          equals(ClassificationStatus.proposed));
      expect(ClassificationStatus.fromString('confirmed'),
          equals(ClassificationStatus.confirmed));
      expect(ClassificationStatus.fromString('reclassified'),
          equals(ClassificationStatus.reclassified));
    });

    test('fromString is case-insensitive', () {
      expect(ClassificationStatus.fromString('PROPOSED'),
          equals(ClassificationStatus.proposed));
      expect(ClassificationStatus.fromString('Confirmed'),
          equals(ClassificationStatus.confirmed));
      expect(ClassificationStatus.fromString('RECLASSIFIED'),
          equals(ClassificationStatus.reclassified));
    });

    test('fromString invalid returns default (proposed)', () {
      expect(ClassificationStatus.fromString('unknown'),
          equals(ClassificationStatus.proposed));
      expect(ClassificationStatus.fromString(''),
          equals(ClassificationStatus.proposed));
      expect(ClassificationStatus.fromString('invalid'),
          equals(ClassificationStatus.proposed));
    });
  });

  // =========================================================================
  // Classification tests
  // =========================================================================
  group('Classification', () {
    final now = DateTime(2024, 6, 15, 10);

    test('constructor with required fields only', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      expect(classification.classificationId, equals('cls-1'));
      expect(classification.targetType, equals('candidate'));
      expect(classification.targetId, equals('target-1'));
      expect(classification.taxonomyId, equals('tax-1'));
      expect(classification.categoryId, equals('cat-1'));
      expect(classification.status, equals(ClassificationStatus.proposed));
      expect(classification.confidence, equals(1.0));
      expect(classification.rationale, isNull);
      expect(classification.policyVersion, equals('v1.0'));
      expect(classification.evidenceRefs, isEmpty);
      expect(classification.createdAt, equals(now));
      expect(classification.updatedAt, isNull);
      expect(classification.previousClassificationId, isNull);
    });

    test('constructor with all fields', () {
      final updated = DateTime(2024, 6, 16, 10);
      final classification = Classification(
        classificationId: 'cls-2',
        targetType: 'event',
        targetId: 'target-2',
        taxonomyId: 'tax-2',
        categoryId: 'cat-2',
        status: ClassificationStatus.confirmed,
        confidence: 0.85,
        rationale: 'High similarity match',
        policyVersion: 'v2.0',
        evidenceRefs: ['ev-1', 'ev-2'],
        createdAt: now,
        updatedAt: updated,
        previousClassificationId: 'cls-1',
      );

      expect(classification.classificationId, equals('cls-2'));
      expect(classification.targetType, equals('event'));
      expect(classification.targetId, equals('target-2'));
      expect(classification.taxonomyId, equals('tax-2'));
      expect(classification.categoryId, equals('cat-2'));
      expect(classification.status, equals(ClassificationStatus.confirmed));
      expect(classification.confidence, equals(0.85));
      expect(classification.rationale, equals('High similarity match'));
      expect(classification.policyVersion, equals('v2.0'));
      expect(classification.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(classification.createdAt, equals(now));
      expect(classification.updatedAt, equals(updated));
      expect(classification.previousClassificationId, equals('cls-1'));
    });

    test('fromJson complete', () {
      final json = {
        'classificationId': 'cls-1',
        'targetType': 'candidate',
        'targetId': 'target-1',
        'taxonomyId': 'tax-1',
        'categoryId': 'cat-1',
        'status': 'confirmed',
        'confidence': 0.9,
        'rationale': 'Pattern match',
        'policyVersion': 'v1.0',
        'evidenceRefs': ['ev-1'],
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-16T10:00:00.000',
        'previousClassificationId': 'cls-0',
      };

      final classification = Classification.fromJson(json);

      expect(classification.classificationId, equals('cls-1'));
      expect(classification.targetType, equals('candidate'));
      expect(classification.targetId, equals('target-1'));
      expect(classification.taxonomyId, equals('tax-1'));
      expect(classification.categoryId, equals('cat-1'));
      expect(classification.status, equals(ClassificationStatus.confirmed));
      expect(classification.confidence, equals(0.9));
      expect(classification.rationale, equals('Pattern match'));
      expect(classification.policyVersion, equals('v1.0'));
      expect(classification.evidenceRefs, equals(['ev-1']));
      expect(classification.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(classification.updatedAt, equals(DateTime(2024, 6, 16, 10)));
      expect(classification.previousClassificationId, equals('cls-0'));
    });

    test('fromJson empty/missing fields', () {
      final classification = Classification.fromJson(<String, dynamic>{});

      expect(classification.classificationId, equals(''));
      expect(classification.targetType, equals(''));
      expect(classification.targetId, equals(''));
      expect(classification.taxonomyId, equals(''));
      expect(classification.categoryId, equals(''));
      expect(classification.status, equals(ClassificationStatus.proposed));
      expect(classification.confidence, equals(1.0));
      expect(classification.rationale, isNull);
      expect(classification.policyVersion, equals(''));
      expect(classification.evidenceRefs, isEmpty);
      expect(classification.createdAt, isA<DateTime>());
      expect(classification.updatedAt, isNull);
      expect(classification.previousClassificationId, isNull);
    });

    test('fromJson with null createdAt falls back to DateTime.now()', () {
      final classification = Classification.fromJson({'createdAt': null});
      expect(classification.createdAt, isA<DateTime>());
    });

    test('fromJson with null updatedAt returns null', () {
      final classification = Classification.fromJson({'updatedAt': null});
      expect(classification.updatedAt, isNull);
    });

    test('toJson populated', () {
      final updated = DateTime(2024, 6, 16, 10);
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.reclassified,
        confidence: 0.75,
        rationale: 'Manual review',
        policyVersion: 'v1.0',
        evidenceRefs: ['ev-1', 'ev-2'],
        createdAt: now,
        updatedAt: updated,
        previousClassificationId: 'cls-0',
      );

      final json = classification.toJson();

      expect(json['classificationId'], equals('cls-1'));
      expect(json['targetType'], equals('candidate'));
      expect(json['targetId'], equals('target-1'));
      expect(json['taxonomyId'], equals('tax-1'));
      expect(json['categoryId'], equals('cat-1'));
      expect(json['status'], equals('reclassified'));
      expect(json['confidence'], equals(0.75));
      expect(json['rationale'], equals('Manual review'));
      expect(json['policyVersion'], equals('v1.0'));
      expect(json['evidenceRefs'], equals(['ev-1', 'ev-2']));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(updated.toIso8601String()));
      expect(json['previousClassificationId'], equals('cls-0'));
    });

    test('toJson excludes null and empty fields', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final json = classification.toJson();

      expect(json.containsKey('rationale'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
      expect(json.containsKey('previousClassificationId'), isFalse);
      // Always-present fields
      expect(json.containsKey('classificationId'), isTrue);
      expect(json.containsKey('targetType'), isTrue);
      expect(json.containsKey('targetId'), isTrue);
      expect(json.containsKey('taxonomyId'), isTrue);
      expect(json.containsKey('categoryId'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('confidence'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final original = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final copy = original.copyWith(
        status: ClassificationStatus.confirmed,
        confidence: 0.95,
        rationale: 'Auto-confirmed',
      );

      expect(copy.classificationId, equals('cls-1'));
      expect(copy.status, equals(ClassificationStatus.confirmed));
      expect(copy.confidence, equals(0.95));
      expect(copy.rationale, equals('Auto-confirmed'));
      // Unchanged fields
      expect(copy.targetType, equals('candidate'));
      expect(copy.targetId, equals('target-1'));
      expect(copy.taxonomyId, equals('tax-1'));
      expect(copy.categoryId, equals('cat-1'));
      expect(copy.policyVersion, equals('v1.0'));
      expect(copy.createdAt, equals(now));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.classificationId, equals(original.classificationId));
      expect(copy.targetType, equals(original.targetType));
      expect(copy.targetId, equals(original.targetId));
      expect(copy.taxonomyId, equals(original.taxonomyId));
      expect(copy.categoryId, equals(original.categoryId));
      expect(copy.status, equals(original.status));
      expect(copy.confidence, equals(original.confidence));
      expect(copy.rationale, equals(original.rationale));
      expect(copy.policyVersion, equals(original.policyVersion));
      expect(copy.evidenceRefs, equals(original.evidenceRefs));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
      expect(copy.previousClassificationId,
          equals(original.previousClassificationId));
    });

    test('copyWith replaces all fields', () {
      final original = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final newDate = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        classificationId: 'cls-new',
        targetType: 'event',
        targetId: 'target-new',
        taxonomyId: 'tax-new',
        categoryId: 'cat-new',
        status: ClassificationStatus.reclassified,
        confidence: 0.5,
        rationale: 'New rationale',
        policyVersion: 'v9.0',
        evidenceRefs: ['ev-new'],
        createdAt: newDate,
        updatedAt: newDate,
        previousClassificationId: 'cls-old',
      );

      expect(copy.classificationId, equals('cls-new'));
      expect(copy.targetType, equals('event'));
      expect(copy.targetId, equals('target-new'));
      expect(copy.taxonomyId, equals('tax-new'));
      expect(copy.categoryId, equals('cat-new'));
      expect(copy.status, equals(ClassificationStatus.reclassified));
      expect(copy.confidence, equals(0.5));
      expect(copy.rationale, equals('New rationale'));
      expect(copy.policyVersion, equals('v9.0'));
      expect(copy.evidenceRefs, equals(['ev-new']));
      expect(copy.createdAt, equals(newDate));
      expect(copy.updatedAt, equals(newDate));
      expect(copy.previousClassificationId, equals('cls-old'));
    });

    // -----------------------------------------------------------------------
    // Boolean getters
    // -----------------------------------------------------------------------
    test('isConfirmed returns true when confirmed', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.confirmed,
        policyVersion: 'v1.0',
        createdAt: now,
      );
      expect(classification.isConfirmed, isTrue);
      expect(classification.isPending, isFalse);
    });

    test('isConfirmed returns false when proposed', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.proposed,
        policyVersion: 'v1.0',
        createdAt: now,
      );
      expect(classification.isConfirmed, isFalse);
    });

    test('isPending returns true when proposed', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.proposed,
        policyVersion: 'v1.0',
        createdAt: now,
      );
      expect(classification.isPending, isTrue);
    });

    test('isPending returns false when reclassified', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        status: ClassificationStatus.reclassified,
        policyVersion: 'v1.0',
        createdAt: now,
      );
      expect(classification.isPending, isFalse);
    });

    // -----------------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------------
    test('confirm() returns confirmed classification with updatedAt', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final confirmed = classification.confirm();

      expect(confirmed.status, equals(ClassificationStatus.confirmed));
      expect(confirmed.updatedAt, isA<DateTime>());
      expect(confirmed.classificationId, equals('cls-1'));
      expect(confirmed.targetType, equals('candidate'));
      expect(confirmed.categoryId, equals('cat-1'));
    });

    test('reclassify() returns reclassified classification', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        confidence: 0.9,
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final reclassified = classification.reclassify(
        newCategoryId: 'cat-2',
        newRationale: 'Better match found',
        newConfidence: 0.7,
      );

      expect(reclassified.status, equals(ClassificationStatus.reclassified));
      expect(reclassified.categoryId, equals('cat-2'));
      expect(reclassified.rationale, equals('Better match found'));
      expect(reclassified.confidence, equals(0.7));
      expect(reclassified.updatedAt, isA<DateTime>());
      expect(reclassified.previousClassificationId, equals('cls-1'));
      // Unchanged fields
      expect(reclassified.classificationId, equals('cls-1'));
      expect(reclassified.targetType, equals('candidate'));
      expect(reclassified.taxonomyId, equals('tax-1'));
    });

    test('reclassify() with minimal arguments', () {
      final classification = Classification(
        classificationId: 'cls-1',
        targetType: 'candidate',
        targetId: 'target-1',
        taxonomyId: 'tax-1',
        categoryId: 'cat-1',
        confidence: 0.9,
        policyVersion: 'v1.0',
        createdAt: now,
      );

      final reclassified = classification.reclassify(
        newCategoryId: 'cat-3',
      );

      expect(reclassified.categoryId, equals('cat-3'));
      expect(reclassified.status, equals(ClassificationStatus.reclassified));
      expect(reclassified.previousClassificationId, equals('cls-1'));
      // rationale and confidence should remain from original since null passed
      expect(reclassified.rationale, isNull);
      expect(reclassified.confidence, equals(0.9));
    });
  });
}
