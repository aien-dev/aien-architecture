# ADR 0010: Canary Observations Are Measurements

**Status:** Accepted

## Context

The promotion path can fill a canary quota with caller-supplied success and latency, then sign the result. A signature over that record is easy to read as production evidence.

## Decision

A canary observation is a measured result of executing a candidate. A qualifying observation carries an observation id, the time it was observed, the candidate's artifact digest, a latency measured from that execution, and the status that execution returned. A new observation id is stored and counts once toward the production quota. The same id with the same canonical observation record is an idempotent success and does not count again. The same id with a different record is a conflict and does not count. Identity of the record is a canonical digest of that observation. A safety envelope is a signed wrapper. A signature can authenticate an observation. It cannot make a rehearsal into an observation. A synthetic rehearsal may use the same shape and carries provenance that makes it ineligible for the production quota. Production promotion rejects a quota satisfied by synthetic rehearsal.

## Consequences

Supervisor tests may keep a synthetic rehearsal loop. That loop cannot satisfy production promotion. The canonical record is one JSON object of every field, with keys in alphabetical order and no insignificant whitespace. `observed_at_ms` is a count of unix milliseconds. The digest is SHA-256 of those bytes. The same digest is an idempotent success. A different digest under the same observation id is a conflict.
