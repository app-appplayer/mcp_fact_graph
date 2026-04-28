/// Unit tests for [IndexPortAdapter] — MOD-INFRA-022.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/src/adapters/standard/index_port_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('IndexPortAdapter', () {
    late IndexPortAdapter adapter;

    setUp(() {
      adapter = IndexPortAdapter();
    });

    test('indexExists is false on unknown id', () async {
      expect(await adapter.indexExists('unknown'), isFalse);
    });

    test('buildIndex then indexExists returns true', () async {
      await adapter.buildIndex(
        'facts-ws1',
        const bundle.IndexBuildConfig(assetRefs: []),
      );
      expect(await adapter.indexExists('facts-ws1'), isTrue);
    });

    test('dropIndex removes the index', () async {
      await adapter.buildIndex(
        'to-drop',
        const bundle.IndexBuildConfig(assetRefs: []),
      );
      await adapter.dropIndex('to-drop');
      expect(await adapter.indexExists('to-drop'), isFalse);
    });

    test('dropIndex no-ops on missing id', () async {
      await adapter.dropIndex('never-existed');
    });

    test('buildIndex throws ArgumentError on empty id', () async {
      expect(
        () => adapter.buildIndex(
          '',
          const bundle.IndexBuildConfig(assetRefs: []),
        ),
        throwsArgumentError,
      );
    });
  });
}
