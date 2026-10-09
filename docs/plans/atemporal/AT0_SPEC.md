# AT0_SPEC: Mathematical contract for the AT-0 reference model

**Status:** DRAFT for independent review. Not a frozen interface (charter section 8). No code implements it yet; program status is NOT_RUN.
**Written:** 2026-10-09 by Agent 1 (mathematical correctness), against the frozen contracts at aien-architecture `044c9d1` and the amended charter at `d390939`.
**Scope:** the minimal Page-Wootters-style model named in the AT-0 Agent 1 brief: a two-level clock, a two-level system, one stationary global state, and a finite covariant clock POVM. Everything here is derived by hand and checked numerically in a scratch C program (section 12); nothing here is a physical claim.

**Reading guide.** Sections 1 to 6 are the mathematics (definitions, theorems, proofs). Sections 7 to 10 turn the mathematics into invariants, tolerances, negative controls and tests. Section 11 says which conclusions follow from the construction and which would need an experiment. Section 12 lists discrepancies and the mapping onto `AT0_CASE_V1`. Section 13 holds the hand-derived answer table for every case class of charter section 6.

## 0. Conventions

- Units: hbar = 1. `omega > 0` is the single energy scale. All times are in units of `1/omega`.
- Qubit basis `|0>, |1>`. Pauli matrices in this basis:
  `X = [[0,1],[1,0]]`, `Y = [[0,-i],[i,0]]`, `Z = [[1,0],[0,-1]]`, so `Z|0> = +|0>`.
  Eigenvectors: `|X+> = (|0>+|1>)/sqrt2`, `|Y+> = (|0>+i|1>)/sqrt2`, `|Z+> = |0>`; the `-` eigenvectors are the orthogonal complements.
  Projectors `Pi_{A,+} = (I + A)/2`, `Pi_{A,-} = (I - A)/2` for `A` in `{X, Y, Z}`.
- Tensor products are written clock first: `|c>_C |s>_S = |c s>`, and the four basis vectors are ordered `|00>, |01>, |10>, |11>` (clock index major). This matches `constraint SUM_HC_HS` in AT0_CASE_V1 section 3.
- `<a|b>` is the inner product, antilinear in the first slot. `||v||` is the Euclidean norm. `||A||_F` is the Frobenius norm, `||A||_op` the operator (spectral) norm.
- A POVM is a finite set of positive semidefinite operators that sum to the identity. "Effect" means one of them.

## 1. The reference model

**Definition 1.1 (Hamiltonians).** On the clock, `H_C = diag(0, -omega)`, that is `H_C|0>_C = 0` and `H_C|1>_C = -omega|1>_C`. On the system, `H_S = diag(0, +omega)`, that is `H_S|0>_S = 0` and `H_S|1>_S = +omega|1>_S`. The total (constraint) Hamiltonian is

    H_total = H_C (x) I_S + I_C (x) H_S.

In the Pauli form of AT0_CASE_V1, `H_S = (omega/2) I - (omega/2) Z`, so `h0 = omega/2`, `hx = hy = 0`, `hz = -omega/2`. Note the sign of `hz`: the system's higher energy sits on `|1>`.

**Definition 1.2 (global state).**

    |Psi> = (|0>_C|0>_S + |1>_C|1>_S) / sqrt2 = (|00> + |11>) / sqrt2.

`|Psi>` is normalized and entangled (its reduced states are `I/2` on each factor).

**Definition 1.3 (clock phase states and labels).** For `N >= 3` and a declared real phase offset `phi`, let

    theta_k = phi + 2 pi k / N,        k = 0, 1, ..., N-1,
    |theta_k> = (|0>_C + exp(i theta_k) |1>_C) / sqrt2.

`theta_k` is an internal clock phase label. `phi` is declared data, part of the question, not a computed quantity. The label index `k` is the only thing a run conditions on.

**Definition 1.4 (clock POVM).**

    E_k = (2/N) |theta_k><theta_k|,     k = 0, ..., N-1.

Each `E_k` is rank one and positive semidefinite with eigenvalues `{2/N, 0}`.

**Definition 1.5 (what is measured).** For each clock label `k` and each Pauli axis `A` in `{X, Y, Z}` and sign `s` in `{+, -}`, the joint probability

    P(k, A, s) = <Psi| (E_k (x) Pi_{A,s}) |Psi>,

the clock marginal `p_k = sum_s P(k, A, s) = <Psi| (E_k (x) I_S) |Psi>` (independent of `A`), and the conditional probability `P(A, s | k) = P(k, A, s) / p_k` when `p_k > 0`.

Nothing in Definitions 1.1 to 1.5 contains a time parameter. The model is a state, a constraint operator, and a measurement.

## 2. Theorem 1: the Hamiltonian constraint

**Theorem 1.** `H_total |Psi> = 0`. More precisely, `ker H_total = span{|00>, |11>}`, which has dimension 2, and `|Psi>` lies in it.

**Proof.** `H_total` is diagonal in the product basis because `H_C` and `H_S` are diagonal. Its diagonal entries are the sums of clock and system energies:

| basis vector | clock energy | system energy | total |
|---|---|---|---|
| `|00>` | 0 | 0 | 0 |
| `|01>` | 0 | `+omega` | `+omega` |
| `|10>` | `-omega` | 0 | `-omega` |
| `|11>` | `-omega` | `+omega` | 0 |

So `H_total = diag(0, omega, -omega, 0)`, its kernel is spanned by `|00>` and `|11>`, and `H_total|Psi> = (0 + 0)/sqrt2 = 0`. Qed.

**Corollary 1.1 (exact stationarity).** For every real `t`, `exp(-i H_total t)|Psi> = |Psi>`. Proof: the exponential of a diagonal operator acts on each kernel vector by `exp(0) = 1`. Hence any external evolution parameter applied to the global state is unobservable: every probability in Definition 1.5 is the same function of `k` before and after. This is the precise sense in which the model has no fundamental external time.

**Corollary 1.2 (general kernel state).** Every physical state has the form `|Psi_{a,b}> = a|00> + b|11>` with `|a|^2 + |b|^2 = 1`. The reference state is `a = b = 1/sqrt2`. Section 6 uses this family for controls.

**Remark 1.3.** `||H_total||_op = omega` (eigenvalues `0, +omega, -omega, 0`). Section 8 normalizes the constraint residual by it.

## 3. Theorem 2: the clock POVM

**Lemma 2.1 (nonorthogonality).** For labels `j, k`,

    <theta_j|theta_k> = (1 + exp(i (theta_k - theta_j))) / 2,
    |<theta_j|theta_k>|^2 = cos^2( (theta_k - theta_j) / 2 ) = cos^2( pi (k - j) / N ).

