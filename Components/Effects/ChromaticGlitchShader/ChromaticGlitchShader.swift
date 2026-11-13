// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum ChromaticGlitchShaderMath {
    /// The farthest a color channel moves from its place, in points.
    static let split = 7.0
    /// The farthest a band moves sideways, in points.
    static let shift = 26.0

    static func clamped(_ amount: Double) -> Double {
        guard amount.isFinite else { return 0 }
        return min(max(amount, 0), 1)
    }

    /// How far from a point the shader reads, which SwiftUI has to know beforehand.
    static func reach(amount: Double) -> Double {
        (split + shift) * clamped(amount)
    }

    /// The function in `ChromaticGlitchShader.metal`, with its arguments in the order it declares them.
    static func shader(amount: Double, time: Double, bounds: CGSize) -> Shader {
        ShaderLibrary.ChromaticGlitchShaderSplit(.float(clamped(amount)), .float(time), .float(split), .float(shift), .float2(bounds))
    }
}

extension View {
    /// Breaks this view up like a bad signal, by a Metal shader: its colors come apart, some
    /// bands jump sideways and scan lines cross it. `amount` goes from 0, untouched, to 1, and
    /// animates.
    ///
    /// - Important: Copy two files into the same target: `ChromaticGlitchShader.swift` and `ChromaticGlitchShader.metal`.
    ///
    /// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map, shows a placeholder.
    ///
    /// The bands change ten times a second. With Reduce Motion on they stand still, and only
    /// the colors come apart. It only changes how the view looks, not what VoiceOver reads.
    func chromaticGlitch(_ amount: Double) -> some View {
        modifier(ChromaticGlitchShaderModifier(amount: amount))
    }
}

/// `Animatable`, so the shader gets every step of the change: a shader's arguments do not animate by themselves.
private struct ChromaticGlitchShaderModifier: ViewModifier, Animatable {
    var amount: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    func body(content: Content) -> some View {
        let strength = ChromaticGlitchShaderMath.clamped(amount)
        let reach = ChromaticGlitchShaderMath.reach(amount: strength)

        // The clock only runs while there is something to move.
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || strength == 0)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 600)

            content
                // `visualEffect` gives the shader the size of the view, which it needs at the edges.
                .visualEffect { view, proxy in
                    view.layerEffect(
                        ChromaticGlitchShaderMath.shader(amount: strength, time: time, bounds: proxy.size),
                        maxSampleOffset: CGSize(width: reach, height: 0),
                        isEnabled: strength > 0
                    )
                }
        }
        // The first use of a shader waits for it to compile. Doing that now keeps the first frames smooth.
        .task {
            try? await ChromaticGlitchShaderMath.shader(amount: 1, time: 0, bounds: .zero).compile(as: .layerEffect)
        }
    }
}

// MARK: - Demo

struct ChromaticGlitchShaderDemo: View {
    @State private var amount = 0.0

    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 64, weight: .semibold))
                    .accessibilityHidden(true)
                Text("SIGNAL LOST")
                    .font(.system(.largeTitle, design: .monospaced, weight: .heavy))
                Text("Reconnecting to channel 7")
                    .font(.system(.subheadline, design: .monospaced))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 44)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 28))
            .chromaticGlitch(amount)

            VStack(alignment: .leading, spacing: 6) {
                Text("Glitch")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Slider(value: $amount, in: 0...1)
                    .tint(.cyan)
                    .accessibilityLabel("Glitch")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.04, blue: 0.09).ignoresSafeArea())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task {
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled, isAutoPlaying else { return }
                withAnimation(reduceMotion ? nil : .easeIn(duration: 0.25)) { amount = 1 }

                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled, isAutoPlaying else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) { amount = 0 }
            }
        }
    }
}

#Preview {
    ChromaticGlitchShaderDemo()
}
