# J-Space

## Definition

J-Space is the typed search/evaluation space over possible World transitions.

It is not Cortex, not WorldStore, not a generic graph database, and not necessarily token-level tree search.

```rust
pub struct JNode {
    pub id: JNodeId,
    pub parent: Option<JNodeId>,
    pub world: WorldId,
    pub sequence: SequenceId,
    pub memory_view: MemoryViewId,
    pub proposal: ProposalRef,
    pub score: ScoreVector,
    pub evidence_root: Digest32,
    pub status: JNodeStatus,
}
```

## Why

Agents often face multiple plausible approaches. AIEN should be able to:

- fork state cheaply,
- execute reversible work,
- compare evidence,
- prune dominated candidates,
- choose a winner,
- commit only the winner's external effects.

## Effect rule

```text
Pure/read-only/local reversible:
  may run speculatively

World mutation:
  only inside draft World

External write/irreversible:
  stage EffectIntent only
  execute after winner + AEGIS
```

## Multi-objective scoring

Keep dimensions separate:

```text
task quality
verifier confidence
safety margin
latency
compute
memory
uncertainty
```

Use Pareto filtering before expensive judging.

## Distributed execution

J-Space is the preferred first use of the Fabric because entire branches tolerate normal network latency much better than per-layer model sharding.
