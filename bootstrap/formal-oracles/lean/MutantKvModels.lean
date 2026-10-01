import AienKv.Corpus
/-!
# Deliberate mutants of the KV layout (each must break one required rule)

WRONG on purpose. Each mutant model compiles; the matching claim file must not.
-/
namespace AienKv

/-- MUTANT 1 (kv_planes_overlap): layer stride is one plane, so the V plane starts inside the next layer. -/
def Cfg.layerM1 (c : Cfg) : Nat := c.plane

/-- MUTANT 2 (total_one_block_short): the allocation is one block too small. -/
def Cfg.totalM2 (c : Cfg) : Nat := c.numBlocks * c.block - c.block

/-- MUTANT 3 (token_stride_forgets_element_size): token stride = heads * dim, not heads * dim * bytes. -/
def Cfg.tokenM3 (c : Cfg) : Nat := c.numKvHeads * c.headDim

/-- MUTANT 4 (validity_off_by_one): the K/V selector is allowed to be 0, 1 or 2. -/
def Cfg.ValidM4 (c : Cfg) (b l v t h d : Nat) : Prop :=
  b < c.numBlocks ∧ l < c.numLayers ∧ v < 3 ∧ t < c.blockSize ∧ h < c.numKvHeads ∧ d < c.headDim

/-- MUTANT 5 (block_stride_short): consecutive blocks are placed one byte too close. -/
def Cfg.blockStrideM5 (c : Cfg) : Nat := c.block - 1

theorem m1_witness : (tiny 4).plane = (tiny 4).layerM1 ∧ (tiny 4).layerM1 < 2 * (tiny 4).plane := by decide
theorem m2_witness : (tiny 4).totalM2 < (tiny 4).block * 4 := by decide
theorem m3_witness : (tiny 4).tokenM3 < (tiny 4).head * 4 := by decide
theorem m4_witness : (tiny 4).off 0 0 2 0 0 0 + 4 ≤ (tiny 4).total ∧ ¬ (tiny 4).Valid 0 0 2 0 0 0 := by
  refine ⟨by decide, ?_⟩; unfold Cfg.Valid; decide
theorem m5_witness : 1 * (tiny 4).blockStrideM5 + (tiny 4).block > 1 * (tiny 4).block := by decide

end AienKv
