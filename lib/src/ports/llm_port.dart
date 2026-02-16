/// LLM Port - Abstract interface for LLM operations.
///
/// Defines contracts for LLM-based processing in the fact graph.
library;

/// Port for LLM operations.
abstract class LlmPort {
  /// Generate completion.
  Future<LlmResponse> complete(LlmRequest request);

  /// Generate embeddings.
  Future<List<double>> embed(String text);

  /// Check if LLM is available.
  Future<bool> isAvailable();

  /// Get model capabilities.
  LlmCapabilities get capabilities;
}

/// LLM request.
class LlmRequest {
  /// System prompt.
  final String? systemPrompt;

  /// User message/prompt.
  final String prompt;

  /// Conversation history.
  final List<LlmMessage>? history;

  /// Maximum tokens to generate.
  final int? maxTokens;

  /// Temperature for generation.
  final double? temperature;

  /// Stop sequences.
  final List<String>? stopSequences;

  /// Response format (text, json, etc.).
  final String? responseFormat;

  /// Additional options.
  final Map<String, dynamic>? options;

  const LlmRequest({
    this.systemPrompt,
    required this.prompt,
    this.history,
    this.maxTokens,
    this.temperature,
    this.stopSequences,
    this.responseFormat,
    this.options,
  });
}

/// LLM message in conversation.
class LlmMessage {
  /// Message role (user, assistant, system).
  final String role;

  /// Message content.
  final String content;

  const LlmMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// LLM response.
class LlmResponse {
  /// Generated content.
  final String content;

  /// Token usage.
  final TokenUsage? usage;

  /// Model used.
  final String? model;

  /// Finish reason.
  final String? finishReason;

  /// Response metadata.
  final Map<String, dynamic>? metadata;

  const LlmResponse({
    required this.content,
    this.usage,
    this.model,
    this.finishReason,
    this.metadata,
  });
}

/// Token usage statistics.
class TokenUsage {
  /// Prompt tokens.
  final int promptTokens;

  /// Completion tokens.
  final int completionTokens;

  /// Total tokens.
  final int totalTokens;

  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}

/// LLM capabilities.
class LlmCapabilities {
  /// Model name.
  final String modelName;

  /// Maximum context length.
  final int maxContextLength;

  /// Whether embeddings are supported.
  final bool supportsEmbeddings;

  /// Embedding dimension.
  final int? embeddingDimension;

  /// Whether function calling is supported.
  final bool supportsFunctionCalling;

  /// Whether JSON mode is supported.
  final bool supportsJsonMode;

  /// Whether vision is supported.
  final bool supportsVision;

  const LlmCapabilities({
    required this.modelName,
    required this.maxContextLength,
    this.supportsEmbeddings = false,
    this.embeddingDimension,
    this.supportsFunctionCalling = false,
    this.supportsJsonMode = false,
    this.supportsVision = false,
  });
}

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
