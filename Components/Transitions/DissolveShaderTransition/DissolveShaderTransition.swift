// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum DissolveShaderTransitionMath {
    /// How wide the glowing edge is, as a share of the range of the noise.
    static let edgeWidth = 0.12

    /// The noise level under which a pixel is gone. It starts below every pixel and its glow,
    /// so the view begins whole, and ends above them all.
    static func threshold(progress: Double) -> Double {
        let clamped = min(max(progress, 0), 1)
        return clamped * (1 + edgeWidth) - edgeWidth
    }

    /// The function in `DissolveShaderTransition.metal`, with its arguments in the order it declares them.
    static func shader(progress: Double, grain: Double, edge: Color) -> Shader {
        ShaderLibrary.DissolveShaderTransitionBurn(
            .float(threshold(progress: progress)),
            .float(edgeWidth),
            .float(max(grain, 1)),
            .color(edge)
        )
    }
}

/// A transition that dissolves a view through noise, with a glowing edge where it burns away,
/// drawn by a Metal shader. Use it as `.transition(.dissolveShader)`.
///
/// - Important: Copy two files into the same target: `DissolveShaderTransition.swift` and `DissolveShaderTransition.metal`.
///
/// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map, shows a placeholder.
///
/// With Reduce Motion on, the view fades instead.
struct DissolveShaderTransition: Transition {
    /// The color of the edge that burns.
    var edge: Color = .orange
    /// The size of the patches of noise, in points.
    var grain: Double = 44

    func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(DissolveShaderTransitionEffect(progress: phase.isIdentity ? 0 : 1, edge: edge, grain: grain))
    }
}

extension Transition where Self == DissolveShaderTransition {
    static var dissolveShader: DissolveShaderTransition { DissolveShaderTransition() }

    static func dissolveShader(edge: Color, grain: Double = 44) -> DissolveShaderTransition {
        DissolveShaderTransition(edge: edge, grain: grain)
    }
}

/// `Animatable`, so the shader gets every step of the transition: a shader's arguments do not animate by themselves.
private struct DissolveShaderTransitionEffect: ViewModifier, Animatable {
    var progress: Double
    let edge: Color
    let grain: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .colorEffect(
                DissolveShaderTransitionMath.shader(progress: progress, grain: grain, edge: edge),
                isEnabled: progress > 0 && !reduceMotion
            )
            .opacity(reduceMotion ? 1 - min(max(progress, 0), 1) : 1)
            // The first use of a shader waits for it to compile. Doing that now keeps the first frames of the transition.
            .task {
                let shader = DissolveShaderTransitionMath.shader(progress: 0, grain: grain, edge: edge)
                try? await shader.compile(as: .colorEffect)
            }
    }
}

// MARK: - Demo

struct DissolveShaderTransitionDemo: View {
    @State private var isShown = true

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                // An empty space of the same shape keeps the button still while the poster is gone.
                Color.clear
                    .aspectRatio(0.8, contentMode: .fit)
                    .overlay {
                        if isShown {
                            poster
                                .transition(.dissolveShader)
                        }
                    }

                Button(isShown ? "Dissolve" : "Restore") {
                    withAnimation(.easeInOut(duration: 1.5)) { isShown.toggle() }
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .animation(nil, value: isShown)
            }
            .padding(.horizontal, 36)
        }
    }

    private var poster: some View {
        VStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(.largeTitle, weight: .semibold))
                .imageScale(.large)
                .accessibilityHidden(true)

            Text("Ember")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Gone in a breath")
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 28)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DissolveShaderTransitionDemo()
}
