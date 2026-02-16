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

  /// View type/name.
  final String viewType;

  /// View title.
  final String title;

  /// View period.
  final ViewPeriod period;

  /// View scope (e.g., category, project, entity).
  final String? scope;

  /// Computed data.
  final Map<String, dynamic> data;

  /// Source event IDs used in computation.
  final List<String> sourceEventIds;

  /// Policy version used for computation.
  final String policyVersion;

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
    required this.viewType,
    required this.title,
    required this.period,
    this.scope,
    this.data = const {},
    this.sourceEventIds = const [],
    required this.policyVersion,
    required this.computedAt,
    required this.asOf,
    this.status = ViewStatus.current,
    this.computationMeta,
    this.metadata = const {},
  });

  factory View.fromJson(Map<String, dynamic> json) {
    return View(
      viewId: json['viewId'] as String? ?? '',
      viewType: json['viewType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      period: ViewPeriod.fromJson(json['period'] as Map<String, dynamic>? ?? {}),
      scope: json['scope'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      sourceEventIds: (json['sourceEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      policyVersion: json['policyVersion'] as String? ?? '',
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
      'viewType': viewType,
      'title': title,
      'period': period.toJson(),
      if (scope != null) 'scope': scope,
      if (data.isNotEmpty) 'data': data,
      if (sourceEventIds.isNotEmpty) 'sourceEventIds': sourceEventIds,
      'policyVersion': policyVersion,
      'computedAt': computedAt.toIso8601String(),
      'asOf': asOf.toIso8601String(),
      'status': status.name,
      if (computationMeta != null) 'computationMeta': computationMeta!.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  View copyWith({
    String? viewId,
    String? viewType,
    String? title,
    ViewPeriod? period,
    String? scope,
    Map<String, dynamic>? data,
    List<String>? sourceEventIds,
    String? policyVersion,
    DateTime? computedAt,
    DateTime? asOf,
    ViewStatus? status,
    ComputationMeta? computationMeta,
    Map<String, dynamic>? metadata,
  }) {
    return View(
      viewId: viewId ?? this.viewId,
      viewType: viewType ?? this.viewType,
      title: title ?? this.title,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      data: data ?? this.data,
      sourceEventIds: sourceEventIds ?? this.sourceEventIds,
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

/// View period.
class ViewPeriod {
  /// Period start.
  final DateTime start;

  /// Period end.
  final DateTime end;

  /// Period type.
  final PeriodType type;

  const ViewPeriod({
    required this.start,
    required this.end,
    this.type = PeriodType.custom,
  });

  factory ViewPeriod.fromJson(Map<String, dynamic> json) {
    return ViewPeriod(
      start: json['start'] != null
          ? DateTime.parse(json['start'] as String)
          : DateTime.now(),
      end: json['end'] != null
          ? DateTime.parse(json['end'] as String)
          : DateTime.now(),
      type: PeriodType.fromString(json['type'] as String? ?? 'custom'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'type': type.name,
    };
  }

  /// Duration of the period.
  Duration get duration => end.difference(start);
}

/// Period types.
enum PeriodType {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom;

  static PeriodType fromString(String value) {
    return PeriodType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PeriodType.custom,
    );
  }
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
