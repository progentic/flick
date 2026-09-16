# FlickDomain — first implementation slice

Status: domain code retained for the bootstrap, subject to fresh validation.
See the current bootstrap evidence in `docs/verification/bootstrap-v0.0.1.md`
at the repository root. The September 15 record is historical, not proof of
the current checkout.

## Scope

One Foundation-only Swift library and its unit tests. The existing domain
implementation is retained where it satisfies the agreed contracts; this is not
a reconstruction of the historical package layout. Other files under `Packages/`
are now normalized bootstrap scaffolds, not dependencies of FlickDomain.
Historical architecture documents and review reports are not a defect baseline
or verification evidence for this slice.

### Contracts

- A capture retains its identity, raw content reference, optional ingress request
  identity, and ordered output references through Codable serialization.
- Constructing a filing plan binds every materialized payload to the supplied
  capture ID and assigns zero-based ordinals in input order.
- Decoding a plan rejects entries with a foreign capture ID, duplicate, gapped,
  or reordered ordinals. Negative ordinals and malformed payload shapes fail
  decoding. Construction guarantees the same structural invariants by assigning
  capture IDs and ordinals rather than accepting them independently.
- Task, event-draft, and note constructors accept only entries of the matching
  intent kind. Capture identity, payload, and ordinal come from that entry.
- Output keys use `UPPERCASE-UUID/kind/ordinal`. Identical components yield the
  same key regardless of generated output ID. Distinct capture IDs, kinds, or
  ordinals distinguish keys. Parsing and decoding reject noncanonical keys.
- Output models derive their key from immutable provenance and ordinal fields;
  the key is not an independently serialized field that can disagree with them.
- Domain sources import Foundation only. There are no package dependencies.

This slice validates structural consistency, not authenticity: it cannot detect
a coherently replaced capture/payload in externally edited data without an
authoritative external record. Empty plans and editable output payloads remain
representable. No additional rules for titles, scheduling, or automatic filing
eligibility are introduced by this slice.

## Requirements

| Setting | Required |
| --- | --- |
| Swift tools | 6.3 or compatible newer toolchain |
| Swift language mode | 6 |
| Declared iOS deployment target | 26 |
| External or local package dependencies | None |

The package build and host unit tests passed with Xcode 27.0 (27A266a), Apple
Swift 6.4. This is package-specific evidence, not validation of an iOS app or
all toolchain features. Do not lower the manifest version or deployment target
to make an older environment pass.

## Acceptance gates

From the repository root:

```sh
swift --version
xcodebuild -version
swift build --package-path Packages/FlickDomain
swift test --package-path Packages/FlickDomain
```

Acceptance requires both compilation and executed, passing tests using a
compatible toolchain. The tests cover capture–payload–ordinal binding, exact key
format and determinism, populated Codable round trips, wrong-kind construction,
inconsistent plan entries, malformed identity fields, and noncanonical keys.
Host unit tests establish domain behavior only; they do not establish an iOS app
build, storage durability, transaction semantics, or external delivery.

## Deferred

SwiftData persistence and uniqueness enforcement, durable plan storage, queue
orchestration and crash recovery, ingestion, classification, UI, and EventKit
delivery are outside this slice. There are no persistence adapters or delivery
test doubles in this package. Existing supporting data types remain preserved;
their presence does not implement any of those services.

Next bounded step: complete repository bootstrap gates before beginning the
0.1.0 application kernel. [VERIFICATION.md](VERIFICATION.md) retains historical
domain-only results; current bootstrap evidence lives under `docs/verification/`.
