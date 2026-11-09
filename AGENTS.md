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
| `Showcase/` | The iOS 18 app that compiles every component and hosts the tests. `Generated/ComponentRegistry.swift` comes from the metadata | In place |
| `scripts/` | Validates the components and generates the files below | In place |
| `catalog.json`, `llms.txt`, `llms-full.txt` | Generated indexes for agents and tools. Never edit them by hand | In place |
| `README.md` | Written by hand, except the table between the `catalog` markers | In place |
| `docs/` | The GitHub Pages site, built with Astro Starlight | Planned |
| `.github/` | Issue and pull request templates | In place |

Update the State column when a planned part lands.

## Commands

You need Node 24 or later and Xcode 27.2 or later. The scripts have no
dependencies.

```sh
make catalog         # rewrite the generated files after changing a component
make check           # fail if a component breaks a rule or a generated file is stale
make test            # the tests of the catalog tooling
make showcase-build  # compile the Showcase app and every component
make showcase-test   # run the Swift Testing suite in the simulator
make verify          # check, test and showcase-test
```

The Showcase commands use an iPhone 18 Pro simulator. Choose another with
`DESTINATION`, for example to run on an iOS 18 runtime:

```sh
make showcase-test DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=18.5'
```

A change is done when `make verify` passes. A component that claims an older
iOS should also pass `make showcase-test` on that runtime.

## Component metadata

Every `<Name>.meta.json` has exactly these fields, and `make check` rejects
anything else:

| Field | Value |
|---|---|
| `id` | Unique, in kebab-case: `pressable-button-style` |
| `name` | The folder and file name: `PressableButtonStyle` |
| `title` | The name people read: `Pressable Button Style` |
| `category` | The parent folder: `Buttons` |
| `summary` | One sentence, in English |
| `keywords` | `{ "en": [...], "es": [...] }`, with the words someone would search for |
| `difficulty` | `beginner`, `intermediate` or `advanced` |
| `minIOS` | `18.0`, `26.0`, `27.0`... It must match `@available` in the source |
| `apis` | The main Apple APIs it uses: `["MeshGradient", "TimelineView"]` |
| `origin` | `{ "kind": "original" }`, `{ "kind": "inspired", "credit": "...", "url": "..." }` or `{ "kind": "adapted", "url": "...", "license": "..." }` |

## Rules for every component

1. **One file to copy.** Keep the component, a `<Name>Demo` view and its
   `#Preview` in `<Name>.swift`. It may not import another component, a package
   or an asset.
2. **The copyright header comes first**, so the notice travels with the code:

   ```swift
   // SPDX-License-Identifier: MIT
   // Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors
   ```

3. **Swift 6 language mode with complete concurrency checking.** The Showcase
   does not set a default actor isolation, so a copied component also compiles
   in projects that do not.
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
