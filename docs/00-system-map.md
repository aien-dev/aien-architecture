# System Map

AIEN is intended to operate as one logical system across multiple independent Machines.

```mermaid
flowchart TB
    subgraph Intelligence
        INF[Inference]
        JS[J-Space]
        SR[Skill Router]
    end

    subgraph State
        W[World]
        CX[Cortex]
        KV[Sequence / KV]
    end

    subgraph Action
        CG[Capability Graph]
        MCP[MCP]
        A[AEGIS]
        EB[Effect Broker]
    end

    subgraph Compute
        F[Fabric]
        M1[Machine 1]
        M2[Machine 2]
        M3[Machine 3]
        MN[Machine N]
    end

    subgraph Improvement
        RSI[RSI]
        H[Harness]
        I[Inquisitor]
        B[Benchmarks]
    end

    INF <--> KV
    JS --> W
    JS --> SR
    SR --> CG
    CG --> MCP
    CG --> F
    F --> M1
    F --> M2
    F --> M3
    F --> MN
    CG --> A
    A --> EB
    EB --> W
    W --> CX
    CX --> INF
    RSI --> H
    RSI --> I
    RSI --> B
```

## Responsibility table

| Concept | Owns | Must not own |
|---|---|---|
| Runtime | composition and execution loop | long-term knowledge |
| Sequence/KV | inference lineage and KV ownership | external effects |
| World | branchable transactional execution state | semantic memory |
| Cortex | durable knowledge/evidence/memory | live scheduler state |
| J-Space | alternatives, evaluation, selection | irreversible execution |
| Skill | reusable procedure/objective | authorization |
| Tool | atomic operation | global planning |
| Capability Graph | what exists and what it requires | execution authority |
| Fabric | where work runs | semantic tool choice |
| AEGIS | whether an action is permitted | transport |
| Effect Broker | irreversible execution | planning |
| MCP | protocol compatibility | core semantics |
| Provenance | evidence of what occurred | policy decisions |
| RSI | out-of-band optimization | direct hot-path mutation |

## Core invariant

The system can speculate freely inside reversible state. External reality changes only after selection, authorization, and effect execution.
