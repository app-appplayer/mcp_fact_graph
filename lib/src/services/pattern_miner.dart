/// PatternMiner - L0 automatic pattern extraction over the fact graph.
///
/// Implements three rule-based algorithms (no LLM) that scan confirmed
/// facts in a workspace and emit `bundle.PatternRecord` entries via the
/// `PatternsPort`:
///
/// 1. Frequency   — entity+factType combinations above a threshold.
/// 2. Co-occurrence — factType pairs that co-appear on the same entity.
/// 3. Temporal    — factTypes that repeat with a detectable interval
///    (hour / day / week) on a specific entity.
///
/// The miner is enabled by default but can be disabled via the `enabled`
/// flag, in which case `mineAll` / the individual `mineX` methods become
/// no-ops.
library;

import 'dart:math' as math;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../domain/entities/fact.dart';
import '../ports/storage_port.dart';

/// L0 pattern miner for the FactGraph layer.
class PatternMiner {
  /// Source of facts to mine.
  final FactStoragePort _factStorage;

  /// Sink used to persist discovered patterns.
  final bundle.PatternsPort _patternsPort;

  /// Master switch — when false the mining methods return empty lists
  /// without touching storage.
  final bool enabled;

  PatternMiner({
    required FactStoragePort factStorage,
    required bundle.PatternsPort patternStorage,
    this.enabled = true,
  })  : _factStorage = factStorage,
        _patternsPort = patternStorage;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Run all three algorithms in sequence and return the flat list of
  /// discovered pattern records (already persisted via PatternsPort).
  Future<List<bundle.PatternRecord>> mineAll(String workspaceId) async {
    if (!enabled) return const [];

    final results = <bundle.PatternRecord>[];
    results.addAll(await mineFrequency(workspaceId));
    results.addAll(await mineCoOccurrence(workspaceId));
    results.addAll(await mineTemporal(workspaceId));
    return results;
  }

  /// Mine frequency patterns: an entityId + factType combination that
  /// appears at least [minOccurrences] times is emitted as a
  /// `kind = 'frequency'` pattern.
  ///
  /// When [withinPeriod] is supplied, only facts whose `occurredAt`
  /// falls inside the trailing window (relative to `DateTime.now()`)
  /// are considered.
  Future<List<bundle.PatternRecord>> mineFrequency(
    String workspaceId, {
    int minOccurrences = 3,
    Duration? withinPeriod,
  }) async {
    if (!enabled) return const [];

    final facts = await _loadFacts(workspaceId, withinPeriod: withinPeriod);
    if (facts.isEmpty) return const [];

    // Group by (entityId, factType) using a pipe-separated composite key
    // since Dart maps cannot use record literals as keys across all SDKs
    // we target without extra tooling.
    final counts = <String, _FrequencyBucket>{};
    for (final fact in facts) {
      for (final entityId in fact.entityRefs) {
        final key = '$entityId||${fact.factType}';
        final bucket = counts.putIfAbsent(
          key,
          () => _FrequencyBucket(
            entityId: entityId,
            factType: fact.factType,
          ),
        );
        bucket.factIds.add(fact.factId);
        if (bucket.lastSeenAt == null ||
            fact.occurredAt.isAfter(bucket.lastSeenAt!)) {
          bucket.lastSeenAt = fact.occurredAt;
        }
      }
    }

    final emitted = <bundle.PatternRecord>[];
    for (final bucket in counts.values) {
      final occurrences = bucket.factIds.length;
      if (occurrences < minOccurrences) continue;

      final confidence = _frequencyConfidence(occurrences);
      final record = bundle.PatternRecord(
        id: _generateId('freq'),
        workspaceId: workspaceId,
        type: 'frequency',
        description:
            'Entity ${bucket.entityId} has $occurrences occurrences of factType ${bucket.factType}',
        confidence: confidence,
        frequency: occurrences,
        entityIds: [bucket.entityId],
        features: {
          'factType': bucket.factType,
          'occurrences': occurrences,
          'factIds': bucket.factIds.toList(),
        },
        detectedAt: bucket.lastSeenAt ?? DateTime.now(),
      );
      await _patternsPort.storePattern(record);
      emitted.add(record);
    }

    return emitted;
  }

