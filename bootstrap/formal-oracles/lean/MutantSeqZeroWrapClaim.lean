import MutantSeqModels
namespace AienSeq
/-- Real-model theorem `nextGen_pos` restated for nextGenM3. MUST FAIL to check. -/
theorem mutant_next_pos (g : Nat) : 1 ≤ nextGenM3 g := by
  unfold nextGenM3; omega
end AienSeq
