# AT-1 charter: interacting clock-system dynamics and independent replication

Status: PROPOSED. Program status: NOT_RUN. Tracking issue: aien-dev/omega#371. Predecessor: AT-0 (omega#358, REVIEWED; `AT0_CHARTER.md`, `AT0_RESULTS.md`). Owner of this file: Agent 0. This is a living document; the contracts it names are frozen files (section 8).

## 1. Purpose and scope

AT-0 showed that three independent code bases implement the finite ideal Page-Wootters model as specified, on one machine under one account. AT-1 adds the two things AT-0 could not give, under Drake's decision of 2026-10-10 (quoted on omega#371, governing):

1. **Interacting dynamics.** A clock-system coupling term `V` in the constraint, from a frozen family in which the physical-state kernel, the conditional states and the clock marginals are exactly computable. The ideal relational prediction (Schrodinger evolution under `H_S` alone) is expected to fail in specified ways, and those failures are exact expected outcomes, not surprises.
2. **Replication.** A second operator on a second machine runs the candidate and an evaluator from clean checkouts, with evaluator access genuinely separated from the candidate authors, and the semantic identities (`verdict_id`) must agree across machines.

Deferred by Drake to a later milestone: automatic clock discovery. Not in scope: any claim about physical time, gravity, cosmology or a new law. AT-1's success criterion, verbatim: "Reproducible, independently evaluated interacting-system results, not proof that time is emergent."

## 2. Source evidence

