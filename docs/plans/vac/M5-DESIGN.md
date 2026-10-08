# VAC M5: bounded RSI hookup, design note (PROPOSED, 2026-10-08)

Status: PROPOSED. Nothing here is implemented. Every claim about current code cites spark-rsi
`origin/main` e5aab9a, interplane `origin/main` 9d1b1ab, or aien-protocols `origin/main`, read on
2026-10-08. Build work starts only after M4 (clean-clone reproducibility) is qualified, per the
directive's Phase 5 rule.

## Goal, one sentence

spark-rsi proposes one Tier1 change to a pinned fixture repository; an evaluator it cannot control
scores the change on a holdout it cannot read or write; the change lands only through the existing
approved path (INTERPLANE -> ComposeApprovedProposal -> daemon ledger); the offline verifier refuses
the bundle unless a signed evaluation receipt names the exact bytes the ledger says were written and
the score meets a threshold fixed before the run.

## What the code already gives us

- **Proposal shape.** `ImprovementProposal` carries one `target_file` and a `proposed_patch`
  (spark-rsi src/models.rs:37). That maps onto one `write_file` effect, the only effect kind the
  daemon has.
- **Branch-only ratifier.** The ratifier creates `rsi/<id>` plus a patch file and never commits to the
  default branch (src/ratify.rs:14-20). This satisfies M5 done-condition (d) as it stands.
- **Fail-closed judge.** `BlindJudge::evaluate_cycle` refuses to run without a signing key or a
  non-empty holdout directory (src/actor/judge.rs:207-213). The judge also ships as its own binary
  that reads its key from a file (judge.rs:49, :641, :674).
- **Signed receipt.** `EvaluationReceipt` is signed with P-256 over `receipt_digest`
  (src/evaluator/mod.rs:96-100). `verify_signature` recomputes the digest before checking the
  signature (mod.rs:103-123).
- **Tier boundaries.** Tier2 engine changes may not touch `tests`, `src/evaluator`, `src/isolation`,
  `src/ledger`, `.rsi/holdouts`, `CONSTITUTION.md`, `LICENSE` (src/meta/tier.rs:34-42).

## Gaps found (must close before M5 can pass)

| id | gap | evidence | consequence |
|---|---|---|---|
| R1 | The signed receipt digest covers `cycle_id`, `candidate_id`, `parent_id`, `admitted` and the layer results only. It does not cover the candidate's content digest, the holdout set digest or the evaluator version. | evaluator/mod.rs:48-68 | A valid receipt can be paired with different patch bytes. Done-condition (c) cannot be checked from the receipt alone. |
| R2 | In the daemon, the judge's signing key is read from `signing_key_hex` in the RSI config, inside the same process that proposes. The signature label says `tpm2-p256` but the key is a software key. | daemon.rs:54-61, evaluator/mod.rs:100 | The proposer can sign its own scores. This breaks the directive's rule that RSI has no authority over its own verification. |
| R3 | The promotion safety envelope runs with an empty probe (`|| async { Ok(()) }`) and a policy digest hashed from a fixed string, not from a policy file. | daemon.rs:467-504 | The envelope adds a signature, not evidence. |
| R4 | Promotion swaps RSI's own active generation (`atomic_symlink_swap`) and records it in RSI's own ledger. | daemon.rs:529 | A second effect path beside the daemon ledger. VAC must not use it for the M5 effect. |
| R5 | The VAC task record (`vac-task`) names `task_id`, `repo_commit` and `test_cmd` but not which file may change. The verifier ties the write path to the source pin, not to the task. | interplane provenance/src/testrun.rs:104-130; a retained `task.json` from the M3b slice | A run that edits the test file instead of the code still verifies. This also blocks M5 done-condition (f). Fix lands before M5 as its own verifier change. |

## Proposed design

1. **Objective.** The M3b fixture `fix_the_test` (or a second pinned fixture with a measurable
   objective) with a written objective: holdout pass count, and for a performance task a stated
   metric and unit. The threshold is fixed in a policy file committed before the run; its sha256 goes
   in the bundle.
2. **Holdout.** Lives outside the target repository and outside RSI's writable roots, owned by a
   different OS user or a read-only mount. RSI receives only the judge's verdict, never the holdout
   bytes. The holdout set digest is recorded.
3. **Judge.** The standalone judge binary, run as a separate process with its key file readable only
   by the judge's user (closes R2 for this lane). Its public key is pinned in the verifier's trust
   input, supplied by the operator, not read from the bundle.
4. **Receipt binding (closes R1).** A receipt version 2 whose digest also covers `subject_sha256`
   (the exact bytes proposed), `holdout_set_sha256`, `policy_sha256` and `evaluator_version`. Version
   1 receipts stay verifiable but cannot satisfy M5. This changes a signed format in spark-rsi, so
   it needs Drake's approval before merge (directive: no unapproved schema or security changes).
5. **Effect.** The winning candidate goes to INTERPLANE as a `write_file` proposal on the fixture
   repository and through ComposeApprovedProposal with the normal operator approval. RSI's
   `atomic_symlink_swap` and the R3 envelope are not used in this lane (R4).
6. **Verifier.** A new optional bundle section `evaluation`, binding `rsi-eval/2`: the verifier checks
   the P-256 signature against the operator-pinned key, `subject_sha256` equals the grant's
   `content_sha256`, `policy_sha256` equals the retained policy file, and the score meets the
   policy's threshold. New refusal codes: `evaluation_missing`, `evaluation_signature_bad`,
   `evaluation_subject_mismatch`, `evaluation_below_threshold`.
7. **Rollback.** A second approved `write_file` that restores the source pin's bytes, with its own
   ledger records; the rollback test checks the file digest equals the pinned prior digest.
8. **Negative tests.** (a) RSI proposes a change to a holdout or policy file: refused before any
   proposal reaches the daemon, and the verifier refuses a bundle that writes outside the task's
   target (needs R5). (b) A receipt for different bytes: `evaluation_subject_mismatch`. (c) A receipt
   signed by RSI's own key: `evaluation_signature_bad`.

## Decision needed from Drake before build

Receipt version 2 (item 4) changes what spark-rsi signs. It is additive (version 1 still verifies),
but it is a signed-format change and needs an explicit yes. Everything else in this note uses
existing paths.

## Done conditions

Unchanged from PLAN.md section D, row M5, items (a) to (f).
