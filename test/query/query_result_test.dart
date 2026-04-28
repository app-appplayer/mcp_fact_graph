import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('QueryResult', () {
    test('creates with items and metadata', () {
      final result = QueryResult<String>(
        items: ['a', 'b', 'c'],
        total: 10,
        offset: 0,
        limit: 3,
      );

      expect(result.items, equals(['a', 'b', 'c']));
      expect(result.total, equals(10));
      expect(result.offset, equals(0));
      expect(result.limit, equals(3));
    });

    test('creates with default offset and no limit', () {
      final result = QueryResult<int>(
        items: [1, 2, 3],
        total: 3,
      );

      expect(result.offset, equals(0));
      expect(result.limit, isNull);
    });

    test('count returns number of items', () {
      final result = QueryResult<int>(
        items: [1, 2, 3],
        total: 10,
      );

      expect(result.count, equals(3));
    });

    test('hasMore returns true when more items exist', () {
      final result = QueryResult<int>(
        items: [1, 2],
        total: 10,
        offset: 0,
      );

      expect(result.hasMore, isTrue);
    });

    test('hasMore returns false when all items returned', () {
      final result = QueryResult<int>(
        items: [1, 2, 3],
        total: 3,
        offset: 0,
      );

      expect(result.hasMore, isFalse);
    });

    test('hasMore accounts for offset', () {
      final result = QueryResult<int>(
        items: [3],
        total: 3,
        offset: 2,
      );

      expect(result.hasMore, isFalse);
    });

    test('hasMore with mid-page offset', () {
      final result = QueryResult<int>(
        items: [2, 3],
        total: 5,
        offset: 1,
      );

      expect(result.hasMore, isTrue);
    });

    test('isEmpty returns true for empty result', () {
      final result = QueryResult<int>(
        items: [],
        total: 0,
      );

      expect(result.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty result', () {
      final result = QueryResult<int>(
        items: [1],
        total: 1,
      );

      expect(result.isEmpty, isFalse);
    });

    test('isNotEmpty returns true for non-empty result', () {
      final result = QueryResult<int>(
        items: [1],
        total: 1,
      );

      expect(result.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns false for empty result', () {
      final result = QueryResult<int>(
        items: [],
        total: 0,
      );

      expect(result.isNotEmpty, isFalse);
    });

    test('firstOrNull returns first item when present', () {
      final result = QueryResult<String>(
        items: ['first', 'second'],
        total: 2,
      );

      expect(result.firstOrNull, equals('first'));
    });

    test('firstOrNull returns null for empty result', () {
      final result = QueryResult<String>(
        items: [],
        total: 0,
      );

      expect(result.firstOrNull, isNull);
    });

    test('map transforms items to different type', () {
      final result = QueryResult<int>(
        items: [1, 2, 3],
        total: 10,
        offset: 5,
        limit: 3,
      );

      final mapped = result.map((i) => i.toString());

      expect(mapped.items, equals(['1', '2', '3']));
      expect(mapped.total, equals(10));
      expect(mapped.offset, equals(5));
      expect(mapped.limit, equals(3));
    });

    test('where filters items', () {
      final result = QueryResult<int>(
        items: [1, 2, 3, 4, 5],
        total: 10,
        offset: 0,
        limit: 5,
      );

      final filtered = result.where((i) => i > 3);

      expect(filtered.items, equals([4, 5]));
      expect(filtered.total, equals(2));
      expect(filtered.offset, equals(0));
      expect(filtered.limit, isNull);
    });

    test('toString returns expected format', () {
      final result = QueryResult<int>(
        items: [1, 2],
        total: 10,
        offset: 3,
      );

      final str = result.toString();

      expect(str, contains('QueryResult'));
      expect(str, contains('count: 2'));
      expect(str, contains('total: 10'));
      expect(str, contains('offset: 3'));
    });
  });

  group('AggregateResult', () {
    test('creates with required fields', () {
      final result = AggregateResult(count: 5);

      expect(result.count, equals(5));
      expect(result.sum, isNull);
      expect(result.avg, isNull);
      expect(result.min, isNull);
      expect(result.max, isNull);
      expect(result.values, isEmpty);
    });

    test('creates with all fields', () {
      final result = AggregateResult(
        count: 10,
        sum: 100.0,
        avg: 10.0,
        min: 1,
        max: 20,
        values: {'groupA': 5, 'groupB': 5},
      );

      expect(result.count, equals(10));
      expect(result.sum, equals(100.0));
      expect(result.avg, equals(10.0));
      expect(result.min, equals(1));
      expect(result.max, equals(20));
      expect(result.values, equals({'groupA': 5, 'groupB': 5}));
    });

    test('toString returns expected format', () {
      final result = AggregateResult(
        count: 5,
        sum: 50.0,
        avg: 10.0,
      );

      final str = result.toString();

      expect(str, contains('AggregateResult'));
      expect(str, contains('count: 5'));
      expect(str, contains('sum: 50.0'));
      expect(str, contains('avg: 10.0'));
    });
  });

  group('PathResult', () {
    test('creates with nodes and edges', () {
      final result = PathResult(
        nodes: ['a', 'b', 'c'],
        edges: ['e1', 'e2'],
      );

      expect(result.nodes, equals(['a', 'b', 'c']));
      expect(result.edges, equals(['e1', 'e2']));
    });

    test('length returns number of edges', () {
      final result = PathResult(
        nodes: ['a', 'b', 'c'],
        edges: ['e1', 'e2'],
      );

      expect(result.length, equals(2));
    });

    test('isEmpty returns true for empty path', () {
      final result = PathResult(
        nodes: [],
        edges: [],
      );

      expect(result.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty path', () {
      final result = PathResult(
        nodes: ['a'],
        edges: [],
      );

      expect(result.isEmpty, isFalse);
    });

    test('start returns first node', () {
      final result = PathResult(
        nodes: ['a', 'b', 'c'],
        edges: ['e1', 'e2'],
      );

      expect(result.start, equals('a'));
    });

    test('start returns null for empty path', () {
      final result = PathResult(
        nodes: [],
        edges: [],
      );

      expect(result.start, isNull);
    });

    test('end returns last node', () {
      final result = PathResult(
        nodes: ['a', 'b', 'c'],
        edges: ['e1', 'e2'],
      );

      expect(result.end, equals('c'));
    });

    test('end returns null for empty path', () {
      final result = PathResult(
        nodes: [],
        edges: [],
      );

      expect(result.end, isNull);
    });

    test('toString returns expected format', () {
      final result = PathResult(
        nodes: ['a', 'b', 'c'],
        edges: ['e1', 'e2'],
      );

      final str = result.toString();

      expect(str, contains('PathResult'));
      expect(str, contains('a'));
      expect(str, contains('b'));
      expect(str, contains('c'));
    });
  });
}
