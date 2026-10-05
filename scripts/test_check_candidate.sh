#!/usr/bin/env bash
# Test for check_candidate.sh. Offline: sha existence is stubbed (CAND_SHA_CHECK) and,
# for the real gh code path, a fake `gh` on PATH. No network or auth needed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
chk="$here/check_candidate.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
stub="$tmp/stub.sh"
cat > "$stub" <<'S'
#!/usr/bin/env bash
[ "$2" != "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" ]
S
chmod +x "$stub"; export CAND_SHA_CHECK="$stub"
good="$here/testdata/cand-draft-fixture.toml"   # the 2026-10-01 draft, kept as a fixture so these tests do not depend on the live manifest
live="$here/../qualification/candidates/CAND-0.toml"
pass=0; bad=0
expect() { # expect <0|1> <label> <file>
  "$chk" "$3" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$1" ]; then pass=$((pass+1)); else bad=$((bad+1)); echo "TEST FAIL: $2 (rc=$rc)"; fi
}
expect 0 "CAND-0 valid" "$good"
sed '/^omega = /d' "$good" > "$tmp/a.toml";            expect 1 "missing omega" "$tmp/a.toml"
sed 's/^id = .*//' "$good" > "$tmp/b.toml";            expect 1 "missing id" "$tmp/b.toml"
sed 's/^omega = .*/omega = "abc123"/' "$good" > "$tmp/c.toml"; expect 1 "short sha" "$tmp/c.toml"
sed 's/^aienos = .*/aienos = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"/' "$good" > "$tmp/d.toml"; expect 1 "nonexistent sha" "$tmp/d.toml"
sed 's/^status = .*/status = "frozen"/' "$good" > "$tmp/e.toml"; expect 1 "frozen with UNBUILT" "$tmp/e.toml"
sed '/^omega-runtime/d;/^aienos-boot/d;/^aien-proof =/d' "$good" > "$tmp/f.toml"; expect 1 "no executables" "$tmp/f.toml"
H64a=$(printf 'a%.0s' $(seq 64)); H64b=$(printf 'b%.0s' $(seq 64)); H64c=$(printf 'c%.0s' $(seq 64))
Z64=$(printf '0%.0s' $(seq 64))
frozen() { # frozen <out> : valid frozen manifest with real-looking digests
  sed -e 's/^status = .*/status = "frozen"/' -e "s/^omega-runtime = .*/omega-runtime = \"$H64a\"/" \
      -e "s/^aienos-boot-image = .*/aienos-boot-image = \"$H64b\"/" -e "s/^aien-proof = .*/aien-proof = \"$H64c\"/" "$good" > "$1"
}

# --- new: positive frozen case
frozen "$tmp/fz.toml";                                          expect 0 "frozen with real digests" "$tmp/fz.toml"
# --- new: all-zero digest rejected (frozen and draft)
sed "s/^aien-proof = .*/aien-proof = \"$Z64\"/" "$tmp/fz.toml" > "$tmp/z.toml"; expect 1 "all-zero digest (frozen)" "$tmp/z.toml"
sed "s/^aien-proof = .*/aien-proof = \"$Z64\"/" "$good" > "$tmp/z2.toml";        expect 1 "all-zero digest (draft)" "$tmp/z2.toml"
# --- new: '#' inside a quoted value is kept, not truncated
sed "s/^aien-proof = .*/aien-proof = \"${H64c}#frag\"/" "$tmp/fz.toml" > "$tmp/h.toml"; expect 1 "digest with # is not truncated into validity" "$tmp/h.toml"
sed 's/^note = .*/note = "issue #5 and #6"  # trailing comment/' "$good" > "$tmp/n.toml"; expect 0 "# in note and trailing comment ok" "$tmp/n.toml"
# --- new: contracts pinned
sed '/^crumb-spec = /d' "$good" > "$tmp/k1.toml";               expect 1 "missing crumb-spec" "$tmp/k1.toml"
sed '/^spark-crumbs = /d' "$good" > "$tmp/k2.toml";             expect 1 "missing spark-crumbs" "$tmp/k2.toml"
sed 's/^spark-crumbs = .*/spark-crumbs = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"/' "$good" > "$tmp/k3.toml"; expect 1 "nonexistent spark-crumbs sha" "$tmp/k3.toml"
sed 's/^crumb-spec = .*/crumb-spec = "abc"/' "$good" > "$tmp/k4.toml"; expect 1 "short crumb-spec sha" "$tmp/k4.toml"

