/// [LlmEvidencePort] reply size: the explicit output limit, truncated
/// replies, and splitting of long input.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:test/test.dart';

const _prefix = 'Source type: text/plain\n\n';

class _ScriptedLlm implements bundle.LlmPort {
  _ScriptedLlm(this.respond);

  final bundle.LlmResponse Function(int call, String chunk) respond;
  final List<bundle.LlmRequest> requests = [];

  List<String> get chunks =>
      [for (final r in requests) r.prompt!.substring(_prefix.length)];

  @override
  bundle.LlmCapabilities get capabilities =>
      const bundle.LlmCapabilities.minimal();

  @override
  Future<bool> isAvailable() async => true;

  @override
  bool hasCapability(String capability) => capability == 'completion';

  @override
  Future<bundle.LlmResponse> complete(bundle.LlmRequest request) async {
    requests.add(request);
    return respond(requests.length - 1, request.prompt!.substring(_prefix.length));
  }

  @override
  Stream<bundle.LlmChunk> completeStream(bundle.LlmRequest request) =>
      throw UnsupportedError('not used');

  @override
  Future<List<double>> embed(String text) => throw UnsupportedError('x');

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) =>
      throw UnsupportedError('x');

  @override
  Future<double> similarity(String text1, String text2) =>
      throw UnsupportedError('x');

  @override
  Future<bundle.LlmResponse> completeWithTools(
    bundle.LlmRequest request,
    List<bundle.LlmTool> tools,
  ) =>
      throw UnsupportedError('x');

  @override
  Future<bundle.LlmResponse> completeWithContext(
    bundle.LlmRequest request,
    dynamic context,
  ) =>
      throw UnsupportedError('x');
}

bundle.LlmResponse _reply(String content, {String? finishReason}) =>
    bundle.LlmResponse(content: content, finishReason: finishReason);

String _unit(String text) =>
    '{"text":"$text","verbatim":true,"kind":"fact","confidence":0.9}';

/// Replies with one verbatim unit: the first word of the chunk it was given.
bundle.LlmResponse _firstWord(int call, String chunk) =>
    _reply('[${_unit(chunk.trim().split(RegExp(r'\s+')).first)}]');

void main() {
  group('output limit', () {
    test('every request carries the default limit', () async {
      final llm = _ScriptedLlm((_, __) => _reply('[]'));
      await LlmEvidencePort(llm: llm).extractFragments('some text', 'text/plain');
      expect(llm.requests.single.maxTokens, 8192);
    });

    test('the limit is configurable', () async {
      final llm = _ScriptedLlm((_, __) => _reply('[]'));
      await LlmEvidencePort(llm: llm, maxOutputTokens: 2000)
          .extractFragments('some text', 'text/plain');
      expect(llm.requests.single.maxTokens, 2000);
    });

    for (final reason in ['length', 'max_tokens']) {
      test('a reply cut off ($reason) falls back and says why', () async {
        final llm = _ScriptedLlm(
            (_, __) => _reply(_unit('cut').replaceAll('{', '[{').substring(0, 20),
                finishReason: reason));
        final reasons = <Object>[];
        final out = await LlmEvidencePort(llm: llm, onFallback: reasons.add)
            .extractFragments('We will ship on Friday.', 'text/plain');
        expect(reasons, hasLength(1));
        expect(reasons.single.toString(), contains('cut off'));
        expect(out, isNotEmpty);
      });
    }

    test('a complete reply that happens to be stopped normally is read',
        () async {
      final llm = _ScriptedLlm(
          (_, __) => _reply('[${_unit('ship')}]', finishReason: 'stop'));
      final out = await LlmEvidencePort(llm: llm)
          .extractFragments('We will ship on Friday.', 'text/plain');
      expect(out.single.text, 'ship');
    });
  });

  group('long input', () {
    test('short input is one call', () async {
      final llm = _ScriptedLlm(_firstWord);
      await LlmEvidencePort(llm: llm, maxChunkChars: 50)
          .extractFragments('short text', 'text/plain');
      expect(llm.requests, hasLength(1));
    });

    test('is split into calls no longer than the chunk size', () async {
      final text = List.generate(40, (i) => 'word$i').join(' ');
      final llm = _ScriptedLlm(_firstWord);
      await LlmEvidencePort(llm: llm, maxChunkChars: 60)
          .extractFragments(text, 'text/plain');
      expect(llm.requests.length, greaterThan(1));
      for (final chunk in llm.chunks) {
        expect(chunk.length, lessThanOrEqualTo(60));
      }
      expect(llm.chunks.join(), text);
    });

    test('prefers a blank line, then a line break', () async {
      final text = '${'a' * 30}\n\n${'b' * 30}\n${'c' * 30}';
      final llm = _ScriptedLlm(_firstWord);
      await LlmEvidencePort(llm: llm, maxChunkChars: 40)
          .extractFragments(text, 'text/plain');
      expect(llm.chunks.first, '${'a' * 30}\n\n');
      expect(llm.chunks.join(), text);
    });

    test('never cuts a surrogate pair', () async {
      final text = '😀' * 30;
      final llm = _ScriptedLlm((_, __) => _reply('[]'));
      await LlmEvidencePort(llm: llm, maxChunkChars: 9)
          .extractFragments(text, 'text/plain');
      for (final chunk in llm.chunks) {
        expect(chunk.runes.length * 2, chunk.length);
      }
      expect(llm.chunks.join(), text);
    });

    test('units of all chunks come back in order with offsets in the whole',
        () async {
      final text = 'alpha one two three four\n\nbeta five six seven eight\n\n'
          'gamma nine ten eleven';
      final llm = _ScriptedLlm(_firstWord);
      final out = await LlmEvidencePort(llm: llm, maxChunkChars: 28)
          .extractFragments(text, 'text/plain');
      expect(out.map((f) => f.text), ['alpha', 'beta', 'gamma']);
      for (final f in out) {
        expect(text.substring(f.sourceOffset!, f.sourceOffset! + f.text.length),
            f.text);
      }
    });

    test('a repeated word is located in its own chunk', () async {
      final text = 'dup first part\n\nsecond dup part';
      final llm = _ScriptedLlm((call, _) => _reply('[${_unit('dup')}]'));
      final out = await LlmEvidencePort(llm: llm, maxChunkChars: 16)
          .extractFragments(text, 'text/plain');
      expect(out.map((f) => f.sourceOffset), [0, text.indexOf('dup', 5)]);
    });

    test('one failed chunk sends the whole input to the fallback', () async {
      final text = List.generate(40, (i) => 'word$i').join(' ');
      final llm = _ScriptedLlm((call, chunk) => call == 1
          ? _reply('[', finishReason: 'length')
          : _firstWord(call, chunk));
      final reasons = <Object>[];
      final out = await LlmEvidencePort(
              llm: llm, maxChunkChars: 60, onFallback: reasons.add)
          .extractFragments(text, 'text/plain');
      expect(reasons, hasLength(1));
      expect(out.map((f) => f.text), isNot(contains('word0')));
    });
  });
}
