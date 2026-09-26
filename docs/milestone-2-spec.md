# Specification: Milestone 2 — Physics Authority Nucleus (`PHYSICS_BOOT`)

## Problem Statement

When `ATLAS` completes the machine awakening and verifies the integrity of the secondary payload, the system requires an authoritative entity to govern the physical substrate. In conventional operating systems, this layer is burdened with monolithic complexity: multi-gigabyte kernel images, thousands of device drivers, complex POSIX abstractions, preemptive task schedulers, dynamic loadable modules, and sprawling memory management subsystems. This legacy surface area introduces ambient authority, non-deterministic latency, opaque failure states, and unverifiable execution paths.

A sovereign computational architecture demands the opposite: **Physics must be a minimal, immutable, auditable authority nucleus, NOT a conventional operating system kernel.** It must answer a single constitutional question: *"What is allowed to become physically real?"* 

Milestone 2 must establish the foundational Physics nucleus (`physics.bin`) without premature bloat: establishing architectural exception handling, validating inbound machine descriptors from Atlas, carving physical memory into bounded capability-governed frames, providing minimal polled diagnostic console output, and synthesizing the root capability record that terminates ambient authority.

---

## Solution

Implement and formally qualify the Physics Authority Nucleus (`physics.bin`) as the trusted physical machine authority of the Sovereign Machine. 

Physics enters under the normative `PHYSICS_ENTRY_ABI` established by Atlas, validates the Machine Boot Descriptor, installs its own deterministic Exception Vector Table (`VBAR_EL1` / `VBAR_EL2`), initializes a bounded physical memory frame allocator over available system DRAM, claims ownership of the polled serial console, synthesizes the root capability record (`CAP_ROOT`), and establishes the initial zero-ambient-authority regime before awaiting higher-order Omega realization intents.

---

## User Stories

1. **As a system architect**, I want Physics to remain a minimal authority nucleus ($\le 32\text{ KiB}$ text) rather than a full OS kernel, so that the trusted machine authority remains auditable, mathematically verifiable, and bounded.
2. **As a security auditor**, I want Physics to strictly validate the inbound Machine Boot Descriptor, verification cookie (`0x5048595349435330`), and memory bounds passed by Atlas in registers `x0`–`x2`, so that Physics never executes on unverified or corrupted platform parameters.
3. **As a bare-metal engineer**, I want Physics to install a complete, 16-entry AArch64 Exception Vector Table at `VBAR_EL1` (or `VBAR_EL2` per contract), so that all synchronous exceptions, IRQs, FIQs, and SErrors are deterministically confined rather than branching into undefined space.
4. **As a verification engineer**, I want synchronous data and instruction aborts to be trapped and reported with syndrome information (`ESR_EL1`, `FAR_EL1`, `ELR_EL1`) before entering fail-closed quiescence, so that hardware memory violations can be diagnosed deterministically.
5. **As a systems programmer**, I want a bounded physical memory frame allocator managing system DRAM beyond the Atlas scratchpad and Physics text, so that memory can only be granted via explicit, bounded physical capabilities.
6. **As a platform engineer**, I want Physics to adopt the polled UART MMIO base from the boot descriptor and establish diagnostic telemetry (`PHYSICS: AWAKEN`, `PHYSICS: VBAR_SET`, `PHYSICS: MMU_BOUND`, `PHYSICS: CAP_GENESIS`), so that early kernel initialization is transparent without interrupt dependencies.
7. **As a capability architect**, I want Physics to synthesize the initial Root Capability Record (`CAP_ROOT`) with Generation 1, so that all subsequent resource grants (memory, execution, devices) derive strictly from a monotonically narrowable root token.
8. **As a test engineer**, I want intentional exception trigger tests (e.g., executing a software breakpoint or an unmapped memory access in a test harness) to verify that the vector table captures faults cleanly into diagnostic confinement.
9. **As a compliance officer**, I want distinct qualification gates for QEMU emulation (`PHYSICS_BOOT_QEMU_PASS`) and physical DGX Spark hardware (`PHYSICS_BOOT_NATIVE_PASS`), so that qualification in virtual environments never implies physical hardware correctness.
10. **As an infrastructure auditor**, I want an independent artifact-audit seam verifying byte decoding, memory bounding, and zero-discrepancy mathematical word accounting on `physics.bin`, mirroring the rigor of Milestone 1.
11. **As a sovereign lineage maintainer**, I want Physics to strictly exclude higher-level cognitive structures (model inference, tokenizers, KV cache management, J-Space graphs, planning engines, and neural weights), preserving the inviolable Non-Cognitive Boundary.
12. **As an operations engineer**, I want secondary SMP cores entering Physics to remain in bounded low-power quiescence (`wfe`) until explicitly assigned execution capabilities, preventing uncoordinated multi-core races.

