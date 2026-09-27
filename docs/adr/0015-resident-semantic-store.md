# ADR 0015: Resident Semantic Store Boundary, Object Identity, and Reconstruction Contract

**Status:** Proposed
**Author:** AIEN Architecture Working Group
**Date:** 2026-09-27
**Target Repositories:** `aien-architecture`, `aienos`, `omega`, `physics` (FORGE), `aegis-runtime`, `cortex-rs`, `aien-sovereign-core`

---

## Context

AIEN is a sovereign artificial intelligence architecture built on the canonical principle:

> **"AIEN lives in memory. Hardware visits it. Storage remembers how to bring it back."**

In this architecture, the primary running intelligence is an in-memory semantic world (`ResidentWorld`) materialized in coherent volatile memory. Accelerators (GPUs) and host processors (CPUs) are execution resources that visit this resident world to perform perception, reasoning, and transformation. Persistent storage (NVMe / block devices) is not the runtime medium; storage exists solely for deterministic reconstruction, provenance, durable knowledge, and cold recovery.

Previous milestones established foundational primitives across isolated subsystems:
- **OMEGA** (M4, M19) proved hardware-neutral semantic calculus, canonical object encodings (`OMG0`), deterministic `SemanticId` derivation, and accelerator residency.
- **FORGE** (formerly Machine Physics, M2, M16; ADR 0014) proved physical machine lowering, DMA descriptors, and Blackwell GPU execution pipelines.
- **AIENOS Store v1** (ADR 0015 in `aienos`) proved an append-only, content-addressed, crash-safe 4096-byte unit object store over NVMe.
- **AIENOS Continuity** (ADR 0016 in `aienos`, Proposed) proved deterministic single-agent provisioning and resume across reboots.
- **CORTEX** (M18) proved epistemic fact storage, vector similarity ranking, and evidence retrieval.

However, the complete contract connecting live volatile memory to durable block storage across reboots remains unratified. Without an unambiguous architecture contract:
1. Systems risk conflating semantic meaning (`SemanticId`) with storage container identity (`Store ObjectId`).
2. Implementations risk leaking machine-local, process-local, or chip-specific addresses into persistent records.
3. Storage engines risk introducing generic relational/key-value databases (SQLite, RocksDB) into formal semantic layers.
4. Cold recovery lacks a mathematically deterministic protocol to restore the in-memory graph from cold silicon.

This ADR ratifies the **Resident Semantic Store boundary**, establishing the authoritative rules, memory categories, object models, commit protocols, and cold reconstruction algorithms that every downstream builder must obey.

---

## Normative Specification

### 1. Authoritative State

1. **Live Operational Authority**:
   While AIEN is actively running, **the live resident state in coherent memory (`ResidentWorld`) is the sole authoritative operational world**. Dynamic goals, frontier reasoning, attention context, and evolving semantic relations exist authoritatively in volatile RAM. Accelerators compute directly over projections of this live state.
2. **Persistent Storage Role**:
   Persistent storage is **durable recovery material, historical evidence, and the immutable lineage anchor**. Disk is not the active working state. Storage does not become authoritative for live operations while the machine is running.
3. **Durability Authority Transition**:
   Persistent storage becomes canonical truth for a specific committed point in time **only upon the successful, atomic publication of a verified generation commit**. 
4. **Crash Authority**:
   Following an uncommitted crash, power loss, or kernel panic, all volatile memory is considered void. The **last successfully committed generation in the persistent Store becomes the authoritative root** from which a new, authoritative `ResidentWorld` is deterministically reconstructed.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        AIEN ResidentWorld                              │
│         (Sole Authoritative Operational World While Running)           │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
                    │ realizes / projects            │ semantic references
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│           FORGE Realization          │  │       CORTEX Epistemic       │
│  (Disposable CPU/GPU machine state)  │  │   (Durable fact memory)      │
└──────────────────────────────────────┘  └──────────────────────────────┘
                    ▲                                ▲
                    │ visits                         │ checkpoints
                    ▼                                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        AIENOS System Store v1                          │
│     (Authoritative Recovery Material & Historical Evidence Anchor)     │
├────────────────────────────────────────────────────────────────────────┤
│ ContinuityManifest ──► OmegaResidentRoot ──► Canonical Semantic Objects │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 2. Memory Categories

Every object, buffer, and descriptor within AIEN belongs to exactly one of five canonical memory categories. Mixing categories or persisting disallowed categories is a critical safety violation that causes immediate fail-closed termination.

