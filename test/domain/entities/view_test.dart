import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

void main() {
  // =========================================================================
  // ViewStatus enum tests
  // =========================================================================
  group('ViewStatus', () {
    test('fromString returns correct value for all valid values', () {
      expect(ViewStatus.fromString('current'), equals(ViewStatus.current));
      expect(ViewStatus.fromString('stale'), equals(ViewStatus.stale));
      expect(ViewStatus.fromString('computing'), equals(ViewStatus.computing));
      expect(ViewStatus.fromString('archived'), equals(ViewStatus.archived));
    });

    test('fromString returns current for invalid value', () {
      expect(ViewStatus.fromString('unknown'), equals(ViewStatus.current));
      expect(ViewStatus.fromString(''), equals(ViewStatus.current));
      expect(ViewStatus.fromString('CURRENT'), equals(ViewStatus.current));
    });

    test('has all expected values', () {
      expect(ViewStatus.values, hasLength(4));
      expect(ViewStatus.values, contains(ViewStatus.current));
      expect(ViewStatus.values, contains(ViewStatus.stale));
      expect(ViewStatus.values, contains(ViewStatus.computing));
      expect(ViewStatus.values, contains(ViewStatus.archived));
    });
  });

  // =========================================================================
  // ViewPeriod tests
  // =========================================================================
  group('ViewPeriod', () {
    test('constructor with required fields', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final period = ViewPeriod(start: start, end: end);

      expect(period.start, equals(start));
      expect(period.end, equals(end));
    });

    test('fromJson with complete data', () {
      final json = {
        'start': '2024-01-01T00:00:00.000',
        'end': '2024-01-31T00:00:00.000',
      };
      final period = ViewPeriod.fromJson(json);

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, equals(DateTime(2024, 1, 31)));
    });

    test('fromJson with empty map uses DateTime.now fallbacks', () {
      final before = DateTime.now();
      final period = ViewPeriod.fromJson({});
      final after = DateTime.now();

      // start and end should be close to now
      expect(
        period.start.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        period.end.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('fromJson with null start and end uses DateTime.now fallbacks', () {
      final before = DateTime.now();
      final period = ViewPeriod.fromJson({'start': null, 'end': null});
      final after = DateTime.now();

      expect(
        period.start.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        period.end.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('toJson produces correct output', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final period = ViewPeriod(start: start, end: end);
      final json = period.toJson();

      expect(json['start'], equals(start.toIso8601String()));
      expect(json['end'], equals(end.toIso8601String()));
    });

    test('duration getter returns correct duration', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final period = ViewPeriod(start: start, end: end);

      expect(period.duration, equals(const Duration(days: 30)));
    });

    test('duration getter returns zero for same start and end', () {
      final date = DateTime(2024, 1, 1);
      final period = ViewPeriod(start: date, end: date);

      expect(period.duration, equals(Duration.zero));
    });
  });

  // =========================================================================
  // ComputationMeta tests
  // =========================================================================
  group('ComputationMeta', () {
    test('constructor with required fields', () {
      const meta = ComputationMeta(
        durationMs: 500,
        eventsProcessed: 100,
        algorithm: 'v1',
      );

      expect(meta.durationMs, equals(500));
      expect(meta.eventsProcessed, equals(100));
      expect(meta.algorithm, equals('v1'));
      expect(meta.warnings, isEmpty);
    });

    test('constructor with all fields', () {
      const meta = ComputationMeta(
        durationMs: 1000,
        eventsProcessed: 200,
        algorithm: 'v2-weighted',
        warnings: ['low confidence', 'missing data'],
      );

      expect(meta.durationMs, equals(1000));
      expect(meta.eventsProcessed, equals(200));
      expect(meta.algorithm, equals('v2-weighted'));
      expect(meta.warnings, hasLength(2));
      expect(meta.warnings, contains('low confidence'));
      expect(meta.warnings, contains('missing data'));
    });

    test('fromJson with complete data', () {
      final json = {
        'durationMs': 750,
        'eventsProcessed': 50,
        'algorithm': 'sum-aggregation',
        'warnings': ['partial data'],
      };
      final meta = ComputationMeta.fromJson(json);

      expect(meta.durationMs, equals(750));
      expect(meta.eventsProcessed, equals(50));
      expect(meta.algorithm, equals('sum-aggregation'));
      expect(meta.warnings, equals(['partial data']));
    });

    test('fromJson with empty map uses defaults', () {
      final meta = ComputationMeta.fromJson({});

      expect(meta.durationMs, equals(0));
      expect(meta.eventsProcessed, equals(0));
      expect(meta.algorithm, equals(''));
      expect(meta.warnings, isEmpty);
    });

    test('fromJson with null fields uses defaults', () {
      final meta = ComputationMeta.fromJson({
        'durationMs': null,
        'eventsProcessed': null,
        'algorithm': null,
        'warnings': null,
      });

      expect(meta.durationMs, equals(0));
      expect(meta.eventsProcessed, equals(0));
      expect(meta.algorithm, equals(''));
      expect(meta.warnings, isEmpty);
    });

    test('toJson with populated fields', () {
      const meta = ComputationMeta(
        durationMs: 500,
        eventsProcessed: 100,
        algorithm: 'v1',
        warnings: ['warning1'],
      );
      final json = meta.toJson();

      expect(json['durationMs'], equals(500));
      expect(json['eventsProcessed'], equals(100));
      expect(json['algorithm'], equals('v1'));
      expect(json['warnings'], equals(['warning1']));
    });

    test('toJson excludes empty warnings', () {
      const meta = ComputationMeta(
        durationMs: 500,
        eventsProcessed: 100,
        algorithm: 'v1',
      );
      final json = meta.toJson();

      expect(json.containsKey('warnings'), isFalse);
    });
  });

  // =========================================================================
  // View tests
  // =========================================================================
  group('View', () {
    final fixedTime = DateTime(2024, 6, 15, 10, 30);
    final fixedAsOf = DateTime(2024, 6, 15, 10, 0);
    final periodStart = DateTime(2024, 6, 1);
    final periodEnd = DateTime(2024, 6, 30);

    View createFullView() {
      return View(
        viewId: 'view-1',
        workspaceId: 'ws-1',
        viewType: 'monthly-summary',
        title: 'June Summary',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'project-alpha',
        dimensions: {'category': 'finance', 'region': 'us'},
        metrics: {'total': 42, 'average': 7.0},
        sourceRefs: ['evt-1', 'evt-2'],
        policyVersion: 'v2.0',
        computedAt: fixedTime,
        asOf: fixedAsOf,
        status: ViewStatus.current,
        computationMeta: const ComputationMeta(
          durationMs: 300,
          eventsProcessed: 50,
          algorithm: 'sum',
          warnings: ['partial'],
        ),
        metadata: {'source': 'auto'},
      );
    }

    test('constructor with required fields only', () {
      final view = View(
        viewId: 'view-1',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'Test View',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );

      expect(view.viewId, equals('view-1'));
      expect(view.workspaceId, equals('ws-1'));
      expect(view.viewType, equals('summary'));
      expect(view.title, equals('Test View'));
      expect(view.period.start, equals(periodStart));
      expect(view.period.end, equals(periodEnd));
      expect(view.scope, equals('global'));
      expect(view.dimensions, isEmpty);
      expect(view.metrics, isEmpty);
      expect(view.sourceRefs, isEmpty);
      expect(view.policyVersion, isNull);
      expect(view.computedAt, equals(fixedTime));
      expect(view.asOf, equals(fixedAsOf));
      expect(view.status, equals(ViewStatus.current));
      expect(view.computationMeta, isNull);
      expect(view.metadata, isEmpty);
    });

    test('constructor with all fields', () {
      final view = createFullView();

      expect(view.viewId, equals('view-1'));
      expect(view.workspaceId, equals('ws-1'));
      expect(view.viewType, equals('monthly-summary'));
      expect(view.title, equals('June Summary'));
      expect(view.scope, equals('project-alpha'));
      expect(view.dimensions, hasLength(2));
      expect(view.dimensions['category'], equals('finance'));
      expect(view.metrics['total'], equals(42));
      expect(view.sourceRefs, equals(['evt-1', 'evt-2']));
      expect(view.policyVersion, equals('v2.0'));
      expect(view.status, equals(ViewStatus.current));
      expect(view.computationMeta, isNotNull);
      expect(view.computationMeta!.durationMs, equals(300));
      expect(view.metadata['source'], equals('auto'));
    });

    test('fromJson with complete data', () {
      final json = {
        'viewId': 'view-1',
        'workspaceId': 'ws-1',
        'viewType': 'monthly-summary',
        'title': 'June Summary',
        'period': {
          'start': '2024-06-01T00:00:00.000',
          'end': '2024-06-30T00:00:00.000',
        },
        'scope': 'project-alpha',
        'dimensions': {'category': 'finance'},
        'metrics': {'total': 42},
        'sourceRefs': ['evt-1', 'evt-2'],
        'policyVersion': 'v2.0',
        'computedAt': '2024-06-15T10:30:00.000',
        'asOf': '2024-06-15T10:00:00.000',
        'status': 'stale',
        'computationMeta': {
          'durationMs': 300,
          'eventsProcessed': 50,
          'algorithm': 'sum',
        },
        'metadata': {'source': 'auto'},
      };

      final view = View.fromJson(json);

      expect(view.viewId, equals('view-1'));
      expect(view.workspaceId, equals('ws-1'));
      expect(view.viewType, equals('monthly-summary'));
      expect(view.title, equals('June Summary'));
      expect(view.period.start, equals(DateTime(2024, 6, 1)));
      expect(view.period.end, equals(DateTime(2024, 6, 30)));
      expect(view.scope, equals('project-alpha'));
      expect(view.dimensions['category'], equals('finance'));
      expect(view.metrics['total'], equals(42));
      expect(view.sourceRefs, equals(['evt-1', 'evt-2']));
      expect(view.policyVersion, equals('v2.0'));
      expect(view.computedAt, equals(DateTime(2024, 6, 15, 10, 30)));
      expect(view.asOf, equals(DateTime(2024, 6, 15, 10, 0)));
      expect(view.status, equals(ViewStatus.stale));
      expect(view.computationMeta, isNotNull);
      expect(view.computationMeta!.algorithm, equals('sum'));
      expect(view.metadata['source'], equals('auto'));
    });

    test('fromJson with empty map uses defaults', () {
      final before = DateTime.now();
      final view = View.fromJson({});
      final after = DateTime.now();

      expect(view.viewId, equals(''));
      expect(view.workspaceId, equals('default'));
      expect(view.viewType, equals(''));
      expect(view.title, equals(''));
      expect(view.scope, equals(''));
      expect(view.dimensions, isEmpty);
      expect(view.metrics, isEmpty);
      expect(view.sourceRefs, isEmpty);
      expect(view.policyVersion, isNull);
      expect(view.status, equals(ViewStatus.current));
      expect(view.computationMeta, isNull);
      expect(view.metadata, isEmpty);
      // computedAt and asOf should be close to now
      expect(
        view.computedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        view.asOf.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('fromJson with null optional fields', () {
      final json = {
        'viewId': 'v-1',
        'computedAt': '2024-01-01T00:00:00.000',
        'asOf': '2024-01-01T00:00:00.000',
        'policyVersion': null,
        'computationMeta': null,
        'dimensions': null,
        'metrics': null,
        'sourceRefs': null,
        'metadata': null,
        'period': null,
        'status': null,
      };
      final view = View.fromJson(json);

      expect(view.viewId, equals('v-1'));
      expect(view.policyVersion, isNull);
      expect(view.computationMeta, isNull);
      expect(view.dimensions, isEmpty);
      expect(view.metrics, isEmpty);
      expect(view.sourceRefs, isEmpty);
      expect(view.metadata, isEmpty);
    });

    test('toJson with fully populated view', () {
      final view = createFullView();
      final json = view.toJson();

      expect(json['viewId'], equals('view-1'));
      expect(json['workspaceId'], equals('ws-1'));
      expect(json['viewType'], equals('monthly-summary'));
      expect(json['title'], equals('June Summary'));
      expect(json['period'], isA<Map>());
      expect(json['scope'], equals('project-alpha'));
      expect(json['dimensions'], equals({'category': 'finance', 'region': 'us'}));
      expect(json['metrics'], equals({'total': 42, 'average': 7.0}));
      expect(json['sourceRefs'], equals(['evt-1', 'evt-2']));
      expect(json['policyVersion'], equals('v2.0'));
      expect(json['computedAt'], equals(fixedTime.toIso8601String()));
      expect(json['asOf'], equals(fixedAsOf.toIso8601String()));
      expect(json['status'], equals('current'));
      expect(json['computationMeta'], isA<Map>());
      expect(json['metadata'], equals({'source': 'auto'}));
    });

    test('toJson excludes empty/null fields', () {
      final view = View(
        viewId: 'view-1',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'Test',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );
      final json = view.toJson();

      expect(json.containsKey('dimensions'), isFalse);
      expect(json.containsKey('metrics'), isFalse);
      expect(json.containsKey('sourceRefs'), isFalse);
      expect(json.containsKey('policyVersion'), isFalse);
      expect(json.containsKey('computationMeta'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('copyWith modifies specified fields', () {
      final original = createFullView();
      final copy = original.copyWith(
        viewId: 'view-2',
        title: 'Updated Title',
        status: ViewStatus.stale,
        policyVersion: 'v3.0',
      );

      expect(copy.viewId, equals('view-2'));
      expect(copy.title, equals('Updated Title'));
      expect(copy.status, equals(ViewStatus.stale));
      expect(copy.policyVersion, equals('v3.0'));
      // Unchanged fields
      expect(copy.workspaceId, equals('ws-1'));
      expect(copy.viewType, equals('monthly-summary'));
      expect(copy.scope, equals('project-alpha'));
      expect(copy.dimensions, equals(original.dimensions));
      expect(copy.metrics, equals(original.metrics));
      expect(copy.sourceRefs, equals(original.sourceRefs));
      expect(copy.computedAt, equals(original.computedAt));
      expect(copy.asOf, equals(original.asOf));
      expect(copy.computationMeta, equals(original.computationMeta));
      expect(copy.metadata, equals(original.metadata));
    });

    test('copyWith with no arguments returns equivalent view', () {
      final original = createFullView();
      final copy = original.copyWith();

      expect(copy.viewId, equals(original.viewId));
      expect(copy.workspaceId, equals(original.workspaceId));
      expect(copy.viewType, equals(original.viewType));
      expect(copy.title, equals(original.title));
      expect(copy.scope, equals(original.scope));
      expect(copy.status, equals(original.status));
    });

    test('copyWith all fields', () {
      final original = createFullView();
      final newTime = DateTime(2025, 1, 1);
      final newPeriod = ViewPeriod(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 1, 31),
      );
      const newMeta = ComputationMeta(
        durationMs: 999,
        eventsProcessed: 999,
        algorithm: 'new-algo',
      );

      final copy = original.copyWith(
        viewId: 'new-id',
        workspaceId: 'new-ws',
        viewType: 'new-type',
        title: 'New Title',
        period: newPeriod,
        scope: 'new-scope',
        dimensions: {'x': 1},
        metrics: {'y': 2},
        sourceRefs: ['ref-99'],
        policyVersion: 'v99',
        computedAt: newTime,
        asOf: newTime,
        status: ViewStatus.archived,
        computationMeta: newMeta,
        metadata: {'z': 3},
      );

      expect(copy.viewId, equals('new-id'));
      expect(copy.workspaceId, equals('new-ws'));
      expect(copy.viewType, equals('new-type'));
      expect(copy.title, equals('New Title'));
      expect(copy.period.start, equals(DateTime(2025, 1, 1)));
      expect(copy.scope, equals('new-scope'));
      expect(copy.dimensions, equals({'x': 1}));
      expect(copy.metrics, equals({'y': 2}));
      expect(copy.sourceRefs, equals(['ref-99']));
      expect(copy.policyVersion, equals('v99'));
      expect(copy.computedAt, equals(newTime));
      expect(copy.asOf, equals(newTime));
      expect(copy.status, equals(ViewStatus.archived));
      expect(copy.computationMeta!.algorithm, equals('new-algo'));
      expect(copy.metadata, equals({'z': 3}));
    });

    test('toString returns expected format', () {
      final view = createFullView();
      final str = view.toString();

      expect(str, contains('View'));
      expect(str, contains('view-1'));
      expect(str, contains('monthly-summary'));
      expect(str, contains('June Summary'));
    });

    test('equality compares by viewId', () {
      final view1 = View(
        viewId: 'view-1',
        workspaceId: 'ws-1',
        viewType: 'a',
        title: 'A',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'x',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );
      final view2 = View(
        viewId: 'view-1',
        workspaceId: 'ws-2',
        viewType: 'b',
        title: 'B',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'y',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );
      final view3 = View(
        viewId: 'view-999',
        workspaceId: 'ws-1',
        viewType: 'a',
        title: 'A',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'x',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );

      expect(view1 == view2, isTrue);
      expect(view1 == view3, isFalse);
      expect(view1.hashCode, equals(view2.hashCode));
    });

    test('fromJson roundtrip preserves data', () {
      final original = createFullView();
      final json = original.toJson();
      final restored = View.fromJson(json);

      expect(restored.viewId, equals(original.viewId));
      expect(restored.workspaceId, equals(original.workspaceId));
      expect(restored.viewType, equals(original.viewType));
      expect(restored.title, equals(original.title));
      expect(restored.scope, equals(original.scope));
      expect(restored.dimensions, equals(original.dimensions));
      expect(restored.metrics, equals(original.metrics));
      expect(restored.sourceRefs, equals(original.sourceRefs));
      expect(restored.policyVersion, equals(original.policyVersion));
      expect(restored.status, equals(original.status));
      expect(
        restored.computationMeta!.algorithm,
        equals(original.computationMeta!.algorithm),
      );
    });

    test('equality with identical reference', () {
      final view = View(
        viewId: 'view-self',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'Self',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );

      expect(view == view, isTrue);
    });

    test('equality with non-View object', () {
      final view = View(
        viewId: 'view-type',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'Type check',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );

      expect(view == Object(), isFalse);
    });

    test('hashCode is based on viewId', () {
      final view = View(
        viewId: 'view-hash',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'Hash test',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
      );

      expect(view.hashCode, equals('view-hash'.hashCode));
    });

    test('constructor with computationMeta with warnings', () {
      final view = View(
        viewId: 'view-meta-warn',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'With warnings',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
        computationMeta: const ComputationMeta(
          durationMs: 200,
          eventsProcessed: 30,
          algorithm: 'weighted',
          warnings: ['low data', 'estimated values'],
        ),
      );

      expect(view.computationMeta, isNotNull);
      expect(view.computationMeta!.warnings, hasLength(2));
    });

    test('fromJson with computationMeta with warnings', () {
      final json = {
        'viewId': 'view-cm-warn',
        'workspaceId': 'ws-1',
        'viewType': 'detail',
        'title': 'CM Warnings',
        'period': {
          'start': '2024-06-01T00:00:00.000',
          'end': '2024-06-30T00:00:00.000',
        },
        'scope': 'project',
        'computedAt': '2024-06-15T10:30:00.000',
        'asOf': '2024-06-15T10:00:00.000',
        'computationMeta': {
          'durationMs': 500,
          'eventsProcessed': 100,
          'algorithm': 'v2',
          'warnings': ['partial data', 'timeout risk'],
        },
      };

      final view = View.fromJson(json);

      expect(view.computationMeta, isNotNull);
      expect(view.computationMeta!.durationMs, equals(500));
      expect(view.computationMeta!.eventsProcessed, equals(100));
      expect(view.computationMeta!.algorithm, equals('v2'));
      expect(view.computationMeta!.warnings, hasLength(2));
    });

    test('toJson with computationMeta', () {
      final view = View(
        viewId: 'view-cm-json',
        workspaceId: 'ws-1',
        viewType: 'summary',
        title: 'CM JSON',
        period: ViewPeriod(start: periodStart, end: periodEnd),
        scope: 'global',
        computedAt: fixedTime,
        asOf: fixedAsOf,
        computationMeta: const ComputationMeta(
          durationMs: 100,
          eventsProcessed: 10,
          algorithm: 'basic',
        ),
      );

      final json = view.toJson();

      expect(json['computationMeta'], isA<Map>());
      final cm = json['computationMeta'] as Map<String, dynamic>;
      expect(cm['durationMs'], equals(100));
      expect(cm['eventsProcessed'], equals(10));
      expect(cm['algorithm'], equals('basic'));
      // warnings is empty, so should not be included
      expect(cm.containsKey('warnings'), isFalse);
    });

    test('copyWith computationMeta and metadata', () {
      final original = createFullView();
      final newMeta = const ComputationMeta(
        durationMs: 999,
        eventsProcessed: 500,
        algorithm: 'advanced',
        warnings: ['new warning'],
      );

      final copy = original.copyWith(
        computationMeta: newMeta,
        metadata: {'new': 'data'},
      );

      expect(copy.computationMeta!.durationMs, equals(999));
      expect(copy.computationMeta!.warnings, equals(['new warning']));
      expect(copy.metadata, equals({'new': 'data'}));
    });

    test('fromJson with status computing', () {
      final json = {
        'viewId': 'view-computing',
        'status': 'computing',
        'computedAt': '2024-01-01T00:00:00.000',
        'asOf': '2024-01-01T00:00:00.000',
      };

      final view = View.fromJson(json);
      expect(view.status, equals(ViewStatus.computing));
    });

    test('fromJson with status archived', () {
      final json = {
        'viewId': 'view-archived',
        'status': 'archived',
        'computedAt': '2024-01-01T00:00:00.000',
        'asOf': '2024-01-01T00:00:00.000',
      };

      final view = View.fromJson(json);
      expect(view.status, equals(ViewStatus.archived));
    });
  });

  // =========================================================================
  // ViewPeriod additional tests
  // =========================================================================
  group('ViewPeriod additional', () {
    test('fromJson with start only uses now for end', () {
      final json = {'start': '2024-01-01T00:00:00.000'};
      final period = ViewPeriod.fromJson(json);

      expect(period.start, equals(DateTime(2024, 1, 1)));
      expect(period.end, isA<DateTime>());
    });

    test('fromJson with end only uses now for start', () {
      final json = {'end': '2024-12-31T00:00:00.000'};
      final period = ViewPeriod.fromJson(json);

      expect(period.start, isA<DateTime>());
      expect(period.end, equals(DateTime(2024, 12, 31)));
    });

    test('toJson roundtrip', () {
      final original = ViewPeriod(
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );
      final json = original.toJson();
      final restored = ViewPeriod.fromJson(json);

      expect(restored.start, equals(original.start));
      expect(restored.end, equals(original.end));
      expect(restored.duration, equals(original.duration));
    });
  });

  // =========================================================================
  // ComputationMeta additional tests
  // =========================================================================
  group('ComputationMeta additional', () {
    test('toJson roundtrip with warnings', () {
      const original = ComputationMeta(
        durationMs: 300,
        eventsProcessed: 50,
        algorithm: 'sum',
        warnings: ['warning1', 'warning2'],
      );

      final json = original.toJson();
      final restored = ComputationMeta.fromJson(json);

      expect(restored.durationMs, equals(original.durationMs));
      expect(restored.eventsProcessed, equals(original.eventsProcessed));
      expect(restored.algorithm, equals(original.algorithm));
      expect(restored.warnings, equals(original.warnings));
    });
  });
}
