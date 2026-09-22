# Canonical Flows

## 1. Normal inference

```mermaid
sequenceDiagram
    participant U as User
    participant C as Control Plane
    participant R as Runtime
    participant X as Cortex
    participant I as Inference
    participant W as World

    U->>C: message
    C->>R: submit turn
    R->>X: retrieve relevant context
    X-->>R: evidence + memories
    R->>I: tokenized request
    I-->>R: token deltas
    R->>W: record state transition
    R-->>C: stream output
    C-->>U: response
```

## 2. Skill and tool resolution

```mermaid
flowchart LR
    OBJ[Objective] --> JS[J-Space]
    JS --> SR[Skill Router]
    SR --> CG[Capability Graph]
    CG --> CF[Constraint Filter]
    CF --> TOP[Top candidate skills/tools]
    TOP --> JS
    JS --> F[Fabric Placement]
    F --> EX[Executor]
```

## 3. MCP discovery vs effect authority

```mermaid
flowchart TD
    S[MCP Server] <-->|persistent session| SM[aien-mcp Session Manager]
    SM --> D[Discovery Lane]
    SM --> SC[Speculation-Safe Lane]
    SM --> ED[Effect Driver Lane]

    D --> CG[Capability Graph]
    CG --> JS[J-Space]
    SC --> JS

    JS -->|stage irreversible intent| A[AEGIS]
    A -->|AuthorizedEffect| EB[Effect Broker]
    EB --> ED
```

J-Space never owns the MCP session. `aien-mcp` owns protocol/session state.

## 4. Irreversible effect

```mermaid
sequenceDiagram
    participant J as J-Space
    participant A as AEGIS
    participant E as Effect Broker
    participant D as Driver
    participant X as External System
    participant W as World
    participant P as Provenance

    J->>J: choose winning World
    J->>A: EffectIntent
    A-->>J: AuthorizedEffect
    J->>E: AuthorizedEffect
    E->>D: execute
    D->>X: external operation
    X-->>D: result
    D-->>E: execution result
    E->>P: receipt
    P-->>E: signed evidence
    E->>W: finalize commit
```

## 5. Secret resolution

```mermaid
flowchart LR
    TC[ToolCall] --> CR[CredentialRef]
    CR --> A[AEGIS]
    A --> FP[Fabric Placement]
    FP --> B[Broker on selected Machine]
    B --> V[Vault]
    V --> B
    B --> CHILD[Call-scoped execution]
```

Raw values must not enter prompts, J-Space, World state, Cortex, logs, or receipts.

## 6. Distributed J-Space

```mermaid
flowchart TD
    ROOT[Parent World] --> A[Candidate A]
    ROOT --> B[Candidate B]
    ROOT --> C[Candidate C]

    A --> M1[Machine 1]
    B --> M2[Machine 2]
    C --> M3[Machine 3]

    M1 --> J[Judge]
    M2 --> J
    M3 --> J

    J --> WIN[Winning World]
    WIN --> AUTH[AEGIS / Commit]
```

## 7. Machine join

```mermaid
sequenceDiagram
    participant N as New Machine
    participant F as Fabric
    participant C as Capability Graph
    participant S as Scheduler

    N->>F: authenticated join
    F->>N: topology probes
    N-->>F: capabilities + model/tool cache
    F->>C: publish provider set
    C->>S: placement options updated
```

## 8. Machine failure

```mermaid
flowchart LR
    TASK[Work Lease] --> M[Machine]
    M -->|lease expires| F[Fabric]
    F --> R[Reconstruct from durable refs]
    R --> M2[Another Machine]
```

Never require remote RAM to be the only source of truth for recoverable work.

## 9. RSI optimization

```mermaid
flowchart LR
    T[Telemetry] --> RSI[RSI]
    B[Benchmarks] --> RSI
    C[Cortex Lessons] --> RSI
    RSI --> H[Hypothesis]
    H --> CA[Candidate]
    CA --> E[Evaluators]
    E --> CAN[Canary]
    CAN -->|pass| P[Promote]
    CAN -->|fail| RB[Rollback]
```