| Property | `DURABLE` | `RECONSTRUCTIBLE` | `DERIVED` | `EPHEMERAL` | `DEVICE_LOCAL` |
|---|---|---|---|---|---|
| **Owner** | AIENOS Store v1 / Continuity | AIEN ResidentWorld | Runtime / Cache Manager | AIEN Reasoning Loop | FORGE / Hardware Driver |
| **Identity** | Store `ObjectId` & `SemanticId` | Canonical `SemanticId` | Derived Content Hash | Session-local ID / Index | Chip Handle / Hardware VA |
| **Lifetime** | Permanent (survives reboot) | Lifespan of Generation | Recomputed or Cached | Single Turn / Step | Active Device Session |
| **Mutability** | Immutable once committed | Immutable view; versioned | Invalidate and replace | Mutable scratch space | Volatile register/VRAM state |
| **May be persisted?** | **YES** (Mandatory) | NO (Rebuilt from Durable) | NO (Cached/discarded) | NO (Prohibited) | **NEVER** (Strictly Prohibited) |
| **Must be persisted?** | **YES** | NO | NO | NO | NO |
| **Reconstructed after reboot?** | Read directly from Store | Reconstructed from Durable | Re-evaluated on demand | Discarded on reboot | Re-initialized on silicon |
| **May contain machine addresses?** | **NEVER** | NO | NO | NO | YES (Device-only) |
| **Failure behavior** | Fail closed to Recovery Core | Re-derive from Store | Invalidate and recompute | Drop current turn | Reset device context |
| **Recovery behavior** | Validated via SHA-256 | Deterministically rebuilt | Lazy recomputation | Fresh initialization | Fresh allocation & binding |

---

### 3. Semantic Identity vs Runtime Realization

1. **The Invariance Principle**:
   Permanent semantic identity must **never depend on transient process, operating system, or hardware values**. A semantic object must have the exact same identity regardless of what CPU, GPU, memory address, or operating system instance executes it.
2. **Transient Realization State**:
   The following entities are explicitly classified as `DEVICE_LOCAL` or `EPHEMERAL` realization state and **must never appear in persistent storage**:
   - Host CPU pointers and virtual addresses (`*mut T`, `uintptr_t`, `void*`)
   - Accelerator / GPU virtual addresses (`gpu_va`)
   - Driver and resource manager handles (`RM_HANDLE`, NVRM allocations, channel handles)
   - Hardware queue IDs, ring buffer head/tail pointers, and doorbells
   - Channel generations and synchronization semaphore values
   - Operating system memory map addresses (`mmap`, page frame numbers)
   - File descriptors (`fd`), socket descriptors, and IPC pipe handles
   - Temporary allocation IDs and scratchpad addresses
   - Operating system process IDs (`PID`), thread IDs (`TID`), or core pinning masks
3. **Reconstruction Law**:
   Cold recovery reconstructs fresh hardware realizations rather than deserializing stale hardware or process identities. If any persistent record is found to contain a physical memory address or driver handle, the verifier MUST reject the record as corrupted.

---

### 4. Persistent Object Model

1. **Canonical Semantic Bytes**:
   Omega semantic objects are serialized strictly using the canonical Omega wire encoding (`OMG0` wire format):
   - Fixed header: Magic `OMG0` (`0x4F, 0x4D, 0x47, 0x30`), `version = 0x01`, `kind: u8`.
   - Lexicographically sorted attributes by key string.
   - Lexicographically sorted relations by `(kind, target_id)`.
   - Lexicographically sorted constraints by `(kind, payload)`.
   - Bounded payload bytes.
2. **Content Identity (`SemanticId`)**:
   `SemanticId` identifies semantic meaning:
   ```text
   SemanticId = SHA256(canonical_omega_encoded_bytes)
   ```
3. **Storage Container Identity (`Store ObjectId`)**:
   AIENOS Store v1 packages canonical semantic objects into storage application objects. `Store ObjectId` identifies a persistent storage container under AIENOS Store-domain hashing per AIENOS ADR 0015:
   ```text
   Store ObjectId = SHA256(
     ASCII("AIENOS-STORE-OBJECT-V1\0")
     || kind:u16le || version:u16le || byte_length:u64le
     || semantic_bytes[byte_length]
   )
   ```
4. **Identity Separation**:
   `SemanticId != Store ObjectId`. Even when wrapping identical canonical bytes, the Store envelope domain separation guarantees that the digests diverge. An explicit translation mapping connects them.
5. **Store Application Object Kinds**:
   Store v1 core format (ADR 0015) is frozen. New persistent semantic types are allocated within the application kind range:
   - `KIND_OMEGA_OBJECT = 24`: Holds the canonical Omega object wire bytes.
   - `KIND_OMEGA_RESIDENT_ROOT = 25`: Holds the resident graph root manifest and index.
6. **Immutability & Deduplication**:
   Once written to the Store append arena, objects are strictly immutable. If an object with an identical `ObjectId` already exists in the Store catalog, the write path deduplicates it by referencing the existing extent, provided its content digest is independently verified.