Proof: expand the inner product using `<0|0> = <1|1> = 1`, `<0|1> = 0`; the modulus follows from `|1 + exp(i x)|^2 = 2 + 2 cos x = 4 cos^2(x/2)`. Qed.

Two phase states are orthogonal only when `(k - j)/N = 1/2`, that is only when `N` is even and the labels are antipodal. For `N >= 3` every label has at least one other label it does not distinguish perfectly (for `N = 3` every pair has overlap `|<theta_j|theta_k>|^2 = 1/4`). **The phase states are not an orthonormal basis and must not be described as one.** Consistently, `E_k^2 = (2/N) E_k`, so the effects are projectors only when `N = 2`.

**Theorem 2 (resolution of the identity).** For every integer `N >= 2` and every `phi`, `sum_{k=0}^{N-1} E_k = I_C`.

**Proof.** Write `|theta_k><theta_k|` in the clock basis:

    |theta_k><theta_k| = (1/2) [ |0><0| + |1><1| + exp(-i theta_k) |0><1| + exp(i theta_k) |1><0| ].

Summing over `k` and multiplying by `2/N`:

    sum_k E_k = (2/N) (N/2) (|0><0| + |1><1|) + (1/N) [ S* |0><1| + S |1><0| ],   S = sum_k exp(i theta_k).

Now `S = exp(i phi) sum_{k=0}^{N-1} exp(2 pi i k / N)`, a full set of `N`-th roots of unity, whose sum is `0` for `N >= 2` (geometric series: `(1 - exp(2 pi i)) / (1 - exp(2 pi i / N)) = 0`, the denominator being nonzero for `N >= 2`). Hence `sum_k E_k = I_C`. Qed.

**Remark 2.2 (why N >= 3).** Theorem 2 already holds at `N = 2`, but then the two effects are orthogonal projectors and the "clock" is an ordinary projective measurement, which does not exercise the nonorthogonal (relational, imperfectly resolving) character the brief asks for. Section 9 gives a second, independent reason: with `N = 2` and `phi = 0` the Pauli Y test has no power. The model therefore requires `N >= 3`.

**Remark 2.3 (covariance).** `exp(-i H_C s)|theta> = (|0> + exp(i (theta + omega s))|1>)/sqrt2 = |theta + omega s>`. The clock Hamiltonian moves a phase state along the phase circle at rate `omega`. This is what makes the phase label a clock reading rather than an arbitrary label, and it is also why a two-level clock can only read phase modulo `2 pi`: readings `theta` and `theta + 2 pi` are the same state.

## 4. Theorem 3: the conditional system state (Born rule)

**Lemma 3.1 (clock marginal).** `p_k = 1/N` for every `k`.

**Proof.** Define the unnormalized conditional vector `|phi_k> = (<theta_k|_C (x) I_S) |Psi>`. Using `<theta_k|0> = 1/sqrt2` and `<theta_k|1> = exp(-i theta_k)/sqrt2`,

    |phi_k> = (1/sqrt2) [ <theta_k|0> |0>_S + <theta_k|1> |1>_S ] = (1/2) ( |0>_S + exp(-i theta_k) |1>_S ).

Then `<Psi|(E_k (x) I)|Psi> = (2/N) <phi_k|phi_k> = (2/N) (1/4)(1 + 1) = 1/N`. Qed.

The clock outcomes are uniform. Because `sum_k p_k = 1` is exactly Theorem 2 evaluated on `|Psi>`, a POVM normalization error shows up as a probability-sum error (charter cases N3, N4).

**Theorem 3 (conditional state).** For every `k`, the conditional probabilities of Definition 1.5 are those of the pure system state

    |psi_k> = (|0> + exp(-i theta_k) |1>) / sqrt2,

that is `P(A, s | k) = <psi_k| Pi_{A,s} |psi_k>`.

**Proof.** `P(k, A, s) = <Psi|(E_k (x) Pi_{A,s})|Psi> = (2/N) <phi_k| Pi_{A,s} |phi_k>`, because `E_k = (2/N)|theta_k><theta_k|` and `(<theta_k| (x) I)|Psi> = |phi_k>`. Dividing by `p_k = (2/N)<phi_k|phi_k>` gives `P(A, s | k) = <phi_k|Pi_{A,s}|phi_k> / <phi_k|phi_k> = <psi_k|Pi_{A,s}|psi_k>` with `|psi_k> = |phi_k>/||phi_k|| = sqrt2 |phi_k>`. Qed.

**Remark 3.2 (no post-measurement convention is needed).** `P(k, A, s)` is a joint Born probability of two commuting effects, `E_k (x) I` and `I (x) Pi_{A,s}`. It does not depend on any choice of Kraus operators or post-measurement state for the clock. The conditional state `rho_k = |phi_k><phi_k| / <phi_k|phi_k>` is pure because `E_k` is rank one and `|Psi>` is pure; for a higher-rank effect or a mixed global state the conditional state would be mixed and Theorem 3 would be stated for `rho_k` only.

**Remark 3.3 (general kernel state).** For `|Psi_{a,b}> = a|00> + b|11>`, the same computation gives `|phi_k> = (a|0> + b exp(-i theta_k)|1>)/sqrt2`, so `p_k = (|a|^2+|b|^2)/N = 1/N` for every kernel state, and `|psi_k> = a|0> + b exp(-i theta_k)|1>`. The clock marginal does not see `a, b`; only the conditional system statistics do.

## 5. Theorem 4: Pauli probabilities and the Schrodinger comparison

**Theorem 4 (expected observables).** For the reference state and every `k`:

    <X>_k = cos theta_k,     <Y>_k = -sin theta_k,     <Z>_k = 0,
    P(X+|k) = (1 + cos theta_k)/2,   P(Y+|k) = (1 - sin theta_k)/2,   P(Z+|k) = 1/2,

and `P(A-|k) = 1 - P(A+|k)` for each axis.

**Proof.** Write `|psi_k> = (|0> + exp(i alpha)|1>)/sqrt2` with `alpha = -theta_k`. Its Bloch vector is `(cos alpha, sin alpha, 0)`: `<X> = Re(exp(i alpha)) = cos alpha`, `<Y> = Im(exp(i alpha)) = sin alpha`, `<Z> = (1 - 1)/2 = 0` (direct computation: `<psi|X|psi> = (exp(i alpha) + exp(-i alpha))/2`, `<psi|Y|psi> = (-i exp(i alpha) + i exp(-i alpha))/2 = sin alpha`). Substitute `alpha = -theta_k`, and use `P(A+) = (1 + <A>)/2`. Qed.

