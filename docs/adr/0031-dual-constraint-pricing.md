# ADR 0031: DUAL, Constraint Pricing for Soft Resource Budgets

**Status:** Accepted by operator Drake Stapleton, 2026-10-03 (via his "DUAL / Constraint Pricing" brief of that date). The placement in section 9 differs from the strictly serial order in the brief; that difference is an orchestrator engineering call under the operator's standing rule and is stated in section 9.2.
**Gate:** `DUAL-0` may begin when this ADR is merged to `main`. No DUAL output may influence a production decision before `DUAL-5` passes (section 8).
**Supersedes:** nothing. **Amends:** nothing. **Extends:** ARCH-0020 (belief / estimation layer: DUAL is a consumer of its estimates, never a producer of observations).
**Related:** ARCH-0007 (J-Space effect boundary), ARCH-0016 (resident reaction architecture), ARCH-0017 (ARGUS observes, never authorizes), ARCH-0024 (Rust scaffolding, Omega destination), ARCH-0028 (AIEN-TEST receipts), `docs/specs/EVOLUTION_ARENA_SPEC_V1.md`.
**Workstream:** DUAL-0 to DUAL-5 (section 8); current state and implementation slices in [`docs/plans/dual/DUAL_CURRENT_STATE.md`](../plans/dual/DUAL_CURRENT_STATE.md) (NOT A MASTER PLAN). Sequencing stays in `CURRENT_EXECUTION_PLAN.md` (Lane 8).

Citation note: in this repository "ADR 0031" and ARCH-0031 name the same decision. In other repositories cite it as ARCH-0031.

---

## 1. Context

AIEN already reasons about several resources at once. Omega's capability query keeps separate dimensions and filters to the nondominated (Pareto) set before any ordering (omega `src/runtime/rx_capq.c` `cq_rank`). The Omega cost model predicts latency with calibrated intervals and carries power, verification cost, synthesis cost and code size per arm (`src/runtime/rx_costmodel.h` `RxCostModel`, `RxCmPrediction`). J-Space decides what stays resident by weighing expected work per byte freed against a **hand-set** pressure scalar (`src/runtime/rx_jspace.c` `choose()`, pressure fixed at `1e9` or `1e3` in `enforce_u`). The legacy serving scheduler uses fixed batch, token and KV-watermark limits (aien-sovereign-core `crates/aien-scheduler/src/lib.rs` `SchedulerConfig`). spark-rsi ranks bottlenecks with fixed weights over hard-coded graph inputs (spark-rsi `src/graph/mod.rs` `rank_bottlenecks`, `src/daemon.rs`).

None of these can answer: **which currently binding resource would give the largest marginal improvement if its budget were relaxed, and by how much?** The scarcity of a resource changes with workload, thermal state and hardware regime, yet every place above encodes it as a constant. Nothing in any of the four repositories computes a shadow price (grep for `shadow price`, `lagrang`, `scarcity`: zero hits; see the current-state document).

Constrained-optimization theory gives a name to the missing quantity: the dual variable, or shadow price, of a constraint. This ADR adopts that idea in a deliberately narrow form.

## 2. Decision

```text
AIEN ESTIMATES A NONNEGATIVE SHADOW PRICE FOR EACH DECLARED SOFT RESOURCE
BUDGET, FROM CALIBRATED ESTIMATES WITH EXPLICIT UNCERTAINTY, BOUND TO A
GENERATION AND AN EVIDENCE ROOT.

PRICES ORDER ALTERNATIVES THAT HAVE ALREADY PASSED EVERY HARD GATE AND
ALREADY SURVIVED PARETO FILTERING. THEY NEVER DECIDE VALIDITY, ELIGIBILITY,
PROMOTION OR AUTHORITY.
```

The four roles stay separate:

```text
Pareto reasoning  decides which alternatives are legitimately competitive.
DUAL              decides what scarce resources are currently worth.
Verification      decides what is valid.
Authority         decides what may act.
```

```text
price      != truth
price      != permission
scarcity   != correctness
cheap      != valid
```

