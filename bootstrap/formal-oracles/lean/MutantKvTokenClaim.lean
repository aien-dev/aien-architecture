import MutantKvModels
namespace AienKv
/-- Real-model theorem `head_in_token` restated for tokenM3. MUST FAIL to check. -/
theorem mutant_head_in_token (c : Cfg) {h : Nat} (hh : h < c.numKvHeads) : h * c.head + c.head ≤ c.tokenM3 := by
  have := succ_mul_le (s := c.head) hh
  unfold Cfg.tokenM3; exact this
end AienKv