**Lemma 4.1 (parity in the phase).** `P(X+|k)` and `P(Z+|k)` are even functions of `theta_k`; `P(Y+|k)` is odd about `1/2` (`P(Y+|k)(-theta) = 1 - P(Y+|k)(theta)`). Therefore any error that replaces `theta_k` by `-theta_k` (a missing complex conjugate, a reversed sign of `omega` in one factor, a reversed reference evolution) is invisible to X and Z and visible to Y. This is the mathematical basis of the Y tests in section 9.

**Theorem 5 (agreement with conventional quantum mechanics).** Let `t_k = theta_k / omega`. Ordinary Schrodinger evolution of the system alone, started in `|X+> = (|0>+|1>)/sqrt2` under `H_S` for time `t_k`, gives

    exp(-i H_S t_k) |X+> = (|0> + exp(-i omega t_k)|1>)/sqrt2 = |psi_k>,

so every conditional probability of Theorem 4 equals the conventional prediction `<X+| exp(+i H_S t_k) Pi_{A,s} exp(-i H_S t_k) |X+>`. For the general kernel state of Remark 3.3, `|psi_k> = exp(-i H_S t_k)(a|0> + b|1>)`, with initial system state `a|0> + b|1>`.

**Proof.** `exp(-i H_S t)` is `diag(1, exp(-i omega t))`; apply it to `|X+>` and compare with Theorem 3. Qed.

**Remark 5.1 (what the identification `t_k = theta_k/omega` is).** It is a dictionary between two descriptions, introduced only to compare them. On the relational side there is no `t`: the engine computes from `|Psi>` and `{E_k}` alone and outputs a table indexed by `k`. On the conventional side the oracle computes from `H_S`, `|X+>` and the declared readings `t_k`. Theorem 5 says the two tables agree. The global state is never evolved (Corollary 1.1), and the `t_k` never enters the engine. In the charter's words, the clock reading is declared data of the question, not an execution coordinate.

**Remark 5.2 (sign convention and the charter example).** AT0_CASE_V1 section 6 uses `H_S = Z/2` (higher energy on `|0>`) and finds `<Y> = +sin t_k`. The present model uses `H_S = diag(0, omega)` (higher energy on `|1>`) and finds `<Y> = -sin theta_k`. Both are correct for their Hamiltonian; the sign of `<Y>` is the sign of `-hz`. An oracle or engine that gets this sign wrong agrees on X and Z and disagrees on Y, which is exactly why Y is mandatory (section 9).

**Remark 5.3 (relational phases).** For `|Psi_{a,b}>` with `b/a = exp(i beta)` and `|a| = |b|`, Theorem 4 holds with `theta_k` replaced by `theta_k - beta`. A phase `beta` written into the global state and a phase `-phi` written into the clock labels are indistinguishable in every prediction. Only the difference between the clock phase and the system phase is observable. This is a derived consequence of the construction, not an assumption.

## 6. Internal clock labels versus external wall-clock time

Three distinct things could be called "time" around an AT-0 run, and the contract keeps them in three separate places.

| Name | What it is | Where it lives | Enters an identity? |
|---|---|---|---|
| Internal clock label `theta_k` (and the dictionary value `t_k = theta_k/omega`) | A declared parameter of the question: which effect `E_k` to condition on | case semantic block (`povm_tau_turns`, `clock_label`) | yes, `case_id` |
| External evolution parameter `t` in `exp(-i H_total t)` | A mathematical operation with no effect on `|Psi>` (Corollary 1.1) | nowhere; it is not a field | no |
| Wall-clock time of a physical execution | When the computer ran | result provenance only (`run_started_utc`, `run_finished_utc`) | no (evidence digest only) |

Consequences that an implementation must satisfy (tests in section 9):

1. The values block of a result depends on the case only. Running the same case twice at different wall-clock times yields the same `case_id`, `acceptance_id`, `verdict_id` and bit-identical values, and different `evidence_digest`.
2. Evaluating the labels in any order yields the same values block: `P(k, A, s)` is a function of `theta_k` alone (Theorem 3), with no state carried between labels.
3. The engine calls no clock, timer or random source (charter section 3, gate G2).
4. No `t` is ever applied to `|Psi>`. An engine that first "evolves" the global state by some `t` and then conditions would still produce the same numbers (Corollary 1.1), so such a step is not wrong but is dead code; the spec forbids it to keep the no-external-time claim honest at the code level.

## 7. Why this clock is an idealized relational model

Each item below is a limit of the construction, derived from it, and must be stated in any report that cites AT-0 results.

1. **Finite and tiny.** The universe is four-dimensional. There is no continuum of clock readings; `N` readings are chosen by the observer and the same state can be read with any `N` (Theorem 2 holds for all `N >= 2`). "Time resolution" is a choice of measurement, not a property of the universe.
2. **Phase, not time.** The clock reads a phase modulo `2 pi` (Remark 2.3). Readings `theta` and `theta + 2 pi` coincide, so the model cannot order events over more than one period and has no arrow of time. `t_k = theta_k/omega` is defined only on one period.
3. **Imperfect readings.** The phase states are nonorthogonal (Lemma 2.1), so a reading `k` does not exclude the clock "being at" a neighbouring label. The conditional states `|psi_k>` are nevertheless exactly the Schrodinger states because the effect is rank one and the global state is pure; this exactness is a feature of the ideal case and is lost for mixed states, higher-rank effects or a clock with more than one frequency.
4. **No time operator.** `H_C` is bounded, so by Pauli's argument there is no self-adjoint operator canonically conjugate to it. The covariant POVM is the standard replacement, and it is the best a two-level clock can do; the model does not escape this limit, it instantiates it.
5. **No interaction, no back-action, no decoherence.** `interaction NONE`: the clock never disturbs the system and vice versa, and nothing is traced out. Real clocks interact and decohere; AT-0 V1 says nothing about that regime (charter: V2 for interaction terms).
6. **One frequency.** The clock has a single energy gap, the system has the same gap, and the global state is the single entangled kernel vector that links them. There is no energy spread, so no clock with better than one-period resolution and no system with more than one oscillation frequency. Multi-level clocks are the contract's general case (`clock_dim` up to 64) but are outside this specification.
7. **Kinematics only.** Everything derived here is linear algebra on a fixed vector. The model does not generate dynamics; it exhibits correlations that read as dynamics when conditioned on a clock label. Whether nature does this is a question for physics, not for this specification (section 11).

## 8. Invariants, tolerances and numerical error analysis

### 8.1 Mathematical invariants

Each invariant names the exact statement, the quantity an implementation writes, and the contract check that judges it.

