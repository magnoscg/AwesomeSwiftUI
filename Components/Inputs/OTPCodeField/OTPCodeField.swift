// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

enum OTPCodeFieldInput {
    /// Keeps only ASCII digits, up to `length`. Handles pasted text such as "123-456".
    static func sanitized(_ input: String, length: Int) -> String {
        String(input.filter { $0.isASCII && $0.isNumber }.prefix(max(length, 0)))
    }
}

/// A one-time code entry with a box per digit, backed by a single invisible `TextField`.
///
/// The field stays behind the boxes rather than hidden, so VoiceOver, paste and code
/// autofill reach it. With Reduce Motion on, digits appear without a pop.
struct OTPCodeField: View {
    @Binding var code: String
    var length: Int = 6
    var title: String = "Verification code"
    var tint: Color = .indigo
    var onComplete: ((String) -> Void)? = nil

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .title) private var boxHeight = 58.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<length, id: \.self) { index in
                digitBox(at: index)
            }
        }
        .accessibilityHidden(true)
        .background {
            TextField(title, text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.5), value: code)
        .onChange(of: code) { oldValue, newValue in
            let clean = OTPCodeFieldInput.sanitized(newValue, length: length)
            if clean != newValue { code = clean }
            if clean.count == length, clean != OTPCodeFieldInput.sanitized(oldValue, length: length) {
                onComplete?(clean)
            }
        }
    }

    private func digitBox(at index: Int) -> some View {
        let digits = Array(code)
        let digit = index < digits.count ? String(digits[index]) : nil
        let isActive = isFocused && index == digits.count

        return RoundedRectangle(cornerRadius: 14)
            .fill(.regularMaterial)
            .strokeBorder(isActive ? tint : Color.secondary.opacity(0.3), lineWidth: isActive ? 2 : 1)
            .frame(height: boxHeight)
            .overlay {
                if let digit {
                    Text(digit)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .transition(reduceMotion ? .identity : .scale(scale: 0.4).combined(with: .opacity))
                }
            }
    }
}

// MARK: - Demo

struct OTPCodeFieldDemo: View {
    @State private var code = ""
    @State private var isVerified = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.3), .cyan.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: isVerified ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(isVerified ? Color.green : Color.indigo)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                Text(isVerified ? "You are in" : "Check your messages")
                    .font(.title2.bold())

                OTPCodeField(code: $code, title: "Code") { _ in
                    withAnimation { isVerified = true }
                }
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: code) { _, newValue in
            if newValue.count < 6 { isVerified = false }
        }
    }
}

#Preview {
    OTPCodeFieldDemo()
}
