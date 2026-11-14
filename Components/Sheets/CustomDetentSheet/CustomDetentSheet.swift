// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// A system sheet that snaps between custom heights with `presentationDetents`.
///
/// Set `interactiveUpThrough` to keep the content behind usable up to that height. The
/// system sheet animation already honours Reduce Motion.
struct CustomDetentSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var detents: Set<PresentationDetent>
    @Binding var selection: PresentationDetent
    var interactiveUpThrough: PresentationDetent?
    @ViewBuilder var sheetContent: () -> SheetContent

    private var backgroundInteraction: PresentationBackgroundInteraction {
        interactiveUpThrough.map { .enabled(upThrough: $0) } ?? .automatic
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            sheetContent()
                .presentationDetents(detents.isEmpty ? [selection] : detents, selection: $selection)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(backgroundInteraction)
                .presentationCornerRadius(30)
        }
    }
}

extension View {
    func customDetentSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent>,
        selection: Binding<PresentationDetent>,
        interactiveUpThrough: PresentationDetent? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(CustomDetentSheet(
            isPresented: isPresented,
            detents: detents,
            selection: selection,
            interactiveUpThrough: interactiveUpThrough,
            sheetContent: content
        ))
    }
}

// MARK: - Demo

private struct CustomDetentSheetPeek: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        guard context.maxDetentValue > 0 else { return nil }
        return max(context.maxDetentValue * 0.22, min(context.maxDetentValue, 150))
    }
}

struct CustomDetentSheetDemo: View {
    private let peek = PresentationDetent.custom(CustomDetentSheetPeek.self)
    private let middle = PresentationDetent.height(400)
    private let stops = ["Museum", "Old town", "Riverside", "Market", "Viewpoint", "Harbour"]

    @State private var isPresented = false
    @State private var selection = PresentationDetent.height(400)
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal, .blue, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("City walk")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Button("Show stops") { isPresented = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
        }
        .customDetentSheet(
            isPresented: $isPresented,
            detents: [peek, middle, .large],
            selection: $selection,
            interactiveUpThrough: peek
        ) {
            sheet
        }
        .simultaneousGesture(stopAutoPlay)
        .task { isPresented = true }
        .task(id: isPresented && !reduceMotion) {
            guard isPresented, !reduceMotion else { return }
            await cycleDetents()
        }
    }

    private var sheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today's stops")
                    .font(.title2.bold())

                ForEach(stops, id: \.self) { stop in
                    Label(stop, systemImage: "mappin.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 16))
                }
            }
            .padding(24)
        }
        // The sheet is its own presentation, so a touch in it does not reach the gesture behind.
        .simultaneousGesture(stopAutoPlay)
    }

    private var stopAutoPlay: some Gesture {
        DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false }
    }

    // Only the demo moves the sheet by itself, by changing the selected detent.
    private func cycleDetents() async {
        let order = [peek, middle, .large, middle]
        var index = 0
        var expected = selection
        while isAutoPlaying {
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled, isAutoPlaying else { return }
            // Dragging the sheet by its grabber does not touch its content, but it changes the detent.
            guard selection == expected else {
                isAutoPlaying = false
                return
            }
            expected = order[index]
            withAnimation(.snappy(duration: 0.4)) {
                selection = expected
            }
            index = (index + 1) % order.count
        }
    }
}

#Preview {
    CustomDetentSheetDemo()
}
