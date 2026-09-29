# Mixed-Algebra Computing for an AI Stack: Prior-Art Survey

| Field | Value |
|---|---|
| Source model | Gemini (via agy), raw draft `gemini-priorart.md` |
| Date | 2026-09-29 |
| Verification status | PARTIALLY VERIFIED. 15 of 29 citations checked on the web by a Claude Opus 5.5 worker. Unchecked citations are marked `[unchecked]`. |
| Verdict counts | 7 VERIFIED, 7 WRONG DETAILS (fixed below), 1 NOT FOUND (removed) |
| Checked | BitNet b1.58, T-MAC, bitnet.cpp, RNSnet, Res-DNN, Beuchat (eta_T), Page and Smart (GF(3^m)), Pedersoli (bitplane), Inagaki (CIM), Wang and Roychowdhury (OIM), Chumak (magnonics), Goto (parametron), HERMES core, Le Gallo 64-core PCM chip, Lin/Kim/Lombardi (CNTFET). Also rechecked the arithmetic of radix economy and packing densities. |
| Main corrections | T-MAC authors, venue and speedup numbers were wrong. RNSnet speedup/energy numbers were wrong (Gemini understated them by roughly 20x to 60x and named the wrong baseline). Res-DNN authors and venue were invented. HERMES citation title and venue were wrong, and the 63.1 TOPS / 9.76 TOPS/W figures belong to the 64-core chip, not HERMES. Chumak 2015 is a review, not a logic demonstration. Pedersoli TCSI 2018 could not be found and was removed. |

How to read this file: text Gemini wrote that was not checked is kept but should be treated as a lead, not a fact. Every correction is marked **[fixed]**; every claim that could not be confirmed is marked **[unverified]**.

---

## 1. Balanced Ternary: History, Hardware, Radix Economy

Balanced ternary represents integers with signed digits {-1, 0, +1}. Compared with unsigned ternary {0, 1, 2} it gives sign symmetry, negation by flipping every digit (no carry), and rounding by truncation.

Nikolay Brusentsov built Setun at Moscow State University in 1958, followed by Setun-70 in 1970, using magnetic amplifier elements as ternary cells. [unchecked]

Radix economy: the cost per digit of radix r scales as r / ln r. Radix 2 gives 2.8854, radix 3 gives 2.7307, the optimum is at e. Radix 3 is about 5.4% cheaper than radix 2 by this measure (arithmetic rechecked; Gemini said 5.3%). This is a theoretical count of digit states, not a statement about real transistor cost.

CMOS ternary logic has struggled because intermediate voltage levels shrink noise margins and raise leakage. CNTFET designs set thresholds by nanotube diameter (Lin et al. 2011, verified below). Memristors have shown multi-level resistive states. [unchecked]

### Sources
1. Brusentsov, N. P., et al. (1960). "The Setun Small Digital Computing Machine." URL https://www.computer-museum.ru/english/setun.htm. [unchecked; Gemini itself said the DOI is unverified]
2. Brusentsov, N. P., and Ramil Alvarez, J. (2006/2011). "Ternary Computers: The Setun and the Setun 70." IFIP AICT, Springer. [unchecked; volume and DOI not confirmed]
3. Knuth, D. E. (1997). The Art of Computer Programming, Vol. 2, 3rd ed., Section 4.1. [unchecked, standard reference]
4. Lin, S., Kim, Y.-B., and Lombardi, F. (2011). "CNTFET-Based Design of Ternary Logic Gates and Arithmetic Circuits." IEEE Trans. Nanotechnology 10(2), 217-225. DOI 10.1109/TNANO.2009.2036845. **VERIFIED.** Note: results are SPICE simulation, not fabricated silicon.

---

## 2. Signed-Digit, CSD, and Redundant Number Systems

Positional addition has carry chains of depth O(n). Avizienis (1961) showed that redundant signed-digit representations allow carry-free addition whose delay does not grow with word length: a carry moves at most one position.

