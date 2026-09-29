#!/bin/sh
# Refuse an overall R16 PASS without its candidate-bound qualification receipt.
# Usage: scripts/verify-r16-status.sh <omega-checkout> [roadmap-file]
# Needs: awk, sha256sum, jq.
set -u

fail() { echo "$*" >&2; exit 1; }

[ $# -ge 1 ] || fail "usage: $0 <omega-checkout> [roadmap-file]"
omega=$1
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
roadmap=${2:-$root/doctrine/ROADMAP.md}
[ -f "$roadmap" ] || fail "roadmap not found: $roadmap"

status=$(awk -F'|' 'index($0, "| R16 orchestrator retirement |") == 1 {
    s = $3; gsub(/^[ \t]+|[ \t]+$/, "", s); print s; exit }' "$roadmap")
[ -n "$status" ] || fail "R16 row not found in $roadmap"

if [ "$status" = "IN PROGRESS" ]; then
    echo "R16 overall qualification is not claimed"
    exit 0
fi

command -v jq >/dev/null 2>&1 || fail "jq is required to check R16 receipts"

for path in "$omega"/evidence/R16/*.json; do
    [ -f "$path" ] || continue
    name=$(basename "$path" .json)
    digest=$(sha256sum "$path" | awk '{print $1}')
    [ "$name" = "$digest" ] || continue
    if jq -e '
        type == "object"
        and .schema == "AIEN_RX_R16_ORCHESTRATOR_RETIRED_V1"
        and .candidate_bound == true
        and .tree_dirty == false
        and .silicon_observed == true
        and (.candidate_commit | type) == "string"
        and (.candidate_commit | length) == 40
        and .candidate_commit == .run_commit
        and ((.gates // {}) | type) == "object"
        and ([range(1; 9) as $i | (.gates // {})["R16-G\($i)"] == "PASS"] | all)
        and ((.production_entry_point // false) | if type == "string" then length > 0 else . == true end)
        and .remaining_unclassified_semantic_loop_count == 0
    ' "$path" >/dev/null 2>&1; then
        echo "R16 qualified receipt: $(basename "$path")"
        exit 0
    fi
done

fail "R16 status '$status' has no valid final G1-G8 candidate-bound silicon receipt; inventory alone is insufficient"
