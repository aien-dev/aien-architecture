# ADR 0034: Physical-Form Realization IR

**Status:** PROPOSED, 2026-10-04. Not accepted. Becomes ACCEPTED only by operator decision recorded on this file; merging the PR that adds it does not accept it.
**Supersedes:** nothing. **Amends:** nothing. **Extends:** ARCH-0018 (substrate-neutral physical realization) with the realization-side intermediate it left implicit, and ARCH-0019 (mixed-algebra realization) by placing the declared algebraic domain of a realization in a named artifact.
**Related:** ARCH-0013 / ARCH-0014 (FORGE realizes, AEGIS verifies), ARCH-0016 (resident reaction architecture; dependency structure, not turn order), ARCH-0020 (belief / estimation), ARCH-0033 (verification pipeline, PROPOSED).
**Workstream:** FORM0 (this cut), FORM1 to FORM4 (section 11). These are workstream gates, not roadmap milestones; sequencing stays in `CURRENT_EXECUTION_PLAN.md` section 6 C3. NOT A MASTER PLAN.

Citation note: in this repository "ADR 0034" and ARCH-0034 name the same decision.

---

## 1. Context

AIEN's direction is that software specifies and verifies, and, where the contract permits, physics computes. ARCH-0018 fixed who owns what: Omega owns semantic meaning and the SemanticResultContract, FORGE owns physical realization and calibration, AEGIS verifies admissibility, AIEN proposes objectives and gains no hardware authority, AIENOS owns enforceable capabilities. ARCH-0019 added that an encoding or algebraic domain is a realization detail, never part of meaning.

Audit of `main` on 2026-10-04 (omega `cb7cc21`, physics `d74d799`, aien-architecture `35dd324`, aienos `25836ba`) shows the realization chain has a gap between the contract and the substrate:

