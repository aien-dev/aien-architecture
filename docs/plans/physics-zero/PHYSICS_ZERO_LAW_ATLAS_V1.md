# Physics Zero Law Atlas V1

Status: DRAFT, design only. Lane 36, Wave 0. No code, no sealed material, no runs.
Companion: `PHYSICS_ZERO_LAW_ATLAS_RESEARCH.md` (classification and citations).
Doctrine read, never edited: `doctrine/DISCOVERY.md` (DOCTRINE-006).
Evidence vocabulary: PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, MISSING_IMPLEMENTATION.
Nothing in this document is a PASS. Every benchmark below is NOT_RUN.

## Scope

The Atlas is a ladder of hidden-world benchmarks. Each rung probes one capability that the rungs below
it do not. The Atlas extends doctrine objects (`OMEGA_THEORY`, `OMEGA_DISCOVERED_CONCEPT`) and adds no
new Omega object kind. Roadmap anchors are M27 to M35 (protocol, hidden worlds, theory discovery,
active experimentation, concept formation, alien worlds, novel regime, novel phenomenon, real lab).
Rung to milestone mapping here is a proposal. The roadmap is not edited by this document.

Plain-English summary of the idea: we invent small worlds whose laws only an evaluator knows. A
candidate system watches and pokes the world through neutral channels, then writes down a theory. The
evaluator, which the candidate cannot see, scores the theory on prediction, on surviving new
experiments, on being compact, and on honestly saying "I found no law" when there is none.

---

## 1. Benchmark taxonomy

Rungs map onto the doctrine pyramid P0-0 to P0-8. Order within a family is difficulty order.

| Rung | Family | Tests (new capability) | Doctrine pyramid | Roadmap |
|---|---|---|---|---|
| PZ-A | Classical identifiability | Observable versus latent; refusing unidentifiable names | P0-0 to P0-2 | M28 |
| PZ-B | Variational and Noether | One scalar law; symmetry and conservation links | P0-2, P0-3 | M28, M29 |
| PZ-C | Fields: wave, diffusion, 2+1D Maxwell-like | Laws over fields; gauge freedom | P0-3, P0-4 | M29 |
| Q0 | Complex amplitudes | Compact complex structure; global phase gauge | P0-4 | M29 |
| Q1 | State versus observable evolution | First cross-formalism equivalence | P0-4, P0-5 | M29, M31 |
| Q2 | Mixed states and open dynamics | Ensemble ambiguity; purification; decoherence | P0-5 | M29, M31 |
| SC-0 | Scale and renormalization | Laws that change with scale; validity regions | P0-5, P0-6 | M32, M33 |
| X-0 | Cross-formalism | Same physics in different frameworks | P0-5 | M31, M32 |
| Q3 | Bell and CHSH | Discriminating experiment between model classes | P0-6 | M30 |
| Q4 | Lindblad and Hamiltonian learning | Calibrated parameter claims | P0-6 | M29, M30 |
| Q5 | Klein-Gordon, Berry phase | Relativistic field law; geometric phase | P0-6 | M33 |
| Q6 | Dirac | Matrix-valued operators, basis independence | P0-6 | see DIRAC-0 |
| S0, S1, S2 | Ising, Langevin, chaos and bifurcation | Collective concepts; noise; chaos versus noise | P0-3 to P0-6 | M31 |
| T-0 | Theory succession | Old theory as a limit of a new one | P0-7 | M33 |
| G-0 | Geodesic and coordinate invariance | Equivalence classes under coordinate groups | P0-7 | M34 |
| PZ-ACTIVE | Active experimentation | Choosing the experiment that discriminates | P0-6 to P0-8 | M30 |

Q6 is owned by DIRAC-0 (`docs/plans/dirac/DIRAC-0-SPEC.md`, arch PR #83, not yet merged when this was
written). That spec defines its own waves D0, D1, D2 and gates (DIRAC_PREP_FROZEN through
DIRAC_D2_DISCOVERY_PASS). The Atlas only reserves the rung name and requires that the Dirac evaluator
follow sections 4, 7, 8 and 9 below. It does not restate the Dirac design.

Every rung has three world classes: signal worlds (a law exists), null worlds (no law, only noise or a
decoy), and adversarial worlds (a tempting wrong law). A rung with no null worlds is invalid.

## 2. Generic Theory semantics

### 2.1 Principle

