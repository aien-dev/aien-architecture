# ADR 0016: AIEN, Omega, and AEGIS Are Faculties of One Resident Reaction System

**Status:** Accepted by operator, 2026-09-27 (directive: "Treat this document as the architectural decision. Do not redesign it back into a service pipeline.")
**Gate:** `R0_REACTION_ARCHITECTURE_LOCKED` — satisfied when this ADR is merged to `main`.
**Supersedes:** nothing. **Amends:** the runtime-composition reading of `doctrine/ARCHITECTURE.md` §1.1 and §2.6 (see "Doctrine reconciliation").
**Amendment 1 (ACCEPTED 2026-10-02 by operator Drake Stapleton, decision Option B):** FORGE is a realization and memory policy, not a stage of accepting a reaction result. See "Amendment 1" under "Doctrine reconciliation".

**Related:** ADR 0005 (effect broker), ADR 0007 (J-Space effect boundary), ADR 0013/0014 (FORGE realizes, AEGIS verifies, AIENOS owns capabilities), ADR 0015 (Resident Semantic Store, accepted and merged 2026-09-27).
**Migration map:** [`docs/plans/CURRENT_CODE_TO_R0_R16_MIGRATION.md`](../plans/CURRENT_CODE_TO_R0_R16_MIGRATION.md) (NOT A MASTER PLAN).

---

## Part I — Decision record

### Context

Until now the runtime was described as a pipeline: AIEN proposes, then Omega defines, then FORGE realizes, then AEGIS verifies, then hardware acts. Every implementation so far follows that shape. `tools/omegatool.c` sequences each step by hand, and M19's `omega_world_*` API is a synchronous call-submit-drain service. The coherent shared world (M19, M20 Stage 1 work) already points the other way: one pointer-free object world that CPU and GPU both observe.

The operator directive of 2026-09-27 (Part II, verbatim) changes the runtime composition. It keeps every sovereignty, authority, verification, evidence, rollback, generation, and semantic-identity standard.

### Decision

The following eight statements are locked. No module migration may contradict them.

```text
AIEN + OMEGA + AEGIS ARE FACULTIES OF ONE RESIDENT SYSTEM.

THE SYSTEM HAS NO SEMANTIC MASTER LOOP.

WORK ACTIVATES THROUGH DEPENDENCY READINESS.

PHYSICAL RESOURCES ARE ARBITRATED BELOW SEMANTIC READINESS.

AUTHORITY IS UNFORGEABLE.

BEHAVIOR IS CONTINUOUS.

DURABLE LEARNING USES GENERATION BARRIERS.

ALL NONTRIVIAL TRANSITIONS ARE CAUSALLY TRACEABLE.
```

Canonical architectural sentence:

> AIEN is a persistent resident computational organism in which cognition, semantics, realization, authority, memory, evidence, and action evolve concurrently over one generation-addressed object world. Work activates by readiness rather than turn-taking; physical resources are locally arbitrated; authority remains unforgeable; durable learning occurs at verified generation barriers; and every consequential state transition remains causally attributable.

### Terminology mapping to current doctrine

Part II was written with some pre-ADR-0014 vocabulary. Read it through this table. Historical identifiers stay unchanged, per ADR 0014.

| Part II term | Current meaning |
|---|---|
| "Physics" as machine realization (§29 cost model, `physics/cpu`, `physics/accelerator`, `physics/memory`) | **FORGE** (ADR 0014). FORGE realizes; it is not a security gatekeeper. |
| "Trusted physical root", "capability mint and validator", `physics/capability` | The **capability root**. Natively this is the AIENOS kernel capability authority, which ADR 0014 assigns to AIENOS. On bare metal the historical M3 ledger (`aien-dev/physics` `m3/capability.s`) is the reference. For Linux-hosted development it is an out-of-process host root whose table the semantic runtime can read but never write (see the migration map). It is never an ordinary mutable semantic object. |
| "AEGIS and Physics must remain capable of stopping execution" (§31) | AEGIS (policy/verification) plus the capability root and AIENOS (revocation, worker cancellation, GPU reset) must be able to stop execution while cognition is unhealthy. |
| AEGIS "capability policy / authority relations" | AEGIS verifies authority and checks compliance against system invariants; it decides no policy and authors no law (acting as quality control verification). It issues PolicyDecision / CapabilityRequest / RevocationIntent strictly as evaluations against canonical criteria. Only the capability root turns a decision into an enforceable capability. AEGIS verifies, the root mints. |
| "Physics Zero" | Unrelated. It is the scientific-discovery program (M27–M35). |

### Doctrine reconciliation

`ATLAS AWAKENS. AIEN PROPOSES. OMEGA DEFINES. FORGE REALIZES. AEGIS VERIFIES. HARDWARE ACTS. EVIDENCE TEACHES.` remains the canonical statement of **responsibilities and causal dependencies**. After this ADR it is **not** a runtime turn order. In the resident system:

- "AIEN proposes" means AIEN publishes typed proposals (`Hypothesis`, `PlanCandidate`, …) into the shared world.
- "OMEGA defines" and "FORGE realizes" are reactions that become ready when those proposals exist. FORGE realization is a realization and memory policy, not a step in accepting a reaction result (ADR 0016 Amendment 1, 2026-10-02, below).
- "AEGIS verifies" means authority state takes part in readiness. Verification reactions gate promotion. AEGIS is not a synchronous call on every step.
- "Evidence teaches" means evidence is appended as structured causal crumbs, and durable learning is promoted only at generation barriers.

