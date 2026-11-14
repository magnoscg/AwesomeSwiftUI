// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A settings row like the ones in the Settings app: a symbol on a colored
/// rounded square, a title, an optional subtitle and a switch. It is a plain
/// `Toggle`, so it works in a `List` or a `Form` and reads as one switch in VoiceOver.
///
/// The symbol bounces when the switch turns on, except with Reduce Motion on.
struct SettingsToggleRow: View {
    let title: LocalizedStringResource
    var subtitle: LocalizedStringResource?
    let systemImage: String
    var iconColor: Color = .blue
    @Binding var isOn: Bool

    @State private var bounces = 0
    @ScaledMetric(relativeTo: .body) private var iconSize = 30.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize * 0.55, weight: .semibold))
                    .foregroundStyle(SettingsToggleRowContrastingForeground(background: iconColor))
                    .symbolEffect(.bounce, value: bounces)
                    .frame(width: iconSize, height: iconSize)
                    .background(iconColor.gradient, in: .rect(cornerRadius: iconSize * 0.26, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: isOn) { _, on in
            if on, !reduceMotion { bounces += 1 }
        }
    }
}

nonisolated struct SettingsToggleRowContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct SettingsToggleRowDemo: View {
    @State private var airplaneMode = false
    @State private var wifi = true
    @State private var bluetooth = true
    @State private var doNotDisturb = false
    @State private var lowPower = false
    @State private var previews = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingsToggleRow(title: "Airplane Mode", systemImage: "airplane", iconColor: .orange, isOn: $airplaneMode)
                    SettingsToggleRow(title: "Wi-Fi", systemImage: "wifi", isOn: $wifi)
                    SettingsToggleRow(title: "Bluetooth", systemImage: "antenna.radiowaves.left.and.right", isOn: $bluetooth)
                }

                Section {
                    SettingsToggleRow(
                        title: "Do Not Disturb",
                        subtitle: "Silence calls and alerts",
                        systemImage: "moon.fill",
                        iconColor: .indigo,
                        isOn: $doNotDisturb
                    )
                    SettingsToggleRow(
                        title: "Low Power Mode",
                        subtitle: "Reduce background activity",
                        systemImage: "battery.25percent",
                        iconColor: .yellow,
                        isOn: $lowPower
                    )
                    SettingsToggleRow(title: "Show Previews", systemImage: "text.bubble.fill", iconColor: .green, isOn: $previews)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsToggleRowDemo()
}
