// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Applies a mask where `#` takes a digit, `A` takes a letter and anything else is written as is.
nonisolated enum MaskedTextFieldFormatter {
    private static func accepts(_ character: Character, slot: Character) -> Bool? {
        switch slot {
        case "#": character.isWholeNumber
        case "A": character.isLetter
        default: nil
        }
    }

    private static func isLiteral(_ slot: Character) -> Bool {
        slot != "#" && slot != "A"
    }

    /// The part of a run of literals that has to be there to read it back: `+34` for `+34 `, so a
    /// pasted number without the separator is recognized. A run like `1 (` has to be there whole,
    /// because without its separators it is just a `1` the user could be typing.
    private static func readBackPrefix(of literals: Substring) -> Substring {
        let isData: (Character) -> Bool = { $0.isWholeNumber || $0.isLetter }
        guard let end = literals.lastIndex(where: isData), !literals[...end].allSatisfy(isData) else { return literals }
        return literals[...end]
    }

    /// Literals are added only when a character follows them, so backspace can always delete.
    /// A run of literals is read back only when its prefix is there complete, so a typed `3` is
    /// not taken for the `3` of a `+34 ` prefix.
    static func format(_ input: String, mask: String) -> String {
        guard !mask.isEmpty else { return input }

        var result = ""
        var pendingLiterals = ""
        var remaining = Substring(input)

        var slots = Substring(mask)

        while let slot = slots.first {
            guard !remaining.isEmpty else { return result }

            if isLiteral(slot) {
                let literals = slots.prefix(while: isLiteral)
                slots.removeFirst(literals.count)
                pendingLiterals += literals
                let prefix = readBackPrefix(of: literals)
                if remaining.hasPrefix(prefix) { remaining.removeFirst(prefix.count) }
                continue
            }

            slots.removeFirst()
            while let next = remaining.first, accepts(next, slot: slot) == false {
                remaining.removeFirst()
            }
            guard let character = remaining.first else { return result }

            result += pendingLiterals
            pendingLiterals = ""
            result.append(character)
            remaining.removeFirst()
        }
        return result
    }

    static func isComplete(_ text: String, mask: String) -> Bool {
        !mask.isEmpty && format(text, mask: mask).count == mask.count
    }
}

/// A text field that formats its input as the user types, such as `12/34` or a phone number.
///
/// Editing in the middle of the text moves the cursor to the end, because the field rewrites its
/// text. With Reduce Motion on, the completion checkmark appears without animating.
struct MaskedTextField: View {
    let title: String
    @Binding var text: String
    let mask: String
    var prompt: String? = nil
    var systemImage: String? = nil
    var keyboard: UIKeyboardType = .numberPad

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isComplete: Bool { MaskedTextFieldFormatter.isComplete(text, mask: mask) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                TextField(title, text: $text, prompt: Text(prompt ?? mask))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .monospacedDigit()
                    .accessibilityLabel(title)
                    .accessibilityHint(isComplete ? "Complete" : "")

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isComplete ? Color.green : .clear, lineWidth: 1.5)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isComplete)
        .onChange(of: text, initial: true) { _, newValue in
            let formatted = MaskedTextFieldFormatter.format(newValue, mask: mask)
            if formatted != newValue { text = formatted }
        }
    }
}

// MARK: - Demo

struct MaskedTextFieldDemo: View {
    @State private var card = ""
    @State private var expiry = ""
    @State private var phone = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Payment details")
                    .font(.largeTitle.bold())

                MaskedTextField(title: "Card number", text: $card, mask: "#### #### #### ####", systemImage: "creditcard.fill")
                MaskedTextField(title: "Expiry date", text: $expiry, mask: "##/##", prompt: "MM/YY", systemImage: "calendar")
                MaskedTextField(title: "Phone", text: $phone, mask: "(###) ###-####", systemImage: "phone.fill")
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    MaskedTextFieldDemo()
}
