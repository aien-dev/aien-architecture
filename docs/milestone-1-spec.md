# Specification: Milestone 1 — Atlas Bootstrap Seed (`ATLAS_BOOT`)

> [!NOTE]
> **Lineage & Provenance Note:** *Formerly designated Alpha (`alpha.bin`) during early lineage bootstrap drafting. Every prior architectural responsibility and contract of ALPHA transfers to ATLAS unchanged.*

## Problem Statement

A sovereign computing lineage cannot build itself out of nothing without a trusted initial entry into physical silicon. If the root bootstrap depends on complex foreign compilers, multi-megabyte bootloaders, or implicit firmware assumptions, the lineage inherits unverifiable surface area, potential supply-chain subversion, and ambient execution state. The machine requires an irreducible, deterministic, fully auditable root artifact that establishes trusted execution, validates the initial machine authority payload (`PHYSICS-0`), and relinquishes control without retaining ambient authority or executing again within the same boot epoch.

## Solution

Formalize and qualify `atlas.bin` as the canonical binary root artifact along with its machine contract and comprehensive verification evidence. Atlas performs only what is strictly required for trusted machine awakening: establish execution context, initialize polled diagnostic console output, locate the `PHYSICS-0` image, verify the pinned expected digest of `PHYSICS-0`, establish the minimum contract-required hardware prerequisites, transfer control according to the normative `PHYSICS_ENTRY_ABI` at the contract-defined exception level, and transition to fail-closed quiescence on any fault.

## User Stories

1. As a system architect, I want an irreducible binary root artifact (`atlas.bin`), so that the system root of trust is as small, auditable, and self-contained as physically possible.
2. As a security auditor, I want an independent artifact-audit seam verifying byte decoding, reachability, control flow, branch targets, and bounded memory access, so that every reachable byte of `atlas.bin` is statically accounted for prior to execution.
3. As a verification engineer, I want the bootstrap seed to compare the cryptographic digest of the `PHYSICS-0` payload against a pinned expected digest, so that corrupted, mismatched, or non-canonical PHYSICS-0 images are rejected before control handoff.
4. As a test engineer, I want Atlas to fail closed into a quiescent state when any single byte of `PHYSICS-0` is corrupted, so that the machine refuses execution, produces no unintended external effects, and prevents fallthrough.
5. As a bare-metal developer, I want a normative machine contract defining entry addresses, entry exception level, target Physics exception level, register contracts, and UART MMIO addresses, so that execution behavior does not rely on ambient QEMU or firmware defaults.
6. As a compliance officer, I want canonical byte reproduction and artifact identity verification, so that the exact canonical `atlas.bin` digest can be verified independently across environments without declaring reconstruction tooling as canonical.
7. As an operator, I want polled serial diagnostic telemetry emitted at discrete bootstrap checkpoints, so that early boot failures can be diagnosed without complex kernel debuggers or interrupt plumbing.
8. As a kernel engineer, I want a normative `PHYSICS_ENTRY_ABI` defining which registers contain exact values, passed arguments, or are explicitly `UNSPECIFIED`, so that Physics makes no uncontracted assumptions about machine state.
9. As a systems auditor, I want strict bounds on all scratchpad RAM accessed by Atlas, so that bootstrap operations cannot corrupt designated Physics memory.
10. As a sovereign lineage maintainer, I want Atlas to strictly exclude filesystems, network stacks, general runtimes, optimizers, Omega compilers, and AI models, so that the root artifact remains non-intelligent and auditable.
11. As a validation harness, I want distinct qualification gates for QEMU emulation and native physical hardware (DGX Spark), so that qualification in emulation never falsely implies native hardware correctness.
12. As a systems programmer, I want secondary SMP cores to remain untouched unless they enter Atlas under the machine contract, so that Atlas does not manage multi-core scheduling policy.
13. As an architect, I want Atlas to be non-reentrant within a single boot epoch after successful handoff, so that Atlas cannot be invoked as an ambient supervisor by higher layers.
14. As an infrastructure engineer, I want a clear hardware ownership matrix delineating Atlas bootstrap prerequisites from Physics governance, so that peripheral controllers, SMMUs, and accelerators remain untouched by Atlas.

