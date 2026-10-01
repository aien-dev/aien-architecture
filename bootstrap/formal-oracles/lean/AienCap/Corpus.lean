import AienCap.Theorems
namespace AienCap

/-! Small positive and negative corpus for the model. Each is a checked theorem. -/

def root : Token := { id := 0, parent := none, auth := [1, 2], depth := 2, expiry := 10 }
def g0 : Graph := { tokens := [root], revoked := [] }

private theorem root_valid : Valid g0 10 root := by
  refine ⟨by simp [g0], ?_, by simp [root]⟩
  intro h
  cases h <;> simp_all [root]

/-- positive: narrower authority, one less depth, same expiry is accepted -/
theorem pos_narrower :
    Derive g0 10 0 1 [1] { id := 1, parent := some 0, auth := [1], depth := 1, expiry := 10 } :=
  ⟨root, by simp [g0, Graph.find, root], root_valid, by simp [root],
    by intro a ha; simp at ha; simp [root, ha], by simp [root]⟩

/-- positive: equal authority is accepted (containment is non-strict) -/
theorem pos_equal :
    Derive g0 10 0 1 [1, 2] { id := 1, parent := some 0, auth := [1, 2], depth := 1, expiry := 10 } :=
  ⟨root, by simp [g0, Graph.find, root], root_valid, by simp [root],
    by intro a ha; simpa [root] using ha, by simp [root]⟩

/-- negative: asking for an atom the parent lacks is refused -/
theorem neg_widen (c : Token) : ¬ Derive g0 10 0 1 [1, 3] c := by
  rintro ⟨p, hf, _, _, hs, _⟩
  have hp : p = root := by simp [g0, Graph.find, root] at hf; exact hf.symm
  subst hp
  have := hs 3 (by simp)
  simp [root] at this

/-- negative: a depth-zero parent cannot delegate -/
theorem neg_depth_zero (c : Token) :
    ¬ Derive { tokens := [{ root with depth := 0 }], revoked := [] } 10 0 1 [1] c :=
  depth_zero_cannot_delegate (p := { root with depth := 0 }) (by simp [Graph.find, root]) rfl

/-- negative: an expired token is invalid -/
theorem neg_expired : ¬ Valid g0 11 root := expired_invalid (by simp [root])

/-- negative: after revocation the revoked token is invalid -/
theorem neg_revoked : ¬ Valid (g0.revoke 0) 5 root := revoke_rejects_target 0 rfl

/-- positive: a token is still valid exactly at its expiry (Rust uses `>`) -/
theorem pos_expiry_boundary : Valid g0 10 root := root_valid

end AienCap
