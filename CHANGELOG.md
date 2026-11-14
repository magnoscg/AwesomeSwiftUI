# Changelog

Every notable change to SwiftUI Blocks, called Awesome SwiftUI Components
until 0.11.0. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `X.Y.Z`
on `main`.

## Unreleased

### Added

- Weather Effects Background: an animated sky for seven kinds of weather,
  with a turning sun, twinkling stars, drifting clouds, rain with splashes,
  lightning, swaying snow and fog, that fades from one to the next.

### Changed

- `make check` fails when a component's social card was not made from its
  current preview, which the card now records, and `make docs` fails when a
  built component page does not share its own card.

## 0.11.1 - 2026-11-14

### Fixed

- The bar at the top of the site names the project SwiftUI Blocks.

## 0.11.0 - 2026-11-14

### Changed

- The project is now SwiftUI Blocks. The site moves to
  `https://swiftuiblocks.dev/`, with a `robots.txt` that points search
  engines to its sitemap, and the repository to `magnoscg/swiftui-blocks`.
  Links to the old repository keep working; the old address of the site,
  `magnoscg.github.io/swiftui-components`, no longer does.

## 0.10.0 - 2026-11-14

### Added

- Each component has a social card, a still of its preview that its page
  shows when it is shared, and its page describes it to search engines as
  source code with a breadcrumb to its category. `make preview` and
  `make record` write the card, `make cards` remakes it, and `make check`
  requires it.

## 0.9.1 - 2026-11-13

### Changed

- The catalog and the page of each category drop their empty outline and
  spread their grid of previews, with larger cards, across the width it
  leaves.

### Fixed

- The outline of a component's page marks Code when that section is opened
  or the page is scrolled to its end.

## 0.9.0 - 2026-11-13

### Added

- The page of a component has an outline with four parts: a description
  from its documentation comment, its demo as an example of use, an API
  reference with the parameters a caller sets, and the code. Long files
  scroll inside their block and can be reached with the keyboard.
- Rule 15 in AGENTS.md: how to write the documentation comments of a
  component, following Swift's API Design Guidelines.

### Changed

- The six components drawn with a Metal shader say to copy both files in an
  `- Important:` callout, which Xcode and the site show apart.

## 0.8.1 - 2026-11-13

### Fixed

- The two rows of previews on the landing page fill the whole width of any
  screen. Each preview that leaves one edge comes back at the other, and both
  rows play every preview, in opposite directions.

## 0.8.0 - 2026-11-13

### Added

- Each category of the catalog has a page on the site with the gallery of its
  components. Its name in the sidebar, the categories on the landing page and
  the category of a component lead to it.

### Changed

- The sidebar of the site is a rail: a line down each group with a mark at
  the open page, which slides to its new place when the page changes, and a
  highlight that follows the mouse. The arrow of a category opens and closes
  its list apart from its name.
- All components shows a section per category, and each card holds its
  preview in a frame with an arrow beside the name.
- Arrows beside the title of a page lead to the previous and next pages.
- `make check` rejects a component whose id is `index`, the page of its
  category on the site.

## 0.7.0 - 2026-11-12

### Added

- Character Count Text Editor, a multiline field with a ring and a count
  that turn orange near the limit and red past it, without cutting the text.
- Clearable Text Field, a text field with a leading symbol, a clear button
  that keeps the keyboard up and an optional error under it.
- Filter Chip Group, filter chips that show a checkmark when chosen and wrap
  onto as many rows as they need.
- Weekday Segmented Picker, round buttons that pick several days of the week
  in the order of the calendar, with a summary such as Weekdays.
- Settings Toggle Row, a row like the ones in the Settings app: a symbol on
  a colored square, a title, a subtitle and a switch.
- Icon Switch Toggle Style, a switch whose knob carries a symbol for each
  state, so on and off do not depend on color alone.
- Select All Checklist, a list of checkable rows under a select-all box that
  is mixed when only some rows are checked, with a count.
- Checkmark Box Toggle Style, a checkbox for any toggle on iOS, whose box
  fills and draws its checkmark, with a dash when it is mixed.
