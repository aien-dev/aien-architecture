#!/usr/bin/env bash
# check_candidate.sh: validate a candidate manifest (docs/qualification/CANDIDATE.md).
# Usage: scripts/check_candidate.sh <manifest.toml>
# Exit 0 = valid, 1 = invalid. Pure bash; sha existence is checked with
# `gh api repos/aien-dev/<repo>/commits/<sha>`. Override with env var
# CAND_SHA_CHECK (a command run as: $CAND_SHA_CHECK <repo> <sha>) for tests.
set -u
# Commit pins: [commits] (5 repos) and [contracts] (crumb-spec, spark-crumbs).
f="${1:-}"
[ -f "$f" ] || { echo "usage: $0 <manifest.toml>" >&2; exit 1; }
fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

sha_exists() {
  if [ -n "${CAND_SHA_CHECK:-}" ]; then $CAND_SHA_CHECK "$1" "$2"
  else gh api "repos/aien-dev/$1/commits/$2" -q .sha >/dev/null 2>&1; fi
}

# Parse: "section.key" -> value, for lines `key = "value"`.
declare -A kv
sec=""
while IFS= read -r line; do
  # A quoted value may contain #; only a trailing comment after the closing quote is dropped.
  if [[ "$line" =~ ^[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*=[[:space:]]*\"([^\"]*)\"[[:space:]]*(#.*)?$ ]]; then
    kv["${sec}${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; continue
  fi
  line="$(echo "$line" | sed -e 's/^[[:space:]]*#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$line" ] && continue
  if [[ "$line" =~ ^\[([A-Za-z0-9_.-]+)\][[:space:]]*(#.*)?$ ]]; then sec="${BASH_REMATCH[1]}."; continue; fi
done < "$f"

for k in schema id status created; do
  [ -n "${kv[$k]:-}" ] || err "missing field: $k"
done
[ "${kv[schema]:-}" = "CandidateManifestV1" ] || err "schema must be CandidateManifestV1"
case "${kv[status]:-}" in
  "draft, not frozen"|frozen|superseded) ;;
  *) err "status must be 'draft, not frozen', 'frozen' or 'superseded'" ;;
esac

for r in commits.omega commits.aienos commits.aien-sovereign-core commits.aien-protocols commits.aien-architecture contracts.crumb-spec contracts.spark-crumbs; do
  s="${kv[$r]:-}"; repo="${r#*.}"
  if [ -z "$s" ]; then err "missing commit: $r"; continue; fi
  [[ "$s" =~ ^[0-9a-f]{40}$ ]] || { err "commit for $r is not 40 lowercase hex: $s"; continue; }
  sha_exists "$repo" "$s" || err "commit $s not found in aien-dev/$repo"
done

nexe=0
for k in "${!kv[@]}"; do
  [[ "$k" == executables.* ]] || continue
  nexe=$((nexe+1))
  v="${kv[$k]}"
  if [ "$v" = "UNBUILT" ]; then
    [[ "${kv[status]:-}" == draft* ]] || err "$k is UNBUILT but status is not draft"
  else
    [[ "$v" =~ ^[0-9a-f]{64}$ ]] || err "$k digest is not 64 lowercase hex"
    [[ "$v" =~ ^0{64}$ ]] && err "$k digest is all zero (placeholder, not a real digest)"
  fi
done
[ "$nexe" -gt 0 ] || err "no [executables] entries"

[ "$fail" -eq 0 ] && echo "OK: $f" && exit 0
exit 1
