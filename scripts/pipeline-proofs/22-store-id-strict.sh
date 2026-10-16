#!/usr/bin/env bash
# 22: registered coordination store identity (aien-architecture#234, synapse#15). On a clone with a linked worktree:
# an unregistered store keeps working (compatibility mode) and warns once on stderr; `crumb store-id` gives the id;
# after `git config crumb.storeId <id>` both worktrees agree on one holder; a deliberately wrong registered root and
# a root without a marker are refused (exit 3) before anything is written; strict mode (--strict or
# CRUMB_STRICT_STORE_ID=1) refuses an unregistered root and accepts the registered one. Records claim latency.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
unset CRUMB_EXPECT_STORE_ID CRUMB_STRICT_STORE_ID
proof_begin 22 "registered store identity fails closed; compatibility and strict modes" "${1:-}"
clone_repo "$TMP/a"
git -C "$TMP/a" worktree add -q "$TMP/wt2" -b proof22-other || { echo "worktree add failed" >&2; exit 1; }
L=$(leaf_crumb_dir "$TMP/a") || L=docs
STORE=$(git -C "$TMP/a" rev-parse --absolute-git-dir)/crumb/v1
num "target=$L"
tree_sum() { find "$1" -type f -exec cksum {} + 2>/dev/null | sort | cksum; }

cd "$TMP/a" || exit 1
measure claim_unregistered $CRUMB claim agent-A . "$L" "proof 22: compatibility mode" 600
check "unregistered store: claim works (rc 0)" [ "$RC" -eq 0 ]
check "first mutation wrote STORE_ID in the synapse-coord format" grep -Eqx 'crumb-coord-store-id/1 [0-9a-f]{32}' "$STORE/STORE_ID"
OUT=$($CRUMB sniff agent-A . 2>&1 >/dev/null)
check "unregistered store with a marker: one dry-run line on stderr" grep -q 'STORE_UNREGISTERED (dry run)' <<<"$OUT"
ID=$($CRUMB store-id . 2>/dev/null)
check_eq "store-id prints the marker's id" "$ID" "$(cut -d' ' -f2 "$STORE/STORE_ID")"
git -C "$TMP/a" config crumb.storeId "$ID"

cd "$TMP/wt2" || exit 1
measure claim_registered_conflict $CRUMB claim agent-B . "$L" "proof 22: registered, other worktree" 600
check_eq "registered: linked worktree's claim on the same target exits 2" "$RC" 2
check "registered: both worktrees agree on the holder" grep -q 'BLOCKED .*held by agent-A' <<<"$OUT"
check "registered: no dry-run warning" bash -c '! grep -q STORE_UNREGISTERED <<<"$1"' _ "$OUT"
measure claim_strict_registered $CRUMB --strict claim agent-B . README-proof22 "proof 22: strict, registered" 600
check "strict mode accepts the registered root (rc 0)" [ "$RC" -eq 0 ]

mkdir -p "$TMP/wrong" && (cd "$TMP/wrong" && git init -q . && CRUMB_COORD_ROOT="$TMP/wrong-store" $CRUMB claim w . x "other store" >/dev/null 2>&1)
before=$(tree_sum "$TMP/wrong-store")
measure claim_wrong_root env CRUMB_COORD_ROOT="$TMP/wrong-store" $CRUMB claim agent-B . "$L" "proof 22: wrong root" 600
check_eq "deliberately wrong registered root refused (exit 3)" "$RC" 3
check "refusal is named STORE_ID_MISMATCH" grep -q 'STORE_ID_MISMATCH' <<<"$OUT"; note "$(echo "$OUT" | head -1 | cut -c1-140)"
check_eq "wrong root's files unchanged" "$(tree_sum "$TMP/wrong-store")" "$before"
measure claim_missing_marker env CRUMB_COORD_ROOT="$TMP/no-store/crumb/v1" $CRUMB claim agent-B . "$L" "proof 22: missing" 600
check_eq "registered id, root without marker: refused (exit 3)" "$RC" 3
check "refusal is named STORE_ID_MISSING and nothing was created" bash -c 'grep -q STORE_ID_MISSING <<<"$1" && [ ! -e "$2" ]' _ "$OUT" "$TMP/no-store"

clone_repo "$TMP/b"; cd "$TMP/b" || exit 1
measure claim_strict_unregistered env CRUMB_STRICT_STORE_ID=1 $CRUMB claim agent-C . "$L" "proof 22: strict, unregistered" 600
check_eq "strict mode refuses an unregistered root (exit 3)" "$RC" 3
check "refusal is named STORE_UNREGISTERED and no store was created" bash -c 'grep -q STORE_UNREGISTERED <<<"$1" && [ ! -e "$2" ]' _ "$OUT" "$(git -C "$TMP/b" rev-parse --absolute-git-dir)/crumb"
cd "$TMP/a" || exit 1
$CRUMB close agent-A . "$L" modify "proof 22 done" >/dev/null 2>&1; (cd "$TMP/wt2" && $CRUMB close agent-B . README-proof22 modify done >/dev/null 2>&1)
check_eq "git status in both worktrees untouched" "$(git -C "$TMP/a" status --porcelain | wc -l)$(git -C "$TMP/wt2" status --porcelain | wc -l)" "00"
proof_end
