# Instructions for agents working on AIEN architecture

Before making cross-project architectural or roadmap changes, read these files in order:

1. `PLAN_AUTHORITY.md`
2. `CURRENT_EXECUTION_PLAN.md`
3. `doctrine/ARCHITECTURE.md`
4. `doctrine/ROADMAP.md`
5. the relevant accepted ADRs

Rules:

- There is one active cross-project master implementation plan: `CURRENT_EXECUTION_PLAN.md`.
- Do not create another “master”, “final”, “complete”, or “canonical” whole-system plan.
- Superseded plan files under `docs/archive/plans/` are historical only.
- Component roadmaps are local implementation aids and do not override cross-project architecture or sequencing.
- Current subsystem name: FORGE. Historical `PHYSICS_*` milestone IDs/receipts remain unchanged.
- Implementation/evidence truth beats planning claims. If code and plan differ, record the discrepancy; do not pretend the target is implemented.
- A milestone status changes only in `doctrine/ROADMAP.md`.
