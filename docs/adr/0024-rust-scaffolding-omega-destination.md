# ADR 0024: Rust is scaffolding, Omega is destination, C where hardware-justified

**Status:** ACCEPTED, 2026-10-01. Decided by the operator, Drake Stapleton, in the course-correction brief of 2026-10-01 (~14:15Z); questions Q1 to Q4 decided by him the same day (see the section at the end).
**Supersedes:** the decision and step order of [`docs/plans/RUST_TO_C_MIGRATION.md`](../plans/RUST_TO_C_MIGRATION.md) (decided 2026-09-27, merged by arch #45, 7154d8a; capability authority ported to C by aienos #156 and omega #43). That file stays in place as history with a SUPERSEDED banner.
**Amends:** `doctrine/SOVEREIGNTY.md` (one clarifying sentence only, see Decision 8) and `doctrine/ARCHITECTURE.md` §2.8 (reconciles capability authority classification with the scaffolding rule). **Extends:** nothing else.
**Related:** ARCH-0022 (Cortex owner retired, not ported); aienos ADR 0013 (ABI v1 handles), aienos ADR 0014 (Binary Artifact v0), aienos ADR 0015 (System Store v1 format), aienos ADR 0016 (Continuity objects), aienos ADR 0017 (M5 key hierarchy).
**Evidence base:** the grounded assessment of 2026-10-01 (`~/handoffs/rust-omega/ASSESSMENT.md`, sections 3, 5, 8, 9), read from fresh clones of aienos 03364c5, aien-sovereign-core 06da469, omega 3108fc2, aien-architecture d46cc4a, physics c5f4828. Paths below are relative to the named repository on those commits. Code, Makefiles, CI and receipts beat READMEs and plans.

---

## Context

On 2026-09-27 the rule became "no Rust anywhere; C is the target; existing Rust is rewritten". The assumption was that AIEN must become C before it can become Omega. Executing it produced a large C tree in aienos (`native/`, about 51k lines) that duplicates working Rust in places, and it pointed the next work at porting working, tested Rust (for example sovereign-core `crates/crumbs`, 8,465 lines) with no benefit to Omega.

The operator reversed the premise on 2026-10-01. The destination is Omega. Rust is the bootstrap implementation language where a higher-level systems implementation is needed. C, assembly and other low-level languages stay where a concrete hardware, boot, ABI, toolchain or qualification reason exists. C is not the default and not an intermediate destination.

Desired progression: Rust implementation, then a stable language-neutral machine contract, then an Omega implementation, then the Omega compiler and backend, then native CPU and GPU machine code. The end state is not "Rust to C to Omega". It is a contract with a Rust implementation and an Omega implementation side by side, both qualified.

## Decision

1. **Rust is the primary scaffolding language** for new systems work that is not hardware-bound. Omega is the destination.
2. **C, assembly and native interfaces stay where justified** by a concrete hardware, boot, firmware, ABI, driver, toolchain or qualification reason. They are not the default.
3. **Nothing already merged is reverted.** The C kernel, artifact loader, Store integration, networking, drivers, gates and receipts stay. Each is one or more of: current production or bootstrap implementation, executable specification, differential reference for a future Rust or Omega implementation, hardware-bound component.
4. **The four-question test.** Before adding a substantial new implementation in C, answer:
   1. Is it genuinely boot-, firmware-, ABI-, driver-, hardware- or freestanding-kernel constrained?
   2. Does an existing Rust implementation already solve it correctly?
   3. Will writing it in C materially help Omega inherit it?
   4. Could a language-neutral contract let Rust implement it today and Omega replace it later?
   If the answer to question 4 is yes and there is no hard reason for C, use Rust. Do not duplicate working Rust in C as a migration step.
5. **Boundary rules (make Rust replaceable).** Omega must never depend on Rust semantics. At major subsystem boundaries use deliberately boring, versioned, language-neutral contracts:
   - `extern "C"` entry points; `#[repr(C)]` structs; fixed-width integer types;
   - opaque handles instead of references; slices as pointer plus length; explicit ownership rules;
   - explicit numeric error codes, with a refusal rule for unknown versions;
   - no Rust trait objects, generics, `Arc<Mutex<..>>`, Tokio types, enum layout, allocator internals, lifetimes, compiler-specific symbols or layout assumptions at a boundary;
   - no Rust serialization as a canonical machine format (fixed byte layouts with magics and versions, such as the existing AIENART, AIENSTR1 and CRB1 formats, are the model).
   Using C ABI conventions does not mean the implementation is C.
6. **Migration rule.** Never rewrite a working, tested Rust subsystem into C because Omega does not yet implement it. Instead: (1) stabilize its externally meaningful behavior; (2) extract a language-neutral contract where appropriate; (3) preserve or improve its test and qualification corpus; (4) implement the Omega capability when Omega is ready; (5) run Rust and Omega against the same conformance suite; (6) switch ownership only when Omega meets the correctness, safety, determinism and performance gates; (7) remove the old implementation only after demonstrated equivalence and only when it no longer has reference value. No big-bang rewrite. Omega earns ownership subsystem by subsystem. For each replaceable subsystem: one canonical contract, a Rust implementation and an Omega implementation behind it, one conformance suite.
7. **Performance by measurement.** Do not assume C is faster than Rust or that Omega is automatically faster than either. Performance decisions need measurements under the same workload, hardware, inputs, compilation conditions and correctness constraints. At extreme hot paths use the best proven realization regardless of the orchestration language.
8. **Doctrine.** `doctrine/SOVEREIGNTY.md` keeps its end-state law (the permanent lineage contains no Rust or C compilers). One sentence is added, verbatim from the operator (Q4 below), saying they are temporary scaffolding. Nothing else in the law changes.

## Bootstrapping phases

Omega is initially bootstrapped by existing tooling. That is acceptable. Self-hosting is not forced early; correctness comes first.

1. Rust, C and assembly build and host Omega.
2. Omega compiles useful standalone components.
3. Omega replaces selected AIEN components behind stable contracts.
4. Large portions of the runtime become Omega-owned.
5. Omega compiles substantial portions of itself.
6. Omega becomes self-hosting or nearly; Rust becomes optional bootstrap and tooling.

## Classification (A to E)

Legend: **A** keep in Rust for now. **B** keep in C, asm or native (justified). **C** active Omega destination. **D** needs a language-neutral seam. **E** duplicated in Rust and C. Full table with interfaces, tests and caveats: assessment section 5.1 and the audit of aienos PRs #182 to #209 in section 5.2. Repository and paths cited here are the ground truth on the commits listed in the evidence base.

| # | Component | Class | Repo and paths | Verdict |
|---|---|---|---|---|
| 1 | C kernel core (boot stub, MMU, GIC, timer, PCI, exceptions, M3 isolation, scheduler, IPC) | B (+E) | aienos `native/kernel/{arch,core,mm,dev,svc}`, `native/boot/efi_main.c`, `native/boot/efi_entry.S` | Inherently kernel. Production kernel going forward (Q1, decided). QEMU only so far. |
| 2 | Rust kernel | E (reference) | aienos `crates/aienos-kernel` | Keep building in CI as differential reference. Do not extend except as a reference. |
| 3 | SMMUv3, NVMe driver, virtio-net driver, disk block layer | B | aienos `native/kernel/dev`, `native/disk/`, `native/net/aienos_virtio_*` | Drivers and DMA confinement. C justified. |
| 4 | Store v1 engine | E | Rust `crates/aienos-kernel/src/store/`, `crates/aienos-store-tool`; C `native/store/{store_v1,store_engine,store_disk,torn_slot}.c` | Production C, Rust frozen reference. Format is aienos ADR 0015 plus aienos `docs/adr/0015-golden-vectors.json`. |
| 5 | Sealed Store (record v2) | B (C only) | aienos `native/store/store_sealed.c` | Not a duplicate. Needs a spec and golden vector. |
| 6 | M5 envelope and key hierarchy | E (diverged on purpose) | Rust `crates/aienos-kernel/src/crypto/envelope.rs`; C `native/m5/` | Production C. Needs an aienos ADR 0017 amendment for the v2 key labels. |
| 7 | Crypto primitives | E (X25519 C only) | C `native/crypto/*`, `native/sig/ed25519.c`, `native/net/x25519.c`; Rust `crates/aienos-crypto` | C justified inside the freestanding kernel. Rust is reference. Add shared vectors and a differential. |
| 8 | Networking M6-A and M6-B | E (M6-A), B and D (M6-B) | C `native/net/aienos_{net,sec,ctl}.c`; Rust `crates/aienos-kernel/src/net.rs` | Kernel production and executable spec. M6-B needs a written wire spec. |
| 9 | Binary Artifact v0, admission, receipt | E (byte-identical) | Rust `crates/aienos-artifact`; C `native/kernel/artifact/`, `native/kernel/core/artifact_loader.c`; aienos ADR 0014 | Proven language-neutral contract. Best second Omega seam. |
| 10 | Artifact loading from NVMe Store | B (C only) | aienos `native/kernel/svc/artifact_store.h` | Kernel-native. Record the layout as an aienos ADR 0014 and 0015 addendum. |
| 11 | Host artifact and image tooling | E and D | aienos `tools/ck_store_image.c`, `tools/ck_artifact_tool.c`, `native/m5/tools/m5_migsig.c` | No hardware reason. Keep what exists, do not extend in C. New host tools in Rust or shell. |
| 12 | Capability authority | E | C `native/capability/`; Rust `crates/aienos-capability`, `aienos-capability-ffi` | C production (omega links it). Rust reference. Handle contract needs a v2 decision (diverges from aienos ADR 0013 u32+u32 handle). |
| 13 | ARGUS | B (C only) | aienos `native/argus/*`; omega `argus.lock`, `src/runtime/rx_argus.h` | Not a duplicate. Omega pin is behind aienos main (v1.1 vs v1.2). |
| 14 | Boot loader (UEFI boot, QEMU rollback test) | B, Rust today | aienos `crates/aienos-boot` | Only working loader is Rust; kept as frozen scaffolding (Q3). It has no slot-based A/B selection and no signed boot manifest. |
| 15 | Continuity, Recovery Core, USB keyboard | Rust only | aienos `crates/aienos-kernel/src/continuity.rs` (aienos ADR 0016), `recovery_core` (aienos ADR 0006), `crates/aienos-boot` | Keyboard is a driver (C fine). Continuity and recovery: Q2. |
| 16 | aienos agent-state, cortex, c1-tree, aegis, accel, evidence crates | A (frozen) and D | aienos `crates/aienos-{agent-state,cortex,c1-tree,aegis,accel,evidence}` | Do not port to C. Cortex retired (ARCH-0022). Future Omega candidates once contracts exist. |
| 17 | TRUST-1 tooling | B-ish (shell) | aienos `scripts/trust1_*.sh` | Language-neutral already. |
| 18 | sovereign-core inference (KV cache, scheduler, ABI) | A (+D at the boundary) | sovereign-core `crates/aien-inference-abi`, `aien-kv-cache`, `aien-scheduler` | Working Rust. Keep. Tensor descriptor not frozen (conflicts with omega M20). |
| 19 | sovereign-core services (cli, cortex-rs, spark-*, mcp, runtime) | A | sovereign-core tokio, axum and reqwest crates | Linux user-space scaffolding. No Omega benefit in rewriting. |
| 20 | Crumb v1 (curriculum, visible and sealed records, verifier) | A (owner) and C (consumer) | sovereign-core `crates/crumbs/`; omega `src/crumbline/cl_crumb.{c,h}` | Already the target pattern. First migration seam. |
| 21 | aien-proof EvidenceReceiptV1 | A and D | sovereign-core `crates/aien-proof/src/evidence.rs` | Language-neutral by design. Two receipt schemes exist, not reconciled. |
| 22 | aien-protocols specs | D (specs), A (crates) | aien-protocols `specs/` | Natural home for cross-language specs. |
| 23 | Omega compiler OSC and AArch64 encoder | C (destination) | omega `src/compiler/*`, `src/aarch64_encoder.c` | Destination. Compiles no AIEN component yet. |
| 24 | Omega numerics, GB10 SASS encoder, M20 tensor | C (destination) | omega `src/omega_numeric*`, `src/omega_blackwell_*` | Destination. Do not freeze a tensor descriptor yet. |
| 25 | Omega resident runtime, fabric, IRs, J-Space | C (destination), D for 32-bit handle sites | omega `src/runtime/*`, `src/fabric/` | Omega-owned C today, written to be replaced by Omega-compiled code. |
| 26 | physics and FORGE | B | physics `forge/`, `m15/`, `m16/`, `nvrm/`, `*.s` | Hardware substrate. C and asm justified. |

## What stops

- The decision "no Rust anywhere; C is the target" (RUST_TO_C_MIGRATION line 3; README line 44; aienos README; omega polyglot and audit wording; ARCH-0017 and the Evolution Arena spec mention it).
- RUST_TO_C_MIGRATION step 1: porting `crates/crumbs` to C.
- RUST_TO_C_MIGRATION step 2 stands: standalone `aegis-runtime` is retired at R16, not ported.
- Porting the rest of sovereign-core, the aien-protocols crates, or the other Rust repos to C.
- Porting `aienos-agent-state`, `aienos-cortex`, `aienos-c1-tree`, `aienos-aegis`, `aienos-accel`, `aienos-evidence` to C.
- New C crypto or format code that exists only to replace a Rust library.
- The "C twin first, then delete Rust" CI rule. It is replaced by the migration rule in Decision 6.

## Store decision

The C Store engine is production (it is what the C kernel boots with and loads artifacts from). The Rust Store engine is frozen and kept as the reference that feeds the cross-check against the shared golden vectors. The on-disk format (aienos ADR 0015 plus golden vectors) is the contract and a future Omega seam. The 1097 power-cut checks are preserved as Omega conformance material.

## Consequences

- Existing C tests, gates and receipts remain evidence and become the conformance corpus for future Rust and Omega implementations.
- New host tooling and services default to Rust (or shell), behind format contracts.
- A contract registry (`docs/contracts/INDEX.md`) and the first migration seam (Crumb v1 visible record) follow as separate work per assessment section 8. Not part of this ADR.
- QEMU runs remain emulator evidence only. Nothing here claims physical qualification.

## Operator decisions Q1 to Q4 (Accepted, Drake Stapleton, 2026-10-01)

- **Q1. Kernel: C goes forward.** The C kernel in aienos `native/kernel` is the active kernel implementation. The Rust kernel (`crates/aienos-kernel`) is frozen as the behavioral and reference checker. Evidence is QEMU only (9 of 14 C kernel gates PASS at the last receipt); the C kernel has not booted on Machine 1.
- **Q2. Continuity and Recovery Core: implemented in C inside the C kernel.** This is an explicit, recorded exception to "do not port Rust to C", because these functions belong to the kernel chosen to be C. Order: write the contract first, use the existing Rust `continuity.rs` and `recovery_core` plus their QEMU campaigns as the oracle, then require differential agreement.
- **Q3. Boot (amended by the operator).** The Rust loader (`crates/aienos-boot`) is kept only as temporary scaffolding and reference. It does NOT implement slot-based A/B selection or a signed boot manifest (live `docs/TRUST-1-M5-GATE-MATRIX.md`); its QEMU rollback test shows candidate and fallback behavior only. Decisions: do not port the loader to C now; loader expansion is frozen; the loader to C-kernel handoff contract is to be defined; the existing QEMU fallback and rollback tests are preserved; permanent boot ownership is deferred until Atlas and TRUST-1 are resolved, with long-term convergence on Atlas (minimal immutable bootstrap root; Atlas is itself only QEMU-qualified).
- **Q4. Doctrine.** The following sentence is added to `doctrine/SOVEREIGNTY.md` verbatim, preserving the Sovereignty Law: "Rust, C, and external compiler toolchains may be used as temporary bootstrap and implementation scaffolding during construction; they are not dependencies of the permanent sovereign lineage, which must ultimately be realizable and maintainable by AIEN's own trusted toolchain."

The crumb reader (Crumb v1 visible record) is confirmed as the first Omega takeover.
