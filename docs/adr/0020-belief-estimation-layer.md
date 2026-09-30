# ADR 0020: Belief / Estimation Layer

**Status:** Accepted by operator Drake Stapleton, 2026-09-30 (course-correction brief "Belief-state / estimation layer" of that date).
**Gate:** `EST-0` may begin when this ADR is merged to `main`. `EST-4` and later wait for R16 closure.
**Supersedes:** nothing. **Amends:** nothing. **Extends:** ARCH-0016 (resident reaction architecture: AIEN contributes BELIEFS, PREDICTIONS, UNCERTAINTY, 0016 section on contributions) by giving those words a typed contract.
**Related:** ARCH-0005 (Effect Broker), ARCH-0007 (J-Space effect boundary), ARCH-0015 (Resident Semantic Store), ARCH-0017 (ARGUS observes, never authorizes), ARCH-0018 (AR3 substrate calibration), ARCH-0019 (selection records).
**Workstream:** EST-0 to EST-10 (section 5); supporting documents in [`docs/plans/belief-estimation/`](../plans/belief-estimation/) (NOT A MASTER PLAN). Sequencing stays in `CURRENT_EXECUTION_PLAN.md`.

Citation note: in this repository "ADR 0020" and ARCH-0020 name the same decision. In other repositories cite it as ARCH-0020.

---

## 1. Context

AIEN's later stages (TURING predictive evaluation, J-Space comparison under uncertainty, Cortex predictive abstraction, information-gain experiments, Physics Zero) all depend on predictions about physical and operational state. Today nothing in the code represents an uncertain dynamic state: there is no belief, covariance, innovation or estimator anywhere ([current state](../plans/belief-estimation/BELIEF_ESTIMATION_CURRENT_STATE.md) section 1). Two narrow predictors exist, the Omega cost model and TURING PRD1, and neither carries a state that evolves over time.

Without a contract, later stages would each invent their own notion of "what the machine believes", and the easiest failure is the quiet one: a smoothed or predicted number gets stored or used as if it had been measured.

## 2. Decision

```text
AIEN REPRESENTS OBSERVATION, ESTIMATE, PREDICTION, INNOVATION AND
UNCERTAINTY AS DISTINCT TYPED RECORDS, BOUND TO A MODEL IDENTITY AND AN
EVIDENCE ROOT, BEFORE ANY LATER STAGE MAY DEPEND MATERIALLY ON PREDICTED STATE.

THE ARCHITECTURE IS GENERAL PROBABILISTIC STATE ESTIMATION.
THE LINEAR KALMAN FILTER IS ONLY THE FIRST REFERENCE REALIZATION.
```

### 2.1 The five categories never collapse

| Record | What it is | Rule |
|---|---|---|
| observation | a measured value with its declared noise, source and evidence digest | evidence; immutable once recorded; an estimator only reads it |
| belief (state estimate) | state vector and covariance at a generation | derived; carries model identity, parent digest and evidence root |
| prediction | a belief propagated forward, plus the predicted observation distribution | never an observation, never overwrites one |
| innovation | observation minus predicted observation, its covariance, normalized squared surprise | a number, never a proof |
| model | transition model and observation model | identity is the digest of its canonical encoding |

```text
estimate      != fact
prediction    != observation
confidence    != authority
probability   != permission
surprise      != proof
```

Each record is a separate type with a separate kind byte and a separate digest domain, so bytes of one kind cannot be decoded or digested as another. Digests follow the TURING rule: SHA-256(domain, 0x00, encoding).

### 2.2 Ownership does not move

| Faculty | Keeps |
|---|---|
| ARGUS | observes and detects (ARCH-0017) |
| Estimator | estimates; consumes observations; owns no observation |
| Omega | models and realizes; the cost model stays the one cost model |
| J-Space | compares alternatives; uncertainty is one more dimension, never a collapsed score |
| AEGIS | authorizes; reads no estimator output as an authority input |
| Effect Broker / physical authority | executes |
| World | commits operational state; estimated state enters only after EST-3 passes |
| TURING / provenance | records and scores predictive evidence |
| Cortex | keeps epistemically significant events as claims, never every estimator tick |

### 2.3 The estimation layer must never

mint capabilities; authorize effects; grant credentials; change AEGIS policy; commit an irreversible external effect; promote its own model; rewrite raw evidence; silently discard contradictory observations; convert probability into authority; declare an estimated state to be observed fact.

Enforcement: estimator object files are built by their own `mk/estimation.mk` and refused if `nm -u` shows any authority, World, generation, capability, ARGUS, FORGE, memory-mapping, process or file operation (the cost-model pattern, omega `Makefile:716-720`). The pluggable `AienosContainAuthorizer.decide` hook (aienos `aienos_contain.h:223-227`) must never be given an estimator-derived verdict. ARGUS's reserved `STATISTICAL` confidence class is not fed by estimator output without a separate decision.

### 2.4 Estimators behind one contract

```text
Estimator
  linear Kalman         EST-1 (only one built now)
  extended Kalman       only after a benchmark shows a nonlinearity the linear filter misses
  unscented Kalman      only after a benchmark shows the Jacobian route is inadequate
  particle              only after a benchmark shows non-Gaussian / multimodal failure
  Omega-synthesized     only after a benchmark shows recurring unexplained structure
```

A new estimator enters only with a named failure class of the previous one, the same calibration protocol, and a head-to-head comparison. Mathematical sophistication earns no production influence.

## 3. Placement and the R16 boundary