# --- new: real gh code path, via a faithful offline stub of `gh` on PATH.
# The stub accepts `gh api repos/aien-dev/<repo>/commits/<sha> -q .sha`, prints the sha and
# exits 0 for known shas, prints a 404 message and exits 1 for deadbeef..., and logs argv.
mkdir -p "$tmp/bin"; log="$tmp/gh.log"
cat > "$tmp/bin/gh" <<'S'
#!/usr/bin/env bash
echo "$*" >> "$GH_STUB_LOG"
[ "$1" = "api" ] || exit 2
sha="${2##*/}"
if [ "$sha" = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" ]; then echo "gh: Not Found (HTTP 404)" >&2; exit 1; fi
echo "$sha"
S
chmod +x "$tmp/bin/gh"
ghexpect() { # ghexpect <rc> <label> <file>
  ( unset CAND_SHA_CHECK; PATH="$tmp/bin:$PATH" GH_STUB_LOG="$log" "$chk" "$3" >/dev/null 2>&1 ); rc=$?
  if [ "$rc" = "$1" ]; then pass=$((pass+1)); else bad=$((bad+1)); echo "TEST FAIL: $2 (rc=$rc)"; fi
}
: > "$log"
ghexpect 0 "gh path: CAND-0 valid" "$good"
grep -q 'api repos/aien-dev/crumb-spec/commits/10b825133580f7a4388ce78aca64b5db52c5d35b ' "$log" \
  && pass=$((pass+1)) || { bad=$((bad+1)); echo "TEST FAIL: gh was not called for crumb-spec"; }
[ "$(wc -l < "$log")" -eq 7 ] && pass=$((pass+1)) || { bad=$((bad+1)); echo "TEST FAIL: expected 7 gh calls, got $(wc -l < "$log")"; }
ghexpect 1 "gh path: 404 sha rejected" "$tmp/d.toml"
ghexpect 1 "gh path: 404 contract sha rejected" "$tmp/k3.toml"


# --- live candidate manifest (CAND-0 is frozen): valid, 9 pins checked through the gh path, and its optional pins bite.
expect 0 "live CAND-0 valid" "$live"
grep -q '^status = "frozen"' "$live" && pass=$((pass+1)) || { bad=$((bad+1)); echo "TEST FAIL: live CAND-0 is not frozen"; }
: > "$log"
ghexpect 0 "gh path: live CAND-0 valid" "$live"
[ "$(wc -l < "$log")" -eq 9 ] && pass=$((pass+1)) || { bad=$((bad+1)); echo "TEST FAIL: expected 9 gh calls for the live manifest, got $(wc -l < "$log")"; }
sed 's/^physics = .*/physics = "abc123"/' "$live" > "$tmp/p1.toml";   expect 1 "short physics sha" "$tmp/p1.toml"
sed 's/^interplane = .*/interplane = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"/' "$live" > "$tmp/p2.toml"; expect 1 "nonexistent interplane sha" "$tmp/p2.toml"
sed 's/^omega-runtime = .*/omega-runtime = "UNBUILT"/' "$live" > "$tmp/p3.toml"; expect 1 "frozen live manifest with UNBUILT" "$tmp/p3.toml"

# --- new: mutants. Each broken copy of the checker must wrongly accept the bad input,
# proving the new test above really depends on the new check.
mutant() { # mutant <label> <sed-expr> <input-file>
  sed "$2" "$chk" > "$tmp/mut.sh"; chmod +x "$tmp/mut.sh"
  if cmp -s "$chk" "$tmp/mut.sh"; then bad=$((bad+1)); echo "TEST FAIL: mutant '$1' did not change the checker"; return; fi
  "$tmp/mut.sh" "$3" >/dev/null 2>&1; rc=$?
  if [ "$rc" = 0 ]; then pass=$((pass+1)); else bad=$((bad+1)); echo "TEST FAIL: mutant '$1' still rejected (rc=$rc), test does not bite"; fi
}
mutant "no zero-digest check" '/all zero/d' "$tmp/z.toml"
mutant "old # truncation" 's/^while IFS= read -r line; do$/while IFS= read -r line; do line="${line%%#*}"/' "$tmp/h.toml"
mutant "contracts not required" 's/ contracts.crumb-spec contracts.spark-crumbs;/;/' "$tmp/k1.toml"
mutant "optional pins not checked" 's/for r in commits.physics commits.interplane; do/for r in; do/' "$tmp/p1.toml"
mutant "optional pin sha existence not checked" '/^for r in commits.physics/,/^done$/s/sha_exists "\$repo" "\$s" || err .*$/true/' "$tmp/p2.toml"
echo "passed=$pass failed=$bad"
[ "$bad" -eq 0 ]
