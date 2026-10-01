# GitHub Repository Map

Snapshot-oriented map of the AIEN GitHub ecosystem, checked against `gh repo list aien-dev` on 2026-10-01. Code remains authoritative. "Archived" means the GitHub repository is read-only. Whether each archived component now lives as a crate in `aien-sovereign-core` is UNVERIFIED here (confirmed only for `spark-crumbs`, per docs/CRUMB_PROTOCOL.md).

## Core program repositories

| Repository | Visibility | Role |
|---|---|---|
| `aien-dev/aienos` | public | AIENOS, the sovereign operating system (pre-alpha). |
| `aien-dev/omega` | public | Omega, the C reaction runtime and compiler. |
| `aien-dev/physics` | public | FORGE machine realization plus historical Atlas/PHYSICS boot evidence. The subsystem was renamed FORGE by [ADR 0014](adr/0014-rename-machine-physics-to-forge.md), which keeps the existing `aien-dev/physics` repository name and history. The GitHub description is empty. |
| `aien-dev/atlas` | public | Atlas, the bare-metal boot layer. The GitHub description is empty. |
| `aien-dev/aien-protocols` | public | Protocol authority (see below). |
| `aien-dev/aien-architecture` | public | This repository. |
| `aien-dev/aien-sealed` | private | Name only. Holds evaluator-only material; never given to a candidate under test. |

Other live public repositories: `aien-dev/aien-edge`, `aien-dev/aienos.com`, `aien-dev/drakestapleton.com`, `aien-dev/aien-dev` (profile), `aien-dev/.github`, `aien-dev/aegis-runtime`, `aien-dev/spark-rsi`, `aien-dev/benchmarks`, `aien-dev/open-humanity`. The other private repositories in the organization are legacy application archives (per their GitHub descriptions),, except `encounter` and `MojoLlama`, which the GitHub descriptions show as non-legacy private projects.

## Canonical composition root

### `aien-dev/aien-sovereign-core`
https://github.com/aien-dev/aien-sovereign-core

Primary composition repository. Current workspace includes runtime, inference ABI/runtime, KV cache, scheduler, platform, Cortex mirror, AEGIS mirror, adapters, cockpit, supervisor, debugger, harness, dream, inquisitor, harvester, mail, and related crates.

Key target paths:

```text
crates/aien-runtime
crates/aien-inference-abi
crates/aien-inference-runtime
crates/aien-kv-cache
crates/aien-scheduler
crates/aien-platform
crates/aien-platform-linux
crates/cortex-rs
crates/spark-aegis
crates/spark-debugger
crates/spark-harness
crates/spark-inquisitor
crates/spark-mail-rs
```

## Protocol authority

### `aien-dev/aien-protocols`
https://github.com/aien-dev/aien-protocols

Canonical cross-process/cross-repo types:

- protocol types,
- agent state ABI,
- inference protocol/client,
- action/event protocol,
- evaluation protocol,
- provenance,
- probes.

Target architectural rule: typed boundaries should converge here or into narrowly scoped protocol crates in the sovereign core.

## Policy / safety

### `aien-dev/aegis-runtime`
https://github.com/aien-dev/aegis-runtime

Current home of:

- pre-dispatch enforcement,
- workspace capability,
- skill registry,
- vault resolver,
- probe-policy machinery.

Target: AEGIS owns authorization; Capability Graph owns discovery/routing.

## Memory

### `aien-dev/cortex-rs` (ARCHIVED, read-only)
https://github.com/aien-dev/cortex-rs

Durable memory and knowledge engine.

Current schema includes:

- spaces,
- entities,
- claims,
- sessions,
- events,
- summaries,
- memory candidates,
- candidate evidence,
- promotion receipts,
- claim evidence,
- security/evidence records.

## Recursive self-improvement

### `aien-dev/spark-rsi`
https://github.com/aien-dev/spark-rsi

Candidate proposal, evaluation, judge, canary, rollback, and promotion.

## Benchmarks

### `aien-dev/benchmarks`
https://github.com/aien-dev/benchmarks

Canonical performance/provenance benchmark work should be linked from this repo rather than copied into architecture docs.

## Local composition

### `aien-dev/aien-local-stack` (ARCHIVED, read-only)
https://github.com/aien-dev/aien-local-stack

Useful integration proof combining protocol crates, AEGIS, and sovereign-core components.

## Existing MCP compatibility fixtures

### `aien-dev/spark-debugger` (ARCHIVED, read-only)
https://github.com/aien-dev/spark-debugger

Contains a hand-written Rust stdio JSON-RPC MCP server.

### `aien-dev/aien-harness` (ARCHIVED, read-only)
https://github.com/aien-dev/aien-harness

Contains another hand-written Rust stdio MCP server around evaluation/validation capabilities.

Target: migrate protocol ownership into `aien-sovereign-core/crates/aien-mcp`; retain old servers temporarily as compatibility fixtures.

## Distributed / coordination / experimentation satellites

- `aien-dev/spark-hive` (archived, read-only)
- `aien-dev/spark-supervisor` (archived, read-only)
- `aien-dev/spark-dream` (archived, read-only)
- `aien-dev/spark-debugger` (archived, read-only)
- `aien-dev/spark-inquisitor` (archived, read-only)
- `aien-dev/spark-adapters` (archived, read-only)
- `aien-dev/harvester` (archived, read-only)
- `aien-dev/open-humanity`
- `aien-dev/crumb-spec` (archived, read-only)
- `aien-dev/spark-crumbs` (archived, read-only)

These should link to this repo for system-wide architecture while retaining component-specific documentation locally.

## Open Humanity

### `aien-dev/open-humanity`
https://github.com/aien-dev/open-humanity

Its Sovereign Manifesto establishes local-first, compiled-core, privacy, vault, durable-memory, and peer-cooperation principles that influence AIEN architecture.

## Source-of-truth policy

Architecture docs should never silently replace code inspection. A documentation update that claims a feature is complete should include:

- repository,
- branch/commit or PR,
- relevant implementation path,
- test or provenance evidence.
