# ADR 0022: The canonical Cortex owner is omega `rx_cortex`

**Status:** Accepted 2026-09-30. This is an engineering call made by the orchestrator under the operator's standing rule that the orchestrator decides engineering calls; it was not separately reviewed by the operator.
**Supersedes:** nothing. **Amends:** nothing.
**Related:** ARCH-0007 (J-Space effect boundary), ARCH-0015 (Resident Semantic Store), ARCH-0016 (resident reaction architecture), `doctrine/ARCHITECTURE.md` §2.8 (Concept Ownership), `doctrine/DISCOVERY.md` §16.1 (Responsibilities), `docs/plans/RUST_TO_C_MIGRATION.md` §6.

Citation note: in this repository "ADR 0022" and ARCH-0022 name the same decision. In other repositories cite it as ARCH-0022.

---

## Context

`doctrine/ARCHITECTURE.md` §2.8 listed three Cortex implementations and recorded no owner:

- aien-sovereign-core `crates/cortex-rs`: the Linux LLM-stack memory service.
- omega `src/runtime/rx_cortex.{c,h}`: the host reference in the runtime tree.
- aienos `crates/aienos-cortex`: a Rust epistemic store.

§2.8 moves a concept to an owner only through an accepted ADR or an R16 gate result. `aien-dev/omega#114` (merge `43dcb04`) gave omega `rx_cortex` an append-only journal with verified replay, a single writer, typed recall and World execution recording, and declared it canonical in code. This ADR records that ownership in the architecture.

## Decision

1. **Owner.** omega `src/runtime/rx_cortex.{c,h}` is the one canonical Cortex. It owns the Cortex contract, the single writer and the journal. Every authoritative Cortex write goes through `cx_append` or `cx_append_as` on a `CxStore`. A store has at most one writer: `cx_claim_writer` inside a process, an exclusive lock on the journal file across processes.
2. **World execution.** World execution enters Cortex only through `src/runtime/rx_cortex_record.c`. Attaching the recorder to a World claims the store as its single writer; while attached, no other code may append to that store.
3. **Non-authoritative stores are retired, not ported.** aien-sovereign-core `crates/cortex-rs` and aienos `crates/aienos-cortex` are non-authoritative. `RUST_TO_C_MIGRATION.md` §6 left both open: item 6 ("aienos host crates ... port or retire") covers `aienos-cortex`, and item 7 ("the rest of sovereign-core ... per-crate review") covers `cortex-rs`. This ADR makes that per-crate call for these two crates: retire. The path is:
   1. No new caller is added to either crate.
   2. Records worth keeping are imported into the canonical store through `cx_append_as` as `CX_K_IMPORTED` claims, with the tag naming the source (`CX_SRC_CORTEX_RS`, `CX_SRC_AIENOS_CORTEX`). They never enter as facts and never by writing a journal directly.
   3. The crates are deleted.
   Until step 3, nothing treats either crate as a source of truth.
4. **Model output is a candidate, never a fact.** Records that originate from model output enter Cortex as candidate claims (`CX_CLAIM` / `CX_K_CANDIDATE`). A candidate becomes fact only through `cx_promote`, which appends a protected `CX_K_PROMOTION` record linking the candidate to an evidence object of class `CX_EVIDENCE`.
5. **J-Space holds no memory or evidence.** Memory, evidence and provenance belong to Cortex. J-Space (`rx_jspace.h`) holds runtime state-space material only and never records them (ARCH-0007).
6. **Roles.** In the responsibilities table of `doctrine/DISCOVERY.md` §16.1, this store is the "Record" holder ("Cortex / Evidence ledger"). Proposing, defining, verifying, minting capabilities, authorizing and realizing stay with the holders named in that table. Cortex records their outputs and decides none of them.

## Limits at the time of this decision

- **Host only.** `rx_cortex` runs hosted on Linux. Native AIENOS does not run it.
- **One tier.** One in-memory tier, optionally backed by an append-only journal that is replayed and verified on reopen. The doctrine tiers L1 (accelerator memory), L2 (host memory) and L3 (NVMe) are not implemented.
- **Not in the living build.** `rx_cortex` is built into the state-projection test target and `test-cortex`. It is not in the R13 living-system build (`RX_R13_SRCS` in the omega `Makefile` does not list it). Integration into the living system is the COMPOSITION-2 work.
- **No Fabric, no remote Cortex.** There is one local store per journal. Nothing replicates it or serves it to another machine.
- **Candidate discipline is not type-enforced.** Nothing in `rx_cortex.h` identifies a writer as model output or stops a writer from appending `CX_K_CLAIM` directly. Decision 4 holds today by writer discipline and review, not by a check in the store.

## Evidence

Checked on omega `origin/main` on 2026-09-30.

- `aien-dev/omega#114` "M20 A7: canonical Cortex, World execution recording", merge `43dcb04`, an ancestor of omega `main`. ("M20" in that title means COMPOSITION-1; see `CURRENT_EXECUTION_PLAN.md`.)
- `src/runtime/rx_cortex.h`: the AUTHORITY block names this file the canonical contract, describes the single writer and the journal lock, names `cortex-rs` and `aienos-cortex` as non-authoritative, and states the three-step retire path. It defines `CX_K_CANDIDATE`, `CX_K_PROMOTION`, `CX_K_IMPORTED`, `CX_SRC_CORTEX_RS`, `CX_SRC_AIENOS_CORTEX` and `cx_promote`, and states that the L1/L2/L3 tiers are not implemented.
- `src/runtime/rx_cortex_record.h`: the World recorder; attaching it claims the store as the single writer. `rx_world.c` calls it through one optional recorder hook (`rx_world_set_recorder`).
- `src/runtime/rx_jspace.h`: "J-Space holds runtime state-space material only. Memory, evidence and provenance belong to Cortex; J-Space never records them."
- `src/runtime/rx_projection.c` already reads Cortex through `cx_get` and `cx_payload`.
- Test target: `make test-cortex` (journal, single writer, typed recall, World execution recorded through `rx_cortex_record`).

## Consequences

- `doctrine/ARCHITECTURE.md` §2.8 records omega `rx_cortex` as the Cortex owner by this ADR, in the same change.
- `cortex-rs` and `aienos-cortex` are legacy. Adding a caller to either is a violation of this ADR.
- `CURRENT_EXECUTION_PLAN.md` still describes the Cortex owner as formally unrecorded. That file is reconciled separately and is not edited here.
- Moving Cortex off the host, adding the L1/L2/L3 tiers, putting it into the living build, or exposing it over Fabric are later work. Each must keep the single-writer and candidate-to-fact rules above.
