// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A switch whose knob carries a symbol for each state, a checkmark and a cross
/// by default, that swaps as the knob slides. The state reads without relying
/// on the track color alone. The whole row is tappable, and VoiceOver reads it
/// as a standard switch.
///
/// With Reduce Motion on, the knob slides without bouncing and the symbols crossfade.
struct IconSwitchToggleStyle: ToggleStyle {
    var onSymbol = "checkmark"
    var offSymbol = "xmark"
    var color: Color = .green

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                IconSwitchToggleStyleTrack(
                    isOn: configuration.isOn,
                    symbol: configuration.isOn ? onSymbol : offSymbol,
                    color: color
                )
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
        }
    }
}

extension ToggleStyle where Self == IconSwitchToggleStyle {
    static var iconSwitch: IconSwitchToggleStyle { IconSwitchToggleStyle() }

    static func iconSwitch(on onSymbol: String, off offSymbol: String, color: Color = .green) -> IconSwitchToggleStyle {
        IconSwitchToggleStyle(onSymbol: onSymbol, offSymbol: offSymbol, color: color)
    }
}

private struct IconSwitchToggleStyleTrack: View {
    let isOn: Bool
    let symbol: String
    let color: Color

    @ScaledMetric(relativeTo: .body) private var height = 32.0
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let inset = 3.0

    var body: some View {
        let knob = height - inset * 2

        Capsule()
            .fill(isOn ? color : Color.secondary.opacity(0.35))
            .frame(width: height * 1.8, height: height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: knob * 0.45, weight: .bold))
                            .foregroundStyle(isOn ? color : Color.gray)
                            .contentTransition(reduceMotion ? .opacity : .symbolEffect(.replace))
                    }
                    .frame(width: knob, height: knob)
                    .padding(inset)
            }
            .opacity(isEnabled ? 1 : 0.4)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.35), value: isOn)
            .accessibilityHidden(true)
    }
}

// MARK: - Demo

struct IconSwitchToggleStyleDemo: View {
    @State private var autoUpdates = true
    @State private var darkMode = false
    @State private var sound = true
    @State private var location = false

    var body: some View {
        VStack(spacing: 8) {
            Toggle("Automatic Updates", isOn: $autoUpdates)
                .toggleStyle(.iconSwitch)
            Toggle("Dark Mode", isOn: $darkMode)
                .toggleStyle(.iconSwitch(on: "moon.fill", off: "sun.max.fill", color: .indigo))
            Toggle("Sound", isOn: $sound)
                .toggleStyle(.iconSwitch(on: "speaker.wave.2.fill", off: "speaker.slash.fill", color: .orange))
            Toggle("Share Location", isOn: $location)
                .toggleStyle(.iconSwitch(on: "location.fill", off: "location.slash.fill", color: .blue))
        }
        .font(.body.weight(.medium))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 24, style: .continuous))
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    IconSwitchToggleStyleDemo()
}
