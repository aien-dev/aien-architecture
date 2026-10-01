# ADR 0026: Sealed Discovery Examinations

**Status:** PROPOSED, 2026-10-01. Source: operator research direction of that date (research synthesis handoff, sections 6, 7, 18, 19, 24). Not accepted until the operator accepts it. Nothing in this document is implemented.
**Scope:** P12 (Physics Zero), as labeled in the operator brief. Roadmap rows M27 to M35 (`doctrine/ROADMAP.md`). This label is the Physics Zero phase of the hive phase map; it is unrelated to the hardening-plan item "P12" cited in ARCH-0025.
**Supersedes:** nothing. **Amends:** nothing.
**Extends:** ARCH-0023 (DIRAC-0) by placing Dirac as the first rung of a ladder of examinations that share one rule, one secrecy boundary and one pass criterion.
**Related:** ARCH-0019 (mixed algebra realization), ARCH-0020 (belief and estimation), ARCH-0021 decision 3 (append-only receipts bound to clean commits), ARCH-0023 (DIRAC-0 program), ARCH-0025 (execution transcript).
**Evidence base:** read-only scout of 2026-10-01 against omega `38919c8` and aien-architecture `8d24c6d` (orchestrator handoff `2026-10-01-EXAMS-SCOUT-scout.md`). Every current-state claim below carries a pointer from that scout. Paths starting `src/`, `tools/`, `spec/`, `docs/turing/` or `research/` are in `aien-dev/omega`; other paths are in this repository. Code beats plans. Nothing here raises any status.
**Citation:** from other repositories, cite this decision as ARCH-0026.

---

## In plain words (read this first)

Dirac, Zeta-style spectral structure, symmetry and supersymmetry are well known to humans. If AIEN is handed those answers, any "discovery" proves nothing. This decision treats them as **exams**: sealed tests where the evaluator knows the answer and AIEN never sees it. AIEN would get only generic mathematical tools and data. An exam passes only if AIEN finds a new way of describing the data that predicts held-back data better, after paying for how complicated that description is.

None of the four exams can start yet. The tools AIEN would need are mostly missing or partial, the measurement that would score them (EST-3) has failed so far, and the sealing step needs Drake's owner signature.

## 1. Decision

```text
NEVER GIVE AIEN THE NAMED ANSWER WHEN THE EXPERIMENT TESTS DISCOVERY.
DIRAC, ZETA, SYMMETRY AND SUSY ARE SEALED EXAMINATIONS HELD AS HIDDEN
EVALUATOR KNOWLEDGE. NONE OF THEM IS EVER AN OMEGA PRIMITIVE, TYPE, MODULE
OR NAMED CAPABILITY. AIEN RECEIVES ONLY GENERIC CAPABILITIES THAT ARE
JUSTIFIED ON THEIR OWN AND SEALED OBSERVATIONS.
```

This repeats the ARCH-0023 section 2 rule ("DIRAC IS A CONFORMANCE FIXTURE AND HIDDEN EVALUATOR KNOWLEDGE, NEVER AN OMEGA PRIMITIVE") and extends it to every rung of the ladder.

Consequences:

- No artifact readable by AIEN may name the target theory, its equation, its constants, its generators or its canonical basis. Identifiers in Omega code stay generic (for example "anticommutator", never a theory name).
- Each generic capability added for an exam must be justified as generic work, the way ARCH-0023 section 3 requires for D0.1 complex values.
- Answer keys, oracles and decoy generators live outside everything AIEN can read and share no code with the candidate path (ARCH-0023 section 3; Physics Zero Law Atlas V1 draft section 4, `docs/plans/physics-zero/PHYSICS_ZERO_LAW_ATLAS_V1.md` line 196).

## 2. Shared pass criterion: a representation transition

A **representation transition** is a change in how AIEN describes the sealed observations (for example from a scalar fit to a multi-component operator form, or from an analytic series to a spectrum). A transition **counts as passed** only if all of the following hold:

1. It improves withheld explanatory performance on the sealed held-out observations after complexity is charged: positive Turing gain under the frozen profile.
2. The profile is frozen and committed before the held-out set is revealed, and the held-out set is scored once.
3. Every hostile control in the exam's control list behaves as specified.
4. The verdict is written to an append-only receipt bound to a clean commit (ARCH-0021 decision 3).