  /// Mine co-occurrence patterns: two distinct factTypes that appear
  /// together on at least [minPairs] distinct entities are emitted as a
  /// `kind = 'co_occurrence'` pattern.
  Future<List<bundle.PatternRecord>> mineCoOccurrence(
    String workspaceId, {
    int minPairs = 2,
  }) async {
    if (!enabled) return const [];

    final facts = await _loadFacts(workspaceId);
    if (facts.isEmpty) return const [];

    // entityId -> set of factTypes observed on that entity.
    final perEntity = <String, Set<String>>{};
    for (final fact in facts) {
      for (final entityId in fact.entityRefs) {
        perEntity.putIfAbsent(entityId, () => <String>{}).add(fact.factType);
      }
    }

    // Pair key (sorted to avoid (A,B) / (B,A) duplication) -> supporting entities.
    final pairSupport = <String, _CoOccurrenceBucket>{};
    for (final entry in perEntity.entries) {
      final types = entry.value.toList()..sort();
      for (var i = 0; i < types.length; i++) {
        for (var j = i + 1; j < types.length; j++) {
          final a = types[i];
          final b = types[j];
          final key = '$a||$b';
          final bucket = pairSupport.putIfAbsent(
            key,
            () => _CoOccurrenceBucket(factTypeA: a, factTypeB: b),
          );
          bucket.entityIds.add(entry.key);
        }
      }
    }

    final emitted = <bundle.PatternRecord>[];
    for (final bucket in pairSupport.values) {
      final pairCount = bucket.entityIds.length;
      if (pairCount < minPairs) continue;

      final confidence = _frequencyConfidence(pairCount);
      final record = bundle.PatternRecord(
        id: _generateId('co'),
        workspaceId: workspaceId,
        type: 'co_occurrence',
        description:
            'FactTypes ${bucket.factTypeA} and ${bucket.factTypeB} co-occur on $pairCount entities',
        confidence: confidence,
        frequency: pairCount,
        entityIds: bucket.entityIds.toList(),
        features: {
          'factTypeA': bucket.factTypeA,
          'factTypeB': bucket.factTypeB,
          'entityCount': pairCount,
        },
        detectedAt: DateTime.now(),
      );
      await _patternsPort.storePattern(record);
      emitted.add(record);
    }

    return emitted;
  }

