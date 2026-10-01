# ADR 0027: Formal verification uses Lean as a temporary oracle; Omega owns the invariants

**Status:** ACCEPTED, 2026-10-01. Decided by the operator, Drake Stapleton, through his Formal Verification Bootstrap Plan of 2026-10-01 (pasted by him, which is the decision; no separate ratification step is needed).
**Supersedes:** nothing. It rules out one interpretation: that "formal verification" means Lean becomes a permanent AIEN subsystem.
**Extends:** `doctrine/SOVEREIGNTY.md` section 3 (the Oracle Principle) by naming Lean as a registered Oracle. **Related:** ARCH-0024 (Rust scaffolding, Omega destination, C where hardware-justified), ARCH-0013 (AEGIS as the invariant checker), ARCH-0016 (resident reaction architecture).
**Evidence base:** `~/handoffs/formal-verification/PLAN.md` (operator plan, sections 1, 4 to 8, 17, 19, 20); `doctrine/SOVEREIGNTY.md` section 3 on `aien-architecture` main b4fce15; aienos main 2ee61b4 (`crates/aienos-aegis/src/capability.rs`, `crates/aienos-artifact/src/receipt.rs`, `native/capability/`).

---

## Context

The project wants machine-checked proofs for a small set of security-relevant invariants (capability attenuation, revocation, receipt consistency, later sequence identity, KV layout, continuity). Lean 4 is a strong tool for this today. Omega, the permanent substrate, cannot yet check proofs. The risk is that a useful tool becomes a permanent dependency simply because replacing it is hard. ARCH-0024 already states the general rule for languages: no scaffold gets permanent ownership because replacement is difficult. This ADR applies that rule to theorem proving.

Formal work is meant to teach Omega what it must eventually own. Lean is successful when AIEN no longer needs it.

## Decision

The ten points below are the operator's, kept in meaning.

1. **Omega owns the invariant semantics.** What an invariant means is defined in AIEN/Omega terms, not in Lean terms.
2. **Lean is an Oracle-Principle dependency.** It is an Oracle in the sense of `doctrine/SOVEREIGNTY.md` section 3: it may be queried for ground truth and may exist outside the permanent lineage only as explicitly non-required, with a registered deprecation horizon (see Registration).
3. **Lean source is not canonical identity.** A theorem name or a `.lean` file never defines an invariant. The invariant ID survives migration; the Lean theorem name does not.
4. **No runtime component depends on Lean.** No kernel, loader, store, agent, or service invokes Lean or Lake at run time.
5. **No permanent serialized AIEN format contains Lean-specific concepts.** No Lean term, universe, tactic, or declaration name appears in a receipt, artifact, store object, or wire format that is meant to last.
6. **Lean results may become evidence but never authority by themselves.** A Lean PASS is one evidence input, bound to an exact source and model revision. It does not by itself admit, release, or qualify anything.
7. **Every Lean-backed invariant needs an Omega takeover condition.** Written in its manifest (`omega_takeover_condition`) before any Lean proof for it is accepted.
8. **Removing Lean is a required project exit gate** (`LEAN_SEVERANCE = PASS`, see Severance).
9. **Formal verification supplements empirical qualification.** It does not replace tests, mutation testing, differential tests, silicon qualification, receipts, or hardware evidence.
10. **Power-button-to-Omega closure is a later project and is explicitly non-blocking.** Firmware and reset-vector ownership are not on this critical path.

### Scaffold classification (operator plan, section 1)

| Item | Classification |
|---|---|
| Rust | Scaffolding (ARCH-0024) |
| C, including current bare-metal C | Scaffolding |
| Assembly source | Scaffolding where Omega eventually generates the machine instructions itself |
| Linux | Scaffolding |
| UEFI | Presently usable scaffolding |
| NVIDIA kernel interfaces | Hardware-development oracles |
| Lean | Mathematical oracle |
| Current `aien-proof` | Evidence scaffold |
| Existing AIENOS, Physics, sovereign-core implementations | Executable specifications and migration sources |

None of these need to disappear now. Immediate policy: stay as bare metal as practical, avoid unnecessary foreign dependencies, keep shipping, and do not let eventual Omega-only closure block current progress. Eventual policy: no temporary scaffold receives permanent architectural ownership merely because replacing it is difficult.

### Repository strategy

- The **invariant registry** is permanent and implementation-neutral. It lives in `formal/invariants/` in this repository, outside `bootstrap/`, because it must survive Lean. See `formal/invariants/SCHEMA.md`.
- The **Lean bootstrap**, when it exists (not before FORMAL-2), lives in `bootstrap/formal-oracles/lean/` in this repository, an explicitly disposable area. If it outgrows a small package it moves to a dedicated repository, `aien-formal-oracles`. Either way it declares:

```text
classification      = DEVELOPMENT_ORACLE
permanent_lineage   = false
deprecation_target  = OMEGA_FORMAL_CLOSURE
```

