/// FactGraph Service - L1 Layer operations.
///
/// Handles candidates, entities, facts, and views.
library;

import '../domain/entities/candidate.dart';
import '../domain/entities/entity.dart';
import '../domain/entities/fact.dart';
import '../domain/entities/view.dart';
import '../domain/entities/fragment.dart';
import '../ports/storage_port.dart';
import '../ports/llm_port.dart';

/// Service for L1 FactGraph Layer operations.
class FactGraphService {
  /// Candidate storage port.
  final CandidateStoragePort _candidateStorage;

  /// Entity storage port.
  final EntityStoragePort _entityStorage;

  /// Fact storage port.
  final FactStoragePort _factStorage;

  /// View storage port.
  final ViewStoragePort _viewStorage;

  /// Entity resolution port.
  final EntityResolutionPort? _entityResolver;

  FactGraphService({
    required CandidateStoragePort candidateStorage,
    required EntityStoragePort entityStorage,
    required FactStoragePort factStorage,
    required ViewStoragePort viewStorage,
    EntityResolutionPort? entityResolver,
  })  : _candidateStorage = candidateStorage,
        _entityStorage = entityStorage,
        _factStorage = factStorage,
        _viewStorage = viewStorage,
        _entityResolver = entityResolver;

  // =========================================================================
  // Candidate Operations
  // =========================================================================

  /// Create candidate from fragments.
  Future<Candidate> createCandidate({
    required String workspaceId,
    required String objectType,
    required List<Fragment> fragments,
    Map<String, dynamic>? additionalData,
  }) async {
    final candidateId = _generateId('cand');
    final now = DateTime.now();

    // Build fields map from fragments
    final fields = <String, CandidateField>{};
    for (final fragment in fragments) {
      // Each fragment has a fields map; merge them
      for (final entry in fragment.fields.entries) {
        fields[entry.key] = CandidateField(
          value: entry.value,
          confidence: fragment.confidence,
          sourceFragmentId: fragment.fragmentId,
        );
      }
    }

    final candidate = Candidate(
      candidateId: candidateId,
      workspaceId: workspaceId,
      objectType: objectType,
      status: CandidateStatus.open,
      fragmentIds: fragments.map((f) => f.fragmentId).toList(),
      fields: fields,
      confidence: _calculateConfidence(fields),
      createdAt: now,
      updatedAt: now,
      metadata: additionalData ?? const {},
    );

    await _candidateStorage.saveCandidate(candidate);
    return candidate;
  }

  /// Get candidate by ID.
  Future<Candidate?> getCandidate(String candidateId) {
    return _candidateStorage.getCandidate(candidateId);
  }

  /// Query candidates.
  Future<List<Candidate>> queryCandidates(CandidateQuery query) {
    return _candidateStorage.queryCandidates(query);
  }

  /// Confirm a candidate and create fact/entity.
  Future<ConfirmationResult> confirmCandidate(
    String candidateId, {
    String? policyVersion,
  }) async {
    final candidate = await _candidateStorage.getCandidate(candidateId);
    if (candidate == null) {
      throw ArgumentError('Candidate not found: $candidateId');
    }

    final now = DateTime.now();
    String? factId;
    String? entityId;

    // Create fact from candidate
    factId = await _createFactFromCandidate(candidate, policyVersion);

    // Resolve entities if resolver available
    if (_entityResolver != null) {
      entityId = await _resolveEntity(candidate);
    }

    // Update candidate status
    final confirmedCandidate = candidate.copyWith(
      status: CandidateStatus.confirmed,
      confirmedAt: now,
      updatedAt: now,
      resultingIds: [factId, if (entityId != null) entityId],
    );
    await _candidateStorage.saveCandidate(confirmedCandidate);

    return ConfirmationResult(
      candidateId: candidateId,
      factId: factId,
      entityId: entityId,
    );
  }

  /// Reject a candidate.
  Future<Candidate> rejectCandidate(
    String candidateId, {
    String? reason,
  }) async {
    final candidate = await _candidateStorage.getCandidate(candidateId);
    if (candidate == null) {
      throw ArgumentError('Candidate not found: $candidateId');
    }

    final rejectedCandidate = candidate.copyWith(
      status: CandidateStatus.rejected,
      updatedAt: DateTime.now(),
    );

    await _candidateStorage.saveCandidate(rejectedCandidate);
    return rejectedCandidate;
  }

  // =========================================================================
  // Entity Operations
  // =========================================================================

  /// Get entity by ID.
  Future<Entity?> getEntity(String entityId) {
    return _entityStorage.getEntity(entityId);
  }

  /// Find entities by name.
  Future<List<Entity>> findEntitiesByName(String query) {
    return _entityStorage.findByName(query);
  }

  /// Get related entities.
  Future<List<Entity>> getRelatedEntities(String entityId) {
    return _entityStorage.getRelated(entityId);
  }

  // =========================================================================
  // Fact Operations
  // =========================================================================

  /// Get fact by ID.
  Future<Fact?> getFact(String factId) {
    return _factStorage.getFact(factId);
  }

