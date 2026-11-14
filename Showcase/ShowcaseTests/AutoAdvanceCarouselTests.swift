// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AutoAdvanceCarouselTests {
    @Test func advancesToTheNextPage() {
        #expect(AutoAdvanceCarouselMath.nextIndex(after: 1, count: 4) == 2)
    }

    @Test func wrapsFromTheLastPageToTheFirst() {
        #expect(AutoAdvanceCarouselMath.nextIndex(after: 3, count: 4) == 0)
    }

    @Test func anUnknownPositionCountsAsTheFirstPage() {
        #expect(AutoAdvanceCarouselMath.nextIndex(after: nil, count: 4) == 1)
    }

    @Test(arguments: [0, 1])
    func doesNotAdvanceWithoutSomewhereToGo(count: Int) {
        #expect(AutoAdvanceCarouselMath.nextIndex(after: 0, count: count) == nil)
    }
}
