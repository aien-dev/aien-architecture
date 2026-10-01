import MutantKvModels
namespace AienKv
/-- Real-model theorem `element_in_allocation` restated for ValidM4. MUST FAIL to check. -/
theorem mutant_element_in_allocation (c : Cfg) {b l v t h d : Nat} (hv : c.ValidM4 b l v t h d) :
    InRange (c.off b l v t h d) c.elemBytes c.total := by
  obtain ⟨hb, hl, hv2, ht, hh, hd⟩ := hv
  have e1 := elem_in_head c hd
  have e2 := head_in_token c hh
  have e3 := token_in_plane c ht
  have e4 := plane_in_layer c hv2
  have e5 := layer_in_block c hl
  have e6 := block_in_total c hb
  unfold InRange Cfg.off
  omega
end AienKv
