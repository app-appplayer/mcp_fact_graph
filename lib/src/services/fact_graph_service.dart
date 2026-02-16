/// FactGraph Service - L1 Layer operations.
///
/// Handles candidates, entities, events, and views.
library;

import '../domain/entities/candidate.dart';
import '../domain/entities/entity.dart';
import '../domain/entities/event.dart';
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

  /// Event storage port.
  final EventStoragePort _eventStorage;

  /// View storage port.
  final ViewStoragePort _viewStorage;

  /// Entity resolution port.
  final EntityResolutionPort? _entityResolver;

  FactGraphService({
    required CandidateStoragePort candidateStorage,
    required EntityStoragePort entityStorage,
    required EventStoragePort eventStorage,
    required ViewStoragePort viewStorage,
    EntityResolutionPort? entityResolver,
  })  : _candidateStorage = candidateStorage,
        _entityStorage = entityStorage,
        _eventStorage = eventStorage,
        _viewStorage = viewStorage,
        _entityResolver = entityResolver;

  // =========================================================================
  // Candidate Operations
  // =========================================================================

  /// Create candidate from fragments.
  Future<Candidate> createCandidate({
    required String objectType,
    required List<Fragment> fragments,
    Map<String, dynamic>? additionalData,
  }) async {
    final candidateId = _generateId('cand');
    final now = DateTime.now();

    // Build fields map from fragments
    final fields = <String, CandidateField>{};
    for (final fragment in fragments) {
      fields[fragment.field] = CandidateField(
        value: fragment.normalizedValue ?? fragment.value,
        confidence: fragment.confidence,
        sourceFragmentId: fragment.fragmentId,
      );
    }

    final candidate = Candidate(
      candidateId: candidateId,
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

  /// Confirm a candidate and create event/entity.
  Future<ConfirmationResult> confirmCandidate(
    String candidateId, {
    String? policyVersion,
  }) async {
    final candidate = await _candidateStorage.getCandidate(candidateId);
    if (candidate == null) {
      throw ArgumentError('Candidate not found: $candidateId');
    }

    final now = DateTime.now();
    String? eventId;
    String? entityId;

    // Create event from candidate
    eventId = await _createEventFromCandidate(candidate, policyVersion);

    // Resolve entities if resolver available
    if (_entityResolver != null) {
      entityId = await _resolveEntity(candidate);
    }

    // Update candidate status
    final confirmedCandidate = candidate.copyWith(
      status: CandidateStatus.confirmed,
      confirmedAt: now,
      updatedAt: now,
      resultingIds: [eventId, if (entityId != null) entityId],
    );
    await _candidateStorage.saveCandidate(confirmedCandidate);

    return ConfirmationResult(
      candidateId: candidateId,
      eventId: eventId,
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
  // Event Operations
  // =========================================================================

  /// Get event by ID.
  Future<Event?> getEvent(String eventId) {
    return _eventStorage.getEvent(eventId);
  }

  /// Query events.
  Future<List<Event>> queryEvents(EventQuery query) {
    return _eventStorage.queryEvents(query);
  }

  /// Get events for entity.
  Future<List<Event>> getEventsForEntity(String entityId) {
    return _eventStorage.getEventsForEntity(entityId);
  }

  // =========================================================================
  // View Operations
  // =========================================================================

  /// Compute a view.
  Future<View> computeView({
    required String viewType,
    required String title,
    required ViewPeriod period,
    String? scope,
    required String policyVersion,
  }) async {
    final viewId = _generateId('view');
    final now = DateTime.now();

    // Query events for the period
    final events = await _eventStorage.queryEvents(EventQuery(
      fromDate: period.start,
      toDate: period.end,
    ));

    // Compute view data based on type
    final data = await _computeViewData(viewType, events, scope);

    final view = View(
      viewId: viewId,
      viewType: viewType,
      title: title,
      period: period,
      scope: scope,
      data: data,
      sourceEventIds: events.map((e) => e.eventId).toList(),
      policyVersion: policyVersion,
      computedAt: now,
      asOf: now,
      status: ViewStatus.current,
      computationMeta: ComputationMeta(
        durationMs: 0,
        eventsProcessed: events.length,
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

  Future<String> _createEventFromCandidate(
    Candidate candidate,
    String? policyVersion,
  ) async {
    final eventId = _generateId('evt');
    final now = DateTime.now();

    // Build summary from fields
    final summary = _buildSummaryFromFields(candidate.objectType, candidate.fields);

    final event = Event(
      eventId: eventId,
      eventType: candidate.objectType,
      summary: summary,
      data: _fieldsToData(candidate.fields),
      occurredAt: now,
      status: EventStatus.active,
      candidateId: candidate.candidateId,
      evidenceIds: candidate.evidenceIds,
      entityIds: const [],
      edges: const [],
      createdAt: now,
      updatedAt: now,
      policyVersion: policyVersion,
    );

    await _eventStorage.saveEvent(event);
    return eventId;
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
      entityType: candidate.objectType,
      name: name,
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
    List<Event> events,
    String? scope,
  ) async {
    // Basic view computation - override for specific view types
    return {
      'eventCount': events.length,
      'eventTypes': events.map((e) => e.eventType).toSet().toList(),
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

  /// Created event ID.
  final String? eventId;

  /// Resolved/created entity ID.
  final String? entityId;

  const ConfirmationResult({
    required this.candidateId,
    this.eventId,
    this.entityId,
  });
}
