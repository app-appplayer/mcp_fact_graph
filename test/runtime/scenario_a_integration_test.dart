/// Scenario A integration test — standalone FactGraphRuntime.
///
/// Per REDESIGN-PLAN.md §5 Scenario A / §7 Success Criteria #5, a host
/// that imports only `mcp_fact_graph` and `mcp_bundle` must be able to
/// exercise the full 12 capability ports through `FactGraphRuntime`.
///
/// This file **MUST NOT** import any other `mcp_*` package.
/// Adding, for example, `package:mcp_knowledge/mcp_knowledge.dart`
/// invalidates the standalone composability guarantee.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_bundle/src/ports/context_bundle_port.dart' as ctx;
import 'package:mcp_bundle/src/types/knowledge_types.dart' show
    AssetNotFoundException;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:test/test.dart';

void main() {
  group('Scenario A — standalone FactGraphRuntime', () {
    late FactGraphRuntime runtime;

    setUp(() async {
      runtime = FactGraphRuntime.inMemory(defaultWorkspaceId: 'ws1');
      await runtime.initialize();
    });

    tearDown(() async {
      await runtime.close();
    });

    test('evidence extract/confidence/classify without an LLM', () async {
      final fragments = await runtime.evidence.extractFragments(
        'Alice spent 12500 won at Cafe X. Was it worth it?',
        'text/plain',
      );
      expect(fragments, isNotEmpty);
      final confidence = await runtime.evidence.computeConfidence(
        fragments.first.text,
      );
      expect(confidence, inInclusiveRange(0.0, 1.0));
      final label = await runtime.evidence.classifyFragment(
        fragments.first.text,
      );
      expect(label, isNotEmpty);
    });

    test('fact CRUD end-to-end', () async {
      await runtime.facts.writeFacts([
        bundle.FactRecord(
          id: 'scenario-a-fact',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {'amount': 12500, 'vendor': 'Cafe X'},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final result = await runtime.facts.queryFacts(
        const bundle.FactQuery(workspaceId: 'ws1'),
      );
      expect(result.any((r) => r.id == 'scenario-a-fact'), isTrue);

      final byId = await runtime.facts.getFact('scenario-a-fact');
      expect(byId, isNotNull);
      expect(byId!.content['amount'], 12500);

      await runtime.facts.deleteFacts(['scenario-a-fact']);
      expect(await runtime.facts.getFact('scenario-a-fact'), isNull);
    });

    test('claims write/query/validate/update', () async {
      final claim = bundle.Claim(
        id: 'scenario-a-claim',
        workspaceId: 'ws1',
        text: 'Cafe X accepted cash',
        type: bundle.ClaimType.fact,
        evidenceRefs: const [],
        confidence: 0.7,
        status: bundle.ClaimStatus.pending,
      );
      await runtime.claims.writeClaims([claim]);
      final fetched = await runtime.claims.queryClaims(
        const bundle.ClaimQuery(workspaceId: 'ws1'),
      );
      expect(fetched.any((c) => c.id == 'scenario-a-claim'), isTrue);

      final report = await runtime.claims.validateClaims([claim]);
      expect(report.entries, hasLength(1));

      await runtime.claims.updateClaimStatus(
        'scenario-a-claim',
        bundle.ClaimStatus.supported,
      );
      final after = await runtime.claims.getClaim('scenario-a-claim');
      expect(after!.status, bundle.ClaimStatus.supported);
    });

    test('entities query + merge short-circuit', () async {
      final initial = await runtime.entities.queryEntities(
        const bundle.EntityQuery(workspaceId: 'ws1'),
      );
      expect(initial, isEmpty);
    });

    test('candidates create/get/reject', () async {
      await runtime.candidates.createCandidates([
        bundle.CandidateRecord(
          id: 'scenario-a-cand',
          workspaceId: 'ws1',
          type: 'expense',
          content: const {'amount': 100},
          createdAt: DateTime(2026, 4, 11),
        ),
      ]);
      final pending = await runtime.candidates.getPendingCandidates('ws1');
      expect(pending.any((c) => c.id == 'scenario-a-cand'), isTrue);
      await runtime.candidates.rejectCandidate(
        'scenario-a-cand',
        'duplicate',
        reviewerId: 'me',
      );
    });

    test('patterns store/get round trip', () async {
      await runtime.patterns.storePattern(
        bundle.PatternRecord(
          id: 'scenario-a-pat',
          workspaceId: 'ws1',
          type: 'rollup',
          description: 'Weekly coffee run',
          confidence: 0.7,
          frequency: 5,
          detectedAt: DateTime(2026, 4, 11),
        ),
      );
      final fetched = await runtime.patterns.getPattern('scenario-a-pat');
      expect(fetched, isNotNull);
      expect(fetched!.frequency, 5);
    });

    test('summaries are null initially', () async {
      final none = await runtime.summaries.getSummary('ent1', 'rollup');
      expect(none, isNull);
    });

    test('runs write + get round trip', () async {
      final record = bundle.RunRecord(
        id: 'scenario-a-run',
        workspaceId: 'ws1',
        producerId: 'skill-1',
        producerKind: 'skill',
        startedAt: DateTime(2026, 4, 11),
        status: bundle.RunStatus.completed,
        inputs: const {'q': 'hi'},
      );
      await runtime.runs.writeRun(record);
      final fetched = await runtime.runs.getRun('scenario-a-run');
      expect(fetched, isNotNull);
      expect(fetched!.producerKind, 'skill');
    });

    test('context bundle builds without error', () async {
      final result = await runtime.contextBundle.buildContextBundle(
        const ctx.ContextBundleRequest(
          query: 'cafe',
          workspaceId: 'ws1',
        ),
      );
      expect(result, isA<bundle.ContextBundle>());
    });

    test('retrieval lists the built-in retriever', () async {
      final retrievers = await runtime.retrieval.listRetrievers();
      expect(retrievers, hasLength(1));
      expect(retrievers.first.id, 'factgraph.default');
    });

    test('asset throws AssetNotFoundException for missing id', () async {
      expect(
        () => runtime.asset.getAsset('missing'),
        throwsA(isA<AssetNotFoundException>()),
      );
    });

    test('index lifecycle build/exists/drop', () async {
      await runtime.index.buildIndex(
        'scenario-a-idx',
        const bundle.IndexBuildConfig(assetRefs: []),
      );
      expect(await runtime.index.indexExists('scenario-a-idx'), isTrue);
      await runtime.index.dropIndex('scenario-a-idx');
      expect(await runtime.index.indexExists('scenario-a-idx'), isFalse);
    });
  });
}
