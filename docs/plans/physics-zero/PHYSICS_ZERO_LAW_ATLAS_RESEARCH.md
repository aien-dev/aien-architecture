# Physics Zero Law Atlas: Literature and Capability Review

Status: DRAFT for review. Lane 36, Wave 0. Research and design only. Nothing here is built or run.
Companion: `PHYSICS_ZERO_LAW_ATLAS_V1.md` (the design). Doctrine owner: `doctrine/DISCOVERY.md` (DOCTRINE-006), read only.

## 0. What this document is for

Physics Zero asks whether an AIEN system can discover the laws of a hidden world from neutral
observations and interventions, without being handed textbook vocabulary. This review does two things.

1. It lists the families of physical law worth turning into hidden-world benchmarks, and classifies each
   one by how much it earns its place.
2. For each family it names the NEW semantic capability the family tests, so that every benchmark
   exists to probe something the earlier benchmarks did not.

A family that tests no new capability is marked REDUNDANT, even when it is famous.

## 1. Method and evidence honesty

- Literature tables were drafted by Gemini (`agy`) and then reviewed by the lead. Citations are
  author, year, venue as remembered by the drafting model. Entries marked `(unsure)` were not
  confirmed and must be spot-checked before any citation is used in a paper. No citation here is a
  claim about AIEN results.
- Grok was the planned second checker but returned a usage-balance error (HTTP 402), so it did not run.
  Status: Grok check NOT_RUN.
- Twenty mathematical statements used in the design were checked by Codex (`gpt-6-astra`). Seventeen
  were confirmed as written. Three needed qualification and the qualified forms are used here:
  - The Chern number is an integer for a nondegenerate band over a closed sphere. The value of plus or
    minus one belongs to the spin-1/2 eigenstate over the sphere of field directions, not to every
    two-level parameter sphere.
  - The Ornstein-Uhlenbeck stationary variance is sigma squared over 2 theta only when theta is positive.
  - Gross-Pitaevskii dynamics conserve norm for real potential and real coupling, and conserve energy
    when the potential and coupling do not depend on time, under suitable boundary conditions.
- The lead also checked by hand: the CHSH maximum 2 root 2 at the standard angles, the sampling cost
  (about 73 pairs per setting pair for a five-sigma gap between 2 root 2 and 2), the dephasing decay
  exp(-gamma t) for a sigma-z jump operator with rate gamma over 2, and the rule of three (60 null worlds
  with zero false discoveries bounds the false-positive rate on null worlds near 4.9 percent at 95 percent confidence).
- Repository statements were read from the live repositories on 2026-10-01 (arch main 921797b, omega
  main 07004a8). Where a plan and the code disagree, the code wins and the gap is stated.

## 2. Classification vocabulary

- ESSENTIAL: the first benchmark ladder is incomplete without it.
- HIGH VALUE: tests a clearly distinct capability, schedule after the essentials.
- LATER: valid and distinct, but needs machinery AIEN does not have yet, or adds little beyond an
  earlier rung for now.
- REDUNDANT: its capability is already covered by another family. Use it as a control inside that
  family, not as its own rung.
- TOO ADVANCED FOR CURRENT STACK: cannot be posed fairly with today's numerics or evaluator.
- POOR DISCOVERY BENCHMARK: no observable could separate the candidate answers.

Oracle cost is Cheap, Moderate or Expensive for the hidden-world generator, not for AIEN.

## 3. Classification table

Rung names refer to the Atlas in V1 section 1. PZ = classical, Q = quantum, F = fields, S = statistical
and scale, X = cross-formalism, G = geometry.

### 3.1 Classical mechanics and dynamics

| Family | Class | New capability tested | Oracle cost | Rung | Prior art |
|---|---|---|---|---|---|
| Classical identifiability (latent variables, hidden parameters, distractors) | ESSENTIAL | Telling what is observable from what must be inferred; refusing to name an unidentifiable quantity | Cheap | PZ-A | Schmidt & Lipson 2009 Science; Brunton, Proctor & Kutz 2016 PNAS (SINDy); Iten et al. 2020 PRL (SciNet) |
| Lagrangian and variational mechanics | ESSENTIAL | A law stated as one scalar functional, not as a list of equations; non-uniqueness (L and L plus total time derivative) | Cheap | PZ-B | Cranmer et al. 2020 (Lagrangian neural networks); Greydanus et al. 2019 NeurIPS (Hamiltonian networks) |
| Noether symmetry and conservation | ESSENTIAL | Linking a transformation that leaves predictions unchanged to a conserved quantity, in both directions | Cheap | PZ-B | Noether 1918; Liu & Tegmark 2021 PRL (conserved quantities); Udrescu & Tegmark 2020 Sci. Adv. |
| Two-body and central force | HIGH VALUE | Reduction to a smaller effective system; hidden second body as a latent | Cheap | PZ-A variant | Schmidt & Lipson 2009; Iten et al. 2020 |
| Liouville | REDUNDANT | Phase-space volume conservation is a Noether-class check; use as a control in Q2 and S1 | Cheap | control | Greydanus et al. 2019 |
| Lorenz and chaos | HIGH VALUE | Telling deterministic chaos from noise when pointwise prediction is impossible; scoring by invariant measures | Cheap | S2 | Lorenz 1963; Brunton et al. 2016; Pathak et al. 2018 (unsure) |
| Bifurcation | HIGH VALUE | Discovering that a law changes qualitatively at a parameter value; normal forms | Cheap | S2 | Champion et al. 2019 PNAS; Bramburger et al. 2020 (unsure) |
| Kuramoto | REDUNDANT | Gauge-like global phase freedom is already tested in Q0 and the Ising rung | Cheap | control | Kuramoto 1975 |