The §2.6 "Bidirectional Lowering Protocol" still describes the dependency structure of one realization. Its numbered steps are dependencies, not a loop body.

#### Amendment 1 (ACCEPTED 2026-10-02 by operator Drake Stapleton, Option B)

- FORGE is a realization policy: hardware lowering and, inside J-Space, a memory-pressure policy (`js_forge_choose`, `js_forge_enforce`). It is not a stage of accepting a reaction result.
- The recorded accept chain is World -> J-Space -> `compose.verify` -> commit -> Cortex, as documented in `aien-dev/omega` `docs/runtime/COMMIT_A_REACTION_DESIGN.md` (merged 35af57d). No FORGE step sits on it.
- Wherever this ADR, `doctrine/ARCHITECTURE.md` §2.6 or any other document lists FORGE before verify, act or commit, read it as a dependency for hardware realization only, not as a commit step.
- If hardware realization later needs a hook on the accept path, that is a new decision and a new amendment.
- This does not change ADR 0024: Physics and FORGE remain hardware-substrate class B.

### Relationship to ADR 0015 (Resident Semantic Store)

ADR 0015 governs durable state: memory categories, `OmegaResidentRoot`, the Store v1 commit point, and cold recovery. This ADR governs how the live world changes. The state classes in Part II §19 map onto ADR 0015's categories as follows:

| Part II §19 | ADR 0015 §2 |
|---|---|
| Ephemeral | `EPHEMERAL`, `DEVICE_LOCAL` |
| Resident | `RECONSTRUCTIBLE`, `DERIVED` |
| Durable | `DURABLE` |

The generation barrier (Part II §17–18, gate R9) must commit through the ADR 0015 ordered commit protocol. ADR 0015 is merged (2026-09-27), so R9 may start once its own prerequisites (R5–R8) hold. R0–R8 are in-memory and do not write persistent formats, so they are not blocked by ADR 0015.

### Invariants carried into every stage

These are I1–I16 from Part II §54. Every R-gate receipt must state which invariants its tests exercised.

### Consequences

- New runtime code is organized by shared primitives (object, reaction, dependency, publication, causal, generation, resource, recovery), not by `aien-runtime/`, `omega-runtime/`, or `aegis-runtime/` schedulers (Part II §50–51).
- The legacy orchestrated paths (`omegatool` gate/demo sequencing, M19 synchronous `omega_world_*` dispatch, `aegis-runtime` orchestration) become the reference oracle. They are not deleted before R16 (Part II §32).
- Authority encoded as editable fields is non-conforming as authority. This includes `OmegaHandle.permissions` in M19 and `is_physics_authorized` in M13/M15, which stays frozen as a historical fingerprint field. Those fields may remain as cached views, but they must never be the thing that grants a right (Part II §3, §57; invariant I3).
- Gate claims follow the existing evidence discipline (M19R Gate 1): observed counts, candidate commit bound as input, and no hardware claim from mocks (Part II §60 items 7–8).

---

## Part II — Normative standard (operator directive, 2026-09-27)

Verbatim, except that the R0–R16 gate sections (§33–§49) and §50–§57 have their bullet lists folded onto single lines. No requirement was added, removed, or reworded.

# AIEN UNIFIED ORGANISM

## Resident Reaction Architecture Implementation Plan

### Status

**PROPOSED ARCHITECTURAL STANDARD** (accepted as ADR 0016 — see Part I)

This document changes the runtime composition of AIEN, Omega, and AEGIS.

It does **not** discard the existing sovereignty, authority, verification, evidence, rollback, generation, or semantic-identity standards.

The central change is:

```text
OLD

AIEN
  ↓
OMEGA
  ↓
AEGIS
  ↓
PHYSICS
  ↓
MACHINE
```

becomes:

```text
               ONE RESIDENT SYSTEM

       ┌──────────┬──────────┬──────────┐
       │          │          │          │
     AIEN       OMEGA      AEGIS       │
   cognition   semantics   authority    │
   learning    synthesis   policy       │
   goals       realization capability   │
       │          │          │          │
       └──────────┴──────────┴──────────┘
                    │
             SHARED LIVE WORLD
                    │
           TRUSTED PHYSICAL ROOT
                    │
                 MACHINE
```

AIEN, Omega, and AEGIS are no longer sequential services.

They are three faculties operating continuously over the same resident state.

No faculty owns the main loop.

There is no semantic-level concept of:

```text
"whose turn is next?"
```

The runtime is reaction-driven:

```text
STATE CHANGE
    ↓
DEPENDENCIES BECOME READY
    ↓
ELIGIBLE TRANSFORMATIONS ACT
    ↓
STATE CHANGES
    ↓
OTHER DEPENDENCIES BECOME READY
```

The system lives.

---

# 1. FUNDAMENTAL MODEL

The canonical computation becomes:

```text
STATE(t)
   │
   ├── cognition
   ├── semantic transformation
   ├── authority
   ├── memory
   ├── evidence
   ├── physical realization
   │
   ▼
STATE(t+1)
```

A valid state transition may simultaneously possess:

```text
GOAL
HYPOTHESIS
SEMANTICS
CONSTRAINTS
REALIZATION
CAPABILITY REQUIREMENTS
AUTHORITY
RESOURCE REQUIREMENTS
EVIDENCE
PROVENANCE
COST
RESULT
```

These are not messages between subsystems.

They are dimensions of the same object graph.

---

# 2. THE THREE FACULTIES

## AIEN — adaptive cognition

AIEN contributes:

