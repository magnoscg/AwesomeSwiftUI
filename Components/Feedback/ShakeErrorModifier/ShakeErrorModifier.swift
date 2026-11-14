// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Shakes a view sideways each time `trigger` changes, with an error haptic.
///
/// With Reduce Motion on, the view stays still and only the haptic plays, so also show the error some other way.
struct ShakeErrorModifier<Trigger: Equatable & Sendable>: ViewModifier {
    let trigger: Trigger
    var distance: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let distance = reduceMotion ? 0 : distance

        content
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-distance, duration: 0.06)
                    LinearKeyframe(distance, duration: 0.1)
                    LinearKeyframe(-distance * 0.7, duration: 0.1)
                    LinearKeyframe(distance * 0.5, duration: 0.08)
                    SpringKeyframe(0, duration: 0.2, spring: .bouncy)
                }
            }
            .sensoryFeedback(.error, trigger: trigger)
    }
}

extension View {
    /// Shakes the view each time `trigger` changes.
    func shakeError(trigger: some Equatable & Sendable, distance: CGFloat = 10) -> some View {
        modifier(ShakeErrorModifier(trigger: trigger, distance: distance))
    }
}

// MARK: - Demo

struct ShakeErrorModifierDemo: View {
    @State private var email = "hello@"
    @State private var attempts = 0
    @State private var showsError = false

    private var isValid: Bool { email.contains("@") && email.contains(".") }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.pink.opacity(0.2), .orange.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Join the beta")
                    .font(.title.bold())

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(16)
                    .background(.regularMaterial, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(showsError ? Color.red : Color.clear, lineWidth: 2)
                    }
                    .shakeError(trigger: attempts)

                Text("Enter a complete email address.")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .opacity(showsError ? 1 : 0)
                    .accessibilityHidden(!showsError)

                Button(action: submit) {
                    Text("Submit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.pink.gradient, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .onChange(of: email) { showsError = false }
    }

    private func submit() {
        showsError = !isValid
        if !isValid { attempts += 1 }
    }
}

#Preview {
    ShakeErrorModifierDemo()
}
