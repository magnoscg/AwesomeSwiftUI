// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// Decides when the error is shown, so the field never complains while someone is typing.
struct ValidatedTextFieldFeedback: Equatable {
    private(set) var message: String?

    /// The only moment an error can appear.
    mutating func fieldLostFocus(text: String, validate: (String) -> String?) {
        message = validate(text)
    }

    /// While typing, an error can only go away, as soon as the text is fixed.
    mutating func textChanged(text: String, validate: (String) -> String?) {
        if message != nil, validate(text) == nil { message = nil }
    }
}

/// A text field that checks its value when it loses focus and shows its error only after that.
struct ValidatedTextField: View {
    let title: LocalizedStringResource
    @Binding var text: String
    /// Returns the message to show, or `nil` when the value is fine.
    let validate: (String) -> String?

    @State private var feedback = ValidatedTextFieldFeedback()
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var borderStyle: AnyShapeStyle {
        if feedback.message != nil { return AnyShapeStyle(.red) }
        return isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .accessibilityHidden(true)

            TextField("", text: $text)
                .focused($isFocused)
                .padding(14)
                .background(.background, in: .rect(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderStyle, lineWidth: 1.5)
                }
                .accessibilityLabel(title)
                .accessibilityHint(feedback.message ?? "")

            if let message = feedback.message {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: feedback)
        .onChange(of: isFocused) { _, focused in
            guard !focused else { return }
            feedback.fieldLostFocus(text: text, validate: validate)
            if let message = feedback.message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
        .onChange(of: text) { _, newValue in
            feedback.textChanged(text: newValue, validate: validate)
        }
    }
}

// MARK: - Demo

struct ValidatedTextFieldDemo: View {
    @State private var email = ""
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your details")
                    .font(.largeTitle.bold())

                ValidatedTextField(title: "Email", text: $email) { value in
                    value.contains("@") && value.contains(".") ? nil : "Enter a valid email address."
                }
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                ValidatedTextField(title: "Name", text: $name) { value in
                    value.isEmpty ? "Tell us your name." : nil
                }
            }
            .padding(24)
        }
        .tint(.indigo)
        .background(LinearGradient(colors: [.indigo.opacity(0.12), .orange.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    ValidatedTextFieldDemo()
}
