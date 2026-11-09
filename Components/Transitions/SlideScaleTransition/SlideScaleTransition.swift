// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A transition that slides and scales a view: it enters from one side and leaves by the other.
///
/// With Reduce Motion on, the view only fades.
struct SlideScaleTransition: Transition {
    var axis: Axis = .horizontal
    var distance: CGFloat = 220
    var scale: CGFloat = 0.8

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(SlideScaleEffect(axis: axis, distance: distance, scale: scale, phase: phase))
    }
}

extension Transition where Self == SlideScaleTransition {
    static var slideScale: SlideScaleTransition { SlideScaleTransition() }

    static func slideScale(axis: Axis, distance: CGFloat = 220, scale: CGFloat = 0.8) -> SlideScaleTransition {
        SlideScaleTransition(axis: axis, distance: distance, scale: scale)
    }
}

// The effect lives in a view modifier so it can read the environment.
private struct SlideScaleEffect: ViewModifier {
    let axis: Axis
    let distance: CGFloat
    let scale: CGFloat
    let phase: TransitionPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // `phase.value` is -1 before appearing, 0 at rest and 1 after disappearing.
    private var offset: CGFloat {
        reduceMotion ? 0 : -phase.value * distance
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(phase.isIdentity || reduceMotion ? 1 : scale)
            .offset(x: axis == .horizontal ? offset : 0, y: axis == .vertical ? offset : 0)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

// MARK: - Demo

struct SlideScaleTransitionDemo: View {
    @State private var index = 0

    private let cards: [(title: String, systemImage: String, colors: [Color])] = [
        ("Run", "figure.run", [.orange, .red]),
        ("Swim", "figure.pool.swim", [.cyan, .blue]),
        ("Climb", "figure.climbing", [.mint, .green]),
    ]

    private var card: (title: String, systemImage: String, colors: [Color]) {
        cards[index % cards.count]
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: card.systemImage)
                    .font(.system(.largeTitle, weight: .semibold))
                    .imageScale(.large)
                    .accessibilityHidden(true)

                Text(card.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .background(
                LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 36)
            )
            .padding(32)
            .id(index)
            .transition(.slideScale)
        }
        .task {
            while (try? await Task.sleep(for: .seconds(1.3))) != nil {
                withAnimation(.smooth(duration: 0.55)) { index += 1 }
            }
        }
    }
}

#Preview {
    SlideScaleTransitionDemo()
}
