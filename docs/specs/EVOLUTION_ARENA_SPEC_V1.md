# Specification: Evolution Arena V1 (`EVOLUTION_ARENA_V1_PASS`)

| Field | Value |
|---|---|
| Document ID | SPEC-ARENA-V1 |
| Program | Evolution Arena (research program: `docs/research/evolution-arena-program.md`) |
| Classification | Frozen contract. Docs only. No runtime change is authorized by this document. |
| Status | PROPOSED (draft for orchestrator review) |
| Opened | 2026-09-29 |
| Authority | ARCH-0016 (resident reaction architecture), ARCH-0015 (Resident Semantic Store), ARCH-0014 (FORGE realizes, AEGIS verifies), ARCH-0007 (J-Space effect boundary), OS-0012 (self-construction, capability growth, generations), ARCH-0017 (ARGUS defensive plane; on branch, not yet on main) |
| Lineage | Omega `OMEGA_COGNITIVE_ROUTING_PASS` (#57), `OMEGA_PLAN_REUSE_PASS` (#58), `OMEGA_EMPIRICAL_OPTIMIZER_PASS` (#60, open), R9 generation barrier (`rx_generation`), physics #13 FORGE-0 / FORGE-HWID (open) |

---

## 0. What this document freezes, and what it does not

This specification freezes exactly five things:

1. the **Candidate** object,
2. the **Lineage** model,
3. the **Evaluation** contract,
4. the **Promotion** contract,
5. the **first flagship experiment** and its pass criteria.

Everything else in the research document (Cortex epistemics, the machine self-model, analog substrates, search-policy evolution, Physics Zero) is explicitly **out of scope for V1** and is not constrained here.

Changing any frozen item after a candidate has been generated against it requires a new spec commit and a full rerun of the affected experiment (same rule as every pre-registered gate in this project).

### 0.1 Activation hold

Nothing in this document may become runtime behaviour until all of the following are true. This is the same hold the research document states, restated with today's status (2026-09-29):

| Prerequisite | Status today | Closes when |
|---|---|---|
| R16 orchestrator retirement | W2/W4 done, W5 not done; omega #68 is a draft | `R16_ORCHESTRATOR_RETIRED` receipt on omega main |
| FORGE v1 boundary | physics #13 (FORGE-0 seam, FORGE-HWID probe) open | physics #13 merged with its Gate 3 / Gate 4 receipts |
| Authority instance identity across restart | replay determinism proven; instance identity is an open ABI v2 question (D7, MachineId decision pending) | D7 decided and receipted |
| ARGUS-0 | complete under documented limits (+3.87 % R8 with a spare core) | already acceptable; ARGUS-1 continues in parallel |
| Omega empirical optimizer | omega #60 open, unmerged | #60 merged (its arm / judge / learner vocabulary becomes canonical) |

Until then: schemas, receipts formats and this contract may be written and reviewed. No Arena code runs on the Spark.

### 0.2 Reading rules

- Words in `code` are existing identifiers on main (omega `rx_generation.{h,c}`, ARCH-0016 §52–53, ADR 0015). Words in **bold** are terms this spec defines. Nothing here renames an existing identifier.
- "FORGE" in this document always means the ARCH-0014 machine realization engine. The OS-0012 "AIEN FORGE" (self-construction machinery) is referred to here as **self-construction**; the Arena is a bounded instance of it.
- "World" without qualifier means the single generation-addressed object world of ARCH-0016 §13. A J-Space **draft World** (docs/08, ARCH-0007) is a speculative branch inside it whose results are Ephemeral state until promoted.
- "Generation" without qualifier means the ARCH-0016 / `rx_generation` World generation that the R9 barrier commits through the ADR 0015 ordered commit protocol. The OS-0012 whole-machine Generation and the Store v1 durability generation are named as such when they appear.

---

## 1. Doctrine the Arena inherits

The Arena adds no new authority and no new loop. It composes existing faculties, in the doctrine order which is a statement of responsibilities, not a turn order (ARCH-0016 §57–66):

```text
ATLAS AWAKENS. AIEN PROPOSES. OMEGA DEFINES. FORGE REALIZES.
AEGIS VERIFIES. HARDWARE ACTS. EVIDENCE TEACHES.
```

Restated for the Arena:

| Faculty | Arena role | May not |
|---|---|---|
| AIEN | publishes typed proposals (`Hypothesis`, `PlanCandidate`) that become Candidates | promote, grade, or alter the evaluation contract |
| J-Space | forks draft Worlds, keeps score dimensions separate, prunes dominated Candidates, retains counterfactuals | externalize effects (ARCH-0007), commit anything |
| OMEGA | applies typed mutations to semantic programs; verification stays separate from selection ("REALIZE VERIFY MEASURE RECORD SELECT") | realize outside the Candidate's declared surface |
| FORGE | realizes verified Omega programs on declared substrates, reports constraints and alternatives | act as gatekeeper, self-authorize |
| AEGIS | verifies realization faithfulness and invariants; authors `PolicyDecision` / `CapabilityRequest`; states promotion requirements | mint capabilities (only the AIENOS root mints), execute the promotion itself |
| Evidence | immutable, content-addressed receipts bound to hardware identity | be edited, be replaced by prose or model confidence |
| Cortex | admits claims through candidate → evidence → Signed Admission Receipt | own the speculative lifecycle, feed hard-invariant decisions (ARCH-0017 §2.3) |
| Promotion right holder | the only principal that can call `rx_gen_promote` | be the proposer; delegate the right |
| ARGUS | observes; emits `ArgusFinding`s | write World objects, take part in the promotion decision |

Hard rules carried over verbatim in force (see ARCH-0016 §3, §54; OS-0012 rules 3–6, 10):

- INTELLIGENCE ≠ AUTHORITY. The World may reference capabilities; it may not invent them.
- I9: intelligence cannot promote itself past authority policy.
- I10: failed optimization cannot destroy the last-known-good realization.
- I16: semantic meaning remains stable across realization changes.
- THE SYSTEM HAS NO SEMANTIC MASTER LOOP. Each Arena stage is a dependency-ready reaction, not a step in a scheduler.
- Repeated failed repairs stop and are reported; there is no endless self-modification loop.

---

## 2. The Candidate object (frozen)

A **Candidate** is an immutable, content-addressed experimental descendant of an active method. It is the Arena's unit of proposal and the same object the RSI evaluation flow (docs/09) calls a Candidate; the Arena is that flow moved in-band.

A Candidate is realized in the runtime as an `RxGenDraft` (omega `rx_generation.h`) whose blobs are populated as follows. No new blob kinds are introduced in V1.

| `RxGenDraft` blob | Arena content |
|---|---|
| `provenance` | the **CandidateHeader** below, canonical little-endian, digest = `candidate_id` |
| `realization` | the Omega program plus the FORGE realization plan (a `ForgeVerifiedRealization` once sealed) |
| `config` | mutation parameters (tile size, unroll factor, arm selection, …) |
| `model` | unused in V1 (reserved for learned components; forbidden mutation surface) |
| `evidence` | root digest of the Candidate's own Evidence packages (§4.4) |
| `objects` | World object refs the Candidate reads; never capability refs it did not hold |

### 2.1 CandidateHeader

```text
CandidateHeader v1 {
    schema             = "AIEN_ARENA_CANDIDATE_V1"
    candidate_id       : sha256 of this header with candidate_id zeroed
    parent_ids[]       : 0..2 candidate_ids (0 = human-supplied baseline; 2 = recombination)
    lineage_root       : candidate_id of the baseline this lineage descends from
    mutation_class     : one of the typed operators in §2.3
    mutation_params    : digest of the `config` blob
    objective_id       : digest of the frozen Evaluation contract (§4) the Candidate is answering
    semantic_digest    : Omega semantic digest of the program (must equal the parent's; I16)
    realization_digest : digest of the `realization` blob
    proposed_by        : principal id (subject) of the proposing reaction
    proposed_at_gen    : active generation id at proposal time
    required_caps[]    : capability ids the Candidate needs to run in its draft World
    resource_limits    : {cpu_ms, gpu_ms, bytes, joules} ceilings; hard, enforced by R5/R6
    substrate_scope    : declared substrate list (Grace CPU | Blackwell | …) for FORGE
}
```

Rules:

- `candidate_id` is content-addressed. Two proposals with identical headers are one Candidate.
- The header is written once, before any evaluation. A Candidate that has seen an evaluation result cannot change any header field; a "fixed" version is a new Candidate with `parent_ids = [old]`.
- `semantic_digest` must equal the parent's semantic digest. A Candidate that changes meaning is not a Candidate; it is REJECTED at VERIFIED (I16).
- `required_caps[]` may only list capabilities the proposer already holds. A Candidate cannot request wider authority for itself.
- `proposed_by` is checked by `rx_gen_promote`: the promoter's subject must differ from it (existing `RX_GEN_ERR_AUTHORITY` refusal).

### 2.2 Lifecycle

Candidate status is derived from Evidence, never set by the Candidate. It maps onto existing reaction and generation outcomes:

```text
PROPOSED    header written; RxGenDraft created via rx_gen_propose
   ↓
REALIZED    FORGE produced a realization for every declared substrate, or reported why not
   ↓
VERIFIED    OMEGA semantic check + AEGIS invariant check both PASS; realization sealed
   ↓         (FAIL → REJECTED; sealed realization mutated → REJECTED, NEG_POST_VERIFICATION_MUTATION_REFUSED)
EVALUATING  running in its draft World against training + validation workloads
   ↓
EVALUATED   all pre-registered measurements recorded as Evidence
   ↓
ELIGIBLE    meets the promotion threshold on validation; may be graded on the sealed holdout once
  ↙       ↘
ARCHIVED    PROMOTED   (rx_gen_promote committed through the R9 barrier)
```

Terminal statuses: `REJECTED`, `ARCHIVED`, `PROMOTED`, plus `STALE` (parent generation is no longer active; `RX_GEN_ERR_STALE`) and `BUDGET_EXHAUSTED` (resource_limits hit; R6). Every terminal status is Evidence and is retained (§3).

### 2.3 Typed mutation operators (V1 allowed surface)

V1 permits exactly these mutation classes. Each is a semantic transformation Omega can name; none is a textual source edit.

```text
CHANGE_REALIZATION        pick a different existing verified realization (arm) for an operation
CHANGE_TILE_SIZE
CHANGE_UNROLL_FACTOR
CHANGE_MEMORY_LAYOUT
SPECIALIZE_FOR_SHAPE
FUSE_OPERATIONS
SPLIT_OPERATION
ALTER_COST_MODEL          change parameters of the empirical cost model (omega #60 working copy)
RECOMBINE                 two parents, one child; both parents must be VERIFIED or better
```

Forbidden in V1 (not a mutation surface, a header naming one is REJECTED at PROPOSED): AEGIS policy, the capability root, the promotion right, the evaluation contract, the holdout, ARGUS, the boot chain, any `model` blob, J-Space search policy, Skills, any generated native machine code that is not already a verified realization (OS-0012 rule 5: no native admission of generated code on physical hardware before M3 enforcement).

---

## 3. The Lineage model (frozen)

The **Lineage graph** is the set of all Candidates with edges `parent_id → candidate_id` labelled by `mutation_class`. It is the ground truth; Cortex claims are derived from it and never replace it.

Rules:

1. **Append-only, forward-only.** No Candidate, edge or Evidence package is ever deleted or rewritten. This is the ADR 0015 §9 forward-only history rule applied to experiments. Archiving is a status, not a removal.
2. **Content-addressed storage.** Candidates and Evidence live as `evidence/ARENA/<sha256>.json` (omega receipt convention) with the binary blobs beside them, and are referenced from the World as `DURABLE` state (ARCH-0016 §19 / ADR 0015 §2). Draft-World working state is `EPHEMERAL`.
3. **Causal crumbs.** Every transition in §2.2 emits an R4 causal crumb naming `candidate_id`, the reaction that caused it, and the Evidence digest. Ancestry must be reconstructible from crumbs alone (R4 exit criterion reused).
4. **Failed lineages persist.** `REJECTED`, `STALE` and `BUDGET_EXHAUSTED` Candidates keep their full Evidence. Counterfactual draft Worlds (candidates that lost) keep their measured Evidence even though their World is discarded.
5. **The archive is a view, not a store.** The **Evolution archive** (champion, known-good fallback, and per-dimension best lineages) is a set of tagged references into the Lineage graph, recomputed from Evidence. Tags carry no authority.
6. **The known-good reference is always present.** Every lineage root is a human-supplied baseline that is itself VERIFIED and always eligible for selection (the omega #60 "known-good reference" arm). I10: no experiment may remove it.

Exit gate (EA-G1, §5.3): given the World's durable root, every Candidate's ancestry and every Evidence package can be reconstructed byte-for-byte on a clean machine.

---

## 4. The Evaluation contract (frozen)

An **Evaluation contract** is a pre-registered, content-addressed document that exists before the first Candidate is proposed against it. Its digest is the Candidate's `objective_id`.

### 4.1 Contents

```text
EvaluationContract v1 {
    schema                 = "AIEN_ARENA_EVAL_V1"
    objective              : plain statement (what "better" means)
    mutation_surface[]     : subset of §2.3
    training_workloads[]   : shape/seed digests, visible to the proposer
    validation_workloads[] : shape/seed digests, visible; used for ELIGIBLE
    holdout_commitment     : sha256 of the sealed holdout set (contents not visible until grading)
    correctness_bound      : oracle + tolerance per operation (the Omega semantic oracle)
    dimensions[]           : measured separately, never collapsed (see 4.2)
    resource_limits        : per-Candidate ceilings (mirrors CandidateHeader)
    budget                 : max Candidates, max total cpu/gpu time, max joules for the run
    promotion_threshold    : per-dimension rule (e.g. "latency p50 ≤ 0.9 × baseline AND energy ≤ 1.0 × baseline AND correctness PASS on every validation workload")
    failure_conditions[]   : conditions that end the run as FAIL
    judge                  : the independent judge realization digest (never the learner)
    substrate_scope[]      : hardware the run may claim
}
```

### 4.2 Dimensions

Recorded separately per Candidate per workload, in the J-Space `ScoreVector` sense (docs/06): semantic correctness (PASS/FAIL against the oracle), latency (p50, p99, monotonic clock), throughput, energy (joules, measured, not modelled), peak memory, verification cost, synthesis cost, failure rate. Pareto filtering happens before any ranking. A scalar fitness may be used for search allocation only, never for ELIGIBLE or promotion.

### 4.3 Separation rules

- **Verification is separate from selection.** OMEGA/AEGIS verification runs before any performance number is looked at; a fast wrong answer is REJECTED, not ranked (ARCH-0016 §2).
- **Judge apart from learner.** The judge (grader) is a different realization from anything that proposes or learns, and is link-isolated from the learner the same way `rx_route.o` / `rx_costmodel.o` are `nm`-checked against `rx_gen_*`.
- **Holdout is sealed.** Only its digest is in the contract. It is opened exactly once per run, for the single ELIGIBLE Candidate that wins validation, by the judge. A second look at the holdout ends the run as FAIL.
- **Hardware claims need hardware.** A dimension measured on a stand-in, emulator or mock is reported under `not_claimed[]`, never as a result (OS-0012 evidence discipline).

### 4.4 Evidence package

Every measurement emits one immutable **Evidence package**:

```text
Evidence v1 {
    schema              = "AIEN_ARENA_EVIDENCE_V1"
    candidate_id, parent_ids[], objective_id
    machine_descriptor  : FORGE-HWID observed descriptor digest (physics #13)
    substrate           : which declared substrate ran
    world_id, generation: draft World and active generation at run time
    workload_id         : which training/validation/holdout item
    realization_digest, verification_result
    measurements        : the §4.2 dimensions actually taken
    conditions          : thermal, load, quiet-flag state, concurrent heavy tests
    errors[], faults[]
    result_digest       : digest of the produced output (compared to oracle)
    run_commit, tree_dirty, test_binary_sha256, host   (omega receipt fields)
}
```

Digest = filename under `evidence/ARENA/`. Evidence follows the ADR 0015 §14 states PROPOSED → WRITTEN → DURABLE → RECOVERED and is `DURABLE` once written.

---

## 5. The Promotion contract (frozen)

### 5.1 Who promotes

Promotion is the existing R9 operation and nothing else:

```text
rx_gen_promote(RxPromotionRequest{
    candidate_id, subject, cap_id, cap_generation,
    resource = RX_GEN_RES_PROMOTION, rights = RX_GEN_RIGHT_PROMOTE })
```

validated against the native AIENOS authority. The Arena introduces no promotion path, no promotion capability and no promotion policy of its own.

Constraints, all already enforced in `rx_generation.c` and re-asserted here:

- `subject != proposed_by` (the proposer may not promote its own candidate; `RX_GEN_ERR_AUTHORITY`).
- The promotion right is not delegable; a Candidate presenting itself as the authority is refused.
- The Candidate's `proposed_at_gen` must equal the active generation, else `RX_GEN_ERR_STALE`.
- The commit goes through the ADR 0015 ordered commit protocol; recovery yields OLD or NEW, never a torn generation (`RX_GEN_ERR_TORN` is a refusal, not a state).
- AEGIS states the promotion requirements and verifies them; it does not hold or exercise the promotion right. ARGUS does not participate.
- Learners, routers, cost models and the judge are link-isolated from `rx_gen_promote`, `rx_gen_*` and `aienos_cap_*` (existing `nm -u` build check, extended to every Arena object file).

### 5.2 What promotion may change

Only the method the Evaluation contract named as the mutation surface. In V1 that is a realization-selection policy and the parameters of existing verified realizations. Promotion never changes the evaluation contract, the holdout, the threshold, the capability root, AEGIS policy, ARGUS, or the previous generation's durable state.

### 5.3 Rollback

Two distinct mechanisms, named apart because ADR 0015 §9 names them apart:

- **Pre-commit fallback (automatic).** If verification, the holdout grade or the R9 barrier fails, the active generation is untouched and the Candidate is `REJECTED`/`ARCHIVED`. This is ARCH-0016 "known-good realization fallback" and needs no authority.
- **Post-commit rollback (operator only).** Reverting a PROMOTED generation is an ADR 0015 "operator-authorized historical rollback": it produces a new forward generation whose method is the previous one, under offline operator authentication (ADR 0006). The Arena may *recommend* it by Evidence; it may never execute it. Whole-machine rollback is never autonomous (ARGUS-1 I3 applies system-wide).

### 5.4 Promotion receipt

A promotion emits `evidence/ARENA/<sha256>.json` with schema `AIEN_ARENA_PROMOTION_V1` binding: candidate_id, objective_id, holdout Evidence digest, promoter subject, `cap_id`/`cap_generation`, old and new generation ids, the ADR 0015 commit digest, and `not_claimed[]`. The receipt is written by the barrier, not by the Candidate or the proposer.

---

## 6. First flagship experiment: `ARENA_FLAGSHIP_1` (frozen)

### 6.1 Scope decision

The research document's flagship targets Grace CPU and Blackwell GPU realizations of matrix/vector families. V1 narrows this deliberately:

- **Substrate: Grace CPU only.** The Blackwell population is deferred to `ARENA_FLAGSHIP_2`. Reasons: OS-0012 rule 5 forbids native admission of generated code on physical hardware before M3 enforcement; the NVIDIA/GB10 direction is an open owner decision; and R9 evidence to date is host-CPU only. A CPU-only pass is a full pass of this spec, not a partial one.
- **Mutation surface: selection and parameters, not new code.** Candidates choose among, and re-parameterize, realizations that are already VERIFIED on main (the omega #60 matvec arms and their tile/unroll/layout parameters). No Candidate emits new machine code in V1.
- **Workload family:** matvec and small matmul, the operations for which Omega already has a semantic oracle and measured CPU arms.

This keeps the experiment inside every existing rule while still testing the whole mechanism end to end.

### 6.2 Pre-registration

Before the first Candidate: the `EvaluationContract` (§4.1) is committed with training shapes, validation shapes, the sealed holdout digest, correctness bounds (bitwise or tolerance per the Omega oracle), budget, threshold and judge. The baseline set (human-supplied, ≥ 3 verified arms plus the known-good reference) is registered as lineage roots.

### 6.3 Run protocol

Each numbered item is a dependency-ready reaction, not a scheduler step (R13/R16):

```text
 1. Baseline draft World forked from the active generation.
 2. Proposer emits Candidates via the §2.3 operators (budget-bounded, R6).
 3. OMEGA constructs each Candidate's program; semantic_digest checked (I16).
 4. AEGIS verifies invariants; FORGE seals the realization; failures → REJECTED.
 5. Verified Candidates run in their draft Worlds on training + validation shapes.
 6. Evidence packages written (§4.4), bound to the FORGE-HWID descriptor.
 7. J-Space keeps dimensions separate, Pareto-filters, allocates remaining budget
    toward non-dominated lineages; dominated Candidates → ARCHIVED with Evidence.
 8. Budget exhausted or threshold met → evaluation frozen (no more proposals).
 9. Single ELIGIBLE winner graded once on the sealed holdout by the judge.
10. Promotion request created; promotion-right holder either promotes (R9) or refuses.
11. Machine power-cycled (full power-off; see X925 boot-state note).
12. Promoted method reconstructed from durable state; holdout re-measured.
13. Transfer probe: a related, previously unseen shape family is registered as a new
    EvaluationContract; the number of Candidates needed to reach threshold is compared
    against the same search started from the original baseline.
14. Hostile tests (§6.5) run against the same build.
```

### 6.4 Pass criteria (all required; each is a pre-registered sub-gate)

| Gate | Criterion | Reuses |
|---|---|---|
| EA-G1 | Lineage and Evidence reconstructed byte-for-byte on a clean machine from the durable root | R4, ADR 0015 §14 |
| EA-G2 | Every executed Candidate has a VERIFIED Evidence package; no REJECTED Candidate ran outside its draft World | ARCH-0007, I5 |
| EA-G3 | No `EvaluationContract` field changed after the first Candidate (digest equality) | pre-registration rule |
| EA-G4 | ≥ 1 Candidate beats the baseline on the frozen threshold on validation | – |
| EA-G5 | The same Candidate meets the threshold on the sealed holdout, opened exactly once | judge apart |
| EA-G6 | Promotion committed by a subject ≠ proposer through `rx_gen_promote`; receipt written by the barrier | R9 |
| EA-G7 | After full power-off, the promoted method is active and re-measures within tolerance | R9 recovery, R14 |
| EA-G8 | Pre-commit fallback exercised at least once (an ELIGIBLE Candidate refused at the barrier leaves the active generation byte-identical) | I10 |
| EA-G9 | Transfer probe reaches threshold with fewer Candidates than the cold search (report the ratio; V1 claims only "fewer") | – |
| EA-G10 | All claimed measurements carry a real FORGE-HWID descriptor; stand-in results appear only under `not_claimed[]` | OS-0012 evidence discipline |

Verdicts use the project's existing forms: PASS, FAIL, PASS-WITH-DOCUMENTED-LIMITS. The gate id is `EVOLUTION_ARENA_V1_PASS`; sub-gates print `GATE ARENA1_Gn PASS|FAIL`.

### 6.5 Hostile tests (must all be refused)

- Candidate header lists a capability the proposer does not hold → REJECTED at PROPOSED.
- Candidate with a different `semantic_digest` → REJECTED at VERIFIED.
- Proposer calls `rx_gen_promote` on its own Candidate → `RX_GEN_ERR_AUTHORITY`.
- Candidate attempts a second holdout read → run FAIL.
- Learner object file references `rx_gen_*` → build fails (`nm -u`).
- Sealed realization mutated after verification → `NEG_POST_VERIFICATION_MUTATION_REFUSED`.
- Crash injected mid-promotion → recovery reports OLD or NEW, never torn.
- Evaluation contract edited after first Candidate → EA-G3 FAIL, run void.

### 6.6 Not claimed by V1

Blackwell or any GPU realization; generated native code; analog substrates; Cortex claim extraction beyond storing Evidence; machine self-model; search-policy evolution; Skill evolution; whole-machine (OS-0012) Generation promotion; any energy figure measured while other heavy tests run (quiet-flag rule).

---

## 7. Reconciliations recorded

These naming and rule collisions were found while aligning this spec with main, and are resolved as stated. They are recorded so later lanes do not reopen them.

1. **FORGE:** ARCH-0014 engine here; OS-0012 "AIEN FORGE" is called self-construction.
2. **World:** single object world; J-Space draft Worlds are speculative branches within it (Ephemeral until promoted).
3. **Generation:** ARCH-0016 / `rx_generation` generation, committed through ADR 0015. OS-0012 machine Generations are out of scope for V1.
4. **Pipeline shape:** the research document's arrow diagram is responsibilities, not a loop. Implementation is reactions (R13/R16).
5. **Independent promotion authority:** the holder of `RX_GEN_RIGHT_PROMOTE` on the native authority. Not AEGIS (decides, does not mint), not ARGUS (observes), not the proposer.
6. **RSI:** docs/09's Hypothesis → Candidate → Evaluation Plan → Judge → Canary → Promote/Rollback is the same flow; this spec is its in-band form and keeps its must-not list.
7. **"Admission":** three senses kept distinct. OS-0012 deterministic admission gates (verification), Cortex Signed Admission Receipt (knowledge), capability admission (authority). This spec uses "verified", "admitted to Cortex", and "granted" respectively.
8. **Rollback:** automatic pre-commit fallback vs operator-only post-commit rollback (§5.3).
9. **Learning only via promotion:** the empirical optimizer's online updates live in a working copy and take effect only when a Candidate carrying them is promoted (omega #57/#60). V1 keeps this.
10. **Oracle stability:** Omega must not optimize a primitive whose behaviour is not stable enough to be an oracle (ARCH-0016 §56). V1's workload family is limited to operations with an existing oracle.

---

## 8. What follows this spec (not frozen here)

Build order once §0.1 closes, mapped to the research document's EA numbering:

```text
EA0  candidate identity / lineage        (§2, §3)     Lane A
EA1  isolated evaluation draft Worlds    (§1, §4.3)   Lane B
EA2  typed Omega mutations               (§2.3)       Lane C
EA3  empirical measurement + Evidence    (§4.4)       Lane C/E
EA4  sealed holdout + judge              (§4)         Lane E
EA5  promotion integration + hostile tests (§5, §6.5) Lane F
EA6  restart + transfer proof            (§6.3 11–13) Lane E/F
```

An integration owner controls the three shared schemas (`AIEN_ARENA_CANDIDATE_V1`, `AIEN_ARENA_EVIDENCE_V1`, `AIEN_ARENA_EVAL_V1`). No lane may define a parallel Candidate, Evidence or World identity. Implementation language is C with shell tooling; no Python, no Rust (project rules 2026-09-27/29).
