# Specification: Milestone 16 — Blackwell Native Path Known (`BLACKWELL_NATIVE_PATH_KNOWN`)

```text
Document ID:     SPEC-ACCEL-M16
Milestone:       Milestone 16 (BLACKWELL_NATIVE_PATH_KNOWN)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Empirical Characterization of Native Blackwell Submission Architecture
Status:          RATIFIED / COMPLETE
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3/M15) -> OMEGA (M4-M14) -> M15 (Authority) -> M16 (Discovery)
```

---

## 1. Executive Summary & Foundational Boundary

Milestone 15 (`PHYSICS_ACCELERATOR_LINK`) established who may touch the accelerator: the sovereign authority model, capability-gated access, bounded IOVA translation policy, immutable effect receipt chaining, and empirical verification of the DGX Spark physical topology (BDF `000f:01:00.0`, vendor `0x10de`, device `0x2e12`, IOMMU group 20, SMMUv3 base `0x13000000`, Stream ID `0x0100`, BAR0 aperture `0x24000000-0x27ffffff`).

Milestone 16 establishes **how the accelerator is actually commanded**:

> **M15 ESTABLISHES WHO MAY TOUCH THE ACCELERATOR.**
> **M16 DISCOVERS HOW THE ACCELERATOR IS ACTUALLY COMMANDED.**

Milestone 16 is an **empirical research and reverse-engineering milestone**. Its mandate is to discover, characterize, and verify the physical Blackwell GB10 native command submission path on NVIDIA DGX Spark without guessing undocumented registers, without fabricating synthetic completions, and without premature compute synthesis.

Milestone 16 does **NOT** need to generate OMEGA compute; verified compute realization belongs to **Milestone 17 (`OMEGA_BLACKWELL_VECTOR`)**.

---

## 2. Core Responsibilities & Ownership

Milestone 16 explicitly owns the discovery and characterization of:

1. **Device Submission Architecture**:
   - Host-to-device submission mechanics across coherent NVLink-C2C interconnect.
   - Distinction between host pushbuffer memory, user-space channel structures, and device runlists.

2. **Command Buffer Format**:
   - Native Blackwell method header formats, subchannel addressing, opcode structures, and payload layout.

3. **Channel & Queue Structures**:
   - GPFIFO / work queue ring layout, entry sizing, alignment constraints, and wrap-around mechanics.

4. **BAR & Register Discovery**:
   - Characterization of physical BAR0 aperture offsets (`0x24000000 - 0x27ffffff`, 64 MiB).
   - Identification of user-accessible doorbell pages, channel control registers, and status apertures.

5. **Doorbell Mechanism**:
   - Verified physical MMIO doorbell address, write token format, and signaling protocol.

6. **Work Descriptor Format**:
   - Concrete binary encoding of minimum viable compute/copy work descriptors.

7. **Completion & Synchronization Mechanism**:
   - Hardware semaphores, memory-backed fence locations, interrupt reporting, and empirical completion latency.

8. **Fault Reporting**:
   - Hardware MMU fault codes, channel error registers, SMMUv3 event records, and recovery syndromes.

9. **Minimum Safe Compute/Copy Submission**:
   - The smallest verified end-to-end hardware execution transaction producing an observable, non-simulated effect on silicon.

---

## 3. Epistemic Classification Standard

To ensure absolute truthfulness and prevent any confusion between empirical facts and speculative models, **every register, structure, offset, and behavior recorded in Milestone 16 must be tagged with one of five canonical epistemic tags**:

```text
[DOCUMENTED]
    Fact established by public vendor architecture manuals, open-source driver
    headers (e.g. open-gpu-kernel-modules), or official hardware specifications.

[OBSERVED]
    Fact directly read, measured, or captured from the live DGX Spark machine
    (e.g. sysfs PCI resources, IOMMU tables, ACPI IORT tables, kernel logs).

[REVERSE_ENGINEERED]
    Fact deduced by empirical instrumentation, command stream tracing, or
    controlled input/output differential analysis on running silicon.

[INFERRED]
    Hypothesis supported by strong architectural analogy to prior generations
    (e.g. Hopper GH200 / Ada Lovelace) but not yet directly confirmed on GB10.
    CANNOT satisfy a qualification gate until elevated to OBSERVED.

[UNKNOWN]
    Currently undiscovered or unverified mechanism. Explicitly tracked as an
    open research problem; never guessed or faked.
```

