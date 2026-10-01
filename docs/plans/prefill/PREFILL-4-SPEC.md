# PREFILL-4 Specification (cache-aware cost model)

**Status:** PROPOSED. Written 2026-10-01. Docs only. Nothing in this file has run on any tier (host, QEMU or GB10 hardware). Every gate below is **NOT_RUN** and **not claimed passed**.
**Authority:** operator material of 2026-10-01 (Drake Stapleton), recorded in the queen handoff `~/handoffs/2026-10-01-prefill-program-pass2.md` (priority ladder step 4, CACHE-AWARE SCHEDULING), extending `~/handoffs/2026-10-01-prefill-artifact-idea.md`. Pasted operator material is pre-approved. Where this text and that material differ, the material wins and the difference is a defect in this text.
**Not a master plan and not a milestone.** `CURRENT_EXECUTION_PLAN.md` owns sequencing and `doctrine/ROADMAP.md` owns milestone status (`PLAN_AUTHORITY.md`). PREFILL-4 is one finite rung of the prefill ladder. It depends on rungs 1 to 3 (section 9).
**Layout copied from:** `docs/plans/prefill/PREFILL-0-SPEC.md` (aien-architecture PR #103, branch `hive/PREFILL-0-SPEC-prefill`, not yet on main at the time of writing).

Snapshots used for every fact below:

- aien-sovereign-core `cfd9982` (`cfd99827ca5483c08d549ca32c7ee3d3bde6f2d8`), equal to `origin/main` when read on 2026-10-01 (`git rev-parse origin/main` after fetch). Read with `git show cfd9982:<path>`. Paths are relative to that repository.
- omega `origin/main` `0171bd4` (`0171bd4224d31b22333305c6f7e7bd1f9c6e327b`, "M20 receipt: content-addressed receipt writer tools/m20_receipt.sh (host PASS) (#179)", 2026-10-01). Read with `git show 0171bd4:<path>`.
- aien-architecture `origin/main` `7b8ca8a`.
- PREFILL-SCOUT facts: `~/handoffs/2026-10-01-PREFILL-SCOUT-scout.md`.

---

## In plain words (read this first)

Today the AIEN scheduler decides what to work on next by arrival order and judges a request's size by how many words (tokens) it carries. A request whose long opening has already been digested and is sitting ready in memory looks exactly as expensive as one that must be digested from scratch. That is wrong: the ready one costs a fraction of the work.

PREFILL-4 replaces "how many words" with "how much work is actually left": the words not yet digested, plus the cost of reading the shared digested part, plus the cost of fetching that digest from wherever it is stored, plus each branch's own new words. The same price list feeds Omega, which already chooses "the cheapest way that meets the requirement" but today has no way to know whether a request's context is already digested.

---

## 1. The cost formula (verbatim from the operator material)

> cost = uncached_prefill_tokens x prefill cost + shared-prefix attention cost + artifact movement cost + branch-local suffix cost (not raw input tokens).

Source: `~/handoffs/2026-10-01-prefill-program-pass2.md` line 7 (ladder step 4).

Every term is carried in **two units side by side: seconds (s) and joules (J)**. They are never added together or converted into one another. The scheduler and Omega each choose which of the two they rank on (section 4), and both are always recorded.

Written out for one request R that needs context revision C, fanned out to B branches (B = 1 for a plain request):

```
cost_s(R) = U(R) * c_pf_s(pos) + A_s(R) + M_s(R) + sum over branches b of S_s(R, b)
cost_J(R) = U(R) * c_pf_J(pos) + A_J(R) + M_J(R) + sum over branches b of S_J(R, b)
```

The split between "shared" (terms 1 to 3, paid once per request group) and "branch-local" (term 4, paid per branch) is this spec's reading of the formula. The operator text names the four terms but does not define the partition. Any later operator text that defines it wins.

## 2. The four terms

### 2.1 Term 1: `uncached_prefill_tokens x prefill cost`

| Item | Definition |
|---|---|
| `U(R)` uncached_prefill_tokens | Number of tokens of the **shared** part of C that are not covered by a reusable PrefillArtifact (section 3). Unit: tokens. Equals the full shared length when nothing is reusable (cold). |
| `c_pf(pos)` prefill cost | Cost of prefilling one token, in s/token and J/token. A function of absolute position `pos`, because each new token attends over everything before it, so later tokens cost more. |
| Measured or estimated | Estimated from a fitted table of per-token prefill cost against context position, per model digest and backend. The table is fitted from PREFILL-0 measurements "prefill tok/s" and "GPU package energy" (`PREFILL-0-SPEC.md` section 7) taken at the PREFILL-0 context lengths (32K, 128K, backend max). The fitted table is versioned and its digest goes in every receipt. No table exists today. |
| Reads | Whether a token counts as cached is decided only by the artifact reuse predicate in section 3. |

### 2.2 Term 2: shared-prefix attention cost `A(R)`

| Item | Definition |
|---|---|
| Meaning | The cost for the new tokens (shared uncached span plus all branch suffixes) to attend over the already-computed shared prefix. Even a fully warm prefix is not free: every new token still reads its keys and values. |
| Unit | s and J. |
| Measured or estimated | Estimated from bytes read of prefix K/V: `prefix_length x per-token KV bytes (from kv_dtype, kv_layout, model shape)`, divided by measured effective read bandwidth for the tier the artifact lives in, times the number of passes over it. With branch-aware attention (ladder step 3, Hydragen-style exact decomposition) the shared prefix is read once per batch for all B branches; without it, B times. The model must state which path is in use, and the estimate differs by up to a factor of B between them. Energy from the same window on the GPU package energy meter. |
| Reads | `prefix_length`, `kv_dtype`, `kv_layout`, `block_size`, `attention_layout` of the artifact; residency tier (section 3). |

The GB10 unified LPDDR5X bandwidth figure (~273 GB/s) is UNVERIFIED (operator material marks it so). The model must use a measured bandwidth, never this number.

### 2.3 Term 3: artifact movement cost `M(R)`

| Item | Definition |
|---|---|
| Meaning | The cost of making a reusable artifact usable by the GPU: zero if already GPU resident, otherwise moving or mapping it from where it is (unified RAM pages, NVMe). |
| Unit | s and J. |
| Measured or estimated | `artifact bytes / measured tier bandwidth + measured fixed per-move latency`, per tier. Energy from the package meter (and, for NVMe, whatever meter covers the drive; UNVERIFIED that one exists on GB10, confidence 40%). |
| Move vs recompute | If moving the artifact costs more than recomputing its tokens (term 1 for that span), the model must price the span as uncached instead: `min(move, recompute)` per span, decided separately in s and J. If the two units disagree on the choice, the one the caller ranks on decides and the other is recorded. A tier of `missing` means the span is uncached. |
| Reads | Residency tier and `storage_handles` of the artifact. |

Residency tier names come from ladder step 5 of the operator material: GPU resident / unified RAM / NVMe / missing. On GB10 GPU and CPU share one physical memory, so the difference between "GPU resident" and "unified RAM" is mapping and page state, not a physical copy. The real cost of that difference is UNVERIFIED (confidence 50% that it is small); it must be measured, not assumed.

### 2.4 Term 4: branch-local suffix cost `S(R, b)`

| Item | Definition |
|---|---|
| Meaning | The cost of prefilling branch b's own tokens (its delta after the shared prefix) and their attention over that branch's own suffix. Summed over all B branches. |
| Unit | s and J. |
| Measured or estimated | `suffix_tokens(b) x c_pf(pos)` with the same table as term 1, evaluated at positions after the shared prefix. Suffix attention over the shared prefix is already in term 2 and is not counted twice. |
| Reads | Branch suffix length; `prefix_length` and `absolute_position_range` of the shared artifact (to know where the suffix starts). |

### 2.5 Mutant (what the formula is not)

`raw_cost(R) = raw_input_tokens(R) x c_pf`, where raw_input_tokens counts every prompt token of every branch whether cached or not. This is the shape the scheduler uses today (section 4.1). It is used only as the mutant for gate PF4-G3.

## 3. Which PrefillArtifact fields the model reads

Field names from the target shape in `~/handoffs/2026-10-01-prefill-program-pass2.md` line 16. None of these fields exist in code at `cfd9982` (no PrefillArtifact type; PREFILL-0 section 4 is a proposal).

**Reuse predicate.** A span of R's context counts as cached for term 1 only if there is an artifact for which all of the following hold:

1. `exactness_class == EXACT`. COMPOSABLE / APPROXIMATE artifacts never count as cached in PREFILL-4 (type-system rule "never silently mix", pass2 lines 12-13; non-prefix reuse is ladder step 7 and has its own contract).
2. `state` is `Ready` or `FrozenShared` and `completion_fence` has completed. `Allocated` and `Computing` never count (rung 1 rule, pass2 line 4).
3. `model_digest` equals the active model, `tokenizer_digest`, `model_architecture_id`, `weight_generation`, `rope_config`, `kv_dtype`, `kv_layout`, `block_size`, `attention_layout` all match what R would compute with.
4. `context_revision_digest` / `token_digest` prove the artifact's tokens equal R's tokens over `absolute_position_range`, and that range starts at position 0 (exact prefix).
5. `generation` is current (no stale handle).

Then the cached length is `prefix_length` of the longest such artifact, and `U(R) = shared_len(R) - prefix_length`.

**Pricing fields.** Term 2 reads `prefix_length`, `kv_dtype`, `kv_layout`, `block_size`, `attention_layout`. Term 3 reads `storage_handles` and the residency tier. Term 4 reads `prefix_length`, `absolute_position_range`.

**Residency tier is not in the pass2 field list.** It is named in ladder step 5 (Cortex-aware prefetch, pass2 line 8). PREFILL-4 needs it as a readable property of `storage_handles` (where each handle lives). Until step 5/6 exists, the model may assume every Ready artifact is GPU resident, and must say so in the receipt.

## 4. Where it enters

### 4.1 aien-sovereign-core scheduler at `cfd9982`

**What it does today.** There is no cost function in the scheduler. Grep of `crates/aien-scheduler/src/lib.rs` for `cost` at `cfd9982` returns nothing; repository-wide grep for `cost` in crates finds only unrelated uses (`crates/cortex-rs/src/compiler.rs:140-236` token budgets for context compilation, `crates/spark-adapters/src/verifier.rs:259` edit distance).

| Behavior | Evidence (`cfd9982`) |
|---|---|
| Waiting requests are a FIFO queue: submit pushes to the back | `crates/aien-scheduler/src/lib.rs:193` (`self.waiting_queue.push_back(seq_id)`) |
| Admission always takes the front of the preempted queue, then the front of the waiting queue | `lib.rs:414-420` |
| Priority is recorded at submit but not used for admission order | mapped at `lib.rs:125-130`; used only to pick a preemption victim (lowest priority first), `lib.rs:326-331` |
| Budgets are in raw prompt tokens | `SchedulerConfig` `max_batch_tokens`, `max_prefill_tokens`, `prefill_chunk_size` (`lib.rs:18-25`, defaults 4096 / 2048 / 512 at `lib.rs:30-33`); admission loop guards at `lib.rs:410-413` |
| KV block need is raw prompt length | `required_blocks = prompt_len.div_ceil(16)` at `lib.rs:443`, checked at `lib.rs:444-455` |
| First chunk size is raw prompt length capped by chunk and budget | `lib.rs:468-473` |
| Charges raw chunk tokens against the budgets | `current_tokens += chunk_size; prefill_budget -= chunk_size` at `lib.rs:521-522` |
| Running sequences are scheduled in id order, decode first then continuing prefill chunks | `running_ids.sort()` at `lib.rs:354-355`; decode at `lib.rs:370-376`; continuing chunk at `lib.rs:377-404` |
| A sequence with an existing block table goes straight to decode (the rung 1 defect) | `lib.rs:475-492`; being changed by aien-sovereign-core PR #145 (OPEN, head `d6455da`, checked with `gh pr view 145` on 2026-10-01) |

**`BlackwellBatchPlan` does no cost or ordering work.** `BlackwellBatchPlan::from_scheduled_batch` (`crates/aien-inference-abi/src/blackwell_batch.rs:31-100`) turns an already-chosen `ScheduledBatch` into rows: one row per decode request (`:43-56`), then one row per prefill token (`:58-82`, `prefill_count += 1` per token at `:80`). It is downstream of every decision, so the formula does not enter here. Its `prefill_count` is the number of prefill tokens actually executed in a step, which makes it the place to **measure** realized `U(R)` plus suffix tokens for gate PF4-G2.

**The seam (does not exist as a function today; must be added).** Three places in `build_scheduled_batch` (`lib.rs:309`):

1. **Order:** `lib.rs:414-420` picks the queue front. PREFILL-4 replaces "front" with "lowest `cost(R)` among waiting requests of the same priority class", so priority still dominates and cost breaks the order inside a class. FIFO stays the tie-breaker (equal cost: earlier arrival first) so behavior is unchanged for cold-only workloads of equal size.
2. **Budget charging:** `lib.rs:443`, `lib.rs:468-473`, `lib.rs:521-522` charge raw prompt tokens. PREFILL-4 charges `U(R) + sum of suffix tokens` (the tokens that will really run) against `max_prefill_tokens` / `max_batch_tokens`, and new blocks only for uncached tokens. This depends on rung 2 (exact prefix reuse) being live; today `prefix_cache` is dead code (`crates/aien-kv-cache/src/lib.rs:688-689`, PREFILL-SCOUT claim 4).
3. **Preemption victim (optional, recorded for later):** `lib.rs:326-331` evicts the lowest priority. Evicting a sequence whose shared prefix is warm throws away work; a cost-aware victim choice would price the recompute. Not a PREFILL-4 gate.

The cost function itself belongs in the scheduler crate as a pure function of (request, artifact view, fitted cost table). The scheduler must not compute digests itself; it receives the artifact view from the KV / artifact owner. Line numbers above must be re-cited after PR #145 merges, because it edits the same admission block.

### 4.2 Omega physical cost model and cognitive routing at `0171bd4`

Omega has no prefill, KV-cache or prefix code: grep of `src/` at `0171bd4` for `prefill|kv.?cache|prefix` finds only unrelated hits (compiler prefix sums, path lineage, signatures). There are two cost models.

**(a) Empirical physical cost model, `src/runtime/rx_costmodel.{h,c}`.** Omega's own state document names it "Physical cost model, empirical learning, energy" (`docs/polyglot/OMEGA_POLYGLOT_CURRENT_STATE.md:164-171`).

| Today | Evidence (`0171bd4`) |
|---|---|
| Predicts cost of each eligible realization ("arm") from measured data; Bayesian ridge regression per (op, core, pressure) cell on log2 picoseconds | `src/runtime/rx_costmodel.h:1-29` |
| One operation class only (matvec) | `RX_CM_OPS 1u` "matvec only today; widen with a second operation", `rx_costmodel.h:37` |
| Features: M, N, `state_bytes`, `cache_bytes`, core, pressure, latency and energy budgets | `RxCmFeatures`, `rx_costmodel.h:57-71`; basis `rx_costmodel.c:46-60` |
| Energy = predicted time x measured power | `rx_costmodel.c:199-200`; `power_mw` table `rx_costmodel.h:138` |
| Already has a recompute idea: "recompute = synth + verify" | `rx_costmodel.h:139-140` |
| Chooses the arm with lowest predicted latency among those meeting budgets | `rx_cm_decide`, `rx_costmodel.c:286-326` (ranking at `:310-326`) |
| Widening the arms or features changes the serialized blob | `OMEGA_POLYGLOT_CURRENT_STATE.md:171` |

**Seam: does not exist.** There is no operation class for prefill and no feature for cached tokens, artifact tier or branch count. The plug-in point is a new operation class (widen `RX_CM_OPS`, `rx_costmodel.h:37`) whose arms are the realizations of "make context C usable": recompute, reuse-in-place, move-then-reuse; with features carrying `U(R)`, `prefix_length`, artifact bytes, residency tier and B. The four-term formula then becomes the prior or basis for that op's prediction, and `rx_cm_decide` (`rx_costmodel.c:310-326`) already picks the cheapest. This is a blob format change and needs the model's own versioning (`rx_cm_serialize`, `rx_costmodel.h:177-182`).

**(b) Cognitive routing ("cheapest realization"), `src/runtime/rx_route.{h,c}`.**

| Today | Evidence (`0171bd4`) |
|---|---|
| Router "picks the cheapest escalation ladder that the evidence says will meet the requirement" | `src/runtime/rx_route.h:1-8` |
| An engine's cost is one fixed number per operation: `mean_ns`, `p99_ns`, `nj_per_call` | `RxCogCost`, `rx_route.h:104-110` |
| Ladder cost = sum of those fixed numbers over rungs | `evaluate`, `rx_route.c:383-398` (sums at `:386-388`) |
| Ranks on energy if measured, else time | `ladder_cost`, `rx_route.c:404-406`; `engine_cost_less`, `rx_route.c:408-413` |
| Cheapest qualifying ladder wins | `choose`, `rx_route.c:465-499` (comparison at `:490-494`) |
| The request carries no context or input-size field | `RxCogRequirement`, `rx_route.h:65-77` |
| Profiles change only through a promoted generation | `rx_route.h:14-21` |

**Seam: does not exist.** Cost is per engine, not per request, so a model engine with a warm context and the same engine with a cold one look identical. The plug-in point is `evaluate` at `rx_route.c:386-388`: add a per-request context cost (the four-term formula, in ns and nJ) for rungs whose engine consumes context. That needs a new request-side input naming the context revision (not a profile field). It must be a request input, never a learned profile value, because profiles may only change through promotion (`rx_route.h:14-21`) and cache state changes every request.

## 5. Gates

All gates are **NOT_RUN**. Workload for every gate: PREFILL-0 cases (`PREFILL-0-SPEC.md` section 6), on a real backend (CPU reference `NativeTransformerBackend` for host, Blackwell for GB10), never the mock backend (it ignores prompt content, PREFILL-SCOUT).

| Gate | Statement | Pass rule |
|---|---|---|
| PF4-G1 warm ranks below cold | Two requests A and B with equal raw input tokens and equal priority. A's shared prefix is an EXACT, Ready, fence-completed PrefillArtifact matching every binding field (section 3); B has no reusable artifact. | `cost_s(A) < cost_s(B)` and `cost_J(A) < cost_J(B)`, and with both waiting the scheduler admits A first. Negative controls (each must give A **no** discount, so `cost(A) == cost(B)`): A's artifact is COMPOSABLE / APPROXIMATE; A's artifact state is Allocated or Computing; A's `model_digest` differs from the active model; A's `tokenizer_digest` differs. |
| PF4-G2 predicted vs measured error | For every request in the run, compare predicted cost with measured cost, per term where separable and in total, in s and in J. | **Report only. No threshold is set** (none exists in the operator material). Measurement defined below. |
| PF4-G3 mutant | Replace the formula with the raw-input-token mutant (section 2.5) and rerun PF4-G1. | PF4-G1 must **FAIL** under the mutant (A and B tie on raw tokens, so "A strictly below B" is false). If PF4-G1 still passes with the mutant, the gate is not testing the formula and PF4-G1 is void. |

**PF4-G2 measurement definition.**

- *Measured seconds:* wall time from the request's admission (the step in which its first prefill or decode row is scheduled) to its prefill completion fence (rung 1), on a monotonic clock. For branches, to the last branch's suffix fence.
- *Measured joules:* GPU package energy integrated over the same window (GB10 leg only; host leg reports N/A). When several requests share a step, the energy of that step is split by a declared attribution rule that conserves total energy (the per-request parts sum to the metered total). The rule must be named in the receipt; no rule is chosen here (UNVERIFIED which existing AIEN rule applies).
- *Realized tokens:* `prefill_count` of each step's `BlackwellBatchPlan` (`blackwell_batch.rs:80`) attributed per `seq_id`, compared with predicted `U(R) + sum suffix tokens`. This checks term 1 and 4 inputs separately from their costs.
- *Reported numbers:* per request, signed relative error `(predicted - measured) / measured` in s and J; per case and per residency tier: count, median, and maximum absolute relative error. Raw per-request rows go in the receipt. The fitted cost table digest and backend are recorded.

### 5.1 Results table

QEMU: N/A (runtime scheduling, no guest boot).

| Gate | Host (CPU reference backend) | GB10 hardware |
|---|---|---|
| PF4-G1 warm ranks below cold (s) | NOT_RUN | NOT_RUN |
| PF4-G1 warm ranks below cold (J) | N/A (no energy meter) | NOT_RUN |
| PF4-G1 negative controls | NOT_RUN | NOT_RUN |
| PF4-G2 predicted vs measured error (s) | NOT_RUN | NOT_RUN |
| PF4-G2 predicted vs measured error (J) | N/A | NOT_RUN |
| PF4-G3 raw-token mutant fails PF4-G1 | NOT_RUN | NOT_RUN |
| Omega `rx_costmodel` prefill op class | NOT_RUN (does not exist) | NOT_RUN |
| Omega `rx_route` per-request context cost | NOT_RUN (does not exist) | NOT_RUN |

A cell leaves NOT_RUN only with a receipt naming: sovereign-core commit, omega commit (if Omega legs), backend, model digest, tokenizer digest, fitted cost table digest, residency assumption (section 3), energy attribution rule, and raw files. Failing receipts are kept. GB10 chip runs go through the shared test queue and are never killed or timed out.

## 6. Precedent (outside sources)

Fetched 2026-10-01 with the WebFetch tool. The tool returns text through a summarizing model, so short quotes below are as returned by that tool; recheck exact wording against the PDF before quoting further.

- **Xiaomi MiMo-V2.5 serving report (fetched).** "Full-Pipeline Inference Optimization for MiMo-V2.5 Series: Pushing Hybrid SWA Efficiency to the Limit", Xiaomi MiMo Team, arXiv 2607.13095. https://arxiv.org/abs/2607.13095 (abstract) and https://arxiv.org/html/2607.13095 (full text).
  - Abstract: they "develop a KVCache-affinity router to reduce computation while preserving load balancing" and optimize the KVCache system "with layerwise prefetch, SWA-aware prefix cache trees, and specialized placement strategies".
  - Section 4.1 (KVCache and Load-Affinity Scheduling): "score(worker) = matchWeight x prefixMatchPercentage - normalizedLoad"; the router "prioritizes nodes that have already cached the current request's prefix while simultaneously balancing load". (Multiplication sign and minus normalized to ASCII.)
  - Section 5.2 (Length Bucketing Strategy): "three-tier length bucketing strategy (0-64K / 64K-256K / 256K-1M)" (dashes normalized to hyphens); and "throughput falls from 1x near zero prefix to about 0.12x at a 1M-token prefix", from their Figure 7, "Relative prefill throughput vs. cache sequence length with a fixed 16K compute chunk".
  - **Status change versus PREFILL-0 section 11:** the prior scout did not find the 1M prefill falloff (UNVERIFIED 25%). This fetch found it in the full text. Treat as VERIFIED-BY-FETCH-TOOL, confidence 75% on exact wording, pending a direct PDF read.
  - What PREFILL-4 takes from it: (1) per-token prefill cost depends strongly on position, so `c_pf(pos)` in term 1 is a function of position, never a constant; (2) cache-affinity is a score term, not a hard rule. What it does not take: their router chooses among workers (machines); PREFILL-4 ranks requests inside one box.
- **MiMo-V2.5 model card (fetched).** "interleaving Sliding Window Attention (SWA) and Global Attention (GA) with a 5:1 ratio and 128 sliding window." https://huggingface.co/XiaomiMiMo/MiMo-V2.5. The card itself does not mention length bucketing, cache-aware routing or prefill throughput (same fetch).

**Contrast only (not adopted).** Topology rule (pass2 lines 23-24): a single DGX Spark first; avoid redundant work inside the unified box before any prefill / decode split across boxes; no hyperscaler P/D split now.

- **DistServe (fetched).** "DistServe assigns prefill and decoding computation to different GPUs, hence eliminating prefill-decoding interferences." https://arxiv.org/abs/2401.09670. Contrast: PREFILL-4 keeps prefill and decode in one box and one batch plan (`BlackwellBatchPlan` mixes D decode and P prefill rows, `blackwell_batch.rs:15-29`).
- **NVIDIA Dynamo (fetched).** README: "Separates prefill and decode into independently scalable GPU pools" and "Routes requests based on worker load and KV cache overlap". https://github.com/ai-dynamo/dynamo. Contrast: its KV-aware routing picks a worker across a pool; PREFILL-4 applies the same "price the overlap" idea to request ordering inside one box. Its claimed "2x faster TTFT" is the vendor's figure, not used here.

## 7. Turing note

Same verified gain at lower physical cost = higher T/J. The cost model lowers the physical cost (s, J) of acquiring context; it does not change the verified gain T. The two quantities are recorded separately and never merged into one score.

## 8. What PREFILL-4 does not do

- No COMPOSABLE / APPROXIMATE reuse pricing (ladder step 7).
- No cross-box routing or prefill / decode disaggregation (topology rule).
- No prefetch planning (ladder step 5); it only reads the residency tier.
- No change to model architecture (YOCO / CED parked, PREFILL-0 section 12).

## 9. Prerequisites

1. Rung 1 (PREFILL-CORRECTNESS) merged: aien-sovereign-core PR #145 (OPEN at `d6455da`), so "Ready" means computed.
2. A PrefillArtifact record carrying the section 3 fields; today none exists.
3. Rung 2 (EXACT PREFIX REUSE) live: a real prefix lookup (today `prefix_cache` is dead code, `crates/aien-kv-cache/src/lib.rs:688-689`) and a production caller of `compute_missing_prefill` (today test-only, `crates/aien-runtime/src/context.rs:200-218`). Without it `U(R)` always equals the full length and PF4-G1 cannot pass.
4. For term 2 with B > 1: rung 3 (branch-aware attention) or a declared "no shared batching" mode.
5. PREFILL-0 measurements of prefill tok/s and GPU package energy across context positions, to fit `c_pf(pos)` (section 2.1).
6. Measured tier bandwidths for term 3 (at least GPU resident and unified RAM).
7. A declared energy attribution rule for batched steps (PF4-G2).

## 10. Real gaps found while writing

- Neither the scheduler nor Omega has any notion of context cost today (sections 4.1, 4.2). Every seam named above is new code, not a parameter change.
- The scheduler records priority but admits in pure FIFO order (`lib.rs:125-130` vs `lib.rs:414-420`). Adding cost ordering is also the first time any ordering beyond FIFO exists at admission.
- Omega's router cannot express per-request cost at all (`RxCogCost` is per engine, `rx_route.h:104-110`). Any context-dependent engine (a language model) is priced as if every call cost the same.
- Omega `rx_costmodel` widening changes its serialized blob (`OMEGA_POLYGLOT_CURRENT_STATE.md:171`); a migration or version bump is required.
