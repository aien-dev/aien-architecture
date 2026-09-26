# Specification: Milestone 18: OMEGA Blackwell Tensor MatMul (`OMEGA_BLACKWELL_MATMUL`)

```text
Document ID:     SPEC-ACCEL-M18
Milestone:       Milestone 18 (OMEGA_BLACKWELL_MATMUL)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Physical Blackwell Tensor Matrix Multiplication on NVIDIA DGX Spark (GB10, sm_121)
Status:          COMPLETE / SILICON QUALIFIED
Ratified:        2026-09-26
Implementation:  aien-dev/omega (commit 9421737)
Receipt:         aien-dev/omega (commit 87349c0)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3/M15/M16) -> OMEGA (M4-M14) -> M16 (Native Submission) -> M17 (Blackwell Vector) -> M18 (Blackwell MatMul)
```

---

## 1. Executive Summary & Sovereignty Boundary

Milestone 17 (`OMEGA_BLACKWELL_VECTOR`) established the first sovereign compute realization on physical Blackwell silicon by binding an unsigned 32-bit vector addition semantic contract ($G_S$) to a verified canonical machine-code artifact, dynamically synthesizing QMD launch descriptors, and executing via the native M16 GPFIFO submission path on physical NVIDIA DGX Spark GB10 silicon.

Milestone 18 establishes **native Blackwell tensor matrix multiplication with tensor core acceleration**:

> **M17 QUALIFIED SOVEREIGN EXECUTION OF A CANONICAL MACHINE-CODE ARTIFACT.**
> **M18 ESTABLISHES OMEGA AS A DYNAMIC BLACKWELL NATIVE CODE GENERATOR.**

Milestone 18 executes the pipeline:

$$\text{Semantic MatMul Contract } (G_S) \longrightarrow \text{OMEGA Instruction Selection} \longrightarrow \text{OMEGA Register Allocation} \longrightarrow \text{Dynamic SASS Encoding} \longrightarrow \text{QMD v5.0 Launch} \longrightarrow \text{M16 Native Submission} \longrightarrow \text{Physical GB10 Tensor Execution} \longrightarrow \text{Bounded Parity Verification}$$

### Strict Epistemic Scope and Sovereignty Mandate
Milestone 18 forbids qualifying by repeating the Milestone 17 method with a larger static or precompiled instruction table. Milestone 18 crosses the code generation boundary:
1. **Instruction Selection**: OMEGA maps the semantic matrix multiplication contract into native Blackwell sm_121 instruction forms.
2. **Bounded Deterministic Register Allocation**: OMEGA allocates physical General Purpose Registers and Uniform Registers dynamically by computing genuine live intervals and register assignments for active tile operands, accumulators, and base pointers, rather than returning predetermined hardcoded register numbers. General-purpose spilling, coalescing, and graph coloring are intentionally deferred to subsequent compiler milestones.
3. **Operand and Field Encoding**: OMEGA programmatically encodes 128-bit sm_121 machine code words (opcodes, register indices, immediate constants, cache modifiers, and predicate masks).
4. **Dynamic Instruction Sequencing**: OMEGA sequences the complete compute kernel: tile index calculation, global loads, tensor core math instructions, barrier synchronization, and global stores.
5. **Dynamic Launch Descriptors**: Queue Meta Data (QMD Version 05_00) launch descriptors configure 2D CTA grid rasterization.
6. **Native Hardware Submission**: Pushbuffer generation and GPFIFO ring submission execute directly via the qualified M16 substrate without proprietary userspace runtimes (`libcuda.so`, `libcudart.so`).

### Mandatory Tensor-Core Completion Invariant
INT32 matrix multiplication serves strictly as an intermediate codegen qualification step. Milestone 18 cannot complete until:
1. FP16 or BF16 tensor-core MMA executes on physical GB10 silicon.
2. Accumulation executes in FP32 precision.
3. Machine code is generated dynamically by OMEGA without static instruction tables.
4. Numerical parity falls strictly within bounded reference tolerances.
5. Empirical hardware evidence proves that the physical tensor-core MMA execution path was utilized.

---

## 2. Mathematical Semantic Contract & Precision Oracle

The computation is defined by an immutable machine-independent matrix multiplication contract:

1. **Operation**: General Matrix Multiplication:
   $$C[m, n] = \sum_{k=0}^{K-1} A[m, k] B[k, n] \quad \text{for } m \in [0, M-1], n \in [0, N-1]$$
