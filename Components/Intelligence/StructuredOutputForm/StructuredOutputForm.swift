// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import FoundationModels
import SwiftUI

@available(iOS 27, *)
@Generable
enum StructuredOutputFormCategory: String, CaseIterable, Identifiable {
    case food, travel, shopping, other

    var id: Self { self }
}

/// What the model must produce. `@Guide` tells it what each field means.
@available(iOS 27, *)
@Generable(description: "An expense extracted from a short note")
struct StructuredOutputFormExpense {
    @Guide(description: "Who was paid, in a few words")
    var merchant: String
    @Guide(description: "The amount paid, as a number without a currency symbol")
    var amount: Double
    var category: StructuredOutputFormCategory
    @Guide(description: "What the expense was for, in at most six words")
    var purpose: String
}

/// The editable values of the form. Empty until the model or the person fills them.
@available(iOS 27, *)
struct StructuredOutputFormDraft: Equatable, Sendable {
    var merchant = ""
    var amount: Double?
    var category = StructuredOutputFormCategory.other
    var purpose = ""
}

/// A form whose fields the on-device model fills in from a free-form note, as a typed value.
@available(iOS 27, *)
struct StructuredOutputForm: View {
    @Binding var note: String
    @Binding var draft: StructuredOutputFormDraft
    /// Replaces the model with your own stream, for previews and for tests.
    var sampleStream: (@MainActor (String) -> AsyncThrowingStream<StructuredOutputFormDraft, Error>)? = nil
    /// Plays instead of an error when the model is unavailable or fails.
    var fallbackStream: (@MainActor (String) -> AsyncThrowingStream<StructuredOutputFormDraft, Error>)? = nil
    var failureMessage = "The on-device model couldn't fill in the form right now. Please try again later."

    @State private var fillTask: Task<Void, Never>?
    @State private var isFilling = false
    @State private var didFail = false

    private var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

    private struct ModelUnavailable: Error {}

    private var hasNote: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("Your note") {
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .accessibilityLabel("Note")

                Button {
                    guard !isFilling else { return }
                    isFilling = true
                    fillTask = Task { await fill() }
                } label: {
                    HStack {
                        Label(isFilling ? "Filling in" : "Fill in the form", systemImage: "sparkles")
                        if isFilling {
                            Spacer()
                            ProgressView().accessibilityHidden(true)
                        }
                    }
                }
                .disabled(isFilling || !hasNote)
            }

            Section("Expense") {
                LabeledContent("Merchant") {
                    TextField("Merchant", text: $draft.merchant).multilineTextAlignment(.trailing)
                }
                LabeledContent("Amount") {
                    TextField("Amount", value: $draft.amount, format: .currency(code: currencyCode))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                Picker("Category", selection: $draft.category) {
                    ForEach(StructuredOutputFormCategory.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                LabeledContent("Purpose") {
                    TextField("Purpose", text: $draft.purpose).multilineTextAlignment(.trailing)
                }
            }
            .disabled(isFilling)

            if didFail {
                Section {
                    Label(failureMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear { fillTask?.cancel() }
    }

    private func fill() async {
        didFail = false
        defer { isFilling = false }

        let previous = draft
        draft = StructuredOutputFormDraft()

        do {
            if let sampleStream {
                for try await partial in sampleStream(note) { draft = partial }
            } else {
                try await fillFromModel()
            }
        } catch {
            draft = previous
            guard !Task.isCancelled else { return }
            didFail = true
        }
    }

    private func fillFromModel() async throws {
        do {
            guard SystemLanguageModel.default.isAvailable else { throw ModelUnavailable() }
            let session = LanguageModelSession(instructions: "Extract an expense from the note. Do not invent values.")
            let stream = session.streamResponse(
                to: note,
                generating: StructuredOutputFormExpense.self,
                contextOptions: ContextOptions(includeSchemaInPrompt: true)
            )
            for try await snapshot in stream { apply(snapshot.content) }
        } catch {
            guard let fallbackStream, !Task.isCancelled else { throw error }
            draft = StructuredOutputFormDraft()
            for try await partial in fallbackStream(note) { draft = partial }
        }
    }

    /// Fields arrive one by one, so a field stays as it is until its value exists.
    private func apply(_ partial: StructuredOutputFormExpense.PartiallyGenerated) {
        draft.merchant = partial.merchant ?? draft.merchant
        draft.amount = partial.amount ?? draft.amount
        draft.category = partial.category ?? draft.category
        draft.purpose = partial.purpose ?? draft.purpose
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct StructuredOutputFormDemo: View {
    @State private var note = "Lunch with Ana at Casa Lucio, 48.50 for the team offsite"
    @State private var draft = StructuredOutputFormDraft()
    @State private var isPlayingSample = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            StructuredOutputForm(note: $note, draft: $draft, fallbackStream: sample)

            if isPlayingSample {
                Text("The on-device model can't answer here, so this demo plays sample values.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .tint(.indigo)
    }

    private func sample(_ note: String) -> AsyncThrowingStream<StructuredOutputFormDraft, Error> {
        isPlayingSample = true
        let steps: [StructuredOutputFormDraft] = [
            .init(merchant: "Casa Lucio"),
            .init(merchant: "Casa Lucio", amount: 48.5),
            .init(merchant: "Casa Lucio", amount: 48.5, category: .food),
            .init(merchant: "Casa Lucio", amount: 48.5, category: .food, purpose: "Team offsite lunch"),
        ]
        let instant = reduceMotion
        return AsyncThrowingStream { continuation in
            let task = Task {
                for step in instant ? Array(steps.suffix(1)) : steps {
                    if !instant {
                        try? await Task.sleep(for: .milliseconds(550))
                        guard !Task.isCancelled else { return }
                    }
                    continuation.yield(step)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

@available(iOS 27, *)
#Preview {
    StructuredOutputFormDemo()
}
