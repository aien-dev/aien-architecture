# ADR 0018: Substrate-Neutral Physical Realization

**Status:** Accepted by operator Drake Stapleton, 2026-09-29.
**Gate:** `AR0` satisfied when this ADR is accepted by the operator and merged to `main`.
**Supersedes:** nothing. **Amends:** the FORGE responsibility text in `doctrine/ARCHITECTURE.md` §2.4, one AEGIS inquiry in §2.5, and one framing paragraph in §3 (see "Doctrine reconciliation").
**Related:** ARCH-0002 (hardware-neutral Machine identities), ARCH-0005 (irreversible effects require a broker), ARCH-0013 / ARCH-0014 (FORGE realizes, AEGIS verifies), ARCH-0015 (Resident Semantic Store), ARCH-0016 (resident reaction architecture, R0–R16), ARCH-0017 (ARGUS; number reserved, not yet on `main`).
**Workstream:** AR0–AR7, sequenced in `CURRENT_EXECUTION_PLAN.md` §6 C3 and Lane 6; supporting documents in [`docs/plans/analog-realization/`](../plans/analog-realization/) (NOT A MASTER PLAN).

Citation note: in this repository "ADR 0018" and ARCH-0018 name the same decision. In other repositories cite it as ARCH-0018.

---

## 1. Context

AIEN's first qualified Machine is a DGX Spark: an AArch64 CPU plus a GB10 GPU sharing coherent memory. Every realization qualified so far is digital and runs on one of those two devices. The architecture already says (ARCH-0002) that Machines are hardware-neutral and that vendor/product information is capability metadata, not identity. It does not yet say what happens when the physical device that realizes a computation is not a digital CPU or GPU at all.

Future substrates are not hypothetical categories to be designed around later. Analog in-memory compute, neuromorphic devices, FPGA/CGRA fabrics and optical/photonic accelerators each realize some operations (for example a matrix-vector product) at a very different cost, and each produces results that are not bit-exact. If the semantic layer assumes bit-exact digital arithmetic, every such substrate either cannot be used, or is used by silently weakening what "correct" means. Both outcomes are unacceptable.

This ADR fixes the ownership split and the data model before any physical non-digital device exists in the project, so that the first one (workstream gate AR4) attaches as a capability provider and does not reshape the architecture.

## 2. Decision

The following statements are locked once this ADR is accepted.

```text
OMEGA OWNS SEMANTIC MEANING.
FORGE OWNS PHYSICAL REALIZATION.
AEGIS VERIFIES ADMISSIBILITY AND INVARIANT PRESERVATION.
AIEN MAY PROPOSE AND SELECT OBJECTIVES; AIEN GAINS NO HARDWARE AUTHORITY.

A SUBSTRATE IS A CAPABILITY PROVIDER, NOT AN ARCHITECTURAL IDENTITY.
DIGITAL DETERMINISM IS ONE NUMERICAL REALIZATION MODEL, NOT THE DEFINITION OF COMPUTATION.
ANALOG UNCERTAINTY MUST BE EXPLICIT DATA.
CALIBRATION IS EVIDENCE.
MEASUREMENT CONDITIONS ARE EVIDENCE.
A HARDWARE RESULT IS ACCEPTED BECAUSE IT SATISFIES THE SEMANTIC RESULT CONTRACT,
NEVER BECAUSE A DEVICE RETURNED IT.
```

### 2.1 Permanent rule

```text
SEMANTIC MEANING MUST NOT ENCODE THE PHYSICAL SUBSTRATE THAT HAPPENS TO REALIZE IT.
```

An Omega program, a capability need, a semantic result contract and a World object never name a device, vendor, product, driver, bus or substrate family. Substrate appears only in FORGE realization records, FORGE substrate descriptors, cost metadata, calibration records and evidence. A program that is correct on a CPU is the same program, with the same identity, when FORGE realizes it on an analog array.

### 2.2 Substrates covered

This ADR covers every physical realization substrate, present or future. The list below is illustrative, not closed:

