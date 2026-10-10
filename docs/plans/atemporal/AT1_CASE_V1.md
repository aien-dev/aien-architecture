# AT1_CASE_V1: AT-1 case interchange contract

**Contract:** `AT1_CASE_V1`. **Domain tags:** `omega.at1.case.v1` (case identity), `omega.at1.acceptance.v1` (acceptance identity).
**Status:** FROZEN on merge of the pull request that adds this file. After that, any change to this file is a contract change and requires `AT1_CASE_V2` (AT1 charter section 8). Typos are not exempt.
**Owner:** Agent 0. **Program status:** NOT_RUN. **Predecessor:** `AT0_CASE_V1` (frozen, unchanged, still the AT-0 contract).

## 0. Changes from AT0_CASE_V1

- Header and tags: `OMEGA-AT1-CASE v1`, `domain omega.at1.case.v1`, `contract AT1_CASE_V1`, identity tags `omega.at1.case.v1` and `omega.at1.acceptance.v1`.
- `model_family PAGE_WOOTTERS_FINITE_CLOCKDIAG`; `interaction CLOCK_DIAGONAL_PAULI`; one new repeated line `interaction_pauli <j> <vx>,<vy>,<vz>` (N entries); `constraint SUM_HC_HS_V`.
- New acceptance line `prediction_target <IDEAL|INTERACTING>` (which reference the engine must agree with).
- Validity rule 4 (rational spectrum) is applied per clock level.
- Everything else is byte-for-byte the AT0_CASE_V1 rule.

## 1. File shape

ASCII text, LF line endings, every line terminated by exactly one LF, including the last. Allowed bytes: 0x20 to 0x7E and 0x0A. No CR, no tab, no blank line, no leading or trailing space, exactly one space between tokens. Lines appear in exactly the order below; a line marked "repeated" appears once per item, in ascending index order. Unknown keys, missing keys, duplicate keys and out-of-order keys are errors (`CASE_PARSE_ERROR`), never warnings. A fixed literal that does not match (for example `model_family` or `constraint`), an enumeration token outside its set, or a repeated block whose line count does not match its count line is a shape error (`CASE_PARSE_ERROR`), per the AT-0 reading "shape before range".

