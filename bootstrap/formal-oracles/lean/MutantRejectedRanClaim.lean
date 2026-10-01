import MutantReceiptModels
namespace AienReceipt
/-- Real-model theorem restated for mutant validateM1. MUST FAIL to check. -/
theorem mutant_rejected_ran {nf} {r : Receipt} (h : validateM1 nf r = true) (hr : r.decision = .rejected) : r.status = .notRun := by
  simp only [validateM1, decisionOkM1, hr, Bool.and_eq_true] at h
  simp_all
end AienReceipt
