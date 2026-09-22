# Gap Analysis

## Strong today

- native Rust runtime composition,
- scheduler,
- branchable inference state,
- KV prefix sharing,
- streaming,
- Cortex evidence/memory,
- AEGIS enforcement primitives,
- signed evaluation receipts,
- RSI judge/canary/rollback,
- Rust MCP proofs,
- benchmark discipline.

## Fragmented

- MCP ownership,
- tools vs skills,
- secret policy,
- effect gating,
- signed runtime provenance,
- model loading/packing,
- accelerator abstraction,
- operator composition.

## Missing as first-class subsystems

1. Capability Graph
2. Skill Router
3. canonical `aien-mcp`
4. production `VaultOnly`
5. Effect Broker
6. signed World Commit
7. Model Capsule
8. portable accelerator contract
9. AIEN Fabric
10. Machine identity/placement
11. J-Space
12. distributed branch execution
13. content-addressed model distribution
14. Relational Path Engine
15. one observability vocabulary

## Market opportunity

The compelling combination is not any one item. It is:

```text
heterogeneous local Fabric
+ branch-native state
+ J-Space
+ capability routing
+ secure MCP/tool compatibility
+ transactional effects
+ signed provenance
+ durable memory
+ gated self-improvement
```

Existing projects solve pieces of this. AIEN should own the integration semantics.
