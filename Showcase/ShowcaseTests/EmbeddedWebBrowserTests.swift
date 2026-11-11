// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Foundation
import Testing
@testable import Showcase

struct EmbeddedWebBrowserTests {
    @Test func anAddressWithItsSchemeIsLoadedAsItIs() {
        #expect(EmbeddedWebBrowserLogic.url(from: "https://example.com/path?x=1")?.absoluteString == "https://example.com/path?x=1")
        #expect(EmbeddedWebBrowserLogic.url(from: "HTTP://example.com")?.host() == "example.com")
    }

    @Test func aHostGetsHTTPSInFront() {
        #expect(EmbeddedWebBrowserLogic.url(from: "example.com")?.absoluteString == "https://example.com")
        #expect(EmbeddedWebBrowserLogic.url(from: "  docs.example.com/guide \n")?.absoluteString == "https://docs.example.com/guide")
    }

    @Test func textThatIsNotAnAddressLoadsNothing() {
        #expect(EmbeddedWebBrowserLogic.url(from: "") == nil)
        #expect(EmbeddedWebBrowserLogic.url(from: "night train") == nil)
        #expect(EmbeddedWebBrowserLogic.url(from: "harbor") == nil)
        #expect(EmbeddedWebBrowserLogic.url(from: ".com") == nil)
        #expect(EmbeddedWebBrowserLogic.url(from: "example.") == nil)
    }

    @Test func otherSchemesAreNotLoaded() {
        #expect(EmbeddedWebBrowserLogic.url(from: "file:///etc/hosts") == nil)
        #expect(EmbeddedWebBrowserLogic.url(from: "javascript://example.com") == nil)
    }

    @Test func theBarShowsTheHostWithoutWWW() {
        #expect(EmbeddedWebBrowserLogic.host(of: URL(string: "https://www.example.com/a/b")) == "example.com")
        #expect(EmbeddedWebBrowserLogic.host(of: URL(string: "https://docs.example.com")) == "docs.example.com")
    }

    @Test func aPageWithNoAddressShowsNothing() {
        #expect(EmbeddedWebBrowserLogic.host(of: nil) == "")
        #expect(EmbeddedWebBrowserLogic.host(of: URL(string: "about:blank")) == "")
    }
}
