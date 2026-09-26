# Specification: Milestone 3 — Physics Effects & Capability Authority (`PHYSICS_EFFECTS`)

```text
Document ID:     SPEC-PHYSICS-M3
Milestone:       Milestone 3 (PHYSICS_EFFECTS)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Physical Compute Fabric (AArch64 CPU Host, PL011 UART, Physical DRAM Frames)
Status:          SPECIFIED / IN PROGRESS (aien-dev/aien-architecture#11)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4+) -> AIEN
```

---

## 1. Executive Summary & Foundational Invariant

Milestone 2 established the **Physics Authority Nucleus** (`PHYSICS_BOOT`): validating ingress parameters from Atlas, adopting current-EL exception vectors, binding physical frame authority, establishing polled diagnostic console telemetry, and synthesizing the genesis root capability record.

Milestone 3 establishes the **Physics Effects Engine** (`PHYSICS_EFFECTS`): the capability ledger, monotonic attenuation engine, deterministic effect broker, and cryptographic execution receipts.

The supreme constitutional invariant enforced by Milestone 3 is:

> **NO PHYSICAL EFFECT OCCURS WITHOUT VALID AUTHORITY, AND EVERY EFFECT ATTEMPT PRODUCES VERIFIABLE EVIDENCE.**

PHYSICS is the sole physical authority of the Sovereign Machine.
No caller—including future OMEGA synthesis runtimes or AIEN cognitive agents—gains authority merely by knowing a physical memory address, an operation opcode, or a capability data structure layout. All authority derives strictly from validated, kernel-private capabilities, and every attempted transition into physical reality is mediated, authorized, executed, and receipted by Physics.

---

## 2. Strict Anti-Scope (The Anti-Bloat Law)

Milestone 3 is an authority and effect governance milestone, **not** a general operating system expansion.
Physics remains an immutable, auditable authority nucleus.

The following components are **strictly excluded** from Milestone 3:
- Filesystems and Virtual File Systems (VFS)
- Block storage device stacks
- Network protocol stacks, sockets, and interfaces
- Schedulers, threads, processes, and preemptive task management
- POSIX compatibility layers and libc dependencies
- Dynamic loaders and ELF interpreters
- GPU initialization, accelerator drivers, and firmware loading
- Model runtime, neural weights, and tensor engines
- OMEGA semantic runtime and AST compilers
- AIEN cognitive models and world-state graphs
- General unprivileged userspace (EL0 execution remains decoupled)
- Unrestricted device drivers or arbitrary MMIO access

### Anti-Bloat Ceilings
- `.text` size $\le 32\text{ KiB}$
- `PHYSICS_TOTAL_IMAGE_BYTES` $\le 64\text{ KiB}$ (code, rodata, vectors, alignment padding)
- Capability table: static 4 KiB allocation (32 fixed-size records)
- Receipt ledger: static 8 KiB allocation (32 chained receipts)
- Replay cache: static 4 KiB allocation (32 replay slots)

---

## 3. Tripartite Division of Physical Authority

Physics enforces an unyielding ontological separation between authority, intent, and evidence:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              CAPABILITY                                │
│              Authority to attempt a bounded class of effects           │
│         Kernel-private, typed handle, non-forgeable, attenuable        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                           Exercised through
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                            EFFECT_INTENT                               │
│              Structured request to exercise specific authority         │
│          Caller-provided, compact binary, validated upon entry         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                        Evaluated by Effect Broker
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                            EFFECT_RECEIPT                              │
│         Authoritative cryptographic record of decision and result      │
│      Typed decision, SHA-256 chain, immutable audit trail, non-loss    │
└────────────────────────────────────────────────────────────────────────┘
```

1. **`CAPABILITY`**: Represents sovereign authority granted by Physics. A caller never holds a raw kernel pointer; callers hold typed references (`CapabilityId { slot, generation }`). The capability defines resource type, allowed operation bitmask, strict physical address bounds, lifetime, and parent provenance.
2. **`EFFECT_INTENT`**: Represents an explicit request to act upon physical reality. It specifies the capability to exercise, target resource, operation, spatial bounds, parameters, and constraints.
3. **`EFFECT_RECEIPT`**: The authoritative output of the effect cycle. Every submitted intent—whether admitted and executed or rejected at any gate—generates an immutable receipt committed to an append-only cryptographic ledger.

---

## 4. Capability Model & Memory Layout

### 4.1 Typed Capability Identifier (`CapabilityId`)
Capabilities are referenced externally exclusively via an 8-byte typed handle:

```text
CapabilityId (8 bytes):
  +0x00: slot        (u32) — Index into PHYSICS_CAPABILITY_TABLE [0..31]
  +0x04: generation  (u32) — Monotonic slot generation counter [1..2^32-1]
