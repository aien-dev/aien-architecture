#!/usr/bin/env bash
# 14: fixed point. A second compile changes nothing: "0 rewritten", `git status --porcelain` empty,
# and every .crumb byte-for-byte as before. Checked at HEAD (crumbs already CURRENT) and from nothing.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 14 "fixed point: the second compile rewrites nothing" "${1:-}"
clone_repo "$TMP/a"; cd "$TMP/a" || exit 1
rewritten() { echo "$1" | tail -1 | sed -n 's/.*crumbs, \([0-9]*\) rewritten.*/\1/p'; }
crumb_sum() { git ls-files '*.crumb' '**/.crumb' | sort | xargs cat | sha256sum | cut -c1-16; }

# (a) at HEAD: the committed crumbs are already what compile would write
measure compile_at_head $CRUMB compile .; note "$(echo "$OUT" | tail -1)"
check_eq "compile at HEAD rewrites 0" "$(rewritten "$OUT")" 0
check_eq "git status --porcelain is empty after compile at HEAD" "$(git status --porcelain | wc -l)" 0

# (b) from nothing: strip, compile once (n rewritten), compile again (0 rewritten, bytes unchanged)
for c in $(git ls-files '*.crumb' '**/.crumb'); do jq 'del(.extensions.generated)' "$c" > "$c.tmp" && mv "$c.tmp" "$c"; done
measure compile_1_from_nothing $CRUMB compile .; N1=$(rewritten "$OUT"); num "first_compile_rewritten=$N1"
check_eq "first compile regenerated every crumb" "$N1" "$(crumb_dirs . | wc -l)"
S1=$(crumb_sum); P1=$(git status --porcelain | sort | sha256sum | cut -c1-16)
measure compile_2 $CRUMB compile .; N2=$(rewritten "$OUT"); num "second_compile_rewritten=$N2"
check_eq "second compile rewrites 0" "$N2" 0
check_eq "second compile leaves every .crumb byte-identical" "$(crumb_sum)" "$S1"
check_eq "second compile leaves git status unchanged" "$(git status --porcelain | sort | sha256sum | cut -c1-16)" "$P1"
git add -A && git commit -q -m "crumb compile (proof 14)"
measure compile_3_after_commit $CRUMB compile .; check_eq "compile after committing rewrites 0" "$(rewritten "$OUT")" 0
check_eq "git status --porcelain empty after the crumb commit + compile" "$(git status --porcelain | wc -l)" 0
measure verify $CRUMB verify .; check "verify OK at the fixed point" [ "$RC" -eq 0 ]
proof_end