### 2.1 What DUAL is not

- Not roadmap M22. M22 `OMEGA_OPTIMIZER` is the sovereign training-optimizer milestone (SGD, Adam, AdamW updating model parameters in shadow state; `doctrine/ROADMAP.md` §3 M22). DUAL updates no model parameter, produces no training step and shares no code path with M22. The name collision ("optimizer") is the only overlap.
- Not a generic Lagrange-multiplier library, not a solver, not a neural policy. The first realization is a damped, clipped, projected feedback update (section 5) because it is simple, interpretable, measurable and reversible. A more complex controller is admissible only after DUAL-5 evidence shows the simple one is inadequate.
- Not a second cost model. The Omega cost model stays the one cost model (ARCH-0020 §4); DUAL reads its predictions.
- Not a second estimator. ESTIMATION (ARCH-0020) produces beliefs and uncertainty; DUAL consumes them.
- Not a scheduler. Existing schedulers keep every decision until DUAL-5 passes, and afterwards still own the decision; DUAL supplies an input.

## 3. Constraint classes

Every constraint DUAL sees carries exactly one class, declared by the contract that owns the constraint (the capability need, the Arena Evaluation contract, the scheduler configuration). DUAL never assigns or changes a class.

| Class | Examples | Enforcement | Price |
|---|---|---|---|
| `INVARIANT` | correctness, semantic validity, security, containment, authority, provenance, verification requirements, AEGIS invariants, typed result contracts (`rc_*`), effect budgets (`RC_E_BUDGET`), sealed-holdout rules | hard gate; failing candidate rejected regardless of any resource figure | **none, ever.** A `DualConstraintState` of this class is refused at construction; it has no lambda field to fill |
| `CAPACITY` | physical KV pool size, resident-memory ceiling (`JsLimits.max_resident_bytes`), memory bandwidth, device occupancy limits, a caller's hard deadline | hard limit; never exceeded, never relaxed by DUAL | **diagnostic only.** May carry a lambda that states what additional capacity would be worth; that lambda is read-only telemetry (RSI, operator) and is never used to admit an alternative that violates the limit |
| `SOFT` | latency budget, energy budget, bandwidth share, KV share, compute occupancy target, verification cost, synthesis cost, search/evaluation budget | soft; may be traded against other soft budgets | **priced.** Lambda may order alternatives inside the nondominated set once DUAL-5 passes |

Rules:

1. A candidate failing an `INVARIANT` is rejected before DUAL sees it. DUAL receives only candidates that passed every hard gate.
2. The same physical quantity may be `CAPACITY` in one contract and `SOFT` in another (for example a hard KV pool size and a soft KV share target below it). The class belongs to the constraint, not to the resource.
3. Reclassifying a constraint (for example `CAPACITY` to `SOFT`) is a change to the owning contract, made by that contract's owner with its own evidence. DUAL has no path to do it.
4. Existing behavior is recorded, not changed: omega `cq_query_admit` treats `latency_budget` and `energy_budget` as hard rejects (`rx_capq.c:639-640`) while also ranking on them; the cost model treats them as soft (`RX_CM_WHY_OVER_BUDGET`); spark-rsi treats `regression_budgets` as hard thresholds. Until an owning contract declares a class explicitly, DUAL treats an existing hard reject as `CAPACITY`.

## 4. Typed records

DUAL follows ARCH-0020 §2.1 discipline: each record is a separate type with a separate kind byte and a separate digest domain; digests are SHA-256(domain, 0x00, canonical encoding). Field names below are architectural; the realization names them in the house prefix (`RxDual*` / `rx_dual_*` in omega, per the current-state document). The word "shadow" is not used in any type name, because omega already has a `Shadow` structure (`src/runtime/rx_graph.c`) and a recorded ARGUS naming collision.

### 4.1 `DualResource` (registry entry)