```
OMEGA-AT1-CASE v1
domain omega.at1.case.v1
contract AT1_CASE_V1
case_name <name>
begin semantic
model_family PAGE_WOOTTERS_FINITE_CLOCKDIAG
energy_unit DIMENSIONLESS_HBAR_1
clock_dim <N>
clock_energies <rational>,<rational>,...            (N entries, strictly increasing)
system_dim 2
system_hamiltonian_pauli <h0>,<hx>,<hy>,<hz>         (rationals)
interaction CLOCK_DIAGONAL_PAULI
interaction_pauli <j> <vx>,<vy>,<vz>                 (repeated, j = 0 .. N-1, rationals)
constraint SUM_HC_HS_V
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
prediction_target <IDEAL|INTERACTING>
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

## 2. Canonical encodings (shared by AT1_CASE_V1 and AT1_RESULT_V1)

Identical to AT0_CASE_V1 section 2, restated so this file stands alone:

- **Integer:** decimal, optional leading `-`, no leading zeros, no `+`. Zero is `0`. `-0` is invalid (`CASE_NONCANONICAL`).
- **Rational:** `n/d` with `d >= 1`, `gcd(|n|, d) = 1`; integers are written `n/1`; zero is `0/1`. Limits: `|n| <= 1048576`, `1 <= d <= 1048576`. Validators use exact integer arithmetic wide enough for section 4 (128-bit or a small bignum); an exceeded internal bound is `CASE_INVALID_PARAMETER`, never wrap-around.
- **Complex rational:** `(re;im)`, both rationals, no spaces.
- **Scaled decimal:** `N@k` meaning `N / 10^k`, `N >= 0` integer, `0 <= k <= 40`; zero is `0@0`; otherwise `N` not divisible by 10 unless `k = 0`.
- **Lists:** comma separated, no spaces, no trailing comma; the empty list is `none`.
- **Label:** `[a-z][a-z0-9_]{0,31}`. **Name:** `[A-Za-z0-9][A-Za-z0-9_.-]{0,63}`. **Digest:** 64 lowercase hex.
- **No floating-point text anywhere in a case file.**
- A token that parses but is not canonical (`2/4`, `04`, `-0/1`, `10@1`) is `CASE_NONCANONICAL`, decided after the whole shape pass.

## 3. Field meaning (the physics, fixed for V1)

Units: hbar = 1, dimensionless energies, times in the reciprocal unit. Pauli matrices in the computational basis with `Z|0> = +|0>`.

- `clock_energies`: `H_C = sum_j E_j |E_j><E_j|`, `j = 0 .. N-1`, `2 <= N <= 64`, strictly increasing.
- `system_hamiltonian_pauli`: `H_S = h0 I + hx X + hy Y + hz Z`.
- `interaction CLOCK_DIAGONAL_PAULI`, `interaction_pauli j vx,vy,vz`: `V = sum_j |E_j><E_j| (x) (vx_j X + vy_j Y + vz_j Z)`. All-zero vectors are allowed (then the case is an AT-0 ideal case written in AT-1 form).
- `constraint SUM_HC_HS_V`: `H_total = H_C (x) I_S + I_C (x) H_S + V`, clock factor first. Because `V` is diagonal in the clock energy basis, `H_total = sum_j |E_j><E_j| (x) (E_j I + h0 I + (h + v_j).sigma)` with `h = (hx, hy, hz)`. Level `j` has system eigenvalues `e_{j,+-} = h0 +- |h + v_j|` with eigenvectors `|e_{j,+-}>` (for `|h + v_j| = 0` both eigenvalues equal `h0` and any orthonormal pair serves; the kernel test below then matches both or neither).
- `physical_state NULLSPACE_PROJECTION`: `|Psi> = P_0 (|t_r> (x) |psi_0>)`, `P_0` the orthogonal projector onto the kernel of `H_total`, `|t_r>` the clock state of `reference_clock_label`, `|psi_0>` the unnormalized nonzero `reference_system_state`. The kernel is exact: spanned by `|E_j> (x) |e_{j,s}>` with `E_j + e_{j,s} = 0`.
- `clock_povm COVARIANT_DISCRETE`, `povm_tau_turns`, `povm_weight`, `clock_label`, `observables`: as AT0_CASE_V1 section 3 (`|t_k> = N^(-1/2) sum_j exp(-2 pi i E_j k tau) |E_j>`, `t_k = 2 pi k tau`, `F_k = w |t_k><t_k|`, `1 <= M <= 256`, labels unique, `reference_clock_label` among them).
- Conditional vector: `phi_k = (<t_k| (x) I) Psi = (1/N) sum_{(j,s) in K} exp(-2 pi i E_j (k - r) tau) <e_{j,s}|psi_0> |e_{j,s}>`, `r` the index of the reference label. Its normalization is the conditional state; `p(k) = w ||phi_k||^2 / ||Psi||^2`. Because the `|e_{j,s}>` differ from level to level, `p(k)` is in general label-dependent and the conditional state is in general not `exp(-i H_S (t_k - t_r)) psi_0`. That is the content AT-1 tests.
- `prediction_target`: `IDEAL` means the engine's conditional probabilities are judged against Schrodinger evolution under `H_S` alone; `INTERACTING` means they are judged against the oracle's independent computation of the interacting conditional probabilities (AT1_RESULT_V1 section 4). It is an acceptance rule, so it lives in `acceptance_id`, not in `case_id`: the same question can be judged both ways.

No field of a case may hold a wall-clock time, a host name, a run number or anything else about a physical execution.

## 4. Validity rules (exact, before any numerics)

A validator refuses the case with the AT1_RESULT_V1 refusal code shown, on the first failure, in this order:

1. Shape and encodings (sections 1, 2): `CASE_PARSE_ERROR` (shape) or `CASE_NONCANONICAL` (parsed, non-canonical token).
2. `domain`, `contract`, the `OMEGA-AT1-CASE v1` header: `CASE_UNSUPPORTED_VERSION`.
3. Ranges and fixed values of section 3; `reference_system_state` nonzero; `povm_weight > 0`; `povm_tau_turns > 0`; `interaction_pauli` indices exactly `0 .. N-1`: `CASE_INVALID_PARAMETER`.
4. Rational spectrum per level: for every `j`, `(hx + vx_j)^2 + (hy + vy_j)^2 + (hz + vz_j)^2` is the square of a rational: `CASE_IRRATIONAL_SPECTRUM`.
5. `case_id` and `acceptance_id` equal the recomputed values (section 5): `CASE_ID_MISMATCH`.
6. Acceptance: `expected_failure_codes` is `none` when `expected_outcome PASS`, nonempty, sorted bytewise ascending, no duplicates when `FAIL`, every code an AT1_RESULT_V1 failure code: `CASE_INVALID_PARAMETER`.

## 5. Identity

- `case_id = SHA-256( "omega.at1.case.v1" || 0x00 || B_sem )`, `B_sem` every line from `begin semantic` through `end semantic` inclusive, each followed by LF.
- `acceptance_id = SHA-256( "omega.at1.acceptance.v1" || 0x00 || B_acc )`, `B_acc` every line from `begin acceptance` through `end acceptance` inclusive, each followed by LF.
- `case_file_sha256 = SHA-256(whole file bytes)`: artifact digest, not an identity.

Every hashed byte is exact text. Equal digests are evidence of equal exact content, not the definition of equality.

## 6. Worked example (known-answer test for codecs)

Normative for byte layout and digests. The physics table is hand-derived and informational; `AT1_SPEC.md` and the oracle are the authority on values.

```
OMEGA-AT1-CASE v1
domain omega.at1.case.v1
contract AT1_CASE_V1
case_name at1-kat-rotated-level-n4
begin semantic
model_family PAGE_WOOTTERS_FINITE_CLOCKDIAG
energy_unit DIMENSIONLESS_HBAR_1
clock_dim 4
clock_energies -3/2,-1/2,1/2,3/2
system_dim 2
system_hamiltonian_pauli 0/1,0/1,0/1,1/2
interaction CLOCK_DIAGONAL_PAULI
interaction_pauli 0 0/1,0/1,0/1
interaction_pauli 1 0/1,0/1,0/1
interaction_pauli 2 3/10,0/1,-1/10
interaction_pauli 3 0/1,0/1,0/1
constraint SUM_HC_HS_V
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
prediction_target INTERACTING
expected_outcome PASS
expected_failure_codes none
min_bound_kind ESTIMATED
tol_constraint_residual 1@12
tol_povm_residual 1@12
tol_probability 1@12
tol_zero_probability 1@9
tol_schrodinger 1@12
end acceptance
case_id 890980a43bd189494c2c922d2bf0049cbffb07f1090f578e04e1142aee7525f1
acceptance_id d63246c391296c6cd381f1b654cc625be9f453c77c27c68d9eac240efd5b4d8f
end
```

`case_file_sha256` of the 45 lines above, each LF-terminated: `76e282fecf21025c9dd675378244e90ff192822a4c49d6cb812c9fe84b3f9ba4`.

Hand derivation (informational). Levels 0, 1, 3 are uncoupled: `e = +-1/2` with eigenvectors `|0>`, `|1>`. Level 2 has `h + v_2 = (3/10, 0, 4/10)`, `|h + v_2| = 1/2`, so its eigenvalues are also `+-1/2` but along the axis `n = (3/5, 0, 4/5)`: `|e_{2,-}> = (-1/sqrt(10)) |0> + (3/sqrt(10)) |1>`. Kernel: `(j = 1, e = +1/2)` via `|0>` and `(j = 2, e = -1/2)` via `|e_{2,-}>`; dimension 2; both system components survive. With `psi_0 = |+x>`: `<0|psi_0> = 1/sqrt(2)`, `<e_{2,-}|psi_0> = 1/sqrt(5)`, `||Psi||^2 = (1/4)(1/2 + 1/5) = 7/40`, and the cross term `<0|e_{2,-}> = -1/sqrt(10)` makes the clock marginal label-dependent: `||phi_k||^2 = (1/16)(7/10 - (1/5) cos(pi k / 2))`, so

| label | p(clock) | ideal model would say |
|---|---|---|
| t0 | 5/28 | 1/4 |
| t1 | 1/4 | 1/4 |
| t2 | 9/28 | 1/4 |
| t3 | 1/4 | 1/4 |

The four values sum to 1 (the POVM is complete for this clock), the clock probabilities alone already refute the ideal prediction, and the same case with `prediction_target IDEAL` is the negative class N1 (expected `SCHRODINGER_DEVIATION_EXCEEDED`). Conditional Pauli values are left to `AT1_SPEC.md`.
