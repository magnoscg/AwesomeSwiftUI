// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A row of content that scrolls forever without a seam.
///
/// `speed` is in points per second. With Reduce Motion on, the row stops
/// moving and becomes a normal horizontal scroll view.
struct InfiniteMarqueeRow<Content: View>: View {
    var speed: Double = 40
    var spacing: CGFloat = 12
    var reversed = false
    @ViewBuilder var content: () -> Content

    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The distance after which a copy lands exactly where the previous one was.
    private var loopWidth: CGFloat { contentWidth + spacing }

    private var copies: Int {
        guard contentWidth > 0 else { return 1 }
        return Int((containerWidth / loopWidth).rounded(.up)) + 1
    }

    var body: some View {
        if reduceMotion {
            ScrollView(.horizontal) { row }
                .scrollIndicators(.hidden)
        } else {
            TimelineView(.animation) { context in
                track.offset(x: offset(at: context.date))
            }
            // A zero ideal width keeps the number of copies from feeding back into the row's own size.
            .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity, alignment: .leading)
            .clipped()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        }
    }

    private var row: some View {
        HStack(spacing: spacing) { content() }
            .fixedSize()
    }

    private var track: some View {
        HStack(spacing: spacing) {
            row.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }

            ForEach(1..<copies, id: \.self) { _ in
                row.accessibilityHidden(true)
            }
        }
        .fixedSize()
    }

    private func offset(at date: Date) -> CGFloat {
        guard contentWidth > 0 else { return 0 }
        let distance = CGFloat(date.timeIntervalSinceReferenceDate * speed).truncatingRemainder(dividingBy: loopWidth)
        return reversed ? distance - loopWidth : -distance
    }
}

// MARK: - Demo

struct InfiniteMarqueeRowDemo: View {
    private let rows: [(tags: [String], tint: Color, speed: Double)] = [
        (["SwiftUI", "Layout", "Gestures", "Animation", "Scrolling"], .pink, 46),
        (["Metal", "Shaders", "Particles", "Gradients", "Glass"], .orange, 32),
        (["Haptics", "Charts", "Maps", "Widgets", "Live Activities"], .teal, 54),
        (["Swift 6", "Concurrency", "Observation", "Testing", "Macros"], .purple, 38),
        (["Accessibility", "Dynamic Type", "VoiceOver", "Reduce Motion"], .blue, 48),
    ]

    var body: some View {
        VStack(spacing: 14) {
            Text("Trending topics")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 20)

            ForEach(rows.indices, id: \.self) { index in
                InfiniteMarqueeRow(speed: rows[index].speed, reversed: index.isMultiple(of: 2)) {
                    ForEach(rows[index].tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(rows[index].tint.gradient, in: .capsule)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    InfiniteMarqueeRowDemo()
}
