# Repository and Product Invariants

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active

## Repository invariants

| ID | Invariant |
|---|---|
| REPO-001 | One behavior or policy has one authoritative source of truth. |
| REPO-002 | Architecture, governance, tests, and implementation must not contradict each other. |
| REPO-003 | Required validation that cannot run is INCONCLUSIVE, never PASS. |
| REPO-004 | CI evidence correlates to the exact commit under review. |
| REPO-005 | Dependencies are intentional, documented, bounded/pinned, and justified. |
| REPO-006 | Secrets, credentials, tokens, and private keys are never committed. |
| REPO-007 | Changed behavior has proportionate tests or a documented NOT_APPLICABLE rationale. |
| REPO-008 | Governance and negative controls are not weakened merely to make work pass. |
| REPO-009 | Destructive/irreversible behavior requires explicit authorization and guardrails. |
| REPO-010 | Contract/architecture changes update governing documentation in the same change. |
| REPO-011 | Generated artifacts are reproducible or clearly identified as generated/non-authoritative. |
| REPO-012 | Public/persisted formats have explicit compatibility/version rules where breakage matters. |
| REPO-013 | Repository root and comparison base must be established before Git evidence is trusted. |

## Flick invariants

| ID | Invariant |
|---|---|
| FLK-001 | Capture becomes durable before downstream processing begins. |
| FLK-002 | Pending capture rows are the durable queue. |
| FLK-003 | Processing may repeat; local visible effects are idempotent. |
| FLK-004 | `sourceCaptureID` is provenance, not the sole uniqueness key. |
| FLK-005 | Ingress replay identity and downstream `outputIdempotencyKey` are separate domains. |
| FLK-006 | Identical content from two independent user requests is allowed. |
| FLK-007 | App/extension capture surfaces share one CaptureCoordinator contract. |
| FLK-008 | Out-of-process capture targets do not run semantic/output pipelines. |
| FLK-009 | Default EventKit write-only mode is create-only. |
| FLK-010 | Ambiguous external EventKit effects are never blindly retried. |
| FLK-011 | User capture content does not egress to app-controlled/third-party services in the MVP local processing path. |
| FLK-012 | Runtime processing order does not dictate sibling-package compile-time dependencies. |
| FLK-013 | Top-level orchestration coordinates; domain decisions and concrete persistence mechanics stay behind focused collaborators. |
