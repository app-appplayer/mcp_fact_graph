import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('FactEdge', () {
    test('creates edge with required fields', () {
      final edge = FactEdge(
        id: 'edge-1',
        type: EdgeType.relatesTo,
        sourceId: 'node-1',
        targetId: 'node-2',
      );

      expect(edge.id, equals('edge-1'));
      expect(edge.type, equals(EdgeType.relatesTo));
      expect(edge.sourceId, equals('node-1'));
      expect(edge.targetId, equals('node-2'));
      expect(edge.bidirectional, isFalse);
      expect(edge.properties, isEmpty);
      expect(edge.metadata, isEmpty);
    });

    test('creates edge with all fields', () {
      final edge = FactEdge(
        id: 'edge-2',
        type: EdgeType.producedBy,
        sourceId: 'cause-node',
        targetId: 'effect-node',
        label: 'Produced By',
        weight: 0.8,
        confidence: 0.95,
        bidirectional: false,
        properties: {'reason': 'test'},
        metadata: {'version': 1},
      );

      expect(edge.label, equals('Produced By'));
      expect(edge.weight, equals(0.8));
      expect(edge.confidence, equals(0.95));
      expect(edge.properties['reason'], equals('test'));
      expect(edge.metadata['version'], equals(1));
    });

    test('getProperty retrieves property value', () {
      final edge = FactEdge(
        id: 'edge-3',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
        properties: {'key': 'value', 'count': 42},
      );

      expect(edge.getProperty('key'), equals('value'));
      expect(edge.getProperty('count'), equals(42));
      expect(edge.getProperty('missing'), isNull);
    });

    test('hasProperty checks existence', () {
      final edge = FactEdge(
        id: 'edge-4',
        type: EdgeType.extractedFrom,
        sourceId: 'a',
        targetId: 'b',
        properties: {'exists': true},
      );

      expect(edge.hasProperty('exists'), isTrue);
      expect(edge.hasProperty('missing'), isFalse);
    });

    test('connectsTo checks node connection', () {
      final edge = FactEdge(
        id: 'edge-5',
        type: EdgeType.partOf,
        sourceId: 'child',
        targetId: 'parent',
      );

      expect(edge.connectsTo('child'), isTrue);
      expect(edge.connectsTo('parent'), isTrue);
      expect(edge.connectsTo('other'), isFalse);
    });

    test('getOtherNode returns connected node', () {
      final edge = FactEdge(
        id: 'edge-6',
        type: EdgeType.dependsOn,
        sourceId: 'dependent',
        targetId: 'dependency',
      );

      expect(edge.getOtherNode('dependent'), equals('dependency'));
      expect(edge.getOtherNode('dependency'), equals('dependent'));
      expect(edge.getOtherNode('unrelated'), isNull);
    });

    test('serializes and deserializes correctly', () {
      final original = FactEdge(
        id: 'edge-7',
        type: EdgeType.derivedFrom,
        sourceId: 'premise',
        targetId: 'conclusion',
        confidence: 0.85,
      );

      final json = original.toJson();
      final restored = FactEdge.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.sourceId, equals(original.sourceId));
      expect(restored.targetId, equals(original.targetId));
      expect(restored.confidence, equals(original.confidence));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final edge = FactEdge.fromJson(json);

      expect(edge.id, equals(''));
      expect(edge.type, equals(EdgeType.relatesTo));
      expect(edge.sourceId, equals(''));
      expect(edge.targetId, equals(''));
      expect(edge.label, isNull);
      expect(edge.weight, isNull);
      expect(edge.confidence, isNull);
      expect(edge.bidirectional, isFalse);
      expect(edge.properties, isEmpty);
      expect(edge.metadata, isEmpty);
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'edge-full',
        'type': 'supports',
        'sourceId': 'src',
        'targetId': 'tgt',
        'label': 'Supports',
        'weight': 0.8,
        'confidence': 0.95,
        'bidirectional': true,
        'properties': {'key': 'val'},
        'metadata': {'v': 1},
      };

      final edge = FactEdge.fromJson(json);

      expect(edge.id, equals('edge-full'));
      expect(edge.type, equals(EdgeType.supports));
      expect(edge.label, equals('Supports'));
      expect(edge.weight, equals(0.8));
      expect(edge.confidence, equals(0.95));
      expect(edge.bidirectional, isTrue);
      expect(edge.properties, equals({'key': 'val'}));
      expect(edge.metadata, equals({'v': 1}));
    });

    test('toJson excludes null and empty fields', () {
      final edge = FactEdge(
        id: 'edge-min',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      );

      final json = edge.toJson();

      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('weight'), isFalse);
      expect(json.containsKey('confidence'), isFalse);
      expect(json.containsKey('bidirectional'), isFalse);
      expect(json.containsKey('properties'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes bidirectional when true', () {
      final edge = FactEdge(
        id: 'edge-bidi',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
        bidirectional: true,
      );

      final json = edge.toJson();

      expect(json['bidirectional'], isTrue);
    });

    test('toJson includes non-null and non-empty fields', () {
      final edge = FactEdge(
        id: 'edge-full-json',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
        label: 'Label',
        weight: 0.7,
        confidence: 0.9,
        properties: {'k': 'v'},
        metadata: {'m': 1},
      );

      final json = edge.toJson();

      expect(json['label'], equals('Label'));
      expect(json['weight'], equals(0.7));
      expect(json['confidence'], equals(0.9));
      expect(json['properties'], equals({'k': 'v'}));
      expect(json['metadata'], equals({'m': 1}));
    });

    test('copyWith creates modified copy', () {
      final original = FactEdge(
        id: 'edge-8',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      );

      final modified = original.copyWith(
        type: EdgeType.contradicts,
        weight: 0.5,
      );

      expect(original.type, equals(EdgeType.relatesTo));
      expect(modified.type, equals(EdgeType.contradicts));
      expect(modified.weight, equals(0.5));
      expect(modified.sourceId, equals(original.sourceId));
    });

    test('copyWith all parameters', () {
      final original = FactEdge(
        id: 'edge-orig',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      );

      final modified = original.copyWith(
        id: 'edge-new',
        type: EdgeType.supersedes,
        sourceId: 'c',
        targetId: 'd',
        label: 'New label',
        weight: 0.8,
        confidence: 0.95,
        bidirectional: true,
        properties: {'new': true},
        metadata: {'v': 2},
      );

      expect(modified.id, equals('edge-new'));
      expect(modified.type, equals(EdgeType.supersedes));
      expect(modified.sourceId, equals('c'));
      expect(modified.targetId, equals('d'));
      expect(modified.label, equals('New label'));
      expect(modified.weight, equals(0.8));
      expect(modified.confidence, equals(0.95));
      expect(modified.bidirectional, isTrue);
      expect(modified.properties, equals({'new': true}));
      expect(modified.metadata, equals({'v': 2}));
    });

    test('copyWith preserves type and weight when not specified', () {
      final original = FactEdge(
        id: 'edge-preserve',
        type: EdgeType.appliedTo,
        sourceId: 'a',
        targetId: 'b',
        weight: 0.75,
      );

      // Only change label, preserving type and weight
      final copy = original.copyWith(label: 'New label');

      expect(copy.type, equals(EdgeType.appliedTo));
      expect(copy.weight, equals(0.75));
      expect(copy.label, equals('New label'));
      expect(copy.id, equals('edge-preserve'));
    });

    test('toString returns expected format', () {
      final edge = FactEdge(
        id: 'edge-str',
        type: EdgeType.supports,
        sourceId: 'src',
        targetId: 'tgt',
      );

      final str = edge.toString();

      expect(str, contains('FactEdge'));
      expect(str, contains('edge-str'));
      expect(str, contains('src'));
      expect(str, contains('tgt'));
      expect(str, contains('supports'));
    });

    test('equality based on id', () {
      final edge1 = FactEdge(
        id: 'same-id',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      );
      final edge2 = FactEdge(
        id: 'same-id',
        type: EdgeType.producedBy,
        sourceId: 'c',
        targetId: 'd',
      );
      final edge3 = FactEdge(
        id: 'diff-id',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      );

      expect(edge1, equals(edge2));
      expect(edge1.hashCode, equals(edge2.hashCode));
      expect(edge1 == edge3, isFalse);
    });
  });

  group('EdgeType', () {
    test('fromString parses correctly', () {
      expect(EdgeType.fromString('supports'), equals(EdgeType.supports));
      expect(EdgeType.fromString('extractedFrom'), equals(EdgeType.extractedFrom));
      expect(EdgeType.fromString('derivedFrom'), equals(EdgeType.derivedFrom));
      expect(EdgeType.fromString('dependsOn'), equals(EdgeType.dependsOn));
      expect(EdgeType.fromString('supersedes'), equals(EdgeType.supersedes));
      expect(EdgeType.fromString('contradicts'), equals(EdgeType.contradicts));
      expect(EdgeType.fromString('relatesTo'), equals(EdgeType.relatesTo));
      expect(EdgeType.fromString('partOf'), equals(EdgeType.partOf));
      expect(EdgeType.fromString('ownedBy'), equals(EdgeType.ownedBy));
      expect(EdgeType.fromString('appliedTo'), equals(EdgeType.appliedTo));
      expect(EdgeType.fromString('producedBy'), equals(EdgeType.producedBy));
      expect(EdgeType.fromString('observedFrom'), equals(EdgeType.observedFrom));
      expect(EdgeType.fromString('promotedTo'), equals(EdgeType.promotedTo));
    });

    test('fromString returns unknown for invalid', () {
      expect(EdgeType.fromString('invalid'), equals(EdgeType.unknown));
    });

    test('skill and pattern edge types can be used in edges', () {
      // Exercise appliedTo, producedBy, observedFrom, promotedTo enum values
      final appliedEdge = FactEdge(
        id: 'e-applied',
        type: EdgeType.appliedTo,
        sourceId: 'skill-1',
        targetId: 'target-1',
      );
      expect(appliedEdge.type, equals(EdgeType.appliedTo));
      expect(appliedEdge.type.name, equals('appliedTo'));

      final producedEdge = FactEdge(
        id: 'e-produced',
        type: EdgeType.producedBy,
        sourceId: 'output-1',
        targetId: 'eval-1',
      );
      expect(producedEdge.type, equals(EdgeType.producedBy));
      expect(producedEdge.type.name, equals('producedBy'));

      final observedEdge = FactEdge(
        id: 'e-observed',
        type: EdgeType.observedFrom,
        sourceId: 'pattern-1',
        targetId: 'claim-1',
      );
      expect(observedEdge.type, equals(EdgeType.observedFrom));
      expect(observedEdge.type.name, equals('observedFrom'));

      final promotedEdge = FactEdge(
        id: 'e-promoted',
        type: EdgeType.promotedTo,
        sourceId: 'pattern-1',
        targetId: 'skill-1',
      );
      expect(promotedEdge.type, equals(EdgeType.promotedTo));
      expect(promotedEdge.type.name, equals('promotedTo'));
    });

    test('isHierarchical returns correct value', () {
      expect(EdgeType.partOf.isHierarchical, isTrue);
      expect(EdgeType.ownedBy.isHierarchical, isTrue);
      expect(EdgeType.relatesTo.isHierarchical, isFalse);
      expect(EdgeType.supports.isHierarchical, isFalse);
      expect(EdgeType.producedBy.isHierarchical, isFalse);
    });

    test('isSymmetric returns correct value', () {
      expect(EdgeType.relatesTo.isSymmetric, isTrue);
      expect(EdgeType.contradicts.isSymmetric, isTrue);
      expect(EdgeType.supports.isSymmetric, isFalse);
      expect(EdgeType.partOf.isSymmetric, isFalse);
      expect(EdgeType.producedBy.isSymmetric, isFalse);
    });
  });
}
