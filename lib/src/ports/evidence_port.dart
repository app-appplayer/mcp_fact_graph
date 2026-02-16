/// Evidence Port - Abstract interface for evidence sources.
///
/// Defines contracts for ingesting evidence from external systems.
library;

import '../domain/entities/evidence.dart';
import '../domain/entities/fragment.dart';

/// Port for evidence ingestion from external sources.
abstract class EvidencePort {
  /// Ingest raw content from a source.
  Future<Evidence> ingest(EvidenceInput input);

  /// Check if source is available.
  Future<bool> isAvailable();

  /// Get source capabilities.
  SourceCapabilities get capabilities;
}

/// Input for evidence ingestion.
class EvidenceInput {
  /// Raw content to ingest.
  final String content;

  /// Content type (text, json, html, etc.).
  final String contentType;

  /// Source identifier.
  final String sourceId;

  /// Source type.
  final EvidenceSourceType sourceType;

  /// Source metadata.
  final Map<String, dynamic> metadata;

  const EvidenceInput({
    required this.content,
    this.contentType = 'text/plain',
    required this.sourceId,
    required this.sourceType,
    this.metadata = const {},
  });
}

/// Capabilities of an evidence source.
class SourceCapabilities {
  /// Supported content types.
  final List<String> supportedTypes;

  /// Maximum content size in bytes.
  final int maxContentSize;

  /// Whether streaming is supported.
  final bool supportsStreaming;

  /// Whether incremental updates are supported.
  final bool supportsIncremental;

  const SourceCapabilities({
    this.supportedTypes = const ['text/plain'],
    this.maxContentSize = 10 * 1024 * 1024,
    this.supportsStreaming = false,
    this.supportsIncremental = false,
  });
}

/// Port for fragment extraction.
abstract class FragmentExtractorPort {
  /// Extract fragments from evidence.
  Future<List<Fragment>> extract(Evidence evidence, ExtractionConfig config);

  /// Get supported extraction methods.
  List<ExtractionMethod> get supportedMethods;
}

/// Configuration for fragment extraction.
class ExtractionConfig {
  /// Extraction method to use.
  final ExtractionMethod method;

  /// Maximum fragment size.
  final int maxFragmentSize;

  /// Minimum fragment size.
  final int minFragmentSize;

  /// Overlap between fragments (for chunking).
  final int overlap;

  /// Additional extraction options.
  final Map<String, dynamic> options;

  const ExtractionConfig({
    this.method = ExtractionMethod.llm,
    this.maxFragmentSize = 1000,
    this.minFragmentSize = 50,
    this.overlap = 100,
    this.options = const {},
  });
}