7. **Corruption Detection**:
   Every object read from persistent media must undergo two-level cryptographic verification:
   1. The Store envelope must match `Store ObjectId = SHA256(domain || header || bytes)`.
   2. The canonical payload must match `SemanticId = SHA256(bytes)`.
   Any mismatch constitutes immediate corruption.

---

### 5. Canonical Resident Root (`OmegaResidentRoot`)

The recoverable entry point for an Omega semantic world is the **`OmegaResidentRoot`** (Store v1 application kind 25).

#### 1. Fields and Bindings:
An `OmegaResidentRoot` minimally and normatively binds:
1. **Magic & Version**: Magic `OMGROOT1`, `format_version = 1`, `omega_schema_version: u16`.
2. **Generation Context**: Monotonic logical generation counter (`generation: u64`), logical epoch timestamp (`epoch: u64`).
3. **Agent Binding**: `logical_agent_id: [u8; 32]`, binding this graph to the provisioned agent.
4. **Lineage Reference**: `parent_resident_root_id: Option<ObjectId>`, pointing to the prior durable resident root (or zero for genesis).
5. **Semantic Graph Roots**: A bounded array of root `SemanticIds` representing the active entry points into the semantic DAG.
6. **Manifest Mapping Table**: A sorted array of tuples `(SemanticId: [u8; 32], store_object_id: ObjectId)`. Sorted in strictly increasing lexicographic order by `SemanticId` to allow $O(\log N)$ binary search during resolution.
7. **Cortex Checkpoint Reference**: `cortex_checkpoint_id: Option<ObjectId>`, binding the epistemic fact checkpoint.
8. **Capability Policy Root**: `policy_root_digest: [u8; 32]`, binding the durable security policy.
9. **Evidence Root**: `evidence_root_digest: [u8; 32]`, binding the signed evidence and receipt tree.
10. **Model State Reference**: `model_state_root_id: Option<ObjectId>`, binding the persistent learned weights and optimizer state.

#### 2. Strict Exclusion:
`OmegaResidentRoot` **must never contain** accelerator context handles, GPU virtual addresses, runtime queue pointers, or transient allocation identifiers.

---

### 6. Generation & Commit Model

Durability is not an incremental background leak; it is an explicit, staged transaction barrier. A state transition becomes durable if and only if the complete commit protocol completes past the durability linearization point.

#### The Ordered Commit Protocol:
1. **Phase 1: Working State Freeze**:
   The runtime freezes the candidate `ResidentWorld` changeset in volatile memory. Active reasoning steps on this generation complete or pause.
2. **Phase 2: Canonical Serialization**:
   All new or modified semantic objects in the changeset are serialized into canonical Omega wire format (`OMG0`).
3. **Phase 3: Semantic Identity Derivation**:
   The runtime computes and verifies the `SemanticId` for every candidate object.
4. **Phase 4: Store Deduplication & Staging**:
   The runtime computes candidate `Store ObjectIds`. The current Store catalog is inspected. Objects already committed in previous generations are deduplicated.
5. **Phase 5: Append Canonical Objects**:
   New application objects (`KIND_OMEGA_OBJECT = 24`) are written to the uncommitted append arena of Store v1.
6. **Phase 6: Assemble OmegaResidentRoot**:
   The runtime constructs `OmegaResidentRoot` (kind 25), sorting its mapping table by `SemanticId`, binding the root set, Cortex references, and policy digest.
7. **Phase 7: Append OmegaResidentRoot**:
   `OmegaResidentRoot` is written to the append arena.
8. **Phase 8: Assemble ContinuityManifest**:
   A new `ContinuityManifest` (kind 17) is constructed with `sequence = previous + 1`, `incarnation = current`, binding `AgentRoot`, `AgentStateCheckpoint`, Cortex WAL segments, and the new `OmegaResidentRoot` `ObjectId`.
9. **Phase 9: Assemble Full Catalog**:
   The full updated Store catalog (kind 1) is written to the append arena, sorted by `ObjectId`.
10. **Phase 10: Arena Hardware Flush**:
    A hardware cache flush / NVMe flush command is issued to ensure all newly written extents reach non-volatile media.
11. **Phase 11: Write CommitRecord**:
    A single-unit `CommitRecord` (kind 2) is written to the append arena, referencing the new Catalog, high-water mark, and generation.
12. **Phase 12: Pre-Commit Hardware Flush**:
    A second NVMe flush is issued, ensuring the `CommitRecord` is durable on media.
13. **Phase 13: The Durability Linearization Point (Superblock Publication)**:
    The active Superblock is toggled (Unit 0 Superblock A $\leftrightarrow$ Unit 1 Superblock B) by writing the updated 4096-byte block with the incremented Store generation, pointing to the new `CommitRecord`, followed by a final NVMe hardware flush.

