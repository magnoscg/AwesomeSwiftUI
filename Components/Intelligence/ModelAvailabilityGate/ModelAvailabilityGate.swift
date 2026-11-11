// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import FoundationModels
import SwiftUI

/// Shows its content when the on-device model can answer. Otherwise it explains
/// why not and what the person can do.
///
/// The system does not notify changes in availability, so the view checks again
/// when the app becomes active and every few seconds while the model downloads.
@available(iOS 26, *)
struct ModelAvailabilityGate<Content: View>: View {
    /// Leave it `nil` to read the real model. Pass a value to force a state.
    var availability: SystemLanguageModel.Availability? = nil
    @ViewBuilder var content: () -> Content

    @State private var liveAvailability = SystemLanguageModel.default.availability
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch availability ?? liveAvailability {
            case .available:
                content()
            case .unavailable(let reason):
                // A long explanation at the largest text sizes stays reachable.
                ViewThatFits(in: .vertical) {
                    explanation(for: reason)
                    ScrollView { explanation(for: reason) }
                }
            }
        }
        .task(id: scenePhase) {
            guard availability == nil else { return }
            liveAvailability = SystemLanguageModel.default.availability
            while liveAvailability == .unavailable(.modelNotReady) {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                liveAvailability = SystemLanguageModel.default.availability
            }
        }
    }

    @ViewBuilder
    private func explanation(for reason: SystemLanguageModel.Availability.UnavailableReason) -> some View {
        switch reason {
        case .deviceNotEligible:
            ContentUnavailableView(
                "Not available on this device",
                systemImage: "iphone.slash",
                description: Text("This feature needs a device that supports Apple Intelligence. Everything else in the app keeps working.")
            )
        case .appleIntelligenceNotEnabled:
            ContentUnavailableView(
                "Apple Intelligence is off",
                systemImage: "sparkles",
                description: Text("Open the Settings app, turn on Apple Intelligence, then come back to use this feature.")
            )
        case .modelNotReady:
            ContentUnavailableView {
                Label("Getting the model ready", systemImage: "arrow.down.circle")
            } description: {
                Text("The model is still downloading. This screen updates by itself when it finishes.")
            } actions: {
                ProgressView()
                    .accessibilityLabel("Preparing the model")
            }
        @unknown default:
            ContentUnavailableView(
                "Not available right now",
                systemImage: "exclamationmark.circle",
                description: Text("The on-device model cannot answer at the moment. Try again later.")
            )
        }
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct ModelAvailabilityGateDemo: View {
    private enum Sample: String, CaseIterable, Identifiable {
        case ready = "Ready"
        case device = "Device"
        case off = "Off"
        case preparing = "Preparing"

        var id: Self { self }

        var availability: SystemLanguageModel.Availability {
            switch self {
            case .ready: .available
            case .device: .unavailable(.deviceNotEligible)
            case .off: .unavailable(.appleIntelligenceNotEnabled)
            case .preparing: .unavailable(.modelNotReady)
            }
        }
    }

    @State private var sample = Sample.device
    @State private var autoPlays = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pickerSelection: Binding<Sample> {
        Binding(get: { sample }, set: { newValue in
            autoPlays = false
            sample = newValue
        })
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.background)
                    .shadow(color: .indigo.opacity(0.18), radius: 22, y: 10)
                    .accessibilityHidden(true)

                ModelAvailabilityGate(availability: sample.availability) {
                    VStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(.indigo.gradient)
                            .accessibilityHidden(true)
                        Text("The model is ready")
                            .font(.title2.bold())
                        Text("Your feature appears here.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(sample)
                .transition(.opacity)
            }

            Picker("Availability", selection: pickerSelection) {
                ForEach(Sample.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .padding(20)
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .teal.opacity(0.1)], startPoint: .top, endPoint: .bottom))
        .task(id: autoPlays && !reduceMotion) {
            guard autoPlays, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                let all = Sample.allCases
                let next = ((all.firstIndex(of: sample) ?? 0) + 1) % all.count
                withAnimation(.smooth(duration: 0.3)) { sample = all[next] }
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    ModelAvailabilityGateDemo()
}