```text
GOALS
ATTENTION
BELIEFS
HYPOTHESES
PREDICTIONS
UNCERTAINTY
PLANS
PRIORITIES
LEARNING
MODEL STATE
MEMORY ACTIVATION
```

AIEN does not possess physical authority merely because it generated a proposal.

---

## OMEGA — semantic and realization faculty

Omega contributes:

```text
SEMANTIC IDENTITY
OPERATIONS
RELATIONS
CONSTRAINTS
PROGRAMS
REALIZATIONS
MACHINE MODELS
EQUIVALENCE
SYNTHESIS
PROOFS
COST MODELS
IMPLEMENTATION SEARCH
```

Meaning remains independent of representation.

Multiple implementations may realize one semantic operation.

The existing realization rule remains:

```text
REALIZE
VERIFY
MEASURE
RECORD
SELECT
```

and verification remains separate from performance selection.

---

## AEGIS — constitutional authority faculty

AEGIS contributes:

```text
CAPABILITY POLICY
AUTHORITY RELATIONS
EFFECT CLASSIFICATION
RESOURCE RIGHTS
PRIVILEGE BOUNDS
REVOCATION
PROMOTION REQUIREMENTS
TRUST RELATIONSHIPS
SECURITY INVARIANTS
```

AEGIS ceases to behave primarily as:

```text
request
↓
gatekeeper
↓
yes/no
```

Ordinary valid authority should already be represented in resident capability state.

AEGIS becomes most active when authority itself changes.

Examples:

```text
CREATE CAPABILITY
EXPAND CAPABILITY
DELEGATE CAPABILITY
REVOKE CAPABILITY
PERMIT EXTERNAL EFFECT
PROMOTE REALIZATION
CHANGE TRUST ROOT
```

---

# 3. NON-NEGOTIABLE TRUST RULE

The integration of AIEN, Omega, and AEGIS must **not** imply that cognition can forge authority.

Canonical invariant:

```text
INTELLIGENCE ≠ AUTHORITY
```

The existing failure model already requires the system to remain sound when intelligence hallucinates, produces bad code or proofs, crashes, or becomes compromised. It requires capability revocation, recovery, known-good restoration, and evidence preservation.

Therefore:

```text
AEGIS POLICY
    │
    ▼
CAPABILITY MINT
    │
    ▼
UNFORGEABLE CAPABILITY
    │
    ▼
PHYSICAL ENFORCEMENT
```

The capability mint and validator live inside the trusted physical root.

They are not ordinary mutable semantic objects.

The shared world may contain references to capabilities.

It may not invent them.

A capability should minimally bind:

```text
CapabilityId
issuer
subject
resource
rights
bounds
generation
epoch
expiry / lease
delegation constraints
revocation state
cryptographic / kernel authenticity
```

Raw permission fields are insufficient.

This rule is absolute.

---

# 4. NO CENTRAL SEMANTIC ORCHESTRATOR

Remove the assumption that the runtime fundamentally looks like:

```text
loop {
    task = choose_next_task();
    execute(task);
}
```

The new semantic runtime is:

```text
mutation
   ↓
dependency propagation
   ↓
readiness
   ↓
resource admission
   ↓
reaction
   ↓
publication
```

A transformation is semantically ready when:

```text
required inputs exist
AND
required semantic constraints hold
AND
required authority exists
AND
required predecessor state is committed
```

Physical execution additionally requires:

```text
resources available
AND
realization available
AND
machine constraints satisfied
```

---

# 5. BUILD THE REACTION FABRIC

This is a real subsystem and must be treated as such.

Do not disguise it as "the graph just reacts."

Implement explicit dependency machinery.

Each reactive transformation must declare:

```text
READ SET
WRITE SET
TRIGGER SET
INVALIDATION SET
CAPABILITY SET
RESOURCE CLASS
GENERATION
PRIORITY CLASS
```

The runtime maintains indexes from changed semantic properties to interested reactions.

Conceptually:

```text
object mutation
      │
      ▼
dependency index
      │
      ├── reaction A
      ├── reaction B
      └── reaction C
```

Do not scan the complete graph after every mutation.

---

# 6. REACTION STATE MACHINE

Every reaction should have an explicit lifecycle.

Use approximately:

```text
DORMANT
  ↓ dependency satisfied
READY
  ↓ resource admitted
RUNNING
  ↓
PUBLISHING
  ↓
COMMITTED
```

Alternative exits:

```text
READY → BLOCKED_AUTHORITY
READY → BLOCKED_RESOURCE
READY → INVALIDATED

RUNNING → FAILED
RUNNING → CANCELLED
RUNNING → INVALIDATED

PUBLISHING → CONFLICT
PUBLISHING → REJECTED
```

Never allow an implicit ambiguous state.

---

# 7. VERSIONED READS AND TRANSACTIONAL PUBLICATION

Reactions may operate concurrently.

Therefore a reaction must not assume the world remained unchanged while it computed.

A reaction records:

```text
input object IDs
input generations
input versions
capability generations
machine-state assumptions
```

Before publication, validate that required assumptions remain valid.

Then:

```text
COMPUTE AGAINST SNAPSHOT
       ↓
PROPOSE MUTATION
       ↓
VALIDATE DEPENDENCIES
       ↓
ATOMIC PUBLISH
```

If relevant input changed:

```text
candidate becomes stale
```

not silently committed.

This should use generation/version semantics already native to Omega's object model.

---

# 8. RESOURCE ARBITRATION STILL EXISTS

