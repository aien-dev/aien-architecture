import MutantReceiptModels
namespace AienReceipt
/-- Real-model theorem restated for mutant validateM3. MUST FAIL to check. -/
theorem mutant_non_rejected {nf} {r : Receipt} (h : validateM3 nf r = true) (hr : r.decision ≠ .rejected) : r.stage = 0 ∧ r.reason = 0 := by
  simp only [validateM3, decisionOkM3, Bool.and_eq_true] at h
  cases hd : r.decision <;> simp_all
end AienReceipt
