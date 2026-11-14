// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI
import WebKit

nonisolated enum EmbeddedWebBrowserLogic {
    /// The address to load for what was typed: as it is when it names its scheme, with `https`
    /// in front when it looks like a host, and nothing when it is neither.
    static func url(from text: String) -> URL? {
        let typed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty, !typed.contains(where: \.isWhitespace) else { return nil }
        if let url = URL(string: typed), let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()), url.host() != nil {
            return url
        }
        guard !typed.contains("://"), typed.contains("."), !typed.hasPrefix("."), !typed.hasSuffix(".") else { return nil }
        return URL(string: "https://\(typed)")
    }

    /// What the address bar shows for a page: its host, without `www.`, or nothing for a page with no address.
    static func host(of url: URL?) -> String {
        guard let host = url?.host() else { return "" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

/// A small browser inside the app: a web page with an address bar, back, forward and reload,
/// and a line that fills while the page loads. It is built on the `WebView` and `WebPage`
/// that iOS 26 added, with no UIKit.
///
/// Create the `WebPage`, load what it should start on, and hand it over.
@available(iOS 26, *)
struct EmbeddedWebBrowser: View {
    let page: WebPage

    @State private var address = ""
    @State private var selection: TextSelection?
    @FocusState private var isEditing: Bool

    private let touchTarget: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            WebView(page)

            if page.isLoading {
                ProgressView(value: page.estimatedProgress)
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Loading page")
            }

            HStack(spacing: 2) {
                barButton("Back", systemImage: "chevron.backward") {
                    if let item = page.backForwardList.backList.last { _ = page.load(item) }
                }
                .disabled(page.backForwardList.backList.isEmpty)

                barButton("Forward", systemImage: "chevron.forward") {
                    if let item = page.backForwardList.forwardList.first { _ = page.load(item) }
                }
                .disabled(page.backForwardList.forwardList.isEmpty)

                TextField("Address", text: $address, selection: $selection)
                    .focused($isEditing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .multilineTextAlignment(isEditing ? .leading : .center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.fill.tertiary, in: .capsule)
                    .onSubmit {
                        if let url = EmbeddedWebBrowserLogic.url(from: address) { _ = page.load(url) }
                    }

                barButton(page.isLoading ? "Stop" : "Reload", systemImage: page.isLoading ? "xmark" : "arrow.clockwise") {
                    if page.isLoading {
                        page.stopLoading()
                    } else {
                        _ = page.reload()
                    }
                }
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.bar)
        }
        .onChange(of: page.url, initial: true) { _, url in
            if !isEditing { address = EmbeddedWebBrowserLogic.host(of: url) }
        }
        .onChange(of: isEditing) { _, editing in
            address = editing ? (page.url?.absoluteString ?? "") : EmbeddedWebBrowserLogic.host(of: page.url)
            // The whole address is selected, as in Safari, so typing replaces it.
            selection = editing ? TextSelection(range: address.startIndex..<address.endIndex) : nil
        }
    }

    /// An icon button with a touch target of the recommended size.
    private func barButton(_ title: LocalizedStringResource, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label { Text(title) } icon: { Image(systemName: systemImage) }
                .frame(minWidth: touchTarget, minHeight: touchTarget)
                .contentShape(.rect)
        }
    }
}

// MARK: - Demo

/// Serves the pages of the demo from the app under a scheme of its own, so it needs no network
/// and its links are real navigations, with a way back.
@available(iOS 26, *)
private nonisolated struct EmbeddedWebBrowserDemoPages: URLSchemeHandler {
    private static let walks = [
        "cliffs": ("The cliffs", "An hour along the edge, with the wind for company and gulls below your feet."),
        "lighthouse": ("The lighthouse", "Flat and easy. Go at dusk, when the lamp starts to turn."),
        "marsh": ("The marsh", "Boardwalks over still water. Bring binoculars and patience."),
    ]

    func reply(for request: URLRequest) -> AsyncThrowingStream<URLSchemeTaskResult, any Error> {
        AsyncThrowingStream { continuation in
            guard let url = request.url else { return continuation.finish(throwing: URLError(.badURL)) }
            let data = Data(Self.html(for: url.host() ?? "").utf8)
            continuation.yield(.response(URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8")))
            continuation.yield(.data(data))
            continuation.finish()
        }
    }

    private static func html(for page: String) -> String {
        let content: String
        if let walk = walks[page] {
            content = "<h1>\(walk.0)</h1><p>\(walk.1)</p><a href=\"guide://home\">&larr; All walks</a>"
        } else {
            let links = walks.keys.sorted().map { "<a href=\"guide://\($0)\">\(walks[$0]?.0 ?? "") &rarr;</a>" }.joined()
            content = "<h1>Field Guide</h1><p>Three short walks near the harbor. Pick one to read about it.</p>\(links)"
        }
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body { font: -apple-system-body; margin: 0; padding: 24px; color-scheme: light dark; }
        h1 { font: -apple-system-title1; font-weight: 700; margin: 0 0 8px; }
        p { line-height: 1.5; opacity: .8; }
        a { display: block; padding: 16px; margin: 12px 0; border-radius: 16px; background: color-mix(in srgb, CanvasText 8%, transparent); color: inherit; text-decoration: none; font-weight: 600; }
        </style></head><body>\(content)</body></html>
        """
    }
}

@available(iOS 26, *)
struct EmbeddedWebBrowserDemo: View {
    @State private var page: WebPage = {
        var configuration = WebPage.Configuration()
        if let scheme = URLScheme("guide") {
            configuration.urlSchemeHandlers[scheme] = EmbeddedWebBrowserDemoPages()
        }
        return WebPage(configuration: configuration)
    }()

    var body: some View {
        EmbeddedWebBrowser(page: page)
            .task {
                if page.url == nil { _ = page.load(URL(string: "guide://home")) }
            }
    }
}

@available(iOS 26, *)
#Preview {
    EmbeddedWebBrowserDemo()
}
