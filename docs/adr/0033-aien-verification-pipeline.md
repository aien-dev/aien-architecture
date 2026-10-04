# ADR 0033: AIEN Verification: Check IR (manifest v2), exactness classes, Spark verifier, signed verification bundles, GitHub thin gate, analog authority rule

**Status:** PROPOSED, 2026-10-04. Source of authority: the operator's approved spec of 2026-10-04 (pasted by Drake Stapleton, kept verbatim at `~/handoffs/2026-10-04-aien-verification-pipeline-spec-drake.md`); this ADR fixes the engineering decisions needed to build it. Becomes ACCEPTED when its PR merges (ADR 0024/0027 convention).
**Supersedes:** nothing. **Amends:** ARCH-0028 (adds manifest v2, receipt identity members, bundles, backends; v1 manifests and EvidenceReceiptV1 stay valid). **Extends:** ARCH-0029 Decision 6 (one receipt wire contract) and Decision 9 (`aien verify-closure`): the bundle is an envelope over receipt ids and does not add a receipt format. **Related:** Crumb RFC-0002/0003 (`crumb verify` is the first portable EXACT check), ARCH-0024 (Rust scaffolding, Omega destination), the quiet-flag and GPU-lock rules (`tools/aien-test/src/resources.rs`).
**Evidence base:** aien-sovereign-core `tools/aien-test` at `14126c6` (Slices A-C merged: manifest v1, verdicts, EvidenceReceiptV1, graph, pools with the GPU lock, runner, `why`, digest cache); GitHub Actions baseline `~/handoffs/verify-pipeline/baseline/` (profiler `profile-actions.sh`, last 40 completed runs per repo); workflow files of omega, aienos, physics, aien-architecture at their 2026-10-04 heads.

---

## In plain words (read this first)

Today every change to an AIEN repository is checked by GitHub's rented computers. They start from nothing each time: install tools, download the code, rebuild everything, run every test, and then discover that the tests that need the Spark's GPU cannot run there anyway. This record decides that the Spark becomes the main verifier, that each check says up front what it needs and how exact it must be, that the Spark hands back a signed, tamper-evident record of what it ran, and that GitHub shrinks to an independent judge that re-checks that record plus a few cheap tests of its own. An analog accelerator may later help with checks that tolerate approximation, but it can never be the one that says PASS for an exact check. Nothing in correctness is removed; the saving comes from not redoing what is already proven.

## Context

1. The GitHub workflows duplicate setup and work across jobs and repositories, and a large share of jobs in physics, omega and aienos exist only to print SKIP because they need the GB10 or NVRM (see the baseline).
2. `aien-test` (ARCH-0028) already owns the pieces this needs on the Spark: declarative gate manifests, verdict derivation from observations, canonical receipts with a sha256 digest, a dependency graph, host/qemu/gb10 pools with the real GPU lock and quiet-flag refusal, and a digest cache. It lacks: exactness and capability classes beyond `host|qemu|gb10|operator`, a changed-path planner, backend abstraction, repository and executor identity, any signature, a per-commit result object, and a GitHub side.
3. GitHub cannot reach the Spark (no inbound path). The Spark can reach GitHub.
4. ARCH-0029 Decision 6 has already decided that one receipt wire contract will live in `aien-protocols`; it has not landed (`specs/evidence-receipt/SUBSET.md` is the start). A third receipt dialect is therefore forbidden here.

## Decision

