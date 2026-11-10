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
| `Components/<Category>/<Name>/` | One component: `<Name>.swift`, `<Name>.meta.json`, `<Name>.webp`, and `<Name>.metal` when it draws with a Metal shader | In place |
| `Showcase/` | The iOS 18 app that compiles every component and hosts the tests. `Generated/ComponentRegistry.swift` comes from the metadata | In place |
| `scripts/` | Validates the components and generates the files below | In place |
| `catalog.json`, `llms.txt`, `llms-full.txt` | Generated indexes for agents and tools. Never edit them by hand | In place |
| `README.md` | Written by hand, except the index between the `catalog` markers | In place |
| `catalog/` | Generated page per category with every preview. Never edit it by hand | In place |
| `docs/` | The site, built with Astro Starlight. Its catalog pages and `public/` files are generated and not committed | In place |
| `.github/` | Issue and pull request templates, CI, the Pages deploy and Dependabot | In place |

Update the State column when a planned part lands.

## Commands

You need Node 24 or later and Xcode 27.2 or later. The scripts have no
dependencies. Xcode compiles the shaders with its Metal toolchain, which is a
separate download: `xcodebuild -downloadComponent MetalToolchain`.

```sh
make catalog                   # rewrite the generated files after changing a component
make check                     # fail if a component breaks a rule or a generated file is stale
make test                      # the tests of the catalog tooling
make record                    # record the previews of one component or all of them
make preview                   # turn a recording into a component's preview
make docs                      # build the site into docs/dist
make docs-dev                  # run the site locally
make showcase-build            # compile the Showcase app and every component
make showcase-build-mainactor  # compile them with the main actor as the default isolation
make showcase-test             # run the Swift Testing suite in the simulator
make verify                    # check, test, showcase-build-mainactor and showcase-test
```

The Showcase commands use an iPhone 18 Pro simulator. Choose another with
`DESTINATION`, for example to run on an iOS 18 runtime:

```sh
make showcase-test DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=18.5'
```

A change is done when `make verify` passes. A component that claims an older
iOS should also pass `make showcase-test` on that runtime, and a change to the
site should also pass `make docs`.

The site uses pnpm. Pin dependencies to exact versions.

## CI

Every pull request runs `make check`, `make test` and `make docs`, and the
Showcase tests and the main-actor build on iOS 26. GitHub's macOS runners stop
at Xcode 26.6, so that job removes components that need iOS 27 before
compiling. Those are verified only by `make verify` on a machine with
Xcode 27.2 or later, so run it before opening the pull request. Revisit this
when a runner offers Xcode 27. The job also downloads the Metal toolchain,
which the runners do not always have.

Pages deploys the site on every push to `main`.

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

1. **One file to copy, or two with a shader.** Keep the component, a
   `<Name>Demo` view and its `#Preview` in `<Name>.swift`. It may not import
   another component, a package or an asset. The one exception is a Metal
   shader, because SwiftUI's `ShaderLibrary` only loads compiled Metal: a
   component may have exactly one `<Name>.metal` next to its Swift file.
   - The documentation comment of its type says to copy both files.
   - Every function in `<Name>.metal` starts with the name of the component,
     like `RippleShaderEffectDistortion`. Xcode compiles every `.metal` file
     of a target into one `default.metallib`, in the Showcase and in the app
     the component is copied to, so two functions with the same name collide.

   `make check` rejects a shader that breaks this, and a Swift file that does
   not name its shader.
2. **The copyright header comes first**, so the notice travels with the code:

   ```swift
   // SPDX-License-Identifier: MIT
   // Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors
   ```

   A `.metal` file starts with the same two lines.

3. **Swift 6 language mode with complete concurrency checking.** A copied
   component has to compile in both kinds of project: one that sets no default
   actor isolation, which `make showcase-test` covers, and one that isolates to
   the main actor by default, as new Xcode projects do, which
   `make showcase-build-mainactor` covers. For the second, mark a type
   `nonisolated` when nonisolated code uses it: a `Shape`, the logic a `Layout`
   or a `visualEffect` closure calls, or a value passed to an API that requires
   `Sendable`.
4. **Observation.** Use `@Observable`, never `ObservableObject`,
   `@StateObject` or `@Published`.
5. **Nothing deprecated.** Warnings are errors in the Showcase app.
6. **Availability.** iOS 18 is the baseline. A component that needs a newer
   iOS marks its types with `@available` and declares the same version in its
   metadata. Add a fallback only where one is natural.
7. **Accessibility.** Honour `accessibilityReduceMotion`, scale with Dynamic
   Type and label anything that is not plain text.
8. **Keep names unique.** Every file name and every non-private top-level type
   in `Components/` must be unique, because the Showcase app compiles the whole
   folder as one target. Prefix supporting types with the component's name, or
   make them `private`.
9. **Internal by default.** No `public`: the code lands inside someone's app.
10. **An animated preview.** Every component has a `<Name>.webp` that shows it
    moving, used by the README and the site. `make check` rejects a missing or
    still image, and anything over 2 MB. Why WebP and not GIF: a fraction of
    the size, full color with no banding in gradients or glass, and GitHub
    renders it in Markdown, which it does not do for a committed video.

## Recording a preview

You need `ffmpeg`, `webp` and [AXe](https://github.com/cameroncooke/AXe). A new
component works like this: write its Swift file and metadata, run `make catalog`
so the Showcase knows it, then boot an iPhone 18 Pro simulator on the newest iOS
and run:

```sh
make record COMPONENT=Buttons/PressableButtonStyle
```

It opens the demo alone with `-showcaseComponent <id>`, records it and writes
the preview, resized to 320 pixels wide at 20 frames per second. A demo that
animates by itself records for 4 seconds. A demo that needs touches lists them
in `previewSteps` in its metadata, as `axe batch` steps:
`["tap --label Like", "sleep 1"]`.

When AXe cannot perform the gesture, such as holding before a drag, record by
hand, set `"previewManual": true` and convert it:

```sh
xcrun simctl io booted recordVideo recording.mov   # Ctrl-C to stop
make preview INPUT=recording.mov COMPONENT=Lists/ReorderableCardList
```

Keep it to the 2 to 5 seconds that show the effect, and do not commit the
recording.

## Rules for tests

- Components with logic get tests in `Showcase/ShowcaseTests/<Name>Tests.swift`.
  Use Swift Testing (`import Testing`), never XCTest.
- A test for a newer API marks each test function with `@available`. Swift
  Testing rejects it on the type.
- A component with a shader tests that it compiles, with
  `try await shader.compile(as: .colorEffect)` or the effect it uses. Swift
  cannot see a misspelled function or a wrong argument in a shader, and this
  fails on both.
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
