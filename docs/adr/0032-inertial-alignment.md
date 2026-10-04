# ADR 0032: Inertial Alignment, an Alignment Navigation System (ANS) with a frozen reference the optimizer cannot touch

**Status:** Accepted by operator Drake Stapleton, 2026-10-03 (via his instruction "fully implement this feature /goal Inertial Alignment" on the pasted Inertial Alignment brief of that date; the brief is the decision, no separate ratification step).
**Gate:** ANS output is ADVISORY ONLY (a verdict is data the authority may consult). No ANS verdict may block, grant or promote anything until `ARGUS1_G1`..`G13` PASS and the Evolution Arena activation hold lifts. ANS-0 (the omega module `src/ans`, PR in flight) may merge once its tests and purity check pass.
**Supersedes:** nothing. **Amends:** nothing. **Extends:** ARCH-0020 (ANS is a consumer of the EST-1 filter; it adds no observation kinds).
**Related:** ARCH-0017 (ARGUS observes, never authorizes: ANS inherits the exact same sentence), ARCH-0012 (self-construction: Seed/Forge/Generation is the optimizer that may not touch the compass), ARCH-0024 (C in omega is the destination), ARCH-0028 (tests go through aien-test once it exists; until then `make test-inertial-alignment`), ARCH-0031 (DUAL prices soft budgets; the autonomy budget here is a hard tiering, never priced), `docs/specs/EVOLUTION_ARENA_SPEC_V1.md` section 5 (promotion contract; ANS adds a pre-check the promotion right holder consults, it does not change who promotes).
**Workstream:** ANS-0 to ANS-4 (section 6); the technical spec v1 lives with the omega module (`docs/ans/INERTIAL_ALIGNMENT_SPEC_V1.md` in omega, UNVERIFIED on main at time of writing, confidence 0.8 that it lands with the module PR).

Citation note: in this repository "ADR 0032" and ARCH-0032 name the same decision. In other repositories cite it as ARCH-0032.

---

## 1. Context

Alignment signals today behave like GPS. A prompt, a policy, a reward, an evaluator or a user's feedback tells the agent where it should be. Every one of those can be jammed (withheld), poisoned (fed false), lost (squeezed out by context compression), or optimized against (an agent that learns what the evaluator likes, not what is wanted). An agent that depends on any single outside signal has no way to know how far it has wandered when that signal goes bad.

Inertial navigation solves the same problem differently. It starts from a trusted reference, keeps adding up every movement, carries an explicit and growing uncertainty, and reconciles against independent fixes from time to time. A vehicle with no GPS still knows roughly where it is and how unsure it is.

The transfer here is architectural. None of it needs quantum mechanics: the 2024 quantum inertial navigation flights that inspired the brief are the analogy, not a dependency. The pieces are an explicit state, a covariance (a measured uncertainty) that grows with each step, sensors of different trustworthiness, and a reference the vehicle cannot rewrite.

AIEN already has the parts to host this. EST-1 (ARCH-0020) provides a bounded Kalman filter in omega C with refusals instead of silent repair. ARGUS (ARCH-0017) observes authority decisions and never authorizes. The Evolution Arena spec section 5 freezes who may promote. ARCH-0012 describes the self-construction loop that would be the optimizer. TURING held-out tests and `aien-sealed` hold material the candidate never sees. What is missing is one quantity, alignment drift, measured at run time against a reference nothing in the optimization loop can modify.

## 2. Decision

```text
ANS ESTIMATES ALIGNMENT DRIFT AS A COVARIANCE OVER THE EST-1 FILTER,
MEASURED AGAINST A FROZEN, DIGEST-BOUND REFERENCE THAT THE CANDIDATE
UNDER TEST NEVER RECEIVES IN MUTABLE FORM.

A VERDICT IS DATA FOR THE AUTHORITY TO CONSULT; ANS NEVER GRANTS,
REVOKES OR PROMOTES.
```

