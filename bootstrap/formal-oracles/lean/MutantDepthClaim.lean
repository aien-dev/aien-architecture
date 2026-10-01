import MutantModels
namespace AienCap
/-- Real-model theorem restated for the no-decrement mutant. MUST FAIL to check. -/
theorem mutant_depth_claim {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : DeriveNoDecrement g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ c.depth < p.depth := by
  obtain ⟨p, hf, _, hd, _, rfl⟩ := h
  exact ⟨p, hf, by omega⟩
end AienCap
