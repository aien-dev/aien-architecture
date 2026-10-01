# DIRAC-0 Current State

**NOT A MASTER PLAN.** `CURRENT_EXECUTION_PLAN.md` owns sequencing and `doctrine/ROADMAP.md` owns milestone status. DIRAC-0 is a downstream consumer of existing workstreams, not a milestone.

**Status:** PROPOSED. Written 2026-10-01. Decision record: `docs/adr/0023-dirac-0-program.md` (PROPOSED). Specification: `docs/plans/dirac/DIRAC-0-SPEC.md`.
**Snapshots:** omega `origin/main` `07004a8`, aien-architecture `origin/main` `921797b`, physics `origin/main` `006e426`.

## What exists

- The operator brief of 2026-10-01 and, with this change, the draft spec, ADR and this page. All documents only.
- Pieces DIRAC-0 will consume: E1 scalar numerics (omega `#124`, `#127`, `#134`, `#147`, `#152`, the last being GB10 DIV/SQRT, merged); OSC-2 items 1 to 4 (omega `#148` to `#151`); TURING yield profile and T unit; the G3 sealed-holdout commitment format (omega `#122`, signing with test keys `#130`); FORGE SUBSTRATE V2 evidence record (physics `#16`).

## What is blocked or missing

- No complex type in Omega. M20 (`aien-dev/omega#136`, draft, not qualified) has F32, F16 and BF16 only.
- No GB10 tensor realization. D1B cannot start.
- ESTIMATION v4 (`aien-dev/omega#153`) has no verdict: attempt 2 was voided at `f5a3036` and attempt 3 is pending.
- G3 sealing is BLOCKED_OPERATOR, so no real sealed dataset can exist yet.
- No Physics Zero loop document and no T/J (TURING H5). D2 cannot start.
- No oracle exists. omega `research/dirac-oracle/` is created by PR D-02.

## Gates

`DIRAC_PREP_FROZEN`, `DIRAC_D0_ALGEBRA_PASS`, `DIRAC_CPU_REALIZATION_PASS`, `DIRAC_D1_REALIZATION_PASS`, `DIRAC_D2_DISCOVERY_PASS`: all NOT_RUN. No receipt exists under `evidence/DIRAC-0/`.

## Next action

Operator review of the spec (D-01). On acceptance, D-02 (independent oracle and known-answer corpus, evaluator side only). No production runtime is touched until OSC-2 and E1 interfaces settle.

## C2S reframing (2026-10-01)
The AIEN-facing ladder is now D-1 to D3 (spec section 17). D-1 waits on the Atlas C2S adequacy lab (Lane 36). D3 waits on a frozen theory and sealed novel-consequence data. All NOT_RUN.
