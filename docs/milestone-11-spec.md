# Specification: Milestone 11 — Omega Library Discovery (`OMEGA_LIBRARY_DISCOVERY`)

```text
Document ID:     SPEC-OMEGA-M11
Milestone:       Milestone 11 (OMEGA_LIBRARY_DISCOVERY)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Autonomous Abstraction Discovery from Program Corpus with Verified Reuse
Status:          COMPLETE / RATIFIED (aien-dev/aien-architecture#23, aien-dev/omega#17)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4-M11) -> AIEN
```

---

## 1. Executive Summary & Core Invariants

Milestone 10 established the program library substrate (`OMEGA_LIBRARY_V1`), providing content-addressed component cataloging, typed contracts, dependency DAG tracking, and baseline synthesis primitive export.
Milestone 11 establishes autonomous abstraction discovery (`OMEGA_LIBRARY_DISCOVERY`):

> **RECURRING STRUCTURE IS DISCOVERED, NOT BESTOWED. EVERY ABSTRACTION MUST COMPRESS EVIDENCE, PRESERVE MEANING, AND SURVIVE VERIFICATION BEFORE ENTERING THE LIBRARY.**

The objective of Milestone 11 is autonomous abstraction discovery from a verified program corpus with verified reuse. The system does not rely on human programmers to invent reusable functions or subroutines. Instead, the discovery engine inspects synthesized and verified programs, identifies recurring computational sub-structures, abstracts them into parameterized library components, refactors the original programs, and deploys the new abstractions to solve harder held-out tasks at reduced search depth.

