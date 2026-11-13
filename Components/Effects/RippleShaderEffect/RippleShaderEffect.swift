// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Where a wave is at one instant: how far its crest has travelled and how strong it still is.
nonisolated struct RippleShaderEffectWave: Equatable {
    var radius = 0.0
    var strength = 0.0

    /// The same wave held at its origin. With no bending either, all it leaves is a light that fades.
    var still: RippleShaderEffectWave {
        RippleShaderEffectWave(radius: 0, strength: strength)
    }
}

nonisolated enum RippleShaderEffectMath {
    /// How far a wave from `origin` travels until all of it has left a view of `size`.
    static func reach(from origin: CGPoint, in size: CGSize, wavelength: Double) -> Double {
        let horizontal = max(abs(origin.x), abs(size.width - origin.x))
        let vertical = max(abs(origin.y), abs(size.height - origin.y))
        return hypot(horizontal, vertical) + max(wavelength, 0)
    }

    /// The seconds a wave takes to cover `reach` points. A wave that cannot move lasts one frame.
    static func travelTime(reach: Double, speed: Double) -> Double {
        let frame = 1.0 / 60.0
        guard speed > 0, reach.isFinite else { return frame }
        return max(reach / speed, frame)
    }

    /// The function in `RippleShaderEffect.metal`, with its arguments in the order it declares them.
    static func shader(wave: RippleShaderEffectWave, origin: CGPoint, amplitude: Double, wavelength: Double) -> Shader {
        ShaderLibrary.RippleShaderEffectDistortion(
            .boundingRect,
            .float2(origin),
            .float(wave.radius),
            .float(wave.strength),
            .float(amplitude),
            .float(max(wavelength, 1))
        )
    }
}

/// A wave that spreads from a point and bends the view as it passes, drawn by a Metal shader.
///
/// - Important: Copy two files into the same target: `RippleShaderEffect.swift` and `RippleShaderEffect.metal`.
///
/// `.rippleShaderEffect()` starts a wave wherever the view is tapped, and
/// `.rippleShaderEffect(at:trigger:)` starts one from code.
/// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map, shows a placeholder.
///
/// With Reduce Motion on, a soft light fades where the wave would start, and nothing moves.
struct RippleShaderEffect<Trigger: Equatable & Sendable>: ViewModifier {
    /// Where the wave starts, in the view's own coordinates.
    var origin: CGPoint
    var trigger: Trigger
    /// How many points the wave moves what is under it.
    var amplitude: Double = 10
    /// The width of the wave, in points.
    var wavelength: Double = 110
    /// Points per second.
    var speed: Double = 650

    @State private var size = CGSize.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let origin = origin
        let amplitude = amplitude
        let wavelength = wavelength
        let reduceMotion = reduceMotion
        let reach = RippleShaderEffectMath.reach(from: origin, in: size, wavelength: wavelength)
        let travel = RippleShaderEffectMath.travelTime(reach: reach, speed: speed)

        content
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .keyframeAnimator(initialValue: RippleShaderEffectWave(), trigger: trigger) { view, wave in
                view.layerEffect(
                    RippleShaderEffectMath.shader(
                        wave: reduceMotion ? wave.still : wave,
                        origin: origin,
                        amplitude: reduceMotion ? 0 : amplitude,
                        wavelength: wavelength
                    ),
                    maxSampleOffset: CGSize(width: abs(amplitude), height: abs(amplitude)),
                    isEnabled: wave.strength > 0
                )
            } keyframes: { _ in
                KeyframeTrack(\.radius) {
                    MoveKeyframe(0)
                    LinearKeyframe(reach, duration: travel)
                }
                KeyframeTrack(\.strength) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: travel * 0.35)
                    CubicKeyframe(0, duration: travel * 0.65)
                }
            }
            // The first use of a shader waits for it to compile. Doing that now keeps the first wave on time.
            .task {
                let shader = RippleShaderEffectMath.shader(wave: RippleShaderEffectWave(), origin: .zero, amplitude: 0, wavelength: 1)
                try? await shader.compile(as: .layerEffect)
            }
    }
}

private struct RippleShaderEffectOnTap: ViewModifier {
    let amplitude: Double
    let wavelength: Double
    let speed: Double

    @State private var origin = CGPoint.zero
    @State private var taps = 0

    func body(content: Content) -> some View {
        content
            .modifier(RippleShaderEffect(origin: origin, trigger: taps, amplitude: amplitude, wavelength: wavelength, speed: speed))
            .contentShape(.rect)
            .simultaneousGesture(
                SpatialTapGesture().onEnded { tap in
                    origin = tap.location
                    taps += 1
                }
            )
    }
}

extension View {
    /// Starts a wave wherever this view is tapped, without blocking its own controls.
    func rippleShaderEffect(amplitude: Double = 10, wavelength: Double = 110, speed: Double = 650) -> some View {
        modifier(RippleShaderEffectOnTap(amplitude: amplitude, wavelength: wavelength, speed: speed))
    }

    /// Starts a wave at `origin`, in this view's own coordinates, every time `trigger` changes.
    func rippleShaderEffect(
        at origin: CGPoint,
        trigger: some Equatable & Sendable,
        amplitude: Double = 10,
        wavelength: Double = 110,
        speed: Double = 650
    ) -> some View {
        modifier(RippleShaderEffect(origin: origin, trigger: trigger, amplitude: amplitude, wavelength: wavelength, speed: speed))
    }
}

// MARK: - Demo

struct RippleShaderEffectDemo: View {
    var body: some View {
        ZStack {
            RippleShaderEffectDemoTiles()

            VStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Tap the Water")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        }
        .rippleShaderEffect()
        .ignoresSafeArea()
    }
}

/// The floor of a pool: a grid whose straight lines show how the wave bends them.
private struct RippleShaderEffectDemoTiles: View {
    var body: some View {
        Canvas { context, size in
            let side = 46.0
            let columns = Int((size.width / side).rounded(.up))
            let rows = Int((size.height / side).rounded(.up))

            for row in 0..<rows {
                for column in 0..<columns {
                    let tile = CGRect(x: Double(column) * side, y: Double(row) * side, width: side, height: side)
                    let shade = Double((row * 7 + column * 13) % 5) / 4
                    let color = Color(hue: 0.52 + 0.03 * shade, saturation: 0.7, brightness: 0.72 + 0.2 * shade)
                    context.fill(Path(roundedRect: tile.insetBy(dx: 2, dy: 2), cornerRadius: 6), with: .color(color))
                }
            }
        }
        .background(Color(hue: 0.56, saturation: 0.8, brightness: 0.42))
        .accessibilityHidden(true)
    }
}

#Preview {
    RippleShaderEffectDemo()
}
