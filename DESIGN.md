# DESIGN.md

Contract Version: 1.2
Last Reviewed: 2026-09-16
Applicability: APPLICABLE
Status: Proposed for application UI

> `v0.0.0` contains no approved application UI. This contract records the target
> native iOS design language for later milestones. Aesthetic criticality is HIGH;
> the ember/paper/ink concept is approved, final token values remain unapproved,
> and no screen is visually approved until `UI-REVIEW.md` records the required
> human review.

## 0. HIG Contract (Normative)

Flick follows the current Apple Human Interface Guidelines unless an
intentional deviation is documented here with its rationale. HIG is the
governing design standard from 0.1.0 — not a 0.8.0 concern.

HIG governs the interaction grammar beneath Flick's identity:

- interaction behavior, accessibility, navigation, responsive layout,
  system materials, platform conventions.

HIG does **not** mean Flick looks like a generic Apple sample app. The
ember/paper/ink direction (values not final — see Tokens), custom feed
presentation, animation language, and distinctive capture surface are
retained.

**Native design objective:** Flick should look, move, adapt, and behave
like a first-party iOS application while retaining a distinct Flick
visual identity. Mail and Notes are reference points for interaction
density, content hierarchy, navigation, toolbar behavior, accessibility,
and platform integration — not templates to reproduce. They exemplify
the primary visual reference (iOS platform-native conventions), not
additional references.

The model is:

```text
Apple HIG
   │  interaction behavior · accessibility · navigation ·
   │  responsive layout · system materials · conventions
   ▼
DESIGN.md (this contract)
   ▼
CEUI — native SwiftUI components first (Button, TextField,
NavigationStack, toolbars, sheets, menus, system symbols);
custom equivalents only with documented justification.
Standard controls inherit Liquid Glass automatically.
   │  ├── Flick visual identity
   │  ├── Flick feed
   │  └── Flick capture surface
   ▼
UI-REVIEW.md — HIG compliance matrix; HIGH criticality reviews
both visual quality and whether the screen behaves like iOS.
```

Every UI phase carries HIG acceptance criteria from 0.1.0 onward
(Dynamic Type, VoiceOver, touch targets, safe-area behavior,
Light/Dark Mode, reduced-motion compatibility, clear state changes,
standard navigation). 0.8.0 is the comprehensive audit and polish
pass — not the first time accessibility or platform conventions are
tested. VoiceOver support is reevaluated whenever the app changes.

## 1. Product Context & Primary Job

**Product:** Flick — "Flick - your thoughts, saved."

**Primary user:** Anyone who thinks faster than they can organize — people who
capture ideas, reminders, and moments on the fly and never want to file them.

**Primary job:** Turn raw, messy input (voice memo, screenshot, text fragment)
into structured output (task, calendar event, note) instantly, with zero
organizing effort from the user.

### Aesthetic Intent

**Desired impression:** Instant, light, trustworthy. The app should feel like a
reflex, not a workspace — open, speak, done.

**Tension:** Effortless but precise. Zero friction in capture; evident care in
what comes out (clean task cards, correct dates, faithful transcripts).

**Subject cues:** The "flick" gesture itself — quick, decisive motion. Waveform
traces from voice capture. Paper-like feed surfaces; ink-like text. Light, fast,
minimal chrome.

**Anti-reference:** A productivity dashboard. No kanban boards, no sidebar
taxonomy, no settings-first onboarding, no "inbox zero" gamification, no generic
AI-chatbot gradient aesthetic.

**Visual Signature:** One giant capture button + a chronological raw feed. The
capture action is Flick's visual signature. In-app it is the dominant hero
control; system surfaces adapt that signature to the interaction and layout
constraints of WidgetKit, Live Activities, Controls, and App Intents.

**Aesthetic Criticality:** HIGH
<!-- Rationale: greenfield consumer identity; the product's core promise ("no
friction") is carried almost entirely by the feel of the capture interaction.
Approved by Ian 2026-09-10. Per UI-REVIEW.md, HIGH requires explicit human
visual approval (Ian) before substantial UI ships. This is deliberate: the
brand is the interaction. -->

