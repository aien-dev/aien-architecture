# Capabilities, Skills, Tools, and MCP

## Definitions

### Tool
Atomic capability.

Examples:

```text
filesystem.read
filesystem.write
process.execute
git.diff
git.commit
mail.send
cortex.search
browser.navigate
```

### Skill
Reusable procedure composed from tools, constraints, success conditions, and optional J-Space strategy.

Examples:

```text
software.debug.rust
software.review.pull_request
research.deep
communication.answer_email
operations.release
```

### Capability Graph
Authoritative semantic catalog describing:

- what a capability means,
- required tools/resources,
- possible effects,
- providers,
- compatible Machines,
- required credentials,
- policy constraints,
- cost/performance metadata.

## Router pipeline

```text
intent
  → deterministic aliases
  → metadata/tags
  → lexical retrieval
  → semantic retrieval
  → small router model if needed
  → J-Space if genuinely ambiguous
  → hard constraint filter
  → top-K candidates
```

A model should not receive thousands of schemas.

## MCP role

MCP is one provider protocol under the Capability Graph.

```text
Capability Graph
 ├─ Native AIEN provider
 ├─ MCP provider
 ├─ WASM provider
 ├─ Process provider
 ├─ HTTP/OpenAPI provider
 └─ Fabric remote provider
```

## Session ownership

`aien-mcp` owns live MCP sessions.

J-Space receives immutable or versioned capability snapshots.

For irreversible tools:

```text
J-Space
  → stages intent
  → winner selected
  → AEGIS authorizes
  → Effect Broker
  → aien-mcp effect driver
  → MCP tools/call
```

For safe tools, J-Space may request execution through the speculation-safe lane.

## Wire migration

Recommended sequence:

1. `McpWire` seam + in-memory provider.
2. Attach official Rust `rmcp`.
3. Add session manager/discovery snapshots.
4. Enforce effect classes.
5. Add vault-backed credential references.
6. Migrate `spark-debugger` and `spark-harness`.

## Authorization type rule

Do not expose an unrestricted production constructor that lets arbitrary code mint `AuthorizedEffect<T>`.

Production authority must be minted only by the policy path.

```rust
EffectIntent<T>
    -> policy evaluation
    -> AuthorizedEffect<T>
```

Test fixtures may use an explicit test-only constructor.

## Effect classification

Each tool declares its effects.

```text
PURE
READ_FILESYSTEM
READ_NETWORK
SPAWN_PROCESS
LOCAL_EPHEMERAL
WORLD_MUTATION
EXTERNAL_WRITE
EXTERNAL_IRREVERSIBLE
SECRET_BEARING
```

J-Space can execute only speculation-safe effect classes. External writes are staged until commit.