---

## Implementation Decisions

### 1. The Anti-Bloat Law (Authority Nucleus vs OS Kernel)
Physics is strictly bounded to physical authority mechanisms:
- **Included:** Vector table (`VBAR`), physical frame tracking, capability record synthesis, polled console handoff, CPU fault confinement, and memory boundary enforcement.
- **Strictly Excluded:** POSIX syscalls, fork/exec, preemptive multi-threading, dynamic linkers, VFS/filesystems, socket networking, graphics drivers, model runtimes, and user shells.

```text
       PHYSICS SCOPE BOUNDARY (MILESTONE 2)
┌──────────────────────────────────────────────────┐
│ INCLUDED (Minimal Authority Nucleus):            │
│  • Entry ABI validation (Cookie, Descriptor, SP) │
│  • 16-entry AArch64 Exception Vector Table (VBAR)│
│  • Bounded DRAM frame bitmap / allocation bounds │
│  • Polled UART console claim & telemetry         │
│  • Root Capability Record (CAP_ROOT) synthesis   │
│  • Fail-closed fault confinement & ESR decode    │
├──────────────────────────────────────────────────┤
│ EXCLUDED (Out of Scope for Milestone 2):         │
│  [✗] Multi-level Stage-1 page tables (M3)        │
│  [✗] SMMUv3 Stream Table Entries (M4)            │
│  [✗] NVMe command queues & block store (M5)      │
│  [✗] GICv3 interrupt distributor routing (M7)    │
│  [✗] GPU PCIe link training & queues (M8)        │
│  [✗] Cognitive models, agents, or J-Space        │
└──────────────────────────────────────────────────┘
```

### 2. Normative Inbound ABI Contract (`PHYSICS_ENTRY_ABI`)
Physics assumes control directly from Atlas conforming to the ratified contract:
- **`x0`**: Pointer to the 64-byte Machine Boot Descriptor at `0x401FE000`.
- **`x1`**: Physics payload size in bytes (`0x100` = 256 bytes for initial stub, extending up to 32 KiB for the full nucleus).
- **`x2`**: Magic verification cookie `0x5048595349435330` (ASCII `'PHYSICS0'`).
- **`DAIF`**: `0x3c0` (all interrupts masked: Debug, SError, IRQ, FIQ).
- **`SP`**: Initial scratchpad stack pointer (`0x401FC000`), strictly disjoint from the descriptor.
- **`PC`**: Entry at `0x40200000`.

Upon entry, Physics validates:
1. `x2 == 0x5048595349435330` (magic cookie check; halts if invalid).
2. `x0 == 0x401FE000` (descriptor address check).
3. Reads descriptor contents: RAM Base (`0x40000000`), RAM Size (`128 MiB`), UART MMIO (`0x09000000`).
4. Re-initializes stack pointer to a dedicated Physics Kernel Stack (`0x40208000`, growing down toward `0x40204000`), completely vacating the Atlas scratchpad.

### 3. Exception Vector Architecture (`VBAR_EL1` / `VBAR_EL2`)
Physics programs the Vector Base Address Register (`VBAR_EL1` or `VBAR_EL2` depending on entry exception level) pointing to a 2,048-byte aligned, 16-entry vector table:

```text
VBAR Base + 0x000: Current EL with SP0  (Synchronous)
VBAR Base + 0x080: Current EL with SP0  (IRQ/vIRQ)
VBAR Base + 0x100: Current EL with SP0  (FIQ/vFIQ)
VBAR Base + 0x180: Current EL with SP0  (SError/vSError)

VBAR Base + 0x200: Current EL with SPx  (Synchronous -> Main Kernel Fault Handler)
VBAR Base + 0x280: Current EL with SPx  (IRQ -> Spurious / Masked Handler)
VBAR Base + 0x300: Current EL with SPx  (FIQ -> Emergency Quiescent Trap)
VBAR Base + 0x380: Current EL with SPx  (SError -> Fatal Hardware Trap)

VBAR Base + 0x400: Lower EL using AArch64 (Synchronous -> Capability Trap / Syscall Gate)
VBAR Base + 0x480: Lower EL using AArch64 (IRQ)
VBAR Base + 0x500: Lower EL using AArch64 (FIQ)
VBAR Base + 0x580: Lower EL using AArch64 (SError)

VBAR Base + 0x600: Lower EL using AArch32 (Unimplemented -> Fatal Reject Trap)
VBAR Base + 0x680: Lower EL using AArch32 (Unimplemented -> Fatal Reject Trap)
VBAR Base + 0x700: Lower EL using AArch32 (Unimplemented -> Fatal Reject Trap)
VBAR Base + 0x780: Lower EL using AArch32 (Unimplemented -> Fatal Reject Trap)
```

