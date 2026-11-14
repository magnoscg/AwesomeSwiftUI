// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A gradient capsule button with a band of light that sweeps across it in a loop.
///
/// With Reduce Motion on, the sweep is removed and the button stays still.
struct ShimmerButton: View {
    let title: LocalizedStringResource
    var systemImage: String?
    var colors: [Color] = [.indigo, .purple]
    var sweepDuration: Double = 1.1
    var pause: Double = 0.9
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .font(.title3.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .overlay {
                if !reduceMotion {
                    sweep
                }
            }
            .clipShape(.capsule)
            .contentShape(.capsule)
            .shadow(color: (colors.first ?? .clear).opacity(0.5), radius: 18, y: 8)
        }
        .buttonStyle(ShimmerButtonPressStyle(reduceMotion: reduceMotion))
    }

    private var sweep: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.65), .clear], startPoint: .leading, endPoint: .trailing)
            .scaleEffect(x: 0.4, y: 2.5)
            .rotationEffect(.degrees(20))
            .keyframeAnimator(initialValue: -1.1, repeating: true) { content, position in
                content.visualEffect { effect, proxy in
                    effect.offset(x: position * proxy.size.width)
                }
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(1.1, duration: sweepDuration)
                    LinearKeyframe(1.1, duration: pause)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The button dims and shrinks a little while it is pressed.
private struct ShimmerButtonPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Demo

struct ShimmerButtonDemo: View {
    @State private var isStarted = false

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 10) {
                Text("Unlock everything")
                    .font(.largeTitle.bold())
                Text("Every feature, free for a week.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
            }

            ShimmerButton(
                title: isStarted ? "Trial started" : "Start free trial",
                systemImage: isStarted ? "checkmark" : "sparkles"
            ) {
                isStarted.toggle()
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.06, blue: 0.16).ignoresSafeArea())
    }
}

#Preview {
    ShimmerButtonDemo()
}
