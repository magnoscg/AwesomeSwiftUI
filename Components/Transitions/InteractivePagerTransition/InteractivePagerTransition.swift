// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum InteractivePagerTransitionMath {
    static func clampedIndex(_ index: Int, count: Int) -> Int {
        count > 0 ? min(max(index, 0), count - 1) : 0
    }

    /// Slows the drag past the first and last page.
    static func resisted(translation: CGFloat, index: Int, count: Int) -> CGFloat {
        let current = clampedIndex(index, count: count)
        let pastStart = current == 0 && translation > 0
        let pastEnd = current >= count - 1 && translation < 0
        return pastStart || pastEnd ? translation * 0.3 : translation
    }

    /// Commits when the finger went far enough, or was flicked hard enough. Otherwise cancels.
    static func targetIndex(index: Int, count: Int, translation: CGFloat, predicted: CGFloat, width: CGFloat) -> Int {
        let current = clampedIndex(index, count: count)
        guard count > 0, width > 0 else { return current }

        let decisive = abs(translation) > width * 0.4 ? translation : (abs(predicted) > width * 0.6 ? predicted : 0)
        guard decisive != 0 else { return current }
        return clampedIndex(current + (decisive < 0 ? 1 : -1), count: count)
    }

    /// `relative` is 0 for the centered page, 1 for the next one and -1 for the previous one.
    /// The page on top slides fully. The one underneath moves at a slower parallax speed.
    static func offsetX(relative: CGFloat, width: CGFloat, parallax: Bool) -> CGFloat {
        relative > 0 || !parallax ? relative * width : relative * width * 0.3
    }

    static func scale(relative: CGFloat, parallax: Bool) -> CGFloat {
        guard parallax, relative < 0 else { return 1 }
        return 1 - 0.08 * min(-relative, 1)
    }
}

/// A pager whose transition follows the finger, then completes or cancels on release.
///
/// VoiceOver can change page with a three-finger swipe or by adjusting the page dots. With
/// Reduce Motion on, pages slide plainly under the finger and settle at once.
struct InteractivePagerTransition<Page: Identifiable, PageContent: View>: View {
    let pages: [Page]
    @Binding var index: Int
    @ViewBuilder var content: (Page) -> PageContent

    @GestureState private var dragTranslation: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Gestures report screen points, but layout mirrors in right-to-left layouts: 1 or -1 converts between them.
    private var forward: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }

    private var currentIndex: Int {
        InteractivePagerTransitionMath.clampedIndex(index, count: pages.count)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let drag = InteractivePagerTransitionMath.resisted(translation: dragTranslation, index: currentIndex, count: pages.count)
            let position = CGFloat(currentIndex) - (width > 0 ? drag / width : 0)

            ZStack {
                ForEach(Array(pages.enumerated()), id: \.element.id) { pageIndex, page in
                    if abs(pageIndex - currentIndex) <= 1 {
                        pageView(page, at: pageIndex, position: position, width: width)
                    }
                }
            }
            // The page underneath shrinks and darkens as it recedes. Black behind it reads as
            // depth; the background of the app would flash as bands above and below.
            .background { Color.black.ignoresSafeArea() }
            .contentShape(.rect)
            .gesture(dragGesture(width: width))
            // No animation while the finger is down, so the page tracks it exactly.
            .animation(dragTranslation != 0 || reduceMotion ? nil : .smooth(duration: 0.45), value: position)
        }
        .overlay(alignment: .bottom) { pageDots }
        .accessibilityScrollAction { edge in
            if edge == .trailing { step(1) }
            if edge == .leading { step(-1) }
        }
        .onChange(of: pages.count) {
            index = currentIndex
        }
    }

    private func pageView(_ page: Page, at pageIndex: Int, position: CGFloat, width: CGFloat) -> some View {
        let relative = CGFloat(pageIndex) - position
        let parallax = !reduceMotion

        return content(page)
            .frame(width: width > 0 ? width : nil)
            .scaleEffect(InteractivePagerTransitionMath.scale(relative: relative, parallax: parallax))
            .brightness(parallax && relative < 0 ? 0.25 * max(relative, -1) : 0)
            .offset(x: InteractivePagerTransitionMath.offsetX(relative: relative, width: width, parallax: parallax))
            .zIndex(Double(pageIndex))
            .allowsHitTesting(pageIndex == currentIndex)
            .accessibilityHidden(pageIndex != currentIndex)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.width * forward
            }
            .onEnded { value in
                index = InteractivePagerTransitionMath.targetIndex(
                    index: currentIndex,
                    count: pages.count,
                    translation: value.translation.width * forward,
                    predicted: value.predictedEndTranslation.width * forward,
                    width: width
                )
            }
    }

    private func step(_ delta: Int) {
        index = InteractivePagerTransitionMath.clampedIndex(currentIndex + delta, count: pages.count)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { dot in
                Capsule()
                    .fill(.white.opacity(dot == currentIndex ? 1 : 0.45))
                    .frame(width: dot == currentIndex ? 22 : 8, height: 8)
            }
        }
        .padding(.bottom, 18)
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: currentIndex)
        .accessibilityElement()
        .accessibilityLabel("Page")
        .accessibilityValue(pages.isEmpty ? "None" : "\(currentIndex + 1) of \(pages.count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: step(1)
            case .decrement: step(-1)
            @unknown default: break
            }
        }
    }
}

// MARK: - Demo

struct InteractivePagerTransitionDemo: View {
    private struct Slide: Identifiable {
        let id: String
        let symbol: String
        let colors: [Color]
    }

    private let slides = [
        Slide(id: "Explore", symbol: "safari.fill", colors: [.teal, .blue]),
        Slide(id: "Collect", symbol: "square.stack.3d.up.fill", colors: [.orange, .pink]),
        Slide(id: "Share", symbol: "paperplane.fill", colors: [.purple, .indigo]),
    ]

    @State private var index = 0

    var body: some View {
        InteractivePagerTransition(pages: slides, index: $index) { slide in
            ZStack {
                LinearGradient(colors: slide.colors, startPoint: .topLeading, endPoint: .bottomTrailing)

                VStack(spacing: 18) {
                    Image(systemName: slide.symbol)
                        .font(.system(size: 90))
                        .accessibilityHidden(true)

                    Text(slide.id)
                        .font(.largeTitle.bold())
                }
                .foregroundStyle(.white)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    InteractivePagerTransitionDemo()
}
