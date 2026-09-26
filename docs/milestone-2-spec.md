# Specification: Milestone 2 — Physics Authority Nucleus (`PHYSICS_BOOT`)

## Problem Statement

When `ATLAS` completes the machine awakening and verifies the integrity of the secondary payload, the system requires an authoritative entity to govern the physical substrate. In conventional operating systems, this layer is burdened with monolithic complexity: multi-gigabyte kernel images, thousands of device drivers, complex POSIX abstractions, preemptive task schedulers, dynamic loadable modules, and sprawling memory management subsystems. This legacy surface area introduces ambient authority, non-deterministic latency, opaque failure states, and unverifiable execution paths.

A sovereign computational architecture demands the opposite: **Physics must be a minimal, immutable, auditable authority nucleus, NOT a conventional operating system kernel.** It must answer a single constitutional question: *"What is allowed to become physically real?"*

Milestone 2 establishes the foundational Physics nucleus (`physics.bin`): validating one-time ingress boot parameters from Atlas, adopting current-EL exception handling, carving physical memory into bounded capability-governed frame authority, establishing polled diagnostic console telemetry, and synthesizing the kernel-private root capability record that terminates ambient authority.

---

## Solution

Implement and formally qualify the Physics Authority Nucleus (`physics.bin`) as the trusted physical machine authority of the Sovereign Machine.

Physics enters under the normative `PHYSICS_ENTRY_ABI` established by Atlas, validates and copies the one-time ingress Machine Boot Descriptor into kernel-private state, checks the current execution level (`CurrentEL`), installs its own deterministic 2,048-byte aligned 16-entry Exception Vector Table (`VBAR_EL1` or `VBAR_EL2`), establishes a disjoint physical memory layout, initializes physical frame authority over unreserved DRAM, takes ownership of the polled serial console, synthesizes the kernel-private root capability record (`CAP_ROOT`), verifies synchronous exception confinement, and establishes the initial zero-ambient-authority regime.

---

## User Stories

1. **As a system architect**, I want Physics to remain a minimal authority nucleus ($\le 32\text{ KiB}$ total code/rodata) rather than a full OS kernel, so that the trusted machine authority remains auditable, mathematically verifiable, and bounded.
2. **As a security auditor**, I want Physics to treat the Atlas Machine Boot Descriptor as untrusted one-time ingress data, validating magic, version, length, overflow, DRAM containment, and device addresses before copying into kernel-private state and dropping all references to Atlas scratchpad RAM.
3. **As a bare-metal engineer**, I want Physics to query `CurrentEL` and dynamically install the correct vector register (`VBAR_EL1` at EL1 or `VBAR_EL2` at EL2), failing closed if entered at an uncontracted exception level, with zero implicit EL switching.
4. **As a verification engineer**, I want the AArch64 exception vector table to span exactly 2,048 bytes (`0x000`–`0x7FF`) with 16 architectural vector slots spaced 128 bytes (`0x80`) apart, each slot cleanly bounded without handler overlap.
5. **As a test engineer**, I want deliberate exception triggers (e.g. software breakpoint or unmapped read) to capture raw architectural trap state (`VECTOR_SLOT`, `CURRENT_EL`, `ESR_ELx`, `ELR_ELx`, `SPSR_ELx`, `FAR_ELx` with validity flag) into a structured trap record and halt in fail-closed quiescence without host crash or unbounded loops.
6. **As a systems programmer**, I want a strictly disjoint physical memory map defining non-overlapping reserved regions (`PHYSICS_IMAGE`, `PHYSICS_VECTOR_TABLE`, `PHYSICS_KERNEL_STACK`, `PHYSICS_BOOT_STATE`, `PHYSICS_CAPABILITY_TABLE`, `PHYSICS_STATIC_DATA`), so that stack, static data, and metadata cannot collide.
7. **As a capability architect**, I want Physics to own **Physical Frame Authority**, where frames are allocated strictly above `FREE_FRAME_BASE = ALIGN_UP(PHYSICS_RESERVED_END, 4096)` and below `DRAM_END`, permanently excluding all reserved Physics pages.
8. **As a security officer**, I want `CAP_ROOT` to be a non-transferable, kernel-private authority tree root with typed identity `CapabilityId { slot, generation }` rather than an ambient, address-dependent, raw memory pointer.
9. **As a platform engineer**, I want Physics to validate UART MMIO parameters and emit structured diagnostic telemetry (`PHYSICS: AWAKEN`, `PHYSICS: INGRESS_VALID`, `PHYSICS: VBAR_INSTALLED`, `PHYSICS: FRAME_AUTH_BOUND`, `PHYSICS: CAP_ROOT_GENESIS`, `PHYSICS: QUIESCENT_READY`).
10. **As an adversarial test engineer**, I want semantic descriptor corruption tests (bad cookie, invalid version, truncated length, zero DRAM, base+size overflow, out-of-profile UART) to deterministically fail closed before frame authority or capabilities are initialized.
11. **As an auditor**, I want a generalized byte accounting audit reconciling `CODE_BYTES` + `RODATA_BYTES` + `CANONICAL_PADDING_BYTES` + `OTHER_DECLARED_BYTES` = `EXACT BINARY SIZE` with 0-byte discrepancy.
12. **As a compliance officer**, I want distinct qualification gates for QEMU emulation (`PHYSICS_BOOT_QEMU_PASS`) and physical DGX Spark hardware (`PHYSICS_BOOT_NATIVE_PASS`), ensuring virtual qualification never implies physical hardware correctness.

