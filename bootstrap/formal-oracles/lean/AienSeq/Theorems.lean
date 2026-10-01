import AienSeq.Model
namespace AienSeq

/-! Rules enforced by the code (AIEN.INV.SEQUENCE.STALE_ID.V1). -/

/-! ### Generation arithmetic -/

theorem nextGen_range {g : Nat} (_h1 : 1 ≤ g) (_h2 : g < two32) : 1 ≤ nextGen g ∧ nextGen g < two32 := by
  unfold nextGen two32 at *; omega

/-- one free always changes the generation (for every valid generation) -/
theorem nextGen_ne {g : Nat} (_h1 : 1 ≤ g) (_h2 : g < two32) : nextGen g ≠ g := by
  unfold nextGen two32 at *; omega

/-- generation 0 is never produced -/
theorem nextGen_pos (g : Nat) : 1 ≤ nextGen g := by
  unfold nextGen; omega

/-- iterate `nextGen` k times -/
def iterGen : Nat → Nat → Nat
  | 0, g => g
  | k + 1, g => iterGen k (nextGen g)

/-- Closed form: generations cycle through 1 .. 2^32 - 1, so the period is genMax = 2^32 - 1. -/
theorem iterGen_closed (k : Nat) : ∀ g, 1 ≤ g → g < two32 → iterGen k g = (g - 1 + k) % genMax + 1 := by
  induction k with
  | zero => intro g h1 h2; unfold iterGen genMax two32 at *; omega
  | succ k ih =>
    intro g h1 h2
    have hr := nextGen_range h1 h2
    show iterGen k (nextGen g) = _
    rw [ih _ hr.1 hr.2]
    unfold nextGen genMax two32 at *
    omega

/-- Slot reuse changes identity: while fewer than 2^32 - 1 frees have hit one slot, its generation
differs from the one an old id carries. -/
theorem no_aba_before_wrap {g k : Nat} (h1 : 1 ≤ g) (h2 : g < two32) (hk0 : 0 < k) (hk : k < genMax) :
    iterGen k g ≠ g := by
  rw [iterGen_closed k g h1 h2]; unfold genMax two32 at *; omega

/-- THE GENERATION-WRAP LIMITATION, stated as a theorem: after exactly 2^32 - 1 frees of the same
slot the generation is back where it started, so a stale id from before the cycle resolves again. -/
theorem aba_after_exactly_one_cycle {g : Nat} (h1 : 1 ≤ g) (h2 : g < two32) :
    iterGen genMax g = g := by
  rw [iterGen_closed genMax g h1 h2]; unfold genMax two32 at *; omega

/-- ...and the wrap skips generation 0 (u32::MAX goes to 1, not 0). -/
theorem wrap_skips_zero : nextGen genMax = 1 := by decide

/-! ### Scheduler variant: retire at u32::MAX -/

/-- a non-retiring step strictly increases the generation, so ids are never reissued -/
theorem retire_strictly_increases {g g' : Nat} (h : retireNext g = some g') : g < g' := by
  unfold retireNext at h; split at h <;> simp_all <;> omega

/-- at u32::MAX the slot is retired instead of wrapping, so no id of that slot is ever reissued -/
theorem retire_at_max : retireNext genMax = none := by decide

/-! ### Counting -/

theorem occCount_le (occ : Nat → Bool) : ∀ n, occCount occ n ≤ n := by
  intro n; induction n with
  | zero => simp [occCount]
  | succ n ih => simp only [occCount]; split <;> omega

theorem occCount_all (occ : Nat → Bool) : ∀ n, (∀ i, i < n → occ i = true) → occCount occ n = n := by
  intro n; induction n with
  | zero => intro _; rfl
  | succ n ih =>
    intro h
    simp only [occCount, h n (by omega), ih (fun i hi => h i (by omega))]; rfl

theorem occCount_congr {f g : Nat → Bool} : ∀ n, (∀ j, j < n → f j = g j) → occCount f n = occCount g n := by
  intro n; induction n with
  | zero => intro _; rfl
  | succ n ih =>
    intro h
    simp only [occCount, h n (by omega), ih (fun j hj => h j (by omega))]

theorem occCount_set_true (occ : Nat → Bool) (i : Nat) :
    ∀ n, i < n → occ i = false → occCount (upd occ i true) n = occCount occ n + 1 := by
  intro n; induction n with
  | zero => intro h; omega
  | succ n ih =>
    intro hi ho
    by_cases hn : i = n
    · subst hn
      have hc : occCount (upd occ i true) i = occCount occ i :=
        occCount_congr i (fun j hj => by simp [upd]; intro h; omega)
      simp [occCount, hc, upd, ho]
    · have := ih (by omega) ho
      simp [occCount, this, upd, Ne.symm hn]; split <;> omega

theorem occCount_set_false (occ : Nat → Bool) (i : Nat) :
    ∀ n, i < n → occ i = true → occCount occ n = occCount (upd occ i false) n + 1 := by
  intro n; induction n with
  | zero => intro h; omega
  | succ n ih =>
    intro hi ho
    by_cases hn : i = n
    · subst hn
      have hc : occCount (upd occ i false) i = occCount occ i :=
        occCount_congr i (fun j hj => by simp [upd]; intro h; omega)
      simp [occCount, hc, upd, ho]
    · have := ih (by omega) ho
      simp [occCount, this, upd, Ne.symm hn]; split <;> omega

