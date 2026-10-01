#!/usr/bin/env bash
# Test for check_candidate.sh using a stub sha checker (no network).
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
good="$here/../qualification/candidates/CAND-0.toml"
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
echo "passed=$pass failed=$bad"
[ "$bad" -eq 0 ]