---

## Implementation Decisions

### 1. The Anti-Bloat Law (Authority Nucleus vs OS Kernel)
Physics is strictly bounded to physical authority mechanisms:
- **Included:** Entry ABI validation, ingress copy, contract-driven `VBAR_ELx`, physical frame authority, kernel-private capability root, polled console telemetry, raw fault confinement, and fail-closed panic.
- **Strictly Excluded:** POSIX syscalls, fork/exec, preemptive multi-threading, dynamic linkers, VFS/filesystems, socket networking, graphics drivers, model runtimes, and user shells.
- **Size Bounds:**
  - `.text <= 32 KiB`
  - `PHYSICS_TOTAL_IMAGE_BYTES <= 64 KiB` (including code, rodata, vector table, and alignment padding).

### 2. Ingress Descriptor Validation & Isolation Boundary
The Atlas Machine Boot Descriptor (`0x401FE000`) is treated as one-time ingress data:
1. **Validation Checks (Prior to Consumption):**
   - Cookie check: `x2 == 0x5048595349435330` (`'PHYSICS0'`).
   - Pointer check: `x0 == 0x401FE000`.
   - Length check: descriptor size $\ge 64$ bytes.
   - Arithmetic overflow check: `DRAM_BASE + DRAM_SIZE` must not overflow 64-bit integer space.
   - Image containment: Physics image (`0x40200000`..`0x40208000`) must be strictly contained within `[DRAM_BASE, DRAM_BASE + DRAM_SIZE)`.
   - Device sanity: UART base must equal contract-approved address (`0x09000000` on QEMU Virt) with 4-byte alignment.
   - Exception level: `CurrentEL[3:2]` must match contract expectation (EL1 or EL2).
2. **Ingress Copy:**
   - Validated fields are copied into `PHYSICS_BOOT_STATE` (`[0x40205800, 0x40206000)`).
   - Once copied, Physics unsets all references to Atlas scratchpad memory (`x0`, `sp`). Atlas scratchpad memory is permanently uncoupled.

### 3. Contract-Driven Exception Level & Vector Architecture
1. **Contract-Driven EL Programming:**
   - Physics reads `CurrentEL`.
   - If `CurrentEL == 0x04` (EL1): programs `VBAR_EL1`.
   - If `CurrentEL == 0x08` (EL2): programs `VBAR_EL2`.
   - If any other value: vectors immediately to terminal quiescent panic.
   - Zero implicit transitions between EL2 and EL1.