```

**Invariants:**
- A raw memory address is never accepted as a capability handle.
- Handles presenting stale generations are rejected immediately (`REJECTED_STALE_GENERATION`).
- Handles presenting out-of-range slots are rejected immediately (`REJECTED_UNKNOWN_CAP`).

### 4.2 Capability Record Layout (`CapabilityRecord`)
Every record in the capability ledger occupies exactly 128 bytes:

```text
CapabilityRecord (128 bytes, 64-bit aligned):
  +0x00: slot               (u32) — Slot index [0..31]
  +0x04: generation         (u32) — Slot generation counter (1-indexed)
  +0x08: principal_id       (u64) — Authorized principal identity (e.g. 1 = Physics)
  +0x10: resource_type      (u32) — Bounded resource class identifier
  +0x14: allowed_ops        (u32) — Bitmask of authorized operations
  +0x18: bound_base         (u64) — Physical start address of resource authority
  +0x20: bound_size         (u64) — Physical byte span of resource authority
  +0x28: revocation_state   (u32) — 1 = ACTIVE, 2 = REVOKED
  +0x2C: attenuation_depth  (u32) — Derivation distance from root (0 for CAP_ROOT)
  +0x30: provenance_digest  (32 bytes) — SHA-256 derivation commitment
  +0x50: parent_slot        (u32) — Slot index of immediate parent (0xFFFFFFFF for root)
  +0x54: parent_generation  (u32) — Generation of immediate parent (0xFFFFFFFF for root)
  +0x58: lifetime           (u64) — Temporal / epoch bound (0 = unbounded)
  +0x60: reserved           (32 bytes) — Zero-padded alignment space
