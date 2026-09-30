# World, Cortex, and Provenance

> **Implementation status (2026-09-30).** World state is owned by omega `src/runtime/rx_world.c`. Cortex has three implementations and no recorded authoritative owner: sovereign-core `crates/cortex-rs` (live Linux LLM stack), omega `src/runtime/rx_cortex.{c,h}` (host reference, one in-memory tier) and aienos `crates/aienos-cortex` (Rust). Evidence is written by omega `src/omega_evidence.{h,c}`; no shared cross-repo evidence schema exists. Ownership: `doctrine/ARCHITECTURE.md` §2.8.

## World

World is branchable execution state.

```text
World
 ├─ object root
 ├─ filesystem root
 ├─ token root
 ├─ memory view/root
 ├─ capability set
 ├─ effect intents
 └─ parent lineage
```

Worlds support speculative execution without immediately changing external reality.

## Cortex

Cortex is durable epistemic memory.

It owns:

- entities,
- claims,
- evidence,
- sessions/events,
- summaries,
- memory candidates,
- promotion receipts,
- verification tiers.

It does not own the live scheduler or speculative execution lifecycle.

## Provenance

The target signed World commit binds:

```text
parent World
object/filesystem/token/memory roots
effect root
evidence root
model/tokenizer identity
policy digest
runtime build digest
J-Space decision
signer identity
signature
```

Reuse existing AIEN protocol signers and Merkle-root machinery.

## Hardware signing

Do not place hardware signing in the hot path for every small event.

Preferred:

- short-lived session signer,
- Merkle batching,
- periodic hardware-rooted checkpoint.

## Memory promotion

Inferred knowledge should enter Cortex through candidate/evidence/promotion flow, not be silently asserted as fact.
