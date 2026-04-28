/// IndexPortAdapter - Implements mcp_bundle's capability `IndexPort`.
///
/// MOD-INFRA-022. Phase 2 ships with a lightweight in-memory registry
/// of declared indexes. Downstream packages that wire real retrieval
/// engines (BM25, vector, etc.) can subclass this adapter.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

/// Implements `bundle.IndexPort` with an in-memory registry.
class IndexPortAdapter implements bundle.IndexPort {
  final Map<String, bundle.IndexBuildConfig> _registry = {};

  IndexPortAdapter();

  @override
  Future<void> buildIndex(String id, bundle.IndexBuildConfig config) async {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Index id must not be empty');
    }
    _registry[id] = config;
  }

  @override
  Future<bool> indexExists(String id) async {
    return _registry.containsKey(id);
  }

  @override
  Future<void> dropIndex(String id) async {
    _registry.remove(id);
  }
}