Each vector handler preserves `x0`–`x30`, extracts `ESR_EL1` (Exception Syndrome Register), `FAR_EL1` (Fault Address Register), and `ELR_EL1` (Exception Link Register), formats a diagnostic crash beacon over polled UART, and transitions the core to fail-closed quiescence.

### 4. Bounded Physical Memory Frame Allocator
Physics establishes a deterministic physical memory map from the Machine Boot Descriptor:
- **Kernel Image Window:** `[0x40200000, 0x40208000)` (32 KiB reserved).
- **Physical Free DRAM Window:** `[0x40208000, 0x48000000)` (~125.9 MiB).
- **Page Size:** Standard 4 KiB granular frames.
- **Allocator Design:** Bounded static frame allocator. A compact bitmap or frame table placed at the base of free DRAM (`0x40208000`) tracks frame allocation state. Memory is never allocated dynamically without binding to an issued `MEMORY_CAPABILITY`.

### 5. Polled Console Governance & Telemetry
Physics takes ownership of the UART transmitter configured by Atlas:
- Confirms UART MMIO base `0x09000000`.
- Implements polled output routine (`poll_tx_char`) using `FR.TXFF` status check.
- Emits standardized milestone telemetry:
  ```text
  PHYSICS: AWAKEN
  PHYSICS: DESCRIPTOR_VALID
  PHYSICS: VBAR_INSTALLED
  PHYSICS: MEMORY_BOUND [128 MiB]
  PHYSICS: ROOT_CAP_GENESIS
  PHYSICS: QUIESCENT_READY
  ```

### 6. Root Capability Record (`CAP_ROOT`)
To instantiate the Zero Ambient Authority doctrine, Physics synthesizes the genesis capability at physical address `0x40209000`:
- **Principal:** `0x0000000000000001` (Physics Authority Nucleus).
- **Resource ID:** `0xFFFFFFFFFFFFFFFF` (All Physical Resources).
- **Allowed Operations:** `0xFFFFFFFF` (Full Sovereign Authority).
- **Memory Bounds:** Base `0x40000000`, Size `128 MiB`.
- **Generation:** `1` (Epoch Genesis).
- **Lifetime:** `INFINITE_BOOT_EPOCH` (Valid until hard reset).
- **Revocation State:** `ACTIVE`.
- **Provenance Hash:** SHA-256 digest of `atlas.sha256` (chain of trust anchored in Atlas).

---

## Hardware Ownership Boundary (Milestone 2)

| Subsystem | Atlas (M1) State | Physics Nucleus (M2) Action | Subsequent Milestones |
| :--- | :--- | :--- | :--- |
| **Boot Core** | Awoken, verified payload, handed off | Owns core; installs `VBAR`; manages stack | Core power management & scheduling (M10) |
| **Secondary Cores** | Quiescent / Parked | Preserves quiescent state (`wfe`); no spurious wakeups | SMP bring-up & affinity routing (M10) |
| **Exception Vectors** | Default / Stubs | Installs 16-entry `VBAR_EL1` table | Virtualization exception traps (M7) |
| **Memory Translation** | Disabled / Identity | Bounded physical frames initialized; page table prep | Stage-1 MMU translation tables (M3) |
| **IOMMU / SMMUv3** | Untouched | DO NOT RECONFIGURE; Preserve entry state | SMMUv3 STE & CD programming (M4) |
| **Interrupts (GIC)** | Masked in `DAIF` | Remains masked in `DAIF`; vector handlers armed | GICv3 distributor initialization (M7) |
| **Console / UART** | Polled TX MMIO | Polled TX MMIO owned by Physics | Ring-buffered interrupt-driven console |
| **Accelerators (GPU)** | Untouched | DO NOT INITIALIZE, RESET, OR CONFIGURE | PCIe enumeration, reset rails, doorbell queues (M8) |

---

## Testing Decisions (Dual Verification Seams)

Verification for Milestone 2 follows the exact same dual-seam methodology proven in Milestone 1:

### Seam 1: Independent Artifact-Audit Seam (`seam1_physics_audit.py`)
Evaluates static properties of `physics.bin` without machine execution:
1. **`PHYSICS_ARTIFACT_IDENTITY_PASS`**: Canonical digest of `physics.bin` matches `physics.sha256`.
2. **`PHYSICS_AUDIT_PASS`**: 100% word-reconciled machine instruction accounting:
   $$(\text{Instructions} \times 4) + (\text{Data Words} \times 4) = \text{Binary Size}$$
   with exactly 0-byte discrepancy.
