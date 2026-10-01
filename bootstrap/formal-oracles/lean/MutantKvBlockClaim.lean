import MutantKvModels
namespace AienKv
/-- Real-model theorem `block_regions_disjoint` restated for blockStrideM5. MUST FAIL to check. -/
theorem mutant_block_regions_disjoint (c : Cfg) {b1 b2 : Nat} (h : b1 ≠ b2) :
    Disjoint (b1 * c.blockStrideM5) c.block (b2 * c.blockStrideM5) c.block := by
  unfold Disjoint
  rcases Nat.lt_or_gt_of_ne h with h | h
  · left; exact succ_mul_le h
  · right; exact succ_mul_le h
end AienKv
