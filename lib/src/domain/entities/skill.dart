/// Skill entity for L3 SkillOps Layer.
///
/// Represents executable skills that can be triggered by patterns.
/// Reference: 03-data-model-specification.md Section 2.16.2
library;

/// Skill represents an executable capability with proceduralized steps.
///
/// Skills are triggered by patterns and perform specific actions
/// through defined steps with quality gates.
class Skill {
  /// Unique skill identifier.
  final String skillId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// Skill name.
  final String name;

  /// Skill description.
  final String description;

  /// Skill version (semantic versioning).
  final String version;

  /// Ordered steps defining the skill procedure.
  /// Reference: Design Section 2.16.2 - "Proceduralized Technique"
  final List<SkillStep> steps;

  /// Required evidence types for this skill.
  final List<String> requiredEvidenceTypes;

  /// Quality gates (DoD/verification rules).
  final List<QualityGate> qualityGates;

  /// Owner entity ID.
  final String? owner;

  /// Contexts where this skill applies.
  final List<String> applicability;

  /// Skill status.
  final SkillStatus status;

  /// When skill was created.
  final DateTime createdAt;

  /// When skill was last updated.
  final DateTime updatedAt;

  const Skill({
    required this.skillId,
    required this.workspaceId,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.steps = const [],
    this.requiredEvidenceTypes = const [],
    this.qualityGates = const [],
    this.owner,
    this.applicability = const [],
    this.status = SkillStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      skillId: json['skillId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => SkillStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requiredEvidenceTypes: (json['requiredEvidenceTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      qualityGates: (json['qualityGates'] as List<dynamic>?)
              ?.map((e) => QualityGate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      owner: json['owner'] as String?,
      applicability: (json['applicability'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: SkillStatus.fromString(json['status'] as String? ?? 'draft'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'version': version,
      if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
      if (requiredEvidenceTypes.isNotEmpty)
        'requiredEvidenceTypes': requiredEvidenceTypes,
      if (qualityGates.isNotEmpty)
        'qualityGates': qualityGates.map((g) => g.toJson()).toList(),
      if (owner != null) 'owner': owner,
      if (applicability.isNotEmpty) 'applicability': applicability,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Skill copyWith({
    String? skillId,
    String? workspaceId,
    String? name,
    String? description,
    String? version,
    List<SkillStep>? steps,
    List<String>? requiredEvidenceTypes,
    List<QualityGate>? qualityGates,
    String? owner,
    List<String>? applicability,
    SkillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      skillId: skillId ?? this.skillId,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      steps: steps ?? this.steps,
      requiredEvidenceTypes:
          requiredEvidenceTypes ?? this.requiredEvidenceTypes,
      qualityGates: qualityGates ?? this.qualityGates,
      owner: owner ?? this.owner,
      applicability: applicability ?? this.applicability,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if skill is available for execution.
  bool get isAvailable => status == SkillStatus.active;

  @override
  String toString() => 'Skill($skillId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Skill && skillId == other.skillId;

  @override
  int get hashCode => skillId.hashCode;
}

/// Skill status.
/// Reference: Design Section 2.16.2 - draft | testing | testFail | active | published | suspended | deprecated
enum SkillStatus {
  /// Initial creation state.
  draft,

  /// Automated testing in progress.
  testing,

  /// Tests failed, awaiting fix.
  testFail,

  /// Validated and ready for execution.
  active,

  /// Shared and available to other contexts.
  published,

  /// Temporarily disabled.
  suspended,

  /// No longer recommended for use.
  deprecated;

  static SkillStatus fromString(String value) {
    return SkillStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillStatus.draft,
    );
  }
}

/// SkillStep defines a single step in a skill procedure.
///
/// Reference: 03-data-model-specification.md Section 2.16.2
class SkillStep {
  /// Unique step identifier.
  final String stepId;

  /// Step order/sequence number.
  final int order;

  /// Step name.
  final String name;

  /// Step description.
  final String description;

  /// Expected inputs for this step.
  final Map<String, dynamic> inputs;

  /// Expected outputs from this step.
  final Map<String, dynamic> outputs;

  /// Condition expression to verify step completion.
  final String? checkpointCondition;

  /// Handler for step failure.
  final String? failureHandler;

  /// Expected duration for this step.
  final Duration? expectedDuration;

  const SkillStep({
    required this.stepId,
    required this.order,
    required this.name,
    required this.description,
    this.inputs = const {},
    this.outputs = const {},
    this.checkpointCondition,
    this.failureHandler,
    this.expectedDuration,
  });

  factory SkillStep.fromJson(Map<String, dynamic> json) {
    return SkillStep(
      stepId: json['stepId'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      inputs: json['inputs'] as Map<String, dynamic>? ?? {},
      outputs: json['outputs'] as Map<String, dynamic>? ?? {},
      checkpointCondition: json['checkpointCondition'] as String?,
      failureHandler: json['failureHandler'] as String?,
      expectedDuration: json['expectedDurationMs'] != null
          ? Duration(milliseconds: json['expectedDurationMs'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'order': order,
      'name': name,
      'description': description,
      if (inputs.isNotEmpty) 'inputs': inputs,
      if (outputs.isNotEmpty) 'outputs': outputs,
      if (checkpointCondition != null)
        'checkpointCondition': checkpointCondition,
      if (failureHandler != null) 'failureHandler': failureHandler,
      if (expectedDuration != null)
        'expectedDurationMs': expectedDuration!.inMilliseconds,
    };
  }

  SkillStep copyWith({
    String? stepId,
    int? order,
    String? name,
    String? description,
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? outputs,
    String? checkpointCondition,
    String? failureHandler,
    Duration? expectedDuration,
  }) {
    return SkillStep(
      stepId: stepId ?? this.stepId,
      order: order ?? this.order,
      name: name ?? this.name,
      description: description ?? this.description,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      checkpointCondition: checkpointCondition ?? this.checkpointCondition,
      failureHandler: failureHandler ?? this.failureHandler,
      expectedDuration: expectedDuration ?? this.expectedDuration,
    );
  }

  @override
  String toString() => 'SkillStep($stepId, order: $order, name: $name)';
}

/// QualityGate defines a verification checkpoint for skill execution.
///
/// Reference: 03-data-model-specification.md Section 2.16.2
class QualityGate {
  /// Unique gate identifier.
  final String gateId;

  /// Gate name.
  final String name;

  /// Condition expression to evaluate.
  final String condition;

  /// Action to take on failure.
  final GateAction onFailure;

  /// Gate description.
  final String? description;

  const QualityGate({
    required this.gateId,
    required this.name,
    required this.condition,
    this.onFailure = GateAction.block,
    this.description,
  });

  factory QualityGate.fromJson(Map<String, dynamic> json) {
    return QualityGate(
      gateId: json['gateId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      onFailure:
          GateAction.fromString(json['onFailure'] as String? ?? 'block'),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gateId': gateId,
      'name': name,
      'condition': condition,
      'onFailure': onFailure.name,
      if (description != null) 'description': description,
    };
  }

  QualityGate copyWith({
    String? gateId,
    String? name,
    String? condition,
    GateAction? onFailure,
    String? description,
  }) {
    return QualityGate(
      gateId: gateId ?? this.gateId,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      onFailure: onFailure ?? this.onFailure,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'QualityGate($gateId, name: $name)';
}

/// Actions for quality gate failures.
enum GateAction {
  /// Block execution on failure.
  block,

  /// Warn but continue execution.
  warn,

  /// Log failure and continue.
  log;

  static GateAction fromString(String value) {
    return GateAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GateAction.block,
    );
  }
}