```

### 4.3 Capacity & Memory Region
The capability ledger resides strictly within `PHYSICS_CAPABILITY_TABLE` (`0x40206000`–`0x40207000`, 4,096 bytes).
- Record size: 128 bytes ($2^7$ bytes, indexed via `slot << 7`).
- Ledger capacity: exactly 32 records ($32 \times 128 = 4,096$ bytes).
- No dynamic memory allocation. No heap.

---

## 5. Genesis Root Capability (`CAP_ROOT`)

`CAP_ROOT` is the sovereign genesis authority established at system awakening:
- **Slot**: 0
- **Generation**: 1
- **Principal ID**: `0x0000000000000001` (`PRINCIPAL_PHYSICS`)
- **Resource Type**: `0x00000001` (`RES_UNIVERSAL_ROOT`)
- **Allowed Ops**: `0xFFFFFFFF` (`OP_ALL_AUTHORITY`)
- **Bound Base**: `0x40208000` (`FREE_FRAME_BASE`)
- **Bound Size**: `0x07DF8000` (~125.9 MiB, `DRAM_END - FREE_FRAME_BASE`)
- **Revocation State**: `0x00000001` (`ACTIVE`)
- **Attenuation Depth**: 0
- **Parent Slot**: `0xFFFFFFFF` (None)
- **Parent Generation**: `0xFFFFFFFF` (None)
- **Lifetime**: 0 (Unbounded)
- **Provenance Digest**: 32-byte canonical SHA-256 digest of `atlas.bin`.

### Invariants:
1. `CAP_ROOT` is **kernel-private, non-transferable, and non-exportable**.
2. External principals never receive `CAP_ROOT` itself.
3. Every usable authority held by any caller is derived through monotonic attenuation from `CAP_ROOT` or one of its descendants.
4. Slot 0 is permanently pinned to `CAP_ROOT` and cannot be reclaimed, overwritten, or reused.

---

## 6. Monotonic Attenuation Engine

Authority may only be derived via monotonic attenuation:

$$\text{derive\_capability}(\text{parent\_id}, \text{child\_principal}, \text{resource\_type}, \text{ops}, \text{base}, \text{size}, \text{lifetime}) \to \text{CapabilityId} \mid \text{Error}$$

### The Monotonic Invariant
$$\begin{aligned}
\text{CHILD RIGHTS} &\subseteq \text{PARENT RIGHTS} \\
\text{CHILD BOUNDS} &\subseteq \text{PARENT BOUNDS} \\
\text{CHILD LIFETIME} &\le \text{PARENT LIFETIME} \\
\text{CHILD AUTHORITY} &\le \text{PARENT AUTHORITY}
\end{aligned}$$

### Attenuation Rules:
1. **Rights Containment**:
   $$( \text{requested\_ops} \land \neg \text{parent.allowed\_ops} ) = 0$$
   A child cannot gain any operation bit that the parent lacks.
2. **Spatial Bounds Containment**:
   All address calculations use checked arithmetic:
   $$\begin{aligned}
   \text{requested\_base} &\ge \text{parent.bound\_base} \\
   \text{requested\_base} + \text{requested\_size} &\ge \text{requested\_base} \quad (\text{no overflow}) \\
   \text{requested\_base} + \text{requested\_size} &\le \text{parent.bound\_base} + \text{parent.bound\_size}
   \end{aligned}$$
   Partial overlap is refused. Complete containment is strictly enforced.
3. **Resource Type Rule**:
   - If `parent.resource_type == RES_UNIVERSAL_ROOT`, child may select any concrete resource class (`RES_MEMORY_FRAME`, `RES_CONSOLE`, `RES_MEASUREMENT`).
   - If parent has a concrete resource class, child `resource_type` must equal `parent.resource_type`.
4. **Lifetime Rule**:
   If parent has a finite lifetime ($> 0$), child lifetime must be $\le \text{parent.lifetime}$ and non-zero.
5. **Anti-Root Equivalence Rule**:
   A derived capability can never have `resource_type == RES_UNIVERSAL_ROOT` or `principal_id == 0`.
6. **Provenance Chain**:
   The child's provenance digest is computed deterministically as:
   $$\text{child.provenance} = \text{SHA256}(\text{parent.provenance} \parallel \text{child\_fields})$$
7. **Ancestry Record**:
   $$\text{child.parent\_slot} = \text{parent.slot}, \quad \text{child.parent\_generation} = \text{parent.generation}$$
   $$\text{child.attenuation\_depth} = \text{parent.attenuation\_depth} + 1$$

---

## 7. Generation Model & Revocation Lifecycle

### 7.1 Slot Lookup Validation
Before any capability can be exercised or attenuated, Physics validates:
1. $0 \le \text{slot} < 32$ (ledger bounds check).
2. Record is occupied ($\text{generation} > 0$).
3. $\text{presented\_generation} == \text{record.generation}$ (stale handle check).
4. $\text{record.revocation\_state} == \text{ACTIVE}$ (immediate revocation check).
5. $\text{record.principal\_id} == \text{caller\_principal}$ (principal check).

### 7.2 Monotonic Generation Bumping
When a capability slot (1..31) is freed or reallocated:
$$\text{generation} := \text{generation} + 1$$
- If `generation` reaches `0xFFFFFFFF`, the slot is permanently marked exhausted and fails closed.
- Stale capability handles presenting older generation numbers fail lookup closed.

### 7.3 Instantaneous Descendant Revocation (Ancestor-Chain Validation)
Physics enforces **ancestor-chain validation on use**:
- When capability $C$ is evaluated, Physics inspects $C$'s revocation state.
- If $C$ is derived ($\text{slot} \ne 0$), Physics traverses the parent lineage:
  For each ancestor $A$ up to `attenuation_depth` (bounded $\le 8$):
  - Verify $A.\text{generation} == C.\text{parent\_generation}$.
  - Verify $A.\text{revocation\_state} == \text{ACTIVE}$.
- If any ancestor in the provenance chain is revoked or stale, validation immediately fails closed (`REJECTED_REVOKED`).
- Result: Revoking a parent capability immediately and deterministically renders all descendant capabilities unusable across the machine, with zero heap allocations and $O(\text{depth})$ bounded verification.

---

## 8. M3 Resource Classes & Operations

Milestone 3 implements the minimal set of physical resources necessary to establish and qualify the authority architecture:

```text
┌──────────────────────────┬────────────┬──────────────────────┬────────────┐
│ Resource Class           │ Type Code  │ Operation            │ Opcode     │
├──────────────────────────┼────────────┼──────────────────────┼────────────┤
│ `RESOURCE_MEMORY_FRAME`  │ 0x00000002 │ `FRAME_GRANT`        │ 0x00000001 │
│                          │            │ `FRAME_RELEASE`      │ 0x00000002 │
├──────────────────────────┼────────────┼──────────────────────┼────────────┤
│ `RESOURCE_CONSOLE`       │ 0x00000003 │ `CONSOLE_WRITE`      │ 0x00000001 │
├──────────────────────────┼────────────┼──────────────────────┼────────────┤
│ `RESOURCE_MEASUREMENT`   │ 0x00000004 │ `MEASUREMENT_READ`   │ 0x00000001 │
└──────────────────────────┴────────────┴──────────────────────┴────────────┘
```

### Constraints:
1. `RESOURCE_MEMORY_FRAME`:
   - Target range must be 4 KiB aligned and strictly contained within the capability's `[bound_base, bound_base + bound_size)`.
   - `FRAME_GRANT` allocates a 4 KiB page and marks the allocation bitmap.
   - `FRAME_RELEASE` clears the bitmap for an allocated frame.
2. `RESOURCE_CONSOLE`:
   - Target address must match the contracted PL011 UART MMIO base (`0x09000000`).
   - `CONSOLE_WRITE` outputs a bounded byte sequence. Arbitrary MMIO access is strictly prohibited.
3. `RESOURCE_MEASUREMENT`:
   - Reads sovereign machine telemetry: allocated frame count, receipt sequence counter, machine epoch.

---

## 9. Effect Intent Binary Format (`EffectIntent`)

Callers submit effect requests using a compact, fixed-size binary structure:

```text
EffectIntent (64 bytes, little-endian, 64-bit aligned):
  +0x00: version               (u16 = 1)
  +0x02: length                (u16 = 64)
  +0x04: reserved0             (u32 = 0)
  +0x08: request_id            (u64) — Caller-generated unique request identifier
  +0x10: principal_id          (u64) — Caller principal identity
  +0x18: capability_slot       (u32) — Slot of presented capability
  +0x1C: capability_generation (u32) — Generation of presented capability
  +0x20: resource_type         (u32) — Target resource class
  +0x24: operation             (u32) — Requested operation bitmask
  +0x28: target_base           (u64) — Target physical address / base
  +0x30: target_size           (u64) — Target byte length / size
  +0x38: constraints           (u64) — Execution constraints flags
  +0x40: expected_invariants   (u64) — Invariant assertions
  +0x48: param0                (u64) — Operation parameter 0 (e.g. data byte/address)
  +0x50: param1                (u64) — Operation parameter 1 (e.g. length)
  +0x58: reserved1             (u64 = 0)
