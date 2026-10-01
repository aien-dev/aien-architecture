import MutantReceiptModels
namespace AienReceipt
/-- Real-model theorem restated for mutant validateM2. MUST FAIL to check. -/
theorem mutant_no_reason {nf} {r : Receipt} (h : validateM2 nf r = true) (hr : r.decision = .rejected) : r.stage ≠ 0 ∧ r.reason ≠ 0 := by
  simp only [validateM2, decisionOkM2, hr, Bool.and_eq_true] at h
  simp_all
end AienReceipt
