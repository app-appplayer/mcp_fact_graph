// Tests for SkillOpsService - L3 Layer operations.

import 'package:test/test.dart';
import 'package:mcp_fact_graph/mcp_fact_graph.dart';
// Internal ports — accessed via src path since they are not barrel-exported.
import 'package:mcp_fact_graph/src/ports/storage_port.dart';
import 'package:mcp_fact_graph/src/ports/llm_port.dart';

// Mock SkillOpsStoragePort
class MockSkillOpsStoragePort implements SkillOpsStoragePort {
  final Map<String, Pattern> _patterns = {};
  final Map<String, Skill> _skills = {};
  final Map<String, Rubric> _rubrics = {};
  final Map<String, EvaluationRun> _evaluationRuns = {};

  @override
  Future<void> savePattern(Pattern pattern) async {
    _patterns[pattern.patternId] = pattern;
  }

  @override
  Future<Pattern?> getPattern(String patternId) async {
    return _patterns[patternId];
  }

  @override
  Future<List<Pattern>> queryPatterns(PatternQuery query) async {
    return _patterns.values.toList();
  }

  @override
  Future<List<Pattern>> getActivePatterns() async {
    return _patterns.values
        .where((p) => p.status == PatternStatus.confirmed)
        .toList();
  }

  @override
  Future<void> saveSkill(Skill skill) async {
    _skills[skill.skillId] = skill;
  }

  @override
  Future<Skill?> getSkill(String skillId) async {
    return _skills[skillId];
  }

  @override
  Future<List<Skill>> querySkills(SkillQuery query) async {
    return _skills.values.toList();
  }

  @override
  Future<void> saveRubric(Rubric rubric) async {
    _rubrics[rubric.rubricId] = rubric;
  }

  @override
  Future<Rubric?> getRubric(String rubricId) async {
    return _rubrics[rubricId];
  }

  @override
  Future<List<Rubric>> queryRubrics(RubricQuery query) async {
    return _rubrics.values.toList();
  }

  @override
  Future<void> saveEvaluationRun(EvaluationRun run) async {
    _evaluationRuns[run.evaluationId] = run;
  }

  @override
  Future<EvaluationRun?> getEvaluationRun(String runId) async {
    return _evaluationRuns[runId];
  }

  @override
  Future<List<EvaluationRun>> queryEvaluationRuns(
      EvaluationRunQuery query) async {
    return _evaluationRuns.values.toList();
  }

  @override
  Future<List<EvaluationRun>> getEvaluationRunsForSkill(
      String skillId) async {
    return _evaluationRuns.values.toList();
  }
}

// Mock LlmPort
class MockLlmPort extends LlmPort {
  String completionResult = '0.75';

  @override
  LlmCapabilities get capabilities => const LlmCapabilities.minimal();

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    return LlmResponse(content: completionResult);
  }
}

