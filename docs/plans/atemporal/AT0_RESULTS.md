# AT-0 results: independent scientific review (Agent 6)

Status: REVIEWED. Gate AT0-G7 of the charter. This file is owned by Agent 6 and grades the claims of the AT-0 program against the recorded evidence. It is not a physics result. Every PASS below means "the software conforms to the frozen specification on the tested cases", and nothing more.

## 1. What this review graded

- Evidence: omega commit `bacc4b6` (PR 370, third qualification run), folder `evidence/AT0/20261010T005447Z-712469d/`, candidate source `712469d`, contracts aien-architecture `fe86e43` (AT0_CASE_V1 `d90af74b...`, AT0_RESULT_V2 `bd0f9eb8...`), spec `AT0_SPEC.md` at `68f47e2`. Report: omega issue 358, comment 6091916338.
- Hidden set: omega `evaluator/results/hidden-run-bff4a428/` (Agent 4, candidate `bff4a42`, comment 6091815405). Six withheld cases H1 to H6 revealed against the commitment digest published before the candidate existed.
- Earlier runs 1 and 2 (`a4ff532`, `aaa2474`) were read for the defect history; they are not graded.
- The reviewer read the three code bases (engine C11, oracle Rust, evaluator C11), the receipts, and recomputed values and digests by hand where stated below.

## 2. Claims and verdicts

| # | Claim (charter gate) | Verdict | Evidence and reviewer check |
|---|---|---|---|
| C1 | Contract freeze (G0): both contracts and the spec are merged and frozen; digests match | PASS | `AT0_FREEZE.md` rows verified on aien-architecture main; CASE_V1 unchanged since `044c9d1`; RESULT_V1 superseded by V2 under charter section 8 without editing V1; control C0 of the run re-checks the digests. |
| C2 | Codec conformance (G1): engine, oracle and evaluator each parse and re-emit the frozen example byte for byte and give every refusal its exact code | PASS | Each code base reproduces the three published digests (`3cf4ca4f...`, `a13fb02d...`, `ed16c95c...`). Refusals 42/42 exact in run 3 after three contract readings by Agent 0 (D2, D3, D11: shape before range). Evaluator public codec 68/68. |
| C3 | Isolation (G2): no clock, random, network, process or thread reaches the compute objects; mutants with a hidden clock are caught | PASS, limited | Symbol scans by two independent scanners on 11 C objects and the Rust rlib; mutants caught: C `clock_gettime`, Rust `std::time::SystemTime`, Rust `extern "C" clock_gettime`, fortified libc read (`__fread_chk`). Limit: scans see named symbols only (section 4). |
| C4 | Oracle calibration (G3): the oracle reproduces the spec hand tables; shares no code with the engine | PASS | Oracle fixtures reproduce spec section 13 tables (Agent 2, PR 364, all 16 values of 13.2 P2). Reviewer hand check of P1 from the section 13.1 formulas: X 1, 1/2, 0, 1/2; Y 1/2, 1, 1/2, 0; Z 1/2; clock marginal 1/4; kernel dimension 2; matches the oracle lines to within 2^-52. Different language, no shared source. |
| C5 | Positive arm (G4): every positive case PASS with expectation met | PASS | 12/12 public cases; hidden H1 to H4 PASS. |
| C6 | Negative arm (G5): every negative case FAIL with exactly its expected codes; planted faults are caught | PASS, with a stated power limit | 8/8 public with exact codes; hidden H5, H6 exact. Axis-swap mutant caught 12/12; Y-sign mutant caught 9/12; the integrator explains the three misses as cases whose states and readings never expose the Y sign (rotation about y, Hamiltonian proportional to identity, h along z with an h0 shift); the reviewer accepts the explanation for the first two by inspection and did not re-derive the third; hidden-clock mutants caught. Reviewer check of N2 (half-covered kernel): conditional state is the single surviving eigenstate (X 1/2, Y 1/2, Z 0) while the Schrodinger reference gives Y 1; FAIL `SCHRODINGER_DEVIATION_EXCEEDED` is the correct prediction of the model, not a software fault. |
| C7 | Independent verification (G6): the evaluator re-derives every check, outcome, `verdict_id` and `evidence_digest` from result files alone and agrees | PASS | 20/20 public and 6/6 hidden. Reviewer recomputed `verdict_id` (`88de580d...`) and `evidence_digest` (`2a940470...`) of P1 from the file bytes with `sha256sum`: both match. |
| C8 | Semantic identity is wall-clock independent on the tested conditions (Atemporal Postulate v1.1 discipline) | PASS | Runs 2 s apart under TZ=UTC and TZ=Asia/Tokyo: values blocks byte-identical 20/20, `verdict_id` equal 20/20, `evidence_digest` different by construction. Across runs 2 and 3 (different candidate commits `aaa2474` and `712469d`): P1 `verdict_id` identical. |
| C9 | Blinded qualification: the candidate was judged by a party that could not have influenced it | INCONCLUSIVE | The evaluator reports UNISOLATED: same host, same account, all agents are sessions of one operator. The hidden set was committed by digest before the candidate existed, which is the strongest blinding available here, but it is not enforceable against the operator. |
| C10 | Rigorous error bounds | INCONCLUSIVE (not claimed) | Engine and oracle both declare `ESTIMATED` bounds (binary64, 1 ulp libm assumption, one platform). Case N5 shows the system refuses a RIGOROUS demand rather than pretending. No RIGOROUS result exists. |
| C11 | Time is emergent / the physical world has no fundamental clock | NOT TESTED | Out of scope by charter. A finite Page-Wootters model reproducing Schrodinger evolution in software is a consistency check of a known construction, not evidence about nature. |