A Theory is an `OMEGA_THEORY` in the doctrine sense. The Atlas needs a few more fields and a few more
value types. All additions must be generic, with no physics name in any primitive, and each must serve
at least two rungs (see the research document section 5).

### 2.2 Field mapping

| Atlas concept | Existing doctrine field (DISCOVERY.md 7.1) | Status |
|---|---|---|
| theory id | THEORY_ID | reuse |
| latent objects | LATENT_VARIABLES | reuse |
| observable objects | OBSERVABLE_SCHEMA | reuse |
| derived quantities | DERIVED_VARIABLES | reuse |
| relations | RELATIONS | reuse |
| dynamical laws | DYNAMICAL_RULES | reuse |
| initial conditions | INITIAL_CONDITIONS | reuse |
| predicted observables | PREDICTION_PROCEDURE | reuse |
| intervention predictions | COUNTERFACTUAL_MODEL | reuse |
| uncertainty | UNCERTAINTY_MODEL | reuse |
| evidence | EVIDENCE_IDS | reuse |
| counterexamples | COUNTEREXAMPLES, KNOWN_FAILURES | reuse |
| description length, score | DESCRIPTION_LENGTH, PREDICTIVE_SCORE | reuse |
| regime and scale | DOMAIN_OF_VALIDITY | split in two, each a testable predicate |
| algebra | none | new |
| geometry and topology | none | new |
| symmetries and gauge equivalences | none | new |
| invariants and conservation laws | none | new, as claim objects (2.4) |
| boundary conditions | none | new |
| discrepancy model | none | new |
| parent, limiting and equivalent theories | COMPETING_THEORY_IDS (partial) | new edges (2.5) |
| distribution-valued laws | UNCERTAINTY_MODEL (partial) | new (2.7) |

A Theory may leave any new field empty. An empty field is an honest answer, not a defect.

### 2.3 Five-question conformance profile

A submitted Theory is read through five questions. Each answer is either filled, explicitly EMPTY, or
UNKNOWN.

1. What exists? (objects, latent and observable)
2. How does it evolve? (laws, algebra, geometry)
3. What changes leave predictions unchanged? (symmetries, gauge, invariants)
4. Where does it apply? (regime, scale, boundary conditions)
5. Where does it fail? (discrepancy model, known failures, counterexamples)

### 2.4 Generic primitives (the minimum set)

Each is generic. None is named after a physical law, and Dirac is never an Omega primitive.

1. Value types: real, complex, tensor over those. Complex is a representation, because C^N is R^(2N)
   with a rotation-like structure. No benchmark may require complex numbers, only reward compact use.
2. Declared transformation: an invertible map on a declared domain, with an observation map and an
   intervention map (DISCOVERY.md 16.6). Covers relabel, coordinate, basis, gauge, field redefinition.
3. Invariant claim: a claim with status DISCOVERED, NOT FOUND, REJECTED or INCONCLUSIVE, plus the
   transformation it is invariant under. Conservation laws are claims of this kind.
4. Discrepancy model: a declared, testable description of what the theory fails to explain.
5. Theory link: typed edges equivalent_to, reduces_to, parent_of, limit_of.
6. Validity region: a predicate over regime and scale that can itself be tested.
7. Distribution-valued law: a law whose output is a distribution, not a point.

Existing Omega primitives are reused wherever they fit: the eleven semantic categories (VALUE, TYPE,
OPERATION, RELATION, CONSTRAINT, MEMORY, MACHINE, EFFECT, REALIZATION, EVIDENCE, PROOF), semantic ids
as SHA-256 over canonical serialization, the verifier levels (V0 to V2 implemented), and the
contract kinds RC_HYPOTHESIS and RC_EVIDENCE.

### 2.5 Identity

Two Theories have the same Omega id only if their canonical serializations match. Equivalence under
section 3 is a separate, evaluator-side judgment recorded as a theory link, not as an id merge.
J-Space (`src/runtime/rx_jspace.{h,c}`) has no theory-level identity today, and cross-formalism work
needs one. That is a dependency (section 10).

### 2.6 Honest emptiness

A Theory that says "no law found" for a null world is correct. The evaluator must reward this.

### 2.7 Distribution-valued laws

For Langevin, Born-rule and Lindblad rungs the law's output is a distribution. The score is
proper-scoring-rule based (log score) against held-out samples, never against a single trajectory.

