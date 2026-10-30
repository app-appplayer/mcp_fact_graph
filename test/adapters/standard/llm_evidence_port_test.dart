/// Unit tests for [LlmEvidencePort]: structured extraction, validation of
/// the reply, and the heuristic fallback.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:test/test.dart';

class _Llm implements bundle.LlmPort {
  _Llm(this.reply, {this.failWith});

  final String reply;
  final Object? failWith;
  bundle.LlmRequest? last;

  @override
  bundle.LlmCapabilities get capabilities =>
      const bundle.LlmCapabilities.minimal();

  @override
  Future<bool> isAvailable() async => true;

  @override
  bool hasCapability(String capability) => capability == 'completion';

  @override
  Future<bundle.LlmResponse> complete(bundle.LlmRequest request) async {
    last = request;
    if (failWith != null) throw failWith!;
    return bundle.LlmResponse(content: reply);
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

const source = 'We will ship on Friday. Do not touch the billing code.';

void main() {
  test('reads a structured reply into fragments', () async {
    final llm = _Llm('''[
      {"text":"We will ship on Friday","verbatim":true,"kind":"decision",
       "confidence":0.9,"emphasis":false,"entityHints":["release"]},
      {"text":"Do not touch the billing code","verbatim":true,"emphasis":true,
       "kind":"task","confidence":0.8}
    ]''');
    final out = await LlmEvidencePort(llm: llm)
        .extractFragments(source, 'text/plain');
    expect(out, hasLength(2));
    expect(out[0].type, 'decision');
    expect(out[0].verbatim, isTrue);
    expect(out[0].sourceOffset, 0);
    expect(out[0].sourceLength, 'We will ship on Friday'.length);
    expect(out[0].entityHints, ['release']);
    expect(out[1].emphasis, isTrue);
    expect(out[1].sourceOffset, source.indexOf('Do not'));
  });

  test('asks for json at temperature 0 and sends the source', () async {
    final llm = _Llm('[]');
    await LlmEvidencePort(llm: llm).extractFragments(source, 'text/plain');
    expect(llm.last!.responseFormat, 'json');
    expect(llm.last!.temperature, 0);
    expect(llm.last!.prompt, contains(source));
    expect(llm.last!.systemPrompt, contains('decision'));
  });

  test('a verbatim claim not found in the source is lowered', () async {
    final llm = _Llm(
        '[{"text":"We will ship on Monday","verbatim":true,"kind":"decision","confidence":0.9}]');
    final out = await LlmEvidencePort(llm: llm)
        .extractFragments(source, 'text/plain');
    expect(out.single.verbatim, isFalse);
    expect(out.single.sourceOffset, isNull);
  });

  test('a model-supplied offset is ignored', () async {
    final llm = _Llm(
        '[{"text":"Do not touch the billing code","verbatim":true,"kind":"task","confidence":0.8,"sourceOffset":3}]');
    final out = await LlmEvidencePort(llm: llm)
        .extractFragments(source, 'text/plain');
    expect(out.single.sourceOffset, source.indexOf('Do not'));
  });

  test('drops units with empty text, unknown kind or no confidence', () async {
    final llm = _Llm('''[
      {"text":"  ","verbatim":false,"kind":"fact","confidence":0.5},
      {"text":"a","verbatim":false,"kind":"rumor","confidence":0.5},
      {"text":"b","verbatim":false,"kind":"fact"},
      {"text":"c","verbatim":false,"kind":"fact","confidence":"high"},
      "not an object",
      {"text":"keep","verbatim":false,"kind":"insight","confidence":0.4}
    ]''');
    final out = await LlmEvidencePort(llm: llm)
        .extractFragments(source, 'text/plain');
    expect(out.map((f) => f.text), ['keep']);
  });

  test('confidence is clamped to 0..1', () async {
    final llm = _Llm('''[
      {"text":"a","verbatim":false,"kind":"fact","confidence":7},
      {"text":"b","verbatim":false,"kind":"fact","confidence":-2}
    ]''');
    final out = await LlmEvidencePort(llm: llm)
        .extractFragments(source, 'text/plain');
    expect(out.map((f) => f.confidence), [1.0, 0.0]);
  });

  test('accepts a code-fenced reply and an object holding units', () async {
    final fenced = _Llm(
        '```json\n[{"text":"a","verbatim":false,"kind":"fact","confidence":0.5}]\n```');
    expect(
        await LlmEvidencePort(llm: fenced)
            .extractFragments(source, 'text/plain'),
        hasLength(1));
    final wrapped = _Llm(
        '{"units":[{"text":"a","verbatim":false,"kind":"fact","confidence":0.5}]}');
    expect(
        await LlmEvidencePort(llm: wrapped)
            .extractFragments(source, 'text/plain'),
        hasLength(1));
  });

  test('an empty list is a real answer, not a failure', () async {
    var fell = false;
    final out = await LlmEvidencePort(
      llm: _Llm('[]'),
      onFallback: (_) => fell = true,
    ).extractFragments(source, 'text/plain');
    expect(out, isEmpty);
    expect(fell, isFalse);
  });

  test('an unreadable reply falls back to the heuristic and reports it',
      () async {
    Object? reason;
    final out = await LlmEvidencePort(
      llm: _Llm('sorry, I cannot do that'),
      onFallback: (r) => reason = r,
    ).extractFragments(source, 'text/plain');
    expect(reason, isA<FormatException>());
    expect(out, isNotEmpty);
    expect(out.first.verbatim, isFalse);
  });

  test('an LLM error falls back and reports it', () async {
    Object? reason;
    final out = await LlmEvidencePort(
      llm: _Llm('', failWith: StateError('down')),
      onFallback: (r) => reason = r,
    ).extractFragments(source, 'text/plain');
    expect(reason, isA<StateError>());
    expect(out, isNotEmpty);
  });

  test('empty content makes no LLM call', () async {
    final llm = _Llm('[]');
    expect(await LlmEvidencePort(llm: llm).extractFragments('  ', 'text/plain'),
        isEmpty);
    expect(llm.last, isNull);
  });

  test('classification and confidence use the fallback', () async {
    final port = LlmEvidencePort(llm: _Llm('[]'));
    expect(await port.classifyFragment('Is it done?'),
        startsWith('intent:question'));
    expect(await port.computeConfidence(''), 0.0);
  });
}
