/// Main fact graph implementation.
library;

import 'fact_node.dart';
import 'fact_edge.dart';

/// A graph structure for storing and querying facts.
class FactGraph {
  FactGraph({
    String? id,
    String? name,
    Map<String, dynamic>? metadata,
  })  : id = id ?? _generateId(),
        name = name ?? 'unnamed',
        metadata = metadata ?? {};

  /// Graph identifier.
  final String id;

  /// Graph name.
  final String name;

  /// Graph metadata.
  final Map<String, dynamic> metadata;

  /// Internal node storage.
  final Map<String, FactNode> _nodes = {};

  /// Internal edge storage.
  final Map<String, FactEdge> _edges = {};

  /// Adjacency list for outgoing edges.
  final Map<String, List<String>> _outgoing = {};

  /// Adjacency list for incoming edges.
  final Map<String, List<String>> _incoming = {};

  // Node operations

  /// Add a node to the graph.
  void addNode(FactNode node) {
    _nodes[node.id] = node;
    _outgoing.putIfAbsent(node.id, () => []);
    _incoming.putIfAbsent(node.id, () => []);
  }

  /// Get a node by ID.
  FactNode? getNode(String id) => _nodes[id];

  /// Check if a node exists.
  bool hasNode(String id) => _nodes.containsKey(id);

  /// Remove a node and its edges.
  FactNode? removeNode(String id) {
    final node = _nodes.remove(id);
    if (node != null) {
      // Remove all edges connected to this node
      final edgesToRemove = <String>[];
      for (final edge in _edges.values) {
        if (edge.sourceId == id || edge.targetId == id) {
          edgesToRemove.add(edge.id);
        }
      }
      for (final edgeId in edgesToRemove) {
        removeEdge(edgeId);
      }
      _outgoing.remove(id);
      _incoming.remove(id);
    }
    return node;
  }

  /// Get all nodes.
  Iterable<FactNode> get nodes => _nodes.values;

  /// Get node count.
  int get nodeCount => _nodes.length;

  // Edge operations

  /// Add an edge to the graph.
  void addEdge(FactEdge edge) {
    if (!hasNode(edge.sourceId)) {
      throw ArgumentError('Source node ${edge.sourceId} does not exist');
    }
    if (!hasNode(edge.targetId)) {
      throw ArgumentError('Target node ${edge.targetId} does not exist');
    }

    _edges[edge.id] = edge;
    _outgoing[edge.sourceId]!.add(edge.id);
    _incoming[edge.targetId]!.add(edge.id);

    // For bidirectional edges, add reverse adjacency
    if (edge.bidirectional) {
      _outgoing[edge.targetId]!.add(edge.id);
      _incoming[edge.sourceId]!.add(edge.id);
    }
  }

  /// Get an edge by ID.
  FactEdge? getEdge(String id) => _edges[id];

  /// Check if an edge exists.
  bool hasEdge(String id) => _edges.containsKey(id);

  /// Remove an edge.
  FactEdge? removeEdge(String id) {
    final edge = _edges.remove(id);
    if (edge != null) {
      _outgoing[edge.sourceId]?.remove(id);
      _incoming[edge.targetId]?.remove(id);
      if (edge.bidirectional) {
        _outgoing[edge.targetId]?.remove(id);
        _incoming[edge.sourceId]?.remove(id);
      }
    }
    return edge;
  }

  /// Get all edges.
  Iterable<FactEdge> get edges => _edges.values;

  /// Get edge count.
  int get edgeCount => _edges.length;

  // Query operations

  /// Get outgoing edges from a node.
  List<FactEdge> getOutgoingEdges(String nodeId) {
    final edgeIds = _outgoing[nodeId] ?? [];
    return edgeIds.map((id) => _edges[id]!).toList();
  }

  /// Get incoming edges to a node.
  List<FactEdge> getIncomingEdges(String nodeId) {
    final edgeIds = _incoming[nodeId] ?? [];
    return edgeIds.map((id) => _edges[id]!).toList();
  }

  /// Get all edges connected to a node.
  List<FactEdge> getConnectedEdges(String nodeId) {
    final outgoing = _outgoing[nodeId] ?? [];
    final incoming = _incoming[nodeId] ?? [];
    final allEdgeIds = {...outgoing, ...incoming};
    return allEdgeIds.map((id) => _edges[id]!).toList();
  }

  /// Get neighbors of a node (connected via outgoing edges).
  List<FactNode> getNeighbors(String nodeId) {
    final edges = getOutgoingEdges(nodeId);
    return edges
        .map((e) => e.getOtherNode(nodeId))
        .nonNulls
        .map((id) => _nodes[id])
        .nonNulls
        .toList();
  }

