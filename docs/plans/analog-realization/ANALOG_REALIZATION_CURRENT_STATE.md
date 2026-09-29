# Analog Realization - Current State

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0018 (ARCH-0018, ACCEPTED, merged 641bd3c), substrate-neutral physical realization. `CURRENT_EXECUTION_PLAN.md` still owns cross-project sequencing (§6 C3, Lane 6), and `doctrine/ROADMAP.md` still owns milestone status. The AR-gates are ADR 0018 workstream gates, not M-milestones.

**Written:** 2026-09-29. Code facts come from three read-only audits of the commits below; PR states were checked live on the same date.

| Repository | Commit |
|---|---|
| omega | `main` `e5159fa` (live); file:line facts read at `8e7a445` (audit basis); `#60` merged `c0edef0`; `#70` merged `e853a11`; `#66` merged `6bebdbd`; `#68` read at `d73315e` |
| physics | `main` `f63a6ef` (live); `#13` merged `5969159`; `#16` merged `1f7c321`; `#17` merged `fa48b7d` |
| aienos | `main` `6e2cd3d` (`#160` and `#161` merged); `#162` closed |
| aien-architecture | `main` `91c0f65` (`#53`, `#54`, `#55` merged) |

---

## 1. Live PR / commit map (2026-09-29)

| Repo | PR | Title / subject | State | Head / merge | Note |
|---|---|---|---|---|---|
| omega | #67 | R15 quantitative performance | MERGED | merge `bba3bd3` | Receipt `evidence/R15/065c688408aa18950f363b52be2357c3cb853827592dc71ea72b6da181b4569a.json`, `"outcome": "PASS"`, 16/16 gates (candidate `3e9e53be3358`, G10 amended Option A) |
| omega | #68 | R16 orchestrator retirement: spec + loop inventory | OPEN, DRAFT | head `d73315e` | W1-W4 done, W5 next; no runtime code; primary active gate |
| omega | #71 | Effect capability generations to 64 bits (cap64) | MERGED | `8e7a445` | `EffectPayload` v2, 178-byte wire form; v1 refused |
| omega | #72 | `aienos.lock` pin `4c21386` -> `d39dd5b` | MERGED | `f308ac7` | Merged; pin frozen for R16 W9 |
| omega | #70 | ARGUS producer (ABI v1.1) | MERGED | merge `e853a11` | Runtime ARGUS producer v1.1 landed |
| omega | #66 | M18 receipt prints measured values | MERGED | merge `6bebdbd` | 17/18 on Spark; prints measured values |
| omega | #60 | Empirical cost model | MERGED | merge `c0edef0` | Merged at 2026-09-29T12:56:58Z; CPU matvec cost model landed |
| omega | #76 | OSC-0/OSC-0B code audit and proposed machine semantics freeze | OPEN, DRAFT | head `5c4b707` | Open draft; code audit and semantics freeze proposal |
| omega | #32 | Blackwell FP32 SIMT instructions and OMEGA-NUMERIC-0 substrate | OPEN | head `25a0c5f` | Open PR |
| physics | #13 | FORGE-0 / FORGE-HWID (M19R Gates 3-4) | MERGED | merge `5969159` | Gates 3 and 4 pass (11/11, 10/10); FORGE v1 boundary closed |
| physics | #16 | FORGE substrate V2 | MERGED | merge `1f7c321` | Host gates 47/47 KAT + 6/6 PASS; V2 frozen digest `89cb5ba6…06c0` |
| physics | #17 | Normalize Gate 3 and Gate 4 receipts to digest-named files | MERGED | merge `fa48b7d` | Canonical digest-named receipts in `evidence/M19R/` (`a39269e8...`, `b81da4e2...`) |
| aienos | #160 | ARGUS-0 C defensive plane | MERGED | merge `6e2cd3d` | ARGUS-0 substrate complete under documented limits (ADR 0017) |
| aienos | #161 | Capability observer | MERGED | `d39dd5b` | Observer hook pinned by omega#72 |
| aienos | #162 | ARGUS-1 spec + plan (I1-I5), no code | CLOSED | head `246fc64` | Closed without merge; spec pre-registered in ADR 0017 §17 |
| aien-architecture | #53 | ADR 0017 (ARGUS) | MERGED | `b19b4ac` | Accepted by operator Drake Stapleton |
| aien-architecture | #54 | Record AR1 pass and FORGE seam closure | MERGED | `d86c3d8` | AR1 closed |
| aien-architecture | #55 | Governance synchronization | MERGED | `91c0f65` | Reconciled roadmap, architecture doctrine, ADR index, arena spec |

`omega` `main` = `e5159fa`; `physics` `main` = `f63a6ef`; `aienos` `main` = `6e2cd3d`; `aien-architecture` `main` = `91c0f65`.

## 2. Discrepancies found

1. **Roadmap R15/R16 rows were stale.** `doctrine/ROADMAP.md` said R15 "Not qualified" and R16 "Not started". Live evidence: R15 PASS (omega#67), R16 in progress (omega#68 draft). Corrected.
2. **physics#13 receipts normalized to digest names.** Historically flat, gate-named receipts in physics#13 were resolved by physics#17 (`fa48b7d`). Canonical digest-named receipts now live under `evidence/M19R/` (`a39269e80dce563be52a5daf6d73d37826e4ee995195af4a8ed064999598d79e.json` and `b81da4e265f5c0770d796423f65a0267d1748eda26bfdcb9a0c1a62493526062.json`), with compatibility symlinks preserved.
3. **omega#60 is merged.** Landed on `main` at 2026-09-29T12:56:58Z (`c0edef0`).
4. **omega#70 landed.** The ARGUS producer v1.1 PR merged (`e853a11`). Omega R16 (#68) remains the primary active gate.
5. **ARGUS performance gate ratified.** During the earlier audit, aienos#160 and handoff documents showed +6.2% on unpinned cores while omega#70 reported +3.87% [3.27, 4.47] with dedicated consumer pinning (`RX_ARGUS_CONSUMER_CPU`). Under accepted ADR 0017 (§5, §7.4, §13), ARGUS-0 is formally complete under documented limits and treats performance as passing with the documented pinning condition. The ratified ADR decision supersedes the pre-ratification audit disagreement.
6. **No-Python rule violations.** omega `tools/qualify_visor.py` (left by omega#69); physics `main` still has 5 `.py` files (`m2_build.py`, `run_milestone2_gates.py`, `generate_physics_audit.py`, `seam1_physics_audit.py`, `seam2_physics_harness.py`).
7. **Shared checkout moved.** The shared checkout `~/workspace/aien-architecture` was switched from `feat/resident-semantic-store-boundary` to `main` during this session; its working tree was clean at the time. This work was done in an isolated worktree.

## 3. What exists for analog realization today

Nothing physical. No analog, neuromorphic, FPGA or photonic code exists on any `main`. The substrate-neutral pieces already present, and the seams that must change later, are listed in ADR 0018 §11 ("Audit basis at ADR drafting time").
