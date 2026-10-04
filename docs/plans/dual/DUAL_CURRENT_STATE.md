# DUAL Constraint Pricing - Current State and Slices

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0031 (ARCH-0031), DUAL constraint pricing. `CURRENT_EXECUTION_PLAN.md` owns sequencing (Lane 8) and `doctrine/ROADMAP.md` owns milestone status. Nothing in this document is a milestone.

**Written:** 2026-10-03, before any DUAL code existed. Facts come from read-only audits of the commits below; code was read, README and spec claims were not taken as evidence, and every claim used by ADR 0031 was re-checked by hand against the cited lines.

**Updated:** 2026-10-04. Sections 1 to 5 describe the state before any DUAL code existed and are kept as the audit record. Section 6 records what has since landed on `main` and supersedes section 1 where they differ.

| Repository | Commit (GitHub `main`) |
|---|---|
| aien-dev/aien-architecture | `b31d6f7` |
| aien-dev/omega | `6d85a16` |
| aien-dev/aien-sovereign-core | `5fdab70` |
| aien-dev/spark-rsi | `f5f1ca2` |

Status words: IMPLEMENTED, PARTIAL, PLANNED, MISSING.

## 1. Headline

- No shadow price, dual variable or scarcity estimate exists in any of the four repositories (case-insensitive grep for `shadow price`, `lagrang`, `scarcity`, `budget pressure`: zero hits). In omega, `lambda` appears only as the cost model's ridge prior precision (`RxCostModel.lambda`).
- Every place that encodes scarcity today encodes it as a constant: J-Space residency pressure, scheduler limits, RSI bottleneck weights.
- The hard-before-soft and Pareto-before-ranking discipline DUAL needs already exists in omega's capability query and in the Arena spec. DUAL must reuse it, not shadow it.
- ESTIMATION is not ready to feed production prices: EST-3 is FAILED on `main` (v1 `aien-dev/omega#105`, v2 `#118`, v3 `#129`); v4 INCONCLUSIVE (`#153`); v5 `#170` is open and interim. EST-4 onward is blocked.

## 2. Concept inventory