### Active References

Within the budget in `docs/UI_REFERENCES.md` (1 primary + 1 pattern, 0 supplementary).

**Primary visual reference:** iOS platform-native conventions (Apple Human
Interface Guidelines) — system typography (SF), system materials, native
controls. Flick must feel like it belongs on the phone, not like a ported web app.

**Pattern reference:** UI Skills (https://ui-skills.com) — for design reasoning,
hierarchy critique, and accessibility passes on capture flows.

**Supplementary reference:** NONE

**Reference rationale:** A capture utility lives or dies on platform fluency.
Native grammar keeps cognitive load at zero; UI Skills keeps the reasoning honest
without importing anyone else's visual identity.

## 2. Interface Mode & Density

**Mode:** Native iOS app (iPhone-first, including iPhone Duo from day one;
iPad adaptive layout post-MVP).

**Density:** Focused/minimal. One job per screen. The feed is a single-column
chronological list; detail is one tap deep.

**Platform assumptions:** iOS 26+, Dynamic Type supported at all sizes,
VoiceOver-first semantics, Dark Mode + high-contrast variants from day one,
reduced-motion respected.

### Composition

**Dominant region:** The capture button — large, centered, thumb-reachable,
always visible above the feed.

**Primary action / reading path:** Tap (or widget/Action Button) → capture →
feed item appears instantly at top of chronological feed → classified output
replaces raw item in place (task card / event chip / note).

**Supporting regions:** Chronological feed below the button; Unsorted feed as a
secondary tab/section; settings kept to a single minimal screen.

**Balance strategy:** Asymmetric editorial — the capture button dominates; the
feed is quiet, uniform rows that scan fast. Whitespace separates captures; no
cards-within-cards.

## 3. Tokens

### Color

> Ember/paper/ink concept APPROVED (Ian, 2026-09-10). Hex values below are NOT
> final: the current values contradict the document's own WCAG 2.2 AA target
> and MUST be reworked before UI implementation —
> `text-muted` #A9A195 is ≈ 2.56:1 against white (needs 4.5:1 for text);
> white on `action-primary` #E4572E is ≈ 3.68:1 (needs 4.5:1 for text, 3:1 for
> large-scale/UI components — fails text use);
> white on the dark-theme ember #FF6B3D is ≈ 2.83:1 (fails even the 3:1
> non-text minimum).
> Open item: re-derive the ramp so every text/background pair meets 4.5:1
> (3:1 for large text and UI components), then record the final values here.

```text
canvas:            #FAFAF8  (warm paper white)
surface:           #FFFFFF
surface-elevated:  #F1EFEA  (feed row press / sheets)
text-primary:      #161310  (ink)
text-secondary:    #6E675C
text-muted:        #A9A195  (NOT FINAL — fails AA, see note above)
border:           #E5E1D8
action-primary:    #E4572E  (ember — capture button + primary actions only; NOT FINAL for text-on-ember use)
action-foreground: (REQUIRED TOKEN — explicit foreground color for content on
                   action-primary, e.g. the capture control glyph/label.
                   MUST pair with action-primary at 4.5:1; MUST be an adaptive
                   asset color, never an assumed constant.)
focus:            #E4572E  (matches action; always paired with visible outline, never color alone)
success:          #2E7D4F
warning:          #B7791F
danger:           #C93A2E
information:      #2F6FED
brand-accent:     #E4572E
```

**Adaptive color rule:** Foreground/background pairs MUST be adaptive asset
colors (light/dark/high-contrast variants) or system colors. NEVER assume white
(or any fixed) foreground content on a tinted background — every pairing MUST
be verified at 4.5:1 (text) or 3:1 (large text, UI components, graphical
objects) in all three themes.

**Palette intent:** Quiet paper-and-ink surfaces so the feed recedes; visual
emphasis is spent in exactly one place — the ember capture button and its
recording state. Large surfaces stay low-chroma; the accent appears only where
action happens.