```text
Staged Objects ──► Staged Root ──► Staged Manifest ──► Flush ──► CommitRecord ──► Flush ──► [SUPERBLOCK PUBLISH] ──► Flush
                                                                                                        ▲
                                                                                       Durability Linearization Point
```

#### Crash Semantics Around Linearization Point:
- **Crash Before Point (Phases 1–12)**:
  The transaction is void. The active Superblock on disk still points to the prior generation. On reboot, the mount engine inspects the prior active superblock; uncommitted arena extents beyond the prior high-water mark are ignored and overwritten on subsequent writes.
- **Crash During Point (Phase 13)**:
  The superblock write is an atomic 4096-byte sector operation protected by a CRC32/SHA-256 checksum. If the write is torn or incomplete, the superblock fails checksum verification, and the mount engine falls back to the alternate valid superblock. Either the old generation mounts or the new generation mounts; a half-committed generation is mathematically impossible.
- **Crash After Point (Phase 13 complete)**:
  The new generation is permanently durable. On reboot, the mount engine selects the new superblock as the highest valid generation.

---

### 7. Storage Atomicity & Fault Tolerance

1. **Atomic Publication Primitive**:
   Store v1 achieves atomicity exclusively through **ping-pong Superblock publication** across Unit 0 and Unit 1. The superblock write is the sole atomic switch of authority.
2. **Ahead-of-Time Writing**:
   All payload objects, indexes, manifests, catalogs, and commit records are appended ahead of time in the passive arena. They do not alter system authority until the superblock references them.
3. **Specific Fault Behaviors**:
   - **Power Cut**: If power cuts at any microsecond, the active superblock remains valid. Torn writes in the arena never affect committed state.
   - **Partial / Torn Block Write**: Discarded by checksum failure on mount; mount falls back to the previous intact superblock.
   - **Filesystem / OS Crash**: Bypassed; AIENOS interacts directly with block storage over NVMe without host filesystem layers.
   - **Duplicate / Replayed Commit**: Monotonic generation counters in the superblock and sequential monotonic sequence counters in `ContinuityManifest` reject replayed commits.
   - **Storage-Full Condition**: If the append arena lacks space for the complete changeset, catalog, and commit record, the transaction aborts cleanly before Phase 10. Volatile memory retains the dirty state, and no generation is published.

---

### 8. Deterministic Cold Recovery Algorithm

When AIENOS boots on physical silicon or within a virtual machine, cold recovery executes strictly as follows:

```text
1. Mount Block Device
   ↓
2. Evaluate Superblock A (Unit 0) and Superblock B (Unit 1)
   ↓
3. Select highest valid generation with verified checksum
   ↓
4. Validate CommitRecord & Catalog
   ↓
5. Count AgentRoot objects (0 = Stop/Unprovisioned, >1 = Stop/Conflict, 1 = Continue)
   ↓
6. Trace ContinuityManifest chain to current tip (Verify monotonic sequence & hashes)
   ↓
7. Extract OmegaResidentRoot ObjectId from ContinuityManifest
   ↓
8. Read & verify OmegaResidentRoot (Check magic, format_version, agent binding)
   ↓
9. Verify Object Closure:
   For each SemanticId reachable from root_semantic_ids:
     a. Lookup SemanticId in mapping_table to obtain Store ObjectId
     b. Read Store v1 object from media
     c. Verify Store envelope: SHA256 == ObjectId
     d. Decode OmegaObject from canonical bytes
     e. Verify recomputed SemanticId == expected SemanticId
     f. Enumerate relation SemanticIds; verify presence in mapping_table
   ↓
10. Reconstruct in-memory ResidentWorld graph (allocate fresh volatile nodes)
   ↓
11. Restore Cortex references: Bind EpistemicRef handles to Cortex database
   ↓
12. Rebuild transient CPU state: Allocators, task rings, scheduler queues
   ↓
13. Rebuild transient GPU realizations: FORGE compiles fresh pushbuffers/QMDs; allocates new GPU VAs
   ↓
14. Re-establish capabilities: Evaluate durable policy against physical hardware ID; mint runtime tokens
   ↓
15. Commit new incarnation manifest before observation (incarnation + 1)
   ↓
16. Resume AIEN sovereign execution loop
```

