import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('Entity', () {
    test('creates entity with required fields', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-1',
        type: 'person',
        canonicalName: 'John Doe',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(entity.entityId, equals('entity-1'));
      expect(entity.type, equals('person'));
      expect(entity.canonicalName, equals('John Doe'));
      expect(entity.status, equals(EntityStatus.active));
      expect(entity.confidence, equals(1.0));
    });

    test('creates entity with all fields', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-2',
        type: 'organization',
        canonicalName: 'Acme Corp',
        aliases: ['Acme', 'Acme Corporation'],
        attributes: {'industry': 'technology'},
        status: EntityStatus.active,
        sourceCandidateIds: ['cand-1', 'cand-2'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
        confidence: 0.95,
        metadata: {'source': 'test'},
      );

      expect(entity.aliases, containsAll(['Acme', 'Acme Corporation']));
      expect(entity.attributes['industry'], equals('technology'));
      expect(entity.sourceCandidateIds.length, equals(2));
      expect(entity.confidence, equals(0.95));
    });

    test('matchesName finds name and aliases', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-3',
        type: 'person',
        canonicalName: 'John Smith',
        aliases: ['Johnny', 'J. Smith'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(entity.matchesName('John'), isTrue);
      expect(entity.matchesName('johnny'), isTrue);
      expect(entity.matchesName('Smith'), isTrue);
      expect(entity.matchesName('Unknown'), isFalse);
    });

    test('serializes and deserializes correctly', () {
      final original = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-4',
        type: 'place',
        canonicalName: 'New York',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = Entity.fromJson(json);

      expect(restored.entityId, equals(original.entityId));
      expect(restored.type, equals(original.type));
      expect(restored.canonicalName, equals(original.canonicalName));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final entity = Entity.fromJson(json);

      expect(entity.entityId, equals(''));
      expect(entity.workspaceId, equals('default'));
      expect(entity.type, equals(''));
      expect(entity.canonicalName, equals(''));
      expect(entity.aliases, isEmpty);
      expect(entity.attributes, isEmpty);
      expect(entity.status, equals(EntityStatus.active));
      expect(entity.sourceCandidateIds, isEmpty);
      expect(entity.confidence, equals(1.0));
      expect(entity.metadata, isEmpty);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'entityId': 'entity-from-json',
        'workspaceId': 'ws-1',
        'type': 'organization',
        'canonicalName': 'Acme Corp',
        'aliases': ['Acme', 'Acme Inc'],
        'attributes': {'industry': 'tech'},
        'status': 'merged',
        'sourceCandidateIds': ['cand-1'],
        'createdAt': '2024-01-15T10:00:00.000',
        'updatedAt': '2024-01-16T10:00:00.000',
        'confidence': 0.85,
        'metadata': {'source': 'import'},
      };

      final entity = Entity.fromJson(json);

      expect(entity.entityId, equals('entity-from-json'));
      expect(entity.workspaceId, equals('ws-1'));
      expect(entity.type, equals('organization'));
      expect(entity.canonicalName, equals('Acme Corp'));
      expect(entity.aliases, equals(['Acme', 'Acme Inc']));
      expect(entity.attributes, equals({'industry': 'tech'}));
      expect(entity.status, equals(EntityStatus.merged));
      expect(entity.sourceCandidateIds, equals(['cand-1']));
      expect(entity.createdAt, equals(DateTime(2024, 1, 15, 10)));
      expect(entity.updatedAt, equals(DateTime(2024, 1, 16, 10)));
      expect(entity.confidence, equals(0.85));
      expect(entity.metadata, equals({'source': 'import'}));
    });

    test('toJson excludes empty lists and maps', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-min',
        type: 'person',
        canonicalName: 'Minimal',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = entity.toJson();

      expect(json.containsKey('aliases'), isFalse);
      expect(json.containsKey('attributes'), isFalse);
      expect(json.containsKey('sourceCandidateIds'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json['entityId'], equals('entity-min'));
      expect(json['workspaceId'], equals('test-workspace'));
      expect(json['type'], equals('person'));
      expect(json['canonicalName'], equals('Minimal'));
      expect(json['status'], equals('active'));
      expect(json['confidence'], equals(1.0));
    });

    test('toJson includes non-empty lists and maps', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-full',
        type: 'person',
        canonicalName: 'Full',
        aliases: ['Alias1'],
        attributes: {'key': 'val'},
        sourceCandidateIds: ['cand-1'],
        metadata: {'m': 1},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = entity.toJson();

      expect(json['aliases'], equals(['Alias1']));
      expect(json['attributes'], equals({'key': 'val'}));
      expect(json['sourceCandidateIds'], equals(['cand-1']));
      expect(json['metadata'], equals({'m': 1}));
    });

    test('copyWith creates modified copy', () {
      final original = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-5',
        type: 'person',
        canonicalName: 'Original Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        canonicalName: 'Modified Name',
        status: EntityStatus.archived,
      );

      expect(original.canonicalName, equals('Original Name'));
      expect(modified.canonicalName, equals('Modified Name'));
      expect(modified.status, equals(EntityStatus.archived));
    });

    test('copyWith all parameters', () {
      final original = Entity(
        workspaceId: 'ws-1',
        entityId: 'entity-orig',
        type: 'person',
        canonicalName: 'Orig',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2024, 6, 1);
      final modified = original.copyWith(
        entityId: 'entity-new',
        workspaceId: 'ws-2',
        type: 'organization',
        canonicalName: 'New Name',
        aliases: ['Alias'],
        attributes: {'a': 1},
        status: EntityStatus.deleted,
        sourceCandidateIds: ['c-1'],
        createdAt: newDate,
        updatedAt: newDate,
        confidence: 0.75,
        metadata: {'x': true},
      );

      expect(modified.entityId, equals('entity-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.type, equals('organization'));
      expect(modified.canonicalName, equals('New Name'));
      expect(modified.aliases, equals(['Alias']));
      expect(modified.attributes, equals({'a': 1}));
      expect(modified.status, equals(EntityStatus.deleted));
      expect(modified.sourceCandidateIds, equals(['c-1']));
      expect(modified.createdAt, equals(newDate));
      expect(modified.updatedAt, equals(newDate));
      expect(modified.confidence, equals(0.75));
      expect(modified.metadata, equals({'x': true}));
    });

    test('toString returns expected format', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-str',
        type: 'person',
        canonicalName: 'Test Person',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final str = entity.toString();

      expect(str, contains('Entity'));
      expect(str, contains('entity-str'));
      expect(str, contains('person'));
      expect(str, contains('Test Person'));
    });

    test('equality based on entityId', () {
      final entity1 = Entity(
        workspaceId: 'test-workspace',
        entityId: 'same-id',
        type: 'person',
        canonicalName: 'Name 1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final entity2 = Entity(
        workspaceId: 'test-workspace',
        entityId: 'same-id',
        type: 'place',
        canonicalName: 'Name 2',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final entity3 = Entity(
        workspaceId: 'test-workspace',
        entityId: 'different-id',
        type: 'person',
        canonicalName: 'Name 1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(entity1, equals(entity2));
      expect(entity1.hashCode, equals(entity2.hashCode));
      expect(entity1 == entity3, isFalse);
    });

    test('matchesName returns false when no alias matches', () {
      final entity = Entity(
        workspaceId: 'test-workspace',
        entityId: 'entity-nomatch',
        type: 'person',
        canonicalName: 'Alice',
        aliases: ['Bob'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(entity.matchesName('Charlie'), isFalse);
    });
  });

  group('EntityStatus', () {
    test('fromString parses correctly', () {
      expect(EntityStatus.fromString('active'), equals(EntityStatus.active));
      expect(EntityStatus.fromString('merged'), equals(EntityStatus.merged));
      expect(EntityStatus.fromString('archived'), equals(EntityStatus.archived));
      expect(EntityStatus.fromString('deleted'), equals(EntityStatus.deleted));
    });

    test('fromString returns active for unknown', () {
      expect(EntityStatus.fromString('unknown'), equals(EntityStatus.active));
    });

    test('all status values accessible by name', () {
      expect(EntityStatus.active.name, equals('active'));
      expect(EntityStatus.merged.name, equals('merged'));
      expect(EntityStatus.archived.name, equals('archived'));
      expect(EntityStatus.deleted.name, equals('deleted'));
    });

    test('fromString maps each value correctly', () {
      for (final status in EntityStatus.values) {
        expect(EntityStatus.fromString(status.name), equals(status));
      }
    });

    test('has all expected values', () {
      expect(EntityStatus.values, hasLength(4));
      expect(EntityStatus.values, contains(EntityStatus.active));
      expect(EntityStatus.values, contains(EntityStatus.merged));
      expect(EntityStatus.values, contains(EntityStatus.archived));
      expect(EntityStatus.values, contains(EntityStatus.deleted));
    });
  });

  // =========================================================================
  // Additional Entity coverage
  // =========================================================================
  group('Entity additional coverage', () {
    test('Entity constructor stores workspaceId', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'my-workspace',
        type: 'person',
        canonicalName: 'Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity.workspaceId, equals('my-workspace'));
    });

    test('Entity fromJson with createdAt/updatedAt null uses DateTime.now()',
        () {
      final before = DateTime.now();
      final entity = Entity.fromJson({
        'entityId': 'e',
        'createdAt': null,
        'updatedAt': null,
      });
      final after = DateTime.now();

      expect(
        entity.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        entity.updatedAt
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('Entity fromJson with createdAt/updatedAt present', () {
      final entity = Entity.fromJson({
        'entityId': 'e',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-06-20T12:00:00.000',
      });
      expect(entity.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(entity.updatedAt, equals(DateTime(2024, 6, 20, 12)));
    });

    test('Entity toJson createdAt and updatedAt as ISO8601', () {
      final t1 = DateTime(2024, 3, 15, 12, 30);
      final t2 = DateTime(2024, 4, 20, 8, 0);
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        createdAt: t1,
        updatedAt: t2,
      );
      final json = entity.toJson();
      expect(json['createdAt'], equals(t1.toIso8601String()));
      expect(json['updatedAt'], equals(t2.toIso8601String()));
    });

    test('Entity toJson with all conditional fields present', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        aliases: const ['Alias1'],
        attributes: const {'key': 'val'},
        sourceCandidateIds: const ['cand-1'],
        metadata: const {'m': 1},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final json = entity.toJson();

      expect(json.containsKey('aliases'), isTrue);
      expect(json.containsKey('attributes'), isTrue);
      expect(json.containsKey('sourceCandidateIds'), isTrue);
      expect(json.containsKey('metadata'), isTrue);
    });

    test('Entity toJson with all conditional fields absent', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final json = entity.toJson();

      expect(json.containsKey('aliases'), isFalse);
      expect(json.containsKey('attributes'), isFalse);
      expect(json.containsKey('sourceCandidateIds'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('Entity toJson confidence field always present', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        confidence: 0.75,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final json = entity.toJson();
      expect(json['confidence'], equals(0.75));
    });

    test('Entity toJson status as name string', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        status: EntityStatus.archived,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final json = entity.toJson();
      expect(json['status'], equals('archived'));
    });

    test('Entity copyWith each field individually', () {
      final base = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final newDate = DateTime(2025, 1, 1);

      expect(base.copyWith(entityId: 'x').entityId, equals('x'));
      expect(base.copyWith(workspaceId: 'x').workspaceId, equals('x'));
      expect(base.copyWith(type: 'org').type, equals('org'));
      expect(
        base.copyWith(canonicalName: 'New').canonicalName,
        equals('New'),
      );
      expect(
        base.copyWith(aliases: const ['A']).aliases,
        equals(['A']),
      );
      expect(
        base.copyWith(attributes: const {'k': 'v'}).attributes,
        equals({'k': 'v'}),
      );
      expect(
        base.copyWith(status: EntityStatus.deleted).status,
        equals(EntityStatus.deleted),
      );
      expect(
        base.copyWith(sourceCandidateIds: const ['c']).sourceCandidateIds,
        equals(['c']),
      );
      expect(base.copyWith(createdAt: newDate).createdAt, equals(newDate));
      expect(base.copyWith(updatedAt: newDate).updatedAt, equals(newDate));
      expect(base.copyWith(confidence: 0.5).confidence, equals(0.5));
      expect(
        base.copyWith(metadata: const {'m': 1}).metadata,
        equals({'m': 1}),
      );
    });

    test('Entity copyWith no args preserves all fields', () {
      final base = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        aliases: const ['A'],
        attributes: const {'k': 'v'},
        status: EntityStatus.merged,
        sourceCandidateIds: const ['c'],
        confidence: 0.8,
        metadata: const {'m': 1},
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final copy = base.copyWith();

      expect(copy.entityId, equals(base.entityId));
      expect(copy.workspaceId, equals(base.workspaceId));
      expect(copy.type, equals(base.type));
      expect(copy.canonicalName, equals(base.canonicalName));
      expect(copy.aliases, equals(base.aliases));
      expect(copy.attributes, equals(base.attributes));
      expect(copy.status, equals(base.status));
      expect(copy.sourceCandidateIds, equals(base.sourceCandidateIds));
      expect(copy.createdAt, equals(base.createdAt));
      expect(copy.updatedAt, equals(base.updatedAt));
      expect(copy.confidence, equals(base.confidence));
      expect(copy.metadata, equals(base.metadata));
    });

    test('Entity matchesName case-insensitive on canonical name', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Alice Wonderland',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity.matchesName('alice'), isTrue);
      expect(entity.matchesName('WONDERLAND'), isTrue);
      expect(entity.matchesName('xyz'), isFalse);
    });

    test('Entity matchesName with alias match', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Alice',
        aliases: const ['Alicia', 'Al'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity.matchesName('alicia'), isTrue);
      expect(entity.matchesName('AL'), isTrue);
    });

    test('Entity matchesName returns false for empty aliases', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Alice',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity.matchesName('xyz'), isFalse);
    });

    test('Entity equality with identical reference', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity == entity, isTrue);
    });

    test('Entity equality with non-Entity object', () {
      final entity = Entity(
        entityId: 'e',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(entity == Object(), isFalse);
    });

    test('Entity hashCode based on entityId', () {
      final e1 = Entity(
        entityId: 'same',
        workspaceId: 'ws1',
        type: 'person',
        canonicalName: 'N1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final e2 = Entity(
        entityId: 'same',
        workspaceId: 'ws2',
        type: 'org',
        canonicalName: 'N2',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('Entity toString exact format', () {
      final entity = Entity(
        entityId: 'e-id',
        workspaceId: 'ws',
        type: 'person',
        canonicalName: 'My Name',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(
        entity.toString(),
        equals('Entity(e-id, type: person, name: My Name)'),
      );
    });

    test('Entity fromJson with all status values', () {
      for (final status in EntityStatus.values) {
        final entity = Entity.fromJson({
          'entityId': 'e',
          'status': status.name,
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        });
        expect(entity.status, equals(status));
      }
    });

    test('Entity fromJson with null optional fields', () {
      final entity = Entity.fromJson({
        'entityId': null,
        'workspaceId': null,
        'type': null,
        'canonicalName': null,
        'aliases': null,
        'attributes': null,
        'status': null,
        'sourceCandidateIds': null,
        'confidence': null,
        'metadata': null,
        'createdAt': null,
        'updatedAt': null,
      });

      expect(entity.entityId, equals(''));
      expect(entity.workspaceId, equals('default'));
      expect(entity.type, equals(''));
      expect(entity.canonicalName, equals(''));
      expect(entity.aliases, isEmpty);
      expect(entity.attributes, isEmpty);
      expect(entity.status, equals(EntityStatus.active));
      expect(entity.sourceCandidateIds, isEmpty);
      expect(entity.confidence, equals(1.0));
      expect(entity.metadata, isEmpty);
    });
  });
}
