# Sealed Exam Data Layout V0

**Status:** PROPOSED, 2026-10-01. Companion spec to ARCH-0026 (`docs/adr/0026-sealed-discovery-examinations.md`, merged `5910dff`). Nothing in this document is implemented. No exam data exists. No status is raised.
**Scope:** how the observations of each ARCH-0026 exam (A Dirac, B Zeta-style spectral, C symmetry, D future SUSY-style) are laid out: train and sealed held-out split, manifest fields, file naming, and what the examinee may and may not see.
**Out of scope:** salt generation, sealing, signing, sealed storage and reveal steps. Those belong to the **sealing procedure (draft, EXAMS-SEAL)**, written in parallel. This spec only names the places where a sealing output is referenced.
**Evidence base:** read on 2026-10-01 against aien-architecture `5910dff` and omega `0171bd4`. Paths starting `spec/`, `src/`, `docs/turing/`, `docs/brownian/` or `research/` are in `aien-dev/omega`; other paths are in this repository.

---

## In plain words (read this first)

Every exam has two piles of data. AIEN studies the first pile (train). The second pile (held out) is locked away and only used once, at the end, to check whether what AIEN found predicts data it never saw. This spec says how the two piles are labeled, what is written on the outside of each locked box, and what AIEN is allowed to see. The main rule: nothing AIEN can see may name the answer or hint at it, including file names, labels and control sets.

## 1. Rules this spec inherits (not new)

| Rule | Source |
|---|---|
| Never give AIEN the named answer; exam theories are hidden evaluator knowledge | ARCH-0026 section 1; ARCH-0023 section 2 |
| Pass criterion: positive Turing gain on sealed held-out data under a profile frozen before reveal, scored once; hostile controls behave; append-only receipt | ARCH-0026 section 2 |
| Shared hostile controls: shuffled, label-permuted, named-answer leakage canary, complexity-penalty-off, decoy structures, budget-matched baseline | ARCH-0026 section 3 |
| Held-out commitment uses the G3 scheme; no second scheme | omega `spec/searchtrace/G3_SEALED_HOLDOUT_COMMITMENT_V1.md`; `docs/plans/dirac/DIRAC-0-SPEC.md` section 7.2 |
| Dataset objects use the OMG0 canonical encoding; record digests are SHA-256 with a domain prefix and a zero byte | `docs/plans/dirac/DIRAC-0-SPEC.md` section 8; omega `spec/canonical-encoding.md` |
| Leakage checklist (filenames, metadata, provenance, repository, Cortex, prompts, Skills, graph, logs, tooling) | `docs/plans/dirac/DIRAC-0-SPEC.md` section 7.1 |
| Neutral channels, randomized order/scale/offset/frame, decoy channels and actions, disjoint exploration and held-out regions | `docs/plans/physics-zero/PHYSICS_ZERO_LAW_ATLAS_V1.md` section 4 items 3, 4, 11 |
| Public fixtures may sit in omega; sealed keys, parameters and generators never enter any AIEN-readable repository | `docs/plans/dirac/DIRAC-0-SPEC.md` section 6 placement rule; omega `research/dirac-oracle/ORACLE-SPEC.md` section 8 |

This spec adds no hash algorithm, key layout or signature format. Where an existing spec does not yet fix something, the text says **TO BE FIXED BY <prerequisite>**.

## 2. Two sides, two manifests

Every exam instance has an **evaluator manifest** and an **examinee view**. They are different files with different readers.

| | Evaluator manifest | Examinee view |
|---|---|---|
| Who reads it | Evaluator only | AIEN (the examinee) |
| Where it lives | Private evaluator storage owned by the operator (location is an owner decision, BLOCKED_OPERATOR per ARCH-0026 section 7 and Law Atlas section 4 item 10) | The examinee's input bundle only |
| May name the theory | Yes | Never |
| Holds the held-out data | Commitment only (sealed bytes are stored per the sealing procedure) | No. Not the data, not its size, not its regime boundaries |

### 2.1 Evaluator manifest fields (PROPOSED)

Field names below are proposed for this manifest only. Where a field carries a value defined by an existing format, the existing name and format are reused unchanged. The byte format of the manifest itself (canonical ASCII record like G3, or OMG0) is **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL**. Its digest domain string is **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL** (DIRAC-0-SPEC section 8 reserves `omega.dirac.*` for Dirac domains and lists none as frozen; no generic exam domain exists).

