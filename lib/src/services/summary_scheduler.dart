/// SummaryScheduler - Periodically refresh stale summary nodes.
///
/// C3. Wraps a capability-level `SummariesPort` with a `Timer.periodic`
/// driver that calls `getStaleSummaries()` and invokes
/// `refreshSummary(entityId, type)` on each result. Hosts that want
/// automatic background refresh can call [start]; tests and ad-hoc
/// flows can call [triggerOnce] for a single pass without owning a
/// timer.
///
/// The scheduler does not perform LLM-based summarization itself;
/// it simply drives the port. Errors raised by individual refreshes
/// are swallowed so one failing summary does not stop the tick.
library;

import 'dart:async';

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

/// Periodic driver for stale-summary refresh.
class SummaryScheduler {
  final bundle.SummariesPort _summaries;

  /// How often to fire a refresh pass when [start] is active.
  final Duration interval;

  /// Master enable switch. When false, both [start] and [triggerOnce]
  /// are no-ops and [isRunning] stays false.
  final bool enabled;

  Timer? _timer;

  SummaryScheduler({
    required bundle.SummariesPort summaries,
    this.interval = const Duration(hours: 24),
    this.enabled = true,
  }) : _summaries = summaries;

  /// Whether a periodic timer is currently active.
  bool get isRunning => _timer != null;

  /// Begin periodic refresh passes. Calling `start` while already
  /// running is a no-op.
  void start() {
    if (!enabled) return;
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) {
      // Fire-and-forget; each tick runs in its own microtask so
      // failures in one do not cancel the timer.
      // ignore: unawaited_futures
      _runPass();
    });
  }

  /// Cancel the periodic timer, if any. Safe to call multiple times.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Run a single refresh pass on demand. Returns the number of
  /// summaries that were successfully refreshed.
  Future<int> triggerOnce({int? limit}) async {
    if (!enabled) return 0;
    return _runPass(limit: limit);
  }

  Future<int> _runPass({int? limit}) async {
    int refreshed = 0;
    List<bundle.SummaryRecord> stale;
    try {
      stale = await _summaries.getStaleSummaries(limit: limit);
    } catch (_) {
      // Port failure — nothing we can do on this tick.
      return 0;
    }
    for (final record in stale) {
      try {
        await _summaries.refreshSummary(record.entityId, record.type);
        refreshed += 1;
      } catch (_) {
        // Skip individual failures; continue with the rest.
      }
    }
    return refreshed;
  }
}
