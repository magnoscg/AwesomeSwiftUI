// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct ShowcaseLocalizationTests {
    @Test func theOnboardingDemoHasItsSpanish() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))

        #expect(spanish.localizedString(forKey: "Get Started", value: nil, table: nil) == "Empezar")
        #expect(spanish.localizedString(forKey: "Welcome", value: nil, table: nil) == "Te damos la bienvenida")
    }
}
