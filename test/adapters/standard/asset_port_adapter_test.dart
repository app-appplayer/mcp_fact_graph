/// Unit tests for [AssetPortAdapter] — MOD-INFRA-021.
library;

import 'package:mcp_bundle/src/types/knowledge_types.dart' show
    AssetNotFoundException;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/ports/storage_port.dart' as storage;
import 'package:test/test.dart';

class _InMemoryArtifactStorage implements storage.ArtifactStoragePort {
  final Map<String, Artifact> _artifacts = {};

  @override
  Future<void> saveArtifact(Artifact artifact) async {
    _artifacts[artifact.artifactId] = artifact;
  }

  @override
  Future<Artifact?> getArtifact(String artifactId) async =>
      _artifacts[artifactId];

  @override
  Future<List<Artifact>> queryArtifacts(storage.ArtifactQuery query) async =>
      _artifacts.values.toList();

  @override
  Future<List<Artifact>> getArtifactsForRun(String runId) async =>
      _artifacts.values.toList();

  @override
  Future<void> deleteArtifact(String artifactId) async {
    _artifacts.remove(artifactId);
  }
}

void main() {
  group('AssetPortAdapter', () {
    late _InMemoryArtifactStorage artifactStorage;
    late AssetPortAdapter adapter;

    setUp(() {
      artifactStorage = _InMemoryArtifactStorage();
      adapter = AssetPortAdapter(artifactStoragePort: artifactStorage);
    });

    test('getAsset throws AssetNotFoundException on missing id', () async {
      expect(
        () => adapter.getAsset('missing'),
        throwsA(isA<AssetNotFoundException>()),
      );
    });

    test('getAsset returns AssetContent on hit', () async {
      await artifactStorage.saveArtifact(
        Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: '{"ok":true}',
          context: GenerationContext(
            asOf: DateTime(2026, 4, 11),
            policyVersion: '1.0.0',
            queryHash: 'h',
          ),
          createdAt: DateTime(2026, 4, 11),
        ),
      );
      final asset = await adapter.getAsset('art-1');
      expect(asset.assetId, 'art-1');
      expect(asset.mimeType, 'application/json');
      expect(asset.size, greaterThan(0));
    });
  });
}
