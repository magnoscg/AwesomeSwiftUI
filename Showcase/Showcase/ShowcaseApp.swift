// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

@main
struct ShowcaseApp: App {
    init() {
        // The String Catalog has the Spanish of one demo. With it, on a device in Spanish the
        // whole app would run in Spanish, half translated: the system's own controls, and every
        // text that shares a key with that demo. So the app keeps to English, and Spanish is
        // asked for when launching it, with `-AppleLanguages "(es)"`, which wins over this.
        if UserDefaults.standard.stringArray(forKey: "AppleLanguages") != ["en"] {
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
    }

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
