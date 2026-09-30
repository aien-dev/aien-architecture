# Implementation Status

**Snapshot date:** 2026-09-23.  
This is a review snapshot, not a permanent truth source.

**Cross-repo update, 2026-09-30.** The J-Space, Cortex and Capability Graph rows below were re-checked against `main` of `aien-dev/omega` (`6d1ff1d`), `aien-dev/aienos` (`f0facc7`), `aien-dev/physics` (`f63a6ef`) and `aien-sovereign-core` (`0df7c32`). The other rows keep their 2026-09-23 basis. "Host reference" below means C code that builds and runs on Linux inside a named test target and is not on the production runtime path. Which implementation owns each concept is recorded in `doctrine/ARCHITECTURE.md` §2.8.

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
| Cortex entities/claims/evidence | ✅ | durable schema exists in sovereign-core `crates/cortex-rs` (the live Linux LLM-stack Cortex). 2026-09-30: two more Cortex implementations exist and no authoritative owner is recorded: omega `src/runtime/rx_cortex.{c,h}` (host reference, append-only, one in-memory tier, L1/L2/L3 tiers not implemented, built only in the state-projection test, evidence `evidence/STATE_PROJECTION`) and aienos `crates/aienos-cortex` (Rust epistemic store). See `doctrine/ARCHITECTURE.md` §2.8 |
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
| Capability Graph | 🟡 | `ToolDescriptor`, `ToolEffects`, and `CapabilitySnapshot` exist in `aien-capability` / `aien-mcp` (#101). This is not yet the runtime graph of providers, machines, credentials, and policy. RSI's `CapabilityGraph` is a different type. 2026-09-30: the capability authority root is aienos `native/capability/aienos_capability.c` (C, built hosted as `libaienos_capability.a` and linked into omega test targets through `AIENOS_CAP_LIB`; it does not yet run inside a natively booted AIENOS kernel). omega `src/runtime/rx_capq.{c,h}` is a capability query IR only (the build refuses admin symbols); omega `src/runtime/rx_caproot.c` is a host reference root that does not claim R7. aienos `crates/aienos-capability` is the legacy Rust twin, still a dependency of `crates/aienos-kernel`. The canonical runtime Capability Graph (CEP F1) is missing |
| Skill Router | ⬜ | target |
| AIEN Fabric | ⬜ | target |
| Machine identity / placement | ⬜ | target |
| J-Space | 🟡 | 2026-09-30: host reference only. omega `src/runtime/rx_jspace.{c,h}` (semantic identity as a SHA-256 chain, realizations carry placement and cost) is built only into the `rx_branch_reuse` test target, evidence `evidence/BRANCH_REUSE`; it is not in the R13 living-system build. aienos `crates/aienos-aegis/src/world.rs` has a separate Rust `JSpaceWorld` sandbox that omega does not link (legacy). sovereign-core `aien-capability` has only `JNodeId` / `WorldId` identifiers. Missing: J-Space on the production reaction path (EST-7 planned) |
| Relational Path Engine | ⬜ | PEARL-inspired target. #102 adds an experimental harness only. The example fixture cannot produce a pass, and production recall is unchanged |
| Content-addressed model distribution | ⬜ | target |
| Adaptive graph/path exploration | ⬜ | target |
| Universal observability schema | ⬜ | target |

## Rule for updating this table

Every status change to ✅ should point to implementation evidence and at least one test or runtime artifact.
