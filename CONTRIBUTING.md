# Contributing

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active repository policy

1. Read `AGENTS.md` and the applicable documents under `docs/`.
2. Confirm the repository state in `docs/REPOSITORY_STATE.md`.
3. Create the smallest change that satisfies the requirement.
4. Add or update tests for changed behavior.
5. Update architecture/design/ADR authority in the same change when the contract changes.
6. For substantial UI work, update `DESIGN.md` and `UI-REVIEW.md`, render the
   affected surfaces, and complete the required human review.
7. Run `bash scripts/repo-enforce.sh --base origin/main`,
   `bash scripts/ui-enforce.sh --base origin/main`, governance negative controls,
   and `bash scripts/validate-packages.sh` on macOS. Regenerate manifest/checksums
   after intentional changes using `bash scripts/repo-enforce.sh --inventory-write`.
8. Open a pull request using the repository template once CI/remote governance
   are established.

Do not bypass failing governance checks. Missing required evidence is
`INCONCLUSIVE`, not PASS.

At `v0.0.0`, no app implementation or CI success is assumed.