Where the profile is defined today (scout item 6):

- `docs/turing/TURING_YIELD_PROFILE_V0.md`, status PRE-REGISTERED 2026-09-29 (line 3): tuning on seeds 1 to 7, held-out seeds 8 to 10 scored once by `turing-yield heldout`. T is net held-out description-length gain.
- "Positive Turing gain" has no formal definition in either repository (scout item 6). This ADR uses it to mean T > 0 under the frozen profile.
- "Net Turing gain" (T minus declared search and compute cost) is a new DIRAC-0 definition pending TURING owner review (`docs/plans/dirac/DIRAC-0-SPEC.md` lines 170 to 172; ARCH-0023 section 3; ARCH-0020 line 105). Exams should report both T and net Turing gain; the pass bar uses whichever the TURING owner accepts. Until that review closes, the pass criterion is incomplete and no exam verdict can be PASS.

## 3. Shared hostile controls

Every exam runs these controls alongside the real run. Each control has an expected outcome; a control that does not behave as expected voids the exam.

| Control | What it is | Expected outcome |
|---|---|---|
| Shuffled data | Same observations with temporal or index order shuffled | No transition passes; T near zero or negative |
| Label-permuted data | Component, channel or sector labels permuted at random | The claimed structure does not survive, or survives only up to the permutation |
| Named-answer leakage canary | A unique marker string and a decoy equation planted in evaluator-only material; every AIEN-readable input, corpus and output is scanned for both | Zero hits. Any hit voids the run and the seal |
| Complexity-penalty-off control | Same search with the description-length charge disabled | Must be reported. If the transition appears only with the penalty off, it does not count |
| Decoy structures | Sealed worlds that carry a structurally similar but different law (wrong signature, broken closure, near-miss spectrum) | AIEN prefers the decoy's own structure on the decoy and the true structure on the true world; it does not report the named target on both |
| Budget-matched baseline | Search with the generic capability being tested withheld | Records how much of the gain the capability earns |

## 4. The examination ladder

Each exam is a blind or partially blind evaluation domain. "Blind" means AIEN sees observations only. "Partially blind" means AIEN also sees declared generic constraints (for example "the world has a conserved quantity") without the named theory.

Status words in the prerequisite tables are the scout's: EXISTS, PARTIAL, MISSING, each with the scout's pointer (scout Part A). No status is raised here.

### 4.1 Exam A: Dirac (blind discovery of a first-order multi-component law)

Owner of detail: ARCH-0023 and `docs/plans/dirac/DIRAC-0-SPEC.md` (gates 0 DIRAC-PREP, 1 D0 algebra, and onward; spec lines 181 to 182). This section adds no Dirac rule and weakens none; it records the prerequisites and controls in the shared ladder format.

Generic prerequisites:

| Capability | State | Pointer |
|---|---|---|
| Complex values | PARTIAL | `src/algebra/phase_twin.c:63-70` static helpers in a simulator; `OmegaDType` is F32/F16/BF16 only (`src/tensor/omega_tensor.h:95-98`) |
| Multi-component state | PARTIAL | `src/tensor/omega_tensor.h` real tensors; no complex or spinor component type |
| Linear operators | PARTIAL | `src/omega_matvec.h:65-86` (u64), `src/tensor/omega_tensor.h:68-76` matmul; no operator object |
| Matrix composition | PARTIAL | `src/omega_blackwell_matmul.h:48-64`; `src/tensor/omega_tensor.h:75`; no operator-algebra layer |
| Noncommutative composition | PARTIAL | `src/omega_program.h:26-29,131-142` sequence composition; not operator algebra |
| Commutators | MISSING | zero hits in src/tools/tests |
| Anticommutators | MISSING | zero hits |
| Metric / signature | MISSING | only crypto "signature" hits (`src/searchtrace/st_holdout.c:425`) |
| Differential operators | MISSING | no autodiff, no finite differences; `src/train/tg_sgd.h:2` takes a caller-supplied gradient |
| Constraints | EXISTS (checking only) | `src/omega_types.h:102-109`, `src/omega_validate.c:98-101`, `src/omega_core.h:17`, `src/omega_program.h:151`; no solver |
| Basis transformations | MISSING | `src/algebra` rns/bitplane/trit/z3 are encodings, not basis maps |

