# AT-0 Charter: The Clock-Free Universe

**NOT A MASTER PLAN.** `CURRENT_EXECUTION_PLAN.md` owns sequencing and `doctrine/ROADMAP.md` owns milestone identifiers and status (`PLAN_AUTHORITY.md`). AT-0 is a research program label, like DIRAC-0. It is not a registered roadmap milestone (section 10).

**Program status: NOT_RUN.** No AT-0 code exists, no case has been executed, and no result exists. Every gate in section 6 is NOT_RUN.
**Contract status:** `AT0_CASE_V1` and `AT0_RESULT_V1` are FROZEN on merge of the pull request that adds them (section 8, `AT0_FREEZE.md`).
**Written:** 2026-10-09 by Agent 0 (technical coordinator).
**Snapshots inspected (GitHub default branches, 2026-10-09):** omega `19f73c7`, aien-architecture `27f3b71`, aien-sovereign-core `5b7861f`, physics `9f96f25`, physics0 `fe587d2`, aienos.com `cc389e3` (Atemporal AIEN Postulate v1.1 source).

## 1. Purpose and scope

AT-0 builds and tests a small relational quantum model in which no external clock time is a fundamental state variable. The universe is a finite Page-Wootters model: a clock and one qubit, a total constraint `H_total |Psi> = 0`, and a clock measurement (a POVM). Time appears only as the label of a clock reading, and the qubit's behaviour is read off by conditioning on that label. The test asks whether the conditional qubit statistics reproduce ordinary Schrodinger evolution in the clock reading when the model says they should, and whether they fail, for the stated reason, when they should not.

AT-0 applies the identity discipline of the Atemporal AIEN Postulate v1.1: meaning carries no wall-clock coordinate; clock readings are declared data or physical evidence; semantic equality is exact; floating-point tolerances belong to acceptance, not identity.

**What AT-0 does not claim.** AT-0 does not run the Postulate's own schedule-invariance experiment (the `A, B -> C -> D` graph; paper.tex lines 201 to 211). It does not test Omega, FORGE, GPU realization or the Crumbline. Passing runs are bounded conformance evidence for the cases run, not proof of any physical or architectural claim.

**Out of scope for V1:** clock-system interaction terms, systems larger than one qubit, shot sampling (V1 uses exact expectation values, so the only uncertainty is numerical), GPU execution, parallel execution, sealed or hidden answers.

## 2. Source evidence for the integration decisions

Every decision below rests on code or files read at the snapshots above. "Line" means the line in that file at that commit.