```

**Invariants:**
- Fixed 64-byte width. No variable-length strings. No JSON. No textual parsing.
- Unaligned structures or truncated buffers trigger immediate structural refusal.

---

## 10. Effect Broker & Admission Pipeline

The Effect Broker owns the single canonical effect-admission path:

$$\text{submit\_effect}(\text{intent}) \to \text{EffectReceipt}$$

Handlers execute only already-admitted operations. Admission and physical execution are strictly decoupled in control flow.

```text
EFFECT_INTENT
      │
      ▼
[Stage 1: Structural Validation]  ──(Fail)──► REJECTED_STRUCTURAL
      │ (Pass)
      ▼
[Stage 2: Principal Validation]   ──(Fail)──► REJECTED_WRONG_PRINCIPAL
      │ (Pass)
      ▼
[Stage 3: Capability Lookup]      ──(Fail)──► REJECTED_UNKNOWN_CAP
      │ (Pass)
      ▼
[Stage 4: Generation Check]       ──(Fail)──► REJECTED_STALE_GENERATION
      │ (Pass)
      ▼
[Stage 5: Revocation Chain Check] ──(Fail)──► REJECTED_REVOKED
      │ (Pass)
      ▼
[Stage 6: Operation Rights Check] ──(Fail)──► REJECTED_OPERATION
      │ (Pass)
      ▼
[Stage 7: Resource Type Check]    ──(Fail)──► REJECTED_RESOURCE
      │ (Pass)
      ▼
[Stage 8: Bounds & Overflow Check]──(Fail)──► REJECTED_BOUNDS
      │ (Pass)
      ▼
[Stage 9: Replay Cache Check]     ──(Conflict)──► REJECTED_REPLAY_CONFLICT
      │                           ──(Hit: Same)─► Return Cached Receipt (No re-exec)
      │ (New Request)
      ▼
