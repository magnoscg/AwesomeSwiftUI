// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

@main
struct ShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            CatalogView(entries: ComponentRegistry.entries)
        }
    }
}
