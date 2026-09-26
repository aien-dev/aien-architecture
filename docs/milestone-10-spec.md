# Specification: Milestone 10 — Omega Library V1 (`OMEGA_LIBRARY_V1`)

```text
Document ID:     SPEC-OMEGA-M10
Milestone:       Milestone 10 (OMEGA_LIBRARY_V1)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Versioned Procedural Program Library, Provenance Tracking, and Component Catalog
Status:          COMPLETE / RATIFIED (aien-dev/aien-architecture#22, aien-dev/omega#16)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4-M10) -> AIEN
```

---

## 1. Executive Summary & Core Invariants

Milestone 9 established sovereign program synthesis (`OMEGA_SYNTHESIS_V0`), discovering verified programs from input/output specifications.
Milestone 10 establishes the **sovereign program library substrate** (`OMEGA_LIBRARY_V1`):

> **DISCOVERED MEANINGS ARE ACCUMULATED, NOT FORGOTTEN. EVERY COMPONENT IS IMMUTABLY INDEXED, PROVENANCE-LINKED, AND VERIFIED.**

The `OMEGA_LIBRARY` substrate provides:
1. **Content-Addressed Catalog**: Programs indexed by canonical `SemanticId` (Program ID) and `RealizationId` with constant-time retrieval.
2. **Contract-Based Semantic Query**: Search and filter components by typed signatures (input/output types, bit widths, precondition/postcondition constraints).
3. **Dependency DAG Tracking**: Composite programs declare explicit dependencies on constituent components, forming an acyclic dependency graph with cycle detection.
4. **Immutable Versioned State**: Library evolution is tracked via monotonic versions ($v_1, v_2, \dots$); a SHA-256 state digest seals the library catalog at every version.
5. **Fail-Closed Verification Gate**: Only programs that have passed the full M7 verification ladder ($V_0, V_1, V_2$) with valid receipts are admitted into the library.
6. **Synthesis Reuse**: The synthesis engine can consume an `OmegaLibrary` as its primitive bank, reusing existing verified abstractions to solve higher-level tasks at lower search depths.

---

## 2. Library Data Model & Interfaces

```c
#define OMEGA_LIB_MAX_PROGRAMS 128
#define OMEGA_LIB_MAX_DEPS 8

typedef struct {
    OmegaProgram program;
    uint32_t version_introduced;
    uint64_t timestamp_added;
    size_t dep_count;
    SemanticId dependency_ids[OMEGA_LIB_MAX_DEPS];
    uint8_t evidence_receipt_hash[32];
} OmegaLibraryEntry;

typedef struct {
    uint32_t version;
    size_t count;
    OmegaLibraryEntry entries[OMEGA_LIB_MAX_PROGRAMS];
    uint8_t state_digest[32];
} OmegaLibrary;

int omega_library_init(OmegaLibrary *lib);
void omega_library_destroy(OmegaLibrary *lib);

/* Insert a verified program into the library. Fails if unverified or duplicate. */
int omega_library_insert(OmegaLibrary *lib, const OmegaProgram *prog,
                         const SemanticId *deps, size_t dep_count,
                         const uint8_t receipt_hash[32]);

/* Content-addressed lookup */
const OmegaLibraryEntry* omega_library_find_by_id(const OmegaLibrary *lib, const SemanticId *prog_id);

/* Semantic query: find all programs matching input/output types and width */
size_t omega_library_query_by_type(const OmegaLibrary *lib,
                                   TypeTag in_type, uint16_t in_width,
                                   TypeTag out_type, uint16_t out_width,
                                   const OmegaLibraryEntry **out_results, size_t max_results);

/* Compute cryptographic checksum over entire library catalog */
int omega_library_compute_digest(OmegaLibrary *lib);

/* Advance version and seal state */
int omega_library_advance_version(OmegaLibrary *lib);
```

---

## 3. Qualification Gates for M10

1. `OMEGA_LIBRARY_INIT_PASS`: Library initialized with version 1, empty catalog, and zeroed digest.
2. `OMEGA_LIBRARY_INSERT_PASS`: Verified programs inserted into the catalog with complete metadata.
3. `OMEGA_LIBRARY_LOOKUP_ID_PASS`: O(1) content-addressed retrieval by `SemanticId`.
4. `OMEGA_LIBRARY_LOOKUP_TYPE_PASS`: Semantic query by type contracts returns matching component entries.
5. `OMEGA_LIBRARY_DEPENDENCY_DAG_PASS`: Composite program dependencies recorded and topologically validated without cycles.
6. `OMEGA_LIBRARY_IMMUTABILITY_PASS`: Cryptographic state digest seals library contents; tampering is detected.
7. `OMEGA_LIBRARY_UNVERIFIED_REFUSAL_PASS`: Unverified programs or programs lacking verification pass are rejected fail-closed.
8. `OMEGA_LIBRARY_DUPLICATE_REFUSAL_PASS`: Duplicate insertions of identical `SemanticId` rejected fail-closed.
9. `OMEGA_LIBRARY_SYNTHESIS_REUSE_PASS`: Synthesis engine queries library components as primitives to discover solutions at reduced depth.
10. `OMEGA_LIBRARY_RECEIPT_PASS`: Qualified library demonstration produces cryptographic evidence receipt with full provenance.
