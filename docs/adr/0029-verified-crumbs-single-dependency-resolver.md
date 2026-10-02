# ADR 0029: Verified Crumbs: Omega's verified library is the only dependency resolver

**Status:** ACCEPTED, 2026-10-02. Decided by the operator, Drake Stapleton, through his approved Verified Crumb plan of 2026-10-02 (pasted by him, which is the decision; no separate ratification step is needed). Nothing in this document is implemented. Source: the plan and ground-truth record `~/handoffs/2026-10-02-VC1-plan.md` (cited below as "the plan"), whose omega facts were checked against omega `origin/main` `6fbf316`.
**Supersedes:** nothing. **Amends:** ARCH-0028 Decision 4 (EvidenceReceiptV1), in the way Decision 6 below states; ARCH-0028 is not otherwise changed.
**Extends:** ARCH-0024 (Rust is scaffolding, Omega is destination) by applying it to dependencies: the resolver that matters lives in Omega, and the Rust and C stack of today is bridged to it by a checker. Applies `doctrine/SOVEREIGNTY.md` section 3 (the Oracle Principle) to library admission.
**Related:** ARCH-0028 (aien-test and its receipt, which Decision 6 amends), ARCH-0021 decision 3 (append-only receipts bound to clean commits), ARCH-0027 (Lean as a temporary oracle, same pattern of "Omega owns the invariant"), ARCH-0016 (resident reaction architecture, causal crumbs in section 20).
**Specification (in flight):** `aien-dev/aien-protocols`, `specs/verified-crumb/`, being written by the VC1-FMT stage in parallel with this ADR. This ADR fixes the decisions; that path will hold the byte-level encoding and the golden vectors. Until it merges, the byte layout is not defined anywhere and nothing may depend on it.
**Citation:** from other repositories, cite this decision as ARCH-0029.

---

## In plain words (read this first)

AIEN already has a library of programs that Omega has verified. This decision makes that library the only place a program may get its parts from. A part is named by what it is (its content identity), never by a file path, a version label or a download. Before a program is allowed to use a part, Omega checks that a passing test record exists for exactly that part and for every part it depends on. If any check fails, the program does not build. There is no switch to turn the check off in the build that produces sealed output.

Because an unchecked part cannot be built in, the rule "agents must use verified parts" does not need to be written down and obeyed. It stops being a rule and becomes a property of the compiler.

Developers still need to experiment with unchecked code. That happens in a second, separate mode whose output is marked as tainted and can never enter the library. There is a one-way door from experiment to library, and it only opens through a passing test record.

---

## Context

The word "crumb" already names two things in AIEN. This decision adds a third, so the three are separated first.

1. **`.crumb` and the Crumb Protocol (RFC-0001).** Agent coordination metadata: files in directories that tell agents who is working where. Spec: `aien-dev/crumb-spec`, `SPEC.md` (RFC-0001 v1.0.0), pinned at commit `10b8251`, repository archived read-only; the in-repo pointer is `docs/CRUMB_PROTOCOL.md` (lines 1 to 20) and the tool is `tools/crumb/` (`docs/CRUMB_PROTOCOL.md`, "Where the spec lives" table). It is unchanged by this decision.
2. **Crumbline.** The learning and verification curriculum. Its Rust side is `aien-sovereign-core/crates/crumbs` (`docs/CRUMB_PROTOCOL.md`, section "Not the same thing as Crumbline"); its Omega side is `src/crumbline/` in omega (`cl_program.c`, `cl_search.c`, per `docs/plans/arena-x/ARENA_X_DISCOVERY_AUDIT.md:44`). It is unchanged by this decision, except that it becomes the first migrated subsystem (Decision 11).
3. **Verified Crumb (VC).** New. A content-addressed, receipt-bound library object that other programs may depend on. Defined by this ADR.

The two existing meanings share a word and nothing else (`docs/CRUMB_PROTOCOL.md`, "Not the same thing as Crumbline"). The Verified Crumb is a third term and is always written in full, "Verified Crumb" or "VC", never "crumb" alone.

### Current facts in omega (from the plan; omega `origin/main` `6fbf316`, re-read for this ADR at the same head)

