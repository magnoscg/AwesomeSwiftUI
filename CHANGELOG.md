# Changelog

Every notable change to AwesomeSwiftUI. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `X.Y.Z`
on `main`.

## Unreleased

### Added

- A component can be drawn by a Metal shader. It then has a second file to
  copy, `<Name>.metal`, which its page on the site, `catalog.json`, `llms.txt`
  and `llms-full.txt` show next to its Swift file.
- The first three components with a shader, for 252 in all: Ripple Shader
  Effect, a wave that bends the view from the point you tap; Holographic Card,
  a foil that shifts as you tilt the card; and Dissolve Shader Transition,
  which burns a view away through noise.

### Fixed

- Components compile in projects that use the main actor as their default
  isolation, which is how Xcode sets up a new app. 26 of them did not, and 5
  more raised warnings.

### Changed

- `make verify` and CI also compile every component with the main actor as the
  default isolation.

## 0.2.1 - 2026-11-09

### Fixed

- The site deploys again. It loads the previews from the repository instead of
  bundling them, which keeps it small enough for GitHub Pages.

## 0.2.0 - 2026-11-09

### Added

- 149 components, for 249 in all, in 35 categories, including charts, pickers,
  calendars, chat, media, image viewers and on-device intelligence.

## 0.1.0 - 2026-11-09

### Added

- 100 components for iOS 18, 26 and 27, in 18 categories, each with an animated
  preview, a page on the site and keywords in English and Spanish.
- A page per category in `catalog/`, so GitHub only loads the previews you open.
- The foundation of the repository: license, contribution workflow, rules for
  components and templates for issues and pull requests.
- Catalog tooling: validates every component and generates `catalog.json`,
  `llms.txt`, `llms-full.txt` and the table in the README.
- Every component must have an animated WebP preview, shown in the README, and
  `make preview` creates one from a recording.
- CI for every pull request, and a deploy of the site to GitHub Pages from
  `main`.
- The documentation site: a page and a searchable entry for every component,
  generated from its metadata.
- The Showcase app: compiles every component on iOS 18 and later with Swift 6
  and warnings as errors, and lets you search and try them.
