/// RetrievalPortAdapter - Implements mcp_bundle's capability `RetrievalPort`.
///
/// MOD-INFRA-020. Phase 2 ships with a single built-in retriever id
/// `factgraph.default` that scores facts by lexical overlap with the
/// incoming query string.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/fact.dart';
import '../../ports/storage_port.dart' as storage;
import '../../services/fact_graph_service.dart';

/// Implements `bundle.RetrievalPort` on top of `FactGraphService`.
class RetrievalPortAdapter implements bundle.RetrievalPort {
  final FactGraphService _factGraphService;
  final String _defaultWorkspaceId;
  final double _minScore;
  final int _defaultMaxResults;

  RetrievalPortAdapter({
    required FactGraphService factGraphService,
    String defaultWorkspaceId = 'default',
    double minScore = 0.15,
    int defaultMaxResults = 20,
  })  : _factGraphService = factGraphService,
        _defaultWorkspaceId = defaultWorkspaceId,
        _minScore = minScore,
        _defaultMaxResults = defaultMaxResults;

  @override
  Future<bundle.RetrievalResult> queryKnowledge(
    String query, {
    String? retrieverId,
    Map<String, dynamic>? filters,
    int? maxResults,
  }) async {
    final workspaceId =
        (filters?['workspaceId'] as String?) ?? _defaultWorkspaceId;
    final limit = maxResults ?? _defaultMaxResults;
    final facts = await _factGraphService.queryFacts(
      storage.FactQuery(workspaceId: workspaceId, limit: limit * 4),
    );

    final queryTokens = _tokenize(query);
    final scored = <_ScoredFact>[];
    for (final fact in facts) {
      final score = _scoreFact(fact, queryTokens);
      if (score >= _minScore) {
        scored.add(_ScoredFact(fact, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(limit).toList();

    return bundle.RetrievalResult(
      passages: top
          .map(
            (s) => bundle.RetrievedPassage(
              id: s.fact.factId,
              content: _factContent(s.fact),
              score: s.score,
              sourceId: s.fact.factType,
            ),
          )
          .toList(),
      totalMatches: top.length,
    );
  }

  @override
  Future<List<bundle.RetrieverInfo>> listRetrievers() async {
    return const [
      bundle.RetrieverInfo(
        id: 'factgraph.default',
        name: 'FactGraph Lexical Retriever',
        type: 'lexical',
        sourceRefs: ['facts', 'summaries'],
        description: 'Lexical overlap over Fact.payload and Fact.summary text.',
      ),
    ];
  }

  // ---- scoring helpers ----

  double _scoreFact(Fact fact, Set<String> queryTokens) {
    if (queryTokens.isEmpty) return 0.0;
    final factTokens = _tokenize(_factContent(fact));
    if (factTokens.isEmpty) return 0.0;
    final matches = queryTokens.where(factTokens.contains).length;
    return matches / queryTokens.length;
  }

  String _factContent(Fact fact) {
    final buf = StringBuffer()..write(fact.summary);
    fact.payload.forEach((k, v) {
      buf.write(' ');
      buf.write(k);
      buf.write('=');
      buf.write(v);
    });
    return buf.toString();
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toSet();
  }
}

class _ScoredFact {
  final Fact fact;
  final double score;
  _ScoredFact(this.fact, this.score);
}
