import MutantSeqModels
namespace AienSeq
/-- Real-model theorem `free_invalidates` (generation half) restated for releaseM1. MUST FAIL to check. -/
theorem mutant_free_changes_gen {a a' : Arena} {id : Id} (h : a.releaseM1 id = (a', true)) :
    a'.gen id.slot ≠ id.gen := by
  unfold Arena.releaseM1 at h
  by_cases hl : a.live id = true
  · simp only [hl, ite_true, Prod.mk.injEq] at h
    obtain ⟨rfl, _⟩ := h
    obtain ⟨hs, hg, ho⟩ := live_gen_match hl
    simp [upd, hg]
  · simp only [hl] at h; simp at h
end AienSeq
