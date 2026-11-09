// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct CoverFlowCarouselTests {
    @Test(arguments: [(200.0, 0.0), (100.0, -0.5), (400.0, 1.0), (900.0, 1.0), (-900.0, -1.0)])
    func positionIsRelativeToTheCenter(midX: Double, expected: Double) {
        #expect(CoverFlowCarouselMath.position(midX: midX, width: 400) == expected)
    }

    @Test(arguments: [0.0, -20.0])
    func anEmptyContainerIsCentered(width: Double) {
        #expect(CoverFlowCarouselMath.position(midX: 50, width: width) == 0)
    }
}