/-! ### Well-formedness -/

theorem occCount_none (n : Nat) : occCount (fun _ => false) n = 0 := by
  induction n with
  | zero => rfl
  | succ n ih => simp [occCount, ih]

theorem init_wf (cap : Nat) : (Arena.init cap).WF where
  freeRange := by intro i hi; simpa [Arena.init] using hi
  freeNodup := by simpa [Arena.init] using List.nodup_range
  freeIff := by intro i hi; simp [Arena.init]; exact hi
  genRange := by intro i; simp [Arena.init, two32]
  activeEq := by simp [Arena.init, occCount_none]

/-- allocation preserves well-formedness -/
theorem alloc_wf {a a' : Arena} {id : Id} (hw : a.WF) (h : a.alloc = some (a', id)) : a'.WF := by
  unfold Arena.alloc at h
  cases hf : a.free with
  | nil => simp [hf] at h
  | cons s rest =>
    simp only [hf, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    have hs : s < a.cap := hw.freeRange s (by simp [hf])
    have hso : a.occ s = false := (hw.freeIff s hs).1 (by simp [hf])
    have hnd := hw.freeNodup; rw [hf] at hnd
    rw [List.nodup_cons] at hnd
    refine ⟨?_, hnd.2, ?_, hw.genRange, ?_⟩
    · intro i hi; exact hw.freeRange i (by simp [hf, hi])
    · intro i hi
      by_cases hi' : i = s
      · subst hi'; simp [upd, hnd.1]
      · have := hw.freeIff i hi
        simp only [hf, List.mem_cons, upd, hi', ite_false] at this ⊢
        simp [hi'] at this ⊢; exact this
    · simp only
      rw [occCount_set_true a.occ s a.cap hs hso, hw.activeEq]

/-- release preserves well-formedness -/
theorem release_wf {a a' : Arena} {id : Id} {b : Bool} (hw : a.WF) (h : a.release id = (a', b)) : a'.WF := by
  unfold Arena.release at h
  by_cases hl : a.live id = true
  · simp only [hl, ite_true, Prod.mk.injEq] at h
    obtain ⟨rfl, _⟩ := h
    simp only [Arena.live, Bool.and_eq_true, decide_eq_true_eq] at hl
    obtain ⟨⟨hs, hg⟩, ho⟩ := hl
    have hnf : id.slot ∉ a.free := fun hm => by have := (hw.freeIff _ hs).1 hm; simp_all
    refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · intro i hi
      simp only [List.mem_cons] at hi
      rcases hi with rfl | hi
      · exact hs
      · exact hw.freeRange i hi
    · exact List.nodup_cons.2 ⟨hnf, hw.freeNodup⟩
    · intro i hi
      by_cases hi' : i = id.slot
      · subst hi'; simp [upd]
      · have := hw.freeIff i hi
        simp [upd, hi', this]
    · intro i
      by_cases hi' : i = id.slot
      · subst hi'; simp only [upd, ite_true]
        exact nextGen_range (hw.genRange _).1 (hw.genRange _).2
      · simp only [upd, hi', ite_false]; exact hw.genRange i
    · have := occCount_set_false a.occ id.slot a.cap hs ho
      simp only
      rw [hw.activeEq]; omega
  · simp only [hl] at h
    simp at h; obtain ⟨rfl, _⟩ := h; exact hw

theorem fork_wf {a a' : Arena} {p id : Id} (hw : a.WF) (h : a.fork p = some (a', id)) : a'.WF := by
  unfold Arena.fork at h
  split at h
  · exact alloc_wf hw h
  · simp at h

/-! ### The invariant theorems -/

/-- a live id has exactly the slot's current generation (generation mismatch never resolves) -/
theorem live_gen_match {a : Arena} {id : Id} (h : a.live id = true) :
    id.slot < a.cap ∧ a.gen id.slot = id.gen ∧ a.occ id.slot = true := by
  simpa [Arena.live, Bool.and_eq_true, decide_eq_true_eq, and_assoc] using h

theorem generation_mismatch_not_live {a : Arena} {id : Id} (h : a.gen id.slot ≠ id.gen) :
    a.live id = false := by
  unfold Arena.live; simp [h]

/-- free invalidates the old id: it no longer resolves, and the slot carries a different generation -/
theorem free_invalidates {a a' : Arena} {id : Id} (hw : a.WF) (h : a.release id = (a', true)) :
    a'.live id = false ∧ a'.gen id.slot ≠ id.gen := by
  unfold Arena.release at h
  by_cases hl : a.live id = true
  · simp only [hl, ite_true, Prod.mk.injEq] at h
    obtain ⟨rfl, _⟩ := h
    obtain ⟨hs, hg, ho⟩ := live_gen_match hl
    have hne : nextGen (a.gen id.slot) ≠ id.gen := by
      rw [← hg]; exact nextGen_ne (hw.genRange _).1 (hw.genRange _).2
    refine ⟨?_, ?_⟩
    · apply generation_mismatch_not_live; simpa [upd] using hne
    · simpa [upd] using hne
  · simp only [hl] at h; simp at h

/-- free of a non-live id (stale, wrong generation, out of range, already freed) changes nothing -/
theorem free_stale_noop {a : Arena} {id : Id} (h : a.live id = false) :
    a.release id = (a, false) := by
  unfold Arena.release; simp [h]

/-- successful free is only possible for a live id -/
theorem free_true_iff_live {a a' : Arena} {id : Id} (h : a.release id = (a', true)) : a.live id = true := by
  unfold Arena.release at h
  by_cases hl : a.live id = true
  · exact hl
  · simp only [hl] at h; simp at h

/-- allocation hands out a live id at the slot's current generation -/
theorem alloc_live {a a' : Arena} {id : Id} (hw : a.WF) (h : a.alloc = some (a', id)) : a'.live id = true := by
  unfold Arena.alloc at h
  cases hf : a.free with
  | nil => simp [hf] at h
  | cons s rest =>
    simp only [hf, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    have hs : s < a.cap := hw.freeRange s (by simp [hf])
    simp [Arena.live, upd, hs]

/-- active count never exceeds capacity -/
theorem active_le_cap {a : Arena} (hw : a.WF) : a.active ≤ a.cap := by
  rw [hw.activeEq]; exact occCount_le _ _

/-- capacity cannot be exceeded: allocation is refused exactly when active = cap -/
theorem alloc_none_iff_full {a : Arena} (hw : a.WF) : a.alloc = none ↔ a.active = a.cap := by
  unfold Arena.alloc
  cases hf : a.free with
  | nil =>
    simp only [true_iff]
    rw [hw.activeEq]
    apply occCount_all
    intro i hi
    have := hw.freeIff i hi
    simp only [hf, List.not_mem_nil, false_iff] at this
    simpa using this
  | cons s rest =>
    simp only [reduceCtorEq, false_iff]
    have hs : s < a.cap := hw.freeRange s (by simp [hf])
    have hso : a.occ s = false := (hw.freeIff s hs).1 (by simp [hf])
    intro hfull
    rw [hw.activeEq] at hfull
    have := occCount_set_true a.occ s a.cap hs hso
    have h2 := occCount_le (upd a.occ s true) a.cap
    omega

/-- successful allocation raises the active count by exactly one and stays within capacity -/
theorem alloc_active {a a' : Arena} {id : Id} (hw : a.WF) (h : a.alloc = some (a', id)) :
    a'.active = a.active + 1 ∧ a'.active ≤ a'.cap ∧ a'.cap = a.cap := by
  have hw' := alloc_wf hw h
  unfold Arena.alloc at h
  cases hf : a.free with
  | nil => simp [hf] at h
  | cons s rest =>
    simp only [hf, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨rfl, active_le_cap hw', rfl⟩

/-- successful free lowers the active count by exactly one -/
theorem release_active {a a' : Arena} {id : Id} (hw : a.WF) (h : a.release id = (a', true)) :
    a'.active + 1 = a.active := by
  have hl := free_true_iff_live h
  obtain ⟨hs, _, ho⟩ := live_gen_match hl
  unfold Arena.release at h
  simp only [hl, ite_true, Prod.mk.injEq] at h
  obtain ⟨rfl, _⟩ := h
  have := occCount_set_false a.occ id.slot a.cap hs ho
  simp only
  rw [hw.activeEq]; omega

