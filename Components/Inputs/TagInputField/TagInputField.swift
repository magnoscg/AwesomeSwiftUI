// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum TagInputFieldLogic {
    /// An invisible character the field always keeps before the typed text. Deleting it is how a
    /// backspace in an empty field is noticed, which `TextField` does not report.
    static let marker = "\u{200B}"
    static let separators: Set<Character> = [",", "\n"]

    /// `tags` with the new ones at the end, trimmed, leaving out the empty and the repeated.
    static func adding(_ new: [String], to tags: [String]) -> [String] {
        new.reduce(into: tags) { tags, candidate in
            let tag = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
            tags.append(tag)
        }
    }

    /// What the field does when its text goes from `old` to `new`: the tags it leaves and the text it keeps.
    ///
    /// A separator turns what comes before it into tags, so pasting "red, green" adds two.
    /// A backspace with nothing typed removes the last tag.
    static func typing(_ new: String, after old: String, tags: [String]) -> (tags: [String], text: String) {
        if old == marker, new.isEmpty { return (Array(tags.dropLast()), marker) }

        let typed = new.replacingOccurrences(of: marker, with: "")
        let pieces = typed.split(omittingEmptySubsequences: false) { separators.contains($0) }.map(String.init)
        // Text that only lacks a separator is left as it is, wherever its marker sits: rewriting the
        // field while keys are still arriving loses some of them.
        if pieces.count == 1, new.count == typed.count + 1 { return (tags, new) }

        let rest = String((pieces.last ?? "").drop { $0 == " " })
        return (adding(Array(pieces.dropLast()), to: tags), marker + rest)
    }

    /// Where each view goes: one after another, on a new line when one does not fit.
    /// The last one is the text field, which takes what is left of its line.
    static func frames(sizes: [CGSize], width: CGFloat, spacing: CGFloat, fieldMinWidth: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            let isField = index == sizes.count - 1
            var size = CGSize(width: isField ? fieldMinWidth : min(size.width, width), height: size.height)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            if isField, width.isFinite { size.width = max(width - x, fieldMinWidth) }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return frames
    }
}

/// A field that turns what you type into tags: press return or type a comma to add one, tap its
/// cross to remove it, or press delete in the empty field to remove the last one.
///
/// The tags wrap onto as many lines as they need and the field follows them. Repeated tags are
/// left out. VoiceOver reads each tag with a Remove action. Keyboard options such as
/// `autocorrectionDisabled` reach the field when set on this view.
struct TagInputField: View {
    @Binding var tags: [String]
    var prompt = "Add a tag"

    private let cornerRadius: CGFloat = 14

    @State private var text = TagInputFieldLogic.marker
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TagInputFieldFlow {
            ForEach(tags, id: \.self) { tag in
                chip(tag)
            }

            TextField("", text: $text)
                .focused($isFocused)
                .font(.subheadline)
                .padding(.vertical, 6)
                .background(alignment: .leading) {
                    // The marker keeps the field from ever being empty, so it cannot show a prompt of its own.
                    if text == TagInputFieldLogic.marker {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(prompt)
                .onSubmit {
                    apply(TagInputFieldLogic.typing(text + ",", after: text, tags: tags))
                    isFocused = true
                }
        }
        .padding(10)
        .background(.fill.quaternary, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.tint, lineWidth: isFocused ? 2 : 0)
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: tags)
        .onChange(of: text) { old, new in
            apply(TagInputFieldLogic.typing(new, after: old, tags: tags))
        }
    }

    private func chip(_ tag: String) -> some View {
        HStack(spacing: 2) {
            Text(tag)
                .lineLimit(1)

            Button {
                tags.removeAll { $0 == tag }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 24, minHeight: 20)
                    // Too small to hit. The padding widens what answers to a touch, and the
                    // same padding taken back keeps the tag as compact as it was.
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                    .padding(.horizontal, -10)
                    .padding(.vertical, -12)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline.weight(.medium))
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 6)
        .background(.tint.opacity(0.16), in: .capsule)
        .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tag)
        .accessibilityAction(named: "Remove") {
            tags.removeAll { $0 == tag }
        }
    }

    private func apply(_ result: (tags: [String], text: String)) {
        if result.tags != tags { tags = result.tags }
        if result.text != text { text = result.text }
    }
}

private nonisolated struct TagInputFieldFlow: Layout {
    var spacing: CGFloat = 8
    var fieldMinWidth: CGFloat = 96

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = frames(of: subviews, in: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? (frames.map(\.maxX).max() ?? 0), height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(of: subviews, in: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(of subviews: Subviews, in width: CGFloat) -> [CGRect] {
        TagInputFieldLogic.frames(sizes: subviews.map { $0.sizeThatFits(.unspecified) }, width: width, spacing: spacing, fieldMinWidth: fieldMinWidth)
    }
}

// MARK: - Demo

struct TagInputFieldDemo: View {
    private let suggestions = ["spicy", "gluten-free", "30 minutes", "one pot"]

    @State private var tags = ["vegan", "dinner", "weeknight"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recipe tags")
                    .font(.title2.bold())
                Text("Press return or type a comma to add one")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TagInputField(tags: $tags)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(suggestions.filter { !tags.contains($0) }, id: \.self) { suggestion in
                            Button {
                                tags = TagInputFieldLogic.adding([suggestion], to: tags)
                            } label: {
                                Label(suggestion, systemImage: "plus")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .tint(.teal)
    }
}

#Preview {
    TagInputFieldDemo()
}
