import AienReceipt.Layout
namespace AienReceipt

/-! Positive and negative corpus. The nonce function is a concrete stand-in; the theorems in
`Theorems.lean` hold for every `nf`, the corpus only shows the rules fire on concrete records. -/

def nf0 (v s : Nat) : Nat := v * 1000 + s

def admittedR : Receipt :=
  { pres := ⟨false, false, false⟩, decision := .admitted, tier := .seed0bQemu, sequence := 7,
    nonce := nf0 5 7, observed := 0, status := .exited, exitCode := 0, rflags := ⟨true, false, true, true, false, true, true, true⟩, stage := 0, reason := 0, syscalls := 3, reads := 1, denials := 0, frames := 4, digests := [1,2,3,4,5,6,7],
    verifier := 5, machineId := 0, generation := 0, contextId := 0 }

def rejectedR : Receipt :=
  { admittedR with decision := .rejected, status := .notRun, exitCode := 0, rflags := ⟨false, false, true, false, false, false, false, false⟩, stage := 3, reason := 18, syscalls := 0, reads := 0, denials := 0 }

/-! Positive: each decision has a valid receipt. -/
theorem pos_admitted_clean : validate nf0 admittedR = true := by decide
theorem pos_rejected_at_stage : validate nf0 rejectedR = true := by decide
theorem pos_loader_reason : validate nf0 { rejectedR with reason := 0x10a } = true := by decide
theorem pos_present_flags :
    validate nf0 { admittedR with pres := ⟨true, true, true⟩, machineId := 9, generation := 1, contextId := 2, observed := 99 } = true := by decide
theorem pos_fault_admitted :
    validate nf0 { admittedR with status := .fault, rflags := ⟨false, false, true, false, false, false, false, true⟩ } = true := by decide
theorem pos_roundtrip : decode nf0 (encode rejectedR) = some rejectedR := decode_encode (by decide)

/-! Negative: one receipt per violated rule, each refused. -/
theorem neg_rejected_but_ran_status : validate nf0 { rejectedR with status := .exited } = false := by decide
theorem neg_rejected_with_exit_status : validate nf0 { rejectedR with exitCode := 1 } = false := by decide
theorem neg_rejected_with_syscalls : validate nf0 { rejectedR with syscalls := 1 } = false := by decide
theorem neg_rejected_with_reads : validate nf0 { rejectedR with reads := 1 } = false := by decide
theorem neg_rejected_with_denials : validate nf0 { rejectedR with denials := 1 } = false := by decide
theorem neg_rejected_with_result_flag :
    validate nf0 { rejectedR with rflags := ⟨true, false, true, false, false, false, false, false⟩ } = false := by decide
theorem neg_rejected_without_stage : validate nf0 { rejectedR with stage := 0 } = false := by decide
theorem neg_rejected_without_reason : validate nf0 { rejectedR with reason := 0 } = false := by decide
theorem neg_stage_out_of_range : validate nf0 { rejectedR with stage := 10 } = false := by decide
theorem neg_reason_out_of_range : validate nf0 { rejectedR with reason := 20 } = false := by decide
theorem neg_admitted_with_reason : validate nf0 { admittedR with reason := 18 } = false := by decide
theorem neg_admitted_with_stage : validate nf0 { admittedR with stage := 3 } = false := by decide
theorem neg_canary_after_fault : validate nf0 { admittedR with status := .fault } = false := by decide
theorem neg_canary_nonzero_exit : validate nf0 { admittedR with exitCode := 3 } = false := by decide
theorem neg_absent_machine_nonzero : validate nf0 { admittedR with machineId := 1 } = false := by decide
theorem neg_absent_context_nonzero : validate nf0 { admittedR with contextId := 1 } = false := by decide
theorem neg_absent_generation_nonzero : validate nf0 { admittedR with generation := 1 } = false := by decide
theorem neg_absent_time_nonzero : validate nf0 { admittedR with observed := 1 } = false := by decide
theorem neg_bad_nonce : validate nf0 { admittedR with nonce := 0 } = false := by decide
theorem neg_refused_after_encode : decode nf0 (encode { rejectedR with status := .exited }) = none :=
  encode_invalid_refused neg_rejected_but_ran_status

/-! Finding (CanaryFailed): the code accepts these. Recorded, not endorsed. -/
theorem finding_canary_decision_with_exited_status :
    validate nf0 { admittedR with decision := .canaryFailed } = true := by decide
theorem finding_admitted_with_canary_failed_status :
    validate nf0 { admittedR with status := .canaryFailed, rflags := ⟨false, false, true, false, false, false, false, true⟩ } = true := by decide
theorem finding_destroyed_with_exited_status :
    validate nf0 { admittedR with decision := .destroyed } = true := by decide

end AienReceipt
