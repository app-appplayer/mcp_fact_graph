/// Unit tests for [ClaimsPortAdapter] — MOD-INFRA-012.
///
/// Mirrors `docs/04_TEST/adapters/standard/02-claims-port-adapter.md`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('ClaimsPortAdapter', () {
    late InMemoryStorageContainer storage;
    late ContextService contextService;
    late ClaimsPortAdapter adapter;

    setUp(() {
      storage = InMemoryStorageContainer();
      contextService = ContextService(
        storage: storage.context,
        factStorage: storage.facts,
      );
      adapter = ClaimsPortAdapter(
        contextService: contextService,
        contextStoragePort: storage.context,
        defaultWorkspaceId: 'ws1',
      );
    });

    bundle.Claim sampleClaim(String id, {bundle.ClaimStatus? status}) {
      return bundle.Claim(
        id: id,
        workspaceId: 'ws1',
        text: 'The sky is blue',
        type: bundle.ClaimType.fact,
        evidenceRefs: const ['ev-1'],
        confidence: 0.9,
        status: status ?? bundle.ClaimStatus.pending,
      );
    }

    test('writeClaims persists a single claim', () async {
      await adapter.writeClaims([sampleClaim('claim-1')]);
      final fetched = await adapter.getClaim('claim-1');
      expect(fetched, isNotNull);
      expect(fetched!.text, 'The sky is blue');
    });

    test('queryClaims returns empty when no claims', () async {
      final result = await adapter.queryClaims(
        const bundle.ClaimQuery(workspaceId: 'ws1'),
      );
      expect(result, isEmpty);
    });

    test('validateClaims returns one entry per claim', () async {
      final report = await adapter.validateClaims([
        sampleClaim('c-1', status: bundle.ClaimStatus.supported),
        sampleClaim('c-2', status: bundle.ClaimStatus.pending),
      ]);
      expect(report.entries, hasLength(2));
      expect(report.passed, isFalse); // one pending
    });

    test('validateClaims passed=true when all supported', () async {
      final report = await adapter.validateClaims([
        sampleClaim('c-1', status: bundle.ClaimStatus.supported),
      ]);
      expect(report.passed, isTrue);
    });

    test('updateClaimStatus throws on missing id', () async {
      expect(
        () => adapter.updateClaimStatus(
          'nope',
          bundle.ClaimStatus.supported,
        ),
        throwsStateError,
      );
    });

    test('updateClaimStatus updates existing claim', () async {
      await adapter.writeClaims([sampleClaim('c-upd')]);
      await adapter.updateClaimStatus(
        'c-upd',
        bundle.ClaimStatus.supported,
      );
      final fetched = await adapter.getClaim('c-upd');
      expect(fetched!.status, bundle.ClaimStatus.supported);
    });

    test('enum mapping covers all bundle.ClaimStatus values', () async {
      for (final status in bundle.ClaimStatus.values) {
        await adapter.writeClaims([sampleClaim('c-${status.name}', status: status)]);
        final fetched = await adapter.getClaim('c-${status.name}');
        expect(fetched, isNotNull);
        expect(fetched!.status, status);
      }
    });
  });
}
