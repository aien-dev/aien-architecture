# Shared helpers for the acceptance proofs 13-21 (sourced, not executed).
# Every proof: `source lib.sh; proof_begin <n> "<title>" "$1"` then assertions, then `proof_end`.
# Exit 0 = PROVEN, 1 = FAILED, 2 = usage, 3 = NOT_APPLICABLE to this repository.
# Each proof works on a temporary `git clone` of the repository given as $1; the source tree is never touched.
# Env: CRUMB (default crumb), KEEP=1 keeps the temp directory, RESULTS_LOG=<file> appends the PROOF line.
set -u
CRUMB=${CRUMB:-crumb}
export GIT_AUTHOR_NAME=proof GIT_AUTHOR_EMAIL=proof@example.invalid GIT_COMMITTER_NAME=proof GIT_COMMITTER_EMAIL=proof@example.invalid
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
unset CRUMB_COORD_ROOT

PROOF_N=""; PROOF_TITLE=""; SRC=""; TMP=""; FAILS=0; NUMBERS=""

now_ms() { date +%s%3N; }

proof_begin() {   # proof_begin <n> <title> <repo-path>
  PROOF_N=$1; PROOF_TITLE=$2
  [ -n "${3:-}" ] || { echo "usage: $(basename "$0") <repo-path>" >&2; exit 2; }
  SRC=$(cd "$3" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git checkout: $3" >&2; exit 2; }
  TMP=$(mktemp -d "${TMPDIR:-/tmp}/proof${PROOF_N}.XXXXXX")
  if [ "${KEEP:-0}" != 1 ]; then trap 'rm -rf "$TMP"' EXIT; fi
  echo "PROOF $PROOF_N: $PROOF_TITLE"
  echo "  repo: $SRC at $(git -C "$SRC" rev-parse --short HEAD) ($(git -C "$SRC" ls-files '*.crumb' '**/.crumb' | wc -l) crumbs); temp: $TMP; load: $(cut -d' ' -f1 /proc/loadavg)"
}

clone_repo() {   # clone_repo <dst>  : clone of SRC at its HEAD, with user config set
  git clone -q --no-hardlinks "$SRC" "$1" || { echo "clone failed" >&2; exit 1; }
  git -C "$1" config user.name proof; git -C "$1" config user.email proof@example.invalid
}

measure() {   # measure <label> <cmd...>   -> sets MS, RC, OUT; prints one MEASURE line
  local l=$1; shift
  local t0 t1; t0=$(now_ms)
  OUT=$("$@" 2>&1); RC=$?
  t1=$(now_ms); MS=$((t1 - t0))
  echo "  MEASURE $l: ${MS} ms (rc=$RC)"
  NUMBERS="$NUMBERS $l=${MS}ms"
}

note() { echo "  $*"; }
num() { NUMBERS="$NUMBERS $1"; echo "  NUMBER $1"; }

check() {   # check "<label>" <command...>   (command's success = assertion holds)
  local l=$1; shift
  if "$@" >/dev/null 2>&1; then echo "  ok   $l"; else echo "  FAIL $l"; FAILS=$((FAILS+1)); fi
}
check_eq() {   # check_eq "<label>" <got> <want>
  if [ "$2" = "$3" ]; then echo "  ok   $1 ($2)"; else echo "  FAIL $1 (got '$2', want '$3')"; FAILS=$((FAILS+1)); fi
}

crumb_dirs() {   # crumb_dirs <repo> : directories holding a tracked .crumb, "." for the root
  git -C "$1" ls-files '*.crumb' '**/.crumb' | sed 's#/\?\.crumb$##; s#^$#.#'
}
leaf_crumb_dir() {   # deepest crumb directory other than the root that holds a tracked non-crumb file
  local r=$1 d
  for d in $(crumb_dirs "$r" | grep -v '^\.$' | awk -F/ '{print NF" "$0}' | sort -rn | cut -d' ' -f2); do
    if git -C "$r" ls-files "$d" | grep -v '\.crumb$' | grep -q .; then echo "$d"; return 0; fi
  done
  return 1
}
tracked_file_in() {   # a tracked non-crumb file under <dir>
  git -C "$1" ls-files "$2" | grep -v '\.crumb$' | grep -v '^\.crumbignore$' | head -1
}
ancestors_with_crumbs() {   # ancestors_with_crumbs <repo> <dir> : the dir, each ancestor with a crumb, and "." (space separated, sorted)
  local r=$1 d=$2 out
  out=". $d"
  while [ "$d" != "." ] && [ "${d%/*}" != "$d" ]; do
    d=${d%/*}
    [ -f "$r/$d/.crumb" ] && out="$out $d"
  done
  echo "$out" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'
}
stale_set() {   # stale_set <repo> : sorted STALE/UNCOMPILED dirs from crumb status
  (cd "$1" && $CRUMB status . | awk '$1=="STALE"||$1=="UNCOMPILED"{print $2}' | sort | tr '\n' ' ' | sed 's/ $//')
}
current_count() { (cd "$1" && $CRUMB status . | grep -c '^CURRENT'); }

proof_end() {
  if [ "$FAILS" -eq 0 ]; then
    echo "PROOF $PROOF_N PROVEN:$NUMBERS"
    [ -n "${RESULTS_LOG:-}" ] && echo "PROOF $PROOF_N PROVEN ($(basename "$SRC")):$NUMBERS" >> "$RESULTS_LOG"
    exit 0
  else
    echo "PROOF $PROOF_N FAILED ($FAILS assertion(s)):$NUMBERS"
    [ -n "${RESULTS_LOG:-}" ] && echo "PROOF $PROOF_N FAILED ($(basename "$SRC")):$NUMBERS" >> "$RESULTS_LOG"
    exit 1
  fi
}
proof_na() { echo "PROOF $PROOF_N NOT_APPLICABLE: $1"; [ -n "${RESULTS_LOG:-}" ] && echo "PROOF $PROOF_N NOT_APPLICABLE ($(basename "$SRC")): $1" >> "$RESULTS_LOG"; exit 3; }
