# Specification: Milestone 6 — Omega Self-Hosting Compiler (`OMEGA_SELF_HOST`)

```text
Document ID:     SPEC-OMEGA-M6
Milestone:       Milestone 6 (OMEGA_SELF_HOST)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Native AArch64 Machine Code Reproducing Compiler from Semantic Graph
Status:          SPECIFIED / IN PROGRESS (aien-dev/aien-architecture#18)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4/M5/M6) -> AIEN
```

---

## 1. Executive Summary & Foundational Invariants

Milestone 4 established abstract semantic meaning (`OMEGA_SEMANTICS`) with content-addressed identity (`SEMANTIC_ID`).
Milestone 5 established direct lowering from pure semantics into native physical machine code (`OMEGA_AARCH64`) without LLVM or GNU `as`.

Milestone 6 establishes the closed-loop reproduction of the realization compiler itself:

> **OMEGA REPRODUCES ITS MINIMAL REALIZATION COMPILER THROUGH ITS OWN SEMANTIC GRAPH.**

The system reaches self-hosting closure when the compiler is an explicit semantic object $G_C \in \text{OmegaGraph}$ that compiles itself into native machine code, achieving an exact fixed point:

```text
C0 = temporary reference C implementation
G_C = OMEGA semantic definition of minimal compiler

C0(G_C)
   ↓
  C1 (native AArch64 machine code)

C1(G_C)
   ↓
  C2 (native AArch64 machine code)

C2(G_C)
   ↓
  C3 (native AArch64 machine code)

Required Fixed Point:
C1 == C2 == C3  (bit-for-bit, byte-for-byte identity)
```

Once this fixed point is demonstrated, the reference C implementation ($C_0$) is sovereignly superseded and no longer required to reproduce the compiler.

---

## 2. Inviolable Governance Principles at M6

1. **No Foreign Compiler Dependency**:
   Neither LLVM, Clang, GCC, nor any external assembler is used to generate $C_1$, $C_2$, or $C_3$. The canonical code generation path runs solely through OMEGA semantic lowering.

2. **Deterministic Bit-for-Bit Fixed Point**:
   $$\text{SHA256}(C_1) == \text{SHA256}(C_2) == \text{SHA256}(C_3)$$
   $$\text{REALIZATION\_ID}(C_1) == \text{REALIZATION\_ID}(C_2) == \text{REALIZATION\_ID}(C_3)$$

3. **Compiler Capability Completeness**:
   The semantic compiler $G_C$ must contain all semantic machinery required to:
   - Decode OMG0 binary wire streams.
   - Validate input types and bit-widths.
   - Lower pure operations into AArch64 instructions.
   - Assign integer registers (`X0`–`X30`, `XZR`).
   - Synthesize AArch64 ALU, immediate, branch, and return opcodes.
   - Lay out bounded branches.
   - Cryptographically compute `REALIZATION_ID` over generated code bytes.

4. **Preservation of Qualified Semantics (M5 Parity)**:
   When $C_1$ compiles the qualified M5 semantic target $F(a, b, c) = (a + b) - c$, it must produce the exact machine bytes qualified in M5:
   $$C_1(G_S) == C_0(G_S) == \text{00 00 01 8B 00 00 02 CB C0 03 5F D6}$$
   and executing the resulting binary with $(a=7, b=11, c=3)$ must yield 15.

---

## 3. Canonical Compiler Interface

The native realization compiler $C$ implements the standard AArch64 register ABI:

```text
Inputs:
  X0: Pointer to serialized OMG0 input buffer (representing graph G)
  X1: Size in bytes of input OMG0 buffer
  X2: Pointer to output buffer for synthesized AArch64 machine code
  X3: Pointer to uint64_t to receive synthesized code length in bytes
  X4: Pointer to 32-byte buffer to receive REALIZATION_ID

Output:
  X0: 0 on success, negative error code on failure
```

---

## 4. Qualification Gates for M6

1. `OMEGA_SELF_HOST_GRAPH_PASS`: Semantic graph $G_C$ successfully constructed and validated.
2. `OMEGA_SELF_HOST_C1_EMISSION_PASS`: $C_0(G_C) \to C_1$ emits valid AArch64 machine instructions.
3. `OMEGA_SELF_HOST_DECODER_SEAM_PASS`: Independent decoder validates all $C_1$ instructions prior to execution.
4. `OMEGA_SELF_HOST_C2_REPRODUCTION_PASS`: Executing $C_1(G_C) \to C_2$ succeeds and emits machine code.
5. `OMEGA_SELF_HOST_C3_REPRODUCTION_PASS`: Executing $C_2(G_C) \to C_3$ succeeds and emits machine code.
6. `OMEGA_SELF_HOST_FIXED_POINT_PASS`: Byte-for-byte identity $C_1 == C_2 == C_3$ verified.
7. `OMEGA_SELF_HOST_REALIZATION_ID_PASS`: `REALIZATION_ID` matching across $C_1, C_2, C_3$.
8. `OMEGA_SELF_HOST_M5_PARITY_PASS`: $C_1(G_S)$ compiles $F(a, b, c) = (a + b) - c$ to exact M5 bytes.
9. `OMEGA_SELF_HOST_NATIVE_EXECUTION_PASS`: Output of $C_1(G_S)$ executes natively to 15.
10. `OMEGA_SELF_HOST_ADVERSARIAL_MUTATION_PASS`: Single-bit mutation in $G_C$ or $C_1$ produces immediate refusal or mismatch.
