# ADR 0014: Rename Machine Physics to FORGE

**Status:** Accepted by operator, 2026-09-27

## Context

ADR 0013 corrected the architecture by redefining PHYSICS from a security gatekeeper into the machine lowering and physical realization subsystem. That change left three problems:

1. the name PHYSICS still suggests authority over physical truth and collides with the separate Physics Zero scientific-discovery program;
2. AIENOS now clearly owns the operating-system/kernel substrate: boot continuation, address spaces, tasks, interrupts, capabilities, DMA confinement, storage, recovery, and native device ownership;
3. current code already behaves more like a realization backend than the older “Trusted Machine Authority” wording implies.

The remaining name was therefore misleading even though the new responsibility boundary was correct.

## Decision

The current machine realization subsystem is renamed **FORGE**.

Canonical doctrine becomes:

```text
ATLAS AWAKENS.
AIEN PROPOSES.
OMEGA DEFINES.
FORGE REALIZES.
AEGIS VERIFIES.
HARDWARE ACTS.
EVIDENCE TEACHES.
```

FORGE is the machine realization engine and physical lowering compiler.

FORGE receives formal Omega programs plus machine facts/constraints, searches or constructs concrete realizations, emits machine-specific artifacts/schedules, and reports physical constraints/alternatives back to Omega.

AEGIS remains the continuous invariant/contract verifier. AIENOS remains the trusted OS/kernel substrate.

## FORGE owns

- machine descriptor normalization;
- physical lowering;
- machine-code/backend realization;
- register/layout/allocation planning;
- physical memory placement required by a realization;
- DMA/IOMMU/device realization plans;
- accelerator command/queue realization;
- machine-specific scheduling/autotuning;
- physical constraint and alternative feedback to Omega.

## FORGE does not own

- human intent;
- semantic meaning;
- goal selection;
- capability policy;
- self-authorization;
- learned planning;
- scientific Physics Zero.

## Historical compatibility rule

This rename is not a history rewrite.

The following remain unchanged when they are historical identifiers:

- `PHYSICS_BOOT`;
- `PHYSICS_EFFECTS`;
- `PHYSICS_ACCELERATOR_LINK`;
- old receipt fields and seals;
- old artifact names such as `physics.bin`;
- commit messages, tags, evidence bundles, and qualification records;
- the existing `aien-dev/physics` repository history.

New code, APIs, documentation, milestones, and receipts use FORGE unless they explicitly refer to historical compatibility.

The GitHub repository may be renamed from `physics` to `forge` as an administrative operation. Git history and qualified artifacts must not be rewritten as part of that operation.

## Consequences

- Physics Zero now exclusively names the scientific-discovery program.
- Current architecture stops implying that the machine-realization backend is a security authority.
- AIENOS and FORGE have distinct responsibilities.
- Agents have one current vocabulary while historical evidence remains truthful.