| Substrate family | Typical numerical model | Notes |
|---|---|---|
| Digital CPU | exact integer; IEEE float with a declared rounding model | The current reference/oracle substrate |
| Digital GPU | exact integer; IEEE / reduced-precision float with declared accumulation order | Qualified on GB10 (M16–M19, R12–R14) |
| Analog compute (e.g. in-memory crossbar) | bounded stochastic: quantization, noise, bias, drift, saturation, temperature dependence | First non-digital target (AR2 simulated, AR4 physical) |
| Neuromorphic | event/spike-based; bounded stochastic or measured distribution | Same contract model as analog |
| FPGA / CGRA | exact or bounded deterministic, per synthesized design | The synthesized bitstream is part of realization identity |
| Optical / photonic | bounded stochastic; calibration-heavy | Same contract model as analog |
| Future substrates | declared by their FORGE provider | Attach without an ADR change if they fit this model |

Canonical APIs (Omega semantic types, capability needs, contracts, World objects, Fabric messages, AEGIS verdicts) carry **no vendor or product names**. Vendor-specific records may exist only inside a FORGE provider, identified to the rest of the system by an opaque content digest.

### 2.3 End-state flow

```text
AIEN proposes an objective (no hardware authority)
        ↓
OMEGA defines semantic meaning + SemanticResultContract
        ↓
OMEGA / FORGE enumerate eligible realizations
   ┌──────────┬──────────┬──────────┬──────────────┬──────────┬──────────┐
   │ digital  │ digital  │ analog   │ neuromorphic │ FPGA /   │ future   │
   │ CPU      │ GPU      │          │              │ CGRA     │          │
   └──────────┴──────────┴──────────┴──────────────┴──────────┴──────────┘
        ↓   (each candidate: substrate descriptor digest, calibration digest,
        ↓    declared error model, cost metadata)
AEGIS verifies admissibility, authority and invariant preservation
        ↓
FORGE realizes on the selected substrate
        ↓
HARDWARE acts
        ↓
EVIDENCE measures (result, error vs contract, calibration, measurement conditions)
        ↓
OMEGA / AIEN learn (cost and error models; promotion only at generation barriers)
```

As in ARCH-0016, this diagram shows **dependency structure**, not a runtime turn order. Each arrow is a readiness dependency in the shared World (§6).

## 3. Semantic result contracts

### 3.1 SemanticResultContract

Every realizable numerical operation carries a **SemanticResultContract**, owned by OMEGA and part of the semantic identity of the operation. It states what a result must satisfy to be accepted, independent of which substrate produced it. It contains at least:

- the operation's semantic identity and input/output types;
- a **numeric contract kind** (§3.2);
- the error bound(s), in declared units (absolute, relative, ULP, or distributional), and the norm they are measured in;
- the reference oracle that defines "correct" for acceptance testing (for example an exact integer reference, or a higher-precision digital reference);
- the required confidence and sample count for stochastic kinds;
- the evidence the result must carry (§4, §5).

A realization is admissible only if its declared error model is within the contract. A result is accepted only if its evidence shows it satisfied the contract. The device that returned it confers nothing.

### 3.2 Numeric contract kinds

| Kind | Meaning | Acceptance |
|---|---|---|
| `EXACT` | Bit-exact against the reference. | Output digest equals the reference digest. |
| `BOUNDED_DETERMINISTIC` | Deterministic, within a declared bound of the reference (e.g. float with declared rounding/accumulation order). | Same inputs give the same output; error ≤ bound on every element. |
| `BOUNDED_STOCHASTIC` | Output varies run to run; every run must fall within a declared bound with declared probability. | Error ≤ bound at the declared confidence over the declared sample count; repeatability within a declared spread. |
| `MEASURED_DISTRIBUTION` | The result *is* a distribution (e.g. a sampled or physical measurement). | The measured distribution's declared statistics fall within the contract; the raw sample set is evidence. |

`EXACT` is the default and is today's only implemented kind. An operation whose contract is `EXACT` can never be realized on a substrate whose declared model is weaker, so no existing exact computation can be silently degraded by this ADR.

