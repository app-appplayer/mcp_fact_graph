/// Query result types for graph queries.
library;

/// Result of a graph query with pagination info.
class QueryResult<T> {
  QueryResult({
    required this.items,
    required this.total,
    this.offset = 0,
    this.limit,
  });

  /// The result items.
  final List<T> items;

  /// Total count before pagination.
  final int total;

  /// Offset used in query.
  final int offset;

  /// Limit used in query.
  final int? limit;

  /// Number of items in result.
  int get count => items.length;

  /// Whether there are more items.
  bool get hasMore => offset + count < total;

  /// Whether the result is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the result has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Get first item or null.
  T? get firstOrNull => items.isNotEmpty ? items.first : null;

  /// Map items to different type.
  QueryResult<U> map<U>(U Function(T) mapper) {
    return QueryResult<U>(
      items: items.map(mapper).toList(),
      total: total,
      offset: offset,
      limit: limit,
    );
  }

  /// Filter items.
  QueryResult<T> where(bool Function(T) predicate) {
    final filtered = items.where(predicate).toList();
    return QueryResult<T>(
      items: filtered,
      total: filtered.length,
      offset: 0,
      limit: null,
    );
  }

  @override
  String toString() =>
      'QueryResult(count: $count, total: $total, offset: $offset)';
}

/// Aggregation result.
class AggregateResult {
  AggregateResult({
    required this.count,
    this.sum,
    this.avg,
    this.min,
    this.max,
    this.values = const {},
  });

  /// Count of items.
  final int count;

  /// Sum of numeric values.
  final double? sum;

  /// Average of numeric values.
  final double? avg;

  /// Minimum value.
  final dynamic min;

  /// Maximum value.
  final dynamic max;

  /// Grouped values.
  final Map<String, dynamic> values;

  @override
  String toString() =>
      'AggregateResult(count: $count, sum: $sum, avg: $avg)';
}

/// Path result for graph traversal.
class PathResult {
  PathResult({
    required this.nodes,
    required this.edges,
  });

  /// Nodes in the path.
  final List<String> nodes;

  /// Edges in the path.
  final List<String> edges;

  /// Path length (number of edges).
  int get length => edges.length;

  /// Whether path is empty.
  bool get isEmpty => nodes.isEmpty;

  /// Start node.
  String? get start => nodes.isNotEmpty ? nodes.first : null;

  /// End node.
  String? get end => nodes.isNotEmpty ? nodes.last : null;

  @override
  String toString() => 'PathResult(${nodes.join(' -> ')})';
}
