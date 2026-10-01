import MutantSeqModels
namespace AienSeq
/-- Real-model theorem `generation_mismatch_not_live` restated for liveM2. MUST FAIL to check. -/
theorem mutant_mismatch_not_live {a : Arena} {id : Id} (h : a.gen id.slot ≠ id.gen) :
    a.liveM2 id = false := by
  unfold Arena.liveM2; simp [h]
end AienSeq
