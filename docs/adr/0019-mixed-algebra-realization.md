# ADR 0019: Mixed-Algebra Realization

**Status:** Accepted by operator Drake Stapleton, 2026-09-29.
**Gate:** `MA-0` satisfied when this ADR is accepted by the operator and merged to `main`.
**Supersedes:** nothing. **Amends:** nothing (section 9.1 is amended by this ADR's own Amendment 1, PROPOSED). **Extends:** ARCH-0018 (substrate-neutral physical realization) with the algebraic axis that ARCH-0018 left open.
**Related:** ARCH-0002 (hardware-neutral Machine identities), ARCH-0013 / ARCH-0014 (FORGE realizes, AEGIS verifies), ARCH-0015 (Resident Semantic Store), ARCH-0016 (resident reaction architecture, R0 to R16), ARCH-0017 (ARGUS), ARCH-0018 (substrate-neutral physical realization).
**Workstream:** MA-0 to MA-8 (section 10); supporting documents in [`docs/plans/mixed-algebra/`](../plans/mixed-algebra/) (NOT A MASTER PLAN). Sequencing stays in `CURRENT_EXECUTION_PLAN.md`.

**Amendment 1 (PROPOSED, 2026-09-29):** section 9.1 selection rule. The lowest measured cost wins; a tie is recorded and never changes the choice; the incumbent / digital-reference tie rule is retired and kept as negative evidence (it failed the pre-registered TURING Wave 1 kill test, omega `docs/turing/TURING_W0_PROPOSAL.md` K.6 / K.7); any incumbent or hysteresis policy must be pre-registered and beat minimum-cost selection first; selection records are `turing.decision.v1`. This amendment awaits acceptance by operator Drake Stapleton. The **Accepted** status above stands for the rest of this ADR; section 9.1 below carries the amended wording, and this change merges only once the operator accepts it.

Citation note: in this repository "ADR 0019" and ARCH-0019 name the same decision. In other repositories cite it as ARCH-0019.

---

## 1. Context

ARCH-0018 settled who owns what when a computation is realized on different physical substrates: Omega owns meaning and the SemanticResultContract, FORGE owns realization and calibration, AEGIS owns admissibility, and a substrate is a capability provider. It did not say what happens when the **number system** changes rather than the device.

The same operation can be computed in binary two's complement, in balanced ternary on two bitplanes, in five-trits-per-byte packing, in a residue number system, over a sparse index list, in BF16 or FP8, or as a phase on a physical carrier. Some of these compute exactly the same function; some compute a different function that is close; and one (Z3) is often mistaken for balanced ternary while meaning something else. Without a decision, three failure modes are open:

1. a lossy format change is presented as "the same operation, faster";
2. a speed claim omits the cost of converting into and out of the faster representation;
3. an encoding detail (a trit, a residue, a spare bit pattern) leaks into semantic identity, so the same meaning gets two ids.

The theory for this program is in [`MIXED_ALGEBRA_THEORY.md`](../plans/mixed-algebra/MIXED_ALGEBRA_THEORY.md); the audited code state is in [`MIXED_ALGEBRA_CURRENT_STATE.md`](../plans/mixed-algebra/MIXED_ALGEBRA_CURRENT_STATE.md). This ADR answers the questions listed in that document's section 16, and does not re-decide anything listed in its section 15.

## 2. Decision summary

```text
OMEGA MEANING IS A MATHEMATICAL FUNCTION OVER DECLARED DOMAINS.
AN ENCODING IS A REALIZATION DETAIL, NEVER PART OF MEANING.
AN EXACT REALIZATION KEEPS THE SEMANTIC IDENTITY.
AN APPROXIMATE TRANSFORM CREATES A NEW SEMANTIC OBJECT.
CONVERSION IS COMPUTATION, AND ITS COST IS PART OF EVERY SPEED CLAIM.
Z3 IS NOT BALANCED TERNARY.
THE BITPLANE (1,1) STATE IS A FAULT, NEVER A VALUE.
SELECTION IS BY MEASURED COST AMONG ELIGIBLE REALIZATIONS, WITH THE MARGIN RECORDED.
A NEGATIVE RESULT IS EVIDENCE.
```

Everything in ARCH-0018 section 2 continues to hold unchanged. This ADR adds rules; it removes none.

## 3. Algebraic domains (D1)

### 3.1 Definition

An **algebraic domain** is the tuple `(carrier set, operations, identities, error contract)` defined in theory section 1.1. Two domains are the same only if all four agree: the same bits with a different contract (for example wrapping versus trapping 32-bit integers) are different domains.

### 3.2 Where a domain lives

- **Semantic side.** An Omega operation's meaning is the mathematical function over its declared input and output domains. The input and output domains, and the error contract, are part of the operation's semantic identity through the SemanticResultContract that ARCH-0018 section 3.1 already makes Omega-owned.
- **Realization side.** A realization is a triple `(enc, g, dec)` in the sense of theory section 1.2: an encoding into machine states, machine operations on those states, and a decoding back. Binary, balanced-ternary digits, bitplanes, trytes, RNS residues, sparse index lists, BF16, FP8, NVFP4 and phase are encodings, or internal algebraic domains a realization computes in.
- **Both.** A domain such as Z3 or Z_m may appear on the semantic side when the operation's meaning is itself modular (section 5), and on the realization side when a realization computes an integer result through modular arithmetic (for example RNS followed by CRT reconstruction). The distinction is where it is declared: in the contract it is meaning; inside a realization record it is mechanism.

The admissible realizations of an operation are those whose declared behaviour on the declared input domain satisfies the contract. The algebraic domain a realization uses is therefore a **declared property of the realization**, checked against the contract, and never a field of the program body.

### 3.3 Consequence for identity

A program's semantic identity does not change when a new encoding for it appears. What enters a `realization_id` is realization-side: encoding, storage format, packing, accumulator width, accumulation order where it affects bits, and the substrate and calibration digests ARCH-0018 section 4 already binds.

## 4. Trit is a realization type (D2)

In this program a trit is a **realization and encoding type**, not a semantic type. A balanced-ternary integer of `n` trits is a bounded integer in `[-(3^n-1)/2, (3^n-1)/2]` (theory section 1.3); its meaning is the integer, and its overflow policy (FAIL_CLOSED, SATURATE or WRAP, already on main at `src/omega_types.h:81-86`) is part of the contract.

The parked branch `experiment/ternary-semantics` (`ae1e2a3`) explored ternary as semantics through an OMG1 canonical encoding whose ids differ from OMG0 ids for the same value (current state section 12 and conflict 5). That branch **stays parked**. Its data components (plane encoding, tryte packing, A64 kernels) are reusable as realizations after rebase; its OMG1 identity is not adopted. Making ternary a semantic type later would be an **identity break** that splits one meaning into two ids, and requires its own ADR and operator decision.

## 5. Z3 is a separate domain (D3)

Z3 = GF(3), carrier `{0,1,2}`, arithmetic mod 3. The bijection `phi: {0,1,2} -> {0,1,-1}` is an isomorphism of multiplicative monoids and a ring isomorphism onto `{-1,0,1}` **with arithmetic mod 3**, but it is **not** a ring isomorphism onto bounded signed integers: `1 + 1 = 2 = -1` in Z3 but `2` in Z (theory section 5.1, enumerated).

Rules:

- An operation may declare Z3 as its domain **only when its meaning is modular**: GF(3) codes and syndromes, mod-3 checksums, GF(3) polynomial arithmetic. Anything that compares, thresholds, rescales or counts is integer (theory section 5.3).
- A Z3 operation may be exactly realized by integer arithmetic followed by reduction mod 3, provided the integer stage cannot overflow. The converse is never admissible: a Z3 result does not determine an integer result.
- Bitplane trits may realize either domain: the half-adder sum with carry discarded is Z3 addition; the same planes with carry are integer addition. The domain comes from the contract, not the encoding.

## 6. Exact realization versus approximate transform (D4)

### 6.1 Exact realization

A realization is **exact** for operation `S` on declared domain `D` when `dec(g(enc(x))) = S(x)` for every `x` in `D`, or the contract's flag is raised, and this is supported by evidence at the tier section 8 requires. An exact realization **is** `S` on `D`. It keeps the semantic identity.

### 6.2 Approximate transform

An **approximate transform** produces a new operation `S'` whose results differ from `S` by more than `S`'s own contract admits. Examples: float to ternary absmean quantization (implemented as a reference in the omega worktree, `src/algebra/oma_quant.{h,c}`, spec `spec/mixed-algebra-reference.md` "Exact vs approximate"), float to FP8 or NVFP4 weight conversion, pruning, and any lossy format change applied to an operation whose contract is `EXACT` or whose declared bound it would exceed.

An approximate transform creates a **new semantic object** with:

- its own semantic identity, never equal to the source id;
- a provenance link: source operation id, transform id, transform parameters (for example the quantization scale and the ternary weights), and the source contract digest;
- a declared error bound and the metric it is measured in (for absmean, relative L2 `||w - q*scale|| / ||w||`, or an output-space operator bound per theory section 8.1);
- the evidence for that bound, at tier E1 or higher (section 8).

Quantization scales and weight tables are **transform parameters of the new object**, not calibration records. ARCH-0018 calibration stays what it is: FORGE-produced, per substrate instance.

### 6.3 Fit with ARCH-0018 bounded contracts

ARCH-0018 section 3 already allows a realization whose declared error model sits inside a `BOUNDED_DETERMINISTIC`, `BOUNDED_STOCHASTIC` or `MEASURED_DISTRIBUTION` contract to realize the operation. That is unchanged. The line this ADR draws is: **a format change that stays inside the source contract is a realization; one that needs a weaker or different contract is a transform.** Promotion of a transformed object into use follows the existing generation barrier (`src/runtime/rx_generation.h`); it never replaces the source id.

## 7. Conversions and the fourth code

### 7.1 Conversions are realization steps (D5)

Encoding, decoding, packing, unpacking, CRT reconstruction, format conversion and overflow detection are **realization steps** owned by the realization that needs them: a FORGE provider, or an Omega CPU realization. They carry measured cost (bytes moved, time, energy) in the realization's evidence. Round-trip correctness of a conversion is part of the realization's equivalence evidence (section 8).

A speed or energy claim for a realization **includes conversion cost wherever production would pay it**. A claim that assumes pre-converted inputs must say so and must name who pays the conversion and how often (once per model load, per call, per element).

### 7.2 The bitplane (1,1) state is forbidden (D6)

In the two-plane trit encoding, `(P,N) = (1,1)` is **FORBIDDEN**: a validation fault, never a value, in every arithmetic domain. Reasons, from theory section 3.6 (all enumerated):

- read as a redundant zero it silently corrupts addition: `(1,1) + (+1)` yields value 2;
- read as poison it is erased by multiplication by zero and vanishes in popcount reductions, so it would promise detection it cannot deliver;
- read as Belnap "both" it changes the meaning of `(0,0)` and is a different semantic domain.

Validation runs where data enters the encoding (load, unpack, external input, deserialization). The omega reference already enforces this: every decoder, validator and operation returns `OMA_E_INVALID_PLANES` or `OMA_E_INVALID_CODE` for `(1,1)` (`src/algebra/oma_trit.h:5-22`), with 380,256 rejection checks in the reference suite. The parked branch's `omega_t_from_planes` decodes `(1,1)` as 0 without checking; that behaviour is not adopted. A four-valued logic domain may exist later only under its own domain tag and its own ADR.

## 8. Equivalence evidence tiers (D7)

This ADR adopts the evidence levels of theory section 8.2:

| Level | Name | Meaning |
|---|---|---|
| E4 | proof | derivation or checked proof that `dec . g . enc = S` on `D` |
| E3 | exhaustive | every `x` in `D` tested |
| E2 | differential with declared coverage | reference versus candidate on a generated suite with stated coverage (boundaries, extremes, overflow edges, every fault path) |
| E1 | statistical with bound | `N` independent inputs, zero failures, failure probability `p <= -ln(a)/N` at confidence `1 - a` |
| E0 | none | not admissible |

- An **exact** realization needs E2, E3 or E4 on the declared domain. Its per-element core (trit ops, packing codes) should reach E3 or E4; the composed kernel may rest on E2.
- A **bounded** realization or an **approximate transform** needs at least E1 against its declared bound.
- The ARCH-0018 contract kinds carry the bound; the evidence record carries the tier, the coverage statement and the sample count. A realization whose tier is below its contract's requirement is ineligible.

## 9. Selection, advertisement and negative results

### 9.1 Selection by measured cost (D8)

Among realizations **eligible under the contract**, meaning the ARCH-0018 eligible set including its digital fallback rule (ARCH-0018 section 14 Q7), Omega selects by **measured cost**: bytes moved, latency, energy, conversion, verification, calibration and link cost. **The lowest measured cost wins:** Omega selects the eligible realization with the lowest measured expected cost for the workload footprint (the lowest running mean of per-call cost, conversion included), and on exact equality the lowest stable realization index. Every selection records the decision, the runner-up, the margin and the noise band used. The **tied set** is every eligible realization whose measured cost is within the noise band of the cheapest; it is recorded with the decision. **A tie is recorded and never changes the choice:** there is no incumbent or reference preference inside the noise band. Selection records use the `turing.decision.v1` record format (omega `src/turing`, `turing_rank_min_cost`); no second decision-record format is introduced. (Retired rule, kept as negative evidence: the earlier rule resolved a tie by incumbent, then digital reference, then cheapest. It failed the pre-registered TURING Wave 1 kill test on the MA-2 benchmark receipts, the files `evidence/MIXED_ALGEBRA/ma3_bench_run1.json` (sha256 `f21d08cdbd20cd017f5139d53d9acbe2d8399543bd06745b4608673a2d6b5b1c`) and `ma3_bench_run2.json` (sha256 `1323e18a340782d19393e4aded19b2cfe4e7bfa74b3c1aa0fea03d3aeb374aa9`), whose file names carry the earlier "MA-3" work label and are not stage MA-3 of section 10: 3.58% mean and 25.51% max regret against 0.01% mean and 0.07% max for minimum-cost selection, in sample, over 8 decisions; omega `docs/turing/TURING_W0_PROPOSAL.md` K.4, K.6, K.7, merged in omega `dbfb474` (PR #79). The omega `oma_select` selector that implements it is kept unchanged only to reproduce `ma2_select_receipt.json`.) Any policy that keeps an incumbent to avoid switching, or adds hysteresis, must be pre-registered and must beat minimum-cost selection on pre-registered data before it is used. An algebra classifier (theory section 8.3), when it exists, **proposes** candidate realizations and rejected candidates with reasons; it never picks.

### 9.2 Advertising algebraic domains (D9)

A Machine advertises the algebraic domains its substrates realize by **extending the FORGE V2 representation descriptor** (`physics:forge/v2/forge_substrate_v2.h:114-118`) with sub-formats: integer widths, BF16 / FP8 / NVFP4, balanced-ternary packing (planes, trytes), Z3, RNS moduli, and `phase.z3`. Each entry carries precision, noise and calibration epoch as ARCH-0018 sections 3.3 and 4 require. The extension uses the V2 reserved-range rules; it does not reserialize v1 or change existing V2 digests. Calibration remains FORGE-owned.

An external analog or FPGA device that joins with its own identity appears as a Machine (for example Fabric "Machine 2") under ARCH-0002; there is no special case for it. A device attached inside an existing Machine is a substrate record of that Machine, as in ARCH-0018.

### 9.3 Negative results and stop conditions (D10)

A realization that loses is **first-class evidence**, recorded with a receipt like any pass. Work on a realization or algebra stops, with a receipt, when measurement shows it is: slower end to end; higher in energy; higher in memory; outside its accuracy bound; drifting beyond its calibration envelope; dominated by conversion cost; creating lock-in to one substrate or vendor; unverifiable at the tier its contract needs; or dependent on calibration that cannot be kept reliable. A stopped realization may be reopened only with new evidence.

## 10. Workstream gates MA-0 to MA-8

These are **workstream gates, not roadmap milestones**; they carry no M-number. Sequencing belongs in `CURRENT_EXECUTION_PLAN.md`.

| Gate | Definition |
|---|---|
| MA-0 | This ADR accepted and merged. |
| MA-1 | CPU reference oracle for trits, bitplanes, trytes, Z3 and absmean, exact and sanitizer-clean. (Exists on the omega worktree commit `6d517a4`, not on `main`.) |
| MA-2 | Several CPU realizations of one operation (binary int8, bitplane, dense tryte, sparse, RNS) with tiered equivalence evidence and measured cost including conversion. |
| MA-3 | Contract and identity: domain and per-domain error units (LSB, ULP with declared format) in the SemanticResultContract; approximate-transform provenance record. |
| MA-4 | FORGE V2 representation sub-format extension with KATs. |
| MA-5 | Empirical cost model widened: more than one op, realization and algebra axis, error field, conversion cost; selection record with margin and noise band. |
| MA-6 | GPU realizations under the same contracts (INT8, FP8, FP4, ternary SASS). |
| MA-7 | Algebra classifier proposing candidates. |
| MA-8 | Physical phase or external-Machine realization, aligned with ARCH-0018 AR4 / AR6. |

**First success gate:** one Omega operation, at least three verified realizations, one selected with a recorded reason and margin, reproducible from receipts. This can be met test-side, in the pattern of `tests/runtime/rx_empirical_optimizer.c`, without runtime edits. **Next gate:** a digital realization and a physical phase realization of the same operation within the same contract.

## 11. What this ADR does NOT decide

- It makes **no performance claim** for any algebra. Theory section 9 marks every performance row as PREDICTION or CONJECTURE.
- It changes no Omega runtime code, no FORGE type, no canonical encoding, and no program identity. OMG0 stays canonical.
- It does not lift the R16 runtime-edit freeze. `CURRENT_EXECUTION_PLAN.md:45,540` still records R16 in progress while `doctrine/ROADMAP.md:282` records it PASS; the lift must be recorded in `CURRENT_EXECUTION_PLAN.md` before any `rx_*` change in MA-3 or MA-5.
- It does not choose wire encodings for the sub-format extension (MA-4 deliverable) or decide sparse as domain versus layout (default: sparse is a realization layout unless an operation's meaning depends on the zero pattern).
- It does not buy or select a physical device.

## 12. Consequences and known gaps

- Program identity v2 is scalar-only (`src/omega_program.h:41-53`): it cannot name matvec, matmul, tensor, float or residue operations, which today carry separate spec ids. MA-3 needs an operation identity that can.
- `rx_contract` is exact-only (`src/runtime/rx_contract.h:61-99`); ARCH-0018 bounded kinds and this ADR's per-domain error units are not yet expressible there.
- Verification V2 ignores the realization (`src/omega_verify.c:175`, `(void)real;`); V3 to V5 are stubs. Section 8 tiers are recorded in evidence, not yet enforced by code.
- The empirical cost model is CPU matvec only (`RX_CM_OPS 1u`), and widening it changes the serialized digest of promoted models (current state conflict 7).
- FORGE v1 cannot execute kernels: its lowering copies bytes and submit releases a semaphore (`physics:forge/forge_realize.c:66-80`).
- Three machine-identity shapes are unreconciled: `CqCandidate.machine_id` u32, FORGE V2 32-byte identity, OS-0010 opaque `MachineId`.
- Omega's own SASS path has no INT8, FP8 or FP4 encoders; ternary on GPU is static cost counting only.
- FORGE V2's digital fallback counts only `DIGITAL_CPU` and `DIGITAL_GPU` classes, so an exact FPGA realization does not yet qualify as fallback (current state conflict 10). Resolving that is a FORGE V2 change, not decided here.
- Every mixed-algebra speed claim will carry conversion and verification cost. Some realizations that look fast in isolation will lose. That is intended.
