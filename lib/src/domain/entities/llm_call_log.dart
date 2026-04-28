/// LLMCallLog entity model.
///
/// Tracks LLM API calls for optimization and cost analysis.
/// Design: 03-data-model-specification.md Section 2.12.4
library;

/// LLMCallLog tracks LLM API calls for optimization and cost analysis.
class LLMCallLog {
  /// Unique call identifier.
  final String callId;

  /// Purpose: extraction, classification, summary, etc.
  final String purpose;

  /// Model used.
  final String model;

  /// Input token count.
  final int inputTokens;

  /// Output token count.
  final int outputTokens;

  /// Estimated cost in USD.
  final double cost;

  /// Whether this call was necessary (could rule have handled it?).
  final bool wasNecessary;

  /// Rule that could have been used instead.
  final String? alternativeRuleId;

  /// Sanitized request.
  final Map<String, dynamic> request;

  /// Response summary.
  final Map<String, dynamic> response;

  /// Latency in milliseconds.
  final int? latencyMs;

  /// Whether the call succeeded.
  final bool success;

  /// Error message if failed.
  final String? errorMessage;

  /// Workspace ID.
  final String? workspaceId;

  /// When the call was made.
  final DateTime createdAt;

  const LLMCallLog({
    required this.callId,
    required this.purpose,
    required this.model,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cost = 0.0,
    this.wasNecessary = true,
    this.alternativeRuleId,
    this.request = const {},
    this.response = const {},
    this.latencyMs,
    this.success = true,
    this.errorMessage,
    this.workspaceId,
    required this.createdAt,
  });

  /// Create from JSON.
  factory LLMCallLog.fromJson(Map<String, dynamic> json) {
    return LLMCallLog(
      callId: json['callId'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      model: json['model'] as String? ?? '',
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      wasNecessary: json['wasNecessary'] as bool? ?? true,
      alternativeRuleId: json['alternativeRuleId'] as String?,
      request: json['request'] as Map<String, dynamic>? ?? {},
      response: json['response'] as Map<String, dynamic>? ?? {},
      latencyMs: json['latencyMs'] as int?,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      workspaceId: json['workspaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'purpose': purpose,
      'model': model,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'cost': cost,
      'wasNecessary': wasNecessary,
      if (alternativeRuleId != null) 'alternativeRuleId': alternativeRuleId,
      if (request.isNotEmpty) 'request': request,
      if (response.isNotEmpty) 'response': response,
      if (latencyMs != null) 'latencyMs': latencyMs,
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (workspaceId != null) 'workspaceId': workspaceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  LLMCallLog copyWith({
    String? callId,
    String? purpose,
    String? model,
    int? inputTokens,
    int? outputTokens,
    double? cost,
    bool? wasNecessary,
    String? alternativeRuleId,
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
    int? latencyMs,
    bool? success,
    String? errorMessage,
    String? workspaceId,
    DateTime? createdAt,
  }) {
    return LLMCallLog(
      callId: callId ?? this.callId,
      purpose: purpose ?? this.purpose,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cost: cost ?? this.cost,
      wasNecessary: wasNecessary ?? this.wasNecessary,
      alternativeRuleId: alternativeRuleId ?? this.alternativeRuleId,
      request: request ?? this.request,
      response: response ?? this.response,
      latencyMs: latencyMs ?? this.latencyMs,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get total tokens.
  int get totalTokens => inputTokens + outputTokens;

  /// Check if this was an unnecessary call.
  bool get wasUnnecessary => !wasNecessary && alternativeRuleId != null;

  /// Check if the call failed.
  bool get failed => !success;
}

/// LLM call purposes.
abstract class LLMCallPurpose {
  /// Extraction purpose.
  static const String extraction = 'extraction';

  /// Classification purpose.
  static const String classification = 'classification';

  /// Summary purpose.
  static const String summary = 'summary';

  /// Response generation.
  static const String response = 'response';

  /// Claim verification.
  static const String verification = 'verification';

  /// Pattern mining.
  static const String patternMining = 'pattern_mining';

  /// Entity resolution.
  static const String entityResolution = 'entity_resolution';

  /// Evaluation.
  static const String evaluation = 'evaluation';
}

/// LLM cost analytics helper.
class LLMCostAnalytics {
  /// Calculate total cost from a list of call logs.
  static double totalCost(List<LLMCallLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.cost);
  }

  /// Calculate cost by purpose.
  static Map<String, double> costByPurpose(List<LLMCallLog> logs) {
    final result = <String, double>{};
    for (final log in logs) {
      result[log.purpose] = (result[log.purpose] ?? 0.0) + log.cost;
    }
    return result;
  }

  /// Count unnecessary calls.
  static int unnecessaryCallCount(List<LLMCallLog> logs) {
    return logs.where((log) => log.wasUnnecessary).length;
  }

  /// Calculate unnecessary call cost.
  static double unnecessaryCallCost(List<LLMCallLog> logs) {
    return logs
        .where((log) => log.wasUnnecessary)
        .fold(0.0, (sum, log) => sum + log.cost);
  }

  /// Calculate average latency.
  static double averageLatency(List<LLMCallLog> logs) {
    final logsWithLatency = logs.where((log) => log.latencyMs != null).toList();
    if (logsWithLatency.isEmpty) return 0.0;
    final totalLatency =
        logsWithLatency.fold(0, (sum, log) => sum + log.latencyMs!);
    return totalLatency / logsWithLatency.length;
  }

  /// Calculate success rate.
  static double successRate(List<LLMCallLog> logs) {
    if (logs.isEmpty) return 0.0;
    final successCount = logs.where((log) => log.success).length;
    return successCount / logs.length;
  }
}
