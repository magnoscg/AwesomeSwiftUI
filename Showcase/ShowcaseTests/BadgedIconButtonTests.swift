// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct BadgedIconButtonTests {
    @Test func zeroOrLessShowsNoBadge() {
        #expect(BadgedIconButtonBadge.text(for: 0) == nil)
        #expect(BadgedIconButtonBadge.text(for: -3) == nil)
    }

    @Test func aCountUpToTheLimitShowsItself() {
        #expect(BadgedIconButtonBadge.text(for: 1) == "1")
        #expect(BadgedIconButtonBadge.text(for: 99) == "99")
    }

    @Test func aCountPastTheLimitShowsTheLimitWithAPlus() {
        #expect(BadgedIconButtonBadge.text(for: 100) == "99+")
        #expect(BadgedIconButtonBadge.text(for: 12, limit: 9) == "9+")
    }
}
