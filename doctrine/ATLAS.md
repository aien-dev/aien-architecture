# DOCTRINE-001: ATLAS — The Irreducible Bootstrap Seed

<!-- HISTORICAL-PROVENANCE:BEGIN -->
> [!NOTE]
> **Historical Lineage & Provenance Note (not normative):** *Formerly designated Alpha (`alpha.bin`) during early lineage bootstrap drafting. Every prior architectural responsibility and contract of ALPHA transfers to ATLAS unchanged. Only `atlas.*` artifacts are canonical.*
<!-- HISTORICAL-PROVENANCE:END -->

```text
Document ID:     DOCTRINE-001
Milestone:       Milestone 0 (DOCTRINE_V1)
Classification:  Sovereign Machine Canonical Doctrine
Target Substrate: AArch64 Bare Metal (ARMv8.2-A / ARMv9-A)
Status:          AUTHORITATIVE / CANONICAL
```

---

## 1. Executive Summary & Definition

**Atlas** is the irreducible bootstrap seed of the Sovereign Machine.

Atlas is not an operating system, not a kernel, not a runtime, not an agent, and not an intelligence. It is the minimal, immutable, deterministic physical origin point from which the machine establishes trustworthy execution.

The doctrine of Atlas rests upon five fundamental tenets:
1. **Small**: Atlas contains the minimum number of machine instructions necessary to validate the physical platform, measure the secondary boot stages, and transfer control to Physics. It carries zero extraneous logic.
2. **Fixed**: Atlas is immutable. Its bytes are burned into permanent read-only media or sealed into write-locked non-volatile firmware. Once finalized, it is never modified in-place.
3. **Auditable**: Every single byte, opcode, branch target, register mutation, and memory reference in Atlas is statically known, formally characterized, and human-verifiable.
4. **Deterministic**: Given identical platform inputs, Atlas follows the exact same execution path, cycle count bounds, and state transitions on every boot invocation without variance.
5. **Non-Intelligent**: Atlas possesses zero cognitive capacity. It contains no neural weights, no heuristic optimizers, no policy graphs, and no adaptive mechanisms. It is pure mechanical constraint.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              ATLAS                                     │
│                  (Irreducible Bootstrap Seed)                          │
│                                                                        │
│   ┌───────────────┐     ┌────────────────┐     ┌──────────────────┐    │
│   │ Platform Init │ ──> │ Integrity &    │ ──> │ Transfer Control │    │
│   │ (Bare Metal)  │     │ Measurement    │     │ to Physics       │    │
│   └───────────────┘     └────────────────┘     └──────────────────┘    │
│           │                     │                        │             │
│           ▼                     ▼                        ▼             │
│      Strict MMU /          SHA-256 /                 Monotonic         │
│      Registers           Manifest Match         Handoff (contract EL)   │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                             PHYSICS                                    │
│                 (Trusted Machine Authority)                            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Canonical Executable Artifact

The sole executable artifact generated for Atlas is:

```text
atlas.bin
```

In the Sovereign Machine architecture, the executable identity invariant is absolute:

$$\text{tested bytes} \equiv \text{evaluated bytes} \equiv \text{authorized bytes} \equiv \text{executed bytes}$$

Source code is historical provenance; `atlas.bin` is the sole physical truth. To ensure that `atlas.bin` can be completely audited and verified across space and time, every build must produce a canonical bundle of seven supporting evidence files.

### 2.1 The Supporting Evidence Bundle

| Evidence File | Format | Purpose and Invariants |
| :--- | :--- | :--- |
| `atlas.bin` | Raw Binary Image | The exact immutable byte stream executed by the processor at reset or early handoff. Contains raw machine opcodes; no dynamic headers. |
| `atlas.manifest` | Canonical TOML / JSON | Machine-readable declaration of entry point, load base, binary size, version, target tuple, authoring toolchain hash, and section boundaries. |
| `atlas.sha256` | Text / Checksum | Cryptographic SHA-256 digest of `atlas.bin`. Must match the hash stored in hardware Root of Trust / fused registers. |
| `atlas.decode` | Annotated Disassembly | Full linear instruction disassembly mapping every 4-byte word to its canonical AArch64 mnemonic, register operands, and immediate values. |
| `atlas.memory-map` | Symbolic Address Map | Explicit map of all physical memory regions: text, read-only data, reserved scratchpad stack, MMIO peripheral registers, and Physics staging buffers. |
| `atlas.control-flow` | Directed Graph / DOT | Exhaustive Control Flow Graph (CFG). Enumerates every basic block, conditional branch, static jump, and exception vector. Zero unresolved dynamic targets permitted. |
| `atlas.audit` | Formal Audit Ledger | Tabular line-by-line verification record proving that every byte is accounted for, every memory dereference is bounded, and every architectural side effect is safe. |

