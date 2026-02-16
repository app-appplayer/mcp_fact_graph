/// Context Service - L2 Layer operations.
///
/// Handles context bundles, summaries, and claim verification.
library;

import '../domain/entities/context_bundle.dart';
import '../domain/entities/summary_node.dart';
import '../domain/entities/claim.dart';
import '../domain/entities/event.dart';
import '../ports/storage_port.dart';
import '../ports/llm_port.dart';

/// Service for L2 ContextOps Layer operations.
class ContextService {
  /// Context storage port.
  final ContextStoragePort _storage;

  /// Event storage port.
  final EventStoragePort _eventStorage;

  /// LLM port for summarization.
  final LlmPort? _llm;

  /// Claim verification port.
  final ClaimVerificationPort? _verifier;

  ContextService({
    required ContextStoragePort storage,
    required EventStoragePort eventStorage,
    LlmPort? llm,
    ClaimVerificationPort? verifier,
  })  : _storage = storage,
        _eventStorage = eventStorage,
        _llm = llm,
        _verifier = verifier;

  // =========================================================================
  // Context Bundle Operations
  // =========================================================================

  /// Build context bundle for a query.
  Future<ContextBundle> buildContext({
    required String query,
    required ContextPurpose purpose,
    int tokenBudget = 4096,
    SelectionStrategy strategy = SelectionStrategy.relevance,
  }) async {
    final bundleId = _generateId('ctx');
    final now = DateTime.now();

    // Fetch relevant events
    final events = await _eventStorage.queryEvents(const EventQuery(
      status: EventStatus.active,
      limit: 100,
    ));

    // Build segments from events
    final segments = <ContextSegment>[];
    var totalTokens = 0;

    for (final event in events) {
      final content = _eventToContent(event);
      final tokens = _estimateTokens(content);

      if (totalTokens + tokens > tokenBudget) break;

      segments.add(ContextSegment(
        type: SegmentType.fact,
        sourceId: event.eventId,
        content: content,
        tokenCount: tokens,
        relevance: 1.0,
        position: segments.length,
      ));
      totalTokens += tokens;
    }

    final bundle = ContextBundle(
      bundleId: bundleId,
      purpose: purpose,
      query: query,
      eventIds: segments.map((s) => s.sourceId).toList(),
      segments: segments,
      tokenCount: totalTokens,
      tokenBudget: tokenBudget,
      createdAt: now,
      strategy: strategy,
    );

    await _storage.saveContextBundle(bundle);
    return bundle;
  }

  /// Get context bundle by ID.
  Future<ContextBundle?> getContextBundle(String bundleId) {
    return _storage.getContextBundle(bundleId);
  }

  // =========================================================================
  // Summary Operations
  // =========================================================================

  /// Create summary from events.
  Future<SummaryNode> createSummary({
    required SummaryType summaryType,
    required String title,
    required List<String> eventIds,
    String? scope,
    String? parentId,
  }) async {
    if (_llm == null) {
      throw StateError('LLM port not configured for summarization');
    }

    final nodeId = _generateId('sum');
    final now = DateTime.now();

    // Fetch events
    final events = <Event>[];
    for (final eventId in eventIds) {
      final event = await _eventStorage.getEvent(eventId);
      if (event != null) events.add(event);
    }

    // Generate summary using LLM
    final content = await _generateSummary(events);
    final tokens = _estimateTokens(content);

    final node = SummaryNode(
      nodeId: nodeId,
      summaryType: summaryType,
      title: title,
      content: content,
      scope: scope,
      parentId: parentId,
      sourceEventIds: eventIds,
      tokenCount: tokens,
      createdAt: now,
      updatedAt: now,
      status: SummaryStatus.current,
    );

    await _storage.saveSummaryNode(node);
    return node;
  }

  /// Get summary node by ID.
  Future<SummaryNode?> getSummaryNode(String nodeId) {
    return _storage.getSummaryNode(nodeId);
  }

  /// Get child summaries.
  Future<List<SummaryNode>> getChildSummaries(String parentId) {
    return _storage.getChildSummaries(parentId);
  }

  /// Refresh stale summary.
  Future<SummaryNode> refreshSummary(String nodeId) async {
    final node = await _storage.getSummaryNode(nodeId);
    if (node == null) {
      throw ArgumentError('Summary node not found: $nodeId');
    }

    // Mark as updating
    final updating = node.copyWith(
      status: SummaryStatus.updating,
      updatedAt: DateTime.now(),
    );
    await _storage.saveSummaryNode(updating);

    // Regenerate summary
    return createSummary(
      summaryType: node.summaryType,
      title: node.title,
      eventIds: node.sourceEventIds,
      scope: node.scope,
      parentId: node.parentId,
    );
  }

  // =========================================================================
  // Claim Verification Operations
  // =========================================================================

  /// Extract and verify claims from text.
  Future<List<Claim>> verifyClaims({
    required String responseText,
    String? responseId,
    List<String>? evidenceIds,
  }) async {
    if (_verifier == null) {
      throw StateError('Claim verifier not configured');
    }

    // Extract claims (simple sentence splitting for now)
    final statements = _extractStatements(responseText);
    final claims = <Claim>[];

    for (final statement in statements) {
      final claim = await _verifyClaim(
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
  Future<Claim?> getClaim(String claimId) {
    return _storage.getClaim(claimId);
  }

  /// Get pending claims.
  Future<List<Claim>> getPendingClaims() {
    return _storage.getPendingClaims();
  }

  // =========================================================================
  // Private Methods
  // =========================================================================

  String _eventToContent(Event event) {
    final buffer = StringBuffer();
    buffer.writeln('${event.eventType}: ${event.summary}');
    if (event.data.isNotEmpty) {
      for (final entry in event.data.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }

  Future<String> _generateSummary(List<Event> events) async {
    if (_llm == null || events.isEmpty) {
      return 'No events to summarize.';
    }

    final eventsText = events.map(_eventToContent).join('\n');

    final response = await _llm!.complete(LlmRequest(
      systemPrompt: 'You are a concise summarizer. Summarize the following events.',
      prompt: eventsText,
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

  Future<Claim> _verifyClaim({
    required String statement,
    String? responseId,
    List<String>? evidenceIds,
  }) async {
    final claimId = _generateId('claim');
    final now = DateTime.now();

    // Gather evidence
    final evidence = <String>[];
    if (evidenceIds != null) {
      for (final eventId in evidenceIds) {
        final event = await _eventStorage.getEvent(eventId);
        if (event != null) {
          evidence.add(_eventToContent(event));
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

    return Claim(
      claimId: claimId,
      statement: statement,
      responseId: responseId,
      verificationStatus: result != null
          ? VerificationStatus.verified
          : VerificationStatus.pending,
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