| Id | Exact statement | Written quantity | Contract check (AT0_RESULT_V1 section 4) |
|---|---|---|---|
| I1 | `H_total Psi = 0` (Theorem 1) | `constraint_residual = ||H_total Psi_hat||` | 4 `constraint_residual` |
| I2 | `dim ker H_total = 2` and `Psi != 0` | `physical_state_kernel_dim` (exact integer) | 3 `physical_state_nontrivial` |
| I3 | `sum_k E_k = I` (Theorem 2) | `povm_residual = ||sum_k F_k - I||_F` | 5 `povm_normalization` |
| I4 | `E_k >= 0` | none (exact by construction: rank one, weight `2/N > 0`) | validity rule `povm_weight > 0` |
| I5 | `p_k = 1/N`, `sum_k p_k = 1` (Lemma 3.1) | `clock_probability k` | 6 `clock_probability_sum`, 7 `probability_range` |
| I6 | `P(A+|k) + P(A-|k) = 1`, each in `[0, 1]` | `pauli k A PLUS/MINUS` | 7, 8 `pauli_pair_sum` |
| I7 | `P(A, s|k)` equals the Schrodinger value (Theorem 5) | `pauli` vs `reference` | 10 `schrodinger_agreement` |
| I8 | `rho_k` is pure: `<X>^2 + <Y>^2 + <Z>^2 = 1` | derived from `pauli` lines | not a V1 check; section 9 test T6 |
| I9 | values depend on the case only (section 6) | whole values block | charter controls (wall-clock independence, evaluation order) |
| I10 | shifting `phi` by `delta` shifts every `theta_k` by `delta`; multiplying `Psi` by a global phase changes nothing | none | section 9 tests T7, T8 |

### 8.2 Tolerance policy

- **Provisional tolerance:** `1e-10` on every normalized residual and every probability deviation, for the first double-precision reference implementation. In contract notation this is `1@10` for `tol_constraint_residual`, `tol_povm_residual`, `tol_probability` and `tol_schrodinger`. The frozen example case uses the tighter `1@12`; section 8.3 shows both are safe for the reference model. The provisional value stands until an implementation publishes its own error analysis or a `RIGOROUS` bound.
- **Absolute, never relative.** Probabilities that are exactly `0` or `1` occur in the reference model (for example `P(X+)` at `theta_k = pi`). Computed through the Born rule they come out as tiny nonzero numbers (squares of rounding errors, about `1e-33`). A relative tolerance would reject them; an absolute tolerance accepts them. The contract's absolute form, `|v| + bound <= tol`, is the one to use.
- **Normalized constraint residual.** The spec's invariant I1 is `||H_total Psi_hat|| / ||H_total||_op <= tol`, scale-free in `omega`. AT0_RESULT_V1 writes the unnormalized residual in energy units. The two agree when `omega = 1`; every V1 case built from this model therefore uses `omega = 1` (clock energies `-1/1, 0/1`), and the normalized form is the one to use if a later contract allows other scales.
- **`tol_zero_probability`.** All `p_k = 1/N >= 1/256` in V1, so labels are never near the undefined threshold; `1@9` from the example is fine.

### 8.3 Error analysis for the binary64 reference implementation

Let `eps = 2^-53` (about `1.1e-16`). Assumptions, to be verified by the implementer: the C library's `cos`, `sin` and `sqrt` return results within 1 ulp of the true value for arguments in `[0, 2 pi]` (glibc lists 1 ulp as the maximum error of `cos` and `sin` on common targets; the implementer must check the table for the build target; `sqrt` is correctly rounded by IEEE 754); `omega = 1` and `1/N` are computed, not read as decimal text; no fused reductions across threads (`threads 1`).

| Quantity | Operations | First-order absolute error bound | Measured (section 12) |
|---|---|---|---|
| `constraint_residual` | 4 multiplies of exactly representable numbers by `0` or `+/-1`, 4 adds | exactly `0` for `omega = 1`; in general `<= 4 eps` | `0` |
| `|theta_k>` entries | one `cos`, one `sin`, one scale by `1/sqrt2` | `<= 3 eps` per entry | |
| `povm_residual` | `N` rank-one terms of size `1/N`, summed | `<= c * eps` with `c` about 12, independent of `N` (each term carries error about `eps/N`) | `2e-16` to `6e-16` for `N` in `{2, 3, 4, 7, 64}` |
| `clock_probability k` | 2 inner products, 1 norm, 1 scale | `<= 10 eps / N` | |
| `sum_k p_k - 1` | `N` adds | `<= 10 eps + N eps` | `<= 6e-16` |
| each `pauli` probability | 2 complex inner products, modulus squared, divide | `<= 12 eps` | `<= 4e-16` |
| each `reference` probability (oracle) | one `cos` or `sin`, one add, one halve | `<= 2 eps` | |

The worst bound above, at the contract's maximum `N = 256`, is about `3e-14`, three orders of magnitude under `1@12` and four under the provisional `1@10`. An implementation that reports `bound_kind ESTIMATED` may cite this table with its own constants; a `RIGOROUS` bound needs directed-rounding interval arithmetic including enclosures of `cos` and `sin`, which is Agent 3's call and is not assumed here.

Two numerical traps the analysis depends on:

1. `cos(theta)` and `sin(theta)` must be evaluated at the double nearest `theta_k = phi + 2 pi k / N`, computed as `phi + (2 pi) * k / N` in that order; the rounding error in `theta_k` itself (at most `2 eps |theta_k|`) adds at most that much to each trigonometric value; reduce `phi` into `[0, 2 pi)` before use so this stays below `30 eps`.
2. Cancellation in `sum_k exp(i theta_k) = 0` (Theorem 2) is benign: the terms are `O(1/N)` after weighting and the sum is `O(1)`, so the absolute error does not grow with `N` beyond the bound stated.

## 9. Negative controls and tests

Every test names the quantity, the expected result, and what it would miss if omitted. Tests marked **Y** are the ones that measuring Pauli X alone cannot replace. Expected outcomes are stated in the contract's vocabulary where a V1 case can express them; others are engine- or oracle-level unit tests.

### 9.1 Positive controls