2. **Data Types & Precision Stages**:
   - **Intermediate Stage (Integer Codegen Qualification)**: Signed/unsigned 32-bit integer matrix multiplication ($C[m, n] = (\sum A[m,k] B[k,n]) \pmod{2^{32}}$). Requires bit-for-bit exact mathematical parity against the CPU reference oracle (zero epsilon tolerance).
   - **Mandatory Final Stage (Tensor-Core Silicon Qualification)**: 16-bit floating point (FP16 or BF16) matrix multiplication with FP32 accumulation executing on GB10 tensor cores. Requires strict ULP-bounded mathematical parity against IEEE-754 reference evaluation.
3. **Matrix Dimensions & Sweeps**:
   - Square canonical tiles: $M = N = K \in \{16, 32, 64, 128\}$.
   - Non-square rectangular boundary sweeps: $(M, K, N) \in \{(16, 64, 32), (32, 16, 64), (64, 32, 16)\}$.
   - Memory layouts: Row-major matrix $A$, column-major or row-major matrix $B$, row-major matrix $C$.
4. **Deterministic Input Generator**:
   - Deterministic arithmetic pattern: $A[m, k] = (m \times 17 + k \times 31 + 7) \pmod{256}$, $B[k, n] = (k \times 13 + n \times 29 + 11) \pmod{256}$.
   - Boundary tests: Identity matrix verification ($A \times I = A$), zero matrix annihilation ($A \times 0 = 0$), and dynamic range wrap tests.
5. **Exact Verification Oracle**: CPU reference implementation evaluated on Host ARM64 vs physical GPU output buffer on GB10 silicon.

---

## 3. Four-Component Realization Identity

Realization on physical accelerator hardware binds four distinct components into a single canonical 32-byte identifier:

$$\text{REALIZATION\_ID} = \text{SHA-256}(\text{spec\_id} \parallel \text{machine\_id} \parallel \text{code\_digest} \parallel \text{sm\_arch})$$

### Bound Input Components (100 Bytes Total)
1. **`spec_id` (32 bytes)**: Canonical SHA-256 semantic identity of the machine-independent matrix multiplication operation in $G_S$ parameterized by $(M, K, N, \text{precision})$.
2. **`machine_id` (32 bytes)**: Machine graph identity representing the physical DGX Spark execution environment (`NVIDIA_DGX_SPARK_GB10_SM121`).
3. **`code_digest` (32 bytes)**: Bit-for-bit SHA-256 digest of the dynamically generated sm_121 machine code artifact for the target matrix shape and tile configuration.
4. **`sm_arch` (4 bytes, little-endian `uint32_t = 121`)**: Target streaming multiprocessor microarchitecture version.

Because `code_digest` is computed over dynamically generated machine code rather than a static table, the realization identity deterministically proves that the synthesized machine code reflects the exact semantic contract and target microarchitecture.

---

## 4. Dynamic Code Generation Substrate (Code Truth Doctrine)

Milestone 18 implements the sovereign Blackwell code generator in OMEGA:

### 4.1 Modular Codegen Architecture
1. **Instruction Selector (`omega_blackwell_select`)**:
   - Traverses the semantic matrix multiplication DAG.
   - Decomposes the operation into load stages, tile index arithmetic, tile accumulation, synchronization, and store stages.
   - Selects native sm_121 instruction primitives:
     - `LDC` / `LDCU`: Parameter and uniform descriptor loading.
     - `S2R`: Special register reading (`SR_CTAID.X`, `SR_CTAID.Y`, `SR_TID.X`).
     - `IMAD` / `IMAD.WIDE`: Index and pointer arithmetic.
     - `LDG.E`: Global memory loads with uniform descriptors.
     - Tensor Core / MMA instructions: Hardware matrix multiply-accumulate primitives.
     - `BAR.SYNC`: CTA thread group synchronization.
     - `STG.E`: Global memory stores.
     - `EXIT` / `BRA`: Control flow and program termination.
2. **Bounded Deterministic Register Allocator (`omega_blackwell_regalloc`)**:
   - Scoped specifically to matrix multiplication kernels.
   - Computes genuine live intervals and register assignments over active tile operands, accumulators, and base pointers.
   - Rejects predetermined hardcoded register tables.
   - Emits an allocation error if live ranges exceed hardware register capacity, preventing silent spill corruption.
