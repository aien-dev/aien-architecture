# Implementation Status

**Snapshot date:** 2026-09-23.  
This is a review snapshot, not a permanent truth source.

Reviewed `aien-sovereign-core` `main` at `8d5f837` (merge of #98). That history includes #99 at `9cec202` (runtime change `7af0715`: CPU bf16 KV decode, a real child fork with shared KV page checks, Cortex record for an allowed mail effect), #100 (architecture roadmap), #101 (`aien-capability` and `aien-mcp`), and #102 (experimental PEARL harness). AEGIS `main` includes #32 at `6272261` (closed local-shell catalog, unadvertised unavailable tools, production secret resolution fails closed unless `AIEN_DEV_SECRET_FALLBACK` is set). RSI measured-canary promotion is `spark-rsi` #27.

Legend:

- ✅ implemented in meaningful code
- 🟡 partial / fragmented / not yet canonical
- ⬜ target architecture / not yet first-class

| Area | Status | Notes |
|---|---:|---|
| In-process runtime spine | ✅ | scheduler, transformer, KV, streaming, branching composed |
| Physical prefix sharing / COW | ✅ | branch tests exist, including shared-page verification after a real child fork (#99) |
| World drafts / staged effects | ✅ | core data structures exist |
| Cortex entities/claims/evidence | ✅ | durable schema exists |
| Signed evaluation receipts | ✅ | protocol layer includes signers and Merkle roots |
| RSI canary/rollback | ✅ | implemented in RSI path; production quota counts measured observations only (#27) |
| AEGIS pre-dispatch checks | ✅ | present |
| Rust MCP servers | ✅ | debugger + harness proofs exist |
| Canonical MCP broker | 🟡 | `aien-mcp` and `aien-capability` are workspace crates (#101): in-memory wire, speculative lane, effect lane, sealed `AuthorizedEffect`. rmcp transport and a single live broker are not there yet. `spark-debugger` and `spark-harness` remain separate servers |
| Vault-first resolution | 🟡 | AEGIS fails closed unless `AIEN_DEV_SECRET_FALLBACK` is explicitly on (#32). That rule is not yet every resolver |
| Tool/Skill semantic split | 🟡 | `SkillRegistry` still owns atomic handlers such as `bash_eval` and `read_file`. `cortex_recall` and `telemetry_ping` stay callable, are not advertised, and return unavailable. Local shell is a closed catalog of whole command forms |
| Long-context production native model path | 🟡 | evolving; verify branch/commit before claiming |
| Effect Broker | 🟡 | mail can check policy and record an allow in Cortex. There is still no single broker that every irreversible effect must pass through |
| Signed World commits | 🟡 | provenance primitives exist; World commit is not yet universal signed envelope |
| Portable accelerator ABI | 🟡 | multiple backends exist; core still contains hardware-specific history |
| Capability Graph | 🟡 | `ToolDescriptor`, `ToolEffects`, and `CapabilitySnapshot` exist in `aien-capability` / `aien-mcp` (#101). This is not yet the runtime graph of providers, machines, credentials, and policy. RSI's `CapabilityGraph` is a different type |
| Skill Router | ⬜ | target |
| AIEN Fabric | ⬜ | target |
| Machine identity / placement | ⬜ | target |
| J-Space | ⬜ | no canonical implementation found in reviewed public code |
| Relational Path Engine | ⬜ | PEARL-inspired target. #102 adds an experimental harness only. The example fixture cannot produce a pass, and production recall is unchanged |
| Content-addressed model distribution | ⬜ | target |
| Adaptive graph/path exploration | ⬜ | target |
| Universal observability schema | ⬜ | target |

## Rule for updating this table

Every status change to ✅ should point to implementation evidence and at least one test or runtime artifact.
