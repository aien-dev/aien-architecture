# Analog Realization — ARGUS Telemetry Requirements

**NOT A MASTER PLAN.** This is a finite workstream document for ADR 0018 (ARCH-0018, PROPOSED), substrate-neutral physical realization. `CURRENT_EXECUTION_PLAN.md` still owns cross-project sequencing (§6 C3, Lane 6), and `doctrine/ROADMAP.md` still owns milestone status. The AR-gates are ADR 0018 workstream gates, not M-milestones.

**DOCUMENTATION ONLY. NO ABI CHANGE NOW.** Nothing here changes the ARGUS event ABI v1.1, the ARGUS code, or the ARGUS-1 invariants. These are requirements to be queued onto the ARGUS ABI v2 discussion that is already open.

**Written:** 2026-09-29, from a read-only audit of the commits below.

| Repository | Commit |
|---|---|
| aienos | `feat/argus-0` `a64bc55` (aienos#160, `native/argus/argus_abi.h`); aienos#162 spec at `1f5fc23` |
| omega | omega#70 at `cf6f45d` (pins aienos `feat/argus-0` `b375dca` via `argus.lock`) |
| aien-architecture | `main` `f6baa35` (ARCH-0017 ARGUS reserved, not on `main`) |

---

## 1. Roles

- **ARGUS detects:** observes, records, raises findings. Its containment is advisory.
- **AEGIS verifies:** decides, revokes, quarantines, holds authority.
- **FORGE realizes:** attaches substrates, calibrates them, produces results, and emits the events below.

ARGUS gains no authority from analog work. The ARGUS-1 invariants (aienos#162) stand unchanged: one-narrow-revoke only (I1), freeze is a labelled stand-in (I2), no whole-system actions (I3), no instant blocking (I4), ARGUS never grows its own authority (I5).

## 2. ABI v1.1 in brief (as audited)

`ArgusEvent` is 128 bytes: version, class (CRITICAL / SECURITY / AUDIT / INFORMATIONAL), kind (u16), effect class, outcome, flags (incl. 14-bit stream id), sequence, tick, principal, code, `cap_id`, `object_id`, `cap_generation` (u64), `world_generation` (u64), `resource` (u64), `machine_id[32]` (PROVISIONAL), `evidence_digest[32]`. Kinds are append-only and stable forever; the highest is `CAPABILITY_USE_SUMMARY` = 81. v2 events are rejected by v1.1 consumers. Finding confidence is DETERMINISTIC only; STATISTICAL is reserved for ARGUS-5+.

## 3. The ten observations analog work will need

"Later version" means either new kinds numbered **above 81** where the 128-byte layout suffices, or **ABI v2** where a new identity field is required.

| # | Needed observation | Nearest v1.1 kind | How a later version could carry it without breaking v1.1 | Notes / gap |
|---|---|---|---|---|
| 1 | Substrate attach / detach | `MACHINE_JOINED` 30 / `MACHINE_REMOVED` 32, `PROVIDER_DISCOVERED` 40 | New kinds >81 `SUBSTRATE_ATTACHED` / `SUBSTRATE_DETACHED`; `evidence_digest` = substrate descriptor digest; `object_id` = substrate slot | Needs producer identity (hostile G-5: no producer identity in v1) → v2 |
| 2 | Calibration change | `POLICY_CHANGED` 71 (closest), `PROVIDER_CHANGED` 41 | New kind >81 `CALIBRATION_CHANGED`; `evidence_digest` = calibration record digest; `resource` = calibration epoch; `object_id` = substrate slot | AEGIS verifies the calibration record; ARGUS only records |
| 3 | Calibration expiry | none | New kind >81 `CALIBRATION_EXPIRED`, emitted by FORGE (or synthesized by ARGUS with the consumer flag from a declared expiry); `resource` = expiry epoch | Expiry is a clock fact; the producer must supply the clock |
| 4 | Unexpected drift | none | New kind >81 `DRIFT_OBSERVED`; `resource` = scaled drift magnitude; `evidence_digest` = measurement digest | Statistical judgement needs STATISTICAL confidence (ARGUS-5+); ARGUS-0/1 may only record |
| 5 | Hardware fault | `INTEGRITY_VIOLATION` 60 (closest) | New kind >81 `SUBSTRATE_FAULT`; `code` = fault class; `object_id` = substrate slot | Keep 60 for digest/trust breaks, not device faults |
| 6 | Provider substitution | `PROVIDER_CHANGED` 41 / provider `QUARANTINED` 42 (`evidence_digest` = provider id) | Same kinds, plus a stable provider identity scheme → v2 | Known gap: hostile G-9 "no stable provider identity in v1" |
| 7 | Out-of-envelope operation | none (`EXTERNAL_EFFECT_DENIED` 51 is authority, not physics) | New kind >81 `ENVELOPE_EXCEEDED`; `resource` = which bound; `code` = direction; `evidence_digest` = envelope / contract digest | Deterministic when the envelope is a declared contract, so it can be a hard finding |
| 8 | Repeated result anomaly | none | New kind >81 `RESULT_ANOMALY` per occurrence; finding on a count threshold | Counting is deterministic; judging "anomalous" is statistical (ARGUS-5+) |
| 9 | Device identity change | `MACHINE_TRUST_CHANGED` 31, finding `MACHINE_IDENTITY_MISMATCH` 7 | Reuse 30-32 and finding 7; a substrate inside a Machine needs its own identity slot → v2 | `machine_id` is 32 bytes but PROVISIONAL |
| 10 | Transport fault | `TELEMETRY_DROPPED` 80 (ARGUS ring loss only) | New kind >81 `SUBSTRATE_TRANSPORT_FAULT` for the device link | Do not overload 80 |

Summary by mechanism:

- **New kinds above 81 (layout unchanged):** 2, 3, 4, 5, 7, 8, 10.
- **Needs ABI v2 identity fields:** 1 (producer identity), 6 (stable provider identity), 9 (substrate identity slot inside a Machine).

## 4. Rules for the later ABI work

- Queue these onto the ABI v2 discussion already opened by R7 code 13 (`AUTHORITY_REPLAY`, needs an authority-instance id) and hostile G-5 / G-9 (producer and provider identity). Do not open a separate ABI track.
- Every new kind needs a class (CRITICAL / SECURITY / AUDIT / INFORMATIONAL) so ring back-pressure stays defined.
- Kinds stay append-only; no existing kind is renumbered or repurposed.
- No vendor or product names in kind names or fields (ADR 0018 §2.2).
- Nothing here is started before the ARGUS performance gate is decided (aienos#160: +6.2% vs omega#70: +3.87%; 5% vs 2% bar undecided) and R16 closes.
