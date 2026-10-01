# Rust versus C capability semantics (FORMAL-3 prep)

Observed on aien-dev/aienos main 2ee61b4. Read only. This note records what each implementation does. The Lean model in `AienCap/Model.lean` models the Rust code only.

| Topic | Rust `crates/aienos-aegis/src/capability.rs` | C `native/capability/aienos_capability.c` |
|---|---|---|
| Authority | `CapabilityScope::contains` (typed scope, per kind rules), checked at line 280 | Rights bitmask. `r->rights & ~auth->rights` refuses with `AIENOS_CAP_ERR_AMPLIFY` (line 253). Privileged right is never delegable (line 254). Resource must be equal (line 252) |
| Child expiry | Not an argument. Child gets parent expiry exactly (line 288) | Child lease is `clock + lease_ticks`, chosen by caller. If parent expiry is nonzero, child must be nonzero and `<= parent` or `ERR_AMPLIFY` (lines 257 to 261). If parent expiry is 0 (no expiry) any child expiry is allowed |
| Expiry boundary | Expired only when `now > valid_until` (line 354). Equal is still valid | Expired when `lease_expiry != 0 && clock >= lease_expiry` (line 97). Equal is expired |
| Depth | Per-token counter. Child depth = parent depth - 1 (line 287). Parent depth 0 refuses `DelegationDepthExceeded` (line 276) | No counter. Absolute chain cap `AIENOS_CAP_MAX_DEPTH = 8` (header line 23), enforced by `ancestor_hops(...) >= AIENOS_CAP_MAX_DEPTH` returning `ERR_CHAIN` (line 255). Delegation also needs the DELEGATE right (line 250) |
| Validity check order | revoked, ancestor revoked (lines 345 to 352), expired, signature | State based slot validity with generation and cascade revoke (`cascade_revoke`), no signature |
| Revocation | `revoke` marks the token and all `child_map` descendants (line 319); `validate_token` also walks ancestors | Revokes live descendants by cascade over slots |
| Duplicate child id | `derive_child_token` does not check `child_id`. `self.tokens.insert(child_id, ...)` at line 312 silently overwrites an existing token and `child_map` gets a second entry at line 313. The caller supplies `child_id` | Slots are allocated by the authority (first free slot, generation counter), the caller does not choose the id |
| Holder | `new_holder` is not checked against the parent holder | Authority must equal parent reference (lines 244 to 246) |

Consequence for the Lean model: the Rust "child expiry <= parent" and "child depth < parent depth" hold by construction (equality, and minus one). The C rules differ in kind. They are separate takeover items, not assumed equal. The overwrite behaviour affects identity uniqueness, not attenuation, and is not modelled (the model lets a newer token shadow an older one with the same id).