## Implementation Decisions

### 1. Root Artifact Status & Canonical Byte Reproduction
`atlas.bin` is the canonical root artifact ($A_0$). Assemblers, hex editors, or toolchains used to emit or inspect the artifact are classified as non-canonical supporting evidence. Verification evaluates canonical byte reproduction and artifact identity against the locked canonical digest, rather than relying on a compiler's build reproducibility.

### 2. Normative Machine Contract & Exception Level Handover
Atlas does not hard-code the Physics handoff to EL1. The machine contract explicitly declares:
- Machine entry exception level (e.g. EL2 or EL1).
- Handover target exception level for Physics (determined by contract: EL2 if hypervisor/bare-metal authority, or EL1).
- Memory map: entry address, scratchpad stack address and bound, and Physics payload base address and length bound.
- Console interface: MMIO physical base address, register width, and access stride for polled UART.

### 3. Normative `PHYSICS_ENTRY_ABI`
Registers and processor state at handoff are strictly categorized:
- **Passed Values:** Registers explicitly used to pass boot arguments (e.g., `x0` = pointer to Machine Boot Descriptor, `x1` = payload size, `x2` = magic verification cookie).
- **Exact Values:** Architecture-mandated control registers configured to fixed states (e.g., MMU/D-cache disabled or contract-configured, interrupts masked in `DAIF`).
- **Explicitly `UNSPECIFIED`:** Scratch registers (`x3`–`x18`, NEON/vector state) are declared explicitly `UNSPECIFIED`. Atlas does not waste instructions or code space zeroing state that Physics is normatively forbidden to rely upon.

### 4. Hardware Ownership Boundary
Atlas initializes only what is strictly required to verify Physics and transfer control:

| Domain | Atlas Responsibility | Physics Responsibility |
| :--- | :--- | :--- |
| **CPU Core** | Initialize primary boot core minimal state & stack pointer | Manage core topology, power states, and scheduling |
| **SMP Cores** | ATLAS MUST NOT WAKE SECONDARY CORES. IF A SECONDARY CORE ENTERS ATLAS UNDER THE MACHINE CONTRACT, ATLAS PLACES IT IN A BOUNDED QUIESCENT STATE UNTIL PHYSICS CLAIMS IT. | Wake, configure, and schedule secondary cores |
| **MMU / Page Tables** | Identity-mapped or disabled per contract | Own and configure multi-level page tables & translation |
| **Interrupt Controller (GIC)** | Leave masked / uninitialized | Initialize distributor, redistributors, and ITS |
| **IOMMU / SMMUv3** | DO NOT RECONFIGURE; ENTRY STATE IS CONTRACT-DEFINED | Own stream tables, context descriptors, and translation |
| **Timers** | Leave interrupts masked | Configure system counter, virtual/physical timers |
| **Serial / Console** | Minimal polled TX MMIO output | Full console driver, buffering, and interrupt management |
| **Storage (NVMe / eMMC)** | No ownership; no drivers | Full controller init, command queues, block layer |
| **Network (NIC / MAC)** | DO NOT INITIALIZE OR RECONFIGURE | PHY init, DMA ring buffers, protocol stack |
| **Accelerators (GPU / Blackwell)** | DO NOT INITIALIZE, RESET, POWER-TRANSITION, OR RECONFIGURE | PCIe topology discovery, MMIO dispatch, firmware loading |

### 5. `PHYSICS-0` Integrity Verification
Verification in Milestone 1 is defined as checking the byte-exact integrity of the uncompressed `PHYSICS-0` binary image against a pinned expected cryptographic digest embedded in `atlas.bin`. The mechanism is optimized for minimum trusted implementation surface rather than hashing throughput. Hash matching validates integrity; it is not characterized as public-key signature authentication.

### 6. Fail-Closed Quiescence
Failure is defined semantically: on any contract violation, digest mismatch, or hardware fault, Atlas must ensure:
- Zero control transfer to Physics.
- Zero unintended external side effects.
- Zero unbounded or out-of-scratchpad memory modifications.
- Complete prevention of instruction stream fallthrough.
A quiescent halt loop (e.g., disabling interrupts followed by a low-power wait loop) represents one realization satisfying the contract.