---

## 3. Equivalence rules

Doctrine anchor: equivalence is an invertible reparameterization on a declared domain with consistent
observation and intervention mappings, and comparing against a named constant needs a declared
correspondence rule (DISCOVERY.md 16.6).

### 3.1 The ladder

| Level | Meaning | Example |
|---|---|---|
| E0 identical | same canonical form | none |
| E1 relabel | renaming of symbols | channel names |
| E2 coordinate | invertible coordinate change | polar versus Cartesian |
| E3 basis or unitary | change of basis in a vector or Hilbert space | rotating a qubit basis |
| E4 canonical | transformation preserving the law's form, including L to L plus dF/dt | Lagrangian shift |
| E5 gauge | transformation unobservable by construction | vector potential shift |
| E6 field redefinition | invertible redefinition of fields | rescaled amplitude |
| E7 dimensionless rescaling | removes units | nondimensional form |
| E8 cross-formalism | different frameworks, same predictions | Schrodinger versus Heisenberg |
| E9 coarse-grained effective | asymmetric: fine theory reduces to coarse theory on a declared domain | Fokker-Planck from Langevin |
| E10 predictive-only | same predictions on tested domain, no structural map | black-box match |

### 3.2 Outcomes

The evaluator returns EQUIVALENT(level), NOT_EQUIVALENT(witness) or UNDETERMINED. NOT_EQUIVALENT must
carry a witness: an experiment or input where the two disagree. UNDETERMINED means no witness and no
proof within the tested domain.

### 3.3 Rules

- E9 is directional and carries a domain. It never upgrades to E8.
- E10 is the weakest level. It earns prediction score and no structure score.
- Redundancy overhead is reported: description length as submitted minus the minimum within the
  planted equivalence class. It is reported, and it does not reduce the prediction score.
- Every world plants its equivalences. Each rung's spec lists them so the evaluator can recognize them
  without guessing.
- Equivalence checking is run by the evaluator and never by the candidate.
- Traps: a world may contain two forms that look equivalent but differ in one observable (Q1 has one).
  A false EQUIVALENT is a scored error.

---

## 4. Hidden-oracle isolation protocol

Builds on the doctrine's sealed world oracle (DISCOVERY.md 6) and the public-commitment precedent
(`docs/brownian/PROFILE_COMMITMENT*.txt`, `spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md`).

1. The world generator, its source, its seeds and its answer keys live evaluator-side only. The
   evaluator world is separated from the AIEN world (same rule as DIRAC-0).
2. Before any candidate sees data, the evaluator publishes a commitment: a hash over the generator
   build, the world list and the scoring code. The commitment is public, the contents are not.
3. The candidate sees only neutral channels: `CHANNEL_nnn`, `OBSERVATION_TIME`,
   `MEASUREMENT_UNCERTAINTY`, `ACTION_HISTORY`. Channel order, scale, offset, frame and action ids are
   randomized per world.
4. The interface offers decoy actions and decoy channels so the menu does not reveal structure.
5. Interventions go through a metered oracle. The oracle answers only with data. It never refuses in
   a way that leaks (a refusal pattern is a signal), so refusals are randomized or budget-based.
6. The candidate commits its predictions before reveal. Reveal happens once. One sealed evaluation per
   candidate per world set. Retries use fresh worlds.
7. An attempt counter records every submission. Selection among attempts is penalized (section 8).
8. No candidate controls its own holdout, baseline, scoring or promotion.
9. Atlas documents and world specifications are on an evaluator-only list. Nothing in the public
   repository may let a candidate derive a hidden law. Public specs state families and scoring, never
   seeds, parameters or key material.
10. Seal storage location is an owner decision. This document does not touch `aien-sealed`. Placement
    of public fixtures versus sealed keys follows the rule in DIRAC-0. Sealing itself is BLOCKED_OPERATOR.

---

## 5. Scoring dimensions

Scoring extends the doctrine's eleven-dimension Pareto surface (DISCOVERY.md section 10). The Atlas
does not collapse it to one number. Each rung states which dimensions apply.

