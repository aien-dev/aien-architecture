#!/bin/sh
# crumb self-test. usage: sh test.sh ./crumb. Uses a scratch dir only.
C=${1:-./crumb}; C=$(cd "$(dirname "$C")" && pwd)/$(basename "$C")
HERE=$(cd "$(dirname "$0")" && pwd)
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
grep -q '"history"' .git/crumb/v1/dirs/src.json && grep -q '"action": "modify"' .git/crumb/v1/dirs/src.json && [ ! -e src/.crumb.local ] && ok "history vector written" || bad history
# expiry sweep
"$C" claim laneC src src/c.c "short" 1 >/dev/null; sleep 2; "$C" claim laneD src src/c.c "takes over" | grep -q CLAIMED && ok "expired lock swept" || bad sweep
echo '{broken' > docs/.crumb.local; "$C" sniff x docs >/dev/null 2>&1; [ $? -ne 0 ] && ok "bad local refused" || bad "bad local"

# ---- RFC-0002 common coordination plane: two real linked worktrees ----
cd "$T" || exit 1
mkdir rc && cd rc && git init -q -b main . && mkdir src && echo a > src/runtime.c && echo b > src/other.c && echo c > src/legacy.c
git add -A && git -c user.name=t -c user.email=t@t commit -qm init
git worktree add -q -b A "$T/wa" && git worktree add -q -b B "$T/wb"
STORE=$(cd "$T/rc" && cd "$(git rev-parse --git-common-dir)" && pwd)/crumb/v1
# T1 cross-worktree visibility
(cd "$T/wa" && "$C" claim agent-a src runtime.c "rewrite runtime" | grep -q CLAIMED) && ok "T1 claim in worktree A" || bad "T1 claim A"
out=$(cd "$T/wb" && "$C" sniff agent-b src)
echo "$out" | grep -q 'shared coordination: ACTIVE' && echo "$out" | grep -q "held by agent-a \[A\]" && echo "$out" | grep -q 'src/runtime.c' && ok "T1 B sniff sees A's claim (branch A)" || bad "T1 visibility"
echo "$out" | grep -q 'CONFLICT: src/runtime.c' && ok "T1 sniff OTHER WORKTREES reports conflict" || bad "T1 other worktrees"
[ -f "$STORE/dirs/src.json" ] && [ ! -e "$T/wa/src/.crumb.local" ] && ok "T1 state lives in common store, no .crumb.local written" || bad "T1 store"
# T2 conflict, deterministic
(cd "$T/wb" && "$C" claim agent-b src runtime.c "also" >/dev/null); [ $? -eq 2 ] && ok "T2 B claim refused (exit 2)" || bad "T2 refuse"
(cd "$T/wb" && "$C" claim agent-b . src/runtime.c "also, repo-relative form" >/dev/null); [ $? -eq 2 ] && ok "T2 refused via repo-relative form" || bad "T2 refuse2"
(cd "$T/wa" && "$C" whisper agent-a src agent-b "runtime half done" high | grep -q WHISPER) && (cd "$T/wb" && "$C" sniff agent-b src | grep -q 'whisper agent-a -> agent-b') && ok "T2 whisper crosses worktrees" || bad "T2 whisper"
# T3 release
(cd "$T/wb" && "$C" close agent-b src runtime.c >/dev/null); [ $? -eq 2 ] && ok "T3 non-holder close refused" || bad "T3 nonholder"
(cd "$T/wa" && "$C" close agent-a src runtime.c modify "done" | grep -q CLOSED) && ok "T3 A closes" || bad "T3 close"
(cd "$T/wb" && "$C" claim agent-b src runtime.c "my turn" | grep -q CLAIMED) && ok "T3 B claim succeeds after release" || bad "T3 claim"
(cd "$T/wb" && "$C" close agent-b src runtime.c >/dev/null)
# T4 independent targets
(cd "$T/wa" && "$C" claim agent-a src one.c "one" >/dev/null) && (cd "$T/wb" && "$C" claim agent-b src two.c "two" >/dev/null) && \
  out=$(cd "$T/wa" && "$C" sniff agent-a src) && echo "$out" | grep -q 'src/one.c' && echo "$out" | grep -q 'src/two.c' && ok "T4 independent targets both survive" || bad "T4 independent"
