// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct ScrollableBarChartTests {
    private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

    private func entries(_ values: [Double]) -> [ScrollableBarChartEntry] {
        values.enumerated().map { ScrollableBarChartEntry(date: start.addingTimeInterval(Double($0.offset) * 86_400), value: $0.element) }
    }

    @Test func theDaysInSightStartAtThePositionAndLastAWeek() {
        let all = entries(Array(repeating: 1, count: 20))

        let shown = ScrollableBarChartMath.visible(all, from: start.addingTimeInterval(3 * 86_400), days: 7)

        #expect(shown == Array(all[3..<10]))
    }

    @Test func aPositionBetweenTwoDaysLeavesTheFirstOut() {
        let all = entries(Array(repeating: 1, count: 20))

        let shown = ScrollableBarChartMath.visible(all, from: start.addingTimeInterval(3.5 * 86_400), days: 7)

        #expect(shown.first == all[4])
        #expect(shown.count == 7)
    }

    @Test func thereIsNothingInSightPastTheEnds() {
        let all = entries([1, 2, 3])

        #expect(ScrollableBarChartMath.visible(all, from: start.addingTimeInterval(40 * 86_400), days: 7).isEmpty)
        #expect(ScrollableBarChartMath.visible(all, from: start, days: 0).isEmpty)
    }

    @Test func theAverageIsTheMeanOfTheValues() {
        #expect(ScrollableBarChartMath.average(of: entries([2, 4, 9])) == 5)
    }

    @Test func nothingHasNoAverage() {
        #expect(ScrollableBarChartMath.average(of: []) == nil)
    }

    @Test func theChartStartsOnItsLastDays() {
        let all = entries(Array(repeating: 1, count: 20))

        #expect(ScrollableBarChartMath.lastStart(of: all, days: 7) == all[13].date)
        #expect(ScrollableBarChartMath.lastStart(of: all, days: 1) == all[19].date)
        #expect(ScrollableBarChartMath.lastStart(of: [], days: 7) == nil)
    }

    @Test func theAxisLeavesRoomAboveTheHighestBar() {
        #expect(abs(ScrollableBarChartMath.ceiling(of: entries([10, 100, 40])) - 112) < 0.000_001)
        #expect(ScrollableBarChartMath.ceiling(of: []) == 1)
    }
}
