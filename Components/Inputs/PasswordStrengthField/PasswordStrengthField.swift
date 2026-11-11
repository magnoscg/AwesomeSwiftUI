// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// One requirement of the password, shown as a line of the checklist.
struct PasswordStrengthFieldRule: Identifiable, Sendable {
    let id: String
    let title: LocalizedStringResource
    let isMet: @Sendable (String) -> Bool

    static let defaults: [PasswordStrengthFieldRule] = [
        .init(id: "length", title: "At least 8 characters") { $0.count >= 8 },
        .init(id: "case", title: "Upper and lower case letters") { $0.contains(where: \.isUppercase) && $0.contains(where: \.isLowercase) },
        .init(id: "digit", title: "A number") { $0.contains(where: \.isNumber) },
        .init(id: "symbol", title: "A symbol") { $0.contains { $0.isPunctuation || $0.isSymbol } },
    ]
}

/// Turns the rules into a strength level, from 0 (empty) to `levels`.
enum PasswordStrengthFieldMeter {
    static let levels = 4

    static func level(for password: String, rules: [PasswordStrengthFieldRule]) -> Int {
        guard !password.isEmpty, !rules.isEmpty else { return 0 }
        let met = rules.filter { $0.isMet(password) }.count
        let scaled = Double(met) / Double(rules.count) * Double(levels)
        return max(1, min(levels, Int(scaled.rounded(.up))))
    }
}

/// A password field with a strength meter and a checklist of rules that tick off as they are met.
struct PasswordStrengthField: View {
    let title: LocalizedStringResource
    @Binding var password: String
    var rules = PasswordStrengthFieldRule.defaults

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fieldCornerRadius: CGFloat = 14

    private var level: Int { PasswordStrengthFieldMeter.level(for: password, rules: rules) }

    private var levelName: String {
        switch level {
        case 0: "Empty"
        case 1: "Weak"
        case 2: "Fair"
        case 3: "Good"
        default: "Strong"
        }
    }

    private var levelColor: Color {
        switch level {
        case 1: .red
        case 2: .orange
        case 3: .yellow
        default: .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field

            HStack(spacing: 6) {
                ForEach(1...PasswordStrengthFieldMeter.levels, id: \.self) { segment in
                    Capsule()
                        .fill(segment <= level ? AnyShapeStyle(levelColor) : AnyShapeStyle(.quaternary))
                        .frame(height: 6)
                }

                Text(levelName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .padding(.leading, 6)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Password strength")
            .accessibilityValue(levelName)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(rules) { rule in
                    checklistRow(rule)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: password)
    }

    private var field: some View {
        HStack(spacing: 10) {
            Group {
                if isRevealed {
                    TextField(text: $password) { Text(title) }
                } else {
                    SecureField(text: $password) { Text(title) }
                }
            }
            .focused($isFocused)
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .accessibilityLabel(title)

            Button {
                isRevealed.toggle()
                isFocused = true
            } label: {
                // The icon is too small to hit. The padding widens what answers to a touch,
                // and the same padding taken back keeps the field as it was.
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .padding(15)
                    .contentShape(.rect)
                    .padding(-15)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
        .padding(14)
        .background(.background, in: .rect(cornerRadius: fieldCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: fieldCornerRadius, style: .continuous)
                .strokeBorder(isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), lineWidth: 1.5)
        }
    }

    private func checklistRow(_ rule: PasswordStrengthFieldRule) -> some View {
        let isMet = rule.isMet(password)
        return Label {
            Text(rule.title)
        } icon: {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : .secondary)
                .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rule.title)
        .accessibilityValue(isMet ? "Met" : "Not met")
    }
}

// MARK: - Demo

struct PasswordStrengthFieldDemo: View {
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Create your account")
                    .font(.largeTitle.bold())

                PasswordStrengthField(title: "Password", password: $password)
            }
            .padding(24)
        }
        .tint(.indigo)
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .pink.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    PasswordStrengthFieldDemo()
}
