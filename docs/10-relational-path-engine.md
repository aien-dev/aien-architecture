# Relational Path Engine

## Research basis

PEARL (September 2026) makes relational paths first-class graph objects, contextualizes them against entity and global subgraph state, then scores paths relative to the query relation.

AIEN should adopt the **idea**, not the Python/PyTorch/DGL implementation.

The PEARL reference repository did not expose a root license file at the time of review, so do not copy source code unless licensing is clarified.

## AIEN opportunity

Build:

```text
aien-relation-graph
aien-path-ranker
```

Use one path substrate across:

- Cortex evidence reasoning,
- Capability Graph routing,
- J-Space plan comparison.

## Path object

```rust
pub struct RelationalPath {
    pub id: PathId,
    pub start: NodeId,
    pub end: NodeId,
    pub nodes: SmallVec<[NodeId; 7]>,
    pub edges: SmallVec<[EdgeId; 6]>,
    pub digest: Digest32,
}
```

## Cortex use

Infer candidate relationships from:

```text
entity
 -> claim
 -> entity
 -> evidence
 -> entity
```

Predictions become `MemoryCandidate`s, never immediate facts.

## Capability use

Score complete execution paths:

```text
intent
 -> skill
 -> tools
 -> credential
 -> Machine
 -> policy
 -> effect class
```

This is more useful than scoring each skill independently.

## J-Space use

Make the trajectory that produced a candidate first-class:

```text
World A:
  inspect -> patch -> test -> verify

World B:
  search -> alternate patch -> test -> verify
```

Store observed operations and evidence, not hidden chain-of-thought.

## Adaptive exploration

Combine PEARL-style contextual path scoring with a MOSAIC-like query-dependent exploration budget.

Do not hard-code the same hop count and path count for every query.

## Performance plan

Start in Rust:

- CSR graph,
- compact integer IDs,
- bounded bidirectional BFS,
- `SmallVec`,
- arenas/slabs,
- Rayon for independent queries.

Only move scoring kernels to Mojo if profiling shows a real bottleneck.

## First experiment

Compare baseline routing/retrieval with path-context routing on:

- top-1 skill accuracy,
- top-5 skill accuracy,
- invalid capability rate,
- unavailable Machine selections,
- Cortex evidence recovery,
- J-Space time-to-valid-answer,
- routing latency,
- token cost.

Stop if it does not produce clear value.
