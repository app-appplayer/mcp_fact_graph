/// Unified Storage Port - Design-compliant facade for fact graph storage.
///
/// Provides a single entry point to all storage operations, wrapping
/// the specialized storage ports into a unified interface.
///
/// Reference: 03-data-model-specification.md, 05-storage-adapter-contract.md
library;

import 'storage_port.dart';

/// Unified StoragePort facade providing access to all storage operations.
///
/// This is the design-compliant interface that wraps all specialized
/// storage ports into a single unified interface.
///
/// Example usage:
/// ```dart
/// final storage = MyUnifiedStoragePortImpl();
///
/// // Access L0 Evidence Layer
/// await storage.evidence.saveEvidence(evidence);
///
/// // Access L1 FactGraph Layer
/// await storage.facts.saveFact(fact);
/// await storage.entities.saveEntity(entity);
///
/// // Access L2 ContextOps Layer
/// await storage.context.saveContextBundle(bundle);
///
/// // Access L3 SkillOps Layer
/// await storage.skillOps.saveSkill(skill);
/// ```
abstract class UnifiedStoragePort {
  // ===========================================================================
  // L0: Evidence Layer
  // ===========================================================================

  /// Evidence storage operations.
  EvidenceStoragePort get evidence;

  // ===========================================================================
  // L1: FactGraph Layer
  // ===========================================================================

  /// Candidate storage operations.
  CandidateStoragePort get candidates;

  /// Entity storage operations.
  EntityStoragePort get entities;

  /// Relation storage operations.
  RelationStoragePort get relations;

  /// Fact storage operations.
  FactStoragePort get facts;

  /// Fact cluster storage operations.
  FactClusterStoragePort get factClusters;

  /// Classification storage operations.
  ClassificationStoragePort get classifications;

  /// Policy storage operations.
  PolicyStoragePort get policies;

  /// View storage operations.
  ViewStoragePort get views;

  /// Automation storage operations.
  AutomationStoragePort get automations;

  /// Run storage operations.
  RunStoragePort get runs;

  /// Artifact storage operations.
  ArtifactStoragePort get artifacts;

  // ===========================================================================
  // L1.5: LLM Call Reduction
  // ===========================================================================

  /// Extraction rule storage operations.
  ExtractionRuleStoragePort get extractionRules;

  /// Extraction validator storage operations.
  ExtractionValidatorStoragePort get extractionValidators;

  /// Classifier memory storage operations.
  ClassifierMemoryStoragePort get classifierMemory;

  // ===========================================================================
  // L2: ContextOps Layer
  // ===========================================================================

  /// Context storage operations (bundles, summaries, claims).
  ContextStoragePort get context;

  // ===========================================================================
  // L3: SkillOps Layer
  // ===========================================================================

  /// Skill operations storage (patterns, skills, rubrics, evaluation runs).
  SkillOpsStoragePort get skillOps;

  // ===========================================================================
  // Lifecycle & Transaction Support
  // ===========================================================================

  /// Initialize storage connections.
  Future<void> initialize();

  /// Check if storage is ready.
  Future<bool> isReady();

  /// Run operations in a transaction.
  Future<T> runInTransaction<T>(Future<T> Function() operation);

  /// Close storage connections.
  Future<void> close();
}

/// Composite implementation of UnifiedStoragePort.
///
/// Wraps individual storage port implementations into a unified facade.
class CompositeStoragePort implements UnifiedStoragePort {
  @override
  final EvidenceStoragePort evidence;

  @override
  final CandidateStoragePort candidates;

  @override
  final EntityStoragePort entities;

  @override
  final RelationStoragePort relations;

  @override
  final FactStoragePort facts;

  @override
  final FactClusterStoragePort factClusters;

  @override
  final ClassificationStoragePort classifications;

  @override
  final PolicyStoragePort policies;

  @override
  final ViewStoragePort views;

  @override
  final AutomationStoragePort automations;

  @override
  final RunStoragePort runs;

  @override
  final ArtifactStoragePort artifacts;

  @override
  final ExtractionRuleStoragePort extractionRules;

  @override
  final ExtractionValidatorStoragePort extractionValidators;

  @override
  final ClassifierMemoryStoragePort classifierMemory;

  @override
  final ContextStoragePort context;

  @override
  final SkillOpsStoragePort skillOps;

  /// Callback for initialization.
  final Future<void> Function()? _onInitialize;

  /// Callback for readiness check.
  final Future<bool> Function()? _onIsReady;

  /// Callback for transaction support.
  final Future<T> Function<T>(Future<T> Function())? _onTransaction;

  /// Callback for closing.
  final Future<void> Function()? _onClose;

  CompositeStoragePort({
    required this.evidence,
    required this.candidates,
    required this.entities,
    required this.relations,
    required this.facts,
    required this.factClusters,
    required this.classifications,
    required this.policies,
    required this.views,
    required this.automations,
    required this.runs,
    required this.artifacts,
    required this.extractionRules,
    required this.extractionValidators,
    required this.classifierMemory,
    required this.context,
    required this.skillOps,
    Future<void> Function()? onInitialize,
    Future<bool> Function()? onIsReady,
    Future<T> Function<T>(Future<T> Function())? onTransaction,
    Future<void> Function()? onClose,
  })  : _onInitialize = onInitialize,
        _onIsReady = onIsReady,
        _onTransaction = onTransaction,
        _onClose = onClose;

  @override
  Future<void> initialize() async {
    if (_onInitialize != null) {
      await _onInitialize!();
    }
  }

  @override
  Future<bool> isReady() async {
    if (_onIsReady != null) {
      return _onIsReady!();
    }
    return true;
  }

  @override
  Future<T> runInTransaction<T>(Future<T> Function() operation) async {
    if (_onTransaction != null) {
      return _onTransaction!<T>(operation);
    }
    return operation();
  }

  @override
  Future<void> close() async {
    if (_onClose != null) {
      await _onClose!();
    }
  }
}

/// Backward compatibility type alias.
@Deprecated('Use UnifiedStoragePort instead')
typedef StoragePort = UnifiedStoragePort;
