#!/usr/bin/env bash
# Run every proof (00 and 13-23) against each repository given, append the PROOF lines to RESULTS_LOG.
# Usage: run-all.sh <repo-path> [<repo-path>...]     Env: RESULTS_LOG (default /tmp/pipeline-proofs.log)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
export RESULTS_LOG=${RESULTS_LOG:-/tmp/pipeline-proofs.log}
[ $# -ge 1 ] || { echo "usage: run-all.sh <repo-path> [<repo-path>...]" >&2; exit 2; }
proven=0; failed=0; na=0
for repo in "$@"; do
  echo "=== $repo ==="
  for s in "$here"/00-*.sh "$here"/1[3-9]-*.sh "$here"/2[0-3]-*.sh; do
    [ -x "$s" ] || continue
    "$s" "$repo"; rc=$?
    case $rc in 0) proven=$((proven+1)) ;; 3) na=$((na+1)) ;; *) failed=$((failed+1)) ;; esac
    echo
  done
done
echo "SUMMARY proven=$proven failed=$failed not_applicable=$na (log: $RESULTS_LOG)"
[ "$failed" -eq 0 ]
