/// Unit tests for [RunsPortAdapter] — MOD-INFRA-018.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
import 'package:mcp_fact_graph/mcp_fact_graph.dart' as fg;
import 'package:mcp_fact_graph/src/adapters/standard/runs_port_adapter.dart';
import 'package:mcp_fact_graph/src/ports/storage_port.dart' as storage;
import 'package:test/test.dart';

/// Minimal in-memory RunStoragePort for the unit test — copied from the
/// package-private one inside `fact_graph_runtime.dart`.
class _InMemoryRunStorage implements storage.RunStoragePort {
  final Map<String, fg.Run> _runs = {};

  @override
  Future<void> saveRun(fg.Run run) async {
    _runs[run.runId] = run;
  }

  @override
  Future<fg.Run?> getRun(String runId) async => _runs[runId];

  @override
  Future<List<fg.Run>> queryRuns(storage.RunQuery query) async {
    return _runs.values.toList();
  }

  @override
  Future<List<fg.Run>> getRunsForAutomation(String jobId) async =>
      _runs.values.where((r) => r.jobId == jobId).toList();

  @override
  Future<fg.Run?> getRunByIdempotencyKey(String idempotencyKey) async {
    for (final run in _runs.values) {
      if (run.idempotencyKey == idempotencyKey) return run;
    }
    return null;
  }

  @override
  Future<void> deleteRun(String runId) async {
    _runs.remove(runId);
  }
}

void main() {
  group('RunsPortAdapter', () {
    late _InMemoryRunStorage runStorage;
    late RunsPortAdapter adapter;

    setUp(() {
      runStorage = _InMemoryRunStorage();
      adapter = RunsPortAdapter(
        runStoragePort: runStorage,
        defaultWorkspaceId: 'ws1',
      );
    });

    bundle.RunRecord sampleRecord(String id, {
      bundle.RunStatus status = bundle.RunStatus.completed,
    }) {
      return bundle.RunRecord(
        id: id,
        workspaceId: 'ws1',
        producerId: 'skill-1',
        producerKind: 'skill',
        producerVersion: '1.0.0',
        startedAt: DateTime(2026, 4, 11, 12),
        finishedAt: DateTime(2026, 4, 11, 12, 5),
        status: status,
        inputs: const {'q': 'hello'},
      );
    }

    test('writeRun → getRun round trip', () async {
      await adapter.writeRun(sampleRecord('run-1'));
      final fetched = await adapter.getRun('run-1');
      expect(fetched, isNotNull);
      expect(fetched!.producerId, 'skill-1');
      expect(fetched.producerKind, 'skill');
      expect(fetched.status, bundle.RunStatus.completed);
    });

    test('writeRun maps blocked → running + metadata marker', () async {
      await adapter.writeRun(
        sampleRecord('run-blocked', status: bundle.RunStatus.blocked),
      );
      final fetched = await adapter.getRun('run-blocked');
      expect(fetched!.status, bundle.RunStatus.blocked);
    });

    test('writeRun maps cancelled → failed + metadata marker', () async {
      await adapter.writeRun(
        sampleRecord('run-canc', status: bundle.RunStatus.cancelled),
      );
      final fetched = await adapter.getRun('run-canc');
      expect(fetched!.status, bundle.RunStatus.cancelled);
    });

    test('getRun returns null on missing id', () async {
      expect(await adapter.getRun('missing'), isNull);
    });
  });
}
