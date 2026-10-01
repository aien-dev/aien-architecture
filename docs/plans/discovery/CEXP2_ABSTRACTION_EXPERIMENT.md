# CEXP-2: Abstraction Learning versus Program Reuse

**NOT A MASTER PLAN.** This is a finite experiment specification for the discovery workstream. `CURRENT_EXECUTION_PLAN.md` owns cross-project sequencing and `doctrine/ROADMAP.md` owns milestone status. Nothing in this document is a milestone, and nothing in it is implemented.

**Spec version:** v1.0, written 2026-09-30. Status: FROZEN AS TEXT, BLOCKED (see section 10). Once a run's preregistration manifest is committed, the values in this document are binding for that run; any change is a new spec version and a new run.

**Parent document:** The Turing Discovery Gap Conjecture, Revision 6, 2026-09-30 (cited below as "Rev 6"). Rev 6 Appendix D freezes CEXP-1, the Claim C experiment. CEXP-2 extends CEXP-1 and reuses its accounting without change. Current facts about the apparatus are in `DISCOVERY_CURRENT_STATE.md` in this folder.

---

## 1. Question

Does a learner that extracts parameterized components from its admitted programs earn more net Turings on unseen tasks than a learner that reuses whole programs, under the same total budget, with every extraction, verification, storage and search cost charged?

CEXP-1 compares a library learner against an empty-library learner. That separates retention from no retention. It does not separate abstraction from caching or from whole-program recall, because its admission rule admits whole solutions and its generator shares components by construction. CEXP-2 adds the missing controls. Its headline comparison is **abstraction learning against program reuse**.

## 2. Accounting (inherited from Rev 6, not redefined)

- **Unit.** One Turing is one bit of net held-out description-length gain: T(M;B,D,X) = [L(B) + L(D|B,X)] − [L(M) + L(D|M,X)].
- **Decoder rule.** Anything available to the decoder beyond the input locations X is part of the model and is charged in L(M). A library entry, a cache entry or a component used by a task's model is written into that model and paid for in that task's L(M).
- **Efficient coding.** Encoding and decoding run in time polynomial in model and data size. A submission outside that bound, or one that does not decode losslessly, earns zero (Rev 6 Appendix A).
- **Gain density.** Every total is reported with its gain density, Turings per evaluated bit.
- **Two accounts.** Description costs are bits and enter the Turing account. Operating costs (search, extraction, verification, library and cache maintenance) are computation, counted in candidate evaluations, and enter the budget account. No conversion between the two accounts is used.

## 3. Apparatus

CEXP-2 runs on the apparatus CEXP-1 runs on, with the same frozen values. From Rev 6 Appendix D:

| Item | Frozen value (inherited from CEXP-1) |
|---|---|
| Apparatus | AIEN stochastic-law apparatus in its EXP-002 configuration (Rev 6 names it "Stochastic Law Discovery") |
| Measurement profile | the Turing profile the CEXP-1 run binds (see section 10 for the version question) |
| Coder | the profile's reference coder |
| Quantizer Q | 256 uniform bins over [-5, 5], out-of-range values clipped to edge bins |
| Baseline | uniform over quantization bins, 8 bits per observation |
| Model cost convention | 32 bits per fitted real parameter, 8 bits per small integer hyperparameter selected on context data |
| Context per task | 8 trajectories of 400 observations |
| Sealed evaluation per task | 4 trajectories of 400 observations, one-step-ahead, steps 1 to 399: 1,596 scored observations |
| Budget unit | one candidate evaluation = one candidate scored against the task's context data |
| Budget per task per arm | 20,000 candidate evaluations |
| Bootstrap | percentile bootstrap over sequences, 10,000 resamples, 95 percent interval |

**Program description code.** Library programs and components are structured objects, so the profile must define a prefix-free description code for them (Rev 6 Appendix A). The same code is used by all four arms. It is fixed in the preregistration manifest before the first sequence runs. If the bound profile has no admissible program code, CEXP-2 is blocked (section 10).

## 4. Arms

Four arms run the same task sequences, paired by seed, with identical per-task budgets. All four use the same discovery procedure and hyperparameters; they differ only in what they carry from one task to the next.

| Arm | Carries across tasks | Charged in bits (Turing account) | Charged in candidate evaluations (budget account) |
|---|---|---|---|
| **R: Reset** | nothing | nothing carried | nothing carried |
| **A: Answer cache** | input-output results only: the context observations of earlier tasks and the predictive distributions the arm produced for them, as a lookup table keyed by context window | every cache entry a task's model consults, per entry, under the decoder rule | every cache lookup and every cache write |
| **P: Program reuse** | whole programs admitted under Claim C's admission rule, reusable and composable as units | every library program a task's model references | admission checks, every scoring of a library-derived candidate |
| **E: Abstraction learning** | admitted whole programs plus admitted parameterized components (section 5) | every program and component a task's model references, and every reference to them | as P, plus every extraction, verification and component scoring step |

