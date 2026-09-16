# v0.1.0 rendered review

Captured from the actual simulator application and real isolated SwiftData stores.
The save/processing pauses suspend real operations at their boundaries. Read-only
stores exercise real failures. No fake saved rows or generated mockups are used.

State revision rendered 2026-09-16. **VISUAL APPROVAL — PASS**, explicitly supplied
by the repository owner for these 18 images and the recorded source fingerprint.
See [the owner review](VISUAL-APPROVAL.md). Hosted candidate CI remains unverified;
visual approval does not authorize commit, push, tag, or release.

| State | Screenshot | Accessibility hierarchy |
| --- | --- | --- |
| Empty feed | [Open](ui/01-empty-light.png) | [Inspect](ui/01-empty-light-accessibility.txt) |
| Text entry | [Open](ui/02-text-entry.png) | [Inspect](ui/02-text-entry-accessibility.txt) |
| Completed Note | [Open](ui/03-note-ready.png) | [Inspect](ui/03-note-ready-accessibility.txt) |
| Saved, waiting for processing | [Open](ui/04-durable-pending.png) | [Inspect](ui/04-durable-pending-accessibility.txt) |
| Persisted processing state | [Open](ui/05-processing.png) | [Inspect](ui/05-processing-accessibility.txt) |
| Actual read-only save failure and retry | [Open](ui/06-save-failure-retry.png) | [Inspect](ui/06-save-failure-retry-accessibility.txt) |
| Waiting for the real save | [Open](ui/07-saving.png) | [Inspect](ui/07-saving-accessibility.txt) |
| Store-open failure | [Open](ui/08-open-failure.png) | [Inspect](ui/08-open-failure-accessibility.txt) |
| Largest Dynamic Type capture | [Open](ui/09-dark-accessibility-size.png) | [Inspect](ui/09-dark-accessibility-size-accessibility.txt) |
| Dark Mode | [Open](ui/10-dark-feed.png) | [Inspect](ui/10-dark-feed-accessibility.txt) |
| Processing write failure | [Open](ui/11-processing-failure.png) | [Inspect](ui/11-processing-failure-accessibility.txt) |
| Light accessibility audit | [Open](ui/12-light-accessibility-audit.png) | [Inspect](ui/12-light-accessibility-audit-accessibility.txt) |
| Landscape feed | [Open](ui/13-landscape.png) | [Inspect](ui/13-landscape-accessibility.txt) |
| Largest Dynamic Type feed | [Open](ui/14-large-type-feed.png) | [Inspect](ui/14-large-type-feed-accessibility.txt) |
| Note and its original capture | [Open](ui/15-note-original-capture.png) | [Inspect](ui/15-note-original-capture-accessibility.txt) |
| Increase Contrast, dark | [Open](ui/high-contrast-10-dark-feed.png) | [Inspect](ui/high-contrast-10-dark-feed-accessibility.txt) |
| Increase Contrast, light | [Open](ui/high-contrast-12-light-accessibility-audit.png) | [Inspect](ui/high-contrast-12-light-accessibility-audit-accessibility.txt) |
| Brief durable Saved feedback | [Open](ui/16-saved.png) | [Inspect](ui/16-saved-accessibility.txt) |