| # | Source | What it shows | Decision it supports |
|---|---|---|---|
| E1 | omega `Makefile` line 5 `-include mk/*.mk` | Programs plug into omega by dropping a fragment in `mk/`. | AT-0 builds from its own `mk/at0.mk`. |
| E2 | omega `Makefile` lines 14 to 23 (`SRCS`) | The main `omegatool` links `physics/m16` and `physics/nvrm` GPU driver code. | AT-0 never joins `SRCS`, `all` or `test`. |
| E3 | omega `mk/physics0.mk` lines 1 to 4 and 17 | Physics Zero is a separate fragment, "not part of `all` or `test`", plain `-std=c11 -pedantic`, `-lm` only. | Same pattern and flags for AT-0. |
| E4 | omega `tests/physics0/isolation.sh` | Symbol-level isolation check with `nm` on object files. | AT-0 isolation gate (G2) reuses the method. |
| E5 | omega `src/sha256.h` lines 16 to 19 | In-house SHA-256 with init/update/final, already linked by Physics Zero. | The only digest code AT-0 uses. |
| E6 | omega `research/dirac-oracle/CORPUS-FORMAT.md` section 2 | Exact text encodings for rationals, complex rationals, matrices, scaled decimals; "no floating point text anywhere". | Adopted for every identity-bearing byte in AT-0. |
| E7 | omega `src/physics0/pd0_wire.h` lines 3 to 4 | "no floating point in any canonical byte". | Same rule: no float enters an AT-0 identity. |
| E8 | omega `src/estimation/est_types.c` lines 8 to 9; `src/dual/rx_dual.c` line 56; `src/ans/ans.h` lines 24 to 25 | Measured doubles are encoded as IEEE-754 binary64 bit patterns, `-0.0` folded to `+0.0`, NaN and infinity refused. | AT-0 records computed values the same way, as evidence. |
| E9 | omega `src/*/` domain strings, for example `omega.dirac.kat.v1`, `omega.ans.measurement.v1`, `omega.dual.trace.v1` | Record-type tags follow `omega.<program>.<kind>.v<N>`; no `omega.at0.*` or `AT0` name exists in omega, aien-architecture or aien-sovereign-core. | Program-local tags `omega.at0.{case,acceptance,verdict,evidence}.v1`; no new project-wide identifier. |
| E10 | omega `.github/workflows/evidence-immutable.yml` lines 24 to 28 | CI rejects any modification, deletion or rename under `evidence/`. | AT-0 evidence goes to new folders under `evidence/AT0/`, never rewritten. |
| E11 | omega `.github/workflows/pr-smoke.yml` lines 44 to 61 | CI runs `make test` (which parses every `mk/*.mk`) and builds some suites with `PHYSICS_DIR=/nonexistent`. | `mk/at0.mk` must parse cleanly and build with `PHYSICS_DIR=/nonexistent PHYSICS_LOCK_CHECK=0`. |
| E12 | omega `research/dirac-oracle/README-NOT-BUILT.md` line 2; aien-architecture `docs/plans/dirac/DIRAC_0_CURRENT_STATE.md` lines 1 to 5; `CURRENT_EXECUTION_PLAN.md` line 392 | A quantum research program is recorded as "not a milestone", with explicit NOT_RUN / PROPOSED status and pinned snapshots. | Same status discipline here. |
| E13 | aien-architecture `doctrine/ROADMAP.md` lines 66 to 81 | Milestone identifiers M27 to M35 belong to Physics Zero; AT-0 is not listed. | AT-0 is not called a milestone (section 10). |
| E14 | aienos.com `public/research/atemporal-aien-postulate/paper.tex` lines 52, 164, 191 to 199, 203 to 211 | No primitive wall-clock coordinate in semantic identity; exact semantic equality; typed identities (program, result, claim); hash equality is evidence, not identity; clock readings allowed as declared data; negative controls must be rejected for their specific reason. | Section 4 policy and the contracts' identity sections. |
| E15 | aien-dev/physics0 at `fe587d2` holds only `LICENSE`; aien-dev/physics is the machine-physics and GPU driver repo. | Neither is a home for AT-0 code. | AT-0 code lives in omega. |
| E16 | aien-sovereign-core `crates/crumbs/SPEC.md` | Crumb receipts are a Rust crate in the sovereign core. | Not linked by AT-0 V1; admitting AT-0 results as crumbs is future work. |
| E17 | No `CODEOWNERS` file in omega, aien-architecture or aien-sovereign-core. | Directory ownership is not enforced by GitHub. | Ownership is set by this charter and claimed through Crumb (section 7). |

## 3. Integration decisions

1. **Home.** AT-0 code lives in `aien-dev/omega` in new `at0` folders (section 7). Contracts, charter and status live here in `aien-architecture/docs/plans/atemporal/`.
2. **Build.** One fragment `mk/at0.mk`, guarded by `ifndef AT0_MK`, defining only targets and variables prefixed `at0` or `AT0_`. It adds nothing to `SRCS`, `all`, `test`, `clean` or any existing target. Flags: `-std=c11 -Wall -Wextra -Werror -pedantic -O2 -D_POSIX_C_SOURCE=200809L`, link `-lm` only; a sanitizer build with `-O1 -g -fsanitize=address,undefined -fno-sanitize-recover=all`. Interval code may add `-frounding-math`.
3. **Isolation.** AT-0 objects link nothing from `physics/`, no GPU code, no `omegatool`, no estimation, DUAL or ANS objects. The only shared source is `src/sha256.c`. Compute objects (engine, oracle) contain no clock, random, file, process, socket or thread symbol.
4. **Execution.** Single-threaded CPU only, deterministic, no network, no external service, no Python, no GPU (`threads 1` in every result).
5. **Evidence.** Each recorded run writes a new folder `evidence/AT0/<YYYYMMDDTHHMMSSZ>-<short omega commit>/` holding the case files, result files and a run log. Existing evidence is never modified (E10).
6. **CI.** V1 adds no workflow. `make test` must be unaffected. Wiring AT-0 into CI is a later, separate pull request.

