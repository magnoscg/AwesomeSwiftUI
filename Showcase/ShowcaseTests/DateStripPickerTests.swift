// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct DateStripPickerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func center() throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 13)))
    }

    @Test func daysSurroundTheCenterAtMidnight() throws {
        let days = DateStripPickerLogic.days(around: try center(), before: 2, after: 3, calendar: calendar)

        #expect(days.count == 6)
        #expect(days[2] == calendar.startOfDay(for: try center()))
    }

    @Test func negativeAndHugeCountsStaySafe() throws {
        let none = DateStripPickerLogic.days(around: try center(), before: -5, after: -1, calendar: calendar)
        let huge = DateStripPickerLogic.days(around: try center(), before: .max, after: 0, calendar: calendar)

        #expect(none.count == 1)
        #expect(huge.count == DateStripPickerLogic.maximumDaysPerSide + 1)
    }

    @Test func aDateOutsideTheStripGoesToItsNearestEnd() throws {
        let days = DateStripPickerLogic.days(around: try center(), before: 1, after: 1, calendar: calendar)
        let early = try #require(calendar.date(byAdding: .day, value: -30, to: try center()))
        let late = try #require(calendar.date(byAdding: .day, value: 30, to: try center()))

        #expect(DateStripPickerLogic.closestDay(to: early, in: days, calendar: calendar) == days.first)
        #expect(DateStripPickerLogic.closestDay(to: late, in: days, calendar: calendar) == days.last)
    }

    @Test func anEmptyStripHasNoClosestDay() throws {
        #expect(DateStripPickerLogic.closestDay(to: try center(), in: [], calendar: calendar) == nil)
    }
}
