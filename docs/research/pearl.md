# Research Note: PEARL and AIEN

## Paper

**PEARL: Path-Entity Aligned Relational Learning with Contextual Subgraphs for Inductive Knowledge Graph Completion** (September 2026).

## Mechanism worth studying

- query-specific contextual subgraph,
- candidate multi-hop paths,
- paths become graph nodes,
- path ↔ entity interaction,
- path ↔ global context interaction,
- relation-conditioned path attention,
- contrastive robustness against irrelevant context.

## Why it maps to AIEN

AIEN already has graph-shaped data:

- Cortex entities/claims/evidence,
- Capability Graph,
- World lineage,
- J-Space candidates.

## What not to copy

The released reference uses Python/PyTorch/DGL and includes provider-specific LLM path-ranking code. AIEN should independently implement the concept in Rust and use AIEN's own model router.

## Safety boundary

Relational inference may suggest that a relationship exists. It must never grant actual runtime authority.

Examples:

```text
predicted "Machine can run Tool" != Fabric advertisement
predicted "credential available" != Vault resolver
predicted "allowed" != AEGIS authorization
```

Predictions rank hypotheses. Authoritative systems decide facts.

## Experiment before adoption

A/B:

- Cortex candidate recovery,
- Skill routing accuracy,
- invalid tool rate,
- unavailable Machine selections,
- J-Space time-to-valid result,
- path scoring latency,
- token cost,
- robustness to irrelevant context.
