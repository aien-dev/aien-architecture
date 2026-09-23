# ADR 0009: Names State Implemented Contracts

**Status:** Accepted

## Context

Public language has described intended mechanisms as if they were the running behavior. A registered name can share a word with a real subsystem and inherit a maturity it does not have.

## Decision

A name states the contract the implementation performs. A capability may be absent. It may not impersonate successful execution. The rule covers every model-facing capability, both Tools and Skills, as those words are fixed by ADR 0003. A registry whose type is named Skill does not create a second definition of Skill. Documentation describes the implementation that exists. Intended behavior is labeled as intent. A real subsystem does not inherit the status of an incomplete adapter that shares its name.

## Consequences

Model-facing catalogs advertise only capabilities whose handlers perform the stated contract. Scaffold handlers that remain callable return an explicit unavailable result. Aspirational sentences in charters and READMEs yield to this rule where they disagree.