---

## 4. Phase Plan: From Topology to Minimum Submission

### Phase 1: Passive Characterization & Discovery
- Inspect kernel GPU driver (`nvidia.ko` / `nvidia-uvm.ko`) channel allocation paths.
- Analyze open-gpu-kernel-modules source for Blackwell GB10 class definitions and method headers.
- Map BAR0 aperture allocations via `/proc/iomem` and kernel debug interfaces.
- Classify all target structures under the Epistemic Classification Standard.

### Phase 2: Channel & Pushbuffer Reverse Engineering
- Observe user-space channel creation (`/dev/nvidia*` ioctl sequence or direct mapping).
- Identify GPFIFO entry formatting and pushbuffer token encodings.
- Trace memory barrier and flush requirements on coherent ARM64 Neoverse V2.

### Phase 3: Doorbell & Completion Validation
- Identify physical doorbell page offset within BAR0.
- Determine token encoding (channel ID + pushbuffer get/put pointer).
- Validate hardware semaphore release or timestamp writeback upon completion.

### Phase 4: Minimum Safe Hardware Transaction
- Construct minimal sovereign pushbuffer descriptor.
- Submit descriptor into hardware channel.
- Independently observe hardware execution without proprietary userspace runtimes.
- Verify completion on physical silicon.

---

## 5. Milestone 16 Exit Criteria

Milestone 16 is complete when:

1. **Submission Path Known**: A complete, documented specification of the native Blackwell submission path exists, with every element tagged as `DOCUMENTED`, `OBSERVED`, or `REVERSE_ENGINEERED`. Zero elements remain `INFERRED` or `UNKNOWN` in the critical submission path.
2. **Doorbell & Queue Verified**: Physical doorbell offset and GPFIFO ring format are independently demonstrated.
3. **Completion Observed**: Hardware completion signaling is independently verified from device-produced memory modification.
4. **Zero Ambient Authority**: All submissions remain strictly mediated through the capability and memory bounds established in Milestone 15.

Milestone 16 provides the empirical foundation upon which **Milestone 17 (`OMEGA_BLACKWELL_VECTOR`)** synthesizes autonomous GPU compute.

---

## 6. Empirical Verification & Qualification

Milestone 16 was qualified on NVIDIA DGX Spark (`spark-b87b`) on 2026-09-26.

- **Authoritative Evidence Collection**: `physics/research/m16/run-20260926-10/`
- **Raw Evidence Digest**: `sha256: 5068e2274fa1dc9401365a2f085bc2187f63230b4909d0ac1bceee804ea230a6`
- **Physics Qualification Receipt**: `evidence/m16-blackwell-native-path-receipt.json` (`physics@f72e297`)
- **Qualification Scope**:
  1. Complete critical path verified with zero `UNKNOWN` or `INFERRED` links (all links `[OBSERVED]` or `[DOCUMENTED]`).
  2. Usermode doorbell aperture identified at BAR0 offset `0xbb0000` (class `0xC661` `HOPPER_USERMODE_A`), with register offset `+0x90` (`NVC361_NOTIFY_CHANNEL_PENDING`).
  3. GPFIFO 8-byte entry structure and `NVC06F` pushbuffer method headers decoded.
  4. Device completion attributed to pushbuffer method `0x5c` (`SEM_ADDR_LO`) writing coherent memory marker with `RELEASE` (`0x1`) flanked by `MEM_OP_D` flushes.
  5. Hardware causality verified via controlled negative perturbation test (`causality_test.c`: withheld doorbell halts execution; released doorbell immediately updates marker).
  6. Minimum sovereign transaction verified directly in pure C (`sovereign_submit.c`) without proprietary userspace runtimes (`libcuda`).

**Milestone 16 is RATIFIED and CLOSED.** Milestone 17 (`OMEGA_BLACKWELL_VECTOR`) is **IN PROGRESS**.

