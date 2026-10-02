# AIEN Engineering Recovery Program: M19R Baseline Stabilization through Foundation-Trust Admission

Status: RATIFIED (operator directive 2026-09-27), revised per critique 2026-09-27
Date: 2026-09-27
Authority: Operator Directive (Drake Stapleton)
Scope: Stop-the-line cleanup of M19 defects and staged admission program prior to M20 training stack development.

---

## 1. Executive Directive and Sequencing

The engineering assessment of 2026-09-27 confirmed that while M19 demonstrated core Blackwell GPFIFO execution on DGX Spark GB10 silicon, critical defects exist beneath the M19 surface:
1. Qualification receipts assert rather than observe counts, hardware strings, and commit identities.
2. Rerunning regression suites overwrites historical milestone evidence in place.
3. GPU device memory allocations lack a deallocation path (`nvrm_free` missing), leaking memory and virtual address space on buffer revocation.
4. Completion markers rely on CPU marker resets and equality tests, enabling race conditions and double-commit vulnerabilities.
5. The Blackwell IR lacks floating-point SIMT instructions, restricting matrix operations to a single fixed K=16 tile width.
6. The synthesis candidate search space is capped at depth 3 and 512 candidates, providing insufficient volume for learned policy training.

Building further training-stack milestones on top of this unverified substrate violates sound engineering doctrine. Work on the training stack (tensors onward) is gated behind repair of the foundation.

### Two Prime Objectives

1. Make the existing M19 foundation trustworthy.
2. Build the training stack on top of that trustworthy foundation, one independently-qualified milestone at a time.

### Doctrine (per ADR 0014, accepted 2026-09-27 — FORGE realizes; historical PHYSICS identifiers unchanged)

```
ATLAS AWAKENS.
AIEN PROPOSES.
OMEGA DEFINES.
FORGE REALIZES.
AEGIS VERIFIES.
HARDWARE ACTS.
EVIDENCE TEACHES.
```

### Master Linear Progression

```
M19
 ↓
M19R        prove the evidence is truthful
 ↓
FORGE-0     FORGE realize / AEGIS verify seam + hardware probe
 ↓
NUMERIC     make general numerical computation real (FP32 substrate)
 ↓
------------------------- Combined Foundation Admission Gate (Gate 14) -------------------------
 ↓
M20 TENSORS            make differentiable state representable      (own gate, own receipt)
 ↓
M21 AUTODIFF           generate learning computation                (own gate, own receipt)
 ↓
M22 OPTIMIZER          make learning atomic                         (own gate, own receipt)
 ↓
M23 SEARCH-GUIDE TRAIN actually learn something, guided by search   (own gate, own receipt)
 ↓
M24 AIEN_0 + HOLDOUT   prove that it learned, on a sealed holdout   (own gate, own receipt)
```

**Decision A (operator, 2026-09-27):** the Combined M20 Admission Gate (Gate 14) covers ONLY the foundation gates: evidence (Gate 1), runtime lifecycle (Gate 2), realize/verify seam (Gates 3-4), and the FP32 substrate (Gate 5). Tensors, autodiff, optimizer, search-guided training, and AIEN_0 + holdout are separately qualified milestones — M20 (tensor), M21 (autodiff), M22 (optimizer), M23 (search-guide training), M24 (AIEN_0 + sealed holdout) — each closed by its own gate and its own receipt, not folded into Gate 14. Gate 14 passing means the foundation may be built on; it does not mean M20-M24 are done.

**Decision B (operator, 2026-09-27, superseding the earlier "PHYSICS keeps its name" decision):** ADR 0014 is accepted. The machine realization subsystem is renamed **FORGE** ("ATLAS AWAKENS. AIEN PROPOSES. OMEGA DEFINES. FORGE REALIZES. AEGIS VERIFIES. HARDWARE ACTS. EVIDENCE TEACHES."). This is not a history rewrite, per ADR 0014's historical compatibility rule: existing milestone identifiers (`PHYSICS_BOOT`, `PHYSICS_EFFECTS`, `PHYSICS_ACCELERATOR_LINK`), the `aien-dev/physics` repository name, existing evidence files, and any field serialized into historical fingerprints (`is_physics_authorized`, serialized at `omega/src/omega_machine.c:96`) are NOT renamed — removing or renaming `is_physics_authorized` would change historical realization IDs. New code, APIs, gates, and receipts use FORGE naming (`ForgeMachineDescriptor`, `forge_realization`, `forge_receipt`) going forward. The realize/verify seam is built under the FORGE/AEGIS names, as new code, alongside the existing (frozen) M15 authority vocabulary.

**Decision C (operator, 2026-09-27):** the mandatory dual-push-to-forgejo rule is dropped until a forgejo server/remote actually exists. No `forgejo` remote exists in any checkout today. GitHub `origin` is the only required remote for now (see §5).

---

## 2. Immediate Five-Lane Parallelization Architecture

Five execution lanes proceed immediately in parallel. **These lanes do not share zero architectural state** — Lane A and Lane B both touch `omega/src/omega_world_gates.c` (evidence emission vs. runtime lifecycle), and Lane C's probe work reads structures Lane B and Lane D also touch. The isolation guarantee that actually holds is narrower: each lane owns a distinct *addition surface* and none of them renames or deletes another lane's files without an explicit merge-order agreement (see file-level overlap notes below).

