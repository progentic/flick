# Releases

Version: 1.1\
Last Reviewed: 2026-09-16\
Status: Active version policy

## Version scheme

Flick uses numeric `MAJOR.MINOR.PATCH` product versions and a monotonically
increasing integer build number.

Tag format: `vMAJOR.MINOR.PATCH`.

## Repository baseline

`0.0.0` is the blank/unproven repository state. It does not need to be
distributed as an application release.

`0.0.1` is the first repository bootstrap baseline. It may be tagged once the
bootstrap exit gates pass.

## Development milestones

- `0.1.0`: durable text kernel
- `0.2.0`: voice
- `0.3.0`: image/share
- `0.4.0`: semantic intelligence
- `0.5.0`: structured outputs
- `0.6.0`: system surfaces
- `0.7.0`: retrieval/organization
- `0.8.0`: hardening
- `0.9.0`: release candidate
- `1.0.0`: first production App Store release

## Release integrity

A tag/release must identify the exact commit that passed required validation.

Do not tag a tree merely because documentation was copied or because historical
logs report success.

## Pre-1.0 compatibility

Breaking internal changes are allowed when required, but persisted data,
external contracts, and migration behavior must be explicit when they exist.