- Badged Icon Button, an icon button with a count on its corner that pops
  in, rolls its number and stops at 99+.
- Async Action Button, a button that runs an async action with a spinner in
  place of its label, keeps its width and ignores taps until the action
  ends.
- Button Variant Style, a button style with filled, tinted, outlined and
  plain variants that follows `.controlSize`, `.disabled` and the
  destructive role, like the system styles.

## 0.6.0 - 2026-11-12

### Changed

- The README has a logo and an animated button to the catalog, a table of
  contents, the section for coding agents before the rest, with the three
  things an agent has to check before copying a component, and sections for
  development and credits.
- The site has a new look, in neutral black and white, and a bar with the
  logo, the sections and the stars of the repository. The sidebar opens one
  category at a time and marks the components that need iOS 26 or iOS 27.
- The page of a component opens with its preview on a stage, what it needs
  as labels, and buttons to copy the code, download its files and copy a
  prompt that tells a coding agent how to add it.
- The landing page searches the catalog as you type, in English and Spanish,
  and has the prompt for coding agents in a box with a button to copy it.
- The button to the catalog in the README stands alone, without the file
  names that floated around it.
- `make check` rejects a component folder that is not one word of letters
  and numbers, and an origin whose address is not a web address. Both reach
  the pages of the site, which run code when it is built.

### Added

- Four pages on the site: the rules every component keeps, accessibility,
  contributing and this changelog.

## 0.5.3 - 2026-11-11

### Added

- Chromatic Glitch Shader, a modifier that breaks a view up like a bad
  signal: its colors come apart, bands jump sideways and scan lines cross
  it. Drawn by a Metal shader.
- Map Cluster Annotations, a map where places that are close together are
  drawn as one bubble with their count, which splits as the map zooms in.
- Profile Header Stretchy, a profile whose cover stretches when the page is
  pulled down and closes into a bar with the name as it scrolls.
- Day Schedule Timeline, the hours of a day down a column, with each event
  drawn over the time it takes, overlapping events side by side and a line
  at the current time.
- Permission Primer Screen, the screen shown before the system asks for a
  permission: what it is for, what the person gets and one button that leads
  to the system's question.
- Slot Machine Reels, reels of symbols that spin and stop one after another,
  with the result under a line across them.
- Notification Stack, notifications piled under the newest one, like a lock
  screen, that open into a column with a tap and can be swiped away.
- Typing Indicator Bubble, three dots that bounce in turn inside a message
  bubble while someone is typing.
- Pulse Ring Button takes `isPulsing`. Set it to false to leave the button
  without rings, as when what it signals has stopped.
- Glass Segmented Control follows a finger dragged along it, as the system's
  control does.
- Sparkline Stat Tile takes `higherIsBetter`. Set it to false for a figure
  that is good news when it falls, like churn, and a fall is drawn in green.
- Masked Text Field takes `isValid`, to check what a mask cannot, like a
  month over 12, before it shows its checkmark.
- Rating Stars clears the rating with a tap on the chosen star.
- Gooey Floating Menu closes with a tap outside it.
- The Showcase app has the Spanish of one demo, Onboarding Pager, in a String
  Catalog, shown when the app is launched with `-AppleLanguages "(es)"`. It
  shows what passing texts as `LocalizedStringResource` buys: the component
  is not touched, and the app that copies it translates it.

### Changed

- `make check` rejects a text that agrees with its count and has no entry
  in the String Catalog of the Showcase. Without one it loses its plural
  when the app is launched in Spanish.
- The README opens with ten components playing, says how to use one in three
  steps and gives coding agents the line to paste and the four files they
  read. The number of components on its badge is read from `catalog.json`.
- The site has a landing page: previews that drift under the title, the
  catalog in four figures counted when it builds, what every component
  keeps, the line to give a coding agent, and every category as a link to
  the catalog filtered by it. Cards in the catalog keep the shape of a phone
  before their preview loads, and the preview on the page of a component is
  framed like a screen.

### Fixed

- Small buttons are easier to hit. In 27 components a button or a row answers
  to a touch in an area of at least 44 points, the size Apple recommends:
  links of one line of text, legends, crumbs, tabs, chips, stars and icons
  inside fields, among others. Where a bigger button would have changed the
  design, only the area that answers grew.