void main() {
  group('SkillOpsService', () {
    late MockSkillOpsStoragePort storage;
    late MockLlmPort llm;
    late SkillOpsService serviceWithLlm;
    late SkillOpsService serviceWithoutLlm;

    final now = DateTime.now();

    setUp(() {
      storage = MockSkillOpsStoragePort();
      llm = MockLlmPort();

      serviceWithLlm = SkillOpsService(
        storage: storage,
        llm: llm,
      );
      serviceWithoutLlm = SkillOpsService(
        storage: storage,
      );
    });

    group('Pattern operations', () {
      group('registerPattern', () {
        test('creates and saves a pattern', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Weekly Expense',
            description: 'Recurring weekly expense pattern',
            features: const {'factTypes': ['expense']},
            confidence: 0.85,
          );

          expect(pattern.patternId, startsWith('pat_'));
          expect(pattern.workspaceId, equals('ws-1'));
          expect(pattern.name, equals('Weekly Expense'));
          expect(pattern.description,
              equals('Recurring weekly expense pattern'));
          expect(pattern.features, equals({'factTypes': ['expense']}));
          expect(pattern.confidence, equals(0.85));
          expect(pattern.status, equals(PatternStatus.proposed));
        });

        test('saves pattern to storage', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Test Pattern',
            description: 'Test',
          );

          final stored = await storage.getPattern(pattern.patternId);
          expect(stored, isNotNull);
        });

        test('uses default values for optional parameters', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Test Pattern',
            description: 'Test',
          );

          expect(pattern.features, isEmpty);
          expect(pattern.confidence, equals(0.0));
        });
      });

      group('getPattern', () {
        test('returns pattern when found', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
          );

          final result =
              await serviceWithLlm.getPattern(pattern.patternId);
          expect(result, isNotNull);
          expect(result!.patternId, equals(pattern.patternId));
        });

        test('returns null when not found', () async {
          final result = await serviceWithLlm.getPattern('nonexistent');
          expect(result, isNull);
        });
      });

      group('getActivePatterns', () {
        test('returns only confirmed patterns', () async {
          await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Pattern 1',
            description: 'Test',
          );

          // The service registers patterns as "proposed", not "confirmed"
          final active = await serviceWithLlm.getActivePatterns();
          expect(active, isEmpty);
        });
      });

      group('detectPatterns', () {
        test('detects matching patterns in facts', () async {
          // Register and manually confirm a pattern
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Expense Pattern',
            description: 'Matches expenses',
            features: const {
              'factTypes': ['expense']
            },
          );
          // Manually confirm the pattern in storage
          await storage.savePattern(
              pattern.copyWith(status: PatternStatus.confirmed));

          final facts = [
            Fact(
              factId: 'fact-1',
              workspaceId: 'ws-1',
              factType: 'expense',
              summary: 'Lunch',
              occurredAt: now,
              candidateId: 'cand-1',
              createdAt: now,
            ),
          ];

          final matches = await serviceWithLlm.detectPatterns(facts);

          expect(matches, hasLength(1));
          expect(matches.first.pattern.name, equals('Expense Pattern'));
          expect(matches.first.matchingFactIds, contains('fact-1'));
        });

        test('returns empty when no patterns match', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Empty Pattern',
            description: 'No features',
          );
          await storage.savePattern(
              pattern.copyWith(status: PatternStatus.confirmed));

          final facts = [
            Fact(
              factId: 'fact-1',
              workspaceId: 'ws-1',
              factType: 'expense',
              summary: 'Lunch',
              occurredAt: now,
              candidateId: 'cand-1',
              createdAt: now,
            ),
          ];

          final matches = await serviceWithLlm.detectPatterns(facts);
          // Empty features means no match
          expect(matches, isEmpty);
        });

        test('does not match when factType not in target list', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Task Pattern',
            description: 'Matches tasks only',
            features: const {
              'factTypes': ['task']
            },
          );
          await storage.savePattern(
              pattern.copyWith(status: PatternStatus.confirmed));

          final facts = [
            Fact(
              factId: 'fact-1',
              workspaceId: 'ws-1',
              factType: 'expense',
              summary: 'Lunch',
              occurredAt: now,
              candidateId: 'cand-1',
              createdAt: now,
            ),
          ];

          final matches = await serviceWithLlm.detectPatterns(facts);
          expect(matches, isEmpty);
        });

        test('updates last observed time on match', () async {
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Expense Pattern',
            description: 'Matches expenses',
            features: const {
              'factTypes': ['expense']
            },
          );
          await storage.savePattern(
              pattern.copyWith(status: PatternStatus.confirmed));

          final facts = [
            Fact(
              factId: 'fact-1',
              workspaceId: 'ws-1',
              factType: 'expense',
              summary: 'Lunch',
              occurredAt: now,
              candidateId: 'cand-1',
              createdAt: now,
            ),
          ];

          await serviceWithLlm.detectPatterns(facts);

          final updated = await storage.getPattern(pattern.patternId);
          expect(updated, isNotNull);
        });

        test('matches pattern with non-list factTypes feature', () async {
          // Features with factTypes that is not a List should pass through
          final pattern = await serviceWithLlm.registerPattern(
            workspaceId: 'ws-1',
            name: 'Generic Pattern',
            description: 'Has non-list features',
            features: const {'someKey': 'someValue'},
          );
          await storage.savePattern(
              pattern.copyWith(status: PatternStatus.confirmed));

          final facts = [
            Fact(
              factId: 'fact-1',
              workspaceId: 'ws-1',
              factType: 'expense',
              summary: 'Lunch',
              occurredAt: now,
              candidateId: 'cand-1',
              createdAt: now,
            ),
          ];

          final matches = await serviceWithLlm.detectPatterns(facts);
          // Pattern has non-empty features but no factTypes filter, so facts match
          expect(matches, hasLength(1));
        });
      });
    });

    group('Skill operations', () {
      group('registerSkill', () {
        test('creates and saves a skill', () async {
          final skill = await serviceWithLlm.registerSkill(
            workspaceId: 'ws-1',
            name: 'Expense Tracker',
            description: 'Tracks expenses automatically',
          );

          expect(skill.skillId, startsWith('skill_'));
          expect(skill.workspaceId, equals('ws-1'));
          expect(skill.name, equals('Expense Tracker'));
          expect(skill.status, equals(SkillStatus.active));
        });

        test('includes steps and quality gates', () async {
          final steps = [
            const SkillStep(
              stepId: 'step-1',
              order: 1,
              name: 'Extract',
              description: 'Extract expense data',
            ),
          ];
          final gates = [
            const QualityGate(
              gateId: 'gate-1',
              name: 'Completeness',
              condition: 'amount > 0',
            ),
          ];

          final skill = await serviceWithLlm.registerSkill(
            workspaceId: 'ws-1',
            name: 'Expense Tracker',
            description: 'Track expenses',
            steps: steps,
            qualityGates: gates,
          );

          expect(skill.steps, hasLength(1));
          expect(skill.qualityGates, hasLength(1));
        });
      });

      group('getSkill', () {
        test('returns skill when found', () async {
          final skill = await serviceWithLlm.registerSkill(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
          );

          final result = await serviceWithLlm.getSkill(skill.skillId);
          expect(result, isNotNull);
        });

        test('returns null when not found', () async {
          final result = await serviceWithLlm.getSkill('nonexistent');
          expect(result, isNull);
        });
      });

      group('executeSkill', () {
        test('executes a skill successfully', () async {
          final skill = await serviceWithLlm.registerSkill(
            workspaceId: 'ws-1',
            name: 'Test Skill',
            description: 'Test',
          );

          final result = await serviceWithLlm.executeSkill(
            skillId: skill.skillId,
            input: const {'data': 'test'},
          );

          expect(result.success, isTrue);
          expect(result.skillId, equals(skill.skillId));
          expect(result.executionId, startsWith('exec_'));
          expect(result.output, isNotNull);
          expect(result.input, equals({'data': 'test'}));
        });

        test('throws ArgumentError when skill not found', () async {
          expect(
            () => serviceWithLlm.executeSkill(
              skillId: 'nonexistent',
              input: const {},
            ),
            throwsArgumentError,
          );
        });

        test('throws StateError when skill not available', () async {
          // Register a skill with draft status (default without active)
          final skill = await serviceWithLlm.registerSkill(
            workspaceId: 'ws-1',
            name: 'Draft Skill',
            description: 'Test',
          );
          // Set skill to draft status
          await storage.saveSkill(
              skill.copyWith(status: SkillStatus.draft));

          expect(
            () => serviceWithLlm.executeSkill(
              skillId: skill.skillId,
              input: const {},
            ),
            throwsStateError,
          );
        });
      });
    });

    group('Rubric operations', () {
      group('createRubric', () {
        test('creates and saves a rubric', () async {
          final dimensions = [
            const RubricDimension(
              dimensionId: 'dim-1',
              name: 'Accuracy',
              description: 'Data accuracy',
            ),
          ];

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Quality Rubric',
            description: 'Evaluate output quality',
            dimensions: dimensions,
          );

          expect(rubric.rubricId, startsWith('rub_'));
          expect(rubric.workspaceId, equals('ws-1'));
          expect(rubric.name, equals('Quality Rubric'));
          expect(rubric.dimensions, hasLength(1));
          expect(rubric.status, equals(RubricStatus.active));
        });

        test('includes weights and thresholds', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Weighted Rubric',
            description: 'Test',
            dimensions: const [],
            weights: const {'dim-1': 0.6, 'dim-2': 0.4},
            thresholds: const {'pass': 0.7},
          );

          expect(rubric.weights, equals({'dim-1': 0.6, 'dim-2': 0.4}));
          expect(rubric.thresholds, equals({'pass': 0.7}));
        });
      });

      group('getRubric', () {
        test('returns rubric when found', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
            dimensions: const [],
          );

          final result = await serviceWithLlm.getRubric(rubric.rubricId);
          expect(result, isNotNull);
        });

        test('returns null when not found', () async {
          final result = await serviceWithLlm.getRubric('nonexistent');
          expect(result, isNull);
        });
      });
    });

    group('Evaluation operations', () {
      group('evaluate', () {
        test('evaluates with boolean dimension', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Completeness',
                description: 'Is data complete?',
                measurementType: MeasurementType.boolean,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.evaluationId, startsWith('eval_'));
          expect(run.status, equals(EvaluationStatus.completed));
          expect(run.output.totalScore, greaterThanOrEqualTo(0.0));
          // Boolean: targetId is not null so score = 1.0
          expect(run.output.dimensionScores['dim-1'], equals(1.0));
        });

        test('evaluates with boolean dimension and null targetId', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Completeness',
                description: 'Is data complete?',
                measurementType: MeasurementType.boolean,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(targetType: 'fact'),
          );

          // Boolean: targetId is null so score = 0.0
          expect(run.output.dimensionScores['dim-1'], equals(0.0));
        });

        test('evaluates with LLM-scored dimension', () async {
          llm.completionResult = '0.85';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Output quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.output.dimensionScores['dim-1'], equals(0.85));
        });

        test('evaluates without LLM falls back to default score', () async {
          final rubric = await serviceWithoutLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Output quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithoutLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          // Without LLM, default score is 0.5
          expect(run.output.dimensionScores['dim-1'], equals(0.5));
        });

        test('handles unparseable LLM response', () async {
          llm.completionResult = 'not a number';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Output quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          // Falls back to 0.5 when parsing fails
          expect(run.output.dimensionScores['dim-1'], equals(0.5));
        });

        test('calculates weighted total score', () async {
          llm.completionResult = '0.8';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Weighted Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Accuracy',
                description: 'Accuracy',
                measurementType: MeasurementType.boolean,
              ),
              RubricDimension(
                dimensionId: 'dim-2',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
            weights: const {'dim-1': 0.6, 'dim-2': 0.4},
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          // dim-1 (boolean, targetId!=null) = 1.0, dim-2 (LLM) = 0.8
          // Weighted: (1.0*0.6 + 0.8*0.4) / (0.6+0.4) = 0.92
          expect(run.output.totalScore, closeTo(0.92, 0.01));
        });

        test('calculates equal-weight total when no weights', () async {
          final rubric = await serviceWithoutLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Unweighted Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'D1',
                description: 'D1',
                measurementType: MeasurementType.boolean,
              ),
              RubricDimension(
                dimensionId: 'dim-2',
                name: 'D2',
                description: 'D2',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithoutLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          // dim-1 = 1.0 (boolean, has targetId), dim-2 = 0.5 (no LLM default)
          // Equal weight: (1.0 + 0.5) / 2 = 0.75
          expect(run.output.totalScore, closeTo(0.75, 0.01));
        });

        test('returns 0 total for empty dimensions', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Empty Rubric',
            description: 'No dimensions',
            dimensions: const [],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(targetType: 'fact'),
          );

          expect(run.output.totalScore, equals(0.0));
        });

        test('determines grade from score', () async {
          llm.completionResult = '0.95';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Grade Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
            thresholds: const {'pass': 0.7},
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          // Score 0.95 >= 0.9 => grade A
          expect(run.output.grade, equals('A'));
        });

        test('determines grade B for score >= 0.8', () async {
          llm.completionResult = '0.85';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Grade Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.output.grade, equals('B'));
        });

        test('determines grade C for score >= passing threshold', () async {
          llm.completionResult = '0.72';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Grade Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
            thresholds: const {'pass': 0.7},
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.output.grade, equals('C'));
        });

        test('determines grade D for score >= 0.5', () async {
          llm.completionResult = '0.55';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Grade Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.output.grade, equals('D'));
        });

        test('determines grade F for score < 0.5', () async {
          llm.completionResult = '0.3';

          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Grade Rubric',
            description: 'Test',
            dimensions: const [
              RubricDimension(
                dimensionId: 'dim-1',
                name: 'Quality',
                description: 'Quality',
                measurementType: MeasurementType.numeric,
              ),
            ],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(
              targetType: 'fact',
              targetId: 'fact-1',
            ),
          );

          expect(run.output.grade, equals('F'));
        });

        test('throws ArgumentError when rubric not found', () async {
          expect(
            () => serviceWithLlm.evaluate(
              workspaceId: 'ws-1',
              rubricId: 'nonexistent',
              input: const EvaluationInput(targetType: 'fact'),
            ),
            throwsArgumentError,
          );
        });

        test('saves evaluation run to storage', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
            dimensions: const [],
          );

          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(targetType: 'fact'),
          );

          final stored =
              await storage.getEvaluationRun(run.evaluationId);
          expect(stored, isNotNull);
        });
      });

      group('getEvaluationRun', () {
        test('returns run when found', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
            dimensions: const [],
          );
          final run = await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(targetType: 'fact'),
          );

          final result =
              await serviceWithLlm.getEvaluationRun(run.evaluationId);
          expect(result, isNotNull);
        });

        test('returns null when not found', () async {
          final result =
              await serviceWithLlm.getEvaluationRun('nonexistent');
          expect(result, isNull);
        });
      });

      group('getEvaluationRunsForSkill', () {
        test('returns runs for skill', () async {
          final rubric = await serviceWithLlm.createRubric(
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
            dimensions: const [],
          );
          await serviceWithLlm.evaluate(
            workspaceId: 'ws-1',
            rubricId: rubric.rubricId,
            input: const EvaluationInput(targetType: 'fact'),
          );

          final runs = await serviceWithLlm
              .getEvaluationRunsForSkill('skill-1');
          expect(runs, isNotEmpty);
        });
      });
    });

    group('PatternMatch', () {
      test('has correct properties', () {
        final match = PatternMatch(
          pattern: Pattern(
            patternId: 'pat-1',
            workspaceId: 'ws-1',
            name: 'Test',
            description: 'Test',
            lastObservedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
          matchingFactIds: const ['fact-1', 'fact-2'],
          matchedAt: now,
        );

        expect(match.pattern.patternId, equals('pat-1'));
        expect(match.matchingFactIds, hasLength(2));
        expect(match.matchedAt, equals(now));
      });
    });

    group('SkillExecutionResult', () {
      test('has correct properties', () {
        const result = SkillExecutionResult(
          executionId: 'exec-1',
          skillId: 'skill-1',
          input: {'data': 'test'},
          output: {'result': 'success'},
          durationMs: 150,
          success: true,
        );

        expect(result.executionId, equals('exec-1'));
        expect(result.skillId, equals('skill-1'));
        expect(result.input, equals({'data': 'test'}));
        expect(result.output, equals({'result': 'success'}));
        expect(result.durationMs, equals(150));
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('supports error property', () {
        const result = SkillExecutionResult(
          executionId: 'exec-1',
          skillId: 'skill-1',
          input: {},
          output: {},
          durationMs: 0,
          success: false,
          error: 'Something failed',
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Something failed'));
      });
    });

    // Additional coverage tests

    group('registerPattern - additional coverage', () {
      test('pattern has all fields set correctly', () async {
        final pattern = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Full Pattern',
          description: 'A complete pattern',
          features: const {'factTypes': ['expense', 'task'], 'threshold': 0.5},
          confidence: 0.75,
        );

        expect(pattern.patternId, startsWith('pat_'));
        expect(pattern.workspaceId, equals('ws-1'));
        expect(pattern.name, equals('Full Pattern'));
        expect(pattern.description, equals('A complete pattern'));
        expect(pattern.features['factTypes'], equals(['expense', 'task']));
        expect(pattern.features['threshold'], equals(0.5));
        expect(pattern.confidence, equals(0.75));
        expect(pattern.status, equals(PatternStatus.proposed));
        expect(pattern.lastObservedAt, isNotNull);
        expect(pattern.createdAt, isNotNull);
        expect(pattern.updatedAt, isNotNull);

        // Verify saved to storage
        final stored = await storage.getPattern(pattern.patternId);
        expect(stored, isNotNull);
        expect(stored!.name, equals('Full Pattern'));
      });
    });

    group('getPattern - additional coverage', () {
      test('returns pattern after registration', () async {
        final pattern = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Lookup Pattern',
          description: 'Test',
        );

        final result = await serviceWithLlm.getPattern(pattern.patternId);
        expect(result, isNotNull);
        expect(result!.name, equals('Lookup Pattern'));
        expect(result.description, equals('Test'));
      });
    });

    group('getActivePatterns - additional coverage', () {
      test('returns confirmed patterns only', () async {
        // Register proposed pattern
        final pattern1 = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Proposed',
          description: 'Test',
        );

        await Future.delayed(const Duration(milliseconds: 2));

        // Register and confirm another
        final pattern2 = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Confirmed',
          description: 'Test',
        );
        await storage.savePattern(
            pattern2.copyWith(status: PatternStatus.confirmed));

        // Verify only confirmed patterns returned
        final active = await serviceWithLlm.getActivePatterns();
        expect(active, hasLength(1));
        expect(active.first.name, equals('Confirmed'));

        // Suppress unused variable warning by using pattern1
        expect(pattern1.status, equals(PatternStatus.proposed));
      });
    });

    group('detectPatterns - additional coverage', () {
      test('detects multiple matching patterns', () async {
        final pattern1 = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Expense Pattern',
          description: 'Matches expenses',
          features: const {
            'factTypes': ['expense']
          },
        );
        await storage.savePattern(
            pattern1.copyWith(status: PatternStatus.confirmed));

        await Future.delayed(const Duration(milliseconds: 2));

        final pattern2 = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'All Pattern',
          description: 'Matches all',
          features: const {'someKey': 'someValue'},
        );
        await storage.savePattern(
            pattern2.copyWith(status: PatternStatus.confirmed));

        final facts = [
          Fact(
            factId: 'fact-1',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'Lunch',
            occurredAt: now,
            candidateId: 'cand-1',
            createdAt: now,
          ),
        ];

        final matches = await serviceWithLlm.detectPatterns(facts);
        expect(matches, hasLength(2));
      });

      test('returns PatternMatch with correct matchedAt timestamp', () async {
        final pattern = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Timestamp Pattern',
          description: 'Test',
          features: const {
            'factTypes': ['task']
          },
        );
        await storage.savePattern(
            pattern.copyWith(status: PatternStatus.confirmed));

        final facts = [
          Fact(
            factId: 'fact-ts',
            workspaceId: 'ws-1',
            factType: 'task',
            summary: 'Meeting',
            occurredAt: now,
            candidateId: 'cand-1',
            createdAt: now,
          ),
        ];

        final before = DateTime.now();
        final matches = await serviceWithLlm.detectPatterns(facts);
        final after = DateTime.now();

        expect(matches, hasLength(1));
        expect(matches.first.matchedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(before.millisecondsSinceEpoch));
        expect(matches.first.matchedAt.millisecondsSinceEpoch,
            lessThanOrEqualTo(after.millisecondsSinceEpoch));
        expect(matches.first.matchingFactIds, contains('fact-ts'));
      });

      test('matches multiple facts per pattern', () async {
        final pattern = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Multi Fact Pattern',
          description: 'Matches multiple expenses',
          features: const {
            'factTypes': ['expense']
          },
        );
        await storage.savePattern(
            pattern.copyWith(status: PatternStatus.confirmed));

        final facts = [
          Fact(
            factId: 'fact-a',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'Lunch',
            occurredAt: now,
            candidateId: 'cand-1',
            createdAt: now,
          ),
          Fact(
            factId: 'fact-b',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'Dinner',
            occurredAt: now,
            candidateId: 'cand-2',
            createdAt: now,
          ),
        ];

        final matches = await serviceWithLlm.detectPatterns(facts);
        expect(matches, hasLength(1));
        expect(matches.first.matchingFactIds, contains('fact-a'));
        expect(matches.first.matchingFactIds, contains('fact-b'));
      });

      test('returns empty when no active patterns exist', () async {
        final facts = [
          Fact(
            factId: 'fact-1',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'Lunch',
            occurredAt: now,
            candidateId: 'cand-1',
            createdAt: now,
          ),
        ];

        final matches = await serviceWithLlm.detectPatterns(facts);
        expect(matches, isEmpty);
      });

      test('empty factTypes list matches all facts', () async {
        final pattern = await serviceWithLlm.registerPattern(
          workspaceId: 'ws-1',
          name: 'Empty List Pattern',
          description: 'Has empty factTypes list',
          features: const {'factTypes': []},
        );
        await storage.savePattern(
            pattern.copyWith(status: PatternStatus.confirmed));

        final facts = [
          Fact(
            factId: 'fact-1',
            workspaceId: 'ws-1',
            factType: 'expense',
            summary: 'Lunch',
            occurredAt: now,
            candidateId: 'cand-1',
            createdAt: now,
          ),
        ];

        final matches = await serviceWithLlm.detectPatterns(facts);
        // Empty list is truthy but not isNotEmpty, so the check passes
        expect(matches, hasLength(1));
      });
    });

    group('registerSkill - additional coverage', () {
      test('creates skill with all fields', () async {
        final steps = [
          const SkillStep(
            stepId: 'step-1',
            order: 1,
            name: 'Step One',
            description: 'First step',
          ),
          const SkillStep(
            stepId: 'step-2',
            order: 2,
            name: 'Step Two',
            description: 'Second step',
          ),
        ];
        final gates = [
          const QualityGate(
            gateId: 'gate-1',
            name: 'Gate One',
            condition: 'output.valid == true',
          ),
        ];

        final skill = await serviceWithLlm.registerSkill(
          workspaceId: 'ws-1',
          name: 'Complete Skill',
          description: 'A skill with all fields',
          steps: steps,
          qualityGates: gates,
        );

        expect(skill.skillId, startsWith('skill_'));
        expect(skill.workspaceId, equals('ws-1'));
        expect(skill.name, equals('Complete Skill'));
        expect(skill.description, equals('A skill with all fields'));
        expect(skill.steps, hasLength(2));
        expect(skill.qualityGates, hasLength(1));
        expect(skill.status, equals(SkillStatus.active));
        expect(skill.createdAt, isNotNull);
        expect(skill.updatedAt, isNotNull);

        // Verify saved
        final stored = await storage.getSkill(skill.skillId);
        expect(stored, isNotNull);
      });
    });

    group('executeSkill - additional coverage', () {
      test('returns execution result with input/output and duration', () async {
        final skill = await serviceWithLlm.registerSkill(
          workspaceId: 'ws-1',
          name: 'Execute Test',
          description: 'Test',
        );

        final result = await serviceWithLlm.executeSkill(
          skillId: skill.skillId,
          input: const {'key': 'value', 'number': 42},
        );

        expect(result.executionId, startsWith('exec_'));
        expect(result.skillId, equals(skill.skillId));
        expect(result.input, equals({'key': 'value', 'number': 42}));
        expect(result.output, isNotNull);
        expect(result.output['result'], equals('executed'));
        expect(result.output['input'], equals({'key': 'value', 'number': 42}));
        expect(result.durationMs, greaterThanOrEqualTo(0));
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });
    });

    group('createRubric - additional coverage', () {
      test('creates rubric with all fields correctly populated', () async {
        final dimensions = [
          const RubricDimension(
            dimensionId: 'dim-a',
            name: 'Accuracy',
            description: 'Accuracy of results',
            measurementType: MeasurementType.numeric,
          ),
          const RubricDimension(
            dimensionId: 'dim-b',
            name: 'Completeness',
            description: 'Data completeness',
            measurementType: MeasurementType.boolean,
          ),
        ];

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Full Rubric',
          description: 'Complete rubric',
          dimensions: dimensions,
          weights: const {'dim-a': 0.7, 'dim-b': 0.3},
          thresholds: const {'pass': 0.6, 'excellent': 0.9},
        );

        expect(rubric.rubricId, startsWith('rub_'));
        expect(rubric.workspaceId, equals('ws-1'));
        expect(rubric.name, equals('Full Rubric'));
        expect(rubric.description, equals('Complete rubric'));
        expect(rubric.dimensions, hasLength(2));
        expect(rubric.weights, equals({'dim-a': 0.7, 'dim-b': 0.3}));
        expect(rubric.thresholds, equals({'pass': 0.6, 'excellent': 0.9}));
        expect(rubric.status, equals(RubricStatus.active));
        expect(rubric.createdAt, isNotNull);
        expect(rubric.updatedAt, isNotNull);

        // Verify saved
        final stored = await storage.getRubric(rubric.rubricId);
        expect(stored, isNotNull);
      });

      test('creates rubric with default weights and thresholds', () async {
        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Default Rubric',
          description: 'Test',
          dimensions: const [],
        );

        expect(rubric.weights, isEmpty);
        expect(rubric.thresholds, isEmpty);
      });
    });

    group('getRubric - additional coverage', () {
      test('returns saved rubric with correct details', () async {
        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Lookup Rubric',
          description: 'Test',
          dimensions: const [],
        );

        final result = await serviceWithLlm.getRubric(rubric.rubricId);
        expect(result, isNotNull);
        expect(result!.name, equals('Lookup Rubric'));
      });
    });

    group('evaluate - additional coverage', () {
      test('evaluate sets all evaluation run fields', () async {
        llm.completionResult = '0.8';

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Full Eval Rubric',
          description: 'Test',
          dimensions: const [
            RubricDimension(
              dimensionId: 'dim-1',
              name: 'Quality',
              description: 'Quality',
              measurementType: MeasurementType.numeric,
            ),
          ],
          thresholds: const {'pass': 0.7},
        );

        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(
            targetType: 'fact',
            targetId: 'fact-1',
          ),
          evaluator: 'custom-evaluator',
        );

        expect(run.evaluationId, startsWith('eval_'));
        expect(run.workspaceId, equals('ws-1'));
        expect(run.rubricId, equals(rubric.rubricId));
        expect(run.rubricVersion, equals(rubric.version));
        expect(run.policyVersion, equals('1.0.0'));
        expect(run.status, equals(EvaluationStatus.completed));
        expect(run.createdAt, isNotNull);
        expect(run.completedAt, isNotNull);
        expect(run.idempotencyKey, isNotEmpty);
        expect(run.output.dimensionScores, isNotEmpty);
        expect(run.output.totalScore, equals(0.8));
        expect(run.output.grade, equals('B'));

        // Verify saved
        final stored = await storage.getEvaluationRun(run.evaluationId);
        expect(stored, isNotNull);
      });

      test('evaluate with multiple dimensions and weighted scores', () async {
        llm.completionResult = '0.6';

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Multi Dim Rubric',
          description: 'Test',
          dimensions: const [
            RubricDimension(
              dimensionId: 'dim-1',
              name: 'Boolean Check',
              description: 'Boolean dimension',
              measurementType: MeasurementType.boolean,
            ),
            RubricDimension(
              dimensionId: 'dim-2',
              name: 'LLM Quality',
              description: 'Quality dimension',
              measurementType: MeasurementType.numeric,
            ),
          ],
          weights: const {'dim-1': 0.5, 'dim-2': 0.5},
        );

        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(
            targetType: 'fact',
            targetId: 'fact-1',
          ),
        );

        // dim-1 (boolean, has targetId) = 1.0
        // dim-2 (LLM) = 0.6
        // Weighted: (1.0 * 0.5 + 0.6 * 0.5) / (0.5 + 0.5) = 0.8
        expect(run.output.dimensionScores['dim-1'], equals(1.0));
        expect(run.output.dimensionScores['dim-2'], equals(0.6));
        expect(run.output.totalScore, closeTo(0.8, 0.01));
        expect(run.output.grade, equals('B'));
      });

      test('grade C when score equals passing threshold', () async {
        llm.completionResult = '0.7';

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Threshold Rubric',
          description: 'Test',
          dimensions: const [
            RubricDimension(
              dimensionId: 'dim-1',
              name: 'Quality',
              description: 'Quality',
              measurementType: MeasurementType.numeric,
            ),
          ],
          thresholds: const {'pass': 0.7},
        );

        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(
            targetType: 'fact',
            targetId: 'fact-1',
          ),
        );

        expect(run.output.totalScore, equals(0.7));
        expect(run.output.grade, equals('C'));
      });

      test('grade uses default passing threshold when not in thresholds',
          () async {
        llm.completionResult = '0.72';

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'No Threshold Rubric',
          description: 'Test',
          dimensions: const [
            RubricDimension(
              dimensionId: 'dim-1',
              name: 'Quality',
              description: 'Quality',
              measurementType: MeasurementType.numeric,
            ),
          ],
          // No 'pass' threshold - defaults to 0.7
        );

        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(
            targetType: 'fact',
            targetId: 'fact-1',
          ),
        );

        // 0.72 >= 0.7 (default pass) => C
        expect(run.output.grade, equals('C'));
      });

      test('weighted score uses default weight 1.0 for unmapped dimensions',
          () async {
        llm.completionResult = '0.9';

        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Partial Weight Rubric',
          description: 'Test',
          dimensions: const [
            RubricDimension(
              dimensionId: 'dim-1',
              name: 'Mapped',
              description: 'Has explicit weight',
              measurementType: MeasurementType.numeric,
            ),
            RubricDimension(
              dimensionId: 'dim-2',
              name: 'Unmapped',
              description: 'No explicit weight, defaults to 1.0',
              measurementType: MeasurementType.numeric,
            ),
          ],
          weights: const {'dim-1': 2.0},
          // dim-2 is not in weights, so defaults to 1.0
        );

        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(
            targetType: 'fact',
            targetId: 'fact-1',
          ),
        );

        // dim-1 = 0.9, weight = 2.0
        // dim-2 = 0.9, weight = 1.0 (default)
        // totalScore = (0.9 * 2.0 + 0.9 * 1.0) / (2.0 + 1.0) = 2.7 / 3.0 = 0.9
        expect(run.output.totalScore, closeTo(0.9, 0.01));
        expect(run.output.grade, equals('A'));
      });
    });

    group('getEvaluationRun - additional coverage', () {
      test('returns stored evaluation run', () async {
        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Test',
          description: 'Test',
          dimensions: const [],
        );
        final run = await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(targetType: 'fact'),
        );

        final result =
            await serviceWithLlm.getEvaluationRun(run.evaluationId);
        expect(result, isNotNull);
        expect(result!.evaluationId, equals(run.evaluationId));
        expect(result.status, equals(EvaluationStatus.completed));
      });
    });

    group('getEvaluationRunsForSkill - additional coverage', () {
      test('returns evaluation runs', () async {
        final rubric = await serviceWithLlm.createRubric(
          workspaceId: 'ws-1',
          name: 'Test',
          description: 'Test',
          dimensions: const [],
        );
        await serviceWithLlm.evaluate(
          workspaceId: 'ws-1',
          rubricId: rubric.rubricId,
          input: const EvaluationInput(targetType: 'fact'),
        );

        final runs = await serviceWithLlm
            .getEvaluationRunsForSkill('any-skill');
        expect(runs, isNotEmpty);
      });
    });

    group('PatternMatch - additional coverage', () {
      test('all fields are accessible', () {
        final matchedAt = DateTime.now();
        final match = PatternMatch(
          pattern: Pattern(
            patternId: 'pat-full',
            workspaceId: 'ws-1',
            name: 'Full Pattern',
            description: 'Full description',
            features: const {'key': 'value'},
            confidence: 0.9,
            lastObservedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
          matchingFactIds: const ['fact-1', 'fact-2', 'fact-3'],
          matchedAt: matchedAt,
        );

        expect(match.pattern.patternId, equals('pat-full'));
        expect(match.pattern.name, equals('Full Pattern'));
        expect(match.pattern.description, equals('Full description'));
        expect(match.pattern.features, equals({'key': 'value'}));
        expect(match.pattern.confidence, equals(0.9));
        expect(match.matchingFactIds, hasLength(3));
        expect(match.matchedAt, equals(matchedAt));
      });
    });

    group('SkillExecutionResult - additional coverage', () {
      test('all fields including error are accessible', () {
        const result = SkillExecutionResult(
          executionId: 'exec-full',
          skillId: 'skill-full',
          input: {'a': 1, 'b': 'two'},
          output: {'result': 'done', 'count': 5},
          durationMs: 250,
          success: true,
          error: null,
        );

        expect(result.executionId, equals('exec-full'));
        expect(result.skillId, equals('skill-full'));
        expect(result.input['a'], equals(1));
        expect(result.input['b'], equals('two'));
        expect(result.output['result'], equals('done'));
        expect(result.output['count'], equals(5));
        expect(result.durationMs, equals(250));
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('failed execution with error message', () {
        const result = SkillExecutionResult(
          executionId: 'exec-fail',
          skillId: 'skill-fail',
          input: {'data': 'bad'},
          output: {},
          durationMs: 10,
          success: false,
          error: 'Execution timeout',
        );

        expect(result.executionId, equals('exec-fail'));
        expect(result.success, isFalse);
        expect(result.error, equals('Execution timeout'));
        expect(result.durationMs, equals(10));
      });
    });
  });
}
