// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A bottom bar with an Undo button and a line that shrinks until the bar expires.
///
/// With Reduce Motion on, the line stays still and the bar simply fades away on time.
struct UndoSnackbar: View {
    let message: LocalizedStringResource
    var duration: Double = 5
    var tint: Color = .yellow
    let onUndo: () -> Void
    let onExpire: () -> Void

    @State private var remaining = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onUndo) {
                Text("Undo")
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(.black.opacity(0.85))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(tint)
                .frame(height: 3)
                .scaleEffect(x: remaining, anchor: .leading)
                .accessibilityHidden(true)
        }
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
        .task { await runTimer() }
    }

    private func runTimer() async {
        AccessibilityNotification.Announcement(String(localized: "\(message). Undo available.")).post()
        let seconds = voiceOverEnabled ? duration * 2 : duration
        if !reduceMotion {
            withAnimation(.linear(duration: seconds)) { remaining = 0 }
        }
        do {
            try await Task.sleep(for: .seconds(seconds))
        } catch {
            return
        }
        onExpire()
    }
}

private struct UndoSnackbarModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: LocalizedStringResource
    let duration: Double
    let onUndo: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    UndoSnackbar(message: message, duration: duration) {
                        isPresented = false
                        onUndo()
                    } onExpire: {
                        isPresented = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.2), value: isPresented)
    }
}

extension View {
    /// Shows an `UndoSnackbar` at the bottom for `duration` seconds.
    func undoSnackbar(
        isPresented: Binding<Bool>,
        message: LocalizedStringResource,
        duration: Double = 5,
        onUndo: @escaping () -> Void
    ) -> some View {
        modifier(UndoSnackbarModifier(isPresented: isPresented, message: message, duration: duration, onUndo: onUndo))
    }
}

// MARK: - Demo

struct UndoSnackbarDemo: View {
    private static let allMessages = ["Team lunch on Friday", "Your flight is confirmed", "Invoice for October"]

    @State private var messages = allMessages
    @State private var lastArchived: String?
    @State private var showsSnackbar = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.25), .indigo.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                HStack {
                    Text("Inbox")
                        .font(.largeTitle.bold())

                    Spacer()

                    Button("Archive", systemImage: "archivebox.fill", action: archive)
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                        .disabled(showsSnackbar)
                }
                .padding(.bottom, 10)

                ForEach(messages, id: \.self) { message in
                    Label(message, systemImage: "envelope.fill")
                        .font(.headline)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(24)
            .animation(.smooth, value: messages)
        }
        .undoSnackbar(isPresented: $showsSnackbar, message: "Conversation archived", duration: 3) {
            if let lastArchived { messages.insert(lastArchived, at: 0) }
        }
    }

    private func archive() {
        if messages.isEmpty { messages = Self.allMessages }
        lastArchived = messages.removeFirst()
        showsSnackbar = true
    }
}

#Preview {
    UndoSnackbarDemo()
}
