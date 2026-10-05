# CAND-2 gates and evidence

CAND-2 is CAND-1 plus the 2026-10-05 cand3 campaign fixes (see `CAND-2.toml` note). Frozen 2026-10-05T17:57Z. It
supersedes CAND-1 (`CAND-1.toml` is not edited). Evidence lives on the Spark under
`~/workspace/evidence-out/CAND2-*`. The campaign ledger is `~/handoffs/2026-10-05-cand3-campaign.md`. Statuses:
PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, BLOCKED_INSTRUMENT, MISSING_IMPLEMENTATION. "Host" means no
chip; "QEMU" qualifies nothing physical.

## 1. Clean-worktree builds (host only)

Script `~/workspace/cand3-campaign/cand2/cand2_build.sh` (copy in each evidence directory), run twice, from two
roots: `~/workspace/cand3-campaign/cand2/rootA` and `~/workspace/cand3-campaign/cand2/rootB/deeper/path-two`. Each
root has its own detached worktrees at the CAND-2 commits and its own CARGO_HOME, empty before
`cargo fetch --locked` (root A's fetch log lists the downloads). Each item is built, hashed, deleted and built
again. Evidence: `CAND2-BUILD-A/summary.txt`, `CAND2-BUILD-B/summary.txt`. Verdict PASS for both.

| Item | Result |
|---|---|
| physics boot bins | identical in all four builds and equal to the committed files |
| omega `all libomega_gpu` | omegatool and libomega_gpu.a identical in all four builds; the archive has no omegatool or gate objects (G6) |
| sovereign-core, production config, `scripts/repro-build.sh` | aien-cli, aien-proof, aien-test identical in all four builds; native engine linked (`has_omega_gpu`); aien-cli carries the native backend string; no home-directory or cargo registry path in aien-cli (G13) |
| Zero-CUDA gate on aien-cli | PASS in both roots (self-test first) |
| aienos C kernel core and full images | identical in all four builds |
| **Path independence** | PASS: all nine digests are the same from root A and root B. CAND-1's omegatool FAIL (embedded physics checkout path) is closed by omega #296 |
| Pins | `scripts/check_candidate.sh` OK; `scripts/check_candidate_pins.sh` PINS AGREE (sovereign-core omega.lock and Cargo.lock, omega physics/aienos/argus locks, every known consumed pin) |
| crumb tool | omega and aienos `crumb.lock` pin aien-architecture `d0f0b95`; `git diff d0f0b95 7390f5d -- tools/crumb` is empty (gap G3 unchanged: different commit, same tool source) |

Eight digests equal CAND-1's: omega-gpu-engine-lib, aien-cli-native-release, aien-proof, aien-test, both aienos
images and both physics bins. Only omega-runtime (omegatool) is new.

## 2. Results carried from CAND-1 by executable identity (not rerun)

CANDIDATE.md freeze rule 3 reruns the results a change affects. These CAND-1 results ran executables whose CAND-2
digests are byte-identical, at inputs that did not change; they are carried, labelled as such, and their receipts
still name CAND-1. They are not new runs.

| Area | Gate | CAND-1 status | Why it carries |
|---|---|---|---|
| Native model | strict real-model gate; Omega vs CPU reference; Omega vs HF oracle; paged_attention_batch; runtime e2e; daemon; zero CUDA | PASS | aien-cli, aien-test and libomega_gpu.a digests identical; same model inputs |
| Attention | GB10 attention timing, TinyLlama shape (quiet window 1) | PASS | gpu_attention_test is built from `tests/gpu_attention_test.c`, `src/omega_gpu_attention_api.h` and libomega_gpu.a: the two sources are unchanged cb06d08..79a805d, no CC or CFLAGS line changed, and the library digest is identical |
| AIENOS | ck_gates (QEMU): 18 PASS, 2 MISSING_IMPLEMENTATION | as CAND-1 | aienos images identical |
| AIENOS | TRUST-1 M5: NOT_QUALIFIED | as CAND-1 | aienos images identical; the attended steps are still blocked on the operator |
| Continuity | M4_CONTINUITY, M4_RECOVERY, M4_ALLEN, M4_STORE_CRASH (QEMU only) | PASS (QEMU) | aienos images identical |

## 3. Results that must be rerun on CAND-2 (omegatool changed)

Every living-runtime result ran omegatool or binaries built from the changed omega tree, so none carries. They run in
one quiet window under declared attempts (`~/workspace/cand3-campaign/cand2/DECLARED-ATTEMPTS.md`, sha256 announced
before the window). Results are added to this section after the window, with an independent reconstruction of the
verdict from the receipts.

| Attempt | Gate | Status |
|---|---|---|
| A1 | R16 harness `tools/r16_qualify.sh` (omega c62f47b, code = 79a805d) | NOT_RUN (pending window) |
| A1b | R11 living under load | NOT_RUN (pending window) |
| A2 | R13 test build on silicon, candidate bound | NOT_RUN (pending window) |
| A3 | production hygiene on silicon | NOT_RUN (pending window) |
| A4 | COMPOSITION-2 GPU tier | NOT_RUN (pending window) |
| A5 | CHIPWAIT campaign, 3 runs | NOT_RUN (pending window) |
| A6 | M18 full qualification | NOT_RUN (pending window) |
| A7 | R15 silicon performance acceptance | NOT_RUN (pending window); expected BLOCKED_INSTRUMENT while the SPBM energy reader is not loaded |
| - | INTERPLANE offline gates: GitHub checks at the pinned commit 2049968 (interplane changed in #50-#68 and #208 since CAND-1: rust crates, adapters, conformance, bench, spec; CAND-1's result does not carry) | at freeze: 6 success, 2 in progress |

## 4. What CAND-2 does not prove (known before the window)

- **R16 G6:** the operator emergency stop exists in the runtime (omega #300, host-tested, 13 mutants) but the
  production program does not wire it and has no operator entry point, so the item reads MISSING_IMPLEMENTATION and
  G6 cannot pass. No silicon run exercises a stop. **G8** is the merge-commit step, outside the script.
- **R15 / R16 G7:** the SPBM energy reader is not loaded (operator action: load the signed module, steps in
  `~/handoffs/2026-10-05-spbm-energy-operator-steps.md`). R15 refuses to start (omega #295, BLOCKED_INSTRUMENT), so
  G7, which needs an R15 PASS, cannot pass. CAND-1's R15 FAIL (G15 residency 0.849 from one stalled trial, SEQ-06)
  is unexplained; a 30-trial diagnostic later saw 100 % residency in every trial, which is a clue, not a verdict.
- **AIENOS:** no USB keyboard driver in the C kernel; C loader A/B and rollback parked (MISSING_IMPLEMENTATION).
- **TRUST-1 M5:** attended hardware boots and owner-key ceremonies are blocked on the operator; Secure Boot is off.
- **Physical machine:** every AIENOS result is QEMU. Nothing here qualifies the Spark booting AIENOS.
- **Toolchain:** no rust-toolchain file pins the compiler (gap G4); both roots used the same installed toolchain.
