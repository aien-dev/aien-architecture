#!/usr/bin/env bash
# 15: one directory change marks exactly the right crumbs STALE: the changed directory's nearest crumb,
# every ancestor directory that holds a crumb, and the root (RFC-0003 section 3). Checked with `crumb status`.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 15 "one change stales the directory, its crumbed ancestors and the root, nothing else" "${1:-}"
clone_repo "$TMP/a"; cd "$TMP/a" || exit 1
L=$(leaf_crumb_dir .) || { echo "no leaf crumb directory with a tracked file" >&2; exit 1; }
F=$(tracked_file_in . "$L"); num "changed_file=$F"
check_eq "clone starts CURRENT" "$(stale_set .)" ""
printf '\n# proof 15 touch\n' >> "$F"; git add -- "$F"   # D2: tracked working-tree content, staged
WANT=$(ancestors_with_crumbs . "$L")
measure status $CRUMB status .
GOT=$(stale_set .)
check_eq "STALE set is exactly the changed dir + crumbed ancestors + root" "$GOT" "$WANT"
num "stale=$(echo "$GOT" | wc -w)"; num "total=$(crumb_dirs . | wc -l)"
measure verify_stale $CRUMB verify .; check "verify exits 1 while stale" [ "$RC" -eq 1 ]
measure compile $CRUMB compile .
check_eq "compile rewrote exactly the stale set" "$(echo "$OUT" | awk '$1=="COMPILED"{print $2}' | sort | tr '\n' ' ' | sed 's/ $//')" "$WANT"
check_eq "nothing stale after compile" "$(stale_set .)" ""
proof_end