[Stage 10: Ledger Space Check]    ──(Full)──► REJECTED_EXHAUSTED
      │ (Pass)
      ▼
[Stage 11: PHYSICAL EXECUTION]    (Only reached after all admission checks pass)
      │
      ▼
[Stage 12: COMMIT TO RECEIPT LEDGER & REPLAY CACHE]
      │
      ▼
EFFECT_RECEIPT
```

**Cardinal Rule:** Any failure before Stage 11 produces zero physical state mutation.

---

## 11. Effect Receipts & Typed Decisions

Every intent evaluated by the broker generates an immutable `EffectReceipt`:

```text
EffectReceipt (192 bytes, 64-bit aligned):
  +0x00: version                 (u16 = 1)
  +0x02: length                  (u16 = 192)
  +0x04: decision                (u32) — Typed decision code
  +0x08: rejection_reason        (u32) — Specific sub-reason code
  +0x0C: reserved0               (u32 = 0)
  +0x10: request_id              (u64) — Mirrored from EffectIntent
  +0x18: intent_digest           (32 bytes) — SHA-256 of the 64-byte EffectIntent
  +0x38: actual_effect           (u64) — Physical effect result (e.g. granted frame)
  +0x40: output                  (u64) — Output code / bytes processed
  +0x48: capability_slot         (u32) — Presented slot
  +0x4C: capability_generation   (u32) — Presented generation
  +0x50: machine_generation      (u64) — Current machine monotonic counter
  +0x58: measurement             (u64) — Hardware measurement / cycle counter
  +0x60: previous_receipt_digest (32 bytes) — SHA-256 of prior receipt in chain
  +0x80: receipt_digest          (32 bytes) — SHA-256 of receipt bytes 0x00..0x7F
  +0xA0: reserved1               (32 bytes) — Reserved padding
```

### Typed Decision Codes:
```text
ADMITTED                 = 0x00000001  (Admitted and executed)
REJECTED_STRUCTURAL      = 0x00000002  (Bad version, length, reserved bits)
REJECTED_UNKNOWN_CAP     = 0x00000003  (Slot out of range or unpopulated)
REJECTED_STALE_GENERATION= 0x00000004  (Presented generation != slot generation)
REJECTED_REVOKED         = 0x00000005  (Target cap or ancestor revoked)
REJECTED_WRONG_PRINCIPAL = 0x00000006  (Caller principal mismatch)
REJECTED_OPERATION       = 0x00000007  (Requested op not in allowed_ops)
REJECTED_RESOURCE        = 0x00000008  (Intent resource != cap resource)
REJECTED_BOUNDS          = 0x00000009  (Target outside cap bounds or wraps)
REJECTED_CONSTRAINT      = 0x0000000A  (Constraint failure)
REJECTED_REPLAY_CONFLICT = 0x0000000B  (Same request_id, different intent)
REJECTED_EXHAUSTED       = 0x0000000C  (Receipt ledger capacity full)
EXECUTION_FAILED         = 0x0000000D  (Admitted but hardware execution failed)
```

---

## 12. Cryptographic Receipt Chain & Bounded Ledger

### 12.1 Digest Binding & Tamper Evidence
- Each receipt binds `previous_receipt_digest`. For the genesis receipt (receipt 0), `previous_receipt_digest` is 32 zero bytes.
- The `receipt_digest` seals all fields from `+0x00` through `+0x7F` (including `previous_receipt_digest`, `intent_digest`, decision, and actual effect) using NIST SHA-256.
- Mutation or reordering of receipts in memory is cryptographically detectable.

### 12.2 Ledger Exhaustion Policy (Fail-Closed)
- Capacity: 32 receipts located in `PHYSICS_RECEIPT_LEDGER` (`0x40208000`–`0x4020A000`, 8,192 bytes).
- When the ledger reaches capacity (32 receipts committed), Physics **halts effect admission**.
- Subsequent intents receive `REJECTED_EXHAUSTED` and cause zero physical effect.
- Physics **never silently overwrites evidence**.

---

## 13. Replay Semantics & Cache

Physics maintains a bounded 32-entry Replay Cache in `PHYSICS_REPLAY_CACHE` (`0x4020A000`–`0x4020B000`, 4,096 bytes).

```text
ReplayRecord (64 bytes):
  +0x00: request_id    (u64)
  +0x08: intent_digest (32 bytes)
  +0x28: receipt_slot  (u32)
  +0x2C: decision      (u32)
  +0x30: actual_effect (u64)
  +0x38: reserved      (16 bytes)
