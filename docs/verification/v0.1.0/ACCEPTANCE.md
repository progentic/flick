# v0.1.0 — Text Flick / Running Kernel

STATUS: **ACCEPTED**\
TARGET: `2ec113ca9ea94092d2a00f38a3280938bc08d17f`\
Owner acceptance: 2026-09-17\
Annotated tag: `v0.1.0`

The owner verified both hosted workflows against this exact SHA and accepted
the milestone. The tag freezes that source revision. This record is subsequent
documentation-only bookkeeping; it does not move the tag or transfer its CI
evidence to another commit.

## Final gates

| Gate | Result | Evidence |
|---|---|---|
| Production implementation | PASS | Owner acceptance of the durable text kernel |
| Package validation | PASS | All eight packages resolve/build; 78 executed tests |
| App build | PASS | Hosted simulator app build |
| Recovery/idempotency | PASS | Real durable boundaries, original identity, exact output counts and relaunch assertions |
| Repository governance | PASS | [Exact-source governance run](https://github.com/progentic/flick/actions/runs/35281192660) |
| Full hosted UI suite | PASS, 12/12 | [Exact-source package/app/UI run](https://github.com/progentic/flick/actions/runs/35281192659); zero failures, unexpected failures, skips or expected failures |
| Dark rendering control | PASS | App-owned region RGB `(22,19,16)`, opaque and uniform |
| Light negative control | PASS | RGB `(250,250,248)`; the same Dark predicate rejects Light |
| Human visual approval | PASS | [Owner approval](VISUAL-APPROVAL.md), unchanged approved fingerprint and 18-image gallery |
| Accepted source checkout | Clean | Local HEAD and remote main matched the target before release bookkeeping |
| v0.1.0 acceptance | **PASS** | Explicit owner disposition on 2026-09-17 |

Hosted toolchain: Xcode 26.6 (17F113), Swift 6.3.3. UI runtime: iPhone 17e,
iOS 26.5 (23F77). Requirements remain Swift tools 6.3, Swift 6 mode and iOS 26.

Approved UI fingerprint, unchanged:
`42ddc9eafa76a54815d03b4a3849995a2dc528c8bba29b9091b9fae1e9975dae`.

## Preserve these three facts

1. The prior hosted candidate `51491b0fc9a49e89d0ecf8d025610976470587b6`
   [reproduced the native timestamp contrast-audit anomaly](https://github.com/progentic/flick/actions/runs/35279561733)
   despite genuine Dark rendering and independently captured foreground
   `(210,201,187)` / background `(22,19,16)` pixels measuring **11.291:1**.
2. The exact final candidate `2ec113ca9ea94092d2a00f38a3280938bc08d17f`
   subsequently passed the unchanged full 12-test hosted gate. Both runs used
   the same UI-test source SHA-256:
   `2b64b61308cf4af1bb30da55f316ad88fabb574996df7c3393e5c63b88d139bf`.
3. **No production styling change was made to obtain the pass.**
   `TextFlickView.swift`, color tokens, product behavior and approved UI evidence
   were unchanged by the synchronization/diagnostic repairs.

## Nonblocking test-infrastructure debt

The native accessibility-audit variability remains unexplained. It is not an
established timestamp-color defect and does not block this accepted milestone.
Do not change the timestamp color solely to address this historical anomaly.
The earlier local Xcode 27 / Swift 6.4 full-suite result remains **FAIL, 11/12**
as diagnostic evidence; the owner designated the exact passing hosted candidate
as the authoritative milestone gate. That local result is not relabeled PASS.

The conditional clean-simulator diagnostic was **NOT RUN** on the final hosted
candidate because the full suite passed. It remains available if the specific
contrast failure recurs. It cannot replace the required full suite or convert
its failure into success. Continue retaining screenshots, crops, appearance
acknowledgements, environment metadata and xcresults on future runs.

See [the investigation](DARK-MODE-INVESTIGATION.md) for observations and limits,
and [the synchronization record](UI-TEST-SYNCHRONIZATION.md) for invariants and
the durable-state assertions. Earlier records retain their historical results;
this record supersedes their pending/unaccepted milestone disposition.

## Release bookkeeping and boundary

- Annotated `v0.0.1` was pushed first, targeting the validated bootstrap
  `f802005ad49e9b3074cbc2bc35d6212dedc2ade8`.
- Annotated `v0.1.0` was then pushed, targeting exactly
  `2ec113ca9ea94092d2a00f38a3280938bc08d17f`.
- Both taggers and authenticated pushes used `progentic`; remote peeled tag
  targets were verified. No tag was moved or replaced.
- No GitHub Release object, binary distribution or App Store submission was
  created. ADR status remains Proposed; product acceptance does not accept ADRs.
- **v0.1.0 is frozen. The next development milestone is 0.2.0 — Voice Flick.**
  Voice implementation has not begun as part of this bookkeeping task.
