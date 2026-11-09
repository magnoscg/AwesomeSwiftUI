// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Testing
@testable import Showcase

struct WheelPickerTests {
    @Test(arguments: [(100.0, 0.0), (0.0, -1.0), (200.0, 1.0), (150.0, 0.5), (-80.0, -1.0), (500.0, 1.0)])
    func positionIsRelativeToTheCenter(midY: Double, expected: Double) {
        #expect(WheelPickerMath.position(midY: midY, height: 200) == expected)
    }

    @Test(arguments: [0.0, -40.0])
    func positionIsCenteredWithoutAHeight(height: Double) {
        #expect(WheelPickerMath.position(midY: 30, height: height) == 0)
    }

    @Test func adjustingStopsAtBothEnds() {
        #expect(WheelPickerMath.adjustedIndex(current: 0, step: -1, count: 3) == 0)
        #expect(WheelPickerMath.adjustedIndex(current: 2, step: 1, count: 3) == 2)
        #expect(WheelPickerMath.adjustedIndex(current: 1, step: 1, count: 3) == 2)
    }

    @Test func adjustingAnEmptyListDoesNothing() {
        #expect(WheelPickerMath.adjustedIndex(current: 0, step: 1, count: 0) == nil)
    }

    @Test func aSelectionOutsideTheListGoesToTheFirstValue() {
        #expect(WheelPickerMath.adjustedIndex(current: nil, step: 1, count: 4) == 0)
    }
}