**Accent role:** Capture and primary confirmation. The ember color MUST NOT be
used for decoration, illustration, or secondary chrome.

**Semantic vs decorative color rule:** Semantic colors (success/warning/danger/
information) are reserved for status and MUST NOT be repurposed decoratively.
Status is never conveyed by color alone — always paired with label/icon.

### Themes

```text
light:         tokens above (after the AA rework — current hexes are placeholders)
dark:          canvas #131110, surface #1C1915, ink #F4F1EA, ember ramp re-derived
               for the dark theme (the draft #FF6B3D fails AA, see note above)
high-contrast: system high-contrast mappings; every pair verified at 7:1 where
               enhanced contrast applies
```

### Typography

System type (SF Pro / SF Rounded for numerals where tabular). Dynamic Type
required; layout MUST NOT break at AX5.

```text
page-title:    Large Title, semibold
section-title: Title 3, semibold
body:          Body, regular
label:         Footnote, medium, text-secondary
metadata:      Caption 1, text-muted (timestamps, source badges)
data/code:     SF Mono, Caption 1 (identifiers, debug info — dev surfaces only)
```

### Spacing

```text
base unit: 4pt
allowed scale: 4 / 8 / 12 / 16 / 24 / 32 / 48
```

### Radius

```text
control: 12
panel:   20
overlay: 24
pill:    full (recording indicator, source badges)
```

## 4. Layout Shell & Navigation

**Primary shell:** Single-window SwiftUI app. Tab-less MVP: one capture screen
(button + feed); Unsorted feed as a segmented section, not a separate tab,
until volume justifies navigation.

**Responsive transitions:** Design from available size classes, safe areas, and
layout margins — NEVER from fixed display or orientation assumptions. iPhone Duo
(unveiled 2026-09-09) is a day-one target, not a post-MVP concern: its inner
display uses regular size classes and can present asymmetric safe areas and
folding regions. No "landscape → dock trailing" style orientation rules; the
capture button stays thumb-reachable within the current safe area in every
configuration. Avoid dramatic rearrangements as the device changes
configuration — layout adapts, it does not reinvent itself.

**Primary navigation:** Chronological feed IS the navigation. Tap an item →
detail (transcript, extracted fields, source capture playback). Feed titles:
single line at ordinary sizes where the title fits; wrapping when Dynamic
Type/accessibility text sizes require it. Never truncate necessary content —
truncation of primary actions/titles is forbidden.

**Context navigation:** Unsorted items surface inline with a one-tap resolver
("this is a task / event / note"). All interactive targets are minimum
44×44pt.

**Grid / alignment rhythm:** 16pt leading margin; feed rows full-bleed with
16pt internal padding; capture button centered horizontally, anchored to the
bottom safe area (not a fixed offset from the home indicator).

## 5. Component Rules

### Existing primitives

None yet (greenfield). Use SwiftUI system components by default; custom
components only where the signature demands it (capture button, waveform).

### Required rules

- The capture button is the ONLY custom hero component. Everything else uses
  system primitives styled with project tokens.
- Feed rows: single-line title at ordinary sizes (wraps when Dynamic
  Type/accessibility requires it — never truncate necessary content) +
  metadata line; no nested cards.
- Recording state: waveform + elapsed time + stop control (Dynamic Island mirrors
  this in compact form).
