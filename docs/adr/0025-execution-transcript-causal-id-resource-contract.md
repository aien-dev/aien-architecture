# ADR 0025: One execution transcript, one causal id chain, one resource-contract vocabulary

**Status:** PROPOSED, 2026-10-01. Written by hardening lane L-C from the hardening plan and audits of 2026-10-01. Not accepted until the operator accepts it.
**Supersedes:** nothing. **Amends:** nothing.
**Extends:** ARCH-0016 §20 to §22 (causal crumbs are first-class, do not log everything as text, observability requirements) by fixing one shared record format, one id chain and one honesty vocabulary across repositories.
**Related:** ARCH-0005 (effect broker), ARCH-0006 (vault-only secrets), ARCH-0007 (J-Space effect boundary), ARCH-0011 (inference context is model state), ARCH-0017 (ARGUS), ARCH-0021 Decision 3 (append-only receipts bound to clean commits), ARCH-0022 (omega `rx_cortex` is the Cortex), ARCH-0024 (Rust scaffolding, Omega destination, language-neutral contracts).
**Contract home:** `aien-dev/aien-protocols` `specs/execution-transcript/` (TRN1). That spec owns the byte layout, record codes and corpus. This ADR owns scope, ids, vocabulary and order. If the two disagree on bytes, the spec wins; on scope, this ADR wins until amended.
**Evidence base:** read-only fresh clones on 2026-10-01: omega `9ca297c`, aienos `33927b1`, aien-sovereign-core `f2bb539`, aien-protocols `b50c00d`, aien-architecture `11c2e9b`. Paths below are relative to the named repository on those commits. Code beats plans.
**Citation:** from other repositories, cite this decision as ARCH-0025.

---

## In plain words (read this first)

AIEN keeps several separate diaries today. Omega's World writes a chained diary of every reaction. ARGUS writes a chained security diary. Cortex writes a memory journal. The M22 trainer writes a dispatch log. The kernel writes admission receipts. Each diary can prove it was not tampered with. None of them can yet answer the question that matters most after something goes wrong: "run it again from the diary; where exactly does the second run first differ from the first?"

This decision does three things.

1. It fixes **one shared diary format**, called the execution transcript (TRN1), that every subsystem can be converted into, so one checker can replay any of them and point at the first step that differs.
2. It fixes **one thread of ids** that runs from the outside request all the way to the final receipt, and says exactly which component is allowed to create each id. Everything else copies ids; nothing invents its own.
3. It fixes **one set of words for resource limits** (budget, need, charge, refund, deadline, cancel, busy) and what a refusal means, so the three code bases stop using the same word for different things.

It also writes down what is **deliberately not logged** (wall-clock time in anything compared, which worker thread ran a step, secrets, payload contents), and the four honesty labels every result must carry: **host**, **QEMU**, **hardware**, or **NOT_RUN**.

---

## Context

The hardening audits of 2026-10-01 (orchestrator handoffs `2026-10-01-hardening-audit-{omega,aienos,sovcore-protocols}.md`) found the same pattern in every repository: the pieces exist, they are not joined.

