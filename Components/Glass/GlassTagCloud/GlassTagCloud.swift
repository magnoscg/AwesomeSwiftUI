// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

@available(iOS 26, *)
struct GlassTagCloudTag: Identifiable {
    let title: String
    let tint: Color

    var id: String { title }
}

/// Tags of tinted, interactive Liquid Glass that melt together when they get close.
///
/// `mergeDistance` is the gap below which neighbouring tags blend. With Reduce Motion on,
/// selecting a tag changes it without animating.
@available(iOS 26, *)
struct GlassTagCloud: View {
    let tags: [GlassTagCloudTag]
    @Binding var selection: Set<String>
    var spacing: CGFloat = 16
    var mergeDistance: CGFloat = 10

    @ScaledMetric(relativeTo: .subheadline) private var horizontalPadding = 16.0
    @ScaledMetric(relativeTo: .subheadline) private var verticalPadding = 10.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassEffectContainer(spacing: mergeDistance) {
            GlassTagCloudLayout(spacing: spacing) {
                ForEach(tags) { tag in
                    tagButton(tag)
                }
            }
        }
    }

    private func tagButton(_ tag: GlassTagCloudTag) -> some View {
        let isSelected = selection.contains(tag.title)

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                if isSelected {
                    selection.remove(tag.title)
                } else {
                    selection.insert(tag.title)
                }
            }
        } label: {
            Text(tag.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .glassEffect(.regular.tint(tag.tint.opacity(isSelected ? 0.85 : 0.3)).interactive(), in: .capsule)
    }
}

@available(iOS 26, *)
private struct GlassTagCloudLayout: Layout {
    var spacing: CGFloat

    var animatableData: CGFloat {
        get { spacing }
        set { spacing = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        return GlassTagCloudFlow.arrange(sizes, width: proposal.width ?? .infinity, spacing: spacing).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let tagProposal = ProposedViewSize(width: bounds.width, height: nil)
        let sizes = subviews.map { $0.sizeThatFits(tagProposal) }
        let origins = GlassTagCloudFlow.arrange(sizes, width: bounds.width, spacing: spacing).origins
        for (subview, origin) in zip(subviews, origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: tagProposal)
        }
    }
}

@available(iOS 26, *)
enum GlassTagCloudFlow {
    /// Places items left to right, starting a new row when the next item would not fit in `width`.
    static func arrange(_ sizes: [CGSize], width: CGFloat, spacing: CGFloat) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for size in sizes {
            if cursor.x > 0, cursor.x + size.width > width {
                cursor = CGPoint(x: 0, y: cursor.y + rowHeight + spacing)
                rowHeight = 0
            }
            origins.append(cursor)
            usedWidth = max(usedWidth, cursor.x + size.width)
            rowHeight = max(rowHeight, size.height)
            cursor.x += size.width + spacing
        }

        return (origins, CGSize(width: usedWidth, height: cursor.y + rowHeight))
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassTagCloudDemo: View {
    @State private var selection: Set<String> = ["SwiftUI"]
    @State private var isTight = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tags = [
        GlassTagCloudTag(title: "SwiftUI", tint: .blue),
        GlassTagCloudTag(title: "Animation", tint: .pink),
        GlassTagCloudTag(title: "Layout", tint: .orange),
        GlassTagCloudTag(title: "Glass", tint: .teal),
        GlassTagCloudTag(title: "Gestures", tint: .purple),
        GlassTagCloudTag(title: "Symbols", tint: .green),
        GlassTagCloudTag(title: "Charts", tint: .red),
        GlassTagCloudTag(title: "Navigation", tint: .indigo),
        GlassTagCloudTag(title: "Metal", tint: .mint),
        GlassTagCloudTag(title: "Widgets", tint: .yellow),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Scrolls only when Dynamic Type makes the content taller than the screen.
            ViewThatFits(in: .vertical) {
                content

                ScrollView {
                    content
                }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Pick your interests")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            GlassTagCloud(tags: tags, selection: $selection, spacing: isTight ? 3 : 18)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("Tight spacing", isOn: $isTight.animation(reduceMotion ? nil : .smooth(duration: 0.7)))
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(24)
    }
}

@available(iOS 26, *)
#Preview {
    GlassTagCloudDemo()
}
