// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct PermissionPrimerScreenBenefit: Identifiable {
    let systemImage: String
    let title: LocalizedStringResource
    let text: LocalizedStringResource

    var id: String { systemImage }
}

/// The screen an app shows before the system asks for a permission: what it is for, what the
/// person gets, and one button that leads to the system's question.
///
/// Ask for the permission in `onContinue`. Pass `skipTitle` as nil where the only way on has
/// to be the system's question, as Apple asks before the tracking prompt. With Reduce Motion
/// on, the rings stand still and the benefits appear together.
struct PermissionPrimerScreen: View {
    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let benefits: [PermissionPrimerScreenBenefit]
    var continueTitle: LocalizedStringResource = "Continue"
    var skipTitle: LocalizedStringResource? = "Not Now"
    var tint: Color = .blue
    let onContinue: () -> Void
    var onSkip: () -> Void = {}

    @State private var hasAppeared = false
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = 96.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minimumTarget: CGFloat = 44

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                hero

                VStack(spacing: 10) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                        row(benefit)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared || reduceMotion ? 0 : 18)
                            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.2).delay(0.2 + 0.12 * Double(index)), value: hasAppeared)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) { buttons }
        .onAppear { hasAppeared = true }
    }

    private var hero: some View {
        Image(systemName: systemImage)
            .font(.system(size: heroSize * 0.44, weight: .semibold))
            .foregroundStyle(PermissionPrimerScreenContrastingForeground(background: tint))
            .frame(width: heroSize, height: heroSize)
            .background(tint.gradient, in: .circle)
            .background {
                if !reduceMotion {
                    ForEach(0..<2, id: \.self) { ring in
                        Circle()
                            .stroke(tint, lineWidth: 2)
                            .phaseAnimator([false, true]) { content, isWide in
                                content
                                    .scaleEffect(isWide ? 1.7 : 1)
                                    .opacity(isWide ? 0 : 0.5)
                            } animation: { isWide in
                                isWide ? .easeOut(duration: 2).delay(Double(ring) * 0.7) : .linear(duration: 0.01).delay(Double(1 - ring) * 0.7)
                            }
                    }
                }
            }
            .padding(.vertical, heroSize * 0.3)
            .accessibilityHidden(true)
    }

    private func row(_ benefit: PermissionPrimerScreenBenefit) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: benefit.systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(.headline)
                Text(benefit.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        VStack(spacing: 4) {
            Button(action: onContinue) {
                Text(continueTitle)
                    .font(.headline)
                    .foregroundStyle(PermissionPrimerScreenContrastingForeground(background: tint))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(tint.gradient, in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            if let skipTitle {
                Button(action: onSkip) {
                    Text(skipTitle)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: minimumTarget)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct PermissionPrimerScreenContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct PermissionPrimerScreenDemo: View {
    private enum Answer {
        case allowed, later
    }

    @State private var answer: Answer?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let answer {
                // Only for this demo: what came of the choice, and a way back to the screen.
                ContentUnavailableView {
                    Label(answer == .allowed ? "The system would ask now" : "Maybe later", systemImage: answer == .allowed ? "bell.badge.fill" : "moon.zzz.fill")
                } description: {
                    Text(answer == .allowed ? "This is where your app requests the permission." : "Ask again when the person reaches something that needs it.")
                } actions: {
                    Button("Start over") { self.answer = nil }
                        .buttonStyle(.borderedProminent)
                }
                .transition(.opacity)
            } else {
                PermissionPrimerScreen(
                    systemImage: "bell.badge.fill",
                    title: "Stay in the loop",
                    message: "Turn on notifications and we only write when it matters.",
                    benefits: [
                        PermissionPrimerScreenBenefit(systemImage: "shippingbox.fill", title: "Order updates", text: "Know the moment your order ships and arrives."),
                        PermissionPrimerScreenBenefit(systemImage: "tag.fill", title: "Price drops", text: "Hear first when something you saved gets cheaper."),
                        PermissionPrimerScreenBenefit(systemImage: "moon.fill", title: "Quiet by default", text: "No marketing, and nothing at night."),
                    ],
                    tint: .indigo,
                    onContinue: { answer = .allowed },
                    onSkip: { answer = .later }
                )
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: answer)
    }
}

#Preview {
    PermissionPrimerScreenDemo()
}
