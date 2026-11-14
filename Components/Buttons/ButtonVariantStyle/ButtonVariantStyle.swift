// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A button style with four variants that reads its size, its enabled state and
/// its role from the environment, like the system styles: `.controlSize(.small)`
/// makes it small, `.disabled(true)` fades it, and a destructive role turns it red.
///
/// With Reduce Motion on, a press dims the button instead of shrinking it.
struct ButtonVariantStyle: ButtonStyle {
    enum Variant {
        case filled, tinted, outlined, plain
    }

    var variant: Variant = .filled
    var color: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        ButtonVariantStyleBody(
            configuration: configuration,
            variant: variant,
            color: configuration.role == .destructive ? .red : color
        )
    }
}

extension ButtonStyle where Self == ButtonVariantStyle {
    static func variant(_ variant: ButtonVariantStyle.Variant, color: Color = .accentColor) -> ButtonVariantStyle {
        ButtonVariantStyle(variant: variant, color: color)
    }
}

private struct ButtonVariantStyleBody: View {
    let configuration: ButtonStyleConfiguration
    let variant: ButtonVariantStyle.Variant
    let color: Color

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var metrics: (font: Font, horizontal: Double, vertical: Double, cornerRadius: Double) {
        switch controlSize {
        case .mini, .small: (.subheadline.weight(.semibold), 12, 7, 10)
        case .large, .extraLarge: (.title3.weight(.semibold), 24, 16, 16)
        default: (.body.weight(.semibold), 18, 12, 12)
        }
    }

    /// The small size is shorter than 44 points, so only its touch area grows.
    private var touchSlop: Double {
        controlSize == .mini || controlSize == .small ? 6 : 0
    }

    private var foreground: AnyShapeStyle {
        variant == .filled ? AnyShapeStyle(ButtonVariantStyleContrastingForeground(background: color)) : AnyShapeStyle(color)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
        let isPressed = configuration.isPressed

        configuration.label
            .font(metrics.font)
            .foregroundStyle(foreground)
            .padding(.horizontal, metrics.horizontal)
            .padding(.vertical, metrics.vertical)
            .background {
                switch variant {
                case .filled:
                    shape.fill(color).brightness(isPressed ? -0.08 : 0)
                case .tinted:
                    shape.fill(color.opacity(isPressed ? 0.25 : 0.15))
                case .outlined, .plain:
                    shape.fill(color.opacity(isPressed ? 0.12 : 0))
                }
            }
            .overlay {
                if variant == .outlined {
                    shape.strokeBorder(color, lineWidth: 1.5)
                }
            }
            .padding(.vertical, touchSlop)
            .contentShape(.rect)
            .padding(.vertical, -touchSlop)
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(isEnabled ? (isPressed && reduceMotion ? 0.7 : 1) : 0.4)
            .animation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0.4), value: isPressed)
    }
}

nonisolated struct ButtonVariantStyleContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct ButtonVariantStyleDemo: View {
    @State private var controlSize = ControlSize.regular
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Picker("Size", selection: $controlSize) {
                    Text("Small").tag(ControlSize.small)
                    Text("Medium").tag(ControlSize.regular)
                    Text("Large").tag(ControlSize.large)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 16) {
                    Button {} label: {
                        Text("Continue").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.variant(.filled))

                    rowLayout {
                        Button("Save", systemImage: "bookmark") {}
                            .buttonStyle(.variant(.tinted))
                        Button("Share", systemImage: "square.and.arrow.up") {}
                            .buttonStyle(.variant(.outlined))
                    }

                    Button("Not Now") {}
                        .buttonStyle(.variant(.plain))

                    Divider()

                    rowLayout {
                        Button("Delete", role: .destructive) {}
                            .buttonStyle(.variant(.filled))
                        Button("Remove", role: .destructive) {}
                            .buttonStyle(.variant(.tinted))
                    }

                    rowLayout {
                        Button("Follow") {}
                            .buttonStyle(.variant(.filled, color: .orange))
                        Button("Sold Out") {}
                            .buttonStyle(.variant(.filled))
                            .disabled(true)
                    }
                }
                .controlSize(controlSize)
                .padding(20)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 24, style: .continuous))
            }
            .padding(20)
            .animation(reduceMotion ? nil : .snappy, value: controlSize)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    ButtonVariantStyleDemo()
}
