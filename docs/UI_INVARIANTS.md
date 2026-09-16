# UI Invariants

Version: 2.0\
Last Reviewed: 2026-09-16\
Status: Active once UI exists

| ID | Invariant |
|---|---|
| UI-001 | Substantial UI changes have a current `DESIGN.md`. |
| UI-002 | Substantial UI changes update `UI-REVIEW.md` in the same change. |
| UI-003 | Apple HIG/native platform behavior takes precedence over decorative preference. |
| UI-004 | Standard SwiftUI controls are preferred before custom equivalents. |
| UI-005 | Dynamic Type and VoiceOver remain functional. |
| UI-006 | Primary hit regions are at least 44×44 pt. |
| UI-007 | Status is never conveyed by color alone. |
| UI-008 | Required loading/empty/error/success states exist where applicable. |
| UI-009 | Keyboard/focus behavior is visible and non-trapping where text entry applies. |
| UI-010 | WCAG 2.2 AA contrast target is met for applicable content. |
| UI-011 | Reduced-motion preferences are respected. |
| UI-012 | Layout adapts to safe areas/available size instead of fixed device geometry. |
| UI-013 | Repeated visual values use semantic tokens. |
| UI-014 | UI never claims a capture is saved before durable persistence succeeds. |
| UI-015 | HIGH aesthetic-criticality work requires explicit human visual approval. |
| UI-016 | Rendered evidence is required for substantial UI review. |
