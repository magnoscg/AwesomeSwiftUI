// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A date row that opens in place into a calendar and closes again once a day is chosen.
///
/// With Reduce Motion on, the calendar appears and disappears without animating.
struct InlineDatePickerDisclosure: View {
    let title: LocalizedStringResource
    @Binding var date: Date
    var range: ClosedRange<Date> = Date.distantPast...Date.distantFuture

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.35)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(animation) { isExpanded.toggle() }
            } label: {
                row
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(date.formatted(date: .long, time: .omitted))
            .accessibilityHint(isExpanded ? "Hides the calendar" : "Shows the calendar")

            if isExpanded {
                Divider()

                DatePicker(selection: $date, in: range, displayedComponents: .date) { Text(title) }
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
        .clipped()
        .onChange(of: date) { oldValue, newValue in
            if isExpanded, InlineDatePickerDisclosureRule.closes(from: oldValue, to: newValue, in: .current) {
                withAnimation(animation) { isExpanded = false }
            }
        }
    }

    private var row: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            // At the largest text sizes the date moves under the title.
            ViewThatFits(in: .horizontal) {
                HStack {
                    labels
                }
                VStack(alignment: .leading, spacing: 4) {
                    labels
                }
            }

            Image(systemName: "chevron.down")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .accessibilityHidden(true)
        }
        .padding()
        .contentShape(.rect)
    }

    @ViewBuilder
    private var labels: some View {
        Text(title)
            .font(.body.weight(.medium))
            .lineLimit(1)
            .fixedSize()

        Spacer(minLength: 8)

        Text(date.formatted(date: .abbreviated, time: .omitted))
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }
}

enum InlineDatePickerDisclosureRule {
    /// Paging through months does not change the date, so only a different day closes the calendar.
    static func closes(from oldValue: Date, to newValue: Date, in calendar: Calendar) -> Bool {
        !calendar.isDate(oldValue, inSameDayAs: newValue)
    }
}

// MARK: - Demo

struct InlineDatePickerDisclosureDemo: View {
    @State private var departure = Date.now
    @State private var comeback = Date.now.addingTimeInterval(4 * 86_400)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your trip")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                VStack(spacing: 14) {
                    InlineDatePickerDisclosure(title: "Departure", date: $departure)
                        .background(.background.secondary, in: .rect(cornerRadius: 20))

                    InlineDatePickerDisclosure(title: "Return", date: $comeback)
                        .background(.background.secondary, in: .rect(cornerRadius: 20))
                }
                .tint(.indigo)
            }
            .padding(20)
        }
    }
}

#Preview {
    InlineDatePickerDisclosureDemo()
}
