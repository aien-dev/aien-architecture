# AT0_CASE_V1: AT-0 case interchange contract

**Contract:** `AT0_CASE_V1`. **Domain tag:** `omega.at0.case.v1` (identity), `omega.at0.acceptance.v1` (acceptance identity).
**Status:** FROZEN on merge of the pull request that adds this file. After that, any change to this file is a contract change and requires `AT0_CASE_V2` (charter section 8). Typos are not exempt.
**Owner:** Agent 0 (charter section 7). **Program status:** NOT_RUN.

A case is one question put to the AT-0 relational clock model: a finite Page-Wootters universe (clock plus one qubit), the clock readings to condition on, and the acceptance rules that judge the answer. A case file holds no computed numbers and no wall-clock reading. It is plain text, so any agent can write one by hand.

## 1. File shape

ASCII text, LF line endings, every line terminated by exactly one LF, including the last. Allowed bytes: 0x20 to 0x7E and 0x0A. No CR, no tab, no blank line, no leading or trailing space, exactly one space between tokens. Lines appear in exactly the order below; a line marked "repeated" appears once per item, in ascending index order. Unknown keys, missing keys, duplicate keys and out-of-order keys are errors (`CASE_PARSE_ERROR`), never warnings.

```
OMEGA-AT0-CASE v1
domain omega.at0.case.v1
contract AT0_CASE_V1
case_name <name>
begin semantic
model_family PAGE_WOOTTERS_FINITE_IDEAL
energy_unit DIMENSIONLESS_HBAR_1
clock_dim <N>
clock_energies <rational>,<rational>,...            (N entries, strictly increasing)
system_dim 2
system_hamiltonian_pauli <h0>,<hx>,<hy>,<hz>         (rationals)
interaction NONE
constraint SUM_HC_HS
physical_state NULLSPACE_PROJECTION
reference_clock_label <label>
reference_system_state <complex>,<complex>
clock_povm COVARIANT_DISCRETE
povm_tau_turns <rational>
povm_weight <rational>
clock_label_count <M>
clock_label <k> <label>                              (repeated, k = 0 .. M-1)
observables PAULI_X,PAULI_Y,PAULI_Z
end semantic
begin acceptance
control_kind <POSITIVE|NEGATIVE>
expected_outcome <PASS|FAIL>
expected_failure_codes <code>,<code>,... | none
min_bound_kind <RIGOROUS|ESTIMATED|NONE>
tol_constraint_residual <scaled>
tol_povm_residual <scaled>
tol_probability <scaled>
tol_zero_probability <scaled>
tol_schrodinger <scaled>
end acceptance
case_id <64 lowercase hex>
acceptance_id <64 lowercase hex>
end
```

## 2. Canonical encodings (shared by AT0_CASE_V1 and AT0_RESULT_V1)

Adopted from the DIRAC-0 corpus format (omega `research/dirac-oracle/CORPUS-FORMAT.md` section 2 at omega `19f73c7`) and restated here so this contract does not move if that file moves.

- **Integer:** decimal, optional leading `-`, no leading zeros, no `+`. Zero is `0`. `-0` is invalid.
- **Rational:** `n/d` with `d >= 1`, `gcd(|n|, d) = 1`; integers are written `n/1`; zero is `0/1`. Limits: `|n| <= 1048576`, `1 <= d <= 1048576`. Validators must use exact integer arithmetic wide enough for the checks in section 4 (128-bit integers or a small bignum); overflow is `CASE_INVALID_PARAMETER`, never wrap-around.
- **Complex rational:** `(re;im)` where both parts are rationals, no spaces. Example `(1/2;-3/1)`.
- **Scaled decimal:** `N@k` meaning `N / 10^k`, with `N >= 0` an integer and `0 <= k <= 40`. Canonical form: zero is `0@0`; otherwise `N` is not divisible by 10 unless `k = 0`. Example: `1@12` is 10^-12. Used for tolerances and bounds only.
- **Lists:** comma separated, no spaces, no trailing comma. The empty list is the token `none`.
- **Label:** `[a-z][a-z0-9_]{0,31}`. **Name:** `[A-Za-z0-9][A-Za-z0-9_.-]{0,63}`.
- **Digest:** 64 lowercase hex characters.
- **No floating-point text anywhere in a case file** (no `.`, no `e` exponent, no `f64:` values).