3. **Instruction Encoder (`omega_blackwell_encode_insn`)**:
   - Synthesizes 128-bit sm_121 instruction words programmatically from opcode specifications, register fields, immediate constants, and predicate masks.
   - Encodes control fields (stall cycles, yield flags, barrier synchronization markers) into instruction bundles.
4. **Program Sequencer (`omega_blackwell_codegen_matmul`)**:
   - Assembles the complete instruction sequence with 128-byte alignment.
   - Computes the runtime SHA-256 `code_digest`.
   - Validates that zero static instruction tables were used in the generation path.

### 4.2 Ordered Development Sequence
Execution follows a two-stage sequential progression:

**Stage 1: Integer Codegen Foundation**
1. INT32 semantic matrix multiplication contract.
2. Minimal IR and selected instruction nodes.
3. Bounded deterministic register allocator.
4. Dynamic scalar integer instruction encoder.
5. Physical INT32 matrix multiplication pass on GB10.
6. Dynamic codegen variation proof (`M18_CODEGEN_VARIATION_PASS`).

**Stage 2: Tensor-Core Acceleration & Qualification**
7. FP16/BF16 semantic matrix contract with FP32 accumulation.
8. Empirical determination of minimum sm_121 tensor MMA instruction forms using allowed research oracles.
9. Integration of tensor MMA instruction forms into OMEGA dynamic encoder.
10. Tensor tile register allocation.
11. Dynamic tensor-core kernel generation.
12. Physical GB10 tensor execution.
13. FP32-accumulation numerical parity verification.
14. Hardware evidence proof of tensor-core utilization.
15. Clean-clone isolated reproduction, zero-libcuda proof, and durable qualification receipt.

---

## 5. Queue Meta Data (QMD Version 05_00) 2D Grid Launch

Blackwell matrix dispatch utilizes the 384-byte Queue Meta Data Version 05_00 layout with 2D tile rasterization:

1. **Grid Geometry**:
   - `cta_raster_width = (N + TILE_N - 1) / TILE_N`
   - `cta_raster_height = (M + TILE_M - 1) / TILE_M`
   - `cta_raster_depth = 1`
   - Thread dimensions: Configured to match the warp and thread group allocation of the active tile configuration.
2. **Memory and Caching Configuration**:
   - `qmd_group_id = 0x3f`
   - `sm_global_caching_enable = 1`
   - Cache invalidation flags enabled on texture and data headers.
   - Constant buffer 0: Mapped to 1024 bytes containing 64-bit pointers ($A, B, C$), matrix dimensions ($M, K, N$), and row/column strides.
   - Shared memory size: Dynamically sized to accommodate tile buffers.
3. **SKEDCHECK05 Compliance**:
   - Local memory allocations zeroed (`local_memory_total_size = 0`, `local_memory_max_size = 0`).

---

## 6. Native Submission Path & M16 Dependency

Milestone 18 relies strictly on the qualified Milestone 16 native submission substrate:
1. Pushbuffer construction with header methods configuring compute engine state.
2. Direct GPFIFO ring entry formatting.
3. BAR0 doorbell trigger at aperture offset `+0x90`.
4. Coherent memory semaphore release monitoring with timeout and error classification.
5. Zero foreign userspace runtime dependency: Zero dynamic linkage to `libcuda.so` or `libcudart.so`, zero undefined dynamic CUDA symbols, zero runtime mappings in `/proc/self/maps`.

---

## 7. Qualification Gates & Cumulative Accounting

Milestone 18 qualification requires passing 18 Milestone 18 gates in addition to the 139 cumulative regression gates established through Milestone 17. Total evaluated gates: 157.