#### Anomaly Resolution Rules:
- **Newest Generation Corrupt**: If the newest manifest or root fails verification, fail closed to **Recovery Core** (`CONTINUITY: CORRUPT`). Never attempt heuristic salvage.
- **Missing Object**: If any object in the transitive closure of the root set is missing from the Store, fail closed (`CONTINUITY: CORRUPT`). Never run with a partial semantic graph.
- **Parent Generation Valid**: The Recovery Core operator interface may authorize fallback to the parent generation via an explicit operator signature.
- **No Valid Generation**: If no valid `AgentRoot` exists, halt with `CONTINUITY: UNPROVISIONED`. Never mint an automatic replacement identity.
- **Unverified Evidence**: If an evidence receipt claims a generation that cannot be reconstructed from storage, mark the receipt as unverified and halt in Recovery Core.

---

### 9. Rollback Architecture

1. **Transparent Automatic Rollback (Uncommitted Crashes)**:
   If a crash occurs before the durability linearization point, recovery automatically mounts the prior committed generation. This is standard crash recovery, not historical rollback.
2. **Operator-Authorized Rollback (Committed Generations)**:
   Reverting to an earlier committed generation is an **exceptional operator-authorized action** performed exclusively through Recovery Core (ADR 0006). It requires offline operator cryptographic authorization.
3. **History Immutability Rule**:
   Rollback **never mutates or truncates history in-place**. When rolling back to generation $K$ from generation $N$:
   - A new forward generation $N+1$ is committed.
   - The new `ContinuityManifest` sets `sequence = N + 1`, `incarnation = current + 1`.
   - It sets `rollback_parent_id = generation_K_manifest_id`.
   - The semantic root of generation $K$ is reinstated as the active root of generation $N+1$.
   Historical generations $K..N$ remain immutable in the store for auditability.

---

### 10. Cortex Epistemic Memory Boundary

1. **Separation of Concerns**:
   - **Resident Semantic Store (`ResidentWorld`)**: Active, operational semantic state, reasoning graphs, goals, and transient attention context.
   - **Cortex**: Durable epistemic memory containing settled facts, world knowledge, dense vector embeddings, full-text indexes, and empirical evidence.
2. **Prohibition of Database Replacement**:
   Cortex durable memory must not become the live runtime scheduler database, and Omega must not embed Cortex's SQLite/vector database internals.
3. **Cross-Boundary References**:
   Active semantic objects reference Cortex knowledge exclusively through immutable, typed reference handles:
   ```text
   struct EpistemicRef {
       fact_id: [u8; 32],        // Unique immutable fact identifier in Cortex
       evidence_hash: [u8; 32],  // Cryptographic digest of supporting evidence
       schema_epoch: u32,        // Epistemic schema generation
   }
   ```
4. **Promotion Lifecycle**:
   Knowledge moves strictly forward through a verified lifecycle:
   ```text
   Ephemeral Reasoning (RAM)
       ↓ evaluated and supported by empirical evidence
   Candidate Knowledge (J-Space)
       ↓ verified by AEGIS contract checker
   Cortex Admission (Signed Admission Receipt)
       ↓ committed to Cortex WAL / Checkpoint
   Durable Epistemic Fact (Referenced by ResidentWorld via EpistemicRef)
   ```
5. **Cold Recovery Parity**:
   On cold restart, resolving an `EpistemicRef` from the reconstructed `ResidentWorld` retrieves the identical committed Cortex fact and evidence receipt.

---

### 11. Model & Learned State

1. **Structured Semantic Representation**:
   Learned weights, model architectures, optimizer states, training steps, and RNG states must be represented as structured, content-addressed semantic objects, **not opaque third-party binary blobs** (e.g. PyTorch pickles or unverified binary dumps).
2. **Deconstruction into Semantic Objects**:
   - **Weights**: Chunked into immutable, content-addressed memory blocks (`KIND_MEMORY = 0x06` or `KIND_VALUE = 0x01`), indexed by tensor descriptor metadata.
   - **Model Architecture**: Formal Omega operation DAG (`KIND_OPERATION = 0x03`, `KIND_TYPE = 0x02`).
   - **Execution Context**: Checkpoint metadata binding current training step (`u64`), learning rate schedule, and cryptographic RNG seed (`[u8; 32]`).
3. **Portability**:
   Model state represented in this manner can be reconstructed onto any supported accelerator (Blackwell, Grace CPU, or generic AArch64) without format conversion.

---

### 12. GPU & FORGE Machine Reconstruction (The Reboot Theorem)

> **The Reboot Theorem**: *Semantic identity survives reboot; physical hardware realizations do not.*

1. **Disposable Projections**:
   All GPU memory allocations, command buffers, page tables, and hardware queues are disposable projections of the underlying `ResidentWorld`.
2. **Reconstruction Pipeline**:
   After cold recovery restores the logical `ResidentWorld`, the accelerator state is reconstructed through a four-stage lowering chain:
   ```text
   Persistent Semantic Object (Durable)
       ↓
   Omega Realization Request (Hardware-neutral intent)
       ↓
   FORGE Target Realization (Physical machine lowering: compiles kernels, plans VRAM layout)
       ↓
   AEGIS Verification (Validates alignment, bounds, and security invariants)
       ↓
   New Accelerator-Resident State (Fresh GPU VAs, new RM channels, new doorbell bindings)
   ```
