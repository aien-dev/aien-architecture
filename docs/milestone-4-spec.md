# Specification: Milestone 4 — Omega Semantic Substrate (`OMEGA_SEMANTICS`)

```text
Document ID:     SPEC-OMEGA-M4
Milestone:       Milestone 4 (OMEGA_SEMANTICS)
Classification:  Sovereign Machine Canonical Specification
Target Substrate: Sovereign Semantic Graph (Substrate-Independent Content-Addressed Identity)
Status:          SPECIFIED / IN PROGRESS (aien-dev/aien-architecture#16)
Lineage:         SILICON -> ATLAS (M1) -> PHYSICS (M2/M3) -> OMEGA (M4+) -> AIEN
```

---

## 1. Executive Summary & Foundational Invariants

Milestone 0 defined the sovereign doctrine.
Milestone 1 established ATLAS as the irreducible bootstrap seed (`ATLAS_BOOT`).
Milestone 2 established PHYSICS as physical machine authority (`PHYSICS_BOOT`).
Milestone 3 established that PHYSICS exercises authority strictly through capability-bounded, receipt-producing physical effects (`PHYSICS_EFFECTS`).

Milestone 4 establishes the sovereign layer directly above PHYSICS:

> **OMEGA DEFINES WHAT COMPUTATION MEANS WITHOUT COMMITTING THAT MEANING TO A PARTICULAR MACHINE REPRESENTATION.**

The objective of Milestone 4 is not to build a programming language, compiler, optimizer, model runtime, tensor engine, or AI system. The objective is to construct the smallest sovereign semantic substrate capable of representing computation independently of the physical machine that will eventually realize it.

### Canonical Stack at M4

```text
SILICON / UNAVOIDABLE FIRMWARE
             ↓
           ATLAS
      BOOTSTRAP SEED
             ↓
          PHYSICS
   PHYSICAL AUTHORITY
             ↓
           OMEGA
      SEMANTIC MEANING
             ↓
            AIEN
       NOT YET BUILT
```

### Canonical Responsibility Boundary

```text
ATLAS
    awakens the machine.

PHYSICS
    owns physical authority and mediates physical effects.

OMEGA
    defines meaning, invariants, relations, constraints,
    effects, resources, and realizations.

AIEN
    will later search over those meanings.
```

Milestone 4 strictly preserves the sovereign axioms:

```text
SMART ≠ TRUSTED
INTELLIGENCE ≠ AUTHORITY
MEANING IS PERMANENT; REPRESENTATION IS DISPOSABLE.
```

---

## 2. The Primary M4 Invariant

Milestone 4 succeeds when the system demonstrates:

> **THE SAME SEMANTIC OBJECT HAS THE SAME CANONICAL IDENTITY REGARDLESS OF NON-SEMANTIC REPRESENTATION DETAILS.**

Formally:

$$\text{SEMANTICALLY\_EQUIVALENT}(A, B) \implies \text{SEMANTIC\_ID}(A) = \text{SEMANTIC\_ID}(B)$$

while:

$$\text{SEMANTICALLY\_DIFFERENT}(A, B) \implies \text{SEMANTIC\_ID}(A) \neq \text{SEMANTIC\_ID}(B)$$

A semantic identity is **never** simply the hash of raw representation bytes:

$$\text{SEMANTIC\_ID} \neq \text{SHA256}(\text{raw\_input\_bytes})$$

Instead, canonical identity is derived exclusively through the canonicalization pipeline:

```text
RAW REPRESENTATION (Text / Binary / Builder Sequence / AST)
       ↓
PARSE / CONSTRUCT
       ↓
VALIDATE (Types, bounds, relations, acyclicity)
       ↓
CANONICALIZE SEMANTICS (Sort, normalize, deduplicate, un-alias)
       ↓
CANONICAL SEMANTIC ENCODING (Deterministic byte stream)
       ↓
SEMANTIC_ID = SHA256(canonical_semantic_bytes)
```

---

## 3. Strict Anti-Scope (The Anti-Bloat Law for OMEGA)

Milestone 4 is the foundation of the sovereign semantic universe. It is **not** a general language compiler or execution runtime.

