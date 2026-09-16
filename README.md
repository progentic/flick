# Flick

**Flick — your thoughts, saved.**

Flick is an iPhone-first capture app concept: text, voice, screenshots/images,
and supported system entry points become durable local captures that can later
be organized into notes, tasks, and calendar-event drafts without requiring the
user to maintain folders, tags, or a manual inbox taxonomy.

## Repository state: v0.0.0

`v0.0.0` is the conceptual pre-bootstrap state. The working tree now contains
a `v0.0.1` bootstrap candidate; it is not yet committed or tagged.

At this state:

- no application implementation is accepted as authoritative;
- no Xcode app target is claimed to exist;
- the eight-package scaffold is evaluated by fresh bootstrap checks below;
- no CI run is proof of a baseline;
- ADRs are proposals, not accepted implementation facts;
- UI documents define intent only; no UI has been approved;
- historical or partial exported source may be preserved for review, but it is
  not automatically an implementation baseline. Reviewed domain code is reused;
  old pipeline behavior is quarantined under `docs/history/`.

The first repository milestone is `v0.0.1`, which establishes the documented
governance, package scaffold, CI, and review baseline. The first functional app
milestone is `v0.1.0`.

See:

- `docs/REPOSITORY_STATE.md`
- `docs/ROADMAP.md`
- `docs/ARCHITECTURE.md`
- `DESIGN.md`
- `SECURITY.md`
- `TASK_PROMPT-v0.0.0-to-v0.0.1.md`

## Target platform contract

These are **target requirements**, not build claims for `v0.0.0`:

- iOS 26+ deployment target
- Swift 6 language mode
- Swift tools 6.3 package manifests
- SwiftUI-first native interface
- Apple HIG as the governing platform design language
- local/on-device processing for the MVP semantic path

The actual developer toolchain may be newer than these minimum language/package
requirements. The `v0.0.1` bootstrap must record and validate the toolchain used.

## Bootstrap validation

```sh
bash scripts/repo-enforce.sh --base origin/main
bash scripts/ui-enforce.sh --base origin/main
python3 -m unittest discover -s scripts/tests -v
bash scripts/validate-packages.sh
git diff --check
```

Portable governance requires Git and Python 3. Package validation requires
macOS and a compatible Swift/Xcode installation. Regenerate checkout inventory
after intentional file changes with `bash scripts/repo-enforce.sh --inventory-write`.
Current evidence and remaining external actions: `docs/verification/bootstrap-v0.0.1.md`.

## Native design objective

Flick should look, move, adapt, and behave like a first-party iOS application
while retaining a distinct Flick identity.

Mail and Notes are interaction references for content hierarchy, navigation,
toolbar behavior, accessibility, and platform fluency. They are not templates
to clone.

## License

BSD 3-Clause. Copyright holder: **Proto**.
