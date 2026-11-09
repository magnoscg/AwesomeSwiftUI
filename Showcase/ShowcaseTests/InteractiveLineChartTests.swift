// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct InteractiveLineChartTests {
    private let points = [0.0, 100, 200].map {
        InteractiveLineChartPoint(date: Date(timeIntervalSinceReferenceDate: $0), value: $0)
    }

    @Test(arguments: [(-50.0, 0.0), (40.0, 0.0), (60.0, 100.0), (999.0, 200.0)] as [(Double, Double)])
    func theNearestPointIsChosen(time: Double, expected: Double) {
        let nearest = InteractiveLineChartLogic.nearest(to: Date(timeIntervalSinceReferenceDate: time), in: points)

        #expect(nearest?.value == expected)
    }

    @Test func nothingIsNearInAnEmptySeries() {
        #expect(InteractiveLineChartLogic.nearest(to: .now, in: []) == nil)
    }

    @Test func theDomainPadsTheRange() {
        #expect(InteractiveLineChartLogic.domain(for: points) == -30...230)
    }

    @Test func emptyAndFlatSeriesGetAValidDomain() {
        let flat = [InteractiveLineChartPoint(date: .now, value: 5)]

        #expect(InteractiveLineChartLogic.domain(for: []) == 0...1)
        #expect(InteractiveLineChartLogic.domain(for: flat) == 4...6)
    }
}
