# ADR 0013: Machine Physics Lowering and AEGIS Invariant Verification Chain

**Status:** Accepted

## Context

Previous doctrine documents described PHYSICS as a gatekeeper membrane between OMEGA and physical execution, while conflating machine authority with security gating. This created ambiguity between:
1. Machine-level execution authority (lowering formal semantic programs into physical machine states).
2. Continuous verification of invariants, capabilities, and contracts across the transformation chain.
3. The separate scientific physics discovery program (Physics Zero).

Treating the machine authority layer as a binary allow or deny gatekeeper fails to capture the bidirectional dialogue required when compiling formal programs to physical silicon realities.

## Decision

1. **Layer Responsibilities:**
   - **ATLAS**: The irreducible bootstrap seed that establishes the first trusted machine state from cold silicon.
   - **AIEN**: The cognitive driver that thinks, reasons across possibility spaces, and proposes intents, hypotheses, and architectural mutations.
   - **OMEGA**: The semantic calculus that defines meaning, graphs, constraints, and formal transformation programs.
   - **PHYSICS (Machine Physics / Physical Realizer)**: The physical compiler and realizer. Understands hardware mechanics (memory layouts, page tables, cache hierarchies, register pressure, DMA descriptors, GPFIFO queues, device registers, and bus topologies). Lowers abstract OMEGA programs into physical machine operations.
   - **AEGIS (Invariant Checker & Verifier)**: A continuous verifier spanning the entire pipeline (AIEN -> OMEGA -> PHYSICS -> HARDWARE). Verifies constraints, bounds, slot generations, types, rollback safety, provenance, and post-execution state contracts.
   - **HARDWARE**: Physical silicon (CPU, GPU, memory, peripherals) performing state transitions.
   - **EVIDENCE**: Immutable record of verified receipts and execution results.

2. **Core Doctrine:**
   > **AIEN PROPOSES. OMEGA DEFINES. PHYSICS REALIZES. AEGIS VERIFIES. HARDWARE ACTS. EVIDENCE TEACHES.**

3. **Bidirectional Compilation Dialogue:**
   The relationship between OMEGA and PHYSICS is an iterative lowering dialogue rather than a one-way command dispatch. When PHYSICS encounters physical constraints (such as alignment mismatches, fragmentation, pinning, or coherence limits), it emits alternative realizations and machine facts back to OMEGA. OMEGA and AIEN select trade-offs, OMEGA formalizes the revised program, AEGIS verifies invariants, and PHYSICS executes.

4. **AEGIS Non-Interference:**
   AEGIS does not censor, filter, or decide what AIEN is allowed to think or propose. AEGIS verifies that a proposed physical realization faithfully implements the requested meaning, preserves system invariants, and possesses valid recovery paths.

5. **Nomenclature Preservation:**
   - `PHYSICS` (Machine Physics / Physics Runtime) retains its name as the physical lowering and realization compiler.
   - `Physics Zero` retains its name as the scientific discovery engine investigating the natural world.

## Consequences

- The execution pipeline mirrors a high-performance compiler with an intelligent physical backend and continuous formal verifier.
- OMEGA remains hardware-neutral; PHYSICS encapsulates silicon-specific realities (Blackwell, AArch64, SMMUv3, NVLink-C2C).
- Historical milestones (M2, M3, M15, M16, M17, M18, M19) remain structurally valid without semantic churn.
