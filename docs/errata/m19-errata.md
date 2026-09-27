# M19 Errata

Status: M19 REOPENED / IN PROGRESS (2026-09-27) — closes via the M19R Foundation Recovery Program.
Scope: M19 (`OMEGA_ACCELERATOR_RESIDENT`) is REOPENED / IN PROGRESS. This document records where the M19 qualification receipt asserted or under-enforced a property rather than deriving or enforcing it from observed execution, and names the M19R recovery gate (see `docs/m19r-recovery-program.md`) that must pass for each gap to close. M19 re-closes when the M19R Combined Foundation Admission Gate passes; M20 opens only after that.

Source: `aien-architecture/docs/AIEN_M20_M26_ENGINEERING_PLAN.md` §0 (Findings that change the plan) and §1 (Current-state checkpoint), as read on 2026-09-27.

**Independent rerun fact (corroboration, applies to all errata below):** on 2026-09-27, all 175 gates (M4-M19) were re-executed and passed at `omega ae2476d` on this DGX Spark, with the rebuilt binary's SHA-256, the M18 manifest digest, and M19's rolling state digest reproduced byte-for-byte against the values already committed in the M18/M19 receipts. This is independent, on-silicon corroboration that the 157 prior gates (M4-M18) and the 18 M19 gates did in fact execute and pass. It does not, on its own, establish that every receipt field was *derived* rather than asserted, or that the architectural gaps below are closed — that is what the errata and the M19R gates below are for.

---

### E-M19-1 — PHYSICS/OMEGA boundary is a source-ownership boundary, not an authority boundary

- **What M19 proved:** Omega links directly against PHYSICS source (`physics/m16/m16_native.c`, `physics/nvrm/nvrm.c`) and drives real GPFIFO submission, doorbell rings, and completion semaphores on physical DGX Spark GB10 silicon. The execution path works.
- **The gap:** the M15 PHYSICS accelerator authority model (`ACCEL_OP_MAP_DMA`/`SUBMIT`/`RESET`, decision codes, effect receipts) is referenced nowhere in Omega. `OmegaAcceleratorWorld` embeds `M16NativeContext` and raw `NvrmMem` directly. What the architecture calls an authority boundary is, in the code, just which repository a file happens to live in — there is no typed seam a request must pass through.
- **Gate that closes it:** Gate 3, FORGE-0 (FORGE realize / AEGIS verify seam), in `docs/m19r-recovery-program.md`. It introduces the typed `Omega Realization Request -> Forge Machine Descriptor -> Forge lowering -> AEGIS verification -> Hardware submission` seam as new, additive code, without renaming or removing any existing PHYSICS/OMEGA file or symbol, the `physics` repository name, or `is_physics_authorized`.

### E-M19-2 — GPU device memory has no deallocation path

- **What M19 proved:** repeated allocate/use/revoke cycles on a fixed, unchanging set of buffers ran for >= 1,000 heterogeneous operations without observed CPU-RSS growth.
- **The gap:** `nvrm.h` exposes `nvrm_alloc` but no `nvrm_free`. `omega_world_revoke_buffer` flips a slot's `active` flag and bumps its generation counter but never releases the underlying `NvrmMem`; the next `register_buffer` on that slot overwrites `entry->mem` without freeing the old allocation. M19's own gate measured CPU RSS on fixed buffers, which cannot see device-side VA/physical-memory leaks. Any workload that churns buffer storage (tensors will) leaks without bound.
- **Gate that closes it:** Gate 2, M19R-RUNTIME, in `docs/m19r-recovery-program.md`. It adds an explicit `nvrm_free` API, a `RETIRING` quarantine state before release, and a `LONG_SOAK_NO_DEVICE_LEAK` exit criterion measured directly against driver handle count and VA high-water mark, not process RSS.

### E-M19-3 — the M19 receipt asserts a regression count it did not execute

- **What M19 proved:** M19's own 18 gates executed and passed, and the M19 gate runner does invoke the M18 gate suite as a nested regression check.
- **The gap:** that nested call chain (`run_m18_gates()` -> `run_m17_gates()`) stops at M17; only 36 of the 157 previously-qualified gates actually execute during an M19 run. The receipt nonetheless writes `"cumulative_regression_passed": 157` and `"total_gates_evaluated": 175` as fixed literal constants, not as counts of gates the M19 run itself observed passing.
- **Gate that closes it:** Gate 1, M19R, in `docs/m19r-recovery-program.md`. Its `RECEIPT_COUNTS_DERIVED` criterion and the cross-cutting "derived cumulative regression counts" requirement (§6) require every cumulative-count field in every future receipt to be computed by summing suites actually executed at receipt-generation time; a literal constant fails the gate.

### E-M19-4 — other receipt fields are literal claims, not measurements

- **What M19 proved:** the qualification harness runs against real hardware and produces a receipt with plausible-looking operational fields.
- **The gap:** several fields are written as fixed constants or silent fallback defaults rather than measured values: `"cycles": 250`, `"parity_error_count": 0`, `"ring_wrap_factor": 3.0`, all `fault_recovery` booleans, and fallback defaults of `1024`/`3072`/`1000` written whenever a measured value comes back zero. `"m19_gates_passed": 18` is written from inside Gate 18 itself, i.e. before the run it describes has finished.
- **Gate that closes it:** Gate 1, M19R. Its receipt-schema requirement ("Derive all receipt fields strictly from observed execution") applies to every field, not only the headline gate counts; a field with a hardcoded fallback default fails the gate.

### E-M19-5 — the digest-fold determinism gate does not prove dispatch is bound to real execution