- Drake's decision (omega#371, 2026-10-10).
- `AT0_RESULTS.md` `21119a9`: section 4 (limitations), section 5 (AT-1 scope: interacting regime; second operator on a second platform), section 6 (outside view's required controls: withheld cases under independent control on another machine; checks for nonzero reference readings, complex states, degeneracy, near-matching energies, zero projections, POVM completeness; dependency controls beyond symbol scans).
- `AT0_CHARTER.md` `5638611`: sections 3 (integration decisions, carried over unless changed below), 4 (identity policy), 8 (interface change rule and the three recorded contract readings).
- Frozen AT-0 contracts: `AT0_CASE_V1.md` (`d90af74b...`), `AT0_RESULT_V2.md` (`bd0f9eb8...`). Never edited; AT-1 uses new files.
- omega `research/atemporal/at0/` and `evidence/AT0/` (immutable), `evaluator/results/hidden-run-bff4a428/`.
- Machines on hand (memory, 2026-10-10): the Spark (aarch64 Linux, where AT-0 ran), the MacBook (macOS arm64, Gemini's host), the hub Pi (aarch64 Linux, boots from a USB stick; heavy work is kept off it).

## 3. Integration decisions

1. **Interaction family (exact).** `H_total = H_C (x) I + I (x) H_S + V` with `V = sum_j |E_j><E_j| (x) (vx_j X + vy_j Y + vz_j Z)`, one rational Pauli vector `v_j` per clock level, written as `interaction_pauli <j> <vx>,<vy>,<vz>` in the case. Because `V` is diagonal in the clock energy basis, `H_total = sum_j |E_j><E_j| (x) (E_j I + h0 I + (h + v_j).sigma)`, the level-`j` system eigenvalues are `e_{j,+-} = h0 +- |h + v_j|`, and the kernel is spanned by `|E_j> (x) |e_{j,s}>` with `E_j + e_{j,s} = 0`. Rational-spectrum rule per level: `|h + v_j|^2` must be a rational square (else `CASE_IRRATIONAL_SPECTRUM`). All-zero couplings reproduce AT-0 exactly and are allowed (control class P1).
2. **Why this family.** It is the smallest coupling that changes the physics qualitatively while keeping everything exact: the kernel eigenvectors now differ from level to level, so the conditional state at reading `k` is no longer `exp(-i H_S (t_k - t_r)) psi_0` and the clock marginals `p(k)` become label-dependent (worked example in `AT1_CASE_V1.md`: `p = 5/28, 1/4, 9/28, 1/4`). Couplings that are not clock-diagonal are a later version.
3. **Two references per case, plus the oracle's own clock marginal.** The oracle writes `reference_ideal` (Schrodinger under `H_S` alone, as in AT-0), `reference_interacting` (the exact conditional probabilities of the interacting model, by its own code path), `reference_clock_probability` and `reference_label` (its own marginal and status). The case's acceptance block names `prediction_target IDEAL|INTERACTING`. Check 10 compares the engine's `pauli` lines and clock marginal with the target (the ideal marginal is the exact `w/N`); check 11 cross-checks against the oracle whenever the target is `IDEAL` (`ORACLE_DISAGREEMENT`), so an engine that silently drops `V` fails even on a case that targets the ideal prediction; check 12 compares label statuses. Two independent reviews (Codex, Opus) of the first draft found the missing marginal check and a phase-sign error; both fixed before freeze (omega#371).
4. **Carried over from AT-0 unchanged:** exact-text identities, `f64:` values as evidence only, `threads 1`, trivial-kernel rule, per-input `NOT_EVALUATED`, shape-before-range refusal order, Rust `std`-only oracle confined to its directory, C11 engine, evaluator that verifies full result files only, hidden set under commitment, immutable evidence folders, `mk/at1.mk` never in `all`/`test`, crumb compile as the separate last commit, every milestone a comment on omega#371.
5. **Isolation gate extended.** Besides symbol scans: a mutant that reads the CPU counter directly (`CNTVCT_EL0` on aarch64, `rdtsc` on x86_64) and a mutant that issues the clock syscall without libc; both must be caught by the evaluator's gate (binary scan for the instruction pattern plus a run-twice-compare control). What the scans cannot see is stated in the report, as in AT-0.
6. **Replication mechanism (gate G7).** Agent 7 is the replicating operator on the MacBook (different OS, libc, compiler and shell from the Spark). Rules: (a) before candidate freeze, Agent 7 posts on omega#371 the SHA-256 commitment of its own hidden case set (at least six cases), produced on the MacBook; the candidate authors' sessions on the Spark never see those cases before freeze; (b) at freeze, Agent 0 posts the candidate commit; (c) Agent 7 clones omega at that commit on the MacBook, builds engine, oracle and evaluator there, runs `make at1-check` and its hidden set, and opens a PR that touches only `evidence/AT1/replication-<host>/`; (d) G7 passes when the replication folder has `source_tree_clean YES`, every public case's `verdict_id` equals the Spark run's `verdict_id`, the hidden set meets expectation, and the separation facts (machine, OS, toolchain, account, who could write where) are written in the folder. Known limit, stated now: all GitHub activity is one account; the separation is by machine, by commitment digest and by folder ownership, not by identity. A second GitHub identity would strengthen it and is an open item for Drake (section 10), not a blocker.
7. **Agent 7's evaluator is Agent 4's evaluator built on the MacBook**, not a fourth code base; what is independent is the machine, the build, the run and the hidden cases. Agent 6 grades this honestly as "independent execution and withheld cases", not as "independent verifier".

## 4. Serialization and identity policy

Unchanged from `AT0_CHARTER.md` section 4. AT-1 tags: `omega.at1.case.v1`, `omega.at1.acceptance.v1`, `omega.at1.verdict.v1`, `omega.at1.evidence.v1`. No digest over floating-point bytes is ever called an identity.

## 5. Reuse and dependencies

As AT-0 (`AT0_CHARTER.md` section 5): omega `src/sha256.c` for the C sides, Rust `std` for the oracle, no Cargo, no Python, no GPU, no network. The AT-0 code bases may be copied into `at1/` by their owners as a starting point; they must not be imported from `at0/` paths, so AT-0 stays exactly what was qualified.

## 6. Case classes and gates

Case classes (Agent 1 fixes the numbers in `AT1_SPEC.md`):

- P1 zero coupling: must reproduce the AT-0 known-answer `verdict_id`-equivalent verdict and the same probabilities (continuity control).
- P2 one rotated level (the worked example), target INTERACTING.
- P3 every level coupled, full cover, target INTERACTING.
- P4 complex `psi_0` and nonzero reference reading, target INTERACTING.
- P5 large rationals within limits; P6 nearly matching energies that do not match (exact test must say no).
- N1 the P2 question with target IDEAL: expected FAIL `SCHRODINGER_DEVIATION_EXCEEDED` ("ideal relational prediction fails").
- N2 coupling that moves every level out of the kernel: `TRIVIAL_PHYSICAL_STATE`.
- N3 label-dependent marginal with one label below `tol_zero_probability`: `CONDITIONAL_UNDEFINED`.
- N4 bad POVM; N5 precision demand; N6 zero projection of `psi_0`.
- R: per-level irrational spectrum; coupling line count not `N`; coupling index out of order; every AT-0 refusal class re-expressed.
- Mutants (Agent 4): drop `V` entirely; flip the sign of `V`; apply `v_j` to the wrong level; AT-0's axis-swap, Y-sign and hidden-clock mutants; counter and raw-syscall clock mutants.

Gates: AT1-G0 freeze (this charter, both contracts, `AT1_SPEC.md`); G1 codec conformance (three parsers reproduce the worked example and digests; every refusal exact); G2 isolation (symbol scans plus counter and raw-syscall mutants); G3 oracle calibration (both references against the spec hand tables); G4 positive arm; G5 negative arm (exact codes; all mutants caught where observable, blindness explained per case); G6 independent verification on the Spark; G7 replication on the MacBook (section 3 item 6); G8 scientific review (`AT1_RESULTS.md`, PASS/FAIL/INCONCLUSIVE per claim, one outside opinion, limits and failures explicit, no new-physics claim).

## 7. Ownership matrix

| Agent | Owns (nothing else) |
|---|---|
| 0 | `AT1_CHARTER.md`, `AT1_CASE_V1.md`, `AT1_RESULT_V1.md`, AT-1 rows of `AT0_FREEZE.md`; contract readings on omega#371 |
| 1 | `AT1_SPEC.md` |
| 2 | omega `research/atemporal/at1/oracle/` (Rust, `std` only) |
| 3 | omega `research/atemporal/at1/model/` (C11) |
| 4 | omega `research/atemporal/at1/evaluator/` incl. hidden set and mutants |
| 5 | omega `mk/at1.mk`, `research/atemporal/at1/integration/`, `evidence/AT1/<run>/` on the Spark |
| 7 | omega `evidence/AT1/replication-<host>/` only, from the MacBook |
| 6 | `AT1_RESULTS.md` |

Order: 0, then 1, then 2, 3, 4 in parallel, then 5, then 7, then 6. Agent 7's commitment digest is posted before Agent 5's first run.

## 8. Interface change rule

`AT0_CHARTER.md` section 8 applies word for word, with `AT1_CASE_V1` and `AT1_RESULT_V1` as the two shared interfaces. The three AT-0 readings (component outputs are not interfaces; per-input `NOT_EVALUATED`; shape before range) are inherited. A reading that cannot be settled from the frozen text is a new version.

AT-1 readings recorded so far (ruled on omega#371, 2026-10-10, raised by `AT1_SPEC.md` section 13.6; none changes a value or an expected code):

- (c) `AT1_RESULT_V1` section 1, "two reference line families" in the oracle-written-records paragraph is a stale count from AT-0. The runner splices every oracle family, every line whose key begins with `reference_` (`reference_label`, `reference_clock_probability`, `reference_ideal`, `reference_interacting`), in values-block order, and nothing else.
- (d) In each version-bearing line the first token is the key and the rest is the value. An `AT0_CASE_V1` file given to an AT-1 tool is `CASE_PARSE_ERROR` (unknown key `OMEGA-AT0-CASE` on line 1); `OMEGA-AT1-CASE v2`, `domain omega.at1.case.v2`, `domain omega.at0.case.v1` or `contract AT1_CASE_V2` is `CASE_UNSUPPORTED_VERSION`.
- (e) The shape pass compares the parsed integer value of an index token (`interaction_pauli`, `clock_label`) with its zero-based position; canonicality is decided after the whole shape pass. `01` at position 1 is `CASE_NONCANONICAL`; a token that does not parse as an integer, or a canonical token with the wrong value, is `CASE_PARSE_ERROR`.

## 9. Handoff

Each agent reads this charter, the two contracts, `AT1_SPEC.md` once merged, and the AT-0 files named in section 2 before writing anything. Reports go to omega#371 at every milestone. Agent 5's first qualification report is what moves the program from NOT_RUN.

## 10. Discrepancies and open items

1. Second GitHub identity for Agent 7 (Drake's call; not blocking; section 3 item 6).
2. Second machine: MacBook chosen; the Pi is excluded (fragile root disk). If the MacBook cannot build the Rust oracle with the pinned toolchain, Agent 7 records the substitution.
3. `AT0_FREEZE.md` is reused as the single freeze record for the atemporal line (rows for AT-1 contracts); its name is historical.

## 11. Status

| Item | Status |
|---|---|
| Program AT-1 | RUN: G0 REFERENCE, G1 to G6 PASS on the Spark (omega run 2 on `f2b9e33`, record frozen at `ff81466`, PR 377), G7 PASS on the MacBook (omega `a392c39`, PR 381); G8 in progress (Agent 6). PASS means spec conformance only |
| AT1_CASE_V1, AT1_RESULT_V1 | FROZEN, PR 184 squash `cbe4c8e` (digests in `AT0_FREEZE.md`) |
| AT1_SPEC.md (Agent 1) | MERGED, aien-architecture PR 185, squash `81047f5` (Codex gpt-6-astra review applied; Agent 0 spot check) |
| AT1_RESULTS.md (Agent 6) | IN_PROGRESS (assigned 2026-10-10 after G7) |
| Agent 7 commitment | POSTED before Agent 5 run 1 (omega#371, MANIFEST sha256 `63b2edf0...`, 21 cases), REVEALED and recomputed at G7 (`evidence/AT1/replication-macbook/20261010T051932Z-ff81466-mac/hidden-set-reveal/`) |
| Gates AT1-G0 to AT1-G8 | G0 REFERENCE; G1 to G6 PASS (Spark); G7 PASS (MacBook, 21/21 hidden); G8 IN_PROGRESS. Defects D1 FIXED (`f2b9e33`), D2 informational, fix HELD (omega PR 380) until G8 |
| Code in omega | `research/atemporal/at1/{oracle,model,evaluator,integration}` and `mk/at1.mk`, frozen at `ff81466` |
| Evidence | omega `evidence/AT1/` (Agent 5 run folders) and `evidence/AT1/replication-macbook/` (Agent 7) |
