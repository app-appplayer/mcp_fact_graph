/// EvidencePortAdapter (standard) - Implements mcp_bundle's capability
/// `EvidencePort` for Phase 2.
///
/// MOD-INFRA-014. Performs lightweight fragment extraction, confidence
/// scoring, and classification. Heuristic implementation that does not
/// require an LLM, so the *Scenario A* standalone host can use it
/// out-of-the-box.
///
/// C7. `classifyFragment` returns one or more `category:subtype`
/// tokens separated by `;`. The canonical categories are:
///
///   * `intent:question | statement | command | opinion`
///   * `domain:numeric | temporal | url | email`
///   * `type:factual | subjective`
///
/// A single fragment may match several categories at once
/// (e.g. `intent:question;domain:numeric`). When no rule matches the
/// result degrades to `intent:unknown`. Hosts that wire an
/// [bundle.LlmPort] can request an LLM fallback for the
/// `intent:unknown` case via the optional [llm] constructor argument.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

/// Implements `bundle.EvidencePort` with heuristic fallbacks.
class EvidencePortAdapter implements bundle.EvidencePort {
  /// Optional LLM for classification fallback. Only invoked when the
  /// rule-based pass produces `intent:unknown`.
  final bundle.LlmPort? llm;

  EvidencePortAdapter({this.llm});

  @override
  Future<List<bundle.EvidenceFragment>> extractFragments(
    String content,
    String mimeType,
  ) async {
    if (content.trim().isEmpty) return const [];

    final sentences = content
        .split(RegExp(r'[.!?]+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final fragments = <bundle.EvidenceFragment>[];
    var offset = 0;
    for (final sentence in sentences) {
      final confidence = _heuristicConfidence(sentence);
      final type = _heuristicClassify(sentence);
      final start = content.indexOf(sentence, offset);
      fragments.add(
        bundle.EvidenceFragment(
          text: sentence,
          type: type,
          confidence: confidence,
          sourceOffset: start >= 0 ? start : null,
          sourceLength: sentence.length,
        ),
      );
      if (start >= 0) {
        offset = start + sentence.length;
      }
    }
    return fragments;
  }

  @override
  Future<double> computeConfidence(String fragment) async {
    if (fragment.trim().isEmpty) return 0.0;
    return _heuristicConfidence(fragment);
  }

  @override
  Future<String> classifyFragment(String fragment) async {
    if (fragment.trim().isEmpty) return 'intent:unknown';
    final rule = _heuristicClassify(fragment);
    if (rule != 'intent:unknown') return rule;

    final model = llm;
    if (model == null) return rule;

    // LLM fallback: ask for a short category label. Failures fall back
    // to the rule-based `intent:unknown`.
    try {
      final response = await model.complete(
        bundle.LlmRequest(
          messages: [
            bundle.LlmMessage.system(
              'Classify the user fragment. Reply with one token from: '
              'intent:question, intent:statement, intent:command, '
              'intent:opinion.',
            ),
            bundle.LlmMessage.user(fragment),
          ],
          maxTokens: 16,
        ),
      );
      final text = response.content.trim();
      if (text.startsWith('intent:')) return text.split(RegExp(r'\s')).first;
    } catch (_) {
      // Swallow and fall through to the rule result.
    }
    return rule;
  }

  double _heuristicConfidence(String fragment) {
    final words = fragment.trim().split(RegExp(r'\s+')).length;
    final base = words / 20.0;
    if (base <= 0.1) return 0.1;
    if (base >= 1.0) return 1.0;
    return base;
  }

  /// Rule-based classifier. Concatenates every matching category with
  /// `;` so callers can react to the full picture (e.g. a numeric
  /// question). Falls back to `intent:unknown` when nothing matches.
  String _heuristicClassify(String fragment) {
    final trimmed = fragment.trim();
    final parts = <String>[];

    parts.add(_intentLabel(trimmed));

    for (final domain in _domainLabels(trimmed)) {
      parts.add(domain);
    }

    final typeLabel = _typeLabel(trimmed);
    if (typeLabel != null) parts.add(typeLabel);

    return parts.join(';');
  }

  /// Infer the fragment's primary intent.
  String _intentLabel(String trimmed) {
    if (trimmed.contains('?')) return 'intent:question';
    final commandPrefixes = RegExp(
      r'^(please\s+|pls\s+|do\s+|run\s+|start\s+|stop\s+|open\s+|create\s+|delete\s+|make\s+|go\s+)',
      caseSensitive: false,
    );
    if (commandPrefixes.hasMatch(trimmed)) return 'intent:command';
    if (trimmed.endsWith('.') ||
        trimmed.endsWith('!') ||
        RegExp(r'^[A-Z]').hasMatch(trimmed)) {
      return 'intent:statement';
    }
    if (trimmed.split(RegExp(r'\s+')).length >= 2) return 'intent:opinion';
    return 'intent:unknown';
  }

  /// Detect canonical domain hints: numeric, temporal, url, email.
  List<String> _domainLabels(String trimmed) {
    final out = <String>[];
    if (RegExp(r'\d').hasMatch(trimmed)) out.add('domain:numeric');
    // Temporal: dates (YYYY-MM-DD, M/D), times (HH:MM), keywords.
    final temporal = RegExp(
      r'(\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}[:/]\d{1,2}\b|\b(am|pm|today|tomorrow|yesterday|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b)',
      caseSensitive: false,
    );
    if (temporal.hasMatch(trimmed)) out.add('domain:temporal');
    if (RegExp(r'https?://\S+', caseSensitive: false).hasMatch(trimmed)) {
      out.add('domain:url');
    }
    if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(trimmed)) {
      out.add('domain:email');
    }
    return out;
  }

  /// Infer factual vs subjective using simple lexical cues.
  String? _typeLabel(String trimmed) {
    final lower = trimmed.toLowerCase();
    const subjective = [
      'love',
      'hate',
      'like',
      'dislike',
      'feel',
      'think',
      'believe',
      'maybe',
      'probably',
      'perhaps',
      'seems',
      'wonderful',
      'awful',
      'good',
      'bad',
    ];
    if (subjective.any((k) => _containsWord(lower, k))) {
      return 'type:subjective';
    }
    // Treat hard signals (URL / email / numeric) as factual markers
    // by default. A trailing period alone does not qualify.
    if (RegExp(r'\d').hasMatch(trimmed) ||
        RegExp(r'https?://', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(lower)) {
      return 'type:factual';
    }
    return null;
  }

  bool _containsWord(String haystack, String word) {
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    return pattern.hasMatch(haystack);
  }
}