| Field | Meaning |
|---|---|
| `resource_id` | stable id in the DUAL resource registry |
| `unit` | declared unit (for example `ps`, `pJ`, `bytes`, `bytes_per_s`, `kv_blocks`, `ppm_occupancy`, `ns_verify`, `ns_synth`) |
| `scale` | positive normalizer in the same unit, declared per contract; makes pressures dimensionless |

Two values are comparable only if their `unit` strings are identical. Conversion is explicit and recorded; implicit conversion is a refusal.

### 4.2 `DualConstraintState`

| Field | Meaning |
|---|---|
| `resource_id`, `unit` | which resource; unit must match the registry and the budget |
| `class` | `CAPACITY` or `SOFT` (an `INVARIANT` cannot be constructed) |
| `budget` | value in `unit`, plus the digest of the contract that declared it |
| `observation_ref` | digest of the ARCH-0020 observation record(s) used, if any; a measured value is never copied into an estimate field |
| `estimate_ref` | digest of the ARCH-0020 belief or prediction record used |
| `estimate_kind` | `MEASURED`, `ESTIMATED` or `PREDICTED`, matching the referenced record kind |
| `estimate`, `uncertainty` | value and standard deviation in `unit`, copied from the referenced record, never computed by DUAL |
| `calibration_ref` | digest of the EST-3 calibration receipt that covers this signal, or absent; absent means `UNCALIBRATED` |
| `lambda` | finite, nonnegative; absent for `INVARIANT` (unconstructible) |
| `lambda_state` | `FRESH`, `STALE`, `FROZEN`, `UNCALIBRATED`, `REFUSED` |
| `controller_id` | digest of the controller parameters (section 5) that produced `lambda` |
| `generation` | World generation the estimate is bound to (`RxObjRef` generation, ARCH-0020 EST-4) |
| `evidence_root` | ARCH-0020 evidence-root chain over every observation that shaped `estimate` and `lambda` |
| `parent` | digest of the previous `DualConstraintState` for this resource (append-only history) |

### 4.3 `DualPriceVector`

The set of `DualConstraintState` digests for one decision context at one generation, plus the ordered list of resource ids, plus its own digest. A consumer cites one `DualPriceVector` digest per decision.

### 4.4 `DualRecommendation` (advisory)

| Field | Meaning |
|---|---|
| `decision_site` | registered site id (section 7.3) |
| `price_vector` | `DualPriceVector` digest |
| `candidates` | digests of the nondominated alternatives offered |
| `actual` | the alternative the production decision-maker chose |
| `recommended` | the alternative DUAL would have chosen |
| `predicted` | predicted consequence per resource, with uncertainty and units |
| `measured` | measured consequence per resource (filled later, from observations) |
| `error` | measured minus predicted, normalized by stated uncertainty |
| `authority` | constant `NONE`; a record carrying any other value is malformed |

### 4.5 `DualOutcome`

Binds a `DualRecommendation` to the before and after `DualPriceVector`s, so a later reader can check whether the price of the targeted resource fell (section 7.6).

## 5. Update semantics

### 5.1 Reference update

For each `SOFT` or `CAPACITY` constraint i, at each update tick:

```text
pressure_i = (estimate_i - budget_i) / scale_i                    dimensionless
deadband_i = k_sigma * uncertainty_i / scale_i

if |pressure_i| <= deadband_i:   g_i = 0                          (inside the noise: no move)
else:                             g_i = pressure_i - sign(pressure_i) * deadband_i

lambda_i(t+1) = clip( (1 - rho) * lambda_i(t) + eta * g_i,  0,  lambda_max_i )
```

- `eta` (step), `rho` (leak toward zero, which bounds memory of old scarcity under nonstationarity), `k_sigma` (deadband width), `lambda_max_i` (clip) and the update cadence are controller parameters. Their canonical encoding is hashed into `controller_id`; a change is a new controller.
- The deadband is the hysteresis: a price moves only when the estimate is outside its own stated uncertainty of the budget, so a noisy measurement cannot drive the price.
- Lambda is dimensionless because pressure is normalized by `scale_i`. A price-weighted comparison of two alternatives uses `sum_i lambda_i * c_i / scale_i` with every `c_i` in the registry unit; a unit mismatch is a refusal, not a conversion.
- This is the projected, damped dual-subgradient form. It is the starting point, not a claim of production quality. DUAL-1 measures its behavior on recorded traces; DUAL-5 compares it against simpler baselines.

