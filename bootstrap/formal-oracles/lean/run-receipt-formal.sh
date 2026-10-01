#!/bin/sh
# FORMAL-4: receipt consistency formal bootstrap runner (DEVELOPMENT_ORACLE, not permanent lineage).
# Builds the real model (must PASS) and each deliberate mutant claim (must FAIL for a proof reason).
# Last stdout line: RECEIPT_FORMAL_BOOTSTRAP: PASS | FAIL | NOT_RUN
# No network needed after the toolchain is installed (core Lean only, no dependencies).
set -u
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 2
PATH="$HOME/.elan/bin:$PATH"; export PATH

quiet="${AIEN_SPARK_QUIET_FLAG:-$HOME/workspace/.spark-quiet}"
if [ -e "$quiet" ]; then
  echo "quiet flag present ($quiet): not building"
  echo "RECEIPT_FORMAL_BOOTSTRAP: NOT_RUN"
  exit 3
fi
command -v lake >/dev/null 2>&1 || { echo "lake not found (install elan)"; echo "RECEIPT_FORMAL_BOOTSTRAP: NOT_RUN"; exit 3; }

log=$(mktemp); trap 'rm -f "$log"' EXIT
echo "toolchain: $(cat lean-toolchain) / $(lean --version)"
fail=0

# Forbidden constructs in the receipt sources (comments excluded by matching code-like uses).
if grep -nE '^[^-]*\b(sorry|admit|native_decide|unsafe)\b|^axiom |^ *axiom ' AienReceipt/*.lean AienReceipt.lean >"$log"; then
  echo "forbidden_constructs: FAIL"; cat "$log"; fail=1
else
  echo "forbidden_constructs: PASS"
fi

lake build AienReceipt >"$log" 2>&1; rc=$?
if [ $rc -eq 0 ] && ! grep -qi "sorry" "$log"; then
  echo "real_model: PASS"
else
  echo "real_model: FAIL (rc=$rc)"; tail -20 "$log"; fail=1
fi

lake build MutantReceiptModels >"$log" 2>&1; rc=$?
if [ $rc -eq 0 ] && ! grep -qi "sorry" "$log"; then
  echo "mutant_models_compile: PASS"
else
  echo "mutant_models_compile: FAIL (rc=$rc)"; tail -20 "$log"; fail=1
fi

# A mutant is killed only by a proof error in its own claim file, not a syntax or import error.
for m in MutantRejectedRanClaim MutantNoReasonClaim MutantNonRejectedFieldsClaim MutantCanaryClaim MutantAbsentFlagClaim; do
  lake build "$m" >"$log" 2>&1; rc=$?
  if [ $rc -ne 0 ] && grep -qE "^error: $m.lean:[0-9]+:[0-9]+: (unsolved goals|simp_all made no progress|Type mismatch|simp made no progress|Tactic)" "$log" \
     && ! grep -q "unexpected token" "$log" && ! grep -qE "^error: (MutantReceiptModels|AienReceipt)" "$log"; then
    echo "$m: FAIL_AS_EXPECTED (mutant killed)"
  else
    echo "$m: UNEXPECTED_BUILD_SUCCESS_OR_NO_PROOF_ERROR (rc=$rc), mutant survived"; fail=1
  fi
done

if [ $fail -eq 0 ]; then echo "RECEIPT_FORMAL_BOOTSTRAP: PASS"; else echo "RECEIPT_FORMAL_BOOTSTRAP: FAIL"; fi
exit $fail