The following components are **strictly excluded** from Milestone 4:
- Direct AArch64 machine byte realization generator (strictly reserved for M5 `OMEGA_AARCH64`)
- Self-hosting realization compiler (strictly reserved for M6 `OMEGA_SELF_HOST`)
- V3-V5 proof engines and proof-carrying code generators (reserved for M7 `OMEGA_VERIFY`)
- Program synthesis solvers, synthesis task schemas, and cost models (reserved for M8/M9)
- Equality saturation, e-graphs, rewriting optimizers, and JIT compilers
- MachineGraph physical pipeline topologies (reserved for M13)
- GPU initialization, Blackwell MMIO, and vector/matrix compute (reserved for M15-M18)
- Tensor multi-dimensional strides, autograd, and loss functions (reserved for M20-M22)
- Neural models, search guides, weights, and AIEN cognitive agents (reserved for M24+)
- Filesystems, POSIX interfaces, networking stacks, and operating system runtimes

---

## 4. The Initial OMEGA Semantic Universe

M4 establishes the foundational set of first-class semantic object categories:

```text
VALUE
TYPE
OPERATION
RELATION
CONSTRAINT
MEMORY
MACHINE
EFFECT
REALIZATION
EVIDENCE
PROOF
```

These are **semantic categories**. They are not Rust enums, C structs, or JSON schemas in the permanent architecture. Temporary bootstrap representations in implementation languages are permitted, but they must be explicitly declared as:

```text
BOOTSTRAP REPRESENTATION
NOT PERMANENT SEMANTIC DEFINITION
```

---

## 5. The Initial Semantic Graph ($G_S$)

OMEGA represents meaning as a directed, typed, content-addressed graph $G_S = (V, E)$.

### Canonical Conceptual Object

```text
OMEGA_OBJECT {
    semantic_id:  SemanticId (32 bytes SHA-256)
    kind:         SemanticKind
    attributes:   CanonicalAttributeMap
    relations:    SortedSet<SemanticRelation>
    constraints:  SortedSet<SemanticConstraint>
}
```

- Relationships are explicit first-class semantic objects or typed directed edges.
- Objects reference other objects **strictly by semantic identity** (`SemanticId`), never by ephemeral physical host memory pointer addresses.
- All attribute keys, relation targets, and constraints are deterministically ordered.

---

## 6. Types

M4 provides an explicit, unambiguous type system with strictly bounded widths. Ambiguous machine-dependent types (`int`, `long`, `usize`, `native_word`) are forbidden at the semantic layer.

### Initial Type Universe
1. `UNIT`: The singleton type representing computational void.
2. `BOOL`: Standard boolean value ($\{\text{false}, \text{true}\}$).
3. `UNSIGNED_INTEGER(width)`: Fixed-width unsigned integer ($w \in [1, 256]$ bits).
4. `SIGNED_INTEGER(width)`: Fixed-width two's complement signed integer ($w \in [2, 256]$ bits).
5. `BITVECTOR(width)`: Uninterpreted bit vector of exact width ($w \in [1, 256]$ bits).
6. `BYTE`: Exact 8-bit octet (`BITVECTOR(8)` equivalent).
7. `SEQUENCE(element_type, length)`: Homogeneous fixed-length sequence ($L \in [0, 65535]$).
8. `TUPLE(types...)`: Heterogeneous fixed-order tuple of types.
9. `ADDRESS`: Semantic computational address (width explicitly parameterized).
10. `RESOURCE`: Abstract resource identifier type.
11. `CAPABILITY_REFERENCE`: Abstract semantic capability handle referencing authority.
12. `EFFECT_INTENT_REFERENCE`: Abstract reference to an intended physical effect.
13. `EFFECT_RECEIPT_REFERENCE`: Abstract reference to an authoritative execution receipt.

---

## 7. Values

A semantic value is:
- **typed**: Every value holds an immutable reference to its canonical `SemanticType`.
- **finite**: Infinite structures are non-admissible.
- **canonicalizable**: All non-semantic representation variations collapse into a unique canonical payload.
- **bounded**: Value bit-widths and sequence lengths must strictly obey declared type bounds.

### Literal Canonicalization Rule
Syntactic variations in integer representation (decimal `18`, hexadecimal `0x12`, octal `022`, binary `0b00010010`) collapse to the identical canonical big-endian byte sequence of length $\lceil \text{width} / 8 \rceil$.