| Id | Case | Expected |
|---|---|---|
| T1 | reference model, `N = 4`, `phi = 0` (exact rationals: `P(X+) = 1, 1/2, 0, 1/2`; `P(Y+) = 1/2, 0, 1/2, 1`; `P(Z+) = 1/2`; `p_k = 1/4`) | all invariants hold; `outcome PASS` |
| T2 | reference model, `N = 3`, `phi = 0` (`P(X+) = 1, 1/4, 1/4`; `P(Y+) = 1/2, (2 - sqrt3)/4, (2 + sqrt3)/4`) | PASS; exercises an irrational expected value, so the comparison is numeric, not exact |
| T3 | reference model, `N = 7`, `phi = 3/10` (nothing rational, no label at a special angle) | PASS |
| T4 | eigenstate control: kernel state `|00>` alone (`a = 1, b = 0`) | every residual passes; `P(X+|k) = P(Y+|k) = 1/2`, `P(Z+|k) = 1` for all `k`; oracle predicts the same (stationary state); PASS. Guards against an engine or oracle that always rotates |
| T5 | relational phase: `b/a = exp(i beta)`, `beta = pi/2`, `N = 4`, `phi = 0` | predictions equal T1 with `theta_k -> theta_k - beta`; PASS against the oracle started in `(|0> + i|1>)/sqrt2` (Remark 5.3) |
| T6 | purity: `<X>^2 + <Y>^2 + <Z>^2` from the `pauli` lines of T1 to T3 | `1` within `4 * tol_probability` |
| T7 | phase-offset covariance: run T3 with `phi` and with `phi + delta` | the second table equals the first with `theta_k -> theta_k + delta`; catches an engine that ignores `phi` |
| T8 | global phase: multiply `Psi` by `exp(i * 1/3)` | bit-for-bit, or within `4 eps`, the same table as T3 |
| T9 | evaluation order: labels evaluated `N-1 .. 0` | bit-identical values block (section 6, item 2) |
| T10 | wall-clock independence: same case run twice | identical `case_id`, `acceptance_id`, `verdict_id`, values block; different `evidence_digest` |

### 9.2 Negative controls (must fail, and only for the stated reason)

| Id | Mutation | Expected | What X alone would miss |
|---|---|---|---|
| N1 | uncovered spectrum: clock energies `+1, +2` | kernel dimension 0; `FAIL TRIVIAL_PHYSICAL_STATE`, later checks `NOT_EVALUATED` | |
| N2 | half-covered spectrum: clock energies `0, +1` with `H_S = diag(0, +1)`; kernel is `|00>` only | residuals pass; conditional state is `|0>` for all `k` while the oracle, started in `|X+>`, rotates; `FAIL SCHRODINGER_DEVIATION_EXCEEDED` on X and Y (Z also: `P(Z+) = 1` vs `1/2`) | |
| N3 | wrong weight: `E_k = (1/N)|theta_k><theta_k|` | `sum_k E_k = I/2`, so `povm_residual = ||I/2||_F = 1/sqrt2` exactly; `sum_k p_k = 1/2`; `FAIL POVM_NORMALIZATION_EXCEEDED, PROBABILITY_SUM_EXCEEDED`; conditional probabilities unchanged (they are ratios), so check 10 passes | |
| N4 | broken clock: labels `theta_k = phi + 2 pi k / N` for `k = 0 .. N-2` only (one effect dropped) | `sum_k E_k = I - E_{N-1}`, `povm_residual = 2/N`, `sum_k p_k = 1 - 1/N`; `FAIL POVM_NORMALIZATION_EXCEEDED, PROBABILITY_SUM_EXCEEDED`; the surviving conditional probabilities still match the oracle | |
| N5 **Y** | missing complex conjugate: engine uses `|theta_k>` where it should use `<theta_k|` (equivalently conditions on `theta_k -> -theta_k`) | X and Z agree with the oracle; `P(Y+)` becomes `(1 + sin theta_k)/2`; deviation `|sin theta_k|` is at least `cos(pi/N) >= 1/2` for some `k` when `N >= 3`; `FAIL SCHRODINGER_DEVIATION_EXCEEDED` raised by Y only | everything: this bug is invisible to X and Z (Lemma 4.1) |
| N6 **Y** | reversed reference evolution: oracle uses `exp(+i H_S t)` (or `hz` with the wrong sign) | engine unchanged; oracle's Y reference flips; `FAIL SCHRODINGER_DEVIATION_EXCEEDED` by Y only. Note (section 12) that flipping the Hamiltonian signs inside the engine changes nothing, because the engine's output depends on `Psi` and `{E_k}` only; the flip must be applied to the reference | everything |
| N7 **Y** | Y-sign swap in the engine: `PLUS` and `MINUS` of Y exchanged | X, Z pass; Y fails on every `k` with `sin theta_k != 0` | everything |
| N8 | axis swap: engine exchanges X and Y results (charter control) | fails on X and Y wherever `cos theta_k != -sin theta_k`; proves oracle independence | |
| N9 | `N = 2`, `phi = 0`, with the N5 mutation | all checks PASS although the engine is wrong: `sin theta_k = 0` for both labels. This is a documented false negative and the reason `N >= 3` is required; it is kept as an engine unit test, not as a V1 case | |
| N10 | precision demand: `min_bound_kind RIGOROUS` against an `ESTIMATED` engine | `FAIL BOUND_KIND_INSUFFICIENT` | |
| N11 | hidden clock read: a mutant engine that calls `clock_gettime` | caught by the isolation gate, never run | |

Every negative control succeeds only when its failure codes equal the expected set exactly (AT0_RESULT_V1 section 5). A control that fails for an extra reason is a defect in the control or the implementation, not a pass.

## 10. Proof obligations for the implementation

An implementation claiming to realize this specification must show, with evidence in the result files or the gate logs:

| Id | Obligation | Discharged by |
|---|---|---|
| O1 | The engine builds `H_total`, `Psi`, `{E_k}` from the case text and nothing else; no wall-clock, no `t` applied to `Psi` | code review plus gate G2 and tests T9, T10 |
| O2 | `physical_state_kernel_dim` is computed exactly from rationals, and equals 2 for the reference model | T1, N1, N2 |
| O3 | `constraint_residual`, `povm_residual`, `clock_probability`, `pauli` are computed as section 8.1 defines, each `pauli` directly from `rho_k`, never as `1 - other` | code review; T6 (purity would still pass if one sign were derived, so T6 is necessary but not sufficient); N7 |
| O4 | The oracle shares no code with the engine and computes `exp(-i H_S t_k)` from `H_S` and `t_k` only | gate G3; N5, N6, N8 |
| O5 | The stated `bound_kind` is honest: `ESTIMATED` cites an error analysis like section 8.3; `RIGOROUS` cites an interval method | Agent 2 and 3 notes; N10 |
| O6 | Every negative control fails with exactly its expected codes | gate G5 |
| O7 | Pauli Y is measured and compared on every label | the contract fixes `observables PAULI_X,PAULI_Y,PAULI_Z`; N5 to N7 |

## 11. What follows from the construction, and what would need an experiment

**Follows from the construction (proved above, needs no experiment):**

