import AienSeq.Theorems
namespace AienSeq

/-! Concrete traces. The theorems in `Theorems.lean` hold for every arena; the corpus shows the rules
fire on concrete records, and fixes the Rust numbers (generation starts at 1, wrap skips 0). -/

/-- the id handed out by alloc, if any -/
def allocId (a : Arena) : Option Id := (a.alloc).map (·.2)
/-- the arena after alloc (unchanged when refused) -/
def allocArena (a : Arena) : Arena := match a.alloc with | some (a', _) => a' | none => a

def a2 : Arena := Arena.init 2

/-! Positive -/
theorem pos_first_id : allocId a2 = some ⟨0, 1⟩ := by decide
theorem pos_second_id : allocId (allocArena a2) = some ⟨1, 1⟩ := by decide
theorem pos_live_after_alloc : (allocArena a2).live ⟨0, 1⟩ = true := by decide
theorem pos_free_then_reuse_new_gen :
    allocId ((allocArena a2).release ⟨0, 1⟩).1 = some ⟨0, 2⟩ := by decide
theorem pos_free_live_true : ((allocArena a2).release ⟨0, 1⟩).2 = true := by decide
theorem pos_fork_live_parent : ((allocArena a2).fork ⟨0, 1⟩).isSome = true := by decide
theorem pos_wrap_skips_zero : nextGen genMax = 1 := by decide
theorem pos_gen_increments : nextGen 1 = 2 := by decide

/-! Negative: each is refused / not live. -/
theorem neg_never_allocated : a2.live ⟨0, 1⟩ = false := by decide
theorem neg_stale_after_free :
    (((allocArena a2).release ⟨0, 1⟩).1).live ⟨0, 1⟩ = false := by decide
theorem neg_stale_free_refused :
    ((((allocArena a2).release ⟨0, 1⟩).1).release ⟨0, 1⟩).2 = false := by decide
theorem neg_wrong_generation : (allocArena a2).live ⟨0, 2⟩ = false := by decide
theorem neg_generation_zero : (allocArena a2).live ⟨0, 0⟩ = false := by decide
theorem neg_slot_out_of_range : (allocArena a2).live ⟨5, 1⟩ = false := by decide
theorem neg_fork_stale_parent :
    ((((allocArena a2).release ⟨0, 1⟩).1).fork ⟨0, 1⟩).isSome = false := by decide
theorem neg_capacity_exhausted :
    allocId (allocArena (allocArena a2)) = none := by decide
theorem neg_old_id_vs_new_slot_owner :
    ((allocArena ((allocArena a2).release ⟨0, 1⟩).1).live ⟨0, 1⟩) = false := by decide

/-- an arena whose slot 0 generation sits at u32::MAX: free then reuse yields generation 1, not 0 -/
def aMax : Arena := { Arena.init 1 with gen := fun _ => genMax, occ := fun _ => true, free := [], active := 1 }
theorem pos_wrap_in_arena : allocId (aMax.release ⟨0, genMax⟩).1 = some ⟨0, 1⟩ := by decide
theorem neg_wrapped_id_differs : (aMax.release ⟨0, genMax⟩).1.live ⟨0, genMax⟩ = false := by decide

/-- Real Rust numbers: 2^32 - 1 = 4294967295 generations per slot before the wrap limitation applies -/
theorem generation_period : genMax = 4294967295 := rfl

end AienSeq
