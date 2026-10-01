import AienReceipt.Corpus
/-!
# Deliberate mutants of `validate` (each must break one required rule)

WRONG on purpose. Each mutant model compiles; the matching claim file must not.
-/
namespace AienReceipt

/-- MUTANT 1 (rejected_but_ran): a Rejected receipt is not required to have status NotRun. -/
def decisionOkM1 (r : Receipt) : Bool :=
  match r.decision with
  | .rejected =>
      r.stage != 0 && r.reason != 0 && r.exitCode == 0 &&
      r.syscalls == 0 && r.reads == 0 && r.denials == 0 && r.rflags.onlyReclaimed
  | _ => r.stage == 0 && r.reason == 0
def validateM1 (nf : Nat → Nat → Nat) (r : Receipt) : Bool :=
  presenceOk r && codesOk r && decisionOkM1 r && canaryOk r && nonceOk nf r

/-- MUTANT 2 (rejected_without_reason): a Rejected receipt may have stage 0 or reason 0. -/
def decisionOkM2 (r : Receipt) : Bool :=
  match r.decision with
  | .rejected =>
      r.status == .notRun && r.exitCode == 0 &&
      r.syscalls == 0 && r.reads == 0 && r.denials == 0 && r.rflags.onlyReclaimed
  | _ => r.stage == 0 && r.reason == 0
def validateM2 (nf : Nat → Nat → Nat) (r : Receipt) : Bool :=
  presenceOk r && codesOk r && decisionOkM2 r && canaryOk r && nonceOk nf r

/-- MUTANT 3 (non_rejected_with_rejection_fields): non-Rejected receipts are not checked. -/
def decisionOkM3 (r : Receipt) : Bool :=
  match r.decision with
  | .rejected =>
      r.stage != 0 && r.reason != 0 && r.status == .notRun && r.exitCode == 0 &&
      r.syscalls == 0 && r.reads == 0 && r.denials == 0 && r.rflags.onlyReclaimed
  | _ => true
def validateM3 (nf : Nat → Nat → Nat) (r : Receipt) : Bool :=
  presenceOk r && codesOk r && decisionOkM3 r && canaryOk r && nonceOk nf r

/-- MUTANT 4 (canary_passed_without_clean_exit): the CANARY_PASSED rule is removed. -/
def validateM4 (nf : Nat → Nat → Nat) (r : Receipt) : Bool :=
  presenceOk r && codesOk r && decisionOk r && nonceOk nf r

/-- MUTANT 5 (absent_flag_with_nonzero_value): the presence-flag rule is removed. -/
def validateM5 (nf : Nat → Nat → Nat) (r : Receipt) : Bool :=
  codesOk r && decisionOk r && canaryOk r && nonceOk nf r

/-- witness: mutant 1 accepts a Rejected receipt that claims it exited... -/
theorem m1_accepts_rejected_but_ran :
    validateM1 nf0 { rejectedR with status := .exited } = true := by decide
/-- ...which the real model refuses -/
theorem real_refuses_rejected_but_ran :
    validate nf0 { rejectedR with status := .exited } = false := by decide

end AienReceipt
