# AT0_RESULT_V1: AT-0 result interchange contract

**Contract:** `AT0_RESULT_V1`. **Domain tags:** `omega.at0.verdict.v1` (verdict identity), `omega.at0.evidence.v1` (evidence digest).
**Status:** FROZEN on merge of the pull request that adds this file. After that, any change to this file is a contract change and requires `AT0_RESULT_V2` (charter section 8).
**Owner:** Agent 0 (charter section 7). **Program status:** NOT_RUN.

A result records one execution of one AT0_CASE_V1 case: the computed numbers, how precise they are, the verdict, and where everything came from. It keeps two things apart:

- **Semantic content** (exact text, may carry an identity): the case, the acceptance rules, and the discrete verdict.
- **Physical execution evidence** (no identity): computed floating-point values, bounds, toolchain, host, wall-clock times and artifact digests.

## 1. File shape

The byte rules and encodings of AT0_CASE_V1 sections 1 and 2 apply unchanged, with one addition: the `f64:` value token of section 2 below. Lines appear in exactly this order:

```
OMEGA-AT0-RESULT v1
domain omega.at0.result.v1
contract AT0_RESULT_V1
case_contract AT0_CASE_V1
case_name <name>
<the case's semantic block, byte-identical, begin semantic .. end semantic>
<the case's acceptance block, byte-identical, begin acceptance .. end acceptance>
case_id <digest>
acceptance_id <digest>
case_file_sha256 <digest>
begin numerics
arithmetic <BINARY64|BINARY64_INTERVAL|BINARY64_COMPENSATED|NONE>
bound_kind <RIGOROUS|ESTIMATED|NONE>
threads 1
end numerics
begin values
physical_state_kernel_dim <integer>
constraint_residual <value> <bound>
povm_residual <value> <bound>
label <k> <label> <DEFINED|UNDEFINED|INDETERMINATE>        (repeated, k = 0 .. M-1)
clock_probability <k> <value> <bound>                     (repeated)
pauli <k> <AXIS> <SIGN> <value> <bound>                    (repeated)
reference <k> <AXIS> <SIGN> <value> <bound>                (repeated)
end values
begin verdict
check <check_name> <PASS|FAIL|INDETERMINATE|NOT_EVALUATED> (repeated, fixed order of section 4)
outcome <PASS|FAIL|ERROR|NOT_RUN>
failure_codes <code>,<code>,... | none
error_code <code> | none
expectation_met <YES|NO|NOT_APPLICABLE>
end verdict
verdict_id <digest>
begin provenance
source_repo <owner/name>
source_commit <40 lowercase hex>
source_tree_clean <YES|NO>
contract_commit <40 lowercase hex>
engine_sha256 <digest>
oracle_repo <owner/name>
oracle_commit <40 lowercase hex>
oracle_sha256 <digest>
build_cc <text>
build_flags <text>
host <text>
run_started_utc <YYYY-MM-DDTHH:MM:SSZ>
run_finished_utc <YYYY-MM-DDTHH:MM:SSZ>
artifact <path> <digest>                                   (repeated, sorted by path bytewise; may be absent)
end provenance
evidence_digest <digest>
end
```

`AXIS` is `X`, `Y` or `Z`; `SIGN` is `PLUS` or `MINUS`. The `pauli` and `reference` lines are ordered by `k`, then axis `X, Y, Z`, then `PLUS, MINUS`. For a label whose status is not `DEFINED`, its six `pauli` lines carry the value token `undefined` and bound `0@0`, and its six `reference` lines are still written (the reference does not depend on the label being reachable). `<text>` is 1 to 200 bytes of 0x20..0x7E with no leading or trailing space.

`case_name`, the two blocks, `case_id` and `acceptance_id` are copied from the case. A writer must refuse to emit a result whose blocks do not reproduce the copied identities.

## 2. Numbers in a result

- **Value token:** `f64:` followed by 16 lowercase hex digits of the IEEE-754 binary64 bit pattern, written most-significant digit first (the integer value of the 64-bit pattern, not the byte order in memory). `-0.0` is written as `+0.0` (`f64:0000000000000000`), the same rule omega uses in `src/estimation/est_types.c`, `src/dual/rx_dual.c` and `src/ans/`. NaN and infinity are never written as `f64:`. A non-finite computed value is written as the token `nonfinite` and forces failure code `NONFINITE_VALUE`. `undefined` is used only as section 1 says.
- **Bound token:** a scaled decimal (AT0_CASE_V1 section 2): a claimed absolute error bound on the value, in the same units. `bound_kind` says what kind of claim every bound in the file is:
  - `RIGOROUS`: a proven enclosure (for example directed-rounding interval arithmetic, with transcendental functions also enclosed).
  - `ESTIMATED`: a stated numerical estimate, not a proof.
  - `NONE`: no claim; every bound is `0@0`.
  The bound covers the full error from the exact mathematical quantity defined in AT0_CASE_V1 section 3, including rounding of inputs.
