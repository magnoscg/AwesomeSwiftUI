// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum PixelateShaderEffectMath {
    /// The side of the blocks for an amount of pixelation: one point, which changes nothing, at
    /// 0, and `maximum` at 1.
    static func blockSize(amount: Double, maximum: Double) -> Double {
        guard amount.isFinite else { return 1 }
        return 1 + (max(maximum, 1) - 1) * min(max(amount, 0), 1)
    }

    /// The center of the block a point falls in, which gives its color to the whole block.
    /// The shader does the same sum.
    static func blockCenter(of point: CGPoint, size: Double) -> CGPoint {
        guard size > 1 else { return point }
        return CGPoint(x: ((point.x / size).rounded(.down) + 0.5) * size, y: ((point.y / size).rounded(.down) + 0.5) * size)
    }

    /// The function in `PixelateShaderEffect.metal`, with its arguments in the order it declares them.
    static func shader(size: Double, bounds: CGSize) -> Shader {
        ShaderLibrary.PixelateShaderEffectBlocks(.float(size), .float2(bounds))
    }
}

extension View {
    /// Draws this view in big square blocks, like a censored picture, by a Metal shader.
    /// `amount` goes from 0, untouched, to 1, in blocks of `blockSize` points, and animates:
    /// the blocks shrink until the view comes into focus.
    ///
    /// Copy two files into the same target: `PixelateShaderEffect.swift` and `PixelateShaderEffect.metal`.
    /// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map, shows a placeholder.
    ///
    /// It only changes how the view looks: hide it from VoiceOver yourself while it is a secret.
    /// With Reduce Motion on, the view goes from blocks to sharp in one step.
    func pixelate(_ amount: Double, blockSize: CGFloat = 22) -> some View {
        modifier(PixelateShaderEffectModifier(amount: amount, blockSize: blockSize))
    }
}

/// `Animatable`, so the shader gets every step of the change: a shader's arguments do not animate by themselves.
private struct PixelateShaderEffectModifier: ViewModifier, Animatable {
    var amount: Double
    let blockSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    func body(content: Content) -> some View {
        // With Reduce Motion the blocks do not shrink step by step: they are there or they are not.
        let shown = reduceMotion ? (amount > 0.5 ? 1 : 0) : amount
        let size = PixelateShaderEffectMath.blockSize(amount: shown, maximum: blockSize)

        content
            // `visualEffect` gives the shader the size of the view, which it needs at the edges.
            .visualEffect { view, proxy in
                view.layerEffect(
                    PixelateShaderEffectMath.shader(size: size, bounds: proxy.size),
                    maxSampleOffset: CGSize(width: size, height: size),
                    isEnabled: size > 1
                )
            }
            // The first use of a shader waits for it to compile. Doing that now keeps the first frames smooth.
            .task {
                try? await PixelateShaderEffectMath.shader(size: blockSize, bounds: .zero).compile(as: .layerEffect)
            }
    }
}

// MARK: - Demo

struct PixelateShaderEffectDemo: View {
    @State private var isHidden = true

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    LinearGradient(colors: [.indigo, .purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 84))
                        .foregroundStyle(.yellow.gradient)
                        .shadow(radius: 8)
                }
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 18))

                Text("Season finale")
                    .font(.title2.bold())
                Text("Rivera wins the final in the last minute, after trailing for the whole second half.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background, in: .rect(cornerRadius: 26))
            .pixelate(isHidden ? 1 : 0)
            .accessibilityElement(children: .combine)
            .accessibilityHidden(isHidden)

            Button(isHidden ? "Reveal Spoiler" : "Hide Again", systemImage: isHidden ? "eye.fill" : "eye.slash.fill") {
                withAnimation(.easeInOut(duration: 0.8)) { isHidden.toggle() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PixelateShaderEffectDemo()
}
