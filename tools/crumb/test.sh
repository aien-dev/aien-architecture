#!/bin/sh
# crumb self-test. usage: sh test.sh ./crumb. Uses a scratch dir only.
C=${1:-./crumb}; C=$(cd "$(dirname "$C")" && pwd)/$(basename "$C")
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "PASS $1"; }; bad() { echo "FAIL $1"; fail=1; }
mkdir -p "$T/r/src/deep" "$T/r/docs" "$T/r/old"; cd "$T/r" || exit 1
git init -q . 2>/dev/null; echo 'int main(void){return 0;}' > src/a.c; echo x > docs/n.md; echo y > src/deep/b.h
echo '{"version":1,"dir_path":"x","history":[]}' > old/.crumb; echo z > old/f.c

"$C" seed . >/dev/null; "$C" seed . | grep -q 'created 0, updated 0' && ok "seed idempotent" || bad "seed idempotent"
grep -q '^.crumb.local$' .gitignore && ok "gitignore has .crumb.local" || bad "gitignore"
grep -q 'version' old/.crumb && ! grep -q schema_version old/.crumb && ok "legacy .crumb untouched" || bad "legacy"
"$C" validate . | grep -q 'INVALID' && bad "validate" || ok "validate"
sed -i 's|"purpose": "Directory src. Purpose not yet described by a human."|"purpose": "Hand written C sources", "invariants": ["no globals"]|' src/.crumb
"$C" seed . >/dev/null; grep -q 'Hand written C sources' src/.crumb && grep -q 'no globals' src/.crumb && ok "hand edits survive reseed" || bad "hand edits"
echo w > src/new.c; "$C" seed . | grep -q 'updated 1' && grep -q new.c src/.crumb && ok "reseed picks up new file" || bad "reseed update"

"$C" claim laneA src src/a.c "refactor a" 600 | grep -q CLAIMED && ok claim || bad claim
"$C" claim laneB src src/a.c "also a" >/dev/null; [ $? -eq 2 ] && ok "second claim blocked (exit 2)" || bad "block"
"$C" claim laneB src src/b.c "other file" | grep -q CLAIMED && ok "claim different target" || bad "claim2"
"$C" update laneA src "still on a.c" | grep -q SCENT && ok update || bad update
"$C" whisper laneA src laneB "a.c done soon" high src/a.c | grep -q WHISPER && ok whisper || bad whisper
"$C" sniff laneB src | grep -q 'whisper laneA -> laneB' && ok "sniff sees whisper" || bad sniff
"$C" sniff laneB src | grep -q 'invariant: no globals' && ok "sniff shows invariants" || bad "sniff inv"
"$C" list . | grep -q 'lock .*src/a.c' && ok list || bad list
"$C" close laneB src src/a.c >/dev/null; [ $? -eq 2 ] && ok "close by non-holder refused" || bad "close refuse"
"$C" close laneA src src/a.c modify "done, ready" | grep -q CLOSED && ok close || bad close
"$C" list . | grep -q 'src/a.c' && bad "lock released" || ok "lock released"
grep -q '"history"' src/.crumb.local && grep -q '"action": "modify"' src/.crumb.local && ok "history vector written" || bad history
# expiry sweep
"$C" claim laneC src src/c.c "short" 1 >/dev/null; sleep 2; "$C" claim laneD src src/c.c "takes over" | grep -q CLAIMED && ok "expired lock swept" || bad sweep
echo '{broken' > docs/.crumb.local; "$C" sniff x docs >/dev/null 2>&1; [ $? -ne 0 ] && ok "bad local refused" || bad "bad local"
# backfill: known commit with a PR number lands in the right dir with the right sha; second run changes nothing
git add -A >/dev/null 2>&1; git -c user.name=t -c user.email=t@t commit -qm "feat: add b (#7)" >/dev/null 2>&1
sha=$(git rev-parse --short=7 HEAD)
HOME="$T/home" "$C" backfill . >/dev/null
grep -q '"pr": 7' src/.crumb && grep -q "\"sha\": \"$sha\"" src/.crumb && grep -q backfill-git src/.crumb && ok "backfill: PR 7 + sha in src/.crumb" || bad "backfill entry"
grep -q "$sha #7" docs/crumbs/BACKFILL.md && ok "BACKFILL.md lists commit" || bad "BACKFILL.md"
HOME="$T/home" "$C" backfill . | grep -q 'updated 0' && HOME="$T/home" "$C" backfill . | grep -q 'BACKFILL.md: unchanged' && ok "backfill idempotent" || bad "backfill idempotent"
exit $fail
