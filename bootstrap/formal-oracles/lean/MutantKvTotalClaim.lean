import MutantKvModels
namespace AienKv
/-- Real-model theorem `block_in_total` restated for totalM2. MUST FAIL to check. -/
theorem mutant_block_in_total (c : Cfg) {b : Nat} (hb : b < c.numBlocks) : b * c.block + c.block ≤ c.totalM2 := by
  have := succ_mul_le (s := c.block) hb
  unfold Cfg.totalM2; exact this
end AienKv
