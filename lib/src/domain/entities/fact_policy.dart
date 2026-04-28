/// FactPolicy entity model.
///
/// Policy defines rules for classification, evaluation, and settlement.
/// Design: 03-data-model-specification.md Section 2.8
/// Note: Named FactPolicy to avoid conflict with mcp_bundle Policy
library;

/// Type of policy.
enum PolicyType {
  /// Classification policy.
  classification,

  /// Evaluation policy.
  evaluation,

  /// Settlement policy.
  settlement,

  /// Alert policy.
  alert;

  /// Create from string.
  static PolicyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'classification':
        return PolicyType.classification;
      case 'evaluation':
        return PolicyType.evaluation;
      case 'settlement':
        return PolicyType.settlement;
      case 'alert':
        return PolicyType.alert;
      default:
        return PolicyType.classification;
    }
  }
}

/// Rule within a policy.
class PolicyRule {
  /// Unique rule identifier.
  final String ruleId;

  /// Condition expression or DSL.
  final String condition;

  /// Action to execute when condition is met.
  final String action;

  /// Rule priority (lower = higher priority).
  final int priority;

  /// Additional parameters.
  final Map<String, dynamic>? params;

  const PolicyRule({
    required this.ruleId,
    required this.condition,
    required this.action,
    this.priority = 0,
    this.params,
  });

  /// Create from JSON.
  factory PolicyRule.fromJson(Map<String, dynamic> json) {
    return PolicyRule(
      ruleId: json['ruleId'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      action: json['action'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'condition': condition,
      'action': action,
      'priority': priority,
      if (params != null) 'params': params,
    };
  }

  /// Create a copy with modifications.
  PolicyRule copyWith({
    String? ruleId,
    String? condition,
    String? action,
    int? priority,
    Map<String, dynamic>? params,
  }) {
    return PolicyRule(
      ruleId: ruleId ?? this.ruleId,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      params: params ?? this.params,
    );
  }
}

/// FactPolicy defines rules for classification, evaluation, and settlement.
class FactPolicy {
  /// Unique policy identifier.
  final String policyId;

  /// Semantic version.
  final String version;

  /// Policy type.
  final PolicyType type;

  /// Applicable scope.
  final String scope;

  /// Policy rules.
  final List<PolicyRule> rules;

  /// When the policy becomes effective.
  final DateTime effectiveFrom;

  /// When the policy stops being effective (null = current).
  final DateTime? effectiveTo;

  /// Human-readable description.
  final String? description;

  /// When the policy was created.
  final DateTime createdAt;

  /// Workspace ID.
  final String? workspaceId;

  const FactPolicy({
    required this.policyId,
    required this.version,
    required this.type,
    required this.scope,
    this.rules = const [],
    required this.effectiveFrom,
    this.effectiveTo,
    this.description,
    required this.createdAt,
    this.workspaceId,
  });

  /// Create from JSON.
  factory FactPolicy.fromJson(Map<String, dynamic> json) {
    return FactPolicy(
      policyId: json['policyId'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      type: PolicyType.fromString(json['type'] as String? ?? 'classification'),
      scope: json['scope'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => PolicyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      effectiveFrom: json['effectiveFrom'] != null
          ? DateTime.parse(json['effectiveFrom'] as String)
          : DateTime.now(),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      workspaceId: json['workspaceId'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'policyId': policyId,
      'version': version,
      'type': type.name,
      'scope': scope,
      if (rules.isNotEmpty) 'rules': rules.map((r) => r.toJson()).toList(),
      'effectiveFrom': effectiveFrom.toIso8601String(),
      if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
      if (description != null) 'description': description,
      'createdAt': createdAt.toIso8601String(),
      if (workspaceId != null) 'workspaceId': workspaceId,
    };
  }

  /// Create a copy with modifications.
  FactPolicy copyWith({
    String? policyId,
    String? version,
    PolicyType? type,
    String? scope,
    List<PolicyRule>? rules,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? description,
    DateTime? createdAt,
    String? workspaceId,
  }) {
    return FactPolicy(
      policyId: policyId ?? this.policyId,
      version: version ?? this.version,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      rules: rules ?? this.rules,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }

  /// Check if the policy is currently effective.
  bool get isCurrentlyEffective {
    final now = DateTime.now();
    if (now.isBefore(effectiveFrom)) return false;
    if (effectiveTo != null && now.isAfter(effectiveTo!)) return false;
    return true;
  }

  /// Get rules sorted by priority.
  List<PolicyRule> get sortedRules {
    final sorted = List<PolicyRule>.from(rules);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
  }
}
