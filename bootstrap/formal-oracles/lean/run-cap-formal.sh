#!/bin/sh
# FORMAL-2/3: capability formal bootstrap runner (DEVELOPMENT_ORACLE, not permanent lineage).
# Builds the real model (must PASS) and each deliberate mutant claim (must FAIL).
# Last stdout line: CAP_FORMAL_BOOTSTRAP: PASS | FAIL | NOT_RUN
# No network needed after the toolchain is installed (core Lean only, no dependencies).
set -u
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 2
PATH="$HOME/.elan/bin:$PATH"; export PATH

quiet="${AIEN_SPARK_QUIET_FLAG:-$HOME/workspace/.spark-quiet}"
if [ -e "$quiet" ]; then
  echo "quiet flag present ($quiet): not building"
  echo "CAP_FORMAL_BOOTSTRAP: NOT_RUN"
  exit 3
fi
command -v lake >/dev/null 2>&1 || { echo "lake not found (install elan)"; echo "CAP_FORMAL_BOOTSTRAP: NOT_RUN"; exit 3; }

log=$(mktemp); trap 'rm -f "$log"' EXIT
echo "toolchain: $(cat lean-toolchain) / $(lean --version)"
fail=0

lake build AienCap >"$log" 2>&1; rc=$?
if [ $rc -eq 0 ] && ! grep -qi "sorry" "$log"; then
  echo "real_model: PASS"
else
  echo "real_model: FAIL (rc=$rc)"; tail -20 "$log"; fail=1
fi

lake build MutantModels >"$log" 2>&1; rc=$?
if [ $rc -eq 0 ] && ! grep -qi "sorry" "$log"; then
  echo "mutant_models_compile: PASS"
else
  echo "mutant_models_compile: FAIL (rc=$rc)"; tail -20 "$log"; fail=1
fi

for m in MutantScopeClaim MutantExpiryClaim MutantDepthClaim; do
  lake build "$m" >"$log" 2>&1; rc=$?
  if [ $rc -ne 0 ] && grep -q "^error: $m.lean:" "$log" && ! grep -q "^error: MutantModels.lean" "$log"; then
    echo "$m: FAIL_AS_EXPECTED (mutant killed)"
  else
    echo "$m: UNEXPECTED_BUILD_SUCCESS_OR_NO_ERROR (rc=$rc), mutant survived"; fail=1
  fi
done

if [ $fail -eq 0 ]; then echo "CAP_FORMAL_BOOTSTRAP: PASS"; else echo "CAP_FORMAL_BOOTSTRAP: FAIL"; fi
exit $fail
