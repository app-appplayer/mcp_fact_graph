import 'package:test/test.dart';
// Import run.dart directly to access Period (hidden in barrel export)
import 'package:mcp_fact_graph/src/domain/entities/run.dart';

void main() {
  // =========================================================================
  // RunStatus enum tests
  // =========================================================================
  group('RunStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(RunStatus.fromString('running'), equals(RunStatus.running));
      expect(RunStatus.fromString('success'), equals(RunStatus.success));
      expect(RunStatus.fromString('failed'), equals(RunStatus.failed));
      expect(RunStatus.fromString('skipped'), equals(RunStatus.skipped));
    });

    test('fromString is case-insensitive (toLowerCase)', () {
      expect(RunStatus.fromString('RUNNING'), equals(RunStatus.running));
      expect(RunStatus.fromString('Success'), equals(RunStatus.success));
      expect(RunStatus.fromString('FAILED'), equals(RunStatus.failed));
      expect(RunStatus.fromString('Skipped'), equals(RunStatus.skipped));
    });

    test('fromString returns running for invalid value', () {
      expect(RunStatus.fromString('unknown'), equals(RunStatus.running));
      expect(RunStatus.fromString(''), equals(RunStatus.running));
      expect(RunStatus.fromString('pending'), equals(RunStatus.running));
    });

    test('has all expected values', () {
      expect(RunStatus.values, hasLength(4));
      expect(RunStatus.values, contains(RunStatus.running));
      expect(RunStatus.values, contains(RunStatus.success));
      expect(RunStatus.values, contains(RunStatus.failed));
      expect(RunStatus.values, contains(RunStatus.skipped));
    });
  });

  // =========================================================================
  // Period tests (from run.dart)
  // =========================================================================
  group('Period (run.dart)', () {
    test('constructor with required fields', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, equals(DateTime(2024, 1, 31)));
      expect(period.type, isNull);
    });

    test('constructor with all fields', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        type: 'month',
      );

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, equals(DateTime(2024, 1, 31)));
      expect(period.type, equals('month'));
    });

    test('fromJson with complete data', () {
      final json = {
        'start': '2024-01-01T00:00:00.000',
        'end': '2024-01-31T00:00:00.000',
        'type': 'month',
      };
      final period = Period.fromJson(json);

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, equals(DateTime(2024, 1, 31)));
      expect(period.type, equals('month'));
    });

    test('fromJson without type', () {
      final json = {
        'start': '2024-01-01T00:00:00.000',
        'end': '2024-01-31T00:00:00.000',
      };
      final period = Period.fromJson(json);

      expect(period.type, isNull);
    });

    test('toJson with type populated', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        type: 'week',
      );
      final json = period.toJson();

      expect(json['start'], equals(DateTime(2024, 1, 1).toIso8601String()));
      expect(json['end'], equals(DateTime(2024, 1, 31).toIso8601String()));
      expect(json['type'], equals('week'));
    });

    test('toJson excludes null type', () {
      final period = Period(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );
      final json = period.toJson();

      expect(json.containsKey('type'), isFalse);
    });
  });

  // =========================================================================
  // LogEntry tests
  // =========================================================================
  group('LogEntry', () {
    test('constructor with required fields', () {
      final ts = DateTime(2024, 1, 15, 10, 30);
      final entry = LogEntry(
        timestamp: ts,
        level: 'info',
        message: 'Processing started',
      );

      expect(entry.timestamp, equals(ts));
      expect(entry.level, equals('info'));
      expect(entry.message, equals('Processing started'));
    });

    test('fromJson with complete data', () {
      final json = {
        'timestamp': '2024-01-15T10:30:00.000',
        'level': 'error',
        'message': 'Connection failed',
      };
      final entry = LogEntry.fromJson(json);

      expect(entry.timestamp, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(entry.level, equals('error'));
      expect(entry.message, equals('Connection failed'));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final entry = LogEntry.fromJson({});
      final after = DateTime.now();

      expect(
        entry.timestamp
            .isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        entry.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(entry.level, equals('info'));
      expect(entry.message, equals(''));
    });

    test('fromJson with null fields uses defaults', () {
      final entry = LogEntry.fromJson({
        'timestamp': null,
        'level': null,
        'message': null,
      });

      expect(entry.level, equals('info'));
      expect(entry.message, equals(''));
    });

    test('toJson produces correct output', () {
      final ts = DateTime(2024, 1, 15, 10, 30);
      final entry = LogEntry(
        timestamp: ts,
        level: 'warn',
        message: 'Low memory',
      );
      final json = entry.toJson();

      expect(json['timestamp'], equals(ts.toIso8601String()));
      expect(json['level'], equals('warn'));
      expect(json['message'], equals('Low memory'));
    });
  });

  // =========================================================================
  // RunInput tests
  // =========================================================================
  group('RunInput', () {
    test('constructor with required fields only', () {
      final asOf = DateTime(2024, 6, 15);
      final input = RunInput(
        asOf: asOf,
        policyVersion: 'v1.0',
      );

      expect(input.asOf, equals(asOf));
      expect(input.period, isNull);
      expect(input.scope, isNull);
      expect(input.policyVersion, equals('v1.0'));
      expect(input.inputViewIds, isEmpty);
      expect(input.inputEventIds, isEmpty);
      expect(input.params, isEmpty);
    });

    test('constructor with all fields', () {
      final asOf = DateTime(2024, 6, 15);
      final period = Period(
        start: DateTime(2024, 6, 1),
        end: DateTime(2024, 6, 30),
        type: 'month',
      );
      final input = RunInput(
        asOf: asOf,
        period: period,
        scope: 'project-alpha',
        policyVersion: 'v2.0',
        inputViewIds: ['view-1', 'view-2'],
        inputEventIds: ['evt-1'],
        params: {'threshold': 0.8},
      );

      expect(input.asOf, equals(asOf));
      expect(input.period, isNotNull);
      expect(input.period!.type, equals('month'));
      expect(input.scope, equals('project-alpha'));
      expect(input.policyVersion, equals('v2.0'));
      expect(input.inputViewIds, equals(['view-1', 'view-2']));
      expect(input.inputEventIds, equals(['evt-1']));
      expect(input.params['threshold'], equals(0.8));
    });

    test('fromJson with complete data', () {
      final json = {
        'asOf': '2024-06-15T00:00:00.000',
        'period': {
          'start': '2024-06-01T00:00:00.000',
          'end': '2024-06-30T00:00:00.000',
          'type': 'month',
        },
        'scope': 'global',
        'policyVersion': 'v1.0',
        'inputViewIds': ['view-1'],
        'inputEventIds': ['evt-1', 'evt-2'],
        'params': {'key': 'value'},
      };
      final input = RunInput.fromJson(json);

      expect(input.asOf, equals(DateTime(2024, 6, 15)));
      expect(input.period, isNotNull);
      expect(input.period!.type, equals('month'));
      expect(input.scope, equals('global'));
      expect(input.policyVersion, equals('v1.0'));
      expect(input.inputViewIds, equals(['view-1']));
      expect(input.inputEventIds, equals(['evt-1', 'evt-2']));
      expect(input.params['key'], equals('value'));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final input = RunInput.fromJson({});
      final after = DateTime.now();

      expect(
        input.asOf.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        input.asOf.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(input.period, isNull);
      expect(input.scope, isNull);
      expect(input.policyVersion, equals(''));
      expect(input.inputViewIds, isEmpty);
      expect(input.inputEventIds, isEmpty);
      expect(input.params, isEmpty);
    });

    test('fromJson with null optional fields', () {
      final input = RunInput.fromJson({
        'asOf': '2024-01-01T00:00:00.000',
        'period': null,
        'scope': null,
        'policyVersion': null,
        'inputViewIds': null,
        'inputEventIds': null,
        'params': null,
      });

      expect(input.period, isNull);
      expect(input.scope, isNull);
      expect(input.policyVersion, equals(''));
      expect(input.inputViewIds, isEmpty);
      expect(input.inputEventIds, isEmpty);
      expect(input.params, isEmpty);
    });

    test('toJson with fully populated input', () {
      final input = RunInput(
        asOf: DateTime(2024, 6, 15),
        period: Period(
          start: DateTime(2024, 6, 1),
          end: DateTime(2024, 6, 30),
        ),
        scope: 'global',
        policyVersion: 'v1.0',
        inputViewIds: ['view-1'],
        inputEventIds: ['evt-1'],
        params: {'key': 'value'},
      );
      final json = input.toJson();

      expect(json['asOf'], equals(DateTime(2024, 6, 15).toIso8601String()));
      expect(json['period'], isA<Map>());
      expect(json['scope'], equals('global'));
      expect(json['policyVersion'], equals('v1.0'));
      expect(json['inputViewIds'], equals(['view-1']));
      expect(json['inputEventIds'], equals(['evt-1']));
      expect(json['params'], equals({'key': 'value'}));
    });

    test('toJson excludes empty/null fields', () {
      final input = RunInput(
        asOf: DateTime(2024, 6, 15),
        policyVersion: 'v1.0',
      );
      final json = input.toJson();

      expect(json.containsKey('period'), isFalse);
      expect(json.containsKey('scope'), isFalse);
      expect(json.containsKey('inputViewIds'), isFalse);
      expect(json.containsKey('inputEventIds'), isFalse);
      expect(json.containsKey('params'), isFalse);
    });

    test('copyWith modifies specified fields', () {
      final original = RunInput(
        asOf: DateTime(2024, 6, 15),
        policyVersion: 'v1.0',
        scope: 'global',
      );
      final newAsOf = DateTime(2025, 1, 1);
      final copy = original.copyWith(
        asOf: newAsOf,
        policyVersion: 'v2.0',
        inputViewIds: ['view-new'],
      );

      expect(copy.asOf, equals(newAsOf));
      expect(copy.policyVersion, equals('v2.0'));
      expect(copy.inputViewIds, equals(['view-new']));
      // Unchanged
      expect(copy.scope, equals('global'));
      expect(copy.period, isNull);
      expect(copy.inputEventIds, isEmpty);
      expect(copy.params, isEmpty);
    });

    test('copyWith with no arguments returns equivalent input', () {
      final original = RunInput(
        asOf: DateTime(2024, 6, 15),
        policyVersion: 'v1.0',
      );
      final copy = original.copyWith();

      expect(copy.asOf, equals(original.asOf));
      expect(copy.policyVersion, equals(original.policyVersion));
    });

    test('copyWith all fields', () {
      final original = RunInput(
        asOf: DateTime(2024, 6, 15),
        policyVersion: 'v1.0',
      );
      final newPeriod = Period(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 1, 31),
      );
      final copy = original.copyWith(
        asOf: DateTime(2025, 1, 1),
        period: newPeriod,
        scope: 'new-scope',
        policyVersion: 'v9',
        inputViewIds: ['v1'],
        inputEventIds: ['e1'],
        params: {'a': 1},
      );

      expect(copy.asOf, equals(DateTime(2025, 1, 1)));
      expect(copy.period, isNotNull);
      expect(copy.scope, equals('new-scope'));
      expect(copy.policyVersion, equals('v9'));
      expect(copy.inputViewIds, equals(['v1']));
      expect(copy.inputEventIds, equals(['e1']));
      expect(copy.params, equals({'a': 1}));
    });
  });

  // =========================================================================
  // RunOutput tests
  // =========================================================================
  group('RunOutput', () {
    test('constructor with default fields', () {
      const output = RunOutput();

      expect(output.createdViewIds, isEmpty);
      expect(output.createdArtifactIds, isEmpty);
      expect(output.modifiedEventIds, isEmpty);
      expect(output.metrics, isEmpty);
    });

    test('constructor with all fields', () {
      const output = RunOutput(
        createdViewIds: ['view-1', 'view-2'],
        createdArtifactIds: ['art-1'],
        modifiedEventIds: ['evt-1'],
        metrics: {'processed': 100, 'duration_ms': 500},
      );

      expect(output.createdViewIds, equals(['view-1', 'view-2']));
      expect(output.createdArtifactIds, equals(['art-1']));
      expect(output.modifiedEventIds, equals(['evt-1']));
      expect(output.metrics['processed'], equals(100));
    });

    test('fromJson with complete data', () {
      final json = {
        'createdViewIds': ['view-1'],
        'createdArtifactIds': ['art-1', 'art-2'],
        'modifiedEventIds': ['evt-1'],
        'metrics': {'count': 5},
      };
      final output = RunOutput.fromJson(json);

      expect(output.createdViewIds, equals(['view-1']));
      expect(output.createdArtifactIds, equals(['art-1', 'art-2']));
      expect(output.modifiedEventIds, equals(['evt-1']));
      expect(output.metrics['count'], equals(5));
    });

    test('fromJson with empty map uses defaults', () {
      final output = RunOutput.fromJson({});

      expect(output.createdViewIds, isEmpty);
      expect(output.createdArtifactIds, isEmpty);
      expect(output.modifiedEventIds, isEmpty);
      expect(output.metrics, isEmpty);
    });

    test('fromJson with null fields uses defaults', () {
      final output = RunOutput.fromJson({
        'createdViewIds': null,
        'createdArtifactIds': null,
        'modifiedEventIds': null,
        'metrics': null,
      });

      expect(output.createdViewIds, isEmpty);
      expect(output.createdArtifactIds, isEmpty);
      expect(output.modifiedEventIds, isEmpty);
      expect(output.metrics, isEmpty);
    });

    test('toJson with populated fields', () {
      const output = RunOutput(
        createdViewIds: ['view-1'],
        createdArtifactIds: ['art-1'],
        modifiedEventIds: ['evt-1'],
        metrics: {'count': 5},
      );
      final json = output.toJson();

      expect(json['createdViewIds'], equals(['view-1']));
      expect(json['createdArtifactIds'], equals(['art-1']));
      expect(json['modifiedEventIds'], equals(['evt-1']));
      expect(json['metrics'], equals({'count': 5}));
    });

    test('toJson excludes empty fields', () {
      const output = RunOutput();
      final json = output.toJson();

      expect(json.containsKey('createdViewIds'), isFalse);
      expect(json.containsKey('createdArtifactIds'), isFalse);
      expect(json.containsKey('modifiedEventIds'), isFalse);
      expect(json.containsKey('metrics'), isFalse);
    });

    test('copyWith modifies specified fields', () {
      const original = RunOutput(
        createdViewIds: ['view-1'],
        metrics: {'old': 1},
      );
      final copy = original.copyWith(
        createdViewIds: ['view-2', 'view-3'],
        createdArtifactIds: ['art-new'],
      );

      expect(copy.createdViewIds, equals(['view-2', 'view-3']));
      expect(copy.createdArtifactIds, equals(['art-new']));
      // Unchanged
      expect(copy.modifiedEventIds, isEmpty);
      expect(copy.metrics, equals({'old': 1}));
    });

    test('copyWith with no arguments returns equivalent output', () {
      const original = RunOutput(createdViewIds: ['v1']);
      final copy = original.copyWith();

      expect(copy.createdViewIds, equals(original.createdViewIds));
    });

    test('copyWith all fields', () {
      const original = RunOutput();
      final copy = original.copyWith(
        createdViewIds: ['v1'],
        createdArtifactIds: ['a1'],
        modifiedEventIds: ['e1'],
        metrics: {'x': 1},
      );

      expect(copy.createdViewIds, equals(['v1']));
      expect(copy.createdArtifactIds, equals(['a1']));
      expect(copy.modifiedEventIds, equals(['e1']));
      expect(copy.metrics, equals({'x': 1}));
    });
  });

  // =========================================================================
  // Run tests
  // =========================================================================
  group('Run', () {
    final fixedStart = DateTime(2024, 6, 15, 10, 0);
    final fixedFinish = DateTime(2024, 6, 15, 10, 5);

    Run createFullRun() {
      return Run(
        runId: 'run-1',
        jobId: 'job-1',
        startedAt: fixedStart,
        finishedAt: fixedFinish,
        status: RunStatus.success,
        idempotencyKey: 'idem-key-1',
        input: RunInput(
          asOf: fixedStart,
          policyVersion: 'v1.0',
          scope: 'global',
          inputViewIds: ['view-1'],
          inputEventIds: ['evt-1'],
          params: {'threshold': 0.5},
        ),
        output: const RunOutput(
          createdViewIds: ['view-out-1'],
          createdArtifactIds: ['art-1'],
          metrics: {'processed': 10},
        ),
        logs: [
          LogEntry(
            timestamp: fixedStart,
            level: 'info',
            message: 'Run started',
          ),
        ],
        artifacts: ['artifact-1', 'artifact-2'],
        errorMessage: null,
        workspaceId: 'ws-1',
      );
    }

    test('constructor with required fields only', () {
      final run = Run(
        runId: 'run-1',
        jobId: 'job-1',
        startedAt: fixedStart,
        idempotencyKey: 'key-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1.0'),
      );

      expect(run.runId, equals('run-1'));
      expect(run.jobId, equals('job-1'));
      expect(run.startedAt, equals(fixedStart));
      expect(run.finishedAt, isNull);
      expect(run.status, equals(RunStatus.running));
      expect(run.idempotencyKey, equals('key-1'));
      expect(run.input.policyVersion, equals('v1.0'));
      expect(run.output, isNull);
      expect(run.logs, isEmpty);
      expect(run.artifacts, isEmpty);
      expect(run.errorMessage, isNull);
      expect(run.workspaceId, isNull);
    });

    test('constructor with all fields', () {
      final run = createFullRun();

      expect(run.runId, equals('run-1'));
      expect(run.jobId, equals('job-1'));
      expect(run.startedAt, equals(fixedStart));
      expect(run.finishedAt, equals(fixedFinish));
      expect(run.status, equals(RunStatus.success));
      expect(run.idempotencyKey, equals('idem-key-1'));
      expect(run.input.scope, equals('global'));
      expect(run.output, isNotNull);
      expect(run.output!.createdViewIds, equals(['view-out-1']));
      expect(run.logs, hasLength(1));
      expect(run.artifacts, equals(['artifact-1', 'artifact-2']));
      expect(run.errorMessage, isNull);
      expect(run.workspaceId, equals('ws-1'));
    });

    test('fromJson with complete data', () {
      final json = {
        'runId': 'run-1',
        'jobId': 'job-1',
        'startedAt': '2024-06-15T10:00:00.000',
        'finishedAt': '2024-06-15T10:05:00.000',
        'status': 'success',
        'idempotencyKey': 'idem-1',
        'input': {
          'asOf': '2024-06-15T10:00:00.000',
          'policyVersion': 'v1.0',
          'scope': 'global',
        },
        'output': {
          'createdViewIds': ['view-1'],
          'metrics': {'count': 5},
        },
        'logs': [
          {
            'timestamp': '2024-06-15T10:00:00.000',
            'level': 'info',
            'message': 'Started',
          },
        ],
        'artifacts': ['art-1'],
        'errorMessage': 'Some error',
        'workspaceId': 'ws-1',
      };
      final run = Run.fromJson(json);

      expect(run.runId, equals('run-1'));
      expect(run.jobId, equals('job-1'));
      expect(run.startedAt, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(run.finishedAt, equals(DateTime(2024, 6, 15, 10, 5)));
      expect(run.status, equals(RunStatus.success));
      expect(run.idempotencyKey, equals('idem-1'));
      expect(run.input.scope, equals('global'));
      expect(run.output, isNotNull);
      expect(run.output!.createdViewIds, equals(['view-1']));
      expect(run.logs, hasLength(1));
      expect(run.logs[0].level, equals('info'));
      expect(run.artifacts, equals(['art-1']));
      expect(run.errorMessage, equals('Some error'));
      expect(run.workspaceId, equals('ws-1'));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final run = Run.fromJson({});
      final after = DateTime.now();

      expect(run.runId, equals(''));
      expect(run.jobId, equals(''));
      expect(
        run.startedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        run.startedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(run.finishedAt, isNull);
      expect(run.status, equals(RunStatus.running));
      expect(run.idempotencyKey, equals(''));
      expect(run.input.policyVersion, equals(''));
      expect(run.output, isNull);
      expect(run.logs, isEmpty);
      expect(run.artifacts, isEmpty);
      expect(run.errorMessage, isNull);
      expect(run.workspaceId, isNull);
    });

    test('fromJson with null optional fields', () {
      final json = {
        'runId': 'r-1',
        'startedAt': '2024-01-01T00:00:00.000',
        'finishedAt': null,
        'output': null,
        'logs': null,
        'artifacts': null,
        'errorMessage': null,
        'workspaceId': null,
        'input': null,
      };
      final run = Run.fromJson(json);

      expect(run.finishedAt, isNull);
      expect(run.output, isNull);
      expect(run.logs, isEmpty);
      expect(run.artifacts, isEmpty);
      expect(run.errorMessage, isNull);
      expect(run.workspaceId, isNull);
    });

    test('toJson with fully populated run', () {
      final run = createFullRun();
      final json = run.toJson();

      expect(json['runId'], equals('run-1'));
      expect(json['jobId'], equals('job-1'));
      expect(json['startedAt'], equals(fixedStart.toIso8601String()));
      expect(json['finishedAt'], equals(fixedFinish.toIso8601String()));
      expect(json['status'], equals('success'));
      expect(json['idempotencyKey'], equals('idem-key-1'));
      expect(json['input'], isA<Map>());
      expect(json['output'], isA<Map>());
      expect(json['logs'], isA<List>());
      expect((json['logs'] as List), hasLength(1));
      expect(json['artifacts'], equals(['artifact-1', 'artifact-2']));
      expect(json['workspaceId'], equals('ws-1'));
    });

    test('toJson excludes empty/null fields', () {
      final run = Run(
        runId: 'run-1',
        jobId: 'job-1',
        startedAt: fixedStart,
        idempotencyKey: 'key-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1.0'),
      );
      final json = run.toJson();

      expect(json.containsKey('finishedAt'), isFalse);
      expect(json.containsKey('output'), isFalse);
      expect(json.containsKey('logs'), isFalse);
      expect(json.containsKey('artifacts'), isFalse);
      expect(json.containsKey('errorMessage'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      // Required fields always present
      expect(json.containsKey('runId'), isTrue);
      expect(json.containsKey('input'), isTrue);
      expect(json.containsKey('status'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = createFullRun();
      final copy = original.copyWith(
        runId: 'run-2',
        status: RunStatus.failed,
        errorMessage: 'An error occurred',
      );

      expect(copy.runId, equals('run-2'));
      expect(copy.status, equals(RunStatus.failed));
      expect(copy.errorMessage, equals('An error occurred'));
      // Unchanged
      expect(copy.jobId, equals('job-1'));
      expect(copy.startedAt, equals(fixedStart));
      expect(copy.finishedAt, equals(fixedFinish));
      expect(copy.idempotencyKey, equals('idem-key-1'));
      expect(copy.workspaceId, equals('ws-1'));
    });

    test('copyWith with no arguments returns equivalent run', () {
      final original = createFullRun();
      final copy = original.copyWith();

      expect(copy.runId, equals(original.runId));
      expect(copy.jobId, equals(original.jobId));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = createFullRun();
      final newTime = DateTime(2025, 1, 1);
      final newInput = RunInput(asOf: newTime, policyVersion: 'v9');
      const newOutput = RunOutput(createdViewIds: ['new-v']);
      final newLog = LogEntry(
        timestamp: newTime,
        level: 'warn',
        message: 'new log',
      );

      final copy = original.copyWith(
        runId: 'new-run',
        jobId: 'new-job',
        startedAt: newTime,
        finishedAt: newTime,
        status: RunStatus.skipped,
        idempotencyKey: 'new-key',
        input: newInput,
        output: newOutput,
        logs: [newLog],
        artifacts: ['new-art'],
        errorMessage: 'new-error',
        workspaceId: 'new-ws',
      );

      expect(copy.runId, equals('new-run'));
      expect(copy.jobId, equals('new-job'));
      expect(copy.startedAt, equals(newTime));
      expect(copy.finishedAt, equals(newTime));
      expect(copy.status, equals(RunStatus.skipped));
      expect(copy.idempotencyKey, equals('new-key'));
      expect(copy.input.policyVersion, equals('v9'));
      expect(copy.output!.createdViewIds, equals(['new-v']));
      expect(copy.logs, hasLength(1));
      expect(copy.artifacts, equals(['new-art']));
      expect(copy.errorMessage, equals('new-error'));
      expect(copy.workspaceId, equals('new-ws'));
    });

    test('isRunning getter', () {
      final running = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
        status: RunStatus.running,
      );
      final success = running.copyWith(status: RunStatus.success);

      expect(running.isRunning, isTrue);
      expect(success.isRunning, isFalse);
    });

    test('isSuccess getter', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
        status: RunStatus.success,
      );

      expect(run.isSuccess, isTrue);
      expect(run.copyWith(status: RunStatus.running).isSuccess, isFalse);
    });

    test('isFailed getter', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
        status: RunStatus.failed,
      );

      expect(run.isFailed, isTrue);
      expect(run.copyWith(status: RunStatus.running).isFailed, isFalse);
    });

    test('duration getter returns duration when finished', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        finishedAt: fixedFinish,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      expect(run.duration, isNotNull);
      expect(run.duration!.inMinutes, equals(5));
    });

    test('duration getter returns null when not finished', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      expect(run.duration, isNull);
    });

    test('complete method marks run as successful', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      const output = RunOutput(createdViewIds: ['v-out']);
      final completed = run.complete(
        output: output,
        artifacts: ['art-1'],
      );

      expect(completed.status, equals(RunStatus.success));
      expect(completed.finishedAt, isNotNull);
      expect(completed.output, isNotNull);
      expect(completed.output!.createdViewIds, equals(['v-out']));
      expect(completed.artifacts, equals(['art-1']));
      // Unchanged
      expect(completed.runId, equals('r-1'));
      expect(completed.jobId, equals('j-1'));
    });

    test('complete method without optional args', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      final completed = run.complete();

      expect(completed.status, equals(RunStatus.success));
      expect(completed.finishedAt, isNotNull);
    });

    test('fail method marks run as failed with error', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      final failed = run.fail(errorMessage: 'Connection timeout');

      expect(failed.status, equals(RunStatus.failed));
      expect(failed.finishedAt, isNotNull);
      expect(failed.errorMessage, equals('Connection timeout'));
      // Unchanged
      expect(failed.runId, equals('r-1'));
    });

    test('addLog method appends a log entry', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
      );

      final withLog = run.addLog('info', 'Starting process');

      expect(withLog.logs, hasLength(1));
      expect(withLog.logs[0].level, equals('info'));
      expect(withLog.logs[0].message, equals('Starting process'));
      expect(withLog.logs[0].timestamp, isNotNull);
    });

    test('addLog method preserves existing logs', () {
      final run = Run(
        runId: 'r-1',
        jobId: 'j-1',
        startedAt: fixedStart,
        idempotencyKey: 'k-1',
        input: RunInput(asOf: fixedStart, policyVersion: 'v1'),
        logs: [
          LogEntry(
            timestamp: fixedStart,
            level: 'info',
            message: 'First log',
          ),
        ],
      );

      final withLog = run.addLog('warn', 'Second log');

      expect(withLog.logs, hasLength(2));
      expect(withLog.logs[0].message, equals('First log'));
      expect(withLog.logs[1].message, equals('Second log'));
    });

    test('fromJson roundtrip preserves data', () {
      final original = createFullRun();
      final json = original.toJson();
      final restored = Run.fromJson(json);

      expect(restored.runId, equals(original.runId));
      expect(restored.jobId, equals(original.jobId));
      expect(restored.status, equals(original.status));
      expect(restored.idempotencyKey, equals(original.idempotencyKey));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.artifacts, equals(original.artifacts));
    });
  });
}
