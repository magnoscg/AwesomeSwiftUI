// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A composer pinned below its content that rises with the keyboard and grows as you type.
///
/// `safeAreaInset` makes the content leave room for the bar and moves the bar with the
/// keyboard, so nothing here needs to measure it.
struct KeyboardTrackingInputBar<Content: View>: View {
    @Binding var text: String
    var placeholder: LocalizedStringResource
    var tint: Color
    var onSend: (String) -> Void
    @ViewBuilder let content: Content

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var sendSize = 34.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        text: Binding<String>,
        placeholder: LocalizedStringResource = "Message",
        tint: Color = .blue,
        onSend: @escaping (String) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _text = text
        self.placeholder = placeholder
        self.tint = tint
        self.onSend = onSend
        self.content = content()
    }

    private var message: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.background, in: .rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20).strokeBorder(.quaternary)
                    }
                    .accessibilityLabel(placeholder)

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundStyle(KeyboardTrackingInputBarContrastingForeground(background: tint))
                        .frame(width: sendSize, height: sendSize)
                        .background(message.isEmpty ? AnyShapeStyle(.gray.opacity(0.4)) : AnyShapeStyle(tint), in: .circle)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .disabled(message.isEmpty)
                .accessibilityLabel("Send")
                .animation(reduceMotion ? nil : .snappy, value: message.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    private func send() {
        let sent = message
        guard !sent.isEmpty else { return }
        text = ""
        onSend(sent)
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct KeyboardTrackingInputBarContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

private struct KeyboardTrackingInputBarDemoMessage: Identifiable {
    let id = UUID()
    let text: String
}

struct KeyboardTrackingInputBarDemo: View {
    @State private var draft = ""
    @State private var messages = [
        KeyboardTrackingInputBarDemoMessage(text: "Tap the field and the bar rides up on the keyboard."),
        KeyboardTrackingInputBarDemoMessage(text: "Long messages make it grow, up to five lines."),
    ]

    var body: some View {
        KeyboardTrackingInputBar(text: $draft, onSend: { sent in
            messages.append(.init(text: sent))
        }, content: {
            ScrollView {
                LazyVStack(alignment: .trailing, spacing: 8) {
                    ForEach(messages) { message in
                        Text(message.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .foregroundStyle(.white)
                            .background(.blue, in: .rect(cornerRadius: 18))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
        })
    }
}

#Preview {
    KeyboardTrackingInputBarDemo()
}
