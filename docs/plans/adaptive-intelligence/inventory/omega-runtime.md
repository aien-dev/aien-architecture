# Inventory: omega runtime cognitive loop (Milestone 0/1, read by the orchestrator)
Repo: aien-dev/omega main @ 16e729b6d844 (fresh clone 2026-10-11). Build pins: aienos.lock b84c0a67590a9 (native authority), argus.lock b375dcaa2887d (ARGUS observer). Sibling deps: ../physics (headers), ../aienos-argus, AIENOS_LOCK_REPO.

| Capability | Status | Source |
|---|---|---|
| Resident AIEN faculty: observe/predict/explain/assess/plan as World reactions | Implemented and integrated | src/runtime/rx_aien.h:1-30, enums :60-85 (PRED_FAILED, HYP_CORE_CLASS/DRIFT, ACT_RESEARCH, EXP_SUPPORTED/REFUTED) |
| Failed prediction -> hypothesis -> bounded experiment plan; memory of explored conditions (no re-plan) | Implemented and integrated | rx_aien.h "memory: explored condition keys", RX_AIEN_MEMORY_SLOTS; tests/runtime/rx_r11_aien.c steps printed by the program |
| Living system: experiment on resident GPU seat under R5 admission/R7 authority, evidence, AIEN experiment belief, generation prepare/promote, in-force record read by production | Implemented and integrated | src/runtime/rx_living.h:1-30; tests/runtime/rx_r13_living.c phases POSITIVE, NO_AIEN, NO_PROMOTION, REVOKED_EXPERIMENT, STALE_GPU, FAILED_VERIFICATION (:48) |
| Restart recovery: generation.restore re-verifies the active generation at body start; R14 scenarios A-F | Implemented and integrated | rx_living.h rx_living_register_restore; tests/runtime/rx_r14_recovery.c:1-20 |
| Canonical Cortex store (append-only, typed, provenance, promote, verify chain) | Implemented and integrated | src/runtime/rx_cortex.h:1-29 (AUTHORITY M20), API :184-289 |
| World -> Cortex recorder (every crumb becomes a Cortex object with provenance links) | Implemented but DISCONNECTED from the living body | src/runtime/rx_cortex_record.h:1-20; only attached by src/runtime/rx_compose.c; no use in rx_living.c, rx_aien.c, rx_r11/r13/r14 tests |
| Cognitive state projection (typed need -> smallest Cortex state, protected evidence never summarized) | Implemented and integrated (compose path); not fed to the living AIEN | src/runtime/rx_projection.h:1-30; Makefile OMEGA_STATE_PROJECTION part B |
| Typed resource needs, 7 priority classes, physical budget, bounded fairness, emergency stop | Implemented and integrated | rx_world.h:48-60 (RX_PRIO_*), :249 RxResourceNeed, :251-269 RxResourceBudget, :735 rx_world_set_resources, :824 rx_world_emergency_stop |
| Adaptive policy that changes priority/budget from observed conditions | Missing | no caller of rx_world_set_resources from a reaction (grep) |
| Legacy stores cortex-rs / aienos-cortex | Superseded (retire, import only as CX_K_IMPORTED) | rx_cortex.h:13-29, CX_SRC_* :111 |

## Executable path (shortest, already in main)
observation (Omega demand interval, external placement change) -> aien.observe belief -> aien.predict prediction -> miss streak -> PRED_FAILED -> aien.explain hypothesis (CORE_CLASS or DRIFT) -> aien.plan plan (ACT_RESEARCH, one per untried condition; memory blocks repeats) -> living.experiment.prepare -> living.blackwell.add (GPU seat, authority-gated) -> living.experiment.evidence -> aien experiment belief (SUPPORTED/REFUTED) -> generation.prepare candidate -> generation.promote (separate subject, native authority) -> in-force record -> production serves the new realization (changed subsequent decision). Control arms prove each link is causal (no AIEN, no promotion, revoked grant, stale GPU, failed verification).

## Baseline (fresh clone, host)
- R11 `make AIENOS_LOCK_REPO=<clone holding b84c0a6> test-r11`: checks 436 failures 0; living run exercised (A725 -> X925, new record 1.63x faster; control without AIEN stays on the old record). Receipt: baseline/20261011T142516Z-16e729b6d844/R11/rx_aien_faculty_receipt.json, R11_CONTINUOUS_COGNITION PASS.
- R13 host, R14 host: see baseline/ (filled when the runs finish).

## What survives a restart today
Durable: the R9 generation store (in-force record, candidate bytes, config, evidence, durable provenance links RxLivingProvenance) and the aienos authority table. Ephemeral: every AIEN world object (belief, prediction, hypothesis, plan, assessment, memory of explored conditions). So after a restart the body serves the promoted realization but AIEN has forgotten why, and would re-explore an already explored condition. That is the Milestone 2 gap.
- R13 host run1 (14:26Z, load 5.7, scouts+compile running): R13_LIVING_SYSTEM=FAIL, phase E "AIEN never confirmed the incumbent cost" (the header's documented wall-clock sensitivity); positive + controls A-D passed. Receipt baseline/20261011T142633Z-16e729b6d844/R13.
- R13 host run2 (14:27Z, alone): R13_LIVING_SYSTEM=HOST_PASS_NON_SILICON, generation 1->2, 16 GPU claims (stand-in), 11 durable links. Receipt baseline/20261011T142755Z-16e729b6d844/R13.
- R14 host: R14_LIVING_RECOVERY=HOST_PASS_NON_SILICON, A-F PASS. Receipt baseline/20261011T142649Z-16e729b6d844/R14.
- Silicon gates (test-r13-silicon, test-r14-silicon) need the GB10 seat: not run in this session (chip window, Drake go).
