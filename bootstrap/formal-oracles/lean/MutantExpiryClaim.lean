import MutantModels
namespace AienCap
/-- Real-model theorem restated for the expiry-extension mutant. MUST FAIL to check. -/
theorem mutant_expiry_claim {g : Graph} {now pid cid exp : Nat} {auth : Auth} {c : Token}
    (h : DeriveLongLived g now pid cid auth exp c) :
    ∃ p, g.find pid = some p ∧ c.expiry ≤ p.expiry := by
  obtain ⟨p, hf, _, _, _, rfl⟩ := h
  exact ⟨p, hf, Nat.le_refl _⟩
end AienCap