```

### Replay Rules:
1. **Idempotent Hit**: Same `request_id` AND identical `intent_digest`:
   - Returns the previous receipt / semantic result without re-executing the physical effect.
   - Example: Repeating a `FRAME_GRANT` returns the previously granted frame address without advancing the frame allocator cursor.
2. **Replay Conflict**: Same `request_id` AND differing `intent_digest`:
   - Rejected immediately with `REJECTED_REPLAY_CONFLICT`.
   - Zero physical effect occurs.
   - A rejection receipt is committed to evidence.

---

## 14. Milestone 3 Disjoint Memory Map

Physics partitions physical memory into strictly disjoint, non-overlapping regions:

```text
0x4000_0000 ┌──────────────────────────────────────────┐ <── DRAM Base (Atlas Staging / DTB)
            │ Unused / Staging / Atlas Scratchpad      │
0x4020_0000 ├──────────────────────────────────────────┤ <── PHYSICS_IMAGE_BASE
            │ PHYSICS_IMAGE (.text, .rodata, SHA-256)  │ [16 KiB] [0x40200000, 0x40204000)
0x4020_4000 ├──────────────────────────────────────────┤ <── PHYSICS_VECTOR_TABLE (2 KiB aligned)
            │ VBAR Table (16 x 128B slots)             │ [2 KiB]  [0x40204000, 0x40204800)
0x4020_4800 ├──────────────────────────────────────────┤ <── PHYSICS_KERNEL_STACK
            │ Dedicated Kernel Stack (Initial SP)      │ [16 KiB] [0x40204800, 0x40208800)
0x4020_8800 ├──────────────────────────────────────────┤ <── PHYSICS_BOOT_STATE
            │ Ingress Descriptor, Entry & Trap Record  │ [2 KiB]  [0x40208800, 0x40209000)
0x4020_9000 ├──────────────────────────────────────────┤ <── PHYSICS_CAPABILITY_TABLE
            │ Capability Table (32 x 128B records)     │ [4 KiB]  [0x40209000, 0x4020A000)
0x4020_A000 ├──────────────────────────────────────────┤ <── PHYSICS_RECEIPT_LEDGER
            │ Receipt Ledger (32 x 192B receipts)      │ [8 KiB]  [0x4020A000, 0x4020C000)
0x4020_C000 ├──────────────────────────────────────────┤ <── PHYSICS_REPLAY_CACHE
            │ Replay Cache (32 x 64B records)          │ [4 KiB]  [0x4020C000, 0x4020D000)
0x4020_D000 ├──────────────────────────────────────────┤ <── PHYSICS_STATIC_DATA
            │ Frame Bitmap & Static Allocator Tables   │ [12 KiB] [0x4020D000, 0x40210000)
0x4021_0000 ├──────────────────────────────────────────┤ <── FREE_FRAME_BASE
            │ Bounded Free DRAM Frames (Frame Auth)    │ [125.9375 MiB = 32,240 frames]