- **Chained logs exist, replay does not.** omega `src/runtime/rx_world.c` `crumb_hash` (l.129) hashes each RxCrumb with tag `AIEN_RX_CAUSAL_V1` over id, kind, reaction, faculty, wake cause, inputs, capability ids and 64-bit generations, outputs, reason and parent digests; `rx_world_verify_crumbs` (l.292) checks the chain. There is no World re-execution and no divergence report. aienos `native/argus/argus_event.c` `argus_chain_extend` (l.245) chains ARGUS events, but the C kernel feeds it only synthetic boot-time events (`native/kernel/svc/security.c` `argus_check`). sovereign-core has KV event replay only inside a verifier (`crates/aien-campaign-verifier/src/kv.rs`). aien-protocols `crates/aien-agent-state-abi` defines a hash-chained `AgentStateEvent` (l.142) that nothing in sovereign-core imports.
- **Nondeterminism is only partly recorded.** omega records the causal wake order and capability generations, but not effect or tool results: `off_effect_result_ring` exists in `src/runtime/omega_shared_world_abi.h` (l.235) and no `.c` file uses it. RNG seeds are recorded per experiment, not per run.
- **Ids exist, never joined.** omega `RxCrumb.episode` (`rx_world.h` l.355) roots a causal episode at an outside publication. Cortex records it as `CX_WREC_EPISODE` (`rx_cortex.h` l.281). aienos `struct cka_receipt` (`native/kernel/artifact/ck_artifact.h` l.166) carries `seq`, `id`, `generation`, `context`, `machine`; `ArgusEvent` (`native/argus/argus_abi.h` l.220 to 236) carries `sequence`, `tick`, `principal`, `cap_id`, `cap_generation`, `world_generation`, `evidence_digest`; kernel `struct ck_task` (`native/kernel/core/sched.h` l.25) carries a `uint32_t id` that appears in neither. sovereign-core has `world_id`, `op_id` (`crates/aien-runtime/src/control.rs` l.130) and two unrelated `SequenceId` types (runtime and scheduler). No receipt names the request that caused it.
- **Resource words disagree.** omega `RxResourceNeed` (`rx_world.h` l.230: "zero means none of this kind") and `RxResourceBudget` (l.241: "the setter is exact: zero means that resource is unavailable") use zero in opposite senses; `RxStabilityBudget` uses zero for "limit disabled". A reaction's `deadline` is compared with the world tick only to increment `stats.deadline_overdue` (`rx_world.c` l.378); nothing is cancelled. `RX_CANCELLED` (`rx_world.h` l.84) and `RX_WORK_CANCELLED` (`rx_generation.h` l.54) exist with no propagation to children. aienos `struct cka_limits` (`ck_artifact.h` l.125) is checked at admission by `over()` (`native/kernel/artifact/admission.c` l.63) and enforced at run time by `ST_OVERRUN` and `ST_TIMEOUT` (`native/kernel/core/artifact_loader.c` l.734 to 778), but `ipc_msgs` defaults to 0 and there is no cancel API. sovereign-core `Scheduler::submit_request` (`crates/aien-scheduler/src/lib.rs` l.122) always accepts, completion uses `unbounded_channel` (`src/sequence.rs` l.111), and cancel exists only per swarm (`crates/aien-runtime/src/swarm.rs` l.137). aien-protocols `ResourceBudget` (`crates/aien-agent-state-abi/src/lib.rs` l.68) uses tokens, micro-dollars and wall-clock seconds and is unused.
- **Honesty labels are partly faked.** aienos `scripts/capture_gate1_receipt.sh` l.28 writes `"status": "PASS_EMULATOR_VERIFIED"` and four invariants as `true` without running a check; `scripts/qemu_store_512b_crash_test.sh` l.189 starts from `tier1_pass=1`. Good practice also exists: omega `src/visor/visor_verify.h` l.32 (PASS / FAIL / NOT_RUN), `HOST_PASS_NON_SILICON` (`tools/r16_authpath.sh` l.28), aienos `scripts/ck_gates.sh` receipts that say `"physical": "NOT_RUN"`, and `scripts/trust1_m5_qualify.sh` BLOCKED_* / MISSING_IMPLEMENTATION verdicts.

ARCH-0024 Decision 5 already requires boring, versioned, language-neutral contracts at subsystem boundaries, with fixed byte layouts and a refusal rule for unknown versions. The transcript is such a boundary: omega (C, destination), aienos (C, hardware-bound) and sovereign-core (Rust, scaffolding) must all read and write it, and an Omega implementation must later replace the C and Rust readers against the same corpus.

## Decision

### 1. The execution transcript (TRN1): scope

