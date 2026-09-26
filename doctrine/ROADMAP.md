# DOCTRINE-ROADMAP: The 41-Milestone Sovereign Roadmap (M0-M40)

```text
Document ID:     DOCTRINE-ROADMAP
Classification:  Sovereign Machine Canonical Doctrine (Single Roadmap Source)
Target Substrate: Complete Sovereign Stack (Atlas -> Physics -> Omega -> Aien)
Status:          AUTHORITATIVE / CANONICAL
```

---

## 1. Authority of This Document

This file is the **single authoritative source** for Sovereign Machine milestone numbering, milestone code identifiers, and milestone status.

- Every other doctrine page references this file instead of restating the milestone table or milestone status.
- Milestone status is changed **only** here. A status change must cite the qualifying evidence (issue, PR, or receipt).
- `scripts/check_doctrine.sh` enforces this: it fails if another doctrine page duplicates the roadmap table, carries its own milestone status tags, or cites a milestone code identifier under a milestone number different from the one below.

Status vocabulary:

| Status | Meaning |
| :--- | :--- |
| `COMPLETE` | Milestone gate passed and ratified. |
| `COMPLETE / QEMU QUALIFIED` | Gate passed under QEMU qualification; native hardware qualification remains separately gated. |
| `REOPENED / IN PROGRESS` | Previously reported complete; reopened for requalification. Not complete. |
| `PLANNED` | Not started. |

---

## 2. The Canonical Roadmap Table