0x4800_0000 └──────────────────────────────────────────┘ <── DRAM_END
```

Formal Disjointness Invariant:
$$\forall \mathcal{R}_i, \mathcal{R}_j \in \{\text{IMAGE}, \text{VBAR}, \text{STACK}, \text{BOOT\_STATE}, \text{CAP\_TABLE}, \text{RECEIPTS}, \text{REPLAY}, \text{STATIC\_DATA}, \text{FREE\_DRAM}\}: \quad i \neq j \implies \mathcal{R}_i \cap \mathcal{R}_j = \emptyset$$

---

## 15. Dynamic Verification Scenario (End-to-End Authority Proof)

The core dynamic proof for Milestone 3 executes the following sequence:

```text
CAP_ROOT (Slot 0, Gen 1)
   │
   ├─► Derive Capability A (Slot 1, Gen 1)
   │     Principal: 2
   │     Resource: RESOURCE_MEMORY_FRAME
   │     Allowed Ops: OP_FRAME_GRANT
   │     Bounds: Region R [0x40210000, 0x40220000) (64 KiB = 16 frames)
   │     │
   │     ├─► Submit Intent 1 (Request ID 100, Cap A, OP_FRAME_GRANT, Target within R)
   │     │     Broker: ADMITTED
   │     │     Execution: Frame granted (0x40210000), bitmap updated
   │     │     Receipt 1 emitted (decision = ADMITTED, prev_digest = 0)
   │     │
   │     ├─► Derive Capability B (Slot 2, Gen 1) from Cap A
   │     │     Principal: 3
   │     │     Resource: RESOURCE_MEMORY_FRAME
   │     │     Allowed Ops: OP_FRAME_GRANT
   │     │     Bounds: Region S [0x40210000, 0x40218000) (32 KiB, strict subset of R)
   │     │     │
   │     │     ├─► Submit Intent 2 (Request ID 101, Cap B, Target 0x40219000, OUTSIDE S)
   │     │     │     Broker: REJECTED_BOUNDS
   │     │     │     Execution: ZERO physical effect, no bitmap change
   │     │     │     Receipt 2 emitted (decision = REJECTED_BOUNDS, binds Receipt 1 digest)
   │     │
   │     └─► Revoke Capability A (Slot 1)
   │           Record 1 marked REVOKED
   │           │
   │           ├─► Submit Intent 3 (Request ID 102, Cap A) -> REJECTED_REVOKED
   │           ├─► Submit Intent 4 (Request ID 103, Cap B) -> REJECTED_REVOKED (descendant failure)
   │           └─► Receipts 3 and 4 emitted in chain; zero physical effects