(cd "$T/wa" && "$C" close agent-a src one.c >/dev/null); (cd "$T/wb" && "$C" close agent-b src two.c >/dev/null)
# T5 concurrent mutation: 8 different targets, then 8 agents on one target
i=1; while [ $i -le 8 ]; do ( cd "$T/w$( [ $((i%2)) -eq 0 ] && echo b || echo a )" && "$C" claim "cagent$i" src "c$i.c" "par" >/dev/null ) & i=$((i+1)); done; wait
n=$(cd "$T/wa" && "$C" sniff x src | grep -c '^  lock .*src/c[1-8].c')
[ "$n" -eq 8 ] && ok "T5 8 concurrent claims on 8 targets: 8 locks survive" || bad "T5 lost updates ($n of 8)"
i=1; while [ $i -le 8 ]; do ( cd "$T/w$( [ $((i%2)) -eq 0 ] && echo b || echo a )" && "$C" claim "sagent$i" src same.c "race" >/dev/null; echo $? > "$T/rc$i" ) & i=$((i+1)); done; wait
w=$(cat "$T"/rc[1-8] | grep -c '^0$'); b=$(cat "$T"/rc[1-8] | grep -c '^2$')
[ "$w" -eq 1 ] && [ "$b" -eq 7 ] && ok "T5 8 racers on one target: exactly 1 wins, 7 exit 2" || bad "T5 race (wins=$w blocked=$b)"
nl=$(cd "$T/wa" && "$C" sniff x src | grep -c '^  lock .*src/same.c'); [ "$nl" -eq 1 ] && ok "T5 exactly one lock record for raced target" || bad "T5 lock count"
# T6 TTL / crash recovery: holder never closes
(cd "$T/wa" && "$C" claim dead-agent src ttl.c "crashes" 1 >/dev/null); sleep 2
(cd "$T/wb" && "$C" claim live-agent src ttl.c "takes over" | grep -q CLAIMED) && ok "T6 expired lock pruned, other worktree claims" || bad "T6 ttl"
(cd "$T/wb" && "$C" sniff x src | grep -q 'lock .*ttl.c.*held by dead-agent') && bad "T6 dead lock still listed" || ok "T6 dead agent's lock gone from sniff"
# T7 path normalization: two absolute worktree paths of the same file are one lock
(cd "$T/wa" && "$C" claim agent-a . "$T/wa/src/abs.c" "abs" | grep -q 'CLAIMED src/abs.c') && ok "T7 absolute path in A normalised to src/abs.c" || bad "T7 abs A"
(cd "$T/wb" && "$C" claim agent-b src "$T/wb/src/abs.c" "abs b" >/dev/null); [ $? -eq 2 ] && ok "T7 same file via B's absolute path is the same lock" || bad "T7 abs B"
(cd "$T/wb" && "$C" claim agent-b src ../src/./abs.c "dots" >/dev/null); [ $? -eq 2 ] && ok "T7 ../ and ./ collapse to the same lock" || bad "T7 dots"
(cd "$T/wb" && "$C" claim agent-b . "$T/wa/elsewhere.c" "x" >/dev/null 2>&1); [ $? -eq 1 ] && ok "T7 path outside this worktree refused" || bad "T7 outside"
# agent identity is never a PID alone
grep -q '"session": "agent-a@' "$STORE/agents/agent-a.json" && ok "agent record carries session id (agent@host), not a PID" || bad "agent session id"
(cd "$T/wa" && CRUMB_SESSION=sess-123 "$C" update agent-a src "pinned session" >/dev/null) && grep -q '"session": "sess-123"' "$STORE/agents/agent-a.json" && ok "CRUMB_SESSION overrides session id" || bad "CRUMB_SESSION"
# T8 legacy .crumb.local: read, import once with provenance, never overridden, file kept
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
(cd "$T/wb" && "$C" claim agent-new src legacy2.c "fresh shared" >/dev/null)
cat > "$T/wa/src/.crumb.local" <<JSON
{"schema_version":"1.0.0","directory":"x","active_scents":{"old-agent":{"focus":"legacy work","updated_at":"$NOW","ttl_seconds":600}},
 "locks":{"src/legacy.c":{"holder":"old-agent","intent":"legacy lock","acquired_at":"$NOW","ttl_seconds":600},
          "src/legacy2.c":{"holder":"old-agent","intent":"stale view","acquired_at":"$NOW","ttl_seconds":600}},
 "whispers":[{"from":"old-agent","message":"legacy note","timestamp":"$NOW"}]}
