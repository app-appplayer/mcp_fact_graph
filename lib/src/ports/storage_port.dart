/// Storage Port - Abstract interface for fact graph storage.
///
/// Defines contracts for persisting and querying fact graph data.
library;

import '../domain/entities/evidence.dart';
import '../domain/entities/fragment.dart';
import '../domain/entities/candidate.dart';
import '../domain/entities/entity.dart';
import '../domain/entities/event.dart';
import '../domain/entities/view.dart';
import '../domain/entities/context_bundle.dart';
import '../domain/entities/summary_node.dart';
import '../domain/entities/claim.dart';
import '../domain/entities/pattern.dart';
import '../domain/entities/skill.dart';
import '../domain/entities/rubric.dart';
import '../domain/entities/evaluation_run.dart';

/// Port for evidence storage operations.
abstract class EvidenceStoragePort {
  /// Store evidence.
  Future<void> saveEvidence(Evidence evidence);

  /// Get evidence by ID.
  Future<Evidence?> getEvidence(String evidenceId);

  /// Query evidence.
  Future<List<Evidence>> queryEvidence(EvidenceQuery query);

  /// Delete evidence.
  Future<void> deleteEvidence(String evidenceId);

  /// Store fragments.
  Future<void> saveFragments(List<Fragment> fragments);

  /// Get fragments for evidence.
  Future<List<Fragment>> getFragments(String evidenceId);
}

/// Query for evidence.
class EvidenceQuery {
  /// Filter by source type.
  final EvidenceSourceType? sourceType;

  /// Filter by status.
  final EvidenceStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const EvidenceQuery({
    this.sourceType,
    this.status,
    this.fromDate,
    this.toDate,
    this.limit,
    this.offset,
  });
}

/// Port for candidate storage operations.
abstract class CandidateStoragePort {
  /// Store candidate.
  Future<void> saveCandidate(Candidate candidate);

  /// Get candidate by ID.
  Future<Candidate?> getCandidate(String candidateId);

  /// Query candidates.
  Future<List<Candidate>> queryCandidates(CandidateQuery query);

  /// Update candidate status.
  Future<void> updateCandidateStatus(String candidateId, CandidateStatus status);

  /// Delete candidate.
  Future<void> deleteCandidate(String candidateId);
}

/// Query for candidates.
class CandidateQuery {
  /// Filter by type.
  final String? candidateType;

  /// Filter by status.
  final CandidateStatus? status;

  /// Filter by minimum confidence.
  final double? minConfidence;

  /// Include only candidates needing review.
  final bool? needsReview;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const CandidateQuery({
    this.candidateType,
    this.status,
    this.minConfidence,
    this.needsReview,
    this.limit,
    this.offset,
  });
}

/// Port for entity storage operations.
abstract class EntityStoragePort {
  /// Store entity.
  Future<void> saveEntity(Entity entity);

  /// Get entity by ID.
  Future<Entity?> getEntity(String entityId);

  /// Find entities by name.
  Future<List<Entity>> findByName(String query);

  /// Get related entities.
  Future<List<Entity>> getRelated(String entityId);

  /// Delete entity.
  Future<void> deleteEntity(String entityId);
}

/// Port for event storage operations.
abstract class EventStoragePort {
  /// Store event.
  Future<void> saveEvent(Event event);

  /// Get event by ID.
  Future<Event?> getEvent(String eventId);

  /// Query events.
  Future<List<Event>> queryEvents(EventQuery query);

  /// Get events for entity.
  Future<List<Event>> getEventsForEntity(String entityId);

  /// Delete event.
  Future<void> deleteEvent(String eventId);
}

/// Query for events.
class EventQuery {
  /// Filter by event type.
  final String? eventType;

  /// Filter by status.
  final EventStatus? status;

  /// Filter by date range.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Filter by entity IDs.
  final List<String>? entityIds;

  /// Limit results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  const EventQuery({
    this.eventType,
    this.status,
    this.fromDate,
    this.toDate,
    this.entityIds,
    this.limit,
    this.offset,
  });
}

/// Port for view storage operations.
abstract class ViewStoragePort {
  /// Store view.
  Future<void> saveView(View view);

  /// Get view by ID.
  Future<View?> getView(String viewId);

  /// Query views.
  Future<List<View>> queryViews(ViewQuery query);

  /// Delete view.
  Future<void> deleteView(String viewId);
}

/// Query for views.
class ViewQuery {
  /// Filter by view type.
  final String? viewType;

  /// Filter by status.
  final ViewStatus? status;

  /// Filter by scope.
  final String? scope;

  /// Limit results.
  final int? limit;

  const ViewQuery({
    this.viewType,
    this.status,
    this.scope,
    this.limit,
  });
}

/// Port for context storage operations.
abstract class ContextStoragePort {
  /// Store context bundle.
  Future<void> saveContextBundle(ContextBundle bundle);

  /// Get context bundle by ID.
  Future<ContextBundle?> getContextBundle(String bundleId);

  /// Store summary node.
  Future<void> saveSummaryNode(SummaryNode node);

  /// Get summary node by ID.
  Future<SummaryNode?> getSummaryNode(String nodeId);

  /// Get child summaries.
  Future<List<SummaryNode>> getChildSummaries(String parentId);

  /// Store claim.
  Future<void> saveClaim(Claim claim);

  /// Get claim by ID.
  Future<Claim?> getClaim(String claimId);

  /// Get pending claims.
  Future<List<Claim>> getPendingClaims();
}

/// Port for skill operations storage.
abstract class SkillOpsStoragePort {
  /// Store pattern.
  Future<void> savePattern(Pattern pattern);

  /// Get pattern by ID.
  Future<Pattern?> getPattern(String patternId);

  /// Get active patterns.
  Future<List<Pattern>> getActivePatterns();

  /// Store skill.
  Future<void> saveSkill(Skill skill);

  /// Get skill by ID.
  Future<Skill?> getSkill(String skillId);

  /// Store rubric.
  Future<void> saveRubric(Rubric rubric);

  /// Get rubric by ID.
  Future<Rubric?> getRubric(String rubricId);

  /// Store evaluation run.
  Future<void> saveEvaluationRun(EvaluationRun run);

  /// Get evaluation run by ID.
  Future<EvaluationRun?> getEvaluationRun(String runId);

  /// Get evaluation runs for skill.
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(String skillId);
}
