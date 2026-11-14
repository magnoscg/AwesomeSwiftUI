// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A checkbox for any `Toggle`: a rounded box that fills and draws its checkmark
/// when turned on, and shows a dash when a `Toggle(sources:isOn:)` is mixed.
/// The whole row is tappable, and VoiceOver reads it as a standard switch.
///
/// It is not called `CheckboxToggleStyle` because SwiftUI already has one, for
/// macOS only, and the two names would collide in a multiplatform app.
/// With Reduce Motion on, the checkmark appears without being drawn.
struct CheckmarkBoxToggleStyle: ToggleStyle {
    var color: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn = configuration.isMixed ? true : !configuration.isOn
        } label: {
            HStack(alignment: .top, spacing: 12) {
                CheckmarkBoxToggleStyleBox(isOn: configuration.isOn, isMixed: configuration.isMixed, color: color)
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            if configuration.isMixed {
                Toggle(isOn: configuration.$isOn) { configuration.label }
                    .accessibilityValue(Text("Mixed"))
            } else {
                Toggle(isOn: configuration.$isOn) { configuration.label }
            }
        }
    }
}

extension ToggleStyle where Self == CheckmarkBoxToggleStyle {
    static var checkmarkBox: CheckmarkBoxToggleStyle { CheckmarkBoxToggleStyle() }
}

private struct CheckmarkBoxToggleStyleBox: View {
    let isOn: Bool
    let isMixed: Bool
    let color: Color

    @ScaledMetric(relativeTo: .body) private var size = 22.0
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFilled: Bool { isOn || isMixed }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        let mark = CheckmarkBoxToggleStyleContrastingForeground(background: color)
        let lineWidth = size * 0.12

        ZStack {
            shape.fill(isFilled ? color : .clear)
            shape.strokeBorder(isFilled ? color : Color.secondary.opacity(0.6), lineWidth: lineWidth)

            if isMixed {
                Capsule()
                    .fill(mark)
                    .frame(width: size * 0.5, height: lineWidth)
                    .transition(.opacity)
            } else {
                CheckmarkBoxToggleStyleCheck()
                    .trim(from: 0, to: isOn ? 1 : 0)
                    .stroke(mark, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        // A checkmark is not mirrored right-to-left, like the system symbol.
        .environment(\.layoutDirection, .leftToRight)
        .scaleEffect(isFilled && !reduceMotion ? 1 : 0.94)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.45), value: isFilled)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isOn)
        .animation(.easeInOut(duration: 0.15), value: isMixed)
    }
}

nonisolated struct CheckmarkBoxToggleStyleCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.26, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.69))
        path.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.33))
        return path
    }
}

nonisolated struct CheckmarkBoxToggleStyleContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct CheckmarkBoxToggleStyleDemo: View {
    @State private var remember = true
    @State private var newsletter = false
    @State private var terms = false
    @State private var toppings = [false, true, false]

    private let toppingNames: [LocalizedStringResource] = ["Cheese", "Mushrooms", "Olives"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create Account")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Remember me", isOn: $remember)
                    Toggle("Email me about new features", isOn: $newsletter)
                    Toggle("I agree to the Terms of Service and the Privacy Policy", isOn: $terms)
                    Toggle("Two-factor authentication (coming soon)", isOn: .constant(false))
                        .disabled(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("All toppings", sources: $toppings, isOn: \.self)
                        .font(.headline)
                    ForEach(toppings.indices, id: \.self) { index in
                        Toggle(isOn: $toppings[index]) { Text(toppingNames[index]) }
                            .padding(.leading, 34)
                    }
                }
                .toggleStyle(CheckmarkBoxToggleStyle(color: .orange))
            }
            .toggleStyle(.checkmarkBox)
            .padding(24)
        }
    }
}

#Preview {
    CheckmarkBoxToggleStyleDemo()
}
