import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  group('Evidence', () {
    test('creates evidence with required fields', () {
      final evidence = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-1',
        sourceType: EvidenceSourceType.text,
        content: 'Test content',
        contentHash: 'abc123',
        source: const SourceMetadata(name: 'test'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      expect(evidence.evidenceId, equals('ev-1'));
      expect(evidence.sourceType, equals(EvidenceSourceType.text));
      expect(evidence.content, equals('Test content'));
      expect(evidence.status, equals(EvidenceStatus.pending));
    });

    test('creates evidence with all fields', () {
      final evidence = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-2',
        sourceType: EvidenceSourceType.image,
        content: 'Receipt data',
        contentHash: 'hash123',
        mimeType: 'image/jpeg',
        source: const SourceMetadata(
          name: 'Camera',
          uri: 'file://photo.jpg',
          reliability: 0.9,
        ),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
        status: EvidenceStatus.extracted,
        fragmentIds: ['frag-1', 'frag-2'],
        metadata: {'device': 'iPhone'},
      );

      expect(evidence.mimeType, equals('image/jpeg'));
      expect(evidence.status, equals(EvidenceStatus.extracted));
      expect(evidence.fragmentIds.length, equals(2));
      expect(evidence.source.reliability, equals(0.9));
    });

    test('serializes and deserializes correctly', () {
      final original = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-3',
        sourceType: EvidenceSourceType.file,
        content: 'Doc content',
        contentHash: 'hash456',
        source: const SourceMetadata(name: 'upload'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = Evidence.fromJson(json);

      expect(restored.evidenceId, equals(original.evidenceId));
      expect(restored.sourceType, equals(original.sourceType));
      expect(restored.content, equals(original.content));
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final evidence = Evidence.fromJson(json);

      expect(evidence.evidenceId, equals(''));
      expect(evidence.workspaceId, equals('default'));
      expect(evidence.sourceType, equals(EvidenceSourceType.text));
      expect(evidence.content, equals(''));
      expect(evidence.contentHash, equals(''));
      expect(evidence.mimeType, isNull);
      expect(evidence.sourceRef, isNull);
      expect(evidence.contentRef, isNull);
      expect(evidence.timestamp, isNull);
      expect(evidence.author, isNull);
      expect(evidence.status, equals(EvidenceStatus.pending));
      expect(evidence.fragmentIds, isEmpty);
      expect(evidence.metadata, isEmpty);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'evidenceId': 'ev-full',
        'workspaceId': 'ws-1',
        'sourceType': 'image',
        'content': 'base64data',
        'contentHash': 'hash-full',
        'mimeType': 'image/png',
        'source': {'name': 'Camera', 'uri': 'file://photo.png', 'reliability': 0.95},
        'sourceRef': 'https://example.com/photo.png',
        'contentRef': 'blob://storage/photo.png',
        'timestamp': '2024-03-15T14:30:00.000',
        'author': 'John Doe',
        'createdAt': '2024-03-15T14:00:00.000',
        'ingestedAt': '2024-03-15T14:01:00.000',
        'status': 'extracted',
        'fragmentIds': ['frag-1', 'frag-2'],
        'metadata': {'device': 'iPhone 15'},
      };

      final evidence = Evidence.fromJson(json);

      expect(evidence.evidenceId, equals('ev-full'));
      expect(evidence.workspaceId, equals('ws-1'));
      expect(evidence.sourceType, equals(EvidenceSourceType.image));
      expect(evidence.content, equals('base64data'));
      expect(evidence.contentHash, equals('hash-full'));
      expect(evidence.mimeType, equals('image/png'));
      expect(evidence.sourceRef, equals('https://example.com/photo.png'));
      expect(evidence.contentRef, equals('blob://storage/photo.png'));
      expect(evidence.timestamp, equals(DateTime(2024, 3, 15, 14, 30)));
      expect(evidence.author, equals('John Doe'));
      expect(evidence.status, equals(EvidenceStatus.extracted));
      expect(evidence.fragmentIds, equals(['frag-1', 'frag-2']));
      expect(evidence.metadata, equals({'device': 'iPhone 15'}));
    });

    test('toJson excludes null and empty fields', () {
      final evidence = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-min',
        sourceType: EvidenceSourceType.text,
        content: 'text',
        contentHash: 'hash',
        source: const SourceMetadata(name: 'test'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      final json = evidence.toJson();

      expect(json.containsKey('mimeType'), isFalse);
      expect(json.containsKey('sourceRef'), isFalse);
      expect(json.containsKey('contentRef'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('author'), isFalse);
      expect(json.containsKey('fragmentIds'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes non-null and non-empty fields', () {
      final evidence = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-full-json',
        sourceType: EvidenceSourceType.image,
        content: 'data',
        contentHash: 'hash',
        mimeType: 'image/jpeg',
        source: const SourceMetadata(name: 'test'),
        sourceRef: 'https://example.com',
        contentRef: 'blob://key',
        timestamp: DateTime(2024, 3, 15),
        author: 'Admin',
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
        fragmentIds: ['frag-1'],
        metadata: {'key': 'val'},
      );

      final json = evidence.toJson();

      expect(json['mimeType'], equals('image/jpeg'));
      expect(json['sourceRef'], equals('https://example.com'));
      expect(json['contentRef'], equals('blob://key'));
      expect(json['timestamp'], equals(DateTime(2024, 3, 15).toIso8601String()));
      expect(json['author'], equals('Admin'));
      expect(json['fragmentIds'], equals(['frag-1']));
      expect(json['metadata'], equals({'key': 'val'}));
    });

    test('copyWith creates modified copy', () {
      final original = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-4',
        sourceType: EvidenceSourceType.text,
        content: 'Original',
        contentHash: 'hash',
        source: const SourceMetadata(name: 'test'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        status: EvidenceStatus.extracted,
        fragmentIds: ['frag-1'],
      );

      expect(original.status, equals(EvidenceStatus.pending));
      expect(modified.status, equals(EvidenceStatus.extracted));
      expect(modified.fragmentIds, contains('frag-1'));
    });

    test('copyWith all parameters', () {
      final original = Evidence(
        workspaceId: 'ws-1',
        evidenceId: 'ev-orig',
        sourceType: EvidenceSourceType.text,
        content: 'orig',
        contentHash: 'hash-orig',
        source: const SourceMetadata(name: 'orig'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2024, 6, 1);
      final modified = original.copyWith(
        evidenceId: 'ev-new',
        workspaceId: 'ws-2',
        sourceType: EvidenceSourceType.api,
        content: 'new-content',
        contentHash: 'hash-new',
        mimeType: 'application/json',
        source: const SourceMetadata(name: 'new-source'),
        sourceRef: 'ref://new',
        contentRef: 'blob://new',
        timestamp: newDate,
        author: 'Admin',
        createdAt: newDate,
        ingestedAt: newDate,
        status: EvidenceStatus.archived,
        fragmentIds: ['frag-x'],
        metadata: {'new': true},
      );

      expect(modified.evidenceId, equals('ev-new'));
      expect(modified.workspaceId, equals('ws-2'));
      expect(modified.sourceType, equals(EvidenceSourceType.api));
      expect(modified.content, equals('new-content'));
      expect(modified.contentHash, equals('hash-new'));
      expect(modified.mimeType, equals('application/json'));
      expect(modified.source.name, equals('new-source'));
      expect(modified.sourceRef, equals('ref://new'));
      expect(modified.contentRef, equals('blob://new'));
      expect(modified.timestamp, equals(newDate));
      expect(modified.author, equals('Admin'));
      expect(modified.status, equals(EvidenceStatus.archived));
      expect(modified.fragmentIds, equals(['frag-x']));
      expect(modified.metadata, equals({'new': true}));
    });

    test('copyWith preserves status and fragmentIds when not specified', () {
      final original = Evidence(
        workspaceId: 'ws-1',
        evidenceId: 'ev-preserve',
        sourceType: EvidenceSourceType.api,
        content: 'API data',
        contentHash: 'hash-api',
        source: const SourceInfo(name: 'api-source'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
        status: EvidenceStatus.extracted,
        fragmentIds: ['frag-a', 'frag-b'],
      );

      // Only change content, preserving status and fragmentIds
      final copy = original.copyWith(content: 'Updated API data');

      expect(copy.content, equals('Updated API data'));
      expect(copy.status, equals(EvidenceStatus.extracted));
      expect(copy.fragmentIds, equals(['frag-a', 'frag-b']));
      expect(copy.evidenceId, equals('ev-preserve'));
    });

    test('toString returns expected format', () {
      final evidence = Evidence(
        workspaceId: 'test-workspace',
        evidenceId: 'ev-str',
        sourceType: EvidenceSourceType.message,
        content: 'msg',
        contentHash: 'hash',
        source: const SourceMetadata(name: 'test'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      final str = evidence.toString();

      expect(str, contains('Evidence'));
      expect(str, contains('ev-str'));
      expect(str, contains('message'));
    });

    test('equality based on evidenceId', () {
      final ev1 = Evidence(
        workspaceId: 'ws-1',
        evidenceId: 'same-id',
        sourceType: EvidenceSourceType.text,
        content: 'a',
        contentHash: 'h1',
        source: const SourceMetadata(name: 'a'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );
      final ev2 = Evidence(
        workspaceId: 'ws-2',
        evidenceId: 'same-id',
        sourceType: EvidenceSourceType.image,
        content: 'b',
        contentHash: 'h2',
        source: const SourceMetadata(name: 'b'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );
      final ev3 = Evidence(
        workspaceId: 'ws-1',
        evidenceId: 'diff-id',
        sourceType: EvidenceSourceType.text,
        content: 'a',
        contentHash: 'h1',
        source: const SourceMetadata(name: 'a'),
        createdAt: DateTime(2024, 1, 1),
        ingestedAt: DateTime(2024, 1, 1),
      );

      expect(ev1, equals(ev2));
      expect(ev1.hashCode, equals(ev2.hashCode));
      expect(ev1 == ev3, isFalse);
    });
  });

  group('EvidenceSourceType', () {
    test('fromString parses correctly', () {
      expect(EvidenceSourceType.fromString('text'), equals(EvidenceSourceType.text));
      expect(EvidenceSourceType.fromString('image'), equals(EvidenceSourceType.image));
      expect(EvidenceSourceType.fromString('file'), equals(EvidenceSourceType.file));
      expect(EvidenceSourceType.fromString('message'), equals(EvidenceSourceType.message));
      expect(EvidenceSourceType.fromString('api'), equals(EvidenceSourceType.api));
    });

    test('fromString returns text for invalid', () {
      expect(EvidenceSourceType.fromString('invalid'), equals(EvidenceSourceType.text));
    });
  });

  group('EvidenceStatus', () {
    test('fromString parses correctly', () {
      expect(EvidenceStatus.fromString('pending'), equals(EvidenceStatus.pending));
      expect(EvidenceStatus.fromString('processing'), equals(EvidenceStatus.processing));
      expect(EvidenceStatus.fromString('extracted'), equals(EvidenceStatus.extracted));
      expect(EvidenceStatus.fromString('failed'), equals(EvidenceStatus.failed));
      expect(EvidenceStatus.fromString('archived'), equals(EvidenceStatus.archived));
    });

    test('fromString returns pending for invalid', () {
      expect(EvidenceStatus.fromString('invalid'), equals(EvidenceStatus.pending));
    });
  });

  group('SourceMetadata', () {
    test('creates metadata with required fields', () {
      const meta = SourceMetadata(name: 'Test Source');

      expect(meta.name, equals('Test Source'));
      expect(meta.uri, isNull);
      expect(meta.reliability, isNull);
      expect(meta.type, isNull);
      expect(meta.capturedAt, isNull);
    });

    test('creates metadata with all fields', () {
      final meta = SourceMetadata(
        name: 'Full Source',
        uri: 'https://example.com',
        type: 'web',
        capturedAt: DateTime(2024, 1, 1),
        reliability: 0.95,
        attributes: {'key': 'value'},
      );

      expect(meta.uri, equals('https://example.com'));
      expect(meta.type, equals('web'));
      expect(meta.reliability, equals(0.95));
      expect(meta.capturedAt, equals(DateTime(2024, 1, 1)));
      expect(meta.attributes, equals({'key': 'value'}));
    });

    test('serializes and deserializes correctly', () {
      const original = SourceMetadata(
        name: 'Test',
        uri: 'file://test.txt',
        reliability: 0.8,
      );

      final json = original.toJson();
      final restored = SourceMetadata.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.uri, equals(original.uri));
      expect(restored.reliability, equals(original.reliability));
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final meta = SourceMetadata.fromJson(json);

      expect(meta.name, equals(''));
      expect(meta.uri, isNull);
      expect(meta.type, isNull);
      expect(meta.capturedAt, isNull);
      expect(meta.reliability, isNull);
    });
  });
}
