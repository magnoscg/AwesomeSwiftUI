// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

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

    @Test func theTooltipStaysOverThePoint() {
        #expect(InteractiveLineChartLogic.tooltipX(at: 150, width: 80, in: 20...320) == 150)
    }

    @Test func theTooltipStopsAtBothEndsOfThePlot() {
        #expect(InteractiveLineChartLogic.tooltipX(at: 20, width: 80, in: 20...320) == 60)
        #expect(InteractiveLineChartLogic.tooltipX(at: 320, width: 80, in: 20...320) == 280)
    }

    @Test func aTooltipWiderThanThePlotIsCentered() {
        #expect(InteractiveLineChartLogic.tooltipX(at: 30, width: 400, in: 20...320) == 170)
        #expect(InteractiveLineChartLogic.tooltipX(at: 30, width: -5, in: 20...320) == 30)
    }
}
