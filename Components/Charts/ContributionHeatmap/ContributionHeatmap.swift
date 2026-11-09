// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A calendar grid of colored cells whose intensity shows the activity of each day.
///
/// It opens scrolled to the newest week. VoiceOver reads the whole grid as one summary,
/// and with Reduce Motion on the cells appear without animating.
struct ContributionHeatmap: View {
    let activity: [Date: Int]
    var endDate: Date = .now
    var weeks: Int = 26
    var calendar: Calendar = .current
    var tint: Color = .green
    var cellSize: CGFloat = 18
    var spacing: CGFloat = 4

    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let levels = 4

    var body: some View {
        let days = ContributionHeatmapLogic.days(endingAt: endDate, weeks: weeks, calendar: calendar)
        let counts = ContributionHeatmapLogic.counts(for: days, activity: activity, calendar: calendar)
        let highest = counts.max() ?? 0
        let size = max(cellSize, 1)
        let gap = max(spacing, 0)

        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(size), spacing: gap), count: 7), spacing: gap) {
                    ForEach(Array(counts.enumerated()), id: \.offset) { index, count in
                        cell(
                            level: ContributionHeatmapLogic.level(count: count, highest: highest, levels: levels),
                            delay: Double((counts.count - 1 - index) / 7) * 0.03
                        )
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            .scrollIndicators(.hidden)

            legend
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity over the last \(max(weeks, 1)) weeks")
        .accessibilityValue(summary(counts))
        .task(id: activity) {
            guard !reduceMotion else {
                isRevealed = true
                return
            }
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { isRevealed = false }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            isRevealed = true
        }
    }

    private func cell(level: Int, delay: Double) -> some View {
        let isShown = isRevealed || reduceMotion

        return RoundedRectangle(cornerRadius: 4)
            .fill(color(for: level))
            .scaleEffect(isShown ? 1 : 0.3)
            .opacity(isShown ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3).delay(delay), value: isRevealed)
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
            ForEach(0...levels, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: level))
                    .frame(width: 12, height: 12)
            }
            Text("More")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func color(for level: Int) -> Color {
        guard level > 0 else { return Color.secondary.opacity(0.15) }
        return tint.opacity(0.25 + 0.75 * Double(level) / Double(levels))
    }

    private func summary(_ counts: [Int]) -> String {
        let activeDays = counts.count { $0 > 0 }
        return "\(ContributionHeatmapLogic.sum(counts)) contributions on \(activeDays) days"
    }
}

/// The grid math, apart from the view so it can be tested.
enum ContributionHeatmapLogic {
    /// Every day shown, oldest first. The first day starts a week, so columns line up.
    static func days(endingAt end: Date, weeks: Int, calendar: Calendar) -> [Date] {
        let weeks = min(max(weeks, 1), 530)
        let last = calendar.startOfDay(for: end)
        let daysIntoWeek = (calendar.component(.weekday, from: last) - calendar.firstWeekday + 7) % 7
        let count = (weeks - 1) * 7 + daysIntoWeek + 1
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0 - count + 1, to: last) }
    }

    /// The count of each day. Dates are matched by day, and repeated days keep the highest.
    static func counts(for days: [Date], activity: [Date: Int], calendar: Calendar) -> [Int] {
        var byDay: [Date: Int] = [:]
        for (date, count) in activity {
            let day = calendar.startOfDay(for: date)
            byDay[day] = max(byDay[day] ?? 0, count)
        }
        return days.map { byDay[calendar.startOfDay(for: $0)] ?? 0 }
    }

    /// The color step of a count: 0 for nothing, then 1 up to `levels`.
    static func level(count: Int, highest: Int, levels: Int) -> Int {
        guard count > 0, highest > 0, levels > 0 else { return 0 }
        let ratio = Double(count) / Double(highest)
        return min(max(Int((ratio * Double(levels)).rounded(.up)), 1), levels)
    }

    /// Adds positive counts and stops at `Int.max` instead of overflowing.
    static func sum(_ counts: [Int]) -> Int {
        counts.reduce(0) { total, count in
            let (result, overflow) = total.addingReportingOverflow(max(count, 0))
            return overflow ? Int.max : result
        }
    }
}

// MARK: - Demo

struct ContributionHeatmapDemo: View {
    @State private var seed = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activity: [Date: Int] {
        let today = Calendar.current.startOfDay(for: .now)
        var result: [Date: Int] = [:]
        for offset in 0..<210 {
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) else { continue }
            let wave = sin(Double(offset) * 0.9 * seed) + cos(Double(offset) * 0.23 + seed)
            result[day] = max(0, Int(wave * 5))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("Commits")
                .font(.largeTitle.bold())
            Text("Your last 30 weeks of work")
                .font(.title3)
                .foregroundStyle(.secondary)

            ContributionHeatmap(activity: activity, weeks: 30)
            Spacer()
        }
        .padding(24)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }
                seed = seed > 1.3 ? 1 : seed + 0.17
            }
        }
    }
}

#Preview {
    ContributionHeatmapDemo()
}