| Concept | Status | Where | Note |
|---|---|---|---|
| Pareto filtering before ordering | IMPLEMENTED (one site) | omega `src/runtime/rx_capq.c` `cq_rank`, `dominates()`; spec `spec/capability-query-ir.md` | hard admit chain in `cq_query_admit` (filter loop at `rx_capq.c:625-645`: liveness, types, effects, authority ceiling, latency, energy, reliability, evidence, max cost, min confidence) runs first; then the front; then a lexicographic caller order with `CqTradeoffs.tolerance_ppm` bands. No weighted sum. Natural DUAL hook: after the front, before the order loop |
| Ranked alternatives for routing | IMPLEMENTED | omega `rx_skillroute.h` `sr_route_alternatives` | reuses the `rx_capq` order |
| Cognitive routing | IMPLEMENTED, not Pareto | omega `spec/cognitive-routing.md` | feasibility, then least expected energy (time if energy unmetered); unsatisfiable requirement refused |
| Empirical optimizer | IMPLEMENTED, scalar | omega `rx_costmodel.c` `rx_cm_decide` | best `mean_log2_ps` among arms whose upper bound meets the budgets; if none, best overall flagged `RX_CM_WHY_OVER_BUDGET` (budgets act soft here, hard in `cq_query_admit`) |
| Cost model fields | IMPLEMENTED | omega `src/runtime/rx_costmodel.h` | `RxCmPrediction` (`mean_log2_ps`, `sd_log2`, `dof`, `energy_pj`, `fail_p`); `RxCostModel` (`power_mw`, `verify_ns`, `synth_ns`, `code_bytes`, `sd_scale` from `rx_cm_calibrate`); `RxCmFeatures` (`latency_budget_ps`, `energy_budget_pj`, `pressure` bucket) |
| Capability-query cost fields | IMPLEMENTED (advertised or estimated) | omega `rx_capq.h` `CqEntry` / `CqCandidate` | cost (abstract units), latency (us), energy (uJ), confidence and reliability (ppm), evidence level |
| KV capacity or bandwidth budget fields | MISSING | omega | `JS_REAL_KV_STATE` is a realization type only |
| Price-like quantity | PARTIAL (hand-set) | omega `rx_jspace.c` `choose()` and `enforce_u` | keeps bytes resident if best action cost `>= pressure * retain_ns_per_byte`; pressure is `1e9` when total residency is over budget (a CAPACITY case, stays hard) and `1e3` when only the hot arena is over half the budget (soft). The `1e3` case is the first candidate for a DUAL-supplied price |
| J-Space hard limits | IMPLEMENTED | omega `rx_jspace.h` `JsLimits` | `max_resident_bytes`, `max_spill_bytes`, etc. return `JS_ERR_FULL`: `CAPACITY` class |
| Typed result contracts | IMPLEMENTED, orthogonal to cost | omega `src/runtime/rx_contract.h` (`rc_*`, `RC_E_BUDGET`) | hard gates; `INVARIANT` class |
| Estimation records | IMPLEMENTED (standalone), not qualified | omega `src/estimation/est_types.h` (`est_observation`, `est_belief` with `evidence_root`, `est_prediction`, `est_innovation`) | DUAL inputs must reference these records |
| Serving scheduler | IMPLEMENTED (legacy scaffolding, class E) | aien-sovereign-core `crates/aien-scheduler/src/lib.rs` `AienScheduler`, `SchedulerConfig` | defaults `max_batch_size` 64, `max_batch_tokens` 4096, `max_prefill_tokens` 2048, `prefill_chunk_size` 512, `watermark_blocks` 4 (daemon overrides 256 / 16384 / 8192 / 128 / 64); watermark preemption evicts the lowest `Priority`, recompute not swap; admission FIFO, preempted queue first |
| Scheduler metrics | PARTIAL | `SchedulerMetrics` (`lib.rs:55`), `StepMetrics` (aien-abi-core) | running-mean step latency only; no p50/p95/p99; no energy in the scheduler (bench reads power separately) |
| Scheduler observer hook | MISSING | | the considered alternatives (preemption candidates, admission shortfall, budget clamps) are locals inside `build_scheduled_batch`; a read-only tap must expose them |
| RSI hard / soft split | IMPLEMENTED | spark-rsi `src/evaluator/layers/mod.rs` `LayerResult.is_hard_invariant`; `src/evaluator/mod.rs` | hard: correctness, security, style, longitudinal replay; soft: performance, resource efficiency; `admitted = hard && statistical` |
| RSI soft budgets | IMPLEMENTED, fixed thresholds | spark-rsi `src/isolation/manifest.rs` `regression_budgets` | p95/p99 degradation 1.0%, RSS growth 2.0% |
| RSI bottleneck ranking | PARTIAL (placeholder inputs) | spark-rsi `src/graph/mod.rs` `rank_bottlenecks` (0.4 centrality + 0.4 latency ratio + 0.2 error) | graph nodes fed literal constants in `src/daemon.rs`; ranking targets hypotheses only, never admission |
| RSI promotion authority | IMPLEMENTED as proposer-only | spark-rsi `src/ratify.rs` (human merges), `src/actor/judge.rs` `BlindJudge` | |
| Arena allocation rule | PLANNED (spec only) | `docs/specs/EVOLUTION_ARENA_SPEC_V1.md` §4.2, §1, §2.3 | Pareto before ranking; scalar fitness for search allocation only; J-Space search policy outside the V1 mutation surface; every automatic decision accountable |

## 3. Discrepancies with the brief

