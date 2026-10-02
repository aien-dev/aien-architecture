# ADR 0028: AIEN-TEST: manifest v1, EvidenceReceiptV1, verdict set, resource pools, incremental digests, Omega-native successor

**Status:** ACCEPTED, 2026-10-02. Decided by the operator, Drake Stapleton, through his approved `aien-test` spec of 2026-10-02 (pasted by him, which is the decision; no separate ratification step is needed). Nothing in this document is implemented. Source: the operator's approved `aien-test` spec of 2026-10-02 (`~/handoffs/2026-10-02-aien-test-spec-drake.md`), whose decisions are carried here and not reopened (no Go; Rust v1 as scaffolding; language-neutral manifests and receipts; the six-verdict set; pools host N, QEMU N, GB10 1; DAG dependencies; digests for incremental reuse; tests report observations and the evidence engine derives the verdict).
**Supersedes:** nothing. **Amends:** nothing.
**Amended by:** ARCH-0029 Decision 6 (one receipt wire contract replaces the Decision 4 format once it lands in `aien-protocols`; staged, nothing changed yet).
**Extends:** ARCH-0024 (Rust is scaffolding, Omega is destination) by applying its migration rule (Decision 6) to the test control plane. Applies `doctrine/SOVEREIGNTY.md` section 3 (the Oracle Principle) to the runner itself.
**Related:** ARCH-0021 decision 3 (append-only receipts bound to clean commits), ARCH-0016 amendment 1 (FORGE is a realization policy, not a commit step), ARCH-0027 (Lean as a temporary oracle, same pattern).
**Evidence base:** two read-only scouts of 2026-10-02: scout A, `~/handoffs/2026-10-02-AIENTEST-scout-a.md` (test control plane inventory, from shallow clones of live heads omega `c147fc8`, aien-sovereign-core `bb1c779`, aienos `31ed9f8`, physics `1ae3295`; cited below as "scout A" with the repo-relative file:line it recorded), and scout B, `~/handoffs/2026-10-02-AIENTEST-scout-b.md` (the `chip_run` rules, from omega `tools/chip_run.sh` at `341cba7`, head of omega#205, 228 lines; cited as CR-nnn with its M: line numbers). The author of this ADR did not re-read those repositories; every repository fact below is the scout's. Claims the scouts marked UNVERIFIED stay UNVERIFIED here with the scout's confidence. **Citation:** from other repositories, cite this decision as ARCH-0028.

---

## In plain words (read this first)

Today, "does this part of AIEN pass its test" is answered by a pile of shell scripts, Make targets and receipt writers, each with its own rules for locks, clean trees and logs. This decision builds one small program, `aien-test`, that reads a short description file (about 20 lines) next to each test, runs it, and writes one standard, tamper-evident record of what happened. The test only says what it saw. The program decides PASS, FAIL or one of four other outcomes by comparing what it saw with what the description file required. The first version is written in Rust because Rust is the allowed scaffolding. The description files and the records are plain text formats that an Omega-written runner can read and write later, and the two runners will be compared byte for byte before the Rust one is retired.

---

## Context

All counts below are file counts from git trees, not gate counts (scout A, "Counts" and open question 6).

1. **Omega has the largest control plane.** 117 `.sh` files, 33 `run_*.sh`, 10 `test*.sh`, 26 gate-named files, 98 files under `tools/`, 93 `test*:` Make targets in a 1656-line `Makefile` (`.PHONY` list at `Makefile:43`), 7 workflows, and 88 entries under `evidence/` (scout A). aienos has 66 non-vendor `.sh`, 13 Makefiles (`native/{argus,boot,capability,crypto,disk,kernel,m5,net,sig,store}`) and `mutants` targets in 7 of them. physics has 17 `.sh` (10 `run_*.sh`) and no Makefile. aien-sovereign-core has 22 `.sh` and no `tools/` directory (scout A). Across the four repos that is at least 222 shell files (117 + 22 + 66 + 17), which is the origin of the "150+ scripts" figure in the operator spec.
2. **Receipt formats diverge.** omega writes `<sha256>.json`, mode 0444, exclusive create, sorted-key `jq` body, blobs under `blobs/` (`tools/m20_receipt.sh:30-33`, `tools/run_divsqrt_gate.sh:7-9`). physics does the same with a sha256 over canonical sorted compact JSON (`tests/run_forge_gates.sh:8-11, 25-28`). aienos prints `AIENOS_CK_<gate>: PASS|FAIL|NOT_RUN` and records `tree_clean_before` (`scripts/ck_gates.sh:12, 271`). aien-sovereign-core's `aien-proof` defines a type named `EvidenceReceiptV1` whose id is BLAKE3 of a canonical big-endian byte encoding, with `commit` and `dirty` fields (`crates/aien-proof/src/evidence.rs:1-12, 307-310`). That is three dialects (scout A, open question 3); whether they converge was not checked.
3. **Rules are duplicated per script.** GPU lock `/tmp/aien-gb10.lock` is implemented separately in physics (`tests/run_forge_gates.sh:13-14`, `tests/run_nvrm_lifecycle_gates.sh:7,27`) and omega (`tools/run_divsqrt_gate.sh:36`). The quiet flag `~/workspace/.spark-quiet` is checked in omega (`tools/run_divsqrt_gate.sh:18,34`) and aienos (`scripts/ck_gates.sh:22-23,78`). Clean-tree checks appear in at least five scripts (scout A, "GPU lock, quiet flag, clean-tree, commit-pin rules"). Mutation runners exist in at least three styles: sed on a scratch copy (omega `tests/path/mutate.sh:1-30`), table-driven (`crates/aien-replay/mutations/run_mutants.sh:1-15`), and Make `mutants` targets (aienos). physics has none found.
4. **A consolidation is already in flight.** omega#205 (`chip_run` module and self-test), #212 (trap manifest) and #213 (transc manifest) are OPEN; `tools/chip_run.sh` is not on omega `origin/main`. Scout B extracted 100 numbered requirements (CR-001 to CR-100) from #205 head `341cba7`. Only #205 was verified line by line; the additions attributed to #212 and #213 come from `gh pr diff` greps and are UNVERIFIED-partial (confidence medium). The #205 self-test has never been confirmed PASS by the forge (scout B, CR-100).
5. **The Rust host exists.** aien-sovereign-core is a 34-member workspace (`Cargo.toml:1-38`, resolver 2), with CI running `fmt --check`, `cargo check --workspace --all-targets`, `clippy -D warnings` and `cargo test --workspace -- --test-threads=1` (`.github/workflows/ci.yml:39,45,48,51`). The lockfile already holds `serde 1.0.229`, `serde_json 1.0.151`, `sha2 0.10.9`, `blake3 1.8.7`, `hex 0.4.3` and `libc` (scout A; `aien-proof` depends on `blake3, libc, serde, serde_json`, `crates/aien-proof/Cargo.toml:9-13`). No pinned toolchain file exists, and editions mix 2021 and 2024 (scout A, open question 5).
6. **Open question carried from scout A (question 2):** `aien-proof` uses its own `slots/gpu.lock` in its board directory (`crates/aien-proof/src/board.rs:9`), not `/tmp/aien-gb10.lock`; a grep found no reference to the latter in `aien-proof` or sovereign-core scripts. Whether the two locks are bridged anywhere is UNVERIFIED (confidence medium). Decision 6 handles it.

## Decision

### 1. Crate location: `tools/aien-test` in aien-sovereign-core

Add a new workspace member `tools/aien-test` (member 35) to aien-sovereign-core. It builds one binary, `aien-test`, and one library. It uses only crates already in the lockfile: `serde`, `serde_json`, `sha2`, `libc` (for `flock`). It hand-writes its manifest parser and argument parser (`clap 4.6.7` is in the lockfile and permitted, but the argument surface in Decision 8 is small enough not to need it). No async framework; worker threads, child processes and in-process semaphores only. No `toml`, YAML or regex dependency in v1. No new outside dependency is added.

Module layout follows the operator spec: `manifest.rs`, `graph.rs`, `runner.rs`, `resources.rs`, `process.rs`, `evidence.rs`, `mutation.rs`, `cache.rs`, `verdict.rs`.

Other repositories (omega, aienos, physics) consume the built binary by pin, not by source: each carries a one-line `aien-test.lock` holding the 40-hex sovereign-core commit that built the runner, the same pattern as omega's `physics.lock` (single 40-hex line, checked at `Makefile:3-16`, scout A). The runner refuses to run if its own build commit does not match the lock.

**Alternatives considered and rejected.**

- **omega `tools/` (or any omega location).** omega has the most gates and 98 files under `tools/`, so the control plane is largest there. Rejected: omega is the destination language repository and its toolchain is C plus shell; a Rust crate there would add a cargo build to a repository whose identity is to be Omega-owned (ARCH-0024 decisions 1 and 8), and would make the runner a part of the thing it qualifies. The cargo CI, lockfile and `fmt/clippy` gates the runner needs already exist in sovereign-core and do not exist in omega (the scout lists 7 omega workflows, none cargo; UNVERIFIED that none builds Rust, confidence medium, since workflow bodies were not read).
- **A standalone repository.** Cleanest isolation. Rejected: it adds a fifth repository with its own CI, lockfile, release pinning and review path before the contract is proven, and every dependency would be a fresh outside dependency decision. It can be split out later because the contract is language-neutral; nothing here prevents that.
- **Extending the `aien-proof` crate.** It already has fingerprint stamps, gates, receipts and a hash-chained ledger (scout A). Rejected for v1: its receipt id scheme (BLAKE3 over big-endian bytes) differs from the omega and physics sha256-of-canonical-JSON scheme that Decision 4 must stay compatible with, and it is the agent preflight board rather than a campaign runner. The two share code later if the reconciliation in Open Question 1 is accepted. `aien-proof` is not replaced by this ADR.

### 2. Discovery next to code

Tests live next to the code they test with a standard shape. For a source file `src/<dir>/<name>.<ext>`:

```text
src/runtime/rx_world.c            the code
tests/runtime/rx_world_test.c     the test program
tests/runtime/rx_world.gate       the gate manifest
```

Rules:

- D1. The runner walks the repository root and collects every file whose name ends in `.gate`. It skips `.git`, `target`, `build`, `vendor`, `node_modules` and any directory containing a file named `.aien-test-ignore`.
- D2. A gate file defines exactly one gate. The `gate:` value is the gate identifier and must be unique across the repository. A duplicate is a hard manifest error, reported for both files.
- D3. Convention-implied inputs. For `tests/<dir>/<name>.gate`, the implied inputs are `src/<dir>/<name>.*` and `tests/<dir>/<name>_test.*`. The explicit `inputs` field (below) adds to them. Implied inputs let `aien-test changed` map a changed `src/x.c` to `tests/x.gate` with no further plumbing.
- D4. A `.gate` file may live anywhere under a `tests/` tree. Convention is a convenience for mapping, not a requirement for discovery.
- D5. A new feature is code, one test program and one gate manifest. Nothing else (the operator's stated goal).

### 3. Gate manifest v1 (file format)

A manifest is UTF-8 text with Unix line endings, at most 200 lines and 16 KiB. The format is a deliberately small subset that a hand-written parser in any language can read in one pass. It is not YAML and does not claim to be; it looks like YAML so that operators can read it.

**Example (full, using every field):**

```text
# tests/numeric/omega_numeric.gate
gate: OMEGA-NUMERIC-0
manifest_version: 1
owner: omega
requires:
  - host
  - gb10
depends_on:
  - NUMERIC-HOST
inputs:
  - src/omega_numeric.c
  - src/omega_numeric.h
  - tests/fixtures/numeric/
build:
  target: omega_numeric
  tool: make
run:
  exec: build/omega_numeric
  args: ["--chip", "SQRT"]
expects:
  exit: 0
  observe:
    - sqrt_max_ulp <= 1
    - fence_count == 3
    - chip_verdict == "PASS"
  verdict: PASS
timeout: 120s
mutants:
  - skip_fence
  - bad_rounding
checks:
  - no_libm_symbols
  - no_cuda_symbols
cache: allow
```

**Grammar (normative).** Lines are processed in order. `LF` ends a line.

```text
file      = { line }
line      = blank | comment | key_line | item_line | child_line
blank     = { SP } LF
comment   = { SP } "#" { any } LF           ; only at line start (after spaces)
key_line  = KEY ":" [ SP VALUE ] LF         ; no indent: top-level key
item_line = "  - " VALUE LF                  ; exactly 2 spaces, then "- "
child_line= "  " KEY ":" [ SP VALUE ] LF     ; exactly 2 spaces: child of the last top-level key
KEY       = lower-case letter { lower-case letter | digit | "_" }
VALUE     = scalar | list
scalar    = bare | quoted
bare      = one or more characters excluding LF and "#" preceded by SP; trailing SP trimmed
quoted    = JSON string literal (RFC 8259), on one line
list      = "[" [ quoted { "," quoted } ] "]"   ; single line, JSON strings only
DURATION  = integer ("ms" | "s" | "m" | "h")    ; for timeout
GATE_ID   = 1 to 64 characters from A-Z a-z 0-9 _ . -
```

**Parsing rules.**

- P1. Tabs, trailing garbage after a value, CRLF line endings, a BOM and non-UTF-8 bytes are errors.
- P2. A top-level key appears at most once. A repeated key is an error.
- P3. A top-level key has exactly one of three shapes: a scalar value on the same line, an `item_line` block (a list of scalars), or a `child_line` block (a one-level map). Mixing shapes under one key is an error. Indentation deeper than two spaces is an error.
- P4. Unknown top-level keys are an error (`BAD_MANIFEST`), never silently ignored. Unknown child keys are an error. Forward compatibility is by `manifest_version`: a runner refuses a manifest whose `manifest_version` it does not know (same refusal-on-unknown-version rule as ARCH-0024 decision 5).
- P5. `#` begins a comment only at the start of a line; inside values it is literal, except that a bare scalar ends at ` #` (space then hash). Use a quoted string to include ` #`.
- P6. Values are never evaluated: no variable expansion, no shell, no command substitution, no includes. A manifest that must vary by machine does so through `requires`, never through conditionals.
- P7. The **manifest digest** is `sha256` over the manifest file bytes after normalizing nothing: the exact file bytes. (Comments therefore change the digest. Accepted: a manifest edit of any kind is a new experiment definition.)
- P8. A parse error yields the pseudo-verdict `BAD_MANIFEST` printed by the CLI and exit code 1 (CR-003), and no receipt, because there is no valid contract to bind a receipt to.

**Fields.**

| Field | Required | Shape | Meaning |
|---|---|---|---|
| `gate` | yes | GATE_ID scalar | Unique identifier. |
| `manifest_version` | yes | integer scalar, `1` | Format version. |
| `owner` | yes | bare scalar | Owning repo or lane; copied to the receipt (CR-017 requires an owner). |
| `requires` | yes | list | Subset of `host`, `qemu`, `gb10`, `operator`. Resource classes the gate needs. Exactly one of `host`, `qemu`, `gb10` is the **pool** (the scarcest listed, order `gb10` > `qemu` > `host`); `operator` is an additional marker that a human step is needed. |
| `depends_on` | no | list of GATE_ID | Edges of the dependency DAG. A cycle is a hard error naming the cycle. |
| `inputs` | no | list of repo-relative paths | Files or directories (trailing `/`) whose bytes feed the incremental digest, added to the convention-implied inputs (D3). |
| `build` | no | map: `target`, `tool` | `tool` is one of `make`, `cargo`, `none`. `target` is the Make target or Cargo package. The runner does not become a build system: it runs the named tool and hashes the output binary. |
| `run` | yes | map: `exec`, `args` | `exec` is a repo-relative path to the binary or script. `args` is a one-line list of JSON strings, passed with no shell. Args after `--` on the command line replace `args` (CR-061). |
| `expects` | yes | map: `exit`, `observe`, `verdict` | `exit` is the required process exit status (integer, default 0). `observe` is a list of rules over observations (Decision 5). `verdict` must be `PASS` in v1 and states which verdict the contract grants when every rule holds. |
| `timeout` | yes | DURATION | Wall-clock limit. Semantics depend on pool (Decision 6). |
| `mutants` | no | list of mutant names | Names resolved by `mutation.rs` against `tests/<dir>/<name>.mutants` (one `name<TAB>sed-or-patch-spec` line each, same table style as `crates/aien-replay/mutations/*.mutants`, scout A). |
| `checks` | no | list from a closed set | Built-in policy checks: `no_libm_symbols` (CR-038), `no_cuda_symbols` (CR-039), `clean_tree_after` (CR-074 to CR-076, on by default and listed only for documentation). New names need an ADR amendment. |
| `cache` | no | `allow` (default) or `never` | `never` forbids cache reuse for this gate regardless of command-line flags (Decision 7). |

**Observation rule grammar (inside `expects.observe`).** Each item is `NAME OP VALUE` where `NAME` is `[a-z][a-z0-9_.-]*`, `OP` is one of `==`, `!=`, `<`, `<=`, `>`, `>=`, and `VALUE` is a JSON string, integer, or `true`/`false`/`null`. No floating point appears in any rule or observation (a measured float is reported as an integer in a declared unit, for example `sqrt_max_ulp`, to keep canonical encoding exact; Decision 4).

**Legacy adapter (migration only).** To carry chip_run manifests (`.chiprun`, scout B) across without rewriting the test binaries, a manifest may include `adapter: chip_run_v1`, with child keys `verdict_re`, `pass_line` and `require_all_pass` (`0` or `1`). The runner then converts every stdout line matching `verdict_re` into an observation `legacy_verdict_line` (in order) and derives the observation `legacy_last_pass` and `legacy_all_pass` per CR-062, CR-071 to CR-073. The adapter is removed once all gates emit observations natively. Adapter use is recorded in the receipt.

### 4. EvidenceReceiptV1 (JSON, immutable)

**Naming note.** `aien-proof` already defines a Rust type called `EvidenceReceiptV1` with a BLAKE3 identity (`crates/aien-proof/src/evidence.rs:1-12`). This ADR defines a different, language-neutral JSON receipt for the runner. To avoid confusion the receipt carries `"schema": "aien-test/EvidenceReceiptV1"`, and prose in this ADR means this schema when it writes EvidenceReceiptV1. Reconciling the two is Open Question 1.

**Shape.** One JSON object with exactly the top-level members `schema`, `core` and `volatile`. The split exists so that two runners (Rust now, Omega later) can be compared byte for byte on `core`, which holds everything determined by the experiment, while `volatile` holds what legitimately differs between runs of the same experiment.

`core` members (all required unless marked):

| Member | Type | Content |
|---|---|---|
| `gate` | string | Gate identifier. |
| `owner` | string | From the manifest. |
| `manifest_digest` | string | 64 hex, sha256 of the manifest file bytes (P7). |
| `commit` | string | 40 hex, HEAD of the repository under test (must not move during the run, CR-076). |
| `pins` | array of `{name, commit}` sorted by `name` | Pinned dependencies such as `physics.lock` (CR-024 to CR-026, CR-080). Empty array if none. |
| `tree_clean_before` | bool | Working tree clean before the run. |
| `tree_clean_after` | bool | Working tree clean after the run. |
| `commit_unchanged_after` | bool | HEAD and pinned HEADs unchanged. |
| `binary_sha256` | string | 64 hex of the built binary or script (CR-092). Absent only for verdicts where nothing was built (see Decision 5). |
| `build_inputs_digest` | string | 64 hex over compiler identity, flags and the bytes of every input file (Decision 7). |
| `env` | object | Captured environment: only these variables if set, sorted by key: `TZ`, `LANG`, `LC_ALL`, `CC`, `CFLAGS`, `RUSTFLAGS`, `AIEN_PROOF_OFF`, `CHIPRUN_SELFTEST`. Values are strings. Nothing else is copied, so secrets cannot leak by default. |
| `machine` | object | Machine descriptor: `arch`, `kernel_release`, `cpu_model`, `cpu_count`, `mem_total_kib`, `gb10_present` (bool), `qemu_available` (bool). |
| `machine_digest` | string | sha256 of the canonical `machine` object. |
| `exit_status` | integer or null | Process exit status; null if the process was not started. |
| `stdout_sha256` | string | 64 hex; blob at `blobs/<sha256>.log`. |
| `stderr_sha256` | string | 64 hex; same. |
| `observations` | array of `{name, value}` | In emission order (Decision 5). |
| `rules` | array of `{rule, held}` | Each `expects.observe` rule and whether it held. |
| `derived_verdict` | string | One of the six verdicts. |
| `reason` | string | First failing reason code, or `""` (CR-006: first reason wins). |
| `mutants` | array of `{name, result, stdout_sha256}` | `result` is `KILLED`, `SURVIVED` or `BROKEN` (non-compiling, scout A on `run_mutants.sh`). Empty if mutants were not requested. |
| `checks` | array of `{name, passed}` | Results of `checks`. |
| `dependencies` | array of `{gate, receipt}` sorted by `gate` | The receipt digests of each `depends_on` gate that this result rests on. |

`volatile` members: `started_utc` and `finished_utc` (strings, `YYYY-MM-DDTHH:MM:SSZ`, second resolution as in CR-092), `duration_ms` (integer), `pool` (`host`, `qemu` or `gb10`), `pool_wait_ms` (integer), `runner` (`{name, version, impl}` with `impl` = `rust` or `omega`), `cache` (`{key, reused, reused_from, mode}`: `key` is 64 hex, `reused` is bool, `reused_from` is a receipt digest or null, `mode` is `allow`, `never` or `disabled`), `timeout_exceeded` (bool).

**Canonical encoding.** Receipts are written in a restricted form of canonical JSON:

- C1. UTF-8, no BOM, no insignificant whitespace, no trailing newline in the hashed bytes.
- C2. Object members sorted by key in bytewise (unsigned UTF-8) order, at every depth. Arrays keep their stated order.
- C3. Integers only, base 10, no leading zeros, no `+`, no exponent. Floating-point numbers are not permitted anywhere in a receipt.
- C4. Strings escape only `"`, `\`, and control characters below U+0020 (as `\u00XX`, lower-case hex, except `\n`, `\r`, `\t` written as those two-character escapes); everything else, including non-ASCII, is emitted as raw UTF-8.
- C5. No duplicate keys. `null`, `true`, `false` lower-case.

**Hash rule.** The receipt digest is `sha256` over the canonical bytes (C1 to C5) of the whole object. It is lower-case hex, 64 characters. This deliberately matches the omega and physics receipt scheme (sha256 of sorted compact JSON, scout A) so existing tooling can read it. The receipt is stored at `<evidence-dir>/<digest>.json` with a single trailing LF appended to the file (the digest excludes that LF), mode 0444, created exclusively (`O_EXCL`); a collision with identical content is success, a collision with different content is a fatal error. Blobs go to `<evidence-dir>/blobs/<sha256>.log`, written via temporary file and rename, digest re-verified after write (CR-090, CR-091). Receipts and blobs are never modified or deleted by the runner. The evidence directory must not be inside the repository under test (CR-021).

**Immutability and trust limits.** A receipt is a digest, not a signature (the physics script says the same, scout A). It proves the bytes were not changed after writing, not who wrote them. Signing is out of scope here.

### 5. Verdicts and how they are derived

The set is closed: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED_HARDWARE`, `BLOCKED_OPERATOR`, `MISSING_IMPLEMENTATION`.

**Observation protocol.** A test program reports observations on standard output as lines of exactly this form:

```text
AIEN-OBS <name> <json-value>
```

`<name>` follows the NAME grammar above; `<json-value>` is a JSON string, integer, boolean or null. A test program never prints a verdict word that the runner trusts. It does not write a receipt, read the lock files, check the tree, or know its own pool. Lines that do not start with `AIEN-OBS ` are ordinary log text, captured in the stdout blob and otherwise ignored. An observation name emitted twice is kept in order; a rule over a repeated name applies to the **last** value unless written `all NAME OP VALUE` (every value must satisfy it) or `any NAME OP VALUE`. A rule over a name never emitted does not hold.

**Derivation, in order. The first matching row decides.** Each row fixes the verdict and the reason code written to `reason`.

| # | Condition (all checked by the runner, never by the test) | Verdict | Reason code |
|---|---|---|---|
| 1 | Manifest unparsable or invalid | none (`BAD_MANIFEST`, no receipt) | n/a |
| 2 | Gate declares `requires: operator` and no operator attestation file for this gate and commit exists | `BLOCKED_OPERATOR` | `OPERATOR_STEP_PENDING` |
| 3 | Gate's pool is `gb10` or `qemu` and `machine.gb10_present` or `machine.qemu_available` is false | `BLOCKED_HARDWARE` | `NO_GB10` or `NO_QEMU` |
| 4 | A `depends_on` gate's current verdict is `BLOCKED_HARDWARE` or `BLOCKED_OPERATOR` | the same blocked verdict | `DEP_BLOCKED:<gate>` |
| 5 | A `depends_on` gate's current verdict is anything other than `PASS` or blocked (including stale or absent) | `NOT_RUN` | `DEP_NOT_PASS:<gate>` |
| 6 | A refusal applies (CR-010 to CR-039, CR-050): dirty tree, lock pin mismatch, quiet flag up, GPU lock held, evidence dir inside the tree, and the like | `NOT_RUN` | the refusal id, for example `quiet_flag`, `gpu_lock` |
| 7 | The `build.target` or `run.exec` does not exist, or the build tool reports no such target | `MISSING_IMPLEMENTATION` | `NO_BUILD_TARGET` or `NO_RUN_EXEC` |
| 8 | Build fails (CR-036) | `FAIL` | `build_failed` |
| 9 | A `checks` entry fails (CR-038, CR-039) | `FAIL` | `libm`, `cuda` |
| 10 | Process exit status differs from `expects.exit` (CR-070) | `FAIL` | `rc_nonzero` |
| 11 | Any `expects.observe` rule did not hold (CR-071 to CR-073 under the adapter) | `FAIL` | `rule:<index>` |
| 12 | Tree dirty after, or HEAD moved during the run (CR-074 to CR-076) | `FAIL` | `omega_dirty_after`-style id, `head_moved` |
| 13 | `mutants` were requested and any mutant is `SURVIVED` or `BROKEN` | `FAIL` | `mutant:<name>` |
| 14 | `timeout` was hit on a `host` or `qemu` job and the runner killed it | `FAIL` | `timeout` |
| 15 | Otherwise | `PASS` | `""` |

Notes. (a) `NOT_RUN` means no experiment was performed; the pre-run refusal verdict follows CR-002 (`REFUSED: <why>` then a `NOT_RUN` line). (b) `MISSING_IMPLEMENTATION` means the contract is declared but the code it names does not exist. It is distinct from `NOT_RUN` so that "nobody has written this yet" is never confused with "it could not run now". It generalizes the aienos rule that gates without implementation report `NOT_RUN` (`scripts/ck_gates.sh:14-15`, scout A). (c) A `PASS` obtained only from reused results carries `cache.reused = true` (Decision 7). (d) The test cannot produce `PASS` by printing the word `PASS`: only rule 15 can, and only when every declared rule held.

**CLI exit codes.** 0 for `PASS`; 1 for `FAIL` or `BAD_MANIFEST`; 2 for `NOT_RUN`; 3 for `BLOCKED_HARDWARE`; 4 for `BLOCKED_OPERATOR`; 5 for `MISSING_IMPLEMENTATION`. For a campaign of several gates the exit code is the highest-numbered code among them in the order `FAIL` (1) before others, so any `FAIL` yields 1; otherwise the highest of 2 to 5; otherwise 0. These values extend CR-001 (0 PASS, 1 FAIL, `REFUSE_EXIT` default 2 for refusals); the chip_run `REFUSE_EXIT` is retained only inside the legacy adapter.

### 6. Resource pools, timeouts and the existing locks

**Pools.** Three counting semaphores inside one runner process: `host` (default size: `std::thread::available_parallelism`), `qemu` (default `min(4, host / 2)`), `gb10` (fixed 1). The qemu default is a starting guess, not a measurement (UNVERIFIED, confidence low) and is overridable with `--jobs host=N,qemu=M`; it is to be set from a measured run. A job holds exactly one pool slot. A gate with `requires: [host, gb10]` is scheduled in the `gb10` pool, because it needs the scarcest resource; its host prerequisites should be separate gates in `depends_on`.

**Scheduling.** Topological order of the DAG, then ready jobs are dispatched as pool slots free. A job whose dependency did not `PASS` is not started; it receives a derived verdict by rules 4 and 5 without running.

**GB10 job protocol** (conformance basis CR-028, CR-033, CR-050 to CR-053):

1. Refuse if the quiet flag file exists (`~/workspace/.spark-quiet`), never overriding or stealing it (CR-028, CR-050). Refuse if an `est_load` process is running (CR-029).
2. Acquire the in-process GB10 slot, then `flock -n` an exclusive lock on `/tmp/aien-gb10.lock` (created if absent, never deleted, CR-052). If the lock is held by another process, the job is `NOT_RUN` with reason `gpu_lock` (CR-033, CR-053). An explicit `--wait-gpu` flag lets the runner block instead; it is off by default so that default behavior equals chip_run's refuse-at-once.
3. Run the job. **The runner never kills, signals or times out a `gb10` job** (CR-060, and the operator's standing rule that chip tests are never killed). For `gb10` jobs `timeout` is advisory: if exceeded, `volatile.timeout_exceeded` is set and `aien-test why` reports it; the verdict is unaffected. For `host` and `qemu` jobs `timeout` is enforced by SIGTERM, then SIGKILL after 10 s, and yields `FAIL` with reason `timeout` (rule 14).
4. Release the lock by closing the descriptor immediately after the job (CR-052).

**Quiet flag.** The runner never creates the quiet flag implicitly for a campaign. It follows the CR-050 content format (`<OWNER> start=<UTC> expected_end=<UTC> pid=<pid>`, exclusive create, removed on exit only if its content still matches, CR-051) only for the duration of a single `gb10` job and only if the operator invoked the runner with `--raise-quiet`; this keeps the multi-hour-hold rule intact (the operator's standing rule of 2026-10-01 that no agent raises the quiet flag or holds the machine for hours without his approval, recorded in the operator's memory entry "No hold without approval"; not a repository file).

**The aien-proof lock (scout A open question 2).** Until the two locks are verified to be bridged, `aien-test` acquires `/tmp/aien-gb10.lock` first and then, if the `aien-proof` board directory exists (`AIEN_PROOF_DIR` or `~/.local/state/aien-proof`, `board.rs:4-14`), `slots/gpu.lock` in that directory, always in that order, and holds both for the job. Taking both in a fixed order cannot deadlock against a holder that takes only one. This is a stopgap that makes the runner safe against either lock regardless of the unknown; whether it is sufficient is UNVERIFIED (confidence medium), and unifying to one lock is Open Question 2.

**Test seams.** The chip_run self-test overrides (`CHIPRUN_QUIET_FLAG`, `CHIPRUN_GPU_LOCK`, `CHIPRUN_EST_LOAD_CMD`, `CHIPRUN_PREBUILT_BIN`) are honored by `aien-test` only through one build-time Cargo feature `selftest`, never through the environment of a release binary, which is stricter than CR-040 (which honors them when `CHIPRUN_SELFTEST=1`). The conformance suite builds with that feature.

### 7. Incremental digests and the no-cache mode

**Cache key.** `cache.key` is `sha256` over the canonical bytes of an object with exactly: `manifest_digest`, `binary_sha256`, `build_inputs_digest` (compiler identity and flags plus the bytes of every input file, where inputs are the convention-implied inputs of D3 plus `inputs`), `fixtures_digest` (folded into `build_inputs_digest` when fixtures are listed in `inputs`; kept as its own member when the manifest lists a fixtures directory), `machine_digest`, `dependencies` (the receipt digests of every dependency, recursively through their own cache keys), `runner_schema` (the string `aien-test/EvidenceReceiptV1`), and `pins`.

**Reuse rule.** Before running a gate in `cache: allow` mode, the runner looks up its key in the evidence index (an append-only file `<evidence-dir>/index.jsonl`, one line `{key, receipt, verdict}` per fresh result). A hit whose verdict is `PASS` or `FAIL` is the same experiment and the runner does not rerun it: it writes a new receipt with identical `core`, `cache.reused = true` and `cache.reused_from = <original digest>`, so that the evidence store records that this commit was checked by reuse, and prints `REUSED <digest>`. `NOT_RUN`, `BLOCKED_*` and `MISSING_IMPLEMENTATION` results are never reused, because they describe a situation, not an experiment. A key that misses runs fresh.

**What invalidates.** Any change to a hashed member changes the key. Because `dependencies` is in the key, a change to a gate's inputs changes the key of every transitive dependent. That is the mechanism by which a commit touching only `aien-kv-cache` re-runs exactly the gates whose inputs or ancestors include it and no others. How a Cargo crate maps to gate inputs in v1: a gate lists the crate directory in `inputs` (for example `crates/aien-kv-cache/`); automatic discovery of path dependencies from `Cargo.toml` is not in v1 and is Open Question 5.

**Qualification no-cache mode.** `--release` (and the explicit `--no-cache`) set `cache.mode = disabled`: lookups are skipped, every gate runs fresh, the index is still appended. A gate with `cache: never` always behaves so. Only receipts with `cache.reused = false` and `cache.mode` in (`disabled`, `never`) are accepted as qualification evidence; `aien-test why` flags a qualification claim backed by a reused receipt. Determinism of the runner's own cache key is itself conformance-tested (the same inputs on two runs give the same key).

### 8. Command surface

The binary is `aien-test`. An `aien test` dispatcher alias is intended; whether an `aien` dispatcher exists was not verified (UNVERIFIED, confidence medium), so v1 specifies only `aien-test`. Shell wrappers become `#!/bin/sh` then `exec aien-test run OMEGA-NUMERIC-0 "$@"` (operator spec).

| Command | Meaning |
|---|---|
| `aien-test run GATE [-- args]` | Run one gate (and any not-yet-PASS dependencies) and write a receipt. Args after `--` replace `run.args` (CR-061). |
| `aien-test test ./...` | Discover all gates under the current directory and run the whole DAG. |
| `aien-test test changed [--base REF]` | Run gates whose implied or declared inputs changed versus `REF` (default `origin/main`), plus every gate that transitively depends on them. |
| `aien-test test crate:NAME` | Run gates whose `inputs` include `crates/NAME/` and their dependents. |
| `aien-test test gate:NAME` | Run one gate and its dependency closure. |
| `--host` / `--qemu` / `--gb10` | Restrict the selection to gates whose pool matches. |
| `--mutants` | After a gate's normal run, run its `mutants` list; any survivor fails the gate (rule 13). |
| `--release` | Qualification mode: no cache reuse, all mutants, all `checks`, clean tree required. |
| `--no-cache` | Disable cache reuse only. |
| `--jobs host=N,qemu=M` | Pool sizes. |
| `--evidence-dir DIR` | Where receipts and blobs go. Required, with a documented default under `~/workspace/evidence-out/<repo>` mirroring omega's existing defaults (`tools/m20_receipt.sh:38`, scout A). |
| `--wait-gpu`, `--raise-quiet` | See Decision 6. |
| `aien-test why GATE` | Print the evidence chain for the gate at the current commit: its latest receipt, whether that receipt is stale (key differs from the current key, and which input or dependency changed), blocked (and by what), failed (first reason, rule index and the observed value), or reused; and the same one level at a time for each dependency. Output is plain lines, one fact per line. |
| `aien-test list` | Print the discovered gates and the DAG. |

`aien bench ./...` (structured observations bound to hardware, binary and source identity, operator spec) uses the same observation protocol and receipt, with a `bench` result class. It is named here and deferred; its format is not decided by this ADR.

### 9. Conformance: chip_run becomes the behavioral specification

omega#205, #212 and #213 are OPEN (scout B). This ADR adopts their behavior, once merged to omega main, as the conformance specification for `aien-test`: the requirements below are CR items from scout B, and each becomes a test in `tools/aien-test/tests/conformance/` named for its CR id. If the PRs change before merge, the merged text controls and this table is updated by amendment. The #212 and #213 rows are UNVERIFIED-partial (confidence medium).

| Category | CR items | How each becomes a conformance test | Mapping or deliberate divergence |
|---|---|---|---|
| Exit codes and final lines | CR-001 to CR-006 | Run a fixture gate per verdict; assert exit code, last output line and that the first failing reason is kept. | Exit codes extended to 0 to 5 (Decision 5). Output prefix `CHIP_RUN:` becomes `AIEN_TEST:`; the legacy adapter can emit the old prefix. |
| Argument and manifest refusals | CR-010 to CR-019 | One test per refusal id: bad argument, missing manifest, bad `refuse_exit`, missing required field, gate id chars (CR-018 equals GATE_ID). | Shell-variable manifests (`.chiprun`) are replaced by `.gate` (P4, P6); CR-014 to CR-016 collapse into `BAD_MANIFEST`. |
| Evidence directory | CR-019, CR-021, CR-094 | Evidence dir inside the repo or inside a pinned checkout is refused; mkdir failure is fatal. | Pinned-checkout generalized to every entry in `pins`. |
| Clean tree and commit pin | CR-022 to CR-027, CR-074 to CR-076, CR-080, CR-081 | Dirty tree, unreadable lock, lock mismatch, HEAD moved mid-run: each refused or `FAIL` as listed. | chip_run pins only physics and compares omega to itself (CR-080); `aien-test` records `pins[]` generically and always checks both before and after. `physics_tree_clean_before` hard-coded true (CR-081) becomes a real measured value. |
| Quiet flag and load | CR-028, CR-029, CR-032, CR-050, CR-051 | Flag present refuses; stale flag still refuses (no age logic, CR-050); race on exclusive create; release only if content unchanged. | The runner does not raise the flag unless `--raise-quiet` (Decision 6). |
| GPU lock | CR-033, CR-052, CR-053 | Held lock refuses at once; dead holder frees the lock; a process that only has the file open does not block (kernel `flock` semantics). | `/tmp/aien-gb10.lock` plus the stopgap second lock (Decision 6). #213's `fuser` mode (refuse on any open handle, then block on `flock`) is UNVERIFIED-partial; the v1 test set pins `flock` semantics and records `fuser` mode as a gap until #213 merges. |
| Host tier and build | CR-030, CR-031, CR-035, CR-036 | Missing source, build failure, host-tier failure leave no chip run. | The `chip_run` host tier becomes `depends_on` (a prerequisite gate, DAG-ordered). gcc flags `-std=gnu11 -O2 -Wall -Wextra -Werror -ffp-contract=off -fno-fast-math -pthread` (CR-036) are a property of the omega make targets, not of the runner. |
| Binary policy | CR-037 to CR-039 | Binary with libm or CUDA undefined symbols is `FAIL` (`checks`). | Closed `checks` set; `nm` unreadable is a `FAIL` with `nm_unreadable`. |
| Test seams | CR-034, CR-040 to CR-042 | A release build must ignore seam environment variables; a `selftest` build honors them; defaults are the quiet flag path, `/tmp/aien-gb10.lock`, `pgrep est_load` (CR-042). | Stricter than CR-040: seams are compile-time, not environment-time (Decision 6). |
| Run behavior | CR-060 to CR-062 | A `gb10` job is never killed or timed out and its log is captured; args after `--` override. | `host` and `qemu` jobs gain an enforced timeout (rule 14); chip_run has none (CR-060). |
| Fail rules | CR-070 to CR-073 | Non-zero exit, no verdict observation, last verdict not PASS, any non-PASS when all-pass is required. | Expressed as `expects.exit` and `expects.observe` rules, or through the legacy adapter. |
| Receipt | CR-090 to CR-093 | Digest equals file name, mode 0444, exclusive create, blob digest re-verified, receipt keeps required fields. | CR-092 field names map as: `omega_commit`/`physics_commit` into `commit`/`pins`; `binary_sha256` and `chip_log_sha256` into `binary_sha256` and `stdout_sha256`; `verdict_lines` into `observations`; `started_utc` and `finished_utc` into `volatile`. `RECEIPT_EXTRA_JQ` (CR-093) is dropped: receipts have a fixed schema, and #213's own limits on it (cannot forge PASS) become true by construction (rule 15). |
| Gaps chip_run itself calls out | CR-095 | Each listed gap becomes a new conformance test the runner adds: binary blob and digests-required, per-line all-pass, receipt reuse and compare. | Receipt reuse is Decision 7. |
| Mutation | CR-100 | Every refusal path in the runner carries a `refusal_point("<id>")` marker; with Cargo feature `mutation` and `AIEN_TEST_MUTATE=<id>` the marker is a no-op, and the conformance case for `<id>` must then fail. `aien-test conformance --mutants` loops over all ids and requires every one killed. | Same idea as the sed-to-`:` mutation in `tests/test_chip_run.sh` (48 tags in scout B), without editing source on disk. The 48 existing tags are the minimum set. |

Conformance is evidence-gated, not assumed: the table above is the plan. Nothing here claims chip_run's own self-test passes; scout B records that the forge has never confirmed it (CR-100).

### 10. Omega-native successor and byte-for-byte retirement of Rust

The manifest (Decision 3) and receipt (Decision 4) are the contract. Neither mentions Rust: both are plain text, with a grammar and a canonical encoding that fit in a few pages, so an Omega program can implement them. This is the contract-first path ARCH-0024 decision 6 prescribes: stabilize behavior, extract the language-neutral contract, preserve the corpus, implement in Omega, run both against one conformance suite, switch only when Omega meets the gates.

Under SOVEREIGNTY section 3 the Rust `aien-test` is a **Scaffold**: it must be registered with a deprecation horizon, and closure qualification must succeed with it absent. Registration entry (to be added to the registry when that ADR is accepted): scaffold `aien-test (Rust v1)`, horizon: retire when the Omega runner meets the retirement test below; not a dependency of the permanent lineage.

**Retirement test (all must hold):**

1. **Same conformance suite.** The Omega runner passes every conformance case of Decision 9, including mutation-killing runs.
2. **Byte-for-byte core comparison.** On a corpus of fixture experiments covering every verdict (at least one per verdict and per rule row 1 to 15 of Decision 5, plus every refusal id) and, separately, on the repository's real gates run on the same machine and commit, the canonical bytes of `core` produced by the Rust and the Omega runner are identical, and so is the `cache.key`. `volatile` is excluded from the comparison by construction. The comparison itself is run by a third program (a plain byte compare, `cmp`) so that neither runner grades itself.
3. **Disagreement is a defect in whichever runner is wrong,** decided against the manifest grammar and derivation table, not against the Rust implementation. Rust is the first oracle, not the permanent authority (Oracle Principle, SOVEREIGNTY section 3.1: oracles are references, never ancestors).
4. **A period of dual running.** Both runners execute in the forge for a declared number of campaigns (the number is fixed by the operator when Omega's runner exists; not set here) with zero core differences before Rust ownership ends.
5. **Rust is removed only after** equivalence is demonstrated and it no longer has reference value (ARCH-0024 decision 6, step 7). Until then it is kept as the reference.

The Omega runner needs process control, `flock`, hashing and file I/O. Which of these the Omega toolchain can express today is not assessed here (UNVERIFIED); that assessment is a prerequisite recorded in Migration step 6, and this ADR does not claim Omega can implement the runner now.

### 11. Going-forward rule and migration

**Rule (takes effect when migration step 4 is complete):** every new pull request that adds or changes behavior ships a gate manifest and the test it names; the forge runs `aien-test` for that gate and attaches the receipt. A new bespoke gate shell script that writes its own receipt format is not accepted once step 3 begins for that repository.

**Steps. Each step names its exit condition.**

0. **Land the spec.** Merge omega#205, #212 and #213 and have the forge confirm the #205 self-test and `--mutants` PASS (owed, scout B). Exit: `tools/chip_run.sh` on omega `origin/main`, receipt recorded. Until then this ADR's conformance table is provisional.
1. **Crate skeleton.** Add `tools/aien-test`, manifest parser with its refusal tests, canonical-JSON encoder with golden vectors, receipt writer. Exit: sovereign-core CI (fmt, check, clippy `-D warnings`, test) green; no new lockfile packages.
2. **Conformance suite.** Implement the CR table cases against fixture gates. Exit: all cases pass; `conformance --mutants` kills every id.
3. **Convert chip_run manifests.** Translate `.chiprun` manifests (for example `tools/manifests/unwritten_trap.chiprun` from #212) to `.gate` with the legacy adapter; `chip_run.sh` becomes a thin wrapper that execs `aien-test`. Exit: for each converted gate the old and the new runner agree on verdict and on the observation list on the same commit.
4. **Convert the shell estate by priority.** The 150+ scripts (at least 222 shell files across four repos, Context 1) are converted gate by gate, highest-traffic gates first, replacing bespoke lock, clean-tree and receipt code. Make targets such as the 93 `test*:` targets in omega become `aien-test run`. Exit per repository: the forge's test queue invokes `aien-test`; the going-forward rule takes effect for that repository. Receipts from converted gates use the new schema; old receipts remain valid historical evidence and are never rewritten.
5. **Dual-path period for numbers.** Reconcile receipt dialects (Open Question 1) and decide the fate of `aien-proof`'s separate lock (Open Question 2).
6. **Omega-native executor.** Assess what Omega can express, implement the runner behind the same contract, dual-run, apply the retirement test (Decision 10).

## Consequences

- A new test needs a short manifest and nothing else; locks, clean-tree rules, logs, hashing, timeouts, mutation runs and receipts are written once.
- The rule "the test reports, the engine decides" is enforced structurally: the only way to reach `PASS` is for every declared rule to hold, so no individual test can claim qualification.
- Verdicts become comparable across repos: `BLOCKED_HARDWARE` and `MISSING_IMPLEMENTATION` stop hiding inside `NOT_RUN` or `FAIL`.
- The runner is itself scaffolding and must be qualified by its own conformance suite before it replaces anything. Early on there will be two paths (old script and `aien-test`) for converted gates; step 3 requires agreement between them.
- Cost: the first version needs a manifest parser, canonical JSON, and a process and locking layer written and tested; the runner crate becomes critical infrastructure, so a runner bug can mislabel every gate. Mitigation: the conformance suite, the mutation loop, and the byte-for-byte comparison with a second implementation.
- Cross-repo gates (a gate in omega depending on one in physics) are not expressed as DAG edges in v1; they are expressed as `pins` in the receipt. A runner pin file (`aien-test.lock`) becomes part of each consuming repository.
- Nothing here changes hardware qualification claims. QEMU results remain emulator evidence only (ARCH-0024 consequences).

## Open questions (recorded, not decided here)

1. **Receipt dialects.** Whether `aien-proof`'s BLAKE3 receipt and this sha256 receipt converge into one (scout A question 3, unchecked). Name collision on `EvidenceReceiptV1` to be resolved by whichever way they converge.
2. **One GPU lock or two.** Whether `aien-proof`'s `slots/gpu.lock` and `/tmp/aien-gb10.lock` are bridged anywhere (UNVERIFIED, medium). Decision 6 holds both as a stopgap. The preferred end state is one lock; which path is canonical is not decided.
3. **Operator attestation format** for `BLOCKED_OPERATOR` gates (rule 2): what file proves a human step was done, and where it lives. Not specified in the operator spec or the scouts.
4. **Workspace hygiene.** `crates/aien-replay` is outside the workspace members but used by a mutation runner and probably not covered by CI (scout A question 4); no pinned toolchain and mixed editions (question 5). Adding `tools/aien-test` should not worsen either; whether to pin a toolchain is an unrelated decision.
5. **Crate-to-gate mapping.** Automatic derivation of a gate's inputs from Cargo path dependencies (v1 requires explicit `inputs`).
6. **Default pool sizes.** The QEMU default is a guess (Decision 6) and needs a measured value.
7. **`aien` dispatcher.** Whether an `aien` front command exists to host the `aien test` spelling (UNVERIFIED).
8. **Warm-pool and `aien bench`.** Deferred (Decision 8).

## Not decided here

The format of `aien bench` records; signing receipts; retrying interrupted jobs (the operator spec lists retry among the runner's duties; this ADR leaves its rules, including that a failed process is never rerun in a qualification run as in `tools/r15_qualify.sh:15-16`, scout A, to the implementation ADR for step 2); remote or distributed execution.
