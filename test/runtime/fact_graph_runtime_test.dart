/// Unit tests for [FactGraphRuntime] — MOD-INFRA-023.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:test/test.dart';

void main() {
  group('FactGraphRuntime.inMemory', () {
    late FactGraphRuntime runtime;

    setUp(() {
      runtime = FactGraphRuntime.inMemory(defaultWorkspaceId: 'ws-runtime');
    });

    test('wires all 12 capability adapters (non-null, correct type)', () {
      expect(runtime.facts, isA<bundle.FactsPort>());
      expect(runtime.claims, isA<bundle.ClaimsPort>());
      expect(runtime.entities, isA<bundle.EntitiesPort>());
      expect(runtime.evidence, isA<bundle.EvidencePort>());
      expect(runtime.candidates, isA<bundle.CandidatesPort>());
      expect(runtime.patterns, isA<bundle.PatternsPort>());
      expect(runtime.summaries, isA<bundle.SummariesPort>());
      expect(runtime.runs, isA<bundle.RunsPort>());
      expect(runtime.contextBundle, isA<bundle.ContextBundlePort>());
      expect(runtime.retrieval, isA<bundle.RetrievalPort>());
      expect(runtime.asset, isA<bundle.AssetPort>());
      expect(runtime.index, isA<bundle.IndexPort>());
    });

    test('initialize + isReady + close cycle', () async {
      expect(await runtime.isReady(), isFalse);
      await runtime.initialize();
      expect(await runtime.isReady(), isTrue);
      await runtime.close();
      expect(await runtime.isReady(), isFalse);
    });

    test('initialize is idempotent', () async {
      await runtime.initialize();
      await runtime.initialize();
      expect(await runtime.isReady(), isTrue);
    });

    test('facts round-trip via runtime.facts', () async {
      await runtime.initialize();
      await runtime.facts.writeFacts([
        bundle.FactRecord(
          id: 'rt-fact',
          workspaceId: 'ws-runtime',
          type: 'note',
          content: const {'text': 'hello'},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final fetched = await runtime.facts.getFact('rt-fact');
      expect(fetched, isNotNull);
      expect(fetched!.content['text'], 'hello');
    });
  });
}