```

---

## 16. Adversarial Qualification Matrix

Every adversarial case must prove: **No unauthorized physical effect occurred** via direct state inspection (memory dump verification), not UART text alone.

| Adversarial Case | Description | Expected Decision | State Verification Proof |
| :--- | :--- | :--- | :--- |
| `FORGED_CAP_SLOT` | Present unallocated slot (e.g. slot 15) | `REJECTED_UNKNOWN_CAP` | No frame allocated; UART unchanged |
| `OUT_OF_RANGE_SLOT` | Present slot $\ge 32$ | `REJECTED_UNKNOWN_CAP` | No frame allocated; ledger bounds intact |
| `STALE_GENERATION` | Present valid slot with old generation | `REJECTED_STALE_GENERATION` | Bitmap untouched; no frame granted |
| `REVOKED_CAP` | Exercise directly revoked capability | `REJECTED_REVOKED` | Bitmap untouched |
| `DESCENDANT_REVOCATION` | Exercise child after parent revoked | `REJECTED_REVOKED` | Bitmap untouched |
| `WRONG_PRINCIPAL` | Present cap with mismatching principal ID | `REJECTED_WRONG_PRINCIPAL` | Zero effect |
| `FORBIDDEN_OP` | Request `FRAME_RELEASE` on grant-only cap | `REJECTED_OPERATION` | Bitmap untouched |
| `WRONG_RESOURCE` | Request `CONSOLE_WRITE` on memory cap | `REJECTED_RESOURCE` | UART MMIO untouched |
| `RIGHTS_WIDENING` | Attempt to derive ops not in parent | Attenuation Error | Child slot unallocated |
| `BOUNDS_WIDENING` | Attempt to derive bounds outside parent | Attenuation Error | Child slot unallocated |
| `LIFETIME_WIDENING` | Attempt to derive longer lifetime than parent | Attenuation Error | Child slot unallocated |
| `BOUNDS_OVERFLOW` | Child base + size wraps 64-bit integer | Attenuation Error | Child slot unallocated |
| `TARGET_OVERFLOW` | Intent target_base + size wraps 64-bit | `REJECTED_BOUNDS` | Bitmap untouched |
| `OUT_OF_BOUNDS_TARGET`| Target outside capability bound | `REJECTED_BOUNDS` | Bitmap untouched |
| `ROOT_EXPORT_ATTEMPT` | External principal attempts to exercise slot 0 | `REJECTED_WRONG_PRINCIPAL` | Root remains private |
| `REUSED_SLOT_OLD_GEN` | Slot reallocated; caller presents old handle | `REJECTED_STALE_GENERATION` | Zero effect |
| `REPLAY_IDENTICAL` | Duplicate request ID with identical intent | Idempotent Return | Frame returned; allocator cursor NOT bumped |
| `REPLAY_CONFLICT` | Duplicate request ID with altered intent | `REJECTED_REPLAY_CONFLICT` | Zero effect; rejection receipt recorded |
| `MALFORMED_VERSION` | Version != 1 in EffectIntent | `REJECTED_STRUCTURAL` | Zero effect |
| `TRUNCATED_INTENT` | Length < 64 in EffectIntent | `REJECTED_STRUCTURAL` | Zero effect |
| `OVERSIZED_INTENT` | Length > 64 in EffectIntent | `REJECTED_STRUCTURAL` | Zero effect |
| `RECEIPT_EXHAUSTION` | Intent submitted when 32 receipts committed | `REJECTED_EXHAUSTED` | Admission halted fail-closed; zero effect |

---

## 17. Milestone 3 Qualification Gates

```text
QUALIFICATION SUITE: MILESTONE 3 (PHYSICS_EFFECTS)
├── Seam 1: Capability & Ledger Static Proofs
│   ├── [PASS] PHYSICS_CAP_LEDGER_PASS (Fixed-width 128B records, 32 slots in 4 KiB)
│   ├── [PASS] PHYSICS_CAP_ROOT_PRIVATE_PASS (Slot 0 private to Physics, non-exportable)
│   ├── [PASS] PHYSICS_CAP_ATTENUATION_PASS (Monotonic narrowing over rights/bounds/lifetime)
│   ├── [PASS] PHYSICS_CAP_NO_AMBIENT_AUTHORITY_PASS (Zero effect without explicit capability)
│   ├── [PASS] PHYSICS_CAP_GENERATION_PASS (Generation bumped on slot reuse; wrap fail-closed)
│   ├── [PASS] PHYSICS_CAP_REVOCATION_PASS (Target capability immediately unusable)
│   └── [PASS] PHYSICS_CAP_DESCENDANT_REVOCATION_PASS (Ancestor chain check fails all descendants)
│
├── Seam 2: Effect Broker & Replay Execution
│   ├── [PASS] PHYSICS_EFFECT_ADMISSION_PASS (Full 10-stage admission pipeline verification)
│   ├── [PASS] PHYSICS_EFFECT_BOUNDS_PASS (Strict containment, checked math, overflow refused)
│   ├── [PASS] PHYSICS_EFFECT_FORGED_CAP_REFUSAL_PASS (Unknown slot refused with zero effect)
│   ├── [PASS] PHYSICS_EFFECT_STALE_CAP_REFUSAL_PASS (Stale generation refused with zero effect)
│   ├── [PASS] PHYSICS_EFFECT_REVOKED_CAP_REFUSAL_PASS (Revoked cap refused with zero effect)
│   ├── [PASS] PHYSICS_EFFECT_WRONG_PRINCIPAL_REFUSAL_PASS (Principal mismatch refused)
│   ├── [PASS] PHYSICS_EFFECT_REPLAY_PASS (Idempotent replay without redundant physical mutation)
│   └── [PASS] PHYSICS_EFFECT_REPLAY_CONFLICT_PASS (Duplicate ID + different intent refused)
│
└── Seam 3: Receipt Evidence & Full System Emulation
    ├── [PASS] PHYSICS_RECEIPT_IDENTITY_PASS (Deterministic 192B receipt with SHA-256 seal)
    ├── [PASS] PHYSICS_RECEIPT_CHAIN_PASS (Append-only hash chain binds previous digest)
    ├── [PASS] PHYSICS_RECEIPT_EXHAUSTION_PASS (Full ledger halts admission fail-closed)
    └── [PASS] PHYSICS_EFFECTS_QEMU_PASS (Clean Atlas -> Physics M3 end-to-end boot and test run)
```

---

## 18. Qualification Receipt Requirements

The Milestone 3 qualification receipt (`m3_qualification_receipt.json`) must deterministically bind:
- `physics.bin` SHA-256 digest
- `machine_contract.json` (M3 contract) SHA-256 digest
- `docs/milestone-3-spec.md` SHA-256 digest
- Capability implementation source SHA-256 digest
- Effect broker implementation source SHA-256 digest
- Receipt implementation source SHA-256 digest
- Static audit runner digest
- Runtime harness runner digest
- Atlas handoff artifact digest
- Git commit hash
- QEMU binary version and invocation flags
- Exact gate pass/fail results (19/19 passing)
- Anti-bloat byte accounting breakdown

Milestone 3 is complete **only when** all 19 qualification gates pass under independent state inspection and the signed qualification receipt is committed.
