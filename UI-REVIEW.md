# UI Review

Schema Version: 1.2

**Status:** NOT_APPLICABLE — v0.0.1 bootstrap candidate has no application UI

## Scope

- Base: v0.0.0
- Head: uncommitted v0.0.1 bootstrap candidate
- UI files changed: none
- `DESIGN.md` changed: baseline contract only
- Aesthetic Criticality: HIGH once application UI exists

> Reset Status to `INCONCLUSIVE` when the first application UI change begins.

## HIG Compliance Matrix

HIGH aesthetic criticality means the review covers visual quality AND
whether the screen behaves like an iOS interface.

### HIG: Layout
- [ ] Safe-area aware
- [ ] No device-specific fixed positioning
- [ ] Adapts to available size
- [ ] Content hierarchy remains clear

### HIG: Controls
- [ ] Standard SwiftUI controls preferred
- [ ] ≥44×44pt primary interaction regions
- [ ] Visible pressed/selected/disabled states
- [ ] Destructive actions clearly identified

### HIG: Typography
- [ ] System text styles
- [ ] Dynamic Type supported
- [ ] AX sizes do not truncate required content
- [ ] Text remains readable at increased contrast

### HIG: Accessibility
- [ ] VoiceOver labels, values, traits
- [ ] Logical VoiceOver traversal
- [ ] Reduced Motion respected
- [ ] Information not conveyed by color alone

### HIG: Materials
- [ ] Standard Liquid Glass behavior preserved
- [ ] No unnecessary custom glass surfaces
- [ ] Content remains visually dominant

### HIG: Navigation
- [ ] Native navigation patterns
- [ ] Predictable back/dismiss behavior
- [ ] Primary actions consistently placed

### HIG: Flick-specific
- [ ] Capture action remains immediately discoverable
- [ ] Durable/pending/processing/error states understandable
- [ ] No UI state claims persistence before durable write

## Required Checks

- [ ] `DESIGN.md` covers the change.
- [ ] Aesthetic Intent, Tension, Anti-reference, and Visual Signature were reviewed.
- [ ] Active references remain within the documented reference budget.
- [ ] The rendered UI follows one coherent visual grammar rather than mixing reference systems.
- [ ] Visual hierarchy identifies a dominant region and primary action/reading path.
- [ ] Color emphasis matches the documented palette intent and accent role.
- [ ] Existing shared primitives were reused where applicable.
- [ ] Loading / Empty / Error / Success states are handled where applicable.
- [ ] Defined responsive targets were validated.
- [ ] Keyboard path and visible focus were validated.
- [ ] WCAG 2.2 AA contrast target was validated.
- [ ] Reduced-motion behavior was validated where motion exists.
- [ ] Supported theme variants were validated.
- [ ] Performance budget was checked where applicable.
- [ ] No unintended overflow, token drift, or duplicated primitives were observed.
- [ ] Rendered visual evidence was reviewed.
- [ ] Anti-reference / generic AI-template drift was checked.

## Visual Review

- Visual Reviewer: NOT_APPLICABLE — no UI
- Human Visual Approval: NOT_APPLICABLE — no UI
<!-- LOW may use AGENT for Visual Reviewer. MEDIUM requires an identified reviewer. HIGH requires explicit Human Visual Approval identity. -->

## Evidence

NOT_APPLICABLE — CEUI contains imports only; no rendered application exists.
<!-- Link or identify screenshots, recordings, visual-regression artifacts, or local render evidence. -->

## Exception

Use only when Status is `EXCEPTION`.

- Invariant: N/A
- Scope: N/A
- Justification: N/A
- Risk: N/A
- Mitigation: N/A
- Follow-up: N/A
- Expiry: N/A
- Owner: N/A
- Approver: N/A
