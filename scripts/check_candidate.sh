#!/usr/bin/env bash
# check_candidate.sh: validate a candidate manifest (docs/qualification/CANDIDATE.md) and its amendments.
# Usage: scripts/check_candidate.sh <manifest.toml>
# Exit 0 = valid, 1 = invalid. Pure bash; sha existence is checked with
# `gh api repos/aien-dev/<repo>/commits/<sha>`. Override with env var
# CAND_SHA_CHECK (a command run as: $CAND_SHA_CHECK <repo> <sha>) for tests.
# Amendments: every <manifest-stem>.amendment-<n>.toml next to the manifest is read and checked too (see below).
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

# parse <file> <assoc-array-name>: "section.key" -> value, for lines `key = "value"`.
parse() {
  local -n out="$2"; local sec="" line
  while IFS= read -r line; do
    # A quoted value may contain #; only a trailing comment after the closing quote is dropped.
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*=[[:space:]]*\"([^\"]*)\"[[:space:]]*(#.*)?$ ]]; then
      out["${sec}${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; continue
    fi
    line="$(echo "$line" | sed -e 's/^[[:space:]]*#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^\[([A-Za-z0-9_.-]+)\][[:space:]]*(#.*)?$ ]]; then sec="${BASH_REMATCH[1]}."; continue; fi
  done < "$1"
}
declare -A kv
parse "$f" kv
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

# Optional pins for repos that are part of a candidate but were not in the first schema (CAND-0 adds
# physics and interplane). When present they get the same checks as the required ones.
for r in commits.physics commits.interplane; do
  s="${kv[$r]:-}"; repo="${r#*.}"
  [ -n "$s" ] || continue
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


# Amendments. A frozen manifest is never edited; evidence recorded after the freeze goes in
# <manifest-stem>.amendment-<n>.toml next to it, with the dated note in <id>.gates.md. Each amendment must:
# have schema CandidateAmendmentV1, name this candidate, carry its own number, a date and a reason; pin the
# sha256 of the manifest it amends (so a later edit of the frozen manifest is refused); and only ADD keys, never
# in [commits], [contracts], [executables] or [consumed_pins] (those define what the candidate is). Added
# *-sha256 values must be real digests.
mf_sha="$(sha256sum "$f" | cut -d' ' -f1)"
stem="${f%.toml}"; namend=0
for a in "$stem".amendment-*.toml; do
  [ -f "$a" ] || continue
  n="${a#"$stem".amendment-}"; n="${n%.toml}"
  unset am; declare -A am=(); parse "$a" am
  [ "${am[schema]:-}" = "CandidateAmendmentV1" ] || err "$a: schema must be CandidateAmendmentV1"
  [ "${am[candidate]:-}" = "${kv[id]:-}" ] || err "$a: candidate '${am[candidate]:-}' is not the manifest id '${kv[id]:-}'"
  [ "${am[amendment]:-}" = "$n" ] || err "$a: amendment '${am[amendment]:-}' does not match its file name ($n)"
  { [ -n "${am[date]:-}" ] && [ -n "${am[reason]:-}" ]; } || err "$a: date and reason are required"
  [ "${am[manifest-sha256]:-}" = "$mf_sha" ] \
    || err "$a: pins manifest sha256 '${am[manifest-sha256]:-}' but $f is $mf_sha (frozen manifests are not edited)"
  nk=0
  for k in "${!am[@]}"; do
    case "$k" in schema|candidate|amendment|date|reason|manifest-sha256) continue ;; esac
    case "$k" in *.*) ;; *) err "$a: unknown top-level key '$k'"; continue ;; esac
    case "$k" in commits.*|contracts.*|executables.*|consumed_pins.*)
      err "$a: $k cannot be amended (it would change what the candidate is)"; continue ;; esac
    [ -z "${kv[$k]+x}" ] || err "$a: $k is already in the manifest; an amendment only adds keys"
    if [[ "$k" == *-sha256 ]]; then
      { [[ "${am[$k]}" =~ ^[0-9a-f]{64}$ ]] && ! [[ "${am[$k]}" =~ ^0{64}$ ]]; } || err "$a: $k is not a real sha256"
    fi
    nk=$((nk+1))
  done
  [ "$nk" -gt 0 ] || err "$a: adds no keys"
  namend=$((namend+1))
done

[ "$fail" -eq 0 ] && echo "OK: $f (amendments: $namend)" && exit 0
exit 1
