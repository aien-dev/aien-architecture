# Specification: Milestone 13 — Omega Machine Graph (`OMEGA_MACHINE_GRAPH`)

```text
Document ID:     SPEC-OMEGA-M13
Milestone:       Milestone 13 (OMEGA_MACHINE_GRAPH)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Formal Machine Hardware Graph ($G_M$) Describing Execution Pipelines and Memory Hierarchies
Status:          COMPLETE / RATIFIED (aien-dev/aien-architecture#24, aien-dev/omega#18)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4-M13) -> AIEN
```

---

## 1. Executive Summary & Foundational Doctrine

Milestone 12 established adaptive realization selection across varying input regimes and cache dynamics (`OMEGA_LIVING_MATVEC`).
Milestone 13 establishes the formal machine hardware graph substrate (`OMEGA_MACHINE_GRAPH`):

> **PHYSICS GOVERNS THE MACHINE; OMEGA MODELS ITS CAPACITIES. THE MACHINE GRAPH $G_M$ EXPOSES PHYSICAL REALITY AS AN AUTHORITATIVE, IMMUTABLE REASONING SURFACE WITHOUT DEFILING PURE SEMANTICS.**

In sovereign architecture:
- **Semantic Graph ($G_S$)** (Milestone 4, `OMEGA_SEMANTICS`): Defines pure mathematical and computational meaning without committing that meaning to a physical machine representation.
- **Machine Hardware Graph ($G_M$)** (Milestone 13, `OMEGA_MACHINE_GRAPH`): Formally describes the physical execution pipelines, functional compute units, register files, and cache/memory hierarchy topologies as reported by Physics.
- **Realization Graph ($G_R$)** (Milestone 14, `OMEGA_REALIZATION_SYNTHESIS`): Synthesized through the formal mapping $G_S \times G_M \to G_R$, matching semantic execution structures to physical hardware capabilities and cost curves.

The machine graph $G_M$ is not an operating system device tree, an emulated virtual machine, or an informal configuration file. It is a strictly typed, topologically validated, content-addressed mathematical graph that models hardware constraints as first-class reasoning surfaces.

---

## 2. Core Doctrine & Invariants

As mandated by canonical roadmap doctrine (`DOCTRINE-ROADMAP`), the machine graph substrate satisfies five foundational invariants:

1. **Physics Authority Ingress**: $G_M$ is derived from verified physical machine descriptors provided by Physics (Milestone 2 `PHYSICS_BOOT`, Milestone 3 `PHYSICS_EFFECTS` authority). Omega never guesses hardware capabilities, queries unauthorized control registers, or runs heuristics. Every machine graph carries a cryptographic seal binding it to a Physics execution receipt.
2. **Canonical Hardware Identity (`MACHINE_ID`)**: Every distinct machine topology possesses a deterministic SHA-256 state digest computed over a canonical wire encoding (`OMG0` format with `KIND_MACHINE = 0x07`). Identical physical configurations yield bit-identical `MACHINE_ID`s across independent runs.
3. **Structural Completeness**: $G_M$ explicitly models all hardware resources necessary for execution scheduling and latency evaluation:
   - Execution pipelines: issue width, maximum in-flight window, dispatch order (in-order vs. out-of-order).
   - Functional compute units: dedicated modeling of ALU, BRANCH, MULTIPLIER, DIVIDER, LOAD_STORE, VECTOR, and ACCELERATOR_PORT units with unit count, issue latency, and throughput per cycle.
   - Register files: General Purpose Registers (GPR count and bit-width) and Vector registers (count and bit-width).
   - Memory hierarchy: Multi-tier caches (L1I, L1D, L2, L3) with capacity, line size, associativity, and cycle access latency, alongside physical DRAM base address and size.
4. **Topology Differential**: Distinct hardware targets produce distinct `MACHINE_ID`s. Heterogeneous microarchitectures (e.g., NVIDIA DGX Spark Neoverse V2 vs QEMU generic AArch64) produce provably distinct cryptographic identities, preventing cross-target realization contamination.
5. **Realization Foundation**: $G_M$ supplies empirical cycle latency and resource cost models utilized by Milestone 14 realization synthesis (`OMEGA_REALIZATION_SYNTHESIS`, $G_S \times G_M \to G_R$). Realization synthesis leverages $G_M$ to schedule instructions, optimize issue-slot occupancy, and avoid pipeline stalls.