The sequence becomes:

```text
R16 (migration closure)
  -> post-R16 convergence
  -> BELIEF / ESTIMATION FOUNDATION (EST-0 .. EST-3)
  -> calibrated predictive state in World and the cost model (EST-4, EST-5)
  -> TURING predictive evaluation (EST-6)
  -> J-Space uncertainty-aware reasoning (EST-7)
  -> Cortex predictive abstraction (EST-8)
  -> innovation as curiosity signal, information-gain experiments (EST-9, EST-10)
  -> Evolution Arena
  -> Physics Zero
```

R16 is not interrupted. EST-0 to EST-3 may run before R16 closes **only** as a standalone module with zero runtime linkage: new files under `omega/src/estimation/` and `omega/tests/estimation/`, its own `mk/estimation.mk` targets, not in `all`, not in `test`, not included by anything under `src/runtime/`. This is more than schema work and is allowed only because it has no production coupling. EST-4 onward edits World, the cost model or runtime paths and waits for R16 closure and the `src/runtime/` hold to lift.

## 4. Reuse, not duplication

- Cost model: EST-5 extends `RxCmPrediction` (mean, sd, dof, fail_p) to accept an estimated input with uncertainty. There is no second cost model.
- TURING: EST-6 emits PRD1 predictions and lets qint.v1 score them. Innovation ("how surprising was this observation under the current state model?") and Turing gain ("did this explanation improve held-out compression after paying for its complexity?") stay separate quantities.
- CAL-0: EST-3 reuses its freeze-then-evaluate discipline and receipt style.
- World: EST-4 reuses `RxObjRef` generations and field versions for staleness; covariance encoding is decided there, since a World object holds eight u64 fields.
- `rx_semcomm.h:26` ("Omega does not estimate uncertainty; a type may declare its producer's uncertainty") stays true: the estimation layer is such a producer, and semcomm remains a transport.
- ARCH-0018 AR3 characterizes substrates; an AR3 calibration artifact may supply observation noise to an estimator model. Neither replaces the other.

## 5. Gates

| Stage | Exit token | Requires |
|---|---|---|
| EST-0 | `ESTIMATION_SEMANTIC_CONTRACT = PASS` | typed records, validation (finite, dimensions, symmetric, PSD, declared units), digests, exact serialization round trip, kind confusion refused, staleness detectable, property tests |
| EST-1 | `LINEAR_KALMAN_REFERENCE = PASS` | predict / update (Joseph form), deterministic, bounded, no hidden state; analytic cases and an independent information-form reference written without reading the implementation |
| EST-2 | `ESTIMATION_REAL_SIGNAL = PASS` | one real AIEN signal replayed strictly causally from digest-bound raw evidence; raw observations preserved; prediction then later observation then innovation |
| EST-3 | `ESTIMATION_CALIBRATION = PASS` | protocol frozen before evaluation; noise fitted on one segment, scored on another; NIS against chi-square, interval coverage with binomial bounds, bias, drift, autocorrelation, regime breakdown; baseline comparison. A failure is recorded and the estimator is not promoted |
| EST-4 | `WORLD_BELIEF_STATE = PASS` | after R16; estimated state explicit in World, only where uncertainty is meaningful |
| EST-5 | `OMEGA_ESTIMATION_INTEGRATION = PASS` | cost model treats `111 GB +/- 8` differently from `111 GB +/- 0.1` near a hard limit; no universal penalty |
| EST-6 | `TURING_ESTIMATION_EVIDENCE = PASS` | model, prediction distribution, observation, innovation, calibration, score |
| EST-7 | `JSPACE_BELIEF_INTEGRATION = PASS` | uncertainty dimensions added without collapsing existing ones; information gain is never permission |
| EST-8 | `CORTEX_PREDICTIVE_MEMORY = PASS` | significant events become claims under existing promotion rules |
| EST-9 | `INNOVATION_CURIOSITY_SIGNAL = PASS` | persistent, structured, out-of-calibration innovation opens a hypothesis, not a silent refit |
| EST-10 | `ACTIVE_INFORMATION_GAIN = PASS` | information-gain experiment selection beats a defined baseline on a controlled benchmark; J-Space proposes, AEGIS authorizes |

Every gate gets a hostile review that tries to show, at least: the filter only smooths and is not calibrated; uncertainty is numerically invalid; future information leaks into the replay; noise was tuned on the test sequence; raw evidence was overwritten; prediction and observation are conflated; confidence is treated as authority; innovation thresholds create false discoveries; covariance collapses numerically; the test is circular; a simpler baseline does as well. Failures stay as evidence; qualification tests are not tuned until a feature passes.

## 6. Doctrine wording to tighten (separate change)

Recorded in the current-state document section 4: the observation **record** is immutable ground truth while the value is noisy evidence (`AIEN.md:534`); Bayesian confidence scores never grant authority or promotion (`AIEN.md:533`); Cortex keeps significant events while live estimates live in the estimation layer and World (`doctrine/ARCHITECTURE.md:55,160`); receipts record measured ground truth, not estimates (`doctrine/ARCHITECTURE.md:75`).

## 7. Success criterion for the whole workstream

AIEN can state from replayable evidence: at generation G it believed physical state X with uncertainty U using estimator M and evidence root E; it predicted observation Y with predicted uncertainty V; reality produced Z; the innovation was I; under the calibrated model that residual had surprise S; the observation caused belief update B; and a persistently unexplained innovation produced a hypothesis for evaluation instead of forcing reality to fit the old model.
