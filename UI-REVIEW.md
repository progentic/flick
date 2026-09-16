# UI Review — v0.1.0 candidate

Schema Version: 1.2

**Status:** PASS — explicit owner visual approval recorded 2026-09-16

The owner approved the supplied 18-image v0.1.0 candidate after the focused state
revision. This supersedes the earlier NOT APPROVED YET disposition for this exact
candidate. [Owner review](docs/verification/v0.1.0/VISUAL-APPROVAL.md).

Approved source fingerprint:
`42ddc9eafa76a54815d03b4a3849995a2dc528c8bba29b9091b9fae1e9975dae`

The current fingerprint and all 18 PNGs match the existing evidence checksums.
This records visual approval only; no commit, push, tag, or release is authorized.

## Scope

- Baseline: `f802005ad49e9b3074cbc2bc35d6212dedc2ade8`.
- Candidate: uncommitted text kernel; `.ui-evidence.json` binds this review to the
  current implementation/design fingerprint and exact screenshot hashes.
- Aesthetic Criticality: HIGH.
- Visual review performed by the agent: rendered-image inspection plus native
  accessibility audits. This is not human approval.
- Human Visual Approval: **APPROVED by the repository owner**, 2026-09-16.

## Rendered evidence

[Complete gallery](docs/verification/v0.1.0/GALLERY.md) includes empty, entry,
saving, durable pending, processing, Note, original capture, write/open/processing
failure, Light/Dark, Increase Contrast, largest Dynamic Type, and landscape.
Every image comes from the real simulator application. Timing pauses suspend
real work at its boundary; failure cases use real read-only/invalid store
configurations. No fake successful capture or mock feed is used.

Primary review images:

- [Light feed](docs/verification/v0.1.0/ui/03-note-ready.png)
- [Dark feed](docs/verification/v0.1.0/ui/10-dark-feed.png)
- [Entry and primary action](docs/verification/v0.1.0/ui/02-text-entry.png)
- [Error and retry](docs/verification/v0.1.0/ui/06-save-failure-retry.png)
- [Largest text size](docs/verification/v0.1.0/ui/14-large-type-feed.png)
- [Landscape](docs/verification/v0.1.0/ui/13-landscape.png)

## HIG matrix — exercised local scope

- [x] Safe areas and portrait/landscape layout; required content remains scrollable.
- [x] Native NavigationStack, List, TextField, buttons, swipe actions, and confirmation.
- [x] Normal-size capture action uses a safe-area inset; accessibility sizes use an inline scrolling action.
- [x] Primary action is at least 52 pt high; native hit-region audits pass.
- [x] System text styles; capture and feed tested through accessibility XXXL.
- [x] No clipped text in the exercised native audits; multi-line status/feedback wrap.
- [x] Labels, values, traits, and descriptions checked through accessibility audits.
- [x] Native hierarchy reviewed for reading order; snapshots are linked in the gallery.
- [x] State is described in words, not color alone.
- [x] Adaptive Light/Dark and Increase Contrast; actual dark pixels are asserted.
- [x] Semantic color pairs tested from the actual token values; old failing pair is a negative control.
- [x] Reduced Motion disables the only custom pressed scale; no custom looping/insertion animation exists.
- [x] Save feedback follows explicit persistence; failed saves retain the draft.
- [x] New draft text clears the prior capture's success; repeated binding writes do not erase feedback.
- [x] Native navigation opens the Note and original capture; deletion requires confirmation.
- [x] HIGH-criticality human visual approval for the fingerprint above.

## VoiceOver and keyboard review notes

The captured native hierarchy exposes the navigation heading, composer heading,
`Your note` text field with its actual value/placeholder, save feedback, feed
heading, combined Note navigation buttons (text/date/status), and the adaptive
capture button with its disabled trait where appropriate. The primary button's
observed frame is 371×53 pt on the tested iPhone 17. A save announcement is posted
only when the model receives the durable result; code does not move VoiceOver
focus into the feed after saving.

UI automation exercised text entry, keyboard dismissal, primary actions, native
back navigation, and deletion. A spoken VoiceOver session and a physical external
keyboard were not exercised. The execution environment did not expose a
Simulator.app GUI, though its CoreSimulator/XCTest backend rendered and tested
the app. These notes describe structural/automated evidence,
not an assertion that an audible or physical-device review occurred.

## Evidence limits and remaining gate

The final application run uses iPhone 17 Simulator / iOS 26.5 (23F77), built with
Xcode 27.0 / Swift 6.4. Native audits cover contrast, hit regions, descriptions,
traits, and clipping on the tested states. Separate tests exercise the largest
Dynamic Type size and landscape. Physical device/provisioning and the new
candidate's hosted CI remain unverified.

Hosted CI against the exact authorized candidate SHA remains INCONCLUSIVE. Static
inspection confirms `.github/workflows/packages.yml` calls `scripts/test-ios.sh`,
which runs the enabled FlickUITests target without test filters. Execution is
still required. If hosted CI does not execute the complete final suite, a final
12/12 aggregate run is required before release acceptance.

## Nonblocking follow-ups from the owner

- Before production, consider privacy-marking or hashing long-lived object IDs
  currently emitted as public, sanitized OSLog data.
- Later polish: remove or clarify the repeated `Note` detail section heading.
- Physical-device review: check both initial and scrolled landscape positions.

These are deferred follow-ups, not v0.1.0 visual blockers. No exception is requested.
