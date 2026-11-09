// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A segmented control with a Liquid Glass thumb that slides between segments.
///
/// With Reduce Motion on, the thumb jumps to the new segment.
@available(iOS 26, *)
struct GlassSegmentedControl<Segment: Hashable>: View {
    let segments: [Segment]
    @Binding var selection: Segment
    var tint: Color?
    let title: (Segment) -> String

    @ScaledMetric(relativeTo: .subheadline) private var height = 44.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments, id: \.self) { segment in
                button(for: segment)
            }
        }
        .background { thumb }
        .padding(4)
        .background(.ultraThinMaterial, in: .capsule)
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// One view that moves, drawn behind the labels so they stay readable on top of it.
    private var thumb: some View {
        GeometryReader { proxy in
            let width = proxy.size.width / CGFloat(max(segments.count, 1))
            let index = segments.firstIndex(of: selection) ?? 0

            Color.clear
                .frame(width: width)
                .glassEffect(.regular.tint(tint), in: .capsule)
                .offset(x: width * CGFloat(index))
        }
    }

    private func button(for segment: Segment) -> some View {
        let isSelected = segment == selection

        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.4)) {
                selection = segment
            }
        } label: {
            Text(title(segment))
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: height)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassSegmentedControlDemo: View {
    @State private var period = "Week"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let steps = ["Day": 8_214, "Week": 61_730, "Month": 248_902, "Year": 2_904_117]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .blue, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 4) {
                    Text("Steps walked")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(steps[period, default: 0], format: .number)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                        .foregroundStyle(.white)
                        .animation(reduceMotion ? nil : .snappy, value: period)
                }

                GlassSegmentedControl(segments: ["Day", "Week", "Month", "Year"], selection: $period) { $0 }
                    .padding(.horizontal, 24)
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassSegmentedControlDemo()
}
