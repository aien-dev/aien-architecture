# ADR 0007: J-Space Cannot Externalize Speculative Effects

**Status:** Accepted

## Context

J-Space explores multiple candidate Worlds, some of which will lose.

## Decision

Speculation-safe tools may execute. World mutations remain in draft Worlds. External write/irreversible tools may only create EffectIntents until the winning World is selected and AEGIS authorizes execution.

## Consequences

Losing branches cannot leak emails, deployments, pushes, purchases, deletions, or other external changes.