  /// Get all ancestors of a node (via incoming edges).
  List<FactNode> getPredecessors(String nodeId) {
    final edges = getIncomingEdges(nodeId);
    return edges
        .map((e) => _nodes[e.sourceId])
        .nonNulls
        .toList();
  }

  /// Find edges between two nodes.
  List<FactEdge> getEdgesBetween(String sourceId, String targetId) {
    return _edges.values.where((e) =>
        (e.sourceId == sourceId && e.targetId == targetId) ||
        (e.bidirectional &&
            e.sourceId == targetId &&
            e.targetId == sourceId)).toList();
  }

  /// Find nodes by type.
  List<FactNode> getNodesByType(NodeType type) {
    return _nodes.values.where((n) => n.type == type).toList();
  }

  /// Find nodes by tag.
  List<FactNode> getNodesByTag(String tag) {
    return _nodes.values.where((n) => n.hasTag(tag)).toList();
  }

  /// Find nodes matching a predicate.
  List<FactNode> findNodes(bool Function(FactNode) predicate) {
    return _nodes.values.where(predicate).toList();
  }

  /// Find edges matching a predicate.
  List<FactEdge> findEdges(bool Function(FactEdge) predicate) {
    return _edges.values.where(predicate).toList();
  }

  // Graph algorithms

  /// Check if there is a path between two nodes.
  bool hasPath(String fromId, String toId) {
    if (!hasNode(fromId) || !hasNode(toId)) return false;
    if (fromId == toId) return true;

    final visited = <String>{};
    final queue = <String>[fromId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == toId) return true;

      if (visited.contains(current)) continue;
      visited.add(current);

      for (final edge in getOutgoingEdges(current)) {
        final nextId = edge.getOtherNode(current);
        if (nextId != null && !visited.contains(nextId)) {
          queue.add(nextId);
        }
      }
    }

    return false;
  }

  /// Find shortest path between two nodes (BFS).
  List<String>? findPath(String fromId, String toId) {
    if (!hasNode(fromId) || !hasNode(toId)) return null;
    if (fromId == toId) return [fromId];

    final visited = <String>{};
    final queue = <List<String>>[[fromId]];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == toId) return path;

      if (visited.contains(current)) continue;
      visited.add(current);

      for (final edge in getOutgoingEdges(current)) {
        final nextId = edge.getOtherNode(current);
        if (nextId != null && !visited.contains(nextId)) {
          queue.add([...path, nextId]);
        }
      }
    }

    return null;
  }

  /// Get subgraph containing nodes within distance from a source.
  FactGraph subgraph(String sourceId, {int maxDistance = 2}) {
    final sub = FactGraph(name: '$name-subgraph');
    final visited = <String>{};
    final queue = <(String, int)>[(sourceId, 0)];

    while (queue.isNotEmpty) {
      final (nodeId, distance) = queue.removeAt(0);
      if (visited.contains(nodeId) || distance > maxDistance) continue;

      visited.add(nodeId);
      final node = getNode(nodeId);
      if (node != null) sub.addNode(node);

      if (distance < maxDistance) {
        for (final edge in getOutgoingEdges(nodeId)) {
          final nextId = edge.getOtherNode(nodeId);
          if (nextId != null && !visited.contains(nextId)) {
            queue.add((nextId, distance + 1));
          }
        }
      }
    }

    // Add edges between included nodes
    for (final edge in _edges.values) {
      if (visited.contains(edge.sourceId) &&
          visited.contains(edge.targetId)) {
        sub.addEdge(edge);
      }
    }

    return sub;
  }

  // Serialization

  /// Create from JSON.
  factory FactGraph.fromJson(Map<String, dynamic> json) {
    final graph = FactGraph(
      id: json['id'] as String?,
      name: json['name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

    final nodes = json['nodes'] as List<dynamic>? ?? [];
    for (final nodeJson in nodes) {
      graph.addNode(FactNode.fromJson(nodeJson as Map<String, dynamic>));
    }

    final edges = json['edges'] as List<dynamic>? ?? [];
    for (final edgeJson in edges) {
      graph.addEdge(FactEdge.fromJson(edgeJson as Map<String, dynamic>));
    }

    return graph;
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (metadata.isNotEmpty) 'metadata': metadata,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  /// Clear the graph.
  void clear() {
    _nodes.clear();
    _edges.clear();
    _outgoing.clear();
    _incoming.clear();
  }

  @override
  String toString() =>
      'FactGraph($name: ${nodeCount} nodes, ${edgeCount} edges)';
}

/// Generate a unique ID.
String _generateId() {
  return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
