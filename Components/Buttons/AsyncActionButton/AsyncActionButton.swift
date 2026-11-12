// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// Knows whether the action is running, so a second tap while it runs does nothing.
struct AsyncActionButtonRun: Equatable {
    private(set) var isRunning = false

    /// Returns `false`, and changes nothing, when the action is already running.
    mutating func start() -> Bool {
        guard !isRunning else { return false }
        isRunning = true
        return true
    }

    mutating func finish() {
        isRunning = false
    }
}

/// A button that runs an async action and shows a spinner in place of its label
/// until the action ends. It keeps its width, works with any button style, and
/// ignores taps while the action runs instead of looking disabled.
///
/// Leaving the screen cancels the action. The swap is a short crossfade, so it
/// needs nothing different with Reduce Motion on.
struct AsyncActionButton<Label: View>: View {
    let action: @MainActor () async -> Void
    let label: Label

    @State private var run = AsyncActionButtonRun()
    @State private var runID: UUID?

    init(action: @escaping @MainActor () async -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            guard run.start() else { return }
            runID = UUID()
        } label: {
            label
                .opacity(run.isRunning ? 0 : 1)
                .overlay {
                    if run.isRunning {
                        AsyncActionButtonSpinner()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: run)
        }
        .accessibilityValue(run.isRunning ? Text("In progress") : Text(""))
        .task(id: runID) {
            guard runID != nil else { return }
            await action()
            run.finish()
            runID = nil
        }
    }
}

/// Drawn with the label's foreground style, which a `ProgressView` does not
/// take, so it is white on a prominent button and tinted on a bordered one.
private struct AsyncActionButtonSpinner: View {
    @ScaledMetric(relativeTo: .body) private var size = 18.0

    var body: some View {
        TimelineView(.animation) { context in
            let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
            Circle()
                .trim(from: 0.15, to: 1)
                .stroke(style: StrokeStyle(lineWidth: size / 7, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(turn * 360))
        }
        .accessibilityHidden(true)
    }
}

extension AsyncActionButton where Label == Text {
    init(_ title: LocalizedStringResource, action: @escaping @MainActor () async -> Void) {
        self.init(action: action) { Text(title) }
    }
}

extension AsyncActionButton where Label == SwiftUI.Label<Text, Image> {
    init(_ title: LocalizedStringResource, systemImage: String, action: @escaping @MainActor () async -> Void) {
        self.init(action: action) { SwiftUI.Label { Text(title) } icon: { Image(systemName: systemImage) } }
    }
}

// MARK: - Demo

struct AsyncActionButtonDemo: View {
    @State private var saves = 0
    @State private var syncs = 0

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Edit Profile")
                    .font(.largeTitle.bold())
                Text("Saves: \(saves) · Syncs: \(syncs)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            AsyncActionButton {
                try? await Task.sleep(for: .seconds(1.5))
                saves += 1
            } label: {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                AsyncActionButton("Sync", systemImage: "arrow.triangle.2.circlepath") {
                    try? await Task.sleep(for: .seconds(1))
                    syncs += 1
                }
                .buttonStyle(.bordered)

                AsyncActionButton("Send Invite") {
                    try? await Task.sleep(for: .seconds(2))
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    AsyncActionButtonDemo()
}
