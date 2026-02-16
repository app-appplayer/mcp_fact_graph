/// SkillOps Service - L3 Layer operations.
///
/// Handles patterns, skills, rubrics, and evaluation.
library;

import '../domain/entities/pattern.dart';
import '../domain/entities/skill.dart';
import '../domain/entities/rubric.dart';
import '../domain/entities/evaluation_run.dart';
import '../domain/entities/event.dart';
import '../ports/storage_port.dart';
import '../ports/llm_port.dart';

/// Service for L3 SkillOps Layer operations.
class SkillOpsService {
  /// SkillOps storage port.
  final SkillOpsStoragePort _storage;

  /// LLM port for evaluation.
  final LlmPort? _llm;

  SkillOpsService({
    required SkillOpsStoragePort storage,
    LlmPort? llm,
  })  : _storage = storage,
        _llm = llm;

  // =========================================================================
  // Pattern Operations
  // =========================================================================

  /// Register a new pattern.
  Future<Pattern> registerPattern({
    required String name,
    required String description,
    required PatternType patternType,
    required PatternCriteria criteria,
    List<String>? triggerSkillIds,
  }) async {
    final patternId = _generateId('pat');
    final now = DateTime.now();

    final pattern = Pattern(
      patternId: patternId,
      name: name,
      description: description,
      patternType: patternType,
      criteria: criteria,
      firstObserved: now,
      lastObserved: now,
      status: PatternStatus.active,
      triggerSkillIds: triggerSkillIds ?? const [],
    );

    await _storage.savePattern(pattern);
    return pattern;
  }

  /// Get pattern by ID.
  Future<Pattern?> getPattern(String patternId) {
    return _storage.getPattern(patternId);
  }

  /// Get all active patterns.
  Future<List<Pattern>> getActivePatterns() {
    return _storage.getActivePatterns();
  }

  /// Detect pattern matches in events.
  Future<List<PatternMatch>> detectPatterns(List<Event> events) async {
    final patterns = await _storage.getActivePatterns();
    final matches = <PatternMatch>[];

    for (final pattern in patterns) {
      final matchingEvents = _matchPattern(pattern, events);
      if (matchingEvents.isNotEmpty) {
        matches.add(PatternMatch(
          pattern: pattern,
          matchingEventIds: matchingEvents.map((e) => e.eventId).toList(),
          matchedAt: DateTime.now(),
        ));

        // Update pattern statistics
        final updatedPattern = pattern.copyWith(
          lastObserved: DateTime.now(),
          matchCount: pattern.matchCount + matchingEvents.length,
        );
        await _storage.savePattern(updatedPattern);
      }
    }

    return matches;
  }

  // =========================================================================
  // Skill Operations
  // =========================================================================

  /// Register a new skill.
  Future<Skill> registerSkill({
    required String name,
    required String description,
    required SkillCategory category,
    Map<String, dynamic>? inputSchema,
    Map<String, dynamic>? outputSchema,
    List<SkillTrigger>? triggers,
    String? rubricId,
  }) async {
    final skillId = _generateId('skill');
    final now = DateTime.now();

    final skill = Skill(
      skillId: skillId,
      name: name,
      description: description,
      category: category,
      inputSchema: inputSchema ?? const {},
      outputSchema: outputSchema ?? const {},
      triggers: triggers ?? const [],
      status: SkillStatus.active,
      createdAt: now,
      updatedAt: now,
      rubricId: rubricId,
    );

    await _storage.saveSkill(skill);
    return skill;
  }

  /// Get skill by ID.
  Future<Skill?> getSkill(String skillId) {
    return _storage.getSkill(skillId);
  }

  /// Execute a skill (placeholder - actual execution depends on skill type).
  Future<SkillExecutionResult> executeSkill({
    required String skillId,
    required Map<String, dynamic> input,
  }) async {
    final skill = await _storage.getSkill(skillId);
    if (skill == null) {
      throw ArgumentError('Skill not found: $skillId');
    }

    if (!skill.isAvailable) {
      throw StateError('Skill is not available: $skillId');
    }

    final executionId = _generateId('exec');
    final startTime = DateTime.now();

    // Execute skill (placeholder - would dispatch to actual handler)
    final output = await _dispatchSkillExecution(skill, input);

    final duration = DateTime.now().difference(startTime);

    return SkillExecutionResult(
      executionId: executionId,
      skillId: skillId,
      input: input,
      output: output,
      durationMs: duration.inMilliseconds,
      success: true,
    );
  }

