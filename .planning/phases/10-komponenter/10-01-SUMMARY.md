---
phase: 10-komponenter
plan: "01"
subsystem: ui

tags: [swiftui, design-system, avatar, friend-list, bubble-pop, temperature-zone, gradient]

requires:
  - phase: 09-design-foundation
    provides: TemperatureZone.gradient, BubblePopColors, BubblePopShadows, BubblePopSpacing, BubblePopTypography, WeatherIconMapper

provides:
  - AvatarView (universal gradient avatar component, reusable in profile, chat header)
  - FriendRowView as Bubble Pop card (white card, gradient avatar, zone-colored text/icon, slide-hover)

affects:
  - 10-komponenter (remaining plans — can reuse AvatarView in ProfileView, ChatView)
  - 11-animationer (WeatherAnimationView removed from FriendRowView — animation layer gone)
  - 12-polish (avatar already done, will not need redesign)

tech-stack:
  added: []
  patterns:
    - "AvatarView: gradient circle + white initials, photoURL with AsyncImage fallback"
    - "CardShadowModifier: ViewModifier switching shadowMd/shadowLg on isPressed"
    - "Long-press gesture pattern for hover/scale: onLongPressGesture(minimumDuration:0, pressing:perform:)"

key-files:
  created:
    - HotAndColdFriends/DesignSystem/AvatarView.swift
  modified:
    - HotAndColdFriends/Features/FriendList/FriendRowView.swift
    - HotAndColdFriends/Features/Chat/WeatherStickerView.swift

key-decisions:
  - "CardShadowModifier as private ViewModifier (not inline if/else) for clean shadow switching"
  - "WeatherAnimationView removed from FriendRowView — avatar replaced the animation layer"
  - "TemperatureZone(celsius: -99) as arctic fallback when temperatureCelsius is nil"

patterns-established:
  - "AvatarView pattern: displayName + temperatureCelsius? + size + photoURL? — same signature for all future avatar placements"
  - "Bubble Pop card pattern: HStack + .background(bubbleSurface) + .clipShape(RoundedRectangle(CornerRadius.md)) + .shadowMd()"

requirements-completed:
  - COMP-01
  - COMP-06

duration: 10min
completed: "2026-03-05"
---

# Phase 10 Plan 01: AvatarView + FriendRowView Bubble Pop Card Summary

**Universell gradient-avatar (AvatarView) med temperaturzon + omformat FriendRowView till flytande Bubble Pop-kort med slide-hover och zone-baserad färgsättning**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-05T07:07:55Z
- **Completed:** 2026-03-05T07:17:00Z
- **Tasks:** 2 (av 2 auto-tasks — 1 checkpoint kvar)
- **Files modified:** 4

## Accomplishments

- Skapade `AvatarView.swift` — fristående komponent med TemperatureZone-gradient, vita initialer och AsyncImage-stöd (fallback till gradient om foto misslyckas)
- Omformade `FriendRowView` från flat list-rad till Bubble Pop-kort: vit yta, CornerRadius.md (20pt), shadowMd/shadowLg, scale(1.02) vid press
- Ersatte WeatherAnimationView + initialsCircle-lagret med AvatarView — enklare arkitektur, tydligare gradient
- Löste merge-konflikt i WeatherStickerView.swift (foregroundStyle-typ) som uppstod vid git stash

## Task Commits

Varje task committades atomärt:

1. **Task 1: Skapa AvatarView** - `e9e3049` (feat)
2. **Task 2: Omforma FriendRowView till Bubble Pop-kort** - `26624ed` (feat)

## Files Created/Modified

- `/Users/richardsandenskog/Claude/weatherfriends/HotAndColdFriends/DesignSystem/AvatarView.swift` — Ny universell gradient-avatar-komponent med 5 temperaturzoner, photoURL-stöd och #Preview
- `/Users/richardsandenskog/Claude/weatherfriends/HotAndColdFriends/Features/FriendList/FriendRowView.swift` — Omformat till Bubble Pop-kort, använder AvatarView
- `/Users/richardsandenskog/Claude/weatherfriends/HotAndColdFriends/Features/Chat/WeatherStickerView.swift` — Löst merge-konflikt (foregroundStyle)
- `/Users/richardsandenskog/Claude/weatherfriends/HotAndColdFriends.xcodeproj/project.pbxproj` — AvatarView registrerad i Xcode-projektet

## Decisions Made

- `CardShadowModifier` skapades som `private struct CardShadowModifier: ViewModifier` för att hantera shadowMd/shadowLg-switch. Alternativet (inline if/else) fungerar inte i SwiftUI utan en ViewModifier.
- `WeatherAnimationView`-lagret i FriendRowView togs bort. AvatarView med gradient ersätter den visuella effekten och är enklare att underhålla.
- `TemperatureZone(celsius: -99)` som fallback när celsius är nil — ger `.arctic` zon (konsekvent med övriga nil-fallbacks i appen).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Löst merge-konflikt i WeatherStickerView.swift**
- **Found during:** Task 2 (stash/pop-operation under debugging)
- **Issue:** Git stash pop skapade merge-konflikt (`.bubbleTextSecondary` vs `Color.bubbleTextSecondary`) — ShapeStyle-typ-mismatch
- **Fix:** Behöll `Color.bubbleTextSecondary`-varianten (korrekt typ för `foregroundStyle`)
- **Files modified:** HotAndColdFriends/Features/Chat/WeatherStickerView.swift
- **Verification:** BUILD SUCCEEDED efter fix
- **Committed in:** 26624ed (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Fix nödvändig för att projektet ska bygga. Ingen scope creep.

## Issues Encountered

- Git stash-operation under debugging av pre-existerande byggfel orsakade merge-konflikt i WeatherStickerView.swift. Löstes med korrekt ShapeStyle-typ.
- Första byggförsöket returnerade "database is locked" — väntat vid parallella byggen, löste sig vid nästa försök.

## Checkpoint Kvar

Task 3 (checkpoint:human-verify) väntar på manuell verifiering. Bygg appen i Xcode och granska vänlistan i simulator.

## Next Phase Readiness

- AvatarView redo att återanvändas i ProfileView, ChatView header etc.
- FriendRowView uppfyller Bubble Pop-designstandard
- Checkpoint kvar — visuell granskning i simulator behövs innan fasen markeras som klar

---
*Phase: 10-komponenter*
*Completed: 2026-03-05*
