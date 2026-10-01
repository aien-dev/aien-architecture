# DIRAC-0 Specification (DIRAC-PREP freeze)

**Status:** PROPOSED. Written 2026-10-01. `DIRAC_PREP_FROZEN` is a gate this document proposes. It is **not claimed passed**. No sealed experiment may run before that gate passes.
**Authority:** operator brief of 2026-10-01 (Drake Stapleton). Where this text and the brief differ, the brief wins and the difference is a defect in this text.
**Decision record:** `docs/adr/0023-dirac-0-program.md` (PROPOSED). Current state: `docs/plans/dirac/DIRAC_0_CURRENT_STATE.md`.
**Not a master plan and not a milestone.** `CURRENT_EXECUTION_PLAN.md` owns sequencing and `doctrine/ROADMAP.md` owns milestone status. DIRAC-0 is a downstream consumer of existing workstreams and creates no new tensor system, measurement system, GPU runtime or evidence system.

Snapshots used for every fact below: omega `origin/main` `07004a8` (includes `aien-dev/omega#152`, merged), aien-architecture `origin/main` `921797b`, physics `origin/main` `006e426`. Names are cited only where seen at those commits.

---

## 1. Purpose

DIRAC-0 asks three questions, in order, and keeps them apart:

1. **D0:** can Omega represent the algebra needed for the Dirac equation exactly, using only generic capabilities?
2. **D1:** can Omega and FORGE realize and verify the computation, first on CPU, then on the GB10 (Blackwell)?
3. **D2:** given numeric observations only, can the Physics Zero machinery attempt blind discovery and beat a frozen baseline?

The Dirac equation is the test subject, never a feature. It exists only as a conformance fixture and as hidden evaluator knowledge.

Do not stop OSC-2. Do not fork E1. Do not create another tensor, measurement, GPU-runtime or evidence system. DIRAC-0 consumes the existing ones.

## 2. The ten rules

1. Dirac is never an Omega primitive.
2. The hidden equation never appears in AIEN, Cortex, prompts, Skills or the graph.
3. D0 is generic.
4. D1 consumes M20, E1 and FORGE.
5. D2 consumes TURING and Physics Zero scoring.
6. Human physics is evaluator knowledge.
7. Sealed outcomes survive, including failures.
8. No candidate controls its holdout, baseline, scoring or promotion.
9. Efficiency is not explanatory quality.
10. Exact notation is never required.

## 3. Dependency order

Current work, then DIRAC-PREP (this spec, a sealed oracle, a conformance corpus), then D0 generic algebra, then D1 CPU then Blackwell, then TURING calibrated, then Physics Zero machinery, then D2 blind rediscovery, then optionally the Evolution Arena.

Subsystem roles: OSC-2 is the foundation. E1 supplies scalar numerics. M20 supplies tensor and state and the realization seam. POLYGLOT is precedent. FORGE realizes and produces physical evidence. TURING records and evaluates. ESTIMATION supplies uncertainty. ARGUS observes only. AEGIS authorizes interventions. World holds state. Cortex remembers evidence, hypotheses and failures, and never the key. J-Space compares models. The Evolution Arena comes later.

## 4. P0: semantic requirements (generic capability list)

Omega must be able to express, as generic capabilities, each of the following. Each item is checked by a conformance fixture, not by a named builtin.

| Id | Capability |
|---|---|
| P0.1 | Complex scalar, with exact identity |
| P0.2 | Multi-component state |
| P0.3 | Linear operator |
| P0.4 | Matrix product |
| P0.5 | Noncommutative product |
| P0.6 | Anticommutator (and commutator) |
| P0.7 | Metric and signature |
| P0.8 | Differential operator |
| P0.9 | Constraint or relation (objects plus equations they must satisfy) |
| P0.10 | Basis transformation |

**Explicitly forbidden:** any builtin named or behaving as `DiracSpinor`, `GammaMatrix`, `Electron`, `Mass` or `Spin`. A change that adds one is rejected under rule 1, whatever its tests show. Dirac is a conformance fixture only.

## 5. Numerical reference conventions

DIRAC-0 reuses E1 and does not define a second numeric contract.

