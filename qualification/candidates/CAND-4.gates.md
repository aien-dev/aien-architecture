# CAND-4 gates and evidence

CAND-4 is CAND-3 plus omega #321 and #322 (aienos.lock -> `b84c0a6`), sovereign-core #230, #231 and #232
(omega.lock -> `c0369e6`, composition library linked), and the tested model Llama-3.2-1B-Instruct (see
`CAND-4.toml` note and `[model]`). Frozen 2026-10-06. It supersedes CAND-3 (`CAND-3.toml` is not edited).
Evidence lives on the Spark under `~/workspace/evidence-out/CAND4-*`. Statuses as in `CAND-3.gates.md`.

## 1. Clean-worktree build (host only)

Script `cand4_build.sh` (copy in each evidence directory), adapted from `cand3_build.sh`: fresh GitHub clones,
detached worktrees at the CAND-4 commits, a fresh CARGO_HOME filled by `cargo fetch --locked`, every item built,
hashed, deleted and built again. The script refuses to build unless the lock chain matches the commits it was
given (sovereign-core `omega.lock` = omega, omega `physics.lock` = physics, omega `aienos.lock` ancestor of aienos).

| Run | Root | Result |
|---|---|---|
| CAND4-BUILD-REAL3 | `tmp/cand4/rootR3` | PASS: 25 of 25 digests identical in both builds, VERDICT PASS |
| CAND4-BUILD-TRIAL | `tmp/cand4/rootT` | the same 25 digests (omega tree of `c0369e6`; sovereign-core trial commit not on GitHub), so the digests agree across two roots |
| CAND4-BUILD-REAL, CAND4-BUILD-REAL2 | `rootR`, `rootR2` | refused mid-build: the Spark quiet flag was raised by other lanes and `make` stopped with QUIETLOCK_REFUSED; no digest difference; kept as records with a NOTE in each summary |

Checks in REAL3: physics boot bins equal the committed files; libomega_gpu.a carries no gate objects (G6); native
engine linked (`has_omega_gpu`); composition library linked (`has_omega_compose`); aien-cli carries the native
backend string; no cargo registry path in aien-cli (G13); zero-CUDA gate PASS; no TEST strings in the aienos
production images; every worktree clean after the build.

## 2. What CAND-4 does not prove yet

- Qualification (useful-workflow campaign Q1 and recovery campaign Q2) is NOT_RUN at freeze; it is planned in
  sovereign-core `docs/campaigns/cand4-qualification` (sovereign-core #234, draft at freeze).
- Release demo (package, sign/verify, install, upgrade, rollback) is NOT_RUN at freeze.
- The sovereign-core release pin (`release/candidate.toml`) still names CAND-3 at freeze. Its gate requires
  `oracle-fixture-*` digests in `[model]`; no oracle fixture exists for this model (see `[model] oracle-fixture`),
  so updating the pin needs either a fixture or a gate change.
- Distribution: internal-only until an open-licence model passes (Drake decision 2026-10-06, Option 3).
- Chip results: none; the build is host only.

## Amendment 1 (2026-10-06): oracle fixture recorded

Additive evidence only; the candidate is unchanged (same commits, executables, model and model digests), and the frozen
`CAND-4.toml` is not edited (byte-identical to 7f99d7e). The machine-readable record is
`CAND-4.amendment-1.toml`, which pins the sha256 of the frozen manifest (5f1cf9d7...) and adds two `[model]` digests;
`scripts/check_candidate.sh` reads it with the manifest and refuses a later manifest edit.

At freeze `[model] oracle-fixture` said none was recorded for this model. An independent reference fixture for
unsloth/Llama-3.2-1B-Instruct snapshot 5a8abab now exists:

- `llama32_1b_oracle.safetensors` sha256 `bf1d83edc1b802ad25cfbbce7a043658d3d4797bd67955447ce8630b51f515ed` (50834760 bytes)
- `llama32_1b_oracle_manifest.json` sha256 `6df1b39eb351db7f8626734e8de882b572c8678bab924b932640621b21235e82` (23139 bytes)

Provenance: Hugging Face Transformers runs the model on the CPU in FP32 (generator: CAND-3's
`scripts/generate_tinyllama_oracle.py` from sovereign-core `d2cacfa^`, constants-only changes; torch 2.14.0+cu130,
transformers 5.17.0, safetensors 0.8.0; `python3 -I`). It is an outside yardstick, made as scratch outside every
repository; AIEN does not depend on it at build, test or run time, and no Python is committed. Two runs gave
byte-identical files. Files and full record: sovereign-core `crates/aien-inference-abi/fixtures/` and
`docs/release/ORACLE-FIXTURE-CAND4.md` (release pin PR sovereign-core#238).

Independence check: the CAND-4 aien-cli (ad6b7eb5..., GB10 native backend) greedy 16 tokens on the same prompt gave
the same text as the oracle ("An operating system (OS) is a software layer that manages computer hardware resources,").
Text level only: aien-cli exposes no token ids or logits, so the fixture's logits and activations were not compared.