The architecture does not pretend contention disappeared.

Semantic readiness and physical admission are separate.

Potentially:

```text
100 reactions READY
3 can physically run
```

Something must allocate resources.

The crucial distinction is:

**the allocator schedules work, not personalities.**

Never allocate:

```text
GPU TO AIEN
CPU TO AEGIS
GPU TO OMEGA
```

Instead reactions describe requirements:

```text
WorkRequirement {
    compute_class
    memory
    locality
    accelerator_features
    latency_class
    energy_budget
    deadline
    authority
    importance
}
```

Then machine policy decides placement.

---

# 9. GLOBAL MODULATORS

Introduce a deliberately small mechanism analogous to attention/arousal/pain rather than reconstructing a giant orchestrator.

Recommended global signals:

```text
CRITICAL
INTERACTIVE
FOREGROUND
LEARNING
MAINTENANCE
SPECULATIVE
BACKGROUND
```

Optional continuous factors may include:

```text
urgency
expected utility
deadline pressure
uncertainty reduction
risk
resource cost
age / starvation
```

The physical scheduler can calculate a local admission score from these properties.

But do not create an all-knowing planning scheduler.

Global modulation says:

```text
"this matters more right now"
```

not:

```text
"here is the entire order in which the organism must think"
```

Include starvation prevention.

---

# 10. PREVENT THUNDERING HERDS

The dependency engine must support:

```text
fine-grained subscriptions
coalesced invalidation
change masks
generation-aware wakeups
deduplication
rate limiting
bounded fan-out
```

A change to:

```text
Object X.attribute[temperature]
```

should not wake every reaction depending on Object X if only three actually depend on `temperature`.

Track dependencies at the narrowest reasonable semantic granularity.

---

# 11. PREVENT OSCILLATION

The runtime needs explicit loop detection.

Examples:

```text
A → B → A

A → B → C → A
```

Maintain causal ancestry sufficient to recognize immediate and bounded cycles.

Policies may include:

```text
fixed-point detection
minimum-change threshold
maximum reaction depth
per-generation activation budget
oscillation quarantine
backoff
operator-visible fault
```

Some cycles are legitimate.

Therefore:

```text
cycle != automatically invalid
```

The runtime must distinguish:

```text
CONVERGENT LOOP
PERIODIC CONTROL LOOP
UNSTABLE OSCILLATION
LIVELOCK
```

---

# 12. PROGRESS AND LIVELOCK

Define progress explicitly.

A system performing infinite reactions without increasing useful committed state is not healthy merely because hardware utilization is high.

Track:

```text
committed semantic progress
goal advancement
new evidence
resolved uncertainty
useful external effect
verified optimization
```

Compare that against:

```text
reaction count
compute consumed
memory churn
invalidations
retries
```

Detect:

```text
livelock
retry storms
conflict storms
wakeup storms
```

and degrade or quarantine the responsible graph region.

---

# 13. ONE SHARED OBJECT WORLD

The current architecture already points toward a shared object world and cross-engine ABI. The migration plan specifically identifies the transition from CPU-prepares/GPU-waits to CPU and GPU participating in a shared object world, and orders the work as Shared Object Pool → Cross-Engine ABI → Resident Cooperation → Generation Barrier → Physical Cost Calculus.

Make that the architectural center.

The world contains:

```text
semantic graph
goals
beliefs
hypotheses
plans
capabilities
realizations
model state
tensor state
Cortex hot state
machine graph
evidence
provenance
active reactions
generation metadata
```

Use logical references:

```text
ObjectId
SemanticId
Generation
CapabilityId
RealizationId
```

not cross-authority raw pointers.

Physical addresses remain implementation details of the trusted machine registry.

---

# 14. CROSS-ENGINE OBJECT ABI

CPU and GPU both need to observe and mutate permitted portions of the resident world.

Define a narrow object ABI containing:

```text
object identity
object generation
object type
state/version
ownership metadata
authority reference
dependency metadata
publication state
payload/reference descriptor
```

No raw CPU pointer should become a semantic identity.

No GPU virtual address should become a semantic identity.

Machine addresses are realizations.

---

# 15. RESIDENT COOPERATION

Replace:

```text
CPU
→ construct command
→ launch GPU
→ wait
→ consume
```

with increasingly resident execution:

```text
CPU PARTICIPANTS ─┐
                  │
                  ▼
            SHARED WORLD
                  ▲
                  │
GPU PARTICIPANTS ─┘
```

GPU-side resident workers should be able to:

```text
observe eligible GPU reactions
claim permitted work
execute realization
publish result descriptors
continue
```

without reconstructing the cognitive system per launch.

The existing standard already calls for:

```text
INITIALIZE ONCE
STAY RESIDENT
OBSERVE SHARED WORK
EXECUTE
PUBLISH RESULTS
CONTINUE
```

---

# 16. FAST PATH / SLOW PATH

The living system must not run expensive reasoning, synthesis, or policy machinery for familiar operations.

## Fast path

```text
known semantics
+
known realization
+
valid capability
+
ready inputs
+
available resources
=
execute
```

No policy RPC.

No synthesis.

No recompilation.

No unnecessary serialization.

No model inference merely to dispatch known work.

## Slow path

Triggered by novelty:

```text
unknown realization
new goal
changed authority
unusual risk
failed verification
missing capability
unknown machine condition
optimization opportunity
```

Then cognition, Omega synthesis, AEGIS reasoning, verification, or operator involvement may activate.

This directly supports the existing performance objective:

```text
MINIMUM PHYSICAL WORK
PER REQUIRED SEMANTIC RESULT
```

which explicitly calls for removing unnecessary movement, parsing, copies, synchronization, launches, context switches, recompilation, and redundant computation.

---

# 17. CONTINUOUS BEHAVIOR, DISCRETE LEARNING

Do not attempt to make permanent belief/model promotion completely fluid.

Use two timescales.

```text
FAST TIMESCALE
continuous reaction

SLOW TIMESCALE
generation promotion
```

Behavior can continue while candidate knowledge is accumulated.

At a generation boundary:

```text
drain relevant in-flight work
freeze evidence set
evaluate candidate changes
verify invariants
publish committed generation
```

This becomes the organism's coherent learning boundary.

---

# 18. GENERATION BARRIER

Canonical lifecycle:

```text
Generation N active
        ↓
open candidate N+1
        ↓
continuous reactions continue
        ↓
candidate learning accumulates
        ↓
request commitment
        ↓
drain / classify relevant in-flight work
        ↓
freeze consistent reachable state
        ↓
verify
        ↓
commit Generation N+1
```

Do not freeze the entire machine for every thought.

Generation barriers are for durable semantic commitments.

---

# 19. THREE CLASSES OF STATE

Explicitly classify state.

## Ephemeral

```text
temporary activations
scheduler queues
scratch tensors
temporary GPU registers
speculative results
```

Can disappear.

## Resident

```text
active cognitive state
hot graph
model state
reaction indexes
working memory
realization cache
active capability references
```

Expected to remain alive during normal operation.

## Durable

```text
committed generations
Cortex evidence
semantic objects
model checkpoints
verified realizations
policy roots
lineage
provenance
```

Must survive recovery.

Never persist raw transient pointers as identity.

---

# 20. CAUSAL CRUMBS ARE FIRST-CLASS

Removing the main loop makes observability more important.

Every meaningful reaction produces a compact causal crumb.

Minimum:

```text
ReactionId
cause
trigger object/version
input generations
reaction type
faculty contributions
authority used
realization used
machine placement
start/finish
published objects
evidence references
failure / invalidation reason
parent causal IDs
```

This allows reconstruction:

```text
Why did this happen?
What woke this?
What evidence caused it?
What authority allowed it?
What realization executed?
What changed because of it?
```

---

# 21. DO NOT LOG EVERYTHING AS TEXT

Causal trace should itself be structured semantic data.

Use content-addressed evidence where possible.

Example:

```text
CausalEvent {
    id
    generation
    causes[]
    inputs[]
    transformation
    realization
    capabilities[]
    outputs[]
    evidence[]
    physical_cost
}
```

Human-readable logs are renderings.

The canonical record is structured.

---

# 22. OBSERVABILITY REQUIREMENTS

The operator must be able to ask:

```text
what is active?
what is blocked?
what is consuming resources?
what is repeatedly waking?
what has highest urgency?
which reactions are starved?
which graph region is oscillating?
which capability enables this action?
why did this effect happen?
which evidence promoted this belief?
```

Implement causal graph inspection before allowing the reaction system to become large.

No opaque "organism" excuse is acceptable.

---

# 23. EFFECTS REMAIN SPECIAL

Pure semantic/cognitive state transformation can be highly concurrent.

Irreversible external effects remain stricter.

Examples:

```text
network transmission
filesystem destruction
external account mutation
physical actuator command
repository deletion
credential use
```

Those require explicit effect authority.

A speculative thought can construct and evaluate an effect.

It cannot externalize one without authority.

---

# 24. SPECULATION

Speculative branches should be native reactions.

They may:

```text
reason
simulate
synthesize
benchmark in sandbox
generate candidate state
```

They may not silently alter canonical external reality.

Promotion remains explicit.

---

# 25. CONFLICT MODEL

Concurrent reactions will sometimes produce incompatible writes.

Do not serialize all writes merely to avoid this.

Define conflict classes:

```text
COMMUTATIVE
MERGEABLE
LAST-WRITER-INVALID
EXCLUSIVE
AUTHORITY-SENSITIVE
GENERATION-SENSITIVE
```

Semantic object types should declare their merge behavior.

Examples:

Evidence append: `commutative`

Capability revocation: `authority-sensitive`

Canonical realization promotion: `exclusive / generation-sensitive`

---

# 26. OBJECT TYPE CONTRACT

Each semantic object type should eventually declare:

```text
canonical encoding
identity rule
mutable fields
immutable fields
dependency granularity
merge semantics
authority requirements
verification rules
persistence class
wake conditions
```

This lets the runtime understand objects without hardcoding behavior for every subsystem.

---

# 27. FACULTY OWNERSHIP IS LOGICAL, NOT MEMORY OWNERSHIP

Do not divide memory into:

```text
AIEN heap
OMEGA heap
AEGIS heap
```

Use one object universe.

But preserve write authority by semantic domain.

For example:

AIEN can propose:

```text
Hypothesis
GoalPriority
Prediction
PlanCandidate
```

Omega can author:

```text
RealizationCandidate
SemanticProof
CostEstimate
Transformation
```

AEGIS can author:

```text
PolicyDecision
CapabilityRequest
RevocationIntent
AuthorityConstraint
```

The trusted root alone creates/revokes physically enforceable capabilities.

---

# 28. RESOURCE OWNERSHIP

Hardware belongs to the whole organism.

Not:

```text
AIEN GPU
OMEGA GPU
AEGIS CPU
```

Instead resources advertise capabilities:

```text
MachineResource {
    capabilities
    topology
    locality
    capacity
    occupancy
    trust domain
    measured costs
}
```

Reactions state requirements.

Placement chooses a realization.

---

# 29. PHYSICAL COST MODEL

Retain Omega's physical optimization role.

Each realized reaction should be measurable in terms such as:

```text
bytes read
bytes written
coherence traffic
cache pressure
synchronization
barriers
CPU cycles
GPU cycles
tensor utilization
latency
energy
peak live memory
```

The target is not maximum activity.

The target remains:

```text
minimum physical work
per required semantic result
```

---

# 30. BOOT BECOMES RECOVERY / AWAKENING

Normal conceptual lifecycle:

```text
AWAKEN
  ↓
RESTORE LAST VALID GENERATION
  ↓
RECONSTRUCT TRANSIENT PHYSICAL STATE
  ↓
REBUILD REACTION INDEXES
  ↓
REESTABLISH CAPABILITIES
  ↓
RESTORE RESIDENT MODEL / MEMORY
  ↓
RESUME LIFE
```

Boot is not "launch application."

The active system is intended to remain resident.

The existing design already treats the intelligence as primarily resident state and persistence as continuity/recovery rather than normal cognitive residence.

---

# 31. FAILURE CONTAINMENT

One bad reactive region must not collapse the organism.

Provide:

```text
reaction budgets
graph-region quarantine
capability revocation
worker cancellation
generation rollback
GPU reset
reconstruction from durable state
known-good realization fallback
```

AEGIS and Physics must remain capable of stopping execution even if adaptive cognition is unhealthy.

---

# 32. MIGRATION RULE

DO NOT rewrite the entire system in one pass.

The legacy orchestrated runtime becomes the reference oracle.

Migration state:

```text
LEGACY
  ↓
SHARED OBJECT MIRROR
  ↓
REACTION SHADOW
  ↓
REACTION AUTHORITATIVE FOR PURE WORK
  ↓
REACTION AUTHORITATIVE FOR SANDBOXED WORK
  ↓
REACTION AUTHORITATIVE FOR CAPABILITY-BOUND EFFECTS
  ↓
LEGACY FALLBACK
  ↓
LEGACY RETIRED
```

The old runtime remains available until the new path proves correctness and recovery.

---

# 33. IMPLEMENTATION PHASE R0 — FREEZE THE CONTRACT

Before code changes, write one ADR defining the eight locked statements (Part I, "Decision"). No module migration until this ADR exists.

Gate: `R0_REACTION_ARCHITECTURE_LOCKED`

# 34. R1 — SHARED OBJECT POOL

Build the canonical resident object substrate. Requirements: logical IDs; generations; versioning; type metadata; content identity where applicable; authority references; persistence class; atomic publication; stale-reference rejection. Do not yet alter cognition.

Gate: `R1_SHARED_WORLD_PASS`

# 35. R2 — CROSS-ENGINE ABI

Make CPU/GPU interaction reference logical objects. Requirements: pointer-free semantic identity; generation-tagged handles; bounded rights; CPU/GPU registry; stale handle rejection; shared publication protocol. Keep physical addresses internal.

Gate: `R2_CROSS_ENGINE_ABI_PASS`

# 36. R3 — REACTION CORE

Implement: ReactionDescriptor; DependencyIndex; ReadySet; Invalidation; AtomicPublication; ReactionLifecycle; CausalId. Initially run only deterministic pure reactions.

Test: single dependency; multiple dependency; fan-out; fan-in; invalidation; concurrent publication; stale input; duplicate wake.

Gate: `R3_REACTION_CORE_PASS`

# 37. R4 — CAUSAL TRACE

Before scaling the system, implement causal crumbs. Require every reaction test to prove: trigger explainable; inputs explainable; authority explainable; outputs explainable; ancestry reconstructible.

Gate: `R4_CAUSAL_TRACE_PASS`

# 38. R5 — CONTENTION AND MODULATION

Implement resource admission and global modulation.

Test: 1000 ready reactions; bounded compute; interactive work outranks background; critical recovery outranks optimization; background work does not starve forever.

Gate: `R5_RESOURCE_ARBITRATION_PASS`

# 39. R6 — STORM AND LOOP CONTROL

Implement: deduplicated wakeups; fan-out limits; activation budgets; oscillation detection; livelock detection; backoff; quarantine. Adversarial tests should intentionally construct pathological dependency graphs.

Gate: `R6_REACTION_STABILITY_PASS`

# 40. R7 — CAPABILITY ROOT

Move AEGIS from synchronous gatekeeping toward resident authority semantics. But first establish the hard root: unforgeable capability mint; verification; revocation; generation binding; rights bounds; delegation; leases.

Attack tests — all must fail: forged capability; modified capability; stale capability; wrong subject; wrong resource; generation replay; revoked capability; rights amplification.

Gate: `R7_CAPABILITY_ROOT_PASS`

# 41. R8 — AEGIS RESIDENT AUTHORITY

Represent authority relationships in the live graph. Fast path: valid existing capability → execute. Slow path: new authority required → policy reasoning / approval / mint. Measure the reduction in synchronous policy round trips.

Gate: `R8_CONSTITUTIONAL_AEGIS_PASS`

**Scope note (2026-09-28).** This note fixes what R8 refers to. It does not
change subsystem responsibilities.

- **"AEGIS" here is the verifier faculty** of ARCHITECTURE §2.5. It is not
  the `aegis-runtime` program. That program is legacy orchestration: it
  becomes the reference oracle (Part I) and is written in Rust. R8 does not
  build on it.