2. **Vector Table Geometry (`PHYSICS_VECTOR_LAYOUT_PASS`):**
   - Table base is strictly aligned to a 2 KiB boundary (`base % 2048 == 0`).
   - Table span is exactly 2,048 bytes (`0x000`–`0x7FF`).
   - 16 architectural vector slots spaced exactly 128 bytes (`0x80`) apart:
     * `0x000`: Current EL with SP0 (Sync)
     * `0x080`: Current EL with SP0 (IRQ)
     * `0x100`: Current EL with SP0 (FIQ)
     * `0x180`: Current EL with SP0 (SError)
     * `0x200`: Current EL with SPx (Sync -> Main Trap)
     * `0x280`: Current EL with SPx (IRQ)
     * `0x300`: Current EL with SPx (FIQ)
     * `0x380`: Current EL with SPx (SError)
     * `0x400`: Lower EL AArch64 (Sync)
     * `0x480`: Lower EL AArch64 (IRQ)
     * `0x500`: Lower EL AArch64 (FIQ)
     * `0x580`: Lower EL AArch64 (SError)
     * `0x600`: Lower EL AArch32 (Sync)
     * `0x680`: Lower EL AArch32 (IRQ)
     * `0x700`: Lower EL AArch32 (FIQ)
     * `0x780`: Lower EL AArch32 (SError)
   - Every slot contains a bounded branch to a common trap collector. No slot code or data overlaps another.
3. **Raw Exception State Capture:**
   - On trap, handler saves `x0`–`x30` to `PHYSICS_BOOT_STATE`.
   - Captures: `VECTOR_SLOT`, `CURRENT_EL`, `ESR_ELx`, `ELR_ELx`, `SPSR_ELx`.
   - Evaluates `ESR_ELx.EC` (Exception Class): reads `FAR_ELx` only if the fault class makes FAR valid (Data Aborts, Instruction Aborts, Alignment, PC faults); otherwise marks `FAR_VALID = 0`.
   - Emits minimal raw hexadecimal diagnostic telemetry over polled UART and enters `wfe; b .`.

### 4. Disjoint Physical Memory Map
Physics establishes strictly partitioned, pairwise non-overlapping memory regions:

```text
0x4000_0000 ┌──────────────────────────────────────────┐ <── DRAM Base (Atlas Staging / DTB)
            │ Unused / Staging / Atlas Scratchpad      │
0x4020_0000 ├──────────────────────────────────────────┤ <── PHYSICS_IMAGE_BASE
            │ PHYSICS_IMAGE (.text, .rodata)           │ [4 KiB] [0x40200000, 0x40201000)
0x4020_1000 ├──────────────────────────────────────────┤ <── PHYSICS_VECTOR_TABLE (2 KiB aligned)
            │ VBAR Table (16 x 128B slots)             │ [2 KiB] [0x40201000, 0x40201800)
0x4020_1800 ├──────────────────────────────────────────┤ <── PHYSICS_KERNEL_STACK (grows downward)
            │ Dedicated Kernel Stack                   │ [16 KiB][0x40201800, 0x40205800)
            │ Initial SP = 0x40205800                  │
0x4020_5800 ├──────────────────────────────────────────┤ <── PHYSICS_BOOT_STATE
            │ Copied Ingress Descriptor & Trap Record  │ [2 KiB] [0x40205800, 0x40206000)
0x4020_6000 ├──────────────────────────────────────────┤ <── PHYSICS_CAPABILITY_TABLE
            │ CAP_ROOT & Authority Table               │ [4 KiB] [0x40206000, 0x40207000)
0x4020_7000 ├──────────────────────────────────────────┤ <── PHYSICS_STATIC_DATA
            │ Static Tables & Frame Bitmaps            │ [4 KiB] [0x40207000, 0x40208000)
0x4020_8000 ├──────────────────────────────────────────┤ <── FREE_FRAME_BASE = ALIGN_UP(RESERVED_END, 4096)
            │ Bounded Free DRAM Frames (Frame Auth)    │ [~125.9 MiB]
0x4800_0000 └──────────────────────────────────────────┘ <── DRAM_END
```