### 3.3 Uncertainty is data

Uncertainty is never implicit. A realization declares its error model as data (bias, noise, quantization step, saturation range, drift rate, temperature coefficient, or a measured distribution), bound into the realization record. A realization with no declared error model is eligible only for `EXACT` contracts and must meet them exactly.

## 4. Calibration

- A **calibration record** is a content-addressed artifact (SHA-256 of a canonical encoding) produced by FORGE for a specific substrate instance. It records what was measured, under which conditions, with which reference, and when it expires.
- The calibration digest is **bound into realization identity**. The same program on the same substrate with a different calibration is a different realization.
- A calibration is **stale** when its declared validity has expired, or when measured conditions leave its declared envelope. A realization bound to a stale calibration is **ineligible**. It is not "degraded"; it is not offered.
- Recalibration is a FORGE activity that produces new evidence. It never changes semantic meaning and never widens a contract.

## 5. Evidence

### 5.1 Measurement conditions are evidence

A physical result's evidence records at least: substrate descriptor digest, calibration digest, contract digest, measured error against the oracle, sample count, and measurement conditions (temperature, supply/clock state where applicable, calibration age, device load, latency).

### 5.2 Evidence v2 is additive

The evidence record gains new fields additively. Existing receipts (`evidence/<AREA>/<sha256>.json`) and their schemas are not rewritten. New records carry:

- `provenance_class`: `PHYSICAL` (a real device acted) or `SIMULATED_DEVELOPMENT` (a software model of a substrate acted). A simulated result may qualify a development gate; it may never be presented as a physical result, and a gate that requires `PHYSICAL` refuses `SIMULATED_DEVELOPMENT`.
- substrate descriptor digest, calibration digest, contract kind and bounds, measured error, measurement conditions.

### 5.3 Cross-machine references carry no process pointers

Any reference that crosses a process, Machine or Fabric boundary is a content digest or a typed identifier, never a memory address. The FORGE v1 `ir_payload` pointer is an in-process detail: its value is never hashed and it must not appear in any evidence, realization identity or cross-machine message (audit fact: `forge_realize.c` hashes only the bytes it points to).

## 6. Authority and the resident reaction system

- **Authority:** substrate access is an AIENOS capability like any other. Capability references use 64-bit generations (Omega `EffectPayload` v2, merged in `aien-dev/omega#71`, `8e7a445`); 32-bit v1 effect payloads are refused. Read-only computation (a pure numeric result) and irreversible effects (a physical actuation, a write outside the World) remain distinct classes; an analog device that only computes is a read-only provider, and one that actuates is an effect provider under ARCH-0005.
- **AIEN** may propose objectives and select among admissible realizations through the existing routing/cost-model paths. It never obtains a capability to a substrate by doing so.
- **Resident reaction fit (after R16):** a substrate provider participates as a reaction over the shared World: its results publish through the existing admission → authority → reaction → atomic publication path. This ADR adds **no new central loop, scheduler, service, callback path, or second World**. Device-internal timing (settling, sampling, pulsing) lives inside the FORGE provider below semantic readiness, per ARCH-0016's "physical resources are arbitrated below semantic readiness".
- **Faults:** a faulted, uncalibrated or out-of-envelope device produces a refused result and evidence. It can never corrupt the World: nothing is published unless the contract check passes.

## 7. Fabric

A substrate reached over a link (another Machine, an external instrument) is still a capability provider. **Transport is cost metadata, not semantic identity.** Latency, bandwidth and link reliability enter the cost model and evidence; they never enter program identity, contract identity or result identity.

## 8. ARGUS (deferred)

ARGUS (ARCH-0017, reserved) detects; it does not decide. AEGIS verifies; FORGE realizes. This ADR makes **no ARGUS ABI change**. Future analog telemetry (substrate attach/detach, calibration change/expiry, drift, device fault, provider substitution, out-of-envelope operation, repeated result anomalies, device identity change, transport fault) is listed as documentation-only requirements in [`ANALOG_ARGUS_TELEMETRY_REQUIREMENTS.md`](../plans/analog-realization/ANALOG_ARGUS_TELEMETRY_REQUIREMENTS.md), to be queued onto the ARGUS ABI v2 discussion.