### 3.2 Fields and waves

| Family | Class | New capability tested | Oracle cost | Rung | Prior art |
|---|---|---|---|---|---|
| Wave and diffusion equations | ESSENTIAL | Laws over fields (space and time), finite versus infinite signal speed, differential operators as the law's content | Cheap | PZ-C | Rudy et al. 2017 Sci. Adv. (PDE-FIND); Raissi et al. 2019 JCP (PINNs) |
| Maxwell and Abelian gauge (2+1D reduced) | ESSENTIAL | Gauge freedom: different potentials, same observations; discovering the gauge rather than a coordinate system | Moderate | PZ-C, F1 | Favoni et al. 2022 PRL; Boyda et al. 2021; Cohen & Welling 2016 |
| Euler-Lagrange for fields | HIGH VALUE | Variational principle extended to fields; boundary terms | Moderate | F1 | Cranmer et al. 2020 |
| KdV and solitons | HIGH VALUE | Nonlinear structure with many conserved quantities, so identification is not unique | Cheap | F2 | Zabusky & Kruskal 1965; Rudy et al. 2017 |
| Navier-Stokes (2D) | LATER | Nonlinear advection plus a pressure that is defined only up to a function of time | Moderate | F3 | Rudy et al. 2017; Raissi et al. 2019 |
| Reaction-diffusion | LATER | Pattern formation from instability; distinct mechanisms give the same patterns | Moderate | F3 | Turing 1952; Schaeffer 2017 PNAS (unsure) |
| Full 3D turbulence | TOO ADVANCED FOR CURRENT STACK | Needs dense 3D grids and statistics far beyond the CPU-only stack | Expensive | none | none |

### 3.3 Quantum structure (rung Q)

| Family | Class | New capability tested | Oracle cost | Rung | Prior art |
|---|---|---|---|---|---|
| Schrodinger evolution (finite-dimensional) | ESSENTIAL | Complex amplitudes as a compact representation; unitary evolution; global phase as a gauge. Note C^N is R^(2N) with a rotation-like structure, so the benchmark rewards compact structure, not complex vocabulary | Cheap | Q0 | Renou et al. 2021 Nature (real versus complex quantum theory) |
| Born rule as observation model | ESSENTIAL | Probabilities from amplitudes; separating the state from the measurement record | Cheap | Q0 | Born 1926 |
| Heisenberg picture | ESSENTIAL | The same predictions from an evolving state or an evolving observable: the first cross-formalism test | Cheap | Q1 | Heisenberg 1925 |
| Density operators and mixed states | ESSENTIAL | Ensemble ambiguity (many ensembles, one state); purification as an equivalent form | Cheap | Q2 | von Neumann 1932 |
| Bell and CHSH | ESSENTIAL | Telling a classical hidden-variable account from a quantum one by a discriminating experiment | Cheap | Q3 (later wave) | Bell 1964; CHSH 1969; Tsirelson 1980; Aspect 1982; Hensen et al. 2015 Nature |
| Kraus maps and Lindblad generators | ESSENTIAL | Open-system dynamics; gauge-like freedom in jump operators; decoherence as a discrepancy from unitary law | Moderate | Q2, Q4 | Lindblad 1976; Gorini, Kossakowski & Sudarshan 1976; Kraus 1983; Breuer et al. 2016 RMP |
| Gate set tomography style gauge | HIGH VALUE | A representation freedom that no data can remove; scoring gauge-invariant quantities only | Moderate | Q4 | Nielsen et al. 2021 Quantum (unsure) |
| Hamiltonian learning | HIGH VALUE | Parameter estimation with calibrated uncertainty, a bridge to EST | Moderate | Q4 | Wiebe et al. 2014 PRL (unsure); Bairey et al. 2019 PRL (unsure) |
| Pauli algebra and spin | HIGH VALUE | Discovering a non-commuting operator algebra from data | Cheap | Q1 variant | none beyond textbooks |
| Berry phase | HIGH VALUE | A geometric quantity that depends on the loop, not the speed | Cheap | Q5 | Berry 1984; Simon 1983 |
| Path integral (finite-dimensional) | HIGH VALUE | The same transition amplitude as a sum over paths: a cross-formalism rung | Moderate | X-0 | Feynman 1948 |
| Klein-Gordon | ESSENTIAL (design-risk caveat: could drop to HIGH VALUE) | Second-order relativistic wave law with a mass gap; tests operator discovery over fields | Moderate | Q5 | none specific |
| Dirac | ESSENTIAL (separate program) | Matrix-valued operators, spinors, basis independence | Moderate | Q6 via DIRAC-0 | see `docs/plans/dirac/DIRAC-0-SPEC.md` |
| Chern invariants | LATER | Topological invariants as integers a candidate must find, not fit | Moderate | later | TKNN 1982 |
| Non-Markovian dynamics | LATER | Memory kernels; hard to separate from state enlargement | Expensive | later | Rivas et al. 2014 (unsure) |
| Master equations | LATER | Discrete jump processes with detailed balance | Cheap | later | van Kampen 1981 |
| QED | TOO ADVANCED FOR CURRENT STACK | Infinite-dimensional field theory with renormalization | Expensive | none | none |
| Measurement-problem interpretations | POOR DISCOVERY BENCHMARK | Interpretations make identical predictions, so no experiment separates them | n/a | none | none |