```
+-----------------------------------------------------------------------------+
| Lane A: Evidence and Immutable Qualification (M19R)                         |
| Repo: omega (evidence/, src/omega_world_gates.c)                            |
| Target: Hash-addressed immutable receipts, derived execution metrics        |
+-----------------------------------------------------------------------------+
| Lane B: GPU Allocation/Free and Monotonic Completion (M19R-RUNTIME)         |
| Repos: physics (nvrm/, m16/), omega (src/omega_accelerator_world.c,         |
|        src/omega_world_gates.c exit-criteria hooks)                        |
| Target: nvrm_free, memory revocation, monotonic tickets, single-commit FSM   |
+-----------------------------------------------------------------------------+
| Lane C: FORGE realize/AEGIS verify seam + hardware probe (FORGE-0, FORGE-HWID) |
| Repos: physics, omega, aien-architecture                                    |
| Target: typed FORGE/AEGIS seam, ForgeMachineDescriptor, raw hardware        |
|         observation probe. NEW FILES ONLY — no renames of existing         |
|         PHYSICS/OMEGA files, the `physics` repository name, or any         |
|         historical PHYSICS_* identifier; historical M15/M16/M19 names and  |
|         evidence paths are untouched.                                      |
+-----------------------------------------------------------------------------+
| Lane D: FP32 GB10 and Omega Instruction Substrate (OMEGA-NUMERIC-0)         |
| Repo: omega (src/omega_blackwell_codegen.*, src/omega_blackwell_encoder.*)  |
| Target: Blackwell SIMT FP32 opcodes, Omega exp/log, CPU-GB10 bit parity     |
+-----------------------------------------------------------------------------+
| Lane E: Instrumented Search Module (OMEGA-SYNTHESIS-1)                     |
| Repo: omega — NEW module: src/search/                                       |
| Target: Candidate exploration telemetry, search expansion, ranker hook.     |
|         MUST NOT edit src/omega_synthesis.* or src/omega_discovery.* —      |
|         the M9-M11 gates depend on those files as-is; Lane E is additive.   |
+-----------------------------------------------------------------------------+
```

### File-level overlap notes (correction to the "zero shared state" claim)

- `omega/src/omega_world_gates.c` is written by both Lane A (receipt/evidence emission) and Lane B (new exit-criteria checks for the runtime FSM). Lane A's receipt-schema changes must land first (see dependency fix below); Lane B rebases onto it rather than merging in parallel.
- Lane C reads (but must not rename) symbols Lane B and Lane D also touch in `omega_accelerator_world.*` and the Blackwell codegen headers; Lane C's probe and descriptor code lives in new files and only *references* those symbols.
- Lane E is fully additive (`src/search/` is new) and has no file-level overlap with any other lane, by construction.

---

## 3. Phased Gate Specifications

### Gate 1: M19R - Repair the Qualified Baseline

Objective: Freeze current evidence and establish an immutable, observation-derived qualification lineage.

1. Freeze existing M18 and M19 receipts as read-only historical records. Qualification scripts must never overwrite existing files. **Existing evidence file paths and filenames are not moved or renamed** — docs (including `aien-architecture/docs/milestone-19-spec.md`) and Cortex records reference these exact paths.
2. Establish the `M19_REPAIR_BASELINE` qualification lineage. New runs are written to new, immutable run directories; nothing already committed under `evidence/M18/` or `evidence/M19/` is edited in place.
3. Restructure evidence storage (for new runs going forward) to hash-addressed immutable receipts:
   ```
   evidence/
     M18/
       <receipt-digest>.json
     M19/
       <receipt-digest>.json
     M19R/
       <receipt-digest>.json
   ```
