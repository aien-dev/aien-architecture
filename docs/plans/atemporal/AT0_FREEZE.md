# AT-0 frozen interface record

This file lists every frozen AT-0 interface with the SHA-256 of its file bytes. A frozen file is never edited; a change is a new version and a new row (charter section 8). The charter and this record are living documents; the contracts are not.

Verify at any time from the aien-architecture root:

```
sha256sum docs/plans/atemporal/AT0_CASE_V1.md docs/plans/atemporal/AT0_RESULT_V1.md docs/plans/atemporal/AT0_RESULT_V2.md
```

| Interface | File | SHA-256 of file bytes | Frozen |
|---|---|---|---|
| AT0_CASE_V1 | `docs/plans/atemporal/AT0_CASE_V1.md` | `d90af74bf818598d28114a73e618f5073706797d7d92d472acc2df404cd663d9` | on merge of the pull request adding this file |
| AT0_RESULT_V1 | `docs/plans/atemporal/AT0_RESULT_V1.md` | `dc52c5730dc52b155ab3c72afac9a26f8db01370804cf25fe6af23dcd0ed90a0` | on merge of the pull request adding this file |
| (no C header) | none | none | the two text contracts are the only shared interfaces (charter section 8); oracle, model and evaluator each carry their own parser |

Known-answer digests published inside AT0_CASE_V1 section 6 (computed with `sha256sum` over the exact byte rule of AT0_CASE_V1 section 5):

| Digest | Value |
|---|---|
| `case_id` of the example | `3cf4ca4f882b5b9691ddcd905e65e15010855adcd2be200e19ebc3184655b44d` |
| `acceptance_id` of the example | `a13fb02dd674b8042ef8c0a197f03d58768709f782ba59cd26545eef6d41a228` |
| `case_file_sha256` of the example (the 40 lines of the code block, each LF-terminated) | `ed16c95c89bf312b0fbf95a4cd43bc352daa138954fabad78d8a170cd35b4e81` |

Program status: NOT_RUN.
