import AienKv.Model
namespace AienKv

/-! Rules enforced by the code (AIEN.INV.KV.LAYOUT_BOUNDS.V1). Every theorem is for every config. -/

/-- scaling a bound: `i < n` gives `i*s + s ≤ n*s` -/
theorem succ_mul_le {i n s : Nat} (h : i < n) : i * s + s ≤ n * s := by
  have := Nat.mul_le_mul_right s (show i + 1 ≤ n from h)
  rw [Nat.succ_mul] at this; exact this

/-! ### Nested bounds, innermost first -/

theorem elem_in_head (c : Cfg) {d : Nat} (h : d < c.headDim) : d * c.elemBytes + c.elemBytes ≤ c.head :=
  succ_mul_le h

theorem head_in_token (c : Cfg) {h : Nat} (hh : h < c.numKvHeads) : h * c.head + c.head ≤ c.token :=
  succ_mul_le hh

theorem token_in_plane (c : Cfg) {t : Nat} (ht : t < c.blockSize) : t * c.token + c.token ≤ c.plane :=
  succ_mul_le ht

theorem plane_in_layer (c : Cfg) {v : Nat} (hv : v < 2) : v * c.plane + c.plane ≤ c.layer := by
  have := succ_mul_le (s := c.plane) hv
  unfold Cfg.layer; exact this

theorem layer_in_block (c : Cfg) {l : Nat} (hl : l < c.numLayers) : l * c.layer + c.layer ≤ c.block :=
  succ_mul_le hl

theorem block_in_total (c : Cfg) {b : Nat} (hb : b < c.numBlocks) : b * c.block + c.block ≤ c.total :=
  succ_mul_le hb

/-- THE BOUNDS THEOREM. A valid (block, layer, K/V, token, head, dim) names an element whose bytes
`[off, off + elemBytes)` lie inside the allocation `[0, total)`. -/
theorem element_in_allocation (c : Cfg) {b l v t h d : Nat} (hv : c.Valid b l v t h d) :
    InRange (c.off b l v t h d) c.elemBytes c.total := by
  obtain ⟨hb, hl, hv2, ht, hh, hd⟩ := hv
  have e1 := elem_in_head c hd
  have e2 := head_in_token c hh
  have e3 := token_in_plane c ht
  have e4 := plane_in_layer c hv2
  have e5 := layer_in_block c hl
  have e6 := block_in_total c hb
  unfold InRange Cfg.off
  omega

/-- the token-plane address used by `write_token_kv` / `read_token_kv` is also inside, with room for a full
`numKvHeads * headDim` row -/
theorem token_row_in_allocation (c : Cfg) {b l v t : Nat} (hb : b < c.numBlocks) (hl : l < c.numLayers)
    (hv : v < 2) (ht : t < c.blockSize) : InRange (c.tokOff b l v t) c.token c.total := by
  have e3 := token_in_plane c ht
  have e4 := plane_in_layer c hv
  have e5 := layer_in_block c hl
  have e6 := block_in_total c hb
  unfold InRange Cfg.tokOff
  omega

/-- `block_region`: block b occupies `[b*block, b*block + block)` inside the allocation -/
theorem block_region_in_allocation (c : Cfg) {b : Nat} (hb : b < c.numBlocks) :
    InRange (b * c.block) c.block c.total := block_in_total c hb

/-! ### Disjointness -/

/-- distinct blocks have disjoint regions -/
theorem block_regions_disjoint (c : Cfg) {b1 b2 : Nat} (h : b1 ≠ b2) :
    Disjoint (b1 * c.block) c.block (b2 * c.block) c.block := by
  unfold Disjoint
  rcases Nat.lt_or_gt_of_ne h with h | h
  · left; exact succ_mul_le h
  · right; exact succ_mul_le h

/-- distinct layers of the same block have disjoint, in-block regions -/
theorem layer_regions_disjoint (c : Cfg) {l1 l2 : Nat} (h : l1 ≠ l2) :
    Disjoint (l1 * c.layer) c.layer (l2 * c.layer) c.layer := by
  unfold Disjoint
  rcases Nat.lt_or_gt_of_ne h with h | h
  · left; exact succ_mul_le h
  · right; exact succ_mul_le h

/-- every layer region lies inside its block -/
theorem layer_region_in_block (c : Cfg) {l : Nat} (hl : l < c.numLayers) :
    InRange (l * c.layer) c.layer c.block := layer_in_block c hl

