# GitHub Repository Map

Snapshot-oriented map of the AIEN GitHub ecosystem. Code remains authoritative.

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

### `aien-dev/cortex-rs`
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

### `aien-dev/aien-local-stack`
https://github.com/aien-dev/aien-local-stack

Useful integration proof combining protocol crates, AEGIS, and sovereign-core components.

## Existing MCP compatibility fixtures

### `aien-dev/spark-debugger`
https://github.com/aien-dev/spark-debugger

Contains a hand-written Rust stdio JSON-RPC MCP server.

### `aien-dev/aien-harness`
https://github.com/aien-dev/aien-harness

Contains another hand-written Rust stdio MCP server around evaluation/validation capabilities.

Target: migrate protocol ownership into `aien-sovereign-core/crates/aien-mcp`; retain old servers temporarily as compatibility fixtures.

## Distributed / coordination / experimentation satellites

- `aien-dev/spark-hive`
- `aien-dev/spark-supervisor`
- `aien-dev/spark-dream`
- `aien-dev/spark-debugger`
- `aien-dev/spark-inquisitor`
- `aien-dev/spark-adapters`
- `aien-dev/harvester`
- `aien-dev/open-humanity`
- `aien-dev/crumb-spec`
- `aien-dev/spark-crumbs`

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
