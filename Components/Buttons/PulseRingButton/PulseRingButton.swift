// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

private enum PulseRingButtonPhase {
    case rest, expanded
}

/// A round button with rings that keep radiating out from behind it.
///
/// With Reduce Motion on, a single still halo replaces the rings.
struct PulseRingButton: View {
    let systemImage: String
    let label: String
    var tint: Color = .red
    var ringCount: Int = 3
    var ringDuration: Double = 1.6
    var stagger: Double = 0.35
    let action: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var diameter = 104.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Group {
                if reduceMotion {
                    Circle()
                        .fill(tint.opacity(0.2))
                        .scaleEffect(1.35)
                } else {
                    ForEach(0..<ringCount, id: \.self) { index in
                        ring(at: index)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(width: diameter, height: diameter)
                    .background(tint.gradient, in: .circle)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        }
        .frame(width: diameter, height: diameter)
    }

    /// Every ring waits before growing and again before resetting, and the two
    /// delays add up to the same total, so all rings keep the same period.
    private func ring(at index: Int) -> some View {
        let startDelay = Double(index) * stagger
        let endDelay = Double(ringCount - 1 - index) * stagger

        return Circle()
            .fill(tint)
            .phaseAnimator([PulseRingButtonPhase.rest, .expanded]) { content, phase in
                content
                    .scaleEffect(phase == .expanded ? 2.5 : 1)
                    .opacity(phase == .expanded ? 0 : 0.55)
            } animation: { phase in
                phase == .expanded
                    ? .easeOut(duration: ringDuration).delay(startDelay)
                    : .linear(duration: 0.01).delay(endDelay)
            }
    }
}

// MARK: - Demo

struct PulseRingButtonDemo: View {
    @State private var isRecording = true

    var body: some View {
        PulseRingButton(systemImage: isRecording ? "mic.fill" : "mic.slash.fill", label: "Record") {
            isRecording.toggle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                Text(isRecording ? "Listening" : "Muted")
                    .font(.largeTitle.bold())
                Text("Tap to toggle the microphone")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .foregroundStyle(.white)
            .padding(.top, 72)
        }
        .background(Color(red: 0.1, green: 0.05, blue: 0.08).ignoresSafeArea())
    }
}

#Preview {
    PulseRingButtonDemo()
}