Sealed held-out observations: field samples from a hidden first-order multi-component evolution law, generated by the evaluator-only oracle (omega `research/dirac-oracle/`, not built: `README-NOT-BUILT.md`), with held-out regimes (masses, momenta, boundary conditions) committed under G3 before any run.

Passed representation transition: the move from per-component scalar fits to a coupled multi-component operator description whose composition rule (for example an anticommutation closure) is found by search, and which yields positive Turing gain on the held-out regimes under the frozen profile (section 2).

Hostile controls: section 3, plus a decoy world with a wrong metric signature and a decoy whose components decouple.

NOT claimed:

- That Omega represents complex values, spinors, commutators or a metric today.
- That AIEN has derived, or will derive, the Dirac equation.
- That passing Exam A shows understanding of relativistic quantum mechanics. It shows only that a compressing multi-component structure was found on sealed data.
- That ARCH-0023's `DIRAC_PREP_FROZEN` gate has passed (it is proposed, not passed; scout item 3).

### 4.2 Exam B: Zeta-style spectral representation transitions

The exam asks whether AIEN moves through a chain of representations of the same sealed object, each move earning its keep: **analytic -> operator -> spectral -> geometric/topological**. AIEN is never taught the Riemann hypothesis, a "Zeta Space", the critical line or any named conjecture.

Generic prerequisites:

| Capability | State | Pointer |
|---|---|---|
| Complex values (complex analysis) | PARTIAL | `src/algebra/phase_twin.c:63-70`; not an Omega type |
| Linear operators | PARTIAL | `src/omega_matvec.h:65-86`; `src/tensor/omega_tensor.h:68-76` |
| Spectra / eigenvalues | PARTIAL | `tools/ty_energy_reduce.c:399` `eig3`, static symmetric 3x3 Jacobi in an offline tool |
| Graphs | EXISTS | `src/runtime/rx_graph.h:1-14`, `src/omega_machine.h`; dependency and machine graphs, not mathematical graph algorithms |
| Topology | NOT ASSESSED | not in the scout table; must be checked before Exam B is scheduled |
| Group action / symmetry generators | MISSING | hits are RNG/digest "generator" only |
| Noncommutative composition | PARTIAL | `src/omega_program.h:26-29,131-142` |
| Integral transforms | MISSING | no fourier/fft/dft hits |
| Symmetry constraints | EXISTS (checking only) as generic constraints | `src/omega_types.h:102-109`; no symmetry-specific constraint |

Sealed held-out observations: evaluator-generated sequences and functions whose hidden structure is spectral (for example eigenvalue statistics of a hidden operator, or values of a hidden analytic function), with held-out ranges and held-out instances committed under G3.

Passed representation transition: each arrow in the chain is scored separately. An arrow counts only if the new representation gives positive Turing gain on the held-out set over the previous representation, under the frozen profile. Reaching a later stage without earning the earlier arrows does not count.

Hostile controls: section 3, plus a decoy whose spectrum is drawn from an unrelated random-matrix ensemble and a decoy whose analytic form has no operator realization in the search space.

NOT claimed:

- Anything about the Riemann hypothesis or any open conjecture.
- That Omega has spectra, transforms, topology or group action today.
- That a passed arrow is a mathematical proof. It is a held-out compression result only.

### 4.3 Exam C: Symmetry discovery

The exam asks whether AIEN finds transformations under which the sealed world's behavior is unchanged, and uses them to predict unseen behavior more cheaply.

Generic prerequisites:

| Capability | State | Pointer |
|---|---|---|
| Group action / symmetry generators | MISSING | hits are RNG/digest "generator"; `src/algebra/oma_z3.*` is Z3 arithmetic, not group action |
| Basis transformations | MISSING | encodings only in `src/algebra` |
| Constraints | EXISTS (checking only) | `src/omega_types.h:102-109`, `src/omega_program.h:151` |
| Linear operators | PARTIAL | `src/omega_matvec.h:65-86` |
| Commutators | MISSING | zero hits |
| Multi-component state | PARTIAL | `src/tensor/omega_tensor.h` |
| Declared transformation, invariant claim (design primitives) | design only | Law Atlas V1 draft section 2.4 line 116; DRAFT design, no code |