## 3. Field meaning (the physics, fixed for V1)

Units: hbar = 1, energies in one dimensionless unit, times in the reciprocal unit.

- `clock_energies`: the clock Hamiltonian `H_C = sum_j E_j |E_j><E_j|`, `j = 0 .. N-1`, in the clock energy basis. `2 <= N <= 64`. Strictly increasing, so the order is canonical.
- `system_hamiltonian_pauli`: `H_S = h0 I + hx X + hy Y + hz Z` on the system qubit, with `X, Y, Z` the Pauli matrices in the computational basis `|0>, |1>` where `Z|0> = +|0>`.
- `interaction NONE`: V1 has no clock-system coupling term. Interacting clocks need `AT0_CASE_V2`.
- `constraint SUM_HC_HS`: the total constraint `H_total = H_C (x) I_S + I_C (x) H_S`, clock factor first in every tensor product. A physical state satisfies `H_total |Psi> = 0`.
- `physical_state NULLSPACE_PROJECTION`: `|Psi> = P_0 (|t_r> (x) |psi_0>)`, where `P_0` is the orthogonal projector onto the kernel of `H_total`, `|t_r>` is the clock state of `reference_clock_label`, and `|psi_0>` is `reference_system_state` (unnormalized, must be nonzero). The kernel is exact: it is spanned by `|E_j> (x) |e_s>` with `E_j + e_s = 0`, where `e_s` are the eigenvalues of `H_S`.
- `clock_povm COVARIANT_DISCRETE`: clock states `|t_k> = N^(-1/2) sum_j exp(-2 pi i E_j k tau) |E_j>`, with `tau = povm_tau_turns` and `k = 0 .. M-1`. The clock reading for label `k` is `t_k = 2 pi k tau`. POVM effects `F_k = w |t_k><t_k|` with `w = povm_weight`. The contract does not require `sum_k F_k = I`; the result measures how far it is (`povm_residual`), so a bad clock can be written down and must be caught.
- `clock_label`: names outcome `k`. `1 <= M <= 256`. Labels are unique. `reference_clock_label` must be one of them.
- `observables`: fixed in V1. For each clock label, the conditional probabilities of the outcomes `+1` and `-1` of Pauli X, Y and Z on the system.

The clock reading `t_k` is declared program data in the sense of the Atemporal AIEN Postulate v1.1 (paper.tex line 199 at aienos.com `cc389e3`): it is an input of the question, not a physical execution coordinate. No field of a case may hold a wall-clock time, a host name, a run number or anything else about a physical execution.

## 4. Validity rules (exact, before any numerics)

A validator must check all of these with exact rational arithmetic and refuse the case with the AT0_RESULT_V1 refusal code shown (no result file is written) on the first failure, in this order:

1. Shape and encodings (section 1, 2). Else `CASE_PARSE_ERROR` or `CASE_NONCANONICAL` (parsed, but some token is not in canonical form, for example `2/4`).
2. `domain`, `contract`, the `OMEGA-AT0-CASE v1` header. Else `CASE_UNSUPPORTED_VERSION`.
3. Ranges and fixed values in section 3; `reference_system_state` nonzero; `povm_weight > 0`; `povm_tau_turns > 0`. Else `CASE_INVALID_PARAMETER`.
4. Rational spectrum: `hx^2 + hy^2 + hz^2` must be the square of a rational, so the eigenvalues `e_s = h0 +/- |h|` are rational and the kernel test `E_j + e_s = 0` is exact. Else `CASE_IRRATIONAL_SPECTRUM`.
5. `case_id` and `acceptance_id` equal the recomputed values (section 5). Else `CASE_ID_MISMATCH`.
6. Acceptance: `expected_failure_codes` is `none` when `expected_outcome PASS`, nonempty and sorted bytewise ascending with no duplicates when `expected_outcome FAIL`, and every code is a V1 failure code (AT0_RESULT_V1 section 5). Else `CASE_INVALID_PARAMETER`.