---

## 3. Atlas Responsibilities & Explicit Non-Responsibilities

Atlas's authority is strictly bounded by design. Any expansion of Atlas beyond its minimal role compromises the auditability of the bootstrap root.

```text
               ATLAS RESPONSIBILITY BOUNDARY
┌────────────────────────────────────────────────────────────────┐
│ INCLUDED (Atlas Responsibilities):                            │
│  [✓] Architectural register hygiene & initialization           │
│  [✓] Identity-mapped minimal page tables (EL1/EL2)             │
│  [✓] Diagnostic console (polled MMIO UART) bringup            │
│  [✓] Verification & measurement of Physics image              │
│  [✓] Monotonic, irreversible handoff to Physics                │
│  [✓] Fail-closed panic / halt state on anomaly                │
├────────────────────────────────────────────────────────────────┤
│ EXCLUDED (Explicit Non-Responsibilities):                      │
│  [✗] NO Filesystem (No ext4, FAT, ZFS, NVMe block layer)       │
│  [✗] NO Network (No TCP/IP, Ethernet, sockets, PCIe NICs)      │
│  [✗] NO Model (No neural networks, weights, KV cache, LLM)    │
│  [✗] NO General Runtime (No heap allocator, threads, libc)     │
│  [✗] NO Optimizer (No JIT, heuristics, runtime tuning)         │
│  [✗] NO Omega Compiler (No IR lowering, program synthesis)     │
│  [✗] NO Aien (No agents, no goals, no semantic reasoning)      │
└────────────────────────────────────────────────────────────────┘
```

### 3.1 Explicit Responsibilities
1. **Platform Hygiene**: Cleanse all processor state inherited from firmware/reset. Clear speculative flags, scrub general-purpose registers, set architectural control registers (`SCTLR_EL1`, `CPACR_EL1`, `TCR_EL1`) to safe, deterministic initial configurations.
2. **Deterministic Memory Substrate**: Configure minimal, static page tables covering only the Atlas text, read-only data, stack, diagnostic MMIO, and the Physics load window.
3. **Diagnostic Telemetry**: Initialize a physical diagnostic UART in polled, unbuffered mode to emit raw ASCII/hex error codes and milestones.
4. **Physics Measurement**: Read `physics.bin`, compute its cryptographic hash, verify it against the signed `physics.manifest`, and ensure its location adheres to the physical memory contract.
5. **Irreversible Handoff**: Prepare the CPU registers with the physical machine contract descriptor and jump into `physics.bin` entry point, irrevocably relinquishing execution.
6. **Deterministic Halting**: In the event of any bit discrepancy, signature failure, or unexpected exception, halt the CPU immediately in an unrecoverable fail-closed spin loop (`wfe`/`wfi`) after broadcasting a diagnostic fault code.

### 3.2 Explicit Non-Responsibilities
- **No Filesystem**: Atlas does not parse partition tables (GPT/MBR), disk formats, file trees, or inode structures. `physics.bin` is retrieved from raw, pre-mapped physical memory or memory-mapped flash.
- **No Network**: Atlas contains no network interface card (NIC) drivers, no MAC layer, no ARP, no IP stack, and no remote boot protocol.
- **No Model**: Atlas contains zero parameters, neural layers, tokenizers, or inference logic. It has no concept of language or reasoning.
- **No General Runtime**: Atlas operates without a heap (`malloc`/`free` do not exist). It does not schedule tasks, handle preemption, support multithreading, or manage user processes.
- **No Optimizer**: Atlas does not evaluate execution efficiency, profile code paths, or synthesize instructions.
- **No Omega Compiler**: Atlas does not compile or translate Intermediate Representations (IR).
- **No Aien**: The cognitive layer of the Sovereign Machine (Aien) does not exist during Atlas's lifetime. Aien cannot influence its own bootstrap seed.