### 3.4 Many-body, statistics and scale (rung S, X)

| Family | Class | New capability tested | Oracle cost | Rung | Prior art |
|---|---|---|---|---|---|
| Ising and lattice spin models | ESSENTIAL | Discrete many-body law, collective behaviour, order parameter as a discovered concept | Cheap | S0 | Onsager 1944; Wetzel 2017 PRE |
| Langevin and noise | ESSENTIAL | Separating deterministic force from stochastic forcing; friction and noise tied together | Cheap | S1 | Champion et al. 2019 |
| Fokker-Planck | HIGH VALUE | The same process described by sample paths or by a density: cross-formalism | Cheap | X-0 | Raissi et al. 2019 |
| Renormalization group | ESSENTIAL | A law that changes with scale; relevant and irrelevant terms; flow in theory space | Moderate | SC-0 | Wilson 1971; Wilson & Kogut 1974; Mehta & Schwab 2014; Koch-Janusz & Ringel 2018 |
| Universality | ESSENTIAL | Different microscopic worlds with identical large-scale behaviour | Moderate | SC-0 | Widom 1965; Kadanoff 1966 |
| Effective and coarse-grained theories | ESSENTIAL | Valid-in-a-region laws; memory and noise appear when variables are dropped | Moderate | SC-0 | Zwanzig 1960; Mori 1965; Weinberg 1979 |
| Boltzmann kinetic theory | HIGH VALUE | Kinetic to fluid reduction as a theory succession | Expensive | SC-1 | Chapman 1916; Enskog 1917 |
| Heisenberg spin chain, Hubbard, Gross-Pitaevskii, Bogoliubov | LATER | Strongly interacting or mean-field many-body physics; state spaces too large for the current stack | Expensive | later | none specific |
| BBGKY | REDUNDANT | Closure is covered by the scale rung | Moderate | control | none |
| Partition functions (standalone) | REDUNDANT | Covered by Ising and RG | Cheap | control | none |
| Yang-Mills (small synthetic) | LATER | Non-Abelian gauge structure; needs Abelian gauge solved first | Expensive | later | none |

### 3.5 Geometry and theory succession (rung G, T)

| Family | Class | New capability tested | Oracle cost | Rung | Prior art |
|---|---|---|---|---|---|
| Theory succession (Newton to relativity, closed to open quantum, kinetic to fluid) | ESSENTIAL | Recognizing that an old theory is a limit of a new one, and knowing where it fails | Moderate | T-0 | Wu & Tegmark 2019 PRE (AI Physicist) |
| Geodesic motion | HIGH VALUE | Curved-space motion; coordinates that are not physical | Cheap | G-0 | Cranmer et al. 2020 |
| Coordinate invariance in GR | HIGH VALUE | Equivalence classes of descriptions under a large coordinate group | Moderate | G-0 | none |
| Curvature and tidal deviation | LATER | Separating real curvature from uniform acceleration | Moderate | later | none |
| Einstein field equation (reduced) | LATER | Dynamic geometry; only in symmetric reduced models | Expensive | later | none |
| Full numerical relativity | TOO ADVANCED FOR CURRENT STACK | Needs large mesh refinement | Expensive | none | none |

## 4. Automated-discovery prior art, and what it leaves open

Ten published systems anchor the field. This list is a map, not an endorsement of any result.

