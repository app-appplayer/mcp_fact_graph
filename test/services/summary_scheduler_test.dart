/// Unit tests for [SummaryScheduler] — C3.
library;

import 'dart:async';

import 'package:mcp_fact_graph/src/adapters/standard/summaries_port_adapter.dart';
import 'package:mcp_fact_graph/src/services/summary_scheduler.dart';
import 'package:mcp_fact_graph/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  group('SummaryScheduler', () {
    late InMemoryStorageContainer storage;
    late SummariesPortAdapter summaries;

    setUp(() {
      storage = InMemoryStorageContainer();
      summaries = SummariesPortAdapter(
        contextStoragePort: storage.context,
        defaultWorkspaceId: 'ws1',
      );
    });

    test('triggerOnce refreshes stale summaries', () async {
      await summaries.refreshSummary('ent-1', 'rollup');
      await summaries.refreshSummary('ent-2', 'rollup');
      await summaries.markSummariesStale(['ent-1', 'ent-2']);

      final scheduler = SummaryScheduler(summaries: summaries);
      final count = await scheduler.triggerOnce();
      expect(count, 2);

      final remaining = await summaries.getStaleSummaries();
      expect(remaining, isEmpty);
    });

    test('triggerOnce is no-op when disabled', () async {
      await summaries.refreshSummary('ent-9', 'rollup');
      await summaries.markSummariesStale(['ent-9']);

      final scheduler = SummaryScheduler(
        summaries: summaries,
        enabled: false,
      );
      expect(await scheduler.triggerOnce(), 0);
      // Stale still present.
      final remaining = await summaries.getStaleSummaries();
      expect(remaining, isNotEmpty);
    });

    test('start/stop manages the Timer', () async {
      final scheduler = SummaryScheduler(
        summaries: summaries,
        interval: const Duration(milliseconds: 50),
      );
      expect(scheduler.isRunning, isFalse);
      scheduler.start();
      expect(scheduler.isRunning, isTrue);
      scheduler.stop();
      expect(scheduler.isRunning, isFalse);
    });

    test('start is idempotent', () {
      final scheduler = SummaryScheduler(
        summaries: summaries,
        interval: const Duration(hours: 1),
      );
      scheduler.start();
      scheduler.start();
      expect(scheduler.isRunning, isTrue);
      scheduler.stop();
    });

    test('disabled scheduler never runs', () {
      final scheduler = SummaryScheduler(
        summaries: summaries,
        enabled: false,
      );
      scheduler.start();
      expect(scheduler.isRunning, isFalse);
    });

    test('periodic tick refreshes stale summaries', () async {
      await summaries.refreshSummary('ent-p', 'rollup');
      await summaries.markSummariesStale(['ent-p']);

      final scheduler = SummaryScheduler(
        summaries: summaries,
        interval: const Duration(milliseconds: 30),
      );
      scheduler.start();
      // Wait through at least two ticks so the periodic callback fires
      // and completes its awaited refresh call.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      scheduler.stop();

      final remaining = await summaries.getStaleSummaries();
      expect(remaining, isEmpty);
    });
  });
}
