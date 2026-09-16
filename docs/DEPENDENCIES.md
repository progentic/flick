# Dependency and Supply-Chain Policy

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active

- New dependencies solve a concrete requirement not reasonably met by Apple
  frameworks, Swift, or existing code.
- Direct dependencies have an accountable reason.
- Versions are bounded/pinned with reproducible mechanisms.
- Lockfiles that participate in reproducible builds are committed.
- Unmaintained or ambiguous-license dependencies require explicit review.
- Dependency build/install scripts are executable supply-chain code.
- GitHub Actions are pinned to immutable full commit SHAs in the bootstrap CI.
- Dependency updates should be reviewable in isolation.

## v0.0.0 approved exceptions

None.

The target MVP intentionally prefers Apple platform frameworks and contains no
required cloud AI SDK.

## Bootstrap tooling

There are no third-party Swift packages. All declared package dependencies are
local edges in `.repo-policy.json`. Seven packages are compile/interface scaffolds;
only FlickDomain currently has behavioral tests.

Portable governance uses Git, Bash, and Python 3's standard library. Local
optional analysis used actionlint 1.7.12 and ShellCheck 0.11.0; CI does not require
those tools or an uninstalled SwiftLint.

The only GitHub Action is `actions/checkout`, pinned to
`d23441a48e516b6c34aea4fa41551a30e30af803`, resolved from its v6 ref through
GitHub's API on 2026-09-16. Updates go through Dependabot and review.
See [checkout upstream](https://github.com/actions/checkout/tree/d23441a48e516b6c34aea4fa41551a30e30af803).

The macOS workflow selects `/Applications/Xcode_26.6.app` on `macos-26`, listed
in the [official arm64 runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
when checked on 2026-09-16. Runner images are maintained externally, so the job
records actual versions and refuses a Swift compiler older than 6.3. Image
availability is not proof of a successful hosted run. Local bootstrap evidence
uses Xcode 27.0 / Swift 6.4 instead; no local minimum was lowered.
