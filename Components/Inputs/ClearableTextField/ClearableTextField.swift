// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A text field with a leading symbol and a button that clears it. The border
/// and the symbol take the tint while it has focus, and both turn red with a
/// message under the field when the caller passes an error.
///
/// Clearing keeps the focus, so the keyboard stays up for the next text.
/// With Reduce Motion on, the clear button and the error fade instead of moving.
struct ClearableTextField: View {
    let title: LocalizedStringResource
    @Binding var text: String
    var systemImage: String?
    var errorMessage: LocalizedStringResource?

    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: AnyShapeStyle {
        if errorMessage != nil { return AnyShapeStyle(.red) }
        return isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                }

                TextField(text: $text) { Text(title) }
                    .focused($isFocused)
                    .accessibilityLabel(Text(title))
                    .accessibilityHint(errorMessage.map { Text($0) } ?? Text(""))

                if !text.isEmpty {
                    Button {
                        text = ""
                        isFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .padding(13)
                            .contentShape(.rect)
                            .padding(-13)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear text")
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent, lineWidth: isFocused || errorMessage != nil ? 1.5 : 0.5)
            }
            .contentShape(.rect)
            .onTapGesture { isFocused = true }

            if let errorMessage {
                Label { Text(errorMessage) } icon: { Image(systemName: "exclamationmark.circle.fill") }
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .snappy(duration: 0.25), value: text.isEmpty)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .snappy(duration: 0.25), value: errorMessage == nil)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Demo

struct ClearableTextFieldDemo: View {
    @State private var search = "Coffee near me"
    @State private var name = ""
    @State private var email = ""

    private var emailError: LocalizedStringResource? {
        !email.isEmpty && !email.contains("@") ? "Enter a valid email address." : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact")
                    .font(.largeTitle.bold())

                ClearableTextField(title: "Search", text: $search, systemImage: "magnifyingglass")
                ClearableTextField(title: "Name", text: $name, systemImage: "person")
                    .textContentType(.name)
                ClearableTextField(title: "Email", text: $email, systemImage: "envelope", errorMessage: emailError)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(20)
        }
        .tint(.indigo)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    ClearableTextFieldDemo()
}