3. **Zero Address Leakage**:
   The newly assigned GPU virtual addresses, NVRM channel handles, and doorbell addresses are completely independent of the addresses used prior to the reboot. The logical `SemanticId` remains bit-for-bit identical.

---

### 13. Capability & Security State Reconstruction

1. **Surviving Authority**:
   The only security state that survives reboot is **durable policy definitions, cryptographic root identities, and agent key material** stored in `AgentRoot` or signed policy manifests.
2. **Prohibition of Serialized Booleans**:
   A serialized boolean flag (such as `is_authorized = true`) or a serialized runtime slot number **must never recreate authority across reboot**.
3. **Re-derivation of Runtime Capabilities**:
   Upon boot, all runtime capabilities must be re-evaluated from scratch:
   - FORGE inspects physical hardware and derives a clean `ForgeMachineDescriptor`.
   - AEGIS evaluates the durable security policy against the verified hardware descriptor.
   - AEGIS issues freshly minted runtime capability tokens with newly generated slot generation numbers.

---

### 14. Evidence & Provenance Lifecycle

Every state transition must generate machine-readable, verifiable evidence. Evidence records must distinguish five distinct lifecycle states:

```text
PROPOSED ──► WRITTEN ──► DURABLE ──► RECOVERED (or REJECTED)
```

1. **`PROPOSED`**: Candidate generation constructed in RAM; contains list of modified `SemanticIds`.
2. **`WRITTEN`**: Objects written to Store append arena; contains Store extent descriptors and calculated `ObjectIds`.
3. **`DURABLE`**: Generation committed via Superblock flush; contains `CommitRecord` hash, Superblock index (A or B), and monotonic generation number.
4. **`RECOVERED`**: Cold recovery successfully completed; contains reconstructed graph digest, execution timestamp, and new incarnation number.
5. **`REJECTED`**: Validation failure receipt; contains exact failing offset, mismatched cryptographic hash, missing object ID, and reason for fail-closed termination.

---

### 15. Comprehensive Failure Matrix

| Failure Event | Detection Mechanism | Safe State | Fallback Action | Operator Evidence |
|---|---|---|---|---|
| **Process crash before commit** | Prior superblock valid on reboot | Prior committed generation intact | Ignore uncommitted arena bytes | `RECOVERY_PRIOR_GENERATION_RESUMED` |
| **Process crash during commit** | Checksum validation of CommitRecord | Prior committed generation intact | Discard partial arena extents | `RECOVERY_UNCOMMITTED_ARENA_IGNORED` |
| **Power loss before publication** | Active superblock generation unchanged | Prior committed generation intact | Resume prior generation | `RECOVERY_POWER_CUT_PRIOR_CLEAN` |
| **Power loss during publication** | Superblock CRC32/SHA-256 failure | Alternate superblock valid | Mount alternate valid superblock | `RECOVERY_SUPERBLOCK_TORN_FALLBACK` |
| **Power loss after publication** | New superblock passes checksum | New committed generation intact | Resume new generation | `RECOVERY_NEW_GENERATION_RESUMED` |
| **Truncated object** | Store envelope length != read length | Fail closed to Recovery Core | Halt; require operator inspection | `RECOVERY_OBJECT_TRUNCATED_REFUSED` |
| **Corrupted object bytes** | `SHA256(bytes) != ObjectId` | Fail closed to Recovery Core | Halt; refuse dirty state | `RECOVERY_OBJECT_CHECKSUM_MISMATCH` |
| **Missing root object** | `OmegaResidentRoot` not in catalog | Fail closed to Recovery Core | Halt; never guess root | `RECOVERY_ROOT_OBJECT_MISSING` |
| **Missing child object** | Traversal encounters missing ID | Fail closed to Recovery Core | Halt; reject partial graph | `RECOVERY_GRAPH_CLOSURE_INCOMPLETE` |
| **SemanticId mismatch** | Canonical decode digest != SemanticId | Fail closed to Recovery Core | Halt; refuse invalid semantics | `RECOVERY_SEMANTIC_ID_DIVERGENCE` |
| **Invalid capability state** | Policy validation fails during boot | Recovery Core minimal privilege | Refuse execution grants | `SECURITY_CAPABILITY_REISSUANCE_FAILED`|
| **GPU reconstruction failure** | FORGE kernel compilation error | Degraded CPU-only resident state | Alert operator; no GPU ops | `FORGE_REALIZATION_GPU_FAILED` |
| **Cortex unavailable/corrupt** | Cortex database integrity check fail | Epistemic read-only recovery | Halt learning; allow inspection| `CORTEX_CHECKPOINT_INTEGRITY_FAILED` |
| **Storage full** | Pre-write arena capacity check | Prior committed generation intact | Abort commit; keep live state | `STORAGE_APPEND_ARENA_EXHAUSTED` |
| **Hardware I/O error** | NVMe driver returns error code | Report `MountError::Io` | Never treat I/O error as corrupt | `STORAGE_HARDWARE_IO_FAULT` |

