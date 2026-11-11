// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A vertical wheel that picks one value. Rows turn away in 3D as they leave the center.
///
/// `values` must be unique. With Reduce Motion on, rows stay flat and only fade.
struct WheelPicker<Value: Hashable>: View {
    let title: LocalizedStringResource
    let values: [Value]
    @Binding var selection: Value
    var visibleRows: Int = 5
    var text: (Value) -> String

    @ScaledMetric(relativeTo: .title3) private var rowHeight: CGFloat = 44
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrolledValue: Value?

    var body: some View {
        let height = rowHeight * CGFloat(max(1, min(visibleRows, 15)))
        let row = rowHeight
        let tilts = !reduceMotion

        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    Text(text(value))
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .frame(height: row)
                        .contentShape(.rect)
                        .onTapGesture { selection = value }
                        .visualEffect { content, proxy in
                            let position = WheelPickerMath.position(midY: proxy.frame(in: .scrollView).midY, height: height)
                            return content
                                .rotation3DEffect(.degrees(tilts ? position * -62 : 0), axis: (1, 0, 0), perspective: 0.55)
                                .scaleEffect(tilts ? 1 - abs(position) * 0.12 : 1)
                                .opacity(1 - abs(position) * 0.72)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.vertical, (height - row) / 2, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledValue, anchor: .center)
        .frame(height: height)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary)
                .frame(height: row)
                .accessibilityHidden(true)
        }
        .onAppear { scrolledValue = selection }
        .onChange(of: scrolledValue) { _, value in
            if let value, value != selection {
                selection = value
            }
        }
        .onChange(of: selection) { _, value in
            if value != scrolledValue {
                withAnimation(reduceMotion ? nil : .snappy) { scrolledValue = value }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(text(selection))
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 1 : -1
            if let index = WheelPickerMath.adjustedIndex(current: values.firstIndex(of: selection), step: step, count: values.count) {
                selection = values[index]
            }
        }
    }
}

nonisolated enum WheelPickerMath {
    /// How far a row is from the center of the wheel: 0 at the center, -1 at the top, 1 at the bottom.
    static func position(midY: Double, height: Double) -> Double {
        guard height > 0, midY.isFinite else { return 0 }
        let halfHeight = height / 2
        return min(max((midY - halfHeight) / halfHeight, -1), 1)
    }

    /// The index one step away, stopping at both ends. Nil when there is nothing to pick.
    static func adjustedIndex(current: Int?, step: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        guard let current else { return 0 }
        return min(max(current + step, 0), count - 1)
    }
}

// MARK: - Demo

struct WheelPickerDemo: View {
    @State private var hour = 7
    @State private var minute = 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 4) {
                Text("Wake Up")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(formatted(hour) + ":" + formatted(minute))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .snappy, value: hour)
                    .animation(reduceMotion ? nil : .snappy, value: minute)
            }

            HStack(spacing: 12) {
                WheelPicker(title: "Hour", values: Array(0..<24), selection: $hour, text: formatted)
                WheelPicker(title: "Minute", values: Array(stride(from: 0, to: 60, by: 5)), selection: $minute, text: formatted)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func formatted(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

#Preview {
    WheelPickerDemo()
}
