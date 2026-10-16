#!/usr/bin/env bash
# 23: hostile coordination-store files get a bounded, named refusal (aien-architecture#234, synapse#58). On a clone:
# a FIFO record, a record symlinked to /dev/zero, an oversize record, a directory planted as .lock and a symlinked
# directory under dirs/ are each refused (exit 4, REFUSED_RECORD) without hanging, without unbounded reads and
# without replacing the planted file; moving the file aside restores normal operation. Every crumb run here is under
# a watchdog (background kill after W seconds, default 10) and a 1 GiB address-space limit. Records refusal latency.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
unset CRUMB_EXPECT_STORE_ID CRUMB_STRICT_STORE_ID
W=${W:-10}
proof_begin 23 "hostile store files are refused, bounded, never replaced" "${1:-}"
clone_repo "$TMP/a"
L=$(leaf_crumb_dir "$TMP/a") || L=docs
STORE=$(git -C "$TMP/a" rev-parse --absolute-git-dir)/crumb/v1
num "target=$L"; num "watchdog=${W}s"
CR=$(command -v "$CRUMB" || echo "$CRUMB")
bounded() {   # bounded <label> <crumb args...> -> like measure, plus HUNG=1 if the watchdog killed it
  local l=$1; shift
  local t0 t1 pid wd o="$TMP/bounded.out"; rm -f "$o.hung"; t0=$(now_ms)
  ( cd "$TMP/a" && ulimit -v 1048576 && exec "$CR" "$@" ) > "$o" 2>&1 < /dev/null &
  pid=$!
  ( n=0; while kill -0 "$pid" 2>/dev/null; do n=$((n + 1)); if [ "$n" -gt $((W * 10)) ]; then : > "$o.hung"; kill -9 "$pid" 2>/dev/null; exit 0; fi; sleep 0.1; done ) &
  wd=$!
  wait "$pid"; RC=$?; t1=$(now_ms); wait "$wd" 2>/dev/null
  MS=$((t1 - t0)); HUNG=0; [ -e "$o.hung" ] && HUNG=1; OUT=$(cat "$o")
  echo "  MEASURE $l: ${MS} ms (rc=$RC hung=$HUNG)"; NUMBERS="$NUMBERS $l=${MS}ms"
}

cd "$TMP/a" || exit 1
$CRUMB claim agent-A . "$L" "proof 23: seed the store" 600 >/dev/null 2>&1
REC=$(find "$STORE/dirs" -name "*.json" -type f | sort | head -1); note "record: ${REC#$STORE/}"
mv "$REC" "$TMP/aside.json"; mkfifo "$REC"
bounded fifo_sniff sniff agent-B .
check "FIFO record: sniff refused (exit 4), no hang" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check "refusal names REFUSED_RECORD and the fifo" grep -q 'REFUSED_RECORD: .* is a fifo' <<<"$OUT"; note "$(echo "$OUT" | grep REFUSED | head -1 | cut -c1-140)"
bounded fifo_claim claim agent-B . "$L" "proof 23" 600
check "FIFO record: claim refused (exit 4), no hang" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check "FIFO left in place" [ -p "$REC" ]
rm -f "$REC"; ln -s /dev/zero "$REC"
bounded zero_sniff sniff agent-B .
check "record symlinked to /dev/zero: refused (exit 4), no unbounded read" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check "refusal names the symbolic link" grep -q 'is a symbolic link' <<<"$OUT"
rm -f "$REC"; { printf '{"schema_version": "1.0.0", "directory": "x", "pad": "'; head -c 1100000 /dev/zero | tr '\0' x; printf '"}\n'; } > "$REC"
s0=$(cksum < "$REC")
bounded oversize_sniff sniff agent-B .
check "oversize record (> 1 MiB): refused (exit 4)" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check "refusal names the 1 MiB cap" grep -q 'is larger than 1048576 bytes' <<<"$OUT"
check_eq "oversize record byte-identical after the refusal" "$(cksum < "$REC")" "$s0"
rm -f "$REC"; mv "$TMP/aside.json" "$REC"
rm -f "$STORE/.lock"; mkdir "$STORE/.lock"
bounded lockdir_claim claim agent-B . README-proof23 "proof 23" 600
check "directory planted as .lock: named refusal (exit 4)" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check "refusal names .lock as a directory" grep -q '\.lock is a directory' <<<"$OUT"
rmdir "$STORE/.lock"
mkdir -p "$TMP/outside"; ln -s "$TMP/outside" "$STORE/dirs/evil"
bounded symdir_claim claim agent-B . evil/sub/f.c "proof 23" 600
check "record path through a symlinked directory: refused (exit 4)" [ "$HUNG" -eq 0 -a "$RC" -eq 4 ]
check_eq "nothing written outside the store" "$(ls -A "$TMP/outside" | wc -l)" 0
rm -f "$STORE/dirs/evil"
bounded restored_claim claim agent-B . README-proof23 "proof 23: after moving files aside" 600
check "after moving the hostile files aside the store works again (rc 0)" [ "$HUNG" -eq 0 -a "$RC" -eq 0 ]
bounded restored_sniff sniff agent-B .
check "sniff shows agent-A's original lock again" grep -q "held by agent-A" <<<"$OUT"
$CRUMB close agent-A . "$L" modify "proof 23 done" >/dev/null 2>&1; $CRUMB close agent-B . README-proof23 modify done >/dev/null 2>&1
proof_end
