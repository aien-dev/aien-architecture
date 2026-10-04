#!/bin/sh
# T9 (RFC-0002 section 9): Continuation revalidation. usage: sh test-continuation.sh ./crumb
# checkpoint at commit C, advance the repo, resume must report STALE for repo HEAD and status NEEDS_REVIEW.
C=${1:-./crumb}; C=$(cd "$(dirname "$C")" && pwd)/$(basename "$C")
CC=${CRUMB_CC:-$HOME/.claude/skills/checkpoint/scripts/cc.sh}
if [ ! -x "$CC" ] || ! command -v jq >/dev/null 2>&1; then echo "SKIP T9 (needs jq and cc.sh at $CC): NOT_RUN"; exit 0; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "PASS $1"; }; bad() { echo "FAIL $1"; fail=1; }
export HOME="$T/home"; mkdir -p "$HOME"            # seal leaves whispers under $HOME/handoffs: keep them in scratch
export CRUMB_CC="$CC" CRUMB_SESSION=t9-agent; unset CRUMB_COORD_ROOT CC_STORE
mkdir -p "$T/r/src" "$HOME/handoffs"; cd "$T/r" || exit 1
git init -q -b main . && echo a > src/a.c && git add -A && git -c user.name=t -c user.email=t@t commit -qm init
C0=$(git rev-parse HEAD)
STORE=$(git rev-parse --absolute-git-dir)/crumb/v1

out=$("$C" checkpoint t9-agent --reason "t9 test") ; rc=$?
[ $rc -eq 0 ] && [ -f "$out" ] && case "$out" in "$STORE/continuations/"*) true;; *) false;; esac && ok "T9 checkpoint creates record in <coordination root>/continuations" || { bad "T9 checkpoint ($out)"; exit 1; }
id=$(basename "$out" .json)
jq -e '.identity.reason=="t9 test" and .identity.created_by=="t9-agent" and (.identity.repos[0].commit=="'"$C0"'")' "$out" >/dev/null && ok "T9 record pins HEAD and reason" || bad "T9 pin"
tmp="$out.t"; jq '.identity.project="t9" | .mission.current_goal="g" | .mission.milestone="m" | .mission.definition_of_done=["done"]
  | .state.items=[{"tag":"OPEN","claim":"nothing yet"}] | .execution.current_task="t" | .execution.next_tasks=[{"id":"n1","task":"x"}]
  | .resume.first_action="look" | .resume.validation_before_work=["git status"] | .resume.bootstrap_prompt="continue"' "$out" > "$tmp" && mv "$tmp" "$out"
seal=$("$C" checkpoint --seal "$id" t9-agent 2>&1); echo "$seal" | grep -q "SEALED $id" && ok "T9 seal succeeds" || bad "T9 seal: $seal"
[ "$(cat "$STORE/continuations/LATEST" 2>/dev/null)" = "$id" ] && ok "T9 LATEST updated in the shared store" || bad "T9 LATEST"

echo more > src/b.c && git add -A && git -c user.name=t -c user.email=t@t commit -qm "advance"
res=$("$C" resume "$id" 2>&1)
echo "$res" | grep -q '^STALE .*repo\..*\.HEAD' && ok "T9 resume prints STALE for repo HEAD" || bad "T9 STALE line"
echo "$res" | grep -q '^status: NEEDS_REVIEW' && ok "T9 resume status NEEDS_REVIEW" || bad "T9 status"
[ "$(jq -r .revalidation.status "$STORE/continuations/$id.json")" = NEEDS_REVIEW ] && ok "T9 findings recorded in the record" || bad "T9 recorded"
CRUMB_CC="$T/missing/cc.sh" "$C" resume "$id" 2>&1 | grep -q 'cc.sh not found.*missing/cc.sh' && ok "T9 missing cc.sh gives a clear error naming the path" || bad "T9 missing cc.sh"
exit $fail