---

## 8. Operations

M4 defines an irreducible set of pure primitive operations:

```text
IDENTITY, CONSTANT, ADD, SUB, MUL, DIV,
EQUAL, LESS_THAN, AND, OR, NOT,
SELECT, CONCAT, SLICE
```

Every operation specification must define:
- `INPUT TYPES`: Fixed arity and expected operand types.
- `OUTPUT TYPE`: Exact deterministic result type.
- `PRECONDITIONS`: Formal domain boundaries (e.g. divisor $\neq 0$).
- `SEMANTIC RULE`: Pure mathematical function mapping inputs to output.
- `FAILURE CONDITIONS & OVERFLOW POLICY`: Explicitly declared behavior (`WRAP`, `SATURATE`, or `FAIL_CLOSED`). No operation inherits ambient host platform overflow semantics.

---

## 9. Relations

Relations are first-class directed semantic entities binding objects in $G_S$:

```text
EQUAL
NOT_EQUAL
LESS_THAN
CONTAINS
SUBSET_OF
DEPENDS_ON
DERIVED_FROM
SATISFIES
EQUIVALENT_TO
```

Relations are never buried in prose comments or string metadata; they are structural edges admitting deterministic traversal, cycle detection, and deductive reasoning.

---

## 10. Constraints & Invariant Envelopes

A constraint specifies an invariant property that must hold over semantic objects:

```text
EQUALITY
INEQUALITY
RANGE
TYPE
LENGTH
CONTAINMENT
PRECONDITION
POSTCONDITION
INVARIANT
```

### Example Authority Constraints
- Spatial containment: $\text{child.bounds} \subseteq \text{parent.bounds}$
- Generation invariance: $\text{child.generation} = \text{parent.generation}$
- Monotonic attenuation: $\text{derived.rights} \subseteq \text{parent.rights}$

These primitives provide the semantic vocabulary to express Milestone 3 authority laws prior to machine code generation.

---

## 11. Pure Computation vs Physical Effects

OMEGA enforces an impenetrable boundary between pure computation and physical effects:
- **Pure Semantics**: Side-effect-free mathematical relations ($7 + 11 = 18$). Can be evaluated, synthesized, or cached without physical authority.
- **Physical Effects**: Operations that alter or observe physical state (console writes, memory frame grants, hardware measurement).

An `OMEGA_EFFECT` object **does not execute the effect**. It defines the desired semantic meaning, parameters, and required authority:

```text
OMEGA_EFFECT {
    operation:           OperationId
    target_resource:     SemanticResourceId
    constraints:         Set<ConstraintId>
    expected_invariants: Set<InvariantId>
    required_authority:  CapabilityReference
}
```

The future physical bridge lowers an `OMEGA_EFFECT` into a Physics M3 `EFFECT_INTENT`, verified against kernel-private capabilities and recorded in an immutable `EFFECT_RECEIPT`.

---

## 12. Canonical Serialization & Canonical Hashing

A semantic object produces exactly one canonical byte representation:

$$\text{canonical\_bytes} = \text{CANONICAL\_ENCODE}(\text{object})$$
$$\text{SEMANTIC\_ID} = \text{SHA256}(\text{canonical\_bytes})$$

### Deterministic Encoding Grammar
1. **Magic Header**: `0x4F, 0x4D, 0x47, 0x30` (`"OMG0"`).
2. **Object Kind**: 1 byte enum tag ($0x01 = \text{TYPE}, 0x02 = \text{VALUE}, 0x03 = \text{OPERATION}, \dots$).
3. **Canonical Attributes**: Length-prefixed sequence of key-value pairs sorted lexicographically by UTF-8 key.
4. **Canonical Relations**: Length-prefixed sequence of relation tuples `(rel_type, target_semantic_id)` sorted lexicographically by relation type then target ID.
5. **Canonical Constraints**: Length-prefixed sequence of constraint descriptors sorted lexicographically.
6. **Payload**: Big-endian, strictly bounded value or descriptor bytes.

---

## 13. Graph Validation & Malformed Refusal Matrix