### 7. Lifecycle & Re-entry
Atlas does not execute again after a successful handover within the current boot epoch. Cold reset or power cycle restarts the platform boot chain; when the machine contract selects Atlas as the boot artifact, control may enter Atlas again. Successor bootstrap seeds may be synthesized by Omega in later milestones, but this capability is strictly bounded to post-`OMEGA_SELF_HOST_PASS` and is out of scope for Milestone 1.

## Testing Decisions

Verification is formally separated into two distinct, decoupled seams:

### Seam 1: Independent Artifact-Audit Seam
Operates on the static artifact `atlas.bin` and supporting ledgers without requiring machine execution:
- **Byte Accounting & Reachability:** Every reachable instruction and byte from entry to terminal points must be mapped to an entry in `alpha.decode` and `alpha.audit`.
- **Control-Flow Graph Verification:** All branch targets must resolve within declared executable memory bounds with no indirect jumps to unverified addresses.
- **Memory Access Bounds:** Validates that every read/write operation is statically constrained within the designated scratchpad RAM or payload address windows.
- **Artifact-Ledger Co-evolution:** For each specific `atlas.bin`, its decode ledger, CFG, and audit log must agree. Instruction ordering may evolve across iterations as long as the artifact and ledger update together.

### Seam 2: External Execution Seam
Evaluates runtime behavior under the Machine Contract:
- **Diagnostic Progress:** Validates the emitted polled UART character sequence across bootstrap checkpoints.
- **Handover Verification:** Asserts register state conforms to the normative `PHYSICS_ENTRY_ABI` and execution transfers to the contract-defined Physics entry point and exception level.
- **Corruption Refusal:** Injecting single-byte mutations into the staged `PHYSICS-0` image must trigger immediate refusal and fail-closed quiescence.

### Qualification Gate Hierarchy

Milestone 1 acceptance requires passing all QEMU qualification gates and static audit gates. Native hardware qualification is decoupled and managed under separate gates:

#### Milestone 1 Mandatory Gates
- `ATLAS_ARTIFACT_IDENTITY_PASS`: Canonical digest matches the locked specification hash.
- `ATLAS_AUDIT_PASS`: 100% of reachable bytes accounted for in the static audit ledger with bounded memory accesses and fully resolved branches.
- `ATLAS_MACHINE_CONTRACT_PASS`: Contract specification formally validated against target execution parameters.
- `ATLAS_BOOT_QEMU_PASS`: Emulation harness boots `atlas.bin` and emits expected diagnostic sequence.
- `ATLAS_HANDOFF_QEMU_PASS`: Control transfers successfully to the mock/initial Physics entry point at the contract-defined exception level conforming to `PHYSICS_ENTRY_ABI`.
- `ATLAS_CORRUPTION_REFUSAL_QEMU_PASS`: Single-byte payload corruption reliably results in boot refusal.
- `ATLAS_FAIL_CLOSED_QEMU_PASS`: Refusal executes cleanly into bounded quiescence without fallthrough or external effect.

#### Separate Native Hardware Qualification Gates (DGX Spark)
- `ATLAS_BOOT_NATIVE_PASS`: Physical silicon cold boot and early console telemetry verified.
- `ATLAS_HANDOFF_NATIVE_PASS`: Native hardware control transfer to Physics under physical constraints.
*(A pass under QEMU never implies or substitutes for a native pass).*

## Out of Scope

- Native hardware execution on DGX Spark / physical silicon (covered by the separate native qualification gates).
- Full Physics kernel subsystems (virtual memory management, device driver framework, capability broker).
- Multi-core SMP wake-up or thread scheduling.
- Synthesis of successor bootstrap seeds via Omega (strictly post-`OMEGA_SELF_HOST_PASS`).
- Cryptographic signature authentication or dynamic public-key certificate chaining.
- GPU / Blackwell accelerator discovery and management.

## Further Notes

Atlas is accepted as the sole Founding Exception to the Sovereignty Law: the first executable artifact must exist before the lineage can construct itself. The goal of Atlas is not to eliminate the root of trust, but to make that root as small, auditable, and immutable as physically possible.