Sealed held-out observations: trajectories from hidden worlds with a hidden symmetry group, held-out initial conditions related to training ones by transformations not shown during training, committed under G3.

Passed representation transition: from a description of trajectories to a description of trajectories plus a transformation set and its invariants, with positive Turing gain on the held-out transformed conditions under the frozen profile.

Hostile controls: section 3, plus a decoy world with explicitly broken symmetry (a small symmetry-breaking term) where a symmetry claim must lose, and a label-permuted control that destroys the group structure.

NOT claimed:

- That Omega has group action, generators or basis maps today.
- That AIEN discovers conservation laws in general. Only the sealed worlds tested count.

### 4.4 Exam D (future): SUSY-style relations between state classes

Future rung. No hard-coded supersymmetry theory, type or module. The exam asks whether AIEN finds a relationship between two classes of states because that relationship compresses unseen behavior.

Generic prerequisites:

| Capability | State | Pointer |
|---|---|---|
| Graded structures | MISSING | no graded/grassmann/parity hits; z2 hits are a statistics variable (`src/algebra/phase_twin.c:384`) |
| Multiple state sectors | PARTIAL (as multi-component state) | `src/tensor/omega_tensor.h`; no sector concept in the scout table |
| Graded commutators | MISSING | no commutator or anticommutator hits |
| Grassmann-style machinery | MISSING | no hits |
| Symmetry generators | MISSING | see Exam C |
| Field/operator relations | NOT ASSESSED | not in the scout table; would depend on linear operators (PARTIAL) and differential operators (MISSING) |

Sealed held-out observations: spectra or dynamics of a hidden two-sector system with a hidden pairing, held-out sectors and parameter ranges committed under G3.

Passed representation transition: from two independent sector descriptions to a single description with a cross-sector map, with positive Turing gain on held-out sectors under the frozen profile.

Hostile controls: section 3, plus a decoy two-sector system with near-degenerate but unpaired spectra, where a pairing claim must lose.

NOT claimed:

- Anything about supersymmetry in nature.
- That any prerequisite for Exam D exists in Omega today.
- A schedule. Exam D is not planned for any milestone yet.

## 5. Phase-map placement and prerequisites

All four exams sit in P12 (Physics Zero), roadmap rows M27 to M35, all PLANNED (`doctrine/ROADMAP.md` lines 66 to 74; `CURRENT_EXECUTION_PLAN.md` Phase J, lines 573 to 587). No exam may start until every prerequisite in its row closes.

Shared prerequisites, current state per the scout:

