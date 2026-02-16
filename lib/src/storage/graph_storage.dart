/// Graph storage interface and implementations.
library;

import '../graph/fact_graph.dart';

/// Abstract interface for graph storage.
abstract class GraphStorage {
  /// Save a graph.
  Future<void> save(FactGraph graph);

  /// Load a graph by ID.
  Future<FactGraph?> load(String id);

  /// Delete a graph.
  Future<bool> delete(String id);

  /// List all graph IDs.
  Future<List<String>> listIds();

  /// Check if a graph exists.
  Future<bool> exists(String id);
}

/// In-memory graph storage.
class MemoryGraphStorage implements GraphStorage {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<void> save(FactGraph graph) async {
    _storage[graph.id] = graph.toJson();
  }

  @override
  Future<FactGraph?> load(String id) async {
    final json = _storage[id];
    if (json == null) return null;
    return FactGraph.fromJson(json);
  }

  @override
  Future<bool> delete(String id) async {
    return _storage.remove(id) != null;
  }

  @override
  Future<List<String>> listIds() async {
    return _storage.keys.toList();
  }

  @override
  Future<bool> exists(String id) async {
    return _storage.containsKey(id);
  }

  /// Clear all stored graphs.
  void clear() => _storage.clear();

  /// Get count of stored graphs.
  int get count => _storage.length;
}

/// Graph storage with versioning support.
class VersionedGraphStorage implements GraphStorage {
  VersionedGraphStorage(this._baseStorage);

  final GraphStorage _baseStorage;
  final Map<String, List<String>> _versions = {};

  @override
  Future<void> save(FactGraph graph) async {
    // Create versioned ID
    final versions = _versions[graph.id] ?? [];
    final version = versions.length + 1;
    final versionedId = '${graph.id}@v$version';

    // Save with versioned ID
    final versionedGraph = FactGraph(
      id: versionedId,
      name: graph.name,
      metadata: {
        ...graph.metadata,
        '_version': version,
        '_originalId': graph.id,
        '_timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Copy nodes and edges
    for (final node in graph.nodes) {
      versionedGraph.addNode(node);
    }
    for (final edge in graph.edges) {
      versionedGraph.addEdge(edge);
    }

    await _baseStorage.save(versionedGraph);

    // Track version
    versions.add(versionedId);
    _versions[graph.id] = versions;

    // Also save latest version reference
    await _baseStorage.save(graph);
  }

  @override
  Future<FactGraph?> load(String id) async {
    return _baseStorage.load(id);
  }

  /// Load a specific version.
  Future<FactGraph?> loadVersion(String id, int version) async {
    final versionedId = '$id@v$version';
    return _baseStorage.load(versionedId);
  }

  /// Get all versions of a graph.
  Future<List<int>> getVersions(String id) async {
    final versions = _versions[id] ?? [];
    return versions
        .map((v) => int.tryParse(v.split('@v').last) ?? 0)
        .toList();
  }

  @override
  Future<bool> delete(String id) async {
    // Delete all versions
    final versions = _versions.remove(id) ?? [];
    for (final versionedId in versions) {
      await _baseStorage.delete(versionedId);
    }
    return _baseStorage.delete(id);
  }

  @override
  Future<List<String>> listIds() async {
    return _baseStorage.listIds();
  }

  @override
  Future<bool> exists(String id) async {
    return _baseStorage.exists(id);
  }
}

/// Cached graph storage wrapper.
class CachedGraphStorage implements GraphStorage {
  CachedGraphStorage(
    this._baseStorage, {
    this.maxCacheSize = 100,
  });

  final GraphStorage _baseStorage;
  final int maxCacheSize;
  final Map<String, FactGraph> _cache = {};
  final List<String> _accessOrder = [];

  @override
  Future<void> save(FactGraph graph) async {
    await _baseStorage.save(graph);
    _addToCache(graph.id, graph);
  }

  @override
  Future<FactGraph?> load(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      _touchCache(id);
      return _cache[id];
    }

    // Load from base storage
    final graph = await _baseStorage.load(id);
    if (graph != null) {
      _addToCache(id, graph);
    }
    return graph;
  }

  @override
  Future<bool> delete(String id) async {
    _removeFromCache(id);
    return _baseStorage.delete(id);
  }

  @override
  Future<List<String>> listIds() async {
    return _baseStorage.listIds();
  }

  @override
  Future<bool> exists(String id) async {
    if (_cache.containsKey(id)) return true;
    return _baseStorage.exists(id);
  }

  void _addToCache(String id, FactGraph graph) {
    // Evict oldest if at capacity
    while (_cache.length >= maxCacheSize && _accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[id] = graph;
    _accessOrder.add(id);
  }

  void _touchCache(String id) {
    _accessOrder.remove(id);
    _accessOrder.add(id);
  }

  void _removeFromCache(String id) {
    _cache.remove(id);
    _accessOrder.remove(id);
  }

  /// Clear the cache.
  void clearCache() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get current cache size.
  int get cacheSize => _cache.length;
}
