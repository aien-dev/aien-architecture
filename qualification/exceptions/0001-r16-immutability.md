# Exception 0001: R16 merge with failed evidence-immutable check

Status: recorded after the fact. Recorded in the plan 2026-10-01 (Lane 33).

## What happened

Quoted from `CURRENT_EXECUTION_PLAN.md` line 45: "`#112` merged with its `evidence-immutable` check FAILED (run `36799862685`) because `evidence/R16/inventory.json` was edited in place by commits `1edb56b` and `6831117`; the PR did not record this."

Verified with commands on 2026-10-01:
- `gh pr checks 112 -R aien-dev/omega` shows `evidence-immutable  fail` at https://github.com/aien-dev/omega/actions/runs/36799862685/job/110171540034.
- `gh api repos/aien-dev/omega/pulls/112` gives merge commit `3dd5eaa171ea095862f319def757f620380e3afb` and PR head `6831117682cad4f8e2daa191be6377ab21a0d0cc`.
- PR: https://github.com/aien-dev/omega/pull/112.

UNVERIFIED: who approved the merge, and whether the in-place edit changed the meaning of the receipt. This record does not decide either.

## Effect

The R16 receipt is kept as history but its inventory file was mutated after the fact, and it binds candidate `850fc545`, which predates later runtime changes. It must not be used to qualify new code.

## Rule going forward

1. Promotion checks are mandatory. A merge with a failing promotion check is not allowed.
2. Any bypass needs a written exception in this directory, naming the check, run, PR, reason, approver, and effect on evidence, committed before or with the bypass.
3. Evidence is never edited in place. A correction is a new receipt that links to the old one.
