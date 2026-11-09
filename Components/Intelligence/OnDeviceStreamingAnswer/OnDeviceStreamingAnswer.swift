// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import FoundationModels
import SwiftUI

/// An answer that fills in while the on-device model writes it, with no network request.
///
/// Changing `prompt` cancels the answer in progress and starts a new one.
/// An empty prompt shows `placeholder`.
@available(iOS 26, *)
struct OnDeviceStreamingAnswer: View {
    private enum Phase: Equatable {
        case idle, streaming, finished, failed
    }

    private struct ModelUnavailable: Error {}

    let prompt: String
    var instructions = "Answer in two short, friendly sentences."
    var placeholder = "Ask something to see the answer here."
    /// Replaces the model with your own text stream, for previews and for tests.
    /// Each element is the whole text so far.
    var sampleStream: (@MainActor (String) -> AsyncThrowingStream<String, Error>)? = nil
    /// Plays instead of an error when the model is unavailable or fails.
    /// Each element is the whole text so far.
    var fallbackStream: (@MainActor (String) -> AsyncThrowingStream<String, Error>)? = nil
    var failureMessage = "The on-device model couldn't answer right now. Please try again later."

    @State private var text = ""
    @State private var phase = Phase.idle
    @State private var answeredPrompt: String?
    @State private var preparedSession: LanguageModelSession?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isStreaming: Bool { phase == .streaming }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(isStreaming ? "Writing on your device" : "On-device answer", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: isStreaming && !reduceMotion)

            content
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: 20, style: .continuous))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: text)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("On-device answer")
        .accessibilityValue(accessibilityValue)
        .task {
            guard sampleStream == nil, SystemLanguageModel.default.isAvailable else { return }
            let session = LanguageModelSession(instructions: instructions)
            session.prewarm()
            preparedSession = session
        }
        .task(id: trimmedPrompt) { await answer() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            Text(placeholder).foregroundStyle(.secondary)
        case .streaming:
            Text("\(Text(text))\(Text(" ▍").foregroundStyle(.tint))")
        case .finished:
            Text(text).textSelection(.enabled)
        case .failed:
            Text(failureMessage).foregroundStyle(.secondary)
        }
    }

    private var accessibilityValue: String {
        switch phase {
        case .idle: placeholder
        case .streaming: "Writing"
        case .finished: text
        case .failed: failureMessage
        }
    }

    private func answer() async {
        // `.task` runs again when the view reappears. A finished answer stays.
        guard trimmedPrompt != answeredPrompt else { return }
        answeredPrompt = nil
        text = ""
        guard !trimmedPrompt.isEmpty else {
            phase = .idle
            return
        }
        phase = .streaming

        do {
            if let sampleStream {
                for try await partial in sampleStream(trimmedPrompt) { text = partial }
            } else {
                try await streamFromModel()
            }
            guard !Task.isCancelled else { return }
            phase = .finished
            answeredPrompt = trimmedPrompt
            AccessibilityNotification.Announcement(text).post()
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }

    private func streamFromModel() async throws {
        do {
            guard SystemLanguageModel.default.isAvailable else { throw ModelUnavailable() }
            // Every answer gets its own session, so old turns never fill its context window.
            let session = preparedSession ?? LanguageModelSession(instructions: instructions)
            preparedSession = nil
            for try await snapshot in session.streamResponse(to: trimmedPrompt) { text = snapshot.content }
        } catch {
            guard let fallbackStream, !Task.isCancelled else { throw error }
            for try await partial in fallbackStream(trimmedPrompt) { text = partial }
        }
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct OnDeviceStreamingAnswerDemo: View {
    private static let questions: [(question: String, answer: String)] = [
        ("Why is the sky blue?", "Air scatters blue light far more than red light. That scattered blue reaches your eyes from every direction, so the whole sky glows."),
        ("Why is the sea salty?", "Rain slowly dissolves minerals from rocks and rivers carry them to the sea. The water evaporates, but the salt stays behind."),
    ]

    @State private var prompt = ""
    @State private var isPlayingSample = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Ask the device")
                    .font(.largeTitle.bold())

                ForEach(Self.questions, id: \.question) { item in
                    Button(item.question) { prompt = item.question }
                        .buttonStyle(.bordered)
                        .tint(.indigo)
                }

                OnDeviceStreamingAnswer(prompt: prompt, fallbackStream: sample)
                    .tint(.indigo)

                if isPlayingSample {
                    Text("The on-device model can't answer here, so this demo plays sample text.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.16), .mint.opacity(0.12)], startPoint: .top, endPoint: .bottom))
    }

    private func sample(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        isPlayingSample = true
        let answer = Self.questions.first { $0.question == prompt }?.answer ?? ""
        let instant = reduceMotion
        return AsyncThrowingStream { continuation in
            let task = Task {
                guard !instant else {
                    continuation.yield(answer)
                    continuation.finish()
                    return
                }
                var written = ""
                for word in answer.split(separator: " ") {
                    try? await Task.sleep(for: .milliseconds(90))
                    guard !Task.isCancelled else { return }
                    written += written.isEmpty ? String(word) : " \(word)"
                    continuation.yield(written)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

@available(iOS 26, *)
#Preview {
    OnDeviceStreamingAnswerDemo()
}