### 5.2 What the update consumes

- `estimate` and `uncertainty` come from ARCH-0020 records, never from raw counters read by DUAL. Where no calibrated estimator exists for a signal, the state is `UNCALIBRATED` and its lambda may be computed and recorded but may not influence any production decision.
- An input whose `generation` is older than the controller's declared maximum age, or whose `evidence_root` does not verify, is refused for that tick: lambda is held at its last value and marked `STALE`. A `STALE` lambda is treated by consumers as absent.

### 5.3 Discrete and non-convex reality

AIEN decisions are discrete (which arm, which batch, which victim), the alternative sets are non-convex, observations are delayed and the hardware changes regime. DUAL therefore claims no convergence to a global optimum and no strong duality. It claims only measurable properties, checked at the gates: prices stay finite, nonnegative and bounded; they do not oscillate beyond a declared bound; price-guided choices among valid alternatives beat the declared baselines on pre-registered measures (DUAL-5). A regime change (detected by ARCH-0020 innovation, EST-9) resets the affected prices to `FROZEN` until the estimator re-qualifies, rather than letting the controller chase a stale model.

## 6. Ownership and boundaries

| Faculty | Keeps | DUAL's relation |
|---|---|---|
| ESTIMATION (ARCH-0020) | beliefs, predictions, uncertainty, calibration | DUAL consumes; never produces an observation or belief |
| Omega cost model | the one cost model (`RxCostModel`) | DUAL reads predictions; never refits or replaces it |
| Omega capability query | hard admit, Pareto front, caller order (`cq_rank`) | DUAL may only reorder **inside** the front, after it is built |
| J-Space | branches, separate score dimensions, residency policy | DUAL may supply the pressure input to residency choice (replacing the hand-set scalar) and an allocation preference among nondominated branches; never prunes a nondominated branch, never externalizes |
| Schedulers | every production decision | advisory input only until DUAL-5; afterwards an input the scheduler may use, never a decision DUAL takes itself |
| AEGIS | authorization, verification | reads no DUAL output as an authority input |
| Evolution Arena | candidates, lineage, evaluation, promotion contract | DUAL may allocate search/evaluation budget among verified, nondominated lineages; never ELIGIBLE, never promotion |
| RSI | proposes and evaluates | reads prices as diagnostic telemetry; holds no authority through them |
| Promotion right holder | `rx_gen_promote` | DUAL is link-isolated from it |

Security and authority:

- DUAL mints no capability, requests no capability beyond read access to its inputs and write access to its own records, and authorizes no effect. Every DUAL object file passes the existing `nm -u` refusal check used for the cost model and capability query (no `aienos_cap_*`, no `rx_gen_*` admin or promote symbols).
- No DUAL record may be presented as evidence of correctness, eligibility or authority. A consumer that reads a `DualPriceVector` as a gate input fails its gate.
- DUAL prices are not secrets but are evidence: they are append-only, digest-bound and replayable.

## 7. Interactions

### 7.1 ESTIMATION

```text
EST-3 calibration  ->  EST-4 World belief  ->  EST-5 uncertainty-aware cost model
                   ->  EST-6 predictive evidence  ->  EST-7 uncertainty-aware J-Space
                   ->  DUAL production influence (DUAL-5)
```

DUAL-0 may be built now. DUAL-1 may run experimentally on recorded traces. No price derived from an uncalibrated estimate may materially control a runtime decision.

### 7.2 Omega and J-Space: the required order

```text
candidate alternatives
    -> hard verification (INVARIANT gates, CAPACITY limits)
    -> separate measurements (no collapse)
    -> Pareto / nondominance filtering
    -> DUAL contextual pricing
    -> preference / allocation among the surviving alternatives
```