4. **`omega_library` is already fail-closed in three ways.** `omega_library_insert` refuses a program that is not verified or not realized (`src/omega_library.c:166-169`), refuses a duplicate semantic id (`:182-185`) and refuses a dependency cycle (`:187-192`, using `omega_library_has_cycle` at `:141`). It also refuses a zero program id (`:175-180`).
5. **It has four holes.** (a) A NULL receipt hash is accepted: the receipt is copied only `if (receipt_hash)` (`:209`), so an entry can exist with an all-zero receipt field. (b) Dependencies are silently truncated at 8: `to_copy = dep_count < OMEGA_LIB_MAX_DEPS ? dep_count : OMEGA_LIB_MAX_DEPS` (`:202`, with `OMEGA_LIB_MAX_DEPS 8` at `src/omega_library.h:10`), and the call still succeeds. (c) Dependencies are never checked to exist: the cycle check walks only dependencies it can find (`:150-153`), and insert never requires each id to be present. (d) The two existing callers pass no dependencies at all and pass a receipt that may be NULL: `src/crumbline/cl_program.c:197` and `src/omega_discovery.c:299` both call `omega_library_insert(..., NULL, 0, <receipt>)`. The plan also records that no unit test for the library exists (plan, "Ground truth"; UNVERIFIED by this ADR's author beyond the plan, confidence medium, since the test tree was not searched).
6. **The OSC compiler reserves `import` and implements nothing.** `import` is in the reserved-word list at `src/compiler/osc_lex.c:24`. The plan records that no import handling exists (the author re-read only the lexer line, so "implements nothing" is the plan's claim; confidence medium-high).
7. **aien-proof already has canonical receipts.** `EvidenceReceiptV1` in `aien-sovereign-core/crates/aien-proof/src/evidence.rs:1-12` has an id equal to the BLAKE3 hash of an explicit canonical byte encoding with fixed field order, length-prefixed strings and big-endian integers. ARCH-0028 Context item 2 records that omega and physics write different receipt dialects (sha256 over sorted JSON), so three receipt formats exist today. ARCH-0028 Decision 4 adds `aien-test's own receipt: canonical JSON hashed with SHA-256, schema `aien-test/EvidenceReceiptV1`, and its naming note defers reconciling it with aien-proof to Open Question 1 (`docs/adr/0028-aien-test-runner-and-evidence-contract.md`, Decision 4, lines 158-160). The aien-proof id is BLAKE3 under the domain string `AIEN_EVIDENCE_RECEIPT_V1` (`crates/aien-proof/src/evidence.rs:22`).

### Framing

This is a convergence of mechanisms that already exist: Omega's verified library (identity, verification gate, duplicate and cycle refusal), aien-proof's canonical receipt, and the compiler's reserved `import`. It is not a new subsystem. The work is to close the four holes, give the three pieces one wire contract, and make the compiler consult the library.

## Decision

### 1. The VerifiedCrumbV1 object

A Verified Crumb is one immutable record with these fields. The byte-level encoding (field order, length prefixes, integer widths, hash function) is NOT decided here; it is owned by `aien-protocols` `specs/verified-crumb/` (in flight) and must follow the same canonical-bytes discipline as `EvidenceReceiptV1` (Context item 7).

| Field | Meaning |
|---|---|
| `format` | The literal format tag and version, `VerifiedCrumbV1`. |
| `semantic_id` | Omega's program identity (`OmegaProgram.program_id`, the id bound to the canonical body and contract, `src/omega_library.c:175-180` refuses a zero id). This is the only name by which the object is addressed. |
| `body_digest` | Digest of the canonical program body, so the store can check what it holds against the id. |
| `dependencies` | An ordered list of `semantic_id` values. Never names, never versions, never ranges. No length cap below the library capacity; truncation is an error, not a behavior. |
| `receipt_id` | The id of the passing evidence receipt that establishes admissibility (Decision 2). Required, never zero. |
| `verifier_profile` | The named profile under which the receipt was produced (which qualification, which verifier, which pins). An unknown profile is a refusal. |
| `name` | Human-readable metadata. Never authority, never used in resolution. |

### 2. Identity and admissibility are two different facts

`semantic_id` is Omega's identity for the program. The receipt establishes admissibility: it is the evidence that this exact `semantic_id` passed qualification under this `verifier_profile`. Identity without a receipt is not admissible. A receipt without a matching `semantic_id` is not admissible. The receipt must bind the `semantic_id` inside its own canonical bytes, so the pair cannot be swapped.

### 3. Resolution

Resolution is one chain, and every link must hold:

```text
lockfile -> semantic id -> store -> receipt -> transitive closure
```

1. The lockfile maps each import to a `semantic_id`. It contains nothing else that resolves.
2. The store returns the object for that `semantic_id`, and its `body_digest` must match.
3. The receipt named by `receipt_id` must exist, verify under its `verifier_profile`, and bind that `semantic_id`.
4. Steps 2 and 3 repeat for every dependency, transitively, until the closure is complete. The whole closure is part of the build identity.

If any link fails, resolution REFUSES. The compiler does not continue with a partial closure.

Prohibited, with no exception:

- No fallback to a local path.
- No "latest", no version range, no name lookup.
- No network result becomes executable. A fetched byte string is data until it has passed the full chain from a store entry that was admitted through Decision 5.

### 4. No escape hatch in the verified compiler

The verified compiler has no `unsafe import`, no `--skip-verify`, and no environment variable that relaxes resolution. Flags and environment cannot change what is legal; only the closure can. A feature that would let a caller weaken the chain is a defect to be removed, not a mode to be documented.

### 5. Two domains and a one-way boundary

| Domain | What it does | What it can never do |
|---|---|---|
| `omega-dev` | Compiles unverified code for experiments. Its output is marked TAINTED. | Enter the store. Satisfy a verified import. Produce a sealed artifact. |
| `omega-build` | Compiles from a verified closure only. | Read anything outside the closure. |

The boundary is one-way and has exactly one door:

```text
unverified code
      |
      v
qualification (aien-test, ARCH-0028)
      |
      v
PASS
      |
      v
receipt
      |
      v
Verified Crumb
      |
      v
store
      |
      v
legal import (omega-build)
```

There is no arrow from unverified code, from `omega-dev` output, or from the network into the store. The store accepts an object only together with the receipt that qualifies it.

### 6. One receipt wire contract (amends ARCH-0028 Decision 4)

Two receipt formats are in force on the path this ADR needs, and they differ in both encoding and hash: `aien-test` receipts are canonical JSON with a SHA-256 digest (ARCH-0028 Decision 4, "Hash rule"), while `aien-proof` receipts are a binary canonical encoding with a BLAKE3 id under the domain `AIEN_EVIDENCE_RECEIPT_V1` (Context item 7). A dependency resolver cannot trust two receipt dialects.

This ADR therefore decides that ONE receipt wire contract is extracted into `aien-protocols` and read by three consumers: `aien-proof`, Omega and CI. The contract carries golden vectors and a C and shell conformance checker, so the three consumers prove they read the same bytes identically without sharing code. **This AMENDS ARCH-0028 Decision 4**: the `aien-test` receipt format is not frozen as ARCH-0028 wrote it, and ARCH-0028 Open Question 1 (reconciling the two) is answered by this decision. The amendment is staged: nothing in ARCH-0028 changes until the contract lands in `aien-protocols`, and the exact receipt shape, hash function and the migration of `aien-test` onto it are fixed by that specification (in flight), not here.

**Binding in the meantime.** Until the contract lands, the Verified Crumb `receipt_id` binds to the **aien-proof id** (BLAKE3 over the binary canonical encoding, domain `AIEN_EVIDENCE_RECEIPT_V1`). An `aien-test` SHA-256 JSON receipt is not a legal `receipt_id` for a Verified Crumb until the contract admits it. Existing receipts are not rewritten (ARCH-0021 decision 3 stands).

### 7. Library hardening (the four holes)

Omega's `omega_library_insert` is changed so that: a NULL or all-zero receipt is refused; dependencies beyond capacity are refused, never truncated; every dependency id must already exist in the library; and the two bootstrap callers (`cl_program.c:197`, `omega_discovery.c:299`) stop using the ordinary insert. A separate, explicitly named bootstrap insert exists only for the Genesis Set (Decision 8) and is not reachable from user code. A unit test with mutants (one per hole) lands in the same stage.

### 8. Genesis Set VC-GENESIS-1

Something must be trusted without a prior receipt, or the chain has no start. That something is the Genesis Set, `VC-GENESIS-1`: a small, enumerated list of semantic ids, inserted by the bootstrap insert, and audited by hand. Its size is part of the trusted computing base, so it is kept small on purpose and every change to it is an ADR-level change, not a routine commit. Growing the set is how a hole would be re-opened, so the set has no wildcard and no "and everything under".

### 9. CI bridge for the present Rust and C stack: `aien verify-closure`

Omega's compiler does not yet compile the Rust and C stack that ships today, so a checker covers the gap. `aien verify-closure` lives in aien-sovereign-core, has its own workflow, and stays off `tools/aien-test` (ARCH-0028 Decision 1), so qualification and closure checking cannot hide each other's failures. It reads the dependency graph the present stack declares and refuses with one of nine codes:

| # | Code | Refuses when |
|---|---|---|
| 1 | `UNVERIFIED_DEPENDENCY` | a dependency has no admissible receipt (named in the plan) |
| 2 | `MISSING_DEPENDENCY` | a dependency's semantic id is absent from the lock or store |
| 3 | `MISSING_RECEIPT` | the object has no receipt id, or the receipt is absent |
| 4 | `RECEIPT_MISMATCH` | the receipt does not bind this semantic id |
| 5 | `STORE_DIGEST_MISMATCH` | the stored body does not match the id |
| 6 | `DEPENDENCY_CYCLE` | the closure contains a cycle |
| 7 | `NAME_OR_VERSION_DEPENDENCY` | a dependency is expressed as a name, version or range |
| 8 | `NOT_IN_GENESIS_SET` | an unreceipted object is not a member of VC-GENESIS-1 |
| 9 | `UNKNOWN_VERIFIER_PROFILE` | the receipt names a profile the verifier does not know (named in the plan) |

Only codes 1 and 9 are named in the plan, which elides the rest with an ellipsis. Codes 2 to 8 are this ADR's own naming and are marked as proposed names; the stage 5 specification may rename them but may not remove a refusal class or add an override.

### 10. Six mergeable stages

Each stage is one pull request that merges on its own and leaves main working (plan, "Stages"):

1. **Format** (`aien-protocols`): VerifiedCrumbV1 canonical encoding, receipt binding aligned with aien-proof, golden vectors, conformance checker. In flight.
2. **Library hardening** (omega): Decision 7, with the unit test and mutants.
3. **Store** (omega): content-addressed, immutable, keyed by semantic id; a name index may exist but is never authority.
4. **Resolve** (omega): `import` resolves per Decision 3, closure in the build identity, `omega-dev` and `omega-build` per Decision 5.
5. **CI bridge** (aien-sovereign-core): `aien verify-closure`, Decision 9.
6. **Genesis and first migration** (omega): VC-GENESIS-1 and the Crumbline migration.

Stages 3 and 4 follow stages 1 and 2; stage 5 follows stage 1 and a read-only scout of the aien-proof receipt contract and CI layout; stage 6 follows stage 4 (plan, "Stages").

### 11. Crumbline is the first migrated subsystem

Crumbline is the first subsystem moved onto the Verified Crumb path: it is the existing caller that inserts into the library with no dependencies (Context item 5d), and the Omega Crumbline migration is already recorded as owed by OSC-2 (`CURRENT_EXECUTION_PLAN.md`, Omega Systems Core compiler slice paragraph). Migration means its programs enter the store through Decision 5 with receipts, and its library inserts stop using the ordinary insert.

## Consequences

- **A program that depends on something unverified cannot compile in `omega-build`.** There is no override to ask for. The question "may this agent use a local copy" has the answer "it cannot be built into a sealed artifact".
- **The policy sentence "agents must use verified crumbs" is deleted, not enforced.** An invalid program cannot compile, so there is nothing for an agent to comply with. No instruction file, brief or review checklist should restate it.
- **What agents can no longer do in the verified path:** import by path, name, version or "latest"; fetch code and run it; skip verification by flag or environment variable; insert into the store without a passing receipt; give an unreceipted entry to the library outside the Genesis Set; mark `omega-dev` output as admissible.
- **What agents can still do:** experiment freely in `omega-dev`, whose output stays tainted; write tests and get receipts through `aien-test`; propose Genesis Set changes by ADR.
- **Cost.** Every shared piece needs a passing receipt before anything can use it. Experiments cost one extra qualification step before they can be depended on. This is the intended cost.
- **The trusted computing base is named and small.** It is the compiler's resolver, the receipt verifier, the store's digest check and VC-GENESIS-1. Review effort goes there.
- **The receipt formats converge on one contract**, which amends ARCH-0028 Decision 4, with golden vectors that catch drift. Until it lands, Verified Crumbs bind to the aien-proof id.
- **Until stages 2 to 4 merge, none of this is enforced.** Today a NULL receipt is accepted, dependencies are truncated, and `import` does nothing (Context items 5 and 6). This ADR is a decision, not an implementation, and no status document may report the Verified Crumb path as implemented before its receipts exist.

## Open questions (recorded, not decided here)

1. The byte layout of VerifiedCrumbV1 and the hash function: owned by `aien-protocols` `specs/verified-crumb/` (in flight). The field set in Decision 1 is this ADR's; if the specification needs a field changed it amends this ADR.
2. The exact members of VC-GENESIS-1: decided in stage 6 with a manual audit, by ADR.
3. Whether the store lives on the Omega resident semantic store (ARCH-0015) or beside it: decided in stage 3.
4. Names 2 to 8 of the refusal codes (Decision 9): provisional until stage 5.
5. How `aien-test` moves onto the single receipt contract (ARCH-0028 Decision 4 amendment): decided with the contract in `aien-protocols`.
6. How `aien verify-closure` reads the present Rust and C dependency graph (Cargo lockfile, Makefiles): the stage 5 scout's output decides; UNVERIFIED here.

## Not decided here

- Any change to RFC-0001 (`.crumb`) or to the Crumbline curriculum itself.
- Rewriting existing receipts or evidence directories.
- The Omega-native replacement of `aien verify-closure` (follows ARCH-0024's migration rule, later).