## 4. Serialization and identity policy

- **Two kinds of content, never mixed.** *Semantic content* is exact text: integers, reduced rationals, complex rationals, scaled decimals, labels, enum words. *Physical execution evidence* is everything about a particular run: computed binary64 values, error bounds, toolchain, host, wall-clock times, artifact digests.
- **Identities are computed over semantic content only.** `case_id` (the question), `acceptance_id` (the judging rules) and `verdict_id` (which checks passed, which codes were raised) are domain-separated SHA-256 digests of exact, canonical text. No floating-point representation, specified or not, enters any of them.
- **Evidence digests are labelled as evidence.** `evidence_digest` covers the whole result record, floats included, and is explicitly not an identity. Plain file digests (`case_file_sha256`, `engine_sha256`, artifact digests) are provenance.
- **No semantic identity over computed values in V1.** The binary64 outputs come from an unspecified sequence of floating-point operations. Calling a hash of them a semantic identity is forbidden. An exact-arithmetic engine could earn one in a later contract version.
- **Decisions never compare floats.** Every acceptance check is decided in exact rational arithmetic on the written binary64 values, their bounds and the scaled-decimal tolerances, with a third answer, `INDETERMINATE`, when the precision does not settle it.
- **Canonical text.** ASCII, LF, fixed line order, fixed key set, single spaces, canonical number forms; anything else is refused, never repaired.
- **Hashes are evidence of equality, not its definition** (Postulate v1.1, paper.tex line 197).

Full rules: `AT0_CASE_V1.md` sections 1 to 5 and `AT0_RESULT_V1.md` sections 1 to 7.

## 5. Reuse and dependencies

**Reuse:**

| Item | Where | How |
|---|---|---|
| SHA-256 | omega `src/sha256.c`, `src/sha256.h` | Link directly (E5). |
| Exact text encodings | omega `research/dirac-oracle/CORPUS-FORMAT.md` section 2 | Adopted by restatement in AT0_CASE_V1 section 2. There is no Dirac code to reuse: the oracle is NOT_BUILT (E12). |
| binary64 canonicalization rule | omega `src/estimation/est_types.c`, `src/dual/rx_dual.c` | Re-implement the rule (a few lines); do not link those modules (E8). |
| Fragment, flags and sanitizer pattern | omega `mk/physics0.mk` | Copy and adapt into `mk/at0.mk`; do not edit `mk/physics0.mk` (E3). |
| Symbol-isolation method | omega `tests/physics0/isolation.sh` | Copy and adapt into `research/atemporal/at0/integration/` (E4). |
| Evidence immutability | omega `.github/workflows/evidence-immutable.yml` | Already covers `evidence/AT0/` with no change (E10). |
| Crumb tooling | `crumb` CLI; `crumb.yml` CI in omega and aien-architecture | Every new directory gets compiled crumbs; compiling is the last step before push. |
| Host tools | `gcc`, `make`, `nm`, `sha256sum` | Build, isolation checks, digest cross-checks. |
| C11 standard library | `<complex.h>`, `<fenv.h>`, `<math.h>`, `<stdint.h>` | Complex arithmetic, rounding control for interval bounds. |

**Not used:** omega `omegatool` and its `SRCS`; the `physics` repo and GB10 GPU code; CUDA, MAX, Mojo; Python anywhere (AIEN rule); any network service or model; external numeric libraries (GMP, MPFR, LAPACK, Eigen); aien-sovereign-core crates (E16); `aien-sealed` (AT-0 has no hidden answers, so nothing is sealed and no agent reads that repo).

## 6. Cases and gates

**Case classes** (Agent 1 derives the expected outcome and failure codes by hand in `AT0_SPEC.md`; Agent 4 writes the case files from those derivations):

