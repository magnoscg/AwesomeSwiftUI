// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A stack of sections where opening one closes the others. Bind `expandedID`
/// to open or close a section from outside.
struct AccordionSection<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    @Binding var expandedID: Data.Element.ID?
    let title: (Data.Element) -> String
    @ViewBuilder let content: (Data.Element) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(spacing: 10) {
            ForEach(data) { element in
                section(element)
            }
        }
    }

    private func section(_ element: Data.Element) -> some View {
        let isExpanded = expandedID == element.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.32)) {
                    expandedID = isExpanded ? nil : element.id
                }
            } label: {
                HStack {
                    Text(title(element))
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 12)
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(16)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title(element))
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                content(element)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .bottom], 16)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background, in: .rect(cornerRadius: cornerRadius, style: .continuous))
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Demo

struct AccordionSectionDemo: View {
    private struct Question: Identifiable {
        let id: String
        let answer: String
    }

    private static let questions = [
        Question(id: "Can I copy the code?", answer: "Yes. Every component is one file that you paste into your app."),
        Question(id: "Does it need a package?", answer: "No. There is nothing to install and nothing to keep up to date."),
        Question(id: "Which iOS does it need?", answer: "Most components run on iOS 18, and newer ones say so in their metadata."),
    ]

    @State private var expandedID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Questions")
                    .font(.largeTitle.bold())

                AccordionSection(data: Self.questions, expandedID: $expandedID, title: \.id) { question in
                    Text(question.answer)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .background(LinearGradient(colors: [.indigo.opacity(0.14), .teal.opacity(0.1)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    AccordionSectionDemo()
}
