#!/usr/bin/env python3
"""Refuse an overall R16 PASS without its candidate-bound qualification receipt."""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def verify(omega, roadmap):
    row = next(line for line in roadmap.splitlines() if line.startswith("| R16 orchestrator retirement |"))
    status = row.split("|")[2].strip()
    if status != "PASS":
        return "R16 overall qualification is not claimed"
    for path in (omega / "evidence/R16").glob("*.json"):
        try:
            raw = path.read_bytes()
            receipt = json.loads(raw)
            if receipt.get("schema") != "AIEN_RX_R16_ORCHESTRATOR_RETIRED_V1":
                continue
            if path.stem != hashlib.sha256(raw).hexdigest():
                continue
            if not (receipt.get("candidate_bound") is True and receipt.get("tree_dirty") is False
                    and receipt.get("silicon_observed") is True
                    and receipt.get("candidate_commit") == receipt.get("run_commit")
                    and len(receipt.get("candidate_commit", "")) == 40):
                continue
            gates = receipt.get("gates", {})
            if not all(gates.get(f"R16-G{i}") == "PASS" for i in range(1, 9)):
                continue
            if not receipt.get("production_entry_point") or receipt.get("remaining_unclassified_semantic_loop_count") != 0:
                continue
            return f"R16 qualified receipt: {path.name}"
        except (ValueError, TypeError, AttributeError):
            continue
    raise ValueError("R16 PASS has no valid final G1-G8 candidate-bound silicon receipt; inventory alone is insufficient")

if __name__ == "__main__":
    try:
        print(verify(Path(sys.argv[1]), (ROOT / "doctrine/ROADMAP.md").read_text()))
    except (IndexError, ValueError) as error:
        sys.exit(str(error))
