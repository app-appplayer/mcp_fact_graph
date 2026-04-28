/// ContextBundlePortAdapter - Implements mcp_bundle's capability
/// `ContextBundlePort`.
///
/// MOD-INFRA-019. Translates `bundle.ContextBundleRequest` into a
/// [ContextService.buildContext] call and converts the resulting
/// internal `InternalContextBundle` into `bundle.ContextBundle`.
library;

import 'package:mcp_bundle/mcp_bundle.dart' as bundle;
// The mcp_bundle barrel hides `ContextBundleRequest` and `ContextBudget`
// (the legacy SkillFactGraph variants take precedence). Import the
// capability port file directly so we see the new shapes.
import 'package:mcp_bundle/src/ports/context_bundle_port.dart'
    as ctx_port;

import '../../domain/entities/context_bundle.dart';
import '../../domain/entities/fact.dart';
import '../../services/context_service.dart';

/// Implements `bundle.ContextBundlePort` on top of `ContextService`.
class ContextBundlePortAdapter implements bundle.ContextBundlePort {
  final ContextService _contextService;
  final String _defaultWorkspaceId;

  ContextBundlePortAdapter({
    required ContextService contextService,
    String defaultWorkspaceId = 'default',
  })  : _contextService = contextService,
        _defaultWorkspaceId = defaultWorkspaceId;

  @override
  Future<bundle.ContextBundle> buildContextBundle(
    ctx_port.ContextBundleRequest request,
  ) async {
    final tokenBudget = request.budget?.maxTokens ?? 4096;
    final workspaceId = request.workspaceId.isEmpty
        ? _defaultWorkspaceId
        : request.workspaceId;

    InternalContextBundle internal;
    try {
      internal = await _contextService.buildContext(
        workspaceId: workspaceId,
        query: request.query,
        tokenBudget: tokenBudget,
      );
    } catch (_) {
      // Graceful fallback: empty bundle on any internal build failure.
      internal = InternalContextBundle(
        bundleId: 'ctx-empty-${DateTime.now().microsecondsSinceEpoch}',
        workspaceId: workspaceId,
        query: request.query,
        asOf: request.asOf ?? DateTime.now(),
        policyVersion: request.policyVersion ?? '1.0.0',
        createdAt: DateTime.now(),
      );
    }

    return bundle.ContextBundle(
      id: internal.bundleId,
      events: internal.facts.map(_factToEvent).toList(),
      views: internal.summaries
          .map(
            (s) => bundle.ContextView(
              id: s.summaryId,
              type: s.scope.scopeType,
              content: s.summaryText,
              asOf: s.asOf,
            ),
          )
          .toList(),
      createdAt: request.asOf ?? internal.createdAt,
      estimatedTokens: internal.tokenEstimate,
    );
  }

  bundle.ContextEvent _factToEvent(Fact fact) {
    return bundle.ContextEvent(
      id: fact.factId,
      type: fact.factType,
      timestamp: fact.occurredAt,
      data: Map<String, dynamic>.from(fact.payload),
    );
  }
}
