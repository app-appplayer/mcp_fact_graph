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
export 'src/domain/entities/event.dart';
export 'src/domain/entities/view.dart';

// =============================================================================
// Domain Entities - L2: ContextOps Layer
// =============================================================================
export 'src/domain/entities/context_bundle.dart';
export 'src/domain/entities/summary_node.dart';
export 'src/domain/entities/claim.dart';

// =============================================================================
// Domain Entities - L3: SkillOps Layer
// =============================================================================
export 'src/domain/entities/pattern.dart';
export 'src/domain/entities/skill.dart';
export 'src/domain/entities/rubric.dart';
export 'src/domain/entities/evaluation_run.dart';

// =============================================================================
// Services
// =============================================================================
export 'src/services/evidence_service.dart';
export 'src/services/fact_graph_service.dart';
export 'src/services/context_service.dart';
export 'src/services/skill_ops_service.dart';

// =============================================================================
// Ports (Abstract Interfaces)
// =============================================================================
export 'src/ports/evidence_port.dart';
export 'src/ports/storage_port.dart';
export 'src/ports/llm_port.dart';

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
