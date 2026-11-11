// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct ProfileHeaderStretchyTests {
    private typealias Math = ProfileHeaderStretchyMath

    @Test func theCoverIsWholeAtTheTop() {
        #expect(Math.coverHeight(offset: 0, expanded: 190, collapsed: 100) == 190)
        #expect(Math.progress(offset: 0, expanded: 190, collapsed: 100) == 0)
    }

    @Test func pullingDownStretchesTheCover() {
        #expect(Math.coverHeight(offset: -60, expanded: 190, collapsed: 100) == 250)
        #expect(Math.progress(offset: -60, expanded: 190, collapsed: 100) == 0)
    }

    @Test func scrollingClosesTheCoverIntoTheBar() {
        #expect(Math.coverHeight(offset: 45, expanded: 190, collapsed: 100) == 145)
        #expect(Math.progress(offset: 45, expanded: 190, collapsed: 100) == 0.5)
        #expect(Math.coverHeight(offset: 400, expanded: 190, collapsed: 100) == 100)
        #expect(Math.progress(offset: 400, expanded: 190, collapsed: 100) == 1)
    }

    @Test func aCoverShorterThanTheBarStaysAsItIs() {
        #expect(Math.coverHeight(offset: 30, expanded: 80, collapsed: 100) == 80)
        #expect(Math.progress(offset: 30, expanded: 80, collapsed: 100) == 1)
    }

    @Test func theAvatarShrinksAndLeavesBeforeTheBar() {
        #expect(Math.avatarScale(progress: 0) == 1)
        #expect(abs(Math.avatarScale(progress: 1) - 0.55) < 0.000_001)
        #expect(Math.avatarOpacity(progress: 0.5) == 1)
        #expect(Math.avatarOpacity(progress: 0.9) < 0.000_001)
    }

    @Test func theNameShowsOnlyOverTheLastStretch() {
        #expect(Math.titleOpacity(progress: 0.8) < 0.000_001)
        #expect(abs(Math.titleOpacity(progress: 0.9) - 0.5) < 0.000_001)
        #expect(abs(Math.titleOpacity(progress: 1) - 1) < 0.000_001)
    }
}
