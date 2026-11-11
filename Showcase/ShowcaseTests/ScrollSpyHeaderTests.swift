// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct ScrollSpyHeaderTests {
    @Test func theFirstVisibleSectionInOrderIsActive() {
        let active = ScrollSpyHeaderMath.activeID(order: [1, 2, 3], visible: [3, 2], isAtEnd: false, previous: 1)

        #expect(active == 2)
    }

    @Test func reachingTheEndActivatesTheLastSection() {
        let active = ScrollSpyHeaderMath.activeID(order: [1, 2, 3], visible: [2, 3], isAtEnd: true, previous: 2)

        #expect(active == 3)
    }

    @Test func nothingVisibleKeepsThePreviousSection() {
        let active = ScrollSpyHeaderMath.activeID(order: [1, 2, 3], visible: [], isAtEnd: false, previous: 2)

        #expect(active == 2)
    }

    @Test func noSectionsHaveNoActiveSection() {
        let active = ScrollSpyHeaderMath.activeID(order: [Int](), visible: [], isAtEnd: true, previous: nil)

        #expect(active == nil)
    }

    @Test func theEndIsReachedAtTheBottomOfTheContent() {
        #expect(ScrollSpyHeaderMath.isAtEnd(visibleMaxY: 2000, contentHeight: 2000, containerHeight: 800))
        #expect(!ScrollSpyHeaderMath.isAtEnd(visibleMaxY: 1500, contentHeight: 2000, containerHeight: 800))
    }

    @Test func contentThatFitsIsNeverAtTheEnd() {
        #expect(!ScrollSpyHeaderMath.isAtEnd(visibleMaxY: 800, contentHeight: 500, containerHeight: 800))
    }
}