- **The authority root is the native AIENOS capability authority**
  (ARCHITECTURE §2.7, aienos `native/capability/`, in C).
- **FORGE (formerly PHYSICS) realizes.** It "is not the kernel and is not the
  policy authority" (FORGE.md).

R8 therefore means four things:

1. Authority relationships are live world objects: which subject holds which
   capability, for which object, under which lease and epoch.
2. A reaction holding a valid existing capability proceeds with no policy
   round trip.
3. A reaction that needs new authority publishes a request object. An AEGIS
   policy reaction evaluates it, and only the AIENOS root mints the grant.
4. The reduction in synchronous policy round trips is measured against the
   current `spark-aegis` shell-out path.

# 42. R9 — GENERATION BARRIER

Implement coherent durable learning.

Test: continuous reactions during candidate generation; in-flight work at barrier; failed verification; crash during generation publication; recovery to old generation; successful promotion.

Required invariant — after recovery: OLD VALID GENERATION or NEW VALID GENERATION; never torn generation.

Gate: `R9_GENERATION_BARRIER_PASS`

# 43. R10 — OMEGA AS CONTINUOUS REALIZATION FACULTY

Connect Omega realization search to reactive demand:

```text
semantic operation becomes hot
       ↓
cost evidence crosses threshold
       ↓
optimization reaction activates
       ↓
Omega synthesizes candidate
       ↓
candidate verified
       ↓
benchmarked
       ↓
recorded
       ↓
eligible for future selection
```

The production path need not stop while optimization occurs.

Gate: `R10_CONTINUOUS_OMEGA_PASS`

# 44. R11 — AIEN AS CONTINUOUS COGNITIVE FACULTY

Remove assumptions that cognition exists only during request handling. AIEN should react to: new observation; goal change; unexpected result; new memory; failed prediction; uncertainty; human input; resource change; new evidence. It publishes semantic objects back into the shared world.

Gate: `R11_CONTINUOUS_COGNITION_PASS`

# 45. R12 — RESIDENT CPU/GPU COOPERATION

Move selected reaction classes onto persistent GPU workers. Demonstrate: CPU reaction; GPU reaction; shared object dependency; capability validation; GPU result publication; CPU observation; no full-object serialization.

Gate: `R12_RESIDENT_COOPERATION_PASS`

# 46. R13 — UNIFIED GOLDEN PATH

Construct one end-to-end demonstration: human provides goal → AIEN reaction interprets objective → Omega reaction finds suitable realization → AEGIS state: existing capability permits sandbox experiment → resource scheduler places computation → GPU executes → evidence published → AIEN updates belief → Omega discovers improved realization candidate → verification passes → generation barrier promotes verified improvement → system continues operating throughout.

There must be no central function manually sequencing those steps. Their ordering must arise from dependencies.

Gate: `R13_LIVING_SYSTEM_PASS`

# 47. R14 — FAILURE GOLDEN PATH

While the organism is active: corrupt candidate realization; forge capability; create reaction cycle; saturate GPU; kill GPU resident worker; crash during checkpoint. System must: contain; revoke; recover; reconstruct; preserve evidence; resume.

Gate: `R14_LIVING_RECOVERY_PASS`

# 48. R15 — PERFORMANCE PROOF

Compare against the existing pipeline. Measure at minimum: semantic operations / second; reaction activation latency; dependency propagation cost; scheduler overhead; AEGIS fast-path cost; generation barrier latency; serialization bytes; CPU↔GPU synchronization count; memory traffic; GPU residency; resource utilization; wasted reactions; invalidation rate; conflict rate; wake amplification; causal-trace overhead; energy per semantic result.

Do not accept architecture on aesthetic grounds.

Gate: `R15_REACTION_PERFORMANCE_PASS`

# 49. R16 — RETIRE CENTRAL ORCHESTRATION

Only after prior gates pass: remove central sequencing where reactions now provide equivalent or stronger behavior. Do not remove: known-good fallback; recovery path; deterministic maintenance controls; trusted capability root; generation mechanism; evidence.

Gate: `R16_ORCHESTRATOR_RETIRED`

---

# 50. CODE ORGANIZATION

Do not create `aien-runtime/`, `omega-runtime/`, `aegis-runtime/` that independently own schedulers and resource pools.

Prefer shared primitives resembling:

```text
runtime/
    object/
    reaction/
    dependency/
    publication/
    causal/
    generation/
    resource/
    recovery/

faculties/
    cognition/
    semantics/
    authority/

physics/
    capability/
    memory/
    cpu/
    accelerator/
    interrupt/
    reset/
```

Exact repository placement should follow the current tree rather than forcing these names literally.

The important rule is dependency direction.

# 51. DEPENDENCY RULE

The faculties may depend on the common semantic/reaction abstractions. They must not depend cyclically on each other's service APIs.

Bad: AIEN calls Omega; Omega calls AEGIS; AEGIS calls AIEN.

Good: AIEN publishes semantic state; OMEGA observes eligible semantic state; AEGIS authority state participates in readiness.

Communication is predominantly through shared typed state.

# 52. REACTION DESCRIPTOR — FIRST REFERENCE FORM

```rust
struct ReactionDescriptor {
    id: ReactionId,

    trigger_set: Vec<Dependency>,
    read_set: Vec<Dependency>,
    write_set: Vec<ObjectSelector>,

    required_capabilities: Vec<CapabilityRef>,
    resource_requirements: ResourceRequirements,

    priority_class: PriorityClass,
    generation: GenerationId,

    realization: RealizationSelector,

    retry_policy: RetryPolicy,
    conflict_policy: ConflictPolicy,
    causal_parent: Option<CausalId>,
}
```