| Dimension | What it measures |
|---|---|
| D1 held-out prediction | log score or error on unseen conditions |
| D2 intervention prediction | accuracy on interventions never shown |
| D3 calibration | stated uncertainty matches observed error |
| D4 compression | held-out description-length gain (TURING-style T) |
| D5 structure recovery | correct symmetry, invariant, algebra, as judged by equivalence level |
| D6 invariant honesty | DISCOVERED, NOT FOUND, REJECTED labels match truth |
| D7 null honesty | no law emitted in null worlds |
| D8 distinguishing experiments | proposes the experiment that separates rival theories |
| D9 validity-region accuracy | declared region matches true region |
| D10 failure reporting | discrepancy model identifies real failures |
| D11 cost | compute and energy, reported, not traded for correctness |

Rules: a false law in a null world is a hard failure regardless of other scores. Score reports carry
confidence bounds. Textbook vocabulary earns nothing, which keeps the rule from CURRENT_EXECUTION_PLAN
section 13.

---

## 6. First six benchmark specifications

Common fields for each spec: capability tested, hidden world (evaluator only), candidate interface,
interventions, splits, null and adversarial worlds, tasks, required Theory fields, applicable
dimensions, planted equivalences, validity ladder, oracle independence, validity gates, leakage risks,
prerequisites, status. All six share these benchmark validity gates:

- BV1: an oracle-solver (told the hidden law) must reach the top score.
- BV2: trivial baselines (constant, linear fit, nearest neighbour) must fail the gate.
- BV3: a null solver (emits no law) must pass null worlds and fail signal worlds.
- BV4: mutation tests. Perturb the oracle law slightly. The scorer must notice.
- BV5: label permutation. Shuffling channel labels must not change the score.
- Status of every gate for every spec: NOT_RUN (no evaluator exists).

### PZ-A Classical identifiability

- Capability: telling observable from latent; refusing to name what data cannot fix.
- Hidden worlds: low-dimensional mechanical and coupled-oscillator systems; hidden parameters; some
  quantities visible only through an indirect channel (latent concept variants); distractor channels
  that are independent noise; null worlds with noise only.
- Interface: neutral channels, time series, a small action set with decoys.
- Interventions: set initial conditions, apply impulses, hold a variable.
- Splits: training conditions, held-out initial conditions, held-out interventions.
- Adversarial worlds: a degenerate parameter pair that no data can separate (a correct answer says so).
- Tasks: predict, intervene, name latents or declare them unidentifiable.
- Required fields: LATENT_VARIABLES, RELATIONS, DYNAMICAL_RULES, UNCERTAINTY_MODEL, COUNTEREXAMPLES.
- Dimensions: D1, D2, D3, D5, D7, D10.
- Planted equivalences: E1, E2, E7.
- Validity ladder: identifiable parameters recovered, unidentifiable ones flagged, null worlds quiet.
- Gate (proposed): at least 90 percent of signal worlds above threshold and zero false laws across
  60 null worlds (rule of three bounds the false-discovery rate near 4.9 percent at 95 percent).
- Leakage risks: L1, L3, L5, L12.
- Prerequisites: evaluator, reference solver. None from AIEN. Status NOT_RUN.

### PZ-B Variational and Noether

- Capability: a law as a scalar functional; symmetry to conservation links.
- Hidden worlds: systems derived from a hidden action with one or more continuous symmetries; some
  worlds with a broken symmetry; non-uniqueness through L plus a total derivative.
- Tasks: propose an action, state symmetries as invariant claims, predict conserved quantities.
- Evaluator checks: self-consistency (first variation of the candidate action along its own predicted
  paths vanishes within tolerance) and Noether pairs (the claimed symmetry yields the claimed
  conserved quantity).
- Required fields: DYNAMICAL_RULES, symmetries, invariants, gauge_equivalences.
- Dimensions: D1, D2, D4, D5, D6, D7.
- Planted equivalences: E4, E6, E7.
- Adversarial worlds: a conserved-looking quantity that drifts slowly; an action that fits training
  data but violates its own variation.
- Gate (proposed): invariant labels correct in at least 90 percent of worlds including broken-symmetry worlds.
- Leakage risks: L1, L9, L13.
- Prerequisites: reference solver; real-valued numerics. Status NOT_RUN.

### PZ-C Fields: wave, diffusion, 2+1D Maxwell-like

- Capability: laws over fields; differential operators as law content; gauge freedom.
- Hidden worlds: wave (finite speed), diffusion (infinite speed, irreversible), and a 2+1D gauge-like
  field with "gauge-scrambled sensors" (sensors report potentials that differ by an unobservable shift).
