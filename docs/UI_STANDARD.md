# Flick Native UI Standard

Version: 2.0\
Last Reviewed: 2026-09-16\
Status: Proposed for application UI

Apple Human Interface Guidelines are the governing platform standard.

## Native-first rule

Prefer standard SwiftUI structures and controls before custom equivalents:

- NavigationStack / native navigation
- toolbar placements
- Button
- TextField / TextEditor where appropriate
- sheets
- menus
- lists/scroll containers
- system search behavior
- SF Symbols
- system text styles
- system materials

Custom styling may express Flick identity, but must not break native interaction
grammar.

## Reference applications

Mail and Notes are reference points for:

- content-first hierarchy;
- restrained chrome;
- navigation behavior;
- toolbar/action placement;
- list/feed scanning;
- platform accessibility;
- system-surface consistency.

Do not clone their visual assets or layouts.

## Layout

- safe-area aware;
- adapt to available size, not named device dimensions;
- no orientation-specific hard-coded placement as a primary layout rule;
- capture remains discoverable;
- content dominates decoration.

## Touch and accessibility

- primary interactive hit regions at least 44×44 pt;
- Dynamic Type at all supported sizes;
- VoiceOver labels/values/traits and logical traversal;
- preserve focus during rapid capture unless context genuinely changes;
- announce durable save rather than forcibly stealing VoiceOver focus;
- respect Reduce Motion;
- never convey state by color alone.

## Materials

Use standard system material/Liquid Glass behavior where platform controls
provide it. Do not add decorative custom glass merely to imitate platform chrome.

## Typography

Use system text styles. Required content may wrap at accessibility sizes. Do
not preserve a one-line aesthetic by truncating required information.

## Flick identity

Apple defines interaction grammar. Flick defines personality through:

- ember/paper/ink semantic color system after contrast validation;
- dominant in-app capture action;
- quiet chronological feed;
- restrained motion associated with capture;
- semantic task/event/note presentation in later milestones.
