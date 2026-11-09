// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct ContributionHeatmapTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func wednesday() throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 15)))
    }

    @Test func theGridStartsOnTheFirstWeekdayAndEndsOnTheLastDay() throws {
        let days = ContributionHeatmapLogic.days(endingAt: try wednesday(), weeks: 2, calendar: calendar)

        #expect(days.count == 10)
        #expect(calendar.component(.weekday, from: try #require(days.first)) == calendar.firstWeekday)
        #expect(days.last == calendar.startOfDay(for: try wednesday()))
    }

    @Test(arguments: [0, -3, Int.min])
    func aBadWeekCountStillShowsOneWeek(weeks: Int) throws {
        #expect(ContributionHeatmapLogic.days(endingAt: try wednesday(), weeks: weeks, calendar: calendar).count == 3)
    }

    @Test func countsMatchByDayAndKeepTheHighest() throws {
        let morning = try wednesday()
        let later = morning.addingTimeInterval(3_600)
        let days = [calendar.startOfDay(for: morning)]

        #expect(ContributionHeatmapLogic.counts(for: days, activity: [morning: 2, later: 7], calendar: calendar) == [7])
    }

    @Test(arguments: [
        (0, 10, 0), (-1, 10, 0), (1, 10, 1), (5, 10, 2), (6, 10, 3), (10, 10, 4), (20, 10, 4), (5, 0, 0),
        (Int.max, Int.max, 4),
    ] as [(Int, Int, Int)])
    func levelsAreBucketed(count: Int, highest: Int, expected: Int) {
        #expect(ContributionHeatmapLogic.level(count: count, highest: highest, levels: 4) == expected)
    }

    @Test func theSumIgnoresNegativesAndDoesNotOverflow() {
        #expect(ContributionHeatmapLogic.sum([2, -9, 3]) == 5)
        #expect(ContributionHeatmapLogic.sum([.max, .max]) == .max)
    }
}