---

## 3. Machine Hardware Graph Topology & Ingress

### 3.1 Architectural Structure

```text
+-------------------------------------------------------------------------------+
|                       PHYSICS AUTHORITY HARDWARE INGRESS                      |
|  PhysicsDescriptor (Magic: 0x4D414348 'MACH', Profile, Seals, Physical Caps)  |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼  omega_machine_ingest_physics_descriptor()
+-------------------------------------------------------------------------------+
|                     OMEGA MACHINE GRAPH (G_M) ARCHITECTURE                    |
+-------------------------------------------------------------------------------+
|  1. Identity & Profile : Name, Target Profile, Deterministic MACHINE_ID       |
|  2. Execution Pipeline : Issue Width, Out-of-Order Window, Unit Capacities    |
|                          - ALU Units          (Count, Latency, Throughput)    |
|                          - Multiplier Units   (Count, Latency, Throughput)    |
|                          - Vector / SIMD      (Count, Latency, Throughput)    |
|                          - Branch / Jump      (Count, Latency, Throughput)    |
|                          - Load / Store Ports (Count, Latency, Throughput)    |
|  3. Register File      : GPRs (31 x 64-bit), Vector Regs (32 x 128/256-bit)   |
|  4. Memory Hierarchy   : L1I Cache -> L1D Cache -> L2 Cache -> L3 Cache       |
|                          (Monotonic hierarchy, line sizes, latencies)         |
|  5. Coherent Memory    : DRAM Base Address, Total Capacity (Bytes)            |
|  6. Authority Seal     : Physics Authority Seal (32-byte cryptographic seal)  |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼  omega_machine_compute_id()
+-------------------------------------------------------------------------------+
|               CANONICAL HARDWARE IDENTITY: SHA-256 (OMG0 SERIALIZATION)       |
+-------------------------------------------------------------------------------+
```

### 3.2 Canonical Target Profiles

Milestone 13 establishes two reference hardware topologies:

1. **NVIDIA DGX Spark Grace Profile (`NVIDIA_DGX_SPARK_GRACE_V2`)**:
   - Microarchitecture: ARM Neoverse V2 core.
   - Pipeline: 4-wide dispatch, 256 instructions max in-flight, out-of-order execution.
   - Functional Units: 4x ALU (1-cycle latency), 2x Branch (1-cycle latency), 2x Multiplier (3-cycle latency), 1x Divider (12-cycle latency), 2x Load/Store (3-cycle latency), 4x Vector/SIMD (2-cycle latency).
   - Register Files: 31x 64-bit GPRs (X0-X30), 32x 128-bit Vector registers (V0-V31).
   - Cache Hierarchy: 64KB 4-way L1I (3-cycle latency), 64KB 8-way L1D (4-cycle latency), 1MB 8-way L2 (10-cycle latency), 114MB 16-way L3 (35-cycle latency).
   - Coherent DRAM: 128 GB LPDDR5X at physical base `0x80000000`.

2. **QEMU Virt AArch64 Baseline Profile (`QEMU_VIRT_AARCH64_GENERIC`)**:
   - Microarchitecture: Generic AArch64 emulation core.
   - Pipeline: 2-wide dispatch, 64 instructions max in-flight, in-order execution.
   - Functional Units: 2x ALU (1-cycle latency), 1x Branch (1-cycle latency), 1x Multiplier (4-cycle latency), 1x Load/Store (4-cycle latency), 2x Vector/SIMD (3-cycle latency).
   - Register Files: 31x 64-bit GPRs, 32x 128-bit Vector registers.
   - Cache Hierarchy: 32KB 2-way L1I (2-cycle latency), 32KB 4-way L1D (3-cycle latency), 512KB 8-way L2 (12-cycle latency).
   - Coherent DRAM: 1 GB at physical base `0x40000000`.

### 3.3 Topological Consistency & Cycle Prevention