In `cq_rank` the hook is after the front is built and before the caller's order loop. DUAL never adds a dimension that would let a dominated candidate re-enter, and never removes a nondominated one. With DUAL absent, `STALE` or failed, the existing order applies unchanged.

### 7.3 Schedulers (advisory first)

The architecture records two scheduler roles (`doctrine/ARCHITECTURE.md` §2.8): the omega reaction scheduler (`rx_world.c`, semantic, the only code that orders faculty work) and physical schedulers (class E), of which the sovereign-core `aien-scheduler` token batcher is the one making batch, admission, chunked-prefill and KV-preemption decisions today. That repository is legacy scaffolding under ARCH-0024; Omega replaces components after conformance. DUAL-3 therefore targets decision sites, not a particular repository:

- each site is registered (`decision_site` id, the decision it makes, its alternatives, its production owner);
- a site is observed through a read-only tap that records the alternatives the scheduler considered and the choice it made, and changes nothing;
- the site list for DUAL-3 is in the current-state document; it includes at least one site that makes real admission or preemption decisions on recorded or live workloads.

### 7.4 Evolution Arena

The Arena spec V1 already says: dimensions are measured separately, Pareto filtering precedes ranking, and a scalar fitness may be used for search allocation only, never for ELIGIBLE or promotion (`EVOLUTION_ARENA_SPEC_V1.md` §4.2). DUAL is a principled source of that allocation quantity:

```text
allocation_value(lineage) = expected_value(lineage) - sum_i lambda_i * c_i(lineage) / scale_i
```

computed only over verified, nondominated lineages. Because Arena V1 freezes J-Space search policy as outside the mutation surface and requires every automatic decision to be attributable, generation-bound, receipt-producing and recoverable (spec §1, §2.3), a DUAL allocation policy must be declared in the frozen Evaluation contract before candidates are generated, and every allocation emits a causal crumb citing its `DualPriceVector` digest. DUAL answers "which candidate deserves the next experiment"; it never answers "which candidate is valid" or "which candidate is promoted".

### 7.5 RSI

RSI stays off the critical path (`CURRENT_EXECUTION_PLAN.md` §11 H3). When it returns, it reads `DualPriceVector`s as diagnostic telemetry: the resource with the largest fresh, calibrated lambda is the dominant current scarcity, which replaces fixed-weight bottleneck scores built on hard-coded inputs. RSI remains a proposer and evaluator; hard invariants stay in its existing hard layers (spark-rsi `LayerResult.is_hard_invariant`), and DUAL may inform only its soft layers.

### 7.6 The replayable claim DUAL exists to support

> At generation G, resource R was a binding soft constraint with estimated shadow price lambda and uncertainty U, based on evidence root E. AIEN chose action A rather than B because of that scarcity. The predicted consequence was P. The measured consequence was M. After the intervention, lambda changed from X to Y. No hard invariant was relaxed, and all effects remained under existing authority boundaries.

Every field of that sentence maps to a record field: G (`generation`), R (`resource_id`, `class`), lambda and U (`lambda`, `uncertainty`), E (`evidence_root`), A and B (`DualRecommendation.actual` / `recommended` or the post-DUAL-5 decision record), P and M (`predicted`, `measured`), X and Y (`DualOutcome` before and after vectors). DUAL is complete only when this sentence can be produced from replayed evidence by a reader who did not write the code.

## 8. Gates

Every gate is pre-registered: its protocol and thresholds are frozen and digest-bound before evaluation (CAL-0 / EST-3 discipline), a failed run is recorded as FAIL and not retried silently, and receipts follow ARCH-0028. Each gate includes the hostile tests listed; a hostile test that is not killed is a gate failure.