### 1. Home and names
The pipeline is the next slices of `aien-test` in aien-sovereign-core, not a new runner. The per-commit layer is called **AIEN Verification**. The check IR is **gate manifest v2** (the spec's `OmegaCheckV1` semantics expressed in the manifest grammar of ARCH-0028 Decision 3, which is already the language-neutral form meant to become Omega). The Spark worker binary is `aien-verify`; the operator CLI is `aien-test` with new subcommands (Decision 10). An `aien check ...` alias is a one-line dispatcher if and when an `aien` dispatcher exists.

### 2. Manifest v2 (Check IR)
`manifest_version: 2`. Everything in v1 keeps its meaning. New top-level keys, all optional with the stated defaults so a v1 manifest is a valid v2 manifest:

| Key | Values | Default | Meaning |
|---|---|---|---|
| `exactness` | `EXACT`, `BOUNDED`, `APPROXIMATE`, `ADVISORY` | `EXACT` | Epistemic requirement (spec). `ADVISORY` can never establish a correctness or security PASS and is reported separately. |
| `requires` | list of `portable`, `aarch64`, `host`, `qemu`, `gb10`, `nvrm`, `bare_metal`, `analog_eligible`, `operator` | `host` | Capabilities, not providers. `host` means SPARK_HOST in the spec's vocabulary. v1 values keep working. |
| `tolerance` | `{metric: name, abs: int, rel_ppm: int}` lines | none | Required when `exactness: BOUNDED`; refused otherwise. Integers only (receipts carry no floats, ARCH-0028 C3). |
| `backends` | `eligible:` list and `canonical:` one of `portable`, `spark`, `qemu`, `gb10`, `analog_sim`, `analog_device` | eligible = implied by `requires`; canonical = `spark` (or `portable` when `requires` is only `portable`) | Where the check may run and which result is authoritative. `analog_*` may be eligible only for `APPROXIMATE` and `ADVISORY`, and as a non-canonical scout for `BOUNDED`. |
| `fallback` | ordered list of backends | `[spark]` | Used when an eligible non-canonical backend is unsupported, uncertain, errors, or disagrees. |
| `cache_scope` | `portable`, `arch`, `machine`, `hardware` | `machine` | What the cache key binds to (Decision 5). `hardware` results are never reused across machine descriptors and never satisfy a `--release` run. |
| `oracle` | `exit`, `observe`, `golden: <path>`, `compare: <gate>` | `exit`+`observe` as in v1 | Names the pass condition explicitly; `golden` hashes the golden file into the check identity. |

The parser stays strict: unknown keys are errors (ARCH-0028). `requires: operator` and `bare_metal` make a check `BLOCKED_OPERATOR` unless the operator starts it by hand; they are never scheduled automatically.

### 3. Check identity
`check_id = sha256` over the canonical object `{manifest_digest, input_blob_ids (git blob ids of every file under inputs, sorted by path), compiler_identity, flags, dependency_check_ids, golden_digests, scope_binding}` where `scope_binding` is empty for `portable`, the `arch` string for `arch`, the ARCH-0028 `machine_digest` for `machine`, and `machine_digest` plus the hardware identity block for `hardware`. This is ARCH-0028 Decision 7's cache key made explicit about scope; it is the identity the spec calls "deterministic across same inputs, different across different inputs, compiler, or incompatible machine profile" (tests 1-4).

### 4. Receipts and the resolution record
EvidenceReceiptV1 is unchanged in shape. Three members are added under `core` (sorted into place by canonical encoding, so old receipts remain valid and verifiable): `repository` (the normalized remote, `github.com/aien-dev/<repo>`), `executor` (`{id, class, machine_digest}` where `id` is the worker's public-key fingerprint and `class` is `portable|spark|qemu|gb10|analog_sim|analog_device`), and `cache_scope`. A cache hit never pretends to be a run: it writes a **ResolutionRecordV1** `{check_id, resolved_from: <receipt digest>, commit, repository, executor, resolved_utc}` and the bundle lists it as `cached`. When ARCH-0029 Decision 6's wire contract lands, the receipt id scheme in bundles switches by the `receipt_id_scheme` field (Decision 6 here); nothing else changes.

### 5. Cache scopes
`portable`: reusable anywhere. `arch`: reusable on the same `arch`. `machine`: reusable on the same `machine_digest` (default). `hardware`: a physical qualification; reusable only for planning information, never as a verdict for another commit, and never under `--release`. A GB10 receipt therefore cannot stand in for a host result, and a host result cannot stand in for a GB10 result (spec, "Persistent build cache").

### 6. VerificationBundleV1 (per commit, signed)
One canonical-JSON object (ARCH-0028 C1-C5 encoding): `{schema: "aien-verification-bundle/1", repository, commit, tree_digest, graph_digest, receipt_id_scheme: "sha256-canonical-json" | "aien-proof-blake3", checks: [{check_id, gate, exactness, required: bool, status: run|cached|not_run|blocked, verdict, receipt | resolution, backend}], verdict, executor: {id, class, machine_digest}, started_utc, finished_utc, signature: {alg: "ed25519", pubkey, sig}}`. `graph_digest` is sha256 over the sorted list of `(gate, check_id, depends_on)` the planner produced, so a bundle for a different check set is a different bundle. `verdict` is PASS only if every `required` check is PASS and no required check is `not_run` or `blocked`; ADVISORY checks are never `required`. The signature covers the canonical bytes with the `signature` member removed. The signing key lives in the worker user's home, mode 0600, and is never readable by the user that runs checks (Decision 9). The public key is committed in each verified repository at `.aien/verify.pub`; the verifier accepts only that key. Rejections (tests 11-13, 18): signature mismatch, `repository` or `commit` differs from the one being gated, `graph_digest` not reproducible from the manifests at that commit, a required check missing, an unknown executor id.

### 7. Verdict algebra (graph)
Unchanged set: `PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR, MISSING_IMPLEMENTATION`. Rules: a check whose dependency lacks an admissible receipt is `NOT_RUN` with reason `UNVERIFIED_DEPENDENCY` (same code as ARCH-0029 Decision 9); FAIL in a dependency makes dependents `NOT_RUN` with reason `DEPENDENCY_FAILED`; a crash, timeout or missing receipt is FAIL or NOT_RUN, never PASS; nothing promotes NOT_RUN to PASS (tests 5-7). With the Spark offline, every check whose `requires` includes `host|qemu|gb10|nvrm` is `NOT_RUN` with reason `BACKEND_UNAVAILABLE` and the commit cannot PASS.

### 8. Backends and the analog authority rule
A backend is a plain table of five functions in Rust (no trait objects beyond what the runner already uses): `supports(check) -> bool`, `prepare(check)`, `execute(check) -> Outcome`, `collect() -> receipt or estimate`, `health()`. First set: `portable` (GitHub-hosted or any host, `requires` ⊆ `{portable, aarch64}`), `spark` (the current runner), `qemu` and `gb10` (the current pools, named as backends), `analog_sim`, and a stub `analog_device` that always reports `health: absent`. **AnalogSimBackend** returns `{estimate, uncertainty}` for `APPROXIMATE`/`ADVISORY`/`BOUNDED` checks with configurable injected error (`AIEN_ANALOG_SIM_NOISE_PPM`, `AIEN_ANALOG_SIM_FAIL_RATE`). The routing policy, verbatim from the spec: inside the declared band → advisory acceptance recorded, canonical run still required for BOUNDED; near boundary (within the uncertainty of the band edge), outside tolerance, device error, or unsupported → run the canonical backend; disagreement between analog and canonical → canonical wins and a `disagreement` member is written into the bundle entry. Non-negotiable rule: analog is never the sole canonical PASS for EXACT; analog FAIL triggers digital confirmation unless the check is ADVISORY; with the analog backend disabled (`--no-analog` or absent) the same graph runs entirely on the Spark and every verdict is identical (test 19).

### 9. Spark worker `aien-verify`
Pull model: polls GitHub (`gh api`) for new heads on open PRs and the default branch of each enrolled repository, at a bounded interval, and also accepts a local trigger (`aien-verify once <repo> <commit>`). Per head: fetch; create a worktree under `~/aien-verify/wt/<repo>/<commit>`; resolve `*.lock` pins (same resolver as ARCH-0029); read `.crumb` and the shared crumb store before touching anything and claim the paths it will build in; `plan`; run through the pools (host N, qemu bounded, gb10 serialized under the existing `/tmp/aien-gb10.lock` + aien-proof slot + quiet-flag refusal, never raising the flag); write receipts; build and sign the bundle; publish the bundle and receipts to `aien-dev/aien-receipts` under `<repo>/<commit>/`; post a commit status `AIEN Verification (Spark)` with the bundle URL; release the claim and the worktree. Security boundary (test 14): checks execute as a separate unprivileged user (`aien-run`) with a minimal environment (no `GH_TOKEN`, no `HOME` of the worker), under timeouts and cgroup limits, in the worktree only; the worker user holds the signing key and the GitHub token; receipts are written by the worker, not by the check. Two GB10 checks cannot both hold the lock (test 15, existing `gpu_lock_is_exclusive` tests); independent host checks run concurrently (test 16).

### 10. Operator CLI
`aien-test plan [--base REF]` (prints Required / Cached / Needs Spark / Needs GB10 / Advisory and the execution graph as in the spec), `aien-test changed [--base REF]` (plan + run), `aien-test graph` (DOT or text), `aien-test verify-bundle <file> --repo <r> --commit <c> --pubkey <path>`, `aien-test cache status|prune`, `aien-test status` (worker health, pools, locks). Existing `run`, `test`, `why`, `list` unchanged.

### 11. GitHub thin gate
Per enrolled repository one workflow, **AIEN Verification**: checkout; `crumb verify .`; download `<repo>/<commit>/bundle.json` from `aien-receipts` (fail = NOT_RUN, status pending with a retry window); `aien-test verify-bundle` with `.aien/verify.pub`; run the repository's declared portable smoke set (manifests with `requires: portable`, bounded to minutes); publish one status. Phase 2: it runs beside the existing workflows and a comparison job records, per commit, whether the two verdict sets agree; disagreement blocks Phase 3. Phase 3: it becomes the required status and the jobs the baseline shows as duplicated, skip-only, or Spark-only are removed from GitHub. Checks that must stay GitHub-hosted for independence: `crumb verify`, the portable smoke set, and the bundle verification itself.

### 12. Planner inputs
Required checks for a commit = closure over: changed paths versus the base (`git diff --name-only`), each manifest's declared `inputs` and `depends_on`, crumb ancestry (a change under a directory invalidates the checks whose inputs contain that directory or any ancestor named in `related`), pinned repository changes (a moved `*.lock` invalidates every check that lists that pin), and an explicit allow-list of always-run checks (`crumb verify`, the smoke set). No inference from build logs in v1 (spec: explicit over clever). A declared dependency is never dropped by path filtering (test 17).

### 13. Omega boundary
Manifest v2 is the IR until Omega can express: what must hold (`oracle`), what evidence establishes it (`receipt`/`bundle`), what capabilities execution needs (`requires`), what backends are permitted (`backends`), and what constitutes refusal (`fallback`, verdict rules). The mapping is one to one by key name; `docs/aien-test/OMEGA_MAPPING.md` lists each key and its intended Omega form, and the ARCH-0028 Decision 10 byte-for-byte retirement rule applies to the planner and verifier as well.

### 14. Rollout and the pilot
Phases as in the spec. The pilot repository is chosen from the baseline by lowest risk: fewest hardware-bound jobs, no destructive or operator gates, shortest total runtime, and an existing portable check (`crumb verify`). At the time of writing that is aien-architecture (doctrine checks and `crumb` only); physics is the first repository with real Spark-only work (GB10/NVRM gates) and follows once the pilot's definition of done holds.

## Tests (mapping of the spec's 20 to slices)
Identity 1-4 and 17: Slice D. Verdict algebra 5-7: Slice E. Analog 8-10 and 19: Slice F. Bundle 11-13 and 18: Slice G. Worker 14-16 and 20: Slice H. Each slice ships its tests and mutants under the ARCH-0028 rules; the benchmark (GitHub-before, AIEN cold, AIEN warm, checks run, cache hits, redundant checks avoided) is a committed receipt in aien-receipts, not a sentence in a PR.

## Consequences
- One runner, one receipt shape, one bundle envelope; GitHub stays an independent gate with less to do.
- A new repository `aien-dev/aien-receipts` (public, Apache-2.0) and a new unprivileged user on the Spark.
- Developers see `aien-test plan` before pushing; a one-line change in a narrow component waits only for its own checks.
- The analog path is fully exercised in simulation before any device decision; hardware choice follows the measured workload.

## Not decided here
The analog device itself; the final receipt wire contract (ARCH-0029 Decision 6 owns it); whether `aien-verify` later runs as its own daemon under the Spark supervisor or stays a cron-driven poller; pool sizes beyond the ARCH-0028 defaults.
