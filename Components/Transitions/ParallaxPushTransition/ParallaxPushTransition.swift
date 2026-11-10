// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum ParallaxPushTransitionMath {
    /// The horizontal shift as a fraction of the page width.
    static func shift(phase: TransitionPhase, isForward: Bool, parallax: CGFloat) -> CGFloat {
        switch phase {
        case .identity: 0
        case .willAppear: isForward ? 1 : -parallax
        case .didDisappear: isForward ? -parallax : 1
        }
    }
}

/// The incoming page slides over while the outgoing page moves at a slower parallax speed.
///
/// A `Transition` cannot read the environment, so pass Reduce Motion in: with it on, the
/// pages crossfade. Give the page on top the higher `zIndex`.
struct ParallaxPushTransition: Transition {
    var isForward = true
    var reduceMotion = false
    var parallax: CGFloat = 0.3

    func body(content: Content, phase: TransitionPhase) -> some View {
        // `visualEffect` takes a `@Sendable` closure, so it works with a local copy.
        let shift = ParallaxPushTransitionMath.shift(phase: phase, isForward: isForward, parallax: parallax)

        if reduceMotion {
            content.opacity(phase.isIdentity ? 1 : 0)
        } else {
            content
                .brightness(shift < 0 ? -0.25 : 0)
                .visualEffect { effect, proxy in
                    effect.offset(x: shift * proxy.size.width)
                }
        }
    }
}

extension Transition where Self == ParallaxPushTransition {
    /// For moving forward. Moving back uses `.parallaxPop`, set before the page changes.
    static func parallaxPush(reduceMotion: Bool = false) -> ParallaxPushTransition {
        ParallaxPushTransition(isForward: true, reduceMotion: reduceMotion)
    }

    static func parallaxPop(reduceMotion: Bool = false) -> ParallaxPushTransition {
        ParallaxPushTransition(isForward: false, reduceMotion: reduceMotion)
    }
}

// MARK: - Demo

struct ParallaxPushTransitionDemo: View {
    private struct Screen {
        let title: String
        let symbol: String
        let colors: [Color]
    }

    private let screens = [
        Screen(title: "Arrive", symbol: "airplane.arrival", colors: [.indigo, .blue]),
        Screen(title: "Stay", symbol: "bed.double.fill", colors: [.orange, .pink]),
        Screen(title: "Taste", symbol: "fork.knife", colors: [.green, .teal]),
        Screen(title: "Depart", symbol: "airplane.departure", colors: [.purple, .pink]),
    ]

    // Keeps growing, so the newest page always has the highest `zIndex`.
    @State private var generation = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var screen: Screen { screens[generation % screens.count] }

    var body: some View {
        ZStack {
            page(screen)
                .transition(.parallaxPush(reduceMotion: reduceMotion))
                .id(generation)
                .zIndex(Double(generation))
        }
        .overlay(alignment: .bottom) {
            Button("Next page", systemImage: "arrow.forward", action: advance)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))
                .padding(.bottom, 32)
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }

    private func advance() {
        withAnimation(.smooth(duration: 0.7)) {
            generation = generation == Int.max ? 0 : generation + 1
        }
    }

    private func page(_ screen: Screen) -> some View {
        ZStack {
            LinearGradient(colors: screen.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: screen.symbol)
                    .font(.system(size: 90))
                    .accessibilityHidden(true)

                Text(screen.title)
                    .font(.largeTitle.bold())
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    ParallaxPushTransitionDemo()
}
