// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Testing
@testable import Showcase

struct GaugeChartTests {
    private let zones = [
        GaugeChartZone(name: "Good", upTo: 50, color: .green),
        GaugeChartZone(name: "Moderate", upTo: 100, color: .yellow),
        GaugeChartZone(name: "Hazardous", upTo: 200, color: .red),
    ]

    @Test func aValueBecomesAShareOfTheDial() {
        #expect(GaugeChartMath.share(of: 0, in: 0...200) == 0)
        #expect(GaugeChartMath.share(of: 50, in: 0...200) == 0.25)
        #expect(GaugeChartMath.share(of: 200, in: 0...200) == 1)
        #expect(GaugeChartMath.share(of: 15, in: 10...20) == 0.5)
    }

    @Test func aValueOutsideTheRangeStaysOnTheDial() {
        #expect(GaugeChartMath.share(of: -30, in: 0...200) == 0)
        #expect(GaugeChartMath.share(of: 900, in: 0...200) == 1)
        #expect(GaugeChartMath.share(of: .nan, in: 0...200) == 0)
        #expect(GaugeChartMath.share(of: 5, in: 5...5) == 0)
    }

    @Test func theNeedleSweepsHalfATurn() {
        #expect(GaugeChartMath.needleAngle(share: 0) == -90)
        #expect(GaugeChartMath.needleAngle(share: 0.5) == 0)
        #expect(GaugeChartMath.needleAngle(share: 1) == 90)
        #expect(GaugeChartMath.needleAngle(share: 4) == 90)
    }

    @Test func aValueFallsInTheFirstZoneThatReachesIt() {
        #expect(GaugeChartMath.zone(for: 20, in: zones)?.name == "Good")
        #expect(GaugeChartMath.zone(for: 50, in: zones)?.name == "Good")
        #expect(GaugeChartMath.zone(for: 51, in: zones)?.name == "Moderate")
        #expect(GaugeChartMath.zone(for: 180, in: zones)?.name == "Hazardous")
    }

    @Test func aValueBeyondEveryZoneFallsInTheLast() {
        #expect(GaugeChartMath.zone(for: 999, in: zones)?.name == "Hazardous")
        #expect(GaugeChartMath.zone(for: 10, in: []) == nil)
    }

    @Test func zonesGivenOutOfOrderAreSorted() {
        #expect(GaugeChartMath.zone(for: 20, in: zones.reversed())?.name == "Good")
    }

    @Test func eachZoneStartsWhereTheOneBeforeEnds() {
        let spans = GaugeChartMath.spans(of: zones, in: 0...200)

        #expect(spans.map(\.start) == [0, 0.25, 0.5])
        #expect(spans.map(\.end) == [0.25, 0.5, 1])
    }

    @Test func aZoneWithNoLengthIsLeftOut() {
        let spans = GaugeChartMath.spans(of: zones + [GaugeChartZone(name: "Again", upTo: 100, color: .blue)], in: 0...200)

        #expect(spans.count == 3)
    }

    @Test func zonesPastTheRangeStopAtItsEnd() {
        let spans = GaugeChartMath.spans(of: zones, in: 0...100)

        #expect(spans.map(\.end) == [0.5, 1])
    }
}
