import MutantSeqModels
namespace AienSeq
/-- Real-model theorem `release_active` restated for releaseM4. MUST FAIL to check. -/
theorem mutant_release_active {a a' : Arena} {id : Id} (hw : a.WF) (h : a.releaseM4 id = (a', true)) :
    a'.active + 1 = a.active := by
  unfold Arena.releaseM4 at h
  by_cases hl : a.live id = true
  · simp only [hl, ite_true, Prod.mk.injEq] at h
    obtain ⟨rfl, _⟩ := h
    obtain ⟨hs, hg, ho⟩ := live_gen_match hl
    have := occCount_set_false a.occ id.slot a.cap hs ho
    simp only
    rw [hw.activeEq]; omega
  · simp only [hl] at h; simp at h
end AienSeq
