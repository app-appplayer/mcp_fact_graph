import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // ArtifactType enum tests
  // =========================================================================
  group('ArtifactType', () {
    test('has all expected values', () {
      expect(ArtifactType.values, contains(ArtifactType.report));
      expect(ArtifactType.values, contains(ArtifactType.export));
      expect(ArtifactType.values, contains(ArtifactType.snapshot));
      expect(ArtifactType.values.length, equals(3));
    });

    test('fromString valid values', () {
      expect(ArtifactType.fromString('report'), equals(ArtifactType.report));
      expect(ArtifactType.fromString('export'), equals(ArtifactType.export));
      expect(ArtifactType.fromString('snapshot'), equals(ArtifactType.snapshot));
    });

    test('fromString is case-insensitive', () {
      expect(ArtifactType.fromString('REPORT'), equals(ArtifactType.report));
      expect(ArtifactType.fromString('Export'), equals(ArtifactType.export));
      expect(ArtifactType.fromString('SNAPSHOT'), equals(ArtifactType.snapshot));
    });

    test('fromString invalid returns default (report)', () {
      expect(ArtifactType.fromString('unknown'), equals(ArtifactType.report));
      expect(ArtifactType.fromString(''), equals(ArtifactType.report));
      expect(ArtifactType.fromString('invalid'), equals(ArtifactType.report));
    });
  });

  // =========================================================================
  // GenerationContext tests
  // =========================================================================
  group('GenerationContext', () {
    test('constructor with required fields only', () {
      final asOf = DateTime(2024, 6, 15);
      final ctx = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        queryHash: 'abc123',
      );

      expect(ctx.asOf, equals(asOf));
      expect(ctx.policyVersion, equals('v1.0'));
      expect(ctx.queryHash, equals('abc123'));
      expect(ctx.inputViewIds, isEmpty);
      expect(ctx.inputEventIds, isEmpty);
      expect(ctx.params, isEmpty);
    });

    test('constructor with all fields', () {
      final asOf = DateTime(2024, 6, 15);
      final ctx = GenerationContext(
        asOf: asOf,
        policyVersion: 'v2.0',
        inputViewIds: ['view-1', 'view-2'],
        inputEventIds: ['event-1'],
        params: {'limit': 100},
        queryHash: 'hash456',
      );

      expect(ctx.asOf, equals(asOf));
      expect(ctx.policyVersion, equals('v2.0'));
      expect(ctx.inputViewIds, equals(['view-1', 'view-2']));
      expect(ctx.inputEventIds, equals(['event-1']));
      expect(ctx.params, equals({'limit': 100}));
      expect(ctx.queryHash, equals('hash456'));
    });

    test('fromJson complete', () {
      final json = {
        'asOf': '2024-06-15T10:00:00.000',
        'policyVersion': 'v1.0',
        'inputViewIds': ['view-1'],
        'inputEventIds': ['event-1', 'event-2'],
        'params': {'key': 'value'},
        'queryHash': 'xyz789',
      };

      final ctx = GenerationContext.fromJson(json);

      expect(ctx.asOf, equals(DateTime(2024, 6, 15, 10)));
      expect(ctx.policyVersion, equals('v1.0'));
      expect(ctx.inputViewIds, equals(['view-1']));
      expect(ctx.inputEventIds, equals(['event-1', 'event-2']));
      expect(ctx.params, equals({'key': 'value'}));
      expect(ctx.queryHash, equals('xyz789'));
    });

    test('fromJson empty/missing fields', () {
      final ctx = GenerationContext.fromJson(<String, dynamic>{});

      // asOf defaults to DateTime.now() - just verify it's a DateTime
      expect(ctx.asOf, isA<DateTime>());
      expect(ctx.policyVersion, equals(''));
      expect(ctx.inputViewIds, isEmpty);
      expect(ctx.inputEventIds, isEmpty);
      expect(ctx.params, isEmpty);
      expect(ctx.queryHash, equals(''));
    });

    test('fromJson with null asOf falls back to DateTime.now()', () {
      final ctx = GenerationContext.fromJson({'asOf': null});
      expect(ctx.asOf, isA<DateTime>());
    });

    test('toJson populated', () {
      final asOf = DateTime(2024, 6, 15, 10);
      final ctx = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        inputViewIds: ['view-1'],
        inputEventIds: ['event-1'],
        params: {'limit': 50},
        queryHash: 'hash123',
      );

      final json = ctx.toJson();

      expect(json['asOf'], equals(asOf.toIso8601String()));
      expect(json['policyVersion'], equals('v1.0'));
      expect(json['inputViewIds'], equals(['view-1']));
      expect(json['inputEventIds'], equals(['event-1']));
      expect(json['params'], equals({'limit': 50}));
      expect(json['queryHash'], equals('hash123'));
    });

    test('toJson excludes empty lists and maps', () {
      final asOf = DateTime(2024, 6, 15);
      final ctx = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        queryHash: 'hash123',
      );

      final json = ctx.toJson();

      expect(json.containsKey('inputViewIds'), isFalse);
      expect(json.containsKey('inputEventIds'), isFalse);
      expect(json.containsKey('params'), isFalse);
      expect(json.containsKey('asOf'), isTrue);
      expect(json.containsKey('policyVersion'), isTrue);
      expect(json.containsKey('queryHash'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final asOf = DateTime(2024, 6, 15);
      final original = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        inputViewIds: ['view-1'],
        inputEventIds: ['event-1'],
        params: {'key': 'val'},
        queryHash: 'hash1',
      );

      final newAsOf = DateTime(2024, 7, 1);
      final copy = original.copyWith(
        asOf: newAsOf,
        policyVersion: 'v2.0',
        queryHash: 'hash2',
      );

      expect(copy.asOf, equals(newAsOf));
      expect(copy.policyVersion, equals('v2.0'));
      expect(copy.queryHash, equals('hash2'));
      // Unchanged fields remain
      expect(copy.inputViewIds, equals(['view-1']));
      expect(copy.inputEventIds, equals(['event-1']));
      expect(copy.params, equals({'key': 'val'}));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final asOf = DateTime(2024, 6, 15);
      final original = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        queryHash: 'hash1',
      );

      final copy = original.copyWith();

      expect(copy.asOf, equals(original.asOf));
      expect(copy.policyVersion, equals(original.policyVersion));
      expect(copy.queryHash, equals(original.queryHash));
      expect(copy.inputViewIds, equals(original.inputViewIds));
      expect(copy.inputEventIds, equals(original.inputEventIds));
      expect(copy.params, equals(original.params));
    });

    test('copyWith replaces all fields', () {
      final asOf = DateTime(2024, 6, 15);
      final original = GenerationContext(
        asOf: asOf,
        policyVersion: 'v1.0',
        queryHash: 'hash1',
      );

      final newAsOf = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        asOf: newAsOf,
        policyVersion: 'v3.0',
        inputViewIds: ['v-new'],
        inputEventIds: ['e-new'],
        params: {'new': true},
        queryHash: 'newhash',
      );

      expect(copy.asOf, equals(newAsOf));
      expect(copy.policyVersion, equals('v3.0'));
      expect(copy.inputViewIds, equals(['v-new']));
      expect(copy.inputEventIds, equals(['e-new']));
      expect(copy.params, equals({'new': true}));
      expect(copy.queryHash, equals('newhash'));
    });
  });

  // =========================================================================
  // Artifact tests
  // =========================================================================
  group('Artifact', () {
    final baseContext = GenerationContext(
      asOf: DateTime(2024, 6, 15),
      policyVersion: 'v1.0',
      queryHash: 'hash123',
    );

    test('constructor with required fields only', () {
      final now = DateTime(2024, 6, 15);
      final artifact = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.report,
        format: 'json',
        contentRef: 'ref-123',
        context: baseContext,
        createdAt: now,
      );

      expect(artifact.artifactId, equals('art-1'));
      expect(artifact.type, equals(ArtifactType.report));
      expect(artifact.format, equals('json'));
      expect(artifact.contentRef, equals('ref-123'));
      expect(artifact.sizeBytes, equals(0));
      expect(artifact.title, isNull);
      expect(artifact.meta, isEmpty);
      expect(artifact.context, equals(baseContext));
      expect(artifact.workspaceId, isNull);
      expect(artifact.createdAt, equals(now));
      expect(artifact.expiresAt, isNull);
    });

    test('constructor with all fields', () {
      final now = DateTime(2024, 6, 15);
      final expires = DateTime(2025, 6, 15);
      final artifact = Artifact(
        artifactId: 'art-2',
        type: ArtifactType.export,
        format: 'csv',
        contentRef: 'ref-456',
        sizeBytes: 2048,
        title: 'Monthly Export',
        meta: {'generated_by': 'system'},
        context: baseContext,
        workspaceId: 'ws-1',
        createdAt: now,
        expiresAt: expires,
      );

      expect(artifact.artifactId, equals('art-2'));
      expect(artifact.type, equals(ArtifactType.export));
      expect(artifact.format, equals('csv'));
      expect(artifact.contentRef, equals('ref-456'));
      expect(artifact.sizeBytes, equals(2048));
      expect(artifact.title, equals('Monthly Export'));
      expect(artifact.meta, equals({'generated_by': 'system'}));
      expect(artifact.workspaceId, equals('ws-1'));
      expect(artifact.createdAt, equals(now));
      expect(artifact.expiresAt, equals(expires));
    });

    test('fromJson complete', () {
      final json = {
        'artifactId': 'art-1',
        'type': 'export',
        'format': 'csv',
        'contentRef': 'ref-123',
        'sizeBytes': 4096,
        'title': 'Test Artifact',
        'meta': {'source': 'test'},
        'context': {
          'asOf': '2024-06-15T00:00:00.000',
          'policyVersion': 'v1.0',
          'inputViewIds': ['v1'],
          'queryHash': 'qh1',
        },
        'workspaceId': 'ws-1',
        'createdAt': '2024-06-15T12:00:00.000',
        'expiresAt': '2025-06-15T12:00:00.000',
      };

      final artifact = Artifact.fromJson(json);

      expect(artifact.artifactId, equals('art-1'));
      expect(artifact.type, equals(ArtifactType.export));
      expect(artifact.format, equals('csv'));
      expect(artifact.contentRef, equals('ref-123'));
      expect(artifact.sizeBytes, equals(4096));
      expect(artifact.title, equals('Test Artifact'));
      expect(artifact.meta, equals({'source': 'test'}));
      expect(artifact.context.policyVersion, equals('v1.0'));
      expect(artifact.context.inputViewIds, equals(['v1']));
      expect(artifact.workspaceId, equals('ws-1'));
      expect(artifact.createdAt, equals(DateTime(2024, 6, 15, 12)));
      expect(artifact.expiresAt, equals(DateTime(2025, 6, 15, 12)));
    });

    test('fromJson empty/missing fields', () {
      final artifact = Artifact.fromJson(<String, dynamic>{});

      expect(artifact.artifactId, equals(''));
      expect(artifact.type, equals(ArtifactType.report));
      expect(artifact.format, equals('json'));
      expect(artifact.contentRef, equals(''));
      expect(artifact.sizeBytes, equals(0));
      expect(artifact.title, isNull);
      expect(artifact.meta, isEmpty);
      // context should be created with defaults
      expect(artifact.context.policyVersion, equals(''));
      expect(artifact.context.queryHash, equals(''));
      expect(artifact.workspaceId, isNull);
      expect(artifact.createdAt, isA<DateTime>());
      expect(artifact.expiresAt, isNull);
    });

    test('fromJson with null context creates default context', () {
      final artifact = Artifact.fromJson({'context': null});
      expect(artifact.context, isA<GenerationContext>());
      expect(artifact.context.policyVersion, equals(''));
    });

    test('toJson populated', () {
      final now = DateTime(2024, 6, 15, 10);
      final expires = DateTime(2025, 1, 1);
      final ctx = GenerationContext(
        asOf: DateTime(2024, 6, 15),
        policyVersion: 'v1.0',
        inputViewIds: ['v1'],
        queryHash: 'qh',
      );
      final artifact = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.snapshot,
        format: 'html',
        contentRef: 'ref-1',
        sizeBytes: 512,
        title: 'Snapshot Title',
        meta: {'key': 'value'},
        context: ctx,
        workspaceId: 'ws-1',
        createdAt: now,
        expiresAt: expires,
      );

      final json = artifact.toJson();

      expect(json['artifactId'], equals('art-1'));
      expect(json['type'], equals('snapshot'));
      expect(json['format'], equals('html'));
      expect(json['contentRef'], equals('ref-1'));
      expect(json['sizeBytes'], equals(512));
      expect(json['title'], equals('Snapshot Title'));
      expect(json['meta'], equals({'key': 'value'}));
      expect(json['context'], isA<Map>());
      expect(json['workspaceId'], equals('ws-1'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['expiresAt'], equals(expires.toIso8601String()));
    });

    test('toJson excludes null and empty fields', () {
      final now = DateTime(2024, 6, 15);
      final artifact = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.report,
        format: 'json',
        contentRef: 'ref-1',
        context: baseContext,
        createdAt: now,
      );

      final json = artifact.toJson();

      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('meta'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      expect(json.containsKey('expiresAt'), isFalse);
      // Always-present fields
      expect(json.containsKey('artifactId'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('format'), isTrue);
      expect(json.containsKey('contentRef'), isTrue);
      expect(json.containsKey('sizeBytes'), isTrue);
      expect(json.containsKey('context'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
    });

    test('copyWith modifies selected fields', () {
      final now = DateTime(2024, 6, 15);
      final original = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.report,
        format: 'json',
        contentRef: 'ref-1',
        context: baseContext,
        createdAt: now,
      );

      final copy = original.copyWith(
        artifactId: 'art-2',
        type: ArtifactType.export,
        format: 'csv',
        sizeBytes: 1024,
        title: 'New Title',
        workspaceId: 'ws-new',
      );

      expect(copy.artifactId, equals('art-2'));
      expect(copy.type, equals(ArtifactType.export));
      expect(copy.format, equals('csv'));
      expect(copy.sizeBytes, equals(1024));
      expect(copy.title, equals('New Title'));
      expect(copy.workspaceId, equals('ws-new'));
      // Unchanged fields
      expect(copy.contentRef, equals('ref-1'));
      expect(copy.context, equals(baseContext));
      expect(copy.createdAt, equals(now));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final now = DateTime(2024, 6, 15);
      final original = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.report,
        format: 'json',
        contentRef: 'ref-1',
        context: baseContext,
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.artifactId, equals(original.artifactId));
      expect(copy.type, equals(original.type));
      expect(copy.format, equals(original.format));
      expect(copy.contentRef, equals(original.contentRef));
      expect(copy.sizeBytes, equals(original.sizeBytes));
      expect(copy.title, equals(original.title));
      expect(copy.meta, equals(original.meta));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.expiresAt, equals(original.expiresAt));
    });

    test('copyWith replaces all fields', () {
      final now = DateTime(2024, 6, 15);
      final original = Artifact(
        artifactId: 'art-1',
        type: ArtifactType.report,
        format: 'json',
        contentRef: 'ref-1',
        context: baseContext,
        createdAt: now,
      );

      final newCtx = GenerationContext(
        asOf: DateTime(2025, 1, 1),
        policyVersion: 'v9',
        queryHash: 'new',
      );
      final newCreated = DateTime(2025, 2, 1);
      final newExpires = DateTime(2026, 1, 1);

      final copy = original.copyWith(
        artifactId: 'art-new',
        type: ArtifactType.snapshot,
        format: 'pdf',
        contentRef: 'ref-new',
        sizeBytes: 9999,
        title: 'All New',
        meta: {'new': true},
        context: newCtx,
        workspaceId: 'ws-new',
        createdAt: newCreated,
        expiresAt: newExpires,
      );

      expect(copy.artifactId, equals('art-new'));
      expect(copy.type, equals(ArtifactType.snapshot));
      expect(copy.format, equals('pdf'));
      expect(copy.contentRef, equals('ref-new'));
      expect(copy.sizeBytes, equals(9999));
      expect(copy.title, equals('All New'));
      expect(copy.meta, equals({'new': true}));
      expect(copy.context, equals(newCtx));
      expect(copy.workspaceId, equals('ws-new'));
      expect(copy.createdAt, equals(newCreated));
      expect(copy.expiresAt, equals(newExpires));
    });

    // -----------------------------------------------------------------------
    // Boolean getters
    // -----------------------------------------------------------------------
    group('isExpired getter', () {
      test('returns false when expiresAt is null', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.isExpired, isFalse);
      });

      test('returns true when expiresAt is in the past', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
          expiresAt: DateTime(2020, 1, 1),
        );
        expect(artifact.isExpired, isTrue);
      });

      test('returns false when expiresAt is in the future', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
          expiresAt: DateTime(2099, 12, 31),
        );
        expect(artifact.isExpired, isFalse);
      });
    });

    group('isValid getter', () {
      test('returns true when not expired (no expiresAt)', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.isValid, isTrue);
      });

      test('returns false when expired', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
          expiresAt: DateTime(2020, 1, 1),
        );
        expect(artifact.isValid, isFalse);
      });
    });

    group('type check getters', () {
      test('isReport returns true for report type', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.isReport, isTrue);
        expect(artifact.isExport, isFalse);
        expect(artifact.isSnapshot, isFalse);
      });

      test('isExport returns true for export type', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.export,
          format: 'csv',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.isReport, isFalse);
        expect(artifact.isExport, isTrue);
        expect(artifact.isSnapshot, isFalse);
      });

      test('isSnapshot returns true for snapshot type', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.snapshot,
          format: 'html',
          contentRef: 'ref-1',
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.isReport, isFalse);
        expect(artifact.isExport, isFalse);
        expect(artifact.isSnapshot, isTrue);
      });
    });

    group('humanReadableSize getter', () {
      test('returns bytes for small sizes', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 500,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('500 B'));
      });

      test('returns bytes for zero', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 0,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('0 B'));
      });

      test('returns KB for kilobyte range', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 2048,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('2.0 KB'));
      });

      test('returns MB for megabyte range', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 5 * 1024 * 1024,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('5.0 MB'));
      });

      test('returns GB for gigabyte range', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 2 * 1024 * 1024 * 1024,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('2.0 GB'));
      });

      test('returns KB at exact boundary (1024)', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 1024,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('1.0 KB'));
      });

      test('returns bytes just below KB boundary', () {
        final artifact = Artifact(
          artifactId: 'art-1',
          type: ArtifactType.report,
          format: 'json',
          contentRef: 'ref-1',
          sizeBytes: 1023,
          context: baseContext,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(artifact.humanReadableSize, equals('1023 B'));
      });
    });
  });

  // =========================================================================
  // ArtifactFormat constants tests
  // =========================================================================
  group('ArtifactFormat', () {
    test('json constant', () {
      expect(ArtifactFormat.json, equals('json'));
    });

    test('markdown constant', () {
      expect(ArtifactFormat.markdown, equals('markdown'));
    });

    test('html constant', () {
      expect(ArtifactFormat.html, equals('html'));
    });

    test('pdf constant', () {
      expect(ArtifactFormat.pdf, equals('pdf'));
    });

    test('csv constant', () {
      expect(ArtifactFormat.csv, equals('csv'));
    });

    test('xlsx constant', () {
      expect(ArtifactFormat.xlsx, equals('xlsx'));
    });
  });
}