| Milestone | Era | Code Identifier | Scope & Objective Invariants | Status |
| :--- | :--- | :--- | :--- | :--- |
| **M0** | Foundational | `DOCTRINE_V1` | Foundational Specification. Ratification of complete architectural corpus. | COMPLETE |
| **M1** | Foundational | `ATLAS_BOOT` | Irreducible bootstrap seed (`atlas.bin`). Dual-seam verified. | COMPLETE / QEMU QUALIFIED |
| **M2** | Foundational | `PHYSICS_BOOT` | Physical machine authority nucleus (`physics.bin`). Current-EL VBAR, frame authority, CAP_ROOT. Requalified 2026-09-26 (`aien-dev/physics#3`, receipt `qualification_receipt.json`). QEMU only; `PHYSICS_BOOT_NATIVE_PASS` pending. | COMPLETE / QEMU QUALIFIED |
| **M3** | Foundational | `PHYSICS_EFFECTS` | Capability ledger, monotonic attenuation, effect broker, signed execution receipts (`EFFECT_INTENT` admission, `EFFECT_RECEIPT` accounting). Qualified 2026-09-26 under `aien-dev/physics#9` (commit `766f8fd6...`, receipt commit `a7dc4ef7...`). QEMU only; native hardware qualification remains separately gated. | COMPLETE / QEMU QUALIFIED |
| **M4** | Omega Core Substrate | `OMEGA_SEMANTICS` | Semantic graph ($G_S$), typed AST, invariant envelopes, substrate-independent content-addressed identity. Qualified 2026-09-26 under `aien-dev/omega` (commit `30bb116...`, receipt commit `a975573...`). | COMPLETE |
| **M5** | Omega Core Substrate | `OMEGA_AARCH64` | Native direct AArch64 machine byte realization generator (no LLVM). Qualified 2026-09-26 under `aien-dev/omega` (commit `2dd4102...`, receipt commit `34dbe93...`). | COMPLETE |
| **M6** | Omega Core Substrate | `OMEGA_SELF_HOST` | Omega reproduces the minimal realization compiler through its own semantic graph. Qualified 2026-09-26 under `aien-dev/omega` (commit `8033c38...`, receipt `evidence/omega_self_host_qualification_receipt.json`). | COMPLETE |
| **M7** | Omega Core Substrate | `OMEGA_VERIFY` | Mandatory V0-V2 verification engine; V3-V5 proof-carrying code framework. Qualified 2026-09-26 under `aien-dev/omega` (commit `202fa3c...`, receipt `evidence/omega_verify_qualification_receipt.json`). | COMPLETE |
| **M8** | Program Synthesis & Library Learning | `OMEGA_PROGRAM_CORE` | Explicit program representation, synthesis task schema (`SYNTHESIS_TASK`), program cost modeling. Qualified 2026-09-26 under `aien-dev/omega` (commit `d25349e...`, receipt `evidence/omega_program_core_qualification_receipt.json`). | COMPLETE |
| **M9** | Program Synthesis & Library Learning | `OMEGA_SYNTHESIS_V0` | Deterministic typed program synthesis over base primitives. Qualified 2026-09-26 under `aien-dev/omega` (commit `39905a3...`, receipt `evidence/omega_synthesis_v0_qualification_receipt.json`). | COMPLETE |
| **M10** | Program Synthesis & Library Learning | `OMEGA_LIBRARY_V1` | Versioned procedural program library, provenance tracking, and verified component catalog. | PLANNED |
| **M11** | Program Synthesis & Library Learning | `OMEGA_LIBRARY_DISCOVERY` | Autonomous abstraction discovery from program corpus with verified reuse. | PLANNED |
| **M12** | Program Synthesis & Library Learning | `OMEGA_LIVING_MATVEC` | Adaptive realization selection across varying input regimes and cache dynamics. | PLANNED |
| **M13** | Program Synthesis & Library Learning | `OMEGA_MACHINE_GRAPH` | Formal machine hardware graph ($G_M$) describing execution pipelines and memory hierarchies, as reported by Physics. | PLANNED |
| **M14** | Program Synthesis & Library Learning | `OMEGA_REALIZATION_SYNTHESIS` | Automated $G_S \times G_M \to G_R$ synthesis targeting declared hardware capabilities. | PLANNED |
| **M15** | Accelerator Cognition Substrate | `PHYSICS_ACCELERATOR_LINK` | Bounded coherent CPU/accelerator memory interface and SMMUv3 DMA sandboxing. | PLANNED |
| **M16** | Accelerator Cognition Substrate | `BLACKWELL_NATIVE_PATH_KNOWN` | Empirical execution characterization of native Blackwell SM architecture (MMIO, queue submission, doorbells). | PLANNED |
| **M17** | Accelerator Cognition Substrate | `OMEGA_BLACKWELL_VECTOR` | Verified Blackwell vector compute realization generated directly from $G_S$. | PLANNED |
| **M18** | Accelerator Cognition Substrate | `OMEGA_BLACKWELL_MATMUL` | Verified native Blackwell tensor matrix multiplication with tensor core acceleration. | PLANNED |
| **M19** | Accelerator Cognition Substrate | `OMEGA_ACCELERATOR_RESIDENT` | Persistent Omega execution substrate residing in accelerator-accessible coherent memory. | PLANNED |
| **M20** | Sovereign Training Runtime | `OMEGA_TENSOR` | Tensor semantics, multi-dimensional array types, strides, and memory layouts. | PLANNED |
| **M21** | Sovereign Training Runtime | `OMEGA_AUTODIFF` | Sovereign automatic differentiation generating gradient semantic graphs. | PLANNED |
| **M22** | Sovereign Training Runtime | `OMEGA_OPTIMIZER` | Verified sovereign optimizer realizations (SGD, Adam, AdamW). | PLANNED |
| **M23** | Sovereign Training Runtime | `OMEGA_SEARCH_GUIDE_TRAINING` | Sovereign training pipeline for search guides using Omega-generated traces. | PLANNED |
| **M24** | Sovereign Training Runtime | `AIEN_0` | First sovereign neural search guide ranking subgoals and pruning search branches. | PLANNED |
| **M25** | Sovereign Training Runtime | `AIEN_GUIDED_SYNTHESIS` | Neural-guided synthesis achieving lower search cost under invariant verification parity. | PLANNED |
| **M26** | Sovereign Training Runtime | `AIEN_ABSTRACTION_DISCOVERY` | AIEN proposes candidate abstractions; Omega enforces survival based on utility. | PLANNED |
| **M27** | Physics Zero Discovery | `PHYSICS_ZERO_PROTOCOL` | Contamination firewall specification and sealed evaluation benchmark contracts. | PLANNED |
| **M28** | Physics Zero Discovery | `PHYSICS_ZERO_HIDDEN_WORLDS` | Discrete and continuous sealed benchmark worlds with randomized channels (P0-0..P0-2). | PLANNED |
| **M29** | Physics Zero Discovery | `AIEN_THEORY_DISCOVERY` | Executable `OMEGA_THEORY` synthesis, population competition, and calibrated prediction. | PLANNED |
| **M30** | Physics Zero Discovery | `AIEN_ACTIVE_EXPERIMENTATION` | Active experiment design distinguishing competing theories ($P(R \mid A) \neq P(R \mid B)$). | PLANNED |
| **M31** | Physics Zero Discovery | `AIEN_CONCEPT_FORMATION` | Autonomous invention of reusable latent concepts (`OMEGA_DISCOVERED_CONCEPT`). | PLANNED |
| **M32** | Physics Zero Discovery | `PHYSICS_ZERO_ALIEN_WORLDS` | Scientific discovery in universes governed by unfamiliar laws (P0-5). | PLANNED |
| **M33** | Physics Zero Discovery | `PHYSICS_ZERO_NOVEL_REGIME` | Extrapolative theory prediction in unobserved state regimes. | PLANNED |
| **M34** | Physics Zero Discovery | `PHYSICS_ZERO_NOVEL_PHENOMENON` | Predictive discovery and experimental realization of unobserved phenomena. | PLANNED |
| **M35** | Physics Zero Discovery | `PHYSICS_ZERO_REAL_LAB` | Capability-bounded, safety-governed autonomous discovery in physical laboratories. | PLANNED |
| **M36** | General AIEN | `AIEN_HUMAN_INTERFACE` | Bi-directional perceptual adapter mapping human natural language to Omega semantics. | PLANNED |
| **M37** | General AIEN | `AIEN_RESIDENT` | Persistent, high-throughput cognitive loop resident in accelerator HBM memory. | PLANNED |
| **M38** | General AIEN | `OMEGA_CONTINUAL_LIBRARY_LEARNING` | Continuous Wake/Solve/Verify/Sleep compounding loop. | PLANNED |
| **M39** | General AIEN | `AIEN_SCIENTIFIC_AUTONOMY` | Fully autonomous scientific discovery cycle: observe, hypothesize, test, discover. | PLANNED |
| **M40** | General AIEN | `AIEN_SUCCESSION` | Sovereign succession protocol: AIEN-N trains and proposes AIEN-N+1 candidate. | PLANNED |

