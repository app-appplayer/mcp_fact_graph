import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('FactGraph', () {
    late FactGraph graph;

    setUp(() {
      graph = FactGraph(name: 'test-graph');
    });

    test('constructor creates graph with defaults', () {
      final g = FactGraph();

      expect(g.id, isNotEmpty);
      expect(g.name, equals('unnamed'));
      expect(g.metadata, isEmpty);
      expect(g.nodeCount, equals(0));
      expect(g.edgeCount, equals(0));
    });

    test('constructor creates graph with custom values', () {
      final g = FactGraph(
        id: 'custom-id',
        name: 'custom-graph',
        metadata: {'version': 1},
      );

      expect(g.id, equals('custom-id'));
      expect(g.name, equals('custom-graph'));
      expect(g.metadata, equals({'version': 1}));
    });

    // Node operations

    test('addNode adds a node to the graph', () {
      final node = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'text': 'Test'},
      );

      graph.addNode(node);

      expect(graph.nodeCount, equals(1));
      expect(graph.hasNode('node-1'), isTrue);
      expect(graph.getNode('node-1'), equals(node));
    });

    test('getNode returns null for non-existent node', () {
      expect(graph.getNode('non-existent'), isNull);
    });

    test('hasNode returns false for non-existent node', () {
      expect(graph.hasNode('non-existent'), isFalse);
    });

    test('removeNode removes node and its edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));

      expect(graph.edgeCount, equals(1));

      final removed = graph.removeNode('a');

      expect(removed, isNotNull);
      expect(removed!.id, equals('a'));
      expect(graph.hasNode('a'), isFalse);
      expect(graph.edgeCount, equals(0));
    });

    test('removeNode returns null for non-existent node', () {
      final removed = graph.removeNode('non-existent');
      expect(removed, isNull);
    });

    test('nodes returns all nodes', () {
      graph.addNode(FactNode(id: 'n1', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'n2', type: NodeType.entity, content: {}));

      final allNodes = graph.nodes.toList();
      expect(allNodes, hasLength(2));
    });

    // Edge operations

    test('addEdge adds an edge between existing nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));

      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));

      expect(graph.edgeCount, equals(1));
      expect(graph.hasEdge('e-1'), isTrue);
      expect(graph.getEdge('e-1'), isNotNull);
    });

    test('addEdge throws for non-existent source node', () {
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));

      expect(
        () => graph.addEdge(FactEdge(
          id: 'e-1',
          type: EdgeType.supports,
          sourceId: 'missing',
          targetId: 'b',
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addEdge throws for non-existent target node', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));

      expect(
        () => graph.addEdge(FactEdge(
          id: 'e-1',
          type: EdgeType.supports,
          sourceId: 'a',
          targetId: 'missing',
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addEdge handles bidirectional edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));

      graph.addEdge(FactEdge(
        id: 'e-bidi',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
        bidirectional: true,
      ));

      // Bidirectional edge should appear in outgoing from both ends
      final outFromA = graph.getOutgoingEdges('a');
      final outFromB = graph.getOutgoingEdges('b');

      expect(outFromA, hasLength(1));
      expect(outFromB, hasLength(1));
    });

    test('getEdge returns null for non-existent edge', () {
      expect(graph.getEdge('non-existent'), isNull);
    });

    test('hasEdge returns false for non-existent edge', () {
      expect(graph.hasEdge('non-existent'), isFalse);
    });

    test('removeEdge removes an edge', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));

      final removed = graph.removeEdge('e-1');

      expect(removed, isNotNull);
      expect(removed!.id, equals('e-1'));
      expect(graph.hasEdge('e-1'), isFalse);
      expect(graph.edgeCount, equals(0));
    });

    test('removeEdge handles bidirectional edge', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-bidi',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
        bidirectional: true,
      ));

      graph.removeEdge('e-bidi');

      expect(graph.edgeCount, equals(0));
      expect(graph.getOutgoingEdges('a'), isEmpty);
      expect(graph.getOutgoingEdges('b'), isEmpty);
    });

    test('removeEdge returns null for non-existent edge', () {
      final removed = graph.removeEdge('non-existent');
      expect(removed, isNull);
    });

    test('edges returns all edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));

      final allEdges = graph.edges.toList();
      expect(allEdges, hasLength(1));
    });

    // Query operations

    test('getOutgoingEdges returns outgoing edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'c',
      ));

      final outgoing = graph.getOutgoingEdges('a');
      expect(outgoing, hasLength(2));
    });

    test('getOutgoingEdges returns empty for non-existent node', () {
      final edges = graph.getOutgoingEdges('non-existent');
      expect(edges, isEmpty);
    });

    test('getIncomingEdges returns incoming edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));

      final incoming = graph.getIncomingEdges('b');
      expect(incoming, hasLength(1));
      expect(incoming.first.sourceId, equals('a'));
    });

    test('getIncomingEdges returns empty for non-existent node', () {
      final edges = graph.getIncomingEdges('non-existent');
      expect(edges, isEmpty);
    });

    test('getConnectedEdges returns all connected edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.supports,
        sourceId: 'c',
        targetId: 'b',
      ));

      final connected = graph.getConnectedEdges('b');
      expect(connected, hasLength(2));
    });

    test('getNeighbors returns connected nodes via outgoing edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.entity, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.concept, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'c',
      ));

      final neighbors = graph.getNeighbors('a');
      expect(neighbors, hasLength(2));
      expect(neighbors.map((n) => n.id).toSet(), equals({'b', 'c'}));
    });

    test('getPredecessors returns nodes with incoming edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'c',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.supports,
        sourceId: 'b',
        targetId: 'c',
      ));

      final predecessors = graph.getPredecessors('c');
      expect(predecessors, hasLength(2));
      expect(predecessors.map((n) => n.id).toSet(), equals({'a', 'b'}));
    });

    test('getEdgesBetween finds edges between nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));

      final edges = graph.getEdgesBetween('a', 'b');
      expect(edges, hasLength(2));
    });

    test('getEdgesBetween finds bidirectional edges in reverse direction', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-bidi',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
        bidirectional: true,
      ));

      // Query in reverse direction for bidirectional edge
      final edges = graph.getEdgesBetween('b', 'a');
      expect(edges, hasLength(1));
    });

    test('getNodesByType returns nodes of a specific type', () {
      graph.addNode(FactNode(id: 'f1', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'f2', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'e1', type: NodeType.entity, content: {}));

      final facts = graph.getNodesByType(NodeType.fact);
      expect(facts, hasLength(2));

      final entities = graph.getNodesByType(NodeType.entity);
      expect(entities, hasLength(1));
    });

    test('getNodesByTag returns nodes with a specific tag', () {
      graph.addNode(FactNode(
        id: 'n1',
        type: NodeType.fact,
        content: {},
        tags: ['important'],
      ));
      graph.addNode(FactNode(
        id: 'n2',
        type: NodeType.fact,
        content: {},
        tags: ['important', 'verified'],
      ));
      graph.addNode(FactNode(id: 'n3', type: NodeType.fact, content: {}));

      final tagged = graph.getNodesByTag('important');
      expect(tagged, hasLength(2));
    });

    test('findNodes with custom predicate', () {
      graph.addNode(FactNode(
        id: 'n1',
        type: NodeType.fact,
        content: {'score': 10},
      ));
      graph.addNode(FactNode(
        id: 'n2',
        type: NodeType.fact,
        content: {'score': 50},
      ));
      graph.addNode(FactNode(
        id: 'n3',
        type: NodeType.fact,
        content: {'score': 90},
      ));

      final highScore = graph.findNodes(
        (n) => (n.content['score'] as int? ?? 0) > 40,
      );
      expect(highScore, hasLength(2));
    });

    test('findEdges with custom predicate', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
        confidence: 0.9,
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
        confidence: 0.3,
      ));

      final highConf = graph.findEdges(
        (e) => (e.confidence ?? 0) > 0.5,
      );
      expect(highConf, hasLength(1));
      expect(highConf.first.id, equals('e-1'));
    });

    // Graph algorithms

    test('hasPath returns true for connected nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'b',
        targetId: 'c',
      ));

      expect(graph.hasPath('a', 'c'), isTrue);
    });

    test('hasPath returns true for same node', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      expect(graph.hasPath('a', 'a'), isTrue);
    });

    test('hasPath returns false for disconnected nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));

      expect(graph.hasPath('a', 'b'), isFalse);
    });

    test('hasPath returns false for non-existent nodes', () {
      expect(graph.hasPath('missing1', 'missing2'), isFalse);
    });

    test('findPath returns shortest path', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'b',
        targetId: 'c',
      ));

      final path = graph.findPath('a', 'c');
      expect(path, isNotNull);
      expect(path, equals(['a', 'b', 'c']));
    });

    test('findPath returns single node for same start and end', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));

      final path = graph.findPath('a', 'a');
      expect(path, equals(['a']));
    });

    test('findPath returns null for disconnected nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));

      final path = graph.findPath('a', 'b');
      expect(path, isNull);
    });

    test('findPath returns null for non-existent nodes', () {
      expect(graph.findPath('missing1', 'missing2'), isNull);
    });

    test('subgraph extracts local neighborhood', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'd', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'b',
        targetId: 'c',
      ));
      graph.addEdge(FactEdge(
        id: 'e-3',
        type: EdgeType.relatesTo,
        sourceId: 'c',
        targetId: 'd',
      ));

      final sub = graph.subgraph('a', maxDistance: 1);

      expect(sub.hasNode('a'), isTrue);
      expect(sub.hasNode('b'), isTrue);
      expect(sub.hasNode('c'), isFalse);
      expect(sub.hasNode('d'), isFalse);
      expect(sub.hasEdge('e-1'), isTrue);
    });

    test('subgraph with maxDistance 2 includes more nodes', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'c', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));
      graph.addEdge(FactEdge(
        id: 'e-2',
        type: EdgeType.relatesTo,
        sourceId: 'b',
        targetId: 'c',
      ));

      final sub = graph.subgraph('a', maxDistance: 2);

      expect(sub.hasNode('a'), isTrue);
      expect(sub.hasNode('b'), isTrue);
      expect(sub.hasNode('c'), isTrue);
      expect(sub.edgeCount, equals(2));
    });

    // Serialization

    test('toJson and fromJson round trip', () {
      graph.addNode(FactNode(
        id: 'n1',
        type: NodeType.fact,
        content: {'text': 'Fact 1'},
      ));
      graph.addNode(FactNode(
        id: 'n2',
        type: NodeType.entity,
        content: {'name': 'Entity 1'},
      ));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'n1',
        targetId: 'n2',
      ));

      final json = graph.toJson();
      final restored = FactGraph.fromJson(json);

      expect(restored.name, equals('test-graph'));
      expect(restored.nodeCount, equals(2));
      expect(restored.edgeCount, equals(1));
      expect(restored.hasNode('n1'), isTrue);
      expect(restored.hasNode('n2'), isTrue);
      expect(restored.hasEdge('e-1'), isTrue);
    });

    test('fromJson handles empty graph', () {
      final json = <String, dynamic>{};

      final g = FactGraph.fromJson(json);

      expect(g.name, equals('unnamed'));
      expect(g.nodeCount, equals(0));
      expect(g.edgeCount, equals(0));
    });

    test('toJson excludes empty metadata', () {
      final g = FactGraph(name: 'test');

      final json = g.toJson();

      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes non-empty metadata', () {
      final g = FactGraph(name: 'test', metadata: {'v': 1});

      final json = g.toJson();

      expect(json['metadata'], equals({'v': 1}));
    });

    // Clear

    test('clear removes all nodes and edges', () {
      graph.addNode(FactNode(id: 'a', type: NodeType.fact, content: {}));
      graph.addNode(FactNode(id: 'b', type: NodeType.fact, content: {}));
      graph.addEdge(FactEdge(
        id: 'e-1',
        type: EdgeType.relatesTo,
        sourceId: 'a',
        targetId: 'b',
      ));

      graph.clear();

      expect(graph.nodeCount, equals(0));
      expect(graph.edgeCount, equals(0));
    });

    test('toString returns expected format', () {
      graph.addNode(FactNode(id: 'n1', type: NodeType.fact, content: {}));

      final str = graph.toString();

      expect(str, contains('FactGraph'));
      expect(str, contains('test-graph'));
      expect(str, contains('1 nodes'));
      expect(str, contains('0 edges'));
    });
  });
}