---

## 4. Machine Contract: AArch64 Bare Metal

Atlas executes directly on bare metal AArch64 hardware. It relies on a rigorous physical contract:

```text
0x0000_0000 ┌──────────────────────────────────────────┐
            │ Boot ROM / Firmware Reserved             │
0x4000_0000 ├──────────────────────────────────────────┤ <── Atlas Load Base
            │ Atlas Code & Read-Only Data (.text/.rodata)│ [64 KB max]
0x4001_0000 ├──────────────────────────────────────────┤
            │ Atlas Static Scratch & Stack             │ [64 KB]
0x4002_0000 ├──────────────────────────────────────────┤ <── Physics Staging Buffer
            │ Physics Canonical Binary (physics.bin)   │ [Up to 16 MB]
0x4102_0000 ├──────────────────────────────────────────┤
            │ Available RAM / Dynamic Allocation Pool  │
            │ (Managed exclusively by Physics)         │
0x0900_0000 ├──────────────────────────────────────────┤ <── MMIO Region
            │ PL011 / Diagnostic UART Registers        │
            └──────────────────────────────────────────┘
```

### 4.1 Architecture & Endianness
- **Target Architecture**: AArch64 (ARMv8.2-A or later).
- **Endianness**: Strictly Little-Endian. Atlas verifies that the `EE` (Exception Endianness) and `E0E` bits in `SCTLR_EL1` (and `SCTLR_EL2` if entering at EL2) are cleared to `0`. If big-endian execution is detected, the processor vectors immediately to the terminal halt state.

### 4.2 Entry Address & Privilege Level
- **Entry Address**: Standardized at physical base address `0x4000_0000` (or `0x8000_0000` depending on platform board definitions, codified in `atlas.manifest`).
- **Entry Exception Level**: Declared by the machine contract (**EL2** or **EL1**). Atlas verifies `CurrentEL` against the contract and enters the fail-closed halt state on any mismatch.
- **Physics Handoff Level**: Declared by the machine contract. Control is transferred to Physics under `PHYSICS_ENTRY_ABI` at the contract-defined exception level with interrupts masked (`DAIF = 0xF`). Atlas performs no implicit EL2 -> EL1 transition.
- **Current QEMU Contract**: `CONTRACT-QEMU-VIRT-AARCH64-M2` specifies EL1 entry. Register names below are shown for an EL1 contract; an EL2 contract uses the corresponding `_EL2` registers.

### 4.3 Architectural Register State
Upon entry into Atlas:
- General-Purpose Registers: `x0`-`x30` are assumed to contain untrusted data from the previous bootloader stage.
- Register Sanitation: Atlas immediately zeroes `x1` through `x30`. If `x0` carries a platform device tree or firmware descriptor pointer, it is validated against physical memory bounds; otherwise, `x0` is also zeroed.
- Stack Pointer: The stack pointer `SP_EL1` is explicitly pointed to the high end of the dedicated 64 KB static scratchpad area:
  $$\text{SP\_EL1} = \text{0x4002\_0000}$$
- System Registers Configuration:
  - `SCTLR_EL1`: Configured with MMU disabled (`M=0`), Data Cache disabled (`C=0`), Instruction Cache disabled (`I=0`) during initial bootstrap, then Instruction Cache enabled (`I=1`) once validation begins. Strict alignment checking (`A=1`, `SA=1`) is permanently asserted.
  - `CPACR_EL1`: Traps for FP/SIMD are disabled (`FPEN = 0b11`) to permit standard register hygiene, but FP instructions are forbidden within Atlas code.
  - `DAIF`: Set to `0xF` (Debug, SError, IRQ, FIQ masked). No interrupts are unmasked during Atlas's lifecycle.

### 4.4 Memory Map and Alignment Contract
- **Instruction Alignment**: Every instruction must be 32-bit (4-byte) aligned.
- **Memory Access Alignment**: Strict alignment enforcement. Unaligned loads/stores result in an Alignment Fault, triggering immediate shutdown.
- **Cache Line Alignment**: Entry points, exception vectors, and critical verification structures must be aligned to 64-byte cache line boundaries.
- **Page Size**: Minimal identity translation uses 4 KB or 64 KB granule pages with Level 1/Level 2 block descriptors to avoid deep table walks.