- **Arithmetic:** names the arithmetic the engine used. `threads 1` is fixed in V1: no parallel reductions, so results are reproducible bit for bit on the same build.

## 3. Quantities

All quantities refer to the exact definitions in AT0_CASE_V1 section 3. Let `Psi` be the physical state and `Psi_hat = Psi / ||Psi||`.

- `physical_state_kernel_dim`: dimension of the kernel of `H_total`, computed exactly from the rational energies (count of pairs with `E_j + e_s = 0`). Exact integer, not a measurement.
- `constraint_residual`: `|| H_total Psi_hat ||_2`, Euclidean norm, energy units. Written only when the kernel is nontrivial; otherwise the value token is `undefined` and bound `0@0`.
- `povm_residual`: `|| sum_k F_k - I_C ||_F`, Frobenius norm over the N x N clock matrix.
- `clock_probability k`: `p(k) = w || phi_k ||^2 / || Psi ||^2` with `phi_k = (<t_k| (x) I_S) Psi`.
- Label status: `UNDEFINED` if `p(k) + bound <= tol_zero_probability`; `DEFINED` if `p(k) - bound > tol_zero_probability`; otherwise `INDETERMINATE`.
- `pauli k AXIS SIGN`: for a `DEFINED` label, the probability of outcome `+1` (`PLUS`) or `-1` (`MINUS`) when that Pauli is measured on the conditional system state `rho_k = phi_k phi_k^dagger / || phi_k ||^2`. Each is computed directly from `rho_k`, not as one minus the other.
- `reference k AXIS SIGN`: the same probabilities for the Schrodinger-evolved state `exp(-i H_S (t_k - t_r)) |psi_0> / || psi_0 ||`, where `t_r` is the reading of `reference_clock_label`. Produced by the independent oracle (charter section 7, Agent 3) through a separate code path, never by the engine.

No result field is a deviation or a sum. Those are derived by the checker from the values above (section 4), so they cannot disagree with them.

## 4. Checks, in this fixed order

Each comparison is decided in exact real arithmetic on the written values: a binary64 value is an exact rational and a scaled decimal is an exact rational, so a checker never compares floats. Two comparison forms are used, for a quantity `v` with bound `b` and tolerance `tol`. **Absolute form** (residuals, sums, deviations): `PASS` if `|v| + b <= tol`; `FAIL` if `|v| - b > tol`; otherwise `INDETERMINATE`. **Signed form** (range limits only): `PASS` if `v + b <= tol`; `FAIL` if `v - b > tol`; otherwise `INDETERMINATE`. Derived quantities carry the summed bounds of their parts. A check whose input contains `nonfinite` or `undefined` is `NOT_EVALUATED` for that input (check 2 and check 9 already report those cases).

| # | check_name | quantity compared with its tolerance | failure code on FAIL |
|---|---|---|---|
| 1 | `bound_kind_sufficient` | `bound_kind` at least `min_bound_kind` (order `NONE < ESTIMATED < RIGOROUS`) | `BOUND_KIND_INSUFFICIENT` |
| 2 | `values_finite` | no `nonfinite` token anywhere | `NONFINITE_VALUE` |
| 3 | `physical_state_nontrivial` | `physical_state_kernel_dim >= 1` and `Psi` nonzero (exact, no tolerance) | `TRIVIAL_PHYSICAL_STATE` |
| 4 | `constraint_residual` | `constraint_residual` vs `tol_constraint_residual` | `CONSTRAINT_RESIDUAL_EXCEEDED` |
| 5 | `povm_normalization` | `povm_residual` vs `tol_povm_residual` | `POVM_NORMALIZATION_EXCEEDED` |
| 6 | `clock_probability_sum` | `sum_k p(k) - 1` vs `tol_probability` | `PROBABILITY_SUM_EXCEEDED` |
| 7 | `probability_range` | every written probability `p`, signed form: `-p` vs `tol_probability` and `p - 1` vs `tol_probability` | `PROBABILITY_OUT_OF_RANGE` |
| 8 | `pauli_pair_sum` | for each defined label and axis, `PLUS + MINUS - 1` vs `tol_probability` | `PROBABILITY_SUM_EXCEEDED` |
| 9 | `conditional_defined` | no label `UNDEFINED` | `CONDITIONAL_UNDEFINED` |
| 10 | `schrodinger_agreement` | for each defined label, axis and sign, `pauli - reference` vs `tol_schrodinger` | `SCHRODINGER_DEVIATION_EXCEEDED` |

A check that cannot be evaluated because an earlier check removed its input (for example check 4 with a trivial kernel) is `NOT_EVALUATED` and contributes no failure code. Any `INDETERMINATE` check or label adds failure code `PRECISION_INSUFFICIENT`. A check that is `FAIL` for several items adds its code once.