This is a bootstrap representation. Do not canonize Rust layout as Omega semantics.

# 53. REACTION RESULT — FIRST REFERENCE FORM

```rust
enum ReactionOutcome {
    Published { mutations: Vec<Mutation>, evidence: Vec<EvidenceRef> },
    BlockedAuthority { requirements: Vec<CapabilityRequirement> },
    BlockedResource { requirements: ResourceRequirements },
    Invalidated,
    Conflict,
    Failed { evidence: EvidenceRef },
}
```

REFERENCE REALIZATION != PERMANENT SEMANTIC DEFINITION.

# 54. STANDARD TEST INVARIANTS

Every implementation stage must preserve:

```text
I1  semantic identity is not physical address
I2  stale generations cannot mutate current state
I3  capabilities cannot be forged by semantic code
I4  revoked authority cannot execute
I5  speculation cannot silently externalize effects
I6  concurrent publication cannot create torn objects
I7  causal history exists for meaningful committed changes
I8  generation recovery produces a coherent world
I9  intelligence cannot promote itself past authority policy
I10 failed optimization cannot destroy last-known-good realization
I11 GPU failure cannot destroy durable identity
I12 resource starvation is bounded/detectable
I13 reaction storms are detectable/containable
I14 livelock is detectable
I15 irreversible effects remain attributable
I16 semantic meaning remains stable across realization changes
```

# 55. VERIFICATION STANDARD

Preserve the existing ladder: V0 STRUCTURAL; V1 DIFFERENTIAL; V2 PROPERTY; V3 ADVERSARIAL; V4 SYMBOLIC; V5 PROOF-CARRYING.

Search, optimization, neural proposals, generated code, and heuristic decisions are not themselves trust. The existing plan already separates untrusted search/generation from semantic contracts, verification, physical authority, and effect admission.

Apply the ladder to reaction infrastructure itself.

# 56. DEVELOPMENT RULE

For every major primitive: 1. define semantics; 2. build simple human reference; 3. test; 4. adversarially break; 5. record evidence; 6. optimize; 7. allow Omega to synthesize alternatives; 8. verify them; 9. measure them; 10. select.

Do not let Omega optimize a primitive before its behavior is stable enough to serve as an oracle.

# 57. WHAT NOT TO DO

Do not build a massive actor framework and call it an organism.
Do not create one queue for everything.
Do not implement global graph scans.
Do not encode authority as editable booleans.
Do not make neural inference the scheduler.
Do not make AEGIS approve every cache read.
Do not flatten everything into JSON.
Do not use text logs as canonical evidence.
Do not persist raw pointer graphs.
Do not make GPU launch boundaries semantic boundaries.
Do not eliminate checkpoint barriers.
Do not remove rollback.
Do not allow "continuous learning" to silently rewrite trusted state.
Do not remove deterministic operator control.
Do not conflate high utilization with useful progress.

# 58. SUCCESS CRITERION

The architecture is successful when this statement is technically true:

```text
The system does not wait for AIEN,
then Omega,
then AEGIS.

A changing resident world continuously
activates whatever cognition,
semantic transformation,
authority reasoning,
verification,
memory,
and physical work is presently valid.

AIEN, Omega, and AEGIS are not services
coordinating a machine.

They are faculties of one persistent
computational organism.
```

And simultaneously:

```text
No faculty can forge authority.

No realization can become trusted
merely because intelligence proposed it.

No durable belief changes without
a coherent generation transition.

No important action becomes
unexplainable merely because
the system is concurrent.
```

# 59. CANONICAL ARCHITECTURAL SENTENCE

See Part I.

# 60. EXECUTION INSTRUCTION

Treat this document as the architectural decision. Do not redesign it back into a service pipeline.

Before modifying code:

1. Inspect the current repository and identify the real modules implementing runtime orchestration, Omega object state, AEGIS/capability enforcement, accelerator-world state, evidence/provenance, and generation/checkpoint behavior.
2. Produce a code-grounded migration map from existing modules to R0–R16.
3. Identify which pieces already satisfy each milestone and do not rewrite working implementations unnecessarily.
4. Preserve every currently passing correctness, security, accelerator, and regression test.
5. Implement milestones sequentially where one establishes an invariant needed by the next.
6. Parallelize work only where ownership is disjoint.
7. Each milestone must add adversarial tests and a machine-readable evidence receipt.
8. Never claim a gate has passed from mocks when the gate requires physical hardware.
9. Never replace the trusted capability boundary with semantic convention.
10. Never delete the last known-good implementation before rollback and reproduction are proven.

When architectural documentation disagrees with executable behavior: CODE + REPRODUCIBLE EVIDENCE wins for current implementation truth. When current code disagrees with this ADR about the desired destination: THIS ADR defines the target architecture.

First deliverable: `CURRENT_CODE_TO_R0_R16_MIGRATION.md` (current module; current responsibility; target responsibility; keep / adapt / replace; dependencies; risk; tests; migration milestone; parallelization group).

Then begin with the smallest implementation that proves:

```text
shared object
→ dependency change
→ reaction becomes ready
→ capability validates
→ reaction executes
→ atomic publication
→ causal crumb
```

with no central semantic orchestrator deciding the sequence. That is the first heartbeat of the new architecture.
