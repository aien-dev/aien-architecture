# ADR 0001: Canonical Composition Root

**Status:** Accepted

## Context

AIEN has multiple repositories and some mirrored crates. Cross-system behavior needs one composition authority.

## Decision

`aien-sovereign-core` is the canonical composition root. Architecture lives here in `aien-architecture`; implementation crates and protocol authorities remain linked explicitly. Mirrors must not silently become independent sources of truth.

## Consequences

Satellite repositories remain useful, but cross-system wiring must resolve to one canonical implementation or generated mirror pipeline.
