# Specification: Milestone 5 — Omega Direct AArch64 Realization (`OMEGA_AARCH64`)

```text
Document ID:     SPEC-OMEGA-M5
Milestone:       Milestone 5 (OMEGA_AARCH64)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Native AArch64 Bare-Metal Machine Bytes (No LLVM, No Foreign Assembler)
Status:          QUALIFIED / RATIFIED (aien-dev/aien-architecture#17, aien-dev/omega@2dd4102)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4/M5) -> AIEN
```

---

## 1. Executive Summary & Foundational Invariants

Milestone 4 established `OMEGA_SEMANTICS`: defining what computation means in a substrate-independent semantic graph ($G_S$) with canonical content-addressed identity (`SEMANTIC_ID`).

Milestone 5 establishes the first direct lowering from abstract semantic meaning into native physical machine code:

> **OMEGA SYNTHESIZES BARE-METAL AARCH64 MACHINE BYTES DIRECTLY FROM SEMANTIC MEANING WITHOUT LLVM, GCC, OR THIRD-PARTY ASSEMBLERS.**

The objective is to establish direct physical realization while preserving absolute semantic equivalence:

```text
M4 SEMANTIC OBJECT ($G_S$)
F(a, b, c) = (a + b) - c
         ↓
    SEMANTIC_ID S
         ↓
OMEGA AARCH64 REALIZER
         ↓
 RAW MACHINE BYTES B
         ↓
  REALIZATION_ID R (references S)
         ↓
PHYSICAL / QEMU EXECUTION
         ↓
 native_result == semantic_result
```

---

## 2. Inviolable Governance Principles at M5

1. **No Foreign Compiler Infrastructure**:
   LLVM, GCC, Clang, GNU `as`, NASM, and third-party JITs are strictly forbidden in the canonical realization path. Machine instructions must be synthesized directly as 32-bit AArch64 binary words.

2. **Dual-Seam Instruction Verification**:
   - **Seam 1 (Static Decoding Seam)**: An independent direct AArch64 decoder disassembles and validates every emitted instruction byte prior to execution, ensuring structural validity and absence of undefined opcodes.
   - **Seam 2 (Execution Parity Seam)**: The synthesized code is executed on AArch64 (both native DGX Spark and bare-metal QEMU) and verified to yield the bit-for-bit identical result as M4 pure semantic evaluation.

3. **Cryptographic Binding of Realization to Meaning**:
   $$\text{REALIZATION\_ID} = \text{SHA256}(\text{CANONICAL\_REALIZATION\_ENCODING})$$
   The canonical realization encoding explicitly embeds the `SEMANTIC_ID` of the source graph, binding physical machine bytes to abstract meaning.

4. **Adversarial Bit Mutation Gate**:
   Mutating any single bit in the generated machine code must either:
   - Cause immediate rejection by the independent instruction decoder, OR
   - Produce a detectable differential mismatch during execution.

---

## 3. Strict Initial Instruction Subset (Anti-Bloat Ceiling)

To keep the initial proof focused on **semantic preservation** without memory-system or MMU complexity, Milestone 5 restricts instruction synthesis to a strictly bounded integer computational subset:

### Primary Computational Primitives
1. **64-bit & 32-bit Integer ALU**:
   - `ADD` (shifted register / immediate)
   - `SUB` (shifted register / immediate)
   - `MUL` (register multiplication)
   - `AND`, `ORR`, `EOR` (bitwise logical operations)
2. **Immediate Loading & Register Movement**:
   - `MOV` / `MOVZ` (wide immediate)
   - `MOVN`, `MOVK`
3. **Control Flow & Return**:
   - `RET` (unconditional return to link register `x30`)
   - `B` (bounded relative branch)
   - `B.cond` (conditional branch on integer flags: `EQ`, `NE`, `LT`, `GE`)
   - `CBZ`, `CBNZ` (compare and branch on zero / non-zero)

*Memory loads and stores (`LDR`, `STR`) and stack frames are deferred until pure register computation is fully qualified.*

---

## 4. Lowering Rules: $G_S \to \text{AArch64}$

The lowering pipeline maps:
- Types $\to$ Register width ($w \le 32 \to$ `Wn`, $32 < w \le 64 \to$ `Xn`).
- Inputs $\to$ Standard AArch64 ABI parameter registers (`x0`, `x1`, `x2`, ...).
- Pure Operations $\to$ Direct 32-bit machine word emission.
- Output $\to$ Return register `x0`.
- Terminal $\to$ `RET` instruction (`0xD65F03C0`).

---

## 5. Canonical M5 Qualification Gates

1. `OMEGA_AARCH64_PROFILE_PASS`: Validates target profile, registers, and calling conventions.
2. `OMEGA_AARCH64_ENCODER_PASS`: Direct binary emission of integer ALU, MOV, branches, and RET without foreign tools.
3. `OMEGA_AARCH64_DECODER_SEAM_PASS`: Independent decoder validates all emitted instruction words.
4. `OMEGA_AARCH64_LOWERING_PASS`: $G_S$ pure operation graphs lower deterministically into instruction sequences.
5. `OMEGA_AARCH64_REALIZATION_ID_PASS`: `REALIZATION_ID` deterministically binds machine bytes and `SEMANTIC_ID`.
6. `OMEGA_AARCH64_NATIVE_EXECUTION_PASS`: Native execution on AArch64 host matches M4 pure semantic evaluation.
7. `OMEGA_AARCH64_QEMU_EXECUTION_PASS`: Bare-metal execution in QEMU `virt` machine matches semantic evaluation.
8. `OMEGA_AARCH64_ADVERSARIAL_MUTATION_PASS`: Single-bit machine code corruption detected fail-closed.
9. `OMEGA_AARCH64_CROSS_BUILD_DETERMINISM_PASS`: Reproducible byte-for-bit realization across independent runs.
