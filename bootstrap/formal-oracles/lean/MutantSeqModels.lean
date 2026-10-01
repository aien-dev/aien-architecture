import AienSeq.Corpus
/-!
# Deliberate mutants of the sequence arena (each must break one required rule)

WRONG on purpose. Each mutant model compiles; the matching claim file must not.
-/
namespace AienSeq

/-- MUTANT 1 (free_keeps_generation): free does not bump the generation. -/
def Arena.releaseM1 (a : Arena) (id : Id) : Arena × Bool :=
  if a.live id then
    ({ a with occ := upd a.occ id.slot false, free := id.slot :: a.free, active := a.active - 1 }, true)
  else (a, false)

/-- MUTANT 2 (get_ignores_generation): resolution ignores the generation. -/
def Arena.liveM2 (a : Arena) (id : Id) : Bool :=
  decide (id.slot < a.cap) && a.occ id.slot

/-- MUTANT 3 (wrap_to_zero): the wrap drops the `.max(1)`, so generation 0 can appear. -/
def nextGenM3 (g : Nat) : Nat := (g + 1) % two32

/-- MUTANT 4 (free_keeps_active): free forgets to decrement the active count. -/
def Arena.releaseM4 (a : Arena) (id : Id) : Arena × Bool :=
  if a.live id then
    ({ a with occ := upd a.occ id.slot false, gen := upd a.gen id.slot (nextGen (a.gen id.slot)),
              free := id.slot :: a.free }, true)
  else (a, false)

/-- MUTANT 5 (fork_without_parent_check): fork allocates even when the parent id is stale. -/
def Arena.forkM5 (a : Arena) (_parent : Id) : Option (Arena × Id) := a.alloc

/-- witnesses: each mutant accepts what the real model refuses -/
theorem m1_reuses_generation :
    allocId ((allocArena a2).releaseM1 ⟨0, 1⟩).1 = some ⟨0, 1⟩ := by decide
theorem m2_wrong_gen_resolves : (allocArena a2).liveM2 ⟨0, 7⟩ = true := by decide
theorem m3_zero_generation : nextGenM3 genMax = 0 := by decide
theorem m4_active_stuck : (((allocArena a2).releaseM4 ⟨0, 1⟩).1).active = 1 := by decide
theorem m5_stale_fork_allowed :
    (((allocArena a2).release ⟨0, 1⟩).1.forkM5 ⟨0, 1⟩).isSome = true := by decide
theorem real_refuses_stale_fork :
    (((allocArena a2).release ⟨0, 1⟩).1.fork ⟨0, 1⟩).isSome = false := by decide

end AienSeq
