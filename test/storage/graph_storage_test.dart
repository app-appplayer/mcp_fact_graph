// Tests for graph storage implementations.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('MemoryGraphStorage', () {
    late MemoryGraphStorage storage;

    setUp(() {
      storage = MemoryGraphStorage();
    });

    test('save stores a graph', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');

      await storage.save(graph);

      expect(await storage.exists('g1'), isTrue);
    });

    test('load returns saved graph', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);

      final loaded = await storage.load('g1');

      expect(loaded, isNotNull);
      expect(loaded!.id, equals('g1'));
      expect(loaded.name, equals('Test Graph'));
    });

    test('load returns null for missing graph', () async {
      final loaded = await storage.load('nonexistent');

      expect(loaded, isNull);
    });

    test('delete removes graph and returns true', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);

      final deleted = await storage.delete('g1');

      expect(deleted, isTrue);
      expect(await storage.exists('g1'), isFalse);
    });

    test('delete returns false for missing graph', () async {
      final deleted = await storage.delete('nonexistent');

      expect(deleted, isFalse);
    });

    test('listIds returns all stored graph IDs', () async {
      await storage.save(FactGraph(id: 'g1', name: 'Graph 1'));
      await storage.save(FactGraph(id: 'g2', name: 'Graph 2'));

      final ids = await storage.listIds();

      expect(ids, containsAll(['g1', 'g2']));
      expect(ids, hasLength(2));
    });

    test('listIds returns empty list when no graphs', () async {
      final ids = await storage.listIds();

      expect(ids, isEmpty);
    });

    test('exists returns true for stored graph', () async {
      await storage.save(FactGraph(id: 'g1', name: 'Test'));

      expect(await storage.exists('g1'), isTrue);
    });

    test('exists returns false for missing graph', () async {
      expect(await storage.exists('nonexistent'), isFalse);
    });

    test('clear removes all graphs', () {
      storage.save(FactGraph(id: 'g1', name: 'Graph 1'));
      storage.save(FactGraph(id: 'g2', name: 'Graph 2'));

      storage.clear();

      expect(storage.count, equals(0));
    });

    test('count returns number of stored graphs', () async {
      expect(storage.count, equals(0));

      await storage.save(FactGraph(id: 'g1', name: 'Graph 1'));
      expect(storage.count, equals(1));

      await storage.save(FactGraph(id: 'g2', name: 'Graph 2'));
      expect(storage.count, equals(2));
    });
  });

  group('VersionedGraphStorage', () {
    late MemoryGraphStorage baseStorage;
    late VersionedGraphStorage storage;

    setUp(() {
      baseStorage = MemoryGraphStorage();
      storage = VersionedGraphStorage(baseStorage);
    });

    test('save creates versioned copies', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');

      await storage.save(graph);

      // Should save both versioned and latest
      expect(await baseStorage.exists('g1'), isTrue);
      expect(await baseStorage.exists('g1@v1'), isTrue);
    });

    test('save increments version number', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');

      await storage.save(graph);
      await storage.save(graph);

      expect(await baseStorage.exists('g1@v1'), isTrue);
      expect(await baseStorage.exists('g1@v2'), isTrue);
    });

    test('load returns latest version', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);

      final loaded = await storage.load('g1');

      expect(loaded, isNotNull);
      expect(loaded!.id, equals('g1'));
    });

    test('loadVersion returns specific version', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);
      await storage.save(graph);

      final v1 = await storage.loadVersion('g1', 1);

      expect(v1, isNotNull);
      expect(v1!.id, equals('g1@v1'));
    });

    test('loadVersion returns null for missing version', () async {
      final result = await storage.loadVersion('g1', 999);

      expect(result, isNull);
    });

    test('getVersions returns all version numbers', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);
      await storage.save(graph);
      await storage.save(graph);

      final versions = await storage.getVersions('g1');

      expect(versions, equals([1, 2, 3]));
    });

    test('getVersions returns empty list for unknown graph', () async {
      final versions = await storage.getVersions('nonexistent');

      expect(versions, isEmpty);
    });

    test('delete removes all versions', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      await storage.save(graph);
      await storage.save(graph);

      final deleted = await storage.delete('g1');

      expect(deleted, isTrue);
      expect(await baseStorage.exists('g1'), isFalse);
      expect(await baseStorage.exists('g1@v1'), isFalse);
      expect(await baseStorage.exists('g1@v2'), isFalse);
    });

    test('delete returns result from base when no versions', () async {
      final deleted = await storage.delete('nonexistent');

      expect(deleted, isFalse);
    });

    test('listIds delegates to base storage', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      final ids = await storage.listIds();

      expect(ids, isNotEmpty);
    });

    test('exists delegates to base storage', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      expect(await storage.exists('g1'), isTrue);
      expect(await storage.exists('nonexistent'), isFalse);
    });

    test('save preserves nodes and edges in versioned copy', () async {
      final graph = FactGraph(id: 'g1', name: 'Test Graph');
      graph.addNode(FactNode(id: 'n1', type: NodeType.fact, content: const {'label': 'Node 1'}));
      graph.addNode(FactNode(id: 'n2', type: NodeType.fact, content: const {'label': 'Node 2'}));
      graph.addEdge(FactEdge(
        id: 'e1',
        type: EdgeType.relatesTo,
        sourceId: 'n1',
        targetId: 'n2',
      ));

      await storage.save(graph);

      final v1 = await storage.loadVersion('g1', 1);
      expect(v1, isNotNull);
      expect(v1!.nodeCount, equals(2));
      expect(v1.edgeCount, equals(1));
    });
  });

  group('CachedGraphStorage', () {
    late MemoryGraphStorage baseStorage;
    late CachedGraphStorage storage;

    setUp(() {
      baseStorage = MemoryGraphStorage();
      storage = CachedGraphStorage(baseStorage, maxCacheSize: 3);
    });

    test('save stores in both base and cache', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      expect(storage.cacheSize, equals(1));
      expect(await baseStorage.exists('g1'), isTrue);
    });

    test('load returns from cache on hit', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      // Load should come from cache
      final loaded = await storage.load('g1');

      expect(loaded, isNotNull);
      expect(loaded!.id, equals('g1'));
    });

    test('load fetches from base on cache miss', () async {
      // Save directly to base storage
      final graph = FactGraph(id: 'g1', name: 'Test');
      await baseStorage.save(graph);

      // Load from cached storage (cache miss)
      final loaded = await storage.load('g1');

      expect(loaded, isNotNull);
      expect(loaded!.id, equals('g1'));
      // Should now be cached
      expect(storage.cacheSize, equals(1));
    });

    test('load returns null for missing graph', () async {
      final loaded = await storage.load('nonexistent');

      expect(loaded, isNull);
      expect(storage.cacheSize, equals(0));
    });

    test('delete removes from both cache and base', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      await storage.delete('g1');

      expect(storage.cacheSize, equals(0));
      expect(await baseStorage.exists('g1'), isFalse);
    });

    test('exists checks cache first then base', () async {
      final graph = FactGraph(id: 'g1', name: 'Test');
      await storage.save(graph);

      // In cache
      expect(await storage.exists('g1'), isTrue);

      // Not in cache but check base
      await baseStorage.save(FactGraph(id: 'g2', name: 'Test 2'));
      expect(await storage.exists('g2'), isTrue);

      // Not anywhere
      expect(await storage.exists('nonexistent'), isFalse);
    });

    test('evicts oldest entry when at capacity', () async {
      await storage.save(FactGraph(id: 'g1', name: 'G1'));
      await storage.save(FactGraph(id: 'g2', name: 'G2'));
      await storage.save(FactGraph(id: 'g3', name: 'G3'));

      expect(storage.cacheSize, equals(3));

      // Adding a 4th should evict the oldest (g1)
      await storage.save(FactGraph(id: 'g4', name: 'G4'));

      expect(storage.cacheSize, equals(3));
      // g1 should still be in base storage
      expect(await baseStorage.exists('g1'), isTrue);
    });

    test('clearCache removes all cached entries', () async {
      await storage.save(FactGraph(id: 'g1', name: 'G1'));
      await storage.save(FactGraph(id: 'g2', name: 'G2'));

      storage.clearCache();

      expect(storage.cacheSize, equals(0));
      // Base storage should still have the data
      expect(await baseStorage.exists('g1'), isTrue);
      expect(await baseStorage.exists('g2'), isTrue);
    });

    test('cacheSize returns current cache size', () async {
      expect(storage.cacheSize, equals(0));

      await storage.save(FactGraph(id: 'g1', name: 'G1'));
      expect(storage.cacheSize, equals(1));

      await storage.save(FactGraph(id: 'g2', name: 'G2'));
      expect(storage.cacheSize, equals(2));
    });

    test('listIds delegates to base storage', () async {
      await storage.save(FactGraph(id: 'g1', name: 'G1'));
      await storage.save(FactGraph(id: 'g2', name: 'G2'));

      final ids = await storage.listIds();

      expect(ids, containsAll(['g1', 'g2']));
    });

    test('loading cached item moves it to end of access order', () async {
      await storage.save(FactGraph(id: 'g1', name: 'G1'));
      await storage.save(FactGraph(id: 'g2', name: 'G2'));
      await storage.save(FactGraph(id: 'g3', name: 'G3'));

      // Access g1 to move it to end
      await storage.load('g1');

      // Add g4, should evict g2 (oldest non-accessed)
      await storage.save(FactGraph(id: 'g4', name: 'G4'));

      expect(storage.cacheSize, equals(3));
    });
  });
}
