// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import Foundation
import Testing
@testable import Showcase

struct WeekdaySegmentedPickerTests {
    private func calendar(firstWeekday: Int, locale: String = "en_US") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    @Test func aWeekThatStartsOnSundayKeepsTheCalendarOrder() {
        let days = WeekdaySegmentedPickerCalendar.days(for: calendar(firstWeekday: 1))

        #expect(days.map(\.weekday) == [1, 2, 3, 4, 5, 6, 7])
        #expect(days.first?.name == "Sunday")
    }

    @Test func aWeekThatStartsOnMondayPutsSundayLast() {
        let days = WeekdaySegmentedPickerCalendar.days(for: calendar(firstWeekday: 2))

        #expect(days.map(\.weekday) == [2, 3, 4, 5, 6, 7, 1])
        #expect(days.last?.name == "Sunday")
    }

    @Test func theLettersComeFromTheLocale() {
        let days = WeekdaySegmentedPickerCalendar.days(for: calendar(firstWeekday: 2, locale: "es_ES"))

        #expect(days.map(\.letter).joined() == "LMXJVSD")
    }

    @Test func repeatedLettersStillGiveSevenDistinctDays() {
        let days = WeekdaySegmentedPickerCalendar.days(for: calendar(firstWeekday: 1))

        #expect(Set(days.map(\.id)).count == 7)
        #expect(Set(days.map(\.letter)).count < 7)
    }

    @Test func namedSelectionsGetTheirName() {
        let order = [2, 3, 4, 5, 6, 7, 1]

        #expect(WeekdaySegmentedPickerCalendar.summary(of: [], order: order) == .never)
        #expect(WeekdaySegmentedPickerCalendar.summary(of: Set(1...7), order: order) == .everyDay)
        #expect(WeekdaySegmentedPickerCalendar.summary(of: [2, 3, 4, 5, 6], order: order) == .weekdays)
        #expect(WeekdaySegmentedPickerCalendar.summary(of: [1, 7], order: order) == .weekends)
    }

    @Test func otherSelectionsListTheirDaysInTheOrderOfTheWeek() {
        let order = [2, 3, 4, 5, 6, 7, 1]

        #expect(WeekdaySegmentedPickerCalendar.summary(of: [1, 4, 2], order: order) == .days([2, 4, 1]))
    }

    @Test func numbersThatAreNotWeekdaysAreIgnored() {
        let order = [1, 2, 3, 4, 5, 6, 7]

        #expect(WeekdaySegmentedPickerCalendar.summary(of: [0, 9], order: order) == .never)
        #expect(WeekdaySegmentedPickerCalendar.summary(of: [1, 7, 12], order: order) == .weekends)
    }
}
