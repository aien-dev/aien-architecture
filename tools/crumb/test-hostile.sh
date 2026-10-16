#!/bin/sh
# Hostile coordination-store files and registered store identity (aien-architecture#234; synapse#58, synapse#15).
# usage: sh test-hostile.sh ./crumb [watchdog_seconds]. Scratch directories only.
# Every crumb run goes through run(): a background watchdog kills the child after W seconds (default 5) and the
# child runs under a 1 GiB address-space limit, so a tool that blocks on a FIFO shows up as HUNG and a tool that
# reads /dev/zero without bound shows up as out of memory, instead of stalling or exhausting the machine.
# Exit codes checked: 3 = store identity refusal, 4 = refused store file (hostile record).
C=${1:-./crumb}; C=$(cd "$(dirname "$C")" && pwd)/$(basename "$C")
W=${2:-5}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
unset CRUMB_COORD_ROOT CRUMB_EXPECT_STORE_ID CRUMB_STRICT_STORE_ID
fail=0; ok() { echo "PASS $1"; }; bad() { echo "FAIL $1"; fail=1; }

run() {   # run <dir> <command...>  -> RC, OUT (stdout+stderr), HUNG=1 if the watchdog had to kill it
  d=$1; shift
  o="$T/run.out"; rm -f "$o" "$o.hung"
  ( cd "$d" && ulimit -v 1048576 && exec "$@" ) > "$o" 2>&1 < /dev/null &
  pid=$!
  ( n=0; while kill -0 "$pid" 2>/dev/null; do n=$((n + 1)); if [ "$n" -gt $((W * 10)) ]; then : > "$o.hung"; kill -9 "$pid" 2>/dev/null; exit 0; fi; sleep 0.1; done ) &
  wd=$!
  wait "$pid"; RC=$?
  wait "$wd" 2>/dev/null
  HUNG=0; [ -e "$o.hung" ] && HUNG=1
  OUT=$(cat "$o")
}
refused() {   # refused <exit-code> <grep-pattern>: bounded refusal with that code and message
  [ "$HUNG" -eq 0 ] && [ "$RC" -eq "$1" ] && printf '%s\n' "$OUT" | grep -q "$2"
}
why() { echo "    (rc=$RC hung=$HUNG) $(printf '%s' "$OUT" | head -2 | cut -c1-160)"; }
mk() {   # mk <name>: repo $T/<name> + linked worktree $T/<name>-wt; sets R, WT, STORE
  R="$T/$1"; WT="$T/$1-wt"; mkdir -p "$R/src"
  (cd "$R" && git init -q -b main . && echo a > src/a.c && echo b > src/b.c && git add -A && git -c user.name=t -c user.email=t@t commit -qm init && git worktree add -q -b wt "$WT") >/dev/null 2>&1
  STORE="$R/.git/crumb/v1"
}
sum() { find "$1" -type f -exec cksum {} + 2>/dev/null | sort; }

echo "crumb under test: $C (watchdog ${W}s, 1 GiB limit)"
# ---- H: hostile store files (bounded refusal: no hang, no OOM, nothing replaced) ----
mk h1; run "$R" "$C" claim a src a.c x
rm -f "$STORE/dirs/src.json"; mkfifo "$STORE/dirs/src.json"
run "$R" "$C" sniff b src
refused 4 'REFUSED_RECORD: .*dirs/src.json is a fifo' && ok "H1 FIFO dirs/src.json: sniff refused (exit 4), no hang" || { why; bad "H1 FIFO dirs record sniff"; }
run "$WT" "$C" claim b src b.c y
refused 4 'dirs/src.json is a fifo' && ok "H1 FIFO dirs/src.json: claim from linked worktree refused, no hang" || { why; bad "H1 FIFO dirs record claim"; }
[ -p "$STORE/dirs/src.json" ] && ok "H1 FIFO left in place (never replaced)" || bad "H1 FIFO replaced"

mk h2; run "$R" "$C" claim a src a.c x
mkfifo "$STORE/agents/planted.json"
run "$R" "$C" claim c src b.c y
refused 4 'agents/planted.json is a fifo' && ok "H2 FIFO agents/*.json: claim refused, no hang" || { why; bad "H2 FIFO agent record"; }

mk h3; run "$R" "$C" claim a src a.c x
rm -f "$STORE/dirs/src.json"; ln -s /dev/zero "$STORE/dirs/src.json"
run "$R" "$C" sniff b src
refused 4 'dirs/src.json is a symbolic link' && ok "H3 symlink dirs/src.json -> /dev/zero: refused, no unbounded read" || { why; bad "H3 /dev/zero dirs record"; }
[ "$(readlink "$STORE/dirs/src.json")" = /dev/zero ] && ok "H3 symlink left as found" || bad "H3 symlink changed"