JSON
(cd "$T/wa" && "$C" sniff agent-a src | grep -q 'held by old-agent.*imported from') && ok "T8 sniff reads legacy .crumb.local (in memory)" || bad "T8 legacy read"
[ ! -e "$STORE/agents/old-agent.json" ] && ok "T8 sniff does not write the store" || bad "T8 sniff wrote"
(cd "$T/wa" && "$C" update agent-a src "trigger import" >/dev/null)
out=$(cd "$T/wb" && "$C" sniff agent-b src)
echo "$out" | grep -q "src/legacy.c.*held by old-agent.*imported from $T/wa" && ok "T8 legacy lock imported with provenance (worktree path)" || bad "T8 import"
echo "$out" | grep -q 'src/legacy2.c.*held by agent-new' && ok "T8 legacy never overrides newer shared lock" || bad "T8 override"
echo "$out" | grep -q 'whisper old-agent' && ok "T8 legacy whisper imported" || bad "T8 whisper"
(cd "$T/wb" && "$C" claim agent-b src legacy.c "x" >/dev/null); [ $? -eq 2 ] && ok "T8 imported lock blocks other worktree" || bad "T8 block"
[ -f "$T/wa/src/.crumb.local" ] && ok "T8 legacy file left in place" || bad "T8 file kept"
n1=$(grep -c old-agent "$STORE/dirs/src.json"); (cd "$T/wa" && "$C" update agent-a src "again" >/dev/null); n2=$(grep -c old-agent "$STORE/dirs/src.json")
[ "$n1" -eq "$n2" ] && ok "T8 import is one-time (no duplicates)" || bad "T8 duplicates"
# outside any git repo: legacy behaviour kept, sniff says so
mkdir -p "$T/plain" && "$C" claim p1 "$T/plain" x.c "plain" | grep -q CLAIMED && [ -f "$T/plain/.crumb.local" ] && "$C" sniff p1 "$T/plain" | grep -q 'shared coordination: none (not a git repository)' && ok "non-git dir keeps .crumb.local, sniff reports none" || bad "non-git"
cd "$T/r" || exit 1
# backfill: known commit with a PR number lands in the right dir with the right sha; second run changes nothing
git add -A >/dev/null 2>&1; git -c user.name=t -c user.email=t@t commit -qm "feat: add b (#7)" >/dev/null 2>&1
sha=$(git rev-parse --short=7 HEAD)
HOME="$T/home" "$C" backfill . >/dev/null
grep -q '"pr": 7' src/.crumb && grep -q "\"sha\": \"$sha\"" src/.crumb && grep -q backfill-git src/.crumb && ok "backfill: PR 7 + sha in src/.crumb" || bad "backfill entry"
grep -q "$sha #7" docs/crumbs/BACKFILL.md && ok "BACKFILL.md lists commit" || bad "BACKFILL.md"
HOME="$T/home" "$C" backfill . | grep -q 'updated 0' && HOME="$T/home" "$C" backfill . | grep -q 'BACKFILL.md: unchanged' && ok "backfill idempotent" || bad "backfill idempotent"
# ---- RFC-0002 section 7: crumb explain ----
cd "$T/r" || exit 1
ex=$("$C" explain src)
for h in 'NEAREST CRUMB' 'INHERITED INVARIANTS' 'SHARED COORDINATION' 'RECENT COMMITS' 'EVIDENCE REFERENCES' 'NEWEST CONTINUATION'; do
  echo "$ex" | grep -q "^== $h ==" && ok "explain prints section: $h" || bad "explain section: $h"
