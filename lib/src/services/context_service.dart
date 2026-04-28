/// Context Service - L2 Layer operations.
///
/// Handles context bundles, summaries, and claim verification.
library;

import '../domain/entities/context_bundle.dart';
import '../domain/entities/summary_node.dart';
import '../domain/entities/claim.dart';
import '../domain/entities/fact.dart';
import '../ports/storage_port.dart';
import '../ports/llm_port.dart';

/// Service for L2 ContextOps Layer operations.
class ContextService {
  /// Context storage port.
  final ContextStoragePort _storage;

  /// Fact storage port.
  final FactStoragePort _factStorage;

  /// LLM port for summarization.
  final LlmPort? _llm;

  /// Claim verification port.
  final ClaimVerificationPort? _verifier;

  ContextService({
    required ContextStoragePort storage,
    required FactStoragePort factStorage,
    LlmPort? llm,
    ClaimVerificationPort? verifier,
  })  : _storage = storage,
        _factStorage = factStorage,
        _llm = llm,
        _verifier = verifier;

  // =========================================================================
  // Context Bundle Operations
  // =========================================================================

  /// Build context bundle for a query.
  Future<InternalContextBundle> buildContext({
    required String workspaceId,
    required String query,
    int tokenBudget = 4096,
  }) async {
    final bundleId = _generateId('ctx');
    final now = DateTime.now();

    // Fetch relevant confirmed facts
    final facts = await _factStorage.queryFacts(const FactQuery(
      status: FactStatus.confirmed,
      limit: 100,
    ));

    // Estimate tokens and trim to budget
    var totalTokens = 0;
    final includedFacts = <Fact>[];

    for (final fact in facts) {
      final content = _factToContent(fact);
      final tokens = _estimateTokens(content);

      if (totalTokens + tokens > tokenBudget) break;

      includedFacts.add(fact);
      totalTokens += tokens;
    }

    final bundle = InternalContextBundle(
      bundleId: bundleId,
      workspaceId: workspaceId,
      query: query,
      facts: includedFacts,
      tokenEstimate: totalTokens,
      budget: BundleBudget(maxTokens: tokenBudget),
      asOf: now,
      policyVersion: '1.0.0',
      createdAt: now,
    );

    await _storage.saveContextBundle(bundle);
    return bundle;
  }

  /// Get context bundle by ID.
  Future<InternalContextBundle?> getContextBundle(String bundleId) {
    return _storage.getContextBundle(bundleId);
  }

  // =========================================================================
  // Summary Operations
  // =========================================================================

  /// Create summary from facts.
  Future<SummaryNode> createSummary({
    required String workspaceId,
    required List<String> factIds,
    required SummaryScope scope,
  }) async {
    if (_llm == null) {
      throw StateError('LLM port not configured for summarization');
    }

    final nodeId = _generateId('sum');
    final now = DateTime.now();

    // Fetch facts
    final facts = <Fact>[];
    for (final factId in factIds) {
      final fact = await _factStorage.getFact(factId);
      if (fact != null) facts.add(fact);
    }

    // Generate summary using LLM
    final content = await _generateSummary(facts);

    final node = SummaryNode(
      summaryId: nodeId,
      workspaceId: workspaceId,
      summaryText: content,
      coversFactIds: factIds,
      asOf: now,
      policyVersion: '1.0.0',
      scope: scope,
      createdAt: now,
      updatedAt: now,
      status: SummaryStatus.active,
    );

    await _storage.saveSummaryNode(node);
    return node;
  }

  /// Get summary node by ID.
  Future<SummaryNode?> getSummaryNode(String nodeId) {
    return _storage.getSummaryNode(nodeId);
  }

