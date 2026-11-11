// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A switch whose icon morphs between a sun and a moon while the sky behind it changes.
/// VoiceOver reads it as a standard switch.
///
/// With Reduce Motion on, it changes without sliding.
struct DayNightToggle: View {
    @Binding var isNight: Bool
    var title: String = "Night mode"

    var body: some View {
        Toggle(title, isOn: $isNight)
            .toggleStyle(DayNightToggleStyle())
    }
}

private struct DayNightToggleStyle: ToggleStyle {
    @ScaledMetric(relativeTo: .title) private var height = 56.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let day = LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
    private static let night = LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)

    func makeBody(configuration: Configuration) -> some View {
        let isNight = configuration.isOn
        let knob = height - 8

        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack {
                Capsule().fill(Self.day)
                Capsule().fill(Self.night).opacity(isNight ? 1 : 0)

                scenery(isNight: isNight, knob: knob)
                    .padding(.horizontal, height * 0.3)

                Circle()
                    .fill(isNight ? Color(white: 0.88) : Color.white)
                    .frame(width: knob, height: knob)
                    .overlay {
                        Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: knob * 0.56))
                            .foregroundStyle(isNight ? Color.indigo : Color.orange)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .frame(maxWidth: .infinity, alignment: isNight ? .trailing : .leading)
                    .padding(4)
            }
            .frame(width: height * 2.2, height: height)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.25), value: isNight)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
        }
    }

    /// Stars sit where the knob is not at night, and a cloud does the same by day.
    private func scenery(isNight: Bool, knob: CGFloat) -> some View {
        ZStack {
            HStack(spacing: knob * 0.14) {
                Image(systemName: "sparkle").font(.system(size: knob * 0.3))
                Image(systemName: "sparkle").font(.system(size: knob * 0.18)).offset(y: -knob * 0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isNight ? 1 : 0)

            Image(systemName: "cloud.fill")
                .font(.system(size: knob * 0.44))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(isNight ? 0 : 1)
        }
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
}

// MARK: - Demo

struct DayNightToggleDemo: View {
    @State private var isNight = false
    @State private var lastAutoValue = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.cyan.opacity(0.55), .white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(isNight ? 1 : 0)

            ScrollView {
                VStack(spacing: 24) {
                    Text(isNight ? "Good night" : "Good morning")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(isNight ? Color.white : Color.primary)
                        .contentTransition(.opacity)

                    DayNightToggle(isNight: $isNight)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center, for: .alignment)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.55), value: isNight)
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }

            while isNight == lastAutoValue {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled, isNight == lastAutoValue else { return }
                lastAutoValue.toggle()
                isNight = lastAutoValue
            }
        }
    }
}

#Preview {
    DayNightToggleDemo()
}
