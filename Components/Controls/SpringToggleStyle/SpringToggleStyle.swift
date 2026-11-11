// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A toggle whose knob widens under your finger and overshoots as it lands.
/// The whole row is tappable, and VoiceOver reads it as a standard switch.
///
/// With Reduce Motion on, the knob slides without bouncing or widening.
struct SpringToggleStyle: ToggleStyle {
    var onColor: Color = .green

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(SpringToggleStyleRow(isOn: configuration.isOn, onColor: onColor))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
        }
    }
}

extension ToggleStyle where Self == SpringToggleStyle {
    static var spring: SpringToggleStyle { SpringToggleStyle() }
}

private struct SpringToggleStyleRow: ButtonStyle {
    let isOn: Bool
    let onColor: Color

    @ScaledMetric(relativeTo: .body) private var trackHeight = 34.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let knobInset = 3.0

    private var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.45, bounce: 0.55)
    }

    func makeBody(configuration: Configuration) -> some View {
        let isSquashed = configuration.isPressed && !reduceMotion
        let knobHeight = trackHeight - knobInset * 2

        HStack(spacing: 16) {
            configuration.label

            Capsule()
                .fill(isOn ? onColor : Color.gray.opacity(0.35))
                .frame(width: trackHeight * 1.75, height: trackHeight)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                        .frame(width: isSquashed ? knobHeight * 1.3 : knobHeight, height: knobHeight)
                        .padding(knobInset)
                }
        }
        .animation(animation, value: isOn)
        .animation(animation, value: isSquashed)
    }
}

// MARK: - Demo

struct SpringToggleStyleDemo: View {
    @State private var notifications = false
    @State private var sounds = true
    @State private var haptics = false

    var body: some View {
        VStack(spacing: 28) {
            Toggle(isOn: $notifications) { Label("Notifications", systemImage: "bell.fill") }
            Toggle(isOn: $sounds) { Label("Sounds", systemImage: "speaker.wave.2.fill") }
            Toggle(isOn: $haptics) { Label("Haptics", systemImage: "iphone.radiowaves.left.and.right") }
        }
        .toggleStyle(.spring)
        .font(.title3.weight(.medium))
        .padding(24)
        .background(.background, in: .rect(cornerRadius: 28))
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    SpringToggleStyleDemo()
}
