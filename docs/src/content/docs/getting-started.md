---
title: How it works
description: Find a component, copy its file and use it in your app.
---

SwiftUI Blocks is a catalog, not a package. There is nothing to
install.

## Use a component

1. Find it in the [catalog](/catalog/) or with the search box.
2. Check its minimum iOS.
3. Copy its code into a new Swift file in your project. A component drawn by a
   Metal shader shows a second file: add it to the same target as
   `<Name>.metal`.
4. Use it. The `Demo` view and the `#Preview` at the end of the file show how,
   and you can delete them afterwards.

## Requirements

Components are written for Swift 6, with complete concurrency checking, and
compile whether or not your project uses the main actor as its default
isolation. iOS 18 is the baseline. A component that needs a newer iOS marks its types with
`@available`, so you decide how to handle older versions in your app.

## License

The catalog is under the
[MIT license](https://github.com/magnoscg/swiftui-blocks/blob/HEAD/LICENSE).
Keep the copyright header at the top of a file when you copy it. Code adapted
from other projects keeps its original license, which its header and its page
in the catalog state.