- Permission prompts are contextual and explain the job ("Flick needs the
  microphone to capture voice notes").

### Forbidden patterns

- Onboarding carousels, coach marks, or setup wizards.
- Compose screens or metadata forms before capture.
- Card grids, stat cards, decorative gradients, custom/decorative glassmorphism.
  (Native Liquid Glass adopted automatically by standard SwiftUI navigation and
  controls remains allowed — Apple expects standard controls to adopt it and
  recommends custom use sparingly. No hand-built glass effects.)
- Generic AI-assistant visual fingerprints (sparkle icons, purple-blue gradients).

## 6. State Semantics

| State | Visual / Behavior Contract |
|---|---|
| Loading | Feed item shows indeterminate shimmer on its derived/processing region while processing runs; capture button never blocks |
| Empty | First-run: capture button + "Tap to capture your first thought." No dead illustration |
| Error | Durable-write failure: surfaced on the capture screen itself (banner/alert with retry) — NEVER as an inline retry on a feed row, because a failed write means no persisted feed item exists. Retry re-attempts the durable write from the recoverable capture source; for the 0.1.0 text path this is the in-memory text payload. Semantic routing remains unresolved after fallback → item lands in Unsorted, never lost (a Foundation Models failure may simply fall back successfully) |
| Success | Capture: brief ember flash on the button + item appears at feed top. <300ms perceived |
| Disabled | While recording, the capture action transitions to a Stop control — it is not called disabled |
| Warning | Low RoutingScore → Unsorted badge with one-tap resolver |
| Danger | Delete capture/output: system confirmation; destructive action in `danger` token |
| Information | Source badges (voice/screenshot/text), "processed on-device" footnote in settings |

### Motion

**Allowed:** Capture-button press scale; ember flash on successful write; waveform
animation during recording; item insertion transition in feed.

**Forbidden:** Decorative spring animations, looping ambient motion, parallax,
animated gradients.

**Reduced-motion behavior:** All non-essential motion disabled; state changes use
cross-fade or instant swap; waveform becomes a static level meter.

## 7. QA Contract

### Accessibility

- WCAG target: 2.2 AA (contrast, names, focus).
- Keyboard requirements: hardware-keyboard entry, submit/dismiss behavior, and visible focus are tested — 0.1.0 ships a text-entry surface. Full VoiceOver rotor/label coverage alongside.
- Focus behavior: on successful capture, prefer an accessibility announcement ("Thought saved") and preserve the user's capture context — Flick is a rapid-capture app and stealing focus after every capture harms consecutive captures. Move VoiceOver focus only when the interaction actually changes screens/context.

### Responsive

- Required targets: iPhone portrait (all sizes incl. SE), iPhone Duo
  (outer display, inner display, folded configurations), size-class variations,
  Dynamic Type up to AX5 without truncation of primary actions or feed titles.
- iPhone Duo configurations are validated once Xcode 27.1 tooling arrives
  (Simulator support for Duo outer/inner/folded); until then, no fixed
  display/orientation assumptions are permitted in layout code, and all layout
  MUST be expressed via size classes, safe areas, and layout margins.
- iPad (post-MVP): two-column — feed master, detail inspector.

### Performance

- Interaction budget: input → durable record < 300ms; button tap → recording start < 500ms.
- Rendering budget: feed scrolls at 60fps with 1,000+ items (lazy loading, cell reuse).
- Large-data behavior: transcript/OCR text virtualized in detail view; search debounced.

### Content / i18n

- Text expansion: layouts tolerate +40% string growth.
- Locale formatting: system formatters for dates/numbers; ISO8601 only in storage.
- RTL support: validate when localization ships (post-MVP).

### Visual Review

- Required rendered targets: capture screen (light/dark), recording state,
  Unsorted feed, task card, empty state.
- Aesthetic reviewer requirement: HIGH → explicit human visual approval (Ian)
  required before substantial UI ships.

### Required Evidence

Applicable-to-change: check only the surfaces the change touches. Recording,
Unsorted, and task-card surfaces are required when those features ship — not
before.

- [ ] Primary layout
- [ ] Narrow/responsive layout
- [ ] Loading state
- [ ] Empty state
- [ ] Error state
- [ ] Focus/keyboard behavior
- [ ] Theme variants where supported
- [ ] Reduced-motion behavior where applicable
- [ ] Rendered visual evidence
- [ ] iPhone Duo configurations (outer / inner / folded) — once Xcode 27.1 tooling arrives

### Negative Controls

- [ ] No unintended overflow
- [ ] No token drift
- [ ] No unauthorized raw visual values
- [ ] No duplicated shared primitive
- [ ] No inaccessible interaction
- [ ] No missing required state
- [ ] No reference soup
- [ ] No anti-reference drift
- [ ] No generic component-demo / AI-template visual fingerprint
