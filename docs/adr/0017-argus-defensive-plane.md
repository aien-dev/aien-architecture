# ADR 0017: ARGUS Is the Defensive Plane; It Observes, Detects, and Proposes, but Never Authorizes

**Status:** Proposed, awaiting operator ratification (Drake). Amended 2026-09-29 after the hostile review and the first live performance measurement (event ABI v1.1).
**Date:** 2026-09-28 (amended 2026-09-29)
**Related:** ADR 0005 (effect broker), ADR 0006 (vault-only secrets), ADR 0013/0014 (FORGE realizes, AEGIS verifies, AIENOS owns capabilities), ADR 0015 (resident semantic store), ADR 0016 (resident reaction architecture; §31 failure containment), [`docs/07-security-effects-secrets.md`](../07-security-effects-secrets.md).
**Implementation home:** `aien-dev/aienos`, directory `native/argus/`, beside `native/capability/` (the C capability authority). Shared contract: `native/argus/argus_abi.h` (event ABI version 1, revision 1.1: same 128-byte layout, new rules).
**Citation:** from other repositories, cite this decision as ARCH-0017.

---

## In plain words (read this first)

AIEN already has a guard at the door. **AEGIS** decides who is allowed to do what, and the capability authority in AIENOS hands out the permission slips (capabilities) and takes them back. What AIEN does not yet have is a **watchman**: something that keeps an eye on the whole building, notices when something happens that should be impossible (a revoked permission slip that still worked, a forged one, a program that changed after it was approved, a machine that is not who it says it is), writes it down in a tamper-evident log, and raises the alarm.

That watchman is **ARGUS**. The one-line rule is:

> **AEGIS protects authority. ARGUS protects the system.**

ARGUS can see and report. It can *ask* for something to be locked down. It can never lock anything down by itself, never grant or refuse permission on its own opinion, and never slow down or stop AIEN's ordinary thinking. If the watchman falls asleep, crashes, or falls behind, the building keeps running; only the one door whose safety depended on the watchman closes.

**What Drake is being asked to ratify:**

1. The boundaries: what ARGUS is responsible for, and the explicit list of things it must never become (section 11).
2. The chain for locking something down: ARGUS proposes, AEGIS decides, the existing authority carries it out, and evidence is always written (section 4).
3. The shape of a security event (a fixed 128-byte record with no secrets in it), who is allowed to write one, the rules that decide whether an event is believed and applied, and what happens when events arrive faster than ARGUS can read them (section 6, with the gaps that remain in section 16).
4. The speed and failure promises (sections 7 and 8). The first design was measured on the Spark and was far too slow; section 7 now carries the measured numbers and the redesign ("report changes, count routine use"), which must be measured again before the speed promise counts as met.
5. That the first milestone, **ARGUS-0**, is only the foundation: the event format, the bounded queues, the watchman's memory, and the "this should be impossible" checks. It can be switched on inside Omega's runtime for testing (off by default), and it does not lock anything down (sections 13 and 15).
6. The six known gaps between the original brief and the code, and how each is handled: four standing, one resolved, and one new (the speed target could not be met by the first design) (section 14).

Everything below is the precise version of those six points.

---

## Words used in this document

- **Capability:** a permission slip issued by the authority; it names who holds it, what it covers, and what it allows.
- **Principal (subject):** the party a capability was issued to, identified by a number the authority assigns.
- **Generation:** a counter that goes up each time a slot or object is reissued, so an old copy can be told apart from the current one.
- **Digest:** a short fingerprint (here SHA-256, 32 bytes) of some content; if the content changes by one bit, the fingerprint changes.
- **Chain digest:** a fingerprint that folds in the previous fingerprint, so the whole history is sealed in order.
- **Shadow state:** ARGUS's own copy of the facts it has been told (what was issued, revoked, admitted), kept only to cross-check.
- **Watermark:** a fill level on the event queue above which lower-priority events are refused and counted.
- **Epoch root:** a sealed checkpoint of the chain at the end of a stretch of history.
- **TPM:** a security chip on the machine that can vouch for a stored value.
- **Attestation:** a machine proving what software and identity it is running.
- **p99:** the time within which 99 out of 100 operations finish (p50: half of them).
- **Producer:** the piece of trusted AIEN code that writes security events (for example AEGIS when it grants a capability).
- **Stream:** one producer thread's own numbered sequence of events. Each thread has its own queue and its own count, so threads never wait on each other.
- **Transition event:** an event that reports a change of state (a grant, a refusal, a revocation, a World commit, an error). These are rare and are always reported in full.
- **Use summary:** one event that says "capability X was used successfully N times since the last summary, at generations between A and B". It replaces one event per use.
- **Observer callback:** a hook inside the capability authority that tells a listener "I just issued" or "I just revoked", so the report comes from the authority itself.
- **Tombstone:** the record ARGUS keeps for a machine after it is removed, so its trust level and quarantine survive if it tries to rejoin.

---

## Part I: Decision record

### Context

