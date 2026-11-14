// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct DynamicHeightTrayTests {
    @Test func theTrayIsAsTallAsItsContent() {
        #expect(DynamicHeightTrayLogic.height(content: 320, maximum: 700) == 320)
    }

    @Test func aFractionOfAPointIsRoundedUp() {
        #expect(DynamicHeightTrayLogic.height(content: 320.2, maximum: 700) == 321)
        #expect(DynamicHeightTrayLogic.height(content: 320.999, maximum: 700) == 321)
    }

    @Test func tallContentStopsAtTheMaximum() {
        #expect(DynamicHeightTrayLogic.height(content: 1200, maximum: 700) == 700)
    }

    @Test func shortContentKeepsAMinimumHeight() {
        #expect(DynamicHeightTrayLogic.height(content: 12, maximum: 700) == 80)
        #expect(DynamicHeightTrayLogic.height(content: 0, minimum: 120, maximum: 700) == 120)
    }

    @Test func theMinimumWinsOverASmallerMaximum() {
        #expect(DynamicHeightTrayLogic.height(content: 300, minimum: 80, maximum: 40) == 80)
    }

    @Test func aMeasureThatMakesNoSenseGivesTheMinimum() {
        #expect(DynamicHeightTrayLogic.height(content: .nan, maximum: 700) == 80)
        #expect(DynamicHeightTrayLogic.height(content: .infinity, maximum: 700) == 80)
        #expect(DynamicHeightTrayLogic.height(content: 300, maximum: .infinity) == 80)
    }
}
