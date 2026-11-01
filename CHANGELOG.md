## [0.2.5] - 2026-11-01 - LLM evidence extraction no longer truncates

### Fixed
- `LlmEvidencePort` sent no `maxTokens`, so a provider's default output limit (1024 for some) cut the reply and extraction silently fell back to the rule-based port. It now asks for `maxOutputTokens` (default 8192); a reply cut at the limit (`finishReason` `length` or `max_tokens`) falls back with that reason through `onFallback`. Input longer than `maxChunkChars` (default 3000) is split into pieces, each piece is extracted on its own, and the fragments are merged with offsets in the whole text; one failed piece falls back for the whole input.

### Added
- `LlmEvidencePort` constructor arguments `maxOutputTokens` and `maxChunkChars`.

## [0.2.4] - 2026-10-30 - Attribution, retraction, point-in-time queries, LLM evidence extraction, unique ids

### Added
- `Fact.actor`, `Fact.retractedAt`, `Fact.retractedBy` (optional, omitted from JSON when null) and `Fact.isRetracted`. A retracted fact keeps its evidence and candidate links and its stored `status`; `FactStatus` is unchanged.
- `FactGraphService.retractFact(factId, {retractedBy, at})` withdraws a fact without deleting it; `confirmCandidate(..., {actor})` records who confirmed.
- `FactQuery.asOf` returns the facts as they stood at an instant (created by then, not retracted by then, not superseded by then). Without `asOf`, retracted facts are left out unless `includeRetracted: true`. `InMemoryFactStorage` implements the rule; a storage that subclasses it inherits it.

- `LlmEvidencePort` (`bundle.EvidencePort`): an injected `LlmPort` splits raw text into evidence units with `kind` (`decision|task|question|state|fact|insight`), `verbatim`, `emphasis`, `confidence` and `entityHints`. A `verbatim` claim is kept only when the words are in the source, and the position is taken from the source. When the call fails or the reply is unreadable it falls back to `EvidencePortAdapter` and reports the reason through `onFallback`. Needs the `EvidenceFragment` fields added in `mcp_bundle` 0.4.12.

### Fixed
- Ids made in the same clock tick repeated, so a store replaced the earlier candidate, fact or evidence without an error (a batch of three candidates left two). All services and port adapters now draw ids from one process-wide generator, `<prefix>_<microseconds>_<sequence>`; the `cand_`/`fact_`/`ev_` prefixes are unchanged.
- `FactsPortAdapter.queryFacts` ignored `mcp_bundle`'s `FactQuery.asOf`; it now passes it through.
- `ConsistencyChecker` and `PatternMiner` skip retracted facts like archived ones.

## [0.2.3] - 2026-06-30 - Storage-port injection seam for persistence

### Added
- The `*StoragePort` interfaces are now re-exported from the public barrel (`mcp_fact_graph.dart`). They were the injection seam of the primary `FactGraphRuntime(...)` constructor all along — exporting them lets a host supply persistent (disk-backed) storage implementations instead of the default in-memory stack, without path-importing `src/`.
- The in-memory storage stack (`InMemory*Storage` + `InMemoryStorageContainer`) is re-exported as the subclassing base for out-of-package persistence adapters: a persistent port can `extends InMemory*Storage`, override only the mutating methods to flush to disk, and reuse all query/index logic unchanged.

### Notes
- Backward-compatible, additive only — no behavioral or signature changes to existing types. Consumers on `^0.2.2` resolve `0.2.3` with no constraint changes.
- The five `*Query` value types whose names also exist in `mcp_bundle` (`ClaimQuery`, `EntityQuery`, `FactQuery`, `PatternQuery`, `RunQuery`) are intentionally hidden from the barrel to avoid ambiguous-export errors in consumers that depend on both packages (e.g. `mcp_knowledge`). They remain reachable by path-importing `src/ports/storage_port.dart`.

## [0.2.2] - 2026-05-23 - mcp_bundle 0.4.0 cascade

