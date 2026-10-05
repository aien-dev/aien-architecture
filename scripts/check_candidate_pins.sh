#!/usr/bin/env bash
# check_candidate_pins.sh: do the pins of a candidate manifest equal what the pinned code consumes?
# Usage: scripts/check_candidate_pins.sh <manifest.toml>
# check_candidate.sh proves each pinned commit exists; this script proves the pins agree with each other.
# It reads the lock files of the pinned commits from GitHub and compares:
#   sovereign-core omega.lock                        = [commits] omega
#   sovereign-core Cargo.lock aien-protocols rev     = [commits] aien-protocols
#   sovereign-core Cargo.lock crumb-spec rev         = [contracts] crumb-spec
#   sovereign-core Cargo.lock spark-crumbs rev       = [contracts] spark-crumbs
#   omega physics.lock                               = [commits] physics (when pinned)
#   omega aienos.lock                                = [commits] aienos
#   every [consumed_pins] key below                  = the value read from its lock file
# A Cargo.lock package with more than one git revision, or a lock file that cannot be read, fails.
# Exit 0 = every pin agrees, 1 = any mismatch or read failure. Pure bash plus `gh api`.
# Override the reader with CAND_FILE_AT (a command run as: $CAND_FILE_AT <repo> <sha> <path>, printing the
# file) for offline tests.
set -u
f="${1:-}"
[ -f "$f" ] || { echo "usage: $0 <manifest.toml>" >&2; exit 1; }
fail=0
ok() { echo "OK: $*"; }
err() { echo "FAIL: $*" >&2; fail=1; }

file_at() {
  if [ -n "${CAND_FILE_AT:-}" ]; then $CAND_FILE_AT "$1" "$2" "$3"
  else gh api -H "Accept: application/vnd.github.raw" "repos/aien-dev/$1/contents/$3?ref=$2"; fi
}

# Same parser as check_candidate.sh: "section.key" -> value, for lines `key = "value"`.
declare -A kv
sec=""
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*=[[:space:]]*\"([^\"]*)\"[[:space:]]*(#.*)?$ ]]; then
    kv["${sec}${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; continue
  fi
  line="$(echo "$line" | sed -e 's/^[[:space:]]*#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$line" ] && continue
  if [[ "$line" =~ ^\[([A-Za-z0-9_.-]+)\][[:space:]]*(#.*)?$ ]]; then sec="${BASH_REMATCH[1]}."; continue; fi
done < "$f"

# The pin of a lock file: its first line that is not blank and not a comment must be exactly 40 lowercase hex
# (comment lines after it are allowed). Anything else, or a failed read, prints nothing and fails. The read is
# captured with its exit status before parsing: on a missing commit `gh api` prints an error body that itself
# contains the 40-hex ref, which must never be taken for the file.
read_lock() { # read_lock <repo> <sha> <path>
  local text line
  text=$(file_at "$1" "$2" "$3") || return 1
  line=$(printf '%s\n' "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v -m1 -e '^$' -e '^#')
  [[ "$line" =~ ^[0-9a-f]{40}$ ]] || return 1
  echo "$line"
}

# git revision of the aien-dev repo $2 in Cargo.lock text $1: every package whose source is that repo (a repo
# that ships several crates, such as aien-protocols, counts once); fails on zero or several revisions
cargo_rev() {
  local revs
  revs=$(printf '%s\n' "$1" | grep -E "^source = \"git\+https://github\.com/aien-dev/$2(\.git)?[?#]" \
    | grep -oE '#[0-9a-f]{40}"' | cut -c2-41 | sort -u)
  [ -n "$revs" ] || { echo "none"; return 1; }
  [ "$(printf '%s\n' "$revs" | wc -l)" -eq 1 ] || { echo "several:$(echo $revs)"; return 1; }
  echo "$revs"
}

same() { # same <label> <pinned> <consumed>
  if [ -z "$2" ]; then err "$1: not pinned in the manifest"
  elif [ "$2" = "$3" ]; then ok "$1 = $3"
  else err "$1: manifest pins $2, the code consumes $3"; fi
}

sc="${kv[commits.aien-sovereign-core]:-}"; om="${kv[commits.omega]:-}"
[ -n "$sc" ] && [ -n "$om" ] || { err "manifest lacks commits.aien-sovereign-core or commits.omega"; exit 1; }

if sc_omega=$(read_lock aien-sovereign-core "$sc" omega.lock); then
  same "sovereign-core omega.lock -> commits.omega" "$om" "$sc_omega"
else err "cannot read omega.lock at aien-sovereign-core $sc"; sc_omega=""; fi

if cargo_lock=$(file_at aien-sovereign-core "$sc" Cargo.lock) && [ -n "$cargo_lock" ]; then
  for pair in aien-protocols:commits.aien-protocols crumb-spec:contracts.crumb-spec spark-crumbs:contracts.spark-crumbs; do
    pkg="${pair%%:*}"; key="${pair#*:}"
    if rev=$(cargo_rev "$cargo_lock" "$pkg"); then same "sovereign-core Cargo.lock $pkg -> $key" "${kv[$key]:-}" "$rev"
    else err "sovereign-core Cargo.lock $pkg: git revision $rev"; fi
  done
  prot=$(cargo_rev "$cargo_lock" aien-protocols) || prot=""
else err "cannot read Cargo.lock at aien-sovereign-core $sc"; prot=""; fi

om_physics=$(read_lock omega "$om" physics.lock) || om_physics=""
om_aienos=$(read_lock omega "$om" aienos.lock) || om_aienos=""
om_argus=$(read_lock omega "$om" argus.lock) || om_argus=""
[ -n "$om_aienos" ] && same "omega aienos.lock -> commits.aienos" "${kv[commits.aienos]:-}" "$om_aienos" \
  || err "cannot read aienos.lock at omega $om"
if [ -n "${kv[commits.physics]:-}" ]; then
  [ -n "$om_physics" ] && same "omega physics.lock -> commits.physics" "${kv[commits.physics]}" "$om_physics" \
    || err "cannot read physics.lock at omega $om"
fi

# [consumed_pins] are informational in check_candidate.sh; here each known key must equal what was read.
for k in "${!kv[@]}"; do
  [[ "$k" == consumed_pins.* ]] || continue
  name="${k#consumed_pins.}"
  case "$name" in
    sovereign-core-omega-lock) got="$sc_omega" ;;
    sovereign-core-cargo-lock-aien-protocols) got="$prot" ;;
    omega-physics-lock) got="$om_physics" ;;
    omega-aienos-lock) got="$om_aienos" ;;
    omega-argus-lock) got="$om_argus" ;;
    *) echo "SKIP: consumed_pins.$name (not read by this script)"; continue ;;
  esac
  [ -n "$got" ] || { err "consumed_pins.$name: its lock file could not be read"; continue; }
  same "consumed_pins.$name" "${kv[$k]}" "$got"
done

[ "$fail" -eq 0 ] && echo "PINS AGREE: $f" && exit 0
echo "PINS DISAGREE: $f" >&2
exit 1
