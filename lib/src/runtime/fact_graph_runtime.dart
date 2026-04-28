/// FactGraphRuntime - Phase 2 composition root.
///
/// MOD-INFRA-023. Owns the 12 standard adapters and exposes each as a
/// typed `final` field, so host code can compose the full
/// `mcp_fact_graph` surface with a single constructor call. The
/// [FactGraphRuntime.inMemory] factory wires an in-memory storage stack
/// end-to-end — the entry point used by the *Scenario A* standalone
/// integration test.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;

import '../adapters/standard/asset_port_adapter.dart';
import '../adapters/standard/candidates_port_adapter.dart';
import '../adapters/standard/claims_port_adapter.dart';
import '../adapters/standard/context_bundle_port_adapter.dart';
import '../adapters/standard/entities_port_adapter.dart';
import '../adapters/standard/evidence_port_adapter.dart';
import '../adapters/standard/facts_port_adapter.dart';
import '../adapters/standard/index_port_adapter.dart';
import '../adapters/standard/patterns_port_adapter.dart';
import '../adapters/standard/retrieval_port_adapter.dart';
import '../adapters/standard/runs_port_adapter.dart';
import '../adapters/standard/summaries_port_adapter.dart';
import '../ports/storage_port.dart';
import '../services/candidate_deduplicator.dart';
import '../services/consistency_checker.dart';
import '../services/context_service.dart';
import '../services/evidence_service.dart';
import '../services/fact_graph_service.dart';
import '../services/pattern_miner.dart';
import '../services/skill_ops_service.dart';
import '../services/summary_scheduler.dart';
import '../storage/in_memory_storage.dart';