- A count agrees with its noun: "1 photo", not "1 photos". Nine components
  wrote the plural for every number, on screen or to VoiceOver: Adaptive
  Sidebar Layout, Countdown Ring, Drawing Pad Speed Brush, Drawing Pad Undo
  Redo, Kanban Board, Pull Progress Refresh, Radial Layout, Range Slider and
  Shutter Capture Button.
- A demo you can empty offers to start over. Five left an empty screen once
  every item was gone: Context Menu Preview Card, Drop Zone Highlight, Edit
  Mode Multi Select, Swipe Action Cards and Swipe Action Row.
- In the demos of Audio Player Card and Video Player Chrome, Play at the end
  starts again. It did nothing.
- Netflix Rows Scroller and Shimmer Button dim and shrink a little while they
  are pressed. They gave no answer to a touch.
- Buttons that did nothing in a demo now do: Previous and Next in Expanding
  Mini Player, the tabs of the bar in Hide On Scroll Bar, and the rows of
  Dynamic Height Tray, which also closes from its last step.
- Dynamic Island Pill starts its content under the pill. On a device the
  sensors of the island covered the first line. Its demo hides the status
  bar while the pill is expanded, which drew over it.
- Surface 3D Chart fits in its view. In a frame taller than wide the corners
  of the plot and the axis labels were cut at the sides.
- Long Press Radial Menu keeps the title of the option under the finger on
  one line. It broke a word in two.
- Provider Sign In Button Stack keeps the button that is signing in at full
  strength, and only dims the ones that wait.
- Country Picker writes its rows in the color of text. They took the tint,
  like links.
- Inline Date Picker Disclosure fades its calendar in as the row grows. It
  slid in over the row for a moment.
- Spin Wheel Roulette spins when you tap the wheel, not only its hub.
- Toolbar Overflow Demo shows its title, large and under the bar. Five
  actions left no room for it.
- In demos: the curve of Spring Study Playground reaches the line whatever
  the spring takes to settle, the email field of Floating Label Text Field
  has the keyboard of an email, Map Route Tracker says the order was
  delivered when it arrives, the strokes of Drawing Pad Speed Brush cast no
  shadow, and the sheet of Toast Host opens at half height, so a toast does
  not cover its bar.
- Candlestick Chart is one value to adjust for VoiceOver, which reads the
  date and the four prices of a day at a time. Charts grouped the candles
  into ranges of dates, with no prices.
- Emoji Picker lights the tab of the last section when the grid reaches its
  end. A short section there never got its tab.
- Expanding Search Button and Map Search Sheet do not capitalize what you
  search for.
- In demos: Calendar Range Selector asks for a later day when the stay has no
  nights, Contribution Heatmap shuffles its data from a button and not every
  two seconds, Expanding Search Button says when nothing matches, Glass Tool
  Strip only holds tools, Inline Date Picker Disclosure keeps the return on
  or after the departure, Kanban Board shows part of its third column, the
  expiry of Masked Text Field rejects a month over 12, and the pages of Paged
  Grid Launcher tell their apps apart.
- Line Chart Draw In fills under the line only as far as it is drawn. The
  fill showed whole from the start.
- Circular Progress Ring draws nothing at zero. Its round cap left a dot.
- Animated Tab Bar keeps the tabs that are not chosen readable over a
  colorful screen.
- Full Screen Menu Overlay lines up the titles of its links, whatever the
  width of their symbols.
- Scattered Photo Board keeps a tilted photo whole inside the board. A
  corner went past the edge.
- Pricing Tier Cards shows the whole shadow of the recommended plan.
- Keyframe Timeline Showcase draws its last dots whole.
- In demos: titles and buttons that were hard to read over a color in
  Adaptive Sidebar Layout, Navigation Path Router, Scroll Edge Header and Two
  Pane Split Layout, names that did not line up in Bottom Drawer and
  Hamburger Menu Button, buttons of unequal width in Spring Study
  Playground, a title that moved in Step Progress Indicator, rows that
  changed height when Skeleton Shimmer Modifier finished loading, figures
  that jumped in Activity Rings, thumbs that overlapped in Range Slider, a
  photo cut by the edge in Multi Photo Picker Tray, icons that changed their
  rhythm in Jiggle Edit Modifier when one was removed, and the white corners
  of the drag preview in Drop Zone Highlight.

