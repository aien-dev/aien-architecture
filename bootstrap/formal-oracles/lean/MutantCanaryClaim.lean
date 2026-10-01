import MutantReceiptModels
namespace AienReceipt
/-- Real-model theorem restated for mutant validateM4. MUST FAIL to check. -/
theorem mutant_canary {nf} {r : Receipt} (h : validateM4 nf r = true) (hc : r.rflags.canaryPassed = true) : r.status = .exited ∧ r.exitCode = 0 := by
  simp only [validateM4, Bool.and_eq_true] at h
  simp_all
end AienReceipt
