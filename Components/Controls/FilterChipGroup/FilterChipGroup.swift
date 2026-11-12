// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Flows chips into rows, starting a new row when the next chip does not fit.
nonisolated struct FilterChipGroupFlowLayout: Layout {
    var spacing: CGFloat = 8

    /// The indices of the items in each row. An item wider than the row gets a row of its own.
    static func rows(for widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [[Int]] {
        var rows: [[Int]] = []
        var current: [Int] = []
        var used: CGFloat = 0

        for (index, width) in widths.enumerated() {
            let needed = current.isEmpty ? width : used + spacing + width
            if needed > maxWidth, !current.isEmpty {
                rows.append(current)
                current = [index]
                used = width
            } else {
                current.append(index)
                used = needed
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    /// Measures each chip at no more than the row, so a long one truncates instead of overflowing.
    private func sizes(of subviews: Subviews, maxWidth: CGFloat) -> [CGSize] {
        subviews.map { subview in
            let natural = subview.sizeThatFits(.unspecified)
            return natural.width > maxWidth ? subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil)) : natural
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = sizes(of: subviews, maxWidth: maxWidth)
        var width: CGFloat = 0
        var height: CGFloat = 0

        for (number, row) in Self.rows(for: sizes.map(\.width), maxWidth: maxWidth, spacing: spacing).enumerated() {
            let rowWidths = row.map { sizes[$0].width }
            let rowWidth = rowWidths.reduce(0, +) + spacing * CGFloat(row.count - 1)
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            width = max(width, rowWidth)
            height += number == 0 ? rowHeight : spacing + rowHeight
        }
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = sizes(of: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in Self.rows(for: sizes.map(\.width), maxWidth: bounds.width, spacing: spacing) {
            var x = bounds.minX
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            for index in row {
                subviews[index].place(at: CGPoint(x: x, y: y + rowHeight / 2), anchor: .leading, proposal: ProposedViewSize(sizes[index]))
                x += sizes[index].width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

/// Chips that filter a list: each one toggles on its own, shows a checkmark
/// when selected, and the group wraps onto as many rows as it needs.
///
/// With Reduce Motion on, the checkmark fades in instead of growing.
struct FilterChipGroup<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Set<Option>
    var color: Color = .accentColor
    let title: (Option) -> LocalizedStringResource

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FilterChipGroupFlowLayout {
            ForEach(options, id: \.self) { option in
                chip(option)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(_ option: Option) -> some View {
        let isSelected = selection.contains(option)

        return Button {
            if isSelected { selection.remove(option) } else { selection.insert(option) }
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
                Text(title(option))
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? AnyShapeStyle(FilterChipGroupContrastingForeground(background: color)) : AnyShapeStyle(.primary))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(color) : AnyShapeStyle(.clear), in: .capsule)
            .overlay {
                Capsule().strokeBorder(isSelected ? AnyShapeStyle(color) : AnyShapeStyle(.quaternary), lineWidth: 1)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
            .padding(.vertical, -4)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.35), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

nonisolated struct FilterChipGroupContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

private enum FilterChipGroupDemoFilter: CaseIterable {
    case openNow, delivery, vegan, glutenFree, italian, japanese, mexican, indian, cheap, topRated

    var title: LocalizedStringResource {
        switch self {
        case .openNow: "Open Now"
        case .delivery: "Delivery"
        case .vegan: "Vegan"
        case .glutenFree: "Gluten-Free"
        case .italian: "Italian"
        case .japanese: "Japanese"
        case .mexican: "Mexican"
        case .indian: "Indian"
        case .cheap: "Under $15"
        case .topRated: "Top Rated"
        }
    }
}

struct FilterChipGroupDemo: View {
    @State private var filters: Set<FilterChipGroupDemoFilter> = [.openNow]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Restaurants")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button("Clear") {
                        filters.removeAll()
                    }
                    .disabled(filters.isEmpty)
                }

                FilterChipGroup(options: FilterChipGroupDemoFilter.allCases, selection: $filters, color: .pink) { $0.title }

                Text("Filters applied: \(filters.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(filters.count)))
                    .animation(.snappy, value: filters.count)
            }
            .padding(20)
        }
    }
}

#Preview {
    FilterChipGroupDemo()
}
