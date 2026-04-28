/// SkillOps Service - L3 Layer operations.
///
/// Handles patterns, skills, rubrics, and evaluation.
library;

import '../domain/entities/pattern.dart';
import '../domain/entities/skill.dart';
import '../domain/entities/rubric.dart';
import '../domain/entities/evaluation_run.dart';
import '../domain/entities/fact.dart';
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
    required String workspaceId,
    required String name,
    required String description,
    Map<String, dynamic> features = const {},
    double confidence = 0.0,
  }) async {
    final patternId = _generateId('pat');
    final now = DateTime.now();

    final pattern = Pattern(
      patternId: patternId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      features: features,
      confidence: confidence,
      lastObservedAt: now,
      status: PatternStatus.proposed,
      createdAt: now,
      updatedAt: now,
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

  /// Detect pattern matches in facts.
  Future<List<PatternMatch>> detectPatterns(List<Fact> facts) async {
    final patterns = await _storage.getActivePatterns();
    final matches = <PatternMatch>[];

    for (final pattern in patterns) {
      final matchingFacts = _matchPattern(pattern, facts);
      if (matchingFacts.isNotEmpty) {
        matches.add(PatternMatch(
          pattern: pattern,
          matchingFactIds: matchingFacts.map((f) => f.factId).toList(),
          matchedAt: DateTime.now(),
        ));

        // Update last observed time
        final updatedPattern = pattern.copyWith(
          lastObservedAt: DateTime.now(),
          updatedAt: DateTime.now(),
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
    required String workspaceId,
    required String name,
    required String description,
    List<SkillStep> steps = const [],
    List<QualityGate> qualityGates = const [],
  }) async {
    final skillId = _generateId('skill');
    final now = DateTime.now();

    final skill = Skill(
      skillId: skillId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      steps: steps,
      qualityGates: qualityGates,
      status: SkillStatus.active,
      createdAt: now,
      updatedAt: now,
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
    required String workspaceId,
    required String name,
    required String description,
    required List<RubricDimension> dimensions,
    Map<String, double> weights = const {},
    Map<String, dynamic> thresholds = const {},
  }) async {
    final rubricId = _generateId('rub');
    final now = DateTime.now();

    final rubric = Rubric(
      rubricId: rubricId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      dimensions: dimensions,
      weights: weights,
      thresholds: thresholds,
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

  /// Evaluate using rubric with structured input/output.
  Future<EvaluationRun> evaluate({
    required String workspaceId,
    required String rubricId,
    required EvaluationInput input,
    String evaluator = 'automated',
  }) async {
    // Get rubric
    final rubric = await _storage.getRubric(rubricId);
    if (rubric == null) {
      throw ArgumentError('Rubric not found: $rubricId');
    }

    final runId = _generateId('eval');
    final startTime = DateTime.now();

    // Evaluate each dimension
    final dimensionScores = <String, double>{};
    for (final dimension in rubric.dimensions) {
      final score = await _evaluateDimension(dimension, input);
      dimensionScores[dimension.dimensionId] = score;
    }

    // Calculate total score using weights
    final totalScore = _calculateTotalScore(dimensionScores, rubric.weights);

    // Determine grade from thresholds
    final grade = _determineGrade(totalScore, rubric.thresholds);

    final completedAt = DateTime.now();
    final run = EvaluationRun(
      evaluationId: runId,
      workspaceId: workspaceId,
      rubricId: rubric.rubricId,
      rubricVersion: rubric.version,
      policyVersion: '1.0.0',
      asOf: startTime,
      input: input,
      output: EvaluationOutput(
        dimensionScores: dimensionScores,
        totalScore: totalScore,
        grade: grade,
      ),
      idempotencyKey: '${rubricId}_${startTime.millisecondsSinceEpoch}',
      status: EvaluationStatus.completed,
      createdAt: startTime,
      completedAt: completedAt,
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

  List<Fact> _matchPattern(Pattern pattern, List<Fact> facts) {
    // Simple pattern matching based on features
    if (pattern.features.isEmpty) return [];

    return facts.where((fact) {
      // Match by fact type if specified in features
      final targetTypes = pattern.features['factTypes'];
      if (targetTypes is List && targetTypes.isNotEmpty) {
        if (!targetTypes.contains(fact.factType)) return false;
      }

      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> _dispatchSkillExecution(
    Skill skill,
    Map<String, dynamic> input,
  ) async {
    // Placeholder - actual implementation would dispatch to skill handlers
    return {'result': 'executed', 'input': input};
  }

  Future<double> _evaluateDimension(
    RubricDimension dimension,
    EvaluationInput input,
  ) async {
    // Simple automated evaluation
    double score = 0.5;

    if (dimension.measurementType == MeasurementType.boolean) {
      // Boolean: check if target exists
      score = input.targetId != null ? 1.0 : 0.0;
    } else if (_llm != null) {
      // Use LLM for evaluation
      final response = await _llm!.complete(LlmRequest(
        systemPrompt: '''You are an evaluator. Score the output on a scale of 0-1.
Dimension: ${dimension.name}
Description: ${dimension.description}
Return only a number between 0 and 1.''',
        prompt: 'Input: ${input.toJson()}',
        maxTokens: 10,
      ));
      score = double.tryParse(response.content.trim()) ?? 0.5;
    }

    return score;
  }

  double _calculateTotalScore(
    Map<String, double> dimensionScores,
    Map<String, double> weights,
  ) {
    if (dimensionScores.isEmpty) return 0.0;

    if (weights.isEmpty) {
      // Equal weighting
      return dimensionScores.values.fold(0.0, (sum, s) => sum + s) /
          dimensionScores.length;
    }

    // Weighted score
    var totalWeight = 0.0;
    var weightedSum = 0.0;
    for (final entry in dimensionScores.entries) {
      final weight = weights[entry.key] ?? 1.0;
      weightedSum += entry.value * weight;
      totalWeight += weight;
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  String _determineGrade(double totalScore, Map<String, dynamic> thresholds) {
    final passingThreshold = thresholds['pass'] as num? ?? 0.7;
    if (totalScore >= 0.9) return 'A';
    if (totalScore >= 0.8) return 'B';
    if (totalScore >= passingThreshold) return 'C';
    if (totalScore >= 0.5) return 'D';
    return 'F';
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

  /// Matching fact IDs.
  final List<String> matchingFactIds;

  /// When pattern was matched.
  final DateTime matchedAt;

  const PatternMatch({
    required this.pattern,
    required this.matchingFactIds,
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