## 9. Physics Zero is separate

Physics Zero (M27–M35, `CURRENT_EXECUTION_PLAN.md` §13) is scientific discovery. This ADR is about realizing computation on physical substrates. Neither depends on the other, and nothing here advances or reorders Physics Zero.

## 10. What this ADR does NOT decide

- It makes **no claim** that any physical analog operation works today. None exists in the project.
- It **does not buy or select a device.** AR4 requires an explicit operator decision on a physical device.
- It **assigns no M-numbers.** AR0–AR7 are workstream gates, not roadmap milestones, and do not change `doctrine/ROADMAP.md` §2.
- It does not change the ARGUS ABI, the R16 scope, Omega runtime code, or any FORGE v1 type.
- It does not choose concrete wire encodings for the V2 descriptor or evidence; those are AR1 deliverables, reviewed against this ADR.

## 11. Current code facts (audit basis, 2026-09-29)

These facts come from read-only audits. Omega file:line references are at `aien-dev/omega` `8e7a445` (audit basis); omega `main` is now `f308ac7` (`#72`, `aienos.lock` pin only). Physics references are at `aien-dev/physics#13` head `5781222` unless marked `main`.

**Omega — already substrate-neutral:**
- `src/runtime/rx_capq.h:84-102` `CqNeed` names an operation, types, effect class, authority ceiling, locality, latency/energy/reliability budgets and evidence requirement. No substrate field.
- `src/runtime/rx_capq.h:104-126` `CqCandidate` carries an opaque `realization_id` (u32). `CQ_SRC_PHYSICAL` (`rx_capq.h:51-56`) is a provider origin, not a substrate.
- `src/runtime/rx_graph.h:234-239` `AG_REAL_HARDWARE` is an existing placeholder realization kind ("none exists on this host").

**Omega — the seams this ADR must eventually touch (after R16):**
- `src/runtime/rx_route.h:61` `enum { RX_COG_HW_CPU_P = 1u, RX_COG_HW_CPU_E = 2u, RX_COG_HW_GPU = 4u };` is **the one hardware-naming type on main**. It filters eligibility (`rx_route.c:323`) and is hashed into the registry digest (`rx_route.c:124`), so adding bits changes registry identity.
- `src/runtime/rx_contract.{h,c}`: contracts are **exact-only**; field types are integer words; zero hits for tolerance/epsilon/float. `RC_EFFECT_CLASSES` includes a `physical` bit (`rx_contract.h:175`) with no `CQ_FX_*` counterpart.
- The only tolerance-style parity path is the M18 matmul comparator (`src/omega_blackwell_submit.c` ~658-662, fixed `1e-4` absolute) against `omega_matmul_cpu_oracle_{i32,f16,bf16}` (`src/omega_blackwell_matmul.h:50-55`). The exact integer oracle is `omega_matvec_reference` (`src/omega_matvec.h:74`).
- `aien-dev/omega#60` (empirical cost model, OPEN, conflicting): arms are anonymous indices (`RX_CM_ARMS` 8); the only hardware axis is CPU core class (`RX_CM_CORE_X925/A725/OTHER`); `RX_CM_OPS 1` (matvec only); observations carry `failed` but no error/accuracy field. **No substrate axis.**
- `EffectPayload` v2 (`src/omega_types.h:166-177`): 64-bit `capability_generation`, 178-byte wire form; v1 refused at `src/omega_canonical.c:48-49` and `src/omega_core.c:295`.

