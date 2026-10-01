import AienCap.Model
namespace AienCap

/-! ## Attenuation (AIEN.INV.CAP.ATTENUATION.V1) -/

/-- child authority is a subset of parent authority -/
theorem derive_auth_subset {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : Derive g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ Auth.Sub c.auth p.auth := by
  obtain ⟨p, hf, _, _, hs, rfl⟩ := h
  exact ⟨p, hf, hs⟩

/-- child expiry is no later than parent expiry -/
theorem derive_expiry_le {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : Derive g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ c.expiry ≤ p.expiry := by
  obtain ⟨p, hf, _, _, _, rfl⟩ := h
  exact ⟨p, hf, Nat.le_refl _⟩

/-- child remaining delegation depth is strictly less than the parent's -/
theorem derive_depth_lt {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : Derive g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ c.depth < p.depth := by
  obtain ⟨p, hf, _, hd, _, rfl⟩ := h
  exact ⟨p, hf, by simp only []; omega⟩

/-- a parent with depth zero cannot delegate -/
theorem depth_zero_cannot_delegate {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    {p : Token} (hf : g.find pid = some p) (h0 : p.depth = 0) :
    ¬ Derive g now pid cid auth c := by
  rintro ⟨q, hq, _, hd, _, _⟩
  rw [hf] at hq
  cases hq
  omega

/-- delegation from an invalid (revoked, ancestor-revoked, or expired) parent is refused -/
theorem derive_parent_valid {g : Graph} {now pid cid : Nat} {auth : Auth} {c : Token}
    (h : Derive g now pid cid auth c) :
    ∃ p, g.find pid = some p ∧ Valid g now p := by
  obtain ⟨p, hf, hv, _⟩ := h
  exact ⟨p, hf, hv⟩

/-! ## Revocation and expiry (AIEN.INV.CAP.REVOCATION_CLOSURE.V1) -/

/-- a revoked token is rejected -/
theorem revoked_invalid {g : Graph} {now : Nat} {t : Token} (h : t.id ∈ g.revoked) :
    ¬ Valid g now t := fun hv => hv.1 h

/-- an expired token is rejected -/
theorem expired_invalid {g : Graph} {now : Nat} {t : Token} (h : t.expiry < now) :
    ¬ Valid g now t := fun hv => by have := hv.2.2; omega

/-- revoking a token rejects that token -/
theorem revoke_rejects_target {g : Graph} {now : Nat} {t : Token} (a : Nat) (h : t.id = a) :
    ¬ Valid (g.revoke a) now t :=
  revoked_invalid (by simp [Graph.revoke, h])

private theorem desc_ancRev {g : Graph} {a : Nat} {t : Token} (h : Desc g a t) :
    AncRev (g.revoke a) t := by
  induction h with
  | direct hp => exact AncRev.direct hp (by simp [Graph.revoke])
  | up hp hf _ ih => exact AncRev.up hp hf ih

/-- revocation invalidates every descendant, at any depth -/
theorem revoke_invalidates_descendants {g : Graph} {now : Nat} {a : Nat} {t : Token}
    (h : Desc g a t) : ¬ Valid (g.revoke a) now t :=
  fun hv => hv.2.1 (desc_ancRev h)

private theorem ancRev_mono {g : Graph} {a : Nat} {t : Token} (h : AncRev g t) :
    AncRev (g.revoke a) t := by
  induction h with
  | direct hp hm => exact AncRev.direct hp (by simp [Graph.revoke, hm])
  | up hp hf _ ih => exact AncRev.up hp hf ih

/-- revocation never turns an invalid token into a valid one -/
theorem revoke_never_validates {g : Graph} {now a : Nat} {t : Token}
    (hv : Valid (g.revoke a) now t) : Valid g now t := by
  obtain ⟨h1, h2, h3⟩ := hv
  exact ⟨fun h => h1 (by simp [Graph.revoke, h]), fun h => h2 (ancRev_mono h), h3⟩

end AienCap
