// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// One page of a `MultiStepForm`. `isValid` decides whether the person can continue.
struct MultiStepFormStep: Identifiable {
    let id: String
    let title: String
    let isValid: Bool
    let content: AnyView

    init<Content: View>(id: String, title: String, isValid: Bool = true, @ViewBuilder content: () -> Content) {
        self.id = id
        self.title = title
        self.isValid = isValid
        self.content = AnyView(content())
    }
}

/// Where the person is in the form, kept apart from the view so it is easy to test.
struct MultiStepFormProgress: Equatable {
    private(set) var index = 0
    private(set) var isFinished = false

    /// Returns `true` only for the call that completes the last step.
    mutating func advance(stepCount: Int, isCurrentStepValid: Bool) -> Bool {
        guard stepCount > 0, isCurrentStepValid, !isFinished else { return false }
        guard index < stepCount - 1 else {
            isFinished = true
            return true
        }
        index += 1
        return false
    }

    mutating func goBack() {
        isFinished = false
        index = max(0, index - 1)
    }

    /// Keeps the position valid when the steps change while the form is on screen.
    mutating func clamp(stepCount: Int) {
        index = min(index, max(0, stepCount - 1))
    }
}

/// A form split into steps, with a progress bar on top. "Continue" stays disabled
/// until the current step is valid, and there is no swipe that could skip it.
struct MultiStepForm: View {
    let steps: [MultiStepFormStep]
    var finishTitle = "Finish"
    var onFinish: () -> Void = {}

    @State private var progress = MultiStepFormProgress()
    @State private var isMovingForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .smooth(duration: 0.35) }

    private var transition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    var body: some View {
        Group {
            if steps.indices.contains(progress.index) {
                form(step: steps[progress.index])
            }
        }
        .onChange(of: steps.count) { _, count in progress.clamp(stepCount: count) }
    }

    private func form(step: MultiStepFormStep) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(step: step)
                    step.content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize)
            .id(step.id)
            .transition(transition)
            .frame(maxHeight: .infinity, alignment: .top)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { buttons(step: step) }
                VStack(spacing: 12) { buttons(step: step) }
            }
            .controlSize(.large)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= progress.index ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private func header(step: MultiStepFormStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(progress.index + 1) of \(steps.count)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(step.title)
                .font(.title.bold())
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func buttons(step: MultiStepFormStep) -> some View {
        if progress.index > 0 {
            Button("Back") {
                isMovingForward = false
                withAnimation(animation) { progress.goBack() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }

        Button(progress.index == steps.count - 1 ? finishTitle : "Continue") {
            isMovingForward = true
            var next = progress
            let didFinish = next.advance(stepCount: steps.count, isCurrentStepValid: step.isValid)
            withAnimation(animation) { progress = next }
            if didFinish { onFinish() }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .disabled(!step.isValid || progress.isFinished)
    }
}

// MARK: - Demo

struct MultiStepFormDemo: View {
    private static let plans = ["Free plan", "Pro plan", "Team plan"]
    private static let days = ["Monday", "Wednesday", "Friday"]

    @State private var plan: String?
    @State private var reminderDays: Set<String> = []
    @State private var acceptsTerms = false
    @State private var isDone = false
    @State private var run = 0

    var body: some View {
        Group {
            if isDone {
                ContentUnavailableView {
                    Label("You are all set", systemImage: "checkmark.seal.fill")
                } actions: {
                    Button("Start over") {
                        plan = nil
                        reminderDays = []
                        acceptsTerms = false
                        run += 1
                        isDone = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                MultiStepForm(steps: steps) { isDone = true }
                    .id(run)
                    .padding(24)
            }
        }
        .tint(.indigo)
        .background(LinearGradient(colors: [.indigo.opacity(0.12), .cyan.opacity(0.08)], startPoint: .top, endPoint: .bottom))
    }

    private var steps: [MultiStepFormStep] {
        [
            MultiStepFormStep(id: "plan", title: "Choose a plan", isValid: plan != nil) {
                VStack(spacing: 10) {
                    ForEach(Self.plans, id: \.self) { name in
                        row(name, isSelected: plan == name) { plan = name }
                    }
                }
            },
            MultiStepFormStep(id: "days", title: "Pick reminder days", isValid: !reminderDays.isEmpty) {
                VStack(spacing: 10) {
                    ForEach(Self.days, id: \.self) { day in
                        row(day, isSelected: reminderDays.contains(day)) {
                            if reminderDays.remove(day) == nil { reminderDays.insert(day) }
                        }
                    }
                }
            },
            MultiStepFormStep(id: "terms", title: "One last thing", isValid: acceptsTerms) {
                Toggle("Accept the terms", isOn: $acceptsTerms)
                    .padding()
                    .background(.background, in: .rect(cornerRadius: 16, style: .continuous))
            },
        ]
    }

    private func row(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.background, in: .rect(cornerRadius: 16, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    MultiStepFormDemo()
}
