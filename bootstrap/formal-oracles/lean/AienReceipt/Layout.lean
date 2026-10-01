import AienReceipt.Model
import AienReceipt.Theorems
namespace AienReceipt

/-! ## 512-byte layout and encode/decode (Rust `encode`, `decode`)

`Layout.fields` is the offset/width table of the Rust `encode` (receipt.rs lines 101-137, header
constants lines 14-18). `layoutContiguous` is checked by `decide`: fields tile 0..512 with no gap or
overlap. `Raw` is the record split into those fields. -/

/-- (offset, width) for every field, in order. Includes reserved 56..64, signature block 400..500
and reserved tail 500..512. -/
def layout : List (Nat × Nat) :=
  [(0,8),(8,2),(10,2),(12,4),(16,4),(20,2),(22,2),(24,8),(32,16),(48,8),(56,8),
   (64,4),(68,4),(72,4),(76,2),(78,2),(80,4),(84,4),(88,4),(92,4),
   (96,32),(128,32),(160,32),(192,32),(224,32),(256,32),(288,32),(320,32),(352,32),
   (384,8),(392,8),(400,100),(500,12)]

def contiguousFrom : Nat → List (Nat × Nat) → Option Nat
  | n, [] => some n
  | n, (o, w) :: rest => if o == n then contiguousFrom (n + w) rest else none

/-- the fields tile exactly 512 bytes -/
theorem layout_tiles_512 : contiguousFrom 0 layout = some 512 := by decide

/-- `RECEIPT_MAGIC = b"AIENRCP\0"` as bytes -/
def magic : List Nat := [65, 73, 69, 78, 82, 67, 80, 0]
theorem magic_len : magic.length = 8 := rfl

def receiptVersion : Nat := 0
def headerSize : Nat := 96
def recordSize : Nat := 512

structure Raw where
  magic    : List Nat
  version  : Nat
  hdr      : Nat
  size     : Nat
  flags    : Nat
  decision : Nat
  tier     : Nat
  sequence : Nat
  nonce    : Nat
  reserved1 : Nat   -- bytes 56..64
  observed : Nat
  status   : Nat
  exitCode : Int
  rflags   : Nat
  stage    : Nat
  reason   : Nat
  syscalls : Nat
  reads    : Nat
  denials  : Nat
  frames   : Nat
  digests  : List Nat
  verifier : Nat
  machineId : Nat
  generation : Nat
  contextId : Nat
  sigOk    : Bool   -- signature block all zero, or algorithm id valid (crypto itself assumed)
  reserved2 : Nat   -- bytes 500..512

def Presence.toNat (p : Presence) : Nat :=
  (if p.machine then 1 else 0) + (if p.context then 2 else 0) + (if p.time then 4 else 0)
def Presence.ofNat (n : Nat) : Presence :=
  { machine := n % 2 == 1, context := n / 2 % 2 == 1, time := n / 4 % 2 == 1 }

def ResultFlags.toNat (f : ResultFlags) : Nat :=
  (if f.readOk then 1 else 0) + (if f.writeDenied then 2 else 0) + (if f.reclaimed then 4 else 0) +
  (if f.canaryPassed then 8 else 0) + (if f.forgedDenied then 16 else 0) +
  (if f.mappedMatch then 32 else 0) + (if f.executedMatch then 64 else 0) +
  (if f.wxSealed then 128 else 0)
def ResultFlags.ofNat (n : Nat) : ResultFlags :=
  { readOk := n % 2 == 1, writeDenied := n / 2 % 2 == 1, reclaimed := n / 4 % 2 == 1,
    canaryPassed := n / 8 % 2 == 1, forgedDenied := n / 16 % 2 == 1,
    mappedMatch := n / 32 % 2 == 1, executedMatch := n / 64 % 2 == 1,
    wxSealed := n / 128 % 2 == 1 }

def Decision.toNat : Decision → Nat | .admitted => 1 | .rejected => 2 | .canaryFailed => 3 | .destroyed => 4
def Decision.ofNat? : Nat → Option Decision
  | 1 => some .admitted | 2 => some .rejected | 3 => some .canaryFailed | 4 => some .destroyed
  | _ => none
def Tier.toNat : Tier → Nat | .seed0bQemu => 1 | .seed0bMachine1 => 2
def Tier.ofNat? : Nat → Option Tier | 1 => some .seed0bQemu | 2 => some .seed0bMachine1 | _ => none
def Status.toNat : Status → Nat
  | .notRun => 0 | .exited => 1 | .timeout => 2 | .fault => 3 | .badSyscall => 4
  | .resourceOverrun => 5 | .canaryFailed => 6
def Status.ofNat? : Nat → Option Status
  | 0 => some .notRun | 1 => some .exited | 2 => some .timeout | 3 => some .fault
  | 4 => some .badSyscall | 5 => some .resourceOverrun | 6 => some .canaryFailed | _ => none

