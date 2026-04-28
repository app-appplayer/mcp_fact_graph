/// AssetPortAdapter - Implements mcp_bundle's capability `AssetPort`.
///
/// MOD-INFRA-021. Exposes `Artifact` entries stored through
/// [ArtifactStoragePort] as byte-level assets.
///
/// The internal `Artifact` entity stores a `contentRef` (e.g., a file
/// path or blob key) rather than inline bytes. This adapter resolves
/// the `contentRef` via an optional [ArtifactBytesResolver]; when no
/// resolver is injected the adapter falls back to treating `contentRef`
/// itself as UTF-8 text payload (useful for tests and in-memory hosts).
library;

import 'dart:convert';

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
// Import knowledge_types directly to pick up the String-keyed
// AssetNotFoundException (the `mcp_bundle.dart` barrel hides it in
// favour of the Uri-keyed io/exceptions variant).
import 'package:mcp_bundle/src/types/knowledge_types.dart' show
    AssetNotFoundException;

import '../../domain/entities/artifact.dart';
import '../../ports/storage_port.dart' as storage;

/// Resolves an `Artifact.contentRef` into a byte list. Downstream
/// adapter packages (filesystem, S3, Firestore) provide real
/// implementations.
typedef ArtifactBytesResolver = Future<List<int>> Function(Artifact artifact);

/// Implements `bundle.AssetPort` on top of `ArtifactStoragePort`.
class AssetPortAdapter implements bundle.AssetPort {
  final storage.ArtifactStoragePort _storagePort;
  final ArtifactBytesResolver _resolver;

  AssetPortAdapter({
    required storage.ArtifactStoragePort artifactStoragePort,
    ArtifactBytesResolver? bytesResolver,
  })  : _storagePort = artifactStoragePort,
        _resolver = bytesResolver ?? _defaultResolver;

  @override
  Future<bundle.AssetContent> getAsset(String id) async {
    final artifact = await _storagePort.getArtifact(id);
    if (artifact == null) {
      throw AssetNotFoundException(id);
    }
    final bytes = await _resolver(artifact);
    return bundle.AssetContent(
      assetId: artifact.artifactId,
      mimeType: _mimeTypeFor(artifact),
      content: bytes,
      size: bytes.length,
    );
  }

  @override
  Stream<List<int>> streamAsset(String id) async* {
    final asset = await getAsset(id);
    final content = asset.content;
    if (content is List<int>) {
      yield content;
    } else if (content is String) {
      yield utf8.encode(content);
    }
  }

  String _mimeTypeFor(Artifact artifact) {
    switch (artifact.format.toLowerCase()) {
      case 'json':
        return 'application/json';
      case 'markdown':
      case 'md':
        return 'text/markdown';
      case 'html':
        return 'text/html';
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }
}

Future<List<int>> _defaultResolver(Artifact artifact) async {
  return utf8.encode(artifact.contentRef);
}