- **Tiers.** The semantic tier is `omega_numeric_reference`. The CPU tier is `omega_numeric_cpu_realize`. The GB10 tier is `omega_gb10_execute_simt_op` (`src/omega_numeric_gb10.c`), with DIV and SQRT kernels in `src/omega_numeric_divsqrt_gb10.c`. All are in omega `src/omega_numeric.h` and neighbours.
- **Comparison vocabulary.** `OMEGA_CMP_BIT_EXACT`, `OMEGA_CMP_INT_EXACT`, `OMEGA_CMP_SEED_BOUND`, `OMEGA_CMP_F16_BITS`, `OMEGA_CMP_BF16_BITS` (type `OmegaNumericCompare`). Parity evidence uses `OmegaParityTrace`.
- **Error kinds.** FORGE spec section 6.1 (`docs/FORGE_SUBSTRATE_V2_SPEC.md` in physics): EXACT (1), BOUNDED_DETERMINISTIC (2), BOUNDED_STOCHASTIC (3), MEASURED_DISTRIBUTION (4), with integer bounds `error_rel_ppb` and `error_abs`. Omega contracts are exact-only today (`RcKind`, `rc_check` in `src/runtime/rx_contract.{h,c}`); kinds 2 to 4 stay in FORGE until Omega adds them (FORGE spec section 6.4).
- **Build discipline.** E1 builds with `-ffp-contract=off`, FPCR round to nearest even, flush to zero clear. DIRAC-0 inherits this.
- **High-precision reference is evaluator-side only.** Any arbitrary-precision or analytic reference used to judge Omega results lives in the evaluator world (section 7). It is never linked into Omega and never visible to AIEN.
- **Transcendentals.** EXP and LOG are CPU only, frozen and bounded (E1 gap table: EXP 40 ulp, LOG 4 ulp), not correctly rounded. No transcendental exists on the GB10. Any DIRAC-0 case that needs one states its bound and does not claim exactness.

## 6. P1: oracle conventions

- The oracle is **independent**. It shares no code, no headers and no build rules with the Omega candidate, and Omega never depends on it.
- It provides: gamma representations (at least two inequivalent-looking but equivalent sets), Clifford relation checks, analytic plane-wave cases, dispersion cases, basis-change equivalence cases, and a high-precision reference.
- It is held on the evaluator side (section 7). Its answer-key mappings are sealed.
- **Future home:** omega `research/dirac-oracle/` will hold the oracle specification. That directory does not exist at omega `07004a8`; it is created by PR D-02, not before.
- Lane B (oracle) is independent of lane A (algebra). Two lanes agreeing is the evidence; one lane checking itself is not.
- **Placement rule (public fixtures versus sealed keys).** Omega is a repository AIEN could read, so `research/dirac-oracle/` holds only the PUBLIC conformance corpus: textbook algebra (gamma representations, Clifford relations, basis changes) that D0 needs as generic known-answer fixtures and that reveals nothing about any sealed experiment. The sealed side (which equation and parameters a sealed dataset uses, its answer-key mappings, the sealed oracle values, the dataset generator D-11) never enters Omega or any AIEN-readable repository; it lives in private evaluator storage owned by the operator (BLOCKED_OPERATOR until set up). Before any sealed experiment, the operator must confirm this placement; D-11 does not start without it. Public fixture filenames in Omega are D0 test names, and no AIEN-facing artifact ever references them.

## 7. P3 first: secrecy boundary (read before P2)

```text
EVALUATOR WORLD                      || HARD BOUNDARY ||           AIEN WORLD
equation                             ||                ||  numeric observations
gamma matrices                       ||                ||  channel ids
physical interpretation              ||                ||  timestamps
oracle                               ||                ||  permitted interventions
answer-key mappings                  ||                ||  uncertainty
```

AIEN has no repository, Cortex, prompt, provenance, metadata or filename access that reveals the answer.

### 7.1 Leakage checklist (every item is a test, not a promise)

| Surface | Must hold |
|---|---|
| Filenames | No path, dataset name, channel name or run name carries physics terms. Names are opaque (digest or counter). |
| File metadata | No timestamps, authorship, tool strings or comments naming the source equation. Fixed metadata. |
| Provenance records | Provenance on the AIEN side names the dataset commitment digest only, never the generator. |
| Repository | The sealed generator, oracle and key mappings are not in any repository AIEN can read at run time. Private repo or offline store on the evaluator side. |
| Cortex | No evidence, hypothesis or failure record contains the equation, the gamma matrices or an answer-key mapping. Cortex never holds the key. |
| Prompts | No prompt, brief or template to an AIEN agent contains Dirac terms or the hidden equation. |
| Skills | No Skill, registered capability or routing key is named for, or encodes, the hidden equation. |
| Graph | The Capability Graph and J-Space contain no node derived from the hidden equation before the prediction freeze (D2.6). |
| Logs and errors | Failure messages and receipts visible to AIEN carry no answer-key text. |
| Tooling | No evaluator tool is on AIEN's path. |

