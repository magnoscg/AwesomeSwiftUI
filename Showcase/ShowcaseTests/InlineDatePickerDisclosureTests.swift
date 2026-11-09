// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct InlineDatePickerDisclosureTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private let noon = Date(timeIntervalSince1970: 1_794_225_600)

    @Test func aDifferentDayCloses() {
        let nextDay = noon.addingTimeInterval(86_400)

        #expect(InlineDatePickerDisclosureRule.closes(from: noon, to: nextDay, in: calendar))
    }

    @Test func aNewTimeOnTheSameDayStaysOpen() {
        let later = noon.addingTimeInterval(3_600)

        #expect(!InlineDatePickerDisclosureRule.closes(from: noon, to: later, in: calendar))
    }
}
