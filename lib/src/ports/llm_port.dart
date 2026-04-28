/// LLM Port - Re-export from mcp_bundle plus domain-specific types.
///
/// This file re-exports the unified LlmPort from mcp_bundle and adds
/// domain-specific ports for fact graph operations.
library;

// Re-export core LLM types from mcp_bundle
export 'package:mcp_bundle/src/ports/llm_port.dart';

/// Port for entity resolution using LLM.
abstract class EntityResolutionPort {
  /// Resolve entity from candidate.
  Future<EntityResolutionResult> resolve(EntityResolutionInput input);

  /// Find matching entities.
  Future<List<EntityMatch>> findMatches(String query, String entityType);
}

/// Input for entity resolution.
class EntityResolutionInput {
  /// Entity name to resolve.
  final String name;

  /// Entity type hint.
  final String? typeHint;

  /// Context for resolution.
  final String? context;

  /// Known attributes.
  final Map<String, dynamic>? attributes;

  const EntityResolutionInput({
    required this.name,
    this.typeHint,
    this.context,
    this.attributes,
  });
}

/// Entity resolution result.
class EntityResolutionResult {
  /// Resolved entity ID (if found).
  final String? entityId;

  /// Whether a new entity should be created.
  final bool shouldCreate;

  /// Confidence in resolution.
  final double confidence;

  /// Alternative matches.
  final List<EntityMatch> alternatives;

  const EntityResolutionResult({
    this.entityId,
    required this.shouldCreate,
    required this.confidence,
    this.alternatives = const [],
  });
}

/// Entity match result.
class EntityMatch {
  /// Entity ID.
  final String entityId;

  /// Entity name.
  final String name;

  /// Entity type.
  final String entityType;

  /// Match confidence.
  final double confidence;

  /// Match reason.
  final String? reason;

  const EntityMatch({
    required this.entityId,
    required this.name,
    required this.entityType,
    required this.confidence,
    this.reason,
  });
}

/// Port for claim verification using LLM.
abstract class ClaimVerificationPort {
  /// Verify a claim against evidence.
  Future<ClaimVerificationResult> verify(ClaimVerificationInput input);
}

/// Input for claim verification.
class ClaimVerificationInput {
  /// Claim statement.
  final String claim;

  /// Evidence to verify against.
  final List<String> evidence;

  /// Context information.
  final String? context;

  const ClaimVerificationInput({
    required this.claim,
    required this.evidence,
    this.context,
  });
}

/// Claim verification result.
class ClaimVerificationResult {
  /// Verification verdict.
  final String verdict;

  /// Confidence in verdict.
  final double confidence;

  /// Explanation.
  final String explanation;

  /// Supporting evidence indices.
  final List<int> supportingIndices;

  /// Contradicting evidence indices.
  final List<int> contradictingIndices;

  const ClaimVerificationResult({
    required this.verdict,
    required this.confidence,
    required this.explanation,
    this.supportingIndices = const [],
    this.contradictingIndices = const [],
  });
}
