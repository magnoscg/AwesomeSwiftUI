// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import Foundation
import Testing
@testable import Showcase

struct TrialTimelinePaywallTests {
    @Test func aTrialShowsTodayTheReminderAndTheEnd() {
        #expect(TrialTimelinePaywallLogic.days(trialDays: 7) == [0, 5, 7])
        #expect(TrialTimelinePaywallLogic.days(trialDays: 14, reminderLead: 3) == [0, 11, 14])
    }

    @Test func aTrialTooShortForAReminderHasNone() {
        #expect(TrialTimelinePaywallLogic.days(trialDays: 2) == [0, 2])
        #expect(TrialTimelinePaywallLogic.days(trialDays: 1) == [0, 1])
        #expect(TrialTimelinePaywallLogic.days(trialDays: 3) == [0, 1, 3])
    }

    @Test func noReminderLeadLeavesTheStepOut() {
        #expect(TrialTimelinePaywallLogic.days(trialDays: 7, reminderLead: 0) == [0, 7])
        #expect(TrialTimelinePaywallLogic.days(trialDays: 7, reminderLead: -4) == [0, 7])
    }

    @Test func noTrialIsJustToday() {
        #expect(TrialTimelinePaywallLogic.days(trialDays: 0) == [0])
        #expect(TrialTimelinePaywallLogic.days(trialDays: -3) == [0])
    }

    @Test func aDateIsCountedInCalendarDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 28, hour: 9)))

        let end = TrialTimelinePaywallLogic.date(afterDays: 7, from: start, calendar: calendar)

        #expect(calendar.dateComponents([.year, .month, .day, .hour], from: end) == DateComponents(year: 2026, month: 12, day: 5, hour: 9))
    }

    @Test func todayIsTheStartDate() {
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

        #expect(TrialTimelinePaywallLogic.date(afterDays: 0, from: start) == start)
    }
}
