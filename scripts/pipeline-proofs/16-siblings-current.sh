#!/usr/bin/env bash
# 16: unchanged siblings stay CURRENT. After one leaf change, every crumb outside the changed directory's
# ancestor chain reports CURRENT in `crumb status`, and a second change in a different subtree stales only
# its own chain (the two chains share only the root).
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 16 "unchanged siblings stay CURRENT" "${1:-}"
clone_repo "$TMP/a"; cd "$TMP/a" || exit 1
L=$(leaf_crumb_dir .) || { echo "no leaf crumb directory with a tracked file" >&2; exit 1; }
F=$(tracked_file_in . "$L")
TOTAL=$(crumb_dirs . | wc -l)
printf '\n# proof 16 touch\n' >> "$F"; git add -- "$F"
CHAIN=$(ancestors_with_crumbs . "$L")
measure status $CRUMB status .
CUR=$(echo "$OUT" | awk '$1=="CURRENT"{print $2}' | sort)
STALE=$(echo "$OUT" | awk '$1=="STALE"{print $2}' | sort)
num "current=$(echo "$CUR" | grep -c .)"; num "stale=$(echo "$STALE" | grep -c .)"; num "total=$TOTAL"
check_eq "CURRENT + STALE = every crumb" "$(( $(echo "$CUR" | grep -c .) + $(echo "$STALE" | grep -c .) ))" "$TOTAL"
outside=0; for d in $CUR; do case " $CHAIN " in *" $d "*) ;; *) outside=$((outside+1)) ;; esac; done
num "siblings_current=$outside"
check_eq "every crumb outside the chain is CURRENT" "$outside" "$((TOTAL - $(echo "$CHAIN" | wc -w)))"
for d in $STALE; do case " $CHAIN " in *" $d "*) ;; *) echo "  FAIL $d is STALE but not in the chain"; FAILS=$((FAILS+1)) ;; esac; done

# second change in a different subtree: pick a crumb dir sharing only the root with the first chain
L2=""
for d in $(crumb_dirs . | grep -v '^\.$' | awk -F/ '{print NF" "$0}' | sort -rn | cut -d' ' -f2); do
  case " $CHAIN " in *" $d "*) continue ;; esac
  case "$L/" in "$d"/*) continue ;; esac
  F2=$(tracked_file_in . "$d"); [ -n "$F2" ] || continue
  L2=$d; break
done
if [ -n "$L2" ]; then
  printf '\n# proof 16 second touch\n' >> "$F2"; git add -- "$F2"
  WANT=$( (echo "$CHAIN" | tr ' ' '\n'; ancestors_with_crumbs . "$L2" | tr ' ' '\n') | sort -u | tr '\n' ' ' | sed 's/ $//')
  check_eq "two changes stale exactly the union of the two chains" "$(stale_set .)" "$WANT"
  num "second_dir=$L2"
else
  note "no second independent subtree with a tracked file; second-change check skipped"
fi
proof_end
