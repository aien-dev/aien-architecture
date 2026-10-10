# AT1_RESULT_V1: AT-1 result interchange contract

**Contract:** `AT1_RESULT_V1`. **Domain tags:** `omega.at1.verdict.v1` (verdict identity), `omega.at1.evidence.v1` (evidence digest).
**Status:** FROZEN on merge of the pull request that adds this file. Any change requires `AT1_RESULT_V2` (AT1 charter section 8).
**Owner:** Agent 0. **Program status:** NOT_RUN. **Predecessor:** `AT0_RESULT_V2` (frozen, unchanged).

## 0. Changes from AT0_RESULT_V2

- Version strings: header `OMEGA-AT1-RESULT v1`, `domain omega.at1.result.v1`, `contract AT1_RESULT_V1`, `case_contract AT1_CASE_V1`, verdict tag `omega.at1.verdict.v1`, evidence tag `omega.at1.evidence.v1`.
- The single `reference` line family becomes two: `reference_ideal` and `reference_interacting`.
- Check 10 compares against the case's `prediction_target`; new check 11 `oracle_cross_check`; two new failure codes `INTERACTING_DEVIATION_EXCEEDED` and `ORACLE_DISAGREEMENT`.
- Everything else (byte rules, `f64:` tokens, bounds, trivial-kernel rule, per-input `NOT_EVALUATED`, outcome rules, provenance, oracle-record marking) is the AT0_RESULT_V2 rule, restated where it matters.

A result records one execution of one AT1_CASE_V1 case. Semantic content (exact text, may carry an identity): the case, the acceptance rules, the discrete verdict. Physical execution evidence (no identity): floating-point values, bounds, toolchain, host, wall-clock times, artifact digests.

## 1. File shape

Byte rules and encodings of AT1_CASE_V1 sections 1 and 2 apply, plus the `f64:` value token of section 2 below. Lines in exactly this order:

