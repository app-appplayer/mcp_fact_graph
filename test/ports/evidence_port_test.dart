// Tests for evidence port concrete classes.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal ingestion contracts — relocated from `src/ports/evidence_port.dart`
// in Phase 2.1 (Phase 9 removal).
import 'package:mcp_fact_graph/src/services/ingestion_source.dart';

void main() {
  group('IngestionInput', () {
    test('creates with required parameters', () {
      const input = IngestionInput(
        workspaceId: 'ws-1',
        content: 'Test content',
        sourceId: 'source-1',
        sourceType: EvidenceSourceType.text,
      );

      expect(input.workspaceId, equals('ws-1'));
      expect(input.content, equals('Test content'));
      expect(input.sourceId, equals('source-1'));
      expect(input.sourceType, equals(EvidenceSourceType.text));
      expect(input.contentType, equals('text/plain'));
      expect(input.metadata, isEmpty);
    });

    test('creates with all parameters', () {
      const input = IngestionInput(
        workspaceId: 'ws-1',
        content: 'Test content',
        contentType: 'application/json',
        sourceId: 'source-1',
        sourceType: EvidenceSourceType.api,
        metadata: {'key': 'value'},
      );

      expect(input.contentType, equals('application/json'));
      expect(input.sourceType, equals(EvidenceSourceType.api));
      expect(input.metadata, equals({'key': 'value'}));
    });

    test('supports all source types', () {
      for (final sourceType in EvidenceSourceType.values) {
        final input = IngestionInput(
          workspaceId: 'ws-1',
          content: 'content',
          sourceId: 'source',
          sourceType: sourceType,
        );
        expect(input.sourceType, equals(sourceType));
      }
    });
  });

  group('SourceCapabilities', () {
    test('creates with default values', () {
      const capabilities = SourceCapabilities();

      expect(capabilities.supportedTypes, equals(['text/plain']));
      expect(capabilities.maxContentSize, equals(10 * 1024 * 1024));
      expect(capabilities.supportsStreaming, isFalse);
      expect(capabilities.supportsIncremental, isFalse);
    });

    test('creates with custom values', () {
      const capabilities = SourceCapabilities(
        supportedTypes: ['text/plain', 'application/json', 'text/html'],
        maxContentSize: 5 * 1024 * 1024,
        supportsStreaming: true,
        supportsIncremental: true,
      );

      expect(capabilities.supportedTypes, hasLength(3));
      expect(capabilities.maxContentSize, equals(5 * 1024 * 1024));
      expect(capabilities.supportsStreaming, isTrue);
      expect(capabilities.supportsIncremental, isTrue);
    });
  });

  group('ExtractionConfig', () {
    test('creates with default values', () {
      const config = ExtractionConfig();

      expect(config.method, equals(ExtractorType.llm));
      expect(config.maxFragmentSize, equals(1000));
      expect(config.minFragmentSize, equals(50));
      expect(config.overlap, equals(100));
      expect(config.options, isEmpty);
    });

    test('creates with custom values', () {
      const config = ExtractionConfig(
        method: ExtractorType.rule,
        maxFragmentSize: 500,
        minFragmentSize: 25,
        overlap: 50,
        options: {'language': 'en'},
      );

      expect(config.method, equals(ExtractorType.rule));
      expect(config.maxFragmentSize, equals(500));
      expect(config.minFragmentSize, equals(25));
      expect(config.overlap, equals(50));
      expect(config.options, equals({'language': 'en'}));
    });

    test('supports all extractor types', () {
      for (final method in ExtractorType.values) {
        final config = ExtractionConfig(method: method);
        expect(config.method, equals(method));
      }
    });
  });
}