  /// Query facts.
  Future<List<Fact>> queryFacts(FactQuery query) {
    return _factStorage.queryFacts(query);
  }

  /// Get facts for entity.
  Future<List<Fact>> getFactsForEntity(String entityId) {
    return _factStorage.getFactsForEntity(entityId);
  }

  // =========================================================================
  // View Operations
  // =========================================================================

  /// Compute a view.
  Future<View> computeView({
    required String workspaceId,
    required String viewType,
    required String title,
    required ViewPeriod period,
    required String scope,
    required String policyVersion,
  }) async {
    final viewId = _generateId('view');
    final now = DateTime.now();

    // Query facts for the period
    final facts = await _factStorage.queryFacts(FactQuery(
      fromDate: period.start,
      toDate: period.end,
    ));

    // Compute view data based on type
    final data = await _computeViewData(viewType, facts, scope);

    final view = View(
      viewId: viewId,
      workspaceId: workspaceId,
      viewType: viewType,
      title: title,
      period: period,
      scope: scope,
      metrics: data,
      sourceRefs: facts.map((f) => f.factId).toList(),
      policyVersion: policyVersion,
      computedAt: now,
      asOf: now,
      status: ViewStatus.current,
      computationMeta: ComputationMeta(
        durationMs: 0,
        eventsProcessed: facts.length,
        algorithm: 'basic',
      ),
    );

    await _viewStorage.saveView(view);
    return view;
  }

  /// Get view by ID.
  Future<View?> getView(String viewId) {
    return _viewStorage.getView(viewId);
  }

  /// Query views.
  Future<List<View>> queryViews(ViewQuery query) {
    return _viewStorage.queryViews(query);
  }

  // =========================================================================
  // Private Methods
  // =========================================================================

  Future<String> _createFactFromCandidate(
    Candidate candidate,
    String? policyVersion,
  ) async {
    final factId = _generateId('fact');
    final now = DateTime.now();

    // Build summary from fields
    final summary = _buildSummaryFromFields(candidate.objectType, candidate.fields);

    final fact = Fact(
      factId: factId,
      workspaceId: candidate.workspaceId,
      factType: candidate.objectType,
      summary: summary,
      payload: _fieldsToData(candidate.fields),
      occurredAt: now,
      status: FactStatus.confirmed,
      candidateId: candidate.candidateId,
      evidenceRefs: candidate.evidenceIds,
      entityRefs: const [],
      createdAt: now,
      policyVersion: policyVersion,
    );

    await _factStorage.saveFact(fact);
    return factId;
  }

  Future<String?> _resolveEntity(Candidate candidate) async {
    if (_entityResolver == null) return null;

    // Try to find entity reference in fields
    final nameField = candidate.fields['name'] ?? candidate.fields['entity'];
    if (nameField == null) return null;

    final input = EntityResolutionInput(
      name: nameField.value.toString(),
      typeHint: candidate.objectType,
    );

    final result = await _entityResolver!.resolve(input);

    if (result.entityId != null) {
      return result.entityId;
    }

    if (result.shouldCreate) {
      return await _createEntity(candidate);
    }

    return null;
  }

  Future<String> _createEntity(Candidate candidate) async {
    final entityId = _generateId('ent');
    final now = DateTime.now();

    final nameField = candidate.fields['name'] ?? candidate.fields['entity'];
    final name = nameField?.value?.toString() ?? 'Unknown';

    final entity = Entity(
      entityId: entityId,
      workspaceId: candidate.workspaceId,
      type: candidate.objectType,
      canonicalName: name,
      sourceCandidateIds: [candidate.candidateId],
      createdAt: now,
      updatedAt: now,
    );

    await _entityStorage.saveEntity(entity);
    return entityId;
  }

  String _buildSummaryFromFields(String objectType, Map<String, CandidateField> fields) {
    final parts = <String>[objectType];
    if (fields.containsKey('name')) {
      parts.add(fields['name']!.value.toString());
    }
    if (fields.containsKey('amount')) {
      parts.add(fields['amount']!.value.toString());
    }
    return parts.join(': ');
  }

  Map<String, dynamic> _fieldsToData(Map<String, CandidateField> fields) {
    return fields.map((key, field) => MapEntry(key, field.value));
  }

  Future<Map<String, dynamic>> _computeViewData(
    String viewType,
    List<Fact> facts,
    String? scope,
  ) async {
    // Basic view computation - override for specific view types
    return {
      'factCount': facts.length,
      'factTypes': facts.map((f) => f.factType).toSet().toList(),
    };
  }

  double _calculateConfidence(Map<String, CandidateField> fields) {
    if (fields.isEmpty) return 0.0;
    return fields.values.fold(0.0, (sum, f) => sum + f.confidence) / fields.length;
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs() % 10000;
    return '${prefix}_${timestamp}_$random';
  }
}

/// Result of confirming a candidate.
class ConfirmationResult {
  /// Candidate ID.
  final String candidateId;

  /// Created fact ID.
  final String? factId;

  /// Resolved/created entity ID.
  final String? entityId;

  const ConfirmationResult({
    required this.candidateId,
    this.factId,
    this.entityId,
  });
}
