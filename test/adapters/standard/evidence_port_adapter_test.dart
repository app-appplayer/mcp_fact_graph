/// Unit tests for [EvidencePortAdapter] (standard) — MOD-INFRA-014.
///
/// C7. Classification returns `category:subtype` tokens with multi-
/// category composition via `;`. Existing basic extract/confidence
/// semantics are preserved.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/src/adapters/standard/evidence_port_adapter.dart';
import 'package:test/test.dart';

class _StubLlm implements bundle.LlmPort {
  _StubLlm(this.reply);

  final String reply;
  int calls = 0;

  @override
  bundle.LlmCapabilities get capabilities =>
      const bundle.LlmCapabilities.minimal();

  @override
  Future<bool> isAvailable() async => true;

  @override
  bool hasCapability(String capability) => capability == 'completion';

  @override
  Future<bundle.LlmResponse> complete(bundle.LlmRequest request) async {
    calls += 1;
    return bundle.LlmResponse(content: reply);
  }

  @override
  Stream<bundle.LlmChunk> completeStream(bundle.LlmRequest request) {
    throw UnsupportedError('not used');
  }

  @override
  Future<List<double>> embed(String text) {
    throw UnsupportedError('not used');
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) {
    throw UnsupportedError('not used');
  }

  @override
  Future<double> similarity(String text1, String text2) {
    throw UnsupportedError('not used');
  }

  @override
  Future<bundle.LlmResponse> completeWithTools(
    bundle.LlmRequest request,
    List<bundle.LlmTool> tools,
  ) {
    throw UnsupportedError('not used');
  }

  @override
  Future<bundle.LlmResponse> completeWithContext(
    bundle.LlmRequest request,
    dynamic context,
  ) {
    throw UnsupportedError('not used');
  }
}

void main() {
  group('EvidencePortAdapter (standard)', () {
    late EvidencePortAdapter adapter;

    setUp(() {
      adapter = EvidencePortAdapter();
    });

    test('extractFragments returns empty for empty content', () async {
      expect(
        await adapter.extractFragments('', 'text/plain'),
        isEmpty,
      );
    });

    test('extractFragments splits sentences on .!?', () async {
      final fragments = await adapter.extractFragments(
        'First sentence. Second one? Third one!',
        'text/plain',
      );
      expect(fragments, hasLength(3));
    });

    test('computeConfidence returns 0.0 for empty input', () async {
      expect(await adapter.computeConfidence(''), 0.0);
    });

    test('computeConfidence scales by word count', () async {
      final low = await adapter.computeConfidence('short');
      final high = await adapter.computeConfidence(
        'This is a longer fragment with many words indeed',
      );
      expect(low, lessThanOrEqualTo(high));
    });

    test('classifyFragment returns intent:unknown for empty', () async {
      expect(await adapter.classifyFragment('  '), 'intent:unknown');
    });

    test('classifyFragment flags intent:question for ?', () async {
      final label = await adapter.classifyFragment('Is this true?');
      expect(label.contains('intent:question'), isTrue);
    });

    test('classifyFragment flags domain:numeric for numbers', () async {
      final label = await adapter.classifyFragment('Price is 12500 won');
      expect(label.contains('domain:numeric'), isTrue);
      expect(label.contains('type:factual'), isTrue);
    });

    test('classifyFragment composes multiple categories', () async {
      final label = await adapter.classifyFragment('How much is 12500 won?');
      expect(label.contains('intent:question'), isTrue);
      expect(label.contains('domain:numeric'), isTrue);
    });

    test('classifyFragment flags intent:statement for sentences', () async {
      final label = await adapter.classifyFragment('Hello world.');
      expect(label.contains('intent:statement'), isTrue);
    });

    test('classifyFragment flags intent:command for imperatives', () async {
      final label = await adapter.classifyFragment('Please open the file');
      expect(label.contains('intent:command'), isTrue);
    });

    test('classifyFragment flags type:subjective for opinion words',
        () async {
      final label = await adapter.classifyFragment('I love this coffee');
      expect(label.contains('type:subjective'), isTrue);
    });

    test('classifyFragment flags domain:url', () async {
      final label = await adapter.classifyFragment(
        'See https://example.com for details.',
      );
      expect(label.contains('domain:url'), isTrue);
    });

    test('classifyFragment flags domain:email', () async {
      final label = await adapter.classifyFragment('Email me at a@b.co');
      expect(label.contains('domain:email'), isTrue);
    });

    test('classifyFragment flags domain:temporal for dates', () async {
      final label = await adapter.classifyFragment(
        'Meeting on 2026-04-14 at 10:30',
      );
      expect(label.contains('domain:temporal'), isTrue);
    });

    test('LLM fallback is invoked only when rule is intent:unknown',
        () async {
      final stub = _StubLlm('intent:opinion');
      final withLlm = EvidencePortAdapter(llm: stub);
      // This short lowercase token has no intent cue and no domain
      // markers, so rule resolves to intent:unknown and LLM is
      // consulted.
      final label = await withLlm.classifyFragment('hi');
      expect(stub.calls, 1);
      expect(label, 'intent:opinion');
    });

    test('LLM not invoked when rule already resolved', () async {
      final stub = _StubLlm('intent:opinion');
      final withLlm = EvidencePortAdapter(llm: stub);
      await withLlm.classifyFragment('Is this a test?');
      expect(stub.calls, 0);
    });
  });
}
