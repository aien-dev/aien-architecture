import MutantSeqModels
namespace AienSeq
/-- Real-model theorem `fork_stale_refused` restated for forkM5. MUST FAIL to check. -/
theorem mutant_fork_stale {a : Arena} {p : Id} (h : a.live p = false) : a.forkM5 p = none := by
  unfold Arena.forkM5; simp [h]
end AienSeq