**FORGE v1 (`aien-dev/physics#13`, open, unmerged):**
- Type names are neutral (`ForgeMachineDescriptor`, `ForgeRealizationRequest`, `ForgeExecutionEvidence`), but the API is **NVIDIA-bound at submit**: `forge_realize.h:29` takes `Nvrm *`; error codes `FORGE_SEAM_ERR_NVRM`; feature/observation flags named after RM classes; `forge_descriptor.c:343` rejects any `pci_vendor_id != 0x10de`.
- The v1 descriptor is a fixed 208-byte stream hashed with SHA-256. **The only frozen, reproducible v1 identity is the KAT digest** `10d63d05f888eaba4fe473c5f17febe22f462f543ae0c2b005a9a8e5417e09fd` (`forge_descriptor.c:486`), independently reproduced. The live GB10 descriptor digest is boot-volatile (it includes total memory, driver/firmware versions and PCI BDF).
- `ir_payload`'s pointer value is never hashed (§5.3).
- SHA-256 comes from `physics` `main:sha256_clean.c`, which is pinned into firmware builds: reuse, never modify or duplicate its exported symbols.
- Consequence: V2 wraps the v1 descriptor as an opaque substrate record identified by its digest. It does not reserialize v1, and it does not reuse v1 types as its neutral model. The companion draft "FORGE substrate V2" is `aien-dev/physics#16` (branch `feat/forge-substrate-v2`, host-only KAT: 47 checks and 6 gates PASS; frozen V2 machine digest `89cb5ba6…06c0`).

## 12. Workstream gates AR0–AR7

These are **workstream gates, not roadmap milestones.** They carry no M-number. Sequencing and blockers live in `CURRENT_EXECUTION_PLAN.md` §6 C3; test detail in [`ANALOG_REALIZATION_TEST_PLAN.md`](../plans/analog-realization/ANALOG_REALIZATION_TEST_PLAN.md).

| Gate | Definition |
|---|---|
| AR0 | This ADR accepted by the operator and merged. |
| AR1 | FORGE substrate-neutral descriptor contract: V2 descriptor and evidence encodings with KATs; v1 KAT digest wrapped and reproduced; strict decode; stale calibration refused; v1 generation refused; `SIMULATED_DEVELOPMENT` provenance explicit. |
| AR2 | Analog **simulation** provider with digital oracle parity: a software analog model realizes matvec; results checked against the exact and tolerance oracles under injected non-idealities; every receipt says `SIMULATED_DEVELOPMENT`. |
| AR3 | Calibration, uncertainty and evidence qualification: staleness ⇒ ineligible; declared uncertainty propagates into the contract check; evidence records are complete. |
| AR4 | First **physical** analog operation: matvec, digital oracle vs physical analog, same contract. PASS requires: bounded error within contract; repeatability within declared spread; calibration bound into identity and fresh; no authority bypass; complete evidence; no vendor identity in the semantic program; clean fallback to the digital realization; a faulted device cannot corrupt the World. |
| AR5 | Omega multi-substrate empirical selection (after `omega#60` lands and R16 closes). |
| AR6 | Fabric-connected analog Machine (after Fabric F5). |
| AR7 | J-Space / RSI multi-substrate optimization (after H3). |

## 13. Doctrine reconciliation

- `doctrine/ARCHITECTURE.md` §2.4: FORGE realizes over one or more typed physical substrates as capability providers, and emits calibration and measurement evidence.
- `doctrine/ARCHITECTURE.md` §2.5: AEGIS inquiry 8 — does a bounded or stochastic numerical result satisfy the semantic result contract, with calibration and measurement conditions in evidence?
- `doctrine/ARCHITECTURE.md` §3: the CPU+GPU dual topology is the first qualified Machine, not the definition of a Machine.
- `doctrine/FORGE.md` is unchanged: its OMEGA → FORGE → AEGIS → HARDWARE → EVIDENCE chain already holds for every substrate.
## 14. Final review questions (answered at proposal time)

These are the thirteen questions the workstream brief requires before any implementation PR. A YES to any of the last three is a design failure. Answers are as of 2026-09-29, from the audits in §11.