### Changed (cascade)
- `mcp_bundle` caret bumped from `^0.3.1` to `^0.4.0`. mcp_fact_graph does not touch `UiSection.pages` directly, so this release is a caret-only cascade. Consumers should bump to `^0.2.2`.

## [0.2.1] - 2026-05-04 - Microsecond consistency overlap

### Fixed
- `ConsistencyChecker._periodsOverlap` now flags overlap iff two facts share the same `occurredAt` instant to the microsecond. Previously the helper reduced both timestamps to calendar-day precision, which caused every same-day, same `(entity, factType)` record to be reported as a triple-mismatch conflict regardless of the actual time gap. Point-in-time lifecycle records (e.g., `agent.fork.assigned` mirrors emitted by host runtimes) can now be ingested with `enableConsistencyCheck: true` without spurious conflicts.

### Dependencies
- `mcp_bundle: ^0.3.1` — additive; no behavioral change for existing call sites.

---

## [0.2.0] - 2026-04-28 - Standard Ports & Domain Expansion

### Added
- Standard port adapters under `src/adapters/` implementing `mcp_bundle` Contract Layer (capability-named ports).
- `UnifiedStoragePort` consolidating per-domain storage.
- L1 FactGraph domain entities — artifact, automation, classification, fact_cluster, fact_policy, relation, run, skill_run.
- LLM-call-reduction domain entities — extraction rules / validators, classifier memory, disambiguation decisions, LLM call log, idempotency records.
- Claim signal entity bridging L2 ContextOps and L3 SkillOps.
- Response validation entity.

### Changed
- Domain entities reorganized into the 4-layer (L0 Evidence, L1 FactGraph, L2 ContextOps, L3 SkillOps) architecture.
- New dependency: `mcp_bundle ^0.3.0`.

### Removed
- Legacy per-domain `EvidencePort` and `event` entity — replaced by Contract Layer ports and `UnifiedStoragePort`.

---

## [0.1.1] - Dependency Update

### Changed
- Updated `mcp_bundle` dependency to ^0.2.1 for Contract Layer compatibility

---

## [0.1.0] - Initial Release

### Added

#### Core Features
- **Temporal Knowledge Graph**
  - `Fact` model with domain, category, value, and temporal scope
  - `Evidence` model for source data with confidence scores
  - `Candidate` model for pending facts awaiting confirmation
  - `Claim` model for skill execution assertions

- **Fact Graph Service**
  - `FactGraphService` as the main entry point
  - Evidence ingestion and processing
  - Candidate creation and confirmation workflow
  - Fact querying with domain, entity, and temporal filters

- **Context Bundles**
  - `ContextBundle` for complete entity context retrieval
  - Facts, summaries, and recent claims aggregation
  - Optimized for LLM consumption

- **Port-Based Architecture**
  - `FactStoragePort` for fact persistence
  - `EvidenceStoragePort` for evidence storage
  - `CandidateStoragePort` for candidate management
  - `EntityStoragePort` for entity data
  - `EventStoragePort` for event sourcing
  - `ViewStoragePort` for materialized views

- **In-Memory Implementations**
  - Complete in-memory storage implementations for testing
  - Thread-safe operations with proper isolation

### Storage Ports
- `FactStoragePort` - CRUD operations for facts
- `EvidenceStoragePort` - Evidence management
- `CandidateStoragePort` - Candidate lifecycle
- `EntityStoragePort` - Entity metadata
- `EventStoragePort` - Event sourcing support
- `ViewStoragePort` - Materialized views

### Data Models
- `Fact` - Confirmed knowledge with temporal validity
- `Evidence` - Source data with metadata
- `Candidate` - Pending facts with confidence
- `Claim` - Skill execution assertions
- `Entity` - Entity metadata and summaries
- `ContextBundle` - Aggregated entity context

---

## Support and Contributing

- [Report Issues](https://github.com/app-appplayer/mcp_fact_graph/issues)
- [Join Discussions](https://github.com/app-appplayer/mcp_fact_graph/discussions)
- [Read Documentation](https://github.com/app-appplayer/mcp_fact_graph/wiki)
- [Support Development](https://www.patreon.com/mcpdevstudio)
