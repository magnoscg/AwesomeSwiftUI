// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A month calendar that picks a start and an end day and shades the days between them.
///
/// The first tap sets the start and the second sets the end. Tapping a day before the
/// start, or any day once the range is complete, starts a new range.
struct CalendarRangeSelector: View {
    @Binding var start: Date?
    @Binding var end: Date?
    var calendar: Calendar
    var tint: Color

    @State private var month: Date
    @ScaledMetric(relativeTo: .body) private var dayHeight = 46.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    init(
        start: Binding<Date?>,
        end: Binding<Date?>,
        month: Date = .now,
        calendar: Calendar = .current,
        tint: Color = .indigo
    ) {
        _start = start
        _end = end
        self.calendar = calendar
        self.tint = tint
        _month = State(initialValue: month)
    }

    private var selection: CalendarRangeSelectorLogic.Selection {
        .init(start: start, end: end)
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            HStack(spacing: 0) {
                ForEach(Array(CalendarRangeSelectorLogic.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(0..<CalendarRangeSelectorLogic.leadingBlanks(inMonthOf: month, calendar: calendar), id: \.self) { _ in
                    Color.clear.frame(height: dayHeight)
                }
                ForEach(CalendarRangeSelectorLogic.days(inMonthOf: month, calendar: calendar), id: \.self) { day in
                    dayCell(day)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            monthButton(systemImage: "chevron.backward", label: "Previous month", offset: -1)
            Spacer()
            Text(format(month, Date.FormatStyle().month(.wide).year()))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            monthButton(systemImage: "chevron.forward", label: "Next month", offset: 1)
        }
    }

    private func monthButton(systemImage: String, label: String, offset: Int) -> some View {
        Button {
            guard let next = calendar.date(byAdding: .month, value: offset, to: month) else { return }
            month = next
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .tint(tint)
        .accessibilityLabel(label)
    }

    private func dayCell(_ day: Date) -> some View {
        let role = CalendarRangeSelectorLogic.role(of: day, in: selection, calendar: calendar)
        let isEndpoint = role == .start || role == .end || role == .single
        let band = tint.opacity(0.18)

        return Button {
            choose(day)
        } label: {
            ZStack {
                HStack(spacing: 0) {
                    (role == .middle || role == .end ? band : Color.clear)
                    (role == .middle || role == .start ? band : Color.clear)
                }
                .padding(.vertical, 2)

                if isEndpoint {
                    Circle().fill(tint).padding(2)
                }

                Text(verbatim: String(calendar.component(.day, from: day)))
                    .font(.body.weight(isEndpoint ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(isEndpoint ? Color.white : Color.primary)
            }
            .frame(height: dayHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(format(day, Date.FormatStyle().weekday(.wide).day().month(.wide).year()))
        .accessibilityValue(accessibilityValue(for: role))
        .accessibilityAddTraits(isEndpoint ? .isSelected : [])
    }

    private func choose(_ day: Date) {
        let next = CalendarRangeSelectorLogic.selecting(day, in: selection, calendar: calendar)
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            start = next.start
            end = next.end
        }
    }

    private func accessibilityValue(for role: CalendarRangeSelectorLogic.Role) -> String {
        switch role {
        case .outside: ""
        case .start: "Start of range"
        case .middle: "In range"
        case .end: "End of range"
        case .single: "Selected"
        }
    }

    private func format(_ date: Date, _ base: Date.FormatStyle) -> String {
        var style = base
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        style.locale = locale
        return date.formatted(style)
    }
}

/// The date math of the calendar, apart from the view so it can be tested.
enum CalendarRangeSelectorLogic {
    struct Selection: Equatable {
        var start: Date?
        var end: Date?
    }

    enum Role: Equatable {
        case outside, start, middle, end, single
    }

    static func selecting(_ day: Date, in selection: Selection, calendar: Calendar) -> Selection {
        let day = calendar.startOfDay(for: day)
        guard let start = selection.start.map({ calendar.startOfDay(for: $0) }), selection.end == nil, day >= start else {
            return Selection(start: day, end: nil)
        }
        return Selection(start: start, end: day)
    }

    static func role(of day: Date, in selection: Selection, calendar: Calendar) -> Role {
        let day = calendar.startOfDay(for: day)
        guard let start = selection.start.map({ calendar.startOfDay(for: $0) }) else { return .outside }
        guard let end = selection.end.map({ calendar.startOfDay(for: $0) }), end != start else {
            return day == start ? .single : .outside
        }

        let lower = min(start, end)
        let upper = max(start, end)
        if day == lower { return .start }
        if day == upper { return .end }
        return day > lower && day < upper ? .middle : .outside
    }

    static func days(inMonthOf date: Date, calendar: Calendar) -> [Date] {
        guard let first = calendar.dateInterval(of: .month, for: date)?.start,
              let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - range.lowerBound, to: first) }
    }

    /// The empty cells before day one, given the calendar's first weekday.
    static func leadingBlanks(inMonthOf date: Date, calendar: Calendar) -> Int {
        guard let first = calendar.dateInterval(of: .month, for: date)?.start else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = min(max(calendar.firstWeekday - 1, 0), symbols.count)
        return Array(symbols[offset...] + symbols[..<offset])
    }
}

// MARK: - Demo

struct CalendarRangeSelectorDemo: View {
    @State private var start: Date?
    @State private var end: Date?

    private let calendar = Calendar(identifier: .gregorian)

    private var firstOfMarch: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? .now
    }

    private var summary: String {
        guard let start else { return "Pick your arrival" }
        guard let end else { return "Now pick your departure" }
        let nights = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return nights == 1 ? "1 night" : "\(nights) nights"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Book your stay")
                    .font(.largeTitle.bold())

                CalendarRangeSelector(start: $start, end: $end, month: firstOfMarch, calendar: calendar)
                    .padding(16)
                    .background(.background, in: .rect(cornerRadius: 24))

                Label(summary, systemImage: "moon.stars.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.indigo)
            }
            .padding(20)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.25), .pink.opacity(0.15)], startPoint: .top, endPoint: .bottom))
        .environment(\.locale, Locale(identifier: "en_US"))
    }
}

#Preview {
    CalendarRangeSelectorDemo()
}
