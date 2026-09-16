# Coding Style

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active

- Prefer clear local code over speculative abstraction.
- Name behavior in domain terms.
- Keep one authority for each rule.
- Keep functions focused enough that ownership and failure are obvious.
- Side effects live at explicit boundaries.
- Prefer platform/standard-library facilities before dependencies.
- Make invalid states difficult to represent.
- Remove dead compatibility code when safe.
- Comments explain constraints/invariants, not obvious syntax.

## Orchestration

High-level orchestration should read like coordination.

If one function performs recovery selection, classification, routing, plan
construction, collection mechanics, domain-model creation, and persistence,
split those responsibilities instead of accepting the abstraction mismatch.