| Field | Meaning | Format source |
|---|---|---|
| `exam_id` | Evaluator label for the exam instance, for example naming rung and attempt | Label rule reused from G3 `holdout_id`: `[A-Za-z0-9._-]{1,64}`. Evaluator side only; may contain theory words |
| `exam_rung` | One of A, B, C, D (ARCH-0026 section 4) | This spec |
| `domain` | Plain description of the exam's mathematical domain, evaluator side | Free text, evaluator side only |
| `generator_ref` | Digest of the evaluator-only generator build and its inputs, or of the external source if the data is not generated | Law Atlas section 4 item 2 (commitment over generator build, world list and scoring code). Exact preimage **TO BE FIXED BY the sealing procedure (draft, EXAMS-SEAL)**. For Exam A the generator is D-11 (DIRAC-0-SPEC section 14 table), not built |
| `train_split_digest` | Digest of the train observation set as delivered to the examinee | SHA-256 with a domain prefix and a zero byte (DIRAC-0-SPEC section 8). Domain **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL** |
| `holdout_id` | Label of the held-out set | G3 `holdout_id`, unchanged |
| `holdout_commitment` | The G3 `commitment` value for the held-out set | G3 spec, Commitment section, unchanged |
| `holdout_record_digest` | SHA-256 of the whole G3 commitment record file (`g3-commit-<digest>.txt`) | G3 spec, Record section, unchanged |
| `sealing_ref` | Pointer to the sealing outputs (owner signature record `g3-sig-<record_digest>.txt`, storage reference) | G3 spec owner-signature section for the signature file name; everything else **TO BE FIXED BY the sealing procedure (draft, EXAMS-SEAL)** |
| `turing_profile_ref` | Digest of the frozen Turing profile used to score this exam, committed before reveal | Pattern from omega `docs/turing/TURING_YIELD_PROFILE_V0.md` (profile digest `turing.yprofile.v0`, split digest `turing.ysplit.v0`). See section 2.3 |
| `pass_bar_ref` | Which quantity the pass bar uses: T or net Turing gain | **TO BE FIXED BY TURING owner review** (ARCH-0026 section 2; DIRAC-0-SPEC lines 170 to 172) |
| `control_sets` | List of hostile control sets (section 4), each with its own `holdout_id`, `holdout_commitment` and expected outcome | ARCH-0026 section 3 for the controls; G3 for each commitment |
| `canary_digest` | SHA-256 of the leakage canary marker string and of the decoy equation text planted in evaluator-only material | ARCH-0026 section 3. Domain and scan procedure **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL**. The marker itself is kept evaluator side; the digest lets a later audit prove which marker was planted |
| `blinding` | `blind` or `partially_blind`, plus the list of declared generic constraints shown to the examinee (ARCH-0026 section 4 opening) | This spec |
| `exploration_region` and `holdout_region` | Evaluator description of the two disjoint regions | Law Atlas section 4 item 11. Evaluator side only |
| `examinee_view_digest` | Digest of the examinee view file (section 2.2) | SHA-256 with domain prefix; domain **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL** |
| `repo_commit` | 40 lowercase hex commit of the evaluator code that produced the data | Format reused from G3 reveal receipt `repo_commit` |

### 2.2 Examinee view fields (PROPOSED)

The examinee view carries only what ARCH-0026 and the DIRAC-0 secrecy boundary allow on the AIEN side: numeric observations, channel ids, timestamps, permitted interventions, uncertainty (DIRAC-0-SPEC section 7 diagram).

| Field | Meaning |
|---|---|
| `bundle_id` | Opaque identifier: a digest or a counter, never a word (DIRAC-0-SPEC section 7.1, Filenames row) |
| `dataset_commitment` | The digest of the train set as delivered. Provenance on the AIEN side names this only, never the generator (DIRAC-0-SPEC section 7.1, Provenance row) |
| `channels` | Opaque channel ids with declared units of measure where units are neutral (for example "seconds", "dimensionless"). Order, scale, offset and frame randomized per world (Law Atlas section 4 item 3). Includes decoy channels (item 4) |
| `observations` | Records of (channel id, time stamp, value, declared uncertainty), per DIRAC-0-SPEC section 8 "Observation" row |
| `interventions` | Permitted action ids (opaque), allowed range, cost, authorization reference, per DIRAC-0-SPEC section 8 "Intervention" row; includes decoy actions |
| `declared_constraints` | Partially blind exams only: generic constraints in generic words (for example "a conserved quantity exists"), never the theory name |
| `budget` | Search and compute budget the examinee may spend |