Before an object is admitted to $G_S$ or assigned a canonical identity, it must pass strict validation:
1. **Reference Completeness**: All referenced `SemanticId`s must resolve within the graph envelope.
2. **Kind Compatibility**: Relation sources and targets must match valid semantic categories.
3. **Type Consistency**: Operand values must match declared operation input signatures.
4. **Structural Acyclicity**: M4 expression graphs must be strictly acyclic DAGs. Structural cycles produce immediate validation refusal.
5. **Finite Bounds**: Sequence lengths $\le 65535$, integer widths $\le 256$, string/attribute keys $\le 255$ bytes.

Malformed, ambiguous, or out-of-bounds representations are rejected fail-closed.

---

## 14. Trust Boundary

Milestone 4 establishes the immutable semantic trust boundary:

```text
UNTRUSTED SEARCH (Future AIEN / Synthesizers / Optimizers)
       ↓
TRUSTED CHECKER (OMEGA Semantic Validator & Type Checker)
       ↓
VERIFIED SEMANTICS ($G_S$ with Canonical SEMANTIC_ID)
```

No synthesis engine or heuristic optimizer is ever trusted. Only representations that pass the deterministic OMEGA validator cross the trust boundary.

---

## 15. Canonical Qualification Gates

Milestone 4 requires formal verification across 12 canonical gates:

1. `OMEGA_OBJECT_MODEL_PASS`: All 11 semantic categories instantiated, populated, and structurally typed.
2. `OMEGA_TYPE_SYSTEM_PASS`: Bounded types validate width, length, and scalar bounds; illegal types rejected.
3. `OMEGA_GRAPH_VALIDATION_PASS`: Valid graphs admitted; dangling references, type mismatches, and broken edges refused.
4. `OMEGA_CANONICAL_ENCODING_PASS`: Canonical byte serialization satisfies strict deterministic layout rules.
5. `OMEGA_SEMANTIC_ID_DETERMINISM_PASS`: Repeated evaluation across distinct memory allocations yields bit-for-bit identical SHA-256 IDs.
6. `OMEGA_REPRESENTATION_INDEPENDENCE_PASS`: Independent builder orders, AST structures, and surface encodings collapse to the exact same canonical `SEMANTIC_ID`.
7. `OMEGA_SEMANTIC_DIFFERENCE_PASS`: Single-bit or operator mutations (`ADD` $\to$ `SUB`, width $8 \to 16$, bounds change) produce distinct `SEMANTIC_ID`s.
8. `OMEGA_RELATION_PASS`: Directed semantic relations evaluate correctly; relation ordering differences collapse into canonical identity.
9. `OMEGA_CONSTRAINT_PASS`: Invariant envelopes and arithmetic/spatial constraints validate and evaluate against concrete models.
10. `OMEGA_PURE_EFFECT_SEPARATION_PASS`: Pure mathematical expressions produce zero physical effect requests; effect objects demand explicit capability references.
11. `OMEGA_MALFORMED_OBJECT_REFUSAL_PASS`: Hostile/malformed corpus (truncated headers, oversized lengths, cycle violations, type violations) rejected fail-closed.
12. `OMEGA_CROSS_BUILD_DETERMINISM_PASS`: Identical test vectors produce identical digests and results across compilation flags and environments.

---

## 16. Central Demonstrations

### Demonstration 1: Pure Arithmetic Equivalence Across 4 Representations
Construct the computation:
$$\text{ADD}(a = \text{U32}(7), b = \text{U32}(11)) \implies \text{U32}(18)$$
via:
1. Builder ordering A (create operands first, then operation, then binding)
2. Builder ordering B (create operation first, insert operands in reverse order)
3. Non-canonical human-readable textual notation
4. Direct compact binary deserialization

**Proof Requirement**: All 4 representations must yield the identical canonical byte sequence and identical `SEMANTIC_ID`. Changing `ADD` to `SUB` must yield a completely distinct `SEMANTIC_ID`.

### Demonstration 2: Physics Authority Semantics
Represent the Milestone 3 authority law:
$$\text{child.bounds} \subseteq \text{parent.bounds} \quad \land \quad \text{child.rights} \subseteq \text{parent.rights}$$
as an OMEGA constraint object. Prove that two independently constructed representations of this law canonicalize to the identical semantic identity.