```
OMEGA-AT1-RESULT v1
domain omega.at1.result.v1
contract AT1_RESULT_V1
case_contract AT1_CASE_V1
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
reference_ideal <k> <AXIS> <SIGN> <value> <bound>          (repeated)
reference_interacting <k> <AXIS> <SIGN> <value> <bound>    (repeated)
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

`AXIS` is `X`, `Y` or `Z`; `SIGN` is `PLUS` or `MINUS`. `pauli`, `reference_ideal` and `reference_interacting` lines are ordered by `k`, then `X, Y, Z`, then `PLUS, MINUS`. For a label whose status is not `DEFINED`, its six `pauli` lines carry `undefined` and bound `0@0`; its reference lines are still written (`reference_ideal` never depends on reachability; `reference_interacting` for an unreachable label is also written `undefined 0@0`, because the interacting conditional state does not exist there). **Trivial kernel** (`physical_state_kernel_dim 0` or `Psi` exactly zero): every label `UNDEFINED`, every `clock_probability`, `pauli`, `reference_interacting` and `constraint_residual` line `undefined 0@0`; `povm_residual` and `reference_ideal` still carry values. Line count and order never change. `<text>` is 1 to 200 bytes of 0x20..0x7E, no leading or trailing space.

`case_name`, the two blocks, `case_id` and `acceptance_id` are copied from the case; a writer refuses to emit a result whose blocks do not reproduce the copied identities.

**Oracle-written records** (carried from the AT-0 approval condition): a record written by the oracle itself has `build_cc` beginning with the literal `oracle ` and `engine_sha256` equal to `oracle_sha256`; a writer refuses anything else, and such a record is never a candidate result. The runner splices only the oracle's two reference line families into the candidate result.

## 2. Numbers in a result

As AT0_RESULT_V2 section 2: `f64:` plus 16 lowercase hex digits of the binary64 bit pattern, most-significant digit first, `-0.0` written as `f64:0000000000000000`; `nonfinite` for a non-finite value (forces `NONFINITE_VALUE`); `undefined` only where section 1 and section 3 say; bounds are scaled decimals with `bound_kind` `RIGOROUS`, `ESTIMATED` or `NONE` (then every bound `0@0`); `threads 1` fixed.

## 3. Quantities

All refer to AT1_CASE_V1 section 3. `Psi_hat = Psi / ||Psi||`.

- `physical_state_kernel_dim`: number of pairs `(j, s)` with `E_j + e_{j,s} = 0`, exact from the rational energies per level.
- `constraint_residual`: `|| H_total Psi_hat ||_2` (with `V` included); `undefined 0@0` on a trivial kernel.
- `povm_residual`: `|| sum_k F_k - I_C ||_F`.
- `clock_probability k`: `p(k) = w ||phi_k||^2 / ||Psi||^2`, label-dependent in general.
- Label status: `UNDEFINED` if `p(k) + bound <= tol_zero_probability`; `DEFINED` if `p(k) - bound > tol_zero_probability`; else `INDETERMINATE`.
- `pauli k AXIS SIGN`: for a `DEFINED` label, the outcome probabilities of the Pauli on `rho_k = phi_k phi_k^dagger / ||phi_k||^2`, each computed directly from `rho_k`. Engine quantity.
- `reference_ideal k AXIS SIGN`: the same probabilities for `exp(-i H_S (t_k - t_r)) |psi_0> / ||psi_0||`, `H_S` alone, no `V`. Oracle quantity, separate code path.
- `reference_interacting k AXIS SIGN`: the same probabilities for the interacting conditional state of AT1_CASE_V1 section 3, computed by the oracle from the closed form (kernel pairs, level eigenvectors, phases), never by the engine's code. Oracle quantity.

No result field is a deviation or a sum.

## 4. Checks, in this fixed order

Comparison forms, bounds, `INDETERMINATE` and per-input `NOT_EVALUATED` as AT0_RESULT_V2 section 4 and the AT-0 reading: checks quantified over written probabilities or defined labels run on the inputs that exist; `NOT_EVALUATED` only when no input remains.

| # | check_name | quantity compared with its tolerance | failure code on FAIL |
|---|---|---|---|
| 1 | `bound_kind_sufficient` | `bound_kind` at least `min_bound_kind` | `BOUND_KIND_INSUFFICIENT` |
| 2 | `values_finite` | no `nonfinite` token | `NONFINITE_VALUE` |
| 3 | `physical_state_nontrivial` | `physical_state_kernel_dim >= 1` and `Psi` nonzero | `TRIVIAL_PHYSICAL_STATE` |
| 4 | `constraint_residual` | vs `tol_constraint_residual` | `CONSTRAINT_RESIDUAL_EXCEEDED` |
| 5 | `povm_normalization` | `povm_residual` vs `tol_povm_residual` | `POVM_NORMALIZATION_EXCEEDED` |
| 6 | `clock_probability_sum` | `sum_k p(k) - 1` vs `tol_probability` | `PROBABILITY_SUM_EXCEEDED` |
| 7 | `probability_range` | every written probability, signed form, vs `tol_probability` | `PROBABILITY_OUT_OF_RANGE` |
| 8 | `pauli_pair_sum` | each defined label and axis, `PLUS + MINUS - 1` vs `tol_probability` | `PROBABILITY_SUM_EXCEEDED` |
| 9 | `conditional_defined` | no label `UNDEFINED` | `CONDITIONAL_UNDEFINED` |
| 10 | `target_agreement` | each defined label, axis, sign: `pauli - reference_<target>` vs `tol_schrodinger`, `<target>` from `prediction_target` | `SCHRODINGER_DEVIATION_EXCEEDED` when the target is `IDEAL`; `INTERACTING_DEVIATION_EXCEEDED` when it is `INTERACTING` |
| 11 | `oracle_cross_check` | only when `prediction_target IDEAL`: each defined label, axis, sign, `pauli - reference_interacting` vs `tol_schrodinger`; `NOT_EVALUATED` when the target is `INTERACTING` (check 10 already compares those lines) | `ORACLE_DISAGREEMENT` |

Trivial kernel: check 3 `FAIL`, checks 4, 6, 7, 8, 9, 10, 11 `NOT_EVALUATED`, checks 1, 2, 5 evaluated. Any `INDETERMINATE` check or label adds `PRECISION_INSUFFICIENT`. A check that is `FAIL` for several items adds its code once.

## 5. Outcome, codes and expectation

`outcome`, `failure_codes` (sorted, unique), `error_code`, `ERROR` and `NOT_RUN` shapes, and `expectation_met` exactly as AT0_RESULT_V2 section 5 (`YES` only when outcome and the failure-code set both equal the expectation; a verifier may not normalize a discrepancy away).

**Failure codes (closed set for V1):** `BOUND_KIND_INSUFFICIENT`, `CONDITIONAL_UNDEFINED`, `CONSTRAINT_RESIDUAL_EXCEEDED`, `INTERACTING_DEVIATION_EXCEEDED`, `NONFINITE_VALUE`, `ORACLE_DISAGREEMENT`, `POVM_NORMALIZATION_EXCEEDED`, `PRECISION_INSUFFICIENT`, `PROBABILITY_OUT_OF_RANGE`, `PROBABILITY_SUM_EXCEEDED`, `SCHRODINGER_DEVIATION_EXCEEDED`, `TRIVIAL_PHYSICAL_STATE`.

**Refusal codes (closed set for V1):** `CASE_PARSE_ERROR`, `CASE_NONCANONICAL`, `CASE_UNSUPPORTED_VERSION`, `CASE_INVALID_PARAMETER`, `CASE_IRRATIONAL_SPECTRUM`, `CASE_ID_MISMATCH`. A refused case produces no result file: the tool prints exactly one line `AT1_CASE_REFUSED <code>` to standard error and exits with status 2.

**Run error codes:** `ORACLE_UNAVAILABLE`, `RESOURCE_LIMIT`, `INTERNAL_ERROR`.

## 6. Identity and evidence

- `verdict_id = SHA-256( "omega.at1.verdict.v1" || 0x00 || "case_id " || case_id || LF || "acceptance_id " || acceptance_id || LF || B_ver )`, `B_ver` every line from `begin verdict` through `end verdict` inclusive, each followed by LF. Claim identity of the run. Two honest runs on different machines reach the same `verdict_id` when they reach the same verdict on the same case and rules; AT-1 gate G7 relies on exactly this.
- No semantic identity over computed values.
- `evidence_digest = SHA-256( "omega.at1.evidence.v1" || 0x00 || every line above the evidence_digest line, each followed by LF )`. Evidence, not identity.
- `case_file_sha256`, `engine_sha256`, `oracle_sha256`, `artifact` digests: plain SHA-256, no tag.

## 7. Provenance rules

As AT0_RESULT_V2 section 7: `source_tree_clean NO` results may not be cited for a gate; `contract_commit` names the aien-architecture commit of the frozen contracts; `host` is free text and, for a replication run, must name the machine and OS so the replication folder is self-describing.