Formal Invariant:
$$\forall \mathcal{R}_i, \mathcal{R}_j \in \{\text{IMAGE}, \text{VBAR}, \text{STACK}, \text{STATE}, \text{CAP\_TABLE}, \text{STATIC\_DATA}, \text{FREE\_DRAM}\}: \quad i \neq j \implies \mathcal{R}_i \cap \mathcal{R}_j = \emptyset$$

### 5. Physical Frame Authority
Physics does not implement a general-purpose OS memory allocator (no slabs, heaps, or buddy systems). It implements **Physical Frame Authority**:
- Granularity: strictly 4,096 bytes (4 KiB frames).
- Managed Range: strictly `[FREE_FRAME_BASE, DRAM_END)`.
- Invariant: Zero frames in `[0x00000000, FREE_FRAME_BASE)` can ever be granted or allocated.
- Tracking: Bitmask located in `PHYSICS_STATIC_DATA`.
- Checked Arithmetic: Base, frame index, and boundary math are overflow-checked.
- Exhaustion: Returns typed error `ERR_FRAME_EXHAUSTED` (0); no silent wraparound.

### 6. Kernel-Private Root Capability (`CAP_ROOT`)
- **Semantic Identity**: `CapabilityId { slot: 0, generation: 1 }`. The capability's identity is decoupled from its physical memory address.
- **Scope**: Kernel-private root of the resource authority tree. Not transferable. Delegable only through strict monotonic attenuation.
- **Structure**:
  ```text
  Capability Record (64 bytes):
    +0x00: cap_id (slot: u32, generation: u32)
    +0x08: principal_id (u64 = 0x1, Physics)
    +0x10: resource_type (u32 = RES_UNIVERSAL_ROOT)
    +0x14: allowed_ops (u32 = OP_ALL_AUTHORITY)
    +0x18: bound_base (u64 = FREE_FRAME_BASE)
    +0x20: bound_size (u64 = DRAM_END - FREE_FRAME_BASE)
    +0x28: revocation_state (u32 = STATE_ACTIVE)
    +0x2C: attenuation_depth (u32 = 0)
    +0x30: provenance_digest (32 bytes = atlas.sha256)
  ```
- Memory capabilities created in later milestones derive exclusively from allocator-owned free ranges (`[FREE_FRAME_BASE, DRAM_END)`) and permanently exclude all reserved Physics regions.

---

## Testing Decisions (Dual Verification Seams)

### Seam 1: Independent Artifact-Audit Seam (`seam1_physics_audit.py`)
Evaluates static properties of `physics.bin` without machine execution:
1. `PHYSICS_ARTIFACT_IDENTITY_PASS`: Canonical digest matches `physics.sha256`.
2. `PHYSICS_MACHINE_CONTRACT_PASS`: Code size $\le 32\text{ KiB}$, total image $\le 64\text{ KiB}$.
3. `PHYSICS_AUDIT_PASS`: Generalized byte accounting:
   $$\text{CODE\_BYTES} + \text{RODATA\_BYTES} + \text{CANONICAL\_PADDING\_BYTES} + \text{OTHER\_DECLARED\_BYTES} = \text{EXACT BINARY SIZE}$$
   with exactly 0 unexplained bytes.
4. `PHYSICS_VECTOR_LAYOUT_PASS`:
   - Vector table base is strictly 2 KiB aligned (`base % 2048 == 0`).
   - Table covers exactly `0x000`..`0x7FF` (2,048 bytes).
   - All 16 vector slots exist at required `0x80` offsets without body overlap.
5. `PHYSICS_MEMORY_DISJOINTNESS_PASS`: Static proof that all reserved regions (`IMAGE`, `VBAR`, `STACK`, `STATE`, `CAP_TABLE`, `STATIC_DATA`) are pairwise disjoint with positive gaps.

