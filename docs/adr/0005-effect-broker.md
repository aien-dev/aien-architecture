# ADR 0005: Irreversible Effects Execution Adapter and Contract Verification

**Status:** Accepted (Reconciled with ADR 0013)

## Context

Speculative branches and model-driven tools must not directly mutate external reality or physical hardware without verified contracts.

## Decision

The execution flow for irreversible external and physical effects is:

1. AIEN proposes an effect.
2. OMEGA formalizes an Effect Program with semantic bounds and invariants.
3. PHYSICS lowers that effect program into concrete device, storage, network, or memory operations.
4. AEGIS verifies the effect contract and resulting physical realization against capability constraints.
5. The protocol-specific Effect Broker acts only as a small execution adapter for external protocol drivers.
6. HARDWARE or external systems perform the verified effect.
7. AEGIS verifies observable postconditions where verifiable.
8. EVIDENCE records the immutable execution receipt.

AEGIS does not make arbitrary authorization decisions or censor intent. Capabilities are machine-verifiable execution constraints:

```text
CapabilityContract {
    principal
    resource
    permitted_operations
    bounds
    generation
    lifetime
    revocation_state
    provenance
}
```

AEGIS checks capability contracts and invariants. PHYSICS realizes operations within those verified bounds.

## Consequences

J-Space can speculate safely. External actions flow through formal lowering, continuous invariant verification, and an auditable execution adapter boundary with cryptographic provenance.