Canonical Signed Digit (CSD, Reitwiesner 1960) forbids two adjacent non-zero digits. Average non-zero density tends to about n/3, versus n/2 for plain binary. This turns constant multipliers into sparse shift-and-add trees. Redundant accumulators must be converted back to binary (a normal carry-propagate add) when results leave the accumulator.

### Sources [all unchecked; classic references, details look standard]
1. Avizienis, A. (1961). "Signed-Digit Number Representations for Fast Parallel Arithmetic." IRE Trans. Electron. Comput. EC-10(3), 389-400.
2. Reitwiesner, G. W. (1960). "Binary Arithmetic." Advances in Computers 1, 231-308.
3. Booth, A. D. (1951). "A Signed Binary Multiplication Technique." Q. J. Mech. Appl. Math. 4(2), 236-240.

---

## 3. Ternary Neural Networks, BitNet b1.58, and Kernels

Ternary networks constrain weights to {-1, 0, +1}, so multiply-accumulate becomes add or subtract.

- TTQ (Zhu et al., ICLR 2017): learned asymmetric scale factors. [unchecked]
- **BitNet b1.58** (Ma et al., 2024): ternary weights in LLMs. The paper states it matches a full-precision (FP16/BF16) Transformer of the same size and training tokens in perplexity and end-task performance. **VERIFIED** (abstract). The "8-bit activations" and "from 3B parameters upward" details come from the paper body and were not rechecked.
- BitNet a4.8 (Wang et al., 2024): 4-bit activations. [unchecked]

### Kernels and reported speedups

- **T-MAC** **[fixed]**. Correct citation: Wei, J., Cao, S., Cao, T., Ma, L., Wang, L., Zhang, Y., Yang, M. "T-MAC: CPU Renaissance via Table Lookup for Low-Bit LLM Deployment on Edge." EuroSys 2025, arXiv:2407.00088. Gemini gave the wrong authors ("Xie"), wrong title and wrong venue (USENIX ATC 24). Reported results: up to 4x throughput and 70% energy reduction versus llama.cpp; BitNet-b1.58-3B at 30 tokens/s on one core and 71 tokens/s on eight cores of an M2 Ultra, 11 tokens/s on a Raspberry Pi 5. Gemini's "2x to 11x" range is **not supported by the abstract**; removed. Method (lookup tables indexed by packed low-bit weights, no dequantization) is correct.
- **bitnet.cpp** (Microsoft, 2024). **VERIFIED** for ARM, with x86 added: ARM 1.37x to 5.07x speedup, 55.4% to 70.0% energy reduction; x86 2.37x to 6.17x speedup, 71.9% to 82.2% energy reduction. Kernel names I2_S, TL1, TL2 exist. Gemini's descriptions of their internals (TL1 "depth-2 LUT", TL2 "depth-3/4 LUT") are **[unverified]**. The repository now also lists an official GPU inference kernel.
- Ternary GPU kernels via BitBLAS "2x to 3.5x over FP16, negligible gain over INT4 Tensor Cores": **[unverified]**, no source given. Treat as a hypothesis to measure.

### Sources
1. Zhu, C., et al. (2017). "Trained Ternary Quantization." ICLR 2017. arXiv:1612.01011. [unchecked]
2. Ma, S., Wang, H., Ma, L., Wang, L., Wang, W., Huang, S., Dong, L., Wang, R., Xue, J., Wei, F. (2024). "The Era of 1-bit LLMs: All Large Language Models are in 1.58 Bits." arXiv:2402.17764. **VERIFIED.**
3. Wei, J., et al. (2025). "T-MAC: CPU Renaissance via Table Lookup for Low-Bit LLM Deployment on Edge." EuroSys 2025. arXiv:2407.00088. **[fixed]**
4. Microsoft. bitnet.cpp. https://github.com/microsoft/BitNet. **VERIFIED.**

---

## 4. Bitplane/Popcount Arithmetic and Trit Packing

