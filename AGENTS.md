# AGENTS.md

How to work on AwesomeSwiftUI, for coding agents and people alike. Read it
before changing anything. [CONTRIBUTING.md](CONTRIBUTING.md) has the workflow
for pull requests and releases.

## What this is

A public catalog of SwiftUI components, animations and transitions, from very
simple to very elaborate, for iOS 18 through iOS 27. There is no package:
people and agents find a component and copy its file. Being easy to find and
easy to copy matters as much as the code itself.

## Map

| Path | What lives there | State |
|---|---|---|
| `Components/<Category>/<Name>/` | One component: `<Name>.swift`, `<Name>.meta.json`, `<Name>.gif` | Planned |
| `Showcase/` | The iOS 18 app that compiles every component and hosts the tests | Planned |
| `scripts/` | Generates the catalog, the README tables and `llms.txt` from the metadata | Planned |
| `docs/` | The GitHub Pages site, built with Astro Starlight | Planned |
| `.github/` | Issue and pull request templates | In place |

Update the State column when a planned part lands.

## Rules for every component

1. **One file to copy.** Keep the component, a `<Name>Demo` view and its
   `#Preview` in `<Name>.swift`. It may not import another component, a package
   or an asset.
2. **The copyright header comes first**, so the notice travels with the code:

   ```swift
   // SPDX-License-Identifier: MIT
   // Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors
   ```

3. **Swift 6 language mode with complete concurrency checking.**
4. **Observation.** Use `@Observable`, never `ObservableObject`,
   `@StateObject` or `@Published`.
5. **Nothing deprecated.** Warnings are errors in the Showcase app.
6. **Availability.** iOS 18 is the baseline. A component that needs a newer
   iOS marks its types with `@available` and declares the same version in its
   metadata. Add a fallback only where one is natural.
7. **Accessibility.** Honour `accessibilityReduceMotion`, scale with Dynamic
   Type and label anything that is not plain text.
8. **Keep names unique.** Every file name in `Components/` must be unique,
   because the Showcase app compiles the whole folder as one target.
9. **Internal by default.** No `public`: the code lands inside someone's app.

## Rules for tests

- Components with logic get tests. Use Swift Testing (`import Testing`), never
  XCTest.
- No comments inside test bodies. Separate the phases with blank lines.
- Use `try #require()` for casts and optionals.
- Only mark a suite `@MainActor` when the type under test is `@MainActor`.

## Verifying APIs

Do not trust memory for anything new. Check Apple's documentation or the SDK's
`.swiftinterface`, and compile against the iOS versions the component claims.

## Where code may come from

- **Original work** is always welcome.
- **Code under a compatible license** (MIT, BSD, Apache 2.0) may be adapted.
  Keep its license and copyright notice next to it, and record the source in
  the metadata.
- **Everything else stays out**: paid courses and tutorials, code with no
  license, and anything else without permission to redistribute. An idea can
  inspire a new implementation written from scratch, and should be credited,
  but do not copy or closely translate its code.

## Git

Gitflow, as described in [CONTRIBUTING.md](CONTRIBUTING.md#branches):
`feature/*` from `develop` through pull requests. Commit messages follow
Conventional Commits, in English, without AI co-author trailers.