**Arm P equals CEXP-1's library learner.** It uses the CEXP-1 admission rule unchanged: after each task, a program that earned positive net Turings on that task's sealed evaluation, with its description length charged, is admitted. Any difference between arm P and the CEXP-1 library learner voids the CEXP-2 claim.

**Arm A is a control, not a contender.** Every task draws a fresh law and fresh sealed trajectories, so an answer table should almost never match a new context. Arm A is predicted to track arm R and to fall below it by whatever cache charges it pays. If arm A beats arm R beyond its interval, the generator or the blinding has leaked and the run is investigated before any claim is made.

**Per-task budget scope.** The 20,000 candidate evaluations of task t cover everything the arm does from the start of task t to the start of task t+1, including post-task admission, extraction and verification. An arm that spends budget on extraction after task t has that much less search on task t, never extra.

## 5. Abstraction extraction procedure (arm E only)

Extraction is a procedure that can fail at every step. It runs after task t's model is frozen and scored, inside task t's budget.

1. **Find repeated structure.** Search the admitted programs for a subprogram that occurs, up to renaming of parameters, in at least 2 admitted programs from different tasks.
2. **Propose a component.** Replace the differing constants of that subprogram with parameters. The result is a parameterized component with a description length under the program code.
3. **Verify behavior preservation.** Rewrite each original program to call the component. Re-score every rewritten program on its original task's context data. The rewrite passes only if its predictive distributions are bit-identical, under the frozen coder, to the original's on every scored context observation. One re-scoring of one rewritten program on one task's context data costs one candidate evaluation. Sealed data of earlier tasks is never used for verification.
4. **Hold provisionally.** A verified component enters the library as provisional. It is available to task t+1 and is charged like any library entry whenever a model uses it.
5. **Admit or discard.** After task t+1's sealed evaluation, the component is admitted only if task t+1's frozen model referenced it and earned positive net Turings with the component's full description length charged. Otherwise it is discarded. Discarding refunds nothing: its extraction and verification evaluations stay spent.

Failure is recorded at each step: no repeated structure found, verification failed, budget exhausted mid-extraction, provisional component unused, or used but not net-positive. The per-sequence counts of each failure kind are reported.

DreamCoder (Rev 6 reference 4, Ellis et al. 2021) is the precedent for library learning by extracting reusable components from solved programs. CEXP-2 differs in that every component is paid for in bits under the decoder rule and every extraction step is paid for in the same budget the search uses.

## 6. Task sequence and blocks

One sequence is 24 tasks in four blocks. Each task follows the CEXP-1 per-task layout (section 3). The generator families and their component pools are written into the preregistration manifest before the first sequence runs.

| Block | Tasks | Library and cache | Generator |
|---|---|---|---|
| **S: Shared structure** | 1 to 8 | open | family F1: laws composed from component pool C1 |
| **W: Family switch** | 9 to 12 | open | family F2: laws composed from pool C2, which shares exactly half of its components with C1 |
| **Freeze** | after task 12's sealed evaluation and the admit-or-discard decisions it settles, before task 13 begins | library and cache frozen for arms A, P, E; any component still provisional is discarded; no admission, extraction or discard after this point | none |
| **N: Final block, unseen** | 13 to 24, order shuffled by sealed seed | frozen | 4 tasks of each kind below |

Final block task kinds:

- **N-fam (familiar compositions):** compositions of C1 components whose composition pattern appeared in block S, with fresh parameters.
- **N-unf (unfamiliar compositions):** compositions of C1 components whose composition pattern never appeared in blocks S or W.
- **N-ctl (unrelated-family control):** laws from family F3, whose pool C3 shares no component with C1 or C2.

**Why these numbers.** Blocks S and W together keep CEXP-1's 12-task learning sequence, so the library a CEXP-2 arm brings to the final block is built from the same amount of experience CEXP-1 measures. The switch at task 9 leaves 8 tasks for a library to form and 4 to show recovery. A half-shared C2 makes the switch informative in both directions: shared components can transfer, whole programs mostly cannot. Four tasks per final kind keeps the final block at 12 tasks, the size of one CEXP-1 sequence.

## 7. Predictions and falsifiers per block