As mandated by canonical roadmap doctrine (`DOCTRINE-ROADMAP`), every discovered abstraction admitted under Milestone 11 must satisfy the **4 Core Invariants**:
1. **Compresses Multiple Verified Programs**: The abstraction replaces recurring sub-graphs across multiple verified programs in the corpus, achieving a strictly positive net description length / cost reduction ($\Delta \text{Cost} > 0$).
2. **Preserves Semantics Under Refactoring**: Substituting the discovered abstraction into corpus programs preserves exact input/output behavioral equivalence across all test cases.
3. **Is Reused on Held-Out Tasks**: The admitted abstraction is exported to the synthesis primitive bank and successfully leveraged to synthesize solutions for held-out tasks that were previously out-of-reach or computationally expensive.
4. **Reduces Search Cost and Depth**: Synthesis of held-out tasks using the augmented library demonstrates measurable reduction in search depth ($D' < D$) and candidate exploration count compared to baseline primitive search.

---

## 2. Discovery Engine Architecture

The Milestone 11 discovery pipeline consists of five sovereign phases:

```
+-------------------------------------------------------------------------------+
|                       OMEGA_LIBRARY_DISCOVERY PIPELINE                        |
+-------------------------------------------------------------------------------+
| 1. Corpus Ingestion    : Load verified programs into OmegaCorpus              |
| 2. Sub-Expression Mine : Mine recurring common sub-DAGs (frequency >= 2)     |
| 3. Compression Scoring : Evaluate Delta Cost = sum(orig - refactored) - abst |
| 4. Verification Ladder : Candidate passes M7 V0 (struct), V1 (diff), V2 (prop)|
| 5. Library Admission   : Insert into OmegaLibrary -> Export to Synthesis Bank |
+-------------------------------------------------------------------------------+
```

### 2.1 Corpus Representation (`OmegaCorpus`)
The discovery engine operates on an `OmegaCorpus`, an immutable collection of verified programs produced by Milestone 9 synthesis (`OMEGA_SYNTHESIS_V0`) or canonical demonstration tasks. Each corpus entry binds:
- The verified program graph ($G_S$) and instruction representation (`OmegaProgram`).
- Input/output specification test vectors and contracts.
- Provenance receipt hashes establishing Milestone 7 (`OMEGA_VERIFY`) verification passage.

### 2.2 Sub-Expression Mining
The mining engine extracts candidate abstractions from the corpus:
- Traverses program expression DAGs to enumerate contiguous sub-DAGs and compositions.
- Computes structural canonical hashes to group isomorphic and behavioral-equivalent sub-expressions.
- Enforces non-triviality: rejects single base primitives, trivial identities, or sub-expressions that already exist in the primitive bank.
- Identifies candidates with frequency $\ge 2$ across distinct programs or distinct call sites.

### 2.3 Evaluation & Minimum Description Length Metric
Candidate abstractions are ranked according to their net structural cost savings across the corpus. The objective metric is the description length / cost reduction:

$$\Delta \text{Cost} = \sum_{P \in \text{Corpus}} \left( \text{Cost}_{\text{orig}}(P) - \text{Cost}_{\text{refactored}}(P) \right) - \text{Cost}(\text{Abstraction})$$

Where:
- $\text{Cost}_{\text{orig}}(P)$ is the instruction count and complexity cost of program $P$ before refactoring.
- $\text{Cost}_{\text{refactored}}(P)$ is the cost of $P$ when recurring sub-DAGs are replaced by a single call/primitive invocation of the candidate abstraction.
- $\text{Cost}(\text{Abstraction})$ is the intrinsic cost of declaring and storing the new abstraction in the library.
- Candidate promotion strictly requires $\Delta \text{Cost} > 0$.

### 2.4 Semantic Preservation & Refactoring Engine
Refactoring replaces the identified sub-expression instances within corpus programs with invocations of the newly formed abstraction. The engine evaluates refactored programs against the original verification harness:
- Test-case equivalence: All original input/output vectors must yield bit-identical outputs.
- Invariant preservation: Contract preconditions and postconditions must remain satisfied.
- Fails closed on any behavioral divergence.

### 2.5 Verification Ladder for Library Admission
Before a candidate abstraction can be admitted into `OmegaLibrary`, it must be elevated to a first-class `OmegaProgram` and strictly pass the complete Milestone 7 (`OMEGA_VERIFY`) verification ladder:
- **$V_0$ Structural Validation**: Rejects malformed DAGs, unbound register operands, type mismatch, and invalid opcodes.
- **$V_1$ Differential Testing**: Compares native AArch64 execution against canonical reference evaluation across dense test vectors.
- **$V_2$ Property Verification**: Formally checks invariant bounds, overflow behavior, and termination guarantees.

### 2.6 Admission and Synthesis Acceleration
Upon passing $V_0-V_2$:
- The abstraction is assigned a canonical `SemanticId` and inserted into `OmegaLibrary` with dependency links.
- Library version is monotonically incremented, and the state digest is re-sealed.
- The updated library is exported to `SynthPrimitiveBank` via `omega_library_export_primitives()`.
- Subsequent synthesis runs on held-out tasks draw upon the discovered abstraction as a foundational primitive, finding solutions at reduced search depth ($D \le 2$ instead of $D \ge 4$).

---

## 3. Discovery Engine Data Model & Interfaces

```c
#define OMEGA_CORPUS_MAX_PROGRAMS 64
#define OMEGA_MAX_CANDIDATES     128
#define OMEGA_MAX_OCCURRENCES     32

typedef struct {
    OmegaProgram program;
    uint8_t proof_receipt[32];
    size_t test_case_count;
    uint64_t test_inputs[16];
    uint64_t test_expected[16];
} OmegaCorpusEntry;

typedef struct {
    size_t count;
    OmegaCorpusEntry entries[OMEGA_CORPUS_MAX_PROGRAMS];
    uint8_t corpus_digest[32];
} OmegaCorpus;

typedef struct {
    size_t program_idx;
    uint32_t start_op_idx;
    uint32_t end_op_idx;
} SubExpressionOccurrence;

typedef struct {
    SemanticId candidate_id;
    char name[64];
    OmegaProgram abstraction_prog;
    size_t occurrence_count;
    SubExpressionOccurrence occurrences[OMEGA_MAX_OCCURRENCES];
    uint32_t abstraction_cost;
    int32_t delta_cost;             /* Net compression: sum(orig - refactored) - abstraction_cost */
    bool is_nontrivial;
    bool semantics_preserved;
    VerifyReport verify_report;
} OmegaCandidateAbstraction;

typedef struct {
    uint32_t min_occurrences;       /* Minimum corpus frequency (>= 2) */
    uint32_t min_nodes;             /* Minimum sub-DAG node count (>= 2 for non-triviality) */
    int32_t min_delta_cost;         /* Minimum net compression savings (> 0) */
    bool require_v2_verification;   /* Mandatory V0-V2 gate passage */
} DiscoveryConfig;

typedef struct {
    size_t subgraphs_mined;
    size_t candidates_evaluated;
    size_t candidates_rejected_trivial;
    size_t candidates_rejected_negative_gain;
    size_t candidates_rejected_semantics;
    size_t candidates_rejected_verify;
    size_t abstractions_admitted;
} DiscoveryStats;

typedef struct {
    bool discovery_succeeded;
    OmegaCandidateAbstraction best_abstraction;
    uint32_t library_version_before;
    uint32_t library_version_after;
    uint8_t new_state_digest[32];
    DiscoveryStats stats;
} DiscoveryResult;

typedef struct {
    SynthesisTask held_out_task;
    size_t baseline_candidates_explored;
    uint32_t baseline_depth_required;
    size_t accelerated_candidates_explored;
    uint32_t accelerated_depth_required;
    bool accelerated_solved;
} DiscoveryAccelerationReport;

/* Corpus Management */
int omega_corpus_init(OmegaCorpus *corpus);
void omega_corpus_destroy(OmegaCorpus *corpus);
int omega_corpus_add(OmegaCorpus *corpus, const OmegaProgram *prog, const uint8_t receipt[32]);
int omega_corpus_compute_digest(OmegaCorpus *corpus);

/* Sub-Expression Mining & Evaluation */
int omega_discovery_mine(const OmegaCorpus *corpus, const DiscoveryConfig *config,
                         OmegaCandidateAbstraction *out_candidates, size_t max_candidates,
                         size_t *out_count);

int omega_discovery_evaluate_compression(const OmegaCorpus *corpus,
                                         OmegaCandidateAbstraction *candidate);

int omega_discovery_verify_semantics(const OmegaCorpus *corpus,
                                     const OmegaCandidateAbstraction *candidate);

/* Verification & Library Admission */
int omega_discovery_verify_candidate(OmegaCandidateAbstraction *candidate);

int omega_discovery_admit_abstraction(OmegaLibrary *lib,
                                      const OmegaCandidateAbstraction *candidate,
                                      uint8_t out_receipt_hash[32]);

/* End-to-End Discovery and Held-Out Validation */
int omega_discovery_run(const OmegaCorpus *corpus, OmegaLibrary *lib,
                        const DiscoveryConfig *config, DiscoveryResult *result);

int omega_discovery_evaluate_heldout(const OmegaLibrary *lib,
                                     const SynthesisTask *held_out_task,
                                     DiscoveryAccelerationReport *report);
```

---

## 4. Qualification Gates for M11

Milestone 11 qualification requires 100% pass across 10 canonical gates:

1. `OMEGA_DISCOVERY_CORPUS_MINING_PASS`: Sub-expression mining traverses `OmegaCorpus` programs and identifies recurring sub-DAG patterns with frequency $\ge 2$.
2. `OMEGA_DISCOVERY_NONTRIVIAL_PASS`: Candidate abstraction is non-trivial (contains $\ge 2$ primitive operations; is not an identity, single constant, or already present in base primitives).
3. `OMEGA_DISCOVERY_COMPRESSION_PASS`: Description length / cost reduction metric evaluates strictly positive ($\Delta \text{Cost} > 0$), confirming measurable corpus compression.
4. `OMEGA_DISCOVERY_SEMANTIC_PRESERVATION_PASS`: Corpus programs refactored with the candidate abstraction preserve bit-exact input/output behavior across all test cases.
5. `OMEGA_DISCOVERY_V0_STRUCTURAL_PASS`: Candidate abstraction passes M7 $V_0$ structural validation (well-formed DAG, type correctness, register bounds).
6. `OMEGA_DISCOVERY_V1_DIFFERENTIAL_PASS`: Candidate abstraction passes M7 $V_1$ differential evaluation against native AArch64 execution.
7. `OMEGA_DISCOVERY_V2_PROPERTY_PASS`: Candidate abstraction passes M7 $V_2$ invariant and property checking.
8. `OMEGA_DISCOVERY_LIBRARY_ADMISSION_PASS`: Discovered abstraction is admitted into `OmegaLibrary`, increments version, seals state digest, and exports to `SynthPrimitiveBank`.
9. `OMEGA_DISCOVERY_SEARCH_ACCELERATION_PASS`: Synthesis on a held-out task using the updated primitive bank finds a verified solution at reduced search depth ($D' < D$) and candidate count.
10. `OMEGA_DISCOVERY_RECEIPT_PASS`: Master qualification runner produces an immutable cryptographic receipt recording corpus hash, abstraction ID, compression metric, verification proofs, and search acceleration evidence.