## 3. What the evidence supports, in one paragraph

The AT-0 software (engine, oracle, evaluator, runner) conforms to AT0_SPEC.md on the twelve public positive classes, eight negative classes, forty-two refusal classes and six hidden cases, with three independent code bases agreeing bit for bit on every discrete verdict, with semantic identities that do not depend on wall-clock time, and with a test suite that catches the planted faults it was designed to catch. That is a software conformance result. It says the construction was implemented as specified; it does not say the construction describes nature.

## 4. Limitations

1. UNISOLATED: one host, one account, one operator; no outside party ran anything.
2. One platform (aarch64 Linux, glibc, gcc 13.3, rustc 1.98.1). `cos`/`sin` come from the C library; bounds assume 1 ulp.
3. Symbol scans only: inline syscalls, raw counter reads (CNTVCT_EL0) or a clock reached through a function pointer would pass. The mutants prove named clock calls are caught, not every way to read time.
4. Mutant power is structural: the Y-sign mutant is invisible on three of twelve positive cases by construction; a fault that only shows on an untested class would not be caught.
5. Bounds are ESTIMATED; nothing here is interval-rigorous.
6. The spec's "non-ideal" regime (interaction between clock and system, `interaction NONE` in every case here) is untested; the model family is `PAGE_WOOTTERS_FINITE_IDEAL` only.
7. Agent 5's own isolation scanner does not strip the `__name_2` alias (Agent 4's gate does); recorded, not blocking.
8. Wall-clock independence was shown for two times, two zones and two candidate commits; it is a property of the identity rule (no wall-clock field is hashed), demonstrated, not exhaustively tested.
9. Judge independence: the runner's judge, the evaluator and the oracle verdicts agree, which shows a consistent reading of the contract, not that the reading is the only one. Three readings were settled by Agent 0 rulings on the tracking issue (component outputs are not interfaces; per-input NOT_EVALUATED; shape before range) without editing a frozen contract.

## 5. Decision on AT-1

An AT-1 proposal is justified as the next software and model step, with scope limited to: (a) the interacting clock-system regime (`interaction` other than `NONE`) where Page-Wootters predictions depart from ideal Schrodinger evolution and the negative arm becomes informative; (b) a qualification run by a second operator on a second platform, to lift C9 from INCONCLUSIVE. AT-1 is not justified as, and must not be presented as, a physics claim; promotion of any claim in C11 would need evidence of a kind this program cannot produce.

## 6. Outside view

One outside second opinion was obtained from Codex (`gpt-6-astra`) on 2026-10-10, on a self-contained brief carrying the model definition, the run 2 numbers for P1 and N2, the gate and mutant results and the integrator's stated limits (brief and full answer kept by the reviewer; cited here as an outside view, not as a co-author of this verdict). The brief predates the hidden-set run and the D11 fix, so two of its "first" controls were already satisfied by the time of this verdict. Its findings:

- P1 is correct: with the reference reading r = 0, P(X+) = (1 + cos t)/2, P(Y+) = (1 + sin t)/2, P(Z+) = 1/2, so P(Y+) = 1 at k = 1; the clock marginal is 1/4 at every reading once the projected state is normalized (the unnormalized projection has squared norm 1/4). Independent of the reviewer's own derivation and in agreement with it.
- N2 is correct: the projection removes the up component and leaves down, whose probabilities are X = Y = 1/2, Z = 0 at every reading; FAIL correctly labels the failure of the equality test, and the negative case itself meets its expectation. N2 does not contradict the claim restricted to full coverage.
- The software evidence supports agreement on the specific tested inputs, detection of the specific planted faults (observable swap, sign flip where observable, named clock calls), and repeatability under the two tested times and zones. It does not establish conformity across whole input classes, absence of every hidden dependency, rigorous accuracy, or universal wall-clock independence. Matching hashes fingerprint content; they are not evidence of correctness.
- Cannot be concluded: experimental evidence that physical time is emergent, or validation of a clock-free cosmology; "this tests a finite mathematical construction within the Page-Wootters framework".
- Controls it would require next, in order: (1) freeze the spec, fix the refusal mismatch, run the withheld cases under independent control on another machine (mismatch fixed and withheld cases run since, on the same machine; the other-machine part is carried into section 5); (2) exact or rigorously bounded checks for nonzero reference readings, complex initial states, energy degeneracy, nearly matching energies, zero projections and clock-measurement completeness (P1d, P1g, P4, N6 and the POVM check cover several of these with ESTIMATED bounds; rigorous bounds remain open, C10); (3) dependency controls beyond symbol scans: direct counter and syscall mutants, altered clock sources, and a precise statement of which independence claim they establish (carried into section 4 item 3 and section 5).

The outside view and this review agree on every verdict in section 2.

## 7. Record

- Reviewer: Agent 6 (the former Agent 0 session), 2026-10-10. Files owned: this one only.
- Defects found and fixed during qualification (D1 to D8, D11) are recorded in omega `research/atemporal/at0/integration/QUALIFICATION.md` and on omega issue 358; none was hidden or normalized away.
- Program status after this review: REVIEWED (software conformance PASS on the tested classes; blinded qualification INCONCLUSIVE; physical claims NOT TESTED).