  /// Mine temporal patterns: an entityId+factType stream whose
  /// `occurredAt` values are separated by a roughly constant interval
  /// (hour, day, or week) is emitted as a `kind = 'temporal'` pattern.
  ///
  /// Requires at least three occurrences and a low coefficient of
  /// variation on the inter-arrival deltas to count as periodic.
  /// [window] optionally restricts analysis to the trailing period.
  Future<List<bundle.PatternRecord>> mineTemporal(
    String workspaceId, {
    Duration? window,
  }) async {
    if (!enabled) return const [];

    final facts = await _loadFacts(workspaceId, withinPeriod: window);
    if (facts.length < 3) return const [];

    // Group facts by (entityId, factType) and sort by occurrence time.
    final streams = <String, _TemporalStream>{};
    for (final fact in facts) {
      for (final entityId in fact.entityRefs) {
        final key = '$entityId||${fact.factType}';
        final stream = streams.putIfAbsent(
          key,
          () => _TemporalStream(
            entityId: entityId,
            factType: fact.factType,
          ),
        );
        stream.timestamps.add(fact.occurredAt);
      }
    }

    final emitted = <bundle.PatternRecord>[];
    for (final stream in streams.values) {
      if (stream.timestamps.length < 3) continue;

      stream.timestamps.sort();
      final deltas = <Duration>[];
      for (var i = 1; i < stream.timestamps.length; i++) {
        deltas.add(stream.timestamps[i].difference(stream.timestamps[i - 1]));
      }

      final periodicity = _detectPeriodicity(deltas);
      if (periodicity == null) continue;

      final record = bundle.PatternRecord(
        id: _generateId('temp'),
        workspaceId: workspaceId,
        type: 'temporal',
        description:
            'Entity ${stream.entityId} repeats factType ${stream.factType} every ${periodicity.label}',
        confidence: periodicity.confidence,
        frequency: stream.timestamps.length,
        entityIds: [stream.entityId],
        features: {
          'factType': stream.factType,
          'interval': periodicity.label,
          'meanIntervalSeconds': periodicity.meanSeconds,
          'occurrences': stream.timestamps.length,
        },
        detectedAt: stream.timestamps.last,
      );
      await _patternsPort.storePattern(record);
      emitted.add(record);
    }

    return emitted;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<List<Fact>> _loadFacts(
    String workspaceId, {
    Duration? withinPeriod,
  }) async {
    final fromDate =
        withinPeriod == null ? null : DateTime.now().subtract(withinPeriod);
    final facts = await _factStorage.queryFacts(FactQuery(
      workspaceId: workspaceId,
      fromDate: fromDate,
    ));
    return facts.where((f) => f.status != FactStatus.archived).toList();
  }

  /// Confidence formula per spec:
  ///   clamp(log10(n) / 2, 0.5, 1.0).
  double _frequencyConfidence(int occurrences) {
    if (occurrences <= 0) return 0.5;
    final raw = math.log(occurrences) / math.ln10 / 2.0;
    if (raw < 0.5) return 0.5;
    if (raw > 1.0) return 1.0;
    return raw;
  }

  /// Best-effort periodicity detector. Returns null when deltas are not
  /// tight enough around one of the canonical buckets (hour/day/week).
  _Periodicity? _detectPeriodicity(List<Duration> deltas) {
    if (deltas.isEmpty) return null;

    final seconds = deltas.map((d) => d.inSeconds.toDouble()).toList();
    final mean = seconds.reduce((a, b) => a + b) / seconds.length;
    if (mean <= 0) return null;

    var variance = 0.0;
    for (final s in seconds) {
      final diff = s - mean;
      variance += diff * diff;
    }
    variance /= seconds.length;
    final stdDev = math.sqrt(variance);
    final cv = mean == 0 ? double.infinity : stdDev / mean;

    // Coefficient of variation must stay low; otherwise intervals are
    // not meaningfully periodic.
    if (cv > 0.35) return null;

    // Match against canonical buckets with a +/-30% tolerance.
    const buckets = <_Bucket>[
      _Bucket('hour', 3600),
      _Bucket('day', 86400),
      _Bucket('week', 604800),
    ];
    for (final bucket in buckets) {
      final lower = bucket.seconds * 0.7;
      final upper = bucket.seconds * 1.3;
      if (mean >= lower && mean <= upper) {
        // Confidence = tightness of fit: (1 - cv) in [0.65, 1.0] after
        // the cv<=0.35 guard; clamp to [0.5, 1.0] for safety.
        final confidence = math.max(0.5, math.min(1.0, 1.0 - cv));
        return _Periodicity(
          label: bucket.label,
          meanSeconds: mean,
          confidence: confidence,
        );
      }
    }

    return null;
  }

  int _idCounter = 0;

  String _generateId(String prefix) {
    _idCounter += 1;
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${ts}_$_idCounter';
  }
}

// ---------------------------------------------------------------------------
// Local helper types (file-private)
// ---------------------------------------------------------------------------

class _FrequencyBucket {
  final String entityId;
  final String factType;
  final Set<String> factIds = <String>{};
  DateTime? lastSeenAt;

  _FrequencyBucket({required this.entityId, required this.factType});
}

class _CoOccurrenceBucket {
  final String factTypeA;
  final String factTypeB;
  final Set<String> entityIds = <String>{};

  _CoOccurrenceBucket({required this.factTypeA, required this.factTypeB});
}

class _TemporalStream {
  final String entityId;
  final String factType;
  final List<DateTime> timestamps = <DateTime>[];

  _TemporalStream({required this.entityId, required this.factType});
}

class _Bucket {
  final String label;
  final int seconds;
  const _Bucket(this.label, this.seconds);
}

class _Periodicity {
  final String label;
  final double meanSeconds;
  final double confidence;

  const _Periodicity({
    required this.label,
    required this.meanSeconds,
    required this.confidence,
  });
}
