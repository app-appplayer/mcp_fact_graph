/// View entity for L1 FactGraph Layer.
///
/// Represents aggregated/materialized views computed from events.
library;

/// View represents an aggregated computation over events/facts.
///
/// Views provide calculated results like summaries, totals, status reports.
class View {
  /// Unique view identifier.
  final String viewId;

  /// Workspace identifier for multi-tenant isolation.
  final String workspaceId;

  /// View type/name.
  final String viewType;

  /// View title.
  final String title;

  /// View period.
  /// Reference: Design Section 2.9 - Period from mcp_bundle.
  final ViewPeriod period;

  /// View scope (e.g., category, project, entity).
  /// Required per design §2.9.
  final String scope;

  /// Grouping dimensions.
  /// Reference: Design Section 2.9 - dimensions.
  final Map<String, dynamic> dimensions;

  /// Calculated metrics.
  /// Reference: Design Section 2.9 - metrics.
  final Map<String, dynamic> metrics;

  /// Source event/fact IDs used in computation.
  /// Reference: Design Section 2.9 - sourceRefs.
  final List<String> sourceRefs;

  /// Policy version used for computation (optional per design §2.9).
  final String? policyVersion;

  /// When this view was computed.
  final DateTime computedAt;

  /// As-of timestamp for the computation.
  final DateTime asOf;

  /// View status.
  final ViewStatus status;

  /// Computation metadata.
  final ComputationMeta? computationMeta;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const View({
    required this.viewId,
    required this.workspaceId,
    required this.viewType,
    required this.title,
    required this.period,
    required this.scope,
    this.dimensions = const {},
    this.metrics = const {},
    this.sourceRefs = const [],
    this.policyVersion,
    required this.computedAt,
    required this.asOf,
    this.status = ViewStatus.current,
    this.computationMeta,
    this.metadata = const {},
  });

  factory View.fromJson(Map<String, dynamic> json) {
    return View(
      viewId: json['viewId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      viewType: json['viewType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      period: ViewPeriod.fromJson(json['period'] as Map<String, dynamic>? ?? {}),
      scope: json['scope'] as String? ?? '',
      dimensions: json['dimensions'] as Map<String, dynamic>? ?? {},
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      sourceRefs: (json['sourceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      policyVersion: json['policyVersion'] as String?,
      computedAt: json['computedAt'] != null
          ? DateTime.parse(json['computedAt'] as String)
          : DateTime.now(),
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
      status: ViewStatus.fromString(json['status'] as String? ?? 'current'),
      computationMeta: json['computationMeta'] != null
          ? ComputationMeta.fromJson(
              json['computationMeta'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewId': viewId,
      'workspaceId': workspaceId,
      'viewType': viewType,
      'title': title,
      'period': period.toJson(),
      'scope': scope,
      if (dimensions.isNotEmpty) 'dimensions': dimensions,
      if (metrics.isNotEmpty) 'metrics': metrics,
      if (sourceRefs.isNotEmpty) 'sourceRefs': sourceRefs,
      if (policyVersion != null) 'policyVersion': policyVersion,
      'computedAt': computedAt.toIso8601String(),
      'asOf': asOf.toIso8601String(),
      'status': status.name,
      if (computationMeta != null) 'computationMeta': computationMeta!.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  View copyWith({
    String? viewId,
    String? workspaceId,
    String? viewType,
    String? title,
    ViewPeriod? period,
    String? scope,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? metrics,
    List<String>? sourceRefs,
    String? policyVersion,
    DateTime? computedAt,
    DateTime? asOf,
    ViewStatus? status,
    ComputationMeta? computationMeta,
    Map<String, dynamic>? metadata,
  }) {
    return View(
      viewId: viewId ?? this.viewId,
      workspaceId: workspaceId ?? this.workspaceId,
      viewType: viewType ?? this.viewType,
      title: title ?? this.title,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      dimensions: dimensions ?? this.dimensions,
      metrics: metrics ?? this.metrics,
      sourceRefs: sourceRefs ?? this.sourceRefs,
      policyVersion: policyVersion ?? this.policyVersion,
      computedAt: computedAt ?? this.computedAt,
      asOf: asOf ?? this.asOf,
      status: status ?? this.status,
      computationMeta: computationMeta ?? this.computationMeta,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'View($viewId, type: $viewType, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is View && viewId == other.viewId;

  @override
  int get hashCode => viewId.hashCode;
}

/// View status.
enum ViewStatus {
  /// Current/valid view.
  current,

  /// Stale (needs refresh).
  stale,

  /// Computing.
  computing,

  /// Archived.
  archived;

  static ViewStatus fromString(String value) {
    return ViewStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ViewStatus.current,
    );
  }
}

/// View period (simplified, aligned with Period from mcp_bundle).
class ViewPeriod {
  /// Period start.
  final DateTime start;

  /// Period end.
  final DateTime end;

  const ViewPeriod({
    required this.start,
    required this.end,
  });

  factory ViewPeriod.fromJson(Map<String, dynamic> json) {
    return ViewPeriod(
      start: json['start'] != null
          ? DateTime.parse(json['start'] as String)
          : DateTime.now(),
      end: json['end'] != null
          ? DateTime.parse(json['end'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  /// Duration of the period.
  Duration get duration => end.difference(start);
}

/// Computation metadata.
class ComputationMeta {
  /// Duration of computation in milliseconds.
  final int durationMs;

  /// Number of events processed.
  final int eventsProcessed;

  /// Computation algorithm/version.
  final String algorithm;

  /// Any warnings during computation.
  final List<String> warnings;

  const ComputationMeta({
    required this.durationMs,
    required this.eventsProcessed,
    required this.algorithm,
    this.warnings = const [],
  });

  factory ComputationMeta.fromJson(Map<String, dynamic> json) {
    return ComputationMeta(
      durationMs: json['durationMs'] as int? ?? 0,
      eventsProcessed: json['eventsProcessed'] as int? ?? 0,
      algorithm: json['algorithm'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'durationMs': durationMs,
      'eventsProcessed': eventsProcessed,
      'algorithm': algorithm,
      if (warnings.isNotEmpty) 'warnings': warnings,
    };
  }
}
