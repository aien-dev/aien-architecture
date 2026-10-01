import MutantKvModels
namespace AienKv
/-- Real-model theorem `plane_in_layer` restated for layerM1. MUST FAIL to check. -/
theorem mutant_plane_in_layer (c : Cfg) {v : Nat} (hv : v < 2) : v * c.plane + c.plane ≤ c.layerM1 := by
  have := succ_mul_le (s := c.plane) hv
  unfold Cfg.layerM1; exact this
end AienKv
