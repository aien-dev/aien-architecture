# Specification: Milestone 7 — Omega Trusted Verification Engine (`OMEGA_VERIFY`)

```text
Document ID:     SPEC-OMEGA-M7
Milestone:       Milestone 7 (OMEGA_VERIFY)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Multi-Tier Trusted Verification Ladder (V0, V1, V2)
Status:          SPECIFIED / IN PROGRESS (aien-dev/aien-architecture#19)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4/M5/M6/M7) -> AIEN
```

---

## 1. Executive Summary & Foundational Invariants

Milestone 6 established the closed-loop reproduction of the realization compiler (`OMEGA_SELF_HOST`).
Milestone 7 establishes the **sovereign verification authority** of OMEGA:

> **AIEN MAY PROPOSE. OMEGA MUST VERIFY. PHYSICS MUST AUTHORIZE. EVIDENCE DECIDES WHAT SURVIVES.**

OMEGA requires a trusted, deterministic verification engine to gate candidate programs, realization binaries, and transformations before increasingly complex generated code is admitted into the ecosystem.

The fundamental trust asymmetry is inviolable:

```text
GENERATOR = UNTRUSTED (Search, AIEN, Heuristics, Lowering)
VERIFIER  = TRUSTED (OMEGA Formal Ladder: V0, V1, V2)
```

No code, program, or transformation survives without passing the required verification tier.

---

## 2. The Verification Ladder

The OMEGA verification engine implements a hierarchical ladder of increasing epistemic rigor:

```text
V5 — PROOF-CARRYING (Machine-checked proofs) [Future]
V4 — SYMBOLIC / FORMAL (SMT, Equivalence proofs) [Future]
V3 — ADVERSARIAL (Fuzzing, Fault injection, Boundary sweeps) [Future]
V2 — PROPERTY / INVARIANT (Algebraic laws, Bounds, Contracts) [M7 MANDATORY]
V1 — DIFFERENTIAL (Reference Semantic Eval vs Native Realization) [M7 MANDATORY]
V0 — STRUCTURAL (Types, DAG validity, Memory bounds, Opcode decoding) [M7 MANDATORY]
```

### V0: Structural Verification
Guarantees physical and syntactic safety before execution:
1. **Semantic Type Safety**: Operand types, bit-widths, and arities match operation specifications.
2. **DAG Integrity**: Semantic graph contains no cycles and no dangling object references.
3. **Target Profile Compliance**: Realization targets valid, admitted profile (`AARCH64_PROFILE_V8A_BAREMETAL`).
4. **Code Buffer Bounds**: $4 \le \text{code\_len} \le 4096$, strictly divisible by 4 bytes.
5. **Instruction Validity**: Every machine word decodes to a valid, permitted AArch64 instruction via the independent bitmask decoder (`aarch64_decoder`).
6. **Bounded Control Flow**: Function terminates strictly with `RET`; branches do not escape code bounds.

### V1: Differential Verification
Verifies semantic preservation between abstract evaluation and physical execution:
1. Drives an exhaustive or bounded test corpus $I = \{x_1, x_2, \dots, x_N\}$ across:
   $$\text{Eval}_{\text{semantic}}(G, x_i) \quad \text{vs} \quad \text{Exec}_{\text{native}}(R, x_i)$$
2. Requires bit-for-bit identity across all test vectors:
   $$\forall x_i \in I, \quad \text{Eval}(G, x_i) == \text{Exec}(R, x_i)$$
3. Refuses realization immediately upon any observed divergence.

### V2: Property and Invariant Verification
Validates that computation obeys declared semantic contracts and mathematical laws:
1. **Algebraic Laws**:
   - Commutativity: $\forall a, b: op(a, b) == op(b, a)$ (e.g. `OP_ADD`, `OP_MUL`, `OP_AND`, `OP_OR`).
   - Identity Elements: $\forall a: op(a, e) == a$ (e.g. $a + 0 = a$, $a \times 1 = a$, $a \land \text{0xFF...} = a$).
   - Associativity: $\forall a, b, c: op(op(a, b), c) == op(a, op(b, c))$.
2. **Range and Bounds Safety**: Output values strictly reside within declared domain ranges $[V_{\min}, V_{\max}]$.
3. **Declared Overflow Policies**: Verifies wrapping on 64-bit boundary when `OVERFLOW_WRAP` is declared.
4. **Pre/Postconditions**: Explicit predicate constraints attached to semantic operations must hold over all admissible inputs.

---

## 3. Qualification Gates for M7

1. `OMEGA_VERIFY_V0_TYPE_PASS`: V0 structural verifier accepts well-typed graphs and rejects ill-typed graphs.
2. `OMEGA_VERIFY_V0_DAG_PASS`: V0 structural verifier rejects cyclic or dangling graphs.
3. `OMEGA_VERIFY_V0_CODE_BOUNDS_PASS`: V0 verifies code length, 4-byte alignment, and buffer boundaries.
4. `OMEGA_VERIFY_V0_INSN_DECODE_PASS`: V0 validates every instruction word and refuses corrupt/unallocated opcodes.
5. `OMEGA_VERIFY_V0_TERMINAL_RET_PASS`: V0 enforces strictly bounded control flow terminating in `RET`.
6. `OMEGA_VERIFY_V1_DIFFERENTIAL_PASS`: V1 confirms bit-for-bit output identity between semantic evaluation and native AArch64 execution across test corpus.
7. `OMEGA_VERIFY_V1_DIVERGENCE_REFUSAL_PASS`: V1 immediately detects and refuses mutant realization causing output mismatch.
8. `OMEGA_VERIFY_V2_COMMUTATIVITY_PASS`: V2 property verifier proves commutativity over declared commutative operations.
9. `OMEGA_VERIFY_V2_IDENTITY_PASS`: V2 property verifier proves identity element preservation.
10. `OMEGA_VERIFY_V2_OVERFLOW_PASS`: V2 property verifier validates declared overflow wrapping semantics.
