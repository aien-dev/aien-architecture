# AT1_SPEC: Mathematical specification for the AT-1 interacting reference model

**Status:** DRAFT for independent review. Not a frozen interface (AT1 charter section 8); the frozen interfaces are `AT1_CASE_V1.md` (sha256 `e62018d8deec97fffca5cacaf6452d8fc45c395596517665cd73eb0c777a3e8f`) and `AT1_RESULT_V1.md` (sha256 `3e6efd7e641a89bf0e425267525afabc51fe7a5497d3d539cdeaf09ddb6fa92d`), frozen at aien-architecture `cbe4c8e` (gate AT1-G0, omega#371). Program status: NOT_RUN.
**Written:** 2026-10-10 by AT-1 Agent 1 (mathematical specification), session spawned by the mission orchestrator 1ea888. Owner of this file: Agent 1 (charter section 7).
**Scope:** the clock-diagonal interacting Page-Wootters model fixed by `AT1_CASE_V1` section 3: a finite clock, one qubit, a Pauli coupling that is diagonal in the clock energy basis, one stationary global state, a covariant discrete clock POVM, and the two reference predictions (ideal and interacting) of `AT1_RESULT_V1` section 3. Every formula is derived here or cited to a section of a frozen contract. Nothing here is a physical claim. A PASS of any AT-1 run means conformance of software with this specification and the contracts, and nothing more.

**Reading guide.** Sections 1 to 5 are the mathematics. Section 5 also says where the ideal relational prediction fails and by how much. Sections 6 to 10 turn it into invariants, numerical policy, controls, mutants and proof obligations. Section 11 separates what follows from the construction from what would need an experiment. Section 12 holds discrepancies, scratch verification, the replication requirements at the spec level, and contract notes. Section 13 holds the hand-derived answer tables for every case class of charter section 6.

## 0. Conventions and claim classes

Every claim in this file carries exactly one of four classes:

- **[ESTABLISHED MATHEMATICS]**: finite-dimensional linear algebra and elementary numerical analysis, proved in the text or standard. Definitions copied from the frozen contracts are also marked this way, with the contract section cited; they are definitions, not discoveries.
- **[COMPUTATIONAL DEMONSTRATION]**: a value or behaviour observed by running the scratch checkers of section 12.2. It shows that a program produced a number; it proves nothing beyond the cases run.
- **[EXPERIMENTAL PHYSICS: none in AT-1]**: no statement in this file is of this class. AT-1 runs no physical experiment and makes no claim about nature.
- **[HYPOTHESIS]**: a statement not proved here (for example about other platforms or about what a future implementation will do), stated so it can be tested.

Rules for case authors and implementers (marked RULE) are choices of this specification, not claims; each names the mathematics that justifies it.

Notation, all from `AT1_CASE_V1` section 3 [ESTABLISHED MATHEMATICS] (definitions):

- Units hbar = 1. Pauli matrices in the computational basis, `Z|0> = +|0>`. Projectors `Pi_{A,+-} = (I +- A)/2`, `A` in `{X, Y, Z}`. Tensor factors are written clock first.
- Clock: energies `E_0 < E_1 < ... < E_{N-1}`, `2 <= N <= 64`, `H_C = sum_j E_j |E_j><E_j|`.
- System: `H_S = h0 I + h.sigma`, `h = (hx, hy, hz)`.
- Coupling: `V = sum_j |E_j><E_j| (x) v_j.sigma`, one rational vector `v_j` per level.
- Level vector `n_j = h + v_j`, level norm `R_j = |n_j|` (rational by validity rule 4).
- Reference reading `r` (index of `reference_clock_label`), labels `k = 0 .. M-1`, `tau = povm_tau_turns`, `w = povm_weight`, readings `t_k = 2 pi k tau`.
- `psi_0` is the case's `reference_system_state`, unnormalized and nonzero. `<a|b>` is antilinear in the first slot.
- For a 2-vector `phi = (phi_0, phi_1) != 0`: `P(X+) = 1/2 + Re(conj(phi_0) phi_1)/||phi||^2`, `P(Y+) = 1/2 + Im(conj(phi_0) phi_1)/||phi||^2`, `P(Z+) = |phi_0|^2/||phi||^2`, and `P(A-) = 1 - P(A+)` [ESTABLISHED MATHEMATICS] (expand `<phi|Pi_{A,+}|phi>` with the matrices above).

## 1. The interacting model

**Definition 1.1 (constraint operator)** [ESTABLISHED MATHEMATICS] (`AT1_CASE_V1` section 3, `constraint SUM_HC_HS_V`):

    H_total = H_C (x) I + I (x) H_S + V = sum_j |E_j><E_j| (x) B_j,     B_j = (E_j + h0) I + n_j.sigma.

The second form holds because `V` and `H_C` are both diagonal in the clock energy basis and `I_C = sum_j |E_j><E_j|`.

**Definition 1.2 (level eigenvectors)** [ESTABLISHED MATHEMATICS] (`AT1_CASE_V1` section 3). For `R_j > 0`, `n_j.sigma` has eigenvalues `s R_j`, `s = +1, -1`, and the unnormalized eigenvector

    f_{j,s} = (s R_j + n_{j,z},  n_{j,x} + i n_{j,y})    if that vector is nonzero,
    f_{j,s} = (n_{j,x} - i n_{j,y},  s R_j - n_{j,z})    otherwise.

Its components are Gaussian rationals. Check: `n.sigma f = s R f` reduces to `R^2 = n_x^2 + n_y^2 + n_z^2` in each component. The first form vanishes only when `n_x = n_y = 0` and `s R = -n_z`; then the second form is `(0, -2 n_z)`, which is nonzero. For `R_j = 0`, `B_j = (E_j + h0) I` and every vector is an eigenvector.

**Definition 1.3 (physical state)** [ESTABLISHED MATHEMATICS] (`AT1_CASE_V1` section 3, `physical_state NULLSPACE_PROJECTION`). `|Psi> = P_0 (|t_r> (x) |psi_0>)`, `P_0` the orthogonal projector onto `ker H_total`, with the clock states

    |t_k> = N^(-1/2) sum_j exp(-2 pi i E_j k tau) |E_j>.

**Definition 1.4 (measurement)** [ESTABLISHED MATHEMATICS] (`AT1_CASE_V1` section 3, `AT1_RESULT_V1` section 3). Effects `F_k = w |t_k><t_k|`; conditional vector `phi_k = (<t_k| (x) I) Psi`; clock probability `p(k) = w ||phi_k||^2 / ||Psi||^2`; conditional state `rho_k = phi_k phi_k^dagger / ||phi_k||^2`; Pauli outcome probabilities `P(A, s | k) = Tr(rho_k Pi_{A,s})`.

Nothing in Definitions 1.1 to 1.4 contains an external time parameter. The model is a constraint operator, a vector in its kernel and a measurement [ESTABLISHED MATHEMATICS].

## 2. Theorem 1: block structure and the exact kernel

**Theorem 1 (kernel)** [ESTABLISHED MATHEMATICS]. Call a pair `(j, s)` a kernel pair if `R_j > 0` and `E_j + h0 + s R_j = 0`, and call a level `j` degenerate-matched if `R_j = 0` and `E_j + h0 = 0`. Then

    ker H_total = span{ |E_j> (x) f_{j,s} : (j, s) kernel pair }  (+)  span{ |E_j> (x) |0>, |E_j> (x) |1> : j degenerate-matched },

and `physical_state_kernel_dim = #(kernel pairs) + 2 #(degenerate-matched levels)`.

**Proof.** `H_total` is block diagonal with blocks `B_j` (Definition 1.1), so its kernel is the direct sum of `|E_j> (x) ker B_j`. For `R_j > 0`, `B_j` has eigenvalues `E_j + h0 + s R_j` with eigenvectors `f_{j,s}`; at most one of the two vanishes because `R_j > 0`. For `R_j = 0`, `B_j = (E_j + h0) I` is zero or invertible. Qed.

**Corollary 1.1 (what changed from AT-0)** [ESTABLISHED MATHEMATICS]. In AT-0 (`V = 0`) every level shares the eigenvectors of `h`, and because the `E_j` are distinct at most two levels match, giving dimension 0, 1 or 2 (AT0_SPEC section 13.1). With clock-diagonal coupling each level has its own axis `n_j` and its own norm `R_j`, so every level can contribute: the dimension ranges from 0 to `N + 1` (at most one level can be degenerate-matched, because the `E_j` are distinct and a degenerate match needs `E_j = -h0`; P3b reaches `N + 1`), and two kernel vectors on different levels are in general not orthogonal in the system factor.

**Corollary 1.2 (kernel membership is not continuous in the coupling)** [ESTABLISHED MATHEMATICS]. Level `j` is in the kernel only when `R_j = |E_j + h0|` exactly. Any change of `v_j` that changes `R_j` by any nonzero amount removes the level from the kernel; a change that keeps `R_j` (a rotation of `n_j`) keeps the level and rotates its kernel vector. There is no "small coupling" limit in which the interacting kernel tends continuously to the ideal one for generic perturbations. Section 5.3 quantifies the rotating case; class P6 (section 13.2) is the exact near-miss test.

**Corollary 1.3 (exact stationarity)** [ESTABLISHED MATHEMATICS]. `exp(-i H_total t) Psi = Psi` for every real `t`, because `Psi` lies in the kernel. An external evolution parameter applied to the global state is unobservable, as in AT0_SPEC Corollary 1.1.

**Remark 1.4 (exact decisions)** [ESTABLISHED MATHEMATICS]. The kernel test, the rational-spectrum test (validity rule 4) and the zero test of `Psi` are decided exactly in rational and Gaussian-rational arithmetic (`AT1_CASE_V1` sections 2 and 3). `R_j` is the exact rational square root of `|n_j|^2`. No floating-point comparison enters any of them.

## 3. Theorem 2: the clock POVM

The clock and its POVM are unchanged from AT-0: `V` acts on the system factor only and does not enter `F_k`.

**Theorem 2 (POVM sum)** [ESTABLISHED MATHEMATICS] (AT0_SPEC section 13.1, restated). `sum_k F_k = (w/N) sum_{j,j'} S_{jj'} |E_j><E_j'|` with `S_{jj'} = sum_{k=0}^{M-1} exp(-2 pi i (E_j - E_j') k tau)`. Diagonal: `S_jj = M`. For a gap `D = E_j - E_j' != 0`: `S = M` if `D tau` is an integer; `S = 0` if `D tau M` is an integer and `D tau` is not; otherwise `S = (1 - exp(-2 pi i D tau M)) / (1 - exp(-2 pi i D tau))`. Call the clock **complete** when every gap satisfies the middle condition; then `sum_k F_k = (w M / N) I` and `povm_residual = |w M / N - 1| sqrt(N)`.

**Lemma 2.1 (phase sums used below)** [ESTABLISHED MATHEMATICS]. For a complete clock and any gap `D` between two levels, `sum_{k=0}^{M-1} exp(2 pi i D (k - r) tau) = exp(-2 pi i D r tau) conj(S) = 0`. Proof: Theorem 2 with the common factor taken out.

## 4. Theorem 3: physical state, conditional vector and clock marginal

Write `Pi_j` for the projector onto the kernel part of level `j` in the system factor: `Pi_j = f_{j,s} f_{j,s}^dagger / ||f_{j,s}||^2` for a kernel pair `(j, s)`, `Pi_j = I` for a degenerate-matched level, `Pi_j = 0` otherwise. Define the **level vectors** `u_j = Pi_j psi_0` and `S = sum_j ||u_j||^2`.

**Theorem 3 (closed forms)** [ESTABLISHED MATHEMATICS].

    Psi   = N^(-1/2) sum_j exp(-2 pi i E_j r tau) |E_j> (x) u_j,          ||Psi||^2 = S / N,
    phi_k = (1/N) sum_j exp(+2 pi i E_j (k - r) tau) u_j,
    p(k)  = w ||sum_j exp(2 pi i E_j (k - r) tau) u_j||^2 / (N S).

**Proof.** `P_0 = sum_j |E_j><E_j| (x) Pi_j` by Theorem 1 (the blocks are orthogonal), and `|t_r> (x) psi_0 = N^(-1/2) sum_j exp(-2 pi i E_j r tau) |E_j> (x) psi_0`; apply `P_0`. The norm follows from orthogonality of the `|E_j>`. For `phi_k`, `<t_k|E_j> = N^(-1/2) exp(+2 pi i E_j k tau)` because the bra conjugates the coefficient of `|t_k>`. Multiply and sum. `p(k)` is Definition 1.4 with these two expressions. Qed.

This is the expression in `AT1_CASE_V1` section 3 (sign `+`, fixed at freeze). On a kernel pair `E_j = -h0 - s R_j = -e_{j,s}`, so each term is `exp(-i e_{j,s} (t_k - t_r)) u_j`: forward evolution of the level component under its own level Hamiltonian [ESTABLISHED MATHEMATICS].

**Corollary 3.1 (trivial physical state)** [ESTABLISHED MATHEMATICS]. `Psi = 0` exactly when every `u_j = 0`, that is when `<f_{j,s}|psi_0> = 0` for every kernel pair and no level is degenerate-matched (a degenerate-matched level has `u_j = psi_0 != 0`). This is the exact zero test of `AT1_CASE_V1` section 3; it is decided on the unnormalized `f_{j,s}` with Gaussian-rational arithmetic.

**Corollary 3.2 (only relative phases matter)** [ESTABLISHED MATHEMATICS]. Multiplying `phi_k` by `exp(-2 pi i E_a (k - r) tau)` for any fixed level `a` changes no probability. With `q_{j}(k) = (E_j - E_a)(k - r) tau`, the conditional vector up to a global phase is `sum_j exp(2 pi i q_j(k)) u_j`. When every `4 q_j(k)` is an integer the phases are powers of `i` and every probability in this model is an exact rational.

**Theorem 4 (clock marginal)** [ESTABLISHED MATHEMATICS]. Whenever `Psi != 0`,

    p(k) = (w/N) [ 1 + (2/S) sum_{j < j'} Re( exp(2 pi i (E_j - E_j') (k - r) tau) <u_j'|u_j> ) ].

**Proof.** Expand `||sum_j c_j u_j||^2` with `|c_j| = 1`: the diagonal terms give `S`, the cross terms give `2 Re(c_j conj(c_j') <u_j'|u_j>)`. Qed.

**Corollary 4.1** [ESTABLISHED MATHEMATICS]. (a) The ideal marginal `w/N` (AT0_SPEC section 13.1) holds at every `k` when the level vectors are pairwise orthogonal; with zero coupling this is always so, because distinct matched levels carry the two orthogonal eigenvectors of `h`. (b) In general `|p(k) - w/N| <= (2 w / (N S)) sum_{j < j'} |<u_j'|u_j>|`. (c) For a complete clock `sum_k p(k) = w M / N` (Lemma 2.1 removes every cross term), so the marginal can be label-dependent and still sum to 1. (d) For an incomplete clock the cross terms need not cancel in the sum: a POVM defect can move `sum_k p(k)` even when `w M = N` (class N4b, section 13.4, where the sum is `13/14`). It need not: P2 with `tau = 1/2` has an incomplete clock (gap 2 gives `D tau = 1`), yet the only kernel gap is 1, its phases `(-1)^k` cancel over `M = 4` labels, and the sum stays 1. In AT-0 the sum could not move at all (AT0_SPEC section 13.3, N3).

## 5. Pauli probabilities, the two references, and where the ideal prediction fails

### 5.1 The interacting prediction

**Theorem 5 (interacting conditional probabilities)** [ESTABLISHED MATHEMATICS]. For a label with `p(k) > 0`, `rho_k` is the pure state of `phi_k`, and `P(A, s | k)` is given by the formulas of section 0 applied to `chi_k = sum_j exp(2 pi i q_j(k)) u_j` (Corollary 3.2). This is what `AT1_RESULT_V1` section 3 calls `reference_interacting` when the oracle computes it from the closed form, and what the engine writes as `pauli`.

**Remark 5.1 (purity)** [ESTABLISHED MATHEMATICS]. `rho_k` is pure because `F_k` has rank one and `Psi` is a vector. The Bloch vector `(2P(X+) - 1, 2P(Y+) - 1, 2P(Z+) - 1)` has length 1 for every DEFINED label. This is the exact purity check used in section 13 (every hand table was checked against it).

### 5.2 The ideal prediction

**Definition 5.2 (ideal reference)** [ESTABLISHED MATHEMATICS] (`AT1_RESULT_V1` section 3). `reference_ideal k A s` is `P(A, s)` for `exp(-i H_S (t_k - t_r)) psi_0 / ||psi_0||`, `H_S` alone. The ideal clock marginal is the exact rational `w/N` (`AT1_RESULT_V1` section 3 and check 10). With `H_S = h0 I + h.sigma`, `exp(-i H_S t)` rotates the Bloch vector right-handedly about `h/|h|` by the angle `2 |h| t` (AT0_SPEC section 13.1; `h0` is a global phase).

**Proposition 5.3 (a sufficient condition for the two predictions to coincide)** [ESTABLISHED MATHEMATICS]. Let `Pi_j^0` be the level projectors of the same case with every `v_j` set to zero (the AT-0 model). If `Pi_j = Pi_j^0` for every level `j`, and `Pi_K^0 psi_0 = psi_0` where `Pi_K^0 = sum_j Pi_j^0` (full cover; `psi_0 != 0` by validity rule 3), then `p(k) = w/N` and the interacting conditional probabilities equal `reference_ideal` at every label. **Proof.** The level vectors are then the AT-0 ones; AT0_SPEC section 13.1 gives `phi_k = (1/N) exp(-i H_S (t_k - t_r)) Pi_K^0 psi_0` and the uniform marginal (for `h != 0` the matched AT-0 eigenvectors are orthogonal, so `Pi_K^0` is a projector); full cover makes `Pi_K^0 psi_0 = psi_0`. Qed. The condition is sufficient, not necessary: for example `E = (-1, 1)`, `h = (0, 0, 1/2)`, `v_0 = (0, 0, 1/2)`, `v_1 = 0`, `psi_0 = |0>` changes the kernel (the zero-coupling kernel is empty; with the coupling, level 0 joins it with vector `|0>`) yet gives the ideal values, because `psi_0 = |0>` is an eigenvector of `H_S` and is itself the only kernel vector, so both predictions are the constant state `|0>` with marginal `w/N`. In particular **a coupling that acts only on levels that are outside the kernel both with and without the coupling leaves every `Pi_j` unchanged, and so changes nothing observable** (class P1c): the ideal prediction is then exact although `V != 0`.

### 5.3 How much the ideal prediction fails

Three mechanisms. The formulas are exact [ESTABLISHED MATHEMATICS]; how large the effect is in a given case depends on `psi_0` and the phases, and section 13.3 gives the sizes for every public case.

1. **Rotated kernel axis.** A level with `R_j = |h|` but `n_j` at angle `theta` to `h` stays in the kernel (Corollary 1.2) with a rotated kernel vector. If the other kernel level carries the opposite eigenvector of `h`, the overlap is `|<f_hat_{a,-s}(h)|f_hat_{j,s}(n_j)>| = sin(theta/2)` (the Bloch vectors are at angle `pi - theta`, and `|<a|b>|^2 = cos^2(angle/2)`). Then `|<u_j|u_a>| = |c_a| |c_j| sin(theta/2)` with `c = <f_hat|psi_0>` (normalized eigenvectors), and Theorem 4 gives a marginal oscillating about `w/N` with amplitude `(2 w / (N S)) |c_a| |c_j| sin(theta/2)`. The coefficients `c_j` and `S` themselves depend on `theta` and can vanish, so this is the exact amplitude, not a claim that the deviation is always first order in `theta`. Worked example (P2): `cos theta = 4/5`, `sin(theta/2) = 1/sqrt(10)`, amplitude `1/14`.
2. **Changed level norm.** A level whose `R_j` differs from `|E_j + h0|` leaves the kernel entirely (Corollary 1.2). The conditional state loses that component. If `psi_0` had a nonzero component there, the deviation can stay finite as the perturbation of `v_j` tends to zero (class N2, and the P6 near miss in the other direction); if the component was zero, nothing changes.
3. **Swapped or degenerate level.** `v_j = -2h` keeps `R_j = |h|` but swaps the eigenvectors, so two levels can carry the same system vector and interfere (class N3: `p(k)` reaches exactly 0). `v_j = -h` makes `R_j = 0`; when also `E_j = -h0` the level is degenerate-matched and contributes all of `psi_0` (class P3b); otherwise it leaves the kernel.

The per-case sizes are in section 13.3. In all cases the deviation is a property of the finite model as specified, computed exactly; it is not a prediction about any physical clock [ESTABLISHED MATHEMATICS].

## 6. Internal clock labels versus external wall-clock time

Unchanged from AT0_SPEC section 6 [ESTABLISHED MATHEMATICS]: the clock label `k` (and the dictionary value `t_k = 2 pi k tau`) is declared data in the case and enters `case_id`; the external parameter `t` of `exp(-i H_total t)` acts trivially on `Psi` (Corollary 1.3) and is not a field; wall-clock time of an execution lives only in result provenance and enters only `evidence_digest`. RULE, consequences required of implementations (tests in section 9): the values block depends on the case only; labels can be evaluated in any order with bit-identical values on one build; no clock, timer or random source is called; no `t` is applied to `Psi`. The interaction does not change any of this: `V` is part of the constraint, not a time-dependent drive [ESTABLISHED MATHEMATICS].

## 7. Why this model is still idealized

Each item is a limit derived from the construction and must be stated in any report citing AT-1 results [ESTABLISHED MATHEMATICS]:

1. **Clock-diagonal coupling only.** `V` commutes with `H_C`, so the clock energy is conserved level by level and the clock is never disturbed in its own basis. Couplings that are not clock-diagonal (energy exchange between clock and system) are outside V1 (charter section 3 item 2).
2. **Exact kernel, no near-kernel.** The physical state lives in the exact kernel. A constraint satisfied only approximately (a smeared kernel) is not modelled; Corollary 1.2 shows the exact construction is discontinuous in the coupling strength.
3. **Pure global state, rank-one effects.** Conditional states are pure (Remark 5.1). Decoherence, mixed global states and coarse-grained clocks are not modelled.
4. **One qubit, finite clock, phase readings.** The system has two levels; the clock reads phase modulo one period of the smallest gap structure; there is no continuum and no arrow of time (AT0_SPEC section 7, items 1, 2, 4).
5. **Kinematics only.** Everything is linear algebra on one fixed vector. The model exhibits correlations that read as dynamics when conditioned on a clock label; it does not generate dynamics (AT0_SPEC section 7, item 7).

## 8. Invariants, label status, oracle quantities, numerical policy

### 8.1 Invariants and the checks that judge them

| Id | Exact statement | Written quantity (`AT1_RESULT_V1` section 3) | Check (section 4) |
|---|---|---|---|
| I1 | `H_total Psi = 0` (Theorem 1) | `constraint_residual = ||H_total Psi_hat||`, `V` included | 4 |
| I2 | kernel dimension by Theorem 1; `Psi != 0` by Corollary 3.1 | `physical_state_kernel_dim` | 3 |
| I3 | `sum_k F_k = I` for a complete clock with `w M = N` (Theorem 2) | `povm_residual` | 5 |
| I4 | `sum_k p(k) = w M / N` for a complete clock (Corollary 4.1c) | `clock_probability` | 6, 7 |
| I5 | `P(A+|k) + P(A-|k) = 1`, each in `[0, 1]` | `pauli` | 7, 8 |
| I6 | label status by the rule of 8.2 | `label` | 9 |
| I7 | engine equals the reference named by `prediction_target`, Pauli values and marginal | `pauli`, `clock_probability` vs `reference_ideal` and `w/N`, or vs `reference_interacting` and `reference_clock_probability` | 10 |
| I8 | engine equals the interacting reference when the target is IDEAL | `pauli`, `clock_probability` vs `reference_interacting`, `reference_clock_probability` | 11 |
| I9 | engine and oracle agree on every label's status | `label` vs `reference_label` | 12 |
| I10 | `rho_k` pure (Remark 5.1) | derived from `pauli` | not a V1 check; test T6 |

All rows are [ESTABLISHED MATHEMATICS] (definitions cited, statements proved above).

### 8.2 Label status and the oracle lines

[ESTABLISHED MATHEMATICS] (definitions, `AT1_RESULT_V1` sections 1 and 3):

- Status rule, applied by the engine to its `clock_probability` and bound, and independently by the oracle to its `reference_clock_probability` and bound: `UNDEFINED` if `p(k) + bound <= tol_zero_probability`; `DEFINED` if `p(k) - bound > tol_zero_probability`; else `INDETERMINATE`.
- An engine label that is not DEFINED writes six `pauli ... undefined 0@0` lines. The oracle writes six `reference_interacting ... undefined 0@0` lines exactly when its own status is not DEFINED. `reference_ideal` is always a value.
- `reference_clock_probability k` is the oracle's own Theorem 3 value; `reference_label k` is its own status. The oracle never sees the engine's numbers.
- Checks 10 and 11 run only on labels DEFINED on both sides; a label DEFINED on one side only fails check 12 (`ORACLE_DISAGREEMENT`), and an INDETERMINATE label on either side makes check 12 INDETERMINATE (adding `PRECISION_INSUFFICIENT`).
- Trivial kernel (`physical_state_kernel_dim 0` or `Psi` exactly zero): every status UNDEFINED, check 3 FAIL, checks 4 and 6 to 12 NOT_EVALUATED, checks 1, 2, 5 evaluated; `povm_residual` and `reference_ideal` still written.

### 8.3 Tolerances

RULE (justified by 8.4): public AT-1 cases use the worked example's tolerances, `1@12` for `tol_constraint_residual`, `tol_povm_residual`, `tol_probability`, `tol_schrodinger`, and `1@9` for `tol_zero_probability`, with `min_bound_kind ESTIMATED` except class N5. Comparisons are absolute, never relative, as in AT0_SPEC section 8.2, because exact probabilities 0 and 1 occur.

RULE (margins, so that platform rounding cannot flip a check; needed for gate G7): in every public and hidden case, (a) each quantity that a check compares has an exact deviation of either 0 or at least `10^3` times its tolerance; (b) each label has `p(k) = 0` exactly or `p(k) >= 10^-3`. Every case in sections 13.2 to 13.4 satisfies both. The smallest nonzero compared deviation in those cases is P5's marginal at `k = 0` and `k = 2` under target IDEAL, `|p(k) - 1/4| = 1/1048358`, about `9.5e-7`, which is `9.5e5` times `tol_probability` [ESTABLISHED MATHEMATICS] (from the exact P5 table). Under target INTERACTING every compared deviation of a correct engine is exactly 0.

### 8.4 Numerical error analysis and traps

Let `eps = 2^-53`.

1. **Phase reduction (trap).** [ESTABLISHED MATHEMATICS] The phase `2 pi E_j (k - r) tau` must be computed by reducing the turn count `E_j (k - r) tau` modulo 1 exactly in integer arithmetic, then multiplying the fraction by `2 pi`. Within the token limits the numerator is at most `2^20 * 255 * 2^20 < 2^48` and the denominator at most `2^40`, so signed 64-bit integers suffice. Without reduction the turn count can reach about `2.8e14`, where adjacent binary64 values are `1/16` turn apart, and the phase is meaningless. The same applies to the separate factors `exp(-2 pi i E_j r tau)` and `exp(+2 pi i E_j k tau)` if an implementation forms them separately. RULE: engine and oracle both reduce exactly.
2. **Ideal-reference angle.** The rotation angle is `2 pi * 2 |h| (k - r) tau`. When `|h|` is rational (always so when some `v_j = 0`, since rule 4 then covers `h` itself) the turn count `2 |h| (k - r) tau` is reduced exactly as in item 1 [ESTABLISHED MATHEMATICS]. Rule 4 is per level, so `|h|` may be irrational when every `v_j != 0`; then the turn count is a binary64 quantity whose error grows linearly with its size. [HYPOTHESIS] (an estimate, not a proved bound: it assumes about `3 eps` relative error from forming `sqrt(hx^2 + hy^2 + hz^2)` and the products) the angle error is about `2 pi * 3 eps * |2 |h| (k - r) tau|`. RULE: in such cases keep `|2 |h| (k - r) tau| <= 64`, for which that estimate is about `1.3e-13`; an oracle that reports a bound must derive its own.
3. **Build `Psi` from the exact kernel pairs (trap).** [COMPUTATIONAL DEMONSTRATION] A projector formed numerically from the matrix `H_total` (by eigen-decomposition with a threshold, or by the product of `(H - l)/(-l)` over the nonzero eigenvalues `l`) loses accuracy in proportion to `1 / delta_min`, `delta_min` the smallest nonzero `|E_j + h0 + s R_j|`. In class P6, `delta_min = 2^-20`; the scratch literal checker built that way in binary64 gave probability errors up to `9.6e-11` and `constraint_residual = 1.4e-10`, which fails `tol_constraint_residual 1@12`. The same checker in `long double` (binary128 on the Spark's gcc 13.3 aarch64 build, `LDBL_MANT_DIG = 113`), and a binary64 evaluation of Theorem 3 from the exact kernel pairs, both agree with exact arithmetic to `1e-15` or better on every case. RULE: engine and oracle construct `Psi` and `phi_k` from the exact kernel pairs and level vectors (Theorems 1 and 3), not from a numerical projector. Proof obligation O2.
4. **Conditioning of small labels.** [ESTABLISHED MATHEMATICS] (first-order perturbation statement only) If the vector `chi_k` (Corollary 3.2) is computed with an absolute error `Delta chi_k`, then each conditional probability moves by at most `2 ||Delta chi_k|| / ||chi_k||` to first order (a ratio of quadratic forms in `chi_k`), and `||chi_k||^2 = N S p(k) / w` (Theorem 3). So for a fixed error in forming `chi_k`, the conditional probabilities of a label degrade like `1 / sqrt(p(k))`. [HYPOTHESIS] (estimate) For a straightforward evaluation, `||Delta chi_k||` is a small multiple of `eps sum_j ||u_j||` (input conversion of the rationals, the level-vector arithmetic, the exactly reduced phases of item 1 passed through `cos` and `sin` with errors of about one ulp, and an `L`-term sum), giving a relative error of order `eps sqrt(L w / (N p(k)))` times an implementation constant. This is why rule (b) of section 8.3 keeps `p(k) >= 10^-3`. It is not a complete error bound; an implementation reporting `ESTIMATED` gives its own full accounting (item 6).
5. **Measured.** [COMPUTATIONAL DEMONSTRATION] For the scratch builds of section 12.2 on the Spark only: binary64 evaluation of Theorem 3 from exact kernel pairs matched exact arithmetic on every DEFINED value in section 13 to at most `5.6e-16` (P5, which has the largest tokens). For every case whose exact sum is 1, binary64 `sum_k p(k) - 1` was at most `2.2e-16` in magnitude; for every complete clock with `w M = N`, `povm_residual` was `0` to printed precision (N4a and N4b are deliberate failures with exact sums `1/2` and `13/14` and residuals `1` and `sqrt(42)/4`, reproduced to the same precision). `constraint_residual` was at most `2.7e-15` with the matrix path (P6 excepted, item 3).
6. **`bound_kind`.** An implementation reporting `ESTIMATED` cites its own version of items 1 to 4 with its constants; `RIGOROUS` needs directed-rounding interval arithmetic including enclosures of `cos` and `sin`, and is not assumed here (as AT0_SPEC section 8.3) [ESTABLISHED MATHEMATICS].

## 9. Tests, controls and mutants

### 9.1 Positive and invariance tests

Each test is [ESTABLISHED MATHEMATICS] as a statement about the model; whether an implementation passes it is what the gates measure.

| Id | Test | Expected |
|---|---|---|
| T1 | every positive case of section 13.2 | values equal the tables; outcome PASS |
| T2 | P1 against AT-0 | probabilities equal AT0_SPEC section 13.2 P1 exactly (zero coupling reduces Theorem 3 to AT0_SPEC 13.1) |
| T3 | spectator coupling P1c, target IDEAL | PASS although `V != 0` (Proposition 5.3) |
| T4 | global phase of `psi_0` multiplied by `i` | identical probabilities |
| T5 | scale of `psi_0` multiplied by 2 | identical probabilities (`p(k)` and `rho_k` are ratios) |
| T6 | purity from `pauli` lines of every DEFINED label | `(2P(X+)-1)^2 + (2P(Y+)-1)^2 + (2P(Z+)-1)^2 = 1` within `8 tol_probability` (AT0_SPEC T6 argument) |
| T7 | reference reading shift: P4 with `r = 1` versus `r = 0` | the `r = 1` table is the `r = 0` table relabelled `k -> k - 1` modulo `M` (Theorem 3 depends on `k - r` only, and every phase there has period dividing `M`) |
| T8 | label evaluation order reversed | RULE (implementation requirement, not a theorem): bit-identical values block on one build |
| T9 | wall-clock independence (same case run twice) | identical `case_id`, `acceptance_id`, `verdict_id`, values block; `evidence_digest` may differ, and must differ whenever the covered evidence bytes differ (for example a different `run_started_utc` second) |
| T10 | cross-platform (gate G7) | identical `verdict_id` on every public case (section 12.3); values may differ in the last bits. [HYPOTHESIS] The measured cross-implementation differences of about `1e-15` stay far inside the 8.3 margins on the second platform. |

### 9.2 Mutants (Agent 4 builds them; this section states what each must produce)

Measured with the scratch literal checker's mutant modes [COMPUTATIONAL DEMONSTRATION]; the statements about which cases are blind follow from Proposition 5.3 and Corollary 3.2 [ESTABLISHED MATHEMATICS]. "Max deviation" is the largest `|mutant - reference_interacting|` over DEFINED labels, all three axes.

| Mutant | P1 | P1c | P2 | P3 | P3b | P4 | P5 | P6 | Expected detection |
|---|---|---|---|---|---|---|---|---|---|
| M1 drop `V` | blind | blind | 0.30 | 0.40 | 1.00 | 0.268 | 0.50 | 0.98 | check 10 under INTERACTING (`INTERACTING_DEVIATION_EXCEEDED`); under IDEAL (N1 family) check 10 passes and check 11 fails (`ORACLE_DISAGREEMENT`), so expectation is not met |
| M2 flip sign of `V` | blind | blind | 0.48 | trivial | 0.66 | 0.50 | 0.0014 | trivial | as M1, or `TRIVIAL_PHYSICAL_STATE` where flipping empties the kernel |
| M3 `v_j` applied to level `j+1 mod N` | blind | 0.50 | 0.30 | 0.80 | 0.77 | 0.268 | 0.80 | trivial | as M1 or M2 |
| M4 pre-freeze phase sign `exp(-2 pi i E_j (k - r) tau)` | 1.00 | 1.00 | 0.86 | 0.86 | 0.95 | 0.89 | 0.0028 | blind | check 10; P6 is blind because its only relative phase is `(-1)^k`, which is real |
| M5 Y-sign swap, M6 axis swap (AT-0 controls) | | | | | | | | | as AT0_SPEC U7, U8: Y-sign is visible on every label with `P(Y+) != 1/2` |
| M7 counter and raw-syscall clock reads | | | | | | | | | isolation gate G2 (charter section 3 item 5), never run |

Blindness is by design and must be reported per case, as in AT-0: M1 to M3 cannot be seen on P1 because `V = 0` there; on P1c the coupling sits outside the kernel, so M1 and M2 are blind and only M3 (which moves a coupling onto a kernel level) is visible. Every mutant is visible on P2, P3, P3b and P4.

## 10. Proof obligations for the implementations

| Id | Obligation | Discharged by |
|---|---|---|
| O1 | Engine builds `H_total` (with `V`), `Psi` and `{F_k}` from the case text only; no wall clock; no `t` applied to `Psi` | code review, gate G2, tests T8, T9 |
| O2 | Kernel pairs, degenerate-matched levels and the zero test are decided exactly (Remark 1.4); `Psi` and `phi_k` are built from them (8.4 item 3) | classes P5, P6, N2, N6; code review |
| O3 | Phases reduced exactly (8.4 item 1) | P5; code review |
| O4 | Every `pauli` value computed directly from `rho_k`, never as `1 - other` | code review; M5 |
| O5 | Oracle shares no code with the engine; `reference_ideal` uses `H_S` only; `reference_interacting` and `reference_clock_probability` use Theorem 3 by the oracle's own path | gate G3 against section 13; M1 on the N1 family |
| O6 | `bound_kind` honest (8.4 item 6) | Agent 2 and 3 notes; N5 |
| O7 | Every negative case fails with exactly its expected code set | gate G5 |
| O8 | Replication inputs and separation as section 12.3 | gate G7 |

Statements about obligations are definitions of what the gates require [ESTABLISHED MATHEMATICS]; whether they are met is decided only by the gate runs.

## 11. What follows from the construction, and what would need an experiment

**Follows from the construction** [ESTABLISHED MATHEMATICS]:

1. With a clock-diagonal coupling, the constraint kernel is still exactly computable level by level (Theorem 1), and the conditional states and clock marginals have closed forms (Theorems 3 to 5).
2. The deviation of the interacting prediction from the ideal relational prediction (Schrodinger evolution under `H_S` alone, uniform marginal `w/N`) is given in closed form for every case (Theorems 3 to 5, section 5.3, table 13.3). A sufficient condition for no deviation is that every level projector equals its zero-coupling value and the zero-coupling kernel covers `psi_0` (Proposition 5.3); in particular a coupling that acts only on levels outside the kernel changes nothing.
3. Kernel membership is discontinuous in the coupling strength and continuous in its direction (Corollary 1.2).
4. Interaction can couple POVM defects into the clock marginal sum (Corollary 4.1d).
5. [COMPUTATIONAL DEMONSTRATION] The scratch binary64 closed-form evaluation of section 12.2, built as section 8.4 prescribes, met every tolerance of section 8.3 on the section 13 cases on the Spark, with errors at most `5.6e-16` against `1e-12` (section 8.4 item 5). [HYPOTHESIS] Agent 3's engine and Agent 2's oracle, built the same way, will show errors of the same order on both platforms.

**Not established here** (each would need physics or further theory, none of it in AT-1) [EXPERIMENTAL PHYSICS: none in AT-1]:

1. That physical time is emergent, relational or absent at a fundamental level.
2. That any laboratory clock couples to anything in a clock-diagonal way, or that its readings behave like `F_k`.
3. That the deviations of section 5.3 have any counterpart in nature.
4. Anything about non-clock-diagonal coupling, mixed states, larger systems or automatic clock discovery (deferred by Drake).

[ESTABLISHED MATHEMATICS] (a statement of what the gates measure, not a result) A passing AT-1 run, on one machine or two, is evidence that independent implementations reproduce the mathematics of sections 2 to 5 for the cases run, and that the verdicts did not depend on the machines and builds that were tested. AT-1's success criterion, verbatim from the charter: "Reproducible, independently evaluated interacting-system results, not proof that time is emergent."

## 12. Discrepancies, scratch verification, replication, contract notes

### 12.1 Discrepancies and observations (recorded, not resolved; resolution belongs to Agent 0)

1. `AT1_RESULT_V1` section 1, last paragraph, says "The runner splices only the oracle's two reference line families into the candidate result", while sections 0 and 1 define four oracle families (`reference_label`, `reference_clock_probability`, `reference_ideal`, `reference_interacting`). This specification reads "two" as a carry-over from the AT-0 single `reference` family and assumes all four oracle families are spliced. Raised on omega#371 for a ruling; nothing in section 13 depends on it.
2. `AT1_CASE_V1` section 1 checks the three version-bearing lines "for key and placement in step 1 and for their value in step 2". It does not say whether the header's first token (`OMEGA-AT1-CASE`) is the key or part of the value, so an `AT0_CASE_V1` file (header `OMEGA-AT0-CASE v1`) given to an AT-1 tool has two defensible codes (`CASE_PARSE_ERROR`, `CASE_UNSUPPORTED_VERSION`). Section 13.5 uses only `OMEGA-AT1-CASE v2`, which is unambiguous. Raised on omega#371.
3. Validity rule 4 is per level, so `h` itself may have an irrational norm when every `v_j != 0`. Such a case is valid as written; section 8.4 item 2 gives the numerical rule for its ideal reference. Not a contract question.
4. The pre-freeze draft sign in the conditional vector (quoted in the Opus review on omega#371) is mutant M4 here. Its effect is zero on P6, small on P5 (`0.0028`), and up to `1.0` elsewhere [COMPUTATIONAL DEMONSTRATION].

### 12.2 Scratch verification

Two independent std-only scratch programs (not project code, not evidence), kept at `~/.claude/jobs/85679b2b/tmp/at1-agent1/` on the Spark:

- `exact.rs` (Rust, std only): Gaussian rationals over checked `i128`; kernel pairs by Theorem 1 with exact square roots; level vectors from the contract's unnormalized eigenvectors; `chi_k` with quarter-turn phases (Corollary 3.2); exact `p(k)`, Pauli values and ideal reference. It also evaluates Theorem 3 in binary64 from the exact kernel pairs, with phases reduced exactly.
- `literal.c` (C11, `-lm`): builds `H_total = H_C (x) I + I (x) H_S + V` as a `2N x 2N` matrix, forms `P_0` as a product over the nonzero eigenvalues, `Psi = P_0 (|t_r> (x) psi_0)`, `phi_k` by applying `<t_k|` literally, Pauli values by projector matrices, the ideal reference by the 2x2 propagator, `povm_residual` and `constraint_residual`; plus four mutant modes. Built in `long double` (`literal.c`; binary128 on the Spark, gcc 13.3 aarch64, `LDBL_MANT_DIG = 113`) and binary64 (`literal_f64.c`).

[COMPUTATIONAL DEMONSTRATION] Results: the exact and `long double` literal paths agree on all 79 overlapping value lines (clock probability, three Pauli values, three ideal values per DEFINED label, cases P1, P1c, P2, P3, P3b, P4, P5, P6, N3, N4a) to `1.0e-15`; kernel dimensions and trivial-kernel decisions agree on all 13 cases; N4b (phases not quarter turns) is confirmed by the literal path and by hand (sum `13/14`, `povm_residual = sqrt(42)/4`); the binary64 closed-form path agrees with exact to `5.6e-16`; the binary64 matrix-projector path fails on P6 as described in section 8.4 item 3. Every exact table in section 13 was also derived by hand and checked for purity (Remark 5.1).

### 12.3 Second operator on a second platform (gate G7) at the spec level

The charter (section 3 items 6 and 7) fixes the mechanism; this section fixes what the mathematics needs from it. These are requirements of this specification [ESTABLISHED MATHEMATICS] (definitions), except where marked.

**What the replicating operator (Agent 7) receives:** (a) the frozen contract files `AT1_CASE_V1.md`, `AT1_RESULT_V1.md` and `AT0_RESULT_V2.md`, checked against their freeze digests; (b) this specification and the charter at their merged commits; (c) the candidate omega commit posted by Agent 0 at freeze, as source only, cloned fresh on the second machine; (d) the public case set at that commit; (e) after its own evidence folder is committed, the Spark run's `verdict_id` list for comparison.

**What the replicating operator must not receive or use:** (a) binaries, object files, build logs or result files produced on the Spark; (b) the Spark run's values blocks or verdicts before its own run is committed (so agreement cannot be copied); (c) write access to any AT-1 path other than `evidence/AT1/replication-<host>/`; (d) any input from the candidate authors (Agents 2 to 5) about its hidden cases.

**What the candidate authors must not receive:** Agent 7's hidden case files or their expected codes before the candidate freeze. They receive only the SHA-256 commitment of the hidden set, posted on omega#371 before freeze (charter section 3 item 6a).

**How the restrictions are enforced (RULE; what cannot be enforced is stated):**

1. Source-only checkout: Agent 7 obtains the candidate as a single-commit checkout of the frozen candidate commit (`git clone --depth 1` of that commit, or `git archive` of it), so no later commit, result history or Spark evidence folder is present on the second machine at build time.
2. Hidden cases stay off every shared system until reveal: they are written and kept only on the second machine, outside any git repository, until the candidate freeze has been posted.
3. Commitment procedure: Agent 7 writes a manifest with one line per hidden case file, `<sha256 of the file bytes><two spaces><file name>`, sorted bytewise by file name, LF-terminated; the commitment is the SHA-256 of the manifest bytes, posted on omega#371 before freeze. At reveal, the manifest and the files are committed to `evidence/AT1/replication-<host>/` and anyone can recompute the commitment.
4. No peeking at the Spark results: Agent 7 commits its own evidence folder, including its `verdict_id` list, before opening any Spark result file; the commit order on GitHub records this.
5. Known limit (charter section 1 and section 3 item 6d, which lists the account among the separation facts): all GitHub activity is one account, so read isolation between Spark sessions and Agent 7 is procedural (separate machines, separate sessions, the commitment digest and the commit order), not enforced by access control. Agent 6 grades it as such.

**How Agent 7 builds hidden cases from this specification:** from the families of section 13.1 with its own parameter choices: other clock grids and `tau`, other rational unit axes for rotated levels (any Pythagorean quadruple `(a, b, c, d)` with `a^2 + b^2 + c^2 = d^2` gives the axis `(a, b, c)/d`), other `psi_0`, other reference labels, and the negative constructions (norm change for N2, `v_j = -2h` for N3, a `psi_0` orthogonal to every kernel vector for N6). Expected codes come from Theorems 1 to 5 by hand or by Agent 7's own scratch computation. Every hidden case obeys the margin rule of section 8.3.

**What agreement means:** equal `verdict_id` on every public case. `verdict_id` covers the case identity, the acceptance identity and the discrete verdict block, never floating-point values (`AT1_RESULT_V1` section 6), so two correct implementations on different hardware, operating systems, C libraries and compilers reach the same `verdict_id` whenever no compared quantity sits near its tolerance. The margin rule makes that so for the section 13 cases. [ESTABLISHED MATHEMATICS] for the margins themselves; [HYPOTHESIS] that the second platform's libm and compiler stay within the measured `1e-15` scale.

### 12.4 Mapping onto `AT1_CASE_V1`

Every case in sections 13.2 to 13.4 is a valid `AT1_CASE_V1` semantic block (the section 13.5 files are deliberately invalid) with: `clock_energies` and `interaction_pauli` as listed, `system_hamiltonian_pauli h0,hx,hy,hz`, `reference_system_state` as listed (written `(re;im)` per component), `clock_label_count M` with labels `t0 .. t{M-1}`, and the acceptance tolerances of section 8.3. Agent 4 owns the case files and their digests; the worked example's digests are fixed in `AT1_CASE_V1` section 6.

## 13. Hand-derived answer tables for the charter section 6 case classes

Every row below was derived by hand from section 13.1 and reproduced by both scratch checkers (section 12.2). Unless a row says otherwise, the case uses the **base clock B**: `N = 4`, `E = (-3/2, -1/2, 1/2, 3/2)`, `h0 = 0`, `h = (0, 0, 1/2)`, `psi_0 = (1, 1)`, `r = 0`, `tau = 1/4`, `w = 1`, `M = 4`. Gaps 1, 2, 3 with `tau M = 1` and `tau = 1/4`: complete, `sum F_k = I`, `povm_residual = 0` (Theorem 2). The rotated coupling `rho = (3/10, 0, -1/10)` gives on a base level `n = (3/10, 0, 2/5)`, `R = 1/2`, axis `(3/5, 0, 4/5)`, and `f_{-} = (-1/10, 3/10)`, proportional to `(-1, 3)`.

All exact values in 13.2 to 13.4 are [ESTABLISHED MATHEMATICS]; their agreement with the checkers is [COMPUTATIONAL DEMONSTRATION].

### 13.1 General formulas (derived once, used by every row)

1. Kernel pairs: `(j, s)` with `R_j > 0` and `E_j + h0 + s R_j = 0`; degenerate-matched levels: `R_j = 0` and `E_j + h0 = 0` (Theorem 1).
2. Level vectors: `u_j = f (f^dagger psi_0) / ||f||^2` for a kernel pair with `f = f_{j,s}`, `u_j = psi_0` for a degenerate-matched level, else 0. `S = sum_j ||u_j||^2`.
3. Conditional vector up to a global phase: `chi_k = sum_j exp(2 pi i (E_j - E_a)(k - r) tau) u_j`, any fixed level `a` (Corollary 3.2).
4. Clock marginal `p(k) = w ||chi_k||^2 / (N S)` (Theorem 3); deviation formula Theorem 4.
5. Pauli values from `chi_k` by the section 0 formulas. Ideal values from `exp(-i H_S (t_k - t_r)) psi_0` by the rotation of Definition 5.2.
6. Expected check vector, in `AT1_RESULT_V1` section 4 order (1 to 12): for a positive case with target INTERACTING, checks 1 to 10 PASS, 11 NOT_EVALUATED, 12 PASS; with target IDEAL and agreeing references, 1 to 12 PASS.
7. Families for new instances (hidden sets): rotated level with axis `(a, b, c)/d` from a Pythagorean quadruple and norm `|E_j + h0|`; spectator level with any `R_j != |E_j + h0|`; swapped level `v_j = -2h`; degenerate level `v_j = -h` with `E_j = -h0`.

### 13.2 Positive classes (expected outcome PASS, codes none)

**P1, zero coupling (continuity with AT-0).** B with every `v_j = 0`. Kernel `{(1, +), (2, -)}` with `f = (1, 0)` and `(0, -1)`, dimension 2; `u_1 = (1, 0)`, `u_2 = (0, 1)`, orthogonal, so `p(k) = 1/4` (Corollary 4.1a). `chi_k = (1, i^k)`.

| k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|
| 0 | 1/4 | 1 | 1/2 | 1/2 | 1, 1/2, 1/2 |
| 1 | 1/4 | 1/2 | 1 | 1/2 | 1/2, 1, 1/2 |
| 2 | 1/4 | 0 | 1/2 | 1/2 | 0, 1/2, 1/2 |
| 3 | 1/4 | 1/2 | 0 | 1/2 | 1/2, 0, 1/2 |

Identical to AT0_SPEC section 13.2 P1 and `AT0_CASE_V1` section 6. Instances: P1a target INTERACTING, P1b target IDEAL; both PASS, the two references coincide (Proposition 5.3). "Verdict-equivalent" to AT-0 means outcome PASS with failure set `none` and the same probabilities; the `verdict_id` itself differs because the domain tag and the check list differ (`AT1_RESULT_V1` section 6).

**P1c, spectator coupling.** B with `v_0 = (0, 0, 1/2)` (`R_0 = 1`, `E_0 = -3/2` does not match `+-1`) and `v_3 = rho` (`R_3 = 1/2`, `E_3 = 3/2` does not match `+-1/2`). Kernel and level vectors as P1, so the table is P1's. Target IDEAL: PASS with `V != 0` (Proposition 5.3). Of the coupling mutants M1 to M3 only M3 is visible here (it moves `v_0` onto level 1, whose norm becomes 1, so level 1 leaves the kernel).

**P2, one rotated level: the worked example `at1-kat-rotated-level-n4`** (`AT1_CASE_V1` section 6; B with `v_2 = rho`, others 0; target INTERACTING). Kernel `{(1, +), (2, -)}`, dimension 2, with `f_{1,+} = (1, 0)` and `f_{2,-} = (-1/10, 3/10)`. With `psi_0 = (1, 1)`: `u_1 = (1, 0)`, `u_2 = (-1, 3)(2)/10 = (-1/5, 3/5)`, `S = 1 + 2/5 = 7/5`, `||Psi||^2 = 7/20` (the frozen text's `7/40` is for the normalized `psi_0`). `<u_2|u_1> = -1/5`. Relative phase of level 2 to level 1: `exp(2 pi i k/4) = i^k`. Scaling by 5: `chi_k = (5 - i^k, 3 i^k)`, `||chi_k||^2 = 35 - 10 cos(pi k/2)`. Theorem 4: `p(k) = (1/4)[1 + (2/(7/5)) Re(i^(-k) (-1/5))] = 1/4 - cos(pi k/2)/14`.

| k | chi_k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|---|
| 0 | (4, 3) | 5/28 | 49/50 | 1/2 | 16/25 | 1, 1/2, 1/2 |
| 1 | (5-i, 3i) | 1/4 | 29/70 | 13/14 | 26/35 | 1/2, 1, 1/2 |
| 2 | (6, -3) | 9/28 | 1/10 | 1/2 | 4/5 | 0, 1/2, 1/2 |
| 3 | (5+i, -3i) | 1/4 | 29/70 | 1/14 | 26/35 | 1/2, 0, 1/2 |

Example entry, `k = 1`: `conj(5 - i)(3i) = (5 + i)(3i) = -3 + 15i`, `||chi||^2 = 26 + 9 = 35`, so `P(X+) = 1/2 - 3/35 = 29/70`, `P(Y+) = 1/2 + 15/35 = 13/14`, `P(Z+) = 26/35`. Purity: Bloch `(-6/35, 30/35, 17/35)`, `36 + 900 + 289 = 1225 = 35^2`. The clock marginal matches `AT1_CASE_V1` section 6 (`5/28, 1/4, 9/28, 1/4`). The `Y` column at `k = 1, 3` is the one the pre-freeze sign would have swapped.

**P3, every level coupled.** `N = 3`, `E = (-1/2, 1/2, 3/2)`, `h0 = 0`, `h = (0, 0, 1/2)`, `v_0 = rho`, `v_1 = (0, 3/10, -1/10)`, `v_2 = (6/5, 0, 2/5)`, `psi_0 = (1, 1)`, `r = 0`, `tau = 1/4`, `w = 3/4`, `M = 4`; target INTERACTING. Levels: `n_0 = (3/10, 0, 2/5)`, `R_0 = 1/2`, pair `(0, +)`, `f = (9/10, 3/10)`; `n_1 = (0, 3/10, 2/5)`, `R_1 = 1/2`, pair `(1, -)`, `f = (-1/10, 3i/10)`; `n_2 = (6/5, 0, 9/10)`, `R_2 = 3/2`, pair `(2, -)`, `f = (-3/5, 6/5)`. Dimension 3 (no AT-0 case can exceed 2). `u_0 = (6/5, 2/5)`, `u_1 = ((1+3i)/10, (9-3i)/10)`, `u_2 = (-1/5, 2/5)`, `S = 8/5 + 1 + 1/5 = 14/5`. Gaps 1, 2 with `tau = 1/4`, `M = 4`: complete. `chi_k = u_0 + i^k u_1 + (-1)^k u_2`; `p(k) = (3/4) ||chi_k||^2 / (3 * 14/5) = 5 ||chi_k||^2 / 56`.

| k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|
| 0 | 107/280 | 98/107 | 65/214 | 65/214 | 1, 1/2, 1/2 |
| 1 | 53/280 | 37/53 | 101/106 | 61/106 | 1/2, 1, 1/2 |
| 2 | 5/56 | 8/25 | 37/50 | 9/10 | 0, 1/2, 1/2 |
| 3 | 19/56 | 37/95 | 17/190 | 29/38 | 1/2, 0, 1/2 |

Example, `k = 0`: `chi_0 = ((11+3i)/10, (17-3i)/10)`, `||chi_0||^2 = 428/100`, `p = 5 * 4.28/56 = 107/280`. Sum of `p(k)`: `(107 + 53 + 25 + 95)/280 = 1`.

**P3b, degenerate level (degeneracy control from the AT-0 outside view).** `N = 3`, `E = (-1/2, 0, 1/2)`, `h0 = 0`, `h = (0, 0, 1/2)`, `v_0 = 0`, `v_1 = (0, 0, -1/2)` (so `n_1 = 0`), `v_2 = rho`, `psi_0 = (1, i)`, `r = 0`, `tau = 1/2`, `w = 3/4`, `M = 4`; target INTERACTING. Level 0: pair `(0, +)`, `f = (1, 0)`. Level 1: `R_1 = 0` and `E_1 + h0 = 0`, degenerate-matched, contributes 2 and `u_1 = psi_0`. Level 2: pair `(2, -)`, `f` proportional to `(-1, 3)`. Dimension 4. `u_0 = (1, 0)`, `u_1 = (1, i)`, `u_2 = (-1, 3)(-1 + 3i)/10 = ((1-3i)/10, (-3+9i)/10)`, `S = 1 + 2 + 1 = 4`. Gaps 1/2, 1 with `tau = 1/2`, `M = 4`: `D tau = 1/4, 1/2`, `D tau M = 1, 2`: complete. `chi_k = u_0 + i^k u_1 + (-1)^k u_2`, `p(k) = ||chi_k||^2/16`.

| k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|
| 0 | 41/80 | 29/82 | 40/41 | 45/82 | 1/2, 1, 1/2 |
| 1 | 19/80 | 1/38 | 10/19 | 25/38 | 1/2, 0, 1/2 |
| 2 | 1/80 | 1/2 | 0 | 1/2 | 1/2, 1, 1/2 |
| 3 | 19/80 | 37/38 | 10/19 | 13/38 | 1/2, 0, 1/2 |

Example, `k = 2` (`i^2 = -1`, `(-1)^2 = 1`): `chi_2 = u_0 - u_1 + u_2 = ((1-3i)/10, (-3-i)/10)`, `||chi_2||^2 = 20/100`, `p = 1/80`; `conj((1-3i)/10) (-3-i)/10 = (1+3i)(-3-i)/100 = -10i/100`, so `P(X+) = 1/2`, `P(Y+) = 1/2 - (1/10)/(1/5) = 0`, `P(Z+) = (10/100)/(20/100) = 1/2`: Bloch `(0, -1, 0)`. The ideal value there is `P(Y+) = 1`, the largest possible conditional deviation. This label has the smallest marginal of any section 13 case (`1/80`, above the `10^-3` margin of section 8.3).

**P4, complex `psi_0` and nonzero reference reading.** P2's clock and coupling with `psi_0 = (1, (3+4i)/5)` and `r = 1` (`reference_clock_label t1`); target INTERACTING. `u_1 = (1, 0)`, `f_{2,-}^dagger psi_0 = -1 + 3(3+4i)/5 = (4+12i)/5`, `u_2 = (-1, 3)(4+12i)/50`, `S = 1 + 16/25 = 41/25`. `chi_k = u_1 + i^(k-1) u_2`.

| k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|
| 0 | 29/164 | 277/290 | 17/58 | 73/145 | 9/10, 1/5, 1/2 |
| 1 | 37/164 | 197/370 | 73/74 | 113/185 | 4/5, 9/10, 1/2 |
| 2 | 53/164 | 37/530 | 65/106 | 193/265 | 1/10, 4/5, 1/2 |
| 3 | 45/164 | 13/50 | 1/10 | 17/25 | 1/5, 1/10, 1/2 |

The ideal column at `k = r = 1` is `psi_0` itself: Bloch `(3/5, 4/5, 0)`.

**P5, large rationals within the token limits.** `N = 2`, `E = (-524289/1048574, 524285/1048574)`, `h0 = 1/524287`, `h = (0, 0, 1/2)`, `v_0 = 0`, `v_1 = (524175/1048354, 724/524177, -1/2)`, `psi_0 = (1, 1)`, `r = 0`, `tau = 1/4`, `w = 1/2`, `M = 4`; target INTERACTING. Write `a = 524175`, `b = 1448`, `c = 524177`, with `a^2 + b^2 = c^2` and `c - a = 2`. Then `E_0 = -1/2 - h0`, `E_1 = 1/2 - h0` (gap exactly 1, clock complete), `n_0 = (0, 0, 1/2)` with pair `(0, +)`, `f = (1, 0)`; `n_1 = (a/(2c), b/(2c), 0)`, `R_1 = 1/2`, pair `(1, -)` because `E_1 + h0 - 1/2 = 0`, `f = (-1/2, (a + ib)/(2c))`. The kernel test needs `E_j + h0` exactly: denominators `1048574` and `524287` combine, and `|n_1|^2` has denominator `4c^2`, about `2^40`. With `zeta = (a + ib)/c` and `beta = (conj(zeta) - 1)/2` (`|beta|^2 = (c - a)/(2c) = 1/c`): `u_0 = (1, 0)`, `u_1 = beta (-1, zeta)`, `S = (c + 2)/c`, `chi_k = (1 - i^k beta, i^k beta zeta)`, `||chi_k||^2 = 1 - 2 Re(i^k beta) + 2/c`. With `gamma_k = conj(chi_{k,0}) chi_{k,1} = i^k (2 - ib)/(2c) - (a + ib)/c^2`:

| k | p(k) exact | p(k) | P(X+) | P(Y+) | P(Z+) |
|---|---|---|---|---|---|
| 0 | (c+4)/(4(c+2)) = 524181/2096716 | 0.250000953873 | 1/2 + 2/(c(c+4)) = 0.500000000007 | 1/2 - b(c+2)/(2c(c+4)) = 0.498618792435 | (c+3)/(c+4) = 524180/524181 |
| 1 | (c-b+2)/(4(c+2)) = 522731/2096716 | 0.249309396218 | 1/2 + (bc-2a)/(2c(c-b+2)) = 0.501383120580 | 1/2 + (c-b)/(c(c-b+2)) = 0.500001907745 | (c-b+1)/(c-b+2) = 522730/522731 |
| 2 | c/(4(c+2)) = 524177/2096716 | 0.249999046127 | 1/2 - (c+a)/c^2 = 0.499996184502 | 1/2 + b(c-2)/(2c^2) = 0.501381207565 | (c-1)/c = 524176/524177 |
| 3 | (c+b+2)/(4(c+2)) = 525627/2096716 | 0.250690603782 | 1/2 - (bc+2a)/(2c(c+b+2)) = 0.498620694911 | 1/2 - (c+b)/(c(c+b+2)) = 0.499998092255 | (c+b+1)/(c+b+2) = 525626/525627 |

Derivation of `P(Z+)`: `|chi_{k,1}|^2 = |beta|^2 = 1/c`, so `P(Z+) = 1 - 1/(c ||chi_k||^2)`. The ideal reference is P1's (rotation about `z` by `pi k/2`; `h0` is a global phase). Exact rationals for the X and Y columns (as computed by `exact.rs`): `k = 0`: `274763624041/549527248074`, `274004612845/549527248074`; `k = 1`: `274761527333/548007134774`, `274004612845/548007134774`; `k = 2`: `274759430625/549523054658`, `275520532729/549523054658`; `k = 3`: `274761527333/551043167958`, `275520532729/551043167958`.

**P6, nearly matching energies that do not match.** B with `v_0 = (0, 0, 1)`, `v_1 = (0, 0, 1/1048576)`, `v_2 = rho`, `v_3 = 0`; target INTERACTING. Level 0: `n_0 = (0, 0, 3/2)`, `E_0 + 3/2 = 0`, pair `(0, +)`, `f = (3, 0)`. Level 1: `R_1 = 524289/1048576`, `E_1 + R_1 = 2^-20 != 0` and `E_1 - R_1 != 0`: **not** in the kernel; the exact test must say no. Level 2: pair `(2, -)` as P2. Level 3: `E_3 = 3/2` against `+-1/2`: no. Dimension 2. `u_0 = (1, 0)`, `u_2 = (-1/5, 3/5)`, relative phase `exp(2 pi i * 2 k/4) = (-1)^k`, so `chi_k` is P2's `chi_0` for even `k` and P2's `chi_2` for odd `k`; `p(k) = 1/4 - cos(pi k)/14`.

| k | p(k) | P(X+) | P(Y+) | P(Z+) | ideal P(X+), P(Y+), P(Z+) |
|---|---|---|---|---|---|
| 0 | 5/28 | 49/50 | 1/2 | 16/25 | 1, 1/2, 1/2 |
| 1 | 9/28 | 1/10 | 1/2 | 4/5 | 1/2, 1, 1/2 |
| 2 | 5/28 | 49/50 | 1/2 | 16/25 | 0, 1/2, 1/2 |
| 3 | 9/28 | 1/10 | 1/2 | 4/5 | 1/2, 0, 1/2 |

An implementation that matched level 1 by a floating-point threshold would add `u_1 = (1, 0)` and get `p = 3/8, 7/24, 1/24, 7/24` with different Pauli values, failing check 10 by at least `0.2`. [ESTABLISHED MATHEMATICS] (Theorem 3 with the extra level vector); [COMPUTATIONAL DEMONSTRATION] reproduced by `exact.rs`. This case also triggers the projector trap of section 8.4 item 3.

### 13.3 Ideal versus interacting deviation table

`max |dP|` is the largest `|P_interacting - P_ideal|` over labels, axes and signs; `max |dp|` is the largest `|p(k) - w/N|`. Every nonzero entry exceeds `10^8` times the tolerance `1e-12`, so with target IDEAL each of these cases must fail check 10 with `SCHRODINGER_DEVIATION_EXCEEDED`, while check 11 (against `reference_interacting`) passes for a correct engine.

| Case | Mechanism (5.3) | max \|dP\| (where) | max \|dp\| | Same case with target IDEAL |
|---|---|---|---|---|
| P1 | none | 0 | 0 | PASS (P1b) |
| P1c | coupling outside kernel | 0 | 0 | PASS |
| P2 | rotated axis | 3/10 (k=2, Z) | 1/14 | N1: FAIL `SCHRODINGER_DEVIATION_EXCEEDED` |
| P3 | rotated axes, three levels | 2/5 (k=2, Z) | 9/56 | N1b: same |
| P3b | degenerate level + rotated axis | 1 (k=2, Y) | 21/80 | N1c: same |
| P4 | rotated axis, complex state, r=1 | 99/370 (k=1, X) | 3/41 | N1d: same |
| P5 | rotated axis, large tokens | 274763624033/549527248074, about 0.5 (k=0, X) | 362/524179 | N1e: same |
| P6 | rotated axis + spectator near miss | 49/50 (k=2, X) | 1/14 | N1f: same |

[ESTABLISHED MATHEMATICS] (differences of the exact tables above; the P2 marginal amplitude is the section 5.3 item 1 formula with `sin(theta/2) = 1/sqrt(10)`). [COMPUTATIONAL DEMONSTRATION] The literal checker's maxima match every row.

### 13.4 Negative classes (exact expected code sets)

| Class | Instance | Derivation | Checks that are not PASS | Expected codes (exact set) |
|---|---|---|---|---|
| N1 (and N1b to N1f) ideal prediction fails | P2 (P3, P3b, P4, P5, P6) with `prediction_target IDEAL`, `control_kind NEGATIVE`, `expected_outcome FAIL` | Section 13.3: check 10 compares `pauli` with `reference_ideal` and `clock_probability` with `w/N`; both differ (P2: `0.3` and `1/14`). Check 11 compares with `reference_interacting` and `reference_clock_probability`: PASS for a correct engine. All labels DEFINED both sides: check 12 PASS. | 10 FAIL | `SCHRODINGER_DEVIATION_EXCEEDED` |
| N2 coupling moves every level out | B with `v_1 = v_2 = (0, 0, 1/2)`, others 0; target INTERACTING | `R_1 = R_2 = 1`, `E_1, E_2 = -+1/2` do not match `+-1`; levels 0, 3: `-+3/2` against `+-1/2`: no. Dimension 0. Clock complete, so check 5 passes. `reference_ideal` is still written (P1's ideal column). | 3 FAIL; 4, 6 to 12 NOT_EVALUATED | `TRIVIAL_PHYSICAL_STATE` |
| N3 label-dependent marginal with a zero | B with `v_2 = (0, 0, -1)` (`= -2h`), others 0; target INTERACTING | Level 2: `n_2 = (0, 0, -1/2)`, pair `(2, -)`, `f = (-1, 0)`, so `u_1 = u_2 = (1, 0)`: two levels carry the same vector. `chi_k = (1 + i^k)(1, 0)`, `p(k) = (2 + 2 cos(pi k/2))/8 = 1/2, 1/4, 0, 1/4`. Labels 0, 1, 3: state `|0>`, `P(X+) = P(Y+) = 1/2`, `P(Z+) = 1`, equal to `reference_interacting`. Label 2: UNDEFINED on both sides (exact 0; binary64 gives about `1e-33`). Sum 1. | 9 FAIL; 11 NOT_EVALUATED (target INTERACTING) | `CONDITIONAL_UNDEFINED` |
| N4a wrong weight | P2 with `w = 1/2` | `sum F_k = I/2`, `povm_residual = (1/2) sqrt(4) = 1`; `p(k) = 5/56, 1/8, 9/56, 1/8`, sum `1/2`; the oracle's `reference_clock_probability` uses the same `w`, so check 10 passes; conditional values are ratios and unchanged. | 5, 6 FAIL; 11 NOT_EVALUATED (target INTERACTING) | `POVM_NORMALIZATION_EXCEEDED`, `PROBABILITY_SUM_EXCEEDED` |
| N4b broken clock | P2 with `tau = 1/3` | Gap 3: `D tau = 1`, `S = 4`; gaps 1, 2: `|S| = 1`; `povm_residual = sqrt(2 (5/16 + 1)) = sqrt(42)/4`, about `1.6202` (AT0_SPEC 13.3 N3). Relative phase `omega^k`, `omega = exp(2 pi i/3)`: `chi_k = (5 - omega^k, 3 omega^k)`, `||chi||^2 = 25, 40, 40, 25`, `p(k) = 5/28, 2/7, 2/7, 5/28`, sum `13/14` (Corollary 4.1d; in AT-0 this defect left the sum at 1). Pauli at `k = 1`: `P(X+) = 19/80`, `P(Y+) = 1/2 + 3 sqrt(3)/16`, `P(Z+) = 31/40`; `k = 2` the same with `P(Y+) = 1/2 - 3 sqrt(3)/16`; `k = 0, 3` as P2's `k = 0`. Oracle uses the same `tau`: check 10 passes. | 5, 6 FAIL; 11 NOT_EVALUATED (target INTERACTING) | `POVM_NORMALIZATION_EXCEEDED`, `PROBABILITY_SUM_EXCEEDED` |
| N5 precision demand | P2 with `min_bound_kind RIGOROUS`, run by an `ESTIMATED` engine | Check 1 fails; everything else as P2. | 1 FAIL; 11 NOT_EVALUATED (target INTERACTING) | `BOUND_KIND_INSUFFICIENT` |
| N6 zero projection of `psi_0` | B with `v_1 = (0, 0, 1/2)`, `v_2 = rho`, others 0, `psi_0 = (3, 1)`; target INTERACTING | Only pair `(2, -)`, dimension 1; `f^dagger psi_0 = -3/10 + 3/10 = 0` exactly, so `Psi = 0` (Corollary 3.1). Trivial-kernel rule. `reference_ideal`: Bloch of `(3, 1)` is `(3/5, 0, 4/5)` rotated about `z` by `pi k/2`: `P(X+) = 4/5, 1/2, 1/5, 1/2`; `P(Y+) = 1/2, 4/5, 1/2, 1/5`; `P(Z+) = 9/10`. | 3 FAIL; 4, 6 to 12 NOT_EVALUATED | `TRIVIAL_PHYSICAL_STATE` |

All derivations [ESTABLISHED MATHEMATICS]; N4b's Pauli values and the trivial-kernel decisions [COMPUTATIONAL DEMONSTRATION] by `literal.c`. Each case carries `expected_failure_codes` equal to exactly the set shown, sorted bytewise; any extra code is a defect (`AT0_RESULT_V2` section 5, normative by reference).

### 13.5 Refusal classes (one defect per file, first failure in `AT1_CASE_V1` section 4 order)

Each file is P2 with exactly one defect, and with `case_id` and `acceptance_id` recomputed for the defective text except in R5 (otherwise rule 5 would fire too). Codes are those of `AT1_CASE_V1` sections 1, 2 and 4 [ESTABLISHED MATHEMATICS] (reading of frozen text; the AT-0 readings of `AT0_CHARTER.md` section 8 item 7 are inherited by charter section 8).

| Class | Single defect | Code |
|---|---|---|
| R0 | a line removed, or a CRLF line ending | `CASE_PARSE_ERROR` |
| R1 | `povm_tau_turns 2/8` | `CASE_NONCANONICAL` |
| R2 | header `OMEGA-AT1-CASE v2`; R2b `domain omega.at1.case.v2`; R2c `contract AT1_CASE_V2` | `CASE_UNSUPPORTED_VERSION` |
| R3 | `clock_dim 65` with 65 energies and 65 `interaction_pauli` lines; R3b `clock_dim 1` with one of each | `CASE_INVALID_PARAMETER` |
| R4 | per-level irrational spectrum: `interaction_pauli 2 1/2,0/1,-1/10`, so `n_2 = (1/2, 0, 2/5)`, `|n_2|^2 = 41/100`, not a rational square, while `|h| = 1/2` is rational (a per-`h` check would miss it) | `CASE_IRRATIONAL_SPECTRUM` |
| R5 | `case_id` with one hex digit changed; R5b the same for `acceptance_id` | `CASE_ID_MISMATCH` |
| R6 | `expected_outcome FAIL` with `expected_failure_codes none`; R6b a code outside the AT1 closed set | `CASE_INVALID_PARAMETER` |
| R7 | coupling line count not `N`: `interaction_pauli 3` removed (three lines, `clock_dim 4`) | `CASE_PARSE_ERROR` |
| R8 | coupling index out of order: lines for `j = 1` and `j = 2` swapped | `CASE_PARSE_ERROR` |
| R9 | `interaction NONE` (fixed literal) | `CASE_PARSE_ERROR` |
| R10 | `model_family PAGE_WOOTTERS_FINITE_IDEAL` (AT-0 family; fixed literal, as the AT-0 D11 ruling) | `CASE_PARSE_ERROR` |
| R11 | `constraint SUM_HC_HS` (fixed literal) | `CASE_PARSE_ERROR` |
| R12 | `prediction_target BOTH` (enumeration), or the line missing | `CASE_PARSE_ERROR` |
| R13 | coupling component `2/10` | `CASE_NONCANONICAL` |
| R14 | coupling component `1048577/1` (over the token limit; as qualified AT-0 manifest row R27 at omega `bacc4b6`) | `CASE_INVALID_PARAMETER` |

Inherited AT-0 refusal rows (omega `bacc4b6`, `research/atemporal/at0/evaluator/cases/MANIFEST.tsv`, 42 refusal rows), re-expressed on P2: each AT-1 file carries the same defect, in the same line kind, as the AT-0 file of that name, with identities recomputed (except the identity rows). Expected AT-1 codes [ESTABLISHED MATHEMATICS] (reading of `AT1_CASE_V1` sections 1, 2, 4, which restate the AT-0 rules):

| AT-0 rows (manifest names) | AT-1 code |
|---|---|
| R07 crlf, R08 tab, R09 blank-line, R10 trailing-space, R11 double-space, R12 missing-key, R13 unknown-key, R14 duplicate-key, R15 out-of-order, R16 float-text, R19 label-uppercase, R31 control-kind-bad, R32 case-name-two-tokens, R33 missing-final-lf, R34 empty, R35 trailing-line, R36 label-count-mismatch, R37 model-family-bad | `CASE_PARSE_ERROR` |
| R01 noncanonical-rational, R17 noncanonical-integer, R18 noncanonical-scaled, R30 negative-zero | `CASE_NONCANONICAL` |
| R02 header-v2 (as `OMEGA-AT1-CASE v2`), R24 wrong-domain, R25 wrong-contract | `CASE_UNSUPPORTED_VERSION` |
| R03 clock-dim-1, R20 energies-not-increasing, R21 psi-zero, R22 tau-zero, R23 weight-negative, R26 clock-dim-65, R27 rational-over-limit, R28 duplicate-label, R29 ref-label-missing, R39 huge-digits-tau, R06 codes-with-pass, R06b codes-unsorted, R06c codes-unknown, R06d fail-without-codes | `CASE_INVALID_PARAMETER` |
| R04 irrational-spectrum (as `system_hamiltonian_pauli 0/1,1/1,0/1,1/1`, so levels 0, 1, 3 with `v_j = 0` have `|n_j|^2 = 2`; in AT-1 a defect in `h` alone is refused only if some level's `n_j` is irrational, which here holds) | `CASE_IRRATIONAL_SPECTRUM` |
| R05 wrong-case-id, R38 acceptance-id-wrong | `CASE_ID_MISMATCH` |

R03 and R26 coincide with R3b and R3 above, R01 with R1, R02 with R2, R04 is a second instance of R4, R05 and R38 with R5 and R5b. For R03 and R26 the AT-1 file also carries one `interaction_pauli` line per energy, so that the count rule of section 1 is met and only the range rule fires. A file with two defects reports only the earlier one. Not used here: an `AT0_CASE_V1` header (section 12.1 item 2) and a non-canonical coupling index token such as `01` (Agent 0 stated `CASE_NONCANONICAL` in its review disposition on omega#371; the frozen text's "index token is not its zero-based position" could also be read as shape); both are listed in 13.6.

### 13.6 Contract notes arising from these derivations (for Agent 0)

1. `AT1_RESULT_V1` section 1: "two reference line families" versus four oracle families (section 12.1 item 1). Reading assumed here: all four are spliced.
2. `AT1_CASE_V1` section 1: key versus value of the header line for an `AT0_CASE_V1` file given to an AT-1 tool (section 12.1 item 2).
3. `AT1_CASE_V1` section 1: a non-canonical but value-correct coupling index token (`interaction_pauli 01 ...` at position 1): `CASE_NONCANONICAL` (Agent 0's stated disposition) or `CASE_PARSE_ERROR` (literal reading of "index token is not its zero-based position").

None of these changes a value or an expected code in sections 13.2 to 13.4. They are raised on omega#371 for rulings; the frozen files are not edited.
