# Exception 0002: R15 silicon PASS taken with Secure Boot OFF

Status: recorded after the run, 2026-10-06. Applies to CAND-3 attempt A7c (`qualification/candidates/CAND-3.gates.md` section 6).

## What happened

R15 clarification C2 (`spec/r15-performance-proof.md` section 17 in aien-dev/omega) names the energy source as the SPBM package accumulator read through the owner-key signed read-only reader, and says: "Secure Boot and integrity lockdown stay on." The A7c run was done with Secure Boot OFF, by Drake's decision (recorded 2026-10-06 ~11:40Z in the CAND-3 final report, and declared before the run in `DECLARED-ATTEMPT-A7c.md`, omega `evidence/CAND3-LIVING-f816473-A7c/00-declared/`). The signed reader loaded with the kernel notice "module verification failed: signature and/or required key missing - tainting kernel", then "firmware contract verified; read-only SPBM telemetry ready". The kernel was tainted for the run. The receipt (outcome PASS, 16 of 16 gates, `90fdebb8...fdd`) records this openly.

## What the written policy says

- R15 spec section 11: package energy must be read from a physical hardware source, otherwise metric 17 is incomplete and R15 cannot PASS. That requirement was met: the reader worked and the counter rose.
- R15 spec section 17 (C2): Secure Boot and lockdown stay on. That condition was NOT met.
- The spec has no clause that waives C2 or defines a "PASS with deviation" outcome. Exception 0001, rule 2: a bypass of a mandatory condition needs a written exception in this directory naming the reason, approver and effect on evidence. This file is that record.
- UNVERIFIED: that the written spec gives anyone authority to waive C2 after the fact. This record does not claim one.

## Classification

**CONDITIONAL PASS: measured PASS under a declared deviation from C2. NOT unconditional compliance, and NOT NOT_COMPLIANT.**

Reasoning: every numeric gate passed on a real hardware energy reading, so the measurement is real and is kept as evidence. The one stated condition of the method (Secure Boot and lockdown on) was not satisfied, so the result may not be cited as "R15 PASS" without this qualifier, and it may not be used as C2-conformant evidence. This label is the resolver's reading of the policy; the policy itself contains no such label.

## Effect

- CAND-3 stays NOT QUALIFIED for other reasons (R16 G7 and G8 NOT_RUN); this record does not change that and changes no milestone status.
- The receipt is not edited. A correction or rerun is a new receipt linked to the old one (exception 0001, rule 3).
- Unexplained and not tested: whether Secure Boot off or the tainted kernel changed any measured value. UNVERIFIED.

## What would make it compliant

1. Turn Secure Boot ON with integrity lockdown on, with the reader module signed by a key enrolled on the machine (no taint notice).
2. Rerun R15 silicon as a new declared attempt on the candidate being claimed, with the reader loaded cleanly and the receipt recording Secure Boot and lockdown state (spec section 13).

## Authorization

Changing machine security settings (Secure Boot, key enrollment, reboots) needs Drake's explicit authorization. No agent makes that change on its own.
