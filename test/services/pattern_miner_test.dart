// Tests for PatternMiner - L0 pattern extraction over confirmed facts.

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:test/test.dart';

/// Minimal in-memory FactStoragePort for mining tests.
class _InMemoryFactStorage implements FactStoragePort {
  final Map<String, Fact> _facts = {};

  @override
  Future<void> saveFact(Fact fact) async {
    _facts[fact.factId] = fact;
  }

  @override
  Future<Fact?> getFact(String factId) async => _facts[factId];

  @override
  Future<List<Fact>> queryFacts(FactQuery query) async {
    return _facts.values.where((f) {
      if (query.workspaceId != null && f.workspaceId != query.workspaceId) {
        return false;
      }
      if (query.factType != null && f.factType != query.factType) return false;
      if (query.status != null && f.status != query.status) return false;
      if (query.fromDate != null && f.occurredAt.isBefore(query.fromDate!)) {
        return false;
      }
      if (query.toDate != null && f.occurredAt.isAfter(query.toDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Fact>> getFactsForEntity(String entityId) async {
    return _facts.values.where((f) => f.entityRefs.contains(entityId)).toList();
  }

  @override
  Future<void> deleteFact(String factId) async {
    _facts.remove(factId);
  }
}

/// Collecting fake PatternsPort — records everything passed to
/// [storePattern] so tests can assert on it.
class _CollectingPatternsPort implements bundle.PatternsPort {
  final List<bundle.PatternRecord> stored = [];

  @override
  Future<String> storePattern(bundle.PatternRecord pattern) async {
    stored.add(pattern);
    return pattern.id;
  }

  @override
  Future<List<bundle.PatternRecord>> queryPatterns(
    bundle.PatternQuery query,
  ) async {
    return stored
        .where((p) => p.workspaceId == query.workspaceId)
        .toList(growable: false);
  }

  @override
  Future<bundle.PatternRecord?> getPattern(String id) async {
    for (final p in stored) {
      if (p.id == id) return p;
    }
    return null;
  }
}

Fact _makeFact({
  required String factId,
  required String factType,
  required List<String> entityRefs,
  required DateTime occurredAt,
  String workspaceId = 'ws1',
}) {
  return Fact(
    factId: factId,
    workspaceId: workspaceId,
    factType: factType,
    summary: 'summary-$factId',
    occurredAt: occurredAt,
    candidateId: 'cand-$factId',
    entityRefs: entityRefs,
    createdAt: occurredAt,
  );
}

void main() {
  group('PatternMiner.mineFrequency', () {
    test('emits pattern when entity+factType repeats >= minOccurrences',
        () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < 4; i++) {
        await facts.saveFact(_makeFact(
          factId: 'f$i',
          factType: 'expense',
          entityRefs: const ['user-1'],
          occurredAt: base.add(Duration(days: i)),
        ));
      }
      // A second entity with only one occurrence -- must NOT trigger.
      await facts.saveFact(_makeFact(
        factId: 'f-other',
        factType: 'expense',
        entityRefs: const ['user-2'],
        occurredAt: base,
      ));

      final results = await miner.mineFrequency('ws1');

      expect(results.length, 1);
      final record = results.single;
      expect(record.type, 'frequency');
      expect(record.frequency, 4);
      expect(record.entityIds, ['user-1']);
      expect(record.confidence, inInclusiveRange(0.5, 1.0));
      expect(port.stored.length, 1);
    });

    test('returns empty when below threshold', () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      await facts.saveFact(_makeFact(
        factId: 'f0',
        factType: 'expense',
        entityRefs: const ['user-1'],
        occurredAt: DateTime(2026, 1, 1),
      ));

      final results = await miner.mineFrequency('ws1');
      expect(results, isEmpty);
      expect(port.stored, isEmpty);
    });

    test('respects enabled=false', () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner = PatternMiner(
        factStorage: facts,
        patternStorage: port,
        enabled: false,
      );

      for (var i = 0; i < 10; i++) {
        await facts.saveFact(_makeFact(
          factId: 'f$i',
          factType: 'expense',
          entityRefs: const ['user-1'],
          occurredAt: DateTime(2026, 1, 1).add(Duration(days: i)),
        ));
      }

      final results = await miner.mineAll('ws1');
      expect(results, isEmpty);
      expect(port.stored, isEmpty);
    });
  });

  group('PatternMiner.mineCoOccurrence', () {
    test('emits pattern when two factTypes co-occur on minPairs+ entities',
        () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1);
      // user-1 has both expense and schedule.
      await facts.saveFact(_makeFact(
        factId: 'a1',
        factType: 'expense',
        entityRefs: const ['user-1'],
        occurredAt: base,
      ));
      await facts.saveFact(_makeFact(
        factId: 'a2',
        factType: 'schedule',
        entityRefs: const ['user-1'],
        occurredAt: base,
      ));
      // user-2 also has both.
      await facts.saveFact(_makeFact(
        factId: 'b1',
        factType: 'expense',
        entityRefs: const ['user-2'],
        occurredAt: base,
      ));
      await facts.saveFact(_makeFact(
        factId: 'b2',
        factType: 'schedule',
        entityRefs: const ['user-2'],
        occurredAt: base,
      ));

      final results = await miner.mineCoOccurrence('ws1');
      expect(results.length, 1);
      final r = results.single;
      expect(r.type, 'co_occurrence');
      expect(r.entityIds.toSet(), {'user-1', 'user-2'});
      expect(r.frequency, 2);
    });

    test('does not emit when only one entity has the pair', () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1);
      await facts.saveFact(_makeFact(
        factId: 'a1',
        factType: 'expense',
        entityRefs: const ['user-1'],
        occurredAt: base,
      ));
      await facts.saveFact(_makeFact(
        factId: 'a2',
        factType: 'schedule',
        entityRefs: const ['user-1'],
        occurredAt: base,
      ));

      final results = await miner.mineCoOccurrence('ws1');
      expect(results, isEmpty);
    });
  });

  group('PatternMiner.mineTemporal', () {
    test('detects daily cadence for repeated factType on an entity',
        () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1, 9, 0, 0);
      for (var i = 0; i < 5; i++) {
        await facts.saveFact(_makeFact(
          factId: 'd$i',
          factType: 'standup',
          entityRefs: const ['team-1'],
          // Small jitter but within +/-30% tolerance of one day.
          occurredAt: base.add(Duration(
            days: i,
            minutes: (i * 7) % 30,
          )),
        ));
      }

      final results = await miner.mineTemporal('ws1');
      expect(results.length, 1);
      final r = results.single;
      expect(r.type, 'temporal');
      expect(r.features['interval'], 'day');
      expect(r.entityIds, ['team-1']);
    });

    test('skips irregular streams', () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1);
      // Very irregular intervals.
      final offsets = [0, 1, 30, 31, 200, 365];
      for (var i = 0; i < offsets.length; i++) {
        await facts.saveFact(_makeFact(
          factId: 'r$i',
          factType: 'review',
          entityRefs: const ['user-1'],
          occurredAt: base.add(Duration(days: offsets[i])),
        ));
      }

      final results = await miner.mineTemporal('ws1');
      expect(results, isEmpty);
    });
  });

  group('PatternMiner.mineAll', () {
    test('runs all three algorithms and persists results via PatternsPort',
        () async {
      final facts = _InMemoryFactStorage();
      final port = _CollectingPatternsPort();
      final miner =
          PatternMiner(factStorage: facts, patternStorage: port);

      final base = DateTime(2026, 1, 1, 9, 0, 0);
      // Enough facts to trigger frequency AND temporal (daily).
      for (var i = 0; i < 5; i++) {
        await facts.saveFact(_makeFact(
          factId: 'd$i',
          factType: 'standup',
          entityRefs: const ['team-1'],
          occurredAt: base.add(Duration(days: i)),
        ));
      }
      // Additional co-occurrence: 'standup' + 'retro' on team-1 and team-2.
      await facts.saveFact(_makeFact(
        factId: 'r1',
        factType: 'retro',
        entityRefs: const ['team-1'],
        occurredAt: base,
      ));
      for (var i = 0; i < 3; i++) {
        await facts.saveFact(_makeFact(
          factId: 's2-$i',
          factType: 'standup',
          entityRefs: const ['team-2'],
          occurredAt: base.add(Duration(days: i)),
        ));
      }
      await facts.saveFact(_makeFact(
        factId: 'r2',
        factType: 'retro',
        entityRefs: const ['team-2'],
        occurredAt: base,
      ));

      final results = await miner.mineAll('ws1');
      expect(results, isNotEmpty);
      expect(port.stored.length, results.length);

      final types = results.map((r) => r.type).toSet();
      expect(types, containsAll(<String>{'frequency'}));
    });
  });
}
