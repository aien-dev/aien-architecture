/-!
# Abstract model of the pooled KV tensor layout (DEVELOPMENT_ORACLE)

Source modelled: aien-dev/sovereign-core `crates/aien-kv-cache/src/lib.rs` at dd1fe32,
`KvLayout::from_config` (stride arithmetic), `element_offset`, `token_plane_offset`,
`block_offset`, and `UnifiedKvTensorPool::{new, block_region}`.

Invariant: AIEN.INV.KV.LAYOUT_BOUNDS.V1 (formal/invariants/kv-layout-bounds-v1.toml).

Abstractions (each is an ASSUMPTION, not a proof):
* Arithmetic is on unbounded naturals. The Rust code uses `usize` with NO checked arithmetic.
  The theorems in `Theorems.lean` (section "64-bit") state exactly when the natural
  result equals the machine result: every product stays below 2^64, equivalently `total < 2^64`
  when `numBlocks ≥ 1`. A concrete wrap witness is in `Corpus.lean`, and was reproduced in a release
  build of the real crate (see DISCREPANCIES.md).
* Bytes are a half-open range `[start, start + len)`. "Within allocation" means the range lies in
  `[0, total)`.
* `elemBytes` is the dtype width in bytes (Fp8 1, Bf16/Fp16 2, Fp32 4). Fp4 is refused by the code
  and is not modelled.
* Alignment and the host buffer's own address are not modelled. The pool constructor's check
  `buffer.len() >= total_bytes` is modelled as the hypothesis `bufLen ≥ total`.
-/
namespace AienKv

structure Cfg where
  numBlocks : Nat
  blockSize : Nat      -- tokens per block
  numLayers : Nat
  numKvHeads : Nat
  headDim : Nat
  elemBytes : Nat

/-- Rust `KvLayout::from_config`, same order of operations. -/
def Cfg.head (c : Cfg) : Nat := c.headDim * c.elemBytes
def Cfg.token (c : Cfg) : Nat := c.numKvHeads * c.head
def Cfg.plane (c : Cfg) : Nat := c.blockSize * c.token
def Cfg.layer (c : Cfg) : Nat := 2 * c.plane
def Cfg.block (c : Cfg) : Nat := c.numLayers * c.layer
def Cfg.total (c : Cfg) : Nat := c.numBlocks * c.block

/-- Rust `element_offset` (is_value = 0 for K, 1 for V). -/
def Cfg.off (c : Cfg) (b l v t h d : Nat) : Nat :=
  b * c.block + l * c.layer + v * c.plane + t * c.token + h * c.head + d * c.elemBytes

/-- Rust `token_plane_offset`. -/
def Cfg.tokOff (c : Cfg) (b l v t : Nat) : Nat :=
  b * c.block + l * c.layer + v * c.plane + t * c.token

/-- All indices valid (the Rust asserts, in `element_offset`). -/
def Cfg.Valid (c : Cfg) (b l v t h d : Nat) : Prop :=
  b < c.numBlocks ∧ l < c.numLayers ∧ v < 2 ∧ t < c.blockSize ∧ h < c.numKvHeads ∧ d < c.headDim

/-- A byte range `[s, s+n)` lies inside `[0, total)`. -/
abbrev InRange (s n total : Nat) : Prop := s + n ≤ total

/-- Two byte ranges do not overlap. -/
abbrev Disjoint (s1 n1 s2 n2 : Nat) : Prop := s1 + n1 ≤ s2 ∨ s2 + n2 ≤ s1

end AienKv