1. There is a four-dimensional quantum state annihilated by a total Hamiltonian (Theorem 1), hence invariant under the evolution it generates (Corollary 1.1).
2. A finite nonorthogonal phase POVM on the two-level clock is a valid measurement for every `N >= 2` (Theorem 2).
3. Conditioning that state on each clock outcome gives, by the Born rule alone, a family of pure system states (Theorem 3) whose Pauli statistics are exactly those of one-qubit Schrodinger evolution read at `t_k = theta_k/omega` (Theorems 4 and 5).
4. Only the relative phase between clock and system is observable (Remark 5.3); the clock marginal is uniform for every physical state (Remark 3.3).
5. Pauli X and Z cannot detect a reversed phase; Pauli Y can (Lemma 4.1), with a deviation of at least `1/2` in probability for some label whenever `N >= 3`.
6. A correct double-precision implementation satisfies every invariant to better than `1e-13` (section 8.3), so the tolerances `1@10` and `1@12` are sound for this model.

**Not established here, and would require physical experiments or further theory:**

1. That physical time is emergent, relational, or absent at a fundamental level. The model is a consistency demonstration: a stationary state can encode what looks like evolution. It does not show that the universe is such a state, and it says nothing about a continuum of time, gravity, or the arrow of time.
2. That any laboratory clock behaves like `E_k`. A real clock interacts, decoheres, has many levels and finite energy spread, and the lab that reads it uses its own external clock to do so.
3. That the dictionary `t_k = theta_k/omega` is more than a bookkeeping choice. Within the model it is a definition.
4. That the construction extends to interacting clocks, larger systems, or mixed states while keeping exact Schrodinger agreement (section 7, items 3 and 5). Those are new theorems, not corollaries.
5. Anything about Omega, FORGE, GPU realization, the Crumbline, or the Postulate's schedule-invariance experiment (charter section 1).

A passing AT-0 run is evidence that an implementation reproduces the mathematics of sections 2 to 5 for the cases run. It is not evidence for any claim in the second list, and no report may say otherwise.

## 12. Discrepancies, scratch verification, and the mapping onto AT0_CASE_V1

**Discrepancies found while writing this specification (recorded, not resolved; resolution belongs to Agent 0 under charter section 8):**

1. RESOLVED. The charter at `044c9d1` listed `docs/plans/atemporal/` under Agent 0 and gave Agent 1 the C codec; the amended charter (aien-architecture#177, `d390939`) names Agent 1 the owner of this file and requires the hand-derived tables of section 13.
2. The brief's reference model fixes the sign convention `H_S = diag(0, +omega)` (`hz < 0`); the frozen example uses `hz > 0`. Not a contradiction (Remark 5.2), but Agent 4's hand derivations must carry the sign of `<Y>` per case.
3. Flipping the sign of `omega` inside the engine's Hamiltonians is not a negative control for the engine: the engine's values do not depend on `H_C` or `H_S` once `Psi` is fixed (Theorem 3). The brief's "Pauli Y must distinguish reversed phase evolution" is satisfied by N5 (engine conjugation bug) and N6 (oracle reversal), both of which Y detects and X does not. Found by the scratch run below.
4. The brief's general `phi` is expressible in a V1 case only as `phi = -2 pi r / N` through `reference_clock_label r` (the conditional state is evolved by `t_k - t_r`). A general `phi` is an engine unit-test parameter in V1, not a case field.
5. AT0_RESULT_V1 writes an unnormalized constraint residual; this spec's invariant is normalized (section 8.2). Equal at `omega = 1`.

**Scratch verification.** A 90-line C11 program (`<complex.h>`, `-lm`, no project code) built the state, the POVM and the Born probabilities directly from Definitions 1.1 to 1.5 and compared them with Theorem 4 for `N` in `{2, 3, 4, 7, 64}`, `phi` in `{0, 0.3, 0.7}`, `omega` in `{1, 2.5, 1e6}`, plus the `|00>` control (T4) and the sign-flipped Hamiltonians (discrepancy 3). Largest deviations: constraint residual `0`, POVM residual `5.3e-16`, probability sum `5.6e-16`, Pauli deviation from Theorem 4 `3.3e-16`. The `|00>` control deviated from Theorem 4 by `0.5` as predicted. Reversed Hamiltonians left the engine table unchanged and moved the Y reference by up to `1.0`. The program is scratch, not evidence; the first evidence is the gate run under the charter.

**Mapping the reference model onto an AT0_CASE_V1 semantic block (informational; Agent 4 owns case files and their digests).** With `omega = 1`, `N = 4` labels, `phi = 0`:

```
model_family PAGE_WOOTTERS_FINITE_IDEAL
energy_unit DIMENSIONLESS_HBAR_1
clock_dim 2
clock_energies -1/1,0/1
system_dim 2
system_hamiltonian_pauli 1/2,0/1,0/1,-1/2
interaction NONE
constraint SUM_HC_HS
physical_state NULLSPACE_PROJECTION
reference_clock_label t0
reference_system_state (1/1;0/1),(1/1;0/1)
clock_povm COVARIANT_DISCRETE
povm_tau_turns 1/4
povm_weight 1/2
clock_label_count 4
clock_label 0 t0
clock_label 1 t1
clock_label 2 t2
clock_label 3 t3
observables PAULI_X,PAULI_Y,PAULI_Z
```

Derivation of the mapping: the contract orders clock energies increasingly, so `|E_0> = |1>_C` (energy `-omega`) and `|E_1> = |0>_C` (energy `0`); its clock state `|t_k> = 2^{-1/2} sum_j exp(-2 pi i E_j k tau)|E_j> = (|0>_C + exp(2 pi i omega k tau)|1>_C)/sqrt2` equals `|theta_k>` with `theta_k = 2 pi omega k tau`, so `tau = 1/(N omega)`; the effect weight is `w = clock_dim / M = 2/N`; the kernel projection of `|t_0> (x) (|0>+|1>)` is `(|00> + |11>)/sqrt2` up to normalization, which is `|Psi>`; and the oracle's `exp(-i H_S (t_k - t_0))|X+>` with `t_k = 2 pi k tau` is `|psi_k>` of Theorem 3. Expected table for this block: `P(X+) = 1, 1/2, 0, 1/2`; `P(Y+) = 1/2, 0, 1/2, 1`; `P(Z+) = 1/2`; `p_k = 1/4` (contrast the frozen example's `P(Y+) = 1/2, 1, 1/2, 0`: opposite `hz`, opposite Y, as Remark 5.2 says).

## 13. Hand-derived answer tables for the charter section 6 case classes

These tables are the input for Agent 4's case files and for Agent 2's oracle calibration (gate G3). They cover the contract's general model, of which section 1 is the two-level instance. Every number was derived by hand as shown and reproduced by a second scratch C11 program implementing AT0_CASE_V1 section 3 literally (clock energies, Pauli `h`, kernel projection, covariant clock states, effects `F_k = w|t_k><t_k|`), with agreement to `1e-15` or better.