mk h4; run "$R" "$C" claim a src a.c x
ln -s /dev/zero "$STORE/agents/zero.json"
run "$R" "$C" claim c src b.c y
refused 4 'agents/zero.json is a symbolic link' && ok "H4 symlink agents/*.json -> /dev/zero: claim refused" || { why; bad "H4 /dev/zero agent record"; }

mk h5; run "$R" "$C" claim a src a.c x
pad() { printf '{"schema_version": "1.0.0", "directory": "%s", "pad": "' "$1"; head -c "$2" /dev/zero | tr '\0' x; printf '"}\n'; }
pad big 1048600 > "$STORE/dirs/big.json"; s0=$(cksum < "$STORE/dirs/big.json")
run "$R" "$C" sniff b src
refused 4 'dirs/big.json is larger than 1048576 bytes' && ok "H5 oversize record (> 1 MiB) refused" || { why; bad "H5 oversize record"; }
[ "$(cksum < "$STORE/dirs/big.json")" = "$s0" ] && ok "H5 oversize record left byte-identical" || bad "H5 oversize rewritten"
n=$((1048576 - $(pad edge 0 | wc -c))); pad edge "$n" > "$STORE/dirs/big.json"
run "$R" "$C" sniff b src
[ "$(wc -c < "$STORE/dirs/big.json")" -eq 1048576 ] && [ "$HUNG" -eq 0 ] && [ "$RC" -eq 0 ] && ok "H5 record of exactly 1 MiB still accepted (cap is inclusive)" || { why; bad "H5 1 MiB boundary"; }

mk h6; run "$R" "$C" claim a src a.c x
rm -f "$STORE/.lock"; mkdir "$STORE/.lock"
run "$R" "$C" claim b src b.c y
refused 4 'REFUSED_RECORD: .*\.lock is a directory' && [ -d "$STORE/.lock" ] && ok "H6 directory planted as .lock: named refusal, left in place" || { why; bad "H6 .lock directory"; }

mk h7; run "$R" "$C" claim a src a.c x
rm -f "$STORE/.lock"; mkfifo "$STORE/.lock"
run "$R" "$C" claim b src b.c y
refused 4 '\.lock is a fifo' && [ -p "$STORE/.lock" ] && ok "H7 FIFO planted as .lock: refused, no hang" || { why; bad "H7 .lock FIFO"; }

mk h8; run "$R" "$C" claim a src a.c x
rm -f "$STORE/.lock"; ln -s "$T/h8-elsewhere" "$STORE/.lock"
run "$R" "$C" claim b src b.c y
refused 4 '\.lock is a symbolic link' && [ ! -e "$T/h8-elsewhere" ] && ok "H8 symlinked .lock: refused, link target never created" || { why; bad "H8 .lock symlink"; }

mk h9; run "$R" "$C" claim a src a.c x
mkdir -p "$T/h9-outside"
printf '{"schema_version": "1.0.0", "directory": "evil/x", "locks": {"evil/x/f.c": {"holder": "outside-holder", "acquired_at": "%s", "ttl_seconds": 3600}}}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$T/h9-outside/x.json"
ln -s "$T/h9-outside" "$STORE/dirs/evil"; o0=$(sum "$T/h9-outside")
run "$R" "$C" sniff b src
[ "$HUNG" -eq 0 ] && [ "$RC" -eq 0 ] && ! printf '%s\n' "$OUT" | grep -q outside-holder && ok "H9 symlinked directory under dirs/ is not walked (its records stay invisible)" || { why; bad "H9 collect_json followed a symlinked directory"; }
run "$R" "$C" claim b . evil/x/g.c y
refused 4 'dirs/evil is a symbolic link' && [ "$(sum "$T/h9-outside")" = "$o0" ] && ok "H9 record path through a symlinked directory refused, nothing written outside the store" || { why; bad "H9 write through symlinked directory"; }

mk h10; run "$R" "$C" claim a src a.c x
rm -f "$STORE/STORE_ID"; mkfifo "$STORE/STORE_ID"
run "$R" "$C" sniff b src
refused 4 'STORE_ID is a fifo' && [ -p "$STORE/STORE_ID" ] && ok "H10 FIFO planted as STORE_ID: refused, no hang, left in place" || { why; bad "H10 STORE_ID FIFO"; }

mk h11; run "$R" "$C" claim a src a.c x
printf 'hello\n' > "$STORE/STORE_ID"
run "$R" "$C" claim b src b.c y
refused 3 'STORE_ID_UNREADABLE: .*STORE_ID is not a store identity marker' && [ "$(cat "$STORE/STORE_ID")" = hello ] && ok "H11 foreign STORE_ID content refused (exit 3), never rewritten" || { why; bad "H11 foreign STORE_ID"; }

mk h12; run "$R" "$C" claim a src a.c x
mkdir -p "$STORE/continuations"; mkfifo "$STORE/continuations/cc-fifo.json"
run "$R" "$C" explain src
refused 4 'continuations/cc-fifo.json is a fifo' && ok "H12 FIFO in continuations/: explain refused, no hang" || { why; bad "H12 continuation FIFO"; }

