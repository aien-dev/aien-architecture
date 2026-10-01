import AienCap.Theorems
/-!
# Deliberate mutants of `Derive` (each must violate attenuation)

These are WRONG on purpose. They exist so the oracle can show it kills privilege widening.
Each mutant model compiles; the matching claim file must not.
-/
namespace AienCap

/-- MUTANT 1 (scope_expansion): the containment check is removed. -/
def DeriveWiden (g : Graph) (now pid cid : Nat) (auth : Auth) (c : Token) : Prop :=
  ∃ p, g.find pid = some p ∧ Valid g now p ∧ 0 < p.depth ∧
    c = { id := cid, parent := some pid, auth := auth, depth := p.depth - 1, expiry := p.expiry }

/-- MUTANT 2 (expiration_extension): child expiry is chosen freely, not capped by the parent. -/
def DeriveLongLived (g : Graph) (now pid cid : Nat) (auth : Auth) (exp : Nat) (c : Token) : Prop :=
  ∃ p, g.find pid = some p ∧ Valid g now p ∧ 0 < p.depth ∧ Auth.Sub auth p.auth ∧
    c = { id := cid, parent := some pid, auth := auth, depth := p.depth - 1, expiry := exp }

/-- MUTANT 3 (delegation_depth_increase): child keeps the parent's depth (no decrement). -/
def DeriveNoDecrement (g : Graph) (now pid cid : Nat) (auth : Auth) (c : Token) : Prop :=
  ∃ p, g.find pid = some p ∧ Valid g now p ∧ 0 < p.depth ∧ Auth.Sub auth p.auth ∧
    c = { id := cid, parent := some pid, auth := auth, depth := p.depth, expiry := p.expiry }

def mroot : Token := { id := 0, parent := none, auth := [1], depth := 1, expiry := 10 }
def mg : Graph := { tokens := [mroot], revoked := [] }

private theorem mroot_valid : Valid mg 5 mroot := by
  refine ⟨by simp [mg], ?_, by simp [mroot]⟩
  intro h
  cases h <;> simp_all [mroot]

/-- witness: the widening mutant accepts a child holding atom 2 that the parent lacks -/
theorem widen_witness :
    ∃ c, DeriveWiden mg 5 0 1 [1, 2] c ∧ ¬ Auth.Sub c.auth mroot.auth :=
  ⟨_, ⟨mroot, by simp [mg, Graph.find, mroot], mroot_valid, by simp [mroot], rfl⟩,
    fun h => by have := h 2 (by simp); simp [mroot] at this⟩

/-- witness: the long-lived mutant accepts a child expiring after its parent -/
theorem long_lived_witness :
    ∃ c, DeriveLongLived mg 5 0 1 [1] 99 c ∧ ¬ c.expiry ≤ mroot.expiry :=
  ⟨_, ⟨mroot, by simp [mg, Graph.find, mroot], mroot_valid, by simp [mroot],
      by intro a ha; simpa [mroot] using ha, rfl⟩, by simp [mroot]⟩

/-- witness: the no-decrement mutant accepts a child whose depth is not below the parent's -/
theorem no_decrement_witness :
    ∃ c, DeriveNoDecrement mg 5 0 1 [1] c ∧ ¬ c.depth < mroot.depth :=
  ⟨_, ⟨mroot, by simp [mg, Graph.find, mroot], mroot_valid, by simp [mroot],
      by intro a ha; simpa [mroot] using ha, rfl⟩, by simp [mroot]⟩

end AienCap
