# Analog Realization — Collision Map

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0018 (ARCH-0018, PROPOSED), substrate-neutral physical realization. `CURRENT_EXECUTION_PLAN.md` still owns cross-project sequencing (§6 C3, Lane 6), and `doctrine/ROADMAP.md` still owns milestone status. The AR-gates are ADR 0018 workstream gates, not M-milestones.

**Written:** 2026-09-29. Code facts come from three read-only audits of the commits below; PR states were checked live on the same date.

| Repository | Commit |
|---|---|
| omega | `main` `f308ac7` (live); file:line facts read at `8e7a445` (audit basis); `#68` read at `d73315e`; `#70` read at `cf6f45d` |
| physics | `main` `fecbedb`; `#13` read at `5781222` |
| aienos | `main` (commit not recorded in the audits); `feat/argus-0` read at `a64bc55` |
| aien-architecture | `main` `f6baa35` |

---

## 1. Collision table

| Active work | Owner PR | Owned files | Analog may touch now? | Waits on |
|---|---|---|---|---|
| R16 spec / map / tool | omega#68 | `spec/r16-*`, `docs/r16-*`, `tools/r16_loop_inventory.*`, `tests/r16_inventory/`, Makefile R16 block | No | R16 merge (W10) |
| omega sequencer retirement (W5) | omega#68 | `tools/omegatool.c`, Makefile, docs entry point | No | W5 + R16 merge |
| omega reaction runtime | omega#68 (G3/G4/G7) + omega#70 | `src/runtime/**` (esp. `rx_world`, `rx_generation`, `rx_aegis`, `rx_native_bind`, `rx_caproot`, `rx_argus*`) | No | R16 complete |
| omega fallback / maintenance / operator | omega#68 (map rows C/B) | `src/omega_world_gates.c`, `src/omega_accelerator_world.c`, `src/visor/` | No | R16 merge |
| omega mapped tests / tools | omega#68 (map rows) | `tests/runtime/rx_r1x_*`, `tools/r15_reduce.c`, `tools/crumbline_learner.c`, `research/m15/spbm/sample.c`, `src/language/*` | No | R16 merge |
| R16 new tests + evidence | omega#68 | `tests/runtime/rx_r16_*.c`, `evidence/R16/` | No | R16 merge |
| M18 receipt | omega#66 | `src/omega_blackwell_gates.c` | No (open PR) | #66 merge or close |
| Authority pin | omega#72 (merged `f308ac7`) | `aienos.lock` | No | Frozen for R16 W9 |
| ARGUS producer | omega#70 | `src/runtime/rx_argus.{c,h}`, hooks in `rx_aegis` / `rx_generation` / `rx_native_bind` / `rx_world`, `argus.lock`, `tools/argus/`, `tools/argus_replay.c`, `tests/bench_rx_argus.c`, `evidence/ARGUS/` | No | ARGUS perf gate decided + R16 |
| ARGUS core + ARGUS-1 | aienos#160, #162 | `native/argus/**` | No (no expansion before perf gate) | Perf gate PASS, then ARGUS-1 |
| ARGUS event ABI | aienos#160 | `native/argus/argus_abi.h` | Docs-only requirements; no ABI edits | ABI v2 decision (R7 code 13) |
| aienos authority | aienos main (R16 map rows, #72 pin) | `native/capability/`, `crates/aienos-capability/` | No | R16 merge |
| aienos kernel / boot mapped files | R16 map (read-only) | `crates/aienos-kernel/src/{thread,scheduler,gic}.rs`, `arch/aarch64.rs`, `crates/aienos-boot/src/handoff.rs`, xhci, evidence crates | No | R16 merge |
| aienos other code | none | new files outside the above | Yes, pattern-clean only | — |
| physics mapped files | R16 map (read-only) + omega M17 gate | `m15/tools/m15tool.c`, `m16/m16_native.{c,h}`, `m3/tools/m3tool.c`, `nvrm/nvrm.c` | No | R16 merge |
| physics FORGE v1 | physics#13 | `forge/forge_descriptor.{c,h}`, `forge/forge_realize.{c,h}`, `forge/forge_types.h`, `tests/test_forge_{hwid,seam}.c`, `tests/run_forge_gates.sh`, `evidence/m19r_gate{3,4}_*.json`, `.gitignore` tail | No (owned by #13) | #13 merge |
| physics FORGE V2 | companion draft, branch `feat/forge-substrate-v2` | `docs/FORGE_SUBSTRATE_V2_SPEC.md`, `forge/v2/**`, `tests/test_forge_v2_kat.c` | Yes, on that branch; pattern-clean | AR1 needs #13 merged first |
| physics `sha256_clean.c` | pinned into firmware builds | `sha256_clean.c` | Never modify; link and reuse only | — |
| aien-sovereign-core, aegis-runtime | R16 Q2=A (labels only) | whole repos | No | R16 merge; C rewrite plan |
| aien-architecture migration map / ADR 0016 | omega#68 W11 | `docs/plans/CURRENT_CODE_TO_R0_R16_MIGRATION.md`, ADR 0016 | No | R16 W11 |
| aien-architecture other docs / ADRs | none | new analog ADRs / docs | Yes | — |

## 2. Must-not-touch lists (until R16 closes: W10 merge, ideally W11)

**omega:** all of `src/runtime/`; `tools/omegatool.c`; Makefile R16/W5 blocks; `spec/r16-*`, `docs/r16-*`; `tools/r16_loop_inventory.{c,sh}`; `tests/r16_inventory/`; `tests/runtime/rx_r16_*`; `evidence/R16/`; `src/omega_world_gates.c`, `src/omega_accelerator_world.c`; `src/visor/`; every other file with a map row (`tests/runtime/rx_r12_*`, `rx_r15_*`, `tools/r15_reduce.c`, `tools/crumbline_learner.c`, `src/language/omega_{lex,parse,lower}.c`, `src/crumbline/cl_search.c`, ...); `aienos.lock` and the physics pin (candidate freeze).

**aienos:** files with map rows (`crates/aienos-kernel/src/{thread,scheduler,gic}.rs`, `arch/aarch64.rs`, `native/capability/aienos_capability.c`, `crates/aienos-capability/`, `crates/aienos-boot/src/handoff.rs` (class C, "must never be removed"), xhci, evidence crates); `native/argus/` (owned by #160/#162).

**physics:** files with map rows (`m15/tools/m15tool.c`, `m16/m16_native.c`, `m3/tools/m3tool.c`, `nvrm/nvrm.c`); `m16/m16_native.h` (read by the omega M17 gate); every file owned by #13 (above); `sha256_clean.c` (permanently).

**aien-sovereign-core, aegis-runtime:** no edits at all.

**aien-architecture:** `docs/plans/CURRENT_CODE_TO_R0_R16_MIGRATION.md`, ADR 0016.

## 3. Safe now

- aien-architecture: new ADRs, docs and doctrine text (not scanned by R16), except the two files above.
- physics: new files under `forge/v2/`, `tests/test_forge_v2_kat.c`, `docs/`, digest-named `evidence/FORGE-V2/<sha256>.json`; build outputs into `build/`. Keep `.gitignore` untouched (#13 appends to it).
- aienos: new files outside the lists above, pattern-clean.
- Non-scanned file types (`.s`, `.sh`, `.mojo`, `.md`). No Python (standing rule).
- omega: nothing in `src/runtime/` or the lists above. A standalone directory outside `src/runtime/` is technically possible, but anything linked into the production golden path changes the R16 G3/G7 candidate, so prefer other repositories until R16 merges.

## 4. R16 inventory heuristics new code must avoid

The R16 inventory tool (`tools/r16_loop_inventory.c`, omega#68) rescans omega, aien-sovereign-core, aegis-runtime, aienos and physics at their current state. Any new flagged site that lands on a `main` before the R16 W9 candidate freeze is an unclassified row and **blocks R16**.

- **Files scanned:** `git ls-files '*.c' '*.h' '*.rs'`. Excluded: `vendor/`, `third_party/`, `tests/r16_inventory/`. Not scanned: `.s`, `.sh`, `.mojo`, `.md`, and other repositories (including aien-architecture). Comments and string contents are blanked first.
- **Always flagged (endless loops):** `while(1)`, `while(true)`, `while(!0)`, `for(;;)`, Rust `loop {}`, `while true`.
- **Bounded loop flagged** if its condition or body contains one of these identifier words (identifiers are split at `_`, digits and camelCase): `sleep usleep nanosleep msleep poll recv heartbeat tick dispatch schedule scheduler orchestrate orchestrator turn turns pulse yield epoll`.
- **Analog naming traps** (flagged inside any loop): `pulse_width`, `tick_count`, `adc_poll`, `settle_sleep_us`, `schedule_calibration`, `turns_ratio`, `sched_yield`. Choose other names (for example `width_ns`, `sample_index`, `adc_read`, `settle_ns`, `calibration_due`).
- **Named terms on any code line:** an identifier containing `run_until_complete`; an identifier exactly `max_steps` or `max_turns`.
- **CLI flag names:** any C line testing `argv[` against a `"--demonstrate-..."` or `"--run-..."` literal is flagged. New analog tools must use other flag names.
- **Join key** = repo + path + enclosing symbol + whitespace-collapsed line. Editing a mapped line or renaming its enclosing function unjoins it (unclassified → G2 FAIL). Line shifts alone are fine.
- A plain bounded `for (i = 0; i < n; i++)` with none of the words is not a site.
- If a flagged loop is truly unavoidable (for example device settling), do not merge it before R16's W9 freeze, or hand R16 a pre-classified map row (likely class E physical scheduler or N not-a-central-loop) through a dated clarification.

## 5. ARGUS / R16 collision (independent of analog work)

omega#70's `rx_argus.c` already contains `for (;;)` (merge loop), `while (!stop) { ... nanosleep }` (consumer thread) and a `yield` instruction; #70 also edits `rx_world.c` and `rx_generation.c`, which carry R16 map rows. If #70 merges before R16's final G2 scan, those are new unclassified rows and R16 G2 fails. By contrast, aienos `native/argus/*.c` at `a64bc55` has no unbounded loops or wait words (its `tests/` were not checked). The analog workstream must not add to this: it does not touch `rx_argus*`, the ARGUS ABI or `native/argus/`.
