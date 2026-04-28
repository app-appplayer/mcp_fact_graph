// Tests for ContextService - L2 Layer operations.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal ports — accessed via src path since they are not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:mcp_fact_graph/src/ports/llm_port.dart';

// Mock ContextStoragePort
class MockContextStoragePort implements ContextStoragePort {
  final Map<String, InternalContextBundle> _bundles = {};
  final Map<String, SummaryNode> _summaries = {};
  final Map<String, VerifiableClaim> _claims = {};

  @override
  Future<void> saveContextBundle(InternalContextBundle bundle) async {
    _bundles[bundle.bundleId] = bundle;
  }

  @override
  Future<InternalContextBundle?> getContextBundle(String bundleId) async {
    return _bundles[bundleId];
  }

  @override
  Future<List<InternalContextBundle>> queryContextBundles(
      ContextBundleQuery query) async {
    return _bundles.values.toList();
  }

  @override
  Future<void> saveSummaryNode(SummaryNode node) async {
    _summaries[node.summaryId] = node;
  }

  @override
  Future<SummaryNode?> getSummaryNode(String nodeId) async {
    return _summaries[nodeId];
  }

  @override
  Future<List<SummaryNode>> querySummaryNodes(SummaryNodeQuery query) async {
    return _summaries.values.toList();
  }

  @override
  Future<void> saveClaim(VerifiableClaim claim) async {
    _claims[claim.claimId] = claim;
  }

  @override
  Future<VerifiableClaim?> getClaim(String claimId) async {
    return _claims[claimId];
  }

  @override
  Future<List<VerifiableClaim>> queryClaims(ClaimQuery query) async {
    return _claims.values.toList();
  }

  @override
  Future<List<VerifiableClaim>> getPendingClaims() async {
    return _claims.values
        .where((c) => c.verificationStatus == ClaimStatus.pending)
        .toList();
  }
}

// Mock FactStoragePort
class MockFactStoragePort implements FactStoragePort {
  final Map<String, Fact> _facts = {};

  @override
  Future<void> saveFact(Fact fact) async {
    _facts[fact.factId] = fact;
  }

  @override
  Future<Fact?> getFact(String factId) async {
    return _facts[factId];
  }

  @override
  Future<List<Fact>> queryFacts(FactQuery query) async {
    var results = _facts.values.toList();
    if (query.status != null) {
      results = results.where((f) => f.status == query.status).toList();
    }
    if (query.limit != null) {
      results = results.take(query.limit!).toList();
    }
    return results;
  }

  @override
  Future<List<Fact>> getFactsForEntity(String entityId) async {
    return _facts.values
        .where((f) => f.entityRefs.contains(entityId))
        .toList();
  }

  @override
  Future<void> deleteFact(String factId) async {
    _facts.remove(factId);
  }
}

// Mock LlmPort
class MockLlmPort extends LlmPort {
  String completionResult = 'Summary of facts.';

  @override
  LlmCapabilities get capabilities => const LlmCapabilities.minimal();

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    return LlmResponse(content: completionResult);
  }
}

// Mock ClaimVerificationPort
class MockClaimVerificationPort implements ClaimVerificationPort {
  ClaimVerificationResult? verifyResult;

  @override
  Future<ClaimVerificationResult> verify(
      ClaimVerificationInput input) async {
    return verifyResult ??
        const ClaimVerificationResult(
          verdict: 'supported',
          confidence: 0.85,
          explanation: 'Claim matches evidence.',
        );
  }
}