Era ranges: Foundational M0-M3; Omega Core Substrate M4-M7; Program Synthesis & Library Learning M8-M14; Accelerator Cognition Substrate M15-M19; Sovereign Training Runtime M20-M26; **Physics Zero Discovery M27-M35**; **General AIEN M36-M40**.

---

## 3. Milestone Notes & Evidence

### M1 — `ATLAS_BOOT`
- Repository: https://github.com/aien-dev/atlas
- Canonical Artifact: `atlas.bin` (1,480 bytes, SHA-256: `f7802501b410a0c19eff7b8fca8865c9ba9c96bfa4f8065ca8f508b67748b9a5`)
- Dual-Seam Verification:
  - Seam 1 (Static Audit): 100% word-reconciled (301 insns, 69 rodata words, 0 discrepancy), static target proof (`ldr x19, =0x40200000; br x19`), disjoint stack/descriptor proof (SP <= `0x401FC000` vs Descriptor @ `0x401FE000` with 8 KiB guard gap, empty intersection).
  - Seam 2 (Execution Harness): Bare-metal QEMU virt; 268/268 mutations refused into fail-closed quiescence (exhaustive 256 single-byte offset sweep + 12 adversarial scenarios).
  - Cryptographic Scheme: Bare-metal NIST FIPS 180-4 SHA-256 (KAT verified 100%).
- Native Hardware Status: `ATLAS_BOOT_NATIVE_PASS` remains pending and decoupled from QEMU qualification.
- Specification: [`docs/milestone-1-spec.md`](../docs/milestone-1-spec.md).

### M2 — `PHYSICS_BOOT`
- Requalified 2026-09-26 under aien-dev/aien-architecture#6, aien-dev/physics#1, and aien-dev/physics#3 (descriptor ingress anti-expansion, frame authority bounds, and exception confinement hardening). Ratified via qualification receipt (`qualification_receipt.json`).
- Exception level is contract-driven: Physics checks `CurrentEL` against the machine contract and installs `VBAR_EL1` or `VBAR_EL2` accordingly, with no implicit EL2 -> EL1 transition. The current QEMU contract, `CONTRACT-QEMU-VIRT-AARCH64-M2`, specifies EL1 entry.
- `PHYSICS_BOOT_QEMU_PASS` does not imply `PHYSICS_BOOT_NATIVE_PASS`.
- Specification: [`docs/milestone-2-spec.md`](../docs/milestone-2-spec.md).

