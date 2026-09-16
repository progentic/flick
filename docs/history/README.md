# Historical material — not an implementation authority

`partial-export/` preserves the prior CEPipelines manifest, orchestrator, and
stub tests, plus the prior CEOutput interfaces, byte-for-byte with `.txt`
suffixes. These files are not compiled or counted as current tests. The pipeline
requires semantic services not implemented in this bootstrap and combines
mapping/routing/filing behavior outside this milestone. Output grounding tools
were placeholders for a feature explicitly deferred by ADR-0001.

`documentation-pack/SHA256SUMS.txt` preserves the incoming documentation pack's
checksums. It describes that pack, not today's checkout. Root `MANIFEST.txt` and
`SHA256SUMS.txt` are generated current-checkout inventories.

The domain package is reused after current-run validation. Existing CEStorage
protocols remain interfaces only; no concrete storage exists. No historical
record serves as proof of current compilation, durability, or delivery.