**Discrepancy recorded (UNVERIFIED which wins):** the Law Atlas names neutral channels as text labels `CHANNEL_nnn`, `OBSERVATION_TIME`, `MEASUREMENT_UNCERTAINTY`, `ACTION_HISTORY` (section 4 item 3), while DIRAC-0-SPEC section 8 defines a channel id as an opaque integer. This spec does not choose. **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL.**

The byte encoding of observation records is OMG0 canonical encoding per DIRAC-0-SPEC section 8. Which OMG0 types carry an observation record is **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL** (and for Exam A, D-11). Complex values on the AIEN side wait on D0.1 (ARCH-0026 section 4.1, PARTIAL).

### 2.3 Turing profile reference

The only frozen profile today, omega `docs/turing/TURING_YIELD_PROFILE_V0.md` (PRE-REGISTERED 2026-09-29), is defined over CTR1 crumb traces from the crumbline control seeds (its section 2). It does not cover exam observations. Each exam therefore needs its own frozen profile, committed before reveal, following the V0 pattern: a profile digest and a split digest, both SHA-256 with a domain prefix, and a once-only held-out scoring path that refuses a second run. The profile content, its domain strings and the meaning of "positive Turing gain" are **TO BE FIXED BY TURING owner review**. `turing_profile_ref` stays empty until then, and no exam verdict can be PASS (ARCH-0026 section 2).

## 3. Train and held-out split

Shared rules:

1. The split is fixed by the evaluator and committed (G3) before any examinee run. The examinee never chooses or sees the split rule (DIRAC-0-SPEC section 7.3, 7.4).
2. Train and held-out observations are disjoint. Held-out data includes at least one preregistered regime not represented in train (DIRAC-0-SPEC section 7.4).
3. Held-out membership is never a function of an examinee query. Interventions are served from the exploration region only; a request that would land in the held-out region gets the same reply as any out-of-budget request (Law Atlas section 4 item 11).
4. The held-out set is scored once. A rerun needs a new commitment and is recorded as a new attempt (ARCH-0026 section 2 item 2; DIRAC-0-SPEC section 7.4).
5. Mapping a held-out observation set onto the G3 task-set input is open. G3 treats the task set as opaque bytes and refuses a set with zero lines starting `task ` (G3 spec, Inputs). How observation records become G3 task lines is **TO BE FIXED BY the sealing procedure (draft, EXAMS-SEAL)**.

Per exam, the held-out axis comes from ARCH-0026 section 4. This spec only states what is split, not values.

| Exam | Train | Sealed held out | Note |
|---|---|---|---|
| A Dirac | Samples from training regimes of the hidden law | Held-out regimes: parameter values, momenta, boundary conditions (ARCH-0026 section 4.1) | Generator is D-11, evaluator side, not built. The public KAT corpus (`research/dirac-oracle/CORPUS-FORMAT.md`) is a conformance fixture and is never part of any exam bundle |
| B Zeta-style spectral | Training ranges and instances of the hidden object | Held-out ranges and held-out instances (ARCH-0026 section 4.2) | Open: ARCH-0026 scores each arrow of the chain separately, while section 2 scores the held-out set once. Whether each arrow needs its own sealed set is **TO BE FIXED BY TURING owner review and ARCH-0026 acceptance** |
| C Symmetry | Trajectories from training initial conditions | Initial conditions related to training ones by transformations not shown in train (ARCH-0026 section 4.3) | The transformation set itself is evaluator side only |
| D SUSY-style (future) | Observations from the sectors and ranges shown | Held-out sectors and parameter ranges (ARCH-0026 section 4.4) | No schedule; a new decision record is required first (ARCH-0026 section 5) |

## 4. Hostile control sets

Each control in ARCH-0026 section 3 that needs its own data is a separate observation set with its own G3 commitment, listed in `control_sets` in the evaluator manifest with its expected outcome.

| Control | Needs its own data set | Notes |
|---|---|---|
| Shuffled data | Yes | Derived from the real set by the evaluator; shuffle seed evaluator side |
| Label-permuted data | Yes | Permutation evaluator side |
| Leakage canary | No data set | Marker and decoy equation planted in evaluator-only material; only `canary_digest` is recorded |
| Complexity-penalty-off | No new data | Same data, different profile setting; reported, never counted (ARCH-0026 section 3) |
| Decoy structures | Yes, one per decoy world | Per-exam decoys listed in ARCH-0026 sections 4.1 to 4.4 |
| Budget-matched baseline | No new data | Same data, capability withheld |