1. **One format.** TRN1 is the single interchange and verification format for "what happened in a run, in causal order". It lives in `aien-protocols` `specs/execution-transcript/`, as a fixed byte layout with a magic and a version (the AIENART, AIENSTR1 and CRB1 pattern), plus a shared corpus of golden and deliberately broken transcripts with expected verdicts.
2. **Native logs stay.** TRN1 does not replace RxCrumb logs, the ARGUS chain, the Cortex journal, the M22 `dispatch.log` or kernel receipts. Each subsystem keeps its own log as the producer of record. A converter or emitter produces TRN1 from it. ARGUS state stays separate from World state (ARCH-0017 §2.2); ARGUS is linked by digest, not merged.
3. **Header.** Every transcript starts with a header naming the TRN1 version, the run id (section 2), the source commit and a tree-clean flag measured at the time (never hardcoded), and the honesty tier (section 4).
4. **Events.** Each event carries the run id, a dense sequence number from 1, and the digest of the previous event. The record kinds TRN1 must be able to carry are:
   - scheduler decision (which unit ran next, and why, as a causal reference, not a thread);
   - branch create and destroy, with the logical branch id and parent;
   - RNG seed and each draw that changes an outcome;
   - artifact digest (code, weights, policy) at the point it is used;
   - capability transition (mint, attenuate, revoke, reclaim, epoch), with the 64-bit generation the authority returned;
   - Cortex read, as the digest of what was read;
   - effect intent and effect commit, as separate records;
   - external input, as a digest (section 3, item 5 says where the bytes go);
   - clock read, only where the value changed an outcome (section 3, item 1);
   - resource charge, refund, refusal and cancel (section 5);
   - crash boundary (the point after which a crashed run has no further events).
5. **Checkpoints.** A checkpoint record carries a per-subsystem state digest, so a verifier can start mid-run and so a divergence can be pinned to a subsystem.
6. **Refusal.** A reader refuses, never guesses, on: an unknown TRN1 version, an unknown record kind, a sequence gap, a broken previous-digest chain, or a truncated record. A refused transcript yields no verdict except "refused, reason".
7. **Divergence report.** Replay reports either `MATCH through N` or `DIVERGENCE event=N expected=<digest> actual=<digest> subsystem=<name>`. The first divergence is reported; later events are not compared.
8. **Replay invariant.** The target invariant, for every subsystem that emits TRN1: re-executing a run from its transcript, feeding back the recorded external inputs, RNG draws, clock reads and effect results, reproduces every compared event digest. Until a subsystem passes that invariant, its claim is "verified chain", not "replayable".

### 2. One causal id chain

There is one chain of ids from the outside request to the final receipt. Each id is minted in exactly one place. Every other component copies it unchanged. A component that needs an id it was not given refuses; it does not mint a substitute.

| Id | Meaning | Minted by (only here) | Today in code | Gap to close |
|---|---|---|---|---|
| **run id** | one transcript | the transcript recorder when the run opens | absent | new; lives in the TRN1 header |
| **cause id** | one outside request (the root of a causal episode) | the admission point that accepts an outside input: omega World external publication; aienos artifact admission; sovereign-core request submission | omega `RxCrumb.episode` (`rx_world.h` l.355), Cortex `CX_WREC_EPISODE`; aienos `cka_receipt.seq` and `id`; sovereign-core `op_id` (`control.rs` l.130) and `Scheduler::submit_request` (`lib.rs` l.122) | omega has it but derives it, unhashed; aienos kernel task id (`ck_task.id`, `sched.h` l.25) never carries it; sovereign-core has two `SequenceId` types and no link to `op_id` |
| **step reference** | one event in the run | the transcript (run id + sequence) | omega crumb `id`, `wake_cause`, `parents[]`; ARGUS `sequence` per stream | the transcript sequence is the reference; native ids are carried inside the event, not reused as the reference |
| **branch id** | one logical branch (J-Space, World fork, KV fork) | the component that creates the branch, at create time | omega `rx_jspace.h` branch ids and 64-bit generations, `divergence_point` (l.236); sovereign-core `WorldStore::fork_world` (`world.rs` l.118), `AienKvManager::fork_sequence` | branch create must be a transcript event carrying the cause id and parent branch |
| **capability generation** | one state of one capability | the capability authority only | aienos `native/capability/aienos_capability.c`; omega `rx_caproot.h`; both 64-bit | copied into events as returned; never recomputed (as ARCH-0017 already requires of ARGUS) |
| **effect id** | one external effect, intent to commit | the effect broker (ARCH-0005) at intent time | absent; effect result ring unused | new; intent and commit are two events with the same effect id |
| **receipt digest** | the final receipt | the receipt writer, as the digest of the receipt bytes | aienos `cka_receipt_encode`; sovereign-core `aien-proof`; omega digest-named `evidence/` receipts | the receipt must name the cause id and run id; the ARGUS event about it sets `evidence_digest` = receipt digest |