3. **`PHYSICS_MACHINE_CONTRACT_PASS`**: Conforms to maximum size bound ($\le 32\text{ KiB}$) and entry ABI literal definitions.
4. **`PHYSICS_VECTOR_ALIGNMENT_PASS`**: Vector base address is verified to be 2,048-byte aligned ($0x800$ alignment), with each of the 16 entries spaced by exactly 128 bytes ($0x80$ stride).
5. **`PHYSICS_STATIC_MEMORY_BOUNDS_PASS`**: All memory dereferences are statically bounded within the kernel image or descriptor address ranges.

### Seam 2: External Execution Seam (`seam2_physics_harness.py`)
Evaluates runtime execution in bare-metal QEMU AArch64 booted by `atlas.bin`:
1. **`PHYSICS_BOOT_QEMU_PASS`**: Full lineage boot from reset: `atlas.bin` awakens, verifies `physics.bin`, and hands off cleanly. Physics emits the complete diagnostic telemetry sequence.
2. **`PHYSICS_DESCRIPTOR_VALIDATION_PASS`**: Physics correctly reads and validates the Machine Boot Descriptor populated by Atlas.
3. **`PHYSICS_EXCEPTION_CONFINEMENT_PASS`**: A test kernel deliberately executes an unmapped read or software breakpoint; Physics vectors to `VBAR_EL1`, traps the fault, emits `ESR_EL1`/`FAR_EL1` telemetry, and halts in fail-closed quiescence without host crash or unbounded loops.
4. **`PHYSICS_ROOT_CAP_PASS`**: Physics synthesizes `CAP_ROOT` in memory with valid generation, provenance, and bounds.
5. **`PHYSICS_CORRUPTION_REFUSAL_PASS`**: Corrupting descriptor values (e.g. invalid RAM size, invalid UART base) causes Physics to refuse execution and halt safely.

### Qualification Gate Hierarchy

```text
QUALIFICATION SUITE: MILESTONE 2 (PHYSICS_BOOT)
├── Seam 1: Artifact Audit (Static)
│   ├── [PASS] PHYSICS_ARTIFACT_IDENTITY_PASS
│   ├── [PASS] PHYSICS_MACHINE_CONTRACT_PASS
│   ├── [PASS] PHYSICS_AUDIT_PASS (Zero-delta word accounting)
│   ├── [PASS] PHYSICS_VECTOR_ALIGNMENT_PASS (2048-byte alignment)
│   └── [PASS] PHYSICS_STATIC_MEMORY_BOUNDS_PASS
│
└── Seam 2: Execution Harness (QEMU Virt)
    ├── [PASS] PHYSICS_BOOT_QEMU_PASS (Atlas -> Physics golden boot)
    ├── [PASS] PHYSICS_DESCRIPTOR_VALIDATION_PASS
    ├── [PASS] PHYSICS_EXCEPTION_CONFINEMENT_PASS (Fault trap verification)
    ├── [PASS] PHYSICS_ROOT_CAP_PASS (Genesis capability record)
    └── [PASS] PHYSICS_CORRUPTION_REFUSAL_PASS
```

*Note: Native DGX Spark hardware qualification (`PHYSICS_BOOT_NATIVE_PASS`) remains strictly decoupled from QEMU qualification and will be evaluated on physical silicon.*

---

## Deliverables & Acceptance Criteria

1. **Repository Structure**:
   - Implementation repository: [`aien-dev/physics`](https://github.com/aien-dev/physics)
   - Canonical artifacts:
     - `physics.bin` (Canonical root binary)
     - `physics.manifest` (Metadata & ABI record)
     - `physics.sha256` (Cryptographic digest)
     - `physics.audit` (100% word-reconciled instruction ledger)
     - `physics.decode` (Annotated disassembly)
     - `physics.memory-map` (Normative layout & frame bounds)
     - `physics.control-flow` (Vector table & CFG)
2. **Verification Tooling**:
   - `seam1_physics_audit.py` (Static audit validator)
   - `seam2_physics_harness.py` (Dynamic QEMU execution test harness)
   - `run_milestone2_gates.py` (Master qualification runner generating `qualification_receipt.json`)
3. **Acceptance Invariant**:
   - Every gate in the Qualification Suite passes 100%.
   - End-to-end boot from cold reset: `atlas.bin` $\rightarrow$ `physics.bin` verified and authorized without manual intervention.