| Stage | Exit token | Prerequisites | Pass condition |
|---|---|---|---|
| DUAL-0 | `DUAL_CONSTRAINT_CONTRACT = PASS` | this ADR on `main` | typed records of section 4 with exact canonical serialization round trip, separate kind bytes and digest domains, unit registry, class rules of section 3, staleness detection, property tests; standalone module with zero runtime linkage |
| DUAL-1 | `DUAL_PRICE_REFERENCE = PASS` | DUAL-0 | reference update of section 5 deterministic and bounded; analytic cases (single binding constraint, slack constraint, two competing constraints) match an independent reference written without reading the implementation; replay on recorded digest-bound traces shows prices finite, nonnegative, within clip, and oscillation within the declared bound; inputs labelled `UNCALIBRATED` where EST-3 has not passed for that signal |
| DUAL-2 | `DUAL_PARETO_INTEGRATION = PASS` | DUAL-1, EST-5 (cost model inputs), EST-7 (J-Space inputs) | in test builds, DUAL ordering applied only inside the Pareto front; front membership byte-identical with DUAL on and off; with DUAL absent or `STALE`, order identical to the existing order; living build unchanged (DUAL ordering off by default) |
| DUAL-3 | `DUAL_ADVISORY_SCHEDULER = PASS` | DUAL-1; at least one registered decision site with a read-only tap | over a pre-registered workload set, a `DualRecommendation` is recorded for every decision; production decisions, outputs and timings are identical with the tap on and off within declared measurement noise; recommendation-versus-actual analysis and prediction-error calibration reported; claims of prediction quality are made only for signals with a passing EST-3 receipt |
| DUAL-4 | `DUAL_ARENA_ALLOCATION = PASS` | DUAL-2, DUAL-3, Arena V1 §0.1 prerequisites closed, DUAL allocation policy frozen in the Arena Evaluation contract | allocation applied only to verified, nondominated lineages; every allocation crumb cites a `DualPriceVector`; DUAL-guided allocation compared against a baseline allocation declared in the same frozen contract, on the same budget; ELIGIBLE and promotion outcomes provably independent of DUAL (same set with DUAL on and off) |
| DUAL-5 | `DUAL_CLOSED_LOOP_QUALIFICATION = PASS` | DUAL-2, DUAL-3, DUAL-4; EST-4, EST-5, EST-7 PASS for every signal DUAL consumes | pre-registered comparison against fixed thresholds, fixed weights, priority-only scheduling, the current heuristic scheduler and Pareto-only selection; DUAL must beat the best baseline on the pre-registered primary measure without regressing any pre-registered guard measure (p50/p95/p99 latency, throughput, memory occupancy, energy, KV pressure, preemption count, fairness, budget violations, oscillation, prediction error) beyond its declared margin; the section 7.6 sentence reproduced from replayed evidence by an independent reader. A controller does not pass because it is more sophisticated |

### 8.1 Hostile and negative tests (each must be refused or detected)

| Test | Gate(s) | Expected |
|---|---|---|
| construct a `DualConstraintState` of class `INVARIANT` | 0 | refused at construction |
| hard constraint reaches the price update by any path | 0, 1 | refused; gate FAIL if a lambda is produced |
| `CAPACITY` lambda used to admit an alternative that exceeds the limit | 2, 3, 5 | refused; gate FAIL |
| reclassify a constraint from inside DUAL | 0 | no API exists; build check FAIL if one appears |
| NaN, infinite or negative lambda, estimate, uncertainty, budget or scale | 0, 1 | refused; lambda held, state `REFUSED` |
| unit mismatch between estimate, budget and scale | 0, 1 | refused; no implicit conversion |
| stale generation or unverifiable evidence root consumed | 0, 1, 3 | input refused; lambda `STALE`; consumer treats as absent |
| measured value overwritten by an estimate, or kind byte confusion | 0 | refused (ARCH-0020 kind rule) |
| oscillation beyond the declared bound on a recorded trace, including a step-change and a square-wave load | 1, 5 | gate FAIL |
| dominated candidate selected or re-admitted by DUAL ordering | 2, 4 | gate FAIL |
| nondominated candidate removed by DUAL | 2, 4 | gate FAIL |
| DUAL recommendation changes a production decision, output or timing during the advisory stage | 3 | gate FAIL |
| `DualRecommendation.authority` other than `NONE` | 3 | record malformed, refused |
| DUAL object file links an authority or promotion symbol (`aienos_cap_*`, `rx_gen_promote`, `rx_gen_*` admin) | all | build check FAIL |
| DUAL attempts to set `proofs_ok`, write Evidence used for ELIGIBLE, or request promotion | 4 | refused; gate FAIL |
| ELIGIBLE or PROMOTED set differs with DUAL on and off | 4 | gate FAIL |
| uncalibrated estimate materially controls a runtime decision | 2, 3, 5 | gate FAIL |
| allocation decision without a crumb citing its price vector | 4 | gate FAIL (Arena EA-G1) |
| controller parameters changed without a new `controller_id` | 1 | digest mismatch detected |

