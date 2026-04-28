/// PatternsPortAdapter - Implements mcp_bundle's capability `PatternsPort`.
///
/// MOD-INFRA-016. Delegates to [SkillOpsService] + [SkillOpsStoragePort].
/// Converts between `bundle.PatternRecord` and internal `Pattern`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/pattern.dart' as local;
import '../../ports/storage_port.dart' as storage;

/// Implements `bundle.PatternsPort` on top of `SkillOpsStoragePort`.
class PatternsPortAdapter implements bundle.PatternsPort {
  final storage.SkillOpsStoragePort _storagePort;
  final String _defaultWorkspaceId;

  PatternsPortAdapter({
    required storage.SkillOpsStoragePort skillOpsStoragePort,
    String defaultWorkspaceId = 'default',
  })  : _storagePort = skillOpsStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<String> storePattern(bundle.PatternRecord pattern) async {
    final internal = _recordToInternal(pattern);
    await _storagePort.savePattern(internal);
    return internal.patternId;
  }

  @override
  Future<List<bundle.PatternRecord>> queryPatterns(
    bundle.PatternQuery query,
  ) async {
    final internalQuery = storage.PatternQuery(
      workspaceId: query.workspaceId,
      limit: query.limit,
    );
    final results = await _storagePort.queryPatterns(internalQuery);
    var filtered = results;
    if (query.type != null) {
      filtered =
          filtered.where((p) => _bundleMeta(p)['type'] == query.type).toList();
    }
    if (query.entityId != null) {
      filtered = filtered.where((p) {
        final ids = _bundleMeta(p)['entityIds'];
        return ids is List && ids.contains(query.entityId);
      }).toList();
    }
    if (query.minFrequency != null) {
      filtered = filtered.where((p) {
        final freq = _bundleMeta(p)['frequency'];
        return freq is int && freq >= query.minFrequency!;
      }).toList();
    }
    if (query.limit != null && filtered.length > query.limit!) {
      filtered = filtered.take(query.limit!).toList();
    }
    return filtered.map(_internalToRecord).toList();
  }

  Map<String, dynamic> _bundleMeta(local.Pattern p) {
    return (p.metadata[_metaKey] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<bundle.PatternRecord?> getPattern(String id) async {
    final internal = await _storagePort.getPattern(id);
    if (internal == null) return null;
    return _internalToRecord(internal);
  }

  // ---- Conversion helpers ----
  //
  // Bundle-specific metadata (`type`, `frequency`, `entityIds`) is
  // stored inside `Pattern.metadata` under a namespaced sub-map so the
  // internal `features` field stays clean for the domain use-case
  // (pattern observability features). This is the Phase 2.1 cleanup of
  // the earlier features-stuffing trade-off.

  static const _metaKey = '__bundle_pattern__';

  local.Pattern _recordToInternal(bundle.PatternRecord record) {
    final metadata = <String, dynamic>{
      _metaKey: <String, dynamic>{
        'type': record.type,
        'frequency': record.frequency,
        if (record.entityIds.isNotEmpty) 'entityIds': record.entityIds,
      },
    };
    final name = record.description.length > 60
        ? record.description.substring(0, 60)
        : record.description;
    return local.Pattern(
      patternId: record.id,
      workspaceId: record.workspaceId.isEmpty
          ? _defaultWorkspaceId
          : record.workspaceId,
      name: name.isEmpty ? record.id : name,
      description: record.description,
      scope: local.PatternScope.global,
      features: Map<String, dynamic>.from(record.features),
      confidence: record.confidence,
      lastObservedAt: record.detectedAt,
      status: local.PatternStatus.observed,
      createdAt: record.detectedAt,
      updatedAt: record.detectedAt,
      metadata: metadata,
    );
  }

  bundle.PatternRecord _internalToRecord(local.Pattern p) {
    final bundleMeta =
        (p.metadata[_metaKey] as Map<String, dynamic>?) ?? const {};
    final type = (bundleMeta['type'] as String?) ?? 'generic';
    final frequency = (bundleMeta['frequency'] as int?) ?? 1;
    final entityIds =
        (bundleMeta['entityIds'] as List?)?.cast<String>() ?? const <String>[];
    return bundle.PatternRecord(
      id: p.patternId,
      workspaceId: p.workspaceId,
      type: type,
      description: p.description,
      confidence: p.confidence,
      frequency: frequency,
      entityIds: entityIds,
      features: Map<String, dynamic>.from(p.features),
      detectedAt: p.lastObservedAt,
    );
  }
}
