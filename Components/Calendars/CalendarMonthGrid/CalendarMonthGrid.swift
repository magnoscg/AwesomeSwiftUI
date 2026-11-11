// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum CalendarMonthGridMath {
    /// Six weeks, so every month is the same height.
    static let cellCount = 42

    /// The cells of a month: nil before its first day and after its last.
    static func days(inMonthContaining date: Date, calendar: Calendar) -> [Date?] {
        guard let first = calendar.dateInterval(of: .month, for: date)?.start else {
            return Array(repeating: nil, count: cellCount)
        }

        let leading = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: first)?.count ?? 0
        let days = (0..<dayCount).map { calendar.date(byAdding: .day, value: $0, to: first) }
        let cells = Array(repeating: nil, count: leading) + days
        return Array(cells.prefix(cellCount)) + Array(repeating: nil, count: max(0, cellCount - cells.count))
    }

    /// The weekday initials, starting on the calendar's first day of the week.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard !symbols.isEmpty else { return [] }
        let start = min(max(calendar.firstWeekday - 1, 0), symbols.count - 1)
        return Array(symbols[start...] + symbols[..<start])
    }

    /// What VoiceOver reads for a day, in the same calendar and time zone as the grid.
    static func dayLabel(for day: Date, calendar: Calendar) -> String {
        day.formatted(Date.FormatStyle(date: .complete, time: .omitted, calendar: calendar, timeZone: calendar.timeZone))
    }
}

/// A month calendar for picking one day, with swipe paging between months.
///
/// With Reduce Motion on, the arrows change the month without sliding.
struct CalendarMonthGrid: View {
    @Binding var selection: Date?
    var anchor: Date = .now
    /// How many months can be reached in each direction.
    var monthRange = 24
    var tint: Color = .indigo

    var body: some View {
        CalendarMonthGridStage(selection: $selection, anchor: anchor, monthRange: monthRange, tint: tint)
            // Seven columns cannot hold accessibility sizes, so growth stops here, row height included.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct CalendarMonthGridStage: View {
    @Binding var selection: Date?
    let anchor: Date
    let monthRange: Int
    let tint: Color

    @State private var page = 0
    @ScaledMetric(relativeTo: .body) private var rowHeight = 44.0
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rowSpacing = 4.0
    private var reach: Int { min(max(monthRange, 0), 600) }

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdays

            TabView(selection: $page) {
                ForEach(-reach...reach, id: \.self) { offset in
                    grid(for: month(at: offset))
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: rowHeight * 6 + rowSpacing * 5)
        }
    }

    private var header: some View {
        HStack {
            Text(month(at: page).formatted(monthStyle))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            arrow("chevron.backward", label: "Previous month", to: page - 1)
            arrow("chevron.forward", label: "Next month", to: page + 1)
        }
    }

    private var monthStyle: Date.FormatStyle {
        var style = Date.FormatStyle().month(.wide).year()
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return style
    }

    private func arrow(_ systemImage: String, label: String, to target: Int) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .smooth) { page = target }
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
        }
        .tint(tint)
        .disabled(abs(target) > reach)
        .accessibilityLabel(label)
    }

    private var weekdays: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalendarMonthGridMath.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private func grid(for month: Date) -> some View {
        let cells = CalendarMonthGridMath.days(inMonthContaining: month, calendar: calendar)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayButton(day)
                } else {
                    Color.clear
                        .frame(height: rowHeight)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func dayButton(_ day: Date) -> some View {
        let isSelected = selection.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)

        return Button {
            selection = day
        } label: {
            Text(calendar.component(.day, from: day), format: .number.grouping(.never))
                .font(.body.weight(isSelected || isToday ? .semibold : .regular))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : isToday ? AnyShapeStyle(tint) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
                .background {
                    if isSelected { Circle().fill(tint) }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CalendarMonthGridMath.dayLabel(for: day, calendar: calendar))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func month(at offset: Int) -> Date {
        calendar.date(byAdding: .month, value: offset, to: anchor) ?? anchor
    }
}

// MARK: - Demo

struct CalendarMonthGridDemo: View {
    @State private var selection: Date?

    var body: some View {
        VStack(spacing: 20) {
            CalendarMonthGrid(selection: $selection)
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)

            Text(selection?.formatted(date: .long, time: .omitted) ?? "Pick a day")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.indigo.opacity(0.08))
    }
}

#Preview {
    CalendarMonthGridDemo()
}