### Milestone 18 Qualification Gates
- **Gate 1: `OMEGA_BW_MATMUL_SEMANTIC_CONTRACT_PASS`**: Formal Mathematical Semantic Contract Specification & CPU Oracle Parity.
- **Gate 2: `OMEGA_BW_MATMUL_MACHINE_GRAPH_PASS`**: Machine Graph ($G_M$) Representation for GB10 Tensor Units & SM Architecture.
- **Gate 3: `OMEGA_BW_MATMUL_ENCODER_UNIT_PASS`**: Dynamic sm_121 Instruction Encoder Unit Tests (Bitfield programmatic encoding).
- **Gate 4: `OMEGA_BW_MATMUL_BOUNDED_REGALLOC_PASS`**: Bounded Deterministic Live-Interval Register Allocation & Conflict Rejection.
- **Gate 5: `OMEGA_BW_MATMUL_INSTRUCTION_SEQUENCING_PASS`**: Dynamic Instruction Sequencer & 128-Byte Bundle Alignment.
- **Gate 6: `OMEGA_BW_MATMUL_CODE_TRUTH_PASS`**: Code Truth Invariant: Zero Static Precompiled Instruction Tables in Codegen Core.
- **Gate 7: `OMEGA_BW_MATMUL_CODEGEN_VARIATION_PASS`**: Stage-1 Codegen Variation Proof: Generates distinct valid kernels across two distinct INT32 configurations ($16\times 16\times 16$ INT32 vs $32\times 16\times 64$ INT32), demonstrating distinct semantic IDs, distinct allocation traces where shape requires it, distinct instruction immediates, loop structures, or code bytes, distinct code digests, and successful execution on physical GB10 silicon for each.
- **Gate 8: `OMEGA_BW_MATMUL_REALIZATION_ID_PASS`**: Dynamic Code Digest (`code_digest`) Computation and Realization Identity Binding.
- **Gate 9: `OMEGA_BW_MATMUL_QMD_2D_PASS`**: QMD Version 05_00 2D Grid Launch Descriptor Synthesis.
- **Gate 10: `OMEGA_BW_MATMUL_NATIVE_SUBMIT_PASS`**: Native M16 Submission Path & GPFIFO Pushbuffer Integration.
- **Gate 11: `OMEGA_BW_MATMUL_INT32_INTERMEDIATE_PASS`**: Intermediate INT32 Execution on Physical GB10 with Exact Bit-for-Bit Parity.
- **Gate 12: `OMEGA_BW_MATMUL_TENSOR_CORE_EXECUTION_PASS`**: Mandatory Silicon Completion Gate: Physical GB10 Tensor Core MMA Execution with FP32 Accumulation. Requires the verified 9-point evidence bundle: (1) OMEGA-selected MMA instruction node in the IR; (2) Register allocation trace for operands and accumulators; (3) Exact 128-bit machine instruction words emitted by OMEGA; (4) Independent research-oracle decode identifying emitted words as the intended MMA instruction form; (5) Runtime SHA-256 digest of the generated kernel; (6) Physical GB10 completion with semaphore state update; (7) FP32 accumulated output within specified numerical bound; (8) Controlled mutation test proving corrupted MMA opcode or operand fields fail qualification or diverge; (9) Zero-libcuda runtime audit. Cross-precision variation requirement: FP16 tensor realization and BF16 tensor realization must generate distinct instruction forms, operands, and code digests.
- **Gate 13: `OMEGA_BW_MATMUL_NUMERICAL_BOUND_PASS`**: Bounded Numerical Parity against Reference Oracle across Canonical Shapes ($16\times 16$, $32\times 32$, $16\times 64\times 32$).
- **Gate 14: `OMEGA_BW_MATMUL_BOUNDARY_ANNIHILATION_PASS`**: Boundary and Annihilation Matrix Tests (Identity, Zeros, Extreme Dynamic Range).
- **Gate 15: `OMEGA_BW_MATMUL_ZERO_LIBCUDA_PASS`**: Zero Foreign Userspace Runtime Verification (`ldd`, `nm -u`, `/proc/self/maps`).
- **Gate 16: `OMEGA_BW_MATMUL_CLEAN_CLONE_PASS`**: Clean-Clone Isolated Reproduction on DGX Spark Silicon.
- **Gate 17: `OMEGA_BW_MATMUL_REGRESSION_PASS`**: Cumulative Regression Parity: 139 / 139 prior milestone gates passing (M4 through M17).
- **Gate 18: `OMEGA_BW_MATMUL_RECEIPT_PASS`**: Cryptographic Qualification Receipt Generation with Hardware Trace Evidence.

---

## 8. Zero Foreign Userspace Runtime Verification

Strict execution invariant:
1. `ldd <binary>`: Must show no dynamic dependency on `libcuda.so*` or `libcudart.so*`.
2. `nm -u <binary>`: Must show zero undefined symbols containing `cu` or `cuda`.
3. `/proc/self/maps`: During physical execution on DGX Spark, memory maps must confirm no loaded CUDA userspace drivers.
