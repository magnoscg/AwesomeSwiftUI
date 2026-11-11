// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import CoreGraphics
import Testing
@testable import Showcase

struct DayScheduleTimelineTests {
    private typealias Math = DayScheduleTimelineMath
    private typealias Slot = DayScheduleTimelineMath.Slot

    @Test func eventsThatDoNotOverlapTakeTheWholeWidth() {
        let slots = Math.slots(for: [540...570, 600...660])

        #expect(slots == [Slot(column: 0, columns: 1), Slot(column: 0, columns: 1)])
    }

    @Test func eventsThatOverlapShareTheWidth() {
        let slots = Math.slots(for: [600...690, 630...675])

        #expect(slots == [Slot(column: 0, columns: 2), Slot(column: 1, columns: 2)])
    }

    @Test func anEventThatStartsWhenAnotherEndsDoesNotShare() {
        let slots = Math.slots(for: [540...600, 600...660])

        #expect(slots == [Slot(column: 0, columns: 1), Slot(column: 0, columns: 1)])
    }

    @Test func aFreedColumnIsUsedAgainInsideARun() {
        let slots = Math.slots(for: [540...720, 540...600, 610...660])

        #expect(slots == [Slot(column: 1, columns: 2), Slot(column: 0, columns: 2), Slot(column: 0, columns: 2)])
    }

    @Test func theOrderOfTheEventsDoesNotMatter() {
        let slots = Math.slots(for: [630...675, 600...690])

        #expect(slots == [Slot(column: 1, columns: 2), Slot(column: 0, columns: 2)])
    }

    @Test func noEventsGiveNoSlots() {
        #expect(Math.slots(for: []).isEmpty)
    }

    @Test func aMinuteIsPlacedFromTheFirstHour() {
        #expect(Math.offset(minute: 420, firstHour: 7, hourHeight: 80) == 0)
        #expect(Math.offset(minute: 570, firstHour: 7, hourHeight: 80) == 200)
    }
}
