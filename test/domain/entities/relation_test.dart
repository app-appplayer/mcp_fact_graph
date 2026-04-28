import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // RelationStatus enum tests
  // =========================================================================
  group('RelationStatus', () {
    test('has all expected values', () {
      expect(RelationStatus.values, contains(RelationStatus.proposed));
      expect(RelationStatus.values, contains(RelationStatus.confirmed));
      expect(RelationStatus.values.length, equals(2));
    });

    test('fromString valid values', () {
      expect(RelationStatus.fromString('proposed'),
          equals(RelationStatus.proposed));
      expect(RelationStatus.fromString('confirmed'),
          equals(RelationStatus.confirmed));
    });

    test('fromString is case-insensitive', () {
      expect(RelationStatus.fromString('PROPOSED'),
          equals(RelationStatus.proposed));
      expect(RelationStatus.fromString('Confirmed'),
          equals(RelationStatus.confirmed));
    });

    test('fromString invalid returns default (proposed)', () {
      expect(
          RelationStatus.fromString('unknown'), equals(RelationStatus.proposed));
      expect(RelationStatus.fromString(''), equals(RelationStatus.proposed));
      expect(
          RelationStatus.fromString('invalid'), equals(RelationStatus.proposed));
    });
  });

  // =========================================================================
  // Relation tests
  // =========================================================================
  group('Relation', () {
    final now = DateTime(2024, 6, 15, 10);

    test('constructor with required fields only', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      expect(relation.relationId, equals('rel-1'));
      expect(relation.fromEntityId, equals('entity-a'));
      expect(relation.toEntityId, equals('entity-b'));
      expect(relation.relationType, equals('owns'));
      expect(relation.status, equals(RelationStatus.proposed));
      expect(relation.validFrom, isNull);
      expect(relation.validTo, isNull);
      expect(relation.evidenceRefs, isEmpty);
      expect(relation.attributes, isEmpty);
      expect(relation.createdAt, equals(now));
      expect(relation.updatedAt, isNull);
    });

    test('constructor with all fields', () {
      final validFrom = DateTime(2024, 1, 1);
      final validTo = DateTime(2025, 1, 1);
      final updated = DateTime(2024, 6, 16);
      final relation = Relation(
        relationId: 'rel-2',
        fromEntityId: 'entity-c',
        toEntityId: 'entity-d',
        relationType: 'works_for',
        status: RelationStatus.confirmed,
        validFrom: validFrom,
        validTo: validTo,
        evidenceRefs: ['ev-1', 'ev-2'],
        attributes: {'role': 'manager'},
        createdAt: now,
        updatedAt: updated,
      );

      expect(relation.relationId, equals('rel-2'));
      expect(relation.fromEntityId, equals('entity-c'));
      expect(relation.toEntityId, equals('entity-d'));
      expect(relation.relationType, equals('works_for'));
      expect(relation.status, equals(RelationStatus.confirmed));
      expect(relation.validFrom, equals(validFrom));
      expect(relation.validTo, equals(validTo));
      expect(relation.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(relation.attributes, equals({'role': 'manager'}));
      expect(relation.createdAt, equals(now));
      expect(relation.updatedAt, equals(updated));
    });

    test('fromJson complete', () {
      final json = {
        'relationId': 'rel-1',
        'fromEntityId': 'entity-a',
        'toEntityId': 'entity-b',
        'relationType': 'supplies',
        'status': 'confirmed',
        'validFrom': '2024-01-01T00:00:00.000',
        'validTo': '2025-12-31T00:00:00.000',
        'evidenceRefs': ['ev-1'],
        'attributes': {'volume': 1000},
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-16T10:00:00.000',
      };

      final relation = Relation.fromJson(json);

      expect(relation.relationId, equals('rel-1'));
      expect(relation.fromEntityId, equals('entity-a'));
      expect(relation.toEntityId, equals('entity-b'));
      expect(relation.relationType, equals('supplies'));
      expect(relation.status, equals(RelationStatus.confirmed));
      expect(relation.validFrom, equals(DateTime(2024, 1, 1)));
      expect(relation.validTo, equals(DateTime(2025, 12, 31)));
      expect(relation.evidenceRefs, equals(['ev-1']));
      expect(relation.attributes, equals({'volume': 1000}));
      expect(relation.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(relation.updatedAt, equals(DateTime(2024, 6, 16, 10)));
    });

    test('fromJson empty/missing fields', () {
      final relation = Relation.fromJson(<String, dynamic>{});

      expect(relation.relationId, equals(''));
      expect(relation.fromEntityId, equals(''));
      expect(relation.toEntityId, equals(''));
      expect(relation.relationType, equals(''));
      expect(relation.status, equals(RelationStatus.proposed));
      expect(relation.validFrom, isNull);
      expect(relation.validTo, isNull);
      expect(relation.evidenceRefs, isEmpty);
      expect(relation.attributes, isEmpty);
      expect(relation.createdAt, isA<DateTime>());
      expect(relation.updatedAt, isNull);
    });

    test('fromJson with null datetime fields', () {
      final relation = Relation.fromJson({
        'validFrom': null,
        'validTo': null,
        'createdAt': null,
        'updatedAt': null,
      });
      expect(relation.validFrom, isNull);
      expect(relation.validTo, isNull);
      expect(relation.createdAt, isA<DateTime>());
      expect(relation.updatedAt, isNull);
    });

    test('toJson populated', () {
      final validFrom = DateTime(2024, 1, 1);
      final validTo = DateTime(2025, 12, 31);
      final updated = DateTime(2024, 6, 16, 10);
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        status: RelationStatus.confirmed,
        validFrom: validFrom,
        validTo: validTo,
        evidenceRefs: ['ev-1'],
        attributes: {'key': 'value'},
        createdAt: now,
        updatedAt: updated,
      );

      final json = relation.toJson();

      expect(json['relationId'], equals('rel-1'));
      expect(json['fromEntityId'], equals('entity-a'));
      expect(json['toEntityId'], equals('entity-b'));
      expect(json['relationType'], equals('owns'));
      expect(json['status'], equals('confirmed'));
      expect(json['validFrom'], equals(validFrom.toIso8601String()));
      expect(json['validTo'], equals(validTo.toIso8601String()));
      expect(json['evidenceRefs'], equals(['ev-1']));
      expect(json['attributes'], equals({'key': 'value'}));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(updated.toIso8601String()));
    });

    test('toJson excludes null and empty fields', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final json = relation.toJson();

      expect(json.containsKey('validFrom'), isFalse);
      expect(json.containsKey('validTo'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('attributes'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
      // Always-present fields
      expect(json.containsKey('relationId'), isTrue);
      expect(json.containsKey('fromEntityId'), isTrue);
      expect(json.containsKey('toEntityId'), isTrue);
      expect(json.containsKey('relationType'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final original = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final copy = original.copyWith(
        relationType: 'works_for',
        status: RelationStatus.confirmed,
      );

      expect(copy.relationId, equals('rel-1'));
      expect(copy.fromEntityId, equals('entity-a'));
      expect(copy.toEntityId, equals('entity-b'));
      expect(copy.relationType, equals('works_for'));
      expect(copy.status, equals(RelationStatus.confirmed));
      expect(copy.createdAt, equals(now));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.relationId, equals(original.relationId));
      expect(copy.fromEntityId, equals(original.fromEntityId));
      expect(copy.toEntityId, equals(original.toEntityId));
      expect(copy.relationType, equals(original.relationType));
      expect(copy.status, equals(original.status));
      expect(copy.validFrom, equals(original.validFrom));
      expect(copy.validTo, equals(original.validTo));
      expect(copy.evidenceRefs, equals(original.evidenceRefs));
      expect(copy.attributes, equals(original.attributes));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.updatedAt, equals(original.updatedAt));
    });

    test('copyWith replaces all fields', () {
      final original = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final newDate = DateTime(2025, 3, 1);
      final copy = original.copyWith(
        relationId: 'rel-new',
        fromEntityId: 'e-new-a',
        toEntityId: 'e-new-b',
        relationType: 'manages',
        status: RelationStatus.confirmed,
        validFrom: newDate,
        validTo: newDate,
        evidenceRefs: ['ev-new'],
        attributes: {'new': true},
        createdAt: newDate,
        updatedAt: newDate,
      );

      expect(copy.relationId, equals('rel-new'));
      expect(copy.fromEntityId, equals('e-new-a'));
      expect(copy.toEntityId, equals('e-new-b'));
      expect(copy.relationType, equals('manages'));
      expect(copy.status, equals(RelationStatus.confirmed));
      expect(copy.validFrom, equals(newDate));
      expect(copy.validTo, equals(newDate));
      expect(copy.evidenceRefs, equals(['ev-new']));
      expect(copy.attributes, equals({'new': true}));
      expect(copy.createdAt, equals(newDate));
      expect(copy.updatedAt, equals(newDate));
    });

    // -----------------------------------------------------------------------
    // Boolean getters
    // -----------------------------------------------------------------------
    group('isCurrentlyValid getter', () {
      test('returns true when no validity bounds', () {
        final relation = Relation(
          relationId: 'rel-1',
          fromEntityId: 'entity-a',
          toEntityId: 'entity-b',
          relationType: 'owns',
          createdAt: now,
        );
        expect(relation.isCurrentlyValid, isTrue);
      });

      test('returns true when within validity bounds', () {
        final relation = Relation(
          relationId: 'rel-1',
          fromEntityId: 'entity-a',
          toEntityId: 'entity-b',
          relationType: 'owns',
          validFrom: DateTime(2020, 1, 1),
          validTo: DateTime(2099, 12, 31),
          createdAt: now,
        );
        expect(relation.isCurrentlyValid, isTrue);
      });

      test('returns false when validFrom is in the future', () {
        final relation = Relation(
          relationId: 'rel-1',
          fromEntityId: 'entity-a',
          toEntityId: 'entity-b',
          relationType: 'owns',
          validFrom: DateTime(2099, 1, 1),
          createdAt: now,
        );
        expect(relation.isCurrentlyValid, isFalse);
      });

      test('returns false when validTo is in the past', () {
        final relation = Relation(
          relationId: 'rel-1',
          fromEntityId: 'entity-a',
          toEntityId: 'entity-b',
          relationType: 'owns',
          validTo: DateTime(2020, 1, 1),
          createdAt: now,
        );
        expect(relation.isCurrentlyValid, isFalse);
      });
    });

    test('isConfirmed returns true when confirmed', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        status: RelationStatus.confirmed,
        createdAt: now,
      );
      expect(relation.isConfirmed, isTrue);
    });

    test('isConfirmed returns false when proposed', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        status: RelationStatus.proposed,
        createdAt: now,
      );
      expect(relation.isConfirmed, isFalse);
    });

    // -----------------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------------
    test('confirm() returns confirmed relation with updatedAt', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final confirmed = relation.confirm();

      expect(confirmed.status, equals(RelationStatus.confirmed));
      expect(confirmed.updatedAt, isA<DateTime>());
      expect(confirmed.relationId, equals('rel-1'));
      expect(confirmed.fromEntityId, equals('entity-a'));
      expect(confirmed.toEntityId, equals('entity-b'));
    });

    test('end() sets validTo and updatedAt', () {
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final ended = relation.end();

      expect(ended.validTo, isA<DateTime>());
      expect(ended.updatedAt, isA<DateTime>());
      expect(ended.relationId, equals('rel-1'));
    });

    test('end() with specific endDate', () {
      final endDate = DateTime(2025, 6, 30);
      final relation = Relation(
        relationId: 'rel-1',
        fromEntityId: 'entity-a',
        toEntityId: 'entity-b',
        relationType: 'owns',
        createdAt: now,
      );

      final ended = relation.end(endDate: endDate);

      expect(ended.validTo, equals(endDate));
      expect(ended.updatedAt, isA<DateTime>());
    });
  });

  // =========================================================================
  // RelationTypes constants tests
  // =========================================================================
  group('RelationTypes', () {
    test('owns constant', () {
      expect(RelationTypes.owns, equals('owns'));
    });

    test('worksFor constant', () {
      expect(RelationTypes.worksFor, equals('works_for'));
    });

    test('supplies constant', () {
      expect(RelationTypes.supplies, equals('supplies'));
    });

    test('locatedAt constant', () {
      expect(RelationTypes.locatedAt, equals('located_at'));
    });

    test('partOf constant', () {
      expect(RelationTypes.partOf, equals('part_of'));
    });

    test('manages constant', () {
      expect(RelationTypes.manages, equals('manages'));
    });

    test('reportsTo constant', () {
      expect(RelationTypes.reportsTo, equals('reports_to'));
    });

    test('createdBy constant', () {
      expect(RelationTypes.createdBy, equals('created_by'));
    });

    test('assignedTo constant', () {
      expect(RelationTypes.assignedTo, equals('assigned_to'));
    });

    test('relatedTo constant', () {
      expect(RelationTypes.relatedTo, equals('related_to'));
    });
  });
}