ADR 0016 made AIEN, Omega, and AEGIS faculties of one resident reaction system. AEGIS became the constitutional authority faculty: it decides capability policy, and only the capability root turns a decision into an enforceable capability. ADR 0016 §31 requires that the system can stop a bad region "even if adaptive cognition is unhealthy", and §20 to §22 require that every consequential transition is causally traceable without logging everything as text.

Nothing today watches the system *as a whole* for violations that no single decision point can see: a capability used after its revocation was recorded, a generation that went backwards, a World commit that skipped a generation, an artifact whose digest changed after admission, a credential lease used by the wrong subject. Each producer checks its own rule at its own boundary. Nobody cross-checks the producers against each other and against history.

As of 2026-09-28, no ARGUS type, queue, detector, or document exists in any repository. The canonical authority is C (`native/capability/aienos_capability.{c,h}` in `aienos`; Omega links it). Omega's runtime has its own C policy faculty (`rx_aegis`) and generation store (`rx_generation`).

### Decision

The following statements are locked. No ARGUS milestone may contradict them.

1. **ARGUS IS A DEFENSIVE PLANE, NOT AN AUTHORITY.** It observes security events, keeps deterministic shadow state, detects violations of hard invariants, records evidence, and proposes containment. It never mints, validates, re-checks, grants, or revokes a capability.
2. **AEGIS PROTECTS AUTHORITY. ARGUS PROTECTS THE SYSTEM.**
3. **A FINDING IS EVIDENCE, NEVER AUTHORITY. A CONTAINMENT REQUEST IS A PROPOSAL, NEVER AN ACTION.**
4. **ARGUS NEVER SITS IN THE PATH OF AUTHORIZED WORK.** Its failure, lag, or overflow never freezes authorized AIEN work. Fail-closed happens only at the one authority boundary that depended on the missing evidence, and only where policy said so in advance.
5. **SECURITY EVENTS ARE FIXED, SMALL, SECRET-FREE, AND DETERMINISTIC.** 128 bytes, digests instead of payloads, no wall clock in anything that is hashed.
6. **EVERY FINDING AND EVERY CONTAINMENT DECISION LEAVES EVIDENCE**, chained so that removal or reordering is detectable.

---

## Part II: Normative standard

The words MUST, MUST NOT, SHOULD, and MAY carry their usual normative meaning.

### 1. ARGUS responsibility

ARGUS is responsible for exactly five things:

| Duty | Meaning |
|---|---|
| **Observe** | Receive security events from producers (the capability authority, AEGIS, the World/generation store, the effect broker, and later the credential vault, provider registry, artifact admission, and Fabric) through a bounded queue. |
| **Remember** | Maintain resident, deterministic shadow state: what capabilities it has seen minted and revoked and at what generation, which machines joined with which identity, which artifacts were admitted with which digest, which leases exist for which subject and scope, which providers are quarantined, and which World generation was last committed. |
| **Detect** | Run detectors over each event against the shadow state *as it stood before that event*, and emit findings. In ARGUS-0 every detector is a hard invariant with deterministic confidence. |
| **Record** | Append every accepted event and every finding to a digest chain, so that deletion, insertion, or reordering of the record is detectable. |
| **Propose** | For a finding that warrants it, build a typed containment request and hand it to AEGIS. |

ARGUS answers the question "did something happen that the rules say cannot happen, and what is the evidence?" It does not answer "is this allowed?" (AEGIS and the authority do) or "what does this mean?" (Omega and Cortex do).

### 2. The separations

#### 2.1 ARGUS and AEGIS

