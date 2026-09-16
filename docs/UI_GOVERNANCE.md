# UI Governance

Version: 2.0\
Last Reviewed: 2026-09-16\
Status: Active once UI exists

## Authority

1. explicit owner/product requirement
2. repository invariants and accepted ADRs
3. Apple HIG/platform conventions
4. root `DESIGN.md`
5. established Flick components/tokens
6. `docs/UI_STANDARD.md`
7. `docs/UI_REFERENCES.md`
8. implementation preference

## Substantial UI change

A substantial change alters presentation, interaction, navigation, shared UI
primitives, tokens, accessibility, responsive behavior, state handling, motion,
or visual identity.

## Required flow

1. confirm `DESIGN.md` covers the change;
2. update it in the same diff if the contract changes;
3. implement with native controls first;
4. render the affected UI;
5. complete `UI-REVIEW.md`;
6. validate HIG/accessibility/theme/motion requirements;
7. obtain explicit human visual approval for HIGH-criticality work;
8. run UI governance once the bootstrap script exists.

At `v0.0.0`, UI review is NOT_APPLICABLE because no application UI is accepted.
