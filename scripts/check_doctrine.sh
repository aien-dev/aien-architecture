#!/usr/bin/env bash
# check_doctrine.sh — doctrine consistency check (aien-dev/aien-architecture#7).
#
# Fails on stale normative doctrine: Alpha naming, fixed EL1 handoff claims,
# obsolete roadmap generations (28/31-milestone, M27 closure), milestone status
# or roadmap tables duplicated outside doctrine/ROADMAP.md, and milestone code
# identifiers cited under the wrong milestone number.
#
# Text between these markers is historical provenance and is not checked:
#   <!-- HISTORICAL-PROVENANCE:BEGIN -->
#   <!-- HISTORICAL-PROVENANCE:END -->
#
# Pure bash + grep + awk. No Python (project rule). Exit 0 = pass, 1 = fail.
#
# Usage: scripts/check_doctrine.sh [repo-root]

set -u
export LC_ALL=C

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT" || { echo "check_doctrine: cannot cd to $ROOT" >&2; exit 2; }

ROADMAP="doctrine/ROADMAP.md"

# Files in scope: the doctrine corpus plus the per-milestone specifications.
FILES=()
for f in doctrine/*.md docs/milestone-*-spec.md; do
  [ -f "$f" ] && FILES+=("$f")
done

# ---------------------------------------------------------------------------
# DEFERRED allowlist. Findings in these files are reported but do not fail the
# check. Every entry must name the issue that owns the fix; remove the entry
# when that issue closes.
# ---------------------------------------------------------------------------
declare -A DEFERRED=(
)

FAILS=0
DEFERS=0

report() { # report <check> <file> <line> <text>
  local check="$1" file="$2" line="$3" text="$4"
  if [ -n "${DEFERRED[$file]+x}" ]; then
    printf 'DEFERRED (%s) [%s] %s:%s: %s\n' "${DEFERRED[$file]}" "$check" "$file" "$line" "$text"
    DEFERS=$((DEFERS + 1))
  else
    printf 'FAIL [%s] %s:%s: %s\n' "$check" "$file" "$line" "$text"
    FAILS=$((FAILS + 1))
  fi
}

# Print a file with historical-provenance lines blanked (line numbers kept).
normative() {
  awk '
    /<!-- HISTORICAL-PROVENANCE:BEGIN -->/ { hist = 1; print ""; next }
    /<!-- HISTORICAL-PROVENANCE:END -->/   { hist = 0; print ""; next }
    { print (hist ? "" : $0) }
  ' "$1"
}

# check_pattern <check-name> <ERE> [exempt-file]
check_pattern() {
  local name="$1" re="$2" exempt="${3:-}" f hit ln txt
  for f in "${FILES[@]}"; do
    [ "$f" = "$exempt" ] && continue
    while IFS= read -r hit; do
      ln="${hit%%:*}"; txt="${hit#*:}"
      report "$name" "$f" "$ln" "$(printf '%s' "$txt" | sed 's/^[[:space:]]*//' | cut -c1-160)"
    done < <(normative "$f" | grep -nE -- "$re")
  done
}