  // =========================================================================
  // Rubric Operations
  // =========================================================================

  /// Create a rubric.
  Future<Rubric> createRubric({
    required String name,
    required String description,
    required List<RubricDimension> dimensions,
    double passingThreshold = 0.7,
    List<String>? targetSkillIds,
  }) async {
    final rubricId = _generateId('rub');
    final now = DateTime.now();

    final rubric = Rubric(
      rubricId: rubricId,
      name: name,
      description: description,
      dimensions: dimensions,
      passingThreshold: passingThreshold,
      targetSkillIds: targetSkillIds ?? const [],
      status: RubricStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _storage.saveRubric(rubric);
    return rubric;
  }

  /// Get rubric by ID.
  Future<Rubric?> getRubric(String rubricId) {
    return _storage.getRubric(rubricId);
  }

  // =========================================================================
  // Evaluation Operations
  // =========================================================================

  /// Evaluate skill output against rubric.
  Future<EvaluationRun> evaluate({
    required String skillId,
    required String executionId,
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
    String? rubricId,
    String evaluator = 'automated',
  }) async {
    // Get rubric
    final Rubric rubric;
    if (rubricId != null) {
      final r = await _storage.getRubric(rubricId);
      if (r == null) {
        throw ArgumentError('Rubric not found: $rubricId');
      }
      rubric = r;
    } else {
      final skill = await _storage.getSkill(skillId);
      if (skill?.rubricId == null) {
        throw ArgumentError('No rubric specified for evaluation');
      }
      final r = await _storage.getRubric(skill!.rubricId!);
      if (r == null) {
        throw ArgumentError('Rubric not found: ${skill.rubricId}');
      }
      rubric = r;
    }

    final runId = _generateId('eval');
    final startTime = DateTime.now();

    // Evaluate each dimension
    final dimensionScores = <DimensionScore>[];
    for (final dimension in rubric.dimensions) {
      final score = await _evaluateDimension(dimension, input, output);
      dimensionScores.add(score);
    }

    // Calculate overall score
    final overallScore = _calculateOverallScore(dimensionScores, rubric);
    final passed = overallScore >= rubric.passingThreshold;

    final completedAt = DateTime.now();
    final run = EvaluationRun(
      runId: runId,
      rubricId: rubric.rubricId,
      skillId: skillId,
      executionId: executionId,
      input: input,
      output: output,
      dimensionScores: dimensionScores,
      overallScore: overallScore,
      passed: passed,
      status: EvaluationStatus.completed,
      evaluator: evaluator,
      startedAt: startTime,
      completedAt: completedAt,
      durationMs: completedAt.difference(startTime).inMilliseconds,
    );

    await _storage.saveEvaluationRun(run);
    return run;
  }

  /// Get evaluation run by ID.
  Future<EvaluationRun?> getEvaluationRun(String runId) {
    return _storage.getEvaluationRun(runId);
  }

  /// Get evaluation runs for skill.
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(String skillId) {
    return _storage.getEvaluationRunsForSkill(skillId);
  }

  // =========================================================================
  // Private Methods
  // =========================================================================

  List<Event> _matchPattern(Pattern pattern, List<Event> events) {
    return events.where((event) {
      // Check event type match
      if (pattern.criteria.eventTypes.isNotEmpty &&
          !pattern.criteria.eventTypes.contains(event.eventType)) {
        return false;
      }

      // Check field conditions
      for (final condition in pattern.criteria.conditions) {
        if (!_checkCondition(condition, event.data)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _checkCondition(FieldCondition condition, Map<String, dynamic> data) {
    final value = _getNestedValue(data, condition.field);
    if (value == null && condition.operator != ConditionOperator.notExists) {
      return false;
    }

    switch (condition.operator) {
      case ConditionOperator.equals:
        return value == condition.value;
      case ConditionOperator.notEquals:
        return value != condition.value;
      case ConditionOperator.greaterThan:
        return (value as num) > (condition.value as num);
      case ConditionOperator.lessThan:
        return (value as num) < (condition.value as num);
      case ConditionOperator.greaterOrEqual:
        return (value as num) >= (condition.value as num);
      case ConditionOperator.lessOrEqual:
        return (value as num) <= (condition.value as num);
      case ConditionOperator.contains:
        return value.toString().contains(condition.value.toString());
      case ConditionOperator.startsWith:
        return value.toString().startsWith(condition.value.toString());
      case ConditionOperator.endsWith:
        return value.toString().endsWith(condition.value.toString());
      case ConditionOperator.matches:
        return RegExp(condition.value.toString()).hasMatch(value.toString());
      case ConditionOperator.exists:
        return value != null;
      case ConditionOperator.notExists:
        return value == null;
    }
  }

  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  Future<Map<String, dynamic>> _dispatchSkillExecution(
    Skill skill,
    Map<String, dynamic> input,
  ) async {
    // Placeholder - actual implementation would dispatch to skill handlers
    return {'result': 'executed', 'input': input};
  }

  Future<DimensionScore> _evaluateDimension(
    RubricDimension dimension,
    Map<String, dynamic> input,
    Map<String, dynamic> output,
  ) async {
    // Simple automated evaluation - would use LLM for complex evaluation
    double score = 0.5;

    if (dimension.evaluationType == EvaluationType.automated) {
      // Check if required fields exist in output
      score = output.isNotEmpty ? 0.8 : 0.2;
    } else if (_llm != null &&
        dimension.evaluationType == EvaluationType.llmBased) {
      // Use LLM for evaluation
      final response = await _llm!.complete(LlmRequest(
        systemPrompt: '''You are an evaluator. Score the output on a scale of 0-1.
Dimension: ${dimension.name}
Description: ${dimension.description}
Return only a number between 0 and 1.''',
        prompt: 'Input: $input\nOutput: $output',
        maxTokens: 10,
      ));
      score = double.tryParse(response.content.trim()) ?? 0.5;
    }

    return DimensionScore(
      dimensionId: dimension.dimensionId,
      dimensionName: dimension.name,
      score: score,
      weight: dimension.weight,
    );
  }

  double _calculateOverallScore(
    List<DimensionScore> scores,
    Rubric rubric,
  ) {
    if (scores.isEmpty) return 0.0;

    switch (rubric.weightingStrategy) {
      case WeightingStrategy.equal:
        return scores.fold(0.0, (sum, s) => sum + s.score) / scores.length;

      case WeightingStrategy.custom:
        final totalWeight = scores.fold(0.0, (sum, s) => sum + s.weight);
        if (totalWeight == 0) return 0.0;
        return scores.fold(0.0, (sum, s) => sum + s.weightedScore) / totalWeight;

      case WeightingStrategy.minimum:
        return scores.fold(1.0, (min, s) => s.score < min ? s.score : min);

      case WeightingStrategy.ranked:
        // Simple ranked weighting
        final sorted = [...scores]..sort((a, b) => b.weight.compareTo(a.weight));
        var totalWeight = 0.0;
        var weightedSum = 0.0;
        var rank = 1.0;
        for (final score in sorted) {
          weightedSum += score.score * rank;
          totalWeight += rank;
          rank *= 0.8;
        }
        return weightedSum / totalWeight;
    }
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs() % 10000;
    return '${prefix}_${timestamp}_$random';
  }
}

/// Pattern match result.
class PatternMatch {
  /// Matched pattern.
  final Pattern pattern;

  /// Matching event IDs.
  final List<String> matchingEventIds;

  /// When pattern was matched.
  final DateTime matchedAt;

  const PatternMatch({
    required this.pattern,
    required this.matchingEventIds,
    required this.matchedAt,
  });
}

/// Skill execution result.
class SkillExecutionResult {
  /// Execution ID.
  final String executionId;

  /// Skill ID.
  final String skillId;

  /// Input data.
  final Map<String, dynamic> input;

  /// Output data.
  final Map<String, dynamic> output;

  /// Duration in milliseconds.
  final int durationMs;

  /// Whether execution succeeded.
  final bool success;

  /// Error message if failed.
  final String? error;

  const SkillExecutionResult({
    required this.executionId,
    required this.skillId,
    required this.input,
    required this.output,
    required this.durationMs,
    required this.success,
    this.error,
  });
}