| # | Question | Answer |
|---|---|---|
| 1 | Does GB10 v1 remain reproducible? | **Yes.** The frozen v1 KAT digest `10d63d05…09fd` is embedded as a literal 208-byte stream in `physics#16` and re-hashed on every run. The live GB10 digest is boot-volatile and is not used as identity. |
| 2 | Did any historical realization identity change? | **No.** No v1 file, receipt, milestone name or evidence was edited; V2 wraps the v1 digest and never re-serializes v1 bytes. |
| 3 | Can Omega express the same semantic operation without naming CPU/GPU/analog? | **Partly.** At the capability-query layer yes: `CqNeed` / `CqCandidate` carry no device field. At the cognitive-routing layer not yet: `RxCogDeclaration.hardware_requirements` uses the `RX_COG_HW_CPU_P/CPU_E/GPU` bitmask (`rx_route.h:61`) and that bitmask is hashed into the registry digest. Closed by AR5, after R16. |
| 4 | Can FORGE describe an analog substrate without making analog a special architectural layer? | **Yes.** `ForgeSubstrateDescriptor` is one typed record per attached substrate; `ANALOG_IN_MEMORY` is one class value beside `DIGITAL_CPU`, `DIGITAL_GPU`, `NEUROMORPHIC_SPIKING`, `FPGA_CGRA_DATAFLOW`, `OPTICAL_PHOTONIC`. No new layer, service or authority. |
| 5 | Can AEGIS verify a bounded stochastic result without pretending it is exact? | **Yes by contract (§3.1–3.3), not yet in code.** `SemanticResultContract` carries `BOUNDED_STOCHASTIC` and `MEASURED_DISTRIBUTION` kinds with confidence and sample requirements; omega's `rx_contract` is exact-only today and gains these kinds in AR3. |
| 6 | Can calibration become stale without silently remaining authoritative? | **Yes.** Calibration epoch + validity window is checked against execution conditions; stale ⇒ not eligible, refused by the V2 validator (KAT `stale_calibration_refused`). Calibration is evidence, never authority. |
| 7 | Can the digital implementation always remain a known-good fallback? | **Yes, as an eligible-set rule.** Admission of a realization plan requires a digital realization for the same contract somewhere in the eligible set (it may live on another Machine). A Machine whose only substrate is analog is a valid descriptor. |
| 8 | Can an unavailable analog device be excluded without changing semantic code? | **Yes.** Availability and fault state are substrate evidence; an unavailable or faulted substrate leaves the eligible set. The semantic program and its digest are untouched. |
| 9 | Can this later become a remote Fabric Machine? | **Yes.** Transport (PCIe, USB, Ethernet, RoCE, board-to-board, remote Machine) is cost metadata in the machine descriptor and evidence, not semantic identity; cross-machine references carry digests, offsets, generation and rights, never pointers. Placement is Fabric's decision (AR6, after F5). |
| 10 | Did we add any new central orchestrator? | **NO.** No loop, scheduler, service, callback path or second World. |
| 11 | Did we disturb R16? | **NO.** No omega `src/runtime/` edit; no R16-owned file touched; new physics C code passes the R16 loop-inventory heuristics as a gate in `physics#16`. |
| 12 | Did we expand ARGUS before its current performance gate passed? | **NO.** ARGUS ABI v1.1 untouched; future observations are documentation only. |
| 13 | Did we create another master plan? | **NO.** Sequencing lives in `CURRENT_EXECUTION_PLAN.md`; the workstream documents are marked NOT A MASTER PLAN. |

## 15. Consequences

- The first physical non-digital device (AR4) attaches as a FORGE capability provider with a descriptor, calibration and error model; no layer above FORGE changes shape.
- Omega must eventually replace the `RX_COG_HW_*` bitmask with substrate-neutral capability requirements, add non-exact contract kinds to `rx_contract`, and add a substrate/realization axis and an error field to the empirical cost model. All three wait for R16 to close.
- FORGE v1 stays as it is: an NVIDIA/GB10 substrate record, identified by digest, reachable through V2 without reserialization.
- Every non-digital result will cost more evidence than a digital one. That is intended.
