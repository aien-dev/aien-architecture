# CEXP-2: Abstraction Learning versus Program Reuse

**NOT A MASTER PLAN.** This is a finite experiment specification for the discovery workstream. `CURRENT_EXECUTION_PLAN.md` owns cross-project sequencing and `doctrine/ROADMAP.md` owns milestone status. Nothing in this document is a milestone, and nothing in it is implemented.

**Spec version:** v1.0, written 2026-09-30. Status: FROZEN AS TEXT, BLOCKED (see section 11). Once a run's preregistration manifest is committed, the values in this document are binding for that run; any change is a new spec version and a new run.

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
| Measurement profile | the Turing profile the CEXP-1 run binds (see section 11 for the version question) |
| Coder | the profile's reference coder |
| Quantizer Q | 256 uniform bins over [-5, 5], out-of-range values clipped to edge bins |
| Baseline | uniform over quantization bins, 8 bits per observation |
| Model cost convention | 32 bits per fitted real parameter, 8 bits per small integer hyperparameter selected on context data |
| Context per task | 8 trajectories of 400 observations |
| Sealed evaluation per task | 4 trajectories of 400 observations, one-step-ahead, steps 1 to 399: 1,596 scored observations |
| Budget unit | one candidate evaluation = one candidate scored against the task's context data |
| Budget per task per arm | 20,000 candidate evaluations |
| Bootstrap | percentile bootstrap over sequences, 10,000 resamples, 95 percent interval |

**Program description code.** Library programs and components are structured objects, so the profile must define a prefix-free description code for them (Rev 6 Appendix A). The same code is used by all four arms. It is fixed in the preregistration manifest before the first sequence runs. If the bound profile has no admissible program code, CEXP-2 is blocked (section 11).

**Budget charging schedule.** Every operation an arm performs is charged against the same per-task budget, in evaluation-equivalent units:

| Operation | Charge |
|---|---|
| scoring one candidate against the current task's context data (search, library-derived and cache-derived candidates) | 1 evaluation |
| re-scoring one rewritten program on one probe set during verification (section 6, step 3) | 1 evaluation |
| cache read, cache write | measured rate, below |
| one repeated-structure alignment attempt between two programs (section 6, step 1) | measured rate, below |
| constructing one parameterized component from an aligned subprogram (section 6, step 2) | measured rate, below |
| admission check of one program or component (reading a settled sealed score and writing the library) | measured rate, below |

A **measured rate** is the operation's mean primitive step count divided by the mean primitive step count of one candidate evaluation, both measured on development seeds before the preregistration manifest is committed, rounded up to the next 1/1000 of an evaluation. The rates are written into the manifest and never re-measured during the run. A cheap operation, such as a cache read, is therefore charged a small fraction of an evaluation, not a whole one.

## 4. Arms

Four arms run the same task sequences, paired by seed, with identical per-task budgets. All four use the same single-task discovery procedure and hyperparameters; they differ only in what they carry from one task to the next and in the between-task work that carried state needs.

| Arm | Carries across tasks | Charged in bits (Turing account) | Charged in the budget account |
|---|---|---|---|
| **R: Reset** | nothing | nothing carried | nothing carried |
| **A: Answer cache** | input-output results only: earlier tasks' context observations and the predictive distributions the arm produced for them, keyed by the full quantized context window | each distinct cache entry a task's model consults | cache reads and writes, and each scoring of a cache-derived candidate |
| **P: Program reuse** | whole programs admitted under Claim C's admission rule, each callable only as a frozen whole program | each distinct library program a task's model references | admission checks and each scoring of a library-derived candidate |
| **E: Abstraction learning** | admitted whole programs plus admitted parameterized components (section 6) | each distinct program and component a task's model references | as P, plus alignment, construction and verification |

**Charging rule for carried entries (all arms).** Under the decoder rule, each distinct carried entry that a task's model uses is written into that model once and charged once, at its length under the program code. Each use of an entry inside the model pays only the program code's pointer cost. Parameters bound to a component for the current task are charged at the profile's parameter cost (32 bits per fitted real parameter).

**What only arm E may do.** Arm P may call a library program only as a frozen whole program: it may not lift constants out of it, splice its internals or refit parts of it. Lifting constants into parameters, and binding those parameters to a new task by the shared enumerator, is arm E's distinguishing operation.

**Arm P and CEXP-1.** Arm P copies CEXP-1's library learner in three respects: the admission rule (after each task, a program that earned positive net Turings on that task's sealed evaluation, with its description length charged, is admitted), the decoder charging, and the single-task procedure given the same library. A departure from any of these three voids the CEXP-2 claim. Arm P is not a replication of CEXP-1: its sequence includes a family switch that CEXP-1 does not have.

**Arm A is a control, not a contender.** Every task draws a fresh law and fresh sealed trajectories. A cache hit requires exact equality of the full quantized context window; nearest-neighbour lookup and refitting on cached pairs are forbidden. Arm A is predicted to track arm R and to fall below it by whatever cache charges it pays. A leak audit is triggered if the cache hit rate exceeds the collision bound preregistered from development seeds, or if the paired A minus R interval lies entirely above zero; the run's claims are held until the audit closes.

