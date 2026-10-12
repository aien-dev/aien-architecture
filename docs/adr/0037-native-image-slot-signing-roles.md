# ADR 0037: Who signs native slot images: Owner Root directly, or a Release Signer it delegates to

**Status:** PROPOSED (2026-10-12). Not decided. Written by the P11 recovery worker (w-recovery, Claude) for Drake Stapleton, as the handoff "DRAKE DECISIONS" of 2026-10-12 asked: if the Owner Root versus Release Signer contract is undefined, propose it here as a reviewed change rather than decide it in code. Until Drake decides, the code keeps doing what it does today (Option A below).
**Addendum to:** ADR 0024 Q3 (boot), as amended by the native v1 addendum of `CURRENT_EXECUTION_PLAN.md` (R8, N7: the slot loader approved on 2026-10-12 for "signed A/B image selection, boot-success tracking, and rollback" only).
**Related:** aien-architecture#190 (native v1 plan), aienos#333 (P11 cuts 2b, 3, 4), aienos#35. Cite aienos ADRs as OS-00nn.
**Evidence base:** aienos `main` at aa76c36 (paths relative to aienos).

---

## What is defined today

- **The roles exist.** TRUST-1 Q6 (`docs/TRUST-1-IMPLEMENTATION-PLAN.md` line 115): "Root never on Spark, never routine; Boot Signer signs small stable loader (firmware trusts its cert); Release Signer signs kernel/manifests under loader (replaceable via root-signed manifest; compromise never requires firmware-root replacement)".
- **The ceremony makes all four keys.** `scripts/trust1_key_ceremony.sh` generates Owner Root, Boot Signer, Release Signer and Operator Approval and an authority manifest signed by the Owner Root; its `role.release_signer.duty` is "signs kernels and manifests under the loader; replaceable by a root-signed manifest". `scripts/trust1_gate5_policy_sim.sh` models the Owner Root to Release Signer delegation. `scripts/trust1_key_ceremony.sh rotate release_signer add|revoke` already rotates the Release Signer as new root-signed generations.
- **The slot format trusts the Owner Root directly.** `native/boot/slot_format.h` (format v1): the slot manifest "is signed by the Owner Root Ed25519 key"; SLOTLDR.EFI verifies it against public keys baked in at build time (`CK_SLOT_KEYS`). There is no authority manifest in the slot path.
- **The gap is recorded, not decided.** `docs/OWNER_KEY_CEREMONY.md` lines 65-71: "Which key signs routine releases is a later design decision; this ceremony creates both, so either answer works without a second ceremony."
- Owner decision of 2026-10-12: the owner key ceremony happens on the MacBook with Drake present; no real key is generated on the Spark.

So the roles are defined; how the slot loader would verify a delegated Release Signer is not. Format v1 contradicts Q6's "Root never routine" for every release.

## Options

**A. Owner Root signs every slot manifest (today).**
What changes: nothing. Upside: one key, one signature, no new format, already gated in QEMU (slot loader gate rows 186-197). Downside: the Owner Root comes out of its offline storage for every release, which TRUST-1 Q6 says it must not do routinely; a compromised Owner Root cannot be replaced without re-baking every loader. Reversible: yes (Option B is additive).

**B. Owner Root delegates to a Release Signer through a root-signed authority record (TRUST-1 as written).**
What changes: the loader keeps only Owner Root public keys. The slots partition carries one more unit, an authority record signed by the Owner Root: authority generation, the Release Signer public key(s), and a minimum authority generation. Slot manifests (format v2) are signed by a Release Signer named in the newest valid authority record whose generation is at or above the floor kept in the control record. Revoking a Release Signer is a new root-signed authority record with a higher generation; the Owner Root is used only for that. Upside: matches Q6; releases never need the Owner Root. Downside: a new signed record, a format v2, and new loader and gate code (new negative controls: authority signed by the wrong key, authority generation rollback, manifest signed by a revoked signer). Reversible: yes, while v1 images stay bootable under a policy that still accepts them.

**C. Bake both Owner Root and Release Signer public keys into SLOTLDR.EFI.**
What changes: `CK_SLOT_KEYS` lists both. Upside: no new format. Downside: replacing a compromised Release Signer means rebuilding and re-signing the loader (Boot Signer) and touching the ESP, which is exactly what Q6 says a Release Signer compromise must never require. Not recommended.

## Proposal

Adopt **B** as the target, implemented as its own small cut after N7's install, update and recovery paths are proven with Option A, and keep **A** for native v1 until then, recorded as a known deviation from TRUST-1 Q6 ("Root never routine"). The owner key ceremony is unaffected: it already creates the Release Signer, so neither option needs a second ceremony.

## What Drake is asked

One question: should native v1 ship with the Owner Root signing every slot image (A, simplest, the Owner Root is used offline once per release), or should the delegated Release Signer of B be built before the first release?

## Not in scope

Key rotation mechanics beyond what B needs, the Boot Signer and firmware db (TRUST-1 Q6, unchanged), TPM, networking. Hardware NOT_RUN; nothing here was run on a physical machine.