- Interventions: localized sources, boundary changes.
- Tasks: identify operator structure, predict fields, state gauge equivalence as a declared
  transformation with an observation map.
- Required fields: RELATIONS, DYNAMICAL_RULES, boundary_conditions, gauge_equivalences, validity region.
- Dimensions: D1, D2, D5, D6, D9.
- Planted equivalences: E2, E5, E6.
- Null world: random smooth field with no dynamics.
- Gate (proposed): operator class correct and gauge claim accepted by transformation witness.
- Leakage risks: L1, L4, L9.
- Prerequisites: grid fields, differential operators (MISSING_IMPLEMENTATION in Omega today).
  Status NOT_RUN.

### Q0 Complex amplitudes

- Capability: compact complex structure with a global phase gauge, without requiring complex numbers.
- Hidden worlds: finite-dimensional unitary evolution observed through measurement counts; a
  classical stochastic null world with the same count statistics at one setting; decoherence worlds.
- Key insight to score: N squared parameters for a unitary-structured generator versus
  N(2N-1) for an unconstrained real antisymmetric generator in R^(2N). The benchmark rewards the
  compact structure and accepts a real encoding.
- Tasks: predict counts, state global phase as an invariant claim, tell classical stochastic from unitary.
- Dimensions: D1, D3, D4, D5, D6, D7, D10.
- Planted equivalences: E3, E5, E6.
- Adversarial: slight decoherence, which a unitary-only theory must report as a discrepancy.
- Gate (proposed): classical-stochastic null worlds are not mislabeled as unitary.
- Leakage risks: L1, L4, L9, L14.
- Prerequisites: complex or paired-real value type (MISSING_IMPLEMENTATION). Status NOT_RUN.

### Q1 State evolution versus observable evolution

- Capability: first cross-formalism rung: evolving state versus evolving observable.
- Hidden worlds: same predictions generated both ways, plus a false-equivalence trap whose two forms
  differ on one rarely probed observable.
- Tasks: submit a theory in either form, submit a link to an equivalent form, or flag
  non-equivalence with a witness.
- Required fields: algebra, theory links, observation map.
- Dimensions: D1, D5, D8.
- Planted equivalences: E3, E8. Trap: a false E8.
- Gate (proposed): the trap form must be marked NOT_EQUIVALENT with a witness.
- Leakage risks: L1, L9, L11.
- Prerequisites: theory-link edges; J-Space theory-level identity. Status NOT_RUN.

### Q2 Mixed states, ensemble ambiguity, open dynamics

- Capability: many ensembles give one state; purification is an equivalent form; decoherence is a
  discrepancy from unitary law.
- Hidden worlds: mixed-state preparation with several ensemble decompositions; Lindblad-type dephasing
  with rate gamma (decay exp(-gamma t) for the standard sigma-z jump operator with rate gamma over 2);
  a hostile slight-dephasing world.
- Tasks: predict, declare the ensemble unidentifiable, supply a purified form, report the dephasing
  discrepancy with a rate and an uncertainty.
- Dimensions: D1, D3, D5, D7, D9, D10.
- Planted equivalences: E3, E8 (purification), jump-operator mixing freedom.
- Controls: a Liouville-type classical control (redundant family kept as a control).
- Gate (proposed): ensemble claims refused where only the state is identifiable.
- Leakage risks: L1, L4, L14.
- Prerequisites: complex or paired-real types, matrix exponential, distribution-valued laws.
  Status NOT_RUN.

---

## 7. Leakage model

| Id | Risk | Mitigation |
|---|---|---|
| L1 | direct names and units in channels | neutral ids, randomized order, scale, offset |
| L2 | metadata and file timestamps | sealed generator output, scrubbed metadata |
| L3 | statistical structure of datasets reveals family | decoy and null worlds, mixed generators |
| L4 | instrument spec reveals structure | spec states noise and range only |
| L5 | intervention menu reveals structure | decoy actions, equal-looking menus |
| L6 | oracle refusals carry information | budget-based, randomized refusals |
| L7 | lineage and inherited priors | AIEN-P0 clean lineage rule (DISCOVERY.md section 5) |
| L8 | Atlas documents in the public repo | evaluator-only list, no seeds or parameters in public |
| L9 | physics-named primitives | generic primitives only (section 2.4) |
| L10 | selection and p-hacking | attempt counter, selection penalty |
| L11 | taxonomy disclosure | decoy and null families, a held-back golden challenge |
| L12 | timing side channels | fixed-latency responses |
| L13 | train and test leakage inside a world | split by condition, not by sample |
| L14 | adaptive overfitting to scoring feedback | single-shot sealed evaluation, commit before reveal |
| L15 | human or LLM in the loop, single-operator risk | logged operator actions, independent evaluator |

