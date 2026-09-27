# DOCTRINE-FORGE: Machine Realization

**Status:** AUTHORITATIVE / CANONICAL  
**Effective:** 2026-09-27  
**Decision:** ADR 0014

FORGE is the physical realization and machine-lowering subsystem.

```text
OMEGA
  defines semantic meaning and constraints
        ↓
FORGE
  discovers/constructs a machine realization
        ↓
AEGIS
  verifies realization contracts and invariants
        ↓
HARDWARE
  acts
        ↓
EVIDENCE
```

The relationship is bidirectional. If a requested realization conflicts with alignment, placement, capacity, queue, register, coherence, timing, or other machine constraints, FORGE returns machine facts and alternatives to OMEGA rather than silently changing semantic meaning.

FORGE is not the kernel and is not the policy authority. AIENOS owns the trusted operating substrate. AEGIS verifies invariant/capability contracts. AIEN chooses goals and proposes strategies. OMEGA defines semantics.

Historical PHYSICS milestone identifiers and evidence remain valid historical names and are not renamed.
