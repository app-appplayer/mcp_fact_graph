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