The machine graph engine enforces topological invariant checks via `omega_machine_validate_topology()`:
- **Cache Monotonicity**: Cache levels must strictly increase monotonically ($L_1 \le L_2 \le L_3$). Inverted cache hierarchies or duplicate unified levels are rejected.
- **Cache Line Power-of-Two**: Every cache line size must be a non-zero power of two (typically 64 bytes).
- **Acyclic Memory DAG**: Memory hierarchy references must form a strict tree/DAG terminating in coherent DRAM without cycles.
- **Architectural Register Integrity**: For AArch64 profiles, GPR count must equal exactly 31 registers with 64-bit width.
- **Non-Zero Pipeline Capacities**: Pipeline issue width and functional unit counts must be strictly positive.

### 3.4 Latency & Execution Cost Modeling

$G_M$ provides an analytical cost function `omega_machine_estimate_latency()` that accepts a compiled machine code realization (`RealizationObject`) and models cycle execution latency:
- Decodes machine instructions into operation classes (ALU, MUL, LOAD/STORE, BRANCH, VECTOR).
- Maps each instruction to the corresponding functional unit latency declared in $G_M$.
- Models pipeline issue folding: $\text{Folded Cycles} = \lceil \text{Instruction Count} / \text{Issue Width} \rceil$.
- Total cycle latency accounts for structural hazards and unit latencies, providing the empirical cost metric required for Milestone 14 realization synthesis.

---

## 4. Data Model & C API Declarations

```c
#ifndef OMEGA_MACHINE_H
#define OMEGA_MACHINE_H

#include "omega_types.h"
#include "omega_realize.h"
#include <stdbool.h>
#include <stddef.h>

#define OMEGA_MACHINE_MAX_UNITS  8
#define OMEGA_MACHINE_MAX_CACHES 8

typedef enum {
    UNIT_ALU = 0,
    UNIT_BRANCH = 1,
    UNIT_MULTIPLIER = 2,
    UNIT_DIVIDER = 3,
    UNIT_LOAD_STORE = 4,
    UNIT_VECTOR = 5,
    UNIT_ACCELERATOR_PORT = 6
} ComputeUnitType;

typedef struct {
    ComputeUnitType type;
    uint32_t count;
    uint32_t latency_cycles;
    uint32_t throughput_per_cycle;
} MachineComputeUnit;

typedef struct {
    uint32_t issue_width;
    uint32_t max_in_flight;
    bool out_of_order;
    size_t unit_count;
    MachineComputeUnit units[OMEGA_MACHINE_MAX_UNITS];
} MachinePipeline;

typedef struct {
    uint32_t gpr_count;         /* 31 for AArch64 X0-X30 */
    uint32_t gpr_width_bits;    /* 64-bit */
    uint32_t vector_count;      /* 32 for V0-V31 */
    uint32_t vector_width_bits; /* 128-bit for NEON / 256+ for SVE */
} MachineRegisterFile;

typedef struct {
    uint32_t level;             /* 1 = L1, 2 = L2, 3 = L3 */
    bool is_instruction;
    uint64_t size_bytes;
    uint32_t line_size_bytes;
    uint32_t associativity;
    uint32_t latency_cycles;
} MachineCacheLevel;

typedef struct {
    SemanticId machine_id;
    char name[64];
    uint8_t target_profile;
    MachinePipeline pipeline;
    MachineRegisterFile registers;
    size_t cache_count;
    MachineCacheLevel caches[OMEGA_MACHINE_MAX_CACHES];
    uint64_t dram_base;
    uint64_t dram_size;
    bool is_physics_authorized;
    uint8_t physics_receipt_seal[32];
} OmegaMachineGraph;

/* Raw physical machine descriptor packet ingested from Physics */
typedef struct {
    uint32_t magic;             /* 0x4D414348 = 'MACH' */
    uint16_t version;
    uint16_t target_profile;
    char cpu_name[32];
    uint32_t issue_width;
    uint32_t gpr_count;
    uint32_t vec_count;
    uint64_t l1d_size;
    uint64_t l2_size;
    uint64_t l3_size;
    uint64_t dram_base;
    uint64_t dram_size;
    uint8_t physics_seal[32];
} MachineDescriptor;

typedef MachineDescriptor PhysicsDescriptor;

/* Machine Graph Initialization & Canonical Identity */
void omega_machine_init(OmegaMachineGraph *mg, const char *name, uint8_t target_profile);
int omega_machine_compute_id(OmegaMachineGraph *mg);

/* Target Topology Builders */
int omega_machine_build_dgx_spark(OmegaMachineGraph *mg);
int omega_machine_build_qemu_virt(OmegaMachineGraph *mg);

/* Physics Ingress & Validation */
int omega_machine_ingest_physics_descriptor(OmegaMachineGraph *mg, const MachineDescriptor *desc);
int omega_machine_validate_topology(const OmegaMachineGraph *mg, char *err_msg, size_t err_msg_len);

/* Cost & Latency Evaluation */
uint32_t omega_machine_estimate_latency(const OmegaMachineGraph *mg, const RealizationObject *real);

#endif /* OMEGA_MACHINE_H */
```

