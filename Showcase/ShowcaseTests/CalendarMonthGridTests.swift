// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct CalendarMonthGridTests {
    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func leapFebruary(in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: 15)))
    }

    @Test(arguments: [(1, 4), (2, 3)] as [(Int, Int)])
    func theFirstDayLandsOnItsWeekday(firstWeekday: Int, leadingBlanks: Int) throws {
        let calendar = calendar(firstWeekday: firstWeekday)

        let cells = CalendarMonthGridMath.days(inMonthContaining: try leapFebruary(in: calendar), calendar: calendar)

        #expect(cells.prefix(leadingBlanks).allSatisfy { $0 == nil })
        #expect(calendar.component(.day, from: try #require(cells[leadingBlanks])) == 1)
    }

    @Test func aLeapFebruaryHas29DaysInSixWeeks() throws {
        let calendar = calendar(firstWeekday: 1)

        let cells = CalendarMonthGridMath.days(inMonthContaining: try leapFebruary(in: calendar), calendar: calendar)

        #expect(cells.count == CalendarMonthGridMath.cellCount)
        #expect(cells.compactMap(\.self).count == 29)
    }

    @Test func aLongMonthStartingLateStillFits() throws {
        let calendar = calendar(firstWeekday: 1)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))

        let cells = CalendarMonthGridMath.days(inMonthContaining: date, calendar: calendar)

        #expect(cells.count == CalendarMonthGridMath.cellCount)
        #expect(cells.compactMap(\.self).count == 31)
    }

    @Test func weekdaysStartOnTheFirstWeekday() {
        let symbols = CalendarMonthGridMath.weekdaySymbols(calendar: calendar(firstWeekday: 2))

        #expect(symbols == ["M", "T", "W", "T", "F", "S", "S"])
    }
}
