---
title: Accessibility
description: What every component does for Reduce Motion, Dynamic Type, VoiceOver, touch and right-to-left layouts.
---

A component that looks good and leaves someone out is not finished. These
are the things every component in the catalog does, so you do not have to
add them after copying it.

## Reduce Motion

Each component reads `accessibilityReduceMotion`. With it on, movement that
carries no meaning stops or becomes a fade: a button dims in place, a
background stands still, a transition crosses over.

The documentation comment at the top of a component says what changes.

## Dynamic Type

Text uses the system text styles, and sizes that have to follow the text use
`@ScaledMetric`. A layout that cannot hold larger text in a row changes to a
column.

## VoiceOver

Anything that is not plain text has a label. A control made of several views
is read as one element, with its value and its actions. A drawing that only
decorates is hidden.

## Touch areas

Anything that takes a tap answers in an area of at least 44 by 44 points.
Where that size would break the design, like an icon inside a field, only
the area that answers grows, not what you see.

## Contrast over your colors

Content drawn over a color you choose takes white or black from that color.
A yellow tint gets black text, and the colors of the system keep white.

## Right-to-left

SwiftUI mirrors layout in a right-to-left language, but a gesture still
reports screen points. Components convert the gesture where they read it, so
a drag follows the finger in Arabic and Hebrew as it does in English.

Surfaces over a photo or a video stay left-to-right, because the picture is
not mirrored either.

## What has not been checked

The catalog is built and tested in the simulator. Listening to every
component with VoiceOver on a device, and feeling its haptics, has not been
done for all of them. If one reads badly,
[open an issue](https://github.com/magnoscg/swiftui-components/issues/new/choose).
