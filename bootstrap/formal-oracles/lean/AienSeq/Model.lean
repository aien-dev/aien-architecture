/-!
# Abstract model of the Rust generational sequence arena (DEVELOPMENT_ORACLE)

Source modelled: aien-dev/sovereign-core `crates/aien-runtime/src/sequence.rs` at dd1fe32
(`SequenceArena::{new, allocate, fork, get, free, active_count}`, `SequenceId`).
The scheduler arena `crates/aien-scheduler/src/sequence.rs` differs (it retires a slot instead of
wrapping); its free rule is modelled separately as `retireNext` in this file.

Invariant: AIEN.INV.SEQUENCE.STALE_ID.V1 (formal/invariants/sequence-stale-id-v1.toml).

Abstractions (each is an ASSUMPTION, not a proof):
* The arena is a total function from slot number to a slot, plus a capacity `cap`; slots at or
  beyond `cap` are never consulted (Rust `slots.get(i)` returns None there).
* Record contents (priority, world id, ...) are not modelled. Only presence (`occ`) matters here.
* `u32` generation arithmetic IS modelled: generations live in [1, 2^32 - 1] (`genMax`).
* `free_slots` is a stack (head = next pop). Rust pops the back of a reversed Vec, the same order.
* Single scheduler thread (the arena has no locks, by its own doc comment). No concurrency model.
-/
namespace AienSeq

/-- 2^32 (the generation field is a `u32`). -/
def two32 : Nat := 4294967296
/-- Largest generation, u32::MAX. -/
def genMax : Nat := 4294967295

structure Id where
  slot : Nat
  gen  : Nat
  deriving DecidableEq, Repr

/-- Rust: `slot.generation.wrapping_add(1).max(1)` on a `u32`. -/
def nextGen (g : Nat) : Nat := max ((g + 1) % two32) 1

structure Arena where
  gen    : Nat → Nat        -- generation counter per slot
  occ    : Nat → Bool       -- slot holds a record
  free   : List Nat         -- free_slots, head is popped next
  active : Nat              -- active_count
  cap    : Nat              -- capacity

def upd {α : Type} (f : Nat → α) (i : Nat) (v : α) : Nat → α :=
  fun j => if j = i then v else f j

/-- Rust `SequenceArena::new(capacity)`: every generation 1, nothing occupied, all slots free. -/
def Arena.init (cap : Nat) : Arena :=
  { gen := fun _ => 1, occ := fun _ => false, free := List.range cap, active := 0, cap := cap }

/-- Rust `get`: the record behind an id, if the slot exists, the generation matches and a record is present. -/
def Arena.live (a : Arena) (id : Id) : Bool :=
  decide (id.slot < a.cap) && decide (a.gen id.slot = id.gen) && a.occ id.slot

/-- Rust `allocate`: pop a free slot, hand out (slot, current generation). `none` = capacity exhausted. -/
def Arena.alloc (a : Arena) : Option (Arena × Id) :=
  match a.free with
  | [] => none
  | s :: rest =>
      some ({ a with occ := upd a.occ s true, free := rest, active := a.active + 1 },
            { slot := s, gen := a.gen s })

/-- Rust `fork`: refused when the parent id does not resolve, else allocate. -/
def Arena.fork (a : Arena) (parent : Id) : Option (Arena × Id) :=
  if a.live parent then a.alloc else none

/-- Rust `free`: succeeds only for a live id; bumps the generation, returns the slot to the free stack. -/
def Arena.release (a : Arena) (id : Id) : Arena × Bool :=
  if a.live id then
    ({ a with occ := upd a.occ id.slot false, gen := upd a.gen id.slot (nextGen (a.gen id.slot)),
              free := id.slot :: a.free, active := a.active - 1 }, true)
  else (a, false)

/-! ### Scheduler arena variant: retire the slot at u32::MAX instead of wrapping -/

/-- `aien-scheduler` `free_sequence`: at `u32::MAX` the slot is retired (never reused); else generation + 1. -/
def retireNext (g : Nat) : Option Nat := if g = genMax then none else some (g + 1)

/-- Number of occupied slots below `n`. -/
def occCount (occ : Nat → Bool) : Nat → Nat
  | 0 => 0
  | n + 1 => occCount occ n + (if occ n then 1 else 0)

/-- Well-formedness: what `new` establishes and every operation must keep. -/
structure Arena.WF (a : Arena) : Prop where
  freeRange : ∀ i ∈ a.free, i < a.cap
  freeNodup : a.free.Nodup
  freeIff   : ∀ i, i < a.cap → (i ∈ a.free ↔ a.occ i = false)
  genRange  : ∀ i, 1 ≤ a.gen i ∧ a.gen i < two32
  activeEq  : a.active = occCount a.occ a.cap

end AienSeq
