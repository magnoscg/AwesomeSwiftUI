// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

struct WeekdaySegmentedPickerDay: Identifiable, Equatable {
    /// The `Calendar` weekday number: 1 is Sunday and 7 is Saturday.
    let weekday: Int
    let letter: String
    let name: String
    let shortName: String

    var id: Int { weekday }
}

enum WeekdaySegmentedPickerSummary: Equatable {
    case never, everyDay, weekdays, weekends
    case days([Int])
}

enum WeekdaySegmentedPickerCalendar {
    /// The seven days in the order of the calendar, starting at its first weekday.
    static func days(for calendar: Calendar) -> [WeekdaySegmentedPickerDay] {
        let letters = calendar.veryShortStandaloneWeekdaySymbols
        let names = calendar.standaloneWeekdaySymbols
        let shortNames = calendar.shortStandaloneWeekdaySymbols

        return (0..<7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return WeekdaySegmentedPickerDay(weekday: index + 1, letter: letters[index], name: names[index], shortName: shortNames[index])
        }
    }

    /// Names a selection the way an alarm does. Saturday and Sunday make the weekend.
    static func summary(of selection: Set<Int>, order: [Int]) -> WeekdaySegmentedPickerSummary {
        let chosen = order.filter(selection.contains)
        switch Set(chosen) {
        case []: return .never
        case Set(1...7): return .everyDay
        case Set(2...6): return .weekdays
        case [1, 7]: return .weekends
        default: return .days(chosen)
        }
    }
}

/// A row of round day buttons that picks several days of the week, like the
/// repeat days of an alarm, with a summary such as "Weekdays" under it.
/// The days follow the calendar: its first weekday and its own letters.
///
/// The selection holds `Calendar` weekday numbers, 1 for Sunday. With Reduce
/// Motion on, a day changes color without popping.
struct WeekdaySegmentedPicker: View {
    @Binding var selection: Set<Int>
    var calendar: Calendar = .current
    var color: Color = .accentColor
    var showsSummary = true

    @ScaledMetric(relativeTo: .body) private var size = 40.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var days: [WeekdaySegmentedPickerDay] {
        WeekdaySegmentedPickerCalendar.days(for: calendar)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(days) { day in
                    dayButton(day)
                }
            }

            if showsSummary {
                summaryText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func dayButton(_ day: WeekdaySegmentedPickerDay) -> some View {
        let isSelected = selection.contains(day.weekday)

        return Button {
            if isSelected { selection.remove(day.weekday) } else { selection.insert(day.weekday) }
        } label: {
            Text(day.letter)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.6)
                .foregroundStyle(isSelected ? AnyShapeStyle(WeekdaySegmentedPickerContrastingForeground(background: color)) : AnyShapeStyle(.primary))
                .frame(maxWidth: size, maxHeight: size)
                .aspectRatio(1, contentMode: .fit)
                .background(isSelected ? AnyShapeStyle(color) : AnyShapeStyle(.quaternary), in: .circle)
                .scaleEffect(isSelected && !reduceMotion ? 1.06 : 1)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.5), value: isSelected)
        .accessibilityLabel(day.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var summaryText: Text {
        switch WeekdaySegmentedPickerCalendar.summary(of: selection, order: days.map(\.weekday)) {
        case .never: Text("Never")
        case .everyDay: Text("Every day")
        case .weekdays: Text("Weekdays")
        case .weekends: Text("Weekends")
        case .days(let weekdays):
            Text(days.filter { weekdays.contains($0.weekday) }.map(\.shortName).formatted(.list(type: .and)))
        }
    }
}

nonisolated struct WeekdaySegmentedPickerContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct WeekdaySegmentedPickerDemo: View {
    @State private var alarmDays: Set<Int> = [2, 4]
    @State private var gymDays: Set<Int> = [3, 5, 7]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Repeat")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 14) {
                Label("7:30 Wake Up", systemImage: "alarm.fill")
                    .font(.headline)
                WeekdaySegmentedPicker(selection: $alarmDays, color: .orange)
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Label("Workout", systemImage: "figure.run")
                    .font(.headline)
                WeekdaySegmentedPicker(selection: $gymDays, color: .mint)
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 22, style: .continuous))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    WeekdaySegmentedPickerDemo()
}
