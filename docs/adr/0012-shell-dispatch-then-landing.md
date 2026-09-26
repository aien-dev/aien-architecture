# ADR 0012: One Shell Dispatch, Then a Landing Split

**Status:** Accepted

## Context

Shell execution has more than one entry, and a shell request can ask for an effect that leaves the machine. ADR 0005 already reconciles irreversible external effects through the Effect Broker adapter after AEGIS verifies them.

## Decision

Every shell request enters one AEGIS shell dispatch. The dispatch applies invariant verification checks and workspace bounds. Local execution inside AEGIS is allowed only when the dispatch has positive evidence that the effect stays on the machine. Failure to recognize an external effect is not that evidence, and unclassified shell text does not take the local path. A command that is not eligible for local execution is requested as a typed effect Tool, verified by AEGIS, lowered by PHYSICS, and externalized by the Effect Broker adapter. Shell text does not exempt an external effect. A Tool may prepare that effect. This path is workspace-bound execution under continuous verification. It is not an OS sandbox.

## Consequences

Callers do not assemble the invariant verifier and the workspace check themselves. Positive evidence is membership in a closed catalog of whole command forms. The first word of a command is not membership. A pipe, a substitution, a sequencer, or a script file is not a form. A command outside the catalog is requested as a typed Tool, verified by AEGIS, lowered by PHYSICS, and externalized by the Effect Broker adapter.
