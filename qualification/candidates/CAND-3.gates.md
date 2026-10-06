# CAND-3 gates and evidence

CAND-3 is CAND-2 plus the omega changes #301, #304, #305, #306, #309, #312 and the
sovereign-core `omega.lock` bump to `f816473` (#218) and the rust toolchain pin (#216, closes gap G4 for sovereign-core) (see `CAND-3.toml` note). Frozen 2026-10-06. It supersedes CAND-2
(`CAND-2.toml` is not edited). Evidence lives on the Spark under `~/workspace/evidence-out/CAND3-*`. Statuses: PASS, FAIL,
NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, BLOCKED_INSTRUMENT, MISSING_IMPLEMENTATION. "Host" means no chip; "QEMU"
qualifies nothing physical.

## 1. Clean-worktree builds (host only)

Script `~/workspace/cand3-campaign/cand3/cand3_build.sh` (copy in each evidence directory), run from two roots
(`~/workspace/cand3-campaign/cand3/rootA` and `.../rootB/deeper/path-two`); each root has its own detached worktrees at the CAND-3
commits and its own CARGO_HOME filled by `cargo fetch --locked`. Each item is built, hashed, deleted and built again (4 builds per
item). Evidence: `CAND3-BUILD-A/summary.txt`, `CAND3-BUILD-B/summary.txt`, `digests.txt` in each. Both verdicts PASS.
`cand3_compare.sh`: PASS, all 18 required artifacts identical from both roots.

| Item | Result |
|---|---|
| physics boot bins | identical in all four builds, equal to the committed files |
| omega omegatool and libomega_gpu.a | identical in all four builds, equal to CAND-2; the archive carries no gate objects (G6) |
| omega production and window executables (new in the manifest: rx_operator, rx_r13_living_host, rx_r13_living_silicon, rx_r13_living_testbuild_silicon, rx_r11_aien_test, rx_composition_gate_gpu, rx_r15_perf_silicon, rx_r15_perf_silicon_nodigest, r15_reduce) | each identical in all four builds |
| sovereign-core production config, `scripts/repro-build.sh` (toolchain from `rust-toolchain.toml`, 1.98.1) | aien-cli, aien-proof, aien-test identical in all four builds and equal to CAND-2; native engine linked; no home or cargo registry path in aien-cli (G13); zero-CUDA gate PASS |
| aienos C kernel core and full images | identical in all four builds and equal to CAND-2 |
| Pins | `check_candidate.sh` OK; `check_candidate_pins.sh` PINS AGREE (sovereign-core omega.lock f816473, Cargo.lock aien-protocols 7ac6fac, crumb-spec 24194d1, spark-crumbs 9355a92; omega physics.lock 6d7cf0d, aienos.lock bbad5e4, argus.lock b375dca). Consumed revisions, not heads (aien-protocols head 3a4cdbe and interplane main are not what the code consumes; interplane is pinned at its main 9129936) |
| crumb tool | omega and aienos `crumb.lock` pin aien-architecture `d0f0b95` (gap G3); `git diff d0f0b95 dcca843 -- tools/crumb` is empty |
| G4 toolchain | closed for sovereign-core: `rust-toolchain.toml` (sha256 887f9be0...1167) pins 1.98.1; C parts use the installed gcc 13.3.0 and binutils 2.42, unpinned |

Digest delta against CAND-2: none of the nine CAND-2 digests changed. The nine new entries are additions to the list, not changes.

## 2. Results carried from earlier candidates by executable identity (not rerun)

`docs/qualification/CANDIDATE.md` "Carry-forward of evidence by executable identity" (#143) governs what may carry. Its six rules:
(1) the executable's sha256 in this manifest equals the earlier frozen manifest's, to the bit; (2) every input unchanged, and a gate's
own test binary shown byte-identical; (3) same environment class, labelled "carried from CAND-N by executable identity (not rerun)" with
the earlier candidate id and receipt sha256; (4) no change of gate script, harness or thresholds; (5) BLOCKED, NOT_RUN, FAIL and
NOT_QUALIFIED carry only as the same status; (6) silicon performance (R15) never carries.

Rule 1 evidence: `CAND3-BUILD-A/digests.txt` against `CAND-2.toml [executables]`: omega-runtime 5a308427, omega-gpu-engine-lib a4af0881,
aien-cli-native-release 3a17ee79, aien-proof a37247a1, aien-test 34ae31e5, aienos-boot-image 8b1595cc, aienos-ck-core-image a21218dc,
physics-boot-bin 4b22a08c, atlas-m2-boot-bin 1d6d75a6: all nine identical. `cand3_carry_check.sh` (evidence `CAND3-CARRY-79a805d`) rebuilt at the CAND-2 code
commit 79a805d with the CAND-3 recipe: omegatool, libomega_gpu.a and r15_reduce IDENTICAL; rx_r13_living_host and _silicon,
rx_r13_living_testbuild_silicon, rx_r11_aien_test, rx_composition_gate_gpu, rx_r15_perf_silicon and _nodigest CHANGED.
The CAND-2 rx_r11_aien_test rebuild (37c15f75) equals the digest recorded in the CAND-2 window, which supports the check's method.

| Area | Gate | Status | Basis |
|---|---|---|---|
| Native model | strict real-model gate; Omega vs CPU reference; Omega vs HF oracle; paged_attention_batch; runtime e2e; daemon; zero CUDA | carried from CAND-1/CAND-2 (receipts name CAND-1) | aien-cli, aien-test and libomega_gpu.a identical (rule 1); model inputs unchanged (`[model]`, rule 2); same environment class (rule 3) |
| Attention | GB10 attention timing, TinyLlama shape | carried from CAND-1 | libomega_gpu.a identical; `tests/gpu_attention_test.c` and `src/omega_gpu_attention_api.h` unchanged 79a805d..f816473 (rule 2, to be shown with `git diff` empty and the test binary rebuilt byte-identical, as CAND2-ATTN-IDENTITY, before this row is final) |
| AIENOS | ck_gates (QEMU): 18 PASS, 2 MISSING_IMPLEMENTATION; TRUST-1 M5 NOT_QUALIFIED; M4_CONTINUITY, M4_RECOVERY, M4_ALLEN, M4_STORE_CRASH (QEMU) | carried, same statuses | both aienos images identical, aienos pin unchanged |
| M18, M19 / CHIPWAIT | matmul gates; 3 x M19R | carry-eligible (omegatool identical, tools unchanged) but rerun in the window so the receipts name CAND-3 | - |
| R16, R13, R11, COMPOSITION-2, production hygiene | all | NOT carried: executable CHANGED or gate script changed (rule 4: `r16_qualify.sh` changed in #309) | carry check |
| R15 | silicon performance | NOT carried (rule 6) | - |

## 3. Results rerun on CAND-3

Not yet run. The window is declared in `DECLARED-ATTEMPTS.md` (sha256 recorded when published) and its results are added here after it,
as CAND-2.gates.md section 3. Attempts: A1 R16 ladder with G6 operator control (host, mutants, silicon), A1b R11, A2 R13 test build,
A3 production hygiene, A4 COMPOSITION-2 GPU, A5 CHIPWAIT 3/3, A6 M18. A7 R15 is NOT ATTEMPTED in that window.

## 4. What CAND-3 does not prove (known before the window)

- **R15 / R16 G7:** the SPBM energy reader is not loaded; R15 is not attempted in the first window; G7 needs an R15 PASS. R15 is a separate later attempt.
- **R16 G6:** exercised by execution only if the window's A1 says so; effects already outside the world when a stop lands and a same-uid deletion of the halt mark while no program runs are not covered (`docs/r16-operator-control.md`, omega #309).
- **G8** is the merge-commit step, outside the script.
- **AIENOS:** no USB keyboard driver in the C kernel; C loader A/B and rollback parked (MISSING_IMPLEMENTATION). Every AIENOS result is QEMU.
- **TRUST-1 M5:** attended hardware boots and owner-key ceremonies blocked on the operator; Secure Boot is off.
- **Toolchain:** G4 closed for sovereign-core (`rust-toolchain.toml`); gcc and binutils are not pinned.
- **CHIPWAIT:** each soak is 100,000 cycles in about 41 to 43 s, not hours of endurance.
- **Known intermittent host failures** under heavy load (omega #313): R13 mode-E wall-clock goal check, mutant-suite log loss, R13 failure reason only on stderr. The window declares full capture and no retry of a FAIL.
- **Open omega PRs not in CAND-3:** #310 (GPU reconvergence), #303, #307 (prime race).
