/// Ingestion source contracts for [EvidenceService].
///
/// Phase 2.1 relocation of the legacy `src/ports/evidence_port.dart`
/// file. The contents here are **package-internal** contracts used by
/// `EvidenceService` to pull raw content from external sources
/// (filesystem, chat bridge, HTTP fetcher, …) and to extract fragments
/// from that content.
///
/// These are *not* capability ports — they do not cross the
/// `mcp_bundle` contract boundary. Capability-level evidence handling
/// lives in `mcp_bundle.EvidencePort` and is exposed through the Phase
/// 2 standard adapter at `src/adapters/standard/evidence_port_adapter.dart`.
///
/// The older `EvidencePort` / `FragmentExtractorPort` class names are
/// preserved for source-adapter maintainers; new code should prefer
/// the capability port and treat these contracts as internal.
library;

import '../domain/entities/evidence.dart';
import '../domain/entities/fragment.dart';

/// Port for evidence ingestion from external sources.
///
/// Implemented by source adapters (filesystem, chat, HTTP, …). The
/// `EvidenceService` invokes `ingest` to pull raw content. Package-
/// internal in Phase 2.1 (not re-exported by the barrel).
abstract class EvidencePort {
  /// Ingest raw content from a source.
  Future<Evidence> ingest(IngestionInput input);

  /// Check if source is available.
  Future<bool> isAvailable();

  /// Get source capabilities.
  SourceCapabilities get capabilities;
}

/// Input for evidence ingestion from external sources.
///
/// Note: distinct from `mcp_bundle.EvidenceInput` which carries richer
/// metadata (`contentHash`, `SourceInfo`). `IngestionInput` is the
/// simpler internal shape used by [EvidencePort.ingest].
class IngestionInput {
  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

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

  const IngestionInput({
    required this.workspaceId,
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
///
/// Implemented by extraction strategies (rule-based, LLM-powered, …).
/// Package-internal in Phase 2.1.
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