Checks: canary tokens in sealed material, label-permutation tests, null-interface tests.

Honest status: the current AIEN stack is not AIEN-P0 clean, and no clean lineage exists because the
M24 lineage work is missing. Early runs therefore use reference solvers and baselines. Any run by
today's AIEN stack is an inherited-knowledge experiment outside Physics Zero (DISCOVERY.md 16.7) and
must be labeled that way.

---

## 8. Falsification rules

An Atlas result is falsified, and the claim withdrawn, when any of these holds.

1. F1: a candidate emits a law in a null world. Hard fail for that world.
2. F2: oracle-solver (BV1) fails to reach top score. The benchmark is broken, not the candidate.
3. F3: a trivial baseline (BV2) passes. The benchmark is too easy.
4. F4: a label permutation changes the score (BV5). The scorer leaks labels.
5. F5: a mutated oracle (BV4) is not noticed. The scorer is blind.
6. F6: two independent scorers disagree on any item (section 9). Result is NOT a PASS until resolved.
7. F7: a candidate passes after more than the allowed attempts without correction.
8. F8: a false EQUIVALENT on a planted trap.
9. F9: a claimed invariant fails its own transformation test on fresh data.
10. F10: any evidence of contact with sealed material. The run is void.
11. F11: held-out performance falls below the stated confidence bound.

A falsified benchmark is recorded as FAIL with the rule number, never silently repaired.

---

## 9. Independent evaluator contract

- Language: C11. No Python. No new Rust.
- Two independent implementations: a primary evaluator and an independent scorer, written by different
  workers, sharing no source. The EXP-001R precedent (312 values, 0 mismatches) is the model.
- Separate from Omega: the evaluator imports no candidate code and no AIEN runtime.
- Deterministic: same inputs and seeds give byte-identical receipts.
- Content-addressed receipts: the receipt hashes the evaluator build, the world list commitment, the
  candidate submission and the scores. The evaluator refuses to run from a dirty tree.
- Fail-closed ordered checks: (1) commitments match, (2) submission well formed, (3) predictions
  committed before reveal, (4) leakage checks, (5) validity gates BV1 to BV5, (6) scoring,
  (7) independent scorer agreement, (8) verdict.
- Verdict vocabulary: PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, MISSING_IMPLEMENTATION,
  plus the golden-challenge verdicts defined in the Lane 36 brief section 19 (DISCOVERED,
  NOT_FOUND, REJECTED, INCONCLUSIVE for invariant claims).
- The evaluator verdict never grants authority. It cannot promote a candidate, change a policy or
  open a capability.
- The independent human or agent evaluator is BLOCKED_OPERATOR.
- Seal storage location is an owner decision, `aien-sealed` is not touched here.

---

## 10. Dependency map

All paths are real and were read on 2026-10-01 from arch main 921797b and omega main 07004a8.

