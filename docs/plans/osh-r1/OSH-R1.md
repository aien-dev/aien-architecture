# osh (Omega-native shell): first-release acceptance and status record

**NOT A MASTER PLAN.** Finite workstream record for [aien-dev/aien-architecture#158](https://github.com/aien-dev/aien-architecture/issues/158). It is subordinate to `PLAN_AUTHORITY.md`, `CURRENT_EXECUTION_PLAN.md`, `doctrine/ARCHITECTURE.md` and `doctrine/ROADMAP.md`. It does not reorder any campaign, change subsystem ownership, replace NEXT-PHASE-3, or raise any milestone status. It freezes the acceptance of one workstream and records, honestly, what exists. Where this file and those authorities disagree, they win. Implementation and evidence win over every claim below.

**Written:** 2026-10-08. **Pins read:** omega `b980783a4674275e720592e4c3887679dd24ec8b`, aienos `c63d6db8e9ac82592899ab0c2cbd9e2a76e6c7b2`, aien-protocols `3a4cdbe` (GitHub default branches). Re-read before acting on this file. Follows ADR 0024: Omega is the destination, Rust and C host code is replaceable scaffolding.

## 1. Frozen first-release language (R1)

R1 is what the Linux adapter must run. This section freezes the language so the ABI vectors and the differential suite have one target. Details of codes and offsets live in the platform ABI draft ([aien-protocols#16](https://github.com/aien-dev/aien-protocols/pull/16), `specs/osh-platform/OSH_PLATFORM_ABI.md`).

**In R1** (issue list): words, single and double quotes, backslash escapes, empty arguments; variable assignment and expansion with the documented field-splitting rule; `;`, `&&`, `||`, pipelines; `<`, `>`, `>>`, and the stderr forms `2>` and `2>>` (generally `N<`, `N>`, `N>>` with N in 0..2); exit statuses; builtins `cd`, `pwd`, `printf`, `export`, `unset`, `exit`; interactive input, `osh -c`, and script files.

**R1 additions** (queen engineering decision, 2026-10-08, from the script syntax inventory): `2>&1` and `N>&M` with N and M in 0..2 (applied left to right, so `>o 2>&1` and `2>&1 >o` differ), `$?`, `#` comments, backslash-newline continuation, `$0` to `$9`, `$#`, `"$@"` (and unquoted `$@`, `$*`; `"$*"` joins with one space).

**Refused by name** (each has its own refusal code, never a silent fallback): command substitution and backticks, `$((`, parameter operators such as `${A:-y}`, `$$ $! $-`, tilde, unquoted globbing characters in the source, and any unquoted expansion result containing `*`, `?` or `[` (`VALUE_GLOB`), background `&`, subshells, here-documents, `;;`, other redirections (`>|`, `<>`, descriptors above 2), `if for while until case function { } !`, builtins outside the six (`set eval exec . source trap shift read return break continue local readonly alias wait`), assigning `IFS`, empty commands, redirections without target, ambiguous redirections, NUL bytes in source or variable values.

**Rules:**
1. A syntax error or any refusal ends that list with exit status 2 and resets the session. Durable state (variables, location, `$?`) survives.
2. Validation is incremental, one complete list at a time. There is no whole-script atomicity: earlier lists of a script have already run when a later one is refused.
3. The guarantee is worded exactly: "refused before the effect of that pipeline". Refusals that depend only on text happen before anything in that list runs. Refusals that depend on variable values (`CAP_FIELDS`, `CAP_OUT`, `VALUE_NUL`, `VALUE_GLOB`) happen before that pipeline only.
4. IFS is fixed to space, tab and newline. Unset variables expand to empty. No `set -u`.
5. Paths and arguments are bytes; NUL is refused. Native storage locations are not POSIX paths (ABI section 8.2).
6. The language engine is never `bash -c`, `sh -c`, `system()` or equivalent.

## 2. Release ladder

| Release | Contents | Gate |
|---|---|---|
| R1 | Shared Omega core plus Linux adapter: interactive, `-c`, script modes. Interpreter and native ARM64 runs of the same core. | Section 3 |
| R1.1 | AIENOS native: real console input path, storage locations over the Store, artifact packaging and loading, task and IPC use, QEMU acceptance. Depends on the 13 native services in section 6. | QEMU acceptance from the issue, hosted simulation does not count |
| R1.2 | Additions in inventory order (unlock count over 326 scripts, recount 2026-10-08): `$( )`, `set -e/-u/-o pipefail`, `if`, `for` and `while`, `case`, `{ }`. | Each addition gets its own vectors and differential rows before it is accepted |
| Later | Functions, globbing, here-documents, background jobs, hardware validation (separately authorized, attended). | Not scheduled here |

R1 is not "AIENOS shell done". R1.1 is still required by the issue and is not dropped.

## 3. R1 acceptance criteria

All of these must have recorded evidence before R1 is called done. Skipped checks are not passes.

1. **Pinned reference.** One Bash version, locale (`LC_ALL=C`), environment and fixture set, recorded with the receipt. UNSET today: the version is not yet chosen.
2. **Differential categories** (issue): argument boundaries; relevant stdout and stderr; exit status; cwd and environment; filesystem effects; pipeline completion and cancellation. Supported-feature comparisons only; refusals are compared to the refusal table, not to bash.
3. **Hostile cases:** empty and quoted arguments, hostile filenames (spaces, leading dash, newline, non-UTF-8 bytes), malformed syntax, oversized input (line cap, token cap, workspace cap), large streams, early pipe-reader exit, failed redirections, partial launch failure, descriptor and child cleanup, Ctrl-C, EOF. Denied, revoked and stale capabilities are R1.1 for the native path and an adapter test on Linux through the binding check.
4. **Interpreter versus native ARM64:** the same core, same vectors, same results in both modes. Adapter tested independently of the core.
5. **Real script target:** `omega/evidence/CAND2-AUDIT-20261005/runners/run_builds.sh` (4 lines) run unchanged in a disposable fixture. The script uses `cd` to an absolute path, `>`, `>>`, `2>&1`, `;` and `$?`; its `echo` is the external `/usr/bin/echo`, resolved as a Linux executable. The fixture must supply that absolute directory and a stub `cand2_build.sh` (the script itself is not edited and its checks are not weakened). This is the only R1 real-script target; no other of the 326 scanned scripts is claimed.
6. **Conformance vectors** from aien-protocols pass in the core, with exact refusal codes and offsets.
7. **Exact revisions** of core, compiler, contract and harness are recorded; failed attempts are kept; no full-Bash, hardware or performance claim.

## 4. Placement (proposed, pending owners)

These are proposals, not ownership decisions. Reconcile with each repo's owners and `.crumb` before creating directories. No new repository.

| Piece | Proposed owner | Note |
|---|---|---|
| Compiler additions (OSC-EXT-BYTES, byte load and store, runtime bounds) | omega `src/compiler/` | extends the existing compiler; design merged as omega#169 |
| Shell core `.osc` (lexer, parser, expander, session) | omega | split across units (32 function limit per unit) |
| Linux host adapter | omega host scaffolding (ADR 0024), owner to confirm | ordinary C, no second parser |
| AIENOS native adapter (console, Store locations, artifact loading, tasks) | aienos | R1.1 |
| Platform ABI and conformance vectors | aien-protocols, `specs/osh-platform/` | draft in aien-protocols#16; "if consistent with current ownership" per the issue |
| This record, compatibility matrix, status | aien-architecture | scoped, not a plan |
| Visor views | omega `src/visor/`, reused through explicit interfaces | section 5 |
| Authority (mint, revoke) | capability root, unchanged | the shell never grants |

## 5. Visor reuse boundary

The Visor (`omega/src/visor/`) is an operator REPL with 19 fixed command words, four argument slots, a 4095-byte line limit and a 255-byte token limit (`visor_parse_command.h:31-33`); it is not Bash syntax. It is not renamed and not called a shell.

Reuse: the console output contract (human and JSON shapes, class tags); the inspection hooks (inspect, type, id, graph, machine, evidence, world, why); the classify-before-run gate as the pattern for any osh "run" (`visor_console.c:304-321`); `visor_effect_request.*` as the only way to render an effect object as a request.

Do not: add any osh path that sets `authorized`, mints, grants, publishes or executes through Visor objects; link `rx_*`, `aienos_cap_*` or `rc_*` into Visor objects; reimplement the digest check in `visor_effect_request.c`; widen the closed Visor command table (use a separate word table).

The invariant, quoted: "Invariant: THE VISOR CAN ASK. THE VISOR CANNOT GRANT." (`src/visor/visor_effect_request.h:4`; also `spec/visor-authority.md:3`). It is enforced by a link check (`tests/visor/check_authority_link.sh`, `make visor-authority-check`).

## 6. R1.1 dependencies: native services that do not exist

From the AIENOS readiness audit at `c63d6db` (read-only, no QEMU run; citations in the issue's audit are repo-relative). Each is an explicit dependency, to be implemented and reviewed, not assumed.

1. Serial console input (`console.c` has output only; the USB keyboard is the only key input).
2. A keyboard session beyond the 60 s total and 15 s idle limits, surviving the recovery choice (`usb_kbd.h:37-41`, `devices.c:75-83`, `xhci_fence.c:101-135`).
3. Shell commands beyond the six in the bounded console (`usb_hid.c:177-186`).
4. A task or process model to spawn into (scheduler is fixed 16 tasks, demo-only callers, `sched.h:9-10`).
5. An IPC endpoint for the shell (two principals, depth 8, 56-byte messages, `ipc.h:65-95`).
6. Runtime artifact read by name (read is boot-time only, `artifact_store.h:57-62`; no lookup-by-name).
7. Runtime artifact invoke (the loader runs once per boot, `artifact_loader.c:1326-1329`).
8. A trusted signer in the default build (zero anchors, `artifact_loader.c:90-91`, `admission.c:17`).
9. Production Store keys (default build uses TEST keys, `store_boot.c:363`; production blocked, `store_boot.c:342`).
10. The 64-bit capability authority started at normal boot with a shell view (only a test starts it, `stage_test.c:355`), and one capability model (the kernel IPC table is 32-bit, `ipc.h:39-54`).
11. A recovery console that accepts commands (the stub halts, `usb_kbd.c:571-592`).
12. A production operator key (`continuity_boot.c:36-38` is a TEST constant).
13. An Omega runtime or loader in native C (none found).

The existing recovery path stays model-independent and read-only; osh is not the only recovery mechanism and is not a repair bypass.

## 7. Status

Honest as of the pins above. "DONE" requires a link to evidence; none of the shell itself is done.

| Item | Status |
|---|---|
| Audit of compiler, Visor, AIENOS, scripts, parser design | DONE as read-only notes (not committed evidence); compiler quick tests 47/47 and 116/116 on `main` by the audit host run, UNVERIFIED by independent rerun |
| OSC-EXT-BYTES design | DONE, merged [omega#169](https://github.com/aien-dev/omega/pull/169) (design only) |
| First-release acceptance frozen | This file (draft, PR pending merge); NOT frozen until merged |
| Platform ABI v1 and vectors | IN PROGRESS: DRAFT [aien-protocols#16](https://github.com/aien-dev/aien-protocols/pull/16); not frozen; expected outputs unrun |
| OSC-EXT-BYTES implementation | IN PROGRESS: local uncommitted work on omega branch `osh/osc-ext-bytes` in a working clone; nothing pushed, no PR; no test result recorded |
| Shell core `.osc` | NOT STARTED as production code; a lexer prototype exists in the audit notes and compiled with `oscc` against `b980783` (6 functions), not committed, not an implementation |
| Linux adapter | NOT STARTED |
| Differential and hostile suite, pinned bash | NOT STARTED |
| Real script run (`run_builds.sh`) | NOT STARTED |
| Interpreter versus native ARM64 run | NOT STARTED |
| AIENOS native services (section 6) | NOT STARTED |
| Native QEMU acceptance | NOT STARTED |
| Attended hardware validation | NOT STARTED; needs separate authorization |
| Compatibility and limits matrix | NOT STARTED |

Verification performed so far is limited to the issue's own compile check and the audit notes above. No generated ARM64 code from this workstream has run. No milestone status changes.
