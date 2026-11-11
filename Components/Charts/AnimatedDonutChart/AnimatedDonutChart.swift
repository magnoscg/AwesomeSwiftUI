// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Charts
import SwiftUI

struct AnimatedDonutChartSegment: Identifiable, Hashable {
    let id: String
    let value: Double
    let color: Color
}

/// A donut chart whose segments grow in one by one, and the selected segment lifts out.
///
/// Tap a segment or its legend row to select it. With Reduce Motion on, the whole donut
/// appears at once.
struct AnimatedDonutChart: View {
    let segments: [AnimatedDonutChartSegment]
    @Binding var selection: String?

    @State private var revealedCount = 0
    @State private var touchedAngle: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var visibleCount: Int { reduceMotion ? segments.count : revealedCount }
    private var total: Double { AnimatedDonutChartLogic.total(of: segments) }

    private var visibleTotal: Double {
        AnimatedDonutChartLogic.total(of: Array(segments.prefix(visibleCount)))
    }

    private var selectedSegment: AnimatedDonutChartSegment? {
        segments.first { $0.id == selection }
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                chart
                centerLabel
            }
            .aspectRatio(1, contentMode: .fit)

            legend
        }
        .task(id: segments) {
            guard !reduceMotion else {
                revealedCount = segments.count
                return
            }
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { revealedCount = 0 }

            for count in segments.indices {
                try? await Task.sleep(for: .milliseconds(count == 0 ? 60 : 260))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.35)) { revealedCount = count + 1 }
            }
        }
        .onChange(of: touchedAngle) { oldValue, newValue in
            guard let newValue,
                  let id = AnimatedDonutChartLogic.segmentID(atAngleValue: newValue, in: segments) else { return }
            selection = oldValue == nil && selection == id ? nil : id
        }
    }

    private var chart: some View {
        Chart {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                SectorMark(
                    angle: .value("Value", index < visibleCount ? AnimatedDonutChartLogic.sanitized(segment.value) : 0),
                    innerRadius: .ratio(0.62),
                    outerRadius: .ratio(selection == segment.id ? 1 : 0.9),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(segment.color)
                .opacity(selection == nil || selection == segment.id ? 1 : 0.4)
            }

            // The empty part of the ring, so that early segments do not fill the circle.
            SectorMark(
                angle: .value("Remaining", total > 0 ? max(total - visibleTotal, 0) : 1),
                innerRadius: .ratio(0.62),
                outerRadius: .ratio(0.9)
            )
            .foregroundStyle(total > 0 ? Color.clear : Color.secondary.opacity(0.2))
        }
        .chartLegend(.hidden)
        .chartAngleSelection(value: $touchedAngle)
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .accessibilityHidden(true)
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text(selectedSegment?.id ?? "Total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text((selectedSegment?.value ?? total).formatted())
                .font(.title.bold())
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .snappy, value: selection)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: 130)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 10) {
            ForEach(segments) { segment in
                let isSelected = selection == segment.id
                let percent = AnimatedDonutChartLogic.share(of: segment, in: segments).formatted(.percent.precision(.fractionLength(0)))

                Button {
                    selection = isSelected ? nil : segment.id
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(segment.color).frame(width: 10, height: 10)
                        Text(segment.id)
                        Spacer(minLength: 4)
                        Text(percent).foregroundStyle(.secondary)
                    }
                    .font(isSelected ? .subheadline.weight(.semibold) : .subheadline)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(segment.id)
                .accessibilityValue("\(segment.value.formatted()), \(percent)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

enum AnimatedDonutChartLogic {
    static func sanitized(_ value: Double) -> Double {
        value.isFinite ? max(value, 0) : 0
    }

    static func total(of segments: [AnimatedDonutChartSegment]) -> Double {
        segments.reduce(0) { $0 + sanitized($1.value) }
    }

    static func share(of segment: AnimatedDonutChartSegment, in segments: [AnimatedDonutChartSegment]) -> Double {
        let total = total(of: segments)
        return total > 0 ? sanitized(segment.value) / total : 0
    }

    /// Finds the segment under an angle, given in the same units as the values.
    static func segmentID(atAngleValue angle: Double, in segments: [AnimatedDonutChartSegment]) -> String? {
        guard angle.isFinite, angle >= 0 else { return nil }
        var cumulative = 0.0
        for segment in segments where sanitized(segment.value) > 0 {
            cumulative += sanitized(segment.value)
            if angle <= cumulative { return segment.id }
        }
        return nil
    }
}

// MARK: - Demo

struct AnimatedDonutChartDemo: View {
    @State private var selection: String?
    @State private var isAlternate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var segments: [AnimatedDonutChartSegment] {
        let values: [Double] = isAlternate ? [980, 240, 310, 160] : [1_120, 420, 180, 290]
        return zip(zip(["Housing", "Food", "Travel", "Fun"], values), [Color.indigo, .teal, .orange, .pink])
            .map { AnimatedDonutChartSegment(id: $0.0, value: $0.1, color: $1) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Spending")
                    .font(.largeTitle.bold())

                AnimatedDonutChart(segments: segments, selection: $selection)
            }
            .padding(24)
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.5))
                for id in ["Housing", "Travel"] {
                    guard !Task.isCancelled else { return }
                    selection = id
                    try? await Task.sleep(for: .seconds(0.8))
                }
                guard !Task.isCancelled else { return }
                selection = nil
                isAlternate.toggle()
            }
        }
    }
}

#Preview {
    AnimatedDonutChartDemo()
}
