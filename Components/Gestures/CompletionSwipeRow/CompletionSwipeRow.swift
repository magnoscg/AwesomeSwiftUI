// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A row you swipe forward to complete, to the right or, in a right-to-left layout, to the left:
/// a checkmark pops in and the row collapses.
///
/// `onComplete` runs once, after the row has collapsed, and is where the caller
/// should remove the row. With Reduce Motion on, the row completes at once.
struct CompletionSwipeRow<Content: View>: View {
    var tint: Color = .green
    var rowBackground: Color = Color(.secondarySystemGroupedBackground)
    var cornerRadius: CGFloat = 16
    var actionName = "Complete"
    var onComplete: () -> Void
    @ViewBuilder var content: () -> Content

    private enum Phase {
        case idle, checked, collapsed
    }

    @State private var phase = Phase.idle
    @State private var size = CGSize.zero
    @GestureState private var dragX: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    /// Gestures report screen points, but layout mirrors in right-to-left layouts: 1 or -1 converts between them.
    private var forward: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }

    private var isPastThreshold: Bool {
        phase != .idle || CompletionSwipeRowMath.shouldComplete(translation: CGSize(width: dragX, height: 0), width: size.width)
    }

    var body: some View {
        content()
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .offset(x: phase == .idle ? dragX : size.width)
            .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.25), value: dragX == 0)
            .background(alignment: .leading) {
                ZStack(alignment: .leading) {
                    tint

                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                        .foregroundStyle(CompletionSwipeRowContrastingForeground(background: tint))
                        .scaleEffect(isPastThreshold ? 1.15 : (reduceMotion ? 1 : 0.5))
                        .opacity(isPastThreshold ? 1 : 0.55)
                        .padding(.leading, 24)
                        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.6), value: isPastThreshold)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: phase == .idle ? nil : (phase == .collapsed ? 0 : size.height))
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .simultaneousGesture(swipe)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPastThreshold) { _, isNowPast in isNowPast }
            .accessibilityElement(children: .combine)
            .accessibilityAction(named: actionName) { complete() }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($dragX) { value, state, _ in
                let forwardDrag = value.translation.width * forward
                guard phase == .idle, forwardDrag > abs(value.translation.height) else { return }
                state = forwardDrag
            }
            .onEnded { value in
                let translation = CGSize(width: value.translation.width * forward, height: value.translation.height)
                guard CompletionSwipeRowMath.shouldComplete(translation: translation, width: size.width) else { return }
                complete()
            }
    }

    private func complete() {
        guard phase == .idle else { return }

        if reduceMotion {
            phase = .collapsed
            onComplete()
            return
        }

        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
            phase = .checked
        } completion: {
            withAnimation(.easeInOut(duration: 0.25).delay(0.12)) {
                phase = .collapsed
            } completion: {
                onComplete()
            }
        }
    }
}

enum CompletionSwipeRowMath {
    static let maximumThreshold: CGFloat = 140

    /// A swipe counts when it goes mostly forward, a positive width, and covers enough of the row.
    static func shouldComplete(translation: CGSize, width: CGFloat) -> Bool {
        guard width > 0, translation.width > abs(translation.height) else { return false }
        return translation.width >= min(width * 0.4, maximumThreshold)
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct CompletionSwipeRowContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

private struct CompletionSwipeRowDemoTask: Identifiable {
    let id: String
    let systemImage: String
}

struct CompletionSwipeRowDemo: View {
    private static let allTasks = [
        CompletionSwipeRowDemoTask(id: "Water the plants", systemImage: "drop.fill"),
        CompletionSwipeRowDemoTask(id: "Call the dentist", systemImage: "phone.fill"),
        CompletionSwipeRowDemoTask(id: "Buy groceries", systemImage: "cart.fill"),
        CompletionSwipeRowDemoTask(id: "Send the invoice", systemImage: "doc.text.fill"),
        CompletionSwipeRowDemoTask(id: "Book the flight", systemImage: "airplane"),
    ]

    @State private var tasks = Self.allTasks

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 4)

                    ForEach(tasks) { task in
                        CompletionSwipeRow(onComplete: { tasks.removeAll { $0.id == task.id } }) {
                            Label(task.id, systemImage: task.systemImage)
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .frame(minHeight: 68, alignment: .leading)
                        }
                    }

                    if tasks.isEmpty {
                        Button("Start over") { tasks = Self.allTasks }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }
}

#Preview {
    CompletionSwipeRowDemo()
}
