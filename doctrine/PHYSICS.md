# DOCTRINE-002: PHYSICS — The Trusted Machine Authority

```text
Document ID:     DOCTRINE-002
Milestone:       Milestone 0 (DOCTRINE_V1)
Classification:  Sovereign Machine Canonical Doctrine
Target Substrate: Physical Compute Fabric (AArch64 CPU Host, SMMUv3, PCIe Bus, Accelerators)
Status:          AUTHORITATIVE / CANONICAL
```

---

## 1. Executive Summary & The Physical Mandate

**Physics** is the Trusted Machine Authority and the Constitution of the Sovereign Machine.

In the Sovereign Machine hierarchy, intelligence proposes, but Physics disposes. While cognitive layers (Aien, neural models, reasoning graphs) formulate desires, plans, and hypothetical transformations, they possess zero direct access to the physical substrate of reality.

The fundamental, uncompromisable question answered by Physics is:

$$\mathbf{\text{“What is allowed to become physically real?”}}$$

If an operation is not explicitly validated, authorized, and admitted by Physics, that operation cannot act upon physical memory, cannot mutate storage cells, cannot transmit photons or electrons across a network wire, and cannot command an accelerator core. Physics is the sole arbiter of physical existence on the machine.

### 1.1 PHYSICS vs. PHYSICS ZERO: Canonical Distinction
It is an architectural violation to conflate the machine authority with the scientific discovery program:
- **`PHYSICS`**: **The Trusted Machine Authority.** The constitutional governor of silicon, CPU exception levels, memory isolation, SMMUv3 DMA protection, device registers, and the Effect Cycle.
- **`PHYSICS ZERO`**: **The Clean-Room Scientific Discovery Program.** An autonomous epistemological methodology wherein AIEN discovers the underlying structure of reality from raw observation without ever receiving human physical theories, constants, or terminology. See [`DISCOVERY.md`](file:///home/drakestapleton/workspace/aien-architecture/doctrine/DISCOVERY.md).

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        COGNITIVE & REASONING LAYERS                    │
│                 (Aien / Cortex / Agents / Model Inference)             │
│                                                                        │
│       Formulates Desired State, Intent, Candidate Transformations      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                         Requests Physical Effect
                          (EFFECT_INTENT + Token)
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                                PHYSICS                                 │
│                     (The Sovereign Machine Authority)                  │
│                                                                        │
│   "What is allowed to become physically real?"                         │
│                                                                        │
│   ┌───────────────┐     ┌────────────────┐     ┌──────────────────┐    │
│   │ Capability    │ ──> │ Physical State │ ──> │ Bounded Hardware │    │
│   │ Authorization │     │ Invariant Gate │     │ Confinement      │    │
│   └───────────────┘     └────────────────┘     └──────────────────┘    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                               Admitted / Denied
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          PHYSICAL SUBSTRATE                            │
│           (Silicon, Memory Bus, NVMe, SMMUv3, GPU Cores, NIC)          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Scope of Authority

Physics exercises total, unshared jurisdiction over the physical resources of the hardware platform. Its authority encompasses thirteen distinct domains:

```text
               PHYSICS DOMAIN OF AUTHORITY
┌────────────────────────────────────────────────────────────────┐
│ [1]  Physical Memory Allocation, Page Tables & Isolation       │
│ [2]  CPU Privilege Levels (EL2/EL1/EL0) & Context Switching     │
│ [3]  Interrupt Routing, Virtualization & Prioritization        │
│ [4]  Architectural Timers & Preemption Clocks                  │
│ [5]  Synchronous & Asynchronous Fault Confinement               │
│ [6]  Device Ownership & Memory-Mapped I/O (MMIO) Registers     │
│ [7]  Direct Memory Access (DMA) & IOMMU/SMMUv3 Translation     │
│ [8]  Accelerator Lifecycle, Clocking, Queues & Reset           │
│ [9]  Non-Volatile Storage Authority & Atomic Block Dispatch    │
│ [10] Network Interface Transmission & Egress Confinement       │
│ [11] Capability Ledger, Generation Tracking & Revocation       │
│ [12] Effect Admission Pipeline & Receipt Cryptography          │
│ [13] Hardware Root of Trust, Measurement & Safe Recovery       │
└────────────────────────────────────────────────────────────────┘
```

### 2.1 The Thirteen Physical Domains

1. **Memory Ownership**: Physics manages physical frame allocation, page table hierarchies (Stage 1 and Stage 2 translations), page attribute tables (`MAIR_EL1`), and memory type tags. No component may map or access memory without a valid memory capability.
2. **CPU Privilege**: Physics runs at EL1 (or EL2 hypervisor), enforcing complete isolation between supervisor domains and unprivileged EL0 user-space runtimes.
3. **Interrupts**: Physics controls the Generic Interrupt Controller (GICv3/v4). It binds, prioritizes, filters, and delivers physical interrupts. No external process may mask or usurp hardware IRQs.
4. **Timers**: Physics configures physical and virtual timers (`CNTP_CTL_EL0`, `CNTV_CTL_EL0`). It enforces preemptive execution slicing and deadline tracking.
5. **Faults**: Physics traps all processor exceptions (Data Aborts, Instruction Aborts, Alignment Faults, Illegal Instructions). Faults are isolated to the offending domain; uncontained corruption triggers fail-safe quarantine.
6. **Device Ownership**: Peripheral devices (PCIe root complexes, controllers, diagnostic ports) are owned exclusively by Physics. Runtimes interact with devices through capability-mediated proxies.
7. **DMA & IOMMU/SMMU**: Physical peripherals and accelerators are strictly confined behind an IOMMU (ARM SMMUv3). Physics programs Stream Table Entries (STE) and Command Queues (CD). Direct, untranslated physical bus mastering by any peripheral is hardware-prohibited.
8. **Accelerator Lifecycle**: Accelerators (GPUs, NPUs, FPGAs) are managed peripherals. Physics governs power rails, clocks, PCIe link training, queue submission rings, watchdog timers, and hardware resets.
9. **Storage Authority**: Non-volatile storage (NVMe controllers, physical flash blocks) is accessed exclusively via Physics block dispatchers. Physics guarantees atomic multi-block transactions and durability barriers.
10. **Network Authority**: Physical network interfaces (PHY/MAC) and DMA ring buffers are owned by Physics. Network packets may only leave the machine if covered by an active `NETWORK_CAPABILITY`.
11. **Capability Management**: Physics is the sole issuer, validator, and revoker of cryptographic capability tokens.
12. **Effect Admission**: Every effect that transitions from a digital calculation into a physical state change must pass through the Physics admission gate.
13. **Roots of Trust & Recovery**: Physics holds the platform cryptographic identity, measures software components against hardware platform PCRs/TPM, and manages the deterministic reset/recovery state machine.

---

## 3. What Physics Does NOT Own (The Non-Cognitive Boundary)

The integrity of Physics depends on strict minimalism regarding higher-level semantics. Physics must never be contaminated with cognitive or heuristic responsibilities.

```text
               THE NON-COGNITIVE BOUNDARY
┌────────────────────────────────────────────────────────────────┐
│ STRICTLY EXCLUDED FROM PHYSICS:                                │
│                                                                │
│  [✗] Goals: Physics does not decide what the machine strives   │
│      for or prioritize human objectives.                       │
│  [✗] Planning: Physics does not create strategies, dependency  │
│      graphs, or task decomposition pipelines.                  │
│  [✗] Reasoning: Physics does not execute logic proofs, J-Space │
│      traversals, or philosophical alignment checks.            │
│  [✗] Model Inference: Physics does not load model weights,     │
│      perform matrix multiplications, or sample logits.         │
│  [✗] Semantic Interpretation: Physics does not parse human     │
│      language, summarize text, or evaluate conversation tone.  │
│  [✗] Self-Improvement: Physics does not rewrite its own rules, │
│      optimize its core laws, or mutate its own constitution.   │
│  [✗] Knowledge: Physics does not host the long-term semantic   │
│      memory graph (Cortex). It holds only physical state.      │
└────────────────────────────────────────────────────────────────┘
```

Physics treats all cognitive workloads as untrusted or semi-trusted data transforms executing in bounded sandboxes. Whether an LLM generates brilliant literature or complete gibberish is irrelevant to Physics; Physics cares only whether the compute, memory, and I/O adhere to the granted capability envelope.

---

## 4. The Boundary Test

Whenever an architectural feature or engineering proposal is evaluated, architects must apply the canonical **Boundary Test**:

$$\mathbf{\text{“Does this feature require direct authority over physical resources?”}}$$

```text
                       PROPOSED FEATURE
                              │
                              ▼
           ┌─────────────────────────────────────┐
           │ Does this feature require direct    │
           │ authority over physical resources?  │
           └──────────────────┬──────────────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
             [YES]                         [NO]
               │                             │
               ▼                             ▼
    Belongs within PHYSICS        Belongs in Higher Layers:
    (Memory, CPU privilege,      • Layer 2: Physical Fabric
     SMMU, IRQ, Device MMIO,     • Layer 3: Transformation IR
     Clock/Reset, Capabilities)  • Layer 4: AEGIS / Policy
                                 • Layer 5: Intelligence / Model
                                 • Layer 6: Desired State / Schema
                                 • Layer 7: Human Intent
```

### 4.1 Boundary Decision Matrix

| Architectural Feature | Physical Authority Required? | Architectural Home | Rationale |
| :--- | :--- | :--- | :--- |
| **Page Table Modification** | **YES** | **PHYSICS** | Mutates CPU MMU translation tables directly. |
| **KV Cache Eviction Policy** | **NO** | Layer 5 (Runtime) | Algorithmic heuristic deciding which tokens to discard; Physics provides the bounded memory pool. |
| **GPU Hardware Reset** | **YES** | **PHYSICS** | Direct PCIe Secondary Bus Reset / MMIO power cycling. |
| **Prompt Routing / Skill Selection**| **NO** | Layer 5 (Agent/Skill) | Semantic decision based on intent and task definition. |
| **NVMe Doorbell Ring Write** | **YES** | **PHYSICS** | Initiates physical controller DMA read/write. |
| **Cortex Semantic Document Indexing**| **NO** | Layer 5/6 (Cortex) | Data organization and vector similarity search. |
| **SMMUv3 Stream Table Configuration**| **YES** | **PHYSICS** | Hardware I/O virtualization and DMA confinement. |
| **Transformation IR Optimization** | **NO** | Layer 3 (Compiler) | Pure symbolic program transformation. |
| **Diagnostic UART Polled Output** | **YES** | **PHYSICS** | Direct physical I/O register write. |
| **Safety Policy Validation** | **NO** | Layer 4 (AEGIS) | Policy verification that formulates the `EFFECT_INTENT`. |

---

## 5. Capability Architecture: No Ambient Authority

Physics enforces a strict **Zero Ambient Authority** model.
No process, subsystem, or processor core possesses rights simply by virtue of who it is, where it was spawned, or what privilege level it previously occupied. Every physical action requires an unforgeable, explicitly presented, bounded **Capability**.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CANONICAL CAPABILITY RECORD                     │
├───────────────────┬────────────────────────────────────────────────────┤
│ Field             │ Description                                        │
├───────────────────┼────────────────────────────────────────────────────┤
│ `principal_id`    │ Cryptographic identity of the holding entity       │
│ `resource_id`     │ Concrete physical/logical asset identifier         │
│ `allowed_ops`     │ Bitmask of authorized operations                   │
│ `bounds`          │ Strict spatial, temporal, and rate constraints    │
│ `generation`      │ Monotonically increasing epoch counter             │
│ `lifetime`        │ Expiration deadline (timestamp / cycle / single-use)│
│ `revocation_state`│ `ACTIVE`, `SUSPENDED`, or `REVOKED`                │
│ `provenance`      │ SHA-256 chain of parent capability derivations     │
└───────────────────┴────────────────────────────────────────────────────┘
```

### 5.1 The Eleven Capability Classes

```text
┌───────────────────────────┬────────────────────────────────────────────┐
│ Capability Class          │ Authority Granted                          │
├───────────────────────────┼────────────────────────────────────────────┤
│ `MEMORY_CAPABILITY`       │ Read/write/execute specific physical frames│
│ `EXECUTION_CAPABILITY`    │ CPU core time slice, priority, affinity   │
│ `MEASUREMENT_CAPABILITY`  │ Hardware counters, telemetry, energy read  │
│ `STORAGE_CAPABILITY`      │ Read/write bounded LBA range on block store│
│ `NETWORK_CAPABILITY`      │ Transmit/receive on bounded network port/IP│
│ `DEVICE_CAPABILITY`       │ Access bounded MMIO peripheral register bar│
│ `GPU_QUEUE_CAPABILITY`    │ Submit command buffers to accelerator ring │
│ `DMA_CAPABILITY`          │ Bind memory to SMMUv3 stream table entry   │
│ `INTERRUPT_CAPABILITY`    │ Bind and handle specific hardware IRQ line │
│ `EFFECT_CAPABILITY`       │ Request external physical mutation         │
│ `VERIFICATION_CAPABILITY` │ Sign, attest, or inspect Root of Trust     │
└───────────────────────────┴────────────────────────────────────────────┘
```

### 5.2 Capability Invariants
1. **Unforgeability**: Capabilities are stored in a dedicated, kernel-protected memory structure inaccessible to unprivileged code, or authenticated via hardware-rooted HMAC/signatures.
2. **Monotonic Narrowing**: A capability may be derived (split or reduced in scope) by its holder, but child capabilities can **never** exceed the rights, bounds, or lifetime of their parent.
3. **Instantaneous Revocation**: When Physics increments the generation counter or marks a capability record as `REVOKED`, all subsequent attempts to exercise that token fail immediately.
4. **Temporal Expiration**: Capabilities default to bounded lifetimes. Persistent ambient access does not exist.

---

## 6. The Effect Cycle

Every interaction that attempts to manifest a change in the physical world must traverse the formal, deterministic **Effect Cycle**. A change that bypasses this cycle is physically impossible under Physics.

```text
 ┌─────────────────┐
 │  EFFECT_INTENT  │  (Declared by Principal: Desired physical mutation)
 └────────┬────────┘
          │
          ▼
 ┌─────────────────┐
 │   Authenticate  │  (Verify cryptographic identity of caller)
 └────────┬────────┘
          │
          ▼
 ┌─────────────────┐
 │ Capability Check│  (Check valid, unrevoked, unexpired capability)
 └────────┬────────┘
          │
          ▼
 ┌─────────────────┐
 │     Verify      │  (Validate physical invariants, constraints, safety bounds)
 └────────┬────────┘
          │
     ┌────┴────┐
     ▼         ▼
  [DENY]    [ADMIT]
     │         │
     │         ▼
     │  ┌──────────────────┐
     │  │ Bounded Execution│  (Execute under strict SMMU / timer confinement)
     │  └────────┬─────────┘
     │           │
     │           ▼
     │  ┌──────────────────┐
     │  │     Measure      │  (Sample physical sensors, telemetry, state diff)
     │  └────────┬─────────┘
     │           │
     ▼           ▼
 ┌─────────────────────────┐
 │      EFFECT_RECEIPT     │  (Cryptographically signed proof of execution/rejection)
 └─────────────────────────┘
```

### 6.1 Effect Cycle Stages

1. **`EFFECT_INTENT`**: The principal formulates a structured request declaring the target resource, requested action, arguments, and required bounds.
2. **Authenticate**: Physics verifies the principal's cryptographic signature and validates its identity against the active domain ledger.
3. **Capability Check**: Physics validates that the principal currently holds an unrevoked capability matching the requested resource, operation, and bounds.
4. **Verify**: Physics performs formal invariant checking. Are physical resources available? Does the effect violate machine thermal or memory constraints?
5. **Admit / Deny**:
   - If validation fails, Physics issues a `DENY` receipt with an explicit rejection code and logs the anomaly.
   - If validation succeeds, Physics admits the operation, arming hardware watchdogs and SMMU isolation windows.
6. **Bounded Execution**: The operation executes on the physical hardware within strictly bounded limits (time slice, memory limits, bandwidth throttle).
7. **Measure**: Physics measures the physical outcome—registers modified, bytes transferred, energy consumed, and hardware telemetry.
8. **`EFFECT_RECEIPT`**: Physics generates an immutable, cryptographically signed `EFFECT_RECEIPT` recording the exact inputs, outcome, duration, and resulting state digest. This receipt is delivered back to the caller and committed to the machine audit ledger.

---

## 7. CPU Governance vs GPU Cognition

Modern sovereign computing is defined by an asymmetry of trust between the CPU and the accelerator fabric (GPU/NPU). Physics formalizes this relationship:

$$\mathbf{\text{CPU}} \equiv \text{Trusted Physical Governor} \quad \longleftrightarrow \quad \mathbf{\text{GPU}} \equiv \text{Semi-Trusted Cognitive Accelerator}$$

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CPU: TRUSTED GOVERNOR                           │
│                                                                        │
│   • Executes Physics Kernel at EL1/EL2                                 │
│   • Controls Platform MMU, SMMUv3, PCIe Root Complex                  │
│   • Controls Power Rails, Clocks, PCIe Reset Lines                     │
│   • Dispatches, Monitors, and Enforces Watchdogs                       │
│                                                                        │
│          │ Watchdog Heartbeat         ▲ GPU Failure / Hang             │
│          │ Submission Doorbell        │ Interrupt (AER / Fence)        │
│          ▼                            │                                │
├────────────────────────────────────────────────────────────────────────┤
│                       GPU: COGNITIVE ACCELERATOR                       │
│                                                                        │
│   • High-throughput matrix math, tensor cores, KV cache                │
│   • Semi-trusted execution context (runs complex generated kernels)    │
│   • Completely confined behind SMMUv3 (Zero Direct Physical Memory)    │
│   • Subject to immediate preemption, queue purge, and hardware reset   │
└────────────────────────────────────────────────────────────────────────┘
```

### 7.1 Principles of Accelerator Confinement

1. **No Ambient Host Memory Access**: The GPU has zero direct access to host physical memory. All memory accessible to the GPU must be explicitly mapped through the ARM SMMUv3 using a valid `DMA_CAPABILITY`. Any unmapped GPU read or write triggers an SMMU Translation Fault, interrupting the CPU.
2. **Command Buffer Isolation**: The cognitive runtime cannot write directly to physical GPU control registers. It writes command buffers into bounded memory. Physics validates the submission against a `GPU_QUEUE_CAPABILITY` before ringing the hardware doorbell.
3. **Watchdog Heartbeat**: Every dispatched GPU queue is bound to a strict hardware timer. If the GPU fails to signal a completion fence within the allotted microsecond budget, Physics declares a **GPU Hang Event**.
4. **Instantaneous Capability Revocation**: Upon detection of a hang, invalid memory access, or PCIe Advanced Error Reporting (AER) anomaly, Physics immediately revokes all active capabilities associated with the offending GPU queue.
5. **Physical GPU Reset**:
   - Physics asserts PCIe Function Level Reset (FLR) or initiates a Secondary Bus Reset (SBR) over the PCIe root complex.
   - Power rails and clocks are cycled to purge all internal GPU SRAM and register state.
6. **Queue Recovery & Scrubbing**:
   - In-flight host buffers are unmapped from the SMMUv3 and zero-scrubbed.
   - The GPU firmware is re-verified against its canonical measurement hash.
   - The healthy CPU state resumes or migrates pending tasks, guaranteeing that a crashed or rogue GPU kernel can never bring down the Sovereign Machine.

---

## 8. Failure and Catastrophic Recovery

Physics is built under the assumption that hardware components fail, memory cells decay, and untrusted software attempts violations.

### 8.1 The Invariant Recovery Hierarchy
1. **Domain Isolation**: When an unprivileged domain or user-space runtime violates a capability or triggers an exception, Physics isolates the domain, revokes its tokens, and reclaims its memory frames without impacting unrelated domains.
2. **Thermal & Electrical Throttle**: If hardware temperature or voltage exceeds safe operational bounds, Physics overrides all performance profiles, throttling clocks or dropping accelerator power stages to preserve silicon integrity.
3. **Cryptographic Panic & Seal**: If physical tampering, unauthorized hardware bus snooping, or uncorrectable memory corruption (ECC multi-bit fault) is detected, Physics:
   - Zeroizes all cryptographic keys and active capability tables.
   - Emits a high-priority diagnostic beacon on the polled UART console.
   - Transitions into a fail-closed terminal state (`halt_error`), refusing all further instruction execution.

---

## 9. Canonical Invariant Checklist

Before declaring Milestone 0 complete for Physics, the following invariants must be verified:

- [ ] Zero ambient authority is enforced; every physical action requires an explicit capability.
- [ ] No higher-level semantic reasoning, model weights, or planning algorithms exist inside Physics.
- [ ] All DMA transactions from peripherals/accelerators are strictly confined behind ARM SMMUv3.
- [ ] Every physical state mutation completes the formal 8-stage Effect Cycle.
- [ ] GPU queues are governed by hardware watchdogs with automated FLR/SBR reset triggers.
- [ ] Capabilities support instantaneous generation-based revocation.
- [ ] Complete isolation between CPU supervisor mode (EL1) and unprivileged execution (EL0).
- [ ] Failure paths are fail-closed: anomalous states freeze physical mutation and record evidence.
