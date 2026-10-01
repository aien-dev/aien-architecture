import MutantModels
namespace AienCap
/-- Real-model theorem restated for the widening mutant. MUST FAIL to check. -/
theorem mutant_scope_claim {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : DeriveWiden g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ Auth.Sub c.auth p.auth := by
  obtain ⟨p, hf, _, _, rfl⟩ := h
  exact ⟨p, hf, by intro a ha; assumption⟩
end AienCap
