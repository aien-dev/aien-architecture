# Integration and release audit, 2026-10-11 (Lane G)

Issue: aien-dev/aien-architecture#203. Programme: #190. Read 2026-10-11 ~03:30 to 04:30 UTC from fresh clones: aien-sovereign-core (sc) main `1fac70c`, aien-architecture main `f932e02`, omega main (GitHub API). Labels: EVIDENCED (read in code or a receipt, source given), GAP (the system lacks it), STALE-DOC (a document says something the code or a receipt contradicts). Nothing here is a PASS claim for any programme step. Pins were not bumped.

## 1. Cross-repository pins

| Item | Label | Where | Detail and exact fix |
|---|---|---|---|
| sc `omega.lock` vs CAND-4 omega | GAP | sc `omega.lock` = `6c6180cf`; `release/candidate.toml` omega-commit and CAND-4 `[commits] omega` = `c0369e67` | `scripts/check-release-candidate.sh` exits 1 on current main: "omega.lock is 6c6180c but candidate CAND-4 names omega c0369e6". omega `6c6180c` is 11 commits ahead of `c0369e6` (GitHub compare). Owner: sc#414 (new; sc#92 is closed). |
| sc source vs CAND-4 source commit | GAP | `candidate.toml` `sovereign-core-commit` = `d5b78ff`; main is 130 commits ahead and 236 crate or Cargo files differ | The 25 `[executables]` digests (aien-cli-native-release and helpers) are digests of a `d5b78ff` build. A tree 130 commits later cannot reproduce them (INFERRED, high confidence: the CLI crates changed). Fixing `omega.lock` alone does not make the gate pass `--package`. A new candidate (CAND-5) with new digests is required. Owner: sc#414. |
| omega `physics.lock` / `aienos.lock` | EVIDENCED, consistent | omega at `c0369e6`, `6c6180c` and main all pin physics `6d7cf0d4` and aienos `b84c0a67`; CAND-4 names the same two | No drift. |
| Cargo.lock git pins | EVIDENCED, consistent | sc `Cargo.lock`: aien-protocols `7ac6fac`, crumb-spec `24194d1`, spark-crumbs `9355a92` | Equal to `candidate.toml [pins]` and CAND-4 `[commits]`/`[contracts]`. |
| CI checkout steps | EVIDENCED, consistent | sc `release.yml` and `ci.yml` check out omega at `omega.lock`, physics and aienos at omega's locks | Matches `scripts/pins.sh` (same three checkouts). `pins.sh --check` was not run here (needs a populated target directory); its tests run in CI (UNVERIFIED locally, confidence 80%). |
| Which commit could be released today | GAP | no tag exists past `v0.1.1` (internal test, `omega.lock` `5e29b82`, old key) | Only a tree whose `omega.lock` is `c0369e6` passes the gate; `d5b78ff` is that tree, but it predates the offline-signing work (#407), so it has no `release-publish.yml` gate or install labels. No commit today satisfies both "passes the CAND-4 gate" and "has the signing path". |
| CAND-4 licence | GAP | CAND-4 `[model] distribution` = "internal-only until an open-licence model passes" (Llama 3.2 Community License) | CAND-4 can never be a public release. CAND-5 (Qwen3) depends on sc#384. |

## 2. Operator experience from a clean machine

Method: downloaded the dry-run artifact (Actions run 38105672607, `dry-run-signed-assets`, built from `46c4e0d`, success) and installed it with sc main's `install.sh` into a scratch HOME with `AIEN_RELEASE_TAG`, `AIEN_RELEASE_BASE_URL=file://...`, `AIEN_DRY_RUN_SIGNERS`. Installed and checked 17 files; receipt `signature_check: dry-run-key`, `dry_run: true`, `candidate: NOT-RELEASABLE`. Seven commands linked into `~/.local/bin`. Nothing was started as a daemon beyond one refused `aien start`.

| Step | Label | Docs say | Code does |
|---|---|---|---|
| README install note | STALE-DOC | "install.sh ... performs no signature verification; signed releases are not yet available" | Release mode verifies the signature (`ssh-keygen -Y verify`) and writes `install-receipt.json`. Fixed by sc#415. The sentence "no public release exists" stays true. |
| Quickstart printed by the installer | GAP | `aien start` starts Cortex, Cockpit and daemons | `aien start` exits at once: "the approval desk is required ... key is not usable ... Create it with `aien compose desk-key --create 1`". No documented step creates the key; only `scripts/whole_system_e2e.sh` does. Fix in `install.sh` text or a first-run step: sc#414. |
| `aien harness` | GAP | "Run 5-layer verification checks" | Runs `spark-harness check`; that binary has no `check` subcommand (observed `unrecognized subcommand 'check'` against the developer's own copy) and `spark-harness` is not in the release archive (`bin/` holds aien, cortex-rs, cortex-encoder-rs, spark-cockpit-rs, spark-debugger, spark-inquisitor, spark-supervisor). |
| `aien chat` / `/doctor` banner | STALE-DOC | n/a | Banner says "Modular MAX 26.5, Resident Seat: Port 18006" although the project decision is to leave MAX; `/doctor` probes ports 18006/18082/18080/18085. Not part of the acceptance path. |
| Model provisioning | GAP | installer: "Model and access-token provisioning remain." | No operator document says where weights go or which variable names them. Only the E2E script uses `AIEN_MODEL_PATH` (script lines 231, 287, 406). |
| First objective | EVIDENCED | ACCEPTANCE_E2E E2: `aien-cli objective record` | After `compose desk-key --create 1`, `aien objective record --text ...` returns `recorded_before_work: true`, `operator_surface: aien-cli`; `--effect-class EXTERNAL_IRREVERSIBLE` is refused `ForbiddenEffectClass`. |
| Objective record location | GAP | contract calls the record durable | Default directory is `/tmp/aien-provenance/objectives` (`crates/aien-runtime/src/objective.rs:27-32`, `crates/aien-cli/src/tools.rs:464`). The installer does not set `AIEN_PROVENANCE_DIR`. A reboot that clears `/tmp` loses the record. Owner: sc#414. |
| RELEASE_NOTES.md v0.1.0 binary list | STALE-DOC (historical) | lists `aegis-runtime`, `bench_inference_stack` | Not in the current archive. The file is headed as v0.1.0 notes and already says v0.1.0/v0.1.1 are internal; left unchanged. |

## 3. Service boundaries named by ACCEPTANCE_E2E

| Component | Label | Where on main | Owner doc | Test |
|---|---|---|---|---|
| Operator CLI (`aien`, crate aien-cli) | EVIDENCED | `crates/aien-cli` | crate `.crumb`; no `CONTEXT.md` in sc | `crates/aien-cli/tests/objective_record_test.rs`, `test_cli_runtime_ipc.rs` |
| Daemon (aien-runtime, started by `aien start`) | EVIDENCED | `crates/aien-runtime` | `docs/AIEN_RUNTIME_ARCHITECTURE.md`; release receipt shows `daemon_sha256 = cli_sha256` (one binary) | 57 test-bearing files; `recovery_matrix_test.rs`, `desk_required_startup_test.rs` |
| Approval desk | EVIDENCED, doc thin | `aien compose desk-key`, compose flow | `docs/COMPOSE_PROPOSER_HOOK.md` (desk key section). No ADR names the desk as a component. | `desk_required_startup_test.rs` |
| ALLEN memory | EVIDENCED | `crates/aien-allen`, `aien-allen-memory`, `aien-allen-profile` | aien-architecture ADR 0035; `crates/aien-allen-memory/RETENTION.md` | `allen_concurrency_test.rs`, `compose_memory_recall_test.rs` |
| Cortex | EVIDENCED, split owner | sc `crates/cortex-rs` (non-authoritative per its README), omega Cortex per ADR 0022 | ADR 0022, ADR 0036 (release v1 memory owner) | `cortex-rs` tests (9 files). The shipped release uses sc `cortex-rs`. |
| Verifier | EVIDENCED | `tools/aien-verify` (std-only Rust), plus `crates/aien-campaign-verifier` (NEXT-PHASE-2) | `docs/campaigns/whole-system-e2e/VERIFIER-v1.md`; ADR 0033 | `tools/aien-verify/tests/run.sh`; used by the harness for E5/CTRL-E5 |
| GB10 backend | EVIDENCED | sc `crates/aien-omega-gpu`; engine in omega | ADR 0016 line in `CURRENT_EXECUTION_PLAN.md`; `ACCEPTANCE-v1.3-gb10.md` | 2 test files in the crate; RUN-2-GB10 (sc#413) exercised it, verdict FAIL on one text row |
| `CONTEXT.md` for sc | GAP | absent (aien-architecture has one) | AGENTS.md says single-context layout per repo | n/a. Low severity; not filed as blocking. |

`tools/aien-verify` is referenced by no workflow in `.github/workflows` and no `scripts/test-*.sh` (grep, 2026-10-11); only the harness builds it per run. So its own tests (`tools/aien-verify/tests/run.sh`) do not appear to run in CI (OBSERVED by grep; whether a path-based trigger runs them is UNVERIFIED). Candidate fix: add them to `ci.yml` (sc#414).

## 4. Completion claims against tonight's evidence

| Claim location | Label | Finding |
|---|---|---|
| aien-architecture README "Current state" | EVIDENCED honest | Says pre-alpha, kernel not qualified, R1 to R16 not requalified. No change. |
| `CURRENT_EXECUTION_PLAN.md` addendum 2026-10-10 | STALE-DOC | Says WHOLE-SYSTEM-E2E "Status 2026-10-10: NOT_RUN". Runs exist since: RUN-1 (CPU, E2, E3, E3m, E4, E6 PASS; E1, E5, CTRL-E1 not run), second-machine verdict R7, RUN-2-GB10 FAIL. Fixed by the dated addendum in this PR. |
| `GAP_ASSESSMENT.md` "NOT_RUN" | Dated snapshot | Written 2026-10-10 as a snapshot; left unchanged. |
| sc README | STALE-DOC | Fixed by sc#415 (see section 2). |
| Any document calling a release signed | none found | sc `docs/release/RELEASE_SIGNING.md` says plainly that the public key is a placeholder. RELEASE_NOTES.md says internal test. |
| `docs/STATE_OF_AIEN.md` "Versioned Release Packaging: Resolved" | STALE-DOC (mild) | Resolved means a tagged workflow and checksums exist; there is still no public signed release. Not edited (the file is a dated deficit inventory; wording risk of an unreviewed rewrite). Reported only. |
| R8 (installed signed release) | NOT RUN | RESULT-RUN-1 marks E1 and CTRL-E1 NOT_RUN pending a signed artifact. |
| AIENOS native | NOT_RUN | `GAP_ASSESSMENT.md` section on AIENOS: native is NOT_RUN for every acceptance step; B7b needs a machine window. |

## 5. Open pull requests older than three days (created before 2026-10-08 03:40 UTC)

| Repo / PR | State | Waits on |
|---|---|---|
| aien-sovereign-core #278 | draft, DIRTY (conflicting), created 2026-10-07, CI success | Its own text: "Not evidence-backed yet; do not merge on this alone." Closes nothing; its issue #277 is CLOSED. Needs a rebase and a decision to keep or close. |
| aien-protocols #16 | draft, DIRTY, created 2026-10-08 | OSH Platform ABI v1 DRAFT; freezes after the Linux adapter consumes it once. aien-architecture#158 is OPEN. Needs a rebase when the freeze is decided. |

Younger open PRs, for completeness (not older than 3 days): sc #413 (BLOCKED, RUN-2-GB10 evidence), sc #370 (CLEAN, process), aien-architecture #178 (DIRTY, 2026-10-09, process), aienos #300 (draft, DIRTY, 2026-10-10, int8 kernel, waits on Drake's go for the default). omega, physics, spark-rsi, aegis-runtime, interplane: 0 open. Nothing was merged or closed.

## Release blockers, in order

1. The public signing key does not exist (Drake-only key ceremony, `docs/release/KEY_CEREMONY.md`). Until then nothing can install as `release`.
2. No open-licence model has passed. CAND-4 is Llama and internal-only; Qwen3 v5 verdict is FAIL (262 of 334 declared rows PASS, sc `docs/campaigns/open-model-qwen3/VERDICT-v5.md`) and sc#384 (v6) is open.
3. No candidate matches current main: the gate fails on `omega.lock` (`6c6180c` vs `c0369e6`), and 130 commits of source drift make the CAND-4 executable digests unreproducible. Needs CAND-5 in `qualification/candidates/`, then `release/candidate.toml` and `omega.lock` bumped together (sc#414).
4. R6 verdict is FAIL (RUN-2-GB10, one text row; E4 rows did not run); a clean GB10 run is needed.
5. R8 not run: an installed, signed release has never been through the harness (E1, CTRL-E1).
6. Install path gaps in section 2 (desk key step, `aien harness`, model provisioning, `/tmp` objective store).

## Not claimed

Not claimed: that any release is signed or qualified; that the model is qualified; that R6, R7-on-GB10 or R8 passed; that AIENOS native works; that the 25 candidate digests are or are not reproducible today (only that the source changed); that `pins.sh --check` passes locally; that the verifier tests are absent from every CI path (grep only). The dry-run install shows the installer and the dry-run artifact agree; it says nothing about the production key.