done
echo "$ex" | grep -q 'purpose: Hand written C sources' && echo "$ex" | grep -q 'invariant: no globals' && ok "explain shows nearest .crumb purpose + invariants" || bad "explain nearest"
echo "$ex" | grep -q 'feat: add b (#7)' && ok "explain lists commits touching the path" || bad "explain commits"
"$C" explain src/a.c | grep -q 'repository path: src/a.c' && ok "explain accepts a file" || bad "explain file"
echo "$ex" | grep -q '(none touches this path)' && ok "explain: no continuation yet" || bad "explain none"
echo '{"version":1,"dir_path":"x","history":[]}' > /dev/null
"$C" claim agent-x src a.c "explain test" >/dev/null; "$C" whisper agent-x src - "explain whisper" >/dev/null
ex=$("$C" explain src); echo "$ex" | grep -q 'held by agent-x' && echo "$ex" | grep -q 'whisper agent-x -> all: explain whisper' && ok "explain shows shared locks + whispers" || bad "explain coordination"
STORE=$(git rev-parse --absolute-git-dir)/crumb/v1; mkdir -p "$STORE/continuations"
cat > "$STORE/continuations/cc-9001-test.json" <<JSON
{"acr_version":1,"identity":{"checkpoint_id":"cc-9001-test","created_by":"tester","sealed_at":"2026-10-04T10:00:00Z","reason":"explain test"},
 "state":{"items":[{"tag":"PROVEN","claim":"src parser works","evidence":["commit:abc1234"]}]},
 "evidence":{"commits":["abc1234"],"prs":["repo#7"],"receipts":[],"tests":[{"name":"parser","result":"PASS"}]},
 "coordination":{"owned_paths":["src/"],"scope":[],"do_not_touch":[]},"revalidation":{"status":"UNVERIFIED"}}
