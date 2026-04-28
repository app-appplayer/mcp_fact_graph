/// EntitiesPortAdapter - Implements mcp_bundle's capability `EntitiesPort`.
///
/// MOD-INFRA-013. Exposes entity retrieval, linking, and (placeholder)
/// merging by delegating to `EntityStoragePort` and
/// `RelationStoragePort`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../../domain/entities/entity.dart';
import '../../domain/entities/relation.dart';
import '../../ports/storage_port.dart' as local;
import '../../services/fact_graph_service.dart';

/// Implements `bundle.EntitiesPort` on top of
/// `FactGraphService` + `EntityStoragePort` + `RelationStoragePort`.
class EntitiesPortAdapter implements bundle.EntitiesPort {
  final FactGraphService _factGraphService;
  final local.EntityStoragePort _entityStoragePort;
  final local.RelationStoragePort? _relationStoragePort;
  final String _defaultWorkspaceId;

  EntitiesPortAdapter({
    required FactGraphService factGraphService,
    required local.EntityStoragePort entityStoragePort,
    local.RelationStoragePort? relationStoragePort,
    String defaultWorkspaceId = 'default',
  })  : _factGraphService = factGraphService,
        _entityStoragePort = entityStoragePort,
        _relationStoragePort = relationStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<bundle.EntityRecord?> getEntity(String entityId) async {
    final entity = await _factGraphService.getEntity(entityId);
    if (entity == null) return null;
    return _entityToRecord(entity);
  }

  @override
  Future<void> linkEntity(
    String sourceId,
    String targetId,
    String relation, {
    Map<String, dynamic>? attributes,
  }) async {
    final relationStorage = _relationStoragePort;
    if (relationStorage == null) return;
    final source = await _factGraphService.getEntity(sourceId);
    final ws = source?.workspaceId ?? _defaultWorkspaceId;
    final rel = Relation(
      relationId: _generateId('rel'),
      fromEntityId: sourceId,
      toEntityId: targetId,
      relationType: relation,
      status: RelationStatus.confirmed,
      attributes: Map<String, dynamic>.from(attributes ?? const {})
        ..putIfAbsent('workspaceId', () => ws),
      createdAt: DateTime.now(),
    );
    await relationStorage.saveRelation(rel);
  }

  @override
  Future<List<bundle.EntityRecord>> queryEntities(
    bundle.EntityQuery query,
  ) async {
    final types = query.types;
    final collected = <Entity>[];

    if (types == null || types.isEmpty) {
      final q = local.EntityQuery(
        workspaceId: query.workspaceId,
        namePattern: query.nameContains,
        limit: query.limit,
      );
      collected.addAll(await _entityStoragePort.queryEntities(q));
    } else {
      for (final type in types) {
        final q = local.EntityQuery(
          workspaceId: query.workspaceId,
          entityType: type,
          namePattern: query.nameContains,
          limit: query.limit,
        );
        collected.addAll(await _entityStoragePort.queryEntities(q));
        if (query.limit != null && collected.length >= query.limit!) break;
      }
    }

    var result = collected;
    final propertyFilters = query.propertyFilters;
    if (propertyFilters != null && propertyFilters.isNotEmpty) {
      result = result.where((e) {
        return propertyFilters.entries.every(
          (filter) => e.attributes[filter.key] == filter.value,
        );
      }).toList();
    }
    if (query.limit != null && result.length > query.limit!) {
      result = result.take(query.limit!).toList();
    }
    return result.map(_entityToRecord).toList();
  }

  @override
  Future<bundle.EntityRecord> mergeEntities(
    String surviving,
    String absorbed,
  ) async {
    if (surviving == absorbed) {
      final existing = await _factGraphService.getEntity(surviving);
      if (existing == null) {
        throw StateError('Entity not found: $surviving');
      }
      return _entityToRecord(existing);
    }

    final survivingEntity = await _factGraphService.getEntity(surviving);
    final absorbedEntity = await _factGraphService.getEntity(absorbed);
    if (survivingEntity == null) {
      throw StateError('Surviving entity not found: $surviving');
    }
    if (absorbedEntity == null) {
      throw StateError('Absorbed entity not found: $absorbed');
    }

    final mergedAliases = <String>{
      ...survivingEntity.aliases,
      absorbedEntity.canonicalName,
      ...absorbedEntity.aliases,
    }.toList();
    final mergedAttributes = <String, dynamic>{
      ...survivingEntity.attributes,
      ...absorbedEntity.attributes,
    };
    final updatedSurviving = survivingEntity.copyWith(
      aliases: mergedAliases,
      attributes: mergedAttributes,
      sourceCandidateIds: [
        ...survivingEntity.sourceCandidateIds,
        ...absorbedEntity.sourceCandidateIds,
      ],
      updatedAt: DateTime.now(),
    );
    await _entityStoragePort.saveEntity(updatedSurviving);

    final archivedAbsorbed = absorbedEntity.copyWith(
      status: EntityStatus.merged,
      updatedAt: DateTime.now(),
    );
    await _entityStoragePort.saveEntity(archivedAbsorbed);

    return _entityToRecord(updatedSurviving);
  }

  bundle.EntityRecord _entityToRecord(Entity entity) {
    return bundle.EntityRecord(
      id: entity.entityId,
      workspaceId: entity.workspaceId,
      type: entity.type,
      name: entity.canonicalName,
      properties: Map<String, dynamic>.from(entity.attributes),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  String _generateId(String prefix) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${ts}';
  }
}
