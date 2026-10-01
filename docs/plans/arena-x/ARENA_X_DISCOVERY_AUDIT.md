# ARENA-X discovery audit

> **NOT A MASTER PLAN. Design notes only.** This is a read-only audit of what already exists that ARENA-X
> could reuse, what is missing, and where leaks could happen. Nothing here authorizes code or runtime work.

ARENA-X has two data worlds: an arithmetic world (integers with structure observations) and a geometric
world (lattice counts). The audit read code first and used docs only for navigation. Nothing was built or run.
Where a doc disagrees with code, code wins and the doc is marked stale.

## 1. Headline finding

**The scorekeeper exists, the player does not.** Omega can score a hypothesis fairly (sealed data, frozen
evaluators, description-length gain, receipts, failure records). It has no general discoverer: no program that
proposes hypotheses from data, checks them on held-out data inside its own loop, and picks among them by
description length. The two real searches are narrow enumerations over a five-operation, one-input,
one-output, unsigned 64-bit vocabulary that stop at the first exact fit.

**Any gate that needs a discoverer is blocked until one is built.** Scoring a discoverer that does not exist
would only produce records about fixtures. The existing scoring of search runs (TY-2) measures how predictable
the search process is, not what was discovered.

## 2. Current HEADs

| repo | origin/main sha | date | subject or note |
|---|---|---|---|
| omega | b608dff6159903a371ff0f83ee95daa301b5110a | 2026-09-30 | merge of PR #104, docs only |
| aien-architecture | f2cf579d083 | 2026-09-30 | merge PR #65 (belief-estimation ADR 0020) |
| aien-sovereign-core | 0df7c321c150 | 2026-09-29 | operator authentication before cockpit controls (#132) |
| aien-protocols | 7ac6facb630c | 2026-09-23 | versioning policy, changelog, consumer pins (#7) |
| benchmarks | 959dedd24c03 | 2026-09-23 | merge PR #12 |
| cortex-rs (standalone) | 0606636f110d | 2026-09-23 | archival pointer to canonical home |

Notes: `src/estimation` and `tests/estimation` do not exist on omega main. The forgejo remote errored on every
repo except aien-architecture; shas are from the GitHub remote. Standalone cortex-rs is archived; the canonical
copy is `aien-sovereign-core/crates/cortex-rs`. The benchmarks repo is performance-only and holds Python helpers.

## 3. Reusable components

Legend: IMPLEMENTED, PARTIAL, PLANNED, MISSING. Paths are omega paths unless a repo is named.

| Component | Status | Evidence (file : function) |
|---|---|---|
| Enumerative synthesizer | PARTIAL (narrow) | `src/omega_synthesis.c : omega_synthesize`; 15-row op bank, depth 1 to 2, equivalence pruning, first exact fit wins |
| Crumbline search | PARTIAL (narrow) | `src/crumbline/cl_search.c : cl_search_run`; ambiguity scan, external one-bit oracle, robust fallback; unsupported unless 1 input and 1 output |
| Learner process | IMPLEMENTED | `tools/crumbline_learner.c`; links no generator or label |
| Task definition | PARTIAL | `src/omega_program.c : omega_task_evaluate_candidate`; exact match on listed pairs, no held-out split in the struct |
| Library learning | PARTIAL | `src/omega_discovery.c : omega_discover_abstractions`; works on machine-code bytes, not on hypotheses about data; `src/omega_library.c : omega_library_insert` |
| Table model code + scoring | IMPLEMENTED | `src/turing/ty_model.c : ty_model_encode, ty_model_score`; small symbol tables only |
| Discrete description length | IMPLEMENTED | `src/turing/ty_math.c : ty_dl, ty_gain, ty_ubits_ratio`; integer micro-bits, overflow-checked |
| Continuous scoring | PARTIAL | `src/turing/ty_qcont.c : ty_qcont_bits`; one family only, no model-length path |
| Prediction records | IMPLEMENTED | `src/turing/ty_prd.c : ty_prd_validate`; `tc_pstream.c`; Brownian binariser `tools/brownian/brw_tps_adapter.c` |
| Evidence records and digests | IMPLEMENTED | `src/turing/ty_record.c`, `ty_qrecord.c`, `field.c`; `src/omega_canonical.c`, `src/sha256.c` |
| Split manifest | IMPLEMENTED | `ty_record.c` (ysplit record); `calibration/scripts/make_dataset_manifest.sh` |
| Measurement profiles | IMPLEMENTED | `calibration/profiles/Turing-profile-v1.1.toml` + `.sha256`; `src/turing/ty_profile.c` |
| Sealing, freeze, blinding | IMPLEMENTED (shell, kernel namespaces) | `calibration/docs/BLINDING_PROTOCOL.md`; `freeze_candidate.sh`, `generate_sealed_data.sh`, `candidate_env.sh`, `evaluator_env.sh`, `verify_holdout_separation.sh`; EXP-001 FAIL and EXP-001R PASS both reached terminal receipts |
| Failure and void records | IMPLEMENTED | `calibration/docs/FAILURE_REPORTING.md`; `record_void.sh`; void receipt schema |
| T gain | IMPLEMENTED | `ty_math.c : ty_gain`; `tools/turing_yield.c` |
| Energy metering | PARTIAL | `src/turing/ty_energy.c` (conserving attribution); a computed T-per-joule record type was not found |
| Selectors, replay | PARTIAL | `history_selector.c`, `field_select.c`, `replay.c`; matvec realization specs only; no replay of a discovery run |
| Runtime promotion | IMPLEMENTED (runtime only) | `src/runtime/rx_generation.h`; no promotion of a hypothesis by held-out description length |
| Receipt shape | IMPLEMENTED (Rust, legacy) | `aien-protocols/crates/aien-evaluation-protocol/src/lib.rs`: EvaluationPlan, EvaluationReceipt, frozen-plan invariant |
| Sealed side + ledger + ladder | IMPLEMENTED (Rust, legacy) | `aien-sovereign-core/crates/crumbs/src/{sealed,ledger,promotion,digest}.rs`; no description-length scoring |
| Memory candidates + promotion | IMPLEMENTED (Rust, legacy) | `aien-sovereign-core/crates/cortex-rs/src/{promotion,db,models}.rs`; thresholds are hand-set confidence numbers; disputed and invalidated states are never written |
| Gate receipt pattern | IMPLEMENTED (Rust, legacy) | `aien-sovereign-core/crates/aien-proof/src/evidence.rs`, `gate.rs` |
| J-Space, relational paths | MISSING / PLANNED | `docs/06-jspace.md`, `docs/10-relational-path-engine.md`; no canonical code |

Rust items are design references only. The no-Rust rule means any port targets C.

Stale doc: the TURING current-state row saying program realize is undefined is wrong. It is defined in
`src/omega_program.c : omega_program_realize`.

## 4. Missing primitives

1. **Discoverer.** A proposer that builds hypotheses from a grammar plus observations, evaluates on held-out
   data inside the loop, and selects by description length. Nothing like it exists (no evolutionary, stochastic
   or description-length-guided search anywhere in source).
2. **Exact big-integer and rational arithmetic.** Today: u64 wrap-around plus a u128 accumulator. No
   arbitrary precision, no rational type, no gcd. Both worlds need exact counts and exact ratios.
3. **Multi-input, multi-output expressions.** Omega program bodies are ordered chains of unary steps. There are
   no multivariate expressions, sums or loops over data, and no predicates as first-class hypotheses. Some
   opcodes (DIV, EQUAL, LESS_THAN, NOT) exist in the enum but no vocabulary uses them.
4. **Program-shaped model cost.** Profile v1.1 forbids programs as models and defers a continuous model length.
   A new measurement profile id is required (the profile rule forbids redefining an existing one). It must fix
   the model-length rule, the free background list, baseline and margin, and pass the digest-refusal checks.
5. **Commit-then-reveal for answers.** Freeze manifests hash artifacts before sealed data exist, but there is
   no salted commitment and no reveal record type for predictions or answers.
6. **T per joule as code.** The definition exists as text; the metering exists; the computed record does not.
7. **Held-out scoring for structure claims.** Scoring covers symbol tables and one continuous family. A
   claim about structure in integers, or a lattice-count law, has no scoring path.

## 5. Leakage channels

The audited repos hold no benchmark content. The risks are indirect.

1. **Names are a channel.** Any file name, gate token, receipt field, branch name, PR title or doc heading that
   names the target is itself a leak to any system with repo access, including an evaluated discoverer or an
   outside AI reviewer. Recommendation: use neutral codenames for everything a discovery run could index
   (gate tokens, dataset ids, family ids, spec file names). Keep the mapping from codename to meaning in
   evaluator-private notes. **Drake decides.**
2. **Answer-bearing evaluator notes.** Notes that state what the data is built to contain should live in a
   private location like the Brownian sealed repo, never in a public repo and never pasted into an AI tool
   before the sealed run ends. Where they live is **Drake's decision.**
3. **Public number-system docs to fence** (hardware-realization math, but visible to anything with repo access):
   - `docs/plans/mixed-algebra/MIXED_ALGEBRA_THEORY.md`, `PRIOR_ART.md`, `MIXED_ALGEBRA_CURRENT_STATE.md`
   - `docs/adr/0019-mixed-algebra-realization.md`
   - omega: `spec/mixed-algebra-phase-twin.md`, `src/algebra/realize_rns.c`, `src/algebra/realize_common.h`,
     `src/algebra/phase_twin.h`, `tests/algebra/test_phase_twin.c`, `tests/algebra/ma_digital_v1_gate.c`
   - omega: `tests/turing/qcont_kat_gen.c` (defines a numeric constant to 36 digits)
   - `docs/turing/protocols/turing-instrument-calibration-validation-protocol-v1-0.tex` was not read line by
     line; recheck before any ARENA-X spec is published.
4. **Crumb conformance vectors.** `tests/crumbline/vectors/v001..v009.crb` are concrete function-fitting
   examples and were not read in detail. Check them before ARENA-X reuses the format.
5. **Burned data.** `calibration/scripts/burned_seeds_exp001.txt` lists seeds already seen; burned development
   data lives outside the repo. Any ARENA-X seed list must refuse these.
6. **Incidental words** (ring-buffer wrap, UI names in sovereign-core) are harmless but should be screened by
   grep before any dataset or spec is indexed by a discovery run.

Existing separation to copy: candidate and evaluator run in separate environments (BLINDING_PROTOCOL.md);
sealed data does not exist until the freeze commit does, with seeds derived from that commit hash; the learner
oracle returns one verdict byte and never labels or counterexamples; Brownian publishes a digest commitment
(`docs/brownian/PROFILE_COMMITMENT.txt`) before the run and the evaluator files after it; one attempt per
profile, no goalpost moves, a departures log.

## 6. Proposed file ownership

| Area | Owner | Contents |
|---|---|---|
| Public docs (aien-architecture, `docs/plans/arena-x/`) | docs | this audit, contracts, receipt formats, gate definitions under neutral codenames |
| Public C tools (omega, offline, CPU-only, outside `src/runtime/`) | C tools | exact arithmetic, discoverer, program-cost scorer, commit-then-reveal record, T-per-joule record, dataset manifest |
| Public profiles | docs + C tools | new profile toml with `.sha256` sidecar |
| Evaluator-private (Brownian-sealed-style private repo) | evaluator | codename map, family definitions, data generators, answer keys, sealed seeds, evaluator notes |

Rule: nothing the discoverer can read may explain what the sealed data was built to contain.
Language rules: C plus shell, no Rust, no Python, no systemd. **[Language rule superseded 2026-10-01 by [ADR 0024](../../adr/0024-rust-scaffolding-omega-destination.md): Rust is scaffolding, Omega is the destination, C only where hardware-justified. No Python and no systemd still hold.]**

## 7. Dependency graph

```
 [discoverer]   [exact arithmetic]   [program-cost profile id]
        \              |                   /
         +-------------+------------------+
                       |
                 [dataset seal]  <-- neutral codenames, private evaluator repo
                       |
                 [baselines]  (table models, trivial programs; frozen before any run)
                       |
      [gate 1] -> [gate 2] -> [gate 3] ... (in order, one attempt per profile)
                       |
                 [unification]  (arithmetic world and geometric world under one scorer)
                       |
                 [active selection]  (choosing what to observe next)
```

Holds: R16 is not closed, and the hold on `src/runtime/` stands. Evolution Arena spec section 0.1 allows
documents only until its prerequisites clear, and ADR 0020 (EST-4 onward) waits for R16. An offline,
CPU-only, docs-plus-C-tool program outside `src/runtime/` looks compatible. **No live Cortex promotion is
possible before R16**, and no runtime loop may consume ARENA-X output.

## 8. Suggested first milestones (small, falsifiable)

1. **Codename and fence decision.** Drake picks codename policy and evaluator-private location. Falsifiable:
   a grep of the public repos for the private codename map returns nothing.
2. **Exact arithmetic library in C.** Big integer and rational with known-answer tests against hand-computed
   values. Falsifiable: all vectors match; overflow and divide-by-zero refuse rather than wrap.
3. **Profile draft with a new id.** Program-shaped model length, free background, baseline, margin, digest
   sidecar. Falsifiable: the tools refuse a one-byte edit; an existing profile is untouched.
4. **Trivial discoverer baseline.** Extend the enumerative search to two inputs and held-out scoring by
   description length inside the loop, on synthetic fixtures with no target content. Falsifiable: it recovers
   a planted small program on fixtures and reports no gain on pure noise.
5. **Commit-then-reveal record.** Salted commitment, reveal record, verifier. Falsifiable: a changed answer
   after commitment fails verification.
6. **Dry-run seal on neutral fixtures.** Run the freeze and blinding scripts end to end on toy data, one
   attempt, void path exercised. Falsifiable: the auditor re-derives seeds and hashes with no mismatch.
7. **T-per-joule record.** Computed record from existing metering. Falsifiable: attribution conserves energy
   on a replayed interval.