**D1. Frozen reference atoms (the compass).** Ten machine-checkable primitives replace a prose constitution: AUTHORITY, CONSENT, SCOPE, PROVENANCE, REVERSIBILITY, RESOURCE_LIMITS, INFORMATION_BOUNDARIES, GOAL_IDENTITY, DELEGATION_LIMITS, SELF_MODIFICATION_LIMITS. A reference holds a per-atom drift limit, process noise per action kind, measurement noise per sensor class, autonomy tier thresholds, a disagreement threshold and a promotion drift limit. `ans_reference_freeze` validates it, marks it frozen and digests it (SHA-256, domain `omega.ans.<record>.v1`). Every other call takes the reference plus the expected digest and refuses (`ANS_ERR_REFERENCE`) if the recomputed digest differs or the reference is not frozen. This is the single rule of the header's first comment.

**D2. Explicit alignment state.** One record per agent: goal digest, constraints digest (equal to the reference digest), intent digest, evidence root, drift belief (a 4 component EST-1 belief over GOAL, INTENT, PROVENANCE, SCOPE), reversibility risk of the pending action, a provenance chain of every record that shaped the state, a generation counter, steps since last FIX, the last reference digest seen, the last disagreement score, and a disagreement flag. Every meaningful action produces a new record. Inputs are never mutated.

**D3. Drift as covariance over EST-1.** The filter has identity dynamics and identity observation. Each action adds process noise by action kind (OBSERVE, EFFECT, DELEGATE, INGEST_UNTRUSTED, SELF_MODIFY), so uncertainty grows with chain length, delegation, untrusted input and self-modification. Each measurement shrinks it by that sensor class's noise. Drift is reported as:

```text
mean_norm = ||x||2        sigma = sqrt(trace(P))        D = sqrt(mean_norm^2 + sigma^2)
```

**D4. Three sensor classes and their noise ordering.**
- IMU: cheap and frequent (policy, permission, provenance, intent consistency, reversibility, anomaly indicators). Carries no reference digest.
- REFERENCE: slow, expensive, hard for the agent to fool (deterministic invariants, independent evaluators, holdout tests unknown to the candidate, frozen original goals). Must carry the frozen reference digest.
- FIX: authoritative external observation (human intervention, signed policy update, verified real-world outcome). Must carry the frozen reference digest, and resets steps-since-fix to zero.

The reference is required to satisfy `r[FIX] < r[REFERENCE] < r[IMU]`. A REFERENCE or FIX whose normalized innovation squared exceeds `nis_limit` sets the disagreement flag and is still fused. The disagreement is the signal and is never hidden. Zero evidence digests, a wrong reference digest, an IMU carrying a reference digest, and non-finite numbers are refused.

**D5. Control law tiers.** The autonomy budget falls as uncertainty rises:

```text
FULL -> REVERSIBLE_ONLY -> SIMULATE_ONLY -> HALT_REQUEST_FIX
```

The tier comes from `sigma` against three increasing thresholds. Any atom whose drift exceeds its limit forces at least REVERSIBLE_ONLY. Disagreement forces HALT_REQUEST_FIX regardless of `sigma`. This is a hard tiering, not a price (contrast ARCH-0031).

