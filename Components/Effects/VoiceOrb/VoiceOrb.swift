// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

nonisolated enum VoiceOrbState: String, CaseIterable, Sendable {
    case idle = "Idle"
    case listening = "Listening"
    case thinking = "Thinking"
    case speaking = "Speaking"
}

nonisolated enum VoiceOrbMath {
    /// How lively the orb is, from 0 to 1. At rest it barely moves, thinking keeps it halfway,
    /// and while it listens or speaks it follows the level of the voice.
    static func energy(state: VoiceOrbState, level: Double) -> Double {
        let level = level.isFinite ? min(max(level, 0), 1) : 0
        switch state {
        case .idle: return 0.1
        case .thinking: return 0.5
        case .listening, .speaking: return 0.25 + 0.75 * level
        }
    }

    /// How big the orb is drawn for an energy: it swells with the voice.
    static func scale(energy: Double) -> Double {
        0.86 + 0.14 * min(max(energy, 0), 1)
    }

    /// Where a blob of color is inside the orb, with the orb as a circle of radius 1 around zero.
    /// The blobs circle its center, every other one the opposite way, and reach further out the
    /// livelier the orb is.
    static func blobCenter(index: Int, count: Int, time: Double, energy: Double) -> CGPoint {
        let phase = Double(index) / Double(max(count, 1))
        let turns = time * (index.isMultiple(of: 2) ? 0.3 : -0.2) + phase
        let reach = 0.2 + 0.3 * min(max(energy, 0), 1)
        return CGPoint(x: cos(turns * 2 * .pi) * reach, y: sin(turns * 2 * .pi) * reach)
    }
}

/// A glowing orb for a voice assistant: colors swirl inside it, and it swells with the voice
/// while it listens or speaks.
///
/// Give it the level of the voice from 0 to 1, from your own audio code: the orb asks for no
/// microphone. With Reduce Motion on, the colors stay still and the orb brightens instead of
/// swelling.
struct VoiceOrb: View {
    var state = VoiceOrbState.idle
    /// How loud the voice is, from 0 to 1.
    var level = 0.0
    var colors: [Color] = [.blue, .purple, .pink, .cyan]
    var label = "Assistant"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let energy = VoiceOrbMath.energy(state: state, level: level)

        VoiceOrbSurface(energy: energy, colors: colors, isStill: reduceMotion)
            .scaleEffect(reduceMotion ? 1 : VoiceOrbMath.scale(energy: energy))
            .brightness(reduceMotion ? energy * 0.2 : 0)
            .saturation(state == .idle ? 0.6 : 1)
            .hueRotation(.degrees(state == .speaking ? 40 : 0))
            .animation(.spring(duration: 0.35), value: energy)
            .animation(.easeInOut(duration: 0.5), value: state)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(state.rawValue)
    }
}

/// The inside of the orb. Its energy is animatable, so the blobs glide to their new reach when the
/// state changes instead of jumping.
private struct VoiceOrbSurface: View, Animatable {
    var energy: Double
    let colors: [Color]
    let isStill: Bool

    nonisolated var animatableData: Double {
        get { energy }
        set { energy = newValue }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isStill)) { timeline in
            let time = isStill ? 0 : timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let radius = min(size.width, size.height) / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let orb = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

                context.clip(to: Path(ellipseIn: orb))
                context.fill(Path(ellipseIn: orb), with: .color(colors.first ?? .blue))

                var blurred = context
                blurred.addFilter(.blur(radius: radius * 0.28))
                for (index, color) in colors.enumerated() {
                    let unit = VoiceOrbMath.blobCenter(index: index, count: colors.count, time: time, energy: energy)
                    let blob = CGRect(x: center.x + unit.x * radius - radius * 0.6, y: center.y + unit.y * radius - radius * 0.6, width: radius * 1.2, height: radius * 1.2)
                    blurred.fill(Path(ellipseIn: blob), with: .color(color))
                }

                // A soft light from the top, so the orb reads as a sphere.
                context.fill(Path(ellipseIn: orb), with: .radialGradient(
                    Gradient(colors: [.white.opacity(0.45), .clear]),
                    center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.4),
                    startRadius: 0,
                    endRadius: radius * 1.1
                ))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: (colors.first ?? .blue).opacity(0.25 + 0.45 * energy), radius: 30)
    }
}

// MARK: - Demo

struct VoiceOrbDemo: View {
    @State private var state = VoiceOrbState.idle
    @State private var level = 0.0

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            VoiceOrb(state: state, level: level)
                .frame(width: 220, height: 220)

            Text(caption)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: state)

            Spacer()

            Picker("State", selection: $state) {
                ForEach(VoiceOrbState.allCases, id: \.self) { state in
                    Text(state.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task(id: state) {
            // Stands in for the level a microphone or a speech synthesizer would give.
            guard state == .listening || state == .speaking else {
                level = 0
                return
            }
            while !Task.isCancelled {
                level = Double.random(in: state == .speaking ? 0.3...1 : 0.1...0.9)
                try? await Task.sleep(for: .milliseconds(160))
            }
        }
    }

    private var caption: String {
        switch state {
        case .idle: "Tap a state to try it"
        case .listening: "I’m listening…"
        case .thinking: "Let me think…"
        case .speaking: "Here’s what I found"
        }
    }
}

#Preview {
    VoiceOrbDemo()
}
