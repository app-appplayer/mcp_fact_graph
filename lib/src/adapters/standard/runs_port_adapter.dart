/// RunsPortAdapter - Implements mcp_bundle's capability `RunsPort`.
///
/// MOD-INFRA-018. Delegates to [RunStoragePort]. Maps the 5-valued
/// `bundle.RunStatus` onto the 4-valued internal `RunStatus`
/// (blocked/cancelled are reconstructed from a single reserved
/// metadata log entry).
library;

import 'dart:convert';

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/run.dart' as local;
import '../../ports/storage_port.dart' as storage;

/// Implements `bundle.RunsPort` on top of `RunStoragePort`.
class RunsPortAdapter implements bundle.RunsPort {
  final storage.RunStoragePort _storagePort;
  final String _defaultWorkspaceId;

  RunsPortAdapter({
    required storage.RunStoragePort runStoragePort,
    String defaultWorkspaceId = 'default',
  })  : _storagePort = runStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<void> writeRun(bundle.RunRecord record) async {
    final existing =
        await _storagePort.getRunByIdempotencyKey(_deriveKey(record));
    if (existing != null) {
      return;
    }
    await _storagePort.saveRun(_recordToInternal(record));
  }

  @override
  Future<List<bundle.RunRecord>> queryRuns(bundle.RunQuery query) async {
    final statuses = query.statuses;
    final collected = <local.Run>[];
    if (statuses == null || statuses.isEmpty) {
      collected.addAll(
        await _storagePort.queryRuns(
          storage.RunQuery(
            workspaceId: query.workspaceId,
            jobId: query.producerId,
            fromDate: query.startedAfter,
            toDate: query.startedBefore,
            limit: query.limit,
          ),
        ),
      );
    } else {
      for (final status in statuses) {
        collected.addAll(
          await _storagePort.queryRuns(
            storage.RunQuery(
              workspaceId: query.workspaceId,
              jobId: query.producerId,
              status: _toLocalStatus(status),
              fromDate: query.startedAfter,
              toDate: query.startedBefore,
              limit: query.limit,
            ),
          ),
        );
        if (query.limit != null && collected.length >= query.limit!) break;
      }
    }

    var result = collected;
    if (query.producerKind != null) {
      result = result.where((r) {
        final meta = _readBundleMeta(r);
        return meta?['producerKind'] == query.producerKind;
      }).toList();
    }
    if (query.limit != null && result.length > query.limit!) {
      result = result.take(query.limit!).toList();
    }
    return result.map(_internalToRecord).toList();
  }

  @override
  Future<bundle.RunRecord?> getRun(String id) async {
    final internal = await _storagePort.getRun(id);
    if (internal == null) return null;
    return _internalToRecord(internal);
  }

  // ---- Conversion helpers ----
  //
  // Bundle-specific metadata that has no first-class slot on the
  // internal `Run` entity is carried inside a **single** reserved
  // `LogEntry` whose `message` is a JSON-encoded blob prefixed with
  // [_metaLogPrefix]. Phase 2.1 replaces the previous multi-line
  // scattered `producerKind=...` / `producerVersion=...` / `claimId=...`
  // log entries. Outbound conversion parses the same blob.

  static const String _metaLogPrefix = '__bundle_run_meta__:';
  static const String _statusBlocked = 'blocked';
  static const String _statusCancelled = 'cancelled';

  local.Run _recordToInternal(bundle.RunRecord record) {
    final meta = <String, dynamic>{
      'producerKind': record.producerKind,
      if (record.producerVersion != null) 'producerVersion': record.producerVersion,
      if (record.claimIds.isNotEmpty) 'claimIds': record.claimIds,
      if (record.status == bundle.RunStatus.blocked)
        'bundleStatusMarker': _statusBlocked,
      if (record.status == bundle.RunStatus.cancelled)
        'bundleStatusMarker': _statusCancelled,
    };
    final logs = <local.LogEntry>[
      local.LogEntry(
        timestamp: record.startedAt,
        level: 'info',
        message: '$_metaLogPrefix${jsonEncode(meta)}',
      ),
    ];
    return local.Run(
      runId: record.id,
      jobId: record.producerId,
      startedAt: record.startedAt,
      finishedAt: record.finishedAt,
      status: _toLocalStatus(record.status),
      idempotencyKey: _deriveKey(record),
      input: local.RunInput(
        asOf: record.startedAt,
        policyVersion: record.producerVersion ?? '1.0.0',
        inputEventIds: List<String>.from(record.evidenceRefs),
        params: Map<String, dynamic>.from(record.inputs),
      ),
      output: record.outputs == null
          ? null
          : local.RunOutput(metrics: Map<String, dynamic>.from(record.outputs!)),
      logs: logs,
      workspaceId: record.workspaceId.isEmpty
          ? _defaultWorkspaceId
          : record.workspaceId,
    );
  }

  bundle.RunRecord _internalToRecord(local.Run run) {
    final meta = _readBundleMeta(run);
    final kind = (meta?['producerKind'] as String?) ?? 'skill';
    final version = meta?['producerVersion'] as String?;
    final claimIds = (meta?['claimIds'] as List?)?.cast<String>() ??
        const <String>[];
    final statusHint = meta?['bundleStatusMarker'] as String?;
    bundle.RunStatus status;
    if (statusHint == _statusBlocked) {
      status = bundle.RunStatus.blocked;
    } else if (statusHint == _statusCancelled) {
      status = bundle.RunStatus.cancelled;
    } else {
      status = _toBundleStatus(run.status);
    }
    return bundle.RunRecord(
      id: run.runId,
      workspaceId: run.workspaceId ?? _defaultWorkspaceId,
      producerId: run.jobId,
      producerKind: kind,
      producerVersion: version,
      startedAt: run.startedAt,
      finishedAt: run.finishedAt,
      status: status,
      inputs: Map<String, dynamic>.from(run.input.params),
      outputs:
          run.output == null ? null : Map<String, dynamic>.from(run.output!.metrics),
      claimIds: claimIds,
      evidenceRefs: List<String>.from(run.input.inputEventIds),
    );
  }

  Map<String, dynamic>? _readBundleMeta(local.Run run) {
    for (final log in run.logs) {
      if (log.message.startsWith(_metaLogPrefix)) {
        try {
          final decoded =
              jsonDecode(log.message.substring(_metaLogPrefix.length));
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          // Fall through to null — metadata is best-effort.
        }
      }
    }
    return null;
  }

  local.RunStatus _toLocalStatus(bundle.RunStatus s) {
    switch (s) {
      case bundle.RunStatus.running:
      case bundle.RunStatus.blocked:
        return local.RunStatus.running;
      case bundle.RunStatus.completed:
        return local.RunStatus.success;
      case bundle.RunStatus.failed:
      case bundle.RunStatus.cancelled:
        return local.RunStatus.failed;
    }
  }

  bundle.RunStatus _toBundleStatus(local.RunStatus s) {
    switch (s) {
      case local.RunStatus.running:
        return bundle.RunStatus.running;
      case local.RunStatus.success:
        return bundle.RunStatus.completed;
      case local.RunStatus.failed:
        return bundle.RunStatus.failed;
      case local.RunStatus.skipped:
        return bundle.RunStatus.cancelled;
    }
  }

  String _deriveKey(bundle.RunRecord record) {
    return '${record.producerId}:${record.startedAt.toIso8601String()}';
  }
}