## 5. Timeline of one task, and the Appendix D between-task exception

Rev 6 Appendix B forbids any selection or update after the freeze. Claim C's admission rule, frozen in Appendix D, uses each task's sealed score. CEXP-2 reconciles the two in the same way for all arms:

1. **Search.** The arm searches within task t's budget, keeping back the between-task reserve declared for it in the manifest.
2. **Emit and freeze.** When the search budget is spent, the arm emits exactly one model for task t. That model is scored once on task t's sealed evaluation and is never changed afterwards.
3. **Between-task work.** After the score is settled, the arm may spend what remains of task t's budget, and nothing more, on admission, extraction and verification. This work edits only the library or cache carried into task t+1. It never edits, reselects or rescores task t's model.

Step 3 is the **Appendix D between-task exception**: post-score work that only edits carried state, paid from the task's own budget. Budget left unspent at the start of task t+1 is lost. A larger reserve means less search on task t; that loss is part of the cost being measured.

## 6. Abstraction extraction procedure (arm E only)

Extraction is a procedure that can fail at every step. It runs in step 3 of section 5, after tasks 1 to 11. It does not run after task 12 (section 7).

1. **Find repeated structure.** Search the admitted programs for a subprogram that occurs, up to renaming of constants, in at least 2 admitted programs from different tasks. Each alignment attempt is charged at its measured rate.
2. **Propose a component.** Replace the differing constants of that subprogram with parameters. The result is a parameterized component with a description length under the program code.
3. **Verify behavior preservation.** Rewrite each original program to call the component. For each original program, draw a probe set of 8 trajectories of 400 observations by running the original program as a simulator, with a seed derived from that task's seed. The rewrite passes only if its predictive distributions are bit-identical, under the frozen coder, to the original's on every probe observation. No earlier task's context or sealed data is carried or used. Passing on probes is a test, not a proof of equivalence.
4. **Hold provisionally.** A verified component enters the library as provisional. It is available to task t+1 and is charged like any library entry whenever a model uses it.
5. **Admit or discard.** After task t+1's sealed score is settled, the component is admitted only if task t+1's frozen model referenced it and earned positive net Turings with the component charged. Otherwise it is discarded. Discarding refunds nothing.

Failure is recorded at each step: no repeated structure found, verification failed, budget exhausted mid-extraction, provisional component unused, or used but not net-positive. The per-sequence counts of each failure kind are reported.

DreamCoder (Rev 6 reference 4, Ellis et al. 2021) is the precedent for library learning by extracting reusable components from solved programs. CEXP-2 differs in that every component is paid for in bits under the decoder rule and every extraction step is paid for in the same budget the search uses.

**Pre-run check on components.** Every component in the generator pools has one declared syntactic form under the program code. Before the manifest is committed, a development-seed run shows whether extraction recovers the pool components from programs that contain them; the recovery rate is recorded in the manifest. A low rate is a finding, not a reason to change the procedure after the freeze.

## 7. Task sequence and blocks

One sequence is 24 tasks in four blocks. Each task follows the per-task layout of section 3.

| Block | Tasks | Library and cache | Generator |
|---|---|---|---|
| **S: Shared structure** | 1 to 8 | open | family F1: laws composed from pool C1 using composition patterns from the set P_S |
| **W: Family switch** | 9 to 12 | open | family F2: laws from pool C2, which shares exactly half of its components with C1, using patterns from the set P_W |
| **Freeze** | after task 12's sealed score and the admission decisions it settles, before task 13 begins | library and cache frozen for arms A, P, E | none |
| **N: Final block, unseen** | 13 to 24, order shuffled by sealed seed | frozen | 4 tasks of each kind below |

**Task 12.** After task 12 is scored, whole programs are admitted and components proposed after task 11 are admitted or discarded. No extraction runs after task 12, because its components could never be tested before the freeze.

Final block task kinds:

- **N-fam (familiar compositions):** fresh-parameter redraws of patterns that block S actually emitted. The 4 patterns are drawn uniformly with replacement from the patterns realized in block S, by sealed seed.
- **N-unf (unfamiliar compositions):** compositions of C1 components using patterns from the set P_unf, which is disjoint from P_S and P_W.
- **N-ctl (unrelated-family control):** laws from family F3, whose pool C3 shares no component with C1 or C2.

P_S, P_W and P_unf are committed in the manifest before any sealed draw, so the unseen patterns are fixed before any task is seen.

**Why these numbers.** Blocks S and W together match CEXP-1's 12-task sequence in task count only. The switch at task 9 leaves 8 tasks for a library to form and 4 to show recovery. A half-shared C2 makes the switch informative in both directions: shared components can transfer, whole programs mostly cannot. Four tasks per final kind keeps the final block at 12 tasks.

## 8. Predictions and falsifiers per block

One rule applies everywhere: an interval entirely above zero supports the prediction, an interval entirely below zero falsifies it, and an interval containing zero is **inconclusive**.

