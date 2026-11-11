// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A segmented picker whose selected pill glides between the options.
///
/// With Reduce Motion on, the pill moves without animating.
struct SlidingSegmentedPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    var tint: Color = .indigo
    let title: (Option) -> String

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(tint.gradient)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.quaternary, in: .capsule)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.25), value: selection)
    }
}

// MARK: - Demo

struct SlidingSegmentedPickerDemo: View {
    private enum Period: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var steps: Int {
            switch self {
            case .day: 8_240
            case .week: 54_910
            case .month: 231_075
            case .year: 2_904_330
            }
        }
    }

    @State private var period = Period.day
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 6) {
                Text(period.steps, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(reduceMotion ? .identity : .numericText(value: Double(period.steps)))
                Text("steps walked")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            SlidingSegmentedPicker(selection: $period, options: Period.allCases) { $0.rawValue }
        }
        .animation(reduceMotion ? nil : .snappy, value: period)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SlidingSegmentedPickerDemo()
}