| Class | Example of the mechanism | Expected |
|---|---|---|
| P1 ideal clock, full cover | the AT0_CASE_V1 section 6 example; also other N, M, `h`, `tau` | `PASS` |
| P2 nonzero `h0`, tilted `h` with rational norm (for example `hx = 3/10, hz = 2/5`) | clock energies chosen to cover `h0 +/- |h|` | `PASS` |
| N1 uncovered spectrum | clock energies all positive, system eigenvalues `+/- 1/2` | `FAIL TRIVIAL_PHYSICAL_STATE` |
| N2 half-covered spectrum | only one system eigenvalue matched | `FAIL SCHRODINGER_DEVIATION_EXCEEDED` |
| N3 broken clock | `tau` with `D tau M` not an integer for some energy gap `D` | `FAIL` with `POVM_NORMALIZATION_EXCEEDED` plus every code that follows (derived by hand) |
| N4 wrong weight | `w != N / M` | `FAIL` with `POVM_NORMALIZATION_EXCEEDED`, `PROBABILITY_SUM_EXCEEDED` (and any other derived code) |
| N5 precision demand | `min_bound_kind RIGOROUS` against an `ESTIMATED` engine | `FAIL BOUND_KIND_INSUFFICIENT` |
| R1 to R6 refusals | non-canonical rational, wrong header, out-of-range dimension, irrational spectrum, wrong `case_id`, bad expected-code list | `AT0_CASE_REFUSED <code>`, one file per refusal code |

**Postulate-derived controls** (implementation level, built by Agent 4 in `at0/evaluator/`, run by Agent 5):

- *Hidden clock read:* a deliberately built mutant engine that calls `clock_gettime` must be caught by the isolation gate.
- *Wall-clock independence:* the same case run twice at different times gives equal `case_id`, `acceptance_id`, `verdict_id` and values block, and different `evidence_digest`.
- *Evaluation order:* the engine evaluated with clock labels in reverse order (a test-only entry point) gives a bit-identical values block.
- *Axis swap:* a mutant engine that swaps the X and Y results must fail `schrodinger_agreement` on the P1 cases (this proves the oracle is independent of the engine).

**Gates (all NOT_RUN):**

| Gate | Pass condition | Owner |
|---|---|---|
| AT0-G0 contract freeze | this charter and both contracts merged; `AT0_FREEZE.md` digests match the merged files; `AT0_SPEC.md` merged | Agents 0, 1 |
| AT0-G1 codec conformance | each of the oracle, the model and the evaluator parses and re-emits the AT0_CASE_V1 section 6 example byte for byte and reproduces its published digests; every refusal case gives its exact code; C code clean under ASan/UBSan | Agents 2, 3, 4 (each for its own parser) |
| AT0-G2 isolation | symbol check passes on model objects and fails on the hidden-clock mutant; `mk/at0.mk` builds with `PHYSICS_DIR=/nonexistent PHYSICS_LOCK_CHECK=0`; `make -n all` and `make -n test` print the same commands with and without `mk/at0.mk` | Agent 5 |
| AT0-G3 oracle calibration | the oracle reproduces the `AT0_SPEC.md` hand tables within its stated bounds on all Pauli values and clock probabilities; oracle shares no source, object or numerical routine with the model | Agent 2 |
| AT0-G4 positive arm | every P case: `outcome PASS`, `expectation_met YES` | Agent 5 runs; Agent 3 answers |
| AT0-G5 negative arm | every N case: `outcome FAIL` with exactly its expected codes, `expectation_met YES`; the axis-swap and hidden-clock mutants are caught | Agent 5 runs; Agent 4 answers |
| AT0-G6 independent verification | the evaluator's verifier, sharing no code with `model/` or `oracle/` except omega `src/sha256.c`, re-derives every check, outcome, `verdict_id` and `evidence_digest` from the result files alone and agrees; the wall-clock independence control holds; evidence is committed to a new `evidence/AT0/` folder with source and toolchain digests | Agent 5 runs; Agent 4 answers |
| AT0-G7 scientific review | `AT0_RESULTS.md` merged with PASS, FAIL or INCONCLUSIVE per claim, limitations stated, and a decision on whether an AT-1 proposal is justified | Agent 6 |

AT-0 V1 is complete when G0 to G7 all pass on one omega commit. A divergence between engine and oracle is first treated as an implementation fault until both are shown to follow the contract (Postulate v1.1, paper.tex line 211).

## 7. Ownership matrix

Agent numbering, roles, paths and execution order follow the tracking issue aien-dev/omega#358, which is authoritative. One owner per path. An agent edits only its own paths; reading anything is allowed. Owners claim their paths through Crumb before editing (`crumb` sniff, claim, whisper, close). Omega paths are relative to the omega repository root; `at0/` below means `research/atemporal/at0/`.

