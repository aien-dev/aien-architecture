# Discovery Experiments - Current State

**NOT A MASTER PLAN.** This is a finite workstream document for the discovery experiments that test Claim C of The Turing Discovery Gap Conjecture, Revision 6, 2026-09-30. `CURRENT_EXECUTION_PLAN.md` still owns cross-project sequencing, and `doctrine/ROADMAP.md` still owns milestone status. Nothing in this document is a milestone.

**Written:** 2026-09-30. Code and evidence facts were read from these commits on that date. Implementation and evidence truth beats planning claims: where a plan or paper and the code disagree, the code and receipts win, and the disagreement is listed in section 2.

| Repository | Commit |
|---|---|
| omega | `main` `529ebfa` (live) |
| aien-architecture | `main` `74f666b` (live) |

---

## 1. What exists versus what is planned

| Item | State | Evidence |
|---|---|---|
| Rev 6 Claim A (hard worlds exist if one-way functions exist) | PROVED in the paper | The Turing Discovery Gap Conjecture, Revision 6, 2026-09-30, Appendix C |
| Rev 6 Claim B (unconditional separation) | OPEN conjecture | same paper |
| Rev 6 Claim C (program reuse helps) | HYPOTHESIS, not tested | same paper |
| CEXP-1 (Claim C experiment: library learner versus empty library) | FROZEN AS TEXT in Rev 6 Appendix D; NOT RUN | no file, branch or receipt named CEXP in omega or aien-architecture |
| EXP-001 (compression bridge, first attempt) | FAIL, preserved | omega `calibration/experiments/EXP-001/final_receipt.json` |
| EXP-001R (compression bridge, successor) | PASS (omega #99) | omega `calibration/experiments/EXP-001R/final_receipt.json`; independent scorer 312 values, 0 mismatches |
| Turing-profile-v1.1 | FROZEN; the profile EXP-001R passed under | omega `calibration/profiles/Turing-profile-v1.1.toml` and `.sha256` |
| EXP-002 apparatus (Brownian calibration program, protocol sections EXP-002A to 002D) | see discrepancy 3: two sources on `main` disagree | omega `docs/turing/protocols/turing-instrument-calibration-validation-protocol-v1-0.tex`; aien-architecture `docs/brownian-calibration-explainer.md` |
| Program description code for program-valued models | DOES NOT EXIST | Turing-profile-v1.1 `candidate_encoding_rules`: table models only, no program admissible |
| CEXP-2 (abstraction learning versus program reuse) | PLANNED, spec v1.0 frozen as text, BLOCKED | `CEXP2_ABSTRACTION_EXPERIMENT.md` |
| DEXP-1 (discoverability map) and Conjectures D1, D2 | PLANNED, spec v1.0 frozen as text, BLOCKED; D1 and D2 NOT PROVED | `DEXP1_DISCOVERABILITY_MAP.md` |
| Generator for a bounded program family (needed by DEXP-1) | DOES NOT EXIST | none found |

## 2. Discrepancies found

1. **Profile version in Rev 6 Appendix D.** Rev 6 binds CEXP-1 to "turing-profile v1.0". In omega, Turing-profile-v1.0 was the profile of the failed EXP-001, and Turing-profile-v1.1 is the profile EXP-001R passed under. The CEXP-1 preregistration must name the actual profile file and digest. CEXP-2 and DEXP-1 bind whatever CEXP-1 binds.
2. **Apparatus values in Rev 6 Appendix D.** Rev 6 lists a 256-bin quantizer over [-5, 5], an 8-bit uniform baseline and 32 bits per fitted real parameter. Neither Turing-profile-v1.0 nor v1.1 contains these values: both score search-event outcomes of the crumbline control learner with 9 symbols, an order-1 table baseline, and table models only. The Rev 6 values may belong to the private Brownian profile, which binds Turing-profile-v1.1 as a companion; that profile is not public and was not read. Until a public profile carries these values, CEXP-1, CEXP-2 and DEXP-1 reuse them as planning values only.
3. **EXP-002 status.** omega `docs/turing/TURING_SCIENTIFIC_QUALIFICATION_STATE.md` at `529ebfa` says EXP-002A to 002D are NOT STARTED, protocol text only. aien-architecture `docs/brownian-calibration-explainer.md` (status date 2026-09-30, merged in #67) reports EXP-002A PASS under a successor profile, EXP-002B PASS, EXP-002C PASS, and EXP-002D INCOMPLETE. Both are on `main`. This document does not resolve the conflict; the owner of the omega qualification state should reconcile it.
4. **Name of the apparatus.** Rev 6 calls the apparatus "EXP-002 Stochastic Law Discovery". omega's protocol has no section by that name; its EXP-002 sections are "EXP-002A: Randomness Without Invented Structure", "EXP-002B: Occam Transition", "EXP-002C: Mechanism Discrimination" and "EXP-002D: Unification". The specs here use Rev 6's umbrella phrase only when quoting Rev 6.

## 3. Gates for every experiment in this folder

| Gate | State on 2026-09-30 |
|---|---|
| EXP-001 PASS | MET in successor form (EXP-001R PASS, omega #99); EXP-001 FAIL kept in the record |
| CEXP-1 run complete, receipt published | NOT MET (not run) |
| Admissible program description code in the bound profile | NOT MET |
| Apparatus identity settled (discrepancies 1 and 2) | NOT MET |

No result from any experiment in this folder is a Physics Zero claim.