# ---- S: registered store identity (fail closed; compatibility mode; strict mode) ----
mk s1; run "$R" "$C" claim a src a.c x
grep -Eqx 'crumb-coord-store-id/1 [0-9a-f]{32}' "$STORE/STORE_ID" 2>/dev/null && [ "$(wc -c < "$STORE/STORE_ID")" -eq 56 ] && ok "S1 compatibility: first mutation of an unregistered store writes the synapse-coord marker format" || { why; bad "S1 marker not created"; }
ID=$(cut -d' ' -f2 "$STORE/STORE_ID" 2>/dev/null)
run "$R" "$C" sniff a src
[ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q "STORE_UNREGISTERED (dry run).*git config crumb.storeId $ID" && ok "S1 compatibility: unregistered store with a marker works and warns (dry run)" || { why; bad "S1 dry-run warning"; }
git -C "$R" config crumb.storeId "$ID"
run "$WT" "$C" claim b src a.c y
refused 2 "BLOCKED src/a.c held by a" && ! printf '%s\n' "$OUT" | grep -q STORE_UNREGISTERED && ok "S2 registered correct root: linked worktree sees the same holder, no warning" || { why; bad "S2 registered root"; }
run "$WT" "$C" --strict claim b src b.c y
[ "$RC" -eq 0 ] && ok "S2 strict mode accepts the registered correct root" || { why; bad "S2 strict on registered root"; }

mk s3w; run "$R" "$C" claim w src a.c "other store"; WRONG=$STORE; w0=$(sum "$WRONG")
mk s3; git -C "$R" config crumb.storeId "${ID:-00000000000000000000000000000000}"
run "$R" env CRUMB_COORD_ROOT="$WRONG" "$C" claim a src b.c y
refused 3 "STORE_ID_MISMATCH: coordination store $WRONG is store .*, expected ${ID:-0}" && [ "$(sum "$WRONG")" = "$w0" ] && ok "S3 deliberately wrong registered root refused (exit 3), its files unchanged" || { why; bad "S3 wrong root"; }
run "$R" env CRUMB_COORD_ROOT="$WRONG" "$C" sniff a src
refused 3 STORE_ID_MISMATCH && ok "S3 read-only sniff refuses the wrong root too" || { why; bad "S3 sniff wrong root"; }

run "$R" env CRUMB_COORD_ROOT="$T/s4-none/crumb/v1" "$C" claim a src a.c x
refused 3 'STORE_ID_MISSING: .*has no STORE_ID marker' && [ ! -e "$T/s4-none" ] && ok "S4 registered id but missing root: refused, nothing created" || { why; bad "S4 missing root"; }
mkdir -p "$T/s4-bare/dirs"
run "$R" env CRUMB_COORD_ROOT="$T/s4-bare" "$C" claim a src a.c x
refused 3 STORE_ID_MISSING && [ ! -e "$T/s4-bare/STORE_ID" ] && [ ! -e "$T/s4-bare/.lock" ] && ok "S4 registered id, store without marker: refused, marker never created" || { why; bad "S4 missing marker"; }

mk s5; run "$R" env CRUMB_STRICT_STORE_ID=1 "$C" claim a src a.c x
refused 3 'STORE_UNREGISTERED' && [ ! -e "$STORE" ] && ok "S5 strict (CRUMB_STRICT_STORE_ID=1) refuses an unregistered root, creates nothing" || { why; bad "S5 strict env"; }
run "$R" "$C" --strict sniff a src
refused 3 'STORE_UNREGISTERED' && ok "S5 strict (--strict) refuses an unregistered root on read too" || { why; bad "S5 strict flag"; }

mk s6; run "$R" "$C" claim a src a.c x; ID6=$(cut -d' ' -f2 "$STORE/STORE_ID" 2>/dev/null)
git -C "$R" config crumb.storeId "${ID6:-x}"
run "$R" env CRUMB_EXPECT_STORE_ID=0123456789abcdef0123456789abcdef "$C" sniff a src
refused 3 'STORE_ID_MISMATCH' && ok "S6 CRUMB_EXPECT_STORE_ID overrides git config crumb.storeId" || { why; bad "S6 env precedence"; }
run "$R" env CRUMB_EXPECT_STORE_ID=0123456789ABCDEF0123456789ABCDEF "$C" sniff a src
refused 3 'STORE_ID_CONFIG_INVALID' && ok "S6 malformed expected id refused (exit 3)" || { why; bad "S6 invalid id"; }
run "$R" "$C" store-id src
[ "$RC" -eq 0 ] && [ "$(printf '%s\n' "$OUT" | head -1)" = "${ID6:-x}" ] && ok "S6 store-id prints the registered id" || { why; bad "S6 store-id"; }

echo "hostile/identity: $( [ $fail -eq 0 ] && echo ALL PASS || echo FAILURES )"
exit $fail