| Block | Predicted ordering | Outcome that falsifies the abstraction hypothesis for that block |
|---|---|---|
| S | early tasks: R ≈ A ≈ P ≈ E, with E lowest because extraction spends budget; late tasks: P and E above R, E at or above P | E below P over tasks 5 to 8, interval entirely below zero |
| W | P falls toward R (whole F1 programs rarely fit F2); E stays above P because half the components transfer | E at or below P on block W, interval not above zero |
| N-fam | P ≈ E, both above R | none (a P ≈ E tie here is expected; E above P here only, with no gain on N-unf, means E's gain is recall, not abstraction) |
| N-unf | E above P, P modestly above R | E at or below P on N-unf, interval not above zero |
| N-ctl | R ≈ A ≈ P ≈ E | any library arm entirely below R means library search cost harms unrelated tasks (reported, not voiding); any arm entirely above R means leakage or a generator flaw, and the run's claim is held pending audit |

## 8. Criterion and analysis

- **Replication.** 30 paired sequences, all four arms on identical seeds and identical task draws. 30 matches CEXP-1, so the arm P results also serve as a 30-sequence replication of CEXP-1's library learner under the CEXP-2 sequence.
- **Primary quantity.** For each sequence, D = (total net Turings of arm E over the 12 final-block tasks) − (the same total for arm P), all library and component costs charged in every task's L(M).
- **Primary criterion.** Mean of D across the 30 sequences, with a 95 percent percentile bootstrap interval over sequences (10,000 resamples).
  - Interval entirely above zero: the abstraction hypothesis is **supported** for this configuration.
  - Interval entirely below zero: the abstraction hypothesis is **falsified** for this configuration.
  - Interval contains zero: **inconclusive**. Inconclusive is reported as inconclusive, never as support.
- **Mandatory secondary quantities** (reported with intervals, never used to rescue the primary): whole-sequence totals (24 tasks, Claim C style, construction costs included) for E minus P; per-block differences for S, W, N-fam, N-unf, N-ctl; P minus A (does program reuse beat plain caching); P minus R (CEXP-1 direction); A minus R (leak check); gain density for every arm and block; extraction failure counts (section 5); budget spent on extraction and verification as a fraction of each task's budget.
- **Full distribution.** The 30 paired differences are reported in full alongside the mean.

## 9. Preregistration and deviations

- Before the first sequence runs, a preregistration manifest is committed holding: this spec version, the bound profile id and its digest, the program description code, the generator families F1, F2, F3, the pools C1, C2, C3 and the composition patterns used in block S and reserved for N-unf, the discovery procedure and its hyperparameters, the seed derivation rule, and the analysis method above.
- Evaluator-only details (pools, patterns, seeds) follow the commit-then-reveal rule used for the Brownian calibration program (`docs/brownian-calibration-explainer.md`): the SHA-256 of the private manifest is published before any sealed data exist, and the manifest is published after the run.
- Sealed data are generated only after the manifest commit, from seeds no one can compute before it.
- Any deviation from this spec or the manifest after the first sequence runs voids the run's claim to test the abstraction hypothesis. The run and its failure stay in the record. A corrected run is a new spec version with fresh sealed data.

**Run validity.** The void rule used for EXP-001 applies. A sequence is void only for an infrastructure failure before any sealed score of that sequence exists; it is retried with identical inputs at most 3 times, and if it still fails the run is reported as inconclusive for infrastructure reasons. Every void is published. A failure after any sealed score exists is a result, not a void.

**What is identical across arms.** The discovery procedure, its hyperparameters, the base candidate enumeration order (before any library-derived candidates are added), the random seed of the learner within each task, the task draws, and the sealed trajectories. The only permitted difference is the carried state of section 4. A test that checks this, by running arm E with an empty library and comparing its outputs bit for bit with arm R on one sequence, is part of the preregistered pre-run checks.

## 10. Gates and blockers

CEXP-2 may not start until all of the following hold:

1. **EXP-001 PASS.** Met in successor form: EXP-001 failed and is preserved; its successor EXP-001R passed (see `DISCOVERY_CURRENT_STATE.md`).
2. **CEXP-1 run complete,** with its receipt published, whatever its result. CEXP-1 has not been run.
3. **An admissible program description code** in the bound profile. Turing-profile-v1.1 in omega admits table models only and states that no program is admissible. CEXP-1 and CEXP-2 both need a successor profile, or a companion profile, that admits programs and components and charges them under the decoder rule.
4. **Apparatus identity settled.** Rev 6 Appendix D names "turing-profile v1.0" and lists quantizer and parameter-cost values that do not appear in omega's Turing-profile-v1.0 or v1.1 files. The CEXP-1 preregistration must name the actual profile file and digest; CEXP-2 binds the same one.

**No result from CEXP-2 is a Physics Zero claim.** CEXP-2 measures learner behavior on synthetic stochastic-law tasks. It says nothing about discovering physical law, and no Physics Zero document may cite it as evidence of discovery.
