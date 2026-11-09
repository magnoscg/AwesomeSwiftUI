// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

@main
struct ShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            if let directEntry {
                directEntry.demo()
            } else {
                CatalogView(entries: ComponentRegistry.entries)
            }
        }
    }

    /// Launching with `-showcaseComponent <id>` opens one demo alone, to record its preview.
    private var directEntry: ShowcaseEntry? {
        let id = UserDefaults.standard.string(forKey: "showcaseComponent")
        return ComponentRegistry.entries.first { $0.id == id }
    }
}