### M3 — `PHYSICS_EFFECTS`
- Qualified 2026-09-26 under `aien-dev/physics#9` (merged as commit `766f8fd6b898f4df793ffa809f031040ba0912fa`), ratified via qualification receipt `m3/m3_qualification_receipt.json` in commit `a7dc4ef7e0ea9fa733d06114eb31a26d70cb3e53`.
- Bounded 32-record capability ledger with monotonic attenuation, ancestor-chain validation on use (instantaneous descendant revocation), single canonical effect broker with 10-stage fail-closed admission decoupled from physical handlers, append-only receipt ledger with rolling cryptographic SHA-256 seal chain, and 32-entry replay cache.
- In-guest bare-metal test suite in QEMU virt AArch64 passed 21/21 tests (`0x001FFFFF`). Python-free qualification runner evaluated all 19 canonical gates with 100% pass and zero regressions on M1 or M2.
- Anti-bloat budget: `physics.elf` text size 10,624 bytes (32.4% of 32 KiB budget); `physics.bin` total image 18,432 bytes (28.1% of 64 KiB budget).
- Native Hardware Status: QEMU qualified only; native hardware qualification remains separately gated.
- Specification: [`docs/milestone-3-spec.md`](../docs/milestone-3-spec.md).

### M5 — `OMEGA_AARCH64`
- Qualified 2026-09-26 under `aien-dev/omega` (commit `2dd41024345d207d57f59d4c7940176b6697b099`, receipt commit `34dbe93e9fa22aee50b8eb426e6d1e43444490f2`).
- Direct AArch64 machine byte realization generator without LLVM, Clang, GCC, or GNU `as`.
- Verified pure integer register lowering ($G_S \to$ AArch64) for $F(a, b, c) = (a + b) - c$.
- Content-addressed `REALIZATION_ID` cryptographic binding to M4 `SEMANTIC_ID`.
- Triple verification seams:
  1. Static independent instruction bitmask decoder.
  2. Native DGX Spark in-memory execution (`mprotect PROT_EXEC`).
  3. Bare-metal QEMU virt runner execution with PL011 UART telemetry and semihosting clean exit.
  4. Adversarial single-bit mutation refusal gate.
- 9/9 canonical M5 qualification gates passed. Specification: [`docs/milestone-5-spec.md`](../docs/milestone-5-spec.md).

### M7 — `OMEGA_VERIFY`
- REQUIRED: V0 Structural/Type/Capability, V1 Differential, V2 Property/Invariant.
- FRAMEWORK DEFINED FOR: V3 Adversarial, V4 Symbolic, V5 Proof-Carrying.

### M11 — `OMEGA_LIBRARY_DISCOVERY`
One nontrivial abstraction not present in the initial library that:
1. Compresses multiple verified programs;
2. Preserves their semantics;
3. Is reused on held-out tasks;
4. Reduces search cost.

### M22 — `OMEGA_OPTIMIZER`
Omega-native semantics for SGD, Adam, and AdamW, with verified CPU reference realizations and optional accelerator-fused realizations.

### M40 — `AIEN_SUCCESSION`
Closed-loop self-improvement: AIEN-N designs AIEN-N+1 under Physics canary control.

---

<!-- HISTORICAL-PROVENANCE:BEGIN -->
## 4. Historical Provenance: Superseded Roadmap Generations

> **HISTORICAL — NOT NORMATIVE.** Retained only to explain older references. Do not cite these numbers.

- **28-milestone workstream roadmap (M0-M27, workstreams A-F):** ended at M27 `SOVEREIGN_MACHINE_CLOSURE`; its identifiers (e.g. `ATLAS_BAREMETAL_BOOT`, `PHYSICS_CORE_MEMBRANE`, `SENTINEL_GATE_1..3`) are retired.
- **31-milestone program-learning roadmap (M0-M30):** placed `AIEN_HUMAN_INTERFACE` at M27, `AIEN_RESIDENT` at M28, `OMEGA_CONTINUAL_LIBRARY_LEARNING` at M29, and `AIEN_SUCCESSION` at M30. Superseded by the 41-milestone roadmap above when Physics Zero (DOCTRINE-006) was ratified.
- **Alpha lineage:** `atlas.bin` was designated Alpha (`alpha.bin`) during early bootstrap drafting; the Alpha evidence bundle names (`alpha.manifest`, `alpha.sha256`, `alpha.decode`, `alpha.memory-map`, `alpha.control-flow`, `alpha.audit`) are retired in favour of `atlas.*`.
<!-- HISTORICAL-PROVENANCE:END -->
