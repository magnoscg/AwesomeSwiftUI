// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct AnimatedBarChartTests {
    @Test func ratiosAreRelativeToTheTallest() {
        #expect(AnimatedBarChartLogic.ratio(of: 5, in: [5, 10]) == 0.5)
        #expect(AnimatedBarChartLogic.ratio(of: 10, in: [5, 10]) == 1)
    }

    @Test(arguments: [
        (0.0, [0.0, 0.0]),
        (-3.0, [-3.0, 4.0]),
        (Double.nan, [1.0]),
        (Double.infinity, [1.0]),
        (2.0, [Double]()),
    ] as [(Double, [Double])])
    func unusableValuesHaveNoHeight(value: Double, values: [Double]) {
        #expect(AnimatedBarChartLogic.ratio(of: value, in: values) == 0)
    }

    @Test func anInfiniteValueDoesNotFlattenTheOthers() {
        #expect(AnimatedBarChartLogic.ratio(of: 5, in: [5, .infinity]) == 1)
    }
}
