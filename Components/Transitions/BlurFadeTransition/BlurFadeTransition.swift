// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A transition that blurs, fades and scales a view. Use it as `.transition(.blurFade)`.
///
/// With Reduce Motion on, the view only fades.
struct BlurFadeTransition: Transition {
    var radius: CGFloat = 18
    var scale: CGFloat = 0.9

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(BlurFadeEffect(radius: radius, scale: scale, isIdentity: phase.isIdentity))
    }
}

extension Transition where Self == BlurFadeTransition {
    static var blurFade: BlurFadeTransition { BlurFadeTransition() }

    static func blurFade(radius: CGFloat, scale: CGFloat = 0.9) -> BlurFadeTransition {
        BlurFadeTransition(radius: radius, scale: scale)
    }
}

// The effect lives in a view modifier so it can read the environment.
private struct BlurFadeEffect: ViewModifier {
    let radius: CGFloat
    let scale: CGFloat
    let isIdentity: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .blur(radius: isIdentity || reduceMotion ? 0 : radius)
            .scaleEffect(isIdentity || reduceMotion ? 1 : scale)
            .opacity(isIdentity ? 1 : 0)
    }
}

// MARK: - Demo

struct BlurFadeTransitionDemo: View {
    @State private var isShown = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if isShown {
                VStack(spacing: 14) {
                    Image(systemName: "moon.stars.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)

                    Text("Good night")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("Sleep mode starts in ten minutes.")
                        .font(.callout)
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(36)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.12), in: .rect(cornerRadius: 32))
                .padding(28)
                .transition(.blurFade)
            }
        }
        .task {
            while (try? await Task.sleep(for: .seconds(1.3))) != nil {
                withAnimation(.smooth(duration: 0.6)) { isShown.toggle() }
            }
        }
    }
}

#Preview {
    BlurFadeTransitionDemo()
}