---

### 16. Subsystem Boundaries (Owner / Boundary / Failure / Evidence)

#### 1. AIEN ResidentWorld
- **Owner**: `aien-sovereign-core`
- **Boundary**: Operates entirely in coherent volatile memory; issues commit barriers to AIENOS; never performs direct disk I/O.
- **Failure Behavior**: On crash or panic, all volatile state is abandoned; recovers exclusively from the last durable generation.
- **Evidence**: Emits `RESIDENT_WORLD_EPOCH_ADVANCED` and `RESIDENT_GENERATION_PROPOSED`.

#### 2. Omega Semantic Calculus
- **Owner**: `omega`
- **Boundary**: Pure formal semantic encoding, `SemanticId` computation, and graph reachability; no knowledge of storage, hardware, or filesystems.
- **Failure Behavior**: Returns error codes on malformed structures; fails closed without mutating state.
- **Evidence**: Known-answer test evaluation suites and deterministic `SemanticId` logs.

#### 3. AIENOS System Store v1
- **Owner**: `aienos` (Kernel Store subsystem)
- **Boundary**: Fixed 4096-byte unit append-only block storage over NVMe; content-addressed `ObjectId` hashing; owns Superblocks, Catalogs, and CommitRecords.
- **Failure Behavior**: Read errors yield `MountError::Io`; corrupted bytes yield `MountError::Corrupt`; never auto-formats or repairs.
- **Evidence**: Superblock transaction receipts and Store unit extent maps.

#### 4. AIENOS Continuity Subsystem
- **Owner**: `aienos` (Kernel Continuity subsystem)
- **Boundary**: Tracks `AgentRoot` and `ContinuityManifest` chains; manages single-agent identity and incarnation progression.
- **Failure Behavior**: Unprovisioned halts with `UNPROVISIONED`; multi-root halts with `CONFLICT`; broken chains halt with `CORRUPT`.
- **Evidence**: `CONTINUITY: RESUMED agent=<id> incarnation=<n> sequence=<s>`.

#### 5. FORGE Machine Realizer
- **Owner**: `physics` (FORGE)
- **Boundary**: Lowers abstract Omega programs to concrete hardware schedules (CPU / Blackwell GPU); owns VRAM allocation and DMA channels.
- **Failure Behavior**: If physical allocation fails, emits alternative realization constraints back to Omega or reports realization failure.
- **Evidence**: `FORGE_REALIZATION_SUCCESS` receipts with verified machine fact digests.

#### 6. AEGIS Invariant Verifier
- **Owner**: `aegis-runtime`
- **Boundary**: Continuous verifier spanning all state transitions; verifies reachability, bounds, non-persistence of hardware addresses, and policy compliance.
- **Failure Behavior**: Immediately blocks invalid state transitions; issues deterministic refusal receipts.
- **Evidence**: Signed verification receipts (`AEGIS_VERIFY_PASS` / `AEGIS_VERIFY_FAIL`).

#### 7. Cortex Durable Memory
- **Owner**: `cortex-rs`
- **Boundary**: Durable epistemic database; manages entity facts, vector similarity search, and evidence logs; referenced via `EpistemicRef`.
- **Failure Behavior**: Database corruption stops epistemic updates; falls back to read-only historical search.
- **Evidence**: Cryptographic fact admission receipts and vector index integrity digests.

---

### 17. Implementation Ownership Across Repositories

Future implementation work is strictly partitioned across existing repositories without introducing new repositories:

| Stage / Component | Repository | Primary Deliverables |
|---|---|---|
| **Architecture Contract** | `aien-architecture` | ADR 0015 (this document) and master plan alignment. |
| **Semantic Persistence API** | `omega` | Pure C API for canonical object validation, reachability traversal, and determinism tests. |
| **Store Bridge & Kinds** | `aienos` | Implementation of Store v1 kinds 24 & 25, write/read paths, and deduplication. |
| **Continuity Integration** | `aienos` | Extension of `ContinuityManifest` to bind `OmegaResidentRoot`, cold boot restore in kernel. |
| **Independent Verifier** | `aegis-runtime` | Implementation of `verify_resident_generation` and refusal receipts. |
| **Physical Realization** | `physics` (FORGE) | Verification of disposable GPU projections and hardware address non-persistence. |
| **Epistemic Integration** | `cortex-rs` | `EpistemicRef` handle definitions and fact promotion lifecycle. |
| **Runtime Residency** | `aien-sovereign-core` | `ResidentWorld` continuous execution lifecycle and checkpoint barriers. |
| **Store Compaction** | `aienos` | Two-region live-set migration implementation for long-lived continuous execution. |
| **Destructive Qualification** | `aien-harness` / `spark-inquisitor` | 20-step fault injection qualification suite (`AIEN_RESIDENT_CONTINUITY`). |