| | AEGIS | ARGUS |
|---|---|---|
| Protects | authority: who may do what | the system: that what happened is consistent with the rules and the record |
| Decides | policy (GRANT, DENY, ESCALATE, REVOKE in Omega's `rx_aegis`) | nothing; it reports |
| Holds | the policy; the capability root holds the admin handle | shadow copies of outcomes only |
| Acts | through the capability root | never; it proposes to AEGIS |
| When it is busy | when authority changes | continuously, off the hot path |

Normative rules:

- ARGUS MUST NOT hold the AIENOS capability admin handle (`AienosCapAdmin`) and MUST NOT call the authority's mint, validate, revoke, reclaim, clock, or epoch operations.
- ARGUS MUST NOT re-validate a capability. The producer copies the authority's own result code (the `AIENOS_CAP_*` code, or `RX_GEN_*` from the generation store) into the event. ARGUS cross-checks that recorded outcome against its shadow state. Example: the shadow says capability 7 was revoked at sequence 40, and at sequence 55 an event reports capability 7 used with outcome OK. That is a finding (revoked capability used), not a new authorization decision.
- AEGIS MUST treat a containment request as input to its own policy, exactly like any other request. ARGUS findings carry no special power to bypass AEGIS rules or the root's own refusals.

#### 2.2 ARGUS and the World

The World (the generation-addressed object world of ADR 0015/0016) is the system's state. ARGUS is not part of it.

- ARGUS MUST NOT write World objects and MUST NOT take part in a generation barrier's decision to promote.
- ARGUS observes World commits as events (a 64-bit World generation matching the generation store's ids, the store's id in the object field, a 32-byte digest, and an object's own generation carried in the resource field when needed) and checks provenance consistency per store: a committed World generation is that store's prior one plus one, and a digest does not conflict with what was already committed for that generation (section 3, row 9).
- One process can hold several generation stores (lane H found three in one Omega test process). ARGUS therefore keeps a separate World record for each store id, not one for "the" World.
- ARGUS state is not World state. It is not promoted, rolled back, or reconstructed with the World. It is reconstructed from its own evidence chain.

#### 2.3 ARGUS and Cortex

Cortex remembers meaning. ARGUS remembers security facts.

- ARGUS MUST NOT use Cortex, embeddings, or any model on its detection path.
- ARGUS MUST NOT become Cortex: it keeps bounded, typed tables, not an open-ended memory.
- ARGUS MAY later publish summarized findings *to* Cortex as ordinary evidence so that AIEN can learn from them, through the normal publication path and without secrets. Cortex never feeds back into a hard-invariant decision.

#### 2.4 ARGUS and Fabric

Fabric is the set of machines working as one. ARGUS on each machine watches that machine's events.

- ARGUS MUST NOT decide Fabric membership or trust. It records `MACHINE_JOINED`, `MACHINE_TRUST_CHANGED`, and `MACHINE_REMOVED` events and checks that later events carry the identity recorded at join.
- Cross-machine correlation of ARGUS evidence is a later rung (ARGUS-7) and depends on cryptographic machine identity, which does not exist yet (Deviation 3).

### 3. Hard invariants

A **hard invariant** is a rule whose violation is never legitimate: if the event and the shadow state disagree in this way, something is broken or someone is attacking. ARGUS-0 defines sixteen, each with a stable code that is append-only and never renumbered. Codes 1 to 12 are the original set; codes 13 to 16 were appended by this amendment after the hostile review:

| Code | Finding | Plain meaning |
|---|---|---|
| 1 | Forged capability | A capability reference was used or granted that ARGUS never saw minted, or the authority itself said it was forged. |
| 2 | Stale generation | A reference's generation is older than the current generation ARGUS knows for that slot. |
| 3 | Revoked capability used | ARGUS saw the revocation, then saw a use reported as successful. |
| 4 | Artifact digest unexpected | Something began executing whose digest was never admitted, or an admitted digest changed. |
| 5 | Signature invalid | A producer reported a signature failure on a trusted-path object. |
| 6 | Credential scope violation | A credential lease was used successfully by another subject or outside its scope. |
| 7 | Machine identity mismatch | An event's machine identity is not the one recorded at join, or the machine is unknown. |
| 8 | Effect class unauthorized | A successful operation had an effect class (ephemeral, evidence, external) beyond what the capability's rights permit. |
| 9 | World provenance inconsistent | For one store: a World commit skipped ahead or went backwards, or repeated an already-committed generation with a **different** digest. A repeat with the **same** digest is the same fact reported twice: it is idempotent and silent, not a finding. A commit is adopted only at the prior generation plus one (or as the store's first commit); a flagged commit is never adopted, so a forged skip cannot drag the record along. World records are kept per store id. |
| 10 | Quarantined use | A provider or machine was used successfully after quarantine. |
| 11 | Telemetry loss | CRITICAL or SECURITY events were dropped: there is a gap in the evidence. |
| 12 | Sequence anomaly | A producer stream replayed or reordered its sequence numbers. (A gap is not a finding: gaps are expected when the queue refuses events, and refusals are counted separately.) |
| 13 | Authority replay | A grant arrived that is not strictly newer than what ARGUS already holds for that slot, or a revocation arrived for a slot ARGUS never saw issued. Raised by the core's apply step; the event is not applied. |
| 14 | Subject mismatch | A capability was used successfully by a principal other than the one it was granted to. |
| 15 | Trust escalation | An event tried to raise a machine's trust level (or a joining machine declared itself more trusted than "observed"). The raise is ignored. |
| 16 | Malformed event | The event failed validation. Raised by the core; the event is neither applied nor chained, but the finding itself is recorded. |

The list of hard invariants is exactly this table. Adding one is an append to the table under ADR amendment (codes 13 to 16 are such an append); removing or renumbering one is forbidden.

### 4. Containment authority

Containment means limiting damage: revoking a capability, freezing or restricting a principal, quarantining a machine or provider, revoking a credential lease, rejecting an artifact, requiring re-attestation, raising the effect class a principal needs, or pausing external effects. The chain is fixed:

1. **ARGUS proposes.** It builds an `ArgusContainmentRequest`: incident id, recommended containment class, severity, finding code, principal, target capability reference (`AienosCapRef` layout), machine identity, and the digest of the finding that justifies it.
2. **AEGIS authorizes.** AEGIS evaluates the request under its policy like any other request. It may grant, deny, or escalate to the operator. AEGIS MAY decline, and declining is itself recorded.
3. **The canonical executor acts.** Only the component that already owns the power carries it out: the capability root revokes, AIENOS cancels workers or resets a GPU (ADR 0016 §31), the provider registry quarantines, the effect broker pauses external effects. ARGUS never gets a second, private way to do any of these.
4. **Evidence always.** The finding, the request, AEGIS's decision (including a refusal), and the executor's result are all recorded and chained. There is no containment without evidence, and no silent refusal.

The containment class ARGUS attaches to a finding is a *recommendation*. It MUST NOT be read as a decision.

ARGUS-0 defines the request type only. ARGUS-1 wires it to AEGIS.

### 5. Synchronous and asynchronous defensive action

By default ARGUS is **asynchronous**: a producer writes an event into the queue and continues immediately. Detection happens later, off the producer's path. The consequence of a finding (a containment request) arrives after the fact.

**Synchronous** action means an authority boundary refuses an operation *in the moment*, citing an ARGUS invariant. It is allowed only under all of these conditions:

- The invariant is on the pre-established hard-invariant list (section 3). No statistical, heuristic, or model-derived signal may ever cause a synchronous refusal.
- Policy set **in advance** marks that detector as synchronous-eligible (the per-detector `sync_allowed` flag). The flag is policy, fixed before the operation happens; it is never raised on the fly by ARGUS.
- The refusal is performed by the authority boundary that owns the operation, using its own normal refusal path, not by ARGUS.
- The refusal **fails closed**: if the synchronous check cannot complete (for example the shadow state needed is unavailable), that one operation at that one boundary is refused and the refusal is recorded. Nothing else stops.

A **report is not evidence**. Four event kinds are a producer saying "I saw something bad" (integrity violation, signature failure, stale generation, forged capability). When ARGUS's own shadow state does not back such a report up, the finding is recorded but is never synchronous-eligible and recommends no containment. Otherwise one producer could aim a freeze at any principal it names (the hostile review's "confused deputy").

The initial policy (which of the sixteen detectors are synchronous-eligible) is recorded with the detector table in code and ratified with ARGUS-1. ARGUS-0 defines the flag and does not wire any synchronous refusal.

### 6. Security event semantics

#### 6.1 The event

Every security event is an `ArgusEvent` of exactly **128 bytes**, with the version byte first. It contains no pointers, no variable-length fields, and no field sized like a secret. Its fields, in plain terms:

- version, class, kind, effect class, outcome, flags (two marker bits, and a 14-bit stream id, section 6.6);
- **sequence**: per stream, strictly increasing from 1; the top value is reserved and rejected;
- **tick**: the authority's logical clock (`aienos_cap_clock`), read only for transition events; routine uses and use summaries carry 0 (section 7);
- principal (the authority's subject; there is no second principal type);
- result code copied from the authority or producer;
- capability reference (32-bit id, 64-bit generation). Id 0 is the authority's own office capability, a real capability checked like any other; "no capability" is a separate reserved value (section 6.7);
- object id, and the World generation (64-bit, the same width as the generation store's ids); an object's own generation travels in the resource field when a kind needs it;
- resource (an authority resource, rights mask, scope, or count, depending on kind);
- a 32-byte machine identity slot (provisional, see Deviation 3);
- a 32-byte evidence digest of the referenced object, artifact, or policy.

Event kinds have stable numbers that are append-only. Revision 1.1 appends one kind, the capability use summary (section 7). Unknown kinds, classes, or outcomes, or any event that breaks a validate rule (section 6.9), make the event malformed; malformed events are rejected, never guessed at, and raise finding 16.

#### 6.2 Time and determinism

- There is **no wall-clock time in any hashed field**. Order is established by the producer sequence and the authority logical tick.
- Given the same event stream, ARGUS MUST produce a byte-identical sequence of findings and a byte-identical state digest. This is tested.
- Detectors MUST be pure: no allocation, no I/O, no global state, no clock.

#### 6.3 Classes and drop policy

Events carry one of four classes that say what happens when the queue fills:

| Class | When the queue is under pressure |
|---|---|
| **CRITICAL** | Never dropped silently. May use the full queue capacity. If it still cannot be queued, a sticky overflow counter is set and ARGUS raises a telemetry-loss finding (code 11): the evidence gap itself becomes evidence. |
| **SECURITY** | Refused above the SECURITY watermark, and counted. Loss raises code 11. |
| **AUDIT** | Refused above the lower AUDIT watermark, and counted. |
| **INFORMATIONAL** | First to be refused, and counted. |

Pushing onto the queue MUST never block the producer; a full queue returns "full" immediately. Refusal counts are turned by the reading side into `TELEMETRY_DROPPED` events marked as synthesized by ARGUS, so that loss enters the same chained record as everything else. Only ARGUS itself may produce such a loss report: the "made by ARGUS" mark is rejected on any other kind and on anything arriving from a producer, so nobody can forge an evidence gap. The queue also refuses an event whose class is weaker than its kind allows (section 6.8); those refusals are counted apart and are never reported as loss.

A producer cannot dodge this policy by mislabelling: every kind has a minimum class (section 6.8), so a revocation cannot be labelled informational and quietly dropped first.

#### 6.4 No secrets, digests not payloads

An event carries digests and identifiers, never contents. Specifically it MUST NOT carry a capability token, a credential, a key, a prompt, a model input or output, or any payload. Where content matters, the event carries a SHA-256 digest of it.

#### 6.5 Who may write an event (producer trust boundary, v1)

In ARGUS-0 an event's fields are believed because of **where it came from**, not because it proves anything. The rule is therefore about who can reach the queue:

- Only AEGIS and runtime code inside the trusted AIEN process may push events. Cognition (models, plans, reactions acting for a model) has no path to the queue. This is the same split the authority already uses between its admin handle and its read-only view.
- The event has no field saying which producer wrote it, and nothing is signed. Cryptographic proof of which producer wrote an event is ARGUS-3 work. Until then, a bug or compromise inside the trusted process can write believable events; section 16 lists what that leaves open.

#### 6.6 Streams

Each producer thread owns its own queue and its own **stream id** (14 bits carried in the flags word; 0 is the default stream). ARGUS keys sequence checking by (machine, stream id, the "made by ARGUS" mark), so each thread counts its own sequence from 1 and never shares a counter or a lock with another thread. Replays and reordering are detected per stream (code 12).

#### 6.7 Capability 0 and "no capability"

Slot 0 in the authority is the **office capability**, the authority's own standing credential. It is a real capability and ARGUS checks its use like any other. "This event concerns no capability" is a separate reserved value that can never be a real slot. (The first design used 0 for "none", which would have hidden every use of the office capability.)

#### 6.8 Minimum class per kind

Every kind has a weakest class it may carry. Producers may label an event **stronger** than its minimum, never weaker; a weaker label is malformed, both at validation and at the queue.

| Minimum class | Kinds |
|---|---|
| CRITICAL | capability revoked, credential lease revoked, artifact rejected, external effect committed, machine trust changed, machine removed, provider quarantined, policy changed, runtime build changed, integrity violation, signature failure, stale generation, forged capability, telemetry dropped |
| SECURITY | capability granted, capability denied, credential lease created, artifact admitted, artifact activated, machine joined, provider discovered, provider changed, external effect requested, external effect denied, World committed |
| AUDIT | capability used, capability use summary, credential lease used, provider used |

No version 1 kind has an INFORMATIONAL floor. The INFORMATIONAL class exists for future kinds; today nothing may fall to it.

#### 6.9 Validate rules (is the event well formed?)

Before anything else, an event is rejected as malformed (code 16, not applied, not chained) if any of these hold:

- the "made by ARGUS" mark is set on any kind other than a telemetry-loss report;
- the capability id is at or above the authority's slot count (256) and is not the "no capability" value;
- the sequence is 0 or the top value (so one event cannot jam a stream's counter at the ceiling);
- the class is weaker than the kind's minimum (section 6.8);
- an external-effect kind does not carry the external effect class.

#### 6.10 Apply rules (what ARGUS believes after an event)

Detectors look at the state before the event; then the core decides whether to fold the event into its shadow state. The rules below close the hostile review's findings that one event could switch an invariant off:

- **Detected but not applied.** An event flagged as a replay or out-of-order (code 12) or as an authority replay (code 13) is recorded as evidence and does not change the shadow state.
- **Grants only move forward.** A grant is applied only when ARGUS has never seen the slot, or the grant's generation is strictly newer than what it holds. An equal or older grant is an authority replay (code 13), so a replayed grant cannot bring a revoked capability back to life. A revocation for a slot never seen issued is also code 13 and creates nothing.
- **Lease ids are never reused.** A second "lease created" for a lease id that is live or revoked is a credential finding (code 6) and is not applied, so nobody can rewrite a lease's owner.
- **Machine trust only moves down in v1.** A joining machine starts no higher than "observed", whatever it claims. A trust change may only move down the order trusted, observed, re-attestation required, restricted, quarantined, untrusted. An upward move is code 15 and is ignored. How a machine legitimately earns its way back up is deferred to ARGUS-1/2. A trust change for a machine ARGUS never saw join is code 7 and creates nothing.
- **Tombstones.** Removing a machine keeps its record, with its trust level and quarantine, so "remove, then rejoin" cannot launder a quarantined machine.
- **World commits** are adopted only at prior plus one per store (section 3, row 9).
- **Use summaries** are checked like uses (detectors 1 to 3) and change nothing in the shadow state.

Every table that fills up is counted and visible in ARGUS's health report (untracked incidents, untracked streams, full tables, events not applied). A full table is never reported as ARGUS losing evidence it did not lose.

### 7. Performance invariants

The **hot path** is what a producer does on AIEN's own time. In revision 1.1 that is, for a routine successful use, one update of a per-thread use table (a count and two generations); for a transition, building one event and pushing it onto the thread's own queue. On the hot path ARGUS MUST NOT use a model, Cortex, a database, disk, network, the TPM, a blocking write, or a lock shared between threads, and SHOULD NOT allocate memory. The reading side (detection and chaining) runs resident, over bounded tables sized at start, with no allocation after start.

Engineering targets:

- less than **2%** throughput reduction on an instrumented AIEN workload;
- less than **5%** increase in p99 latency (the slowest 1 in 100 operations).

#### 7.1 What was measured (first design, lane H, 2026-09-29)

The first design sent one full 128-byte event for every capability check. Lane H wired it into Omega's runtime and measured it on the Spark, pinned to one fast core, on a capability check that on its own takes about 24 nanoseconds (policy decision plus World capability check):

| Setting | Checks per second | Change | p50 / p99 per check |
|---|---|---|---|
| ARGUS off | 41.4 million | baseline | 48 / 64 ns |
| ARGUS on, one event per check | 16.5 million | **-60%** | 80 / 96 ns |

- Building and pushing one event cost about 48 ns at p50 and 64 ns at p99, twice the operation being watched. Reading the authority's clock, which sits behind a lock, added about 16 ns per event.
- Pushing onto the queue alone costs about 4 ns. The queue was not the problem; building an event per check, the clock lock, a single process-wide sequence under one push lock, and cache traffic were.
- On the reading side, taking in one event costs about 1 microsecond, dominated by the SHA-256 chain (the tamper-evident seal). That caps one reader well below a million events per second. In one Omega test (R8), 184,000 of 204,000 use events were refused at the queue's AUDIT level. No SECURITY or CRITICAL event was lost, but the design was generating far more events than any reader could seal.

The 2% target failed by a factor of thirty. The measurement, not intuition, drove the redesign below.

#### 7.2 The redesign: emit on transition, count on use

- **Transitions are reported in full.** Grants, refusals, revocations, World commits, joins, and errors each produce one event. These are rare.
- **Routine successful uses are counted, not reported one by one.** Each producer thread keeps its own use table of 256 slots. A successful check adds one to the count for that (capability, principal) and updates the lowest and highest generation seen. It emits nothing.
- **The aggregation policy** (fixed, not adaptive):
  1. Each thread flushes its table every 4096 checks, and also after a bounded time, whichever comes first, so a quiet thread's uses still reach ARGUS promptly.
  2. A flush emits one **capability use summary** per touched slot: the count, the lowest generation seen, and the highest generation seen.
  3. If the queue refuses a summary, the table keeps counting and the next summary carries the running total. No use is ever silently lost; at worst it is reported late.
  4. Every refusal is still counted by class, exactly as in section 6.3.
  5. ARGUS checks a summary like a use: the capability against issuance (code 1), the highest generation against revocation (code 3), and the lowest generation against the current one (code 2).
- **The clock is read only for transition events.** Uses and summaries carry tick 0, so the hot path never touches the authority's clock lock.
- **One queue and one stream per producer thread.** No push lock; the reader polls all queues (section 6.6).

What this gives up: a use of a revoked capability is detected at the next flush rather than at that instant, and the summary does not say which of the N uses was first. Neither weakens a hard invariant; synchronous refusal (section 5) never depended on the asynchronous stream.

#### 7.3 Re-measurement (the gate)

The 2% and 5% targets MUST be re-measured on revision 1.1, twice:

- on a real workload: the wall-clock time of Omega's R8 host test suite, ARGUS off versus on;
- on the micro-operation: the same ~24 ns capability check as in section 7.1.

If the micro-operation still cannot meet 2%, the evidence is documented and the target is revised by ADR amendment. The benchmark is never tuned to make a number pass.

### 8. Failure behavior

| ARGUS condition | Effect on AIEN |
|---|---|
| ARGUS crashes | Authorized work continues. Producers keep pushing; the queue fills; drops are counted by class. On restart ARGUS records the gap as a telemetry-loss finding. |
| ARGUS lags | Same as above. The producer is never made to wait. |
| Queue overflows | Lower classes are refused first; CRITICAL loss sets a sticky flag and becomes a finding. |
| A synchronous-eligible check cannot complete | Only that operation at that one authority boundary fails closed, and the refusal is recorded. |

ARGUS MUST NOT freeze, pause, or slow authorized AIEN work because ARGUS itself is unhealthy. The failure of the watchman is recorded; it is not a reason to stop the building.

### 9. Evidence

- **Rolling chain digest.** Every accepted event extends a chain: new chain = SHA-256(previous chain, the event's 128 bytes). Findings are digested the same way. Removing, inserting, or reordering anything changes every later chain value.
- **In-house hashing.** SHA-256 is the in-house implementation copied from Omega with a provenance note; no outside library.
- **Epoch roots.** At bounded intervals ARGUS seals the current chain value together with the digest of its shadow state as an epoch root, so a later reader can verify a stretch of history without replaying from the beginning.
- **Hardware-rooted checkpoint (later).** Periodically an epoch root will be anchored in hardware (TPM or the owner-key chain). This waits on the TRUST-1 owner-key work and is always off the hot path.

### 10. Data minimization

ARGUS keeps the minimum needed to detect the sixteen invariants: identifiers, generations, states, rights masks, scopes, sequences, and digests. It keeps no contents, no secrets, and no free text on the detection path. This is enforced by a test: no field in the ARGUS contract is sized like a capability token, and the capability token length constant does not appear anywhere in ARGUS code. Finding and event records follow ADR 0006 and `docs/07-security-effects-secrets.md`: no plaintext secret in logs, receipts, Cortex, or World state.

### 11. What ARGUS does not do

This list is normative. Any design that makes ARGUS do one of these is rejected.

- **ARGUS does not authorize.** It never grants, refuses, mints, validates, re-checks, or revokes a capability, and never holds the capability admin handle.
- **ARGUS does not schedule AIEN.** It never decides what runs, when, or where.
- **ARGUS does not become the Effect Broker.** It never performs or routes an external effect; it may only propose pausing them.
- **ARGUS does not become Cortex.** It keeps bounded typed security tables, not general memory, and never uses a model to decide a hard invariant.
- **ARGUS does not block cognition for semantic analysis.** No thought, plan, or reaction waits for ARGUS to understand it.

### 12. Findings and confidence

A finding (`ArgusFinding`) records the finding code, severity, confidence, whether policy permits synchronous refusal for it, the recommended containment class, the detector, the triggering event's sequence and digest, the earlier evidence event's sequence (for example the revocation), the principal, capability reference, and machine identity.

Confidence has three levels. **Deterministic** is the only level permitted in ARGUS-0 and the only level that may ever justify synchronous refusal. **Statistical** is reserved for ARGUS-5 and later. **Hypothesis** is reserved for the hunting rung. A non-deterministic finding MUST NOT appear in ARGUS-0.

### 13. Milestone ladder

Only the ARGUS-0 scope is binding in this ADR. Later rungs are a proposed order, set by what must exist first; each is ratified separately before it starts.

| Rung | Scope |
|---|---|
| **ARGUS-0** | **Substrate only.** Event ABI (revision 1.1), bounded queues (one per producer thread, each single-producer/single-consumer) with class drop policy, resident deterministic shadow state, the sixteen hard-invariant detectors, findings, digest chain, benchmarks, hostile tests. Test-wired into Omega's runtime behind a switch that is off by default; takes no containment action. |
| ARGUS-1 | Wire containment requests to AEGIS; ratify the synchronous-eligible policy; first live producers (capability authority, generation store). |
| ARGUS-2 | Live producers in Omega's reaction runtime; measured performance gate on the Spark. |
| ARGUS-3 | Evidence: epoch roots persisted, ARGUS restart and reconstruction from its own chain. |
| ARGUS-4 | Live producers for credential leases, providers, and artifact admission as those exist in C (detectors 4 to 8 and 10 go live). |
| ARGUS-5 | Statistical detectors, asynchronous only, never synchronous. |
| ARGUS-6 | Hardware-rooted checkpoints (after TRUST-1 owner-key chain). |
| ARGUS-7 | Fabric: cross-machine evidence correlation (after cryptographic machine identity). |
| ARGUS-8 | Operator surface: plain-language incident reports and review of containment decisions. |
| ARGUS-9 | ARGUS Hunt: hypothesis-driven investigation, off the hot path, findings as hypotheses only. |

ARGUS-0 exit gates: event ABI, secret-negative, transport, saturation, core determinism, hard invariants, and false-positive rate on a synthetic corpus. The three gates that were blocked have now run:

- **Hostile review:** done. Most findings were fixed in the code (validate, apply, and machine lifecycle rules, section 6); what remains is listed in section 16.
- **Runtime integration:** works. Events flow from Omega's runtime and replay deterministically. Findings are not yet zero on every test because of producer coverage (section 15).
- **Performance:** the first design failed (section 7.1). Revision 1.1 (section 7.2) must be re-measured (section 7.3) before this gate can pass.

### 14. Deviations and discrepancies

These are places where the originating brief and the code disagree. Each records what governs.

1. **Language and home.** The originating brief assumed Rust crates in `aien-sovereign-core`. Drake's decision of 2026-09-27 (no Rust anywhere; target C, with assembly only where measured) governs. ARGUS therefore lives in `aien-dev/aienos` under `native/argus/`, in C, next to the C capability authority it observes. The existing Rust security crates are slated for removal and are not a base for ARGUS.
2. **Capability generation width.** The C authority (`AienosCapRef`) uses a 64-bit generation. Omega's `rx_caproot` Linux stand-in uses a 32-bit generation, and so do Omega's generation-store promotion types (`RxPromotionRequest.cap_generation` and its authorization callback). ARGUS follows the authority: 64-bit, layout-identical to `AienosCapRef`. The Omega stand-in is not an event source. When Omega becomes a live producer it must widen, or convert explicitly, before emitting ARGUS events.
3. **Machine identity.** No `MachineId` or Fabric identity exists in C. (Omega's `omega_machine` names an accelerator, not a Fabric member.) The 32-byte machine identity slot in the event is **provisional and opaque**. Cryptographic machine identity is on the operator's escalation list and is not designed here. Detector 7 checks consistency against whatever was recorded at join; it is not proof of identity.
4. **Producers that do not exist yet.** Credential leases, the provider registry, and artifact admission have no C producers (artifact admission exists only in the Rust crate slated for removal). In ARGUS-0, detectors 4, 5, 6, 7, 8, and 10 are exercised by synthetic events, marked with the synthetic flag. Detectors 1 to 3 have live C producers (test-wired in Omega behind a switch; connected for real in ARGUS-1), and detector 9 via the generation store.
5. **World generation width (resolved).** The first draft of the event used a 32-bit World generation, matching `RxGenObject`'s object generation, while Omega's generation store identifies whole World generations with 64-bit ids (the active and candidate generation ids). Resolved before ARGUS-0 merged, within event ABI version 1: the event's World generation is 64 bits, the separate object-generation field was dropped, and an object's generation travels in the resource field when a kind needs it. The event stays exactly 128 bytes. No deviation remains.
6. **Performance target not met by the first design.** The brief's 2% throughput target could not be met with one full event per capability check: on a ~24 ns check it cost 60% of throughput (section 7.1). The design changed (section 7.2) rather than the target; the target stands until re-measurement on revision 1.1 shows whether the micro-operation can meet it (section 7.3).

### 15. Producer coverage

ARGUS can only cross-check what it is told. Grants and revocations are the facts every capability check is compared against, so they must be reported by the one component that actually issues and revokes: the capability authority itself.

- **Today** the grant and revocation events come from Omega's AEGIS faculty, when it asks the authority to issue or revoke. Anything that issues a capability by calling the authority directly, without going through AEGIS, is invisible to ARGUS.
- **Consequence:** ARGUS then sees a capability used that it never saw issued, and reports it as forged (code 1). That is why lane H's first runs showed findings on healthy tests: the test harnesses issue capabilities directly. With the harnesses' direct calls wrapped for the test, two of three test groups showed zero findings; the remaining two findings came from several World stores in one process which the per-store World records of revision 1.1 address (section 3, row 9); that fix is still to be re-run.
- **Required change:** the authority gains an optional **observer callback**, a hook that announces "issued" and "revoked" as they happen. This is a separate change in AIENOS's `native/capability`, and it MUST be:
  - ARGUS-agnostic: the authority knows it has a listener, not what the listener is;
  - zero cost when no observer is set;
  - settable only with the authority's admin handle, never from the read-only view or from cognition;
  - blind to secrets: it passes identifiers, generations, subjects, and rights, never the capability token or the office secret.
- ARGUS itself still never holds the admin handle (section 2.1); trusted runtime code holding the handle installs the observer and forwards what it hears into ARGUS's queue.

Until the observer lands, any issuance made outside the Omega AEGIS faculty is reported as forged. That is correct behaviour for ARGUS (it really did not see the grant), and it is why the runtime-integration findings above are not a detector bug.

### 16. Remaining open in ARGUS-0

These are limits of event ABI version 1 that the fixes in section 6 do not close. Each is known, tested as an expected failure or documented as an accepted risk, and assigned to a later rung.

1. **No producer identity.** An event does not say, and cannot prove, which producer wrote it. Any code inside the trusted boundary can write a believable event, for example a grant that makes its own later uses look legitimate. Closed by cryptographic producer attestation (ARGUS-3).
2. **No provider identity continuity.** A provider is identified by its digest, so a quarantined provider that reappears under a new digest looks new. Needs a stable provider id from a provider registry (ARGUS-4).
3. **Class strengthening by trusted producers.** A producer may label an event more urgent than its kind requires (section 6.8). A misbehaving trusted producer could label junk CRITICAL and crowd out SECURITY events in its own queue. Accepted in v1 because producers are inside the trusted boundary and each thread has its own queue.
4. **No ESCALATE kind.** AEGIS can decide GRANT, DENY, ESCALATE, or REVOKE, but the event format has no "escalated to the operator" kind, so escalations are not yet part of the record. To be appended with ARGUS-1, when containment requests are wired to AEGIS.
5. **Uses carry no rights.** A use event (and a use summary) does not say which rights were exercised, so ARGUS cannot tell a read from a write on the same capability. The effect-class check (code 8) relies on the effect class the producer reports. Needs a rights field in a later ABI revision.

### Consequences

- AIEN gains a system-wide cross-check that no single boundary can provide, without adding a second authority.
- The authority stays single: AEGIS decides, the root mints and revokes, and ARGUS's worst failure mode is a recorded evidence gap, not a stopped system.
- Every alarm is reproducible: the same events always give the same findings, and the record is tamper-evident.
- Detectors for vaults, providers, artifacts, and machine identity are proven only against synthetic events until those producers exist in C. Their live value waits on that work.
- Performance was measured and the first design failed its target (60% slower on a 24 ns check). The redesign reports changes and counts routine use; whether it meets the target is decided by re-measurement, not by argument.
- Until the authority's observer callback lands, capabilities issued outside AEGIS show up as forged. That is expected, and it is the reason the observer is required.