### 4.5 Diagnostic Console Contract
- Polled MMIO UART (e.g., ARM PrimeCell PL011 or standard 16550) mapped into a dedicated 4 KB device memory page (`Device-nGnRE`).
- Zero interrupts. Atlas transmits bytes by polling the UART `FR` (Flag Register) until the Transmit FIFO is not full (`TXFF == 0`), writing the 8-bit ASCII character to `DR` (Data Register).
- Diagnostic format: 2-character hex status prefixes followed by newline (e.g., `00` = reset, `01` = registers scrubbed, `02` = physics measured, `EE` = fatal failure).

### 4.6 Terminal Failure State (Fail-Closed)
If any check fails:
1. Write 2-byte failure code to UART.
2. Disable all caches and MMU.
3. Zero all general purpose registers `x0`-`x30`.
4. Enter an infinite, interrupt-masked terminal spin loop:
   ```asm
   msr daifset, #0xf
   1:  wfe
       b 1b
   ```
5. No reboot loops, no silent recovery, no fallback execution paths.

---

## 5. Atlas Audit Specification

The Atlas Audit is the definitive proof of correctness and boundedness. Every single instruction in `atlas.bin` must be documented in `atlas.audit`.

### 5.1 Audit Invariants
1. **Total Reachability**: Every byte in `atlas.bin` must belong to a reachable basic block starting from the entry point, or a formally defined static data table. Zero orphaned bytes.
2. **Bounded Control Flow**: All branches (`b`, `b.cond`, `bl`, `cbz`, `cbnz`, `tbz`, `tbnz`) must target statically provable offsets within the text segment of `atlas.bin`. Indirect register branches (`br`, `blr`) are **strictly prohibited**, except for the final single transfer to Physics:
   $$\text{br } x0 \quad (\text{where } x0 \equiv \text{PHYSICS\_ENTRY\_POINT})$$
3. **Bounded Memory Access**: Load and store instructions (`ldr`, `str`, `ldp`, `stp`) must access only:
   - The predefined static stack frame (`[SP, #offset]`).
   - The declared MMIO UART address space.
   - The verified read-only memory window containing `physics.bin`.
4. **Zero Self-Modification**: No instruction may write to any memory range marked executable. The page tables strictly enforce `W^X` (Write XOR Execute).

### 5.2 Line-by-Line Audit Ledger Schema

Each instruction in `atlas.audit` is recorded using the following standardized schema:

```text
| Offset | Raw Bytes | Decoded Op | Inputs | Outputs | Branch Target | Memory Accessed | Privilege Required |
```

#### Canonical Audit Ledger Excerpt:

| Offset | Raw Bytes | Decoded Op | Inputs | Outputs | Branch Target | Memory Accessed | Privilege |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `0x0000` | `0xD5384100` | `mrs x0, CurrentEL` | `CurrentEL` | `x0` | `None` | `None` | `EL1/EL2` |
| `0x0004` | `0xD3424000` | `lsr x0, x0, #2` | `x0` | `x0` | `None` | `None` | `EL1/EL2` |
| `0x0008` | `0x7100081F` | `cmp w0, #2` | `w0` | `NZCV` | `None` | `None` | `EL1/EL2` |
| `0x000C` | `0x540000A0` | `b.eq 0x0020` | `NZCV` | `PC` | `0x0020` (EL2 setup) | `None` | `EL1/EL2` |
| `0x0010` | `0x7100041F` | `cmp w0, #1` | `w0` | `NZCV` | `None` | `None` | `EL1/EL2` |
| `0x0014` | `0x54000100` | `b.eq 0x0034` | `NZCV` | `PC` | `0x0034` (EL1 setup) | `None` | `EL1/EL2` |
| `0x0018` | `0x14000030` | `b 0x00D8` | `None` | `PC` | `0x00D8` (Halt Panic) | `None` | `EL1/EL2` |
| `...` | `...` | `...` | `...` | `...` | `...` | `...` | `...` |
| `0x01F8` | `0x58000140` | `ldr x0, [PC, #40]` | `PC` | `x0` | `None` | `0x0220` (Phys Base)| `EL1` |
| `0x01FC` | `0xD61F0000` | `br x0` | `x0` | `PC` | `Physics Entry` | `None` | `EL1` |