- **What M19 proved:** M19 Gate 14 shows the rolling-digest fold function is deterministic when fed synthetic identities `{1, 2, 3}`. M19 Gate 8 partly strengthens this by requiring a non-zero sustained digest across the real 1,000-operation workload.
- **The gap:** determinism on synthetic inputs is a property of the hash function, not evidence that the digest is actually bound to what the hardware executed. Nothing in M19 independently proves the rolling digest tracks real dispatch provenance rather than, say, a counter.
- **Gate that closes it:** Gate 10, TRAINING-PROVENANCE-0, in `docs/m19r-recovery-program.md` (Tier 1 per-launch execution provenance, bound to realization identifiers and Forge machine descriptor digests actually produced per dispatch), building on Gate 1's requirement that realization and runtime identity fields be observed, not asserted.

### E-M19-6 — regression reruns silently rewrite historical qualification records

- **What M19 proved:** the qualification and regression suites are runnable end-to-end and reproducible byte-for-byte on this DGX Spark (see the independent rerun fact above): rebuilding at `ae2476d` reproduced the M18 manifest digest and M19's rolling state digest exactly.
- **The gap:** running that same regression is destructive. It rewrote `evidence/omega_blackwell_matmul_stage2_receipt.json` (M18's binary/manifest digests and timestamp) and rewrote `evidence/omega_accelerator_world_qualification_receipt.json`, changing `candidate_git_commit` from `beaa118…` (the qualified implementation commit) to `ae2476d…` (the merge commit the rerun happened to execute at). A routine regression run can silently rebind a historical qualification to a different commit. Receipts also never record the PHYSICS commit compiled into the binary, even though PHYSICS source is compiled directly into `omegatool`.
- **Gate that closes it:** Gate 1, M19R. `HISTORICAL_RECEIPTS_IMMUTABLE` (existing evidence files are never overwritten) and `CANDIDATE_COMMIT_BOUND_NOT_HEAD` (the receipt binds the candidate commit supplied to the harness, never `git rev-parse HEAD` at rerun time) together make this class of bug structurally impossible; the PHYSICS commit is additionally captured via Gate 4, FORGE-HWID's hardware/build descriptor.

### E-M19-7 — batched-dispatch safety lives in test code, not in the enforced world API

- **What M19 proved:** the batched submission path (pushbuffer pool slots, slot reuse after retirement, QMD/cbank assembly) works correctly when driven the way M19's own gates drive it.
- **The gap:** that correctness depends on caller discipline implemented in the gate/test code (`omega_world_gates.c`), not on an invariant the world itself enforces. A future caller (e.g. a tensor runtime) that reuses a pushbuffer slot without replicating that same discipline would silently corrupt in-flight work.
- **Gate that closes it:** Gate 2, M19R-RUNTIME. Its strict per-dispatch state machine (`Created -> Submitted -> InFlight -> Completed -> Committed`, forward-only, `Committed` reachable exactly once) is enforced inside the world API itself, so retirement-safe reuse no longer depends on caller discipline.

### E-M19-8 — the completion protocol has two payload authorities and unsafe equality waits

- **What M19 proved:** completion detection works for the synchronous and batched dispatch paths individually, each exercised on their own in M19's gates.
- **The gap:** `m16_native_wait_marker` waits for exact equality (`*marker == expected`), not a monotonic `>=`; synchronous dispatch resets the marker to `0` from the CPU mid-run; batched submit uses a separately caller-supplied `completion_val`; and `drain`'s error paths can partially compact `in_flight` without updating `in_flight_count`, so a retry can commit the same dispatch twice, double-counting `total_dispatches` and double-folding the provenance digest. Mixing the synchronous and batched paths while work is in flight is unsafe.
- **Gate that closes it:** Gate 2, M19R-RUNTIME. Monotonic ticket comparison (`>=`), no CPU-side marker resets during active operation, a single completion authority, and an adversarial test matrix (duplicate/skipped/stale marker observations, timeout-races-completion, error-after-success, teardown-during-in-flight) directly targets this class of bug.

### E-M19-9 — spec-to-code binding is not enforced at dispatch

- **What M19 proved:** `omega_world_dispatch_matmul` successfully dispatches matching spec/code pairs in every case M19's gates exercise.
- **The gap:** `spec` and `code_handle` are accepted as independent parameters, and the dispatch path never checks that the supplied code was actually realized for that spec. A mismatched pair is not rejected by the world; it is simply not tested.
- **Gate that closes it:** Gate 3, FORGE-0. The typed seam's AEGIS verification step sits exactly at this boundary — it verifies the Forge machine descriptor and lowered code correspond to the Omega realization request before hardware submission, rather than trusting the caller to have paired them correctly.

### E-M19-10 — hardware identity in receipts is a string literal, not an observation

- **What M19 proved:** M19 ran, and did run, on a machine PHYSICS's own RM query correctly characterizes: compute class `0xCEC0`, RM SM version `0x0A04` (`NV2080_CTRL_GR_INFO_SM_VERSION_10_04`), as shown in PHYSICS's own M16 logs.
- **The gap:** receipts write `"sm_121"` verbatim as a hardcoded string rather than deriving it from that RM query. Nothing in either repository records how RM's GR SM version relates to the "sm_121" compute-capability name, or checks that relationship at qualification time. This is not a defect in what executed — the hardware really is what M19 says it is — it is a defect in what the receipt claims to bind.
- **Gate that closes it:** Gate 4, FORGE-HWID. `HardwareIdentity` binds the observed `(compute_class, rm_sm_version, gpu_uuid)` triple from a single canonical hardware probe module, with `"sm_121"` demoted to a documented derived alias rather than a receipt-level literal.