Rules:

- **Hierarchy.** A step reference belongs to exactly one run. A run may serve one or more cause ids (a long-lived World serves many). Every event that does work on behalf of an outside request carries its cause id. Every effect and every receipt carries the cause id and the run id.
- **ARGUS ABI is not changed by this ADR.** ARGUS v1.1 events keep their 128-byte layout. The link from an ARGUS event to the causal chain is `evidence_digest` = the receipt digest or artifact digest, which already exists. A new ARGUS field needs its own ABI revision under ARCH-0017.
- **Kernel task ids are slots, not identities.** aienos `ck_task.id` and the 8-slot IPC table in `native/kernel/core/ipc.c` (`ck_cap_lookup` l.57) are reused; they are never the cause id. The task that runs an admitted artifact carries the cause id given at admission.
- **One sequence type per process boundary.** sovereign-core must settle on one `SequenceId` at the transcript boundary. Which one is a sovereign-core decision; this ADR only requires that the transcript sees one.

### 3. What is deliberately not logged

These are excluded on purpose. Each exclusion has a reason, and a verifier must not treat the missing data as a gap.

1. **Wall-clock time in anything compared or hashed.** Order comes from sequence numbers and logical ticks, as in omega `crumb_hash` ("Timing and worker placement are recorded but are not identity", `rx_world.c` l.168) and ARGUS (`argus_abi.h` l.14, ARCH-0017 §6.2). Wall-clock values may be stored for humans, outside the compared digest. Exception: a clock read whose value changed an outcome (for example aienos `ST_TIMEOUT` from the elapsed timer) is recorded as a clock-read event so replay can feed it back.
2. **Which worker or thread ran a step.** omega `RxCrumb.worker`, `t_start_ns`, `t_end_ns` are kept out of the hash. The same causal history must hash the same on any schedule.
3. **Secrets and capability tokens.** No plaintext secret, key or token, in line with ARCH-0006 and ARCH-0017 §6.4 and §10. Capabilities appear as id plus generation.
4. **Payload contents in line.** Cortex reads, artifact bytes, weights, tensors, network frames and tool outputs appear as digests. The transcript stays small and does not become a second copy of the data.
5. **External input bytes go beside the transcript, not inside it.** Replay needs the exact input, so input and effect-result bytes are stored in a content-addressed store next to the transcript, keyed by the digest in the event. An input that is itself a secret is never stored; its event is marked opaque, and replay reports that step as NOT_RUN with the reason, never as MATCH.
6. **Routine successful checks.** As in ARGUS v1.1 ("emit on transition, count on use", ARCH-0017 §7.2), a successful capability use that changes nothing is counted, not logged per use. Transitions are always logged.
7. **Performance counters and telemetry.** They are measurements (ARCH-0010), not causal history. They may sit in receipts; they are not transcript events.
8. **Free text.** Human-readable logs are renderings of structured records (ARCH-0016 §21). No free-text field is compared.

### 4. Honesty categories

Every result, receipt and transcript header carries exactly one **tier** and one **verdict**.

| Tier | Means | Never implies |
|---|---|---|
| **HOST** | ran as a program on a development machine (Linux on the Spark or elsewhere), including sanitizer and simulator runs | anything about QEMU or real hardware |
| **QEMU** | ran in an emulator | anything about real hardware |
| **HARDWARE** | ran on the named physical machine (Machine 1 / GB10), with the machine identified in the record | anything about another machine |
| **NOT_RUN** | did not run; the record says why: `BLOCKED_OPERATOR`, `BLOCKED_HARDWARE`, `MISSING_IMPLEMENTATION`, or a stated reason | a pass |

Verdicts are PASS or FAIL for a run, or NOT_RUN with a reason. Rules:

- **Derived, never typed in.** Every verdict and every boolean in a receipt (for example a candidate-bound or tree-dirty field) is computed by a check that ran in the same invocation. A script that writes PASS or `true` as a constant is a defect (aienos `scripts/capture_gate1_receipt.sh` l.28, `scripts/qemu_store_512b_crash_test.sh` l.189; fix owned by hardening lane L-A).
- **No promotion between tiers.** A HOST PASS is not a QEMU PASS; a QEMU PASS is not a HARDWARE PASS. A summary may list tiers side by side; it never collapses them. Existing names map as: omega `HOST_PASS_NON_SILICON` = HOST + PASS; aienos `ck_gates.sh` `"physical": "NOT_RUN"` = QEMU result plus HARDWARE NOT_RUN.
- **A failing gate stays failing.** A FAIL receipt is kept (ARCH-0021 Decision 3). A rerun produces a new receipt; it does not edit the old one.
- **Every check has a counterexample.** A check is trusted only when a realistic mutation or broken input is shown to make it fail (omission, reorder, bit flip, truncation for transcripts).
- **Clean commit.** Receipts name the source commit and are written outside the checkout under test (ARCH-0021 Decision 3).

### 5. Resource-contract vocabulary and refusal semantics

These words have one meaning across omega, aienos and sovereign-core. The byte layout and units belong to a later `aien-protocols` `specs/resource-contract/` spec (plan item P2); this ADR fixes only the words and the rules.

| Word | Meaning | Closest existing code |
|---|---|---|
| **Budget** | what a principal, World or service is offered, per resource kind | omega `RxResourceBudget`; aienos admission `avail` limits; sovereign-core `SchedulerConfig` |
| **Need** | what one unit of work declares it requires, before it starts | omega `RxResourceNeed`; aienos `struct cka_limits` in the artifact policy |
| **Charge** | resources taken from the budget at admission | omega `charge` (`rx_world.c` l.369; `used_slots`, `used_memory`, `used_energy`) |
| **Refund** | resources returned at reclaim, exactly once | omega `uncharge` (`rx_world.c` l.382) |
| **Quota** | a count limit: children, queued items, IPC messages or bytes | aienos `ipc_msgs`, `ipc_bytes`; `CK_SCHED_MAX_TASKS`; omega R6 `fanout_limit` |
| **Deadline** | a logical tick after which unfinished work is cancelled | omega `RxResourceNeed.deadline` (counted only today) |
| **Cancel** | stop a unit of work and all its descendants, and refund their charges | omega `RX_CANCELLED`, `RX_WORK_CANCELLED`; sovereign-core `cancel_swarm` |
| **Overrun** | work stopped after admission because it exceeded its declared need | aienos `ST_OVERRUN`, `ST_TIMEOUT` |
| **Busy** | refused now because the budget or queue is full; may fit later | absent (sovereign-core `submit_request` always accepts) |

Rules:

1. **Absent is not zero.** The contract distinguishes "no limit declared", "zero available" and "limit disabled". The current opposite uses of zero in omega (`RxResourceNeed` versus `RxResourceBudget` versus `RxStabilityBudget`) are mapped explicitly by any converter, never assumed.
2. **Units are declared per field.** Time used for decisions that must replay is in logical ticks. Wall-clock limits (aienos `elapsed`) are allowed for enforcement, and their outcome is recorded as a clock-read event.
3. **Refuse before start.** Admission either accepts and charges, or refuses with a typed reason and charges nothing. The typed refusals are:
   - `BUSY`: does not fit now; the caller may retry; nothing charged.
   - `OVER_BUDGET`: the declared need can never fit the budget as declared; retry is pointless.
   - `UNKNOWN`: unknown resource kind or contract version; fail closed.
   - `QUOTA`: a count limit is reached.
4. **After admission, stop only with a record.** `CANCELLED` (deadline, parent cancel or explicit cancel) and `OVERRUN` are terminal outcomes recorded as events with the cause id. No work is dropped silently; no queue grows without bound.
5. **Invariants every implementation must eventually show:** the sum of charges never exceeds the budget; every charge is refunded exactly once at reclaim; cancelling a parent cancels every descendant and refunds their charges; an expired deadline cancels (it is not just counted). Today omega counts deadlines and does not cancel, and has no child propagation (omega audit section 2; lane L-G records these as findings and does not fix them).
6. **Every charge, refund, refusal and cancel is a TRN1 event** carrying the cause id, so resource behavior replays like everything else.