## 0.5.2 - 2026-11-11

### Changed

- A demo that plays by itself stops for good when you touch it. Fourteen kept
  moving and undid what you did: Adaptive Columns Grid, Cover Flow Carousel,
  Custom Detent Sheet, Double Tap Heart Overlay, Double Tap Zoom Image, Hide
  On Scroll Bar, Masonry Layout, Paged Grid Launcher, Scroll Progress Bar,
  Scroll Visibility Reveal, Search Scopes And Suggestions, Spinning Vinyl Art,
  Sticky Stacked Cards and Vertical Full Screen Feed.

### Fixed

- Scroll Spy Header jumps to the section of the chip you tap. It did nothing
  for a section the list had not built yet. A chip whose section is too near
  the end to reach the top stays chosen until the list moves again.
- Undo Snackbar announces its message to VoiceOver again, and the demo of
  Notched Tab Bar shows its heading. Since 0.5.0 both printed the internals of
  the localizable text instead of the text.
- Swipe Action Row keeps one row open at a time: opening another, or tapping
  one, closes it.
- Embedded Web Browser selects the whole address when you tap it, so typing
  replaces it, and its three buttons have a touch target of 44 points.
- Command Palette runs the first match when you press Return.
- Rich Text Editor formats each part of a selection on its own font, so a
  title keeps its size when the selection also covers the text under it.
- Swipe To Confirm Slider carries its symbol back with the thumb. The check
  stayed at the far end for a moment, over an empty thumb.
- Matched Hero Card stays opaque while it opens and closes, and clips its
  detail, which ran over the rows below the card.
- Interactive Pager Transition shows black behind the page that recedes, not
  bands of the app's background.
- Image Derived Gradient Background fades from one gradient to the next. It
  dipped through black on every change.
- Map Annotation Callout only moves the map when you tap a pin. The first
  tap also zoomed it.
- The demo of Search Scopes And Suggestions shows its scopes when you search
  by hand. Playing by itself left the search without them.
- Emoji Picker jumps to the section of the category you tap, and that tab
  stays chosen until the grid moves again. It had the fault Scroll Spy Header
  had.
- Wheel Picker draws its wheel around the selected row. The effect was
  centered two rows below it, so the selected value looked small and faded.
- Dropdown Select Menu opens its list under the field, with every option. It
  opened over the field, squeezed to the height of one row.
- Interactive Line Chart shows the value and the date over the rule while you
  drag. On iOS 27 the tooltip was not drawn, and before it its background was
  black.

## 0.5.1 - 2026-11-11

### Added

- The site carries the file that verifies it in Google Search Console, so its
  pages can be submitted for indexing.

## 0.5.0 - 2026-11-11

### Added

- The catalog on the site can be searched and filtered by category, by the iOS
  version your app runs on and by level. The filters stay in the address, so a
  filtered view can be shared. It also filters by an Apple API, like
  `TimelineView` or `Canvas`, and by having a Metal shader, and the search
  finds a component by the APIs it uses.
- A page of the site shared on a network or in a chat shows a card with six
  components.

### Changed