/// Phase 2 composition root for `mcp_fact_graph`.
///
/// The primary constructor takes pre-wired services and storage ports.
/// The [FactGraphRuntime.inMemory] factory offers a zero-config
/// single-line setup that the *Scenario A* host uses:
///
/// ```dart
/// final runtime = FactGraphRuntime.inMemory(defaultWorkspaceId: 'ws1');
/// await runtime.initialize();
/// await runtime.facts.writeFacts([...]);
/// ```
class FactGraphRuntime {
  /// Primary constructor. All services and storage ports must be
  /// wired; the factory [FactGraphRuntime.inMemory] assembles a
  /// default in-memory stack on the caller's behalf.
  FactGraphRuntime({
    required EvidenceService evidenceService,
    required FactGraphService factGraphService,
    required ContextService contextService,
    required SkillOpsService skillOpsService,
    required EvidenceStoragePort evidenceStoragePort,
    required CandidateStoragePort candidateStoragePort,
    required EntityStoragePort entityStoragePort,
    required FactStoragePort factStoragePort,
    required ContextStoragePort contextStoragePort,
    required SkillOpsStoragePort skillOpsStoragePort,
    required RelationStoragePort relationStoragePort,
    required RunStoragePort runStoragePort,
    required ArtifactStoragePort artifactStoragePort,
    PatternMiner? patternMiner,
    SummaryScheduler? summaryScheduler,
    ConsistencyChecker? consistencyChecker,
    CandidateDeduplicator? candidateDeduplicator,
    String defaultWorkspaceId = 'default',
    String defaultPolicyVersion = 'v1',
  })  : patternMiner = patternMiner,
        summaryScheduler = summaryScheduler,
        _factStoragePort = factStoragePort,
        _defaultWorkspaceId = defaultWorkspaceId,
        facts = FactsPortAdapter(
          factGraphService: factGraphService,
          factStoragePort: factStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
          consistencyChecker: consistencyChecker,
        ),
        claims = ClaimsPortAdapter(
          contextService: contextService,
          contextStoragePort: contextStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        entities = EntitiesPortAdapter(
          factGraphService: factGraphService,
          entityStoragePort: entityStoragePort,
          relationStoragePort: relationStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        evidence = EvidencePortAdapter(),
        candidates = CandidatesPortAdapter(
          factGraphService: factGraphService,
          candidateStoragePort: candidateStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
          defaultPolicyVersion: defaultPolicyVersion,
          deduplicator: candidateDeduplicator,
        ),
        patterns = PatternsPortAdapter(
          skillOpsStoragePort: skillOpsStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        summaries = SummariesPortAdapter(
          contextStoragePort: contextStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        runs = RunsPortAdapter(
          runStoragePort: runStoragePort,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        contextBundle = ContextBundlePortAdapter(
          contextService: contextService,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        retrieval = RetrievalPortAdapter(
          factGraphService: factGraphService,
          defaultWorkspaceId: defaultWorkspaceId,
        ),
        asset = AssetPortAdapter(
          artifactStoragePort: artifactStoragePort,
        ),
        index = IndexPortAdapter();

  /// Convenience constructor: wires a full in-memory storage stack,
  /// default services, and the 12 standard adapters. Intended for
  /// tests and the *Scenario A* standalone host.
  factory FactGraphRuntime.inMemory({
    String defaultWorkspaceId = 'default',
    String defaultPolicyVersion = 'v1',
    bool enablePatternMining = true,
    bool enableSummaryScheduler = true,
    bool enableConsistencyCheck = true,
    bool enableCandidateDedup = true,
  }) {
    final container = InMemoryStorageContainer();

    final evidenceService = EvidenceService(
      storage: container.evidence,
    );
    final factGraphService = FactGraphService(
      candidateStorage: container.candidates,
      entityStorage: container.entities,
      factStorage: container.facts,
      viewStorage: container.views,
    );
    final contextService = ContextService(
      storage: container.context,
      factStorage: container.facts,
    );
    final skillOpsService = SkillOpsService(
      storage: container.skillOps,
    );

    final patternsPort = PatternsPortAdapter(
      skillOpsStoragePort: container.skillOps,
      defaultWorkspaceId: defaultWorkspaceId,
    );
    final patternMiner = PatternMiner(
      factStorage: container.facts,
      patternStorage: patternsPort,
      enabled: enablePatternMining,
    );

    final summariesPort = SummariesPortAdapter(
      contextStoragePort: container.context,
      defaultWorkspaceId: defaultWorkspaceId,
    );
    final summaryScheduler = SummaryScheduler(
      summaries: summariesPort,
      enabled: enableSummaryScheduler,
    );
    final consistencyChecker = ConsistencyChecker(
      storage: container.facts,
      enabled: enableConsistencyCheck,
    );
    final candidateDeduplicator = CandidateDeduplicator(
      storage: container.candidates,
      enabled: enableCandidateDedup,
    );

    return FactGraphRuntime(
      evidenceService: evidenceService,
      factGraphService: factGraphService,
      contextService: contextService,
      skillOpsService: skillOpsService,
      evidenceStoragePort: container.evidence,
      candidateStoragePort: container.candidates,
      entityStoragePort: container.entities,
      factStoragePort: container.facts,
      contextStoragePort: container.context,
      skillOpsStoragePort: container.skillOps,
      relationStoragePort: container.relations,
      runStoragePort: container.runs,
      artifactStoragePort: container.artifacts,
      patternMiner: patternMiner,
      summaryScheduler: summaryScheduler,
      consistencyChecker: consistencyChecker,
      candidateDeduplicator: candidateDeduplicator,
      defaultWorkspaceId: defaultWorkspaceId,
      defaultPolicyVersion: defaultPolicyVersion,
    );
  }

  /// Capability: facts CRUD.
  final bundle.FactsPort facts;

  /// Capability: claim lifecycle.
  final bundle.ClaimsPort claims;

  /// Capability: entity CRUD / linking / merging.
  final bundle.EntitiesPort entities;

  /// Capability: evidence fragment extraction / confidence / classification.
  final bundle.EvidencePort evidence;

  /// Capability: candidate CRUD and review.
  final bundle.CandidatesPort candidates;

  /// Capability: pattern CRUD.
  final bundle.PatternsPort patterns;

  /// Capability: summary storage and refresh.
  final bundle.SummariesPort summaries;

  /// Capability: run record storage.
  final bundle.RunsPort runs;

  /// Capability: context bundle construction.
  final bundle.ContextBundlePort contextBundle;

  /// Capability: lexical retrieval over facts.
  final bundle.RetrievalPort retrieval;

  /// Capability: binary asset retrieval.
  final bundle.AssetPort asset;

  /// Capability: knowledge index lifecycle.
  final bundle.IndexPort index;

  /// Optional L0 pattern miner. When wired, hosts can call
  /// [mineAllPatterns] to run the three default algorithms.
  final PatternMiner? patternMiner;

  /// Optional summary refresh scheduler (C3). Built automatically by
  /// [FactGraphRuntime.inMemory] and left stopped; hosts call
  /// [startSummaryScheduler] to begin periodic refresh and
  /// [stopSummaryScheduler] to halt it. [close] cancels the timer.
  final SummaryScheduler? summaryScheduler;

  /// Backing fact storage — retained so mining can be invoked without
  /// passing the port around separately.
  // ignore: unused_field
  final FactStoragePort _factStoragePort;

  /// Default workspace id used when the caller omits an explicit one.
  final String _defaultWorkspaceId;

  bool _initialized = false;

  /// Initialize the runtime. Idempotent.
  Future<void> initialize() async {
    _initialized = true;
  }

  /// Whether the runtime has been initialized successfully.
  Future<bool> isReady() async => _initialized;

  /// Release runtime resources. The in-memory adapters have nothing to
  /// do here but subclasses may override for a real backend.
  Future<void> close() async {
    summaryScheduler?.stop();
    _initialized = false;
  }

  /// Start the periodic summary refresh loop, if a scheduler is wired.
  /// No-op when none.
  void startSummaryScheduler() {
    summaryScheduler?.start();
  }

  /// Stop the periodic summary refresh loop, if a scheduler is wired.
  /// Safe to call when never started.
  void stopSummaryScheduler() {
    summaryScheduler?.stop();
  }

  /// Run the L0 pattern miner across all default algorithms for the
  /// given workspace. No-op and returns an empty list when no
  /// [patternMiner] is wired.
  Future<List<bundle.PatternRecord>> mineAllPatterns([
    String? workspaceId,
  ]) async {
    final miner = patternMiner;
    if (miner == null) return const [];
    return miner.mineAll(workspaceId ?? _defaultWorkspaceId);
  }
}
