// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// An event of the day. `start` and `end` are minutes after midnight: 570 is half past nine.
struct DayScheduleTimelineEvent: Identifiable {
    let id: String
    let title: String
    let start: Int
    let end: Int
    var color: Color = .blue
}

nonisolated enum DayScheduleTimelineMath {
    static let minutesPerHour = 60

    struct Slot: Equatable, Sendable {
        /// The column of the event, from the leading edge.
        let column: Int
        /// How many columns share the width where the event is.
        let columns: Int
    }

    /// Puts events that overlap side by side. Each takes the first free column, and every
    /// event of a run of overlaps is as wide as the others, so none hides another.
    static func slots(for spans: [ClosedRange<Int>]) -> [Slot] {
        var slots = [Slot](repeating: Slot(column: 0, columns: 1), count: spans.count)
        let order = spans.indices.sorted { (spans[$0].lowerBound, spans[$0].upperBound) < (spans[$1].lowerBound, spans[$1].upperBound) }

        var run: [Int] = []
        var runEnd = Int.min
        var columnEnds: [Int] = []

        func close() {
            for index in run { slots[index] = Slot(column: slots[index].column, columns: max(columnEnds.count, 1)) }
            run = []
            columnEnds = []
        }

        for index in order {
            let span = spans[index]
            if span.lowerBound >= runEnd { close() }

            let column = columnEnds.firstIndex { $0 <= span.lowerBound } ?? columnEnds.count
            if column == columnEnds.count { columnEnds.append(span.upperBound) } else { columnEnds[column] = span.upperBound }
            slots[index] = Slot(column: column, columns: 1)
            run.append(index)
            runEnd = max(runEnd, span.upperBound)
        }
        close()
        return slots
    }

    /// How far down a minute of the day is, in a column that starts at `firstHour`.
    static func offset(minute: Int, firstHour: Int, hourHeight: CGFloat) -> CGFloat {
        CGFloat(minute - firstHour * minutesPerHour) / CGFloat(minutesPerHour) * hourHeight
    }
}

/// The hours of a day down a column, with each event drawn over the time it takes. Events
/// that overlap share the width, and a line marks the time it is.
///
/// A tap on an event sets `selection`. The column starts scrolled to its first event.
struct DayScheduleTimeline: View {
    let events: [DayScheduleTimelineEvent]
    @Binding var selection: DayScheduleTimelineEvent.ID?
    var hours: ClosedRange<Int> = 7...21
    var showsCurrentTime = true

    @ScaledMetric(relativeTo: .body) private var hourHeight = 88.0
    @ScaledMetric(relativeTo: .caption) private var labelWidth = 52.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let calendar = Calendar.current
    private let gap: CGFloat = 3
    private let cornerRadius: CGFloat = 10
    private let minutesPerHour = DayScheduleTimelineMath.minutesPerHour

    private var firstHour: Int { min(max(hours.lowerBound, 0), 23) }
    private var lastHour: Int { min(max(hours.upperBound, firstHour + 1), 24) }

    private func date(atMinute minute: Int) -> Date {
        calendar.date(byAdding: .minute, value: minute, to: calendar.startOfDay(for: .now)) ?? .now
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    grid
                    eventLayer
                    if showsCurrentTime { currentTime }
                }
                .padding(.vertical, 12)
            }
            .onAppear {
                guard let first = events.map(\.start).min() else { return }
                proxy.scrollTo(min(max(first / minutesPerHour, firstHour), lastHour - 1), anchor: .top)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 0) {
            ForEach(firstHour..<lastHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(date(atMinute: hour * minutesPerHour), format: .dateTime.hour())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: labelWidth, alignment: .trailing)
                        // The label sits on its line, not under it.
                        .alignmentGuide(.top) { $0[VerticalAlignment.center] }

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
                .id(hour)
            }
        }
    }

    private var eventLayer: some View {
        let slots = DayScheduleTimelineMath.slots(for: events.map { $0.start...max($0.end, $0.start) })

        return GeometryReader { proxy in
            let width = max(proxy.size.width - labelWidth - 8, 0)

            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                let slot = slots[index]
                let column = width / CGFloat(slot.columns)
                let height = max(DayScheduleTimelineMath.offset(minute: event.end, firstHour: 0, hourHeight: hourHeight) - DayScheduleTimelineMath.offset(minute: event.start, firstHour: 0, hourHeight: hourHeight), hourHeight / 2)

                block(event)
                    .frame(width: max(column - gap, 0), height: max(height - gap, 0), alignment: .topLeading)
                    .offset(
                        x: labelWidth + 8 + column * CGFloat(slot.column),
                        y: DayScheduleTimelineMath.offset(minute: event.start, firstHour: firstHour, hourHeight: hourHeight)
                    )
            }
        }
    }

    private func block(_ event: DayScheduleTimelineEvent) -> some View {
        let isSelected = selection == event.id

        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                selection = isSelected ? nil : event.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(date(atMinute: event.start)...date(atMinute: event.end))
                    .font(.caption)
                    .opacity(0.8)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(DayScheduleTimelineContrastingForeground(background: event.color)) : AnyShapeStyle(.primary))
            .padding(.horizontal, cornerRadius)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(event.color.opacity(isSelected ? 1 : 0.22), in: .rect(cornerRadius: cornerRadius))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: cornerRadius, bottomLeading: cornerRadius))
                    .fill(event.color)
                    .frame(width: 4)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var currentTime: some View {
        TimelineView(.everyMinute) { context in
            let parts = calendar.dateComponents([.hour, .minute], from: context.date)
            let minute = (parts.hour ?? 0) * minutesPerHour + (parts.minute ?? 0)

            if minute >= firstHour * minutesPerHour, minute <= lastHour * minutesPerHour {
                HStack(spacing: 0) {
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                    Rectangle()
                        .fill(.red)
                        .frame(height: 1.5)
                }
                .padding(.leading, labelWidth + 3)
                .offset(y: DayScheduleTimelineMath.offset(minute: minute, firstHour: firstHour, hourHeight: hourHeight) - 4.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct DayScheduleTimelineContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct DayScheduleTimelineDemo: View {
    private let events = [
        DayScheduleTimelineEvent(id: "standup", title: "Stand-up", start: 9 * 60, end: 9 * 60 + 30, color: .teal),
        DayScheduleTimelineEvent(id: "review", title: "Design review", start: 10 * 60, end: 11 * 60 + 30, color: .indigo),
        DayScheduleTimelineEvent(id: "interview", title: "Interview", start: 10 * 60 + 30, end: 11 * 60 + 15, color: .orange),
        DayScheduleTimelineEvent(id: "lunch", title: "Lunch with Ana", start: 13 * 60, end: 14 * 60, color: .green),
        DayScheduleTimelineEvent(id: "focus", title: "Focus time", start: 15 * 60, end: 17 * 60, color: .purple),
        DayScheduleTimelineEvent(id: "gym", title: "Gym", start: 18 * 60 + 30, end: 19 * 60 + 30, color: .pink),
    ]

    @State private var selection: String? = "review"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(Date.now, format: .dateTime.day().month(.wide))
                    .font(.largeTitle.bold())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            DayScheduleTimeline(events: events, selection: $selection)
                .padding(.trailing, 16)
        }
    }
}

#Preview {
    DayScheduleTimelineDemo()
}
