# Changelog

Every notable change to AwesomeSwiftUI. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `X.Y.Z`
on `main`.

## Unreleased

### Added

- Intelligence Glow Border, a soft band of color that travels around a view's
  edge and spreads inward, like an assistant that is listening.
- Karaoke Lyrics Text, lyrics that start dim and light up from the first
  letter to the last as they are sung.
- Wallet Card Stack, a stack of cards where the one you tap rises to the top
  with its details and the rest wait in a pile below.
- Circular Range Slider, a dial with two handles that sets a range around the
  clock, like a night of sleep.
- Passcode Keypad, a number pad with a dot per digit that shakes and empties
  when the passcode is wrong.
- Range Slider, a slider with two thumbs that picks a range, like the lowest
  and highest price of a filter.
- Tag Input Field, a field that turns what you type into removable tags, which
  wrap onto as many lines as they need.
- What's New Sheet, a sheet that lists what a new version brings and comes up
  once for each version.
- Trial Timeline Paywall, a paywall that shows what happens on each day of the
  free trial, with the plans and the button to start it.
- Toast Host, a queue of toasts that show above everything, sheets and
  full-screen covers included.
- Map Search Sheet, the first component with a map: a sheet of places that
  rests at the bottom, filters as you type and flies to the place you choose.

### Changed

- The nine components inspired by Kavsoft credit it by name and link to its
  channel.
- A component inspired by something else must link it, and `make check`
  rejects one that does not. Border Beam Modifier now credits Magic UI, and
  five components that named no source are listed as original: Command
  Palette, Contribution Heatmap, Floating Dock Bar, Kanban Board and Sticky
  Stacked Cards.
- A number written four or more times in a component has a name, so there is
  one place to change it. `make check` requires it, and 17 components were
  updated.

## 0.3.1 - 2026-11-10

### Fixed

- On a narrow iPhone, the preset buttons of Spring Study Playground no longer
  break their names in two, and the demo of Animated Badge Count keeps its
  third badge on screen.
- On iOS 18, Interactive Line Chart no longer cuts its last date, and the tab
  bars in the demos of Sidebar Adaptive Tabs and Tab Navigation State Preserve
  can be read over their colored pages.

### Changed

- CI also runs the Showcase tests on iOS 18, the oldest version the catalog
  supports.

## 0.3.0 - 2026-11-10

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
- In right-to-left layouts, 24 components now follow the finger instead of
  moving away from it, among them the swipe rows, the side drawer, the sliders,
  the pager, the card stack, the dock, the radial menu, the reaction picker and
  the photo board, viewers and croppers. Crops and zooms stay in the photo's
  own coordinates.
- Chevrons and arrows that mean back or forward now point the right way in
  right-to-left layouts.
- Photo Lightbox returns every page to fit when its photos change. A photo
  that moved into another's place used to inherit its zoom.

### Changed

- `make verify` and CI also compile every component with the main actor as the
  default isolation.
- The rules ask every component to work in right-to-left layouts, and say how
  to convert a gesture and how to try a demo that way.

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
