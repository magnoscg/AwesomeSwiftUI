// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct CoachMarkTourStep: Identifiable {
    /// Matches the id passed to `coachMarkTourTarget(_:)`.
    let id: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource
}

/// Where the tour is. `advance` and `finish` report the end only once.
struct CoachMarkTourProgress: Equatable {
    private(set) var index = 0
    private(set) var isFinished = false

    /// Moves to the next step. Returns `true` when this call finished the tour.
    mutating func advance(stepCount: Int) -> Bool {
        guard !isFinished else { return false }
        if index + 1 < stepCount {
            index += 1
            return false
        }
        return finish()
    }

    /// Ends the tour. Returns `true` only the first time.
    mutating func finish() -> Bool {
        guard !isFinished else { return false }
        isFinished = true
        return true
    }

    /// Keeps the index valid when the list of steps shrinks.
    mutating func clamp(stepCount: Int) {
        index = max(min(index, stepCount - 1), 0)
    }

    mutating func restart() {
        self = CoachMarkTourProgress()
    }
}

private struct CoachMarkTourAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Marks this view as the target of the tour step with the same id.
    func coachMarkTourTarget(_ id: String) -> some View {
        anchorPreference(key: CoachMarkTourAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Runs a guided tour over this view. Apply it to a container of all the targets.
    func coachMarkTour(
        steps: [CoachMarkTourStep],
        isPresented: Binding<Bool>,
        onFinish: @escaping () -> Void = {}
    ) -> some View {
        modifier(CoachMarkTourModifier(steps: steps, isPresented: isPresented, onFinish: onFinish))
    }
}

private struct CoachMarkTourModifier: ViewModifier {
    let steps: [CoachMarkTourStep]
    @Binding var isPresented: Bool
    let onFinish: () -> Void

    @State private var progress = CoachMarkTourProgress()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .smooth(duration: 0.45) }

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(CoachMarkTourAnchorKey.self) { anchors in
                GeometryReader { outer in
                    if isPresented, !progress.isFinished, steps.indices.contains(progress.index) {
                        let step = steps[progress.index]

                        GeometryReader { proxy in
                            let hole = anchors[step.id].map { proxy[$0].insetBy(dx: -8, dy: -8) }
                            overlay(step: step, hole: hole, screen: proxy.size, insets: outer.safeAreaInsets)
                        }
                        .ignoresSafeArea()
                        .transition(.opacity)
                    }
                }
            }
            .onChange(of: steps.count) { _, count in progress.clamp(stepCount: count) }
            .onChange(of: isPresented) { _, presented in
                if presented { progress.restart() }
            }
            .onChange(of: isPresented && steps.isEmpty, initial: true) { _, hasNothingToShow in
                guard hasNothingToShow else { return }
                progress.restart()
                skip()
            }
    }

    private func overlay(step: CoachMarkTourStep, hole: CGRect?, screen: CGSize, insets: EdgeInsets) -> some View {
        let holeRect = hole ?? CGRect(x: screen.width / 2, y: screen.height / 2, width: 0, height: 0)
        let placeBelow = screen.height - holeRect.maxY >= holeRect.minY
        let available = max(
            placeBelow ? screen.height - holeRect.maxY - insets.bottom - 24 : holeRect.minY - insets.top - 24,
            120
        )

        return ZStack(alignment: placeBelow ? .top : .bottom) {
            CoachMarkTourDim(hole: holeRect)
                .fill(.black.opacity(0.65), style: FillStyle(eoFill: true))
                .contentShape(.rect)
                .onTapGesture(perform: next)
                .accessibilityHidden(true)

            ViewThatFits(in: .vertical) {
                card(step)
                ScrollView { card(step) }
            }
            .frame(maxHeight: available)
            .padding(.horizontal, 20)
            .padding(placeBelow ? .top : .bottom, placeBelow ? holeRect.maxY + 12 : screen.height - holeRect.minY + 12)
        }
    }

    private func card(_ step: CoachMarkTourStep) -> some View {
        let isLast = progress.index + 1 >= steps.count

        return VStack(alignment: .leading, spacing: 8) {
            Text(step.title).font(.headline)
            Text(step.message).font(.subheadline).foregroundStyle(.secondary)

            HStack {
                Button("Skip tour", action: skip)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(progress.index + 1) of \(steps.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button(isLast ? "Done" : "Next", action: next)
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(isLast ? "Finish tour" : "Next step")
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func next() {
        var updated = progress
        let finished = updated.advance(stepCount: steps.count)
        withAnimation(animation) {
            progress = updated
            if finished { isPresented = false }
        }
        if finished { onFinish() }
    }

    private func skip() {
        var updated = progress
        let finished = updated.finish()
        withAnimation(animation) {
            progress = updated
            if finished { isPresented = false }
        }
        if finished { onFinish() }
    }
}

/// The dimming layer with a rounded hole around the target. Its hole animates between steps.
nonisolated private struct CoachMarkTourDim: Shape {
    var hole: CGRect

    var animatableData: CGRect.AnimatableData {
        get { hole.animatableData }
        set { hole.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: 14, height: 14))
        return path
    }
}

// MARK: - Demo

struct CoachMarkTourDemo: View {
    private let steps = [
        CoachMarkTourStep(id: "profile", title: "Your profile", message: "Change your photo and settings here."),
        CoachMarkTourStep(id: "search", title: "Search", message: "Find any note in a moment."),
        CoachMarkTourStep(id: "card", title: "Today", message: "Your plan for the day lives on this card."),
        CoachMarkTourStep(id: "add", title: "Add a note", message: "Tap here to write something new."),
    ]

    @State private var isTouring = true
    @ScaledMetric(relativeTo: .title2) private var buttonSize = 46.0

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                circleButton("person.fill", label: "Profile").coachMarkTourTarget("profile")
                Spacer()
                Text("Notes").font(.title2.bold())
                Spacer()
                circleButton("magnifyingglass", label: "Search").coachMarkTourTarget("search")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Today").font(.title.bold())
                Text("Three notes waiting for you").font(.body)
            }
            .foregroundStyle(.white)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.indigo.gradient, in: .rect(cornerRadius: 26))
            .coachMarkTourTarget("card")

            Button("Start tour again") { isTouring = true }
                .buttonStyle(.bordered)

            Spacer()

            circleButton("plus", label: "Add note")
                .coachMarkTourTarget("add")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .coachMarkTour(steps: steps, isPresented: $isTouring)
    }

    private func circleButton(_ systemImage: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: buttonSize, height: buttonSize)
                .background(.indigo.opacity(0.14), in: .circle)
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    CoachMarkTourDemo()
}
