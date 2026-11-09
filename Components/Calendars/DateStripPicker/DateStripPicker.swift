// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A horizontal strip of days that keeps the selected day centered as you scroll.
///
/// With Reduce Motion on, tapping a day jumps to it without scrolling.
struct DateStripPicker: View {
    @Binding var selection: Date
    var tint: Color

    private let days: [Date]
    private let calendar: Calendar

    @State private var centeredDay: Date?
    @ScaledMetric(relativeTo: .title2) private var itemWidth = 58.0
    @ScaledMetric(relativeTo: .title2) private var itemHeight = 84.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let spacing = 10.0

    init(
        selection: Binding<Date>,
        center: Date = .now,
        daysBefore: Int = 30,
        daysAfter: Int = 30,
        calendar: Calendar = .current,
        tint: Color = .indigo
    ) {
        _selection = selection
        self.tint = tint
        self.calendar = calendar
        days = DateStripPickerLogic.days(around: center, before: daysBefore, after: daysAfter, calendar: calendar)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(days, id: \.self) { dayCell($0) }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max(0, (proxy.size.width - itemWidth) / 2), for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredDay, anchor: .center)
        }
        .frame(height: itemHeight)
        .onAppear { centeredDay = closestDay(to: selection) }
        .onChange(of: centeredDay) { _, day in
            guard let day, day != calendar.startOfDay(for: selection) else { return }
            selection = day
        }
        .onChange(of: selection) { _, newValue in
            let day = closestDay(to: newValue)
            guard day != centeredDay else { return }
            withAnimation(reduceMotion ? nil : .snappy) { centeredDay = day }
        }
        .sensoryFeedback(.selection, trigger: centeredDay) { old, new in old != nil && new != nil }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = day == calendar.startOfDay(for: selection)
        let isToday = calendar.isDateInToday(day)

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) { centeredDay = day }
        } label: {
            VStack(spacing: 4) {
                Text(format(day, Date.FormatStyle().weekday(.abbreviated)))
                    .font(.caption.weight(.medium))
                Text(format(day, Date.FormatStyle().day()))
                    .font(.title2.weight(.bold))
                Circle()
                    .fill(isToday ? (isSelected ? Color.white : tint) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(width: itemWidth, height: itemHeight)
            .background(isSelected ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(.thinMaterial), in: .rect(cornerRadius: 18))
            .scaleEffect(isSelected || reduceMotion ? 1 : 0.92)
            .animation(reduceMotion ? nil : .snappy, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(format(day, Date.FormatStyle().weekday(.wide).day().month(.wide)))
        .accessibilityValue(isToday ? "Today" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func closestDay(to date: Date) -> Date? {
        DateStripPickerLogic.closestDay(to: date, in: days, calendar: calendar)
    }

    private func format(_ date: Date, _ base: Date.FormatStyle) -> String {
        var style = base
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }
}

/// The date math of the strip, apart from the view so it can be tested.
enum DateStripPickerLogic {
    /// Keeps a very wide request from building an enormous array.
    static let maximumDaysPerSide = 3_650

    static func days(around center: Date, before: Int, after: Int, calendar: Calendar) -> [Date] {
        let before = min(max(before, 0), maximumDaysPerSide)
        let after = min(max(after, 0), maximumDaysPerSide)
        let start = calendar.startOfDay(for: center)
        return (-before...after).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map { calendar.startOfDay(for: $0) }
        }
    }

    /// The same day when it is in the strip, otherwise the nearest end of the strip.
    static func closestDay(to date: Date, in days: [Date], calendar: Calendar) -> Date? {
        let day = calendar.startOfDay(for: date)
        return days.first { $0 >= day } ?? days.last
    }
}

// MARK: - Demo

struct DateStripPickerDemo: View {
    @State private var selection = Date.now

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.3), .teal.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            DateStripPicker(selection: $selection)

            VStack {
                Text("Your agenda")
                    .font(.largeTitle.bold())
                Spacer()
                Text(selection, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

#Preview {
    DateStripPickerDemo()
}
