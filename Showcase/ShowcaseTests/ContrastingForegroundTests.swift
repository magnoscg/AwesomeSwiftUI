// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI
import Testing
@testable import Showcase

/// Every component that draws over a color it is given carries its own copy of
/// the style, because a component is one file. This runs the same cases on each.
struct ContrastingForegroundTests {
    private static let styles: [(String, @Sendable (Color) -> Color)] = [
        ("AddToCartStepper", { AddToCartStepperContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("AnimatedBadgeCount", { AnimatedBadgeCountContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("BadgedIconButton", { BadgedIconButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ButtonVariantStyle", { ButtonVariantStyleContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("CheckmarkBoxToggleStyle", { CheckmarkBoxToggleStyleContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("CompletionSwipeRow", { CompletionSwipeRowContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("DayScheduleTimeline", { DayScheduleTimelineContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("DownloadPillProgress", { DownloadPillProgressContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ElasticDragButton", { ElasticDragButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ExpandableInfoCard", { ExpandableInfoCardContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("FloatingActionMenu", { FloatingActionMenuContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("GooeyFloatingMenu", { GooeyFloatingMenuContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("HoldToConfirmButton", { HoldToConfirmButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("KeyboardTrackingInputBar", { KeyboardTrackingInputBarContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("LiquidFillProgress", { LiquidFillProgressContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("MapClusterAnnotations", { MapClusterAnnotationsContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("MorphingSubmitButton", { MorphingSubmitButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("NestedCommentThread", { NestedCommentThreadContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("PermissionPrimerScreen", { PermissionPrimerScreenContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("PulseRingButton", { PulseRingButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ScrollToTopButton", { ScrollToTopButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("SlotMachineReels", { SlotMachineReelsContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("SelectAllChecklist", { SelectAllChecklistContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("SettingsToggleRow", { SettingsToggleRowContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("ShrinkingExtendedButton", { ShrinkingExtendedButtonContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("SwipeActionRow", { SwipeActionRowContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("TooltipPopover", { TooltipPopoverContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
        ("VerticalTimeline", { VerticalTimelineContrastingForeground(background: $0).resolve(in: EnvironmentValues()) }),
    ]

    @Test(arguments: styles.indices)
    func aLightColorGetsBlack(index: Int) {
        let foreground = Self.styles[index].1

        #expect(foreground(.white) == .black)
        #expect(foreground(.yellow) == .black)
        #expect(foreground(Color(red: 0.8, green: 0.9, blue: 1)) == .black)
    }

    @Test(arguments: styles.indices)
    func aDarkOrSaturatedColorKeepsWhite(index: Int) {
        let foreground = Self.styles[index].1

        #expect(foreground(.black) == .white)
        #expect(foreground(.blue) == .white)
        #expect(foreground(.indigo) == .white)
        #expect(foreground(.red) == .white)
        #expect(foreground(.green) == .white)
        #expect(foreground(.orange) == .white)
    }
}
