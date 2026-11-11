// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct CalendarRangeSelectorTests {
    private typealias Logic = CalendarRangeSelectorLogic

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
    }

    @Test func theFirstTapSetsTheStart() throws {
        let day = try date(3, 10)

        let result = Logic.selecting(day, in: .init(), calendar: calendar)

        #expect(result == .init(start: day, end: nil))
    }

    @Test func theSecondTapSetsTheEnd() throws {
        let start = try date(3, 10)
        let end = try date(3, 20)

        let result = Logic.selecting(end, in: .init(start: start), calendar: calendar)

        #expect(result == .init(start: start, end: end))
    }

    @Test func tappingBeforeTheStartStartsAgain() throws {
        let start = try date(3, 10)
        let earlier = try date(3, 2)

        let result = Logic.selecting(earlier, in: .init(start: start), calendar: calendar)

        #expect(result == .init(start: earlier, end: nil))
    }

    @Test func tappingAfterACompleteRangeStartsAgain() throws {
        let selection = Logic.Selection(start: try date(3, 10), end: try date(3, 20))
        let next = try date(3, 25)

        let result = Logic.selecting(next, in: selection, calendar: calendar)

        #expect(result == .init(start: next, end: nil))
    }

    @Test func rolesFollowTheRange() throws {
        let selection = Logic.Selection(start: try date(3, 10), end: try date(3, 12))

        #expect(Logic.role(of: try date(3, 9), in: selection, calendar: calendar) == .outside)
        #expect(Logic.role(of: try date(3, 10), in: selection, calendar: calendar) == .start)
        #expect(Logic.role(of: try date(3, 11), in: selection, calendar: calendar) == .middle)
        #expect(Logic.role(of: try date(3, 12), in: selection, calendar: calendar) == .end)
    }

    @Test func aSameDayRangeIsASingleDay() throws {
        let day = try date(3, 10)

        #expect(Logic.role(of: day, in: .init(start: day, end: day), calendar: calendar) == .single)
    }

    @Test func blanksRespectTheFirstWeekday() throws {
        let march = try date(3, 15)

        #expect(Logic.leadingBlanks(inMonthOf: march, calendar: calendar) == 6)
        #expect(Logic.days(inMonthOf: march, calendar: calendar).count == 31)
    }

    @Test func weekdaySymbolsStartOnTheFirstWeekday() {
        #expect(Logic.weekdaySymbols(calendar: calendar).first == calendar.veryShortStandaloneWeekdaySymbols[1])
    }
}