1. **The scheduler the brief describes is legacy.** Fixed batch budgets, KV watermark and preemption live in aien-sovereign-core, which its README calls legacy Linux-hosted scaffolding and `doctrine/ARCHITECTURE.md` §2.8 classes as a physical scheduler (class E), not on the reaction path. The semantic scheduler recorded as authoritative in §2.8 is omega `rx_world.c`, which orders reactions; no batch or KV policy was found there (UNVERIFIED beyond a grep). ADR 0031 therefore targets registered decision sites, not a repository.
2. **Budgets are both hard and soft today.** `cq_query_admit` rejects over-budget latency and energy; `rx_cm_decide` runs them flagged; RSI thresholds reject. ADR 0031 §3 rule 4 treats an existing hard reject as `CAPACITY` until the owning contract declares a class.
3. **Serial placement is not required.** EST-8 to EST-10 do not depend on DUAL (ADR 0031 §9.2).
4. **Name collision.** omega already has a `Shadow` structure (`rx_graph.c`) with an ARGUS collision recorded in omega `docs/turing/TURING_CURRENT_STATE.md:107-113`; the brief's "Shadow Scheduler" is named the advisory scheduler (`DUAL_ADVISORY_SCHEDULER`).
5. **Arena spec header is stale** (still PROPOSED, still calls omega #68 a draft), as already recorded in the belief-estimation current-state document. Not changed here.

## 4. Decision sites for DUAL-3 (initial list)

| Site id | Decision | Alternatives | Production owner |
|---|---|---|---|
| `jspace.residency` | keep, move, compress, spill or evict a branch realization | `choose()` actions | omega `rx_jspace.c` |
| `capq.front_order` | order inside the capability-query Pareto front | front members | omega `rx_capq.c` (advisory only: its latency and energy budgets are hard rejects today, so they are CAPACITY and unpriced until a need contract declares a SOFT budget; ADR 0031 §3 rule 4) |
| `costmodel.arm` | realization arm per call | eligible arms | omega `rx_costmodel.c` |
| `serve.admit_preempt` | admission, preemption victim, prefill chunk allocation | waiting/preempted queue heads, running sequences | aien-sovereign-core `aien-scheduler` (scaffolding; moves with its Omega replacement under ARCH-0024) |

## 5. Implementation slices, in dependency order

Each slice is one small pull request with its own receipt. None touches `omega/src/runtime/` until slice 5.

1. **DUAL-0a, records and registry (omega, standalone).** (IMPLEMENTED, see section 6.) `src/dual/` and `tests/dual/`, own `mk/dual.mk` targets, not in `all` or `test`, not included by `src/runtime/`. Section 4 records, kind bytes, digest domains, unit registry, class rules, canonical encoding round trip, `nm -u` refusal check. Hostile tests for `INVARIANT` construction, NaN/negative/unit mismatch, kind confusion.
2. **DUAL-0b, staleness and evidence binding.** Generation and maximum-age checks; evidence-root verification reusing `est_evidence_root_extend`; references to `est_*` records, never copies of raw observations. Exit `DUAL_CONSTRAINT_CONTRACT = PASS`.
3. **DUAL-1a, reference update.** Section 5.1 update as a pure function of (state, input, controller parameters); `controller_id` digest; analytic cases plus an independent reference written without reading the implementation.
4. **DUAL-1b, replay on recorded traces.** Digest-bound traces already on disk (for example the R15 machine-state series used by EST-2) plus synthetic step-change and square-wave loads; oscillation bound pre-registered; inputs labelled `UNCALIBRATED`. Exit `DUAL_PRICE_REFERENCE = PASS`.
5. **DUAL-3a, read-only tap at one site.** Start with `jspace.residency` (omega, smallest blast radius, already has a price-shaped input) or `serve.admit_preempt` (real batch decisions). Tap records alternatives and the actual choice; a with/without comparison proves identical decisions. This is the first change under `src/runtime/` and must stay clean of the R16 loop-inventory patterns.
6. **DUAL-3b, advisory campaign.** Pre-registered workloads, `DualRecommendation` for every decision, prediction-error report. Exit `DUAL_ADVISORY_SCHEDULER = PASS`.
7. **DUAL-2, Pareto integration (test builds).** Waits on EST-5 and EST-7. Exit `DUAL_PARETO_INTEGRATION = PASS`.
8. **DUAL-4, Arena allocation.** Waits on DUAL-2, DUAL-3, the Arena V1 activation hold and a DUAL allocation policy frozen in the Arena Evaluation contract; observe-and-record Arena runs only until DUAL-5. Exit `DUAL_ARENA_ALLOCATION = PASS`.
9. **DUAL-5, closed-loop qualification.** Waits on DUAL-2, DUAL-3, DUAL-4 and on EST-3, EST-4, EST-5, EST-7 for every consumed signal. Exit `DUAL_CLOSED_LOOP_QUALIFICATION = PASS`.

Slices 1 to 4 are permitted now by the same rule that let EST-0 to EST-3 run as a standalone module. Slices 5 and 6 need no ESTIMATION gate because they have no production authority. Slices 7 to 9 wait as stated.

## 6. Implementation status, 2026-10-04 (updated after the first DUAL code landed)

Written by the orchestrator after read-only audits of the merged commits below. Status words as above plus EXPERIMENTAL (code and evidence exist, no gate claimed, nothing wired into production) and BLOCKED (gate prerequisite failed or missing).

| Repository | Commit (GitHub `main`, after the merges) |
|---|---|
| aien-dev/omega | `55d05d6` |
| aien-dev/aien-sovereign-core | `7580039` |
| aien-dev/spark-rsi | `e5aab9a` |

Baseline before this work: omega `cb7cc21`, aien-sovereign-core `91fba8f`, spark-rsi `f5f1ca2`, aien-architecture `35dd324`. Grep for `rx_dual`, `RxDual`, `src/dual` at those commits: zero hits (DUAL was MISSING everywhere, consistent with section 1).

| Slice | Status | Where | Evidence |
|---|---|---|---|
| DUAL-0a records and registry | IMPLEMENTED | omega `src/dual/rx_dual.{h,c}`, `tests/dual/test_dual_types.c`, `mk/dual.mk` (`make test-dual`), `docs/dual/DUAL_RECORDS.md` | omega #266 (`109cadc`); `evidence/DUAL/0a-records/receipt.md`; 14107 checks plain, 1667 ASan/UBSan, 4 mutants killed; `nm -u` purity clean |
| DUAL-0b evidence and staleness binding | IMPLEMENTED | omega `src/dual/rx_dual_bind.{h,c}`, `tests/dual/test_dual_bind.c` | omega #267 (`3bebcc6, reopened as #272 after GitHub closed #267 with its base branch`); binds to `est_belief`, `est_prediction`, `est_observation` digests, verifies `evidence_root` via `est_evidence_root_extend`; states FRESH / STALE / FROZEN / UNCALIBRATED / REFUSED; `DUAL_CONSTRAINT_CONTRACT = PASS` (host) |
| DUAL-1a reference update | IMPLEMENTED | omega `src/dual/rx_dual_update.{h,c}`, `tests/dual/test_dual_update.c`, independent closed form `tests/dual/dual_ref.c` | omega #267; analytic cases 1-8, 3000-round property suite (355348 checks plain, 35837 ASan), 5 mutants killed |
| DUAL-1b replay | IMPLEMENTED | omega `src/dual/rx_dual_replay.{h,c}`, `tests/dual/test_dual_replay.c`, `tests/dual/dual_traces.{h,c}` | omega #271 (`55d05d6`); 12 synthetic scenarios + 6 recorded R15 perf-counter traces (digest-bound), thresholds pre-registered in a commit before the code; 456 checks plain and ASan; hostile controller (eta 5, rho 0) fails the amplitude bound as declared; `DUAL_PRICE_REFERENCE = PASS` (host); every replayed input UNCALIBRATED |
| DUAL-3a read-only tap at `jspace.residency` | IMPLEMENTED | omega `src/runtime/rx_jspace.{h,c}` (`js_dual_set_observer`, default NULL), `mk/dual_jspace_tap.mk` (`make test-dual-3a`) | omega #270 (`3a3144d`); on/off parity byte-identical (rc, `JsPolicyReport`, `JsStats`, space digest), hostile observer killed 2035 times, bench: tap-off within -0.42 % of base, +2.06 us per record with tap on; receipt `evidence/DUAL/3a-jspace-tap/receipt.md` (thresholds declared before the run, committed after it, stated there) |
| DUAL-3a observer at `serve.admit_preempt` | IMPLEMENTED | aien-sovereign-core `crates/aien-scheduler/src/dual_observer.rs` (`DecisionObserver`, default None), `build_scheduled_batch` wrapper | aien-sovereign-core #198 (`2f9570a`); per-scenario decision digests over 13 scripted scenarios identical to the base commit; observer on/off byte-identical; compile_fail doctests prove the observer cannot mutate or return a choice; feature-gated mutant that changes a decision fails 4/13 scenarios; bench B1 (counting/absent <= 1.25) measured 1.337 and recorded FAIL, threshold untouched (noise reference 0.594); receipt `docs/campaigns/dual/2026-10-04-serve-observer-receipt.md` |
| Macroscopic snapshot adapter | IMPLEMENTED | aien-sovereign-core `crates/aien-dual-observation` (new read-only crate) | aien-sovereign-core #199 (`7580039`); conservation tests (8) pass; zero-denominator ratio yields None, never zero; no scheduler decision read or written; receipt `docs/campaigns/dual/2026-10-04-macro-snapshot-receipt.md` |
| Applicability (continuum vs discrete) experiment | EXPERIMENTAL | omega `src/dual_experiment/`, `tools/dual_experiment/applic_run.c`, `mk/dual_applicability.mk`, `docs/dual/APPLICABILITY_EXPERIMENT.md` | omega #268 (`00f54b6`); 8 synthetic workloads x 24 seeds, bit-reproducible (results digest pinned in the test); aggregate throughput prediction usable when demand spread is low, degrades monotonically with heterogeneity; shuffled-window control worse in 192/192 runs; proposes a regime rule only, nothing inserted |
| DUAL-3b advisory recommendation campaign | MISSING | | needs the tap (#270) and the records (#266, #267) on the same build; not started |
| RSI diagnostic price consumer | IMPLEMENTED (diagnostic only) | spark-rsi `src/dual/{records,diagnostic}.rs`, knob `RsiConfig.dual_price_vector_dir` (default None), report field `RsiCycleResult.scarcity` | spark-rsi #33 (`e5aab9a`); byte-exact re-encode of omega golden vectors (generated at omega #266), 32 hostile cases refused with the same status codes as the C decoder; flipped-bit digest mismatch reported as unavailable, never as zero scarcity; names only the highest FRESH calibrated price; weighted sum, hard invariants, admission, ratification and promotion untouched (source-level test guards them); 198 tests pass; receipt `evidence/dual/receipt.md` |
| DUAL-2 Pareto integration | BLOCKED | | waits on EST-5 and EST-7 (not reached) |
| DUAL-4 Arena allocation | BLOCKED | | waits on DUAL-2, DUAL-3, Arena V1 activation hold |
| DUAL-5 closed-loop qualification | BLOCKED | | waits on EST-3 (FAILED on `main`), EST-4, EST-5, EST-7 |

**DUAL production influence: DISABLED BY GATE.** No price reaches any production decision. The only `src/runtime/` change is the `jspace.residency` tap, which is read-only with a NULL default and a proven on/off parity. ESTIMATION gates EST-3, EST-4, EST-5 and EST-7 are not passed, so DUAL-5 cannot start.

Known limits of the merged work: host-only (no GB10 chip time was used or needed); the `lambda_max` and controller constants are placeholders bound into `controller_id`, not tuned; FRESH inputs require a calibration reference that nothing on `main` yet produces, so every real input today classifies as UNCALIBRATED or STALE by construction; ADR 0033 verification manifests do not yet exist for omega, so these slices are gated by the existing make targets and GitHub CI.
