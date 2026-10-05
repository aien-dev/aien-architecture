# Qualification candidate pinning (C2)

Status: spec, part of the AIEN Convergence Plan task C2.
Scope: how one exact integrated AIEN build is named, frozen, and judged.

## Why this exists

`CURRENT_EXECUTION_PLAN.md` line 45 says the R16 receipt binds candidate `850fc545`, that every candidate-bound R13 to R16 receipt predates omega `#126` (`4f8485b`), and that the current living build is IMPLEMENTED / NOT QUALIFIED until re-qualified. The same line records that omega `#112` merged with its `evidence-immutable` check failed. Both problems come from judging code that was not the code being shipped. A candidate manifest closes that gap.

## Reuse, no parallel format

Results are `EvidenceReceiptV1` receipts from `aien-sovereign-core/crates/aien-proof` (`src/evidence.rs`: fields `repo`, `commit`, `dirty`, `toolchain`, `procedure`, `machine`, `env_class`, `input_artifacts`, `output_artifacts`, `assertions`, `output_digest`, `result`). Formal proofs use the `formal-oracle-binding` receipt kind (`src/formal.rs`, `KIND`). This spec adds only the candidate manifest and the rules below. It does not define a new receipt. CAND-0 was frozen on 2026-10-05 and replaced the never-frozen 2026-10-01 draft of the same id.

## The candidate manifest

A candidate is a TOML file `qualification/candidates/CAND-<n>.toml`, schema `CandidateManifestV1`, with:

- `schema`, `id`, `status`, `created`.
- `[commits]`: one full 40-hex commit per repo: `omega`, `aienos`, `aien-sovereign-core` (FORGE and `aien-proof`), `aien-protocols`, `aien-architecture`. The contracts and wire schemas live in `aien-protocols`, so its pin is the contracts pin. The crumb contracts are pinned separately in `[contracts]`.
- `[executables]`: a content digest for every built binary or image under test. `UNBUILT` is allowed only while status begins with `draft`.
- `[contracts]`: one full 40-hex commit for each contract repo: `crumb-spec` (the Crumb Protocol specification) and `spark-crumbs` (its event ledger implementation). Orchestrator decision 2026-10-01: both are contracts and are pinned in every candidate. Both repos are archived on GitHub, so the pins are stable.
- Optional `[commits]` keys `physics` and `interplane` (added for CAND-0): validated like the others when present. Informational sections the checker ignores: `[consumed_pins]` (pins the pinned repos themselves hold, so a mismatch with `[commits]` is visible), `[model]`, `[toolchain]`, `[build]`, `[env]`, `[hardware]`. A candidate may carry a companion `CAND-<n>.gates.md` next to its manifest with the build recipe, the reproducibility gaps and the required gate list (see `CAND-0.gates.md`); it defines no new format and no new receipt.

`status` is one of: `draft, not frozen`, `frozen`, `superseded`. Only a `frozen` candidate may be qualified.

## Freeze rules during a campaign

1. A campaign runs against exactly one frozen candidate. Any change to a pinned commit or executable digest creates a new candidate id; the old one is `superseded`, never edited.
2. Unrelated development continues on other branches and on `main`. Freezing pins commits; it does not lock repos.
3. A fix found by the campaign lands on main as usual, then a new candidate is cut and the affected results are rerun.
4. A frozen manifest is immutable. Edits to it are rejected, the same as evidence.

## Required fields on every result

Each result (a receipt, or the campaign table row pointing to one) carries:

| Field | Meaning | EvidenceReceiptV1 home |
|---|---|---|
| source commits | the candidate id and each pinned commit used (including `[contracts]`) | `repo`, `commit`, `dirty` (must be false); `external_refs` carries the candidate id as `cand:<id>` |
| executable digest | digest of the binary or image run; must equal the manifest `[executables]` entry | `external_refs`, one entry `exe:<name>=<digest>` per executable (kept apart from inputs; `input_artifacts` is a digest list with no role tag) |
| execution environment | host, QEMU, or physical GB10 | `env_class`, `machine` |
| inputs | data, models, seeds (never the executable) | `input_artifacts` |
| commands | exact procedure | `procedure`, `toolchain` |
| raw output location | where the full output is stored | `output_artifacts`, `output_digest` |
| acceptance criteria | the pass condition, written before the run | `assertions` |
| status | `PASS`, `FAIL`, `SKIPPED`, or `BLOCKED` | `result` |

A result with a missing field, a dirty tree, or a commit not in the manifest is not a PASS. `SKIPPED` and `BLOCKED` are never reported as PASS. `Verdict` in `evidence.rs` also has `INCOMPLETE` (the run did not finish or lacked a required field). Campaign tables report it as `INCOMPLETE`, never as `BLOCKED`: `BLOCKED` means something outside the run (hardware, access, a dependency) stopped it, `INCOMPLETE` means the result itself is missing evidence. Both are not-PASS.

## Old receipts

Receipts for earlier code stay valid history. They prove what they bound. They never qualify new code: a receipt counts toward a candidate only if its `commit` and executable digest match that candidate's manifest.

## Promotion checks and exceptions

Promotion checks (for example `evidence-immutable`) are mandatory. A bypass needs a written exception under `qualification/exceptions/`, committed before or in the same change as the bypass. See `qualification/exceptions/0001-r16-immutability.md`.

## Checker

`scripts/check_candidate.sh <manifest.toml>` verifies that all required fields are present, that each pinned commit (`[commits]` and `[contracts]`) is 40 hex digits and exists in its repo (checked with `gh api`), that executable digests are 64 hex and not all zero, that a `#` inside a quoted value is kept (only a trailing comment is dropped), and that a non-draft manifest has real executable digests. Test: `scripts/test_check_candidate.sh` (the 2026-10-01 draft is kept as `scripts/testdata/cand-draft-fixture.toml`; offline: a fake `gh` on PATH exercises the real `gh` code path, and mutant copies of the checker prove each check bites). Wiring into CI is not done and needs Drake's approval.
