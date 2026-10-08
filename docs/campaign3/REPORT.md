# Campaign 3 report: native AIENOS, Omega Systems Core, release qualification

Date: 2026-10-08. Owner session f68569. Statuses are kept apart: host, QEMU, Linux-hosted GB10, native physical Spark. A QEMU result is never a physical Spark result. Companion: [SOVEREIGNTY_AUDIT.md](SOVEREIGNTY_AUDIT.md) (C3-8).

## Outcome in one paragraph
An OSC-compiled program can now be packaged, admitted with a signature check and run as its own isolated task inside AIENOS, and the minimal shell (OSH, built by session ee6210) runs that way with output identical to Linux, all in QEMU. The AIENOS console now takes sustained serial and USB keyboard input in QEMU. Release preparation for the internal candidate CAND-4 landed (licence and third-party notices, kill -9 at the final install switch, an offline build check). Nothing in this campaign ran on the physical Spark without Linux. The admission and task-launch work is held for one operator decision (below). No production signing key was created and nothing was published.

## Items

| Item | What | Status | Evidence |
|---|---|---|---|
| C3-1a | Console session: sustained serial + USB keyboard input, exit revokes | QEMU PASS, MERGED | aienos#280 (8641977): AIENOS_CK_CONSOLE rows 146-153, serial 70.5 s / 129.8 s, USB 72.6 s / 131.8 s; independent review APPROVE |
| C3-2 | OSC unit container spec | v1 DRAFT, frozen pending ADR reconciliation | aien-protocols#17 (82 conformance vectors, section 15 reconciles 70 rows with aienos ADR 0013/0014/0017; open C1 required_generation, C3 two-section cap) |
| C3-2 | OSC unit admission in the C kernel (signature, limits, refusals) | QEMU PASS, HELD for the operator | aienos#277 (36e67c6): AIENOS_CK_OSC_UNIT PASS, ck_gates 21/21 QEMU only; CI green; independent review APPROVE |
| C3-3a | Launch an admitted unit as its own EL0 task, wait, exit status, caller-sized workspace | QEMU PASS, draft behind #277 | aienos#279: AIENOS_CK_OSC_LAUNCH 55 PASS 0 FAIL, 44 launches; test_osc_launch 680 checks; three independent reviews APPROVE |
| OSH | Minimal shell units run as AIENOS tasks | QEMU PASS (ee6210) | 3 real OSH units as EL0 tasks, trace equal to Linux (omega#343) on 16/16 scripts; omega#335, #336 merged |
| C3-6 | Release prep for CAND-4 | MERGED | aien-sovereign-core#308 (c47a168): LICENSE/NOTICE/THIRD_PARTY in the package with digests, packaging fails closed without them, kill -9 holds at the final switch and rollback, offline warm-cache build (network denial not enforced) |
| C3-7 | Plan currency | MERGED | aien-architecture#163 (7bfbb63), #165 (78770cc) |
| C3-8 | Sovereignty audit | draft | this folder; verdict PARTIAL on all eight questions, no claim of complete sovereignty |
| C3-3b/3c | Capability authority at boot; 64-to-32 bit generation refusal | NOT STARTED | waits for #277 |
| C3-4 | "OSC unit executes in AIENOS (QEMU)" as a named milestone | evidence exists on #279, not merged | waits for #277 |
| C3-5 | Native CPU inference in AIENOS | DEFERRED | QEMU floating point says nothing about silicon; aienos#34 open |
| C3-9 | Native continuity demo in QEMU (boot, unlock TEST identity, task, persist, reboot, recover) | NOT STARTED | waits for #277 |

Physical Spark: NOT_RUN for every item above. The C kernel has never booted on the physical Spark (aien-architecture#163).

## Decisions for the operator (recorded, not decided)
1. **aienos#277: is the OSC unit a second container format beside Binary Artifact v0?** Options as framed by the overnight coordinator: (1) amend ADR 0014 for a distinct container type (recommended by the owner session: the unit carries limits and launch fields v0 has no room for); (2) fit the OSC unit into v0; (3) merge as provisional, QEMU-only. #279, C3-3b/3c, C3-4 and C3-9 wait on this.
2. **Native order.** Two orders are recorded (M5 to M6 to M7, versus NEXT-PHASE-3); aien-architecture#163 recommends NEXT-PHASE-3 and labels it "not a decision".
3. **Release signing key.** An existing `aien-release` key signed v0.1.0 and v0.1.1 before decision D1 (dedicated offline key at first public release). Whether it may count as the D1 key is open (SOVEREIGNTY_AUDIT.md).

## Operator-only steps (not done)
Offline signing key ceremony; physical Spark rollback with the operator present; attended native boots (TRUST-1); NVMe on the Spark (512-byte atomicity); Spark IORT verification for native input.

## Limits
Every AIENOS PASS here is QEMU. Test signers only (TEST keys); the owner-signer path refuses until a real anchor exists. Linux-hosted GB10 serving work ran in another lane (aien-sovereign-core issue #277, Campaign 1) and is not claimed here. Issues aienos#31-35 remain open.