JSON
cat > "$STORE/continuations/cc-9002-other.json" <<JSON
{"identity":{"checkpoint_id":"cc-9002-other","sealed_at":"2026-10-04T11:00:00Z"},"state":{"items":[{"tag":"OPEN","claim":"docs thing"}]},"coordination":{"scope":["docs/.crumb"]}}
JSON
ex=$("$C" explain src)
echo "$ex" | grep -q 'id: cc-9001-test' && echo "$ex" | grep -q '\[PROVEN\] src parser works' && echo "$ex" | grep -q 'continuation test: parser -> PASS' && ok "explain surfaces continuation whose owned_paths match" || bad "explain continuation"
echo "$ex" | grep -q 'cc-9002-other' && bad "explain ignores continuation about another path" || ok "explain ignores continuation about another path"
"$C" explain docs | grep -q 'id: cc-9002-test\|id: cc-9002-other' && ok "explain matches via coordination.scope" || bad "explain scope"
"$C" explain "$T/nonexistent" >/dev/null 2>&1; [ $? -ne 0 ] && ok "explain on missing path fails" || bad "explain missing"
# ---- RFC-0003: Crumb Compiler (compile / verify / status / propose / context) ----
printf 'abc' | "$C" sha256 | grep -q '^ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad$' && ok "C3 sha256 known vector (abc)" || bad "C3 sha256 vector"
head -c 300000 /dev/urandom > "$T/rand.bin"
[ "$("$C" sha256 < "$T/rand.bin")" = "$(sha256sum < "$T/rand.bin" | cut -c1-64)" ] && ok "C3 sha256 matches sha256sum on 300 KB" || bad "C3 sha256 vs sha256sum"
CC3="$T/cc3"; mkdir -p "$CC3/src/deep" "$CC3/docs" "$CC3/evidence" && cd "$CC3" || exit 1
git init -q -b main . && echo 'int a;' > src/a.c && echo 'int b;' > src/deep/b.c && echo n > docs/n.md && echo r > evidence/r.json && echo top > README
"$C" seed . >/dev/null; git add -A && git -c user.name=t -c user.email=t@t commit -qm init
"$C" status . | grep -q 'UNCOMPILED' && ok "C3 status: fresh crumbs are UNCOMPILED" || bad "C3 status uncompiled"
"$C" verify . >/dev/null; [ $? -eq 1 ] && ok "C3 verify exits 1 on uncompiled crumbs" || bad "C3 verify uncompiled"
"$C" compile . | grep -q 'rewritten' && ok "C3 compile runs" || bad "C3 compile"
git add -A && git -c user.name=t -c user.email=t@t commit -qm compiled
"$C" compile . | grep -q ', 0 rewritten' && ok "C3 fixed point: second compile rewrites 0" || bad "C3 fixed point"
"$C" verify . | grep -q 'OK' && ok "C3 verify OK after compile" || bad "C3 verify OK"
git -c user.name=t -c user.email=t@t commit -q --allow-empty -m "empty" && "$C" verify . >/dev/null && ok "C3 empty commit keeps verify OK (stamps are not inputs)" || bad "C3 empty commit"
echo 'int b2;' > src/deep/b.c; git add -A
out=$("$C" verify .); st=$(echo "$out" | grep '^STALE' | awk '{print $2}' | sort | tr '\n' ' ')
[ "$st" = ". src src/deep " ] && ok "C3 touching src/deep/b.c: STALE is exactly src/deep, src and the root (ancestors only)" || bad "C3 ancestor-only staleness (got: $st)"
echo "$out" | grep -q 'docs\|evidence' && bad "C3 sibling dirs stay current" || ok "C3 sibling dirs stay current"
"$C" compile . >/dev/null; "$C" verify . >/dev/null && ok "C3 compile after the change: verify OK again" || bad "C3 recompile"
git add -A; git -c user.name=t -c user.email=t@t commit -qm "change + compile"; "$C" verify . >/dev/null && ok "C3 verify stays OK after the compiled change is committed (last_commit is not an input, D3a)" || bad "C3 D3a last_commit"
before=$(jq -r .purpose docs/.crumb); sem0=$(jq -cS '{purpose,layer,invariants,exports,related,boundaries}' src/.crumb)
"$C" propose docs "Design notes and decision records" | grep -q PROPOSED && ok "C3 propose prints PROPOSED" || bad "C3 propose"
[ "$(jq -r .purpose docs/.crumb)" = "$before" ] && [ "$(jq -r .extensions.proposed.purpose docs/.crumb)" = "Design notes and decision records" ] && [ "$(jq -r .extensions.proposed.status docs/.crumb)" = PROPOSED ] && ok "C3 propose never changes .purpose, writes extensions.proposed" || bad "C3 propose purpose"
[ "$sem0" = "$(jq -cS '{purpose,layer,invariants,exports,related,boundaries}' src/.crumb)" ] && ok "C3 compile never touches the semantic kernel" || bad "C3 kernel"
ctx=$("$C" context src/deep/b.c)
for h in 'TREE' 'YOUR TASK TOUCHES' 'READ THESE CRUMBS' 'CURRENT CONFLICTS' 'RELEVANT CONTINUATION'; do
  echo "$ctx" | grep -q "^== $h" && ok "C3 context prints section: $h" || bad "C3 context section: $h"
