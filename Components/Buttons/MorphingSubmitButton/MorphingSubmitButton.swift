// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

private enum MorphingSubmitButtonPhase {
    case idle, loading, success
}

/// A submit button that collapses into a spinner while its async action runs,
/// then turns into a checkmark before returning to normal.
///
/// With Reduce Motion on, the button keeps its shape and only its content crossfades.
struct MorphingSubmitButton: View {
    let title: LocalizedStringResource
    var tint: Color = .blue
    var successColor: Color = .green
    var successDuration: Double = 1.2
    let action: @MainActor () async -> Void

    @State private var phase = MorphingSubmitButtonPhase.idle
    @ScaledMetric(relativeTo: .headline) private var height = 64.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var morph: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.3)
    }

    private var isCollapsed: Bool { phase != .idle && !reduceMotion }

    private var accessibilityTitle: LocalizedStringResource {
        switch phase {
        case .idle: title
        case .loading: "Submitting"
        case .success: "Done"
        }
    }

    var body: some View {
        Button {
            submit()
        } label: {
            ZStack {
                Text(title)
                    .font(.title3.bold())
                    .fixedSize()
                    .opacity(phase == .idle ? 1 : 0)

                if phase == .loading {
                    ProgressView()
                        .tint(MorphingSubmitButtonContrastingForeground(background: phase == .success ? successColor : tint))
                        .transition(.opacity)
                }

                if phase == .success {
                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(MorphingSubmitButtonContrastingForeground(background: phase == .success ? successColor : tint))
            .padding(.horizontal, isCollapsed ? 0 : 52)
            .frame(width: isCollapsed ? height : nil, height: height)
            .background(
                phase == .success ? successColor : tint,
                in: RoundedRectangle(cornerRadius: isCollapsed ? height / 2 : 18, style: .continuous)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: phase) { _, newPhase in newPhase == .success }
        .accessibilityLabel(accessibilityTitle)
    }

    private func submit() {
        guard phase == .idle else { return }
        withAnimation(morph) { phase = .loading }

        Task {
            await action()
            withAnimation(morph) { phase = .success }
            try? await Task.sleep(for: .seconds(successDuration))
            withAnimation(morph) { phase = .idle }
        }
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct MorphingSubmitButtonContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct MorphingSubmitButtonDemo: View {
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text("Join the waitlist")
                    .font(.largeTitle.bold())
                Text("We will write when your spot opens.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            MorphingSubmitButton(title: "Submit") {
                try? await Task.sleep(for: .seconds(1.4))
            }
            .frame(height: 80)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MorphingSubmitButtonDemo()
}