| Block | Statistic (paired E minus P total) | Predicted | Falsified only if |
|---|---|---|---|
| S, tasks 5 to 8 | E minus P over tasks 5 to 8 | at or above zero late in the block (E pays extraction early) | interval entirely below zero |
| W | E minus P over tasks 9 to 12 | above zero: half the components transfer, whole F1 programs rarely fit F2 | interval entirely below zero |
| N-fam | E minus P over the 4 N-fam tasks | near zero: both arms hold the patterns | no falsifier; E above P here with no N-unf gain means recall, not abstraction |
| N-unf | E minus P over the 4 N-unf tasks | above zero | interval entirely below zero |
| N-ctl | each library arm minus R over the 4 N-ctl tasks | near zero | not a falsifier: a library arm entirely below R means search cost harms unrelated tasks (reported); entirely above R triggers the leak audit |

## 9. Criterion and analysis

- **Replication.** 30 paired sequences, all four arms on identical seeds and identical task draws. The number matches CEXP-1's replication count; the bootstrap and interval rules are also CEXP-1's.
- **Joint primary criterion.** Two paired quantities per sequence, all carried costs charged in every task's L(M):
  - D_final = (arm E total net Turings over the 12 final-block tasks) minus (the same for arm P);
  - D_unf = (arm E total net Turings over the 4 N-unf tasks) minus (the same for arm P).
  For each, the mean across the 30 sequences with a 95 percent percentile bootstrap interval over sequences (10,000 resamples).
  - **Supported:** both intervals lie entirely above zero.
  - **Falsified:** the D_unf interval lies entirely below zero.
  - **Not supported, inconclusive:** every other outcome, including a D_final interval above zero with a D_unf interval containing zero (a recall-only gain). Inconclusive is never reported as support.
- **Mandatory secondary quantities** (reported with intervals, never used to rescue the primary): whole-sequence totals (24 tasks, construction costs included) for E minus P; the block statistics of section 8; P minus A (does program reuse beat plain caching); P minus R; A minus R and the cache hit rate (leak check); gain density for every arm and block; extraction failure counts (section 6); budget spent on between-task work as a fraction of each task's budget.
- **Full distribution.** The 30 paired values of D_final and D_unf are reported in full alongside the means.

## 10. Preregistration and deviations

- Before any sealed data exist, a preregistration manifest is committed holding: this spec version, the bound profile id and its digest, the program description code and its pointer cost, the measured-rate charging schedule, each arm's between-task reserve, the generator families F1, F2, F3, the pools C1, C2, C3, the pattern sets P_S, P_W, P_unf and the N-fam fill rule, the component recovery rate and the cache collision bound from development seeds, the discovery procedure and its hyperparameters, the seed derivation rule, and the analysis method above.
- Evaluator-only details (pools, patterns, seeds) follow the commit-then-reveal rule used for the Brownian calibration program (`docs/brownian-calibration-explainer.md`): the SHA-256 of the private manifest is published before any sealed data exist, and the manifest is published after the run.
- Sealed data are generated only after the manifest commit, from seeds no one can compute before it.
- Any deviation from this spec or the manifest after the first sequence runs voids the run's claim to test the abstraction hypothesis. The run and its failure stay in the record. A corrected run is a new spec version with fresh sealed data.

**Run validity.** The EXP-001 void rule applies, with one counter for the whole run. A sequence is void only for an infrastructure failure before any sealed score of that sequence exists, and is retried with identical inputs. The third void in the run closes the run as inconclusive for infrastructure reasons; it is not retried. Every void is published. A failure after any sealed score exists is a result, not a void.

**What is identical across arms.** The single-task discovery procedure, its hyperparameters, the base candidate enumeration order (before any carried candidates are added), the learner's random seed within each task, the task draws, and the sealed trajectories. A pre-run check runs arm E with an empty library and zero reserve on one development sequence and compares its outputs bit for bit with arm R.

## 11. Gates and blockers

CEXP-2 may not start until all of the following hold:

1. **EXP-001 PASS.** Met in successor form: EXP-001 failed and is preserved; its successor EXP-001R passed (see `DISCOVERY_CURRENT_STATE.md`).
2. **CEXP-1 run complete,** with its receipt published, whatever its result. CEXP-1 has not been run.
3. **An admissible program description code** in the bound profile. Turing-profile-v1.1 in omega admits table models only and states that no program is admissible. CEXP-1 and CEXP-2 both need a successor profile, or a companion profile, that admits programs and components and charges them under the decoder rule.
4. **Apparatus identity settled.** Rev 6 Appendix D names "turing-profile v1.0" and lists quantizer and parameter-cost values that do not appear in omega's Turing-profile-v1.0 or v1.1 files. The CEXP-1 preregistration must name the actual profile file and digest; CEXP-2 binds the same one.

**No result from CEXP-2 is a Physics Zero claim.** CEXP-2 measures learner behavior on synthetic stochastic-law tasks. It says nothing about discovering physical law, and no Physics Zero document may cite it as evidence of discovery.
