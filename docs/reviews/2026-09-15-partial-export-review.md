# Historical Partial-Export Review

Authority note: this review is preserved as evidence about a September 15,
2026 local partial checkout/export. It is **not** proof that the `v0.0.0`
blank baseline or the future `v0.0.1` bootstrap builds.

The review body below is preserved verbatim.

---

# Initial repository review

Reviewed: 2026-09-15. Scope: this directory only.

## 1. Critique: Abstraction Mismatches [Evidence-Based]

- [High] `PipelineOrchestrator.process()` line 87: combines recovery selection,
  classification, routing decisions, plan construction, and persistence. The
  orchestration function contains domain decisions and storage operations.
- [High] `PipelineOrchestrator.file()` line 135: combines array allocation,
  capacity management, iteration, output-kind decisions, model construction,
  and persistence. Collection mechanics leak into orchestration.
- [Mid] `PipelineOrchestrator.filingIntents()` line 160: contains literal empty
  string fallbacks and spans more than 20 lines. Domain defaults and mapping
  branches are embedded in one function.
- [Mid/Low] `FilingPlan.init(from:)` line 104: mixes Decoder API calls with
  capture-identity and ordinal validation. Serialization mechanics and domain
  invariants share one function.

These are targeted findings, not an exhaustive function-by-function audit.

### Repository and build findings

- Only FlickDomain and CEPipelines have Package.swift manifests. CEStorage and
  CEOutput contain protocol source files but have no package manifests.
- CEPipelines/Package.swift lines 14–16 depend on CEIngestion, CESemantic, and
  CEStorage. The first two directories are absent; CEStorage is not currently
  a resolvable Swift package.
- MANIFEST.txt describes many absent files, including the app, CI workflows,
  scripts, and additional packages. It is an export inventory, not a reliable
  inventory of this checkout. Historical verification logs do not establish
  that this checkout builds.
- Both package manifests require Swift tools 6.3. The installed default Swift
  toolchain reports 6.2.4. Test attempts for both packages stopped at manifest
  validation; no tests executed.
- docs/ARCHITECTURE.md contains visible text-encoding corruption and references
  absent ADR and policy documents.
- Before initialization, Git resolved the working directory to an ancestor
  repository. A repository rooted here establishes a separate Git history,
  index, configuration, and remote list. Normal global Git settings still apply.

## 2. Refactored Code

No application refactor was performed in this review and repository-setup task.
Existing source behavior is preserved. Local ignore rules exclude macOS metadata
and SwiftPM/Xcode generated files; AGENTS.md documents the project boundary.

## 3. Hierarchy Table

| Intended layer | Function name | Responsibility | Current calls | Allowed to call |
| :--- | :--- | :--- | :--- | :--- |
| High | `process` | Coordinate processing | storage, ingestion, classification, scorer, plan construction, filing | Mid only |
| High | `file` | Coordinate output filing | model constructors, stores, array operations | Mid only |
| Mid | `filingIntents` | Map classification to intents | intent constructors | Low only |
| Low boundary with mixed domain logic | `FilingPlan.init(from:)` | Deserialize a filing plan | Decoder APIs, domain validation | Low only; separate domain decisions |

## Validation commands

```sh
swift test --package-path Packages/FlickDomain --scratch-path /tmp/flick-review-domain-build
swift test --package-path Packages/CEPipelines --scratch-path /tmp/flick-review-pipelines-build
```

Both exited with Swift tools version mismatch (required 6.3.0, installed 6.2.4).
Package dependency gaps remain independently visible in the local inventory.