**Indistinguishability rule (PROPOSED):** the examinee must not be able to tell a real set from a control or decoy set. Control and decoy bundles use the same field layout, the same opaque naming and the same channel randomization as the real bundle. The mapping from `bundle_id` to "real", "decoy" or "control" lives only in the evaluator manifest. A bundle whose name, size pattern, field set or metadata reveals its role voids the exam (it is a leak under ARCH-0026 section 3).

## 5. File naming

Evaluator side files may use descriptive names. Examinee side files may not.

1. Examinee side names are opaque: a lowercase hex digest or a counter (DIRAC-0-SPEC section 7.1, Filenames row). No exam letter, rung, theory word, regime word or the words "train", "test", "holdout", "control" or "decoy" appear in any examinee-readable path, directory name, field value or metadata.
2. Examinee side files carry fixed metadata: no timestamps, authorship or tool strings that name the source (DIRAC-0-SPEC section 7.1, File metadata row).
3. G3 files keep their existing names: `g3-commit-<sha256>.txt`, `g3-sig-<record_digest>.txt`, `g3-reveal-<sha256>.txt` (G3 spec). These are evaluator side until the sealing procedure says what is published.
4. The neutral prefix and extension for examinee data files (for example a fixed prefix plus the content digest) are **TO BE FIXED BY M27 PHYSICS_ZERO_PROTOCOL**. Precedents for content-addressed names: `g3-commit-<sha256>.txt` (G3) and `dirac-kat-<sha256>.txt` (DIRAC KAT corpus). The second is evaluator and public-fixture naming and must never be reused on the examinee side, because it names the theory.

## 6. What the examinee may and may not see

| May see | May not see |
|---|---|
| Train observations with opaque channel ids, time stamps, values, declared uncertainty | Held-out observations, their count, size or regime boundaries before reveal |
| Permitted interventions (opaque ids, ranges, costs), including decoys | The theory name, its equation, constants, generators or canonical basis (ARCH-0026 section 1) |
| Declared generic constraints, for partially blind exams only | Any label that encodes the theory's structure, for example channel names that name components, sectors, spin, mass, energy, gamma, spinor, zeta, critical line, symmetry group or supersymmetry |
| The `dataset_commitment` of its own train bundle | `generator_ref`, `exam_id`, `exam_rung`, `domain`, the split rule, region descriptions, `control_sets`, `canary_digest` or any evaluator manifest field |
| The search and compute budget | Whether a bundle is real, control or decoy |
| Its own predictions and the committed scoring result after reveal | The scoring code at run time, the oracle, answer keys (DIRAC-0-SPEC section 7.3) |

Label leakage includes structure, not only words. Examples that are forbidden on the examinee side: channel ids grouped or numbered so that components of one field are adjacent (Exam A), instance ids that sort in the order of a hidden spectrum (Exam B), initial conditions labeled by the transformation that relates them (Exam C), sector tags that pair states across sectors (Exam D). Channel order, scale, offset and frame are randomized per world (Law Atlas section 4 item 3) for this reason.

## 7. Prerequisites before any exam bundle is produced

| Item | Owner | State |
|---|---|---|
| Sealing procedure (salt, storage, signing, reveal) | EXAMS-SEAL draft; owner signature by Drake | Draft in progress; G3 owner signing BLOCKED_OPERATOR (ARCH-0026 section 7) |
| Manifest byte format, domain strings, neutral channel naming, examinee file prefix | M27 PHYSICS_ZERO_PROTOCOL | PLANNED (`doctrine/ROADMAP.md` line 66) |
| Frozen exam Turing profile and pass bar | TURING owner | Not started for exam data; pass bar open |
| Exam A data generator | D-11 (DIRAC-0-SPEC section 14) | Not built; does not start before the operator confirms placement (DIRAC-0-SPEC section 6) |
| Private evaluator storage location | Operator | BLOCKED_OPERATOR |
| Process isolation of the examinee | Law Atlas section 4 item 12 | Not built; results until then are UNISOLATED and cannot count toward a gate |

## 8. What this spec does not do

- It adds no code, script, tool, data, primitive or type.
- It defines no sealing, signing, salt or storage step.
- It defines no hash algorithm, key layout or signature format; it reuses G3 and the DIRAC-0 section 8 digest rule.
- It changes no milestone status and does not accept ARCH-0026 or ARCH-0023.