| Prerequisite | Current state | Pointer |
|---|---|---|
| EST-3 calibrated estimation | FAILED on main (v1, v2, v3 at Phase A). v4: INCONCLUSIVE (omega#153 merged 2026-10-01); v5 in progress (omega#170, open). EST-4 and EST-5 blocked | `CURRENT_EXECUTION_PLAN.md:96` at f81e4ce; omega#129 `d78fd11`; arch#80 `ac83f0d` (scout item 5) |
| G3 sealed evaluation | Format and code PASS with TEST keys only; owner signing and sealing BLOCKED_OPERATOR | `CURRENT_EXECUTION_PLAN.md:93`, G3 definition lines 491 to 505; `spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md` lines 3, 162 to 168 (scout item 1) |
| M20 OMEGA_TENSOR | omega#136 merged, `src/tensor/` on main; GB10 NOT_RUN; M20 not qualified; roadmap row not rechecked | plan section E2 line 338 (scout item 5) |
| M21 OMEGA_AUTODIFF | Plan only (E3 line 347); no code in omega | scout item 5 |
| M27 PHYSICS_ZERO_PROTOCOL | PLANNED; Law Atlas V1 is a DRAFT design | `doctrine/ROADMAP.md:66`; `docs/plans/physics-zero/PHYSICS_ZERO_LAW_ATLAS_V1.md` (scout item 4) |
| TURING profile and pass bar | Profile PRE-REGISTERED; "positive Turing gain" undefined; "net Turing gain" pending TURING owner review | section 2 above (scout item 6) |
| DIRAC-0 / ARCH-0023 | PROPOSED, not accepted; `DIRAC_PREP_FROZEN` proposed, not passed | `docs/adr/0023-dirac-0-program.md` (scout item 3) |

Per exam:

| Exam | Must close first |
|---|---|
| A Dirac | All shared rows; ARCH-0023 accepted and `DIRAC_PREP_FROZEN` passed; D0.1 complex values and the MISSING rows in 4.1 built as generic capabilities |
| B Zeta-style spectral | All shared rows; Exam A's generic operator work; spectra, integral transforms, group action and topology (after it is assessed) built as generic capabilities |
| C Symmetry | All shared rows; group action, basis transformations and commutators built as generic capabilities |
| D SUSY-style (future) | Exams A and C passed; graded structures and Grassmann-style machinery built as generic capabilities; a new decision record before scheduling |

## 6. Research directions (HYPOTHESIS)

Both items in this section are research hypotheses. Neither exists in Omega today.

### 6.1 HYPOTHESIS: CEGIS-style SearchTrace counterexamples

CEGIS (counterexample-guided inductive synthesis) does not exist in Omega today. No mention of CEGIS was found in omega or this repository (scout item 8).

What exists: SearchTrace records each synthesis step observe-only, including prune reason (NONE/TYPE/COST/EQUIV/BUDGET), verdict (NONE/REJECT/SOLVED/VERIFY_FAIL) and a 32-byte equivalence signature (`src/searchtrace/st_hook.h:21-77`; emit sites `src/omega_synthesis.c` 176, 254 and `src/omega_realize_synth.c`). The G1 corpus passed with 12 tasks and 3072 steps (`CURRENT_EXECUTION_PLAN.md:78`); training is NOT_RUN and waits on M22 (scout item 7).

Hypothesis: turn SearchTrace history into reusable pruning.

```text
failure Y -> counterexample C -> generalized constraint G
          -> attach G to a semantic region -> prune candidates violating G
```

Measurement (defined here, not run):

- Freeze a task set and the synthesis budget before measuring.
- N = number of candidates SearchTrace records before G exists, on the frozen task set.
- M = number of candidates SearchTrace records after G is attached, on the same frozen task set.
- Report N, M and the ratio M / N.
- Soundness check: replay every candidate accepted as correct in the N run against the pruned search. If any previously accepted correct candidate is pruned by G, the result is unsound and the ratio is not reported as a gain.
- Optional link to section 2: if G also yields positive Turing gain as a reusable rule on held-out tasks, record that separately.

### 6.2 HYPOTHESIS: e-graphs and equality saturation as a reference

E-graphs and equality saturation do not exist in Omega. They appear only as doctrine prose (`doctrine/OMEGA.md` lines 486, 496; `doctrine/INDEX.md` lines 155, 161). `ST_PRUNE_EQUIV` in `src/omega_synthesis.c:176,254` is probe-signature equivalence pruning, not an e-graph (scout Part A note, item 8).

Hypothesis: e-graphs and equality saturation are a research reference for treating rewritten expressions, basis changes, coordinate systems, gauge-related states and equivalent implementations as **one** discovery. For the exams, this would stop the Turing score from counting the same structure twice under two encodings, and would let decoy controls check that a "new" representation is not a rewrite of an old one. No design is adopted here.

## 7. BLOCKED: items only Drake can do

These stay blocked until Drake acts. No agent may work around them, sign in Drake's place, use TEST keys as a substitute for the owner seal, or treat a recommendation as a decision.

1. **G3 owner signature.** Real owner signing and sealing of held-out commitments, done with the owner key in the offline owner key ceremony (`spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md` line 162; BLOCKED_OPERATOR per `CURRENT_EXECUTION_PLAN.md:93`). No exam observations can be sealed until this is done.
2. **Brownian Wave 2 decisions D1 to D4.** `aien-dev/aien-sealed` PR #1 (draft EXP-003 contract), open with no comments: D1 Grok route, D2 mixture format, D3 GPU row, D4 ordering after BRN-10. No evidence any is decided (scout item 2). The contract cannot seal before BRN-10 seals.

## 8. What this decision does not do

- It adds no code, primitive, type, module or test.
- It changes no milestone status and no execution order in `CURRENT_EXECUTION_PLAN.md`.
- It does not accept ARCH-0023 or define the Turing pass bar; those stay with their owners.
