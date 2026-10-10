# AT-0 frozen interface record

This file lists every frozen AT-0 interface with the SHA-256 of its file bytes. A frozen file is never edited; a change is a new version and a new row (charter section 8). The charter and this record are living documents; the contracts are not.

Verify at any time from the aien-architecture root:

```
sha256sum docs/plans/atemporal/AT0_CASE_V1.md docs/plans/atemporal/AT0_RESULT_V1.md docs/plans/atemporal/AT0_RESULT_V2.md docs/plans/atemporal/AT1_CASE_V1.md docs/plans/atemporal/AT1_RESULT_V1.md
```

| Interface | File | SHA-256 of file bytes | Frozen |
|---|---|---|---|
| AT0_CASE_V1 | `docs/plans/atemporal/AT0_CASE_V1.md` | `d90af74bf818598d28114a73e618f5073706797d7d92d472acc2df404cd663d9` | on merge of the pull request adding this file |
| AT0_RESULT_V1 | `docs/plans/atemporal/AT0_RESULT_V1.md` | `dc52c5730dc52b155ab3c72afac9a26f8db01370804cf25fe6af23dcd0ed90a0` | aien-architecture PR 174, commit `044c9d1`; SUPERSEDED by AT0_RESULT_V2 on 2026-10-09 (trivial-kernel gap, omega issue 358); no evidence was written under it |
| AT0_RESULT_V2 | `docs/plans/atemporal/AT0_RESULT_V2.md` | `bd0f9eb8cf3ef7226c3ea18c1c9fbd4db62e0c23a0481afa519830fc1f514b5e` | aien-architecture PR 180, commit `c7a7181`; the current result contract |
| (no C header) | none | none | the two text contracts are the only shared interfaces (charter section 8); oracle, model and evaluator each carry their own parser |
| AT1_CASE_V1 | `docs/plans/atemporal/AT1_CASE_V1.md` | `e62018d8deec97fffca5cacaf6452d8fc45c395596517665cd73eb0c777a3e8f` | on merge of the pull request adding this file (AT-1, omega issue 371), after two independent reviews (Codex, Opus) of the draft; worked example `case_id 890980a4...`, `acceptance_id d63246c3...`, file `76e282fe...` |
| AT1_RESULT_V1 | `docs/plans/atemporal/AT1_RESULT_V1.md` | `3e6efd7e641a89bf0e425267525afabc51fe7a5497d3d539cdeaf09ddb6fa92d` | on merge of the pull request adding this file (AT-1), after the same two reviews; the AT-1 result contract; incorporates AT0_RESULT_V2 sections 2, 4, 5, 7 by reference |

This record serves the whole atemporal line (AT-0, AT-1, ...); its file name is historical.

Known-answer digests published inside AT0_CASE_V1 section 6 (computed with `sha256sum` over the exact byte rule of AT0_CASE_V1 section 5):

| Digest | Value |
|---|---|
| `case_id` of the example | `3cf4ca4f882b5b9691ddcd905e65e15010855adcd2be200e19ebc3184655b44d` |
| `acceptance_id` of the example | `a13fb02dd674b8042ef8c0a197f03d58768709f782ba59cd26545eef6d41a228` |
| `case_file_sha256` of the example (the 40 lines of the code block, each LF-terminated) | `ed16c95c89bf312b0fbf95a4cd43bc352daa138954fabad78d8a170cd35b4e81` |

Program status: NOT_RUN.
