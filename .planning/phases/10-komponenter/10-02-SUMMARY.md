---
phase: 10-komponenter
plan: "02"
subsystem: ui
tags: [swiftui, designsystem, chat, bubble-pop, gradient, animation]

# Dependency graph
requires:
  - phase: 10-komponenter-01
    provides: AvatarView och DesignSystem-tokens (BubblePopColors, TemperatureZone, WeatherIconMapper)
  - phase: 09-design
    provides: Baloo2-font, BubblePopColors, BubblePopTypography, BubblePopSpacing, BubblePopShadows
provides:
  - BubblePopButton — återanvändbar pill-knapp med brand-gradient och bounce-animation
  - ChatBubbleView — gradient-styling på egna bubblor, vit/border på andras, asymmetrisk radius
  - WeatherStickerView — gradient-accent via TemperatureZone, WeatherIconMapper-ikon
affects: [onboarding, settings, all forms using primary action buttons]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - UnevenRoundedRectangle för pratbubbla-hake-känsla (iOS 16+)
    - DragGesture(minimumDistance:0) + scaleEffect för bounce utan ButtonStyle-konflikter
    - foregroundStyle(LinearGradient) för gradient-text på temperaturvärde

key-files:
  created:
    - HotAndColdFriends/DesignSystem/BubblePopButton.swift
  modified:
    - HotAndColdFriends/Features/Chat/ChatBubbleView.swift
    - HotAndColdFriends/Features/Chat/WeatherStickerView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "UnevenRoundedRectangle (iOS 16+) används för asymmetrisk border-radius — hak-känslan i nedre höger (egna) och övre vänster (andras)"
  - "foregroundStyle(Color.bubbleTextPrimary) explicit (inte .bubbleTextPrimary shorthand) — Swift kan inte resolva ShapeStyle extension via dot-notation"
  - "WeatherStickerView zone-property definieras som computed var istället för i body — renare separation"

patterns-established:
  - "BubblePopButton: DragGesture(minimumDistance:0) + simultaneousGesture för bounce utan att blockera ScrollView"
  - "Gradient-text: foregroundStyle(zone.gradient) på Text — fungerar utan Shader för iOS 16+"
  - "Sticker-border: overlay med gradient LinearGradient i strokeBorder ger levande kant"

requirements-completed: [COMP-02, COMP-03, COMP-04]

# Metrics
duration: 5min
completed: 2026-03-05
---

# Phase 10 Plan 02: Komponenter Summary

**BubblePopButton (pill+bounce), gradient ChatBubbleView (asymmetrisk radius) och gradient-accent WeatherStickerView med TemperatureZone-styling**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-05T07:08:06Z
- **Completed:** 2026-03-05T07:13:38Z
- **Tasks:** 2 (+ 1 checkpoint:human-verify)
- **Files modified:** 4

## Accomplishments

- Ny `BubblePopButton` med Capsule-form, brand-gradient (leading→trailing), bounce-animation via DragGesture+scaleEffect och shadowGlowPrimary
- ChatBubbleView ersätter Color.blue/systemGray5 med `LinearGradient.chatMine` (egna) och `UnevenRoundedRectangle` med pratbubbla-hake (6pt hörn) för båda typer
- WeatherStickerView byter ut `Image(systemName:)` mot `WeatherIconMapper.icon(for:size:36)`, temperaturen får `zone.gradient`-fill och border är gradient-strokeBorder

## Task Commits

1. **Task 1: BubblePopButton** - `156b248` (feat)
2. **Task 2: ChatBubbleView + WeatherStickerView** - `b9e8ab9` (feat)

## Files Created/Modified

- `HotAndColdFriends/DesignSystem/BubblePopButton.swift` - Ny pill-knapp med gradient, bounce, destructive-variant och Preview
- `HotAndColdFriends/Features/Chat/ChatBubbleView.swift` - Gradient-styling, asymmetrisk UnevenRoundedRectangle, DesignSystem-färger
- `HotAndColdFriends/Features/Chat/WeatherStickerView.swift` - WeatherIconMapper-ikon, gradient-temperaturtext, gradient-border
- `HotAndColdFriends.xcodeproj/project.pbxproj` - BubblePopButton registrerad i main + widget target

## Decisions Made

- `UnevenRoundedRectangle` (iOS 16+) valdes för pratbubbla-hake — deployment target är iOS 16+
- `foregroundStyle(Color.bubbleTextPrimary)` explicit (inte dot-syntax `.bubbleTextPrimary`) — Swift kräver explicit typ för ShapeStyle-extension i denna kontext
- `zone`-property i WeatherStickerView definieras som computed var utanför `body` för att undvika let-binding i View builder

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Explicit Color-typ krävs i foregroundStyle**
- **Found during:** Task 2 (ChatBubbleView-styling)
- **Issue:** `.bubbleTextPrimary` shorthand gav kompileringsfel "type 'ShapeStyle' has no member 'bubbleTextPrimary'" — Swift resolvar inte Color-extension via dot-notation i foregroundStyle
- **Fix:** Ersatt med `Color.bubbleTextPrimary` explicit
- **Files modified:** HotAndColdFriends/Features/Chat/ChatBubbleView.swift
- **Verification:** BUILD SUCCEEDED
- **Committed in:** b9e8ab9 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug)
**Impact on plan:** Minimal. Swift-API kräver explicit typ, ingen funktionell skillnad.

## Issues Encountered

- Xcode var öppet under första byggförsöket och låste build-databasen. Löstes genom att stänga Xcode och bygga om med `CODE_SIGNING_REQUIRED=NO`.
- En linter återställde WeatherStickerView.swift och ChatBubbleView.swift till originalet efter första redigeringsrundan — filerna skrevs om korrekt i andra passet.

## User Setup Required

None - ingen extern konfiguration krävs. Ändringar är rent SwiftUI/DesignSystem.

## Next Phase Readiness

- BubblePopButton redo att användas i onboarding och profilformulär
- ChatBubbleView har Bubble Pop-styling genomgående — inga Color.blue/systemGray5-referenser kvar
- WeatherStickerView visar tydligare gradient-accent med WeatherIconMapper-ikoner
- Checkpoint awaiting human visual verification i simulator

---
*Phase: 10-komponenter*
*Completed: 2026-03-05*
