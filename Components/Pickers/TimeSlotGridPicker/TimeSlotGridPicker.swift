// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A grid of time slots. Unavailable times are disabled and the chosen one is highlighted.
struct TimeSlotGridPicker: View {
    let slots: [Date]
    var unavailable: Set<Date> = []
    @Binding var selection: Date?
    var format: Date.FormatStyle = .dateTime.hour().minute()
    var tint: Color = .indigo

    @ScaledMetric(relativeTo: .subheadline) private var minimumWidth: CGFloat = 96
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var orderedSlots: [Date] { Array(Set(slots)).sorted() }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: 10)], spacing: 10) {
            ForEach(orderedSlots, id: \.self) { slot in
                cell(for: slot)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func cell(for slot: Date) -> some View {
        let isAvailable = !unavailable.contains(slot)
        let isSelected = isAvailable && selection == slot

        return Button {
            selection = slot
        } label: {
            Text(slot.formatted(format))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .strikethrough(!isAvailable)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : isAvailable ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(tint) : isAvailable ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
                }
                .overlay {
                    if !isAvailable {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.quaternary)
                    }
                }
                .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityValue(isAvailable ? "" : "Unavailable")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct TimeSlotGridPickerDemo: View {
    @State private var selection: Date?

    private static let format = Date.FormatStyle.dateTime.hour().minute().locale(Locale(identifier: "en_GB"))

    private static let slots: [Date] = stride(from: 9 * 60, through: 16 * 60, by: 30).compactMap { minutes in
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now)
    }

    private static let unavailable: Set<Date> = Set(
        slots.enumerated().filter { [1, 4, 5, 9, 12].contains($0.offset) }.map(\.element)
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Book a Table")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Choose a time for today.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                TimeSlotGridPicker(
                    slots: Self.slots,
                    unavailable: Self.unavailable,
                    selection: $selection,
                    format: Self.format
                )

                Text(selection.map { "Your table is at \($0.formatted(Self.format))" } ?? "No time chosen yet")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.indigo.opacity(0.14), in: .rect(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
        }
    }
}

#Preview {
    TimeSlotGridPickerDemo()
}