---

## 5. The 10 Qualification Gates

Milestone 13 qualification requires 100% pass across 10 canonical gates:

1. `OMEGA_MACHINE_INIT_PASS`: Machine graph initializes cleanly with valid target name, designated execution profile, and zero-initialized memory structures.
2. `OMEGA_MACHINE_PIPELINE_PASS`: Multi-unit execution pipeline is fully modeled, specifying issue width, in-flight window, dispatch order, and unit-specific cycle latencies.
3. `OMEGA_MACHINE_REGISTER_FILE_PASS`: Register file capacities and widths are validated (31 64-bit GPRs, 32 128-bit Vector registers for AArch64 targets).
4. `OMEGA_MACHINE_MEMORY_HIERARCHY_PASS`: Multi-tier cache hierarchy (L1I, L1D, L2, L3) is accurately constructed with explicit capacities, line sizes, associativity, and access latencies.
5. `OMEGA_MACHINE_PHYSICS_INGRESS_PASS`: Physical descriptor packet is ingested from Physics, verifying descriptor magic (`0x4D414348`), parameter bounds, and cryptographic authority seal.
6. `OMEGA_MACHINE_CANONICAL_ID_PASS`: Deterministic bit-for-bit `MACHINE_ID` generation via SHA-256 over canonical `OMG0` wire-format serialization.
7. `OMEGA_MACHINE_TOPOLOGY_DIFFERENCE_PASS`: Distinct hardware microarchitectures (NVIDIA DGX Spark Neoverse V2 vs. QEMU virt AArch64) generate distinct, collision-free `MACHINE_ID`s.
8. `OMEGA_MACHINE_CYCLE_PREVENTION_PASS`: Topological validator rejects cyclic memory dependencies, inverted cache hierarchies, non-power-of-two line sizes, and invalid issue widths.
9. `OMEGA_MACHINE_COST_EVALUATION_PASS`: Execution latency estimator accurately models realization execution cycles, correctly accounting for opcode latencies and pipeline issue folding.
10. `OMEGA_MACHINE_RECEIPT_PASS`: Master qualification runner executes all test assertions and generates an immutable cryptographic receipt recording machine identity, topology hash, and gate results.

---

## 6. Provenance & Qualification Evidence

Upon execution of the Milestone 13 test harness (`tests/run_m13_gates.sh`), the system emits a signed qualification receipt into `evidence/omega_machine_qualification_receipt.json`.

```json
{
  "milestone": "OMEGA_MACHINE_GRAPH",
  "document_id": "SPEC-OMEGA-M13",
  "status": "QUALIFIED",
  "machine_id_dgx_spark": "e4a2...<64-hex>",
  "machine_id_qemu_virt": "c8f1...<64-hex>",
  "topology_difference_verified": true,
  "physics_authority_seal_verified": true,
  "gates": {
    "OMEGA_MACHINE_INIT_PASS": "PASS",
    "OMEGA_MACHINE_PIPELINE_PASS": "PASS",
    "OMEGA_MACHINE_REGISTER_FILE_PASS": "PASS",
    "OMEGA_MACHINE_MEMORY_HIERARCHY_PASS": "PASS",
    "OMEGA_MACHINE_PHYSICS_INGRESS_PASS": "PASS",
    "OMEGA_MACHINE_CANONICAL_ID_PASS": "PASS",
    "OMEGA_MACHINE_TOPOLOGY_DIFFERENCE_PASS": "PASS",
    "OMEGA_MACHINE_CYCLE_PREVENTION_PASS": "PASS",
    "OMEGA_MACHINE_COST_EVALUATION_PASS": "PASS",
    "OMEGA_MACHINE_RECEIPT_PASS": "PASS"
  }
}
```