## 5. Identity

Three digests are defined over a case. Only the first two are identities.

- `case_id = SHA-256( "omega.at0.case.v1" || 0x00 || B_sem )`, where `B_sem` is every line from `begin semantic` through `end semantic` inclusive, each followed by LF. This is the semantic identity of the question (the `PROGRAM_ID` role in the Postulate). `case_name` is outside it: renaming a case does not change what it asks.
- `acceptance_id = SHA-256( "omega.at0.acceptance.v1" || 0x00 || B_acc )`, where `B_acc` is every line from `begin acceptance` through `end acceptance` inclusive, each followed by LF. Acceptance tolerances are kept out of `case_id` because the Postulate (paper line 164) puts floating-point acceptance tolerances in receipt acceptance, not in semantic equality.
- `case_file_sha256 = SHA-256(whole file bytes)`: an artifact digest used for provenance. It is not an identity.

Every byte that enters `case_id` or `acceptance_id` is exact text: integers, reduced rationals, labels, enum words and scaled decimals. No floating-point representation is hashed, so equal digests mean equal exact content (under the usual collision-resistance assumption; the digest is evidence of equality, not its definition).

## 6. Worked example (known-answer test for codecs)

The example below is normative for byte layout and digests: a codec that parses and re-emits it must reproduce it byte for byte and must compute the two identities shown. Its physics expectations are hand-derived and informational; the AT-0 oracle (Agent 3) is the authority on values.

```
OMEGA-AT0-CASE v1
domain omega.at0.case.v1
contract AT0_CASE_V1
case_name at0-kat-ideal-qubit-n4
begin semantic
model_family PAGE_WOOTTERS_FINITE_IDEAL
energy_unit DIMENSIONLESS_HBAR_1
clock_dim 4
clock_energies -3/2,-1/2,1/2,3/2
system_dim 2
system_hamiltonian_pauli 0/1,0/1,0/1,1/2
interaction NONE
constraint SUM_HC_HS
physical_state NULLSPACE_PROJECTION
reference_clock_label t0
reference_system_state (1/1;0/1),(1/1;0/1)
clock_povm COVARIANT_DISCRETE
povm_tau_turns 1/4
povm_weight 1/1
clock_label_count 4
clock_label 0 t0
clock_label 1 t1
clock_label 2 t2
clock_label 3 t3
observables PAULI_X,PAULI_Y,PAULI_Z
end semantic
begin acceptance
control_kind POSITIVE
expected_outcome PASS
expected_failure_codes none
min_bound_kind ESTIMATED
tol_constraint_residual 1@12
tol_povm_residual 1@12
tol_probability 1@12
tol_zero_probability 1@9
tol_schrodinger 1@12
end acceptance
case_id 3cf4ca4f882b5b9691ddcd905e65e15010855adcd2be200e19ebc3184655b44d
acceptance_id a13fb02dd674b8042ef8c0a197f03d58768709f782ba59cd26545eef6d41a228
end
```

Hand derivation (informational). `H_S = Z/2` has eigenvalues `+1/2` on `|0>` and `-1/2` on `|1>`; both are matched by clock energies `-1/2` and `+1/2`, so the kernel keeps both system components. With `tau = 1/4` and `M = 4`, every clock energy difference `D` in `{1, 2, 3}` gives `D tau M` an integer and `D tau` not an integer, so the four effects sum exactly to the identity with `w = N / M = 1`. The clock readings are `t_k = k pi / 2`. Conditioned on reading `t_k`, the system state is the Schrodinger evolution `exp(-i t_k Z / 2) |+>`, so `<X> = cos t_k`, `<Y> = sin t_k`, `<Z> = 0`, and each clock label has probability `1/4`:

| label | P(X=+1) | P(Y=+1) | P(Z=+1) | P(clock) |
|---|---|---|---|---|
| t0 | 1 | 1/2 | 1/2 | 1/4 |
| t1 | 1/2 | 1 | 1/2 | 1/4 |
| t2 | 0 | 1/2 | 1/2 | 1/4 |
| t3 | 1/2 | 0 | 1/2 | 1/4 |
