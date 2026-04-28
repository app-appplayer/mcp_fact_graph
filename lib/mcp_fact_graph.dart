/// MCP Fact Graph - Knowledge representation with 4-layer architecture.
///
/// Layers:
/// - L0: Evidence Layer (ingestion, extraction)
/// - L1: FactGraph Layer (candidates, entities, events, views)
/// - L2: ContextOps Layer (context bundles, summaries, claims)
/// - L3: SkillOps Layer (patterns, skills, rubrics, evaluation)
library mcp_fact_graph;

// =============================================================================
// Domain Entities - L0: Evidence Layer
// =============================================================================
export 'src/domain/entities/evidence.dart';
export 'src/domain/entities/fragment.dart';

// =============================================================================
// Domain Entities - L1: FactGraph Layer
// =============================================================================
export 'src/domain/entities/candidate.dart';
export 'src/domain/entities/entity.dart';
export 'src/domain/entities/fact.dart';
export 'src/domain/entities/view.dart';
export 'src/domain/entities/fact_cluster.dart';
export 'src/domain/entities/classification.dart';
export 'src/domain/entities/relation.dart';
export 'src/domain/entities/fact_policy.dart';
export 'src/domain/entities/automation.dart';
export 'src/domain/entities/run.dart' hide Period;
export 'src/domain/entities/artifact.dart';

// =============================================================================
// Domain Entities - L2: ContextOps Layer
// =============================================================================
export 'src/domain/entities/context_bundle.dart';
export 'src/domain/entities/summary_node.dart';
export 'src/domain/entities/claim.dart';
export 'src/domain/entities/response_validation.dart';

// =============================================================================
// Domain Entities - LLM Call Reduction
// =============================================================================
export 'src/domain/entities/extraction_rule.dart';
export 'src/domain/entities/extraction_validator.dart' hide ValidationResult;
export 'src/domain/entities/classifier_memory.dart';
export 'src/domain/entities/disambiguation_decision.dart';
export 'src/domain/entities/llm_call_log.dart';
export 'src/domain/entities/idempotency_record.dart';

// =============================================================================
// Domain Entities - L2-L3 Bridge
// =============================================================================
export 'src/domain/entities/claim_signal.dart';

// =============================================================================
// Domain Entities - L3: SkillOps Layer
// =============================================================================
export 'src/domain/entities/pattern.dart';
export 'src/domain/entities/skill.dart';
export 'src/domain/entities/rubric.dart';
export 'src/domain/entities/evaluation_run.dart';
export 'src/domain/entities/skill_run.dart' hide GateAction;

// =============================================================================
// Services
// =============================================================================
export 'src/services/evidence_service.dart';
export 'src/services/fact_graph_service.dart';
export 'src/services/context_service.dart';
export 'src/services/skill_ops_service.dart';
export 'src/services/pattern_miner.dart';
export 'src/services/summary_scheduler.dart';
export 'src/services/consistency_checker.dart';
export 'src/services/candidate_deduplicator.dart';

// Exceptions
export 'src/exceptions/fact_conflict_exception.dart';

// =============================================================================
// Internal Ports — NOT re-exported
// =============================================================================
// Per REDESIGN-PLAN.md §3.4 / §8 OQ5 recommendation (a), the low-level
// storage ports and LLM port are package-internal. The 17 `*StoragePort`
// interfaces, `UnifiedStoragePort`, `LlmPort`, and the local ingestion
// `EvidencePort` / `FragmentExtractorPort` are reachable only via the
// standard adapters and `FactGraphRuntime`. Tests that need direct
// access should import the `src/ports/…` files by path — intentionally
// awkward to discourage new consumer-facing usage.

// =============================================================================
// Phase 2 — Standard capability adapters + FactGraphRuntime
// =============================================================================
// Composition root exposing the 12 capability-named standard adapters
// (MOD-INFRA-011..022). Phase 2 public entry point per
// REDESIGN-PLAN.md §3.3 and the Scenario A standalone host test.
// The individual adapter classes in `src/adapters/standard/` are also
// re-exported so hosts can construct them directly without reaching
// for the `src/` path. Legacy consumer-sliced adapters
// (FactGraphPortAdapter / SkillFactGraphPortAdapter / legacy
// EvidencePortAdapter) were removed in Phase 2.1 (Phase 9 completion).
export 'src/runtime/fact_graph_runtime.dart';
export 'src/adapters/standard/facts_port_adapter.dart';
export 'src/adapters/standard/claims_port_adapter.dart';
export 'src/adapters/standard/entities_port_adapter.dart';
export 'src/adapters/standard/evidence_port_adapter.dart';
export 'src/adapters/standard/candidates_port_adapter.dart';
export 'src/adapters/standard/patterns_port_adapter.dart';
export 'src/adapters/standard/summaries_port_adapter.dart';
export 'src/adapters/standard/runs_port_adapter.dart';
export 'src/adapters/standard/context_bundle_port_adapter.dart';
export 'src/adapters/standard/retrieval_port_adapter.dart';
export 'src/adapters/standard/asset_port_adapter.dart';
export 'src/adapters/standard/index_port_adapter.dart';

// =============================================================================
// Legacy Graph Components (for backward compatibility)
// =============================================================================
export 'src/graph/fact_node.dart';
export 'src/graph/fact_edge.dart';
export 'src/graph/fact_graph.dart';

// Query components
export 'src/query/graph_query.dart';
export 'src/query/query_result.dart';

// Storage
export 'src/storage/graph_storage.dart';
