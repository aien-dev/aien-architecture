import AienKv.Theorems
namespace AienKv

/-- TinyLlama as `KvPoolConfig::for_tinyllama(num_blocks, 16, Fp32)`: 22 layers, 4 KV heads, head dim 64. -/
def tiny (nb : Nat) : Cfg :=
  { numBlocks := nb, blockSize := 16, numLayers := 22, numKvHeads := 4, headDim := 64, elemBytes := 4 }

/-! Ties to the PREFILL-E2E-0 receipt (spark-cpu-5512e3c): kv_block_bytes = 720896, physical_kv_bytes =
10092544 = 14 blocks. Which config the receipt run used is read from transformer_backend.rs (Fp32) and
lib.rs (block_size 16); the receipt itself does not record dtype or block size. -/
theorem pos_tinyllama_block_bytes : (tiny 1).block = 720896 := by decide
theorem pos_receipt_physical_bytes : 14 * (tiny 1).block = 10092544 := by decide
theorem pos_strides : (tiny 1).head = 256 ∧ (tiny 1).token = 1024 ∧ (tiny 1).plane = 16384 ∧
    (tiny 1).layer = 32768 := by decide

/-- last element of the last block -/
theorem pos_last_element_in_pool :
    InRange ((tiny 256).off 255 21 1 15 3 63) 4 (tiny 256).total := by decide
theorem pos_last_element_exact :
    (tiny 256).off 255 21 1 15 3 63 + 4 = (tiny 256).total := by decide
theorem pos_first_element : (tiny 256).off 0 0 0 0 0 0 = 0 := by decide
theorem pos_v_plane_start : (tiny 256).off 0 0 1 0 0 0 = 16384 := by decide
theorem pos_next_block_start : (tiny 256).off 1 0 0 0 0 0 = 720896 := by decide

/-- an index just past each limit is NOT inside (the bounds theorem needs validity) -/
theorem neg_block_past_end : ¬ InRange ((tiny 256).off 256 0 0 0 0 0) 4 (tiny 256).total := by decide
theorem neg_token_overruns_into_next_plane :
    (tiny 256).off 0 0 0 16 0 0 = (tiny 256).off 0 0 1 0 0 0 := by decide

/-- V flag 2 (invalid) aliases the next layer: why the `v < 2` validity matters -/
theorem neg_v_flag_2_aliases_next_layer :
    (tiny 256).off 0 0 2 0 0 0 = (tiny 256).off 0 1 0 0 0 0 := by decide

/-- concrete wrap: block 720896 B times 2^45 blocks = 25364273101350633472 B >= 2^64; the machine value wraps to
6917529027641081856, as reproduced by `KvPoolConfig{num_blocks: 1<<45,..}.layout()` in a release build. -/
theorem wrap_witness_real : (tiny (2 ^ 45)).total = 25364273101350633472 := by decide
theorem wrap_witness_machine : wrapTotal (tiny (2 ^ 45)) = 6917529027641081856 := by decide
theorem wrap_witness_over : two64 ≤ (tiny (2 ^ 45)).total := by decide

end AienKv
