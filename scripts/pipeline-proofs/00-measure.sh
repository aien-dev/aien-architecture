#!/usr/bin/env bash
# 00: baseline timings of the crumb tool on a clean clone (no assertion beyond "the commands run").
# Records: compile (at HEAD, expected 0 rewritten), verify, status, context lookup on the deepest crumb path.
here="$(cd "$(dirname "$0")" && pwd)"; . "$here/lib.sh"
proof_begin 00 "crumb timings on a clean clone" "${1:-}"
clone_repo "$TMP/a"; cd "$TMP/a" || exit 1
L=$(leaf_crumb_dir .) || L=.
F=$(tracked_file_in . "$L")
measure compile_at_head $CRUMB compile .;  note "$(echo "$OUT" | tail -1)"; check "compile exits 0" [ "$RC" -eq 0 ]
measure verify          $CRUMB verify .;   note "$(echo "$OUT" | tail -1)"; check "verify exits 0 at HEAD" [ "$RC" -eq 0 ]
measure status          $CRUMB status .;   note "$(echo "$OUT" | tail -1)"; check "status exits 0" [ "$RC" -eq 0 ]
measure context_root    $CRUMB context .;  check "context . exits 0" [ "$RC" -eq 0 ]
measure context_leaf    $CRUMB context "$F"; check "context $F exits 0" [ "$RC" -eq 0 ]
num "crumbs=$(crumb_dirs . | wc -l)"; num "tracked_files=$(git ls-files | wc -l)"; num "leaf=$L"
proof_end
