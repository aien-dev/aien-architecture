# Resource contract v0 (per reaction)

**NOT A MASTER PLAN.** Sequencing stays in `CURRENT_EXECUTION_PLAN.md`; milestone status stays in `doctrine/ROADMAP.md` (`PLAN_AUTHORITY.md`, "The three whole-system authorities").
**Status:** DRAFT v0, 2026-10-01, hardening item HD-09 part 1. Docs only. Nothing in this file has run on any tier: every statement about code is a reading of source, labelled by file and line. Where a claim could not be checked from source it is labelled **UNVERIFIED**.
**Derived from:** [ADR 0025](../adr/0025-execution-transcript-causal-id-resource-contract.md) (ARCH-0025, PROPOSED) section 5 (resource words and refusal rules) and section 1 item 4 (resource charge, refund, refusal and cancel are transcript events). Where this file and ARCH-0025 disagree, ARCH-0025 wins until amended.
**Also cites:** ARCH-0016 section 8 ("Resource arbitration still exists", the `WorkRequirement` list), section 20 to 22 (causal crumbs, no free-text logs, observability) and section 28 ("Reactions state requirements"); ARCH-0010 (measurements are not causal history); ARCH-0021 Decision 3 (failing receipts are kept).
**Byte layout home:** a later `aien-dev/aien-protocols` `specs/resource-contract/` (plan item P2 in ARCH-0025 section 6, order 4). This file fixes fields, units, presence rules, measurement points and verdicts. It does not fix bytes.
**Evidence base:** read-only fresh clones on 2026-10-01: omega `38919c8` (main), aien-protocols `fdd288a` (main, TRN1 merged in aien-protocols#10), aien-architecture `8d24c6d` (main). Omega paths are relative to the omega repository; line numbers are for `38919c8`.

---

## In plain words (read this first)

Every reaction in Omega already fills in a small "what I need" form before it is allowed to run (memory, energy, a deadline, and so on). Today the form is used only to decide whether the reaction fits right now. Nobody checks afterwards whether the reaction stayed inside what it asked for, and a missed deadline is only counted: the late work still runs and still publishes its result.

This document turns that form into a **contract**: a list of limits with fixed units, a clear rule for "no limit" versus "zero allowed", a statement of how each limit is actually measured (or that it is not measured yet), and what happens when a reaction goes over: it is refused before it starts, cancelled, or allowed to finish but written down as over its contract. Every one of those outcomes is written into the shared run diary (the TRN1 transcript) so a replay sees it too.

It ends with the smallest first step for Omega: **enforce one limit (the deadline), with one check, proven by one test that fails on today's code.**

---

## 1. The contract record

One contract record belongs to one reaction registration. It is the ARCH-0025 **need** ("what one unit of work declares it requires, before it starts"). The World's offer is the **budget**; the contract never describes the budget.

### 1.1 Presence: absent is not zero

ARCH-0025 section 5 rule 1 requires three distinct states. Every field below carries one of them:

| State | Meaning | How it is written |
|---|---|---|
| **ABSENT** | no limit declared for this resource; the reaction makes no promise | presence bit clear; the value is ignored and must be zero |
| **LIMIT n** | the reaction promises to use at most `n` units; `n` may be zero, meaning "uses none of this" | presence bit set; value `n` |
| **DISABLED** | budget side only (a World switches a limit off); never appears in a contract | not representable in the contract |

A contract therefore carries a 32-bit **presence mask** (one bit per field in the table below, bit = row number minus 1) and a 16-bit **contract version**. A reader refuses a contract with an unknown version or a presence bit it does not know, with the ARCH-0025 refusal `UNKNOWN` (section 5 rule 3). It never guesses.

**Mapping today's omega zeros (required of any converter, never assumed):**

- `RxResourceNeed` (`src/runtime/rx_world.h` l.230 to 239): the comment says "Zero means none of this kind". `deadline` 0 = "none" (l.237), `energy_cost` 0 = "free" (l.238). A converter maps `memory_bytes` 0 and `energy_cost` 0 to **LIMIT 0**, and `deadline` 0 to **ABSENT**. Today omega cannot express "no memory limit declared"; that is a gap, recorded here, not fixed.
- `RxResourceBudget` (`rx_world.h` l.241 to 255): "the setter is exact: zero means that resource is unavailable" (also `rx_world.c` l.1745 to 1746). Budget zero = **zero available**, not ABSENT.
- `RxStabilityBudget` (`rx_world.h` l.257 to 264): "Zero disables that limit" = **DISABLED**.

### 1.2 Fields and units

| # | Field | Unit | Kind | ARCH-0025 word | Closest omega field today |
|---|---|---|---|---|---|
| 1 | `deadline_tick` | World logical ticks (absolute) | deterministic | Deadline | `RxResourceNeed.deadline` (`rx_world.h` l.237), compared with `RxResourceBudget.logical_tick` (l.254) |
| 2 | `cpu_ns` | nanoseconds of CPU time consumed by the reaction function, per activation | measured | Need | none |
| 3 | `wall_ns` | nanoseconds of monotonic wall time from dispatch to publish, per activation | measured | Need | none (only timing samples, section 2) |
| 4 | `memory_bytes` | bytes reserved for one activation | declared reservation | Need, Charge | `RxResourceNeed.memory_bytes` (l.235) |
| 5 | `gpu_ns` | nanoseconds of graphics-seat time per activation | measured | Need | none; seat selected by `RX_ACCEL_BLACKWELL` (l.168 to 171) |
| 6 | `energy_uj` | microjoules per activation | measured where a meter exists | Need, Charge | `RxResourceNeed.energy_cost` (l.238), **unitless** today |
| 7 | `max_caps` | count of capability references used | deterministic | Quota | `RxReactionDesc.n_caps`, bounded by `RX_MAX_CAPS` = 8 (l.39) |
| 8 | `max_effects` | count of external effect intents per activation | deterministic | Quota | none (effect result ring unused; ARCH-0025 Context) |
| 9 | `max_mutations` | count of proposed field writes per activation | deterministic | Quota | `RxCtx.n_out`, array bound `RX_MAX_MUTATIONS` = 16 (l.40, l.210) |
| 10 | `max_output_bytes` | bytes of proposed output per activation | deterministic | Quota | implied: each `RxMutation` value is one `uint64_t` (l.190 to 194), so 8 bytes per mutation |

Rules for units:

- **Logical before wall.** ARCH-0025 section 5 rule 2: time that decides an outcome that must replay is in logical ticks. That is why the first enforced field (section 5) is `deadline_tick`, not `wall_ns`.
- **Measured fields may enforce only with a recorded clock read.** `cpu_ns`, `wall_ns`, `gpu_ns` and `energy_uj` come from a meter, not from the program. If a meter reading changes an outcome, the reading is written as a TRN1 `CLOCK_READ` record (TRN1 spec section 5.1, type 12; ARCH-0025 section 3 item 1) so replay can feed it back.
- **Energy unit is a decision for P2.** Omega's `energy_cost` is a dimensionless count charged against `energy_budget` (`rx_world.c` l.329, l.372, l.375). Whether any caller already treats it as joules or microjoules is **UNVERIFIED** (not checked across callers). Until P2 fixes it, a converter maps `energy_cost` into `energy_uj` only with an explicit, stated scale.

### 1.3 Where the declaration lives

- **Omega:** in the reaction descriptor, `RxReactionDesc.need` (`rx_world.h` l.276), fixed at registration. The contract is the descriptor's need plus a presence mask and the four fields omega lacks (2, 3, 5, 8; 9 and 10 can be derived from existing bounds until declared). It is part of the reaction's identity: for meta programs the need is already sealed into the program digest by `rx_graph_meta_seal` (`src/runtime/rx_graph.c` l.1638; need fields hashed at l.1684 to 1691). A contract change is a new registration, never an edit of a live one.
- **aienos:** in the artifact policy as `struct cka_limits`, checked at admission. Location as cited by ARCH-0025 (`native/kernel/artifact/ck_artifact.h` l.125, `admission.c` l.63); **not re-read for this spec**.
- **sovereign-core:** no per-unit declaration exists (ARCH-0025 Context: `submit_request` always accepts). Out of scope for v0.
- **Transcript:** the digest of the contract is recorded once per registration (section 4), so a replay can prove it ran each reaction under the same contract.

---

## 2. How actual use is measured in omega today

| # | Field | Measured today? | Where (omega `38919c8`) |
|---|---|---|---|
| 1 | deadline | compared, not enforced | `charge` (`rx_world.c` l.369) compares the deadline with `budget.logical_tick` only at admission and only increments `stats.deadline_overdue` (l.378 to 379; counter at `rx_world.h` l.427). The tick is advanced only by the caller through `rx_world_set_resources` (`rx_world.c` l.1742 to 1751). Nothing compares it again while the reaction runs or before it publishes. Lane L-G reproduces this as finding I4 "deadline overrun is not surfaced while running, and never enforced" with `late_commit_published` (`tests/model/world_diff.c` l.513 to 560). |
| 2 | cpu_ns | **no** | A thread CPU clock exists, `thread_cpu_ns` (`rx_world.c` l.41 to 45), but it is used only for scheduler and propagation cost (l.467 to 485, l.627 to 635, l.1609 to 1642, l.2354 to 2379). The reaction function call (`d->fn(&ctx)`, l.1439, with the world lock dropped at l.1438) is not bracketed by it. |
| 3 | wall_ns | sampled, not compared | `k.t_start_ns` and `r->t_run` at dispatch (l.1332 to 1333); `r->t_fn_end` after the function, only when `w->timing` is set (l.1441). Kept out of the crumb hash by design (ARCH-0025 section 3 item 2). |
| 4 | memory_bytes | declared and charged, not measured | Admission fit check (`res_fits`, l.323 to 338, memory at l.326 and l.328); charge (l.371, l.374); refund (`uncharge`, l.382 to 393, called from `end_activation_inner` l.1275). The reaction function runs in-process; nothing meters what it allocates. Snapshot bytes are counted (`stats.snapshot_bytes`, l.1435) but that is the runtime's copy, not the reaction's use. |
| 5 | gpu_ns | **no** (UNVERIFIED beyond `rx_world.c`) | The resident-seat path is chosen at l.1374 and hands the claim to a seat (l.1412 to 1419). No seat-time measurement found in `rx_world.c` or `rx_world.h`; other runtime files were not searched. |
| 6 | energy | declared and charged, not measured | `energy_cost` charged and refunded like memory (l.329, l.372, l.375, l.387 to 388). No meter in `rx_world.c`. Energy figures in Omega gate receipts come from separate measurement harnesses; whether any can be attributed per activation is **UNVERIFIED**. |
| 7 | max_caps | bounded by structure | `n_caps` at most `RX_MAX_CAPS`; each checked by `validate_caps` before running (l.1359 to 1369). |
| 8 | max_effects | **no** | No effect counting in the World; effects run through deferral (`RX_FN_DEFER`, `rx_world.h` l.223; `rx_world.c` l.1442 to 1453). |
| 9, 10 | max_mutations, max_output_bytes | partly | `stage_mutations` (l.941 onward, called at l.1516) refuses writes outside the declared write set (`RX_ERR_WRITE_SET`, l.946 to 954) and more than `RX_MAX_WRITES` distinct objects (`RX_ERR_FULL`, l.960). **Finding (source reading, not tested):** `ctx.n_out` is passed to `stage_mutations` without a check against `RX_MAX_MUTATIONS`, and `stage_mutations` indexes `m[i]` for every `i < n`, while `ctx.out` holds 16 entries (`rx_world.h` l.210). A reaction function that sets `n_out` above 16 would make the runtime read past `ctx.out`. Recorded here; owner is the omega runtime lane. |

Summary: of ten fields, one is compared (deadline, without effect), two are reserved and refunded but never metered (memory, energy), three are bounded by structure (caps, mutations, write set), and four have no measurement (CPU, wall as a limit, GPU, effects).

---

## 3. Verdict when a reaction exceeds its contract

There are three moments and three verdicts. The words are ARCH-0025's; nothing here invents a new outcome.

| Moment | What is checked | Verdict | Effect on charges |
|---|---|---|---|
| **Before start** (admission) | the declared need against the budget | **Refuse** with `BUSY` (does not fit now), `OVER_BUDGET` (can never fit as declared), `QUOTA` (a count limit), or `UNKNOWN` (unknown version or field) | nothing charged (ARCH-0025 section 5 rule 3) |
| **During or at end of the run**, deterministic field (deadline, caps, effects, mutations, output bytes) | the field against the contract, at a fixed point in the activation | **Cancel** (`CANCELLED`) for an expired deadline; **Overrun** (`OVERRUN`) for a count exceeded. Nothing the activation proposed is published. | charge refunded exactly once at reclaim (rule 5) |
| **During or at end of the run**, measured field (CPU, wall, GPU, energy) | meter reading against the contract | **Overrun** when the field is in ENFORCE mode; **Record** (an over-contract event, the activation still publishes) when the field is in OBSERVE mode | refund as above; in OBSERVE mode the actual use is recorded beside the declaration |

**Enforcement mode per field.** Each field is ENFORCE or OBSERVE, set by the World, not by the reaction. A meter that has not passed its own counterexample test (ARCH-0025 section 4, "Every check has a counterexample") may only run in OBSERVE mode, because a false overrun would cancel correct work. In v0: `deadline_tick` ENFORCE; every measured field OBSERVE; count fields ENFORCE once their check exists.

**Today's gaps against this table (findings, not fixed here):**

- No `OVER_BUDGET`: a reaction whose need can never fit stays in `RX_BLOCKED_RESOURCE` (set at `rx_world.c` l.536; `admit_one` l.394 to 400 returns silently when `res_fits` fails). Nothing refuses it.
- No `BUSY` in the ARCH-0025 sense. `RX_ERR_BUSY` (`rx_world.h` l.126) already exists with a different meaning ("the reaction still has work pending", used by `rx_world_remove_reaction`). P2 must pick a name that does not collide, or rename one of them.
- No cancel: `RX_CANCELLED` exists (`rx_world.h` l.84) and `RUNNING -> CANCELLED` is a legal transition (`rx_world.c` l.79), but no code sets it. No crumb kind records a cancel (`RxCrumbKind`, `rx_world.h` l.90 to 102).
- No child propagation of cancel (ARCH-0025 rule 5; L-G finding I2, `tests/model/world_diff.c`).

**Stop only with a record.** Every refusal, cancel, overrun and over-contract observation is written as a record carrying the cause id (ARCH-0025 section 5 rule 4 and rule 6). No silent drop.

---

## 4. What goes into the TRN1 transcript

TRN1 v0 (`aien-protocols` `specs/execution-transcript/TRN1_TRANSCRIPT_SPEC.md`, contract 0.1.0, merged in aien-protocols#10 `fdd288a`) has **no resource record type**: its registry is types 1 to 16 plus `END` (section 5.1). TRN1 section 10 says a writer that needs a record the spec lacks "proposes it here first; it does not invent a type number". So:

**Now (TRN1 0.1.0, no spec change needed).** Omega's resource outcomes reach the transcript inside `RX_CRUMB` records (type 15). The crumb kind field is carried as a `u32` and "not range-checked here, so new kinds pass" (TRN1 section 5.3), so a new omega crumb kind for a cancel is carried losslessly with its `reason`. The logical tick that decided a deadline is a value supplied from outside the World (`rx_world_set_resources`), so its change must reach the transcript as an outcome-changing clock read (`CLOCK_READ`, type 12). TRN1 v0 defines `clock u32` with no registry of clock ids; a "World logical tick" clock id must be added by aien-protocols. Until then the replay input for the tick is **not recorded**, and a replay of a deadline cancel is "verified chain", not "replayable" (ARCH-0025 section 1 item 8).

**Proposed for TRN1 0.2 (to be filed with aien-protocols; number assigned there).** A `RESOURCE` record whose identity is:

The TRN1 0.2 bump is shared with aien-architecture#98 (HD-08); the joint record-type number table lives in [causal-id-join-v0.md](causal-id-join-v0.md) section 3.

| Field | Size | Meaning |
|---|---|---|
| op | u8 | 1 CHARGE, 2 REFUND, 3 REFUSE, 4 CANCEL, 5 OVERRUN, 6 OVER_OBSERVED |
| reason | u8 | for REFUSE: 1 BUSY, 2 OVER_BUDGET, 3 UNKNOWN, 4 QUOTA; for CANCEL: 1 DEADLINE, 2 PARENT, 3 EXPLICIT; else 0 |
| field | u16 | contract field number from section 1.2 (0 for a whole-need charge or refund) |
| reserved | u32 | zero |
| unit | u64 | the reaction or task id the outcome applies to |
| cause | 32 bytes | the cause id, a 32-byte digest as defined in [causal-id-join-v0.md](causal-id-join-v0.md) section 2.1 (HD-08, aien-architecture#98) |
| contract | 32 bytes | digest of the contract record in force |
| declared | u64 | the declared limit for `field` (0 when ABSENT; presence is in the contract) |
| used | u64 | the deterministic amount used, or 0 for a measured field |

Measured amounts (CPU, wall, GPU, energy) go in the annotation, never the identity, because two correct runs differ in them (TRN1 section 4.3). When a measured value changed the outcome (an ENFORCE-mode overrun), a `CLOCK_READ` record precedes the `RESOURCE` record and carries that value in its identity.

---

## 5. The smallest first enforcement cut in omega

**One resource: the deadline. One check: before publishing. One test: a late reaction must not publish.**

When a reaction's function returns, omega today goes straight on to publish (`set_state(w, r, RX_PUBLISHING)` at `rx_world.c` l.1473, after the failure branch at l.1462 to 1471, which ends with `return`). The cut adds one check at that point, while the activation is still `RX_RUNNING`: if the reaction declared a deadline (`d->need.deadline != 0`) and the World's logical tick has passed it (`w->budget.logical_tick > d->need.deadline`, the same comparison `charge` already makes at l.378), the activation moves to `RX_CANCELLED` (already a legal transition, l.79), appends a crumb of a new kind `RX_CRUMB_CANCELLED` (appended after `RX_CRUMB_QUARANTINE`, `rx_world.h` l.101, so existing kind numbers do not move) with a new reason code for "deadline" (next free code after `RX_ERR_BUSY` -29, `rx_world.h` l.126), counts it in a new `deadline_cancelled` counter, and ends the activation through `end_activation` (which refunds the charge exactly once, l.1275). The function's proposed writes are never staged, so nothing late is published. A new host test, `tests/runtime/rx_deadline_cancel.c`, registers one reaction with deadline 5 whose function waits on a gate, publishes its trigger at tick 0, moves the tick to 6 with `rx_world_set_resources` while the function is parked, releases it, waits for quiescence, and requires: zero commits, the written field unchanged, the last crumb of kind `RX_CRUMB_CANCELLED` with the deadline reason, `used_slots` back to zero, and `rx_world_verify_crumbs` returning 0. Its control case moves the tick only to 5 (not past the deadline, because the comparison is strictly greater) and requires exactly one commit. On today's omega the test fails, because the late work commits (the same behaviour L-G records as `real.I4.late_commit_published=YES`); a mutant that changes `>` to `>=` must fail the control case, and a mutant that removes the check must fail the main case.

Why this cut and not another:

- The declaration already exists (`RxResourceNeed.deadline`), so no descriptor layout change is needed.
- It is fully deterministic: the decision depends only on the logical tick, not on a clock, so it needs no new meter and no `CLOCK_READ` in the identity, only the tick record named in section 4.
- It closes the exact gap L-G proved (finding I4) and the one ARCH-0025 section 5 rule 5 names: "an expired deadline cancels (it is not just counted)".
- It touches one function (`run_one`, `rx_world.c` l.1322) in a few lines, one header enum, one counter.

What this cut does **not** do: it does not stop a function that is still running (the check fires when it returns; a function that never returns is not covered); it does not cancel a reaction that is still waiting for admission; it does not cancel children (I2); it does not make the tick replayable (needs the TRN1 clock id). Each is a later cut.

**Coordination.** The omega `src/runtime/` edit freeze is lifted after R16 (`CURRENT_EXECUTION_PLAN.md` l.45), and the COMPOSITION-1 runtime program is actively editing `rx_world.c` (l.64 to 66, for example the Cortex recorder hook); the cut must be landed in coordination with that lane and rebased on its latest `run_one`. `tests/model/world_diff.c` reports I4 as `KNOWN_FAIL`; after the cut, its directed replay should report `NOT_REPRODUCED`, so lane L-G must update its expectation in the same change or the next one. A failing gate stays failing until then (ARCH-0021 Decision 3).

---

## 6. Deliberately out of scope for v0

- **Byte layout of the contract.** Owned by aien-protocols `specs/resource-contract/` (P2).
- **The TRN1 `RESOURCE` record and the logical-tick clock id.** Proposed in section 4; decided by aien-protocols.
- **Measured enforcement** (CPU, wall, GPU, energy in ENFORCE mode). Needs a meter with its own counterexample test first. GPU and energy meters per activation are UNVERIFIED to exist.
- **Preemption.** Stopping a reaction function mid-run needs a cooperative or forced stop point that omega does not have.
- **Cancel propagation to children** (ARCH-0025 rule 5, L-G finding I2).
- **`OVER_BUDGET` and `BUSY` refusals at admission** in omega, and the `RX_ERR_BUSY` name collision.
- **Fixing the `n_out` bound finding** (section 2, rows 9 and 10). Recorded for the omega runtime lane.
- **aienos and sovereign-core enforcement.** aienos already enforces `ST_OVERRUN` and `ST_TIMEOUT` at run time (as cited by ARCH-0025); its mapping to this vocabulary is a later item. sovereign-core has no per-unit declaration.
- **Budget accounting across Worlds or machines** (placement, P7) and **cost models** (what a reaction should declare). The contract states what was promised; it does not estimate.
- **Edits to `CURRENT_EXECUTION_PLAN.md` or ARCH-0025.** Neither is changed by this file.

## 7. Limits of this document

- Nothing here has run on HOST, QEMU or HARDWARE. Tier: NOT_RUN (`MISSING_IMPLEMENTATION`).
- Line numbers are for omega `38919c8` and drift with every runtime merge. The enforcement cut must re-read `run_one` before editing.
- aienos citations are carried from ARCH-0025 and were not re-read for this spec.