4. Derive all receipt fields strictly from observed execution:
   - Source git commit SHA — **the receipt binds the frozen CANDIDATE commit under qualification, never whatever HEAD the rerun happens to execute at.** (Observed failure mode, 2026-09-27: a regression rerun at the merge commit rebound M19's `candidate_git_commit` from `beaa118` to `ae2476d`, silently falsifying the qualification record. This must be structurally impossible: the qualification harness takes the candidate commit as an input parameter, not a runtime `git rev-parse HEAD`.)
   - Working tree dirty/clean state
   - Candidate binary digest (SHA-256)
   - Test manifest digest
   - Array of test identifiers actually executed
   - Pass and fail counts actually observed (zero fixed constants like "157" or "175"; see §6, derived cumulative regression counts)
   - Hardware probe digest
   - Realization and runtime identity
   - Predecessor qualification digest
   - Timestamp and run identity
   - Overall receipt digest
5. **Evidence is committed separately from code.** Regenerating or adding evidence happens in a dedicated evidence-only commit, never mixed into a commit that also changes source, so evidence provenance can be audited independently of implementation changes.
6. Exit Gate:
   ```
   RECEIPT_COUNTS_DERIVED           PASS
   HISTORICAL_RECEIPTS_IMMUTABLE   PASS
   CLEAN_RERUN_REPRODUCIBLE         PASS
   CANDIDATE_COMMIT_BOUND_NOT_HEAD  PASS
   EVIDENCE_COMMIT_SEPARATE         PASS
   M19R_EVIDENCE                    PASS
   ```

**Owner:** Lane A (omega repo, evidence/ + omega_world_gates.c).
**Boundary:** May add new evidence files and new receipt-schema fields; must not edit, move, or rename any existing evidence file under `evidence/M4/` … `evidence/M19/`.
**Failure behavior:** Any attempted overwrite of an existing evidence file, or any receipt whose `candidate_git_commit` does not match the harness-supplied candidate parameter, fails the gate closed — no receipt is emitted.
**Evidence:** `evidence/M19R/<receipt-digest>.json`, plus the evidence-only commit SHA recorded in the ratification PR.

---

### Gate 2: M19R-RUNTIME - Fix Correctness Defects Hidden by Current Gates

Objective: Eliminate physical GPU memory leaks and establish deterministic, monotonic completion semantics.

1. GPU Resource Lifecycle:
   - Introduce an explicit `nvrm_free` API in `physics/nvrm/nvrm.c` that issues `NVOS00_CTRL_CMD_FREE` / `NV_ESC_RM_FREE` to release allocation handles and physical device memory.
   - Update `omega_world_revoke_buffer` to transition slots to `RETIRING`, await retirement of all referencing in-flight dispatches, and invoke `nvrm_free`.
   - Measure actual GPU device allocation state via driver queries and VMM inspection, not merely process RSS.
   - Verify repeated allocate, use, revoke loops without virtual address or physical memory creep.
2. Monotonic Completion and State Machine:
   - Replace exact-value completion markers (`*marker == expected`) with monotonic ticket comparisons (`*marker >= expected`).
   - Eliminate CPU-side marker resets during active operation.
   - Enforce a strict per-dispatch state machine:
     ```
     Created -> Submitted -> InFlight -> Completed -> Committed
     ```
   - Transitions are strictly forward. `Committed` is reachable exactly once.
   - Test the core invariant: one dispatch yields zero or one failure result, exactly one terminal state, and never two commits.
3. Adversarial Test Matrix (there are no hardware interrupts in this path — completion is detected by the runtime polling a memory completion marker; the adversarial cases below are stated in those terms):
   - **Duplicate marker observation**: the runtime polls the same completed marker value more than once across poll cycles and must commit exactly once, not once per observation.
   - **Skipped marker value**: the polled marker jumps past the expected ticket value (e.g. a batched dispatch completes out of the polled sequence) without the intermediate value ever being observed.
   - **Stale marker value**: the runtime reads a marker value left over from a prior generation/epoch (e.g. after a slot reuse) and must reject it rather than treat it as current completion.
   - Timeout racing completion (poll times out in the same window the marker actually flips).
   - Error arriving after success status.
   - Teardown and recovery during active in-flight execution.
4. Exit Gate:
   ```
   DEVICE_ALLOCATION_BALANCE        PASS
   REVOKE_RELEASES_DEVICE_MEMORY    PASS
   COMPLETION_MONOTONIC             PASS
   DISPATCH_COMMIT_EXACTLY_ONCE     PASS
   FAILURE_CLEANUP                  PASS
   LONG_SOAK_NO_DEVICE_LEAK         PASS
   ```
   - **LONG_SOAK_NO_DEVICE_LEAK definition:** a soak run of ≥ 1 hour OR ≥ 100,000 allocate/use/revoke cycles (whichever is reached first is sufficient, both are attempted), with total bytes churned through the allocator > 2× physical device memory over the run, and **zero growth** in driver handle count and VA high-water mark measured at the start and end of the run (not merely "no crash").

**Owner:** Lane B (physics nvrm/m16 + omega_accelerator_world.c).
**Boundary:** May add `nvrm_free` and modify the revoke path and completion/state-machine code; must not modify Lane A's receipt-schema fields directly — new exit-criteria fields are proposed to Lane A and merged after Gate 1 lands (see dependency fix below).
**Failure behavior:** Any double-commit, any non-monotonic marker acceptance, or any measured handle/VA growth over the soak window latches a FAULTED state; only explicit `recover`/`rebuild` clears it, and the gate does not pass while latched.
**Evidence:** `evidence/M19R-RUNTIME/<receipt-digest>.json`, including raw driver handle-count/VA samples at soak start and end.

---

### Gate 3: FORGE-0 - FORGE realize / AEGIS verify seam

Note (ADR 0016 Amendment 1, 2026-10-02): this is the hardware realization seam. FORGE is not a stage of accepting a reaction result; that chain is World -> J-Space -> compose.verify -> commit -> Cortex.

Objective: Formally establish the typed FORGE-realize / AEGIS-verify seam and eliminate obsolete authorization concepts that are not doctrine, without touching what is already correct doctrine.

1. Architectural Alignment (per ADR 0013 clause 5 — see §1 doctrine block). No renaming of PHYSICS or its historical vocabulary.
2. Vocabulary additions (new code, additive — nothing existing is renamed):
   - `ForgeMachineDescriptor`
   - `forge_realization`
   - `forge_receipt`
   - `verified_realization`
   - `aegis_verification`
   - **`is_physics_authorized` is kept as-is** — it is serialized into machine-graph fingerprints (`omega/src/omega_machine.c:96`); removing or renaming it would change historical realization IDs and invalidate every prior fingerprint. It is documented, not deleted. Historical identifiers `PHYSICS_BOOT`, `PHYSICS_EFFECTS`, and `PHYSICS_ACCELERATOR_LINK`, and the `aien-dev/physics` repository name, are likewise not renamed (ADR 0014 historical compatibility rule).
   - Historical M15/M16/M19 evidence files and their field names are preserved verbatim.
3. Typed Seam:
   - Enforce an explicit boundary between Omega and FORGE:
     ```
     Omega Realization Request
                ↓
     Forge Machine Descriptor
                ↓
     Forge lowering
                ↓
     AEGIS verification
                ↓
     Hardware submission
                ↓
     Forge execution evidence
     ```
4. Exit Gate:
   ```
   FORGE_TYPED_BOUNDARY_ENFORCED     PASS
   FORGE_REALIZE_API_NAMED           PASS
   AEGIS_VERIFY_API_NAMED            PASS
   HISTORICAL_NAMES_PRESERVED        PASS
   NO_EXISTING_FILE_RENAMED          PASS
   ```

**Owner:** Lane C (physics + omega + aien-architecture).
**Boundary:** New files/symbols only (`forge_realization.*`, `aegis_verification.*`, `ForgeMachineDescriptor`); must not rename, move, or delete any existing PHYSICS/OMEGA file, symbol, or evidence field, must not rename the `physics` repository, and must not remove `is_physics_authorized`.
**Failure behavior:** Any diff that renames or deletes an existing symbol/file referenced by a historical receipt fails the gate; the PR is rejected at review, not just at CI.
**Evidence:** `evidence/FORGE-0/<receipt-digest>.json`, plus a diff-scope check recorded in the PR showing zero renames/deletions of pre-existing files.

---

### Gate 4: FORGE-HWID - Make Hardware Claims Observational

Objective: Bind qualification evidence to physical hardware facts measured at runtime.

1. Canonical Machine and Hardware Probe:
   - Create a single hardware probe module. Receipts consume its structured output; receipts never accept hardcoded hardware strings.
   - Probe captures:
     - PCI vendor, device, and subsystem IDs
     - Driver reported compute class (`0xCEC0` for Blackwell GB10)
     - RM SM version (`0x0A04` for SM 10.04)
     - Driver and firmware version strings
     - Physical and unified memory topology
     - Hardware realization features supported
   - Compute a SHA-256 digest over the canonical descriptor (`ForgeMachineDescriptor`).
2. Derived Labels:
   - Treat semantic labels such as `"sm_121"` as derived aliases linked to the underlying `(compute_class, rm_sm_version)` measurement, per errata E-M19-10.
3. Exit Gate:
   ```
   RAW_HARDWARE_PROBE_CAPTURED      PASS
   FORGE_DESCRIPTOR_NORMALIZED      PASS
   DESCRIPTOR_DIGEST_BOUND          PASS
   RECEIPT_HARDWARE_DERIVED         PASS
   ```

**Owner:** Lane C.
**Boundary:** New probe module only; reads driver/RM state, writes nothing to existing receipt generators except through the new structured descriptor type.
**Failure behavior:** A receipt containing a hardware string not traceable to a probe digest fails the gate.
**Evidence:** `evidence/FORGE-HWID/<receipt-digest>.json`, containing the raw probe output and its SHA-256.

---

### Gate 5: OMEGA-NUMERIC-0 - FP32 Blackwell Machine Vocabulary

Objective: Construct and qualify a complete floating-point machine instruction set on GB10 before tensor operations.

1. SIMT FP32 Instruction Realization:
   - Implement codegen and encoder support for Blackwell FP32 instructions:
     - Load and store (global and shared memory)
     - `FADD`, `FSUB`, `FMUL`
     - `FFMA` (fused multiply-add)
     - `FSETP` (floating-point compare and predicate set)
     - `FMNMX` (minimum and maximum)
     - `MUFU` (multi-function unit: reciprocal, reciprocal square root) — **MUFU is allowed only as a seed input to a correctly-rounded division/square-root sequence (e.g. a Newton-Raphson refinement step defined by Omega); the raw MUFU output is never compared bit-exactly as a final result**, since its rounding behavior is not fully documented.
     - Conversion operations (`CVT` between integer and FP32)
     - Reduction primitives across warps — **warp reductions are qualified only under a declared, fixed summation order** (e.g. a specified pairwise-tree order); floating-point addition is not associative, so an unordered/hardware-scheduled reduction order is not bit-parity qualifiable and is out of scope here.
2. Transcendental Operations:
   - Implement Omega-defined polynomial approximation sequences for `exp` and `log`.
   - Zero dependence on host or vendor math runtime libraries (`libm`, CUDA math libraries).
3. Three-Tier Parity Verification:
   ```
   Semantic Reference == CPU Realization == GB10 Realization
   ```
4. Edge Class Coverage:
   - Positive and negative zero (`+0.0`, `-0.0`)
   - Positive and negative infinity (`+inf`, `-inf`)
   - Quiet and signaling NaNs
   - **Subnormals are preserved bit-exactly — flush-to-zero is explicitly rejected as a semantics.** (Gate 5's original text asked for both "subnormal representation" and "flush-to-zero semantics" verification, which are contradictory; this resolves it: subnormals must round-trip, FTZ behavior is a failure if observed.)
   - Exponent boundaries and overflow/underflow handling
   - Exhaustive deterministic pseudo-random vectors
5. Mixed precision (FP16, BF16, FP8) is barred until FP32 bit-parity is verified on silicon.
6. Exit Gate:
   ```
   FP32_SIMT_OPCODES_ENCODED        PASS
   OMEGA_MATH_SEQUENCES_QUALIFIED   PASS
   CPU_GB10_BIT_PARITY              PASS
   SUBNORMALS_PRESERVED_NO_FTZ      PASS
   MUFU_SEED_ONLY_NOT_COMPARED      PASS
   WARP_REDUCTION_ORDER_DECLARED    PASS
   EDGE_CLASS_BEHAVIOR_VERIFIED     PASS
   ```

**Owner:** Lane D (omega Blackwell codegen/encoder).
**Boundary:** `src/omega_blackwell_codegen.*`, `src/omega_blackwell_encoder.*`; does not touch tensor, autodiff, or search code.
**Failure behavior:** Any FTZ observation, any bit-exact comparison against a raw MUFU result, or any warp reduction without a declared fixed order fails the gate; mixed-precision code paths are rejected at review if introduced before this gate passes.
**Evidence:** `evidence/OMEGA-NUMERIC-0/<receipt-digest>.json`, including the three-tier parity trace per opcode and edge class.

---

### Combined Foundation Admission Gate (Gate 14 — scope narrowed per Decision A, 2026-09-27)

Before M20 (tensors) may begin drawing on GPU-side runtime or FP32 substrate work, the **foundation** — Gates 1 through 5 only — must satisfy:

```
[ ] EVIDENCE_IMMUTABLE                  PASS   (Gate 1)
[ ] RECEIPTS_OBSERVED_NOT_ASSERTED      PASS   (Gate 1)
[ ] DEVICE_MEMORY_LIFECYCLE             PASS   (Gate 2)
[ ] COMPLETION_EXACTLY_ONCE             PASS   (Gate 2)
[ ] LONG_RUNNING_GPU_SOAK               PASS   (Gate 2)
[ ] FORGE_BOUNDARY                      PASS   (Gate 3)
[ ] HARDWARE_ID_OBSERVED                PASS   (Gate 4)
[ ] FP32_CPU_GB10_PARITY                PASS   (Gate 5)
```

This gate does **not** include tensor, autodiff, optimizer, training, or holdout criteria. Those live in the milestone gates below (M20-M24), each independently qualified with its own receipt. Passing this gate means: the substrate is trustworthy enough to build GPU-side tensor/training work on. It does not mean any training-stack milestone is complete.

**Owner:** Program-level (all four foundation lanes jointly).
**Boundary:** Read-only aggregation of Gates 1-5 receipts; produces no new implementation, only a combined receipt referencing the four.
**Failure behavior:** If any of the eight criteria is not PASS, GPU-side M20+ work does not open (CPU-side work may still proceed — see dependency fix below).
**Evidence:** `evidence/GATE14-FOUNDATION/<receipt-digest>.json`, referencing the four constituent receipt digests.

---

## 3a. Milestone Gates M20-M24 (separately qualified; each has its own gate and receipt)

### Gate 6: OMEGA-TENSOR-0 - Immutable Semantic Tensors — Milestone M20

Objective: Define immutable tensor values and generation-tracked storage representations.

1. Semantic Layer:
   ```
   Tensor = immutable value
   ```
   Zero semantic in-place mutation. Every transformation produces a new tensor value.
2. Realization Layer:
   ```
   TensorValue -> TensorView -> StorageId + Generation
   ```
   - Physical storage recycling requires incrementing the storage generation counter.
   - Access via an outdated `TensorView` referencing an older generation fails deterministically.
3. Initial Primitive Set:
   - `create`
   - `reshape` / `view`
   - `elementwise` arithmetic (`add`, `sub`, `mul`, `div`)
   - `matmul` (fixed-tile path only — see Gate 7, deferred)
   - `reduction` (`sum`, `mean`, `max`)
   - `broadcast`
   - `transpose`
   - `compare_select`
4. Graph Construction Invariant:
   - Entire computation graph must be constructed and validated prior to execution dispatch. Zero eager partial execution during graph building.
5. Exit Gate:
   ```
   TENSOR_VALUE_IMMUTABLE           PASS
   STORAGE_GENERATION_ABA_SAFE      PASS
   PRIMITIVE_OPERATIONS_VERIFIED    PASS
   GRAPH_AOT_VALIDATION             PASS
   ```

**Owner:** Training-stack lane (omega), post-foundation.
**Boundary:** New tensor module; CPU-side realization may start without waiting on Lanes B/D (dependency fix, §4); GPU-side tensor kernels require Gate 14 (foundation) to have passed.
**Failure behavior:** Any successful mutation of a `TensorValue`, or any read through a stale `TensorView` that doesn't fail deterministically, fails the gate.
**Evidence:** `evidence/M20-TENSOR/<receipt-digest>.json` — this is M20's own qualification receipt, independent of Gate 14.

---

### Gate 8: OMEGA-AUTODIFF-0 - Omega-Producing Differentiation — Milestone M21

Objective: Generate backward computation graphs as first-class Omega programs without a separate runtime.

1. Pure Symbolic Differentiation:
   ```
   Omega Forward Graph -> Differentiator -> Omega Backward Graph
   ```
   - Derivative generation uses symbolic differentiation rules over Omega primitives.
   - The resulting backward graph is submitted to FORGE, verified by AEGIS, and realized through the identical hardware execution pipeline. (Hardware realization path only; ADR 0016 Amendment 1.)
   - Core Invariant: Training computation is standard Omega computation.
2. Numerical Verification:
   - Compare analytical gradients against double-precision finite differences on small graphs.
   - Verify trivial analytic targets: identity, linear combination, quadratic bowl, cross-entropy loss.
3. Exit Gate:
   ```
   SYMBOLIC_BACKWARD_GENERATED      PASS
   BACKWARD_IS_STANDARD_OMEGA       PASS
   FINITE_DIFFERENCE_MATCH          PASS
   ANALYTIC_ORACLE_MATCH            PASS
   ```

**Owner:** Training-stack lane. CPU-side symbolic differentiation and the finite-difference oracle may start without waiting on Lanes B/D (dependency fix, §4); silicon realization of the backward graph requires Gate 14.
**Boundary:** New autodiff module, consumes M20's tensor graph; does not modify Gate 6 primitives.
**Failure behavior:** Any analytic/finite-difference mismatch beyond a pre-declared tolerance fails the gate.
**Evidence:** `evidence/M21-AUTODIFF/<receipt-digest>.json`.

---

### Gate 9: OMEGA-OPT-0 - Transactional Optimizer State — Milestone M22 (part 1)

Objective: Implement atomic parameter updates using isolated shadow state generations.

1. Transactional Update Cycle:
   ```
   ParameterGeneration N
          ↓
   Create shadow generation N+1
          ↓
   Forward pass
          ↓
   Backward pass
          ↓
   Optimizer writes to shadow state N+1
          ↓
   Validation and invariant checks
          ↓
   Record commit receipt
          ↓
   Atomic generation switch (N -> N+1)
   ```
2. Failure Invariant:
   - Any failure or aborted check prior to the atomic switch leaves generation N intact.
   - State is either fully OLD or fully NEW; partial updates are structurally impossible.
3. Injected Fault Testing:
   - Inject deliberate faults at every phase boundary: pre-forward, post-forward, mid-backward, post-backward, mid-optimizer-write, pre-commit.
   - Verify that generation N parameters remain uncorrupted after every injected fault.
4. Exit Gate:
   ```
   TRANSACTIONAL_SHADOW_UPDATE      PASS
   ATOMIC_GENERATION_SWITCH         PASS
   FAULT_INJECTION_STABILITY        PASS
   ZERO_PARTIAL_UPDATE              PASS
   ```

**Owner:** Training-stack lane.
**Boundary:** New optimizer module, consumes M21's backward graph and M20's tensors; requires Gate 14.
**Failure behavior:** Any observed partial-update state after an injected fault fails the gate.
**Evidence:** `evidence/M22-OPTIMIZER/<receipt-digest>.json`.

---

### Gate 10: TRAINING-PROVENANCE-0 - Two-Tier Provenance Architecture — Milestone M22 (part 2)

Objective: Provide cryptographic execution and state traceability without excessive hashing overhead.

1. Tier 1: Per-Launch Execution Provenance
   - Captured per kernel dispatch:
     - Operation identity
     - Input and output object identifiers
     - Realization identifier
     - Tensor shapes and memory layouts
     - Forge machine descriptor digest
     - Monotonic dispatch sequence ticket
     - Execution status and completion code
2. Tier 2: Per-Commit State Provenance
   - Captured at committed optimizer step boundaries:
     - Complete parameter state digest
     - Complete optimizer state digest
     - Predecessor generation index and digest
     - Resulting generation index and digest
     - Training batch reference and dataset offset
     - Loss and evaluation metric state
3. Invariant: Execution provenance verifies kernel dispatch; state provenance verifies model evolution.
4. Exit Gate:
   ```
   EXECUTION_PROVENANCE_CAPTURED    PASS
   STATE_PROVENANCE_COMMITTED       PASS
   HASH_OVERHEAD_BOUNDED            PASS
   ```
   - **HASH_OVERHEAD_BOUNDED definition:** provenance hashing (both tiers combined) adds ≤ 5% to measured wall-clock step time, averaged over a representative training step count (≥ 1,000 steps), measured with hashing on vs. off on the same hardware and batch configuration.

**Owner:** Training-stack lane.
**Boundary:** Instruments Gate 9's commit path and Gate 6/8 dispatch path; does not change their semantics.
**Failure behavior:** Overhead > 5% fails the gate; provenance is then optimized (e.g. incremental hashing) before re-attempting, not disabled.
**Evidence:** `evidence/M22-PROVENANCE/<receipt-digest>.json`, including the on/off timing comparison.

---

### Gate 13: OMEGA-SYNTHESIS-1 - Expanded Instrumented Search Module — prerequisite for M23

Objective: Scale program synthesis exploration as a parallel research track with rich search telemetry, in a new module that does not touch the existing M9-M11 synthesis gates.

1. Search Instrumentation (new module `src/search/`):
   - Instrument candidate exploration to record detailed telemetry for every node:
     - Parent node identifier
     - Applied transformation
     - Search depth
     - Semantic properties
     - Estimated execution cost
     - Verifier outcome
     - Machine realization outcome
     - Execution performance
     - Reason for pruning or abandonment
     - Reason for success or failure
2. Scaled Search Space:
   - Expand candidate limits beyond the existing `omega_synthesis.*` caps (depth 3, 512 candidates) inside the new module — the old module and its M9-M11 gates are untouched.
3. Separation of Concerns:
   - The learned ranking model proposes candidate paths to explore.
   - Deterministic verification retains absolute authority over semantic validity.
4. Exit Gate:
   ```
   SYNTHESIS_TELEMETRY_LOGGED       PASS
   SEARCH_ENVELOPE_EXPANDED         PASS
   PROPOSAL_VERIFIER_SEAM_CLEAN     PASS
   OMEGA_SYNTHESIS_UNTOUCHED        PASS
   ```
   - **SEARCH_ENVELOPE_EXPANDED definition:** search depth ≥ 6, ≥ 70 distinct primitives available, and the exploration budget calibrated so that *baseline* (unguided) search success on a fixed calibration task set lands in the 40-60% range — neither trivially easy nor effectively unsolvable — so that a learned guide has genuine room to demonstrate improvement in M23.

**Owner:** Lane E.
**Boundary:** `src/search/` only; must not edit `src/omega_synthesis.*` or `src/omega_discovery.*`.
**Failure behavior:** Any diff touching the two protected files fails the gate at review, independent of test results.
**Evidence:** `evidence/OMEGA-SYNTHESIS-1/<receipt-digest>.json`, including the calibration-set baseline success rate.

**Dependency:** this gate is a prerequisite of AIEN_0 training (Gates 11/12, M23/M24) — those milestones cannot start without a passing `OMEGA-SYNTHESIS-1` receipt, since there is no guided-vs-baseline comparison possible without the expanded, telemetered search space.

---

### Gate 11: AIEN_0 - Smallest Model Validating the Architectural Thesis — Milestone M23 (search-guide training)

Objective: Train a minimal model that learns to score candidate operations in search space, using the Gate 13 search module.

1. Architecture and Scale:
   - Target parameter budget: approximately 99k parameters. Parameter count serves as an upper bound, not a dogmatic constant.
2. Learning Objective:
   ```
   State + Available Next Operations + Target Objective
                          ↓
                        AIEN_0
                          ↓
             Score(Candidate Next Operation)
   ```
3. Input-Visible Semantics:
   - Primitive operation semantics must be exposed as input representations so the model scores unseen but describable candidates based on semantic properties.
4. Exit Gate:
   ```
   AIEN_0_CONVERGENCE               PASS
   SEMANTIC_OPERATION_SCORING       PASS
   GENERALIZATION_TO_UNSEEN_OPS     PASS
   ```
   - **None of these three is "loss went down."** AIEN_0's convergence and scoring criteria are measured by the same guided-vs-baseline search-cost comparison defined for M24 (below), run on a *training-visible* task set (not the sealed holdout) to confirm the model is learning something usable before the one-shot holdout evaluation is spent.

**Owner:** Training-stack lane. Requires Gate 13 (OMEGA-SYNTHESIS-1) and Gates 8/9/10 (M21/M22) to have passed; requires Gate 14 (foundation) for any silicon-realized training.
**Boundary:** New training-loop module; consumes M20-M22 and Lane E's search module; does not modify any of them.
**Failure behavior:** A model that reduces loss but does not improve guided search cost over baseline on the training-visible task set does not pass this gate.
**Evidence:** `evidence/M23-SEARCH-GUIDE-TRAIN/<receipt-digest>.json`.

---

### Gate 12: AIEN_0-HOLDOUT - Cryptographically Sealed Evaluation — Milestone M24

Objective: Pre-register evaluation holdouts to eliminate post-hoc metric tuning, and produce the final AIEN_0 qualification.

1. Pre-Registration Commitment:
   - Commit the following parameters to the repository prior to launching the final training run:
     - Evaluation generator version
     - Holdout seed commitment (SHA-256 hash)
     - Target evaluation metrics
     - Required pass/fail thresholds — **stated as concrete numeric thresholds, pre-registered in the M24 spec document before the final training run begins; not decided after seeing results.**
     - Allowed training dataset bounds
     - Model architecture specification
     - Optimizer hyperparameter schedule
     - Maximum training compute budget
     - Disallowed operational contexts
2. **The comparison being evaluated is named explicitly:** AIEN-guided search cost vs. baseline (unguided) search cost, on the *same* held-out task set, both run through the Gate 13 search module. Success is a pre-registered reduction in search cost (e.g. nodes expanded, or wall-clock, to reach a valid program) for the guided policy relative to baseline — never "loss went down."
3. **Benchmark validity step:** the Gate 13 calibration (baseline success 40-60% on the calibration set) is performed and recorded *before* training starts, so the holdout task set is known to be neither trivial nor unsolvable for the baseline.
4. **Holdout/training exclusivity:** any holdout task whose signature overlaps a training-set task signature is excluded from the holdout set before the seed is revealed; this exclusion check is itself part of the pre-registration record.
5. Execution Sequence:
   ```
   Commit holdout seed hash
              ↓
   Execute training run
              ↓
   Freeze candidate model digest
              ↓
   Reveal holdout seed
              ↓
   Generate evaluation dataset (excluding any training-overlapping task signature)
              ↓
   Evaluate candidate once (guided vs. baseline search cost)
              ↓
   Generate immutable qualification receipt
   ```
6. Invariant: Evaluation thresholds are immutable once training commences.
7. Exit Gate:
   ```
   PRE_REGISTRATION_COMMITTED       PASS
   BENCHMARK_VALIDITY_CALIBRATED    PASS
   HOLDOUT_TRAIN_DISJOINT           PASS
   SEED_REVEAL_VERIFIED             PASS
   ONE_SHOT_EVALUATION_PASS         PASS
   HOLDOUT_RECEIPT_IMMUTABLE        PASS
   ```

**Owner:** Training-stack lane.
**Boundary:** Consumes the frozen M23 candidate model; performs exactly one holdout evaluation; does not retrain on holdout failure.
**Failure behavior:** A holdout failure does not permit threshold adjustment; the candidate is rejected and a new M23 training run (with the same pre-registered thresholds, or a newly pre-registered set for a new attempt) is required.
**Evidence:** `evidence/M24-HOLDOUT/<receipt-digest>.json`, including the pre-registration commitment and the guided-vs-baseline search-cost numbers.

---

## 3b. Deferred — Post-M24, Not On the Critical Path

### Gate 7: OMEGA-TENSOR-1 - Generalize Tensor-Core Realization (MOVED OUT OF CRITICAL PATH)

**This gate is removed from the Combined Foundation Admission Gate and from the M20-M24 critical path.** Rationale: NVIDIA tensor cores accept FP16/BF16 inputs and accumulate with an undocumented internal add order. That is incompatible with the FP32 bit-parity requirement of Gate 5 and with this plan's own mixed-precision ban (§Gate 5, item 5). A ~99k-parameter AIEN_0 model (Gate 11/M23) does not need general tensor-core MMA tiling — the fixed-tile FP32 path from Gate 6 is sufficient. This work is deferred to a later, explicitly-scoped milestone after M24, if and when a larger model's compute needs justify reopening the mixed-precision question as its own decision.

Objective (deferred): Remove fixed-dimension restrictions and establish tiled execution for arbitrary matrix dimensions.

1. Generalized Matrix Multiplication:
   - Eliminate the `K == 16` restriction.
   - Implement a multi-level tiling pipeline:
     ```
     Semantic MatMul
           ↓
     Shape Analysis
           ↓
     Tiling Plan
           ↓
     Edge and Tail Decomposition
           ↓
     Tensor-Core MMA Tiles + FP32 Edge Kernels
           ↓
     Accumulated Result
     ```
2. Qualification Envelope:
   - Non-ideal dimensions where M, N, or K are not multiples of tile size.
   - Asymmetric aspect ratios (tall-skinny, short-wide).
   - Single-element dimensions and prime dimension sizes.
3. Exit Gate (deferred, not evaluated for M20-M24 admission):
   ```
   GENERAL_SHAPE_DECOMPOSITION      PASS
   MMA_TILE_ACCUMULATION            PASS
   ARBITRARY_DIMENSION_PARITY       PASS
   ```

**Owner:** Unassigned (post-M24).
**Boundary:** Not scheduled; do not start this work under an M19R or M20-M24 lane.
**Failure behavior:** N/A — deferred.
**Evidence:** N/A — deferred.

---

## 4. Staged Execution Dependency Map

Dependency fixes (2026-09-27 revision):
- **Lane A (evidence) must land before any other gate's receipt is produced.** Every gate's exit criteria depend on the derived-not-asserted receipt schema from Gate 1; a Gate 2-13 receipt produced against the old (literal-constant) schema is not valid evidence.
- **Lane E (search/traces, Gate 13) is a prerequisite of AIEN_0 training (Gates 11/12, M23/M24)**, not a parallel independent track all the way to the end — it must reach its own exit gate before M23 can start.
- **CPU-side tensor and autodiff work (Gates 6 and 8) may start without waiting for Lanes B/D.** Nothing about immutable tensor values, storage generations, or symbolic differentiation requires the GPU runtime fixes (Lane B) or the FP32 Blackwell ISA (Lane D) — those are only required before *silicon-realized* execution of tensor/autodiff graphs, not before the CPU-realized semantic and correctness work.

```
LANE A (Evidence)        LANE B (Runtime)      LANE C (Forge/HWID)  LANE D (FP32)      LANE E (Search)
       |                        |                     |                  |                   |
  [must land first]        Stabilized            Stabilized          Stabilized              |
       |                        \                     |                 /                    |
       |                         +-------------------+------------------+                     |
       |                                             |                                       |
       |                              Combined Foundation Admission Gate                     |
       |                                  (Gate 14 — Gates 1-5 only)                          |
       |                                             |                                       |
       |             CPU-side M20/M21 work may start earlier, in parallel with Lane B/D       |
       |                                             |                                       |
       |                                    M20: Gate 6 (Tensors, silicon)                    |
       |                                             |                                       |
       |                                    M21: Gate 8 (Autodiff, silicon)                   |
       |                                             |                                       |
       |                            M22: Gates 9, 10 (Optimizer + Provenance)                 |
       |                                             |                                        |
       |                                             +----------------------------------------+
       |                                             |                        (Gate 13 exit required)
       |                                    M23: Gate 11 (Search-Guide Train)
       |                                             |
       |                                    M24: Gate 12 (AIEN_0 + Holdout)
       |                                             |
       +---------------------------------------------+
                  (Gate 1 receipt schema underlies every receipt above)
```

Gate 7 (general tensor-core MMA tiling) does not appear on this map — it is deferred (§3b) and not a dependency of M20-M24.

---

## 5. Repository Assignments and Branch Standards

### Branch Allocations

- `omega`:
  - `refactor/m19r-lane-a-evidence`: Receipt generation, immutable receipt store, observed execution counts.
  - `fix/m19r-lane-b-runtime`: World memory revocation, monotonic ticket completion, state machine.
  - `feat/m19r-lane-d-fp32`: Blackwell SIMT FP32 instruction codegen, polynomial exp/log, bit parity suite.
  - `feat/m19r-lane-e-search`: New `src/search/` module, candidate telemetry collection.
- `physics`:
  - `fix/m19r-lane-b-nvrm-free`: Implementation of `nvrm_free` via `NVOS00_CTRL_CMD_FREE`.
  - `feat/m19r-lane-c-forge`: `ForgeMachineDescriptor`, raw hardware observation probe, FORGE/AEGIS seam types.
- `aien-architecture`:
  - `docs/m19r-gated-recovery`: Architectural updates, gate definitions, schema standards.

### Remote Requirement (revised per Decision C, 2026-09-27)

GitHub `origin` is the only required remote for branch pushes, PRs, and merges at this time. No `forgejo` remote exists in any checkout as of 2026-09-27. The mandatory dual-push rule is dropped until a forgejo server/remote is actually provisioned; if and when one exists, this section is revised to reinstate a dual-push (or mirrored-push) requirement with SHA-equality verification.

---

## 6. Also Required (Cross-Cutting Requirements)

These apply across every gate above, in addition to each gate's own exit criteria:

- **Checkpoints, crash recovery, and resume equivalence.** Any training run (M22 optimizer commits onward, M23/M24) must checkpoint parameter and optimizer generation state such that a kill-and-resume produces the same continuation (bit-identical, or an explicitly documented equivalence class) as an uninterrupted run. Tested by an actual kill-and-resume, not by inspection.
- **Training determinism.** Same inputs (seed, data order, hardware, code) produce the same weights, byte-for-byte, verified by two independent full runs before any M23/M24 result is trusted.
- **Dataset construction, train/test split by task signature, label verification.** M23/M24 datasets are split by task signature, not by random row assignment, so that near-duplicate tasks cannot leak across the split; labels/ground truth are verified (not merely generated) before use.
- **Memory aliasing / planner checks.** The tensor storage planner (M20) must prove at graph-build time that no two live `TensorView`s alias the same physical storage across a generation boundary — since in-place mutation is banned (Gate 6), any observed aliasing is a planner bug, not a legitimate optimization, and must fail closed.
- **Fail-closed out-of-range index handling.** Any indexing primitive (reshape, view, gather, etc.) presented with an out-of-range index rejects the operation at graph-build or dispatch time. It never wraps, clamps, or silently reads adjacent memory.
- **Exact-commit, clean-worktree qualification procedure.** Every gate's receipt is generated from a clean worktree (`git status --porcelain` empty) checked out at one exact, recorded commit per repository involved (omega, physics). A dirty worktree fails the gate before any test runs.
- **Derived cumulative regression counts.** Every "cumulative gates passed" / "total gates evaluated" field in every receipt (not just Gate 1's own) is computed by summing actually-executed suite results at receipt-generation time. Writing a literal constant for these fields fails the gate that produced it.
- **Guard against agents weakening tests.** Any change that deletes, skips, or loosens the threshold of an existing passing gate or test requires an explicit, recorded operator-approved waiver in the same evidence-only commit category as Gate 1's evidence commits. A PR that both touches test/gate code and claims a gate pass is flagged for mandatory human review before merge.
- **Owner / Boundary / Failure behavior / Evidence for every gate.** Each gate section above states these four fields explicitly; a gate specification lacking any of the four is incomplete and is not eligible to be exit-checked until amended.
