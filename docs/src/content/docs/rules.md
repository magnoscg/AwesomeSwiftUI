---
title: The rules every component keeps
description: What you can count on when you copy a component from the catalog.
sidebar:
  label: Rules
---

Every component in the catalog keeps the same rules, and the repository
checks most of them on every change. They are what lets you copy a file
without reading it first.

## One file to copy

A component, its demo and its `#Preview` live in one Swift file. It imports
no other component, no package and no asset.

The one exception is a component drawn by a Metal shader, because SwiftUI
loads only compiled Metal. It has a second file, `<Name>.metal`, and its page
shows both. Every function in a shader starts with the name of its component,
so two shaders never collide in your target.

## Swift 6, in either kind of project

Components are written in the Swift 6 language mode with complete concurrency
checking. Each one compiles in a project with no default actor isolation and
in one that isolates to the main actor by default, as new Xcode projects do.
Both are built on every change.

State uses `@Observable`. Nothing in the catalog uses `ObservableObject`,
`@StateObject` or `@Published`.

## Nothing deprecated

Warnings are errors where the components are built. A component uses the
current Apple API for the iOS versions it claims.

## Honest about versions

iOS 18 is the baseline. A component that needs a newer iOS marks its types
with `@available` and states the same version on its page. It adds a fallback
only where one is natural, so you decide what older versions see.

## Accessible

Reduce Motion, Dynamic Type, VoiceOver, touch areas of 44 points and
right-to-left layouts. [Accessibility](/swiftui-components/accessibility/)
says what each of those means in practice.

## Ready to localize

A text you pass to a component to be shown or read aloud is a
`LocalizedStringResource`, so a literal at the call site lands in the String
Catalog of your app. Data stays a `String`: a name, a message, the name of a
symbol.

## Internal, and named apart

Nothing is `public`: the code lands inside your app. Supporting types carry
the name of their component or are `private`, so copying two components never
gives you two types with the same name.

## A preview that moves

Every component has an animated preview, recorded from the demo in its file.
What you see on its page is what the code does.

## A clean origin

Each component is original work, or adapts code under a compatible license
with its notice kept, and its page says which. Ideas from elsewhere are
credited with a link and written from scratch.
