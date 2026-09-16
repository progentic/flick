# Security Policy

Version: 1.0
Last Reviewed: 2026-09-16
Status: Active

Do not report security vulnerabilities through public issues.

## Reporting

**Primary channel: GitHub Private Vulnerability Reporting.** Security reports go
directly to the maintainers through private vulnerability reports on the
repository — do not open public issues for security reports. Please include the
app version/build number, iOS version, device model, and steps to reproduce.

> Distribution gate: Private Vulnerability Reporting MUST be enabled before any public application binary or public release is distributed
> (see `docs/RELEASES.md`).

## Supported Versions

The v0.1.0 candidate is local development code, not a distributed release.
Its bundle identifier is `com.progentic.flick` and its reserved App Group is
`group.com.progentic.flick`. The app fails visibly if that container cannot be
opened; it never silently substitutes a different store. No account, network,
microphone, photo, or calendar capability is added by the text kernel.

Capture success telemetry records time-to-durable-save milliseconds. Structured
failure diagnostics record operation/category, opaque capture/output identifiers,
state/stage, attempt scope/count, duration, recovery, store mode, and bounded
error type/domain/code chains. Only authored static reason identifiers and
allowlisted error domains are included. Unknown domains are redacted. Error
descriptions, userInfo dictionaries, paths, note text, transcripts, OCR content,
prompts, and extracted fields are excluded. Attempt counts are scoped to a
request, store instance, kernel instance, or application session; they are not
durable cross-launch retry counts. Storage `state` is a best-effort actor-context
snapshot after failure and can include an in-flight transition; `expected_state`
is the operation's precondition. Neither is proof of committed disk state;
reopen/integration tests establish durability. Debug UI-test configuration is
isolated under UUID-named directories and excluded from Release builds.

At `v0.0.0` there is no supported application binary. Once pre-1.0 TestFlight distribution begins, only the latest TestFlight build is supported.
After 1.0.0, the current App Store release and the current TestFlight beta are
supported; older builds should update.

## Security Properties (by design)

- **Local-processing data-egress property.** User capture content does not
  egress to an app-controlled or third-party network service during the local
  processing path (capture → transcription/OCR → classification → filed
  objects). Apple-managed model asset provisioning may use the network:
  SpeechAnalyzer can download locale-specific ML assets, and Foundation Models
  can be unavailable while model assets are being prepared. The guarantee is
  about where *user content* goes — never to our servers or any third party —
  not a claim of zero network activity on the device.
- **Contextual permission requests.** Microphone, Photos (only where
  PhotosPicker-selected-item access is insufficient), and Calendar access are
  requested at first real use of each, never all at launch. Calendar export
  defaults to write-only EventKit access; full read/write access is an explicit
  optional capability for calendar-aware grounding (see ADR-0002) — the app
  MUST NOT silently escalate permission on first event creation.
- **On-device language model.** `LanguageModelSession` calls stay on-device per
  Apple's Foundation Models framework guarantees. This MUST be stated explicitly
  in the App Store privacy policy, alongside the asset-provisioning note above.
- **Sync (post-MVP, CloudKit):** syncs `FlickDomain` objects only. CloudKit private
  databases provide account-based protection; encrypted fields use key material
  from iCloud Keychain, and their end-to-end characteristics depend on the
  configuration, including whether Advanced Data Protection is enabled. Raw
  audio files are excluded from sync by default (opt-in only) to avoid
  transmitting raw voice recordings off-device.
  - **Future requirement (not yet implemented):** before sync ships, record an
    explicit cryptographic guarantee — which fields are end-to-end encrypted,
    under which key hierarchy, and the Advanced Data Protection dependency —
    in an ADR. No such guarantee is promised by this document today.

## Privacy Notes

- Screenshot/photo import uses PhotosPicker where possible: selected-item access
  requires no Photo Library authorization.
- Microphone/Photos/Calendar permissions are requested contextually (first real
  use), matching App Store review expectations.
