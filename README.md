# AIEN Architecture

Canonical whole-system architecture and execution authority for the AIEN ecosystem.

## Start here

Agents and maintainers should read these in order:

1. [Plan authority](PLAN_AUTHORITY.md)
2. [Current execution plan](CURRENT_EXECUTION_PLAN.md)
3. [Canonical architecture](doctrine/ARCHITECTURE.md)
4. [Canonical milestone registry](doctrine/ROADMAP.md)
5. [Architecture decision records](docs/adr/README.md)
6. [Implementation status snapshot](docs/02-implementation-status.md)
7. [Golden path](docs/13-golden-path.md)

Superseded whole-system plans are kept only under [docs/archive/plans](docs/archive/plans/README.md).

## Current doctrine

```text
ATLAS AWAKENS.
AIEN PROPOSES.
OMEGA DEFINES.
FORGE REALIZES.
AEGIS VERIFIES.
HARDWARE ACTS.
EVIDENCE TEACHES.
```

AIENOS owns the trusted OS/kernel substrate. OMEGA defines semantic computation. FORGE constructs machine realizations. AEGIS verifies contracts and invariants. Historical `PHYSICS_*` names remain unchanged in old milestones and evidence.

## Source-of-truth policy

- Architecture ownership and terminology: `doctrine/ARCHITECTURE.md`.
- Milestone IDs/status: `doctrine/ROADMAP.md`.
- Cross-project sequencing: `CURRENT_EXECUTION_PLAN.md`.
- Implementation claims: current code and reproducible evidence.

If these disagree, do not create another master plan. Record the discrepancy and update the appropriate authority.

## Component documentation

Detailed subsystem/reference documents under `docs/` remain useful, but they are subordinate to the authorities above. Component repositories may keep their own local roadmaps.

## License

See [LICENSE-NOTICE.md](LICENSE-NOTICE.md).
