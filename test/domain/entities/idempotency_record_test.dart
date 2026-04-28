import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // IdempotencyStatus enum tests
  // =========================================================================
  group('IdempotencyStatus', () {
    test('has all expected values', () {
      expect(IdempotencyStatus.values, contains(IdempotencyStatus.pending));
      expect(IdempotencyStatus.values, contains(IdempotencyStatus.completed));
      expect(IdempotencyStatus.values, contains(IdempotencyStatus.failed));
      expect(IdempotencyStatus.values.length, equals(3));
    });

    test('fromString valid values', () {
      expect(IdempotencyStatus.fromString('pending'),
          equals(IdempotencyStatus.pending));
      expect(IdempotencyStatus.fromString('completed'),
          equals(IdempotencyStatus.completed));
      expect(IdempotencyStatus.fromString('failed'),
          equals(IdempotencyStatus.failed));
    });

    test('fromString is case-insensitive', () {
      expect(IdempotencyStatus.fromString('PENDING'),
          equals(IdempotencyStatus.pending));
      expect(IdempotencyStatus.fromString('Completed'),
          equals(IdempotencyStatus.completed));
      expect(IdempotencyStatus.fromString('FAILED'),
          equals(IdempotencyStatus.failed));
    });

    test('fromString invalid returns default (pending)', () {
      expect(IdempotencyStatus.fromString('unknown'),
          equals(IdempotencyStatus.pending));
      expect(
          IdempotencyStatus.fromString(''), equals(IdempotencyStatus.pending));
      expect(IdempotencyStatus.fromString('invalid'),
          equals(IdempotencyStatus.pending));
    });
  });

  // =========================================================================
  // IdempotencyRecord tests
  // =========================================================================
  group('IdempotencyRecord', () {
    final now = DateTime(2024, 6, 15, 10);

    test('constructor with required fields only', () {
      final record = IdempotencyRecord(
        key: 'job-1:2024-06-15',
        createdAt: now,
      );

      expect(record.key, equals('job-1:2024-06-15'));
      expect(record.createdAt, equals(now));
      expect(record.expiresAt, isNull);
      expect(record.resultRef, isNull);
      expect(record.status, equals(IdempotencyStatus.pending));
      expect(record.operationType, isNull);
      expect(record.metadata, isNull);
    });

    test('constructor with all fields', () {
      final expires = DateTime(2024, 6, 16, 10);
      final record = IdempotencyRecord(
        key: 'op-1:hash123',
        createdAt: now,
        expiresAt: expires,
        resultRef: 'result-ref-1',
        status: IdempotencyStatus.completed,
        operationType: 'ingest',
        metadata: {'source': 'api'},
      );

      expect(record.key, equals('op-1:hash123'));
      expect(record.createdAt, equals(now));
      expect(record.expiresAt, equals(expires));
      expect(record.resultRef, equals('result-ref-1'));
      expect(record.status, equals(IdempotencyStatus.completed));
      expect(record.operationType, equals('ingest'));
      expect(record.metadata, equals({'source': 'api'}));
    });

    test('fromJson complete', () {
      final json = {
        'key': 'user-1:req-abc',
        'createdAt': '2024-06-15T10:00:00.000',
        'expiresAt': '2024-06-16T10:00:00.000',
        'resultRef': 'res-1',
        'status': 'completed',
        'operationType': 'extract',
        'metadata': {'attempt': 1},
      };

      final record = IdempotencyRecord.fromJson(json);

      expect(record.key, equals('user-1:req-abc'));
      expect(record.createdAt, equals(DateTime(2024, 6, 15, 10)));
      expect(record.expiresAt, equals(DateTime(2024, 6, 16, 10)));
      expect(record.resultRef, equals('res-1'));
      expect(record.status, equals(IdempotencyStatus.completed));
      expect(record.operationType, equals('extract'));
      expect(record.metadata, equals({'attempt': 1}));
    });

    test('fromJson empty/missing fields', () {
      final record = IdempotencyRecord.fromJson(<String, dynamic>{});

      expect(record.key, equals(''));
      expect(record.createdAt, isA<DateTime>());
      expect(record.expiresAt, isNull);
      expect(record.resultRef, isNull);
      expect(record.status, equals(IdempotencyStatus.pending));
      expect(record.operationType, isNull);
      expect(record.metadata, isNull);
    });

    test('fromJson with null datetime fields', () {
      final record = IdempotencyRecord.fromJson({
        'createdAt': null,
        'expiresAt': null,
      });
      expect(record.createdAt, isA<DateTime>());
      expect(record.expiresAt, isNull);
    });

    test('toJson populated', () {
      final expires = DateTime(2024, 6, 16, 10);
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
        expiresAt: expires,
        resultRef: 'ref-1',
        status: IdempotencyStatus.failed,
        operationType: 'classify',
        metadata: {'error': 'timeout'},
      );

      final json = record.toJson();

      expect(json['key'], equals('key-1'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['expiresAt'], equals(expires.toIso8601String()));
      expect(json['resultRef'], equals('ref-1'));
      expect(json['status'], equals('failed'));
      expect(json['operationType'], equals('classify'));
      expect(json['metadata'], equals({'error': 'timeout'}));
    });

    test('toJson excludes null fields', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final json = record.toJson();

      expect(json.containsKey('key'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('expiresAt'), isFalse);
      expect(json.containsKey('resultRef'), isFalse);
      expect(json.containsKey('operationType'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('copyWith modifies selected fields', () {
      final original = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final copy = original.copyWith(
        status: IdempotencyStatus.completed,
        resultRef: 'new-ref',
      );

      expect(copy.key, equals('key-1'));
      expect(copy.createdAt, equals(now));
      expect(copy.status, equals(IdempotencyStatus.completed));
      expect(copy.resultRef, equals('new-ref'));
    });

    test('copyWith with no arguments returns equivalent object', () {
      final original = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.key, equals(original.key));
      expect(copy.createdAt, equals(original.createdAt));
      expect(copy.expiresAt, equals(original.expiresAt));
      expect(copy.resultRef, equals(original.resultRef));
      expect(copy.status, equals(original.status));
      expect(copy.operationType, equals(original.operationType));
      expect(copy.metadata, equals(original.metadata));
    });

    test('copyWith replaces all fields', () {
      final original = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final newDate = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        key: 'key-new',
        createdAt: newDate,
        expiresAt: newDate,
        resultRef: 'ref-new',
        status: IdempotencyStatus.failed,
        operationType: 'new-op',
        metadata: {'new': true},
      );

      expect(copy.key, equals('key-new'));
      expect(copy.createdAt, equals(newDate));
      expect(copy.expiresAt, equals(newDate));
      expect(copy.resultRef, equals('ref-new'));
      expect(copy.status, equals(IdempotencyStatus.failed));
      expect(copy.operationType, equals('new-op'));
      expect(copy.metadata, equals({'new': true}));
    });

    // -----------------------------------------------------------------------
    // Boolean getters
    // -----------------------------------------------------------------------
    group('isExpired getter', () {
      test('returns false when expiresAt is null', () {
        final record = IdempotencyRecord(
          key: 'key-1',
          createdAt: now,
        );
        expect(record.isExpired, isFalse);
      });

      test('returns true when expiresAt is in the past', () {
        final record = IdempotencyRecord(
          key: 'key-1',
          createdAt: now,
          expiresAt: DateTime(2020, 1, 1),
        );
        expect(record.isExpired, isTrue);
      });

      test('returns false when expiresAt is in the future', () {
        final record = IdempotencyRecord(
          key: 'key-1',
          createdAt: now,
          expiresAt: DateTime(2099, 12, 31),
        );
        expect(record.isExpired, isFalse);
      });
    });

    group('isValid getter', () {
      test('returns true when not expired', () {
        final record = IdempotencyRecord(
          key: 'key-1',
          createdAt: now,
        );
        expect(record.isValid, isTrue);
      });

      test('returns false when expired', () {
        final record = IdempotencyRecord(
          key: 'key-1',
          createdAt: now,
          expiresAt: DateTime(2020, 1, 1),
        );
        expect(record.isValid, isFalse);
      });
    });

    test('isCompleted returns true when completed', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
        status: IdempotencyStatus.completed,
      );
      expect(record.isCompleted, isTrue);
      expect(record.isPending, isFalse);
      expect(record.isFailed, isFalse);
    });

    test('isPending returns true when pending', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
        status: IdempotencyStatus.pending,
      );
      expect(record.isPending, isTrue);
      expect(record.isCompleted, isFalse);
      expect(record.isFailed, isFalse);
    });

    test('isFailed returns true when failed', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
        status: IdempotencyStatus.failed,
      );
      expect(record.isFailed, isTrue);
      expect(record.isCompleted, isFalse);
      expect(record.isPending, isFalse);
    });

    // -----------------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------------
    test('complete() marks record as completed', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final completed = record.complete(resultRef: 'result-123');

      expect(completed.status, equals(IdempotencyStatus.completed));
      expect(completed.resultRef, equals('result-123'));
      expect(completed.key, equals('key-1'));
      expect(completed.createdAt, equals(now));
    });

    test('complete() without resultRef', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final completed = record.complete();

      expect(completed.status, equals(IdempotencyStatus.completed));
      expect(completed.resultRef, isNull);
    });

    test('fail() marks record as failed', () {
      final record = IdempotencyRecord(
        key: 'key-1',
        createdAt: now,
      );

      final failed = record.fail();

      expect(failed.status, equals(IdempotencyStatus.failed));
      expect(failed.key, equals('key-1'));
      expect(failed.createdAt, equals(now));
    });
  });

  // =========================================================================
  // IdempotencyKeyStrategy tests
  // =========================================================================
  group('IdempotencyKeyStrategy', () {
    test('timeBased constant', () {
      expect(IdempotencyKeyStrategy.timeBased, equals('time-based'));
    });

    test('contentBased constant', () {
      expect(IdempotencyKeyStrategy.contentBased, equals('content-based'));
    });

    test('requestBased constant', () {
      expect(IdempotencyKeyStrategy.requestBased, equals('request-based'));
    });

    test('generateTimeBased creates correct key', () {
      final timestamp = DateTime(2024, 6, 15, 14, 30);
      final key =
          IdempotencyKeyStrategy.generateTimeBased('job-1', timestamp);
      expect(key, equals('job-1:2024-06-15'));
    });

    test('generateTimeBased handles different dates', () {
      final timestamp = DateTime(2025, 1, 1);
      final key =
          IdempotencyKeyStrategy.generateTimeBased('daily-job', timestamp);
      expect(key, equals('daily-job:2025-01-01'));
    });

    test('generateContentBased creates correct key', () {
      final key = IdempotencyKeyStrategy.generateContentBased(
          'ingest', 'sha256abc');
      expect(key, equals('ingest:sha256abc'));
    });

    test('generateContentBased with empty values', () {
      final key = IdempotencyKeyStrategy.generateContentBased('', '');
      expect(key, equals(':'));
    });

    test('generateRequestBased creates correct key', () {
      final key =
          IdempotencyKeyStrategy.generateRequestBased('user-1', 'req-abc');
      expect(key, equals('user-1:req-abc'));
    });

    test('generateRequestBased with different inputs', () {
      final key = IdempotencyKeyStrategy.generateRequestBased(
          'admin', 'request-12345');
      expect(key, equals('admin:request-12345'));
    });
  });
}
