// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum FlowTagsLayoutMath {
    /// Groups widths into lines. A tag wider than `maxWidth` gets a line of its own.
    static func lines(widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [Range<Int>] {
        var lines: [Range<Int>] = []
        var start = 0
        var used: CGFloat = 0

        for (index, width) in widths.enumerated() {
            if index == start {
                used = width
            } else if used + spacing + width > maxWidth {
                lines.append(start..<index)
                start = index
                used = width
            } else {
                used += spacing + width
            }
        }

        if start < widths.count {
            lines.append(start..<widths.count)
        }
        return lines
    }
}

/// A layout that wraps its views onto as many lines as they need.
struct FlowTagsLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = measuredSizes(of: subviews, maxWidth: proposal.width ?? .infinity)
        let lines = FlowTagsLayoutMath.lines(widths: sizes.map(\.width), maxWidth: proposal.width ?? .infinity, spacing: spacing)
        let widest = lines.map { lineWidth($0, sizes: sizes) }.max() ?? 0
        let height = lines.reduce(0) { $0 + lineHeight($1, sizes: sizes) } + CGFloat(max(lines.count - 1, 0)) * lineSpacing
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = measuredSizes(of: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for line in FlowTagsLayoutMath.lines(widths: sizes.map(\.width), maxWidth: bounds.width, spacing: spacing) {
            let height = lineHeight(line, sizes: sizes)
            var x = bounds.minX

            for index in line {
                subviews[index].place(
                    at: CGPoint(x: x, y: y + height / 2),
                    anchor: .leading,
                    proposal: ProposedViewSize(width: min(sizes[index].width, bounds.width), height: nil)
                )
                x += sizes[index].width + spacing
            }
            y += height + lineSpacing
        }
    }

    /// A view wider than the layout is measured at the width it gets, so its wrapped height counts.
    private func measuredSizes(of subviews: Subviews, maxWidth: CGFloat) -> [CGSize] {
        subviews.map { subview in
            let ideal = subview.sizeThatFits(.unspecified)
            return ideal.width > maxWidth ? subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil)) : ideal
        }
    }

    private func lineWidth(_ line: Range<Int>, sizes: [CGSize]) -> CGFloat {
        sizes[line].reduce(0) { $0 + $1.width } + CGFloat(line.count - 1) * spacing
    }

    private func lineHeight(_ line: Range<Int>, sizes: [CGSize]) -> CGFloat {
        sizes[line].map(\.height).max() ?? 0
    }
}

// MARK: - Demo

struct FlowTagsLayoutDemo: View {
    private static let extras = ["Typography", "Motion", "Haptics", "Color", "Icons"]

    @State private var tags = ["Swift", "Design", "Photography", "Travel", "Coffee", "Running", "Music", "Architecture", "Film", "Cooking", "Books", "Cycling"]
    @State private var added = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .snappy(duration: 0.4) }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your interests")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            FlowTagsLayout(spacing: 10, lineSpacing: 12) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [.indigo, .pink], startPoint: .leading, endPoint: .trailing), in: .capsule)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Button("Remove", systemImage: "minus") {
                    withAnimation(animation) {
                        tags.removeFirst()
                        added = max(added - 1, 0)
                    }
                }
                .disabled(tags.isEmpty)

                Button("Add", systemImage: "plus") {
                    withAnimation(animation) {
                        tags.insert(Self.extras[added], at: 0)
                        added += 1
                    }
                }
                .disabled(added == Self.extras.count)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .pink.opacity(0.14)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    FlowTagsLayoutDemo()
}
