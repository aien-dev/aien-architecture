# ADR 0005: Irreversible Effects Require a Broker

**Status:** Accepted

## Context

Speculative branches and model-driven tools must not directly change external reality.

## Decision

External irreversible effects are staged as intents, authorized by AEGIS after winner selection, and executed only by a small Effect Broker using protocol-specific drivers.

## Consequences

J-Space can speculate safely and external actions gain a single auditable execution boundary.
