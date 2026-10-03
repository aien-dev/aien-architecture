# ADR 0030: Switchboard, one typed router over our own AI accounts

**Status:** PROPOSED, 2026-10-03. Not yet reviewed by the operator, Drake Stapleton.
**Number:** 0030 was the next free number on 2026-10-03; no open PR claimed it.
**Related:** ADR 0024 (Rust is scaffolding, Omega is destination; Decision 1 and 4 cover a new Rust crate), ADR 0028 (AIEN-TEST), ADR 0006 (production secrets are vault-only), ADR 0022 (cognitive-routing idea reused as a pattern only, no dependency).
**Evidence:** `~/mindmap/notes/2026-10-03-switchboard-research.md`, `~/handoffs/switchboard/program-facts.md`.
**Implementation:** `aien-dev/aien-sovereign-core`, `crates/aien-switchboard` (cut 3, pure types and router with a fake runner).

## Context
The operator holds subscription accounts with several AI companies: 2 Anthropic, 2 Google, 1 xAI (Grok), 1 OpenAI, plus an OpenRouter key. Today he and the hive switch between them by hand and run into usage limits. He wants one local program that decides which account handles which job, and fails over when an account is out of room.

## Decision
1. **Purpose.** A Rust crate `aien-switchboard` that owns: account list, job description, usage gauge per account, a routing rule table the operator edits, and one deterministic decision function. Commands: `switchboard run "<prompt>" [--kind code|review|research]` and `switchboard status`.
2. **Home.** New crate `crates/aien-switchboard` in `aien-dev/aien-sovereign-core`. Reason: that repo is the Linux user-space Rust scaffolding home (ADR 0024 classification A, item 19), already holds the hive, adapters, `aien-test` runner and `aien-proof`, and ADR 0024 says new non-hardware systems work defaults to Rust. Not omega (C, resident runtime, chip work), not aienos (kernel). Contract at the boundary stays language-neutral per ADR 0024 Decision 5 so Omega can replace it later.
3. **Hard design rules.**
   1. Never read, copy, store or proxy subscription login tokens (Anthropic and Google forbid it in writing; Google names account termination).
   2. Each subscription account is the company's own unmodified program (`claude`, `codex`, `agy`, `grok`), signed in by the operator through that company's own login, one settings folder per account.
   3. OpenRouter is a direct web request; the key lives in process memory, resolved from `atlas-vault`, never written to a file (ADR 0006).
   4. AIEN works fully offline. The local model is the default route; outside accounts are optional help.
   5. No Python anywhere. Rust, licensed as the workspace is (`Apache-2.0 WITH LLVM-exception`), tests run through AIEN-TEST (ADR 0028).
4. **Accounts (initial).** anthropic-1, anthropic-2 (`claude`), google-1, google-2 (`agy`), xai-1 (`grok`), openai-1 (`codex`), openrouter-1 (HTTP), plus `local` (own model, always first for jobs it can meet).
5. **Router decision.** Typed and deterministic: inputs `Job{kind,size,needs}`, per-account `Gauge{used_pct?, resets_at?, cooled_down_until?}`, and an operator-owned plain config file mapping job kind to an ordered account list. Choice = first account in the list that meets the job's needs and has room; cheapest first, in the spirit of cognitive routing. No learned model in v1. A Jev-like fast learned chooser is a later, separately gated step.
6. **Gauges.** Read where a program reports them (Claude status-line `rate_limits`; OpenRouter `GET /api/v1/key`). Where it does not, treat a limit error or failed exit as the signal and cool the account down until the reset time, else a configured default.
7. **Offline-first.** With no network the router returns `local` or a typed refusal; it never blocks waiting for a vendor.
8. **Tests.** Router and failover with fake runners (no real accounts). One live smoke per account only with the operator present to sign in.

5a. **Cut 3 choices (the crate, first slice).** The rule file also lists accounts (a settings-folder path or a key reference name, never a secret). `local` is appended as the last fallback of every route and is never skipped, so a decision always exists. The `needs` part of a job is left out for now because no first-party source says what each program can do; it is UNKNOWN and tracked for a later cut.

## Not decided here
Wiring the hive and AIEN-TEST to call the Switchboard (later ADR). Any Omega port.

## Open UNKNOWNs
- Anthropic consumer terms on one person holding two paid accounts to spread usage: not read (https://www.anthropic.com/legal/consumer-terms). Must be read before shipping.
- xAI terms on automated use: page returned 403, not read.
- Side-by-side logins: `CLAUDE_CONFIG_DIR` documented; `CODEX_HOME` documented but multi-account not described; `GROK_HOME` name seen only in the binary; `agy` unknown.
- Usage-left in machine-readable form for codex, agy, grok: none found. Limit-error text for codex, agy, grok, and Claude's exact shape in `-p` json: undocumented.