1. Dual bitplanes: a ternary vector W splits into W+ (where W = +1) and W- (where W = -1), with W+ AND W- = 0. For integer activations X: Y = sum over W+ of X minus sum over W- of X. If activations are single bits (x in {0,1}, stored as a bit vector), Y = popcount(X AND W+) - popcount(X AND W-). **[fixed]**: Gemini wrote this for X in {-1, +1}, which needs an XNOR form instead; the AND form is for {0,1} bits.
2. 2-bit packing: 4 trits per byte, density log2(3)/2 = 79.2% (arithmetic rechecked).
3. 5 trits per byte: 3^5 = 243 < 256, density log2(243)/8 = 99.06% (rechecked). Uses 1.6 bits per trit, 20% less memory traffic than 2-bit packing. Whether that beats the unpack cost is an open measurement (see end).

### Sources
1. Rastegari, M., et al. (2016). "XNOR-Net." ECCV 2016. [unchecked]
2. ~~Pedersoli, F., et al. (2018). "Energy Efficient CNNs with Ternary Quantization and Bit-Plane Computation." IEEE TCSI 65(12).~~ **NOT FOUND, removed.** A search found no such paper. The closest real work by Pedersoli is "Espresso: Efficient Forward Propagation for Binary Deep Neural Networks" (ICLR 2018), which was not checked.
3. Courbariaux, M., et al. (2016). "Binarized Neural Networks." arXiv:1602.02830. [unchecked]

---

## 5. Residue Number Systems (RNS)

An RNS represents integer X by its remainders modulo pairwise coprime moduli m_1..m_k. By the Chinese Remainder Theorem the representation is unique over range M = product of m_i. Add and multiply work independently per channel with no carries between channels. Moduli sets like {2^n - 1, 2^n, 2^n + 1} make each channel cheap.

### RNS in DNN accelerators
- **RNSnet** **[fixed numbers]**: Salamat, Imani, Gupta, Rosing, IEEE ICRC 2018. The paper executes networks in memory in the digital domain using RNS. Reported: 145.5x less energy and 35.4x speedup versus an NVIDIA GTX 1080 GPU, and 8.5x better energy-delay product than prior NN accelerators. Gemini's "2.3x energy, 1.8x speedup, 16-bit MACs split into 5 to 6 bit channels" is not what the paper reports; removed. Note the baseline is a 2016 GPU, so the headline factors say little about a modern stack.
- **Res-DNN** **[fixed citation]**: Samimi, N., Kamal, M., Afzali-Kusha, A., Pedram, M. "Res-DNN: A Residue Number System-Based DNN Accelerator Unit." IEEE Trans. Circuits Syst. I 67(2), 658-671, 2020. Reported about 2.5x lower computation energy and about 30% lower overall energy than binary counterparts. Gemini's "Tartamella et al., JETCAS 2020" does not exist. The moduli set Gemini attributed to it is **[unverified]**.

### Known bottlenecks (consistent with the literature; not tied to one source)
1. Reverse conversion (CRT or mixed-radix) back to binary is slow and costly.
2. Comparison, sign detection, division, ReLU, softmax and normalization are not channel-wise; they need positional form.
3. Overflow past M wraps silently; detecting it needs extra channels.

Gemini's summary "unless dozens of MACs chain without activations, reverse conversion negates the savings" is a reasonable rule of thumb but **[unverified]** as a quantitative claim.

### Sources
1. Garner, H. L. (1959). "The Residue Number System." IRE Trans. Electron. Comput. EC-8(2), 140-147. [unchecked]
2. Taylor, F. J. (1984). "Residue Arithmetic: A Tutorial with Examples." Computer 17(5), 50-62. [unchecked]
3. Salamat, S., Imani, M., Gupta, S., Rosing, T. (2018). "RNSnet: In-Memory Neural Network Acceleration Using Residue Number System." IEEE ICRC 2018. **WRONG DETAILS, fixed.** DOI given by Gemini (10.1109/ICRC.2018.8638622) not confirmed.
4. Samimi, N., et al. (2020). "Res-DNN." IEEE TCAS-I 67(2), 658-671. **[fixed]**

---

## 6. Z3 / GF(3) Arithmetic and Ternary Cryptography