1. Schmidt & Lipson 2009, Science: symbolic regression that recovers conservation laws.
2. Brunton, Proctor & Kutz 2016, PNAS: sparse regression over a function library (SINDy).
3. Rudy et al. 2017, Science Advances: the same idea for partial differential equations (PDE-FIND).
4. Champion et al. 2019, PNAS: learns coordinates and equations together.
5. Greydanus et al. 2019, NeurIPS: networks that respect Hamilton's equations.
6. Wu & Tegmark 2019, Physical Review E: several theories, each valid in a region.
7. Cranmer et al. 2020, NeurIPS: Lagrangian neural networks.
8. Iten et al. 2020, Physical Review Letters: latent concepts from a bottleneck network (SciNet).
9. Udrescu & Tegmark 2020, Science Advances: symbolic regression using discovered symmetries.
10. Liu & Tegmark 2021, Physical Review Letters: conserved quantities from trajectories.

Benchmark suites: SRBench (La Cava et al. 2021) and SRSD (Matsubara et al. 2022). Both score equation
recovery against a known textbook formula, which rewards recognizing a formula. Neither isolates a
hidden oracle, scores equivalence across formalisms, or includes worlds with no law to find.
Those gaps are what the Atlas adds. This is a statement about design intent. The gaps were not audited
paper by paper (unsure for individual cases).

## 5. Capabilities that more than one family needs

The design in V1 admits a generic capability only if at least two rungs need it.

| Capability | Families that need it |
|---|---|
| Real, complex and tensor value types | Q0, Q1, Q2, F1, G-0, Dirac |
| Declared transformation with an observation map | Noether, gauge, basis change, coordinate change, field redefinition |
| Invariant claim with DISCOVERED, NOT FOUND, REJECTED, INCONCLUSIVE | PZ-B, PZ-C, Q0, Q3, S0 |
| Discrepancy model (what the theory does not explain) | Lindblad, chaos, coarse-graining, succession |
| Theory-link edges (equivalent to, reduces to, parent) | Heisenberg versus Schrodinger, Fokker-Planck versus Langevin, succession, RG |
| Testable validity region | RG, effective theory, succession, bifurcation |
| Distribution-valued laws | Langevin, Fokker-Planck, Born rule, Lindblad |

## 6. Ground truth about the current stack (what the benchmarks can lean on)

All of this was read from the repositories on 2026-10-01.

- Doctrine already defines `OMEGA_THEORY` and `OMEGA_DISCOVERED_CONCEPT` (DISCOVERY.md sections 7.1
  and 7.2), the sealed world oracle (section 6), the clean-lineage rule (section 5), the benchmark
  pyramid P0-0 to P0-8 (section 12), and the equivalence rule (section 16.6).
- Omega has eleven semantic categories and no real, complex or tensor type, and no differential
  operator. The Omega compiler slice handles small closed integer programs, and the Program IR has no
  FP32 value type.
- E1 numerics are partial: F32 scalar tier only, transcendentals bounded and CPU only.
- M20 (tensors) is an unmerged draft, CPU only, not qualified, no complex type.
- Estimation (EST-3) failed in v1, v2 and v3. v4 has no verdict. EST-4 to EST-10 are blocked.
- TURING has a held-out description-length score (TY-2 PASS) and an independent-scorer precedent
  (EXP-001R). Its selector kill test failed, so an active-scientist gate waits.
- There is no AIEN-P0 clean lineage yet. Any run by today's AIEN stack is an inherited-knowledge
  experiment and sits outside Physics Zero (DISCOVERY.md section 16.7).
- DIRAC-0 (Lane 35, PR #83) owns the Dirac rung. This review cites it and does not duplicate it.

## 7. Recommended order

1. Write evaluator and reference solvers first (V1 sections 6 and 9). They need no AIEN capability.
2. PZ-A, PZ-B, PZ-C, Q0, Q1, Q2 (the six specs in V1).
3. Next specs: SC-0 (scale and renormalization) and X-0 (cross-formalism), because Drake's emphasis
   is theories that change with scale and the same physics in different forms.
4. Q3 (Bell), Q4 (open systems and Hamiltonian learning), Q5 (Klein-Gordon, Berry), then Q6 (Dirac).

8. Addendum A (Constraint-to-Structure, Drake's 2026-10-01 brief) changes the order. The first build is
   the C2S-0 Representational Adequacy Lab (see V1 Addendum A.10), before any quantum rung beyond Q0
   and before every Dirac challenge. Where this section and V1 Addendum A differ, V1 Addendum A wins.
   Note on table order in V1: rows group rungs by family, not by milestone. Milestone order follows
   `doctrine/ROADMAP.md`.
## 8. Open items

- Spot-check every `(unsure)` citation before external use.
- Grok check of the math is NOT_RUN. A second independent check remains owed.
- Whether Klein-Gordon is ESSENTIAL or HIGH VALUE depends on how the first quantum rungs score.
