// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum ScrollProgressBarMath {
    /// How far through the content the reader is, from 0 to 1.
    static func progress(offsetY: CGFloat, topInset: CGFloat, bottomInset: CGFloat, contentHeight: CGFloat, containerHeight: CGFloat) -> CGFloat {
        let scrollable = contentHeight + topInset + bottomInset - containerHeight
        guard scrollable > 0 else { return 0 }
        return min(max((offsetY + topInset) / scrollable, 0), 1)
    }
}

/// A thin bar pinned to the top of a scroll view that grows with the reading progress.
///
/// Apply it to the `ScrollView` with `.scrollProgressBar()`. The bar follows the scroll
/// position directly, so it has no animation of its own.
struct ScrollProgressBar: ViewModifier {
    var tint: LinearGradient
    var height: CGFloat

    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                ScrollProgressBarMath.progress(
                    offsetY: geometry.contentOffset.y,
                    topInset: geometry.contentInsets.top,
                    bottomInset: geometry.contentInsets.bottom,
                    contentHeight: geometry.contentSize.height,
                    containerHeight: geometry.containerSize.height
                )
            } action: { _, newValue in
                progress = newValue
            }
            .overlay(alignment: .top) { bar }
    }

    private var bar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: max(height, 0))
        .padding(.horizontal, 12)
        .accessibilityElement()
        .accessibilityLabel("Reading progress")
        .accessibilityValue(Double(progress).formatted(.percent.precision(.fractionLength(0))))
    }
}

extension View {
    func scrollProgressBar(
        tint: LinearGradient = LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing),
        height: CGFloat = 5
    ) -> some View {
        modifier(ScrollProgressBar(tint: tint, height: height))
    }
}

// MARK: - Demo

struct ScrollProgressBarDemo: View {
    @State private var position = ScrollPosition(y: 0)
    @State private var maxOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let paragraph = "Good interfaces explain themselves. A small sign of how much is left can turn a long read into something that feels easy to finish, and it asks nothing of the reader."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("The long read")
                    .font(.largeTitle.bold())

                ForEach(0..<14, id: \.self) { index in
                    Text("Chapter \(index + 1)")
                        .font(.title2.bold())

                    Text(paragraph)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .scrollPosition($position)
        .scrollProgressBar()
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height, 0)
        } action: { _, newValue in
            maxOffset = newValue
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await autoScroll()
        }
    }

    // Only the demo scrolls by itself: down for most of the loop, then quickly back up.
    private func autoScroll() async {
        var time = 0.0
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            time = (time + 0.016).truncatingRemainder(dividingBy: 5)
            let fraction = time < 4 ? time / 4 : 5 - time
            position.scrollTo(y: maxOffset * fraction)
        }
    }
}

#Preview {
    ScrollProgressBarDemo()
}
