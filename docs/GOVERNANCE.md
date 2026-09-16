# Repository Governance

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active repository policy

## Evidence states

Every required control resolves to one of:

- `PASS`
- `FAIL`
- `INCONCLUSIVE`
- `NOT_APPLICABLE`

Missing evidence never becomes PASS.

## Authority order

1. explicit owner/product requirement;
2. repository invariants and accepted ADRs;
3. current architecture/security/design contracts;
4. tests and validated implementation evidence;
5. implementation preference.

A `Proposed` ADR records intended direction but may still change. An `Accepted`
ADR governs implementation until superseded.

## Merge/release rules

- Required checks must correlate to the exact source revision.
- A check that cannot establish its comparison base is INCONCLUSIVE.
- Governance must not be weakened to turn a red job green.
- Platform-specific checks belong on a compatible runner.
- A portable governance job must not pretend to execute Xcode-only validation.
- Releases/tags are created only from an exact validated commit.

## v0.0.0 special rule

At `v0.0.0`, the existence of documentation does not imply the implementation
or CI exists. The `v0.0.1` task must establish the actual enforcement machinery.

## Exceptions

An exception must include:

- invariant/control;
- narrow scope;
- justification;
- owner;
- approver;
- mitigation;
- expiry/follow-up.

Open-ended exceptions are invalid.

## Bootstrap enforcement

`.repo-policy.json` is the machine-readable package graph and platform contract.
`scripts/repo-enforce.sh` runs portable Git, metadata, license, ADR status,
import/dependency-boundary, inventory/checksum, and CI structure checks. It does
not claim Swift compilation on Ubuntu. `scripts/validate-packages.sh` separately
evaluates every manifest, resolves dependencies, builds all modules, and runs
applicable tests on macOS. There are no placeholder behavior tests.

`scripts/ui-enforce.sh` reports NOT_APPLICABLE only when no app project or UI
implementation exists. On detecting UI it returns INCONCLUSIVE until the
rendered-evidence and human-review controls are implemented for that milestone.
It cannot manufacture human visual approval.

Exit codes: 0 for PASS/NOT_APPLICABLE, 1 for FAIL, 2 for INCONCLUSIVE. Missing
Python, Git, compatible Swift, or a trustworthy comparison base fails closed.

### Git evidence

Local default comparison is HEAD. An explicit `--base origin/main` compares
against its merge base with HEAD and includes staged, unstaged, deleted, and
untracked nonignored paths. Local output identifies working-tree evidence;
it is not a claim that the modified files are already committed.

CI provides the event's exact head SHA and base SHA through environment values.
The check verifies HEAD equals the requested source SHA and the checkout has
no uncommitted changes before comparing the merge base. Missing/unrelated bases and all-zero initial-push bases are
INCONCLUSIVE. The supplied remote already has a root commit, so the bootstrap
push has a real base. Checkout fetches history and does not persist credentials.

### Generated inventory

`bash scripts/repo-enforce.sh --inventory-write` explicitly regenerates root
`MANIFEST.txt` and `SHA256SUMS.txt`. The manifest lists all existing tracked and
untracked nonignored files, including itself and the checksum file. Checksums
cover those files except `SHA256SUMS.txt` itself. Deleted files and ignored
build/cache output are excluded. Normal enforcement never repairs stale evidence.

### Test and CI limits

The governance tests use disposable Git repositories to exercise real staged,
unstaged, deleted, and untracked change detection. Fixture commits never touch
the Flick branch or index. Negative controls cover missing bases, wrong source
SHAs, dependency gaps/cycles, forbidden imports, license drift, mutable action
refs, stale inventories, and UI without evidence.

CODEOWNERS routes review to `@progentic`; it does not establish a required
self-approval rule. No branch protection or external setting is modified by
bootstrap scripts. Hosted CI execution is separate evidence from local workflow
linting and remains unverified until an authorized push.
