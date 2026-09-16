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
