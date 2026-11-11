// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct StickyParallaxHeaderTests {
    @Test func theBackdropDriftsAtHalfSpeed() {
        #expect(StickyParallaxHeaderMath.drift(offset: 100, fullHeight: 322, height: 222) == 50)
    }

    @Test func thePinnedHeaderKeepsItsBackdropCovered() {
        #expect(StickyParallaxHeaderMath.drift(offset: 500, fullHeight: 322, height: 122) == 200)
        #expect(StickyParallaxHeaderMath.drift(offset: 2_000, fullHeight: 322, height: 122) == 200)
    }

    @Test func overscrollDoesNotMoveTheBackdrop() {
        #expect(StickyParallaxHeaderMath.drift(offset: -40, fullHeight: 322, height: 362) == 0)
    }
}