| Agent | Role | Order | Owns (may create and edit) | Must not touch |
|---|---|---|---|---|
| 0 | Coordinator, contract owner | serial, first | aien-architecture `docs/plans/atemporal/AT0_CHARTER.md`, `AT0_CASE_V1.md`, `AT0_RESULT_V1.md`, `AT0_FREEZE.md` | any omega path |
| 1 | Mathematical specification | serial, after 0 | aien-architecture `docs/plans/atemporal/AT0_SPEC.md`: proofs of the constraint, POVM completeness and conditional probabilities; X, Y, Z tests that detect phase-sign errors; assumptions, idealizations, tolerances, invariants; the hand-derived case tables of section 6 | contracts, all code |
| 2 | Independent reference oracle | parallel, after 1 | `at0/oracle/` (own parser, direct complex-matrix reference values with bounds, deterministic tests) | `at0/model/`, `at0/evaluator/` (no imports, calls or shared numerical routines) |
| 3 | Candidate model engine | parallel, after 1 | `at0/model/` (own parser, explicit state, Hamiltonian, constraint, clock POVM, conditional density matrix, X/Y/Z probabilities; fail-closed on malformed input) | `at0/oracle/`, `at0/evaluator/` |
| 4 | Independent adversarial evaluator | parallel, after 1 | `at0/evaluator/` (own parser; verifier; the case corpus `cases/positive/`, `cases/negative/`, `cases/refuse/` derived from `AT0_SPEC.md`; mutants built from copies inside `at0/evaluator/`) | `at0/model/`, `at0/oracle/` |
| 5 | Integrator | serial, after 2 to 4 | `mk/at0.mk`, `at0/integration/` (runner, `make at0-check`, clean-checkout execution, receipts, source and toolchain digests, repeatability, qualification report), `evidence/AT0/` (append-only) | `at0/oracle/`, `at0/model/`, `at0/evaluator/` (read-only; request changes from their owners) |
| 6 | Independent scientific reviewer | serial, after 5 | aien-architecture `docs/plans/atemporal/AT0_RESULTS.md` | all code, contracts |

Nobody edits omega's `Makefile`, other `mk/` fragments, existing `src/`, `tests/`, `tools/`, `evidence/` or `.github/` paths, or any other repository, under this charter. `research/atemporal/` and `at0/` parent directories and their crumbs are created by the first agent to need them and are shared only as containers. Agents 2, 3 and 4 work on separate branches or worktrees with disjoint files; 0, 1, 5 and 6 are never run in parallel with their prerequisites.

## 8. Interface change rule

1. The shared interfaces are exactly two: `AT0_CASE_V1` text and `AT0_RESULT_V1` text. The oracle, the model and the evaluator exchange nothing else: no shared C header, no shared library, no shared numerical routine. Each implements its own parser and proves it on the AT0_CASE_V1 section 6 example (gate G1).
2. A frozen interface is never edited, including typo fixes. Any change, however small, is a new version: new file (`AT0_CASE_V2.md`, `AT0_RESULT_V2.md`), new header line and domain tags (`omega.at0.case.v2` and so on), new entry in `AT0_FREEZE.md`, and re-review of every consumer. Old versions stay readable and their evidence stays valid under the version it was written against.
3. Only Agent 0 creates a new contract version. Other agents raise a contract question as a GitHub issue in aien-architecture with label `needs-triage`, naming the contract and section, and keep working against the frozen version.
4. Private code inside one owner's paths may change freely.
5. Every result names its `contract_commit`; every omega pull request touching AT-0 names the frozen contract commit it implements; `research/atemporal/at0/integration/contract.lock` (Agent 5) pins that commit and the contract file digests.

## 9. Handoff instructions