## 5. Outcome, codes and expectation

- `outcome PASS`: every check is `PASS` or `NOT_EVALUATED`, and no label is `INDETERMINATE`.
- `outcome FAIL`: the case was valid and the run completed, but at least one failure code was raised. `failure_codes` lists them, sorted bytewise ascending, no duplicates.
- `outcome ERROR`: the case was refused or the run could not complete. `error_code` names why; `failure_codes none`; every check `NOT_EVALUATED`; the values block is written with `physical_state_kernel_dim 0`, all values `undefined` and bounds `0@0`.
- `outcome NOT_RUN`: a placeholder result for a case that has not been executed. Same shape as `ERROR` with `error_code none`. In `ERROR` and `NOT_RUN` results, provenance fields whose value does not exist (`engine_sha256`, `oracle_repo`, `oracle_commit`, `oracle_sha256`, `build_cc`, `build_flags`, `host`, `run_started_utc`, `run_finished_utc`) carry the token `none`. `NOT_RUN` is the status of every AT-0 case today.

**Failure codes (closed set for V1):** `BOUND_KIND_INSUFFICIENT`, `CONDITIONAL_UNDEFINED`, `CONSTRAINT_RESIDUAL_EXCEEDED`, `NONFINITE_VALUE`, `POVM_NORMALIZATION_EXCEEDED`, `PRECISION_INSUFFICIENT`, `PROBABILITY_OUT_OF_RANGE`, `PROBABILITY_SUM_EXCEEDED`, `SCHRODINGER_DEVIATION_EXCEEDED`, `TRIVIAL_PHYSICAL_STATE`.

**Refusal codes (closed set for V1):** `CASE_PARSE_ERROR`, `CASE_NONCANONICAL`, `CASE_UNSUPPORTED_VERSION`, `CASE_INVALID_PARAMETER`, `CASE_IRRATIONAL_SPECTRUM`, `CASE_ID_MISMATCH`. A case that fails AT0_CASE_V1 section 4 cannot be copied into a result, so no result file is written: the tool prints exactly one line `AT0_CASE_REFUSED <code>` to standard error and exits with status 2.

**Run error codes (closed set for V1, written as `error_code`):** `ORACLE_UNAVAILABLE`, `RESOURCE_LIMIT`, `INTERNAL_ERROR`.

**`expectation_met`:** `NOT_APPLICABLE` when the outcome is `ERROR` or `NOT_RUN`. Otherwise `YES` exactly when the outcome equals `expected_outcome` and `failure_codes` equals `expected_failure_codes` as a set; else `NO`. A negative control therefore succeeds only when it fails for the stated reasons and no others: a verifier may not normalize a discrepancy away (Postulate v1.1, "Negative controls").

## 6. Identity and evidence

- **`verdict_id`** `= SHA-256( "omega.at0.verdict.v1" || 0x00 || "case_id " || case_id || LF || "acceptance_id " || acceptance_id || LF || B_ver )`, where `B_ver` is every line from `begin verdict` through `end verdict` inclusive, each followed by LF. It covers only exact, discrete content: which case, which rules, which checks passed, which codes. It is the claim identity of the run (the `CLAIM_ID` role in the Postulate). Two runs on different hosts, at different times, with bit-different floating-point values, have the same `verdict_id` when they reach the same verdict on the same case and rules.
- **No semantic identity over computed values in V1.** The values are binary64 measurements produced by an unspecified sequence of floating-point operations. Their bit patterns are physical evidence, so no V1 identity is defined over them, and no digest that includes them may be called a semantic identity, case identity, result identity or claim identity. An exact-arithmetic engine could define a result identity in a later contract version.
- **`evidence_digest`** `= SHA-256( "omega.at0.evidence.v1" || 0x00 || every line of the file above the evidence_digest line, each followed by LF )`. It fingerprints this physical record (values, bounds, provenance, wall-clock times) so it can be cited and checked for tampering. It is evidence, not identity: two honest runs of the same case normally have different evidence digests.
- `case_file_sha256`, `engine_sha256`, `oracle_sha256` and `artifact` digests are artifact digests: plain SHA-256 of the file bytes, no domain tag.

## 7. Provenance rules

- `source_repo`, `source_commit`: the omega commit the engine was built from; `source_tree_clean NO` means the build had uncommitted changes, and such a result may not be cited as evidence for a gate.
- `contract_commit`: the aien-architecture commit holding the frozen AT0 contract files the writer was built against.
- `engine_sha256`, `oracle_sha256`: digests of the executables that produced the values and the reference values.
- `build_cc`, `build_flags`, `host`: free text for humans; never parsed for decisions.
- `run_started_utc`, `run_finished_utc`: wall-clock times of the physical execution, UTC, second resolution. They exist only here, outside every identity.
- `artifact` lines name other files produced by the run (logs, case file copy), relative to the evidence folder.