- No permanent `aien-lean` subsystem is created.
- This ADR creates no Lean code, no Lean install, and no CI change.

### Registration under the Oracle Principle

`doctrine/SOVEREIGNTY.md` section 3.1 requires each Oracle to be registered with its deprecation horizon. Lean is registered here: horizon = `LEAN_SEVERANCE` (below), deprecation target = `OMEGA_FORMAL_CLOSURE`. The closure qualification must succeed with Lean absent. Section 3.2 (zero code leakage, black-box comparator, disposable status) applies: no Lean source, library, or generated artifact enters the permanent lineage, and Lean talks to AIEN only through serialized results (PASS/FAIL records bound to an invariant ID, model revision, and source revision).

### Severance criteria (operator plan, section 17)

Lean is removable only when all production-relevant Lean-backed invariants satisfy:

1. A stable Omega invariant identity exists.
2. Omega expresses every relevant assumption.
3. Omega accepts the positive corpus.
4. Omega rejects the negative corpus.
5. Omega kills the required semantic mutants.
6. Omega produces canonical proof/evidence identity.
7. Current gates consume Omega proof status.
8. RSI consumes implementation-neutral/Omega proof evidence.
9. No runtime invokes Lean.
10. No required build invokes Lean or Lake.
11. Deleting the Lean bootstrap changes no production result.

Then `LEAN_SEVERANCE = PASS`, and Lean is removed from required CI, agent preflight, qualification, RSI admission, release generation, developer bootstrap, and permanent lineage. The final Lean tree and receipts are kept only as historical genesis evidence.

### RSI rule (operator plan, section 19)

RSI (`spark-rsi`) never contains Lean. It asks only whether a candidate touches a protected invariant surface; if so, it determines the required invariant IDs, verifies each current proof/evidence object, its exact candidate/source binding, and its dependencies, and requires PASS. A missing, stale, or failing required proof means the candidate is not admitted. There is never a `--skip-proof`, `--trust-model`, or `--assume-safe` option for required hard invariants. The review-branch-only ratification policy and human merge authority are unchanged.

### Non-interference rules (operator plan, section 20)

Until current work lands, this project does not: edit Omega M20 tensor code; edit the active PREFILL integration surfaces; edit active AIENOS C Store, disk, or continuity implementation; fix I11; create a new shared protocol merely because the Lean oracle needs metadata; rewrite working Rust into C for formal-verification purposes; or rewrite working C into Omega before Omega can represent it faithfully. Formal work initially occupies: this ADR, the neutral invariant manifests, the temporary Lean oracle, stable AEGIS capability semantics, stable artifact receipt semantics, and an evidence adapter.

### Rules for the implementing agent

Never upgrade NOT_RUN into PASS. Never treat host or QEMU evidence as physical GB10 qualification. Preserve failed receipts and counterexamples. Separate observed implementation from proposed invariant. Cryptographic correctness (signatures, HMAC, hashes) is an assumption at this level unless separately formalized.

### Milestone naming

The operator plan numbers its milestones M0 to M14. Those collide with the canonical milestone identifiers owned by `doctrine/ROADMAP.md`. In this repository they are cited as FORMAL-0 to FORMAL-14. FORMAL-0 is this ADR; FORMAL-1 is the registry in `formal/invariants/`.

## Relationship to ARCH-0024 and the Oracle Principle

Consistent, with two notes recorded plainly.

1. ARCH-0024 classifies Rust and C as scaffolding and Omega as destination. This ADR adds Lean to the same scaffolding family. No conflict.
2. The Oracle Principle text in `doctrine/SOVEREIGNTY.md` section 3.1 describes Oracles as producing "reference output tensors" and numerical parity checks, and section 3.2 says "Zero Training Leakage: oracle outputs are verification signals only." It does not mention proof oracles. Treating Lean as an Oracle extends the Principle to a new kind (a symbolic proof checker rather than a numeric comparator). This ADR does not edit SOVEREIGNTY.md; if the operator wants the Oracle definition widened in doctrine text, that is a separate change. Until then, this ADR is the registration of Lean as an Oracle.
3. ARCH-0013 names AEGIS as the continuous invariant verifier. This ADR does not change that: AEGIS code remains the thing being checked, and Omega-owned invariant identities are what AEGIS-related proofs refer to.

## Consequences

- Invariants get stable `AIEN.INV.*` IDs before any Lean exists (FORMAL-1, this change).
- Lean work cannot start (FORMAL-2 onward) without this ADR, the registry, and an Omega takeover condition per invariant.
- Observed implementation facts and proposed invariants are kept separate in each manifest. Where Rust and C implementations of the same invariant differ (they do for capabilities, see the manifests), the invariant states the neutral rule and records each implementation's divergence.
- Nothing in this ADR changes runtime behavior, CI, or any other repository.
