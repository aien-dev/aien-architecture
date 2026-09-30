# Belief Estimation - Current State

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0020 (ARCH-0020), the belief / estimation layer. `CURRENT_EXECUTION_PLAN.md` owns sequencing and `doctrine/ROADMAP.md` owns milestone status. Nothing in this document is a milestone.

**Written:** 2026-09-30, before any estimation code existed. Facts come from three read-only audits of the commits below. Code was read; README and spec claims were not taken as evidence. Nine claims were re-checked by hand (section 7).

| Repository | Commit |
|---|---|
| aien-dev/omega | `6b9d4b7` (main; `b608dff` after a docs-only merge during the audit) |
| aien-dev/aien-architecture | `ede9f16` |
| aien-dev/aienos | `f0facc7` |
| aien-dev/physics | `f63a6ef` |

Status words: IMPLEMENTED, PARTIAL, EXPERIMENTAL, PLANNED, MISSING, CONFLICTING, OBSOLETE. "Host reference" means C code exercised by tests but not wired into a live service.

## 1. Headline

- No belief state, state estimate, covariance, innovation or Kalman code exists in any of the four repositories (grep for `kalman`, `covariance`, `innovation`, `BeliefState`: zero hits). The layer is **MISSING** and must be built.
- Three existing pieces already do part of the job and must be reused, not shadowed: the Omega cost model (a Bayesian predictor with calibrated intervals), the TURING PRD1 prediction file plus qint.v1 scorer (a predicted Gaussian per held-out point, scored in bits), and the TURING CAL-0 freeze and blinding machinery.
- R16 is at W4 of W11. W1 spec, W2 retirement map and W4 loop inventory are merged (omega `6fdc4c3`, PR #68); the W3 fix PRs #62-#65 are merged; W5-W11 are not started (no `rx_r16` tests, `evidence/R16/` holds only `inventory.json`). The `src/runtime/` edit hold stays in force.

## 2. Concept inventory

| Concept | Status | Where | Note |
|---|---|---|---|
| Observation as typed evidence | PARTIAL | aienos `native/argus/argus_abi.h:218-237` (128-byte ARGUS event, evidence_digest, logical tick, no wall clock); FORGE v2 `forge/v2/forge_substrate_v2.h:328-355` (EXPERIMENTAL, reference model only) | Events are security observations, not numeric measurements with declared noise. |
| Belief / state estimate | MISSING | none | |
| Covariance / uncertainty with declared units | MISSING (as a state quantity) | | Uncertainty exists only as the per-prediction fields below. |
| Prediction distribution | IMPLEMENTED (two narrow forms) | omega `src/runtime/rx_costmodel.h:79-88` (`RxCmPrediction`: mean and sd of log2 ps, Student-t dof, `fail_p` Beta posterior mean, point energy); `src/turing/ty_prd.h:1-4` (PRD1: per index u32 family, f64 loc, f64 scale, Gaussian only) | Neither carries a state vector or covariance. |
| Innovation / residual | MISSING as a type | | TURING scores code length, not residuals. |
| Normalized surprise | MISSING | | |
| Transition / observation model identity | MISSING | | Cost model identity is its blob digest (`rx_costmodel.c:422-443`, magic OGCM v1). |
| Estimator | PARTIAL | cost model is a conjugate Bayesian regression per (cell, arm), `rx_costmodel.h:21-28` | Static regression, not a dynamic state estimator. |
| Calibration of stated uncertainty | IMPLEMENTED (cost model); IMPLEMENTED (engine confidence) | `rx_cm_calibrate`, `rx_costmodel.c:385-411` (split conformal on held-out residuals, needs 10+ points); `rx_route.h:68,120` (`RxCogCalibration`, per-bin hit rate of an engine's stated confidence) | Both are reusable patterns for EST-3; neither calibrates a dynamic estimate. |
| Calibration protocol, freeze, blinding | IMPLEMENTED | omega `calibration/` (CAL-0, PR #92): `BLINDING_PROTOCOL.md`, `scripts/freeze_receipt.sh`, `schemas/*.json`, independent-scorer rule | The statistic (code length vs baseline) does not transfer; the freeze and blinding machinery does. |
| Evidence root / digest | PARTIAL | `src/omega_evidence.h` (write-once content-addressed files under `build/qual-runs/<run>/`); `src/turing/ty_qrecord.h:10` (digest = SHA-256(domain, 0x00, bytes)) | No single evidence-root type. ARCH-0020 adopts the TURING domain-separated digest rule. |
| World generation, staleness | IMPLEMENTED | `src/runtime/rx_world.h:292-316` (per-field version and writer), `:172` (`RxObjRef{id,generation}`), `rx_world.c:1180-1195` (stale read refused at publish) | World objects hold eight u64 fields and no doubles (`rx_world.h:34`), so a covariance cannot live in one object. EST-4 decides the encoding. |
| External input path into World | IMPLEMENTED | `rx_world_publish_external`, `rx_world.h:604-608` (capability required) | Natural entry for observations in EST-4. |
| State Projection with uncertainty | PARTIAL | `rx_projection.h:78` (NONE / POINT / INTERVAL request), `:137-143` (count, sum, sumsq, min, max) | `PJ_OP_PREDICT` exists as a label only (tests use it). |
| Uncertainty transport | CONFLICTING (wording) | `rx_semcomm.h:26`: "Omega does not estimate uncertainty. A type may declare one field as its producer's uncertainty" | Not a real conflict: an estimator is a producer. ARCH-0020 records that the estimation layer is that producer and that semcomm stays a transport. |
| Read-only observation tap | MISSING | ARGUS rings are single producer, single consumer; `argus_ring_pop` consumes (`argus_abi.h:506`) | An estimator must never pop a producer ring. A live feed needs a second, read-only ring filled by the ARGUS consumer (EST-4 scope). |
| Estimator isolation from authority | IMPLEMENTED pattern | omega `Makefile:716-720` (`nm -u` refusal for the cost model); aienos `argus_contain.c:293` (containment only on DETERMINISTIC confidence) | No numeric confidence reaches authorization today. One injection point exists: `AienosContainAuthorizer.decide` (`aienos_contain.h:223-227`). Record as a watch item. |
| J-Space | IMPLEMENTED (host reference), not wired | omega `src/runtime/rx_jspace.c/.h`; spec `docs/06-jspace.md:50-62` (separate score dimensions incl. uncertainty, Pareto filter) | `docs/02-implementation-status.md:35` (dated 2026-09-23) still says no implementation. Discrepancy recorded. |
| Cortex | IMPLEMENTED (host reference), not wired | omega `src/runtime/rx_cortex.c/.h` (`CX_OBSERVATION` class, protection bits `rx_cortex.h:38-50`) | |
| TURING T unit, held-out scoring | IMPLEMENTED | omega `docs/turing/TURING_YIELD_PROFILE_V0.md:21-29`; `src/turing/ty_qcont.h`; records `turing.q*.v0` | qworld (`ty_qrecord.h:64-77`) has no evidence-root field; adding one needs a v1 domain. |
| Information-gain experiment selection | PLANNED | `doctrine/DISCOVERY.md:273-274,335` | No code. |
| Physics Zero prediction needs | PLANNED | `doctrine/DISCOVERY.md:222-233` (`UNCERTAINTY_MODEL`, `PREDICTIVE_SCORE`), ROADMAP M29 "calibrated prediction" | This layer supplies the machinery; it is not Physics Zero. |
| Evolution Arena | PLANNED (spec only) | `docs/specs/EVOLUTION_ARENA_SPEC_V1.md` | No prediction or uncertainty dimensions; header still says PROPOSED and still calls omega #68 a draft (:8, :39). Stale. |
| FORGE physical evidence | IMPLEMENTED v1 (duration + success only); EXPERIMENTAL v2 | physics `forge/forge_types.h:66-76`; `forge/v2/forge_substrate_v2.h:192-207` | v2 has temperature, energy with MEASURED / ESTIMATED source, confidence_ppm. No v2 records on disk. |
| Effect Broker | IMPLEMENTED but CONFLICTING | aienos `crates/aienos-aegis/src/broker.rs:113-194` (Rust) | Conflicts with the recorded C-target decision; out of scope here. |
| AIENOS physical sensors | MISSING | | Thermal, power and clock sampling exists only as Omega test tooling. |

## 3. Candidate real signals (EST-2)

| Signal | Source | Samples | Evidence binding | Verdict |
|---|---|---|---|---|
| CPU thermal zone 0, 1 Hz | omega `evidence/R15/raw/20260929T020536Z-ad8e1f2ea4e4-silicon/machine-state.ndjson` and `.../20260929T025735Z-3e9e53be3358-silicon/machine-state.ndjson` (fields `t`, `thermal_mc` x7, `spbm_uj`, `busy`, `gpu`) | 1953 and 2009 lines, one continuous series each, max gap about 1.13 s | each run's `raw/SHA256SUMS`, bound to the R15 receipt `raw_digest_sha256` | **Chosen.** Two independent runs give a natural fit / held-out split. Load marks exist in `machine-state-marks.txt`. Produced by shell tooling (`tools/r15_machine_state.sh`), no Python. |
| Machine power (differenced `spbm_uj`) | same files | same | same | Second candidate; cumulative counter must be differenced. |
| 10 Hz telemetry (`power_uw`, `nvml_mw`) | R15 per-trial `.jsonl` | about 225 samples per trial segment | same | Rejected for EST-2: short disjoint segments. |
| `research/r14-failure-modes/.../machine-1hz.log` | | 607 lines, 45 gaps over 3 s | none | Rejected: not digest-bound. |

Honesty note: both runs were recorded on 2026-09-29, before this workstream existed. Their summary statistics had not been examined for estimation purposes when the EST-3 protocol was frozen, but the data are not blind in the CAL-0 sense. EST-3 therefore treats run B as held-out and reports it as "pre-existing, unexamined" evidence. A fresh collection after the freeze is the stronger test and is listed as EST-3b.

## 4. Doctrine lines that need tightening (ARCH-0020 section 6)

- `AIEN.md:534` "Observations are immutable ground truth": the observation **record** is immutable; the measured value is evidence with noise.
- `AIEN.md:533` claims "tagged with Bayesian confidence scores": such a score never grants authority or promotion.
- `doctrine/ARCHITECTURE.md:55,160` Cortex "maintains continuous world models" / "records world state": live estimates belong to the estimation layer and World; Cortex keeps epistemically significant events only.
- `doctrine/ARCHITECTURE.md:75` "receipts record ground truth": scoped to measurements, not estimates.
- ARCH-0018 AR3 (`docs/adr/0018-...:204`) owns substrate calibration and uncertainty. ARCH-0020 estimates dynamic state; AR3 characterizes substrates. An AR3 calibration artifact may be an observation-noise input to an estimator model; neither replaces the other.

These are recorded here, not edited, because `doctrine/` changes need their own reviewed change.

## 5. What must not be duplicated

- Cost-model uncertainty (EST-5 extends `RxCmPrediction`, does not add a second cost model).
- PRD1 and qint.v1 (EST-6 emits PRD1 predictions for held-out observations and lets TURING score them).
- CAL-0 freeze and blinding (EST-3 reuses `freeze_receipt.sh` style receipts).
- World generations (EST-4 reuses `RxObjRef` generation and field versions for staleness).
- The `nm -u` authority-isolation check (copied, not reinvented, in `mk/estimation.mk`).

## 6. Watch items

1. `AienosContainAuthorizer.decide` accepts a pluggable verdict function; a probability-based authorizer could be injected there. ARCH-0020 forbids it.
2. ARGUS `STATISTICAL` confidence class is reserved for ARGUS-5; it must not be fed by estimator output without a separate decision.
3. `docs/02-implementation-status.md` is a week stale on J-Space and Cortex.
4. `EVOLUTION_ARENA_SPEC_V1.md` activation hold still names omega #68 as a draft.

## 7. Claims re-checked by hand

| Claim | Result |
|---|---|
| `rx_semcomm.h:26` says Omega does not estimate uncertainty | confirmed |
| PRD1 header and record layout (`ty_prd.h:1-4`) | confirmed |
| `rx_cm_calibrate` at `rx_costmodel.c:385` | confirmed |
| machine-state.ndjson line counts 1953 / 2009 and field names | confirmed |
| `evidence/R16/` holds only `inventory.json`; last R16 commit is the spec `6fdc4c3` | confirmed |
| cost-model `nm -u` check at `Makefile:716-720` | confirmed |
| `mk/turing_qcont.mk` standalone pattern, `-ffp-contract=off` | confirmed |
| digest rule SHA-256(domain, 0x00, bytes) at `ty_qrecord.h:10` | confirmed |
| No kalman / covariance / innovation / BeliefState hits in omega, aien-architecture, aienos | confirmed |
