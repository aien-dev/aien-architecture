# ADR 0004: MCP Is a Compatibility Layer

**Status:** Accepted

## Context

AIEN already contains multiple hand-written Rust MCP servers.

## Decision

Canonical MCP lives at `aien-sovereign-core/crates/aien-mcp`, uses the official Rust MCP SDK, and translates MCP capabilities into AIEN Tool/Capability descriptors. `aien-mcp` owns sessions; J-Space does not.

## Consequences

AIEN remains compatible with MCP without coupling internal semantics to MCP protocol details.
