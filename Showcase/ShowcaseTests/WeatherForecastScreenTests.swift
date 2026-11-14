// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct WeatherForecastScreenTests {
    private typealias Math = WeatherForecastScreenMath
    private typealias Day = WeatherForecastScreenDay

    private func day(_ low: Double, _ high: Double, offset: Int = 0) -> Day {
        Day(
            date: Date(timeIntervalSinceReferenceDate: Double(offset) * 86_400),
            condition: .clear,
            low: Measurement(value: low, unit: .celsius),
            high: Measurement(value: high, unit: .celsius)
        )
    }

    // MARK: - Span of the week

    @Test func theSpanRunsFromTheLowestLowToTheHighestHigh() throws {
        let span = try #require(Math.span(of: [day(12, 19), day(9, 24, offset: 1), day(14, 21, offset: 2)]))

        #expect(span == 9...24)
    }

    @Test func theSpanReadsTemperaturesGivenInFahrenheit() throws {
        let fahrenheit = Day(
            date: .now,
            condition: .rain,
            low: Measurement(value: 32, unit: .fahrenheit),
            high: Measurement(value: 50, unit: .fahrenheit)
        )

        let span = try #require(Math.span(of: [fahrenheit]))

        #expect(abs(span.lowerBound) < 0.001)
        #expect(abs(span.upperBound - 10) < 0.001)
    }

    @Test func noDaysHaveNoSpan() {
        #expect(Math.span(of: []) == nil)
    }

    // MARK: - Range bars

    @Test func aBarSitsWhereItsDayFallsInTheWeek() {
        #expect(Math.bar(low: 15, high: 25, in: 10...30) == 0.25...0.75)
    }

    @Test func theColdestDayStartsAtTheLeadingEdge() {
        #expect(Math.bar(low: 10, high: 20, in: 10...30).lowerBound == 0)
    }

    @Test func aFlatWeekFillsTheTrack() {
        #expect(Math.bar(low: 20, high: 20, in: 20...20) == 0...1)
    }

    @Test func aValueOutsideTheWeekStaysOnTheTrack() {
        #expect(Math.fraction(of: 40, in: 10...30) == 1)
        #expect(Math.fraction(of: -5, in: 10...30) == 0)
    }

    // MARK: - Collapsing header

    @Test func theHeaderStartsExpanded() {
        #expect(Math.collapse(offset: 0, distance: 120) == 0)
    }

    @Test func pullingDownKeepsTheHeaderExpanded() {
        #expect(Math.collapse(offset: -80, distance: 120) == 0)
    }

    @Test func theHeaderIsHalfCollapsedHalfway() {
        #expect(Math.collapse(offset: 60, distance: 120) == 0.5)
    }

    @Test func theHeaderStaysCollapsedPastTheDistance() {
        #expect(Math.collapse(offset: 400, distance: 120) == 1)
    }

    @Test func noDistanceCollapsesAtTheFirstPoint() {
        #expect(Math.collapse(offset: 0, distance: 0) == 0)
        #expect(Math.collapse(offset: 1, distance: 0) == 1)
    }
}