void main() {
  group('ContextService', () {
    late MockContextStoragePort contextStorage;
    late MockFactStoragePort factStorage;
    late MockLlmPort llm;
    late MockClaimVerificationPort verifier;
    late ContextService serviceWithAll;
    late ContextService serviceWithoutLlm;
    late ContextService serviceWithoutVerifier;

    final now = DateTime.now();

    setUp(() {
      contextStorage = MockContextStoragePort();
      factStorage = MockFactStoragePort();
      llm = MockLlmPort();
      verifier = MockClaimVerificationPort();

      serviceWithAll = ContextService(
        storage: contextStorage,
        factStorage: factStorage,
        llm: llm,
        verifier: verifier,
      );
      serviceWithoutLlm = ContextService(
        storage: contextStorage,
        factStorage: factStorage,
        verifier: verifier,
      );
      serviceWithoutVerifier = ContextService(
        storage: contextStorage,
        factStorage: factStorage,
        llm: llm,
      );
    });

    group('buildContext', () {
      test('builds context bundle from confirmed facts', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          payload: const {'amount': 15},
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'What did I spend?',
        );

        expect(bundle.bundleId, startsWith('ctx_'));
        expect(bundle.workspaceId, equals('ws-1'));
        expect(bundle.query, equals('What did I spend?'));
        expect(bundle.facts, isNotEmpty);
        expect(bundle.policyVersion, equals('1.0.0'));
      });

      test('respects token budget', () async {
        // Add a fact with large content
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'A' * 1000, // Large summary
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'query',
          tokenBudget: 10, // Very small budget
        );

        // Bundle should still be created, but may have fewer facts
        expect(bundle, isNotNull);
      });

      test('saves bundle to storage', () async {
        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'query',
        );

        final stored =
            await contextStorage.getContextBundle(bundle.bundleId);
        expect(stored, isNotNull);
      });

      test('uses default token budget of 4096', () async {
        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'query',
        );

        expect(bundle.budget.maxTokens, equals(4096));
      });
    });

    group('getContextBundle', () {
      test('returns bundle when found', () async {
        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'query',
        );

        final result =
            await serviceWithAll.getContextBundle(bundle.bundleId);

        expect(result, isNotNull);
        expect(result!.bundleId, equals(bundle.bundleId));
      });

      test('returns null when not found', () async {
        final result =
            await serviceWithAll.getContextBundle('nonexistent');

        expect(result, isNull);
      });
    });

    group('createSummary', () {
      test('creates summary from facts using LLM', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch at restaurant',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-1'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        expect(summary.summaryId, startsWith('sum_'));
        expect(summary.workspaceId, equals('ws-1'));
        expect(summary.summaryText, equals('Summary of facts.'));
        expect(summary.coversFactIds, contains('fact-1'));
        expect(summary.status, equals(SummaryStatus.active));
      });

      test('throws StateError when LLM not configured', () async {
        expect(
          () => serviceWithoutLlm.createSummary(
            workspaceId: 'ws-1',
            factIds: ['fact-1'],
            scope: const SummaryScope(scopeType: 'period'),
          ),
          throwsStateError,
        );
      });

      test('generates default text when no facts available', () async {
        llm.completionResult = 'No facts to summarize.';

        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['nonexistent-fact'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        expect(summary.summaryText, equals('No facts to summarize.'));
      });

      test('saves summary to storage', () async {
        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: [],
          scope: const SummaryScope(scopeType: 'period'),
        );

        final stored =
            await contextStorage.getSummaryNode(summary.summaryId);
        expect(stored, isNotNull);
      });
    });

    group('refreshSummary', () {
      test('refreshes existing summary', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final originalSummary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-1'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        llm.completionResult = 'Updated summary.';

        // Delay to ensure unique timestamp-based ID generation
        await Future.delayed(const Duration(milliseconds: 2));

        final refreshed = await serviceWithAll
            .refreshSummary(originalSummary.summaryId);

        expect(refreshed.summaryText, equals('Updated summary.'));
        expect(refreshed.summaryId, isNot(equals(originalSummary.summaryId)));
      });

      test('marks old summary as stale before regenerating', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final originalSummary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-1'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        // Delay to ensure unique timestamp-based ID generation
        await Future.delayed(const Duration(milliseconds: 2));

        await serviceWithAll.refreshSummary(originalSummary.summaryId);

        final staleNode = await contextStorage
            .getSummaryNode(originalSummary.summaryId);
        expect(staleNode!.status, equals(SummaryStatus.stale));
      });

      test('throws ArgumentError when summary not found', () async {
        expect(
          () => serviceWithAll.refreshSummary('nonexistent'),
          throwsArgumentError,
        );
      });
    });

    group('verifyClaims', () {
      test('verifies claims with evidence', () async {
        final fact = Fact(
          factId: 'fact-1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch cost 15 dollars',
          payload: const {'amount': 15},
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText:
              'The lunch cost 15 dollars. It was at a nice restaurant.',
          responseId: 'resp-1',
          evidenceIds: ['fact-1'],
        );

        expect(claims, isNotEmpty);
        // Statements shorter than 10 chars are filtered out
        for (final claim in claims) {
          expect(claim.statement.length, greaterThan(10));
        }
      });

      test('throws StateError when verifier not configured', () async {
        expect(
          () => serviceWithoutVerifier.verifyClaims(
            workspaceId: 'ws-1',
            responseText: 'Some claim statement here.',
          ),
          throwsStateError,
        );
      });

      test('creates pending claims when no evidence provided', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'The lunch cost 15 dollars.',
        );

        for (final claim in claims) {
          expect(
              claim.verificationStatus, equals(ClaimStatus.pending));
        }
      });

      test('saves claims to storage', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'The lunch cost 15 dollars.',
        );

        for (final claim in claims) {
          final stored = await contextStorage.getClaim(claim.claimId);
          expect(stored, isNotNull);
        }
      });

      test('filters short statements', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'Short. This is a longer statement for testing purposes.',
        );

        // "Short" is under 10 characters and should be filtered
        for (final claim in claims) {
          expect(claim.statement.length, greaterThan(10));
        }
      });
    });

    group('getClaim', () {
      test('returns claim when found', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'The lunch cost 15 dollars at the restaurant.',
        );

        if (claims.isNotEmpty) {
          final result = await serviceWithAll.getClaim(claims.first.claimId);
          expect(result, isNotNull);
        }
      });

      test('returns null when not found', () async {
        final result = await serviceWithAll.getClaim('nonexistent');
        expect(result, isNull);
      });
    });

    group('getPendingClaims', () {
      test('returns pending claims', () async {
        await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'The lunch cost 15 dollars at the restaurant.',
        );

        final pending = await serviceWithAll.getPendingClaims();

        // Claims without evidence are pending
        for (final claim in pending) {
          expect(
              claim.verificationStatus, equals(ClaimStatus.pending));
        }
      });
    });

    // Additional coverage tests

    group('buildContext - additional coverage', () {
      test('includes facts with non-empty payload in context', () async {
        final fact = Fact(
          factId: 'fact-payload',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          payload: const {'amount': 15, 'currency': 'USD'},
          occurredAt: now,
          candidateId: 'cand-1',
          status: FactStatus.confirmed,
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'expenses',
        );

        expect(bundle.facts, isNotEmpty);
        expect(bundle.tokenEstimate, greaterThan(0));
      });

      test('trims facts when token budget is exceeded', () async {
        // Create many facts with large summaries to exceed budget
        for (var i = 0; i < 10; i++) {
          final fact = Fact(
            factId: 'fact-big-$i',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'A' * 500,
            payload: const {'amount': 100},
            occurredAt: now,
            candidateId: 'cand-$i',
            status: FactStatus.confirmed,
            createdAt: now,
          );
          await factStorage.saveFact(fact);
        }

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'expenses',
          tokenBudget: 200,
        );

        // Should include fewer facts than total
        expect(bundle.facts.length, lessThan(10));
        expect(bundle.tokenEstimate, lessThanOrEqualTo(200));
      });

      test('builds bundle with no facts available', () async {
        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'nothing',
          tokenBudget: 100,
        );

        expect(bundle.facts, isEmpty);
        expect(bundle.tokenEstimate, equals(0));
        expect(bundle.bundleId, startsWith('ctx_'));
        expect(bundle.policyVersion, equals('1.0.0'));
      });

      test('facts with empty payload use summary only', () async {
        final fact = Fact(
          factId: 'fact-no-payload',
          workspaceId: 'ws-1',
          factType: 'note',
          summary: 'Short note',
          occurredAt: now,
          candidateId: 'cand-1',
          status: FactStatus.confirmed,
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'notes',
        );

        expect(bundle.facts, hasLength(1));
        expect(bundle.tokenEstimate, greaterThan(0));
      });
    });

    group('getContextBundle - additional coverage', () {
      test('returns saved bundle with correct data', () async {
        final fact = Fact(
          factId: 'fact-ctx',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Test',
          occurredAt: now,
          candidateId: 'cand-1',
          status: FactStatus.confirmed,
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final bundle = await serviceWithAll.buildContext(
          workspaceId: 'ws-1',
          query: 'test query',
        );

        final retrieved =
            await serviceWithAll.getContextBundle(bundle.bundleId);
        expect(retrieved, isNotNull);
        expect(retrieved!.query, equals('test query'));
        expect(retrieved.workspaceId, equals('ws-1'));
      });
    });

    group('createSummary - additional coverage', () {
      test('fetches multiple facts and generates summary via LLM', () async {
        final fact1 = Fact(
          factId: 'fact-s1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          payload: const {'amount': 15},
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        final fact2 = Fact(
          factId: 'fact-s2',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Dinner',
          payload: const {'amount': 30},
          occurredAt: now,
          candidateId: 'cand-2',
          createdAt: now,
        );
        await factStorage.saveFact(fact1);
        await factStorage.saveFact(fact2);

        llm.completionResult = 'Spent 15 on lunch and 30 on dinner.';

        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-s1', 'fact-s2'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        expect(summary.summaryText,
            equals('Spent 15 on lunch and 30 on dinner.'));
        expect(summary.coversFactIds, contains('fact-s1'));
        expect(summary.coversFactIds, contains('fact-s2'));
        expect(summary.summaryId, startsWith('sum_'));
        expect(summary.status, equals(SummaryStatus.active));
        expect(summary.policyVersion, equals('1.0.0'));
      });

      test('skips non-existent fact IDs during fetch', () async {
        final fact = Fact(
          factId: 'fact-exists',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-exists', 'fact-missing'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        // Should still succeed (only found facts are summarized)
        expect(summary.summaryText, isNotEmpty);
      });

      test('returns default text when all facts are empty', () async {
        // No facts in storage for given IDs
        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['nonexistent-1', 'nonexistent-2'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        expect(summary.summaryText, equals('No facts to summarize.'));
      });
    });

    group('getSummaryNode - additional coverage', () {
      test('returns summary node after creation', () async {
        final summary = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: [],
          scope: const SummaryScope(scopeType: 'period'),
        );

        final result =
            await serviceWithAll.getSummaryNode(summary.summaryId);
        expect(result, isNotNull);
        expect(result!.summaryId, equals(summary.summaryId));
        expect(result.workspaceId, equals('ws-1'));
      });

      test('returns null for non-existent summary', () async {
        final result =
            await serviceWithAll.getSummaryNode('non-existent');
        expect(result, isNull);
      });
    });

    group('refreshSummary - additional coverage', () {
      test('creates new summary with updated content', () async {
        final fact = Fact(
          factId: 'fact-ref',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch',
          payload: const {'amount': 15},
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        llm.completionResult = 'Original summary.';
        final original = await serviceWithAll.createSummary(
          workspaceId: 'ws-1',
          factIds: ['fact-ref'],
          scope: const SummaryScope(scopeType: 'period'),
        );

        await Future.delayed(const Duration(milliseconds: 2));
        llm.completionResult = 'Refreshed summary.';

        final refreshed =
            await serviceWithAll.refreshSummary(original.summaryId);

        expect(refreshed.summaryText, equals('Refreshed summary.'));
        expect(refreshed.summaryId, isNot(equals(original.summaryId)));

        // Verify old node is marked stale
        final staleNode =
            await contextStorage.getSummaryNode(original.summaryId);
        expect(staleNode!.status, equals(SummaryStatus.stale));
      });

      test('throws ArgumentError for non-existent summary', () async {
        expect(
          () => serviceWithAll.refreshSummary('no-such-id'),
          throwsArgumentError,
        );
      });
    });

    group('verifyClaims - additional coverage', () {
      test('verifies claims with existing evidence and returns supported status',
          () async {
        final fact = Fact(
          factId: 'fact-ev1',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch cost 15 dollars',
          payload: const {'amount': 15},
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        verifier.verifyResult = const ClaimVerificationResult(
          verdict: 'supported',
          confidence: 0.9,
          explanation: 'Matches the evidence.',
        );

        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText:
              'The lunch cost fifteen dollars at the restaurant downtown.',
          responseId: 'resp-verify',
          evidenceIds: ['fact-ev1'],
        );

        expect(claims, isNotEmpty);
        for (final claim in claims) {
          expect(claim.verificationStatus, equals(ClaimStatus.supported));
          expect(claim.verificationResult, isNotNull);
          expect(claim.verificationResult!.confidence, equals(0.9));
          expect(claim.confidence, equals(0.9));
          expect(claim.verifiedAt, isNotNull);
          expect(claim.workspaceId, equals('ws-1'));
        }
      });

      test('creates claims with responseId when provided', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'A detailed statement about something important here.',
          responseId: 'resp-123',
        );

        for (final claim in claims) {
          expect(claim.responseId, equals('resp-123'));
        }
      });

      test('creates claims without responseId', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'A detailed statement about something important here.',
        );

        for (final claim in claims) {
          expect(claim.responseId, isNull);
        }
      });

      test('handles evidence IDs where some facts do not exist', () async {
        final fact = Fact(
          factId: 'fact-partial',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Lunch cost 15',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'The lunch costs fifteen dollars at the restaurant.',
          evidenceIds: ['fact-partial', 'non-existent-fact'],
        );

        // Should still work with the one valid evidence
        expect(claims, isNotEmpty);
        for (final claim in claims) {
          expect(claim.verificationStatus, equals(ClaimStatus.supported));
        }
      });

      test('pending status when evidence IDs are empty list', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'A claim about something important that is long enough.',
          evidenceIds: [],
        );

        for (final claim in claims) {
          expect(claim.verificationStatus, equals(ClaimStatus.pending));
          expect(claim.verificationResult, isNull);
          expect(claim.confidence, equals(0.0));
          expect(claim.verifiedAt, isNull);
        }
      });

      test('saves each claim to storage', () async {
        final claims = await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText:
              'First long statement for testing. Second long statement for testing.',
        );

        for (final claim in claims) {
          final stored = await contextStorage.getClaim(claim.claimId);
          expect(stored, isNotNull);
          expect(stored!.claimId, equals(claim.claimId));
        }
      });
    });

    group('getClaim - additional coverage', () {
      test('returns null for non-existent claim', () async {
        final result = await serviceWithAll.getClaim('no-such-claim');
        expect(result, isNull);
      });
    });

    group('getPendingClaims - additional coverage', () {
      test('returns only pending claims, not verified ones', () async {
        // Create verified claims (with evidence)
        final fact = Fact(
          factId: 'fact-pend',
          workspaceId: 'ws-1',
          factType: 'expense',
          summary: 'Test',
          occurredAt: now,
          candidateId: 'cand-1',
          createdAt: now,
        );
        await factStorage.saveFact(fact);

        await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'This is a supported claim statement here.',
          evidenceIds: ['fact-pend'],
        );

        await Future.delayed(const Duration(milliseconds: 2));

        // Create pending claims (without evidence)
        await serviceWithAll.verifyClaims(
          workspaceId: 'ws-1',
          responseText: 'This is a pending claim statement here.',
        );

        final pending = await serviceWithAll.getPendingClaims();
        for (final claim in pending) {
          expect(claim.verificationStatus, equals(ClaimStatus.pending));
        }
      });
    });
  });
}