# --- 0. Historical markers must be balanced --------------------------------
for f in "${FILES[@]}"; do
  bad=$(awk '
    /<!-- HISTORICAL-PROVENANCE:BEGIN -->/ { if (open) { print NR; exit } open = NR; next }
    /<!-- HISTORICAL-PROVENANCE:END -->/   { if (!open) { print NR; exit } open = 0; next }
    END { if (open) print open }
  ' "$f")
  [ -n "$bad" ] && report "unbalanced-historical-marker" "$f" "$bad" "HISTORICAL-PROVENANCE marker without partner"
done

# --- 1. Forbidden stale normative patterns ---------------------------------
check_pattern "alpha-naming" \
  '\bALPHA\b|\bAlpha\b|\balpha\.(bin|manifest|sha256|decode|memory-map|control-flow|audit)\b'

check_pattern "fixed-el1-handoff" \
  'Monotonic Handoff \(EL1\)|Handoff \(EL1\)|EL1 [Hh]andoff|strictly at \*\*EL1|EL1 Jump|at EL1 privilege level'

check_pattern "obsolete-m27-closure" \
  '(Milestone|MILESTONE|\bM) ?27\b[^|]*SOVEREIGN(_MACHINE)?_CLOSURE|SOVEREIGN(_MACHINE)?_CLOSURE[^|]*(Milestone|MILESTONE|\bM) ?27\b|(Milestone|MILESTONE|M) ?27\b[^|]*AIEN_HUMAN_INTERFACE|AIEN_HUMAN_INTERFACE[^|]*(Milestone|MILESTONE|\bM) ?27\b'

check_pattern "obsolete-roadmap-generation" \
  '\b(28|31)-[Mm]ilestone|[Tt]wenty-eight (precise )?milestones|[Tt]hirty-one milestones|^MILESTONE [0-9]+ +— |\bM[0-9]+ ?(-|–) ?M27\b'

check_pattern "retired-milestone-identifier" \
  '\b(BOOTSTRAP_SEED_ATLAS|ATLAS_BAREMETAL_BOOT|ATLAS_MEASUREMENT_CHAIN|ATLAS_STAGE2_ELIMINATION|PHYSICS_CORE_MEMBRANE|SENTINEL_GATE_[0-9]|AIEN_SEED_TRAINING|AIEN_SEED_TOPOLOGY)\b'

# Milestone status lives only in ROADMAP.md.
check_pattern "status-outside-roadmap" \
  '\[(COMPLETE|IN PROGRESS|REOPENED[^]]*|COMPLETE / QEMU QUALIFIED|QEMU QUALIFIED)\]|PHYSICS_BOOT[^|]*\bCOMPLETE\b' \
  "$ROADMAP"

# The roadmap table itself lives only in ROADMAP.md.
check_pattern "duplicate-roadmap-table" \
  '^[[:space:]]*M[0-9]{1,2}:[[:space:]]+[A-Z][A-Z0-9_]{3,}|^\| \*\*M[0-9]{1,2}\*\* \|' \
  "$ROADMAP"

# --- 2. Physics Zero numbering must be M27-M35 ------------------------------
# (ROADMAP.md itself is checked row-by-row in section 3.)
for f in "${FILES[@]}"; do
  [ "$f" = "$ROADMAP" ] && continue
  while IFS= read -r hit; do
    report "physics-zero-range" "$f" "${hit%%:*}" "${hit#*:}"
  done < <(normative "$f" | awk '
    # Only ranges labelled as Physics Zero: "Physics Zero ... Mx-My" (within
    # 30 chars) or "Mx-My (Physics Zero".
    {
      s = $0
      while (match(s, /[Pp]hysics [Zz]ero[^.]{0,30}M[0-9]+ ?[-–] ?M[0-9]+|M[0-9]+ ?[-–] ?M[0-9]+ ?\([Pp]hysics [Zz]ero/)) {
        t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        match(t, /M[0-9]+ ?[-–] ?M[0-9]+/); r = substr(t, RSTART, RLENGTH)
        gsub(/ /, "", r); sub(/–/, "-", r)
        if (r != "M27-M35") { print NR ":" $0; break }
      }
    }')
done

# --- 3. ROADMAP.md structure ------------------------------------------------
if [ ! -f "$ROADMAP" ]; then
  report "roadmap-missing" "$ROADMAP" 0 "canonical roadmap file not found"
else
  while IFS= read -r msg; do
    report "roadmap-structure" "$ROADMAP" "${msg%%:*}" "${msg#*:}"
  done < <(normative "$ROADMAP" | awk -F'|' '
    /^\| \*\*M[0-9]+\*\* \|/ {
      m = $2; gsub(/[ *M]/, "", m); m = m + 0; st = $6; gsub(/^ +| +$/, "", st)
      if (m + 0 != n) print NR ": expected row M" n ", found M" m
      if (st !~ /^(COMPLETE|COMPLETE \/ QEMU QUALIFIED|REOPENED \/ IN PROGRESS|IN PROGRESS|PLANNED)$/)
        print NR ": M" m " has unknown status \"" st "\""
      era = $3; gsub(/^ +| +$/, "", era)
      if (era == "Physics Zero Discovery" && (m < 27 || m > 35)) print NR ": M" m " is outside Physics Zero M27-M35"
      if ((m >= 27 && m <= 35) && era != "Physics Zero Discovery") print NR ": M" m " must be in the Physics Zero Discovery era"
      if (era == "General AIEN" && (m < 36 || m > 40)) print NR ": M" m " is outside General AIEN M36-M40"
      n++
    }
    END { if (n != 41) print "0: expected 41 roadmap rows (M0-M40), found " n }')
fi

# --- 4. Milestone code identifiers must carry their ROADMAP number ----------
# Build CODE -> number from the canonical table, then flag any citation outside
# ROADMAP.md that pairs a code with a different milestone number, e.g.
# "Milestone 14 (`OMEGA_LIVING_MATVEC`)" or "M27: AIEN_HUMAN_INTERFACE".
if [ -f "$ROADMAP" ]; then
  MAP=$(normative "$ROADMAP" | awk -F'|' '/^\| \*\*M[0-9]+\*\* \|/ {
    m = $2; gsub(/[ *M]/, "", m); c = $4; gsub(/[ `]/, "", c); print c "=" m }')
  for f in "${FILES[@]}"; do
    [ "$f" = "$ROADMAP" ] && continue
    while IFS= read -r hit; do
      report "milestone-number-mismatch" "$f" "${hit%%:*}" "${hit#*:}"
    done < <(normative "$f" | awk -v map="$MAP" '
      BEGIN { k = split(map, pairs, "\n"); for (i = 1; i <= k; i++) { split(pairs[i], p, "="); num[p[1]] = p[2] } }
      {
        line = $0
        # "Milestone N (`CODE`)", "MN: CODE", "M N — CODE"
        s = line
        while (match(s, /(Milestones?|MILESTONE|\<M) ?[0-9]+[^A-Za-z0-9]{1,6}[A-Z][A-Z0-9_]+/)) {
          t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
          match(t, /[0-9]+/); n = substr(t, RSTART, RLENGTH)
          match(t, /[A-Z][A-Z0-9_]+$/); c = substr(t, RSTART, RLENGTH)
          if ((c in num) && num[c] != n) { print NR ":" c " cited as M" n ", is M" num[c] " in ROADMAP.md: " line; next }
        }
        # "`CODE` (Milestone N ...)", "CODE (MN)"
        s = line
        while (match(s, /[A-Z][A-Z0-9_]+`?[^A-Za-z0-9]{1,4}\((Milestones?|MILESTONE|M) ?[0-9]+/)) {
          t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
          match(t, /^[A-Z][A-Z0-9_]+/); c = substr(t, RSTART, RLENGTH)
          match(t, /[0-9]+$/); n = substr(t, RSTART, RLENGTH)
          if ((c in num) && num[c] != n) { print NR ":" c " cited as M" n ", is M" num[c] " in ROADMAP.md: " line; next }
        }
      }
      ')
  done
fi

# --- Summary ------------------------------------------------------------------
echo "----------------------------------------------------------------------"
echo "check_doctrine: scanned ${#FILES[@]} files; ${FAILS} failure(s); ${DEFERS} deferred finding(s)."
if [ "$FAILS" -gt 0 ]; then
  echo "check_doctrine: FAIL"
  exit 1
fi
echo "check_doctrine: PASS"
exit 0
