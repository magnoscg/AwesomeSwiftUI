# Changelog

Every notable change to AwesomeSwiftUI. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `X.Y.Z`
on `main`.

## Unreleased

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
