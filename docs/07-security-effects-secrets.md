# Security, Effects, and Secrets

## Separation of powers

```text
Model     proposes
J-Space   compares
AEGIS     authorizes
Broker    externalizes
World     commits
Provenance proves
Cortex    remembers
```

## AEGIS on every provider

All providers enter the same policy boundary:

- Native
- MCP
- Fabric
- WASM
- Process
- HTTP

The broker routes; it does not grant authority.

## Secret invariant

The realistic invariant is:

> No plaintext secret at rest, in configuration, prompts, logs, receipts, Cortex, or World/J-Space state. A raw bearer secret may be materialized only at the narrowest volatile execution boundary and for the shortest duration required by a legacy protocol.

Preferred delivery:

1. broker-owned authentication,
2. short-lived OAuth token,
3. descriptor/pipe/socket delivery,
4. call-scoped child environment variable only when required.

## Credential scope

```rust
pub enum CredentialScope {
    FabricResolvable,
    MachineBound(MachineId),
    OperatorBound(OperatorId),
    SessionBound(SessionId),
}
```

Fabric placement filters Machines by credential resolvability.

## Effect Broker

Irreversible operations should execute in a small, heavily audited broker.

```text
Runtime
  -> AuthorizedEffect
  -> Effect Broker
  -> protocol-specific driver
  -> external system
  -> receipt
  -> World Commit
```

## Retry rule

Do not blindly retry an irreversible action after an ambiguous timeout.

Use:

- provider idempotency keys where available,
- remote-state reconciliation,
- explicit uncertain-effect state,
- operator reconciliation where necessary.
