// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

struct AnimatedDonutChartTests {
    private let segments = [
        AnimatedDonutChartSegment(id: "a", value: 10, color: .red),
        AnimatedDonutChartSegment(id: "empty", value: 0, color: .green),
        AnimatedDonutChartSegment(id: "b", value: 30, color: .blue),
    ]

    @Test(arguments: [(0.0, "a"), (10.0, "a"), (10.5, "b"), (40.0, "b")] as [(Double, String)])
    func anglesMapToTheirSegment(angle: Double, expected: String) {
        #expect(AnimatedDonutChartLogic.segmentID(atAngleValue: angle, in: segments) == expected)
    }

    @Test(arguments: [-1.0, 41.0, Double.nan])
    func anglesOutsideTheChartMapToNothing(angle: Double) {
        #expect(AnimatedDonutChartLogic.segmentID(atAngleValue: angle, in: segments) == nil)
    }

    @Test func sharesAreSafeWhenThereIsNothingToShare() {
        let zero = AnimatedDonutChartSegment(id: "zero", value: 0, color: .red)

        #expect(AnimatedDonutChartLogic.share(of: zero, in: [zero]) == 0)
    }

    @Test func badValuesCountAsZero() {
        let bad = [
            AnimatedDonutChartSegment(id: "nan", value: .nan, color: .red),
            AnimatedDonutChartSegment(id: "negative", value: -4, color: .red),
            AnimatedDonutChartSegment(id: "good", value: 6, color: .red),
        ]

        #expect(AnimatedDonutChartLogic.total(of: bad) == 6)
    }
}
