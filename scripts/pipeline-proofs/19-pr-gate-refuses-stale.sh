#!/usr/bin/env bash
# 19: missing or stale required crumbs block admission. The real scripts/pr-gate.sh (with a fake `gh` that
# answers from fixtures: open PR, CLEAN, no required contexts) is run with --worktree on a clone whose PR
# branch (a) changed source without recompiling (STALE), (b) deleted a leaf .crumb (MISSING, parent STALE),
# (c) changed source and committed the compiled crumbs as a separate last commit (control: PASS).
# (a) and (b) must stop at "GATE crumb: FAIL"; (c) must pass the crumb gate. Real `crumb`, no network.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 19 "pr-gate.sh refuses stale or missing crumbs" "${1:-}"
GATE=${PR_GATE:-$here/../pr-gate.sh}; [ -x "$GATE" ] || { echo "pr-gate.sh not found at $GATE" >&2; exit 2; }
export SLEEP_SECS=0
clone_repo "$TMP/seed"; git -C "$TMP/seed" checkout -q -B main
git clone -q --bare "$TMP/seed" "$TMP/origin.git"
git clone -q "$TMP/origin.git" "$TMP/w"; W=$TMP/w
git -C "$W" config user.name proof; git -C "$W" config user.email proof@example.invalid
FX="$TMP/fx"; mkdir -p "$FX" "$TMP/bin"; export FX
cat > "$TMP/bin/gh" <<'S'
#!/usr/bin/env bash
d="$FX/$CASE"
case "$1 $2" in
  "pr view") cat "$d/pr.json" ;;
  "pr list") echo '[]' ;;
  api\ repos/*) echo '[]' ;;
  *) echo "fake gh: unhandled: $*" >&2; exit 2 ;;
esac
S
chmod +x "$TMP/bin/gh"; export PATH="$TMP/bin:$PATH"
fx() {   # fx <case> <branch> <sha>
  mkdir -p "$FX/$1"
  printf '{"number":1,"state":"OPEN","isDraft":false,"baseRefName":"main","headRefName":"%s","headRefOid":"%s","mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":"","statusCheckRollup":[]}\n' "$2" "$3" > "$FX/$1/pr.json"
}
L=$(leaf_crumb_dir "$W") || { echo "no leaf crumb dir" >&2; exit 1; }
F=$(tracked_file_in "$W" "$L")
MAIN=main
branch() { git -C "$W" checkout -q -b "$1" "origin/$MAIN"; }
push() { git -C "$W" push -q origin "$1"; git -C "$W" rev-parse HEAD; }

# (a) stale: source change committed without recompiling
branch stale; printf '\n# proof 19 stale\n' >> "$W/$F"; git -C "$W" commit -qam "source change, no crumb compile"
SHA=$(push stale); fx stale stale "$SHA"
export CASE=stale; measure gate_stale "$GATE" proof-repo 1 --worktree "$W" --dry-run
check_eq "stale tree: pr-gate exits 1" "$RC" 1
check "stale tree: stops at GATE crumb: FAIL" grep -q '^GATE crumb: FAIL crumb verify did not print OK' <<<"$OUT"
note "$(grep '^GATE crumb' <<<"$OUT" | cut -c1-110)"

# (b) missing: a .crumb deleted. RFC-0003 D7 (amended 2026-10-11): children[] holds the NEAREST crumbed descendants,
# so every .crumb is reachable from the root digest and any deletion must be refused.
#   (b1) parent holds a crumb (immediate child).
#   (b2) parent holds no crumb (deep leaf under uncrumbed directories): the orphan case that was invisible before the
#        amendment (recorded as FAILED in the first run of 2026-10-11, fixed in tools/crumb/crumb.c the same day).
IMM=""; DEEP=""
for d in $(crumb_dirs "$W" | grep -v '^\.$'); do
  p=${d%/*}; [ "$p" = "$d" ] && p=.
  if [ -f "$W/$p/.crumb" ]; then [ -n "$IMM" ] || IMM=$d; else [ -n "$DEEP" ] || DEEP=$d; fi
done
num "immediate_child_crumb=$IMM"; num "deep_crumb_without_crumbed_parent=${DEEP:-none}"
branch missing-immediate; git -C "$W" rm -q "$IMM/.crumb"; git -C "$W" commit -qm "delete $IMM/.crumb"
SHA=$(push missing-immediate); fx missing missing-immediate "$SHA"
export CASE=missing; measure gate_missing_immediate "$GATE" proof-repo 1 --worktree "$W" --dry-run
check_eq "missing immediate-child crumb: pr-gate exits 1" "$RC" 1
check "missing immediate-child crumb: stops at GATE crumb: FAIL" grep -q '^GATE crumb: FAIL' <<<"$OUT"
if [ -n "$DEEP" ]; then
  branch missing-deep; git -C "$W" rm -q "$DEEP/.crumb"; git -C "$W" commit -qm "delete $DEEP/.crumb"
  SHA=$(push missing-deep); fx deep missing-deep "$SHA"
  export CASE=deep; measure gate_missing_deep "$GATE" proof-repo 1 --worktree "$W" --dry-run
  check_eq "missing deep crumb (orphan, parent ${DEEP%/*} has no .crumb): pr-gate exits 1" "$RC" 1
  check "missing deep crumb: stops at GATE crumb: FAIL" grep -q '^GATE crumb: FAIL' <<<"$OUT"
else
  note "no deep crumb without a crumbed parent in this repository; (b2) not applicable"
fi

# (c) control: same source change, compiled, crumb commit separate and last
branch ok; printf '\n# proof 19 ok\n' >> "$W/$F"; git -C "$W" commit -qam "source change"
( cd "$W" && $CRUMB compile . >/dev/null ); git -C "$W" add -A; git -C "$W" commit -qm "crumb compile"
SHA=$(push ok); fx ok ok "$SHA"
export CASE=ok; measure gate_ok "$GATE" proof-repo 1 --worktree "$W" --dry-run
check_eq "compiled tree: pr-gate exits 0 (dry run)" "$RC" 0
check "compiled tree: GATE crumb: PASS" grep -q '^GATE crumb: PASS' <<<"$OUT"
note "$(grep '^GATE crumb' <<<"$OUT" | cut -c1-110)"

# (d) mixed last commit: crumbs and source in one commit is refused even though verify is OK
branch mixed; printf '\n# proof 19 mixed\n' >> "$W/$F"; ( cd "$W" && $CRUMB compile . >/dev/null )
git -C "$W" add -A; git -C "$W" commit -qm "source + crumbs together"
SHA=$(push mixed); fx mixed mixed "$SHA"
export CASE=mixed; measure gate_mixed "$GATE" proof-repo 1 --worktree "$W" --dry-run
check_eq "mixed last commit: pr-gate exits 1" "$RC" 1
check "mixed last commit: refused by rule 2" grep -q 'crumb commit must be separate and last' <<<"$OUT"
proof_end