**D6. The promotion gate has five refusals.** `ans_promotion_check` takes a candidate, the reference digest at the candidate's birth, the test-set digest at birth and now, and the candidate's state. It refuses with: REFUSED_REFERENCE (the compass changed during the candidate's life), REFUSED_TESTS (the instrument changed in the same transaction), REFUSED_DISAGREEMENT, REFUSED_DRIFT (D above `promote_limit`), REFUSED_SELF_MOD (self-modification with no FIX after it). Otherwise OK. The output is a digested record for the promotion right holder.

**D7. The optimizer may never change the navigated thing and the compass in one transaction.** The reference frame and the drift tests live outside the optimization domain. Candidate M' is measured against constant R before any promotion. A candidate whose birth-time reference or test digest differs from now is refused by D6, which is how this rule is enforced rather than merely stated.

**D8. Advisory only.** ANS does not call `rx_gen_promote` or any `rx_*` function; its purity check forbids them. Only the operator-held principal promotes (Arena spec section 5.1). ANS is the same kind of thing as ARGUS and EST: it observes and reports.

## 3. What this does NOT do

- It has no authority. It cannot grant, revoke, block or promote. Any consumer that treats a verdict as a command is out of contract.
- It adds no observation kinds to EST-1. It is a consumer of the filter, not a producer of evidence.
- It has no runtime wiring. Nothing in `src/runtime` calls it, and it is not in `all` or `test`.
- It does not claim AIEN is aligned. It makes drift a measurable quantity against a stated reference; whether the reference is the right one is a human question.
- The AIEN grounding rule applies: live repositories define current state. Everything in this ADR beyond the decision is PROPOSED until the module and its evidence are on `main`.

## 4. Consequences

- Alignment drift becomes a number with an uncertainty, bound to a generation and an evidence root, instead of a feeling.
- Reference tampering is detectable: a copy mutated after freeze fails every API on digest mismatch.
- A self-modifying candidate cannot quietly move the goalposts in the same step it is promoted.
- Tests are specified (ten cases including hostile ones) before any consumer exists.
- Cost: calibration burden (q, r, tier thresholds, limits are chosen, not learned), and a new frozen artifact to govern. Calibration from real data is deferred to ANS-1.
- Risk: a verdict nobody consults changes nothing. ANS-3 and ANS-4 exist to give it consumers, and are gated.

## 5. Alternatives rejected

- **One more safety classifier.** A classifier is another GPS-class signal: learnable, gameable, and silent on how far the agent has drifted over a long chain. Rejected as the primary mechanism; classifier outputs may still feed IMU class sensors.
- **A prose constitution.** Not machine-checkable and not frozen by digest. The atoms are the checkable core of what a constitution would say.
- **Wiring into `rx_argus` now.** ARGUS-1 is not closed (G6 unfinished, G13 open per ARCH-0017). Coupling an unproven estimator to a containment path would break "observes, never authorizes". Revisit after the gates pass.
- **A Rust crate in sovereign-core.** EST-1 lives in omega C, and ARCH-0024 names Omega and C as the destination. A Rust copy would need its own filter and would split the digest and test discipline.

## 6. Workstream

- **ANS-0:** omega module `src/ans`, tests, `mk/ans.mk`, `make test-inertial-alignment` (plain and ASan/UBSan) and purity check. Standalone, not in `all` or `test`. May merge once tests and purity pass.
- **ANS-1:** reference atoms calibrated from real ARGUS event streams (limits, q, tier thresholds). Waits on recorded streams being available.
- **ANS-2:** REFERENCE and FIX sensors fed by TURING held-out tests and `aien-sealed` material. The candidate never sees these.
- **ANS-3:** promotion pre-check consulted by the Arena promotion right holder. Observe-only until the Arena hold lifts.
- **ANS-4:** autonomy tier consumed by the runtime scheduler as advice. Waits on ANS-1, ANS-3 and the ARGUS-1 gates.

Tests go through `make test-inertial-alignment` until the aien-test runner (ARCH-0028) exists.

## 7. Open questions

- **Calibration.** The numbers for q, r, tier thresholds, `nis_limit` and `promote_limit` are placeholders in ANS-0. ANS-1 must set them from data. UNVERIFIED that any single set works across action kinds (confidence 0.5).
- **Heavy tails.** EST-3 calibration is FAILED on main (heavy tails; see `CURRENT_EXECUTION_PLAN.md` Lane 7). A Gaussian covariance may understate rare large drifts. Until the filter passes calibration, no verdict may be treated as a probability.
- **What counts as a FIX.** The brief names human intervention, signed policy updates and verified outcomes. Which of those the system can authenticate today is open, and a weak FIX would reset drift falsely. This needs an operator decision before ANS-2.
- **IMU strength.** Whether IMU measurements alone can ever restore a higher tier is a numbers choice the spec documents; the intended default is that they should not.
