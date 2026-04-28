/// SummariesPortAdapter - Implements mcp_bundle's capability `SummariesPort`.
///
/// MOD-INFRA-017. Fact-level summary storage and refresh on top of
/// [ContextStoragePort]. The Phase 2 implementation does not require an
/// LLM: `refreshSummary` simply re-persists an updated `SummaryNode`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/summary_node.dart';
import '../../ports/storage_port.dart' as storage;

/// Implements `bundle.SummariesPort` on top of `ContextStoragePort`.
class SummariesPortAdapter implements bundle.SummariesPort {
  final storage.ContextStoragePort _storagePort;
  final String _defaultWorkspaceId;

  SummariesPortAdapter({
    required storage.ContextStoragePort contextStoragePort,
    String defaultWorkspaceId = 'default',
  })  : _storagePort = contextStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<bundle.SummaryRecord?> getSummary(
    String entityId,
    String summaryType, {
    bundle.Period? period,
  }) async {
    final syntheticId = _syntheticId(entityId, summaryType);
    final direct = await _storagePort.getSummaryNode(syntheticId);
    if (direct != null) return _nodeToRecord(direct);

    final scoped = await _storagePort.querySummaryNodes(
      storage.SummaryNodeQuery(
        workspaceId: _defaultWorkspaceId,
        scopeType: summaryType,
      ),
    );
    for (final node in scoped) {
      if (node.scope.entityId == entityId) {
        return _nodeToRecord(node);
      }
    }
    return null;
  }

  @override
  Future<bundle.SummaryRecord> refreshSummary(
    String entityId,
    String summaryType, {
    bundle.Period? period,
  }) async {
    final syntheticId = _syntheticId(entityId, summaryType);
    final existing = await _storagePort.getSummaryNode(syntheticId);
    final now = DateTime.now();
    final node = existing?.copyWith(
          status: SummaryStatus.active,
          updatedAt: now,
        ) ??
        SummaryNode(
          summaryId: syntheticId,
          workspaceId: _defaultWorkspaceId,
          summaryText: '',
          asOf: now,
          policyVersion: '1.0.0',
          status: SummaryStatus.active,
          scope: SummaryScope(scopeType: summaryType, entityId: entityId),
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        );
    await _storagePort.saveSummaryNode(node);
    return _nodeToRecord(node);
  }

  @override
  Future<void> markSummariesStale(
    List<String> entityIds, {
    String? summaryType,
  }) async {
    for (final entityId in entityIds) {
      final nodes = await _storagePort.querySummaryNodes(
        storage.SummaryNodeQuery(
          workspaceId: _defaultWorkspaceId,
          scopeType: summaryType,
        ),
      );
      for (final node in nodes) {
        if (node.scope.entityId != entityId) continue;
        final stale = node.copyWith(
          status: SummaryStatus.stale,
          updatedAt: DateTime.now(),
        );
        await _storagePort.saveSummaryNode(stale);
      }
    }
  }

  @override
  Future<List<bundle.SummaryRecord>> getStaleSummaries({int? limit}) async {
    final nodes = await _storagePort.querySummaryNodes(
      storage.SummaryNodeQuery(
        workspaceId: _defaultWorkspaceId,
        status: SummaryStatus.stale,
        limit: limit,
      ),
    );
    return nodes.map(_nodeToRecord).toList();
  }

  // ---- Conversion helpers ----

  bundle.SummaryRecord _nodeToRecord(SummaryNode node) {
    final entityId = node.scope.entityId ?? '';
    return bundle.SummaryRecord(
      id: node.summaryId,
      entityId: entityId,
      type: node.scope.scopeType,
      content: node.summaryText,
      isStale: node.status == SummaryStatus.stale,
      sourceFactIds: List<String>.from(node.coversFactIds),
      createdAt: node.createdAt,
      refreshedAt: node.updatedAt,
    );
  }

  String _syntheticId(String entityId, String summaryType) =>
      'sum_${entityId}_$summaryType';
}
