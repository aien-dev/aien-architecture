# ADR 0006: Production Secrets Are Vault-Only

**Status:** Accepted

## Context

Existing vault resolvers may allow environment fallback.

## Decision

Production configuration stores only credential references. Raw values are resolved just in time at the narrowest broker boundary. Environment fallback is development-only and explicit.

## Consequences

Legacy tools can still receive call-scoped environment variables when unavoidable, but AIEN config, prompts, logs, state, and provenance remain secret-free.