---

### 18. No-Premature-Implementation Rule

> **Normative Restriction**:
> **No downstream Resident Semantic Store implementation begins in any repository until ADR 0015 is formally ratified and merged into `aien-architecture`.**
> 
> Downstream builders (Builders 2 through 10) must implement strictly against the boundaries, types, and invariants frozen by this document. No builder may invent ad-hoc storage formats, alter frozen Store v1 bytes, or introduce external database dependencies.

---

### 19. Acceptance Gates for ADR 0015

This ADR is considered ready for ratification because it normatively and unambiguously settles all 15 core architectural questions:
1. **What lives only in RAM?** Dynamic goals, active reasoning state, scratchpad buffers, compiled kernel caches, and physical hardware addresses.
2. **What can survive reboot?** Immutable `DURABLE` Store v1 objects (`AgentRoot`, `ContinuityManifest`, `OmegaResidentRoot`, canonical semantic objects, Cortex checkpoints).
3. **What is immutable?** All committed Store v1 objects, historical generations, and canonical semantic bytes.
4. **What is mutable?** Active `ResidentWorld` working memory in volatile RAM (prior to commit freeze).
5. **What identifies a semantic object?** `SemanticId` = SHA-256 of canonical Omega wire encoding (`OMG0`).
6. **What identifies a durable generation?** The cryptographic digest of `ContinuityManifest` and monotonic generation number published in the active Superblock.
7. **What is the single durability commit point?** The hardware-flushed publication of the active Superblock (Unit 0 $\leftrightarrow$ Unit 1).
8. **What happens on power loss at every stage?** Defined in Section 6 & 15; state remains cleanly at the prior committed generation or cleanly advances to the new generation.
9. **How is the newest valid generation selected?** Mount evaluates Superblocks A and B, verifies checksums, and selects the highest valid generation number.
10. **What is reconstructed rather than restored?** Graph adjacency indexes, lookup tables, runtime task queues, memory allocators, GPU VAs, and device channels.
11. **What authority must be re-derived after reboot?** All runtime capabilities, hardware access rights, and execution tokens are re-issued by AEGIS from durable policy.
12. **How does Cortex relate to resident state?** Distinct epistemic store referenced via immutable, typed `EpistemicRef` handles.
13. **How does GPU state get reconstructed?** Freshly compiled and allocated by FORGE as disposable projections with new hardware addresses.
14. **What evidence proves successful recovery?** Bit-for-bit `SemanticId` recalculation across all reachable objects and valid `CONTINUITY: RESUMED` log receipt.
15. **Can any stale pointer/handle cross reboot?** **NO.** Strictly prohibited without exception.

---

## Consequences

### Positive Consequences
- **Complete Decoupling**: AIEN's intelligence is formally liberated from physical silicon placement.
- **Crash Immunity**: The system can lose power at any microsecond and guarantee zero corruption of committed state.
- **Clear Roadmap**: Builders 2 through 10 have exact, unambiguous technical specifications to implement.

### Negative Consequences / Tradeoffs
- **Catalog Bound**: Store v1's 4,096-entry catalog requires future live-set migration (Builder 9) before long-running continuous deployments exhaust entries.
- **Serialization Overhead**: Every state commit requires canonical sorting and cryptographic hashing of all reachable objects.

### Downstream Builders Blocked on Ratification
- **Builder 2**: Omega Semantic Persistence Builder (`aien-dev/omega`)
- **Builder 3**: AIENOS Omega Store Bridge (`aien-dev/aienos`)
- **Builder 4**: AIENOS Continuity / Resident World (`aien-dev/aienos`)
- **Builder 5**: AEGIS Resident-State Verifier (`aien-dev/aegis-runtime`)
- **Builder 6**: FORGE Machine Realization (`aien-dev/physics`)
- **Builder 7**: Cortex Integration (`aien-dev/cortex-rs`)
- **Builder 8**: AIEN Runtime Residency (`aien-dev/aien-sovereign-core`)
- **Builder 9**: Long-Lived Store / Compaction (`aien-dev/aienos`)
- **Builder 10**: Destructive Qualification (`aien-dev/aien-harness`, `aien-dev/spark-inquisitor`)