/-- K and V planes of one layer are disjoint (K ends exactly where V starts) -/
theorem k_v_planes_disjoint (c : Cfg) (l : Nat) :
    Disjoint (l * c.layer + 0 * c.plane) c.plane (l * c.layer + 1 * c.plane) c.plane := by
  unfold Disjoint; left; omega

/-- distinct tokens of one plane have disjoint rows -/
theorem token_rows_disjoint (c : Cfg) {t1 t2 : Nat} (h : t1 ≠ t2) :
    Disjoint (t1 * c.token) c.token (t2 * c.token) c.token := by
  unfold Disjoint
  rcases Nat.lt_or_gt_of_ne h with h | h
  · left; exact succ_mul_le h
  · right; exact succ_mul_le h

/-- the stride chain itself is consistent: block = layers * 2 * planes and plane = tokens * heads * dim * bytes -/
theorem block_closed_form (c : Cfg) :
    c.block = 2 * c.numLayers * c.blockSize * c.numKvHeads * c.headDim * c.elemBytes := by
  unfold Cfg.block Cfg.layer Cfg.plane Cfg.token Cfg.head
  simp only [Nat.mul_assoc, Nat.mul_left_comm, Nat.mul_comm]

/-- `bytes_per_block` (2 * layers * block_size * heads * dim * element size) is the same number -/
theorem block_eq_bytes_per_block (c : Cfg) :
    c.block = 2 * c.numLayers * c.blockSize * c.numKvHeads * c.headDim * c.elemBytes := block_closed_form c

/-! ### Pool constructor: `buffer.len() >= total_bytes` -/

/-- if the host buffer is at least `total` bytes (the check in `UnifiedKvTensorPool::new`), every valid
element's bytes lie inside the host buffer -/
theorem element_in_buffer (c : Cfg) {b l v t h d bufLen : Nat} (hv : c.Valid b l v t h d)
    (hbuf : c.total ≤ bufLen) : InRange (c.off b l v t h d) c.elemBytes bufLen := by
  have := element_in_allocation c hv
  unfold InRange at *; omega

/-! ### 64-bit (machine) arithmetic: when the natural-number result is the machine result -/

def two64 : Nat := 18446744073709551616

/-- all six dimensions are nonzero (a zero dimension has no valid element at all) -/
def Cfg.Pos (c : Cfg) : Prop :=
  1 ≤ c.numBlocks ∧ 1 ≤ c.blockSize ∧ 1 ≤ c.numLayers ∧ 1 ≤ c.numKvHeads ∧ 1 ≤ c.headDim ∧ 1 ≤ c.elemBytes

/-- With nonzero dimensions the strides grow along the chain head <= token <= plane <= layer <= block <= total.
So if `total < 2^64`, no stride product wraps and the unbounded model is exact for the Rust `usize` code. -/
theorem machine_exact_when_total_fits (c : Cfg) (hp : c.Pos) (ht : c.total < two64) :
    c.head < two64 ∧ c.token < two64 ∧ c.plane < two64 ∧ c.layer < two64 ∧ c.block < two64 := by
  obtain ⟨hnb, hbs, hnl, hnh, _, _⟩ := hp
  have h1 : c.block ≤ c.total := Nat.le_mul_of_pos_left _ hnb
  have h2 : c.layer ≤ c.block := Nat.le_mul_of_pos_left _ hnl
  have h3 : c.plane ≤ c.layer := by unfold Cfg.layer; omega
  have h4 : c.token ≤ c.plane := Nat.le_mul_of_pos_left _ hbs
  have h5 : c.head ≤ c.token := Nat.le_mul_of_pos_left _ hnh
  omega

/-- and every valid offset (and each summand of it) is below total, hence below 2^64 -/
theorem offset_fits_u64 (c : Cfg) {b l v t h d : Nat} (hv : c.Valid b l v t h d) (ht : c.total < two64) :
    c.off b l v t h d < two64 := by
  have := element_in_allocation c hv
  unfold InRange at this; omega

/-- THE LIMITATION, stated: the unbounded model and the Rust code disagree as soon as `total ≥ 2^64`.
`from_config` does not refuse such a config (no checked arithmetic). -/
def wrapTotal (c : Cfg) : Nat := c.total % two64

theorem wrap_total_smaller (c : Cfg) (h : two64 ≤ c.total) : wrapTotal c < c.total := by
  unfold wrapTotal two64 at *; omega

end AienKv
