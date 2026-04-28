# MCP Fact Graph

> **Positioning:** `mcp_fact_graph` is an internal component of the MakeMind knowledge stack exposed through the `mcp_knowledge` facade. Application code should import `package:mcp_knowledge/mcp_knowledge.dart` — the symbols declared here are re-exported from there. Direct `package:mcp_fact_graph/` imports remain valid for advanced or integration scenarios but are discouraged in product code.

A temporal knowledge graph for evidence-based fact management with candidates, summaries, and skill-execution claims. The persistence and query backbone of the MakeMind knowledge stack.

## Architecture

A 4-layer model:

- **L0 Evidence** — raw fragments and evidence ingested from sources.
- **L1 FactGraph** — entities, candidates, facts, relations, fact clusters, classifications, fact policies, automations, runs, artifacts.
- **L2 ContextOps** — context bundles, summaries, claims, response validation.
- **L3 SkillOps** — patterns, skills, rubrics, evaluation runs.

Cross-cutting domain entities reduce LLM calls (extraction rules / validators, classifier memory, disambiguation decisions, LLM call log, idempotency records).

## Contract Layer

Implements `mcp_bundle` standard ports through capability-named adapters under `src/adapters/`. Persistence is unified via `UnifiedStoragePort`. Hosts wire the adapters they need; the legacy per-domain ports are gone.

## Quick Start

```dart
import 'package:mcp_fact_graph/mcp_fact_graph.dart';

final graph = FactGraphRuntime(
  storage: InMemoryUnifiedStorage(),
);

await graph.ingestEvidence(myEvidence);
final candidates = await graph.candidatesFor(entityId);
final bundle = await graph.contextBundleFor(entityId);
```

## Support

- [Issue Tracker](https://github.com/app-appplayer/mcp_fact_graph/issues)
- [Discussions](https://github.com/app-appplayer/mcp_fact_graph/discussions)

## License

MIT — see [LICENSE](LICENSE).
