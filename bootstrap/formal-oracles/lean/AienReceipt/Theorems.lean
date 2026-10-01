import AienReceipt.Model
namespace AienReceipt

/-! Rules enforced by the code (AIEN.INV.RECEIPT.REJECTION_CONSISTENCY.V1).
Every theorem holds for every nonce function `nf` (crypto is an assumption). -/

/-- Unpack `validate = true` into its five groups. -/
theorem validate_parts {nf : Nat → Nat → Nat} {r : Receipt} (h : validate nf r = true) :
    presenceOk r = true ∧ codesOk r = true ∧ decisionOk r = true ∧ canaryOk r = true ∧
    nonceOk nf r = true := by
  simp only [validate, Bool.and_eq_true] at h
  exact ⟨h.1.1.1.1, h.1.1.1.2, h.1.1.2, h.1.2, h.2⟩

/-- the full Rejected arm of `validate`, as propositions -/
theorem rejected_arm {nf} {r : Receipt} (h : validate nf r = true) (hr : r.decision = .rejected) :
    r.stage ≠ 0 ∧ r.reason ≠ 0 ∧ r.status = .notRun ∧ r.exitCode = 0 ∧ r.syscalls = 0 ∧
    r.reads = 0 ∧ r.denials = 0 ∧ r.rflags.onlyReclaimed = true := by
  have := (validate_parts h).2.2.1
  simp only [decisionOk, hr, Bool.and_eq_true, bne_iff_ne, ne_eq, beq_iff_eq] at this
  obtain ⟨⟨⟨⟨⟨⟨⟨a, b⟩, c⟩, d⟩, e⟩, f⟩, g⟩, i⟩ := this
  exact ⟨a, b, c, d, e, f, g, i⟩

/-- rejected => execution status NotRun -/
theorem rejected_not_run {nf} {r : Receipt} (h : validate nf r = true)
    (hr : r.decision = .rejected) : r.status = .notRun :=
  (rejected_arm h hr).2.2.1

/-- rejected => no successful execution evidence: not Exited, zero exit status, zero syscalls,
zero object reads, zero denials, and CANARY_PASSED clear (only RECLAIMED may be set). -/
theorem rejected_no_execution_evidence {nf} {r : Receipt} (h : validate nf r = true)
    (hr : r.decision = .rejected) :
    r.status ≠ .exited ∧ r.exitCode = 0 ∧ r.syscalls = 0 ∧ r.reads = 0 ∧ r.denials = 0 ∧
    r.rflags.canaryPassed = false := by
  obtain ⟨_, _, hs, hx, hc, hr', hd, hf⟩ := rejected_arm h hr
  refine ⟨by rw [hs]; decide, hx, hc, hr', hd, ?_⟩
  simp only [ResultFlags.onlyReclaimed, Bool.and_eq_true, Bool.not_eq_true'] at hf
  simp [hf]

/-- rejected => a rejection stage (1..9) and a valid rejection reason are present -/
theorem rejected_stage_reason_present {nf} {r : Receipt} (h : validate nf r = true)
    (hr : r.decision = .rejected) :
    (1 ≤ r.stage ∧ r.stage ≤ maxStage) ∧ r.reason ≠ 0 ∧ validReason r.reason = true := by
  obtain ⟨hs, hq, _⟩ := rejected_arm h hr
  have hc := (validate_parts h).2.1
  simp only [codesOk, Bool.and_eq_true, decide_eq_true_eq, Bool.or_eq_true, beq_iff_eq] at hc
  refine ⟨⟨by omega, hc.1⟩, hq, ?_⟩
  rcases hc.2 with h0 | h1
  · exact absurd h0 hq
  · exact h1

/-- not rejected => the rejection-only fields (stage, reason) are absent -/
theorem not_rejected_no_rejection_fields {nf} {r : Receipt} (h : validate nf r = true)
    (hr : r.decision ≠ .rejected) : r.stage = 0 ∧ r.reason = 0 := by
  have := (validate_parts h).2.2.1
  unfold decisionOk at this
  cases hd : r.decision <;> simp_all

/-- CANARY_PASSED => execution succeeded (status Exited, exit status zero) -/
theorem canary_passed_executed {nf} {r : Receipt} (h : validate nf r = true)
    (hc : r.rflags.canaryPassed = true) : r.status = .exited ∧ r.exitCode = 0 := by
  have := (validate_parts h).2.2.2.1
  simp [canaryOk, hc] at this
  exact this

/-- absent machine id flag => the machine id digest is zero (not readable as present) -/
theorem absent_machine_zero {nf} {r : Receipt} (h : validate nf r = true)
    (ha : r.pres.machine = false) : r.machineId = 0 := by
  have := (validate_parts h).1
  simp [presenceOk, ha] at this
  exact this.1.1

/-- absent context id flag => generation and context id are zero -/
theorem absent_context_zero {nf} {r : Receipt} (h : validate nf r = true)
    (ha : r.pres.context = false) : r.generation = 0 ∧ r.contextId = 0 := by
  have := (validate_parts h).1
  simp [presenceOk, ha] at this
  exact this.1.2

/-- absent timestamp flag => observed time is zero -/
theorem absent_time_zero {nf} {r : Receipt} (h : validate nf r = true)
    (ha : r.pres.time = false) : r.observed = 0 := by
  have := (validate_parts h).1
  simp [presenceOk, ha] at this
  exact this.2

/-- the nonce is exactly the derived one (for the assumed derivation `nf`) -/
theorem nonce_derived {nf} {r : Receipt} (h : validate nf r = true) :
    r.nonce = nf r.verifier r.sequence := by
  have := (validate_parts h).2.2.2.2
  simpa [nonceOk] using this

/-! ## Finding: CanaryFailed decision is not tied to the CanaryFailed status

`validate` has one arm for `Rejected` and one arm `_` for every other decision (Rust lines 336-354).
The `_` arm checks only stage = 0 and reason = 0. Nothing relates `ReceiptDecision::CanaryFailed`
(or `Destroyed`) to `ExecutionStatusCode::CanaryFailed`. The two theorems below state the
consequence exactly: for decisions other than Rejected, validity does not depend on which of the
three non-rejected decisions is recorded. -/

/-- swapping among the non-rejected decisions never changes validity -/
theorem validate_decision_irrelevant_when_not_rejected (nf : Nat → Nat → Nat) (r : Receipt)
    (d : Decision) (h0 : r.decision ≠ .rejected) (h1 : d ≠ .rejected) :
    validate nf { r with decision := d } = validate nf r := by
  have key : decisionOk { r with decision := d } = decisionOk r := by
    unfold decisionOk
    cases hd : r.decision <;> cases d <;> simp_all
  simp [validate, presenceOk, codesOk, canaryOk, nonceOk, key]

/-- a valid receipt with decision CanaryFailed need not have status CanaryFailed:
validity does not force the status either way (it only constrains Rejected and CANARY_PASSED). -/
theorem canary_decision_status_unconstrained (nf : Nat → Nat → Nat) (r : Receipt)
    (h : validate nf r = true) (hd : r.decision = .canaryFailed) (s : Status)
    (hs : r.rflags.canaryPassed = false) :
    validate nf { r with status := s } = true := by
  have hp := validate_parts h
  simp only [validate, Bool.and_eq_true]
  refine ⟨⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩, ?_⟩
  · exact hp.1
  · exact hp.2.1
  · have := hp.2.2.1
    simpa [decisionOk, hd] using this
  · simp [canaryOk, hs]
  · exact hp.2.2.2.2

end AienReceipt
