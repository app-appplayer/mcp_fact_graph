/// Graph query builder and executor.
library;

import '../graph/fact_graph.dart';
import '../graph/fact_node.dart';
import '../graph/fact_edge.dart';
import 'query_result.dart';

/// A fluent query builder for fact graphs.
class GraphQuery {
  GraphQuery(this._graph);

  final FactGraph _graph;
  final List<QueryFilter> _nodeFilters = [];
  final List<QueryFilter> _edgeFilters = [];
  String? _startNode;
  int? _maxDepth;
  int? _limit;
  int _offset = 0;
  QuerySort? _sort;

  /// Start query from a specific node.
  GraphQuery from(String nodeId) {
    _startNode = nodeId;
    return this;
  }

  /// Filter nodes by type.
  GraphQuery whereType(NodeType type) {
    _nodeFilters.add(QueryFilter.type(type));
    return this;
  }

  /// Filter nodes by tag.
  GraphQuery whereTag(String tag) {
    _nodeFilters.add(QueryFilter.tag(tag));
    return this;
  }

  /// Filter nodes by property.
  GraphQuery whereProperty(String name, dynamic value) {
    _nodeFilters.add(QueryFilter.property(name, value));
    return this;
  }

  /// Filter nodes by property existence.
  GraphQuery whereHasProperty(String name) {
    _nodeFilters.add(QueryFilter.hasProperty(name));
    return this;
  }

  /// Filter by custom predicate.
  GraphQuery where(bool Function(FactNode) predicate) {
    _nodeFilters.add(QueryFilter.custom(predicate));
    return this;
  }

  /// Filter edges by type.
  GraphQuery viaEdgeType(EdgeType type) {
    _edgeFilters.add(QueryFilter.edgeType(type));
    return this;
  }

  /// Set maximum traversal depth.
  GraphQuery depth(int max) {
    _maxDepth = max;
    return this;
  }

  /// Limit results.
  GraphQuery take(int count) {
    _limit = count;
    return this;
  }

  /// Skip results.
  GraphQuery skip(int count) {
    _offset = count;
    return this;
  }

  /// Sort results.
  GraphQuery sortBy(String property, {bool descending = false}) {
    _sort = QuerySort(property, descending);
    return this;
  }

  /// Execute query and return nodes.
  QueryResult<FactNode> execute() {
    var results = <FactNode>[];

    if (_startNode != null) {
      // Traversal query
      results = _traverseFrom(_startNode!, _maxDepth ?? 1);
    } else {
      // Filter all nodes
      results = _graph.nodes.toList();
    }

    // Apply node filters
    for (final filter in _nodeFilters) {
      results = results.where((n) => filter.matches(n)).toList();
    }

    // Apply sorting
    if (_sort != null) {
      results.sort((a, b) {
        final aVal = a.getProperty(_sort!.property);
        final bVal = b.getProperty(_sort!.property);
        final comparison = _compareValues(aVal, bVal);
        return _sort!.descending ? -comparison : comparison;
      });
    }

    // Apply pagination
    final total = results.length;
    if (_offset > 0) {
      results = results.skip(_offset).toList();
    }
    if (_limit != null) {
      results = results.take(_limit!).toList();
    }

    return QueryResult(
      items: results,
      total: total,
      offset: _offset,
      limit: _limit,
    );
  }

  /// Execute and return first result.
  FactNode? first() {
    _limit = 1;
    final result = execute();
    return result.items.firstOrNull;
  }

  /// Execute and check if any results exist.
  bool exists() {
    _limit = 1;
    return execute().items.isNotEmpty;
  }

  /// Execute and count results.
  int count() {
    return execute().total;
  }

  List<FactNode> _traverseFrom(String startId, int maxDepth) {
    final results = <FactNode>[];
    final visited = <String>{};
    final queue = <(String, int)>[(startId, 0)];

    while (queue.isNotEmpty) {
      final (nodeId, depth) = queue.removeAt(0);
      if (visited.contains(nodeId) || depth > maxDepth) continue;

      visited.add(nodeId);
      final node = _graph.getNode(nodeId);
      if (node != null) {
        results.add(node);

        if (depth < maxDepth) {
          for (final edge in _graph.getOutgoingEdges(nodeId)) {
            // Apply edge filters
            if (_edgeFilters.isNotEmpty &&
                !_edgeFilters.every((f) => f.matchesEdge(edge))) {
              continue;
            }

            final nextId = edge.getOtherNode(nodeId);
            if (nextId != null && !visited.contains(nextId)) {
              queue.add((nextId, depth + 1));
            }
          }
        }
      }
    }

    return results;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }
}

/// Query filter types.
class QueryFilter {
  QueryFilter._(this._matcher, this._edgeMatcher);

  final bool Function(FactNode)? _matcher;
  final bool Function(FactEdge)? _edgeMatcher;

  factory QueryFilter.type(NodeType type) {
    return QueryFilter._((n) => n.type == type, null);
  }

  factory QueryFilter.tag(String tag) {
    return QueryFilter._((n) => n.hasTag(tag), null);
  }

  factory QueryFilter.property(String name, dynamic value) {
    return QueryFilter._((n) => n.getProperty(name) == value, null);
  }

  factory QueryFilter.hasProperty(String name) {
    return QueryFilter._((n) => n.hasProperty(name), null);
  }

  factory QueryFilter.custom(bool Function(FactNode) predicate) {
    return QueryFilter._(predicate, null);
  }

  factory QueryFilter.edgeType(EdgeType type) {
    return QueryFilter._(null, (e) => e.type == type);
  }

  bool matches(FactNode node) => _matcher?.call(node) ?? true;

  bool matchesEdge(FactEdge edge) => _edgeMatcher?.call(edge) ?? true;
}

/// Sort specification.
class QuerySort {
  QuerySort(this.property, this.descending);

  final String property;
  final bool descending;
}

/// Extension to add query method to FactGraph.
extension QueryableGraph on FactGraph {
  /// Create a query builder for this graph.
  GraphQuery query() => GraphQuery(this);
}
