import MutantReceiptModels
namespace AienReceipt
/-- Real-model theorem restated for mutant validateM5. MUST FAIL to check. -/
theorem mutant_absent_flag {nf} {r : Receipt} (h : validateM5 nf r = true) (ha : r.pres.machine = false) : r.machineId = 0 := by
  simp only [validateM5, Bool.and_eq_true] at h
  simp_all
end AienReceipt
