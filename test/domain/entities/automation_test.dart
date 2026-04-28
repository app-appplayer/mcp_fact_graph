import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // AutomationTriggerType enum
  // =========================================================================
  group('AutomationTriggerType', () {
    test('has all expected values', () {
      expect(AutomationTriggerType.values,
          contains(AutomationTriggerType.schedule));
      expect(AutomationTriggerType.values,
          contains(AutomationTriggerType.condition));
      expect(AutomationTriggerType.values,
          contains(AutomationTriggerType.manual));
      expect(AutomationTriggerType.values.length, equals(3));
    });

    test('fromString returns correct value for all variants', () {
      expect(AutomationTriggerType.fromString('schedule'),
          equals(AutomationTriggerType.schedule));
      expect(AutomationTriggerType.fromString('condition'),
          equals(AutomationTriggerType.condition));
      expect(AutomationTriggerType.fromString('manual'),
          equals(AutomationTriggerType.manual));
    });

    test('fromString is case-insensitive', () {
      expect(AutomationTriggerType.fromString('Schedule'),
          equals(AutomationTriggerType.schedule));
      expect(AutomationTriggerType.fromString('CONDITION'),
          equals(AutomationTriggerType.condition));
      expect(AutomationTriggerType.fromString('Manual'),
          equals(AutomationTriggerType.manual));
    });

    test('fromString returns manual for invalid values', () {
      expect(AutomationTriggerType.fromString('unknown'),
          equals(AutomationTriggerType.manual));
      expect(AutomationTriggerType.fromString(''),
          equals(AutomationTriggerType.manual));
      expect(AutomationTriggerType.fromString('trigger'),
          equals(AutomationTriggerType.manual));
    });
  });

  // =========================================================================
  // ScheduleMeta class
  // =========================================================================
  group('ScheduleMeta', () {
    test('constructor with required fields only', () {
      const meta = ScheduleMeta(cron: '0 9 * * 1-5');

      expect(meta.cron, equals('0 9 * * 1-5'));
      expect(meta.timezone, equals('UTC'));
    });

    test('constructor with all fields', () {
      const meta = ScheduleMeta(
        cron: '0 0 * * *',
        timezone: 'America/New_York',
      );

      expect(meta.cron, equals('0 0 * * *'));
      expect(meta.timezone, equals('America/New_York'));
    });

    test('fromJson complete', () {
      final json = {
        'cron': '30 8 * * MON',
        'timezone': 'Asia/Seoul',
      };

      final meta = ScheduleMeta.fromJson(json);

      expect(meta.cron, equals('30 8 * * MON'));
      expect(meta.timezone, equals('Asia/Seoul'));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final meta = ScheduleMeta.fromJson(json);

      expect(meta.cron, equals(''));
      expect(meta.timezone, equals('UTC'));
    });

    test('toJson outputs all fields', () {
      const meta = ScheduleMeta(
        cron: '0 12 * * *',
        timezone: 'Europe/London',
      );

      final json = meta.toJson();

      expect(json['cron'], equals('0 12 * * *'));
      expect(json['timezone'], equals('Europe/London'));
    });

    test('copyWith modifies specified fields', () {
      const original = ScheduleMeta(
        cron: '0 9 * * *',
        timezone: 'UTC',
      );

      final copy = original.copyWith(cron: '0 10 * * *');

      expect(copy.cron, equals('0 10 * * *'));
      expect(copy.timezone, equals('UTC'));
    });

    test('copyWith with no arguments returns equivalent meta', () {
      const original = ScheduleMeta(cron: '0 0 * * *', timezone: 'UTC');
      final copy = original.copyWith();

      expect(copy.cron, equals(original.cron));
      expect(copy.timezone, equals(original.timezone));
    });
  });

  // =========================================================================
  // RetryPolicy class
  // =========================================================================
  group('RetryPolicy', () {
    test('constructor with default values', () {
      const policy = RetryPolicy();

      expect(policy.maxRetries, equals(3));
      expect(policy.backoffSeconds, equals(60));
      expect(policy.exponentialBackoff, isTrue);
    });

    test('constructor with custom values', () {
      const policy = RetryPolicy(
        maxRetries: 5,
        backoffSeconds: 30,
        exponentialBackoff: false,
      );

      expect(policy.maxRetries, equals(5));
      expect(policy.backoffSeconds, equals(30));
      expect(policy.exponentialBackoff, isFalse);
    });

    test('fromJson complete', () {
      final json = {
        'maxRetries': 10,
        'backoffSeconds': 120,
        'exponentialBackoff': false,
      };

      final policy = RetryPolicy.fromJson(json);

      expect(policy.maxRetries, equals(10));
      expect(policy.backoffSeconds, equals(120));
      expect(policy.exponentialBackoff, isFalse);
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final policy = RetryPolicy.fromJson(json);

      expect(policy.maxRetries, equals(3));
      expect(policy.backoffSeconds, equals(60));
      expect(policy.exponentialBackoff, isTrue);
    });

    test('toJson outputs all fields', () {
      const policy = RetryPolicy(
        maxRetries: 7,
        backoffSeconds: 45,
        exponentialBackoff: false,
      );

      final json = policy.toJson();

      expect(json['maxRetries'], equals(7));
      expect(json['backoffSeconds'], equals(45));
      expect(json['exponentialBackoff'], isFalse);
    });

    test('copyWith modifies specified fields', () {
      const original = RetryPolicy(
        maxRetries: 3,
        backoffSeconds: 60,
        exponentialBackoff: true,
      );

      final copy = original.copyWith(maxRetries: 5, exponentialBackoff: false);

      expect(copy.maxRetries, equals(5));
      expect(copy.backoffSeconds, equals(60));
      expect(copy.exponentialBackoff, isFalse);
    });

    test('copyWith with no arguments returns equivalent policy', () {
      const original = RetryPolicy(maxRetries: 2, backoffSeconds: 30, exponentialBackoff: false);
      final copy = original.copyWith();

      expect(copy.maxRetries, equals(original.maxRetries));
      expect(copy.backoffSeconds, equals(original.backoffSeconds));
      expect(copy.exponentialBackoff, equals(original.exponentialBackoff));
    });

    test('getBackoffDuration with exponential backoff', () {
      const policy = RetryPolicy(
        backoffSeconds: 10,
        exponentialBackoff: true,
      );

      // attempt 0: 10 * 2^0 = 10 seconds
      expect(policy.getBackoffDuration(0), equals(const Duration(seconds: 10)));
      // attempt 1: 10 * 2^1 = 20 seconds
      expect(policy.getBackoffDuration(1), equals(const Duration(seconds: 20)));
      // attempt 2: 10 * 2^2 = 40 seconds
      expect(policy.getBackoffDuration(2), equals(const Duration(seconds: 40)));
      // attempt 3: 10 * 2^3 = 80 seconds
      expect(policy.getBackoffDuration(3), equals(const Duration(seconds: 80)));
    });

    test('getBackoffDuration without exponential backoff', () {
      const policy = RetryPolicy(
        backoffSeconds: 30,
        exponentialBackoff: false,
      );

      // Fixed backoff - always the same duration
      expect(policy.getBackoffDuration(0), equals(const Duration(seconds: 30)));
      expect(policy.getBackoffDuration(1), equals(const Duration(seconds: 30)));
      expect(policy.getBackoffDuration(2), equals(const Duration(seconds: 30)));
      expect(policy.getBackoffDuration(5), equals(const Duration(seconds: 30)));
    });

    test('getBackoffDuration with negative attempt', () {
      const policy = RetryPolicy(backoffSeconds: 10);

      expect(policy.getBackoffDuration(-1), equals(Duration.zero));
      expect(policy.getBackoffDuration(-100), equals(Duration.zero));
    });
  });

  // =========================================================================
  // Automation entity
  // =========================================================================
  group('Automation', () {
    final now = DateTime(2024, 6, 15, 10, 0, 0);
    final later = DateTime(2024, 7, 15, 10, 0, 0);

    test('constructor with required fields only', () {
      final auto = Automation(
        jobId: 'job-1',
        name: 'Daily Cleanup',
        trigger: AutomationTriggerType.schedule,
        action: 'cleanup_stale_data',
        createdAt: now,
        updatedAt: now,
      );

      expect(auto.jobId, equals('job-1'));
      expect(auto.name, equals('Daily Cleanup'));
      expect(auto.description, isNull);
      expect(auto.trigger, equals(AutomationTriggerType.schedule));
      expect(auto.condition, isNull);
      expect(auto.action, equals('cleanup_stale_data'));
      expect(auto.enabled, isTrue);
      expect(auto.scheduleMeta, isNull);
      expect(auto.idempotencyKeyStrategy, equals('time-based'));
      expect(auto.retryPolicy.maxRetries, equals(3));
      expect(auto.workspaceId, isNull);
      expect(auto.createdAt, equals(now));
      expect(auto.updatedAt, equals(now));
      expect(auto.lastRunAt, isNull);
      expect(auto.nextRunAt, isNull);
    });

    test('constructor with all fields', () {
      const scheduleMeta = ScheduleMeta(
        cron: '0 9 * * 1-5',
        timezone: 'America/New_York',
      );

      const retryPolicy = RetryPolicy(
        maxRetries: 5,
        backoffSeconds: 120,
        exponentialBackoff: false,
      );

      final auto = Automation(
        jobId: 'job-2',
        name: 'Weekly Report',
        description: 'Generate weekly summary reports',
        trigger: AutomationTriggerType.schedule,
        condition: 'facts.count > 10',
        action: 'generate_report',
        enabled: false,
        scheduleMeta: scheduleMeta,
        idempotencyKeyStrategy: 'content-hash',
        retryPolicy: retryPolicy,
        workspaceId: 'ws-1',
        createdAt: now,
        updatedAt: later,
        lastRunAt: now,
        nextRunAt: later,
      );

      expect(auto.jobId, equals('job-2'));
      expect(auto.name, equals('Weekly Report'));
      expect(auto.description, equals('Generate weekly summary reports'));
      expect(auto.trigger, equals(AutomationTriggerType.schedule));
      expect(auto.condition, equals('facts.count > 10'));
      expect(auto.action, equals('generate_report'));
      expect(auto.enabled, isFalse);
      expect(auto.scheduleMeta, isNotNull);
      expect(auto.scheduleMeta!.cron, equals('0 9 * * 1-5'));
      expect(auto.idempotencyKeyStrategy, equals('content-hash'));
      expect(auto.retryPolicy.maxRetries, equals(5));
      expect(auto.workspaceId, equals('ws-1'));
      expect(auto.lastRunAt, equals(now));
      expect(auto.nextRunAt, equals(later));
    });

    test('fromJson complete', () {
      final json = {
        'jobId': 'job-3',
        'name': 'Conditional Task',
        'description': 'Runs on condition',
        'trigger': 'condition',
        'condition': 'new_facts > 5',
        'action': 'process_facts',
        'enabled': true,
        'scheduleMeta': {
          'cron': '0 0 * * *',
          'timezone': 'UTC',
        },
        'idempotencyKeyStrategy': 'uuid',
        'retryPolicy': {
          'maxRetries': 2,
          'backoffSeconds': 30,
          'exponentialBackoff': true,
        },
        'workspaceId': 'ws-2',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-07-15T10:00:00.000',
        'lastRunAt': '2024-06-15T10:00:00.000',
        'nextRunAt': '2024-07-15T10:00:00.000',
      };

      final auto = Automation.fromJson(json);

      expect(auto.jobId, equals('job-3'));
      expect(auto.name, equals('Conditional Task'));
      expect(auto.description, equals('Runs on condition'));
      expect(auto.trigger, equals(AutomationTriggerType.condition));
      expect(auto.condition, equals('new_facts > 5'));
      expect(auto.action, equals('process_facts'));
      expect(auto.enabled, isTrue);
      expect(auto.scheduleMeta, isNotNull);
      expect(auto.scheduleMeta!.cron, equals('0 0 * * *'));
      expect(auto.idempotencyKeyStrategy, equals('uuid'));
      expect(auto.retryPolicy.maxRetries, equals(2));
      expect(auto.retryPolicy.backoffSeconds, equals(30));
      expect(auto.workspaceId, equals('ws-2'));
      expect(auto.createdAt,
          equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(auto.updatedAt,
          equals(DateTime.parse('2024-07-15T10:00:00.000')));
      expect(auto.lastRunAt,
          equals(DateTime.parse('2024-06-15T10:00:00.000')));
      expect(auto.nextRunAt,
          equals(DateTime.parse('2024-07-15T10:00:00.000')));
    });

    test('fromJson empty/missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final auto = Automation.fromJson(json);

      expect(auto.jobId, equals(''));
      expect(auto.name, equals(''));
      expect(auto.description, isNull);
      expect(auto.trigger, equals(AutomationTriggerType.manual));
      expect(auto.condition, isNull);
      expect(auto.action, equals(''));
      expect(auto.enabled, isTrue);
      expect(auto.scheduleMeta, isNull);
      expect(auto.idempotencyKeyStrategy, equals('time-based'));
      expect(auto.retryPolicy.maxRetries, equals(3));
      expect(auto.workspaceId, isNull);
      expect(auto.lastRunAt, isNull);
      expect(auto.nextRunAt, isNull);
    });

    test('toJson populated', () {
      const scheduleMeta = ScheduleMeta(cron: '0 8 * * *');

      final auto = Automation(
        jobId: 'job-tj',
        name: 'ToJson Test',
        description: 'Testing toJson',
        trigger: AutomationTriggerType.schedule,
        condition: 'always',
        action: 'run_task',
        enabled: true,
        scheduleMeta: scheduleMeta,
        idempotencyKeyStrategy: 'time-based',
        retryPolicy: const RetryPolicy(maxRetries: 1),
        workspaceId: 'ws-tj',
        createdAt: now,
        updatedAt: later,
        lastRunAt: now,
        nextRunAt: later,
      );

      final json = auto.toJson();

      expect(json['jobId'], equals('job-tj'));
      expect(json['name'], equals('ToJson Test'));
      expect(json['description'], equals('Testing toJson'));
      expect(json['trigger'], equals('schedule'));
      expect(json['condition'], equals('always'));
      expect(json['action'], equals('run_task'));
      expect(json['enabled'], isTrue);
      expect(json['scheduleMeta'], isA<Map<String, dynamic>>());
      expect((json['scheduleMeta'] as Map)['cron'], equals('0 8 * * *'));
      expect(json['idempotencyKeyStrategy'], equals('time-based'));
      expect(json['retryPolicy'], isA<Map<String, dynamic>>());
      expect((json['retryPolicy'] as Map)['maxRetries'], equals(1));
      expect(json['workspaceId'], equals('ws-tj'));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(later.toIso8601String()));
      expect(json['lastRunAt'], equals(now.toIso8601String()));
      expect(json['nextRunAt'], equals(later.toIso8601String()));
    });

    test('toJson excludes null fields', () {
      final auto = Automation(
        jobId: 'job-min',
        name: 'Minimal',
        trigger: AutomationTriggerType.manual,
        action: 'simple_action',
        createdAt: now,
        updatedAt: now,
      );

      final json = auto.toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('condition'), isFalse);
      expect(json.containsKey('scheduleMeta'), isFalse);
      expect(json.containsKey('workspaceId'), isFalse);
      expect(json.containsKey('lastRunAt'), isFalse);
      expect(json.containsKey('nextRunAt'), isFalse);
      // Always present
      expect(json.containsKey('jobId'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('trigger'), isTrue);
      expect(json.containsKey('action'), isTrue);
      expect(json.containsKey('enabled'), isTrue);
      expect(json.containsKey('idempotencyKeyStrategy'), isTrue);
      expect(json.containsKey('retryPolicy'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final original = Automation(
        jobId: 'job-cw',
        name: 'Original',
        trigger: AutomationTriggerType.manual,
        action: 'original_action',
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith(
        name: 'Updated',
        description: 'New description',
        trigger: AutomationTriggerType.schedule,
        condition: 'new_condition',
        action: 'new_action',
        enabled: false,
        scheduleMeta: const ScheduleMeta(cron: '0 0 * * *'),
        idempotencyKeyStrategy: 'content-hash',
        retryPolicy: const RetryPolicy(maxRetries: 10),
        workspaceId: 'ws-new',
        updatedAt: later,
        lastRunAt: now,
        nextRunAt: later,
      );

      // Unchanged
      expect(copy.jobId, equals('job-cw'));
      expect(copy.createdAt, equals(now));

      // Changed
      expect(copy.name, equals('Updated'));
      expect(copy.description, equals('New description'));
      expect(copy.trigger, equals(AutomationTriggerType.schedule));
      expect(copy.condition, equals('new_condition'));
      expect(copy.action, equals('new_action'));
      expect(copy.enabled, isFalse);
      expect(copy.scheduleMeta, isNotNull);
      expect(copy.scheduleMeta!.cron, equals('0 0 * * *'));
      expect(copy.idempotencyKeyStrategy, equals('content-hash'));
      expect(copy.retryPolicy.maxRetries, equals(10));
      expect(copy.workspaceId, equals('ws-new'));
      expect(copy.updatedAt, equals(later));
      expect(copy.lastRunAt, equals(now));
      expect(copy.nextRunAt, equals(later));
    });

    test('copyWith with no arguments returns equivalent automation', () {
      final original = Automation(
        jobId: 'job-nc',
        name: 'No Change',
        trigger: AutomationTriggerType.condition,
        action: 'test_action',
        createdAt: now,
        updatedAt: now,
      );

      final copy = original.copyWith();

      expect(copy.jobId, equals(original.jobId));
      expect(copy.name, equals(original.name));
      expect(copy.trigger, equals(original.trigger));
      expect(copy.action, equals(original.action));
      expect(copy.enabled, equals(original.enabled));
    });

    test('isScheduled getter', () {
      final scheduled = Automation(
        jobId: 'job-sched',
        name: 'Scheduled',
        trigger: AutomationTriggerType.schedule,
        action: 'task',
        createdAt: now,
        updatedAt: now,
      );

      final manual = Automation(
        jobId: 'job-man',
        name: 'Manual',
        trigger: AutomationTriggerType.manual,
        action: 'task',
        createdAt: now,
        updatedAt: now,
      );

      final condition = Automation(
        jobId: 'job-cond',
        name: 'Condition',
        trigger: AutomationTriggerType.condition,
        action: 'task',
        createdAt: now,
        updatedAt: now,
      );

      expect(scheduled.isScheduled, isTrue);
      expect(manual.isScheduled, isFalse);
      expect(condition.isScheduled, isFalse);
    });

    test('isReadyToRun when disabled', () {
      final disabled = Automation(
        jobId: 'job-dis',
        name: 'Disabled',
        trigger: AutomationTriggerType.manual,
        action: 'task',
        enabled: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(disabled.isReadyToRun, isFalse);
    });

    test('isReadyToRun for manual trigger without nextRunAt', () {
      final manualReady = Automation(
        jobId: 'job-mr',
        name: 'Manual Ready',
        trigger: AutomationTriggerType.manual,
        action: 'task',
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(manualReady.isReadyToRun, isTrue);
    });

    test('isReadyToRun for condition trigger without nextRunAt', () {
      final conditionNoNext = Automation(
        jobId: 'job-cn',
        name: 'Condition No Next',
        trigger: AutomationTriggerType.condition,
        action: 'task',
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );

      // nextRunAt is null and trigger is not manual
      expect(conditionNoNext.isReadyToRun, isFalse);
    });

    test('isReadyToRun with past nextRunAt', () {
      final pastDue = Automation(
        jobId: 'job-pd',
        name: 'Past Due',
        trigger: AutomationTriggerType.schedule,
        action: 'task',
        enabled: true,
        nextRunAt: DateTime(2020, 1, 1),
        createdAt: now,
        updatedAt: now,
      );

      expect(pastDue.isReadyToRun, isTrue);
    });

    test('isReadyToRun with future nextRunAt', () {
      final futureRun = Automation(
        jobId: 'job-fr',
        name: 'Future Run',
        trigger: AutomationTriggerType.schedule,
        action: 'task',
        enabled: true,
        nextRunAt: DateTime(2099, 12, 31),
        createdAt: now,
        updatedAt: now,
      );

      expect(futureRun.isReadyToRun, isFalse);
    });

    test('enable creates enabled copy', () {
      final disabled = Automation(
        jobId: 'job-en',
        name: 'Enable Test',
        trigger: AutomationTriggerType.manual,
        action: 'task',
        enabled: false,
        createdAt: now,
        updatedAt: now,
      );

      final enabled = disabled.enable();

      expect(enabled.enabled, isTrue);
      expect(enabled.jobId, equals('job-en'));
      expect(enabled.name, equals('Enable Test'));
      // updatedAt should be updated (will be close to DateTime.now())
      expect(enabled.updatedAt.isAfter(now) || enabled.updatedAt == now, isTrue);
    });

    test('disable creates disabled copy', () {
      final enabled = Automation(
        jobId: 'job-dis',
        name: 'Disable Test',
        trigger: AutomationTriggerType.schedule,
        action: 'task',
        enabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final disabled = enabled.disable();

      expect(disabled.enabled, isFalse);
      expect(disabled.jobId, equals('job-dis'));
      expect(disabled.name, equals('Disable Test'));
    });

    test('markRun updates lastRunAt and nextRunAt', () {
      final auto = Automation(
        jobId: 'job-mr',
        name: 'Mark Run Test',
        trigger: AutomationTriggerType.schedule,
        action: 'task',
        createdAt: now,
        updatedAt: now,
      );

      final nextRun = DateTime(2024, 8, 1);
      final marked = auto.markRun(nextRun: nextRun);

      expect(marked.lastRunAt, isNotNull);
      expect(marked.nextRunAt, equals(nextRun));
      expect(marked.jobId, equals('job-mr'));
    });

    test('markRun without nextRun parameter', () {
      final auto = Automation(
        jobId: 'job-mr2',
        name: 'Mark Run No Next',
        trigger: AutomationTriggerType.manual,
        action: 'task',
        createdAt: now,
        updatedAt: now,
      );

      final marked = auto.markRun();

      expect(marked.lastRunAt, isNotNull);
      expect(marked.nextRunAt, isNull);
    });

    test('fromJson then toJson roundtrip', () {
      final json = {
        'jobId': 'job-rt',
        'name': 'Roundtrip',
        'description': 'Test roundtrip',
        'trigger': 'schedule',
        'condition': 'facts > 0',
        'action': 'process',
        'enabled': true,
        'scheduleMeta': {
          'cron': '0 8 * * *',
          'timezone': 'UTC',
        },
        'idempotencyKeyStrategy': 'content-hash',
        'retryPolicy': {
          'maxRetries': 5,
          'backoffSeconds': 30,
          'exponentialBackoff': false,
        },
        'workspaceId': 'ws-rt',
        'createdAt': '2024-06-15T10:00:00.000',
        'updatedAt': '2024-07-15T10:00:00.000',
        'lastRunAt': '2024-06-15T10:00:00.000',
        'nextRunAt': '2024-07-15T10:00:00.000',
      };

      final auto = Automation.fromJson(json);
      final result = auto.toJson();

      expect(result['jobId'], equals(json['jobId']));
      expect(result['name'], equals(json['name']));
      expect(result['description'], equals(json['description']));
      expect(result['trigger'], equals(json['trigger']));
      expect(result['condition'], equals(json['condition']));
      expect(result['action'], equals(json['action']));
      expect(result['enabled'], equals(json['enabled']));
      expect(result['idempotencyKeyStrategy'],
          equals(json['idempotencyKeyStrategy']));
      expect(result['workspaceId'], equals(json['workspaceId']));
    });
  });
}
