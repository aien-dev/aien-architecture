# Specification: Milestone 18: OMEGA Blackwell Tensor MatMul (`OMEGA_BLACKWELL_MATMUL`)

```text
Document ID:     SPEC-ACCEL-M18
Milestone:       Milestone 18 (OMEGA_BLACKWELL_MATMUL)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Physical Blackwell Tensor Matrix Multiplication on NVIDIA DGX Spark (GB10, sm_121)
Status:          OPEN / IN PROGRESS
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
2. **Register Allocation**: OMEGA allocates physical General Purpose Registers (R0 through R255) and Uniform Registers (UR0 through UR63) dynamically without hardcoded register assignments.
3. **Operand and Field Encoding**: OMEGA programmatically encodes 128-bit sm_121 machine code words (opcodes, register indices, immediate constants, cache modifiers, and predicate masks).
4. **Dynamic Instruction Sequencing**: OMEGA sequences the complete compute kernel: tile index calculation, global loads, tensor core math instructions, barrier synchronization, and global stores.
5. **Dynamic Launch Descriptors**: Queue Meta Data (QMD Version 05_00) launch descriptors configure 2D CTA grid rasterization.
6. **Native Hardware Submission**: Pushbuffer generation and GPFIFO ring submission execute directly via the qualified M16 substrate without proprietary userspace runtimes (`libcuda.so`, `libcudart.so`).

---

## 2. Mathematical Semantic Contract & Precision Oracle

The computation is defined by an immutable machine-independent matrix multiplication contract:

1. **Operation**: General Matrix Multiplication:
   $$C[m, n] = \sum_{k=0}^{K-1} A[m, k] B[k, n] \quad \text{for } m \in [0, M-1], n \in [0, N-1]$$
2. **Data Types & Precision Stages**:
   - **Phase 1 (Exact Integer Verification)**: Signed/unsigned integer matrix multiplication with 32-bit integer accumulation ($C[m, n] = (\sum A[m,k] B[k,n]) \pmod{2^{32}}$). Requires bit-for-bit exact mathematical parity against the CPU reference oracle (zero epsilon tolerance).
   - **Phase 2 (Accelerated Precision)**: 16-bit floating point (FP16 or BF16) matrix multiplication with FP32 accumulation. Requires strict ULP-bounded mathematical parity against IEEE-754 reference evaluation.
3. **Matrix Dimensions & Sweeps**:
   - Square canonical tiles: $M = N = K \in \{16, 32, 64, 128\}$.
   - Non-square rectangular boundary sweeps: $(M, K, N) \in \{(16, 64, 32), (32, 16, 64), (64, 32, 16)\}$.
   - Memory layouts: Row-major matrix $A$, column-major or row-major matrix $B$, row-major matrix $C$.
4. **Deterministic Input Generator**:
   - Deterministic arithmetic pattern: $A[m, k] = (m \times 17 + k \times 31 + 7) \pmod{256}$, $B[k, n] = (k \times 13 + n \times 29 + 11) \pmod{256}$.
   - Boundary tests: Identity matrix verification ($A \times I = A$), zero matrix annihilation ($A \times 0 = 0$), and maximum dynamic range wrap/overflow tests.
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
2. **Register Allocator (`omega_blackwell_regalloc`)**:
   - Allocates general registers (R0 through R255) based on live intervals of tile inputs, accumulators, and memory pointers.
   - Allocates uniform registers (UR0 through UR63) for uniform descriptors and grid invariants.
   - Emits allocation failure if live ranges exceed hardware register capacity, preventing silent spill corruption.
3. **Instruction Encoder (`omega_blackwell_encode_insn`)**:
   - Synthesizes 128-bit sm_121 instruction words programmatically from opcode specifications, register fields, immediate constants, and predicate masks.
   - Encodes control fields (stall cycles, yield flags, barrier synchronization markers) into instruction bundles.
4. **Program Sequencer (`omega_blackwell_codegen_matmul`)**:
   - Assembles the complete instruction sequence with 128-byte alignment.
   - Computes the runtime SHA-256 `code_digest`.
   - Validates that zero static instruction tables were used in the generation path.

---

## 5. Queue Meta Data (QMD Version 05_00) 2D Grid Launch

Blackwell matrix dispatch utilizes the 384-byte Queue Meta Data Version 05_00 layout with 2D tile rasterization:

1. **Grid Geometry**:
   - `cta_raster_width = (N + TILE_N - 1) / TILE_N`
   - `cta_raster_height = (M + TILE_M - 1) / TILE_M`
   - `cta_raster_depth = 1`
   - Thread dimensions: Configured to match the warp/thread group allocation of the active tile configuration.
2. **Memory and Caching Configuration**:
   - `qmd_group_id = 0x3f`
   - `sm_global_caching_enable = 1`
   - Cache invalidation flags enabled on texture/data headers.
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

Milestone 18 qualification requires passing 16 Milestone 18 gates in addition to the 139 cumulative regression gates established through Milestone 17.

### Milestone 18 Qualification Gates
- **Gate 1**: Formal Mathematical Semantic Contract Specification & CPU Oracle Parity.
- **Gate 2**: Machine Graph ($G_M$) Representation for GB10 Tensor Units & SM Architecture.
- **Gate 3**: Dynamic sm_121 Instruction Encoder Unit Tests (Bitfield programmatic encoding).
- **Gate 4**: Dynamic Register Allocator Determinism & Conflict Rejection.
- **Gate 5**: Dynamic Instruction Sequencer & 128-Byte Bundle Alignment.
- **Gate 6**: Code Truth Invariant: Zero Static Precompiled Instruction Tables in Codegen Core.
- **Gate 7**: Dynamic Code Digest (`code_digest`) Computation and Realization Identity Binding.
- **Gate 8**: QMD Version 05_00 2D Grid Launch Descriptor Synthesis.
- **Gate 9**: Native M16 Submission Path & GPFIFO Pushbuffer Integration.
- **Gate 10**: Square Matrix Parity ($16\times 16$, $32\times 32$) against OMEGA Semantic Oracle.
- **Gate 11**: Non-Square Rectangular Matrix Parity ($16\times 64 \times 32$).
- **Gate 12**: Boundary and Annihilation Matrix Tests (Identity, Zeros, Extreme Dynamic Range).
- **Gate 13**: Coherent Memory Semaphore Completion & Execution Timing on Physical GB10.
- **Gate 14**: Zero Foreign Userspace Runtime Verification (`ldd`, `nm -u`, `/proc/self/maps`).
- **Gate 15**: Clean-Clone Isolated Reproduction on DGX Spark Silicon.
- **Gate 16**: Cumulative Regression Parity: 139 / 139 prior milestone gates passing (M4 through M17).

---

## 8. Zero Foreign Userspace Runtime Verification

Strict execution invariant:
1. `ldd <binary>`: Must show no dynamic dependency on `libcuda.so*` or `libcudart.so*`.
2. `nm -u <binary>`: Must show zero undefined symbols containing `cu` or `cuda`.
3. `/proc/self/maps`: During physical execution on DGX Spark, memory maps must confirm no loaded CUDA userspace drivers.
