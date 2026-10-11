#!/usr/bin/env bash
# 21: the final SHA (source commit + separate crumb commit) differs from the pre-crumb SHA, and
# `crumb verify` passes only on the final one: FAIL (exit 1) at the pre-crumb commit, OK (exit 0) at the final.
# The pre-crumb commit is re-checked in its own detached worktree after the final commit exists.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 21 "final SHA = source + crumb commit is the only one that verifies" "${1:-}"
clone_repo "$TMP/a"; cd "$TMP/a" || exit 1
L=$(leaf_crumb_dir .) || { echo "no leaf crumb dir" >&2; exit 1; }
F=$(tracked_file_in . "$L")
S0=$(git rev-parse HEAD)
printf '\n# proof 21 source change\n' >> "$F"; git commit -qam "source change in $L"
S1=$(git rev-parse HEAD); num "pre_crumb_sha=${S1:0:12}"
check "pre-crumb commit differs from the base" [ "$S1" != "$S0" ]
measure verify_pre_crumb $CRUMB verify .; check_eq "verify at the pre-crumb SHA exits 1" "$RC" 1
note "$(echo "$OUT" | tail -1)"
measure compile $CRUMB compile .
RW=$(echo "$OUT" | tail -1 | sed -n 's/.*crumbs, \([0-9]*\) rewritten.*/\1/p'); num "crumbs_rewritten=$RW"
check_eq "compile changed only .crumb files" "$(git status --porcelain | grep -vc '\.crumb$' || true)" 0
git add -A && git commit -qm "crumb compile"
S2=$(git rev-parse HEAD); num "final_sha=${S2:0:12}"
check "final SHA differs from the pre-crumb SHA" [ "$S2" != "$S1" ]
check_eq "the crumb commit touches only .crumb files" "$(git diff-tree --no-commit-id --name-only -r HEAD | grep -vc '\.crumb$' || true)" 0
measure verify_final $CRUMB verify .; check_eq "verify at the final SHA exits 0" "$RC" 0
note "$(echo "$OUT" | tail -1)"
git worktree add -q --detach "$TMP/pre" "$S1"
( cd "$TMP/pre" && measure verify_pre_crumb_again $CRUMB verify . ); check_eq "verify at the pre-crumb SHA still exits 1 (own worktree)" "$(cd "$TMP/pre" && $CRUMB verify . >/dev/null 2>&1; echo $?)" 1
git worktree add -q --detach "$TMP/fin" "$S2"
check_eq "verify at the final SHA exits 0 in a fresh worktree" "$(cd "$TMP/fin" && $CRUMB verify . >/dev/null 2>&1; echo $?)" 0
proof_end
