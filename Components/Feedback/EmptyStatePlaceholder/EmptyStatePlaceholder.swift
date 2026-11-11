// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// An empty screen with a breathing symbol, a message and an optional call to action.
///
/// With Reduce Motion on, the symbol stays still.
struct EmptyStatePlaceholder: View {
    var systemImage: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .symbolEffect(.breathe, isActive: !reduceMotion)
            }
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Demo

struct EmptyStatePlaceholderDemo: View {
    @State private var messages: [String] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if messages.isEmpty {
                EmptyStatePlaceholder(
                    systemImage: "tray",
                    title: "No messages",
                    message: "New conversations will show up here.",
                    actionTitle: "Load samples"
                ) {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        messages = ["Welcome aboard", "Your invoice is ready", "Lunch on Friday?"]
                    }
                }
                .transition(.opacity)
            } else {
                List {
                    ForEach(messages, id: \.self) { message in
                        Label(message, systemImage: "envelope")
                    }
                    Button("Clear all", role: .destructive) {
                        withAnimation(reduceMotion ? nil : .snappy) { messages = [] }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    EmptyStatePlaceholderDemo()
}
