# Brownian calibration program: public explainer (Wave 1)

Status date: 2026-09-30. This is the public account of how the hidden-law calibration program (code name Brownian) is run, what has been done, and where it departed from its plan. It deliberately leaves out every evaluator-only detail: hidden settings, thresholds, the list of model families, cell names, sample sizes, seed labels and preregistered signs. Those stay in a private evaluator repository until the final sealed run (BRN-10) is finished; after that they are published in full.

## What the program is for

AIEN will later be asked to find a hidden law in data it has never seen. Before any such result can mean anything, the scoring machinery has to be shown to work on cases where the right answer is known. Wave 1 is that check. It certifies the scorer; it is not a discovery claim, and no sentence in any report may say that AIEN discovered a physical law.

The score is description length: how many bits a model needs to describe both itself and the held-out data. A model that captures real structure saves bits compared with a declared baseline; the saving, with a bootstrap interval, is the score.

## How cheating by the operator is prevented

- **Commit, then reveal.** Before any sealed data exists, the SHA-256 fingerprint of the private profile (the full set of rules and thresholds) and of the frozen evaluator code is published in omega at `docs/brownian/PROFILE_COMMITMENT.txt`. After BRN-10 the files are published and anyone can check they match.
- **One shot per profile.** Each sealed run can be attempted once under a given profile. The tool writes an attempt record before it generates any sealed data, and it refuses a second attempt. A failure cannot be quietly retried.
- **No moving the goalposts.** No threshold or analysis choice may change after sealed scores exist. Any fix after a failure needs a new profile version, a new fingerprint and fresh sealed data, and the failed run stays in the record.
- **Sample sizes come from simulation**, fixed before any sealed data, never chosen after seeing results.
- **Access.** Humans may read the private material by request: email drake@aienos.com; after verification you get read-only access. Please do not paste it into any AI tool before the sealed run is finished.

## The ladder and where each rung stands

A claim is limited by the highest rung that passed. A later success never erases an earlier failure, and every failed or blocked rung is listed.

| rung | what it checks | status |
|---|---|---|
| CAL-0 | the evaluator is calibrated | PASS |
| EXP-001 | the compression bridge (ideal lengths match two real coders) | first attempt FAIL; successor EXP-001R PASS |
| EXP-002A | the scorer certifies the simplest known family | first profile BLOCKED; successor PASS |
| EXP-002B | the scorer certifies the second stage | PASS (without the Occam curve) |
| Occam curve | how the score trades model size against fit | INCOMPLETE |
| EXP-002C | the scorer certifies emerging structure, plus an intervention phase | PASS |
| EXP-002D | hostile and adversarial cases give their expected verdicts | INCOMPLETE (no wrong verdicts; one safety check cannot run in the frozen build) |
| interventional replication | the intervention effect repeats on fresh worlds | BLOCKED |
| EXP-003 | active experiment choice (Wave 2) | BLOCKED |
| H3 replay | stored scores replay byte for byte | PASS |
| H3 statistical | the preregistered hypotheses hold on sealed data | PASS |
| H4 | GPU rows | INCOMPLETE |
| H5 | six different compiler builds give the same scores | PASS |
| sensitivity | verdicts are stable under preset variants | BLOCKED |
| independent replication | independent implementation (in-house), not external lab | BLOCKED |

## Departures from the plan, in full

1. **EXP-001 failed, and was replaced.** The first compression-bridge run failed one audit: a single sealed test item was identical, in its visible part, to one development item. The cause was a small space of possible items in one category, not a leak of answers. The failure stands and is published (omega #95). A successor, EXP-001R, ran with the same candidates and criteria, a tightened and documented overlap rule and new seeds, and passed (omega #99).
2. **The profile binds Turing profile v1.1, not v1.0.** The Brownian profile names the Turing scoring profile it builds on. Because EXP-001 was replaced by EXP-001R, the frozen run binds the v1.1 Turing profile (the one EXP-001R passed under). The Brownian profile text itself was unchanged.
3. **A descriptive figure was wrong.** The frozen profile understated the worst-case false-alarm rate of one safety check, because an early calculation missed the largest cell. The check itself (its pass rule) was not changed; the corrected figure is used in every report.
4. **The fingerprint was published after the freeze, not before the development data.** The fingerprint's second line has to name the final code, which only exists after the freeze. It was published before any sealed data was generated. Certification fits no candidate to development data, so nothing was exposed.
5. **EXP-002A was BLOCKED under the first profile.** Every scientific check passed, but the plan required one comparison model to be fitted on a cell where that fit is mathematically undefined. The fit could not be made, the tool refused it as designed, and the plan's own rule turned that refusal into a block. The contradiction was in the plan, not in the data or the code. Fixing it after sealed scores existed would have been moving the goalposts, so it went to a new profile (v1.1) with one added rule: an exactly-determined comparison fit is not scored.
6. **The first attempt under v1.1 failed on a missing folder.** The operator script had not created one output folder. The tool records the attempt before it checks the folder, so the attempt was used up with no data produced. We did not delete that record. The attempt went to profile v1.2, which is v1.1 plus a note recording the failure, with no rule change, and the script was fixed. EXP-002A (as EXP-002AR), EXP-002B and EXP-002C then all passed under v1.2.
7. **One safety check was "not evaluated".** One stop condition compares a candidate's reported parameter intervals. Certification candidates report predictions, not parameter intervals, so the check has nothing to measure and is reported as not evaluated, with that reason. It must be defined before EXP-003, where candidates do report intervals.
8. **The Occam curve is INCOMPLETE.** Producing it needs extra cells, which would be a fourth profile in Wave 1. The profile limit is three unless Drake raises it. Until then the EXP-002B claim leaves out "with the Occam curve".
9. **Rungs blocked by rules, not by results.** Interventional replication and the sensitivity variants need new sealed data or new preset choices, so a new profile. EXP-003 needs a separate Wave 2 contract. The independent re-implementation would have to be briefed from the private profile, which no outside AI may see before the sealed run. The GPU rows are not defined in Wave 1. None of these is counted as passed.
10. **Outside review is deferred.** The plan asks for an outside AI to check the mathematics of each new profile. The confidentiality rule forbids showing the private material to any outside AI before the sealed run, so that review happens after BRN-10.
11. **Two build findings.** The two highest-optimisation builds in the six-build check refuse to compile under the strict warnings setting, because a piece of verdict description text is cut short. That is a wording defect, not a scoring one; those two builds were made with that single warning allowed, and all six builds agree exactly. Separately, the adapter that measures real coded lengths and runs one safety check was added to the shared code after this run's code was frozen, so the real-coder comparison and that safety check are not part of Wave 1. Both fixes wait for the next profile.

## What may be claimed

Only the outcome sentences in the profile may be used. A certification pass says the scorer behaves as specified on known cases. It says nothing about AIEN discovering anything.