Every byte must be accounted for in the complete `atlas.audit` ledger. Unexplained data or non-audited opcodes invalidate the machine release.

---

## 6. Verification Gates

Before an Atlas build is admitted as a Sovereign Machine release, it must clear four mandatory, sequential verification gates:

```text
       ┌──────────┐
       │ ATLAS-0  │ ──> ATLAS_BOOT_PASS (Executes from reset to handoff on silicon)
       └────┬─────┘
            ▼
       ┌──────────┐
       │ ATLAS-1  │ ──> ATLAS_AUDIT_PASS (100% reachable byte & branch accounting)
       └────┬─────┘
            ▼
       ┌──────────┐
       │ ATLAS-2  │ ──> ATLAS_CORRUPTION_REFUSAL_PASS (1-bit mutation halts machine)
       └────┬─────┘
            ▼
       ┌──────────┐
       │ ATLAS-3  │ ──> ATLAS_REPRODUCIBILITY_PASS (Identical byte-for-byte build & trace)
       └──────────┘
```

### 6.1 Gate ATLAS-0: `ATLAS_BOOT_PASS`
- **Criterion**: `atlas.bin` boots on bare-metal hardware (or validated hardware-accurate emulator) from initial reset or firmware handoff, cleanses the processor state, initializes memory, validates the Physics payload, and successfully transitions execution to Physics.
- **Evidence Required**:
  - Raw UART console log capturing the expected sequence of diagnostic checkpoint tokens.
  - Hardware trace showing successful execution of the final `br x0` instruction into `physics.bin`.

### 6.2 Gate ATLAS-1: `ATLAS_AUDIT_PASS`
- **Criterion**: The build passes automated static audit analysis.
  - Zero instructions outside declared memory bounds.
  - Zero indirect jumps except the final Physics entry point.
  - Zero unverified NOP padding or orphaned bytes.
  - 100% compliance with `atlas.audit` line-by-line verification rules.
- **Evidence Required**: Signed `atlas.audit` and `atlas.control-flow` artifacts with zero unresolved edges and zero warnings from the audit validator tool.

### 6.3 Gate ATLAS-2: `ATLAS_CORRUPTION_REFUSAL_PASS` (1-Byte Mutation Test)
- **Criterion**: The system must prove its refusal capability against corruption. A test harness systematically introduces single-bit and single-byte mutations:
  1. Any 1-byte mutation in `atlas.bin` must fail static signature verification before execution.
  2. Any 1-byte mutation in `physics.bin` must be detected by Atlas's SHA-256 measurement loop, causing immediate abort and transition to the terminal fail-closed halt state.
  3. The corrupted payload must **never** be executed under any circumstance.
- **Evidence Required**: Automated test matrix report showing 1,000 randomized 1-bit and 1-byte corruption trials against `physics.bin`, with a 100% refusal and safe-halt rate.

### 6.4 Gate ATLAS-3: `ATLAS_REPRODUCIBILITY_PASS`
- **Criterion**: Complete, bit-for-bit reproducibility of the binary artifact and its execution trace.
  - The binary `atlas.bin` must be bit-for-bit reproducible across independent builds on distinct host systems using the certified toolchain container.
  - The runtime execution trace (instruction retired count, memory read sequence, register transitions) must be identical between consecutive boots given the same platform inputs.
- **Evidence Required**: Identical SHA-256 digests across 3 independent clean-room builds, and cycle-accurate execution trace equality up to the Physics entry instruction.

---

## 7. Canonical Invariant Checklist

Before declaring Milestone 0 complete for Atlas, the following invariants must be verified:

- [ ] `atlas.bin` size is strictly within limits ($\le$ 64 KB).
- [ ] No heap memory allocator is present or linked.
- [ ] No file system driver or network stack is present.
- [ ] No floating-point or vector registers are used.
- [ ] Every branch target is direct and statically bounded.
- [ ] MMIO UART access is strictly synchronous and polled.
- [ ] Single-byte corruption results in immediate, fail-closed terminal halt.
- [ ] Handoff to Physics is monotonic and irreversible.
- [ ] All 7 supporting evidence files are generated and cryptographically bound.
