// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum RichTextEditorLogic {
    /// How many words a text has, whatever its formatting.
    static func wordCount(of text: AttributedString) -> Int {
        String(text.characters).split { $0.isWhitespace || $0.isNewline }.count
    }

    /// The highlight a tap leaves: the color tapped, or none when the text already had it.
    static func toggled<Value: Equatable>(_ current: Value?, choosing value: Value) -> Value? {
        current == value ? nil : value
    }
}

/// A text editor with a bar to make the selection bold, italic, underlined, struck through or
/// highlighted, on the rich text editing that iOS 26 added to `TextEditor`.
///
/// It edits an `AttributedString`. With no selection, the bar changes what is typed next, and
/// each button shows whether its format is on at the cursor.
@available(iOS 26, *)
struct RichTextEditor: View {
    @Binding var text: AttributedString
    var highlights: [Color] = [.yellow, .green, .pink]

    private let buttonSize: CGFloat = 44

    @State private var selection = AttributedTextSelection()
    @Environment(\.fontResolutionContext) private var fontResolutionContext

    private var typing: AttributeContainer { selection.typingAttributes(in: text) }
    private var font: Font.Resolved { (typing.font ?? .body).resolve(in: fontResolutionContext) }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text, selection: $selection)
                .padding(.horizontal, 12)

            Divider()

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    // Each button reads its state once, so every run of the selection ends the same.
                    let isBold = font.isBold
                    let isItalic = font.isItalic
                    let isUnderlined = typing.underlineStyle != nil
                    let isStruck = typing.strikethroughStyle != nil

                    toggle("Bold", symbol: "bold", isOn: isBold) { attributes in
                        attributes.font = (attributes.font ?? .body).bold(!isBold)
                    }
                    toggle("Italic", symbol: "italic", isOn: isItalic) { attributes in
                        attributes.font = (attributes.font ?? .body).italic(!isItalic)
                    }
                    toggle("Underline", symbol: "underline", isOn: isUnderlined) { attributes in
                        attributes.underlineStyle = isUnderlined ? nil : .single
                    }
                    toggle("Strikethrough", symbol: "strikethrough", isOn: isStruck) { attributes in
                        attributes.strikethroughStyle = isStruck ? nil : .single
                    }

                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, 4)

                    ForEach(highlights, id: \.self) { color in
                        Button {
                            let highlight = RichTextEditorLogic.toggled(typing.backgroundColor, choosing: color.opacity(0.4))
                            apply { $0.backgroundColor = highlight }
                        } label: {
                            Image(systemName: "highlighter")
                                .frame(width: buttonSize, height: buttonSize)
                                .background(color.opacity(0.4), in: .rect(cornerRadius: 10))
                        }
                        .accessibilityLabel("Highlight in \(color.description)")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .buttonStyle(.plain)
        }
    }

    /// Changes every run of the selection on its own attributes, so a run keeps what makes it
    /// different, like the size of a title. With no selection it changes what is typed next.
    private func apply(_ change: (inout AttributeContainer) -> Void) {
        guard case .ranges(let ranges) = selection.indices(in: text), !ranges.isEmpty else {
            text.transformAttributes(in: &selection, body: change)
            return
        }
        // Indices do not survive a change, so the selection is kept as offsets and put back.
        let offsets = ranges.ranges.map { range in
            (
                text.characters.distance(from: text.startIndex, to: range.lowerBound),
                text.characters.distance(from: text.startIndex, to: range.upperBound)
            )
        }
        for (lower, upper) in offsets {
            let range = text.index(text.startIndex, offsetByCharacters: lower)..<text.index(text.startIndex, offsetByCharacters: upper)
            for run in Array(text[range].runs) {
                var attributes = run.attributes
                change(&attributes)
                text[run.range].setAttributes(attributes)
            }
        }
        var selected = RangeSet<AttributedString.Index>()
        for (lower, upper) in offsets {
            selected.insert(contentsOf: text.index(text.startIndex, offsetByCharacters: lower)..<text.index(text.startIndex, offsetByCharacters: upper))
        }
        selection = AttributedTextSelection(ranges: selected)
    }

    private func toggle(_ title: String, symbol: String, isOn: Bool, change: @escaping (inout AttributeContainer) -> Void) -> some View {
        Button {
            apply(change)
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .rect(cornerRadius: 10))
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct RichTextEditorDemo: View {
    @State private var text: AttributedString = {
        var title = AttributedString("Trip notes\n")
        title.font = .title2.bold()
        var body = AttributedString("Book the night train before Friday. ")
        var important = AttributedString("Seats sell out fast.")
        important.backgroundColor = Color.yellow.opacity(0.4)
        body.append(important)
        return title + body
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RichTextEditor(text: $text)

            Text("\(RichTextEditorLogic.wordCount(of: text)) words")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .background(.background, in: .rect(cornerRadius: 22))
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 420)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
    }
}

@available(iOS 26, *)
#Preview {
    RichTextEditorDemo()
}