### 13.1 General formulas (derived once, used by every row)

Notation: clock energies `E_j` (`j < N`, strictly increasing), system eigenvalues `e_+ = h0 + |h|`, `e_- = h0 - |h|` with eigenvectors `|e_+>, |e_->`, components `c_s = <e_s|psi_0>`, readings `t_k = 2 pi k tau`, reference label `r`, `M` labels, weight `w`.

- **Kernel.** `K = {(j, s) : E_j + e_s = 0}`. Because the `E_j` are distinct, each `s` is matched by at most one `j`, so `physical_state_kernel_dim = |K|` is `0`, `1` or `2`. When `|h| = 0` the two eigenvalues coincide and both share one clock energy; that degenerate case is excluded from these tables.
- **Physical state.** `Psi = sum_K N^{-1/2} exp(-2 pi i E_j r tau) c_s |E_j>|e_s>`. `Psi = 0` exactly when every matched `c_s` is `0`. `||Psi||^2 = (1/N) sum_K |c_s|^2`.
- **Conditional vector.** `phi_k = (<t_k| (x) I) Psi = (1/N) sum_K exp(-i e_s (t_k - t_r)) c_s |e_s> = (1/N) exp(-i H_S (t_k - t_r)) Pi_K psi_0`, where `Pi_K` projects onto the matched eigenvectors. Proof: `<t_k|E_j> = N^{-1/2} exp(+2 pi i E_j k tau)` and `E_j = -e_s` on `K`.
- **Clock marginal.** `p_k = w ||phi_k||^2 / ||Psi||^2 = w / N` for every `k`, whenever `Psi != 0`, because the phases have modulus one and the matched eigenvectors are orthogonal. Hence `sum_k p_k = w M / N`, independent of the clock being well formed.
- **Conditional probabilities.** Those of the normalized `exp(-i H_S (t_k - t_r)) Pi_K psi_0`. They equal the oracle's reference (which evolves `psi_0` itself) exactly when `Pi_K psi_0` is proportional to `psi_0`: full cover, or `psi_0` an eigenvector of `H_S`.
- **POVM sum.** `sum_k F_k = (w/N) sum_{j,j'} S_{jj'} |E_j><E_j'|` with `S_{jj'} = sum_{k=0}^{M-1} exp(-2 pi i (E_j - E_j') k tau)`. Diagonal: `S = M`. Off-diagonal with gap `D = E_j - E_j'`: `S = M` if `D tau` is an integer; `S = 0` if `D tau M` is an integer and `D tau` is not; otherwise `S = (1 - exp(-2 pi i D tau M)) / (1 - exp(-2 pi i D tau))`. So `sum_k F_k = (w M / N) I` exactly when every gap satisfies the second condition, and the residual is then `|w M / N - 1| sqrt(N)`.
- **Bloch rotation** (for tilted `h`): `exp(-i H_S t)` rotates the Bloch vector right-handedly about `n = h/|h|` by angle `alpha = 2 |h| t`; `r(alpha) = r cos(alpha) + (n x r) sin(alpha) + n (n . r)(1 - cos(alpha))`, and `P(A+) = (1 + r_A)/2`. Check against section 5: `h = (0,0,-omega/2)`, `r(0) = (1,0,0)` gives `r_Y = -sin(omega t)`.

### 13.2 Positive classes

**P1, the frozen example** (`N = 4`, `E = -3/2, -1/2, 1/2, 3/2`, `H_S = Z/2`, `psi_0 = |+>`, `r = 0`, `tau = 1/4`, `w = 1`, `M = 4`). Kernel `{(1, +), (2, -)}`, dimension 2, full cover. Gaps `D` in `{1, 2, 3}`: `D tau M = D` integer, `D tau = D/4` not integer, so `sum F_k = I` exactly. `t_k = k pi / 2`, Bloch vector `(cos t_k, sin t_k, 0)`.

| k | p_k | P(X+) | P(Y+) | P(Z+) | expected |
|---|---|---|---|---|---|
| 0 | 1/4 | 1 | 1/2 | 1/2 | `PASS` |
| 1 | 1/4 | 1/2 | 1 | 1/2 | |
| 2 | 1/4 | 0 | 1/2 | 1/2 | |
| 3 | 1/4 | 1/2 | 0 | 1/2 | |

This agrees with the table in AT0_CASE_V1 section 6. Residuals: constraint `0`, POVM `0`, probability sum `1`. Codes: none.

**P1b, other `N`, `M`, `tau`** (`N = 2`, `E = -1/2, 1/2`, `H_S = Z/2`, `psi_0 = |+>`, `r = 0`, `tau = 1/3`, `w = 2/3`, `M = 3`). Single gap `D = 1`: `D tau M = 1`, `D tau = 1/3`, so `sum F_k = I`. `t_k = 2 pi k / 3`.

| k | p_k | P(X+) | P(Y+) | P(Z+) | expected |
|---|---|---|---|---|---|
| 0 | 1/3 | 1 | 1/2 | 1/2 | `PASS` |
| 1 | 1/3 | 1/4 | (2 + sqrt3)/4 | 1/2 | |
| 2 | 1/3 | 1/4 | (2 - sqrt3)/4 | 1/2 | |

`(2 + sqrt3)/4` is about `0.9330127`; this row is the first with an irrational expected value, so it is compared numerically.

**P1c, the section 1 reference model as a case** (section 12 block: `N = 2`, `E = -1, 0`, `h = (1/2, 0, 0, -1/2)`, `psi_0 = |+>`, `tau = 1/4`, `w = 1/2`, `M = 4`): `P(X+) = 1, 1/2, 0, 1/2`; `P(Y+) = 1/2, 0, 1/2, 1`; `P(Z+) = 1/2`; `p_k = 1/4`. Same X and Z as P1, opposite Y (Remark 5.2). `PASS`.

**P2, nonzero `h0`, tilted `h` with rational norm** (`h0 = 1/10`, `hx = 3/10`, `hy = 0`, `hz = 2/5`; `|h| = 1/2`; `e_+ = 3/5`, `e_- = -2/5`; clock `N = 2`, `E = -3/5, 2/5`; `psi_0 = |0>`; `r = 0`; `tau = 1/4`; `w = 1/2`; `M = 4`). Kernel `{(0, +), (1, -)}`, full cover. Gap `D = 1`: `sum F_k = I`. `n = (3/5, 0, 4/5)`, `r(0) = (0, 0, 1)`, `alpha_k = 2 |h| t_k = k pi / 2`. `n . r = 4/5`, `n x r = (0, -3/5, 0)`, so `r(alpha) = (12/25 (1 - cos alpha), -3/5 sin alpha, cos alpha + 16/25 (1 - cos alpha))`.