D2 additionally requires an independent leakage review before any result counts (section 12).

### 7.2 Commitment before scoring

Sealed datasets use the existing G3 scheme: `spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md` in omega (`st_holdout.{h,c}`). The commitment is `SHA-256("omega.g3.holdout.commit.v1" 0x00 || salt[32] || u64be(taskset_len) || u32be(task_count) || taskset)`, with `salt_digest = SHA-256("omega.g3.holdout.salt.v1" 0x00 || salt)`. The commitment is recorded before any scoring. DIRAC-0 adds no second scheme.

**Real limit:** G3 sealing is BLOCKED_OPERATOR (secret salt, storage place for the sealed set, owner-key signature). Until the operator acts, DIRAC-0 sealed runs cannot be real. Test-key commitments (omega#130) are for tooling tests only.

### 7.3 No self-control

No candidate controls its own holdout, baseline, scoring or promotion (rule 8). The evaluator owns all four. A candidate may not read the scorer's code at run time, choose its split, or promote its own result.

### 7.4 Held-out policy

- Splits and seeds are fixed and committed before any candidate runs.
- Training observations and sealed observations are disjoint, and sealed observations include at least one preregistered unseen regime for D2.3.
- A sealed set is used once per preregistered claim. Re-use after a result needs a new commitment and is recorded as a new attempt.
- Failed attempts are kept as receipts. No gate, baseline or metric is weakened after a sealed result (rule 7).

## 8. P2: canonical encodings

All dataset and fixture objects use the existing canonical encoding (`spec/canonical-encoding.md`, magic `OMG0`; `SEMANTIC_ID = SHA256(CANONICAL_SERIALIZATION(object))`, `omega_compute_semantic_id`). Record-level digests use SHA-256 with a domain prefix and a zero byte, as the G3 commitment and TURING records do. New domains use the `omega.dirac.*` prefix and are listed here when frozen (none are frozen yet).

Each encoding is stated in plain structural terms, with no physics words in field names on the AIEN side:

| Object | Content (structural) |
|---|---|
| Complex value | Pair of fixed-width real parts (real, imaginary), width and rounding named. Deterministic byte order. Exact identity defined bitwise. Real element type per E1 (F32 today; see section 14). |
| Operator dims | Row count, column count, element type, entries in declared order. |
| Tensor dims | Rank (at most 8 in M20), shape, element type, layout declared. |
| Metric | Square symmetric table of declared size and entries, plus signature count. |
| Initial state | Component count, per-component complex entries, sample grid reference. |
| Boundary condition | Kind (bounded, periodic, none), bounds, per-boundary values. |
| Space/time sample | Ordered coordinates, spacing, count, time stamps as integers in a stated unit. |
| Observation | Channel id (opaque integer), time stamp, value, declared uncertainty. |
| Intervention | Permitted action id (opaque), allowed range, cost, authorization reference (AEGIS). |
| Prediction | Channel id, future time stamp, predictive distribution (location, scale, shape per the ESTIMATION record, `est_dpred`), model identity. |

A dataset is readable with no human physics terms on the AIEN side. Evaluator-side companion files may carry terms, and never cross the boundary.

## 9. Measurement profile

DIRAC-0 measures with TURING and FORGE. It defines no new meter.

### 9.1 TURING

- **T unit** (`docs/turing/TURING_YIELD_PROFILE_V0.md` in omega): `DL(M,D) = L(M) + L(D|M)`; `T(M;B,D) = DL(B,D) - DL(M,D)` on the held-out split only. "1 T = 1 bit of net held-out description-length gain versus the declared baseline." Fixed point is micro-bits (int64).
- **T/s:** T divided by wall time of the declared work. Wall time comes from `turing_evidence` timing fields.
- **T/J:** T divided by energy. **H5 (T/J) is NOT STARTED** (`docs/turing/TURING_SCIENTIFIC_QUALIFICATION_STATE.md`). DIRAC-0 reports T/J as NOT_RUN until H5 exists and never fabricates one from an estimated energy.
- Records use the existing TURING domains (`turing.yprofile.v0`, `turing.ysplit.v0`, `turing.yfit.v0`, `turing.yield.v0`) and the structure `ty_gain_rec`.

### 9.2 FORGE

For D1B, each realization carries `ForgeExecutionEvidenceV2` (tags 0x0601 to 0x0670 in the FORGE spec section 8): realization, machine and substrate identity, semantic contract digest, input and output identity, execution duration, energy (with `energy_source` NOT_MEASURED, MEASURED or ESTIMATED), temperature, supply, measured error (`error_rel_ppb`, `error_abs`, `confidence_ppm`), runs and spread, `hardware_status`, `fault_state`, and the mandatory `provenance_class` (PHYSICAL or SIMULATED_DEVELOPMENT). SIMULATED_DEVELOPMENT evidence never satisfies a hardware gate. Encode and decode use `forge_v2_encode_evidence` and `forge_v2_decode_evidence`.

Real limit: no FORGE V2 receipt exists yet, and the `hardware_status` value list is unconfirmed.

## 10. Definitions

- **No Physics Zero loop document exists yet.** There is no document in omega or aien-architecture defining the OBSERVE, COMPRESS, HYPOTHESIZE, PREDICT, INTERVENE, MEASURE, FALSIFY and ABSTRACT loop. Physics Zero today is `CURRENT_EXECUTION_PLAN.md` section 13 (Phase J, M27 to M35) and roadmap M27 `PHYSICS_ZERO_PROTOCOL`. D2 entry therefore waits on that loop being written and supported by the TURING substrate.
- **The term "net Turing gain" does not exist yet.** The existing name is "net held-out description-length gain", the T unit. This spec defines, as a **new DIRAC-0 definition pending TURING owner review**:

  `net Turing gain = T (per TURING_YIELD_PROFILE_V0, held-out only) minus the declared search and compute cost accounting`

  The cost accounting is stated in the preregistration (D2.0) in the same unit (micro-bits) with its conversion rule fixed before the sealed run. Until the TURING owner accepts this definition, results use T and the cost terms reported separately, and the combined figure is informational.
- **Efficiency is not explanatory quality** (rule 9). Speed, energy and T/s are reported beside, never instead of, held-out predictive gain.

## 11. Wave map

| Wave | Name | Entry criteria | Content | Gate |
|---|---|---|---|---|
| 0 | DIRAC-PREP | Interfaces refreshed | This spec, the sealed oracle, the conformance corpus | `DIRAC_PREP_FROZEN` |
| 1 | D0 generic algebra | `DIRAC_PREP_FROZEN`; OSC-2 interfaces stable; E1 contracts stable; M20 GB10 not needed | D0.1 to D0.6 | `DIRAC_D0_ALGEBRA_PASS` |
| 2 | D1A CPU | D0 PASS; M20 CPU qualified; E1 CPU qualified | 1+1D first: free propagation, known initial state, bounded domain; state, norm, phase, dispersion error; stability; determinism; two independent discretizations converge | `DIRAC_CPU_REALIZATION_PASS` |
| 3 | D1B Blackwell | M20 GB10 qualified; E1 GB10 qualified; CPU PASS | Omega semantics, M20, realization choice, FORGE, GB10; generic first; specialized kernels only after profiling; compare CPU, GB10 generic, GB10 optimized | `DIRAC_D1_REALIZATION_PASS` |
| 4 | D1C expand oracle | D1 gates as the wave needs | D1C-1 momenta, -2 rest parameters, -3 superpositions, -4 wave packets, -5 external fields, -6 higher dimensions, -7 full 3+1 Clifford. Evaluator capabilities, not AIEN facts | none (extends fixtures) |
| 5 | D2 Physics Zero | Loop OBSERVE, COMPRESS, HYPOTHESIZE, PREDICT, INTERVENE, MEASURE, FALSIFY, ABSTRACT supported by the TURING substrate; `DIRAC_PREP_FROZEN`; G3 sealing done | D2.0 to D2.6 | `DIRAC_D2_DISCOVERY_PASS` |

**D0 entry conditions** reference OSC-2 interface stability and E1 contract stability. Neither is claimed here. OSC-2 items 1 to 4 have merged in omega (`#148`, `#149`, `#150`, `#151`), and E1 has merged WP-A, WP-B, WP-D, WP-C batch 1 and GB10 DIV/SQRT (`#124`, `#127`, `#134`, `#147`, `#152`), but "stable" is a call the OSC-2 and E1 owners make, not this spec.

### 11.1 D0 content

- **D0.1** `Complex<T>`: add, sub, mul, div, conj, magnitude, exact identity, deterministic serialization.
- **D0.2** Operator algebra: `A+B`, `A.B`, `aA`, `[A,B]`, `{A,B}`, identity, zero, declared noncommutativity.
- **D0.3** Constraint-defined algebras: objects `g0..g3` with constraints `gi gj + gj gi = 2 metric(i,j) I`; derive and check consequences; reusable for Clifford, Pauli, geometric and symmetry algebras.
- **D0.4** Multi-component state via M20 `Tensor<Complex<T>,[N]>`.
- **D0.5** Differential operator representation independent of discretization.
- **D0.6** Basis independence: two gamma representations give equivalent observables.

### 11.2 D2 content

- **D2.0** Preregister: training observations, sealed observations, allowed operations, complexity accounting, baselines, metrics, failure criteria, intervention and compute budgets, seeds.
- **D2.1** Blind free propagation: `channel_k(t,x)`, predict the future.
- **D2.2** Latent coupling: shared structure beats independent channels after paying complexity.
- **D2.3** Regime transfer.
- **D2.4** Intervention choice. AEGIS authorizes. Information gain grants no authority.
- **D2.5** Hidden external field.
- **D2.6** Structural comparison after predictions are frozen. Classes: equivalent, approximate, predictively equivalent, different-superior, different-inferior, uninterpretable-predictive, failure.

D2 measurement: primary is held-out predictive description length. Derive net Turing gain (section 10), T per observation, T/s, T/J (NOT_RUN until H5). Cost is reported separately from explanation. Also report calibration, prediction and transfer error, counterexample survival, intervention efficiency, complexity, hypotheses explored, search cost and uncertainty. Failures are retained.

## 12. Gates

Pass criteria are copied from the brief. A gate is claimed only by a receipt (section 13).

| Gate | Pass criteria |
|---|---|
| `DIRAC_PREP_FROZEN` | This spec accepted by the operator; it freezes semantic requirements, numerical reference conventions, oracle conventions, dataset format, held-out policy, leakage policy, measurement profile and qualification gates. No sealed experiment before it. |
| `DIRAC_D0_ALGEBRA_PASS` | Generic only, no Dirac primitive; Clifford known-answer tests pass; basis transformation passes; deterministic serialization; stable semantic ids; mutation tests catch broken relations; independent oracle agrees. |
| `DIRAC_CPU_REALIZATION_PASS` | D1A: 1+1D free propagation, bounded domain, known initial state; state, norm, phase and dispersion error measured within declared bounds; stability and determinism shown; two independent discretizations converge. |
| `DIRAC_D1_REALIZATION_PASS` | D1B: same semantic operation, state and result within declared bounds on CPU, GB10 generic and GB10 optimized; authority contract satisfied; FORGE evidence (duration, energy, temperature, error, repetitions, hardware status, faults) fed to TURING; latency, energy, memory, movement, precision, T/s and T/J measured (T/J as far as H5 allows, else NOT_RUN). |
| `DIRAC_D2_DISCOVERY_PASS` | Beats the frozen baseline on the sealed held-out set AND complexity-adjusted gain is greater than 0 AND transfers to at least one preregistered unseen regime AND independent replay reproduces AND no leakage found. Exact rediscovery is NOT required. |

**Verdict vocabulary:** PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, MISSING_IMPLEMENTATION. Of these, PASS, FAIL, NOT_RUN, MISSING_IMPLEMENTATION and BLOCKED_OPERATOR already appear in omega or this repository. BLOCKED_HARDWARE is new here and is added to the vocabulary by this spec.

## 13. Receipt shape

Receipts follow the existing omega convention (ADR 0021 decision 3): append-only, named by their own digest, bound to a clean source commit, written outside the tree under qualification.

- Path: `evidence/DIRAC-0/<sha256>.json` in omega (or the repository that ran the gate).
- Keys modeled on the OMEGA-NUMERIC-0 receipt: `schema`, `status`, `gate`, `candidate_git_commit`, `candidate_binary_sha256`, `candidate_trees_clean`, `physics_lock`, `physics_candidate_git_commit`, `hardware_descriptor`, `hardware_descriptor_digest`, `gb10_parity[]` (D1B only), `test_manifest`, `test_manifest_sha256`, `test_results`, `observed_pass_count`, `observed_fail_count`, `observed_test_count`, `gate_log_sha256`, `gate_stderr_sha256`, `receipt_digest`, `run_id`, `timestamp_utc`, `digest_meaning`.
- DIRAC additions: `dataset_commitment_digest` (G3 form) and `leakage_review_ref` for D2 receipts; `preregistration_digest` for D2.
- **A dirty tree is refused.** If `candidate_trees_clean` would be false the tool writes no receipt. A FAIL receipt is kept. Reruns write new files and never overwrite.
- The receipt records the verdict only from the vocabulary in section 12.

## 14. PR sequence and lanes

| PR | Content | Note |
|---|---|---|
| D-01 | Spec and ADR (no code) | This document |
| D-02 | Oracle and known-answer corpus | Evaluator only; creates omega `research/dirac-oracle/` |
| D-03 | Complex | Must justify itself as generic Omega capability |
| D-04 | Noncommutative operator relations | Generic |
| D-05 | Clifford fixtures, no Dirac builtin | Generic |
| D-06 | Differential operator | Generic |
| D-07 | 1+1D CPU reference | |
| D-08 | Omega and M20 CPU parity | |
| D-09 | GB10 via tensor and FORGE | |
| D-10 | FORGE and TURING evidence | |
| D-11 | Sealed dataset generator | Evaluator side |
| D-12 | Preregistration | |
| D-13 | Blind experiment | |
| D-14 | Replay and receipt | |

D-03 to D-06 each state, in their PR, the generic Omega capability they add and a non-Dirac use for it. Without that, they are rejected.

**Lanes after PREP:** A algebra, B oracle (independent of A), C numerical, D realization, E measurement, F adversarial. One integration owner holds shared schemas.

## 15. Real gaps (checked at the snapshots above)

| Gap | Fact |
|---|---|
| No complex type | M20 `OmegaDType` is F32, F16, BF16 only (omega#136, draft). Grep for `_Complex`, `complex64`, `OMEGA_DT_C` over omega `src/` and `docs/` finds nothing. **D0.1 is new generic work, not a wrapper.** |
| M20 not qualified | `docs/tensor/M20_OMEGA_TENSOR.md` (on the #136 branch) says "M20 NOT QUALIFIED". `aien-dev/omega#136` is a draft and not on main. |
| No GB10 tensor realization | GB10 parity NOT_RUN; GB10 general matmul MISSING_IMPLEMENTATION. D1B cannot start. |
| EXP and LOG not correctly rounded | CPU only, frozen and bounded (EXP 40 ulp, LOG 4 ulp). Transcendentals on GB10 missing. |
| No FP32 in program IR | The Omega program IR has no FP32 value type (E1 gap table row 12). |
| Omega contracts exact-only | `RcKind` and `rc_check` have no tolerance kinds. Kinds 2 to 4 live in FORGE. |
| ESTIMATION v4 has no verdict | `aien-dev/omega#153` is open. Its body says PASS for attempt 2, but the branch head `f5a3036` voided attempt 2 and says attempt 3 is pending. **Never cite v4 as PASS.** |
| G3 sealing BLOCKED_OPERATOR | No real sealed set exists. |
| No Physics Zero loop document | See section 10. |
| T/J not started | H5 NOT STARTED. |
| No FORGE V2 receipts | Physics has none; `hardware_status` values unconfirmed. |
| Oracle home missing | omega `research/dirac-oracle/` does not exist; D-02 creates it. |

Omega #152 (GB10 DIV/SQRT) is MERGED at `07004a8`.

## 16. C2S ladder (Drake addendum, 2026-10-01): mathematical invention under physical constraint

Source: `~/handoffs/physics-zero/PZ-C2S-ADDENDUM-DRAKE-BRIEF.md` section 18 (the addendum wins on any difference). The C2S benchmark family (Constraint-to-Structure) itself, its concepts (RepresentationAdequacy, RepresentationalCrisis, UnexpectedSolutionPolicy) and its gates (`PZ_C2S_*`, `PZ_NOVEL_PREDICTION_PASS`, `PHYSICS_ZERO_C2S_FOUNDATION_PASS`) are defined by the Physics Zero Atlas V1 section (Lane 36), not here. DIRAC-0 cites them by name only and defines none of them.

**What changes.** DIRAC-0 is no longer a test of equation rediscovery. It tests whether AIEN can find that its current mathematics cannot describe reality, invent a richer algebra because the evidence demands it, and use that invention to predict something it has not seen. Credit goes to algebraic necessity, never to symbols.

**The AIEN-facing ladder:**

| Step | Question | Relation to the waves in section 11 |
|---|---|---|
| D-1 | Can AIEN prove that simpler representation classes (scalar, real-only, commuting) are inadequate for the sealed constraints? "My language cannot represent this" is progress, not failure. | New first step. Needs the C2S adequacy lab (`PHYSICS_ZERO_C2S_FOUNDATION_PASS`) before any Dirac-flavoured world. |
| D0 | Can AIEN discover and represent the richer algebra (objects whose relations make a first-order evolution square to the quadratic energy-momentum relation, with the needed state dimension earned by held-out gain)? | AIEN-facing meaning. Not to be confused with wave 1 (section 11 row 1), which is the evaluator-side generic Omega capability (complex, operator relations, constraint-defined algebras) that makes D0 representable at all. Wave 1 stays as written and remains a prerequisite. |
| D1 | Can the discovered structure be realized physically (CPU, then Blackwell) and verified? | Waves 2 and 3 (D1A, D1B). |
| D2 | Can a predictive theory be discovered from observations only? | Wave 5 (D2.0 to D2.6). |
| D3 | Does the frozen theory predict a sealed, novel consequence that was never requested? | New. Gate cited: `PZ_NOVEL_PREDICTION_PASS` (and `PZ_C2S_NOVEL_CONSEQUENCE_PASS`), both from the Atlas section. |

**Hard rules added by the addendum (they tighten, never loosen, the ten rules):**
1. AIEN is never handed complex numbers, matrices, spinors, tensors, gamma matrices, Clifford or Lie structure, or the notation of the hidden relation. AIEN receives only generic machinery earned by earlier gates and composes new abstractions itself. This reinforces rules 1, 2 and 6, and the evaluator/AIEN boundary in section 7.
2. The hidden state dimension is not announced. Candidate dimensions are each charged for complexity and must be earned by held-out gain (`PZ_C2S_STATE_DIMENSION_PASS`).
3. Success is judged by equivalence of structure (for example objects with the required squares and anticommutation), never by matching historical notation or path (rule 10).
4. Worlds where the current representation is already sufficient are included. Gratuitous complexity is penalized; "existing representation adequate" can be the right answer.
5. Strange solution branches are classified, never silently discarded, under the Atlas UnexpectedSolutionPolicy.
6. Prediction-before-observation: the prediction (timestamp, theory digest, distribution) is committed before the evaluator reveals the observation, using the existing G3 commitment scheme (section 7). Post-hoc retrofit earns no credit.
7. Discovered mathematics is promoted to an Omega abstraction only on multiple independent uses, held-out compression gain, semantic preservation and verification, and never because humans have a name for it.

**Effect on this spec's gates.** `DIRAC_D2_DISCOVERY_PASS` (section 12) is unchanged. Two additions are proposed, defined only by reference: `DIRAC_D3_NOVEL_PREDICTION_PASS` is NOT defined here; it is the Atlas `PZ_NOVEL_PREDICTION_PASS` applied to the DIRAC world, and D-1 passes when the Atlas C2S adequacy lab passes. Neither is claimed. Both are NOT_RUN.

**Scorecard.** Reported separately, with no single score: constraint satisfaction, predictive accuracy, held-out Turings, representation complexity, failed representations count, time until inadequacy recognized, cost of expansion, new-prediction accuracy, transfer, cross-domain reuse, false-complexification rate, uncertainty, falsification quality (addendum section 17).

**Effect on the oracle (D-02).** The oracle and its public conformance corpus (omega `458c57f`) are unchanged: they check the evaluator-side fixtures only. The C2S worlds are sealed evaluator material and follow the placement rule in section 6.

## 17. Immediate next action

Refresh interfaces, accept this spec, freeze requirements, specify the oracle, specify the leakage boundary, define receipts and gates. Touch no production runtime. Wait for OSC-2 and E1 to settle before production algebra or tensor work. The first real milestone after PREP: Omega represents and independently verifies a generic Clifford relation without a Dirac primitive.
