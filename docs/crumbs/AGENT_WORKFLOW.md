# How an agent works with Crumbs (RFC-0001 + RFC-0002)

One rule, always: **before modifying an unfamiliar repository path, inspect the applicable Crumb. Respect its invariants and shared locks. Follow related Crumbs, Git history, evidence and active continuation state until the purpose of the code is understood. Do not rely on undocumented assumptions from previous sessions.** Context is loaded on demand; nobody hands you the whole architecture up front.

## Meeting an unfamiliar file
```
crumb explain native/kernel/core/infer.c
```
You get, in bounded sections: what the directory is for and its layer; the invariants it inherits from parent crumbs; who holds locks or scents there right now; the last commits that touched the path and any commit the crumb calls significant; evidence references; and the newest Continuation Crumb whose scope includes it, with its PROVEN / PARTIAL / BLOCKED lines. Follow the references that matter (`git show <sha>`, the receipt file, the related `.crumb`) instead of reading everything.

## Doing a cut (RFC-0001 lifecycle, now repository-wide)
```
crumb sniff   <agent> <dir>                     # read before touching; shows agents, locks, whispers from EVERY worktree
crumb claim   <agent> <dir> <target> "<intent>" # exit 2 = someone else holds it: stop, read their scent, do not take it
crumb update  <agent> <dir> "<focus>"           # heartbeat while you work
crumb whisper <agent> <dir> - "<finding>"       # what the next agent must know
crumb close   <agent> <dir> <target> modify "<what landed>"   # after pushing
```
`<agent>` is a stable session id you choose once (e.g. `claude-l6b-7f32`), never a process id. Targets are repository-relative; it does not matter which worktree you run the command in.

## Ending a long session (QUIESCE -> CHECKPOINT -> VERIFY -> WHISPER -> RELEASE)
1. Quiesce: no new branches, decisions or workers; finish the cut in hand to a clean boundary or record exactly where it stopped.
2. `crumb checkpoint <agent> --reason context-pressure` (today: `cc.sh new`), fill the record from the machine state (`git`, receipts, test output), not from memory. Tag every fact PROVEN (with a reference) / PARTIAL / BLOCKED (named dependency) / ASSUMED / OPEN. Keep the definition of done verbatim. Order next tasks by dependency with gates. Carry operator boundaries and who-owns-what.
3. Seal (`--seal` / `cc.sh seal`): the checks must pass; the tool leaves the pointer whisper.
4. Release every lock with `crumb close`.

## Starting a session (SNIFF -> RESOLVE -> REVALIDATE -> LEASE -> RESUME)
1. `crumb sniff` the root: the high-priority whisper names the continuation id (or read `continuations/LATEST`).
2. `crumb resume <id>` (today: `cc.sh resume <id>`): prints the record and compares it with the live repository; stale or superseded pins are flagged.
3. Judge each flag yourself: has the top blocker been fixed since? did main move past the pin? Record verdicts. Re-read the cheapest critical receipt; do not rerun long gates just to feel sure.
4. Re-claim the owned paths. Exit 2 means another agent is there: stop.
5. Do `first_action`. Only now.

## What not to do
- Do not paste the previous conversation into the new one.
- Do not call something PROVEN because a previous agent sounded sure. Point at the receipt or downgrade it.
- Do not soften the definition of done while checkpointing.
- Do not write to `.crumb.local` inside a repository; the shared store is authoritative. Legacy files are read, imported with provenance, and left alone.
- Do not start work before the lock table is rebuilt.
