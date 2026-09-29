# Analog Realization — Current State

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0018 (ARCH-0018, ACCEPTED, merged 641bd3c), substrate-neutral physical realization. `CURRENT_EXECUTION_PLAN.md` still owns cross-project sequencing (§6 C3, Lane 6), and `doctrine/ROADMAP.md` still owns milestone status. The AR-gates are ADR 0018 workstream gates, not M-milestones.

**Written:** 2026-09-29. Code facts come from three read-only audits of the commits below; PR states were checked live on the same date.

| Repository | Commit |
|---|---|
| omega | `main` `f308ac7` (live); file:line facts read at `8e7a445` (audit basis); `#60` merged `c0edef0`; `#68` read at `d73315e` |
| physics | `main` `5969159` (live); `#13` merged `5969159`; `#16` merged `1f7c321` |
| aienos | `main` (commit not recorded in the audits; `#161` merged); `feat/argus-0` read at `a64bc55` |
| aien-architecture | `main` `f6baa35` |

---

## 1. Live PR / commit map (2026-09-29)

| Repo | PR | Title / subject | State | Head / merge | Note |
|---|---|---|---|---|---|
| omega | #67 | R15 quantitative performance | MERGED | merge `bba3bd3` | Receipt `evidence/R15/065c688408aa18950f363b52be2357c3cb853827592dc71ea72b6da181b4569a.json`, `"outcome": "PASS"`, 16/16 gates (candidate `3e9e53be3358`, G10 amended Option A) |
| omega | #68 | R16 orchestrator retirement: spec + loop inventory | OPEN, DRAFT | head `d73315e` | W1–W4 done, W5 next; no runtime code; `evidence/R16/` does not exist on `main` |
| omega | #71 | Effect capability generations to 64 bits (cap64) | MERGED | `8e7a445` | `EffectPayload` v2, 178-byte wire form; v1 refused |
| omega | #72 | `aienos.lock` pin `4c21386` → `d39dd5b` | MERGED | `f308ac7` | Audit (earlier the same day) saw it OPEN at `ed1194f`; live state is merged. Pin is frozen for R16 W9 |
| omega | #70 | ARGUS producer (ABI v1.1) | OPEN, DRAFT | head `cf6f45d` | "Do not merge". `rx_argus.c` contains loops that would collide with R16 G2 |
| omega | #66 | M18 receipt prints measured values | OPEN, DRAFT | head `3512af3` | 17/18 on Spark; only the pre-existing Gate 16 clean-clone env failure |
| omega | #60 | Empirical cost model | MERGED | merge `c0edef0` | Merged at 2026-09-29T12:56:58Z; CPU matvec cost model landed |
| physics | #13 | FORGE-0 / FORGE-HWID (M19R Gates 3-4) | MERGED | merge `5969159` | Gates 3 and 4 pass (11/11, 10/10); FORGE v1 boundary closed |
| physics | #16 | FORGE substrate V2 | MERGED | merge `1f7c321` | Host gates 47/47 KAT + 6/6 PASS; V2 frozen digest `89cb5ba6…06c0` |
| aienos | #160 | ARGUS-0 C defensive plane | OPEN, DRAFT | head `a64bc55` | 8/10 gates; PERFORMANCE FAIL (+6.2% vs 5%) |
| aienos | #161 | Capability observer | MERGED | — | Observer hook pinned by omega#72 |
| aienos | #162 | ARGUS-1 spec + plan (I1–I5), no code | OPEN, DRAFT | head `1f5fc23` | Stacked on #160 |
| aien-architecture | #53 | ADR 0017 (ARGUS) | MERGED | `b19b4ac` | Accepted by operator Drake Stapleton |

`omega` `main` = `f308ac7`; `physics` `main` = `5969159`.

## 2. Discrepancies found

1. **Roadmap R15/R16 rows were stale.** `doctrine/ROADMAP.md` said R15 "Not qualified" and R16 "Not started". Live evidence: R15 PASS (omega#67), R16 in progress (omega#68 draft). Corrected in this change.
2. **physics#13 receipts are not digest-named.** `evidence/m19r_gate3_forge_seam_evidence.json` and `evidence/m19r_gate4_forge_hwid_evidence.json` are flat, gate-named, hand-authored (both timestamped `2026-09-27T15:30:00Z`); the live descriptor digest they record cannot be recomputed from their contents; no JSON emitter exists in `forge/`.
3. **omega#60 is merged** with `main` at 2026-09-29T12:56:58Z (`c0edef0`).
4. **omega#70 vs R16 loop collision.** `rx_argus.c` contains `for (;;)` and `while (!stop) { ... nanosleep }`; #70 also edits `rx_world.c` and `rx_generation.c`, which carry R16 map rows. If #70 merges before R16's final G2 scan, R16 G2 fails. This collision exists independently of analog work.
5. **ARGUS performance numbers disagree.** aienos#160 and the ARGUS-0 handoff report +6.2% (FAIL vs 5%); omega#70's speed2 round reports +3.87% [+3.27, +4.47] (PASS vs 5%, FAIL vs ADR 0017's 2%), not on `main`. Which bar binds is undecided, so the performance gate is treated as **not passed**.
6. **No-Python rule violations.** omega `tools/qualify_visor.py` (left by omega#69); physics `main` still has 5 `.py` files (`m2_build.py`, `run_milestone2_gates.py`, `generate_physics_audit.py`, `seam1_physics_audit.py`, `seam2_physics_harness.py`).
7. **Shared checkout moved.** The shared checkout `~/workspace/aien-architecture` was switched from `feat/resident-semantic-store-boundary` to `main` during this session; its working tree was clean at the time. This work was done in an isolated worktree.

## 3. What exists for analog realization today

Nothing physical. No analog, neuromorphic, FPGA or photonic code exists on any `main`. The substrate-neutral pieces already present, and the seams that must change later, are listed in ADR 0018 §11 ("Current code facts").