/-- fork from a stale or unknown parent is refused -/
theorem fork_stale_refused {a : Arena} {p : Id} (h : a.live p = false) : a.fork p = none := by
  unfold Arena.fork; simp [h]

/-- fork success implies the parent id was live -/
theorem fork_parent_live {a a' : Arena} {p id : Id} (h : a.fork p = some (a', id)) : a.live p = true := by
  unfold Arena.fork at h
  by_cases hl : a.live p = true
  · exact hl
  · simp only [hl] at h; simp at h

/-- allocation reads the slot's current generation and leaves every generation unchanged -/
theorem alloc_gen {a a' : Arena} {id : Id} (h : a.alloc = some (a', id)) :
    id.gen = a.gen id.slot ∧ a'.gen = a.gen := by
  unfold Arena.alloc at h
  cases hf : a.free with
  | nil => simp [hf] at h
  | cons s rest =>
    simp only [hf, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨rfl, rfl⟩

/-- slot reuse changes identity: free an id, allocate again, and if the same slot comes back the id
differs. One-step case; it needs no wrap assumption. -/
theorem reuse_changes_identity {a a1 a2 : Arena} {id id2 : Id} (hw : a.WF)
    (hf : a.release id = (a1, true)) (ha : a1.alloc = some (a2, id2)) (_hslot : id2.slot = id.slot) :
    id2 ≠ id := by
  intro heq
  have hi := (free_invalidates hw hf).2
  have hg := (alloc_gen ha).1
  apply hi
  rw [← heq]; exact hg.symm

end AienSeq
