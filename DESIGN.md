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

### Color — implemented v0.1.0 tokens

The ember/paper/ink concept remains approved. The following adaptive sRGB values
replace the failing draft ramps. Code authority is `FlickColorTokens.swift` in
CEUI; unit tests calculate WCAG contrast from those actual values. Human visual
approval of the rendered candidate is still required.

| Token | Light | Dark | Increased contrast, light | Increased contrast, dark |
|---|---|---|---|---|
| canvas | #FAFAF8 | #161310 | #FAFAF8 | #161310 |
| ink | #161310 | #F4F1EA | #161310 | #F4F1EA |
| secondary / placeholder | #595147 | #D2C9BB | #595147 | #D2C9BB |
| action-primary (ember) | #A43212 | #FF9B78 | #912B0D | #FF9B78 |
| action-foreground | #FFFFFF | #161310 | #FFFFFF | #161310 |
| outline | #706559 | #B6AA99 | #595147 | #B6AA99 |

Standard text/background pairs exceed 4.5:1; increased-contrast text pairs
exceed 7:1. Input/action boundaries exceed 3:1. The light secondary/canvas pair
is 7.46:1; white/light ember is 6.90:1; dark ink/canvas is 16.41:1;
dark action-foreground/ember is 9.00:1. Exact computed values and native audit
results are in the current v0.1.0 verification record.

Disabled capture uses secondary text on canvas with an outline, not reduced
opacity. Saving uses a progress indicator and the active action colors.
Status is conveyed in words and, where useful, a system symbol; never color
alone. Destructive confirmation uses the native destructive role.

Palette selection follows the system color scheme and Increase Contrast trait.
The primary action uses a native Button with explicit adaptive foreground and
background pairing. Its custom style preserves contrast when disabled and
suppresses its small pressed scale when Reduce Motion is enabled.

Accent is spent on the capture action and contextual native actions. Large
surfaces remain quiet. Future voice/task/event color semantics are deferred.

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
| Empty | `Save Note`, disabled outline; neutral editor; no status copy |
| Editing | `Save Note`, ember filled action and focused editor border |
| Saving | `Saving…` and spinner; editor locked; no redundant page status |
| Saved | `Saved` and checkmark for two seconds after explicit persistence, then neutral; a new draft clears prior feedback |
| Save failed | `Try again`; error border/icon; "Couldn't save note. Your text is still here." The draft remains in memory, not durably saved |
| Saved, processing | Normal capture action; affected feed row owns spinner and "Saved · Finishing note…" |
| Processing failed | Normal capture action; affected row owns warning/tint, "Saved · Note not ready", and inline `Retry` |
| Store unavailable | Capture disabled; `Try again`; "Couldn't open notes." |
| Delete | Native destructive confirmation; failure says "Couldn't delete note." |

At accessibility Dynamic Type sizes, remove the marketing headline, use an
expanding editor, and put the single-line `Save` action inside the scrolling
composer. Do not retain the bottom action inset at those sizes. Normal sizes
retain the safe-area action. While editing, native navigation-toolbar `Done`
dismisses the keyboard without overlaying the capture action. Navigation uses native NavigationStack back behavior.

Semantic error ink is #9D2020 on light surfaces and #FFB4AB on dark surfaces;
error surface is #FFF1EF / #321B19. An icon and words accompany error color.
These presentation states do not replace persisted capture status. Processing
retry requeues only persisted failed captures; pending/interrupted work resumes
through the kernel's recovery path.

### Motion

**Allowed:** Capture-button press scale (disabled under Reduce Motion); waveform
animation during recording; item insertion transition in feed.

**Forbidden:** Decorative spring animations, looping ambient motion, parallax,
animated gradients.

**Reduced-motion behavior:** All non-essential motion disabled; state changes use
cross-fade or instant swap; waveform becomes a static level meter.

## 7. QA Contract

### Accessibility

- WCAG target: 2.2 AA (contrast, names, focus).
- Keyboard requirements: hardware-keyboard entry, submit/dismiss behavior, and visible focus are tested — 0.1.0 ships a text-entry surface. Full VoiceOver rotor/label coverage alongside.
- Focus behavior: on successful capture, prefer an accessibility announcement ("Saved") and preserve the user's capture context — Flick is a rapid-capture app and stealing focus after every capture harms consecutive captures. Move VoiceOver focus only when the interaction actually changes screens/context.

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
- Locale formatting: system formatters for dates/numbers; Schema V1 stores typed Date values, never locale-formatted strings.
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
