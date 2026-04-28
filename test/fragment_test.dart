import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('Fragment', () {
    test('creates fragment with required fields', () {
      final fragment = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-1',
        evidenceId: 'ev-1',
        fields: {'amount': 100.0},
        confidence: 0.95,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(fragment.fragmentId, equals('frag-1'));
      expect(fragment.evidenceId, equals('ev-1'));
      expect(fragment.fields['amount'], equals(100.0));
      expect(fragment.confidence, equals(0.95));
      expect(fragment.status, equals(FragmentStatus.proposed));
    });

    test('creates fragment with all fields', () {
      final fragment = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-2',
        evidenceId: 'ev-2',
        fields: {'date': '2024-01-15', 'amount': 50.0},
        confidence: 0.9,
        extractor: ExtractorType.llm,
        status: FragmentStatus.confirmed,
        createdAt: DateTime(2024, 1, 1),
        metadata: {'model': 'gpt-4'},
      );

      expect(fragment.fields['date'], equals('2024-01-15'));
      expect(fragment.extractor, equals(ExtractorType.llm));
      expect(fragment.status, equals(FragmentStatus.confirmed));
    });

    test('isHighConfidence returns correct value', () {
      final highConf = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-3',
        evidenceId: 'ev-1',
        fields: {'amount': 100},
        confidence: 0.95,
        createdAt: DateTime(2024, 1, 1),
      );

      final lowConf = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-4',
        evidenceId: 'ev-1',
        fields: {'amount': 100},
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(highConf.isHighConfidence, isTrue);
      expect(lowConf.isHighConfidence, isFalse);
    });

    test('isConfirmed returns correct value', () {
      final confirmed = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-5',
        evidenceId: 'ev-1',
        fields: {'test': 'value'},
        confidence: 0.9,
        status: FragmentStatus.confirmed,
        createdAt: DateTime(2024, 1, 1),
      );

      final proposed = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-6',
        evidenceId: 'ev-1',
        fields: {'test': 'value'},
        confidence: 0.9,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(confirmed.isConfirmed, isTrue);
      expect(proposed.isConfirmed, isFalse);
    });

    test('serializes and deserializes correctly', () {
      final original = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-7',
        evidenceId: 'ev-1',
        fields: {'merchant': 'Store ABC', 'amount': 25.0},
        confidence: 0.85,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = Fragment.fromJson(json);

      expect(restored.fragmentId, equals(original.fragmentId));
      expect(restored.fields['merchant'], equals('Store ABC'));
      expect(restored.confidence, equals(original.confidence));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final fragment = Fragment.fromJson(json);

      expect(fragment.fragmentId, equals(''));
      expect(fragment.workspaceId, equals('default'));
      expect(fragment.evidenceId, equals(''));
      expect(fragment.fields, isEmpty);
      expect(fragment.confidence, equals(0.0));
      expect(fragment.extractor, equals(ExtractorType.rule));
      expect(fragment.status, equals(FragmentStatus.proposed));
      expect(fragment.metadata, isEmpty);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'fragmentId': 'frag-full',
        'workspaceId': 'ws-1',
        'evidenceId': 'ev-full',
        'fields': {'amount': 42.0, 'date': '2024-01-01'},
        'confidence': 0.92,
        'extractor': 'ocr',
        'status': 'confirmed',
        'createdAt': '2024-06-15T10:00:00.000',
        'metadata': {'page': 1},
      };

      final fragment = Fragment.fromJson(json);

      expect(fragment.fragmentId, equals('frag-full'));
      expect(fragment.workspaceId, equals('ws-1'));
      expect(fragment.evidenceId, equals('ev-full'));
      expect(fragment.fields['amount'], equals(42.0));
      expect(fragment.confidence, equals(0.92));
      expect(fragment.extractor, equals(ExtractorType.ocr));
      expect(fragment.status, equals(FragmentStatus.confirmed));
      expect(fragment.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(fragment.metadata, equals({'page': 1}));
    });

    test('fromJson uses method field as fallback for extractor', () {
      final json = {
        'fragmentId': 'frag-method',
        'evidenceId': 'ev-1',
        'confidence': 0.5,
        'method': 'llm',
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final fragment = Fragment.fromJson(json);
      expect(fragment.extractor, equals(ExtractorType.llm));
    });

    test('toJson excludes empty fields and metadata', () {
      final fragment = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-min',
        evidenceId: 'ev-1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = fragment.toJson();

      expect(json.containsKey('fields'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json['fragmentId'], equals('frag-min'));
      expect(json['workspaceId'], equals('test-workspace'));
      expect(json['evidenceId'], equals('ev-1'));
      expect(json['confidence'], equals(0.5));
      expect(json['extractor'], equals('rule'));
      expect(json['status'], equals('proposed'));
    });

    test('toJson includes non-empty fields and metadata', () {
      final fragment = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-full-json',
        evidenceId: 'ev-1',
        fields: {'key': 'val'},
        confidence: 0.8,
        metadata: {'src': 'test'},
        createdAt: DateTime(2024, 1, 1),
      );

      final json = fragment.toJson();

      expect(json['fields'], equals({'key': 'val'}));
      expect(json['metadata'], equals({'src': 'test'}));
    });

    test('copyWith creates modified copy', () {
      final original = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-8',
        evidenceId: 'ev-1',
        fields: {'test': 'original'},
        confidence: 0.7,
        createdAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        fields: {'test': 'modified'},
        status: FragmentStatus.confirmed,
        confidence: 0.99,
      );

      expect(original.fields['test'], equals('original'));
      expect(modified.fields['test'], equals('modified'));
      expect(modified.status, equals(FragmentStatus.confirmed));
      expect(modified.confidence, equals(0.99));
    });

    test('copyWith all parameters', () {
      final original = Fragment(
        workspaceId: 'ws-1',
        fragmentId: 'frag-orig',
        evidenceId: 'ev-1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2024, 6, 1);
      final modified = original.copyWith(
        fragmentId: 'frag-new',
        workspaceId: 'ws-2',
        evidenceId: 'ev-2',
        fields: {'a': 1},
        confidence: 0.99,
        extractor: ExtractorType.manual,
        status: FragmentStatus.rejected,
        createdAt: newDate,
        metadata: {'x': true},
      );

      expect(modified.fragmentId, equals('frag-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.evidenceId, equals('ev-2'));
      expect(modified.fields, equals({'a': 1}));
      expect(modified.confidence, equals(0.99));
      expect(modified.extractor, equals(ExtractorType.manual));
      expect(modified.status, equals(FragmentStatus.rejected));
      expect(modified.createdAt, equals(newDate));
      expect(modified.metadata, equals({'x': true}));
    });

    test('toString returns expected format', () {
      final fragment = Fragment(
        workspaceId: 'test-workspace',
        fragmentId: 'frag-str',
        evidenceId: 'ev-1',
        confidence: 0.88,
        createdAt: DateTime(2024, 1, 1),
      );

      final str = fragment.toString();

      expect(str, contains('Fragment'));
      expect(str, contains('frag-str'));
      expect(str, contains('0.88'));
    });

    test('equality based on fragmentId', () {
      final frag1 = Fragment(
        workspaceId: 'ws-1',
        fragmentId: 'same-id',
        evidenceId: 'ev-1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );
      final frag2 = Fragment(
        workspaceId: 'ws-2',
        fragmentId: 'same-id',
        evidenceId: 'ev-2',
        confidence: 0.9,
        createdAt: DateTime(2024, 1, 1),
      );
      final frag3 = Fragment(
        workspaceId: 'ws-1',
        fragmentId: 'diff-id',
        evidenceId: 'ev-1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(frag1, equals(frag2));
      expect(frag1.hashCode, equals(frag2.hashCode));
      expect(frag1 == frag3, isFalse);
    });

    test('constructor defaults', () {
      final fragment = Fragment(
        fragmentId: 'frag-defaults',
        workspaceId: 'ws-1',
        evidenceId: 'ev-1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(fragment.fields, isEmpty);
      expect(fragment.extractor, equals(ExtractorType.rule));
      expect(fragment.status, equals(FragmentStatus.proposed));
      expect(fragment.metadata, isEmpty);
    });
  });

  group('ExtractorType', () {
    test('fromString parses correctly', () {
      expect(ExtractorType.fromString('rule'), equals(ExtractorType.rule));
      expect(ExtractorType.fromString('ocr'), equals(ExtractorType.ocr));
      expect(ExtractorType.fromString('llm'), equals(ExtractorType.llm));
      expect(ExtractorType.fromString('manual'), equals(ExtractorType.manual));
    });

    test('fromString returns rule for invalid', () {
      expect(ExtractorType.fromString('invalid'), equals(ExtractorType.rule));
    });
  });

  group('FragmentStatus', () {
    test('fromString parses correctly', () {
      expect(FragmentStatus.fromString('proposed'), equals(FragmentStatus.proposed));
      expect(FragmentStatus.fromString('confirmed'), equals(FragmentStatus.confirmed));
      expect(FragmentStatus.fromString('rejected'), equals(FragmentStatus.rejected));
    });

    test('fromString returns proposed for invalid', () {
      expect(FragmentStatus.fromString('invalid'), equals(FragmentStatus.proposed));
    });

    test('all status values accessible by name', () {
      expect(FragmentStatus.proposed.name, equals('proposed'));
      expect(FragmentStatus.confirmed.name, equals('confirmed'));
      expect(FragmentStatus.rejected.name, equals('rejected'));
    });

    test('fromString maps each value correctly', () {
      for (final status in FragmentStatus.values) {
        expect(FragmentStatus.fromString(status.name), equals(status));
      }
    });
  });

  // =========================================================================
  // Additional Fragment coverage
  // =========================================================================
  group('Fragment additional coverage', () {
    test('Fragment copyWith each field individually', () {
      final base = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );
      final newDate = DateTime(2025, 1, 1);

      expect(base.copyWith(fragmentId: 'x').fragmentId, equals('x'));
      expect(base.copyWith(workspaceId: 'x').workspaceId, equals('x'));
      expect(base.copyWith(evidenceId: 'x').evidenceId, equals('x'));
      expect(
        base.copyWith(fields: const {'a': 1}).fields,
        equals({'a': 1}),
      );
      expect(base.copyWith(confidence: 0.99).confidence, equals(0.99));
      expect(
        base.copyWith(extractor: ExtractorType.ocr).extractor,
        equals(ExtractorType.ocr),
      );
      expect(
        base.copyWith(status: FragmentStatus.rejected).status,
        equals(FragmentStatus.rejected),
      );
      expect(base.copyWith(createdAt: newDate).createdAt, equals(newDate));
      expect(
        base.copyWith(metadata: const {'m': 1}).metadata,
        equals({'m': 1}),
      );
    });

    test('Fragment copyWith with no args returns equivalent', () {
      final base = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        fields: const {'k': 'v'},
        confidence: 0.8,
        extractor: ExtractorType.llm,
        status: FragmentStatus.confirmed,
        metadata: const {'m': 1},
        createdAt: DateTime(2024, 1, 1),
      );

      final copy = base.copyWith();

      expect(copy.fragmentId, equals(base.fragmentId));
      expect(copy.workspaceId, equals(base.workspaceId));
      expect(copy.evidenceId, equals(base.evidenceId));
      expect(copy.fields, equals(base.fields));
      expect(copy.confidence, equals(base.confidence));
      expect(copy.extractor, equals(base.extractor));
      expect(copy.status, equals(base.status));
      expect(copy.createdAt, equals(base.createdAt));
      expect(copy.metadata, equals(base.metadata));
    });

    test('Fragment isHighConfidence boundary at 0.9', () {
      final atBoundary = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.9,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(atBoundary.isHighConfidence, isTrue);

      final belowBoundary = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.89,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(belowBoundary.isHighConfidence, isFalse);
    });

    test('Fragment isConfirmed for all statuses', () {
      for (final status in FragmentStatus.values) {
        final fragment = Fragment(
          fragmentId: 'f',
          workspaceId: 'ws',
          evidenceId: 'ev',
          confidence: 0.5,
          status: status,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(
          fragment.isConfirmed,
          equals(status == FragmentStatus.confirmed),
        );
      }
    });

    test('Fragment toString exact format', () {
      final fragment = Fragment(
        fragmentId: 'frag-abc',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.75,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(
        fragment.toString(),
        equals('Fragment(frag-abc, confidence: 0.75)'),
      );
    });

    test('Fragment equality with identical reference', () {
      final fragment = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(fragment == fragment, isTrue);
    });

    test('Fragment equality with non-Fragment object', () {
      final fragment = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(fragment == Object(), isFalse);
    });

    test('Fragment hashCode based on fragmentId', () {
      final f1 = Fragment(
        fragmentId: 'same',
        workspaceId: 'ws1',
        evidenceId: 'ev1',
        confidence: 0.5,
        createdAt: DateTime(2024, 1, 1),
      );
      final f2 = Fragment(
        fragmentId: 'same',
        workspaceId: 'ws2',
        evidenceId: 'ev2',
        confidence: 0.9,
        createdAt: DateTime(2024, 6, 1),
      );
      expect(f1.hashCode, equals(f2.hashCode));
    });

    test('Fragment fromJson with createdAt null uses DateTime.now()', () {
      final before = DateTime.now();
      final fragment = Fragment.fromJson({
        'fragmentId': 'f',
        'createdAt': null,
      });
      final after = DateTime.now();

      expect(
        fragment.createdAt
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        fragment.createdAt
            .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('Fragment fromJson with createdAt present', () {
      final fragment = Fragment.fromJson({
        'fragmentId': 'f',
        'createdAt': '2024-06-15T10:00:00.000',
      });
      expect(fragment.createdAt, equals(DateTime(2024, 6, 15, 10)));
    });

    test('Fragment toJson includes createdAt as ISO8601 string', () {
      final date = DateTime(2024, 3, 15, 12, 30);
      final fragment = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.5,
        createdAt: date,
      );
      final json = fragment.toJson();
      expect(json['createdAt'], equals(date.toIso8601String()));
    });

    test('Fragment toJson status and extractor as name strings', () {
      final fragment = Fragment(
        fragmentId: 'f',
        workspaceId: 'ws',
        evidenceId: 'ev',
        confidence: 0.5,
        extractor: ExtractorType.manual,
        status: FragmentStatus.rejected,
        createdAt: DateTime(2024, 1, 1),
      );
      final json = fragment.toJson();
      expect(json['extractor'], equals('manual'));
      expect(json['status'], equals('rejected'));
    });

    test('Fragment with all ExtractorType values via fromJson', () {
      for (final ext in ExtractorType.values) {
        final fragment = Fragment.fromJson({
          'fragmentId': 'f',
          'extractor': ext.name,
          'createdAt': '2024-01-01T00:00:00.000',
        });
        expect(fragment.extractor, equals(ext));
      }
    });

    test('Fragment with all FragmentStatus values via fromJson', () {
      for (final status in FragmentStatus.values) {
        final fragment = Fragment.fromJson({
          'fragmentId': 'f',
          'status': status.name,
          'createdAt': '2024-01-01T00:00:00.000',
        });
        expect(fragment.status, equals(status));
      }
    });

    test('Fragment fromJson with null fields uses defaults', () {
      final fragment = Fragment.fromJson({
        'fragmentId': null,
        'workspaceId': null,
        'evidenceId': null,
        'fields': null,
        'confidence': null,
        'extractor': null,
        'status': null,
        'createdAt': null,
        'metadata': null,
      });

      expect(fragment.fragmentId, equals(''));
      expect(fragment.workspaceId, equals('default'));
      expect(fragment.evidenceId, equals(''));
      expect(fragment.fields, isEmpty);
      expect(fragment.confidence, equals(0.0));
      expect(fragment.extractor, equals(ExtractorType.rule));
      expect(fragment.status, equals(FragmentStatus.proposed));
      expect(fragment.metadata, isEmpty);
    });
  });

  // =========================================================================
  // ExtractorType enum value coverage
  // =========================================================================
  group('ExtractorType enum values', () {
    test('all values accessible by name', () {
      expect(ExtractorType.rule.name, equals('rule'));
      expect(ExtractorType.ocr.name, equals('ocr'));
      expect(ExtractorType.llm.name, equals('llm'));
      expect(ExtractorType.manual.name, equals('manual'));
    });

    test('fromString maps each value correctly', () {
      for (final ext in ExtractorType.values) {
        expect(ExtractorType.fromString(ext.name), equals(ext));
      }
    });
  });
}