| Need | Where it lives or should live | Real status |
|---|---|---|
| Theory and concept objects | `doctrine/DISCOVERY.md` sections 7.1, 7.2 | doctrine only |
| Roadmap rows M27 to M35 | `doctrine/ROADMAP.md`; plan section 13 in `CURRENT_EXECUTION_PLAN.md` | planned |
| Semantic categories, type system | omega `spec/semantic-object.md`, `spec/type-system.md` | no real, complex or tensor types |
| Canonical ids | omega `src/omega_canonical.h`; program id v2 omega #75 (805a3a6) | implemented |
| Contracts (RC_HYPOTHESIS, RC_EVIDENCE) | omega `src/runtime/rx_contract.{h,c}` | implemented, exact-only |
| Verifier V0 to V2 | omega `src/omega_verify.{h,c}` | V3 to V5 are stubs |
| Compiler for models | omega OSC slice | cannot express floating-point models; Program IR has no FP32 value type |
| Numerics | E1 PRs #124, #127, #134, #147, #152 (07004a8) | F32 scalar tier only; transcendentals bounded, CPU only; exactness decision arch #76 |
| Tensors | omega M20 PR #136 (draft) | CPU only, no complex, no GB10 path, NOT QUALIFIED |
| Differential operators | none | MISSING_IMPLEMENTATION |
| Estimation | omega `src/estimation/est_types.h`; v4 omega #153 | EST-3 v1 to v3 FAIL; v4 no verdict; EST-4 to EST-10 blocked |
| Description-length score | omega `src/turing/ty_*`; `docs/turing/TURING_SCIENTIFIC_QUALIFICATION_STATE.md` | TY-2 PASS; T/J not started; selector kill test FAILED |
| Independent scorer precedent | EXP-001R | 312 values, 0 mismatches |
| Sealed commitment precedent | `docs/brownian/PROFILE_COMMITMENT*.txt` (omega #100 to #104); `spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md`, `src/searchtrace/st_holdout.{h,c}` | sealing BLOCKED_OPERATOR |
| J-Space | omega `src/runtime/rx_jspace.{h,c}`, omega #116 (529ebfa) | no theory-level identity; 32-bit generation wrap |
| Cortex (negative knowledge) | omega `src/runtime/rx_cortex*.{h,c}`; ADR 0022 | implemented, not qualified |
| Fabric | omega `src/fabric` | host only, one process |
| Evolution Arena | `docs/specs/EVOLUTION_ARENA_SPEC_V1.md` | spec merged, runtime on hold, Physics Zero out of scope for V1 |
| Dirac rung | `docs/plans/dirac/DIRAC-0-SPEC.md`, ADR 0023 (arch PR #83) | proposed, unmerged |
| Name collision to avoid | omega `src/algebra/oma_*` | mixed trit algebra, not physics operator algebra |
| Name collision to avoid | omega `src/omega_discovery.{h,c}` | program-abstraction mining (M11), unrelated to physics |

Consequences:

- Can begin now with no AIEN capability: evaluator, world generators, reference solvers, independent
  scorer, commitments (all C11, evaluator-side).
- J-Space needs a theory-level identity before Q1, X-0 and SC-0 can be scored as cross-formalism.
- The compiler cannot express floating-point models, so no AIEN-authored law can be executed by
  Omega yet. This blocks running candidates through Omega, not designing the benchmarks.
- PZ-ACTIVE waits on the TURING selector and EST-10.
- No run counts as Physics Zero until a clean P0 lineage exists.

---

## Closing summary

What exists. Doctrine for Theory objects, the sealed oracle and the pyramid. A scoring idea (TURING
description-length gain) and an independent-scorer precedent. Sealed-commitment precedent from the
Brownian work. A Dirac plan in review. Host-level runtime pieces (Cortex, J-Space, World) that are
implemented and not qualified.

What is missing. Real, complex and tensor value types. Differential operators. Floating-point
expression in the Omega compiler. A tensor layer that is merged and qualified. A theory-level identity
in J-Space. A clean AIEN-P0 lineage. Any evaluator code. Any world generator. The independent human or
agent evaluator.

What must wait. EST-3 and everything behind it (calibrated uncertainty claims in D3 for AIEN runs).
TURING selection (PZ-ACTIVE, D8 for AIEN). M20 (tensor-valued rungs on AIEN hardware paths).
Sealing of any commitment (BLOCKED_OPERATOR).

What can begin now. The C11 evaluator and independent scorer; world generators for PZ-A, PZ-B and
PZ-C; reference solvers; null and adversarial world libraries; commitments in public form; the
leakage canary and label-permutation tooling; a Q0 spec using a paired-real encoding.

Capabilities that earn their place across several rungs. Declared transformation with observation map
(Noether, gauge, basis, coordinates, field redefinition). Invariant claims with honest labels (PZ-B,
PZ-C, Q0, Q3, S0). Theory-link edges (Q1, X-0, T-0, SC-0). Discrepancy models (Q0, Q2, S2, T-0).
Distribution-valued laws (S1, Q0, Q2, Q4). Testable validity regions (SC-0, S2, T-0). Value types for
complex and tensor (Q0, Q1, Q2, F rungs, Q6).

Recommended next specs: SC-0 and X-0, because Drake's emphasis is laws that change with scale and the
same physics in different forms. Alternative: swap Q2 for SC-0 in the first six if the quantum
prerequisites (complex types) are judged too far away. The recommendation is to keep the six as written
and write SC-0 and X-0 next.