Z3 (the field GF(3)) is different from balanced ternary integers:
- Balanced ternary works over the integers with carries: (+1) + (+1) = +2 = (+1)*3 + (-1), so digit -1 carry +1.
- GF(3) works modulo 3 with no carry: (+1) + (+1) = 2 = -1 mod 3.

GF(3^m) hardware came from pairing-based cryptography on supersingular curves. In characteristic 3 the cubing map x -> x^3 is linear and cheap in hardware. Elements are commonly stored 2 bits per digit. Gemini's "a GF(3) adder takes 3 to 4 gates" is **[unverified]**.

AI relevance (Gemini's view, not a sourced claim): training and accumulation need ordered magnitudes, so GF(3) cannot replace integer math inside a network, but it can serve as a cheap checksum over ternary data.

### Sources
1. **[fixed]** Beuchat, J.-L., et al. (2008). "Algorithms and Arithmetic Operators for Computing the eta_T Pairing in Characteristic Three." IEEE Trans. Computers 57(11), 1454-1468. Gemini gave the title of the earlier ARITH-18 (2007) paper ("An Algorithm for the eta_T Pairing Calculation in Characteristic Three and its Hardware Implementation", Beuchat, Shirase, Takagi, Okamoto, pp. 97-104) and wrong pages. DOI not confirmed.
2. Bertoni, G., et al. (2006). "Computing the eta_T Pairing over GF(3^m) in Hardware." DATE 2006. [unchecked]
3. **[fixed]** Page, D., and Smart, N. P. "Hardware Implementation of Finite Fields of Characteristic Three." CHES **2002**, LNCS **2523**. DOI 10.1007/3-540-36400-5_38. Gemini gave CHES 2004, LNCS 3156 and a wrong DOI.

---

## 7. Phase-Domain and Oscillator Computing

Phase computing stores a value in the phase of an oscillation.

1. Goto's parametron (invented 1954): a nonlinear resonant circuit pumped at twice its frequency oscillates in one of two phases pi apart, giving a binary digit and majority logic. **VERIFIED** (Proc. IRE, August 1959, pp. 1304-1316). The PC-1 computer at the University of Tokyo used parametrons. [PC-1 detail unchecked]
2. Von Neumann independently patented subharmonic phase-locked logic in the 1950s. [unchecked]

Roots of unity: binary phase {0, pi} generalizes to n phases exp(j 2 pi k / n). For n = 3, phases {0, 120, 240 degrees} are the cube roots of unity and multiplying them adds exponents mod 3 (see PHASE_EXPERIMENT_AND_HARDWARE.md for the math and a C check).

### Modern demonstrations
- **Coherent Ising machine**: Inagaki, T., et al. (including McMahon, P. L.), Science 354(6312), 603-606, 2016. Time-multiplexed degenerate optical parametric oscillators solving MAX-CUT on up to 2000 nodes. **VERIFIED.**
- **Oscillator Ising machines**: Wang, T., and Roychowdhury, J. "OIM: Oscillator-Based Ising Machines for Solving Combinatorial Optimisation Problems." UCNC 2019, Springer LNCS, DOI 10.1007/978-3-030-19311-9_19, arXiv:1903.07163. **VERIFIED.** Caveat: this paper is theory plus simulation (subharmonic injection locking gives a Lyapunov function tied to the Ising Hamiltonian). Hardware prototypes are in a separate DAC 2019 paper ("New Computational Results and Hardware Prototypes for Oscillator-based Ising Machines") [unchecked]. Gemini's "demonstrated coupled CMOS LC/ring oscillators" is attributed to the wrong paper.
- Optical matrix multiply: Shen, Y., et al. "Deep learning with coherent nanophotonic circuits." Nature Photonics 11, 441-446, 2017. [unchecked]. "At light speed" is marketing wording; conversion and detection dominate real cost.
- **[fixed]** Spin waves: Chumak, A. V., Vasyuchka, V. I., Serga, A. A., Hillebrands, B. "Magnon spintronics." Nature Physics 11, 453-461, 2015. This is a **review article**, not a demonstration of magnonic-crystal logic as Gemini claimed. It surveys wave-based computing with magnons.

Accuracy and latency: interference itself is fast, but phase noise, jitter, and the cost of converting phase back to digital set the real limits. [general statement]

---

## 8. Analog In-Memory Matrix-Vector Multiply

Compute-in-memory stores weights as conductances G_ij in a crossbar. Input voltages drive rows; by Ohm's law and Kirchhoff's current law the column currents are the matrix-vector product.

### Silicon
1. **[fixed]** IBM HERMES core: Khaddam-Aljameh, R., et al. "HERMES Core: A 14nm CMOS and PCM-based In-Memory Compute Core using an array of 300ps/LSB Linearized CCO-based ADCs and local digital processing." VLSI Symposium 2021; journal version "HERMES-Core: A 1.59-TOPS/mm2 PCM on 14-nm CMOS In-Memory Compute Core Using 300-ps/LSB Linearized CCO-Based ADCs," IEEE JSSC 2022. One 256x256 PCM crossbar, 256 CCO-based ADCs, local digital unit for scaling and ReLU. Gemini's title ("HERMES-E ... 4.88 TFLOPS/W"), venue (ISSCC 2021) and DOI are wrong.
2. **VERIFIED with correction**: Le Gallo, M., et al. (2023). "A 64-core mixed-signal in-memory compute chip based on phase-change memory for deep neural network inference." Nature Electronics. DOI 10.1038/s41928-023-01010-1. 64 cores, each a 256x256 PCM crossbar, 14 nm CMOS. For 8-bit input/output matrix-vector multiply: 63.1 TOPS at 9.76 TOPS/W in the one-phase (low-precision) read mode, or 16.1 TOPS at 2.48 TOPS/W in the four-phase (high-precision) mode. **[fixed]**: Gemini attributed 63.1 TOPS / 9.76 TOPS/W to HERMES and to "ResNet and LSTM benchmarks"; they are the 64-core chip's peak MVM figures, and the high-precision figures are four times lower.
3. Joshi, V., et al. (2020). "Accurate deep neural network inference using computational phase-change memory." Nature Communications 11, 2473. [unchecked]
4. Mythic AMP: analog compute in embedded flash cells. [unchecked]

### Limits (Gemini's claims)
1. "Crossbar is under 20% of tile power; ADCs, DACs and digital are 80% to 85%": **[unverified]**. The direction (converters dominate) is widely reported, but the specific split was not traced to a source.
2. PCM conductance drift G(t) = G0 (t/t0)^(-nu) needs compensation. Standard model. [unchecked]
3. "4 to 6 equivalent bits per cell": **[unverified]**.

---

## What Is Already Known (do not claim as novel)

- Radix 3 is about 5.4% more economical than radix 2 in the digit-count sense; binary CMOS still wins on manufacturing and noise margin.
- Signed-digit redundant representations give carry-free addition (Avizienis 1961).
- CSD reduces average non-zero digits to about n/3.
- Ternary-weight LLMs can match full-precision models of the same size (BitNet b1.58 claim).
- Ternary dot products map onto two bitplanes plus AND and popcount.
- RNS gives carry-free per-channel arithmetic; reverse conversion, overflow and non-linear ops are the known costs.
- GF(3) is modulo-3 field math with no carries; balanced ternary is integer math with carries.
- Phase logic with parametrons and injection-locked oscillators dates to the 1950s.
- Analog crossbar efficiency is limited by converters and peripherals.

## Open Questions Where Measurement Is Needed

- Break-even between INT8 SIMD, bitplane popcount, sparse index lists and 5-trits-per-byte lookup on the Grace CPUs, conversion cost included.
- When lookup-table kernels (T-MAC, bitnet.cpp) lose to plain SIMD (ARM sdot or vector popcount) as batch size grows.
- Whether 5-trits-per-byte packing beats 2-bit packing in wall-clock time once unpacking is included.
- Whether residue arithmetic can be confined to accumulators while weights stay ternary and activations INT8.
- True energy of phase readout (phase detector or ADC) at the digital boundary.
- Headroom needed before CRT wraparound for ternary-weight INT8 matrix multiply.
