#!/usr/bin/env bash
# 17: two worktrees cannot hold conflicting active claims. Agent A claims a target from worktree 1;
# agent B's claim on the same target from a linked worktree 2 exits 2 (BLOCKED); B may claim another
# target; after A closes, B's claim on the first target succeeds. Records claim/close latency.
# The coordination plane is the clone's own common git dir, so nothing touches the real repository's store.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 17 "claims are exclusive across linked worktrees" "${1:-}"
clone_repo "$TMP/a"
git -C "$TMP/a" worktree add -q "$TMP/wt2" -b proof17-other || { echo "worktree add failed" >&2; exit 1; }
L=$(leaf_crumb_dir "$TMP/a") || L=docs
OTHER=$(crumb_dirs "$TMP/a" | grep -v '^\.$' | grep -v "^$L\$" | head -1); [ -n "$OTHER" ] || OTHER=README.md
num "target=$L"; num "other_target=$OTHER"

cd "$TMP/a" || exit 1
measure claim_A $CRUMB claim agent-A . "$L" "proof 17: agent A" 600
check "A claims $L from worktree 1 (rc 0)" [ "$RC" -eq 0 ]; check "A's claim prints CLAIMED" grep -q '^CLAIMED' <<<"$OUT"
cd "$TMP/wt2" || exit 1
measure claim_B_conflict $CRUMB claim agent-B . "$L" "proof 17: agent B" 600
check_eq "B's claim on the same target from worktree 2 exits 2" "$RC" 2
check "B's refusal names the holder" grep -q 'BLOCKED .*held by agent-A' <<<"$OUT"; note "$(echo "$OUT" | head -1 | cut -c1-120)"
measure sniff_B $CRUMB sniff agent-B .
check "sniff from worktree 2 shows A's lock" grep -q 'agent-A' <<<"$OUT"
measure claim_B_other $CRUMB claim agent-B . "$OTHER" "proof 17: agent B elsewhere" 600
check "B claims a different target (rc 0)" [ "$RC" -eq 0 ]
cd "$TMP/a" || exit 1
measure close_A $CRUMB close agent-A . "$L" modify "proof 17: A done"
check "A closes (rc 0)" [ "$RC" -eq 0 ]
cd "$TMP/wt2" || exit 1
measure claim_B_after_close $CRUMB claim agent-B . "$L" "proof 17: agent B after A closed" 600
check "B claims the released target (rc 0)" [ "$RC" -eq 0 ]
$CRUMB close agent-B . "$L" modify "proof 17: B done" >/dev/null; $CRUMB close agent-B . "$OTHER" modify "proof 17: B done" >/dev/null
check_eq "no locks remain" "$($CRUMB list . | grep -ci 'lock.*agent-' || true)" 0
check_eq "git status in both worktrees untouched by claims" "$(git -C "$TMP/a" status --porcelain | wc -l)$(git -C "$TMP/wt2" status --porcelain | wc -l)" "00"
proof_end