**Order** (omega#358). Agent 1 starts now: it needs only the merged charter and the two frozen contracts, and its `AT0_SPEC.md` is the input for everyone after it. Agents 2, 3 and 4 start in parallel once `AT0_SPEC.md` is merged. Agent 5 starts once 2, 3 and 4 have merged and runs G2, G4, G5 and G6. Agent 6 starts once Agent 5's qualification report is merged and runs G7. Every milestone (contract change, gate result, pull request opened or merged) is reported as a comment on omega#358.

**Every agent:**
1. Read this charter, `AT0_CASE_V1.md`, `AT0_RESULT_V1.md` and `AT0_FREEZE.md` at the frozen aien-architecture commit, and the Postulate v1.1 sections cited in section 2.
2. Start from current omega `origin/main`; pin the commit in your notes.
3. Sniff and claim your paths with Crumb; whisper findings; compile crumbs as the last step before pushing; close the claim after the pull request.
4. Branch `at0/agent<N>-<slug>`, one pull request per finishable cut into omega `main`. The pull request body names the frozen contract commit, the gate it serves, the commands run and their results.
5. Plain C11 under section 3 rules. No Python, no GPU, no network, no new dependencies.
6. Never edit outside your paths, never edit a contract, never rewrite evidence. If you need any of those, stop and raise it (section 8 step 3).
7. Report back: what was inspected, what changed, which tests ran with pass/fail, and anything UNKNOWN stated as such.

**Per-agent first deliverable:**

| Agent | First deliverable | Done means |
|---|---|---|
| 1 | `AT0_SPEC.md`: proofs, tolerances, invariants, and a hand-derived answer table for every case class in section 6 | merged; Agent 0 has checked the AT0_CASE_V1 section 6 example against it |
| 2 | Oracle: Schrodinger reference probabilities with `RIGOROUS` bounds if achievable, otherwise `ESTIMATED` stated plainly; own parser | AT0-G1 for its parser; AT0-G3 passes |
| 3 | Model: kernel projection, clock states, POVM residual, constraint residual, conditional probabilities, with stated `bound_kind`; own parser; fail-closed input handling | AT0-G1 for its parser; model unit tests pass; values for the section 6 example within its own bounds of the `AT0_SPEC.md` table |
| 4 | Evaluator: own parser, verifier with exact rational comparison, full case corpus (positive, negative, refusal) with expected codes taken from `AT0_SPEC.md`, mutants and controls | AT0-G1 for its parser; verifier agrees with hand-made result files, including deliberately wrong ones |
| 5 | `mk/at0.mk`, `make at0-check`, clean-checkout runner, receipts, evidence folder, qualification report | AT0-G2, G4, G5, G6 results recorded in `evidence/AT0/` and reported on omega#358 |
| 6 | `AT0_RESULTS.md`: review of source and raw receipts; PASS, FAIL or INCONCLUSIVE per claim; limitations; AT-1 decision | AT0-G7 |

## 10. Discrepancies and open items

- **"Milestone" wording.** The AT-0 brief calls AT-0 a research milestone. `doctrine/ROADMAP.md` owns milestone identifiers and does not list AT-0 (E13). This charter therefore treats AT-0 as a research program label. Registering it, or placing it under Physics Zero (M27 to M35), is a roadmap decision outside this charter.
- **No complex type in Omega** (DIRAC-0 current state). AT-0 does not need one: it uses C11 `<complex.h>` inside its own isolated code and never touches the Omega language.
- **Oracle language.** omega#358 says the Agent 2 oracle is "preferably Python standard-library"; the standing project rule (no Python in any repo, build, CI or tooling) and section 3 of this charter say C11 only. This charter keeps C11 until Drake decides; whichever way it goes, the oracle must share no code with the model, which is the property that matters.
- **Independent review.** The contracts were self-reviewed against the sources in section 2. An outside review before the first G1 run is recommended.
- **Charter history.** The first merged charter (aien-architecture#174, `044c9d1`) numbered the agents and placed omega paths differently from omega#358; sections 6, 7, 9 and 11 were realigned to the issue in the following pull request. The two frozen contracts were not touched.

## 11. Status

| Item | Status |
|---|---|
| Program AT-0 | NOT_RUN |
| AT0_CASE_V1, AT0_RESULT_V1 | FROZEN (aien-architecture#174, `044c9d1`) |
| AT0_SPEC.md (Agent 1) | NOT_WRITTEN |
| AT0_RESULTS.md (Agent 6) | NOT_WRITTEN |
| Gates AT0-G0 to AT0-G7 | NOT_RUN |
| Code in omega | none |
| Evidence | none |