### Seam 2: External Execution Seam (`seam2_physics_harness.py`)
Evaluates runtime execution in bare-metal QEMU AArch64 booted by `atlas.bin`:
1. `PHYSICS_ENTRY_EL_PASS`: Verifies current EL matches machine contract without implicit switching.
2. `PHYSICS_DESCRIPTOR_INGRESS_PASS`: Validates ingress descriptor checks, copies fields, and vacates Atlas scratchpad.
3. `PHYSICS_BOOT_QEMU_PASS`: Clean end-to-end boot from reset: Atlas verifies Physics $\rightarrow$ Physics initializes VBAR, frame authority, and CAP_ROOT $\rightarrow$ reaches `PHYSICS: QUIESCENT_READY`.
4. `PHYSICS_FRAME_BOUNDS_PASS`: Tests frame allocation within bounds; asserts frames are strictly $\ge \text{FREE\_FRAME\_BASE}$ and $<\text{DRAM\_END}$.
5. `PHYSICS_RESERVED_FRAME_REFUSAL_PASS`: Asserts allocator refuses any attempt to allocate frames in reserved regions.
6. `PHYSICS_CAP_ROOT_PASS`: Validates `CapabilityId { slot: 0, generation: 1 }` in memory with valid provenance hash.
7. `PHYSICS_EXCEPTION_STATE_CAPTURE_PASS`: Deliberate synchronous software exception (e.g. `brk #0` or deliberate unmapped read) vectors to `VBAR_ELx`, captures raw architectural state (`VECTOR_SLOT`, `CURRENT_EL`, `ESR_ELx`, `ELR_ELx`, `SPSR_ELx`, `FAR_ELx` with validity), emits crash telemetry, and halts in fail-closed quiescence.
8. `PHYSICS_CORRUPTION_REFUSAL_PASS`: Hostile ingress corruption matrix (bad cookie, unsupported version, truncated length, DRAM size zero, DRAM base+size overflow, out-of-profile UART) halts safely before frame authority or capabilities are published.

---

## Qualification Gate Suite (Milestone 2)

```text
QUALIFICATION SUITE: MILESTONE 2 (PHYSICS_BOOT)
├── Seam 1: Artifact Audit (Static)
│   ├── [PASS] PHYSICS_ARTIFACT_IDENTITY_PASS
│   ├── [PASS] PHYSICS_MACHINE_CONTRACT_PASS
│   ├── [PASS] PHYSICS_AUDIT_PASS (Generalized byte accounting)
│   ├── [PASS] PHYSICS_VECTOR_LAYOUT_PASS (2048B span, 16 x 0x80 slots)
│   └── [PASS] PHYSICS_MEMORY_DISJOINTNESS_PASS (Pairwise disjoint regions)
│
└── Seam 2: Execution Harness (QEMU Virt)
    ├── [PASS] PHYSICS_ENTRY_EL_PASS (Contract-driven CurrentEL)
    ├── [PASS] PHYSICS_DESCRIPTOR_INGRESS_PASS (Validated ingress copy)
    ├── [PASS] PHYSICS_BOOT_QEMU_PASS (Atlas -> Physics golden boot)
    ├── [PASS] PHYSICS_FRAME_BOUNDS_PASS (Allocation strictly within free bounds)
    ├── [PASS] PHYSICS_RESERVED_FRAME_REFUSAL_PASS (Reserved frames never allocated)
    ├── [PASS] PHYSICS_CAP_ROOT_PASS (Kernel-private CAP_ROOT genesis)
    ├── [PASS] PHYSICS_EXCEPTION_STATE_CAPTURE_PASS (Raw trap state capture)
    └── [PASS] PHYSICS_CORRUPTION_REFUSAL_PASS (Hostile semantic ingress refusals)
```

*Note: Native DGX Spark hardware qualification (`PHYSICS_BOOT_NATIVE_PASS`) remains strictly decoupled from QEMU qualification and will be evaluated on physical silicon.*
