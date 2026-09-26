# Specification: Milestone 8 — Omega Program Core (`OMEGA_PROGRAM_CORE`)

```text
Document ID:     SPEC-OMEGA-M8
Milestone:       Milestone 8 (OMEGA_PROGRAM_CORE)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Explicit Program Objects, Contracts, Cost Accounting, and Composition
Status:          SPECIFIED / IN PROGRESS (aien-dev/aien-architecture#20)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4-M8) -> AIEN
```

---

## 1. Executive Summary & Core Invariants

Milestone 7 established the trusted verification engine (`OMEGA_VERIFY`).
Milestone 8 formalizes programs from isolated semantic graph operations into first-class sovereign objects:

> **A PROGRAM IS NOT MERELY A SEQUENCE OF INSTRUCTIONS; IT IS A BOUNDED SEMANTIC CONTRACT WITH DECLARED TYPES, COSTS, COMPOSITION LAWS, AND EVIDENCE OF VERIFICATION.**

The `OMEGA_PROGRAM` substrate establishes:
1. **Explicit Program Objects**: Typed boundaries separating inputs, outputs, preconditions, postconditions, and resource costs.
2. **Deterministic Composition**: Algebraic composition $C = A \circ B$ where $C(x) = B(A(x))$ with automated intermediate type unification.
3. **Additive Cost Accounting**: Formally modeled costs (instruction count, register pressure, memory overhead) that compose strictly and monotonically.
4. **Verification-Coupled Realization**: Programs compile to native AArch64 machine code and must pass the M7 verification ladder ($V_0, V_1, V_2$).

---

## 2. Program Data Model & Interface

```c
typedef struct {
    uint32_t insn_count;
    uint32_t reg_pressure;
    uint32_t memory_bytes;
    uint32_t latency_cycles;
} OmegaCost;

typedef struct {
    TypeTag input_type;
    uint16_t input_width;
    TypeTag output_type;
    uint16_t output_width;
    char precondition[64];
    char postcondition[64];
} OmegaContract;

typedef struct {
    SemanticId program_id;
    char name[64];
    OmegaContract contract;
    OmegaCost cost;
    OmegaGraph *graph;
    RealizationObject realization;
    bool is_realized;
    bool is_verified;
} OmegaProgram;

typedef struct {
    SemanticId task_id;
    char description[128];
    OmegaContract target_contract;
    OmegaCost cost_budget;
    size_t example_count;
    uint64_t inputs[16];
    uint64_t expected_outputs[16];
} SynthesisTask;
```

### Composition Invariant:
Given $A: X \to Y$ and $B: Y \to Z$:
- Requires: $\text{Type}(A_{\text{out}}) == \text{Type}(B_{\text{in}})$
- Derived Contract: $C: X \to Z$, with $\text{Pre}(C) = \text{Pre}(A)$, $\text{Post}(C) = \text{Post}(B) \circ \text{Post}(A)$
- Derived Cost: $\text{Cost}(C) = \text{Cost}(A) + \text{Cost}(B)$

---

## 3. Qualification Gates for M8

1. `OMEGA_PROGRAM_OBJECT_PASS`: `OMEGA_PROGRAM` instantiated with explicit contracts and cost models.
2. `OMEGA_PROGRAM_CONTRACT_VALIDATION_PASS`: Type checking enforces input/output contract validity.
3. `OMEGA_PROGRAM_COMPOSITION_PASS`: Programs $A$ and $B$ composed into $C = A \circ B$ with intermediate type unification.
4. `OMEGA_PROGRAM_TYPE_MISMATCH_REFUSAL_PASS`: Incompatible composition ($A_{\text{out}} \ne B_{\text{in}}$) refused fail-closed.
5. `OMEGA_PROGRAM_COST_ACCOUNTING_PASS`: Composite cost $\text{Cost}(C) = \text{Cost}(A) + \text{Cost}(B)$ strictly verified.
6. `OMEGA_PROGRAM_REALIZATION_PASS`: Composite program lowered to native AArch64 machine instructions.
7. `OMEGA_PROGRAM_V0_STRUCTURAL_PASS`: Composite program passes M7 V0 structural verification.
8. `OMEGA_PROGRAM_V1_DIFFERENTIAL_PASS`: Composite program passes M7 V1 differential evaluation vs native execution.
9. `OMEGA_PROGRAM_V2_PROPERTY_PASS`: Composite program passes M7 V2 property/invariant verification.
10. `OMEGA_PROGRAM_SYNTHESIS_TASK_PASS`: `SYNTHESIS_TASK` schema verified with input-output test harness ready for M9 search.
