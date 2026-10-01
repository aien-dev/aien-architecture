# Invariant manifest schema (version 0, provisional)

This directory is the implementation-neutral registry of formal invariants (ARCH-0027, FORMAL-1). A manifest says what must be true, in AIEN terms. It never contains Lean, Rust, C, or Omega source. The semantic content is meant to be permanent; this file format is not (ARCH-0027 says the format may change, the invariant IDs may not).

One TOML file per invariant, named `<area>-<name>-v<N>.toml`. The invariant ID survives migration between oracles and implementations. Lean theorem names, Rust function names, and file offsets do not identify an invariant.

## Fields

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | integer | Manifest format version. `0` today. |
| `id` | string | Stable ID, `AIEN.INV.<AREA>.<NAME>.V<N>`. Never reused for a different meaning. A changed meaning gets a new `V<N>`. |
| `version` | integer | Same `N` as in the ID. |
| `status` | string | `PROPOSED`, `SEEDED`, or `ACTIVE`. `SEEDED` = text written, no oracle model yet. Nothing here is `ACTIVE` until an oracle result is bound to evidence. |
| `statement` | string | The invariant in plain words, implementation neutral. |
| `assumptions` | array of strings | What is taken as given (for example cryptographic soundness). |
| `semantic_types` | array of strings | The abstract kinds of thing the statement ranges over. |
| `positive_examples` | array of tables | Cases that must be accepted. Each has `name` and `description`. |
| `negative_examples` | array of tables | Cases that must be rejected. Same shape. |
| `counterexamples` | array of tables | Known violation patterns a correct checker must catch. Same shape. Failed receipts and counterexamples are preserved, never deleted. |
| `required_counterexamples` | array of strings | Names of `counterexamples` that a mutant suite must kill for the invariant to count as covered. |
| `implementation_surfaces` | array of tables | Where the invariant is currently expected to hold. Fields: `repo`, `path`, `kind` (`production`, `reference`, `executable_spec`), `observed_at` (commit), `note`. |
| `observations` | array of tables | Facts read from code, kept apart from the proposed statement. Each has `surface` and `text`. Where code differs from the statement, a `divergence` entry says so. |
| `oracle_models` | array of strings | Which oracles are planned to check it (`lean` today). A name here is a plan, not a result. |
| `evidence_requirements` | array of strings | What evidence is needed besides any proof (tests, mutants, differential runs, receipts). |
| `omega_takeover_condition` | string | The condition under which Omega replaces every oracle for this invariant. Required before an oracle proof is accepted. |

## Rules

- Observed implementation and proposed invariant stay separate: `statement` is proposed, `observations` is what the code does today.
- Cryptographic correctness is an assumption unless a separate invariant covers it.
- A manifest is not evidence. It never records PASS or FAIL. Results live in the evidence machinery and cite the invariant `id`.
- Paths in `implementation_surfaces` are relative to the named repository and were checked on the commit in `observed_at`.
- No manifest may contain `--skip-proof`, `--trust-model`, or `--assume-safe` style escape hatches (ARCH-0027, RSI rule).

## Index

- `capability-attenuation-v1.toml`: AIEN.INV.CAP.ATTENUATION.V1
- `capability-revocation-v1.toml`: AIEN.INV.CAP.REVOCATION_CLOSURE.V1
- `artifact-receipt-v1.toml`: AIEN.INV.RECEIPT.REJECTION_CONSISTENCY.V1
- `sequence-stale-id-v1.toml`: AIEN.INV.SEQUENCE.STALE_ID.V1
- `kv-layout-bounds-v1.toml`: AIEN.INV.KV.LAYOUT_BOUNDS.V1
