# ADR 0023: DIRAC-0 Program (Integration Workstream)

**Status:** PROPOSED, 2026-10-01. Source: operator brief of that date (Drake Stapleton). Not accepted until the operator accepts it.
**Gate:** `DIRAC_PREP_FROZEN` (proposed by `docs/plans/dirac/DIRAC-0-SPEC.md`). No sealed experiment may run before it passes.
**Supersedes:** nothing. **Amends:** nothing. **Extends:** ARCH-0020 (belief and estimation) and the TURING, FORGE and Physics Zero lines by adding one test subject that exercises them together.
**Related:** ARCH-0016 (resident reaction architecture), ARCH-0017 (ARGUS observes, never authorizes), ARCH-0019 (mixed algebra realization), ARCH-0020 (belief estimation layer), ARCH-0021 (decision 3: append-only receipts bound to clean commits), ARCH-0022 (canonical Cortex owner).
**Workstream:** DIRAC-0, PRs D-01 to D-14 (spec section 14); supporting documents in [`docs/plans/dirac/`](../plans/dirac/) (NOT A MASTER PLAN). Sequencing stays in `CURRENT_EXECUTION_PLAN.md`.

Citation note: in this repository "ADR 0023" and ARCH-0023 name the same decision. In other repositories cite it as ARCH-0023.

---

## 1. Context

AIEN needs a hard, checkable test of two claims: that Omega can represent non-trivial physical algebra from generic parts, and that the Physics Zero machinery can find structure from numbers alone. The Dirac equation is a good subject because it has exact algebraic structure (a Clifford relation), analytic solutions, and a known answer held by humans, not by AIEN.

The risk is in how it would be built. Adding Dirac-specific types would prove nothing, and a new tensor, measurement, GPU or evidence system would fork work already in flight (OSC-2, E1, M20, ESTIMATION, TURING, FORGE).

## 2. Decision

```text
DIRAC-0 IS AN INTEGRATION WORKSTREAM. IT CONSUMES OSC-2, E1, M20, ESTIMATION,
TURING AND FORGE. IT CREATES NO NEW TENSOR SYSTEM, MEASUREMENT SYSTEM,
GPU RUNTIME OR EVIDENCE SYSTEM. DIRAC IS A CONFORMANCE FIXTURE AND HIDDEN
EVALUATOR KNOWLEDGE, NEVER AN OMEGA PRIMITIVE.
```

The ten rules, the three gates (D0 generic algebra, D1 realization on CPU then Blackwell, D2 blind discovery), the secrecy boundary, the measurement profile and the receipt shape are in the spec. This ADR does not restate them and does not weaken them.

## 3. Consequences

- Work that would stop OSC-2 or fork E1 is out of scope.
- D0.1 (complex values) is new generic Omega work, because M20 has no complex element type. It must be justified as a generic capability, not as Dirac support.
- Evaluator material (equation, gamma matrices, oracle, answer keys) lives outside everything AIEN can read. The oracle shares no code with the Omega candidate.
- D2 sealing depends on the operator completing G3 sealing (BLOCKED_OPERATOR today).
- The spec defines "net Turing gain" as T minus declared search and compute cost. That term does not exist elsewhere yet and is a new DIRAC-0 definition pending TURING owner review.
- The spec adds BLOCKED_HARDWARE to the verdict vocabulary.

## 4. Evidence checked on 2026-10-01

- No complex type: grep for `_Complex`, `complex64`, `OMEGA_DT_C` over omega `src/` and `docs/` finds nothing; M20 `OmegaDType` is F32, F16, BF16 (`aien-dev/omega#136`, draft).
- No Physics Zero loop document exists in omega or aien-architecture.
- ESTIMATION v4: INCONCLUSIVE (omega#153 merged 2026-10-01); v5 in progress (omega#170, open). It is not cited as PASS anywhere in DIRAC-0.
- `aien-dev/omega#152` (GB10 DIV/SQRT) is merged at `07004a8`.

## 5. Status of alternatives not taken

- A Dirac module or Dirac builtins in Omega: rejected by rule 1.
- A separate DIRAC tensor or evidence format: rejected; M20, TURING and FORGE records are used.
- Letting the candidate choose its holdout or score itself: rejected by rule 8.

## 6. Placement of the oracle and sealed material

Omega is readable by AIEN. The omega `research/dirac-oracle/` directory therefore holds only the public conformance corpus (textbook algebra fixtures for D0). Sealed experiment parameters, answer keys and the sealed generator stay in private evaluator storage and never enter an AIEN-readable repository. The operator confirms this placement before D-11 (BLOCKED_OPERATOR). Source: external review finding, 2026-10-01.

## 7. C2S reframing (Drake addendum, 2026-10-01)

DIRAC-0 is reframed as mathematical invention under physical constraint, not equation rediscovery. The AIEN-facing ladder becomes D-1 (prove simpler representation classes inadequate), D0 (discover and represent the richer algebra), D1 (realize physically), D2 (discover a predictive theory from observations), D3 (sealed novel prediction). The evaluator-side generic Omega capability work (spec wave 1) stays and is a prerequisite. AIEN is never handed complex numbers, matrices, noncommutativity, spinors, tensors, gamma matrices or any other listed structure (spec section 16 has the full list); the evaluator-side fixtures in spec sections 4 and 11 are never exposed to AIEN. The C2S benchmark family and its gates are owned by the Physics Zero Atlas V1 section (Lane 36); DIRAC-0 cites them by name and defines none. Details: spec section 16. Source: `~/handoffs/physics-zero/PZ-C2S-ADDENDUM-DRAKE-BRIEF.md`.
