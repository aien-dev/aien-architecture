#!/usr/bin/env bash
# 20: scripts/rebase-crumb.sh keeps source changes and leaves crumbs CURRENT, with no GitHub. A local bare
# repository stands in for origin (the script requires an aien-dev URL; url.insteadOf redirects it to the bare
# repo). Branch feat changes a leaf file and commits its compiled crumbs; main then moves with a change in
# another subtree, also compiled, so the root .crumb (and any shared ancestor) conflicts in .crumb only.
# Expected: exit 0, feat's source change kept, main's change present, `crumb verify` OK, crumb commit last, pushed.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 20 "rebase-crumb.sh on a local bare origin keeps source and leaves crumbs CURRENT" "${1:-}"
RB=${REBASE_CRUMB:-$here/../rebase-crumb.sh}; [ -x "$RB" ] || { echo "rebase-crumb.sh not found at $RB" >&2; exit 2; }
FAKEURL="https://github.com/aien-dev/proof-repo"
clone_repo "$TMP/seed"; git -C "$TMP/seed" checkout -q -B main
git clone -q --bare "$TMP/seed" "$TMP/origin.git"
git clone -q "$TMP/origin.git" "$TMP/w"; W=$TMP/w
git clone -q "$TMP/origin.git" "$TMP/other"; O=$TMP/other
for r in "$W" "$O"; do git -C "$r" config user.name proof; git -C "$r" config user.email proof@example.invalid; done

L1=$(leaf_crumb_dir "$W") || { echo "no leaf crumb dir" >&2; exit 1; }
F1=$(tracked_file_in "$W" "$L1")
# a second subtree sharing only the root with L1
L2=""; for d in $(crumb_dirs "$W" | grep -v '^\.$' | awk -F/ '{print NF" "$0}' | sort -rn | cut -d' ' -f2); do
  case "$L1/" in "$d"/*) continue ;; esac; case "$d/" in "$L1"/*) continue ;; esac
  F2=$(tracked_file_in "$W" "$d"); [ -n "$F2" ] || continue; L2=$d; break
done
[ -n "$L2" ] || { F2=README.md; L2=.; }
num "feat_file=$F1"; num "main_file=$F2"

# feat: source change + compiled crumbs as the last commit, pushed
git -C "$W" checkout -q -b feat
printf '\n# proof 20 FEAT MARKER\n' >> "$W/$F1"; git -C "$W" commit -qam "feat: change $F1"
( cd "$W" && $CRUMB compile . >/dev/null ); git -C "$W" add -A; git -C "$W" commit -qm "crumb compile"
git -C "$W" push -q origin feat
git -C "$W" remote set-url origin "$FAKEURL"; git -C "$W" config "url.$TMP/origin.git.insteadOf" "$FAKEURL"
git -C "$W" checkout -q main

# main moves: change in another subtree, compiled, pushed
printf '\n# proof 20 MAIN MARKER\n' >> "$O/$F2"; git -C "$O" commit -qam "main: change $F2"
( cd "$O" && $CRUMB compile . >/dev/null ); git -C "$O" add -A; git -C "$O" commit -qm "crumb compile (main)"
git -C "$O" push -q origin main
MAINSHA=$(git -C "$O" rev-parse HEAD)
check "root .crumb differs between feat and new main (a crumb conflict exists)" sh -c "! git -C '$O' diff --quiet origin/feat origin/main -- .crumb"

measure rebase_crumb "$RB" "$W" feat
note "$(echo "$OUT" | tail -1 | cut -c1-120)"
check_eq "rebase-crumb.sh exits 0" "$RC" 0
check "feat's source change survived" grep -q 'proof 20 FEAT MARKER' "$W/$F1"
check "main's change is present" grep -q 'proof 20 MAIN MARKER' "$W/$F2"
check_eq "feat now sits on the new main" "$(git -C "$W" merge-base HEAD origin/main)" "$MAINSHA"
( cd "$W" && measure verify_after $CRUMB verify . ); check "crumb verify OK after rebase" sh -c "cd '$W' && $CRUMB verify . >/dev/null"
check_eq "nothing STALE after rebase" "$(stale_set "$W")" ""
LAST=$(git -C "$W" diff-tree --no-commit-id --name-only -r HEAD | grep -vc '\.crumb$' || true)
check_eq "last commit touches only .crumb files" "$LAST" 0
check_eq "pushed: origin/feat == local feat" "$(git -C "$TMP/origin.git" rev-parse refs/heads/feat)" "$(git -C "$W" rev-parse HEAD)"
check_eq "working tree clean" "$(git -C "$W" status --porcelain | wc -l)" 0
num "crumbs_rewritten_by_rebase=$(git -C "$W" diff-tree --no-commit-id --name-only -r HEAD | grep -c '\.crumb$')"
proof_end
