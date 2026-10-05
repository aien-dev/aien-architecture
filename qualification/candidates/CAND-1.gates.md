# CAND-1 gates and evidence

CAND-1 is CAND-0 plus the 2026-10-05 overnight fixes (see `CAND-1.toml` note). Frozen 2026-10-05T05:35Z.
Evidence lives on the Spark under `~/workspace/evidence-out/CAND1-*`. The campaign ledger is
`~/handoffs/2026-10-05-overnight-campaign.md`. Statuses: PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE,
BLOCKED_OPERATOR, MISSING_IMPLEMENTATION. "Host" means no chip; "QEMU" qualifies nothing physical.

## 1. Clean-worktree builds (host only)

Script `~/workspace/overnight-1005/C1/cand1_build.sh 2eec75b...` (copy in the evidence directory). Each item is
built, hashed, deleted and built again. Evidence: `CAND1-BUILD-2eec75b/summary.txt`. Verdict PASS.

| Item | Result |
|---|---|
| physics boot bins | both runs equal each other and the committed files |
| omega `all libomega_gpu` | omegatool and libomega_gpu.a identical across runs; the archive has no omegatool or gate objects (G6) |
| sovereign-core, production config, `scripts/repro-build.sh` | aien-cli, aien-proof, aien-test identical across runs; native engine linked (`has_omega_gpu`); no home-directory or cargo registry path in aien-cli (G13); no spark-max crate compiled (G7) |
| Zero-CUDA gate on aien-cli | PASS (self-test first) |
| aienos C kernel core and full images | identical across runs |
| omega link check at cb06d08 | libomega_gpu.a, gpu_matmul_api_test and the COMPOSITION-2 GPU binary build (`CAND1-BUILD-cb06d08`) |

## 2. Gate results on CAND-1

| Area | Gate | Status | Evidence / notes |
|---|---|---|---|
| R16 | G1/G2 loop inventory, every repo at its CAND-1 commit | PASS | 513 sites, 0 unclassified, 0 stale, no WARN; `CAND1-R16INV-cb06d08` (before the SC-126..129 rows: 4 unclassified, FAIL, kept) |
| CI | GitHub checks on the CAND-1 commits | PASS | omega 39/39 (2 skipped), aienos 14/14, interplane 8/8, sovereign-core 1/1 (Workspace Verification & Invariant Audit) |
| AIENOS | ck_gates (QEMU) | 18 PASS, 0 FAIL, 2 MISSING_IMPLEMENTATION | `CAND1-CKGATES-bbad5e4`; KEYBOARD (no xHCI/USB HID driver in the C kernel), M0_ROLLBACK (C loader A/B parked) |
| AIENOS | TRUST-1 M5 qualification | NOT_QUALIFIED: 20 PASS, 11 BLOCKED, 5 MISSING_IMPLEMENTATION, 1 FAIL that is BLOCKED_OPERATOR | `CAND1-TRUST-bbad5e4`; the FAIL is `t1_gate7_preflight`: Secure Boot is off on this machine (operator setting since 2026-10-01), so the preflight correctly refuses |
| Native model | strict real-model gate (TinyLlama, GB10, production build, 0 fallback) | PASS | `CAND1-NATIVE-2eec75b/receipt-strict-gate.json` |
| Native model | Omega vs own CPU reference | PASS | `receipt-omega-vs-ref.json` |
| Native model | Omega vs independent HF oracle | PASS | step-0 max abs logit difference 0.0435 against bound 0.15, same token; `receipt-omega-vs-oracle.json` |
| Native model | native paged_attention_batch, 3 sequences decoding together | PASS | `paged_batch_gb10.log`: ran on chip with >= 2 sequences per call, 0 fallback, 0 chip errors; a skipped body would fail the step |
| Native model | runtime e2e on chip | PASS | rerun with the same binary: both tests pass (`runtime_e2e_gb10-rerun.log`). The first run refused only because the batch script set AIEN_REQUIRE_RELEASE without AIEN_CHECKPOINT_ID (script defect, fixed: the label now names the test fixture weights); every functional check had passed |
| Native model | daemon serves a turn; refuses to start without a checkpoint | PASS | `daemon_positive.log`, `daemon_missing_checkpoint.log` |
| Native model | zero CUDA (script self-test, dynamic deps, symbols, strings) | PASS | `zero_cuda.log` |
| Living runtime | R16 harness `tools/r16_qualify.sh` (omega 80ca5d4, code = cb06d08) | NOT_RUN overall: G1-G5 PASS; G6 MISSING_IMPLEMENTATION; G7 NOT_RUN; G8 NOT_RUN | `CAND1-LIVING-cb06d08/R16-ladder`; G6 presence checks are not implemented; G7 waits on the R15 performance receipt (needs a quiet machine, operator); G8 is the merge-commit step outside the script |
| Living runtime | R1-R10, R12-R14 host and silicon, R15 parity host and silicon | PASS | same run; receipts copied to `qual-runs-after-R16/` |
| Living runtime | R11 living under load | NOT_RUN (BLOCKED_OPERATOR) | the load phase skips on a busy machine and now says NOT_RUN instead of PASS (omega #283); needs a quiet window |
| Living runtime | R13 test build on silicon, candidate bound | PASS | receipt `candidate_bound: true`, `candidate_commit: 80ca5d4...`, `silicon_observed: true` (unbound at CAND-0) |
| Living runtime | production hygiene on silicon | PASS | ARGUS linked and observing; refuses to run unobserved |
| Living runtime | COMPOSITION-2 GPU tier | PASS | 14/14 steps, chip failures 0 (FAIL at CAND-0: link error, fixed by omega #283) |
| Living runtime | CHIPWAIT campaign, 3 runs | PASS | `CAND1-LIVING-cb06d08/CHIPWAIT`, mechanical verdict PASS, failed [] |
| Living runtime | M18 full qualification | PASS | 18/18 gates, `CAND1-LIVING-cb06d08/M18` |
| Continuity | identity and memory restored after interruption (QEMU): M4_CONTINUITY, M4_RECOVERY, M4_ALLEN cold restore, M4_STORE_CRASH | PASS (QEMU only) | `CAND1-CKGATES-bbad5e4`; physical restore on Machine 1 is BLOCKED_HARDWARE (attended boots) |
| INTERPLANE | trust gates with exit codes, injection coverage by name, empty and partial runs refused | PASS (offline gates) | interplane #48, #49 at 5330a1c; gate M on main is the interplane owner's run after its campaign |

## 3. What CAND-1 does not prove (remaining gaps)

- **Quiet-machine gates.** R11 living under load, the R15 performance receipt (so R16 G7), and attention timing
  need the GPU without the resident llama-server and atlas processes. The CAND-0 attention A/B gave the same
  ~5.78 ms for two code versions under that load, so the timing FAIL measures the machine, not the code. BLOCKED_OPERATOR.
- **R16 G6** presence checks are not implemented (MISSING_IMPLEMENTATION). **G8** is the merge-commit step, outside the script.
- **AIENOS** has no USB keyboard driver in the C kernel and the C loader A/B and rollback are parked (MISSING_IMPLEMENTATION).
- **TRUST-1 M5:** 11 gates need attended hardware boots or operator ceremonies; 5 have no implementation; the
  Gate 7 preflight refuses because Secure Boot is off on this machine (operator setting). Not qualified.
- **Physical machine:** every AIENOS result is QEMU. Nothing here qualifies the Spark booting AIENOS.
- **Path independence** of aien-cli is inferred (no home or registry path in the binary), not tested by a build at
  a second path.
- **EST v5 D2** estimation has not run on CAND-1; it waits for the interplane campaign to end.
