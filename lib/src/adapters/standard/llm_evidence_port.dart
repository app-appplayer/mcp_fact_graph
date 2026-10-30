/// LlmEvidencePort - structured evidence extraction with an injected LLM.
///
/// Turns raw text into evidence units (`kind`, `verbatim`, `emphasis`,
/// `confidence`, `entityHints`). The heuristic [EvidencePortAdapter] is the
/// fallback when the call fails or the reply cannot be read.
library;

import 'dart:convert';

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import 'evidence_port_adapter.dart';

const String _systemPrompt = '''
You split source text into evidence units. Reply with JSON only: an array of objects with these fields.
text (string, required): the unit, a faithful excerpt or a minimal paraphrase.
verbatim (boolean, required): true only when text is the source's exact words.
emphasis (boolean, optional): true when the source stressed the unit (repetition, intensifier, correction).
kind (string, required): one of decision, task, question, state, fact, insight.
confidence (number 0..1, required): how sure you are.
entityHints (array of strings, optional): names the unit is about.
Return [] when the text holds nothing worth keeping.''';

/// Implements `bundle.EvidencePort` with an LLM, falling back to heuristics.
class LlmEvidencePort implements bundle.EvidencePort {
  final bundle.LlmPort _llm;
  final bundle.EvidencePort _fallback;

  /// Called with the reason whenever the fallback was used, so the host can
  /// log it.
  final void Function(Object reason)? onFallback;

  LlmEvidencePort({
    required bundle.LlmPort llm,
    bundle.EvidencePort? fallback,
    this.onFallback,
  })  : _llm = llm,
        _fallback = fallback ?? EvidencePortAdapter();

  @override
  Future<List<bundle.EvidenceFragment>> extractFragments(
    String content,
    String mimeType,
  ) async {
    if (content.trim().isEmpty) return const [];

    final List<dynamic> raw;
    try {
      final response = await _llm.complete(
        bundle.LlmRequest(
          systemPrompt: _systemPrompt,
          prompt: 'Source type: $mimeType\n\n$content',
          temperature: 0,
          responseFormat: 'json',
        ),
      );
      raw = _decodeUnits(response.content);
    } catch (e) {
      onFallback?.call(e);
      return _fallback.extractFragments(content, mimeType);
    }

    final out = <bundle.EvidenceFragment>[];
    for (final item in raw) {
      final fragment = _toFragment(item, content);
      if (fragment != null) out.add(fragment);
    }
    return out;
  }

  @override
  Future<double> computeConfidence(String fragment) =>
      _fallback.computeConfidence(fragment);

  @override
  Future<String> classifyFragment(String fragment) =>
      _fallback.classifyFragment(fragment);

  /// Reads the reply as a JSON array, or an object holding one under
  /// `units`. Throws [FormatException] for anything else.
  List<dynamic> _decodeUnits(String reply) {
    var text = reply.trim();
    if (text.startsWith('```')) {
      final firstBreak = text.indexOf('\n');
      final lastFence = text.lastIndexOf('```');
      if (firstBreak < 0 || lastFence <= firstBreak) {
        throw const FormatException('unterminated code fence');
      }
      text = text.substring(firstBreak + 1, lastFence).trim();
    }
    final decoded = jsonDecode(text);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['units'] is List) {
      return decoded['units'] as List;
    }
    throw const FormatException('reply is not a list of units');
  }

  bundle.EvidenceFragment? _toFragment(dynamic item, String content) {
    if (item is! Map) return null;
    final text = item['text'];
    final kind = item['kind'];
    final confidence = item['confidence'];
    if (text is! String || text.trim().isEmpty) return null;
    if (kind is! String || !bundle.statementKinds.contains(kind)) return null;
    if (confidence is! num) return null;

    // A verbatim claim is trusted only when the words are in the source;
    // the position is then taken from the source, not from the model.
    var verbatim = item['verbatim'] == true;
    int? offset;
    if (verbatim) {
      final at = content.indexOf(text);
      if (at < 0) {
        verbatim = false;
      } else {
        offset = at;
      }
    }

    final hints = item['entityHints'];
    return bundle.EvidenceFragment(
      text: text,
      type: kind,
      confidence: confidence.toDouble().clamp(0.0, 1.0),
      sourceOffset: offset,
      sourceLength: offset == null ? null : text.length,
      verbatim: verbatim,
      emphasis: item['emphasis'] == true,
      entityHints: hints is List
          ? hints.whereType<String>().where((h) => h.trim().isNotEmpty).toList()
          : const [],
    );
  }
}