done
"$C" verify . >/dev/null && ok "C3 propose does not stale crumbs (proposal is not a digest input)" || bad "C3 propose stale"
echo x >> src/a.c; git add -A; "$C" context src/a.c | grep -q "^Crumbs STALE: 2 .*run crumb compile" && ok "C3 context freshness: STALE: n (run crumb compile)" || bad "C3 context stale line"
"$C" compile . >/dev/null; "$C" context src | grep -q '^Crumbs CURRENT at HEAD' && ok "C3 context freshness: CURRENT at HEAD <sha>" || bad "C3 context current line"
"$C" context src/deep/b.c | grep -q 'src/.crumb' && "$C" context src/deep/b.c | grep -q 'src/deep/.crumb' && ok "C3 context recommends the path's ancestor crumbs" || bad "C3 context ancestors"
"$C" context . | grep -q 'PROPOSED: Design notes' && ok "C3 context shows PROPOSED purpose for a child without .purpose" || bad "C3 context proposed"
"$C" claim lane-x src src/a.c "ctx test" >/dev/null; "$C" context src/a.c | grep -q 'held by lane-x' && ok "C3 context lists a shared-store lock on the path" || bad "C3 context conflict"
"$C" context docs | grep -q 'held by lane-x' && bad "C3 context ignores locks elsewhere" || ok "C3 context ignores locks elsewhere"
"$C" close lane-x src src/a.c >/dev/null
[ "$("$C" context src | wc -l)" -lt 80 ] && ok "C3 context output is bounded" || bad "C3 context bounded"
# differential vs the shell reference (needs jq, git, sha256sum)
REF="$HERE/crumb-compile.sh"
if command -v jq >/dev/null 2>&1 && [ -f "$REF" ]; then
  diffgen() { # $1 repoA (shell) $2 repoB (C): every .crumb extensions.generated minus stamps must match
    r=0; for f in $(cd "$1" && find . -name .crumb -not -path './.git/*'); do
      a=$(jq -cS '.extensions.generated | del(.generated_at_commit, .compiled_at)' "$1/$f"); b=$(jq -cS '.extensions.generated | del(.generated_at_commit, .compiled_at)' "$2/$f")
      [ "$a" = "$b" ] || { echo "DIFF $f"; r=1; }
    done; return $r; }
  cd "$T" || exit 1; rm -rf dA dB; git clone -q --no-hardlinks "$CC3" dA && git clone -q --no-hardlinks "$CC3" dB
  (cd dA && sh "$REF" compile . >/dev/null) && (cd dB && "$C" compile . >/dev/null)
  diffgen "$T/dA" "$T/dB" >/dev/null && ok "C3 differential on scratch repo: generated blocks identical to crumb-compile.sh" || bad "C3 differential scratch"
  (cd dB && sh "$REF" verify . >/dev/null) && (cd dA && "$C" verify . >/dev/null) && ok "C3 each tool verifies the other's output" || bad "C3 cross verify"
  TOP=$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$TOP" ]; then
    rm -rf eA eB; git clone -q --no-hardlinks "$TOP" eA && git clone -q --no-hardlinks "$TOP" eB
    (cd eA && sh "$REF" compile . >/dev/null) && (cd eB && "$C" compile . >/dev/null)
    diffgen "$T/eA" "$T/eB" > "$T/diff.out" && ok "C3 differential on this repo: generated blocks identical" || { cat "$T/diff.out"; bad "C3 differential this repo"; }
    cmp -s "$T/eA/.crumb" "$T/eB/.crumb" 2>/dev/null; sed '/compiled_at/d' "$T/eA/tools/.crumb" > "$T/ta"; sed '/compiled_at/d' "$T/eB/tools/.crumb" > "$T/tb"
    cmp -s "$T/ta" "$T/tb" && ok "C3 whole .crumb file byte-identical apart from compiled_at (same commit stamp)" || bad "C3 file bytes"
  else echo "NOT_RUN differential on this repo (not in a git checkout)"; fi
else echo "NOT_RUN C3 differential (jq or crumb-compile.sh missing)"; fi
exit $fail