  /// Refresh stale summary.
  Future<SummaryNode> refreshSummary(String nodeId) async {
    final node = await _storage.getSummaryNode(nodeId);
    if (node == null) {
      throw ArgumentError('Summary node not found: $nodeId');
    }

    // Mark as stale before regenerating
    final stale = node.copyWith(
      status: SummaryStatus.stale,
      updatedAt: DateTime.now(),
    );
    await _storage.saveSummaryNode(stale);

    // Regenerate summary
    return createSummary(
      workspaceId: node.workspaceId,
      factIds: node.coversFactIds,
      scope: node.scope,
    );
  }

  // =========================================================================
  // Claim Verification Operations
  // =========================================================================

  /// Extract and verify claims from text.
  Future<List<VerifiableClaim>> verifyClaims({
    required String workspaceId,
    required String responseText,
    String? responseId,
    List<String>? evidenceIds,
  }) async {
    if (_verifier == null) {
      throw StateError('Claim verifier not configured');
    }

    // Extract claims (simple sentence splitting for now)
    final statements = _extractStatements(responseText);
    final claims = <VerifiableClaim>[];

    for (final statement in statements) {
      final claim = await _verifyClaim(
        workspaceId: workspaceId,
        statement: statement,
        responseId: responseId,
        evidenceIds: evidenceIds,
      );
      claims.add(claim);
      await _storage.saveClaim(claim);
    }

    return claims;
  }

  /// Get claim by ID.
  Future<VerifiableClaim?> getClaim(String claimId) {
    return _storage.getClaim(claimId);
  }

  /// Get pending claims.
  Future<List<VerifiableClaim>> getPendingClaims() {
    return _storage.getPendingClaims();
  }

  // =========================================================================
  // Private Methods
  // =========================================================================

  String _factToContent(Fact fact) {
    final buffer = StringBuffer();
    buffer.writeln('${fact.factType}: ${fact.summary}');
    if (fact.payload.isNotEmpty) {
      for (final entry in fact.payload.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }

  Future<String> _generateSummary(List<Fact> facts) async {
    if (_llm == null || facts.isEmpty) {
      return 'No facts to summarize.';
    }

    final factsText = facts.map(_factToContent).join('\n');

    final response = await _llm!.complete(LlmRequest(
      systemPrompt: 'You are a concise summarizer. Summarize the following facts.',
      prompt: factsText,
      maxTokens: 500,
    ));

    return response.content;
  }

  List<String> _extractStatements(String text) {
    // Simple sentence extraction
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();
  }

  Future<VerifiableClaim> _verifyClaim({
    required String workspaceId,
    required String statement,
    String? responseId,
    List<String>? evidenceIds,
  }) async {
    final claimId = _generateId('claim');
    final now = DateTime.now();

    // Gather evidence
    final evidence = <String>[];
    if (evidenceIds != null) {
      for (final factId in evidenceIds) {
        final fact = await _factStorage.getFact(factId);
        if (fact != null) {
          evidence.add(_factToContent(fact));
        }
      }
    }

    // Verify claim
    VerificationResult? result;
    if (_verifier != null && evidence.isNotEmpty) {
      final input = ClaimVerificationInput(
        claim: statement,
        evidence: evidence,
      );
      final verificationResult = await _verifier!.verify(input);

      result = VerificationResult(
        verdict: VerificationVerdict.fromString(verificationResult.verdict),
        confidence: verificationResult.confidence,
        explanation: verificationResult.explanation,
        durationMs: 0,
      );
    }

    return VerifiableClaim(
      claimId: claimId,
      workspaceId: workspaceId,
      statement: statement,
      responseId: responseId,
      verificationStatus: result != null
          ? ClaimStatus.supported
          : ClaimStatus.pending,
      verificationResult: result,
      confidence: result?.confidence ?? 0.0,
      createdAt: now,
      verifiedAt: result != null ? now : null,
    );
  }

  int _estimateTokens(String text) {
    // Rough estimation: ~4 characters per token
    return (text.length / 4).ceil();
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs() % 10000;
    return '${prefix}_${timestamp}_$random';
  }
}