| k | alpha | Bloch vector | p_k | P(X+) | P(Y+) | P(Z+) | expected |
|---|---|---|---|---|---|---|---|
| 0 | 0 | (0, 0, 1) | 1/4 | 1/2 | 1/2 | 1 | `PASS` |
| 1 | pi/2 | (12/25, -3/5, 16/25) | 1/4 | 37/50 | 1/5 | 41/50 | |
| 2 | pi | (24/25, 0, 7/25) | 1/4 | 49/50 | 1/2 | 16/25 | |
| 3 | 3pi/2 | (12/25, 3/5, 16/25) | 1/4 | 37/50 | 4/5 | 41/50 | |

Every Bloch vector has unit norm (`144 + 225 + 256 = 625`; `576 + 0 + 49 = 625`), which is the purity check T6 in exact arithmetic. `h0` enters only through the clock energies that must cover `h0 +/- |h|`; it is a global phase in the dynamics. Codes: none.

### 13.3 Negative classes (exact expected codes)

| Class | Instance | Derivation | Expected codes (exact set) |
|---|---|---|---|
| N1 uncovered spectrum | P1 with `E = 1, 2, 3, 4` | No `E_j` equals `-1/2` or `+1/2`, so `K` is empty, `physical_state_kernel_dim 0`, `Psi = 0`. Check 3 fails. Checks 4 and 6 to 10 have no input and are `NOT_EVALUATED`. Check 5 still runs on the clock alone: gaps `1, 2, 3` with `tau = 1/4`, `M = 4` give `sum F_k = I`, so it passes. Caution: the charter's wording "clock energies all positive" is not sufficient; a positive energy equal to `+1/2` matches `e_- = -1/2` and gives class N2 instead. | `TRIVIAL_PHYSICAL_STATE` |
| N2 half-covered spectrum | P1 with `E = 1/2, 3/2, 5/2, 7/2` | Only `E_0 = 1/2` matches `e_- = -1/2` (eigenvector `|1>`), kernel dimension 1, `Psi = (1/2)|E_0>|1>`, nonzero. Clock well formed (same gaps as P1), `p_k = 1/4`, sum `1`. Conditional state is `|1>` for every `k`: `P(X+) = 1/2`, `P(Y+) = 1/2`, `P(Z+) = 0`. Reference rotates: `P(X+) = 1, 1/2, 0, 1/2`; `P(Y+) = 1/2, 1, 1/2, 0`; `P(Z+) = 1/2`. Deviations: Z `1/2` on every label; X `1/2, 0, 1/2, 0`; Y `0, 1/2, 0, 1/2`. | `SCHRODINGER_DEVIATION_EXCEEDED` |
| N3 broken clock | P1 with `tau = 1/3` (`M = 4`) | Gap `D = 3`: `D tau = 1` integer, `S = M = 4`. Gaps `1, 2`: `D tau M = 4/3, 8/3` not integers, `|S| = 1` (geometric sum of four cube roots of unity). Off-diagonal entries of `sum F_k`: `1/4` for the five pairs with `D = 1, 2` and `1` for the pair with `D = 3`, each twice; `povm_residual = sqrt(2 (5/16 + 1)) = sqrt(42)/4` about `1.6202`. `p_k = w/N = 1/4` regardless, sum `1`, conditional probabilities are those of `t_k = 2 pi k / 3`, which the reference uses too, so checks 6 to 10 pass. "Every code that follows" is therefore the empty set for a clock that is broken only in `tau`. | `POVM_NORMALIZATION_EXCEEDED` |
| N4 wrong weight | P1 with `w = 1/2` | `sum F_k = (w M / N) I = I/2`, `povm_residual = (1/2) sqrt(4) = 1`. `p_k = w/N = 1/8`, sum `1/2`. Conditional probabilities unchanged (ratios), so check 10 passes; `p_k` within `[0, 1]`, so check 7 passes. In general check 7 also fails (`PROBABILITY_OUT_OF_RANGE`) exactly when `w > N`; and `CONDITIONAL_UNDEFINED` cannot occur in V1 because `w/N >= 1/(1048576 * 64)` exceeds any sensible `tol_zero_probability`. | `POVM_NORMALIZATION_EXCEEDED`, `PROBABILITY_SUM_EXCEEDED` |
| N5 precision demand | P1 with `min_bound_kind RIGOROUS` run by an `ESTIMATED` engine | Check 1 fails; every other check is evaluated and passes as in P1. | `BOUND_KIND_INSUFFICIENT` |

Each N case must carry `expected_failure_codes` equal to exactly the set shown, sorted bytewise; any extra code is a defect (AT0_RESULT_V1 section 5).

### 13.4 Refusal classes (one defect per file, first failure in AT0_CASE_V1 section 4 order wins)

| Class | Single defect in an otherwise valid P1 file | Code |
|---|---|---|
| R0 | a line removed, or a CRLF line ending | `CASE_PARSE_ERROR` |
| R1 | `povm_tau_turns 2/8` | `CASE_NONCANONICAL` |
| R2 | header `OMEGA-AT0-CASE v2` | `CASE_UNSUPPORTED_VERSION` |
| R3 | `clock_dim 65` with 65 energies | `CASE_INVALID_PARAMETER` |
| R4 | `system_hamiltonian_pauli 0/1,1/1,0/1,1/1` (`|h|^2 = 2`) | `CASE_IRRATIONAL_SPECTRUM` |
| R5 | `case_id` with one hex digit changed | `CASE_ID_MISMATCH` |
| R6 | `expected_outcome FAIL` with `expected_failure_codes none` | `CASE_INVALID_PARAMETER` |

R3 and R6 share a code; the charter asks for one file per refusal code, so R0 to R5 give the six codes and R6 is an extra instance. Because validation stops at the first failure, a file with two defects reports only the earlier one; files must have exactly one.

### 13.5 Contract notes arising from these derivations (for Agent 0)

1. AT0_RESULT_V1 section 3 says how `constraint_residual` is written when the kernel is trivial (`undefined`) but not how `clock_probability`, `pauli` and label status lines are written when `Psi = 0` (N1). This specification expects `clock_probability` values `undefined` with bound `0@0`, every label `UNDEFINED`, and checks 6 to 10 `NOT_EVALUATED` with no `CONDITIONAL_UNDEFINED` code, so that N1 raises exactly `TRIVIAL_PHYSICAL_STATE`. A contract clarification or a V2 note should fix this reading.
2. Charter section 6, class N1: "all positive" must be strengthened to "no clock energy equals the negative of any system eigenvalue".
