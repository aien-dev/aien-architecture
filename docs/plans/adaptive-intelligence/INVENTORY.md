# AIEN Adaptive Intelligence: Milestone 0 inventory (2026-10-11)
Orchestrator: Claude (Fable 5.1) session 65ed29. Fresh clones of GitHub default branches under ~/workspace/adaptive/ (PINS.txt). Detail per area in inventory/*.md with file:line evidence.

## Pinned sources
omega 16e729b6d844 | spark-rsi 24f412f699f1 | aien-protocols 407487b7e163 | interplane 667fbe811f78 | spark-inquisitor 230d257199b7 (ARCHIVED) | benchmarks 8d4dfde8f944 | physics 8b23e5a2352e | aien-sealed 3a6659dc63b2 | aienos 3b2004b692a7 | aegis-runtime 1eba7a7223ba | aien-sovereign-core 00e7ef05302c | cortex-rs 0606636f110d (ARCHIVED)
Also ARCHIVED on GitHub: spark-supervisor, spark-hive, spark-dream, spark-crumbs, spark-adapters, aien-harness. Not modified; nothing live depends on them (evidence-chain.md, spark-rsi.md).

## Classification
| # | Capability | Repo | Status | Evidence |
|---|---|---|---|---|
| 1 | Resident cognition loop observe/predict/explain/assess/plan, failed prediction -> hypothesis -> bounded experiment plan, explored-condition memory | omega src/runtime | Implemented and integrated; R11 PASS 436/0 | inventory/omega-runtime.md |
| 2 | Living system: GPU experiment under authority, evidence, belief update, promotion, changed production decision; 5 control arms | omega | Implemented and integrated; R13 host run1 FAIL phase E under load 5.7 (preserved), run2 HOST_PASS_NON_SILICON all phases | baseline/ |
| 3 | Restart/attack recovery A-F incl. crash in promotion and restore | omega | Implemented and integrated; R14 HOST_PASS_NON_SILICON 6/6 | baseline/ |
| 4 | Canonical Cortex CxStore (append, recall, provenance, promote, verify chain) | omega | Implemented and integrated | rx_cortex.h |
| 5 | World -> Cortex recorder (every crumb -> typed record with provenance) | omega | Implemented but DISCONNECTED from the living body (only compose path) | rx_cortex_record.h; grep |
| 6 | Cognitive state projection from Cortex | omega | Implemented (compose path); not fed to living AIEN | rx_projection.h |
| 7 | Typed resource needs, priority classes, budget, fairness, emergency stop | omega | Implemented and integrated; no adaptive policy caller | rx_world.h |
| 8 | Physics-0 world, guard (truth hidden from learner), learner (sparse polynomial, MDL), ladder, scorer, PD-0b sealed run (seal-1 FAIL at level 6) | omega/physics0, physics | Implemented and integrated | inventory/physics-learning.md |
| 9 | Latent-state recovery; multi-step consistency in ranking; changed dynamics between episodes; fixed-vs-updating comparison | omega/physics0 | Missing | LEARNER.md:106-136 |
| 10 | Brownian sealed lifecycle (freeze, one-attempt ledger, sealed parent, leak oracle) | aien-sealed | Implemented; EXP-003-CERT w2.v1 frozen on paper, no sealed world yet | brownian/ |
| 11 | RSI daemon cycle, judge, holdouts, signed exact-artifact promotion | spark-rsi | Implemented and integrated | inventory/spark-rsi.md |
| 12 | RSI capability graph measurements | spark-rsi | Implemented but disconnected: all literals (daemon.rs:66-99) | |
| 13 | Production canary admission | spark-rsi | Implemented, fed `&[]` (daemon.rs:446): fails closed by design | |
| 14 | Authenticated measured execution feed for RSI | any | Missing (archived supervisor not vendored) | |
| 15 | Evaluation receipt types + P-256 signing | aien-protocols | Implemented but disconnected (only archived inquisitor + spark-rsi use) | inventory/evidence-chain.md |
| 16 | TRN1 execution transcript (spec, C verifier, corpus) | aien-protocols | Implemented but disconnected: "not yet produced by any runtime"; unsigned | |
| 17 | Judge receipt verification (rsi-eval/2), conformance corpus + negative controls V1-V8 | interplane | Implemented and integrated | |
| 18 | AIEN adapter evidence export | interplane | Implemented, unsigned (same-user forgeable per its docs) | |
| 19 | spark-inquisitor evaluators | spark-inquisitor | Superseded (sovereign-core dropped them; archived) | |
| 20 | benchmarks main harness | benchmarks | Experimental: cannot build from a fresh clone (missing sibling canonical-branch-native-runtime) | |
| 21 | Unified receipt format; longitudinal history store; independent audit chain | benchmarks/protocols/interplane | Missing | |
| 22 | cortex-rs service on :18080 and all agent memory callers | sovereign-core | Superseded by doctrine (rx_cortex.h), still LIVE in practice; no import path into CxStore | inventory/authority-and-cortex.md |
| 23 | aegis-runtime ExecutionAuthority/RunBudget/EmergencyStop | aegis-runtime | Types only, nothing enforces them; real enforcement = skill allowlist + probe gate | |
| 24 | Experiment authority entry: RunComposeTask -> compose run (AEGIS verify, World commit, Cortex journal) -> approval desk for effects | sovereign-core | Implemented and integrated | control.rs:89 |
| 25 | Typed resource-condition state (latency, contention, memory pressure, deadline risk) | omega/sovereign-core | Missing as one typed state; raw pieces exist | |

## Ownership freeze (Gate 0)
- Cortex: omega CxStore is the only writer path. No new caller of cortex-rs or aienos-cortex. Legacy records enter only as CX_K_IMPORTED.
- Omega runtime (Agent A): src/runtime/rx_living.c, rx_aien.c, rx_cortex_record.c + tests/runtime. Physics (Agent B): src/physics0, tests/physics0, new learner VERSION (seal-1 trees frozen). Shared Makefile edits: orchestrator only, serial.
- Agent F owner change: spark-inquisitor is archived and superseded; negative/tamper tests belong in interplane conformance + aien-protocols verifiers (Agent D). Recorded as a directive discrepancy, no decision needed.
- aegis-runtime is not an enforcement point today; bounded experiments go through sovereign-core RunComposeTask + omega World authority (aienos cap table).

## Prioritized gap list
G1 (M2) Attach the existing World->Cortex recorder to the living body so every observe/predict/explain/plan/experiment/evidence/promotion crumb is journaled with provenance; recall + projection on restart; candidate lesson = CX_K_CANDIDATE, promotion only via cx_promote with evidence digest. Smallest missing component; all pieces exist.
G2 (M1) R13 host phase E under load: rerun idle, record both. Then M1 trace doc from receipts.
G3 (M3) New learner version: 20-step rollout error on SELECT episodes in ranking + hidden-state flag; regime-switch between episodes; fixed-vs-updating arms. Never touches seal-1 holdouts.
G4 (M4) One typed resource-condition object + a bounded policy reaction that only calls existing budget/priority setters within granted caps.
G5 (M6/M7) Unify on aien-protocols receipt + TRN1 transcript, signed; have omega/sovereign-core produce TRN1; benchmarks harness buildable from clone; history store.
G6 (M5) Measured execution feed: candidate source = sovereign-core executor emitting CanaryObservation with signed source identity; until then fail-closed stays (documented blocker).
