import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('FactNode', () {
    test('creates node with required fields', () {
      final node = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'statement': 'The sky is blue'},
      );

      expect(node.id, equals('node-1'));
      expect(node.type, equals(NodeType.fact));
      expect(node.content['statement'], equals('The sky is blue'));
      expect(node.metadata, isEmpty);
      expect(node.tags, isEmpty);
    });

    test('creates node with all fields', () {
      final node = FactNode(
        id: 'node-2',
        type: NodeType.entity,
        content: {'name': 'John', 'age': 30},
        confidence: 0.95,
        source: FactSource(type: SourceType.user, name: 'Admin'),
        validFrom: DateTime(2024, 1, 1),
        validUntil: DateTime(2025, 1, 1),
        metadata: {'version': 1},
        tags: ['person', 'important'],
      );

      expect(node.confidence, equals(0.95));
      expect(node.source!.type, equals(SourceType.user));
      expect(node.metadata['version'], equals(1));
      expect(node.tags, containsAll(['person', 'important']));
    });

    test('isValid checks date range', () {
      final futureNode = FactNode(
        id: 'node-3',
        type: NodeType.fact,
        content: {},
        validFrom: DateTime.now().add(const Duration(days: 30)),
      );

      final pastNode = FactNode(
        id: 'node-4',
        type: NodeType.fact,
        content: {},
        validUntil: DateTime.now().subtract(const Duration(days: 30)),
      );

      final currentNode = FactNode(
        id: 'node-5',
        type: NodeType.fact,
        content: {},
        validFrom: DateTime.now().subtract(const Duration(days: 30)),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      );

      expect(futureNode.isValid, isFalse);
      expect(pastNode.isValid, isFalse);
      expect(currentNode.isValid, isTrue);
    });

    test('getProperty retrieves content', () {
      final node = FactNode(
        id: 'node-6',
        type: NodeType.fact,
        content: {'key': 'value', 'count': 42},
      );

      expect(node.getProperty('key'), equals('value'));
      expect(node.getProperty('count'), equals(42));
      expect(node.getProperty('missing'), isNull);
    });

    test('hasProperty checks existence', () {
      final node = FactNode(
        id: 'node-7',
        type: NodeType.fact,
        content: {'exists': true},
      );

      expect(node.hasProperty('exists'), isTrue);
      expect(node.hasProperty('missing'), isFalse);
    });

    test('hasTag checks tags', () {
      final node = FactNode(
        id: 'node-8',
        type: NodeType.fact,
        content: {},
        tags: ['tag1', 'tag2'],
      );

      expect(node.hasTag('tag1'), isTrue);
      expect(node.hasTag('missing'), isFalse);
    });

    test('serializes and deserializes correctly', () {
      final original = FactNode(
        id: 'node-9',
        type: NodeType.concept,
        content: {'definition': 'A test concept'},
        confidence: 0.8,
        tags: ['test'],
      );

      final json = original.toJson();
      final restored = FactNode.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.content['definition'], equals(original.content['definition']));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.tags, equals(original.tags));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final node = FactNode.fromJson(json);

      expect(node.id, equals(''));
      expect(node.type, equals(NodeType.fact));
      expect(node.content, isEmpty);
      expect(node.claim, isNull);
      expect(node.confidence, isNull);
      expect(node.source, isNull);
      expect(node.validFrom, isNull);
      expect(node.validUntil, isNull);
      expect(node.metadata, isEmpty);
      expect(node.tags, isEmpty);
    });

    test('fromJson parses all fields including source', () {
      final json = {
        'id': 'node-full',
        'type': 'entity',
        'content': {'name': 'Test'},
        'confidence': 0.95,
        'source': {
          'type': 'document',
          'uri': 'file://doc.pdf',
          'name': 'Research',
          'timestamp': '2024-06-15T10:00:00.000',
          'reliability': 0.9,
        },
        'validFrom': '2024-01-01T00:00:00.000',
        'validUntil': '2025-01-01T00:00:00.000',
        'metadata': {'version': 2},
        'tags': ['important'],
      };

      final node = FactNode.fromJson(json);

      expect(node.id, equals('node-full'));
      expect(node.type, equals(NodeType.entity));
      expect(node.confidence, equals(0.95));
      expect(node.source, isNotNull);
      expect(node.source!.type, equals(SourceType.document));
      expect(node.source!.uri, equals('file://doc.pdf'));
      expect(node.source!.name, equals('Research'));
      expect(node.source!.timestamp, equals(DateTime(2024, 6, 15, 10)));
      expect(node.source!.reliability, equals(0.9));
      expect(node.validFrom, equals(DateTime(2024, 1, 1)));
      expect(node.validUntil, equals(DateTime(2025, 1, 1)));
      expect(node.metadata, equals({'version': 2}));
      expect(node.tags, equals(['important']));
    });

    test('fromJson parses claim field when present', () {
      final json = {
        'id': 'node-with-claim',
        'type': 'fact',
        'content': {'statement': 'A claim-based fact'},
        'claim': {
          'id': 'claim-1',
          'workspaceId': 'ws-1',
          'text': 'The sky is blue',
          'type': 'fact',
          'evidenceRefs': ['ev-1'],
          'confidence': 0.95,
          'status': 'supported',
        },
      };

      final node = FactNode.fromJson(json);

      expect(node.id, equals('node-with-claim'));
      expect(node.claim, isNotNull);
      expect(node.claim!.id, equals('claim-1'));
      expect(node.claim!.text, equals('The sky is blue'));
    });

    test('toJson excludes null and empty fields', () {
      final node = FactNode(
        id: 'node-min',
        type: NodeType.fact,
        content: {'x': 1},
      );

      final json = node.toJson();

      expect(json.containsKey('claim'), isFalse);
      expect(json.containsKey('confidence'), isFalse);
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('validFrom'), isFalse);
      expect(json.containsKey('validUntil'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.containsKey('tags'), isFalse);
    });

    test('toJson includes non-null and non-empty fields', () {
      final node = FactNode(
        id: 'node-full-json',
        type: NodeType.entity,
        content: {'name': 'Test'},
        confidence: 0.9,
        source: FactSource(type: SourceType.user, name: 'Admin'),
        validFrom: DateTime(2024, 1, 1),
        validUntil: DateTime(2025, 1, 1),
        metadata: {'v': 1},
        tags: ['tag1'],
      );

      final json = node.toJson();

      expect(json['confidence'], equals(0.9));
      expect(json['source'], isA<Map>());
      expect(json['validFrom'], equals(DateTime(2024, 1, 1).toIso8601String()));
      expect(json['validUntil'], equals(DateTime(2025, 1, 1).toIso8601String()));
      expect(json['metadata'], equals({'v': 1}));
      expect(json['tags'], equals(['tag1']));
    });

    test('toJson includes claim when present', () {
      final claim = bundle.Claim(
        id: 'claim-tj',
        workspaceId: 'ws-1',
        text: 'Test claim',
        type: bundle.ClaimType.fact,
        evidenceRefs: const ['ev-1'],
        confidence: 0.9,
      );
      final node = FactNode(
        id: 'node-with-claim-json',
        type: NodeType.fact,
        content: {'statement': 'Has a claim'},
        claim: claim,
      );

      final json = node.toJson();

      expect(json.containsKey('claim'), isTrue);
      expect((json['claim'] as Map)['id'], equals('claim-tj'));
    });

    test('copyWith creates modified copy', () {
      final original = FactNode(
        id: 'node-10',
        type: NodeType.fact,
        content: {'original': true},
      );

      final modified = original.copyWith(
        content: {'modified': true},
        confidence: 0.9,
      );

      expect(original.content['original'], isTrue);
      expect(modified.content['modified'], isTrue);
      expect(modified.confidence, equals(0.9));
    });

    test('copyWith all parameters', () {
      final original = FactNode(
        id: 'node-orig',
        type: NodeType.fact,
        content: {'a': 1},
      );

      final newDate = DateTime(2024, 6, 1);
      final claim = bundle.Claim(
        id: 'claim-cw',
        workspaceId: 'ws-1',
        text: 'CopyWith claim',
        type: bundle.ClaimType.fact,
        evidenceRefs: const ['ev-1'],
        confidence: 0.8,
      );
      final modified = original.copyWith(
        id: 'node-new',
        type: NodeType.event,
        content: {'b': 2},
        claim: claim,
        confidence: 0.99,
        source: FactSource(type: SourceType.api, uri: 'https://api.example.com'),
        validFrom: newDate,
        validUntil: DateTime(2025, 1, 1),
        metadata: {'new': true},
        tags: ['updated'],
      );

      expect(modified.id, equals('node-new'));
      expect(modified.type, equals(NodeType.event));
      expect(modified.content, equals({'b': 2}));
      expect(modified.claim, isNotNull);
      expect(modified.claim!.id, equals('claim-cw'));
      expect(modified.confidence, equals(0.99));
      expect(modified.source, isNotNull);
      expect(modified.source!.type, equals(SourceType.api));
      expect(modified.validFrom, equals(newDate));
      expect(modified.validUntil, equals(DateTime(2025, 1, 1)));
      expect(modified.metadata, equals({'new': true}));
      expect(modified.tags, equals(['updated']));
    });

    test('toString returns expected format', () {
      final node = FactNode(
        id: 'node-str',
        type: NodeType.concept,
        content: {},
      );

      final str = node.toString();

      expect(str, contains('FactNode'));
      expect(str, contains('node-str'));
      expect(str, contains('concept'));
    });

    test('isValid returns true when no date constraints', () {
      final node = FactNode(
        id: 'node-no-dates',
        type: NodeType.fact,
        content: {},
      );

      expect(node.isValid, isTrue);
    });

    test('equality based on id', () {
      final node1 = FactNode(
        id: 'same-id',
        type: NodeType.fact,
        content: {'a': 1},
      );
      final node2 = FactNode(
        id: 'same-id',
        type: NodeType.entity,
        content: {'b': 2},
      );
      final node3 = FactNode(
        id: 'diff-id',
        type: NodeType.fact,
        content: {'a': 1},
      );

      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));
      expect(node1 == node3, isFalse);
    });
  });

  group('NodeType', () {
    test('fromString parses correctly', () {
      expect(NodeType.fromString('fact'), equals(NodeType.fact));
      expect(NodeType.fromString('entity'), equals(NodeType.entity));
      expect(NodeType.fromString('concept'), equals(NodeType.concept));
      expect(NodeType.fromString('event'), equals(NodeType.event));
      expect(NodeType.fromString('relationship'), equals(NodeType.relationship));
      expect(NodeType.fromString('rule'), equals(NodeType.rule));
      expect(NodeType.fromString('query'), equals(NodeType.query));
    });

    test('fromString returns unknown for invalid', () {
      expect(NodeType.fromString('invalid'), equals(NodeType.unknown));
    });
  });

  group('FactSource', () {
    test('creates source with required fields', () {
      final source = FactSource(type: SourceType.user);

      expect(source.type, equals(SourceType.user));
      expect(source.uri, isNull);
      expect(source.name, isNull);
    });

    test('creates source with all fields', () {
      final source = FactSource(
        type: SourceType.document,
        uri: 'file://doc.pdf',
        name: 'Research Paper',
        timestamp: DateTime(2024, 1, 1),
        reliability: 0.9,
      );

      expect(source.uri, equals('file://doc.pdf'));
      expect(source.name, equals('Research Paper'));
      expect(source.reliability, equals(0.9));
    });

    test('serializes and deserializes correctly', () {
      final original = FactSource(
        type: SourceType.api,
        uri: 'https://api.example.com',
        reliability: 0.85,
      );

      final json = original.toJson();
      final restored = FactSource.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.uri, equals(original.uri));
      expect(restored.reliability, equals(original.reliability));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final source = FactSource.fromJson(json);

      expect(source.type, equals(SourceType.unknown));
      expect(source.uri, isNull);
      expect(source.name, isNull);
      expect(source.timestamp, isNull);
      expect(source.reliability, isNull);
    });

    test('fromJson parses timestamp', () {
      final json = {
        'type': 'user',
        'timestamp': '2024-06-15T10:00:00.000',
      };

      final source = FactSource.fromJson(json);

      expect(source.timestamp, equals(DateTime(2024, 6, 15, 10)));
    });

    test('toJson excludes null fields', () {
      final source = FactSource(type: SourceType.user);

      final json = source.toJson();

      expect(json.containsKey('uri'), isFalse);
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('reliability'), isFalse);
    });

    test('toJson includes non-null fields', () {
      final source = FactSource(
        type: SourceType.document,
        uri: 'file://doc.pdf',
        name: 'Doc',
        timestamp: DateTime(2024, 6, 15),
        reliability: 0.9,
      );

      final json = source.toJson();

      expect(json['uri'], equals('file://doc.pdf'));
      expect(json['name'], equals('Doc'));
      expect(json['timestamp'], equals(DateTime(2024, 6, 15).toIso8601String()));
      expect(json['reliability'], equals(0.9));
    });
  });

  group('SourceType', () {
    test('fromString parses correctly', () {
      expect(SourceType.fromString('user'), equals(SourceType.user));
      expect(SourceType.fromString('document'), equals(SourceType.document));
      expect(SourceType.fromString('api'), equals(SourceType.api));
      expect(SourceType.fromString('database'), equals(SourceType.database));
      expect(SourceType.fromString('inference'), equals(SourceType.inference));
    });

    test('fromString returns unknown for invalid', () {
      expect(SourceType.fromString('invalid'), equals(SourceType.unknown));
    });
  });

  group('FactNode copyWith - content and confidence', () {
    test('copyWith overrides content', () {
      final node = FactNode(
        id: 'n1',
        type: NodeType.fact,
        content: {'a': 1},
      );

      final updated = node.copyWith(content: {'b': 2});
      expect(updated.content, equals({'b': 2}));
      expect(node.content, equals({'a': 1}));
    });

    test('copyWith overrides confidence', () {
      final node = FactNode(
        id: 'n1',
        type: NodeType.fact,
        content: {'a': 1},
        confidence: 0.5,
      );

      final updated = node.copyWith(confidence: 0.99);
      expect(updated.confidence, equals(0.99));
      expect(node.confidence, equals(0.5));
    });
  });
}