### 6. Order of implementation lanes

| Order | Work | Where | Depends on |
|---|---|---|---|
| 0 | Fake-gate fixes, capability mutants (P0) | aienos scripts, `native/capability/Makefile` (lane L-A) | nothing; precedes trusting new evidence |
| 1 | TRN1 spec v0 and shared corpus | aien-protocols `specs/execution-transcript/` (lane L-B) | nothing |
| 1 | This ADR | aien-architecture `docs/adr/0025-*`, `docs/hardening/` (lane L-C) | nothing |
| 2 | Independent C verifier and replayer for RxCrumb logs and M22 `dispatch.log` converted to TRN1 | omega `tests/replay/`, `tools/replay/`, `mk/replay.mk` (lane L-D) | TRN1 corpus |
| 2 | Rust TRN1 reference reader and verifier passing the same corpus | sovereign-core `crates/aien-replay/` (lane L-E) | TRN1 corpus |
| 2 | Independent: World admit/run/commit/cancel model and TSan target; security gaps in spark-rsi and aegis-runtime | omega `tests/model/` (L-G); spark-rsi, aegis-runtime (L-F) | nothing |
| 3 | Cause id carried end to end (P5): omega episode into receipts; aienos admission to task to receipt to ARGUS `evidence_digest`; sovereign-core one `SequenceId` at the boundary | omega runtime lane, aienos CK lane, sovereign-core | TRN1 header; coordination with the active omega `src/runtime` and aienos `native/kernel` lanes |
| 3 | aienos kernel event emission (real, not synthetic, ARGUS and TRN1 events from cap, IPC, syscall and admission decisions) | aienos CK lane | TRN1; CK lane coordination |
| 4 | Resource-contract spec (P2) and enforcement: deadline cancel, child propagation, bounded admission with BUSY | aien-protocols `specs/resource-contract/`, then omega, aienos, sovereign-core | this ADR's vocabulary |
| 5 | Deferred: BranchTransfer (P6), placement scoring (P7), speculative inference (P8), hot replacement (P11), RSI evidence (P12) | per hardening plan section 6 | TRN1, cause id, resource contract |

Two independent implementations (C in omega, Rust in sovereign-core) against one corpus is deliberate: it is the ARCH-0024 Decision 6 pattern (one contract, more than one implementation, one conformance suite), and it leaves room for the Omega implementation to join later.

## Proposed text for `CURRENT_EXECUTION_PLAN.md`

This ADR does not edit the plan. The plan owner may add, under the hardening or Phase E area:

> **Hardening H-TRN (ARCH-0025, PROPOSED).** One execution transcript format (TRN1, aien-protocols `specs/execution-transcript/`), one cause id chain from outside request to receipt, one resource-contract vocabulary. Order: P0 gate hygiene; TRN1 spec and corpus; omega C verifier/replayer and sovereign-core Rust reader against the same corpus; cause id end to end; kernel event emission; resource-contract spec and enforcement. All results labelled HOST, QEMU, HARDWARE or NOT_RUN; no tier is promoted from another.

## Consequences

- New logs, receipts and replayers target TRN1 and use the id table above. A new subsystem-specific causal log format needs a reason written in its PR.
- "Replayable" becomes a checked claim: only a subsystem that passes the replay invariant against the shared corpus may use the word. Today none does; omega and aienos have verified chains, not replay.
- Converters must state which native fields they drop and why, by reference to section 3.
- The ADR index in `docs/adr/README.md` is not edited by this lane; the index owner adds the entry.

## Limits at the time of this decision

- TRN1 does not exist yet; lane L-B is writing it in parallel. Record kinds above are the required scope, not the encoding.
- No subsystem emits TRN1. Nothing in this ADR has run on any tier; every claim about current code is a reading of source, not a test result.
- aienos C kernel evidence is QEMU only; no C kernel gate has run on Machine 1. sovereign-core replay is verifier-only. omega has no inference runtime, so KV and batch ids are out of reach there.
- The ARGUS and capability-generation parts depend on ARCH-0017 and the 64-bit generation work already merged; they are not reopened here.