## 9. Placement

### 9.1 Where DUAL sits

```text
R16 (closed)
  -> EST-0 .. EST-3 (calibration; EST-3 FAILED on main, v5 in progress)
  -> EST-4 .. EST-7 (World belief, uncertainty-aware cost model, predictive evidence, uncertainty-aware J-Space)
  -> DUAL production influence (DUAL-2 needs EST-5 and EST-7; DUAL-5 needs EST-4, EST-5, EST-7)
  -> DUAL-4 inside Evolution Arena (after Arena V1 §0.1 prerequisites)
  -> later RSI use (H3)
  -> Physics Zero and later discovery
```

DUAL-0 and DUAL-1 run now as a standalone module, like EST-0 to EST-3 did: new files only, own build targets, not in `all` or `test`, not included by `src/runtime/`. DUAL-3's advisory tap is read-only and may be built after DUAL-1 without waiting for ESTIMATION, because it has no production authority.

### 9.2 Difference from the brief

The brief proposed a strictly serial order `EST-7 -> DUAL -> EST-8 -> EST-9 -> EST-10`. The live dependencies do not require it: EST-8 (Cortex predictive memory), EST-9 (innovation curiosity signal) and EST-10 (active information gain) consume ESTIMATION, not DUAL, and DUAL does not consume them, except that DUAL uses EST-9's regime-change detection when it exists (section 5.3) and falls back to freezing prices without it. Making EST-8 to EST-10 wait for DUAL would block Cortex and curiosity work for no technical reason. DUAL is therefore a lane (Lane 8) with dependency edges on EST-5 and EST-7, running beside EST-8 to EST-10, and both must be done before DUAL-4 uses the Arena.

### 9.3 Why not M22

M22 is a milestone row with a fixed meaning (verified SGD, Adam, AdamW realizations; `doctrine/ROADMAP.md`). Folding DUAL into it would change a milestone's meaning by name association, which ADR 0009 ("names state implemented contracts") forbids, and would tie a scheduling and allocation layer to tensor/autodiff prerequisites (M20, M21) it does not need. DUAL is not a milestone; like ESTIMATION it is a workstream with gates.

## 10. Failure behavior

- DUAL failure never blocks work: when DUAL is absent, refuses its inputs, or holds only `STALE`, `FROZEN`, `UNCALIBRATED` or `REFUSED` prices, every consumer uses its existing behavior (Pareto front plus existing order; existing scheduler limits; existing Arena baseline allocation).
- DUAL failure never weakens a gate: no failure mode changes a hard-gate outcome, a capacity limit, an ELIGIBLE decision or a promotion.
- Every refusal is recorded with its reason, so the rate of DUAL refusals is itself evidence.
- A gate failure is recorded as FAIL with its receipt; the controller is not promoted (the EST-3 rule applies).

## 11. Consequences

- AIEN gains a typed, replayable answer to "what is scarce right now and how much would relaxing it be worth", which the hand-set J-Space pressure, fixed scheduler limits and fixed-weight RSI bottleneck scores cannot give.
- The cost: one new record family, one standalone module, one read-only tap per decision site, and a qualification campaign against honest baselines before any production influence.
- DUAL may fail DUAL-5. That outcome is acceptable and must be recorded; the simpler baseline then stays in production.
