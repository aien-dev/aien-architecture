# Implementation Status

**Snapshot date:** 2026-09-22.  
This is a review snapshot, not a permanent truth source.

Legend:

- ✅ implemented in meaningful code
- 🟡 partial / fragmented / not yet canonical
- ⬜ target architecture / not yet first-class

| Area | Status | Notes |
|---|---:|---|
| In-process runtime spine | ✅ | scheduler, transformer, KV, streaming, branching composed |
| Physical prefix sharing / COW | ✅ | branch tests exist |
| World drafts / staged effects | ✅ | core data structures exist |
| Cortex entities/claims/evidence | ✅ | durable schema exists |
| Signed evaluation receipts | ✅ | protocol layer includes signers and Merkle roots |
| RSI canary/rollback | ✅ | implemented in RSI path |
| AEGIS pre-dispatch checks | ✅ | present |
| Rust MCP servers | ✅ | debugger + harness proofs exist |
| Canonical MCP broker | 🟡 | target `aien-mcp`; current servers are fragmented |
| Vault-first resolution | 🟡 | exists; production-only no-env-fallback not universal |
| Tool/Skill semantic split | 🟡 | current registries mix atomic tools and higher-level skills |
| Long-context production native model path | 🟡 | evolving; verify branch/commit before claiming |
| Effect Broker | 🟡 | effect-specific code exists; universal non-bypassable broker is target |
| Signed World commits | 🟡 | provenance primitives exist; World commit is not yet universal signed envelope |
| Portable accelerator ABI | 🟡 | multiple backends exist; core still contains hardware-specific history |
| Capability Graph | ⬜ | target |
| Skill Router | ⬜ | target |
| AIEN Fabric | ⬜ | target |
| Machine identity / placement | ⬜ | target |
| J-Space | ⬜ | no canonical implementation found in reviewed public code |
| Relational Path Engine | ⬜ | PEARL-inspired target |
| Content-addressed model distribution | ⬜ | target |
| Adaptive graph/path exploration | ⬜ | target |
| Universal observability schema | ⬜ | target |

## Rule for updating this table

Every status change to ✅ should point to implementation evidence and at least one test or runtime artifact.
