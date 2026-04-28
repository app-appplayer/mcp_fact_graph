/// GraphQuery Tests
///
/// Tests for GraphQuery, QueryFilter, and QuerySort.
library;

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('QueryFilter', () {
    test('type filter matches node type', () {
      final filter = QueryFilter.type(NodeType.fact);
      final factNode = FactNode(
        id: 'fact-1',
        type: NodeType.fact,
        content: {'statement': 'Test Fact'},
      );
      final entityNode = FactNode(
        id: 'entity-1',
        type: NodeType.entity,
        content: {'name': 'Test Entity'},
      );

      expect(filter.matches(factNode), isTrue);
      expect(filter.matches(entityNode), isFalse);
    });

    test('tag filter matches node tag', () {
      final filter = QueryFilter.tag('important');
      final taggedNode = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'text': 'Tagged'},
        tags: ['important', 'verified'],
      );
      final untaggedNode = FactNode(
        id: 'node-2',
        type: NodeType.fact,
        content: {'text': 'Untagged'},
      );

      expect(filter.matches(taggedNode), isTrue);
      expect(filter.matches(untaggedNode), isFalse);
    });

    test('property filter matches exact value', () {
      final filter = QueryFilter.property('status', 'active');
      final activeNode = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'status': 'active'},
      );
      final inactiveNode = FactNode(
        id: 'node-2',
        type: NodeType.fact,
        content: {'status': 'inactive'},
      );

      expect(filter.matches(activeNode), isTrue);
      expect(filter.matches(inactiveNode), isFalse);
    });

    test('hasProperty filter checks property existence', () {
      final filter = QueryFilter.hasProperty('amount');
      final nodeWith = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'amount': 100},
      );
      final nodeWithout = FactNode(
        id: 'node-2',
        type: NodeType.fact,
        content: {'other': 'value'},
      );

      expect(filter.matches(nodeWith), isTrue);
      expect(filter.matches(nodeWithout), isFalse);
    });

    test('custom filter with predicate', () {
      final filter = QueryFilter.custom((n) => n.content['name']?.toString().startsWith('Test') ?? false);
      final matchingNode = FactNode(
        id: 'node-1',
        type: NodeType.fact,
        content: {'name': 'Test Node'},
      );
      final nonMatchingNode = FactNode(
        id: 'node-2',
        type: NodeType.fact,
        content: {'name': 'Other Node'},
      );

      expect(filter.matches(matchingNode), isTrue);
      expect(filter.matches(nonMatchingNode), isFalse);
    });

    test('edgeType filter matches edge type', () {
      final filter = QueryFilter.edgeType(EdgeType.supports);
      final supportsEdge = FactEdge(
        id: 'edge-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      );
      final contradictEdge = FactEdge(
        id: 'edge-2',
        type: EdgeType.contradicts,
        sourceId: 'a',
        targetId: 'b',
      );

      expect(filter.matchesEdge(supportsEdge), isTrue);
      expect(filter.matchesEdge(contradictEdge), isFalse);
    });
  });

  group('QuerySort', () {
    test('creates with property and direction', () {
      final ascSort = QuerySort('createdAt', false);
      final descSort = QuerySort('createdAt', true);

      expect(ascSort.property, equals('createdAt'));
      expect(ascSort.descending, isFalse);
      expect(descSort.descending, isTrue);
    });
  });

  group('GraphQuery', () {
    late FactGraph graph;

    setUp(() {
      graph = FactGraph();

      // Add test nodes
      graph.addNode(FactNode(
        id: 'fact-1',
        type: NodeType.fact,
        content: {'statement': 'Fact 1', 'priority': 1, 'amount': 100},
        tags: ['verified'],
      ));
      graph.addNode(FactNode(
        id: 'fact-2',
        type: NodeType.fact,
        content: {'statement': 'Fact 2', 'priority': 2, 'amount': 200},
        tags: ['pending'],
      ));
      graph.addNode(FactNode(
        id: 'concept-1',
        type: NodeType.concept,
        content: {'name': 'Concept 1', 'priority': 3},
      ));
      graph.addNode(FactNode(
        id: 'entity-1',
        type: NodeType.entity,
        content: {'name': 'Entity 1'},
      ));

      // Add edges
      graph.addEdge(FactEdge(
        id: 'edge-1',
        type: EdgeType.supports,
        sourceId: 'entity-1',
        targetId: 'fact-1',
      ));
      graph.addEdge(FactEdge(
        id: 'edge-2',
        type: EdgeType.relatesTo,
        sourceId: 'fact-1',
        targetId: 'fact-2',
      ));
    });

    test('execute returns all nodes without filters', () {
      final result = graph.query().execute();

      expect(result.items.length, equals(4));
      expect(result.total, equals(4));
    });

    test('whereType filters by node type', () {
      final result = graph.query().whereType(NodeType.fact).execute();

      expect(result.items.length, equals(2));
      expect(result.items.every((n) => n.type == NodeType.fact), isTrue);
    });

    test('whereTag filters by tag', () {
      final result = graph.query().whereTag('verified').execute();

      expect(result.items.length, equals(1));
      expect(result.items.first.id, equals('fact-1'));
    });

    test('whereProperty filters by property value', () {
      final result = graph.query().whereProperty('priority', 2).execute();

      expect(result.items.length, equals(1));
      expect(result.items.first.id, equals('fact-2'));
    });

    test('whereHasProperty filters by property existence', () {
      final result = graph.query().whereHasProperty('amount').execute();

      expect(result.items.length, equals(2));
    });

    test('where filters with custom predicate', () {
      final result = graph.query()
          .where((n) => n.content.containsKey('statement'))
          .execute();

      expect(result.items.length, equals(2));
    });

    test('multiple filters combine with AND', () {
      final result = graph.query()
          .whereType(NodeType.fact)
          .whereTag('verified')
          .execute();

      expect(result.items.length, equals(1));
      expect(result.items.first.id, equals('fact-1'));
    });

    test('from starts traversal from node', () {
      final result = graph.query()
          .from('entity-1')
          .depth(1)
          .execute();

      expect(result.items, isNotEmpty);
      expect(result.items.any((n) => n.id == 'entity-1'), isTrue);
    });

    test('depth limits traversal depth', () {
      final result = graph.query()
          .from('entity-1')
          .depth(1)
          .execute();

      // Should include entity-1 and connected nodes within depth 1
      expect(result.items.length, lessThanOrEqualTo(2));
    });

    test('viaEdgeType filters traversal edges', () {
      final result = graph.query()
          .from('entity-1')
          .viaEdgeType(EdgeType.supports)
          .depth(1)
          .execute();

      expect(result.items, isNotEmpty);
    });

    test('take limits results', () {
      final result = graph.query().take(2).execute();

      expect(result.items.length, equals(2));
      expect(result.total, equals(4));
    });

    test('skip offsets results', () {
      final result = graph.query().skip(2).execute();

      expect(result.items.length, equals(2));
      expect(result.offset, equals(2));
    });

    test('take and skip paginate results', () {
      final page1 = graph.query().skip(0).take(2).execute();
      final page2 = graph.query().skip(2).take(2).execute();

      expect(page1.items.length, equals(2));
      expect(page2.items.length, equals(2));

      final allIds = [...page1.items.map((n) => n.id), ...page2.items.map((n) => n.id)];
      expect(allIds.toSet().length, equals(4));
    });

    test('sortBy orders results', () {
      final result = graph.query()
          .whereHasProperty('priority')
          .sortBy('priority')
          .execute();

      expect(result.items.length, greaterThan(1));
      final priorities = result.items.map((n) => n.getProperty('priority') as int).toList();
      expect(priorities, equals([1, 2, 3]));
    });

    test('sortBy descending reverses order', () {
      final result = graph.query()
          .whereHasProperty('priority')
          .sortBy('priority', descending: true)
          .execute();

      final priorities = result.items.map((n) => n.getProperty('priority') as int).toList();
      expect(priorities, equals([3, 2, 1]));
    });

    test('first returns single node', () {
      final result = graph.query()
          .whereType(NodeType.fact)
          .first();

      expect(result, isNotNull);
      expect(result!.type, equals(NodeType.fact));
    });

    test('first returns null for no matches', () {
      final result = graph.query()
          .whereType(NodeType.rule)
          .first();

      expect(result, isNull);
    });

    test('exists returns true for matches', () {
      final result = graph.query()
          .whereType(NodeType.fact)
          .exists();

      expect(result, isTrue);
    });

    test('exists returns false for no matches', () {
      final result = graph.query()
          .whereType(NodeType.rule)
          .exists();

      expect(result, isFalse);
    });

    test('count returns total matches', () {
      final result = graph.query()
          .whereType(NodeType.fact)
          .count();

      expect(result, equals(2));
    });

    test('sortBy handles null property values', () {
      graph.addNode(FactNode(
        id: 'null-prop',
        type: NodeType.fact,
        content: {'statement': 'No priority'},
      ));

      final result = graph.query()
          .whereType(NodeType.fact)
          .sortBy('priority')
          .execute();

      // Node without priority should be sorted before nodes with priority
      expect(result.items, isNotEmpty);
    });

    test('sortBy handles string property values', () {
      final result = graph.query()
          .whereType(NodeType.fact)
          .sortBy('statement')
          .execute();

      final statements = result.items.map((n) => n.getProperty('statement') as String).toList();
      expect(statements, equals(['Fact 1', 'Fact 2']));
    });

    test('sortBy handles DateTime property values', () {
      final g = FactGraph();
      g.addNode(FactNode(
        id: 'dt-1',
        type: NodeType.fact,
        content: {'date': DateTime(2024, 6, 1)},
      ));
      g.addNode(FactNode(
        id: 'dt-2',
        type: NodeType.fact,
        content: {'date': DateTime(2024, 1, 1)},
      ));

      final result = g.query().sortBy('date').execute();

      expect(result.items.first.id, equals('dt-2'));
      expect(result.items.last.id, equals('dt-1'));
    });

    test('sortBy fallback comparison for non-standard types', () {
      final g = FactGraph();
      g.addNode(FactNode(
        id: 'obj-1',
        type: NodeType.fact,
        content: {'flag': true},
      ));
      g.addNode(FactNode(
        id: 'obj-2',
        type: NodeType.fact,
        content: {'flag': false},
      ));

      // Should not throw even with non-standard types
      final result = g.query().sortBy('flag').execute();
      expect(result.items, hasLength(2));
    });

    test('sortBy with only null vs non-null covers null-a branch', () {
      // Ensure _compareValues branch where a==null but b!=null is exercised
      final g = FactGraph();
      g.addNode(FactNode(
        id: 'has-val',
        type: NodeType.fact,
        content: {'score': 10},
      ));
      g.addNode(FactNode(
        id: 'no-val',
        type: NodeType.fact,
        content: {},
      ));

      final result = g.query().sortBy('score').execute();
      // Node without 'score' (null) should sort before the one with 'score'
      expect(result.items, hasLength(2));
      expect(result.items.first.id, equals('no-val'));
      expect(result.items.last.id, equals('has-val'));
    });

    test('traversal with edge filter that rejects all edges', () {
      final result = graph.query()
          .from('entity-1')
          .viaEdgeType(EdgeType.contradicts)
          .depth(2)
          .execute();

      // Only the start node should be included since no edges match
      expect(result.items, hasLength(1));
      expect(result.items.first.id, equals('entity-1'));
    });

    test('traversal handles cycles gracefully', () {
      // Create a cycle: fact-1 -> fact-2 -> fact-1 (already linked)
      graph.addEdge(FactEdge(
        id: 'edge-cycle',
        type: EdgeType.relatesTo,
        sourceId: 'fact-2',
        targetId: 'fact-1',
      ));

      final result = graph.query()
          .from('fact-1')
          .depth(5)
          .execute();

      // Should not enter infinite loop
      expect(result.items, isNotEmpty);
    });
  });

  group('QueryFilter', () {
    test('matches returns true when no node matcher', () {
      final filter = QueryFilter.edgeType(EdgeType.supports);
      final node = FactNode(
        id: 'n-1',
        type: NodeType.fact,
        content: {},
      );

      // Edge type filter has no node matcher, should return true for nodes
      expect(filter.matches(node), isTrue);
    });

    test('matchesEdge returns true when no edge matcher', () {
      final filter = QueryFilter.type(NodeType.fact);
      final edge = FactEdge(
        id: 'e-1',
        type: EdgeType.supports,
        sourceId: 'a',
        targetId: 'b',
      );

      // Type filter has no edge matcher, should return true for edges
      expect(filter.matchesEdge(edge), isTrue);
    });
  });

  group('QueryResult', () {
    test('creates with items and metadata', () {
      final nodes = [
        FactNode(id: 'n1', type: NodeType.fact, content: {'text': 'Node 1'}),
        FactNode(id: 'n2', type: NodeType.fact, content: {'text': 'Node 2'}),
      ];

      final result = QueryResult(
        items: nodes,
        total: 10,
        offset: 5,
        limit: 2,
      );

      expect(result.items.length, equals(2));
      expect(result.total, equals(10));
      expect(result.offset, equals(5));
      expect(result.limit, equals(2));
    });

    test('hasMore indicates more results', () {
      final result1 = QueryResult(
        items: [FactNode(id: 'n1', type: NodeType.fact, content: {'text': 'Node 1'})],
        total: 10,
        offset: 0,
        limit: 1,
      );

      final result2 = QueryResult(
        items: [FactNode(id: 'n1', type: NodeType.fact, content: {'text': 'Node 1'})],
        total: 1,
        offset: 0,
        limit: 10,
      );

      expect(result1.hasMore, isTrue);
      expect(result2.hasMore, isFalse);
    });

    test('isEmpty checks for empty items', () {
      final emptyResult = QueryResult<FactNode>(
        items: const [],
        total: 0,
        offset: 0,
      );

      final nonEmptyResult = QueryResult(
        items: [FactNode(id: 'n1', type: NodeType.fact, content: {'text': 'Node 1'})],
        total: 1,
        offset: 0,
      );

      expect(emptyResult.isEmpty, isTrue);
      expect(nonEmptyResult.isEmpty, isFalse);
    });
  });

  group('QueryableGraph extension', () {
    test('query returns GraphQuery instance', () {
      final graph = FactGraph();
      final query = graph.query();

      expect(query, isA<GraphQuery>());
    });
  });

  group('GraphQuery sortBy - null value ordering', () {
    test('sortBy ascending: null property sorted before non-null', () {
      final g = FactGraph();
      // Add null-value node first so it's likely compared as 'a'
      g.addNode(FactNode(
        id: 'no-val',
        type: NodeType.fact,
        content: {'other': 'x'},
      ));
      g.addNode(FactNode(
        id: 'has-val',
        type: NodeType.fact,
        content: {'score': 10},
      ));

      // Ascending sort: null should come before non-null
      final result = g.query().sortBy('score').execute();
      expect(result.items.first.id, equals('no-val'));
      expect(result.items.last.id, equals('has-val'));
    });

    test('sortBy descending: null property sorted after non-null', () {
      final g = FactGraph();
      g.addNode(FactNode(
        id: 'has-val',
        type: NodeType.fact,
        content: {'score': 10},
      ));
      g.addNode(FactNode(
        id: 'no-val',
        type: NodeType.fact,
        content: {'other': 'x'},
      ));

      // Descending sort: non-null should come first, null last
      final result = g.query().sortBy('score', descending: true).execute();
      expect(result.items.first.id, equals('has-val'));
      expect(result.items.last.id, equals('no-val'));
    });

    test('sortBy with both null values returns equal ordering', () {
      final g = FactGraph();
      g.addNode(FactNode(
        id: 'null-a',
        type: NodeType.fact,
        content: {'x': 1},
      ));
      g.addNode(FactNode(
        id: 'null-b',
        type: NodeType.fact,
        content: {'y': 2},
      ));

      // Both have null 'score', should not crash
      final result = g.query().sortBy('score').execute();
      expect(result.items, hasLength(2));
    });
  });
}
