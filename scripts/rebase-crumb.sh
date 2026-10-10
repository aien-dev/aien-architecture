#!/usr/bin/env bash
# Rebase a PR branch onto origin/main, resolve conflicts that are only in .crumb files by taking
# main's copy, recompile crumbs as a fresh last commit, and push with a lease on the old head.
#
# Usage: rebase-crumb.sh <worktree> <branch>
# Env:   GIT (default git), CRUMB (default crumb), so tests can stub the tools.
# Exit:  0 done, 2 precondition refused, 3 CODE CONFLICT (rebase aborted), 4 crumb or rebase failure
#        (nothing pushed).
set -u
GIT=${GIT:-git}
CRUMB=${CRUMB:-crumb}
TRAILERS='Co-authored-by: Drake Stapleton <drake@aienos.com>
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>'

refuse() { echo "REFUSED: $1" >&2; exit 2; }

[ $# -eq 2 ] || { echo "usage: rebase-crumb.sh <worktree> <branch>" >&2; exit 2; }
W=$1; B=$2
cd "$W" 2>/dev/null || refuse "worktree $W does not exist"
$GIT rev-parse --is-inside-work-tree >/dev/null 2>&1 || refuse "$W is not a git checkout"
[ -z "$($GIT status --porcelain)" ] || refuse "working tree is not clean"
[ "$B" != "main" ] || refuse "branch is main"
URL=$($GIT config --get remote.origin.url 2>/dev/null) || refuse "no origin remote"
case "$URL" in
  *github.com/aien-dev/*|*git@github.com:aien-dev/*) ;;
  *) refuse "origin URL is not under aien-dev: $URL" ;;
esac
$GIT fetch -q origin || refuse "fetch failed"
$GIT rev-parse -q --verify "refs/remotes/origin/$B" >/dev/null || refuse "origin/$B does not exist"

GD=$($GIT rev-parse --git-dir)
LOCK="$GD/rebase-crumb.lock"
if [ -e "$LOCK" ] && [ -z "$(find "$LOCK" -mmin +120 2>/dev/null)" ]; then
  refuse "lock $LOCK is fresh (another run, or younger than 2 hours)"
fi
echo $$ > "$LOCK" || refuse "cannot create lock"
trap 'rm -f "$LOCK"' EXIT

LEASE=$($GIT rev-parse "origin/$B")
$GIT checkout -q -B "$B" "origin/$B" || { echo "checkout failed" >&2; exit 4; }

rebasing() { [ -d "$($GIT rev-parse --git-path rebase-merge)" ] || [ -d "$($GIT rev-parse --git-path rebase-apply)" ]; }

$GIT rebase -q origin/main >/dev/null 2>&1
while rebasing; do
  C=$($GIT diff --name-only --diff-filter=U)
  if [ -z "$C" ]; then
    GIT_EDITOR=true $GIT rebase --continue >/dev/null 2>&1 && continue
    # A resolved commit that became empty cannot be continued; skip it.
    if [ -z "$($GIT diff --cached --name-only)" ]; then
      $GIT rebase --skip >/dev/null 2>&1 && continue
    fi
    echo "rebase continue failed" >&2; $GIT status --short | head; $GIT rebase --abort; exit 4
  fi
  NONCRUMB=$(echo "$C" | grep -v '\.crumb$' || true)
  if [ -n "$NONCRUMB" ]; then
    echo "CODE CONFLICT: $(echo "$NONCRUMB" | tr '\n' ' ')"
    $GIT rebase --abort
    exit 3
  fi
  # During a rebase "ours" is the branch being rebased onto, which is main.
  echo "$C" | while IFS= read -r f; do
    if $GIT cat-file -e "origin/main:$f" 2>/dev/null; then
      $GIT checkout -q --ours -- "$f" && $GIT add -- "$f"
    else
      $GIT rm -q -f -- "$f"
    fi
  done
  GIT_EDITOR=true $GIT rebase --continue >/dev/null 2>&1 || {
    if [ -z "$($GIT diff --cached --name-only)" ] && $GIT rebase --skip >/dev/null 2>&1; then continue; fi
    echo "rebase continue failed" >&2; $GIT status --short | head; $GIT rebase --abort; exit 4
  }
done

if $GIT ls-files '*.crumb' '**/.crumb' | grep -q .; then
  $CRUMB compile . >/dev/null 2>&1
  VOUT=$($CRUMB verify . 2>&1); VRC=$?
  if [ "$VRC" -ne 0 ] || ! echo "$VOUT" | tail -1 | grep -q 'OK' || echo "$VOUT" | tail -1 | grep -q 'FAIL'; then
    echo "crumb verify did not print OK; nothing pushed: $(echo "$VOUT" | tail -1)" >&2
    exit 4
  fi
  echo "crumb: $(echo "$VOUT" | tail -1)"
  if [ -n "$($GIT status --porcelain)" ]; then
    $GIT add -A && $GIT commit -q -m "crumb compile (after rebase onto main)

$TRAILERS" || { echo "crumb commit failed" >&2; exit 4; }
  fi
else
  echo "crumb: no crumbs in repo, step skipped (rule 2 notice)"
fi

$GIT push -q --force-with-lease="refs/heads/$B:$LEASE" origin "$B" || { echo "push failed (lease or network)" >&2; exit 4; }
echo "rebased $B onto $($GIT rev-parse --short origin/main): $($GIT log --oneline -1 | cut -c1-70)"
