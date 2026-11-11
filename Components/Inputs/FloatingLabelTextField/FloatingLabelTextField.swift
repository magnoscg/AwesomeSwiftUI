// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A text field whose placeholder floats up on focus or once it has text.
///
/// With Reduce Motion on, the label changes place without sliding.
struct FloatingLabelTextField: View {
    let title: LocalizedStringResource
    @Binding var text: String
    var tint: Color = .indigo

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var fieldHeight = 60.0
    @ScaledMetric(relativeTo: .body) private var textDrop = 9.0
    @ScaledMetric(relativeTo: .body) private var labelLift = 12.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFloating: Bool { isFocused || !text.isEmpty }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.body)
                .foregroundStyle(isFocused ? tint : Color.secondary)
                .scaleEffect(isFloating ? 0.78 : 1, anchor: .leading)
                .offset(y: isFloating ? -labelLift : 0)
                .accessibilityRepresentation { EmptyView() }
                .allowsHitTesting(false)

            TextField(text: $text, prompt: Text(verbatim: "")) { Text(title) }
                .accessibilityLabel(title)
                .font(.body)
                .focused($isFocused)
                .tint(tint)
                .offset(y: isFloating ? textDrop : 0)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: fieldHeight)
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isFocused ? tint : Color.secondary.opacity(0.25), lineWidth: isFocused ? 2 : 1)
        }
        .contentShape(.rect(cornerRadius: 14))
        .onTapGesture { isFocused = true }
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.2), value: isFloating)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Demo

struct FloatingLabelTextFieldDemo: View {
    @State private var name = ""
    @State private var email = ""
    @State private var city = "Valencia"

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.25), .purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Create your account")
                    .font(.title.bold())
                    .padding(.bottom, 8)

                FloatingLabelTextField(title: "Name", text: $name)
                FloatingLabelTextField(title: "Email", text: $email)
                FloatingLabelTextField(title: "City", text: $city)
            }
            .padding(24)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    FloatingLabelTextFieldDemo()
}