/-- Rust `encode`: constants for magic, version, header size, record size; reserved bytes zero;
signature block zero (kernel-emitted record). -/
def encode (r : Receipt) : Raw :=
  { magic := magic, version := receiptVersion, hdr := headerSize, size := recordSize,
    flags := r.pres.toNat, decision := r.decision.toNat, tier := r.tier.toNat,
    sequence := r.sequence, nonce := r.nonce, reserved1 := 0, observed := r.observed,
    status := r.status.toNat, exitCode := r.exitCode, rflags := r.rflags.toNat,
    stage := r.stage, reason := r.reason, syscalls := r.syscalls, reads := r.reads,
    denials := r.denials, frames := r.frames, digests := r.digests, verifier := r.verifier,
    machineId := r.machineId, generation := r.generation, contextId := r.contextId,
    sigOk := true, reserved2 := 0 }

/-- Rust `decode`: strict layout checks, enum codes, then `validate`. -/
def decode (nf : Nat → Nat → Nat) (b : Raw) : Option Receipt :=
  if b.magic = magic ∧ b.version = receiptVersion ∧ b.hdr = headerSize ∧ b.size = recordSize ∧
     b.flags < 8 ∧ b.rflags < 256 ∧ b.reserved1 = 0 ∧ b.reserved2 = 0 ∧ b.sigOk = true then
    match Decision.ofNat? b.decision, Tier.ofNat? b.tier, Status.ofNat? b.status with
    | some d, some t, some s =>
      let r : Receipt :=
        { pres := Presence.ofNat b.flags, decision := d, tier := t, sequence := b.sequence,
          nonce := b.nonce, observed := b.observed, status := s, exitCode := b.exitCode,
          rflags := ResultFlags.ofNat b.rflags, stage := b.stage, reason := b.reason,
          syscalls := b.syscalls, reads := b.reads, denials := b.denials, frames := b.frames,
          digests := b.digests, verifier := b.verifier, machineId := b.machineId,
          generation := b.generation, contextId := b.contextId }
      if validate nf r = true then some r else none
    | _, _, _ => none
  else none

theorem presence_roundtrip (p : Presence) : Presence.ofNat p.toNat = p := by
  cases p with | mk a b c => cases a <;> cases b <;> cases c <;> decide
theorem presence_lt (p : Presence) : p.toNat < 8 := by
  cases p with | mk a b c => cases a <;> cases b <;> cases c <;> decide
theorem rflags_roundtrip (f : ResultFlags) : ResultFlags.ofNat f.toNat = f := by
  cases f with | mk a b c d e g h i =>
    cases a <;> cases b <;> cases c <;> cases d <;> cases e <;> cases g <;> cases h <;> cases i <;> decide
theorem rflags_lt (f : ResultFlags) : f.toNat < 256 := by
  cases f with | mk a b c d e g h i =>
    cases a <;> cases b <;> cases c <;> cases d <;> cases e <;> cases g <;> cases h <;> cases i <;> decide

/-- encode then decode returns the receipt exactly when `validate` accepts it, else nothing.
Holds for every nonce function (crypto assumption). -/
theorem decode_encode_eq (nf : Nat → Nat → Nat) (r : Receipt) :
    decode nf (encode r) = if validate nf r = true then some r else none := by
  obtain ⟨pres, dec, tier, seq, nonce, obs, st, ex, rf, stage, reason, sc, rd, dn, fr, dg, ver, mid, gen, cid⟩ := r
  have hp := presence_roundtrip pres
  have hpl := presence_lt pres
  have hf := rflags_roundtrip rf
  have hfl := rflags_lt rf
  simp only [decode, encode, hp, hf, hpl, hfl, receiptVersion, headerSize, recordSize]
  cases dec <;> cases tier <;> cases st <;>
    simp [Decision.toNat, Decision.ofNat?, Tier.toNat, Tier.ofNat?, Status.toNat, Status.ofNat?]

/-- encode then decode preserves every valid abstract receipt -/
theorem decode_encode {nf} {r : Receipt} (h : validate nf r = true) : decode nf (encode r) = some r := by
  rw [decode_encode_eq]; simp [h]

/-- a receipt that `validate` refuses never survives encode then decode -/
theorem encode_invalid_refused {nf} {r : Receipt} (h : validate nf r = false) : decode nf (encode r) = none := by
  rw [decode_encode_eq]; simp [h]

/-- decode never returns a receipt that `validate` refuses -/
theorem decode_valid {nf} {b : Raw} {r : Receipt} (h : decode nf b = some r) : validate nf r = true := by
  unfold decode at h
  split at h
  · split at h
    · dsimp only at h
      split at h
      · injection h with h; subst h; assumption
      · cases h
    · cases h
  · cases h

/-- encode writes the contract constants -/
theorem encode_constants (r : Receipt) :
    (encode r).magic = magic ∧ (encode r).version = 0 ∧ (encode r).hdr = 96 ∧ (encode r).size = 512 :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- a wrong magic or version is refused by decode -/
theorem decode_bad_magic (nf) (b : Raw) (h : b.magic ≠ magic) : decode nf b = none := by
  simp [decode, h]
theorem decode_bad_version (nf) (b : Raw) (h : b.version ≠ 0) : decode nf b = none := by
  simp [decode, receiptVersion, h]

end AienReceipt
