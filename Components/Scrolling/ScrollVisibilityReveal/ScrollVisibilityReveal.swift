// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Fades and slides a view into place the first time it becomes visible in a scroll view.
///
/// With Reduce Motion on, the view only fades in. With VoiceOver on, it is shown from the
/// start, so a section that has not been reached yet can still be found.
struct ScrollVisibilityReveal: ViewModifier {
    var threshold: Double
    var distance: CGFloat

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    private var isVisible: Bool { hasAppeared || voiceOverEnabled }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : distance)
            .onScrollVisibilityChange(threshold: min(max(threshold, 0), 1)) { visible in
                guard visible, !hasAppeared else { return }
                withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .smooth(duration: 0.6)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// A low threshold means a section taller than the screen still gets revealed.
    func scrollVisibilityReveal(threshold: Double = 0.15, distance: CGFloat = 36) -> some View {
        modifier(ScrollVisibilityReveal(threshold: threshold, distance: distance))
    }
}

// MARK: - Demo

struct ScrollVisibilityRevealDemo: View {
    private struct Section: Identifiable {
        let id: String
        let symbol: String
        let colors: [Color]
    }

    private let sections = [
        Section(id: "Sunrise", symbol: "sunrise.fill", colors: [.orange, .pink]),
        Section(id: "Forest", symbol: "leaf.fill", colors: [.green, .teal]),
        Section(id: "Ocean", symbol: "water.waves", colors: [.cyan, .blue]),
        Section(id: "Night", symbol: "moon.stars.fill", colors: [.indigo, .purple]),
        Section(id: "Storm", symbol: "cloud.bolt.rain.fill", colors: [.gray, .indigo]),
        Section(id: "Snow", symbol: "snowflake", colors: [.mint, .cyan]),
    ]

    @State private var position = ScrollPosition(y: 0)
    @State private var maxOffset: CGFloat = 0
    @State private var cycle = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ForEach(sections) { section in
                    card(section)
                        .scrollVisibilityReveal()
                }
            }
            .padding(20)
        }
        // A new identity forgets what has been revealed, so the demo can replay it.
        .id(cycle)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height, 0)
        } action: { _, newValue in
            maxOffset = newValue
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            await replay()
        }
    }

    private func card(_ section: Section) -> some View {
        VStack(spacing: 12) {
            Image(systemName: section.symbol)
                .font(.largeTitle)
                .accessibilityHidden(true)

            Text(section.id)
                .font(.title.bold())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 240)
        .background(LinearGradient(colors: section.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 28))
    }

    // Only the demo scrolls by itself. Each pass scrolls to the end, then starts over.
    private func replay() async {
        var time = 0.0
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            guard !Task.isCancelled else { return }
            time += 0.016
            if time >= 4 {
                time = 0
                cycle += 1
            }
            position.scrollTo(y: maxOffset * min(time / 3.6, 1))
        }
    }
}

#Preview {
    ScrollVisibilityRevealDemo()
}