- `physics` FORGE V2 (`forge/v2/forge_substrate_v2.h`) describes substrates, contracts, calibration and evidence, and composes realization identity from contract, Machine identity, substrate digest, a **code digest** and calibration. The code digest is an opaque label today.
- The AR2 simulated analog provider (`physics` `forge/analog-sim/`, merged `d52759d`, PR #21, 52 checks, receipt `evidence/AR2/808e79f8…b073.json`, every record `SIMULATED_DEVELOPMENT`) realizes MATVEC against the omega oracles under all four V2 error kinds. It is wired directly from contract to its own substrate: there is no object that says *which mathematical structure* is being embodied, so a second substrate (photonic mesh, resistive array, GPU) would have to repeat the mapping privately.
- Omega's own realization object (`src/omega_realize.h` `RealizationObject`) is AArch64 code bytes; the action graph's `AG_REAL_HARDWARE` kind is a placeholder ("none exists on this host", `src/runtime/rx_graph.h`).

The missing object is a **substrate-neutral realization form**: the mathematical structure a physical system can embody, independent of which substrate embodies it. It is the thing that lets the same semantic operation be realized by a digital solver, a linear physical operator, an energy landscape or a physical sampler without renaming the operation and without a per-substrate opcode.

## 2. Decision

```text
A REALIZATION FORM IS A REALIZATION-SIDE ARTIFACT, NOT A SEMANTIC OBJECT.
IT IS NOT A NEW LAYER: IT SITS BELOW OMEGA MEANING AND BESIDE SUBSTRATE LOWERING, INSIDE FORGE.
ITS IDENTITY NEVER ENTERS SEMANTIC IDENTITY.
ITS IDENTITY ENTERS REALIZATION IDENTITY AND EVIDENCE.
A FORM CARRIES NO SUBSTRATE, VENDOR, DEVICE, BUS, CALIBRATION, ADDRESS, CLOCK OR TEMPERATURE FIELD.
ONE CONTRACT MAY MAP TO SEVERAL FORMS; ONE FORM MAY LOWER TO SEVERAL SUBSTRATES.
EVERY FORM KIND NEEDS: PRECISE MATHEMATICS, A CONTRACT MAPPING, A VERIFICATION STRATEGY,
  A DIGITAL REFERENCE REALIZATION, AND A PLAUSIBLE PHYSICAL REALIZATION.
A FORM KIND THAT LACKS A REFERENCE IMPLEMENTATION IS SPECIFIED, RESERVED AND REFUSED BY CODE.
THE EXACT CONTROL PLANE STAYS EXACT.
```

### 2.1 Data flow and ownership

```text
AIEN proposes an objective                      (no hardware authority)
        |
Omega semantic operation + SemanticResultContract   OMEGA owns; semantic identity
        |
        |  forge_form_from_contract              FORGE owns from here down
        v
ForgeRealizationForm  (LINEAR_OPERATOR, ...)    form digest
        |
   +----+-----------------+
   v                      v   forge_form_lower_*  (lowering digest = H(form, code))
digital reference      simulated analog   ...  GPU | resistive array | photonic mesh
   |                      |
   v                      v   forge_form_realize: V2 eligibility, runs, oracle check
V2 evidence + record   V2 evidence + record      realization identity (V2), evidence identity
        |
AEGIS admissibility (V2 eligible-set rule: digital fallback must exist)
        |
measurement, evidence, empirical selection (unchanged owners: ARCH-0018 / ARCH-0019 section 9)
```

Nothing above the contract changes. Nothing in AIENOS changes: substrate access remains an AIENOS capability (aienos `native/capability/aienos_capability.h`, one mint/validate path; no hardware right exists yet and none is added).

### 2.2 Form kinds

| Kind | Mathematics | Contract mapping | Verification | Digital reference | Plausible physical realization | Status |
|---|---|---|---|---|---|---|
| `LINEAR_OPERATOR` (1) | y = A x over a declared scalar domain (integers mod 2^64 or mod 2^32, exact modular accumulation), A is M x N | V2 `MATVEC`, rank 2, oracle `omega_matvec_reference` (u64) or `omega_matmul_cpu_oracle_i32` (n = 1) | per-element error against the contract's oracle under EXACT / BOUNDED_DETERMINISTIC / BOUNDED_STOCHASTIC; digests for EXACT | host restatement of the omega oracle (`physics` `forge/analog-sim/` oracles, cross-checked against omega sources by the AR2 gate) | resistive / analog in-memory array, photonic mesh, GPU | IMPLEMENTED (host, FORM0) |
| `ENERGY_FUNCTIONAL` (2) | minimize E(s) = s^T J s + h^T s over s in {-1,+1}^n (or a declared bounded integer box); result contract: E(s*) <= bound, or E(s*) within delta of a reference optimizer's value with declared confidence | no existing Omega contract; needs a `solve_optimization` operation with an objective bound in the SemanticResultContract (MA-3 territory) | reference: exhaustive for n <= 20, otherwise a deterministic digital optimizer with recorded value; acceptance = contract bound, never "reached the global optimum" | NOT WRITTEN | oscillator / Ising networks, thermodynamic samplers | SPECIFIED, RESERVED, REFUSED BY DECODE |
| `STOCHASTIC_DISTRIBUTION` (3) | draw samples from a declared distribution; result is the sample set, accepted by declared statistics | needs `MEASURED_DISTRIBUTION` contract semantics, which no omega seam implements (section 5) | distributional statistics against the contract; raw samples are evidence | NOT WRITTEN | physical stochastic samplers | RESERVED, REFUSED BY DECODE |

No other kinds are reserved. The families below (from the operator's 2026-10-04 "software specifies, physics computes" material) were considered and are **not** given ids: none has an Omega contract to map from today, and a reserved id without a mapping is a promise, not a design. Each gets an id only when a contract, a digital reference and an acceptance rule exist for it.

| Considered family | Physical meaning (one line) | Why not reserved yet |
|---|---|---|
| dynamical system | a state evolves under declared dynamics; the result is the trajectory or its endpoint | no Omega contract names a trajectory or an endpoint tolerance |
| graph coupling | coupled nodes settle into a joint state; the result is the settled configuration | subsumed by `ENERGY_FUNCTIONAL` once a coupling matrix is the objective; no separate contract |
| wave / interference transform | a linear transform realized by propagation (Fourier-like, convolution-like) | a `LINEAR_OPERATOR` with a structured A; needs a structured-operator contract before it earns its own id |
| constraint manifold | the result must lie on a declared set; physics enforces the constraint | no constraint-satisfaction contract in `rx_contract` |
| attractor / associative recall | a perturbed state relaxes to the nearest stored pattern | no recall contract; "nearest" needs a declared metric and acceptance bound |


### 2.3 Wire form and identity

`physics` `forge/form/forge_form.h` (PR `aien-dev/physics#46`):

- Own magic `"FGFM"`, version 1, TLV body with the FORGE V2 discipline (ascending tags, fixed widths, every field required, little-endian), strict decoder that refuses unknown tags, wrong widths, bad order, missing fields, out-of-range values, reserved kinds, and any input whose canonical re-encoding differs. Digest = SHA-256 over header + body (`sha256_clean.c`, never duplicated).
- Form fields: `form_kind`, `scalar_domain`, `operator_rows`, `operator_cols`, `accumulation`. That is all. A gate greps the struct for substrate, vendor, device, calibration, clock, temperature, address, bus and machine words and fails if any appears.
- Frozen KAT: `LINEAR_OPERATOR`, `INT_WRAP_U64`, 8 x 8, `EXACT_MODULAR` digests to `6e1769e21b1c1df854f4832618e276f3c556a45500af62636a51e1e862cf71d8`.
- Lowering digest = SHA-256(`"FORGE-FORM-LOWER-V1"` | form digest | lowering code digest). It is passed as the `code_digest` of `forge_v2_realization_identity`. **FORGE V2 bytes, tags, enums, digests and the realization-identity formula are unchanged.**
- Realization record (kind 2): form digest, contract digest, substrate digest, lowering digest, realization identity, evidence digest, provenance, decision. It is an evidence-side binding; it is an input to no identity.

### 2.4 Identity consequences

| Field | Semantic identity | Realization identity | Evidence identity | No identity |
|---|---|---|---|---|
| form_kind, scalar_domain, rows, cols, accumulation | never | yes, via lowering digest in the V2 code slot | yes, via the record | |
| form digest | never (test: not an input of the contract digest; a bounded contract on the same operation maps to the same form) | yes | yes | |
| lowering code digest | never | yes | yes | |
| substrate digest, calibration digest | never (ARCH-0018) | yes (V2, unchanged) | yes | |
| realization record decision, provenance | never | no | yes | |
| backend enum (digital / analog-sim) in the lowering struct | never | only through the code label it selects | | otherwise none |

### 2.5 Exact control plane

Hashes, signatures, capability validation, identity, package and dependency state, transaction and commit state, evidence integrity, authority and security decisions stay on the exact digital control plane. A realization form is only ever derived from a SemanticResultContract whose kind admits it; an `EXACT` contract is realized by a form only when the lowering reproduces the oracle digest bit for bit (the analog lowering is refused under `EXACT` once any non-ideality is injected, even if the outputs match). No contract is weakened to admit a device; no cryptographic or commit operation gains a form.

### 2.6 Provenance

Every evidence record and realization record produced by the FORM0 code is `SIMULATED_DEVELOPMENT`. The digital reference running on the host CPU of a development fixture is **not** a physical measurement of a provisioned Machine and is labelled accordingly. There is no API in the form module that emits `PHYSICAL`; a gate greps for it.

## 3. What this ADR does NOT decide

- It makes **no performance or energy claim**. The analog lowering is a software model (AR2). A losing realization is still evidence (ARCH-0019 section 9.3).
- It adds **no Omega opcode**, no substrate class, no cognitive-routing bit, no cost-model axis, no scheduler, no second World, no authority path.
- It does not implement `ENERGY_FUNCTIONAL` or `STOCHASTIC_DISTRIBUTION`.
- It does not change FORGE V2 (no new V2 tag or kind), Omega program ids, `rx_contract`, `rx_costmodel` blobs, generation digests, any existing receipt, or GB10 qualification.
- It does not buy or select a device.

## 4. Audit basis (2026-10-04, from code, not prose)

**IMPLEMENTED**
- FORGE V2 reference (`physics` `forge/v2/`): objects 1 to 7, strict decode, calibration freshness, eligibility, eligible-set digital-fallback rule, realization identity with code slot, `SIMULATED_DEVELOPMENT` provenance. Gates pass (47 checks, 6 gates).
- AR2 simulated analog provider (`physics` `forge/analog-sim/`, `d52759d`): all four V2 error kinds checked against the u64 and i32 omega oracles; 52 checks; receipt committed. The execution plan's C3 table still lists AR2 as "may proceed" (STALE, corrected in the companion amendment).
- Omega capability query (`src/runtime/rx_capq.h`): `CqNeed` / `CqCandidate` carry no substrate field; `CQ_SRC_PHYSICAL` is a provider origin.
- Omega selection record `turing.decision.v1` and `turing_rank_min_cost` (`src/turing`).
- AIENOS capability authority: one mint / validate path (`native/capability/aienos_capability.h`); no hardware right yet.

**PARTIAL**
- Uncertainty kinds: `EXACT`, `BOUNDED_DETERMINISTIC`, `BOUNDED_STOCHASTIC` are implemented at the FORGE V2 / AR2 / FORM0 seam. `MEASURED_DISTRIBUTION` exists only as an enum value; AR2 and FORM0 refuse it as unsupported. In omega, `rx_contract` is integer-exact only (no error bound, tolerance, confidence or kind field; `rc_contract_identify` hashes kinds, fields, rules, world type). The M18 matmul comparator is the only tolerance path (fixed absolute). `RxCogRequirement` has `uncertainty_budget_ppm` and `precision_requirement` (APPROX / EXACT) but no bound units.
- Empirical cost model (`src/runtime/rx_costmodel.h`): `RX_CM_OPS 1` (matvec), 8 anonymous arms, core class X925 / A725 / OTHER, observation = `ps_per_call` + `failed`; `power_mw` per core and arm; serialized blob `"OGCM"` version 1 with SHA-256 trailer, strict deserialize (no migration path); no error, substrate or realization axis.
- Cognitive routing (`src/runtime/rx_route.h`): `RX_COG_HW_CPU_P / CPU_E / GPU` bitmask filters eligibility (`rx_route.c:323`) and is hashed into the registry digest (`rx_route.c:124`). This is the one hardware-named type on main (ARCH-0018 section 14 Q3). Not touched here; the eventual replacement is capability-based eligibility through `rx_capq`, not more bits.
- Omega verification V2 ignores the realization (`src/omega_verify.c` `(void)real;`).

**MERGED BUT UNUSED**
- `AG_REAL_HARDWARE` realization kind (`src/runtime/rx_graph.h`): placeholder, no provider.
- FORGE V2 `FORGE_V2_OP_SAMPLE`, `FORGE_V2_OP_TRANSFORM`, `FORGE_V2_STATE_DYNAMICAL`, substrate classes NEUROMORPHIC / FPGA_CGRA / OPTICAL: enum values with no provider.
- `CqTradeoffs.tolerance_ppm[]` / `min_confidence`: carried, not consulted by any physical seam.

**EXPERIMENTAL**
- Mixed-algebra reference (`src/algebra/oma_*`), parked ternary branch (ARCH-0019).

**PROPOSED**
- This ADR; `ENERGY_FUNCTIONAL`; `STOCHASTIC_DISTRIBUTION`; FORM1 to FORM4 (section 11).

**ABSENT**
- Any `PhysicalForm` / `realization_form` / `LINEAR_OPERATOR` / `ENERGY_FUNCTIONAL` object before PR physics#46 (grep of omega and physics: no hits).
- A matvec SemanticResultContract object in omega outside `physics` FORGE V2 (omega has `rx_contract` and `turing_contract`, neither carries V2 error kinds).
- A hardware or substrate capability right in AIENOS.
- Any physical non-digital device, calibration or measurement in the project.

**STALE DOCUMENTATION**
- `CURRENT_EXECUTION_PLAN.md` section 6 C3: AR2 shown as a precondition row, not PASS (physics #21 merged 2026-09-30). Corrected by the companion amendment in the same PR as this ADR.
- `docs/plans/analog-realization/ANALOG_REALIZATION_CURRENT_STATE.md` (written 2026-09-29): no AR2 status; `ANALOG_REALIZATION_COLLISION_MAP.md` and `ANALOG_REALIZATION_TEST_PLAN.md:91` still say omega `src/runtime/` must not be touched while R16 is open; R16 closed (`omega#112`) and the freeze is lifted (plan line 45). Not rewritten here (historical plan documents); readers should take the plan's line 45 as authoritative.
- `physics` `forge/v2/forge_substrate_v2.h` header comment cites ARCH-0018 as PROPOSED; it is ACCEPTED. Not changed here (comment only; no canonical effect).
- ADR 0019 section 11 says the R16 lift "must be recorded in `CURRENT_EXECUTION_PLAN.md`"; it is recorded at line 45. ADR 0019 also says `MA-3` to `MA-5` are not sequenced in the plan; still true.

## 5. Compatibility

| Artifact | Effect |
|---|---|
| FORGE V2 canonical bytes, digests, golden vectors (`docs/forge-v2-golden-vectors.md`) | unchanged; AR1 gates re-run and pass inside the FORM0 gate |
| FORGE v1 208-byte GB10 descriptor and KAT digest `10d63d05…09fd` | untouched |
| AR2 receipt `evidence/AR2/808e79f8…b073.json` | reproduced byte for byte by the unchanged AR2 gate |
| Omega program ids (`omega.program.v2`), `rc_contract_identify`, registry digest, cost-model blob `"OGCM"` v1, generation digests | untouched (no omega edit) |
| GB10 qualification receipts (M16 to M19, R16, CHIPWAIT) | untouched |
| New: `evidence/FORM0/ca1f0847…f7c4.json` | new, digest-named, `SIMULATED_DEVELOPMENT` |

## 6. Cost accounting (requirement, not implementation)

A future selection among forms and lowerings must count end to end: input encoding, output measurement, DAC / ADC, setup, settling, calibration and recalibration, transport and bytes moved, synchronization, physical evolution, verification, error and retry rate, reset, state footprint, measured energy, latency, and monetary or resource cost where applicable. FORGE V2 evidence already carries `execution_duration_ns`, `conversion_duration_ns`, `energy_nj` with `energy_source` (NOT_MEASURED / MEASURED / ESTIMATED), repeat statistics and measured error; the FORM0 record binds those to a form. **No Landauer-limit or "information destruction" joule figure may be derived from runtime state**; an irreversibility measure may later be recorded as a structural property only, never as an energy estimate without measurement.

## 7. Causality

Unchanged. The Omega action graph's dependency edges are the causal constraints; effect boundaries are where explicit ordering is required; total ordering is exceptional. A form or a lowering adds no ordering of its own: device-internal timing (settling, sampling) stays inside the FORGE provider below semantic readiness (ARCH-0016, ARCH-0018 section 6).

## 8. Uncertainty

A stochastic realization is a valid realization only when the contract kind admits it (`BOUNDED_STOCHASTIC` with confidence and sample count; `MEASURED_DISTRIBUTION` once implemented). FORM0 enforces the first three kinds at the FORGE seam. Making these kinds first-class in omega's `rx_contract` is MA-3 / AR3 work and is **not** done here.

## 9. Scientific framing

Analog in-memory computation, physical neural networks, optical transforms, physical reservoir computing, Ising / energy-landscape optimization, stochastic and thermodynamic computation, reversible-computation principles and dynamical systems motivate the form families above. They prove no AIEN advantage. A physical realization is useful only if its measured end-to-end cost beats the competing digital realization under the same contract; mapping a problem to a Hamiltonian makes it neither polynomial nor guaranteed to reach a global optimum. **Physics does not repeal complexity:** relaxation can trap in a local minimum, encoding and readout cost count against the realization, and any advantage is problem- and implementation-dependent and must be measured per contract, never assumed from the substrate class.

## 10. Success criteria

- **First proof (met at the host / simulated level by FORM0):** one semantic operation and one SemanticResultContract realized by two mathematically or physically different methods, selected without substrate names in semantic code, with separately identified and evidenced realizations and the same contract satisfied. Receipt: `physics` `evidence/FORM0/ca1f0847…f7c4.json`, field `proof_two_realizations_same_contract: PASS`. This is a development proof under `SIMULATED_DEVELOPMENT`, not a physical result.
- **Second proof (open):** a non-digital realization wins a measured end-to-end cost objective under the same contract without weakening correctness or authority. Requires AR4 (physical device, operator decision) and the widened cost model (MA-5 / AR5).

## 11. Workstream gates (not milestones; sequencing in `CURRENT_EXECUTION_PLAN.md`)

| Gate | Definition | Depends on |
|---|---|---|
| FORM0 | Form IR, LINEAR_OPERATOR, two lowerings of one contract, host gate + receipt (`physics#46`) | AR2 (PASS) |
| FORM1 | Form-aware selection record: `turing.decision.v1` candidates carry form digest + lowering digest; selection by measured cost among eligible realizations (test-side first, `rx_empirical_optimizer` pattern, no runtime edit) | FORM0, ARCH-0019 section 9.1 |
| FORM2 | `ENERGY_FUNCTIONAL` reference: exhaustive and digital-optimizer references, contract with objective bound, host gate; decode accepts kind 2 only once this lands | an Omega `solve_optimization` contract (MA-3) |
| FORM3 | Omega seam: non-exact contract kinds in `rx_contract` (AR3 / MA-3) and capability-based realization eligibility replacing `RX_COG_HW_*` (AR5); explicit blob versioning before any `rx_costmodel` widening (MA-5) | R16 closed (done), ADR 0020 EST-3 |
| FORM4 | First physical lowering of a form (AR4) with `PHYSICAL` provenance | operator decision on a device |

## 12. Review questions (answered at proposal time)

| # | Question | Answer |
|---|---|---|
| 1 | Does any new field enter Omega semantic identity? | **No.** Tested: form digest absent from contract bytes; contract digest unchanged. |
| 2 | Did FORGE V2 canonical bytes change? | **No.** No V2 file edited; AR1 golden vectors reproduce. |
| 3 | Did any historical receipt change? | **No.** AR2 receipt reproduced byte for byte. |
| 4 | New central scheduler, loop, service, World or authority? | **No.** R16 loop-inventory heuristics gate passes; no AIENOS edit. |
| 5 | Any substrate name in the form? | **No.** Gate greps the struct. |
| 6 | Any quantum vocabulary in classical semantics? | **No.** Gate greps the provider. |
| 7 | Any physical-device claim? | **No.** Every record `SIMULATED_DEVELOPMENT`; the module cannot emit `PHYSICAL`. |
| 8 | Is `ENERGY_FUNCTIONAL` implemented? | **No.** Specified, reserved, refused by decode. |
| 9 | Does digital fallback remain? | **Yes.** `forge_form_admit` is the V2 eligible-set rule; a refused analog lowering leaves the digital reference to publish under the same contract (tested). |
| 10 | Another master plan? | **No.** Gates above are sequenced only in `CURRENT_EXECUTION_PLAN.md`. |