- The texts you pass to a component are becoming `LocalizedStringResource`, so
  a literal lands in your app's String Catalog. A literal keeps working as it
  is; a `String` variable is now passed as `"\(value)"`. Done in the ten
  buttons that take a title, a label or a prompt, in five controls (Animated
  Radio Button, Counter Stepper, Day Night Toggle, Ruler Scroll Picker and
  Swipe To Confirm Slider) and in six inputs (Floating Label Text Field,
  Masked Text Field, Multi Step Form, OTP Code Field, Password Strength Field
  and Validated Text Field), and in eleven components with tabs, bars and
  navigation titles: Animated Tab Bar, Collapsing Bottom Bar, Floating Dock
  Bar, Full Screen Menu Overlay, Notched Tab Bar, Prominent Tab Bar, Search
  Scopes And Suggestions, Sidebar Adaptive Tabs, Tab Navigation State
  Preserve, Toolbar Overflow Demo and Two Pane Split Layout. Also in Add To
  Cart Fly Button, Add To Cart Stepper, Download Pill Progress, Empty State
  Placeholder, Expandable Info Card, Glass Action Menu, Glass Tool Strip, Long
  Press Radial Menu, Sparkline Stat Tile, Swipe Action Row, Trial Timeline
  Paywall and Vertical Timeline. And in Blur Up Image, Coach Mark Tour, Color Reveal
  Image, Double Tap Zoom Image, Dropdown Select Menu, Gooey Floating Menu,
  Inline Date Picker Disclosure, Ken Burns Image, Keyboard Tracking Input Bar,
  Map Search Sheet, Onboarding Pager, Paged Grid Launcher, Path Trim Draw On,
  Photo Multi Select Grid, Symbol Morph Toggle, Toast Banner, Toast Host,
  Tooltip Popover, Undo Snackbar, What's New Sheet and Wheel Picker.
- Emoji Reaction Picker identifies each option by its emoji, not by its name.

### Fixed

- Text and icons drawn over a color you choose stay readable on a light one:
  they turn black on yellow or a pastel and stay white on the system's own
  colors. It reaches the 19 components that did it: the six buttons that take
  a tint, Add To Cart Stepper, Animated Badge Count, Completion Swipe Row,
  Download Pill Progress, Expandable Info Card, Gooey Floating Menu, Keyboard
  Tracking Input Bar, Liquid Fill Progress, Nested Comment Thread, Scroll To
  Top Button, Swipe Action Row, Tooltip Popover and Vertical Timeline.

## 0.4.0 - 2026-11-11

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
- Map Annotation Callout, map pins with a short label that open a callout
  above them when tapped, while the camera moves to fit it.
- Map Route Tracker, a route on a map with a marker that travels along it,
  like an order on its way.
- Voice Orb, a glowing orb for a voice assistant whose colors swirl and that
  swells with the voice while it listens or speaks.
- Tapback Reaction Bubble, a message you press and hold to react to, with the
  chosen reaction kept as a badge on its corner.
- Dynamic Height Tray, a sheet exactly as tall as its content, which grows and
  shrinks as one step of a flow gives way to the next.
- Streaming Text, text that arrives in chunks, like the answer of a language
  model, and fades each new part in.
- Progressive Blur Header, a blur that grows toward the top edge of a scroll
  view, drawn by a Metal shader, so what scrolls under a header melts away.
- Pixelate Shader Effect, a modifier that draws a view in big square blocks,
  like a spoiler, and brings it into focus as they shrink.
- Candlestick Chart, a chart of open, high, low and close prices, with a rule
  that reads the day under the finger.
- Radar Chart, an axis per quality around a center and a shape per series that
  grows out when it appears.
- Gauge Chart, a half-moon gauge with colored zones and a needle that swings
  to the value.
- Scrollable Bar Chart, a bar chart that scrolls sideways a week at a time and
  marks the average of the days in sight.
- Tick Mark Slider, for iOS 26: the system slider with a mark at the values
  that matter, which settles on the nearest one when let go.
- Rich Text Editor, for iOS 26: a text editor with a bar to make the selection
  bold, italic, underlined, struck through or highlighted.
- Embedded Web Browser, for iOS 26: a small browser inside the app, with an
  address bar, back, forward and reload.
- Swipe Action Cards, for iOS 27: a column of cards with the system's swipe
  actions, outside a `List`.
- Tabs Picker Pages, for iOS 27: a row of tabs over a page that slides in with
  them, on the new tabs picker style.

### Changed

- The project is now called Awesome SwiftUI Components, and its repository
  `swiftui-components`, so the name says what is inside. The old repository
  address redirects, and the site moves to
  `https://magnoscg.github.io/swiftui-components/`.
- Two Pane Split Layout is now built on the system's `NavigationSplitView`,
  which adds the button that hides the list, the swipe back and the keyboard.
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
