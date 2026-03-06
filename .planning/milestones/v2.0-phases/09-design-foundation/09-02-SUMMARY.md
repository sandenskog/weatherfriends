---
phase: 09-design-foundation
plan: "02"
subsystem: ui
tags: [ios, swiftui, assets, svg, xcassets, weather-icons, design-system]

# Dependency graph
requires:
  - phase: 09-01
    provides: DesignSystem tokens (BubblePopColors, BubblePopSpacing, BubblePopTypography, BubblePopShadows, TemperatureZone) som används i empty state-vyerna
provides:
  - 14 SVG väderikoner i Assets.xcassets/WeatherIcons/
  - WeatherIconMapper: central WeatherKit symbolName → custom asset mapping med SF Symbol fallback
  - App-ikon 1024x1024 PNG utan alfakanal från design-pack SVG
  - LogoHorizontal, EmptyStateFriends, EmptyStateChat som SVG imagesets
  - FriendRowView använder custom väderikoner via WeatherIconMapper
  - LoginView visar horisontell logotyp
  - FriendListView och ConversationListView har empty state-illustrationer
affects: [10-design-polish, FriendRowView, LoginView, FriendListView, ConversationListView]

# Tech tracking
tech-stack:
  added: [librsvg (brew, för SVG→PNG-konvertering), rsvg-convert]
  patterns: [WeatherIconMapper enum-pattern för centraliserad asset-mapping med fallback, SVG imageset med preserves-vector-representation]

key-files:
  created:
    - HotAndColdFriends/DesignSystem/WeatherIconMapper.swift
    - HotAndColdFriends/Resources/Assets.xcassets/WeatherIcons/ (14 imagesets)
    - HotAndColdFriends/Resources/Assets.xcassets/LogoHorizontal.imageset/
    - HotAndColdFriends/Resources/Assets.xcassets/EmptyStateFriends.imageset/
    - HotAndColdFriends/Resources/Assets.xcassets/EmptyStateChat.imageset/
  modified:
    - HotAndColdFriends/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
    - HotAndColdFriends/Features/FriendList/FriendRowView.swift
    - HotAndColdFriends/Features/Login/LoginView.swift
    - HotAndColdFriends/Features/FriendList/FriendListView.swift
    - HotAndColdFriends/Features/Chat/ConversationListView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "WeatherIconMapper normaliserar .fill-suffix automatiskt — alla WeatherKit symboler hanteras oavsett variant"
  - "SVG-ikoner används direkt i asset catalog med preserves-vector-representation — ingen PNG-konvertering behövs för väderikoner"
  - "App-ikon konverterades via rsvg-convert + JPEG round-trip för att garantera att alfakanal tas bort"
  - "FriendListView empty state visas bara när favorites OCH others är tomma OCH ingen demo-banner — undviker att dölja listan under laddning"
  - "ContentUnavailableView i ConversationListView ersattes med custom empty state för att visa EmptyStateChat-illustration"

patterns-established:
  - "WeatherIconMapper-pattern: enum med static func assetName(for:) + static @ViewBuilder func icon(for:size:) — använd detta mönster för alla asset-mappningar"
  - "SVG imageset-pattern: placera SVG direkt i .imageset/ med preserves-vector-representation: true i Contents.json"

requirements-completed: [ASSET-01, ASSET-02, ASSET-03, ASSET-04]

# Metrics
duration: 6min
completed: 2026-03-04
---

# Phase 9 Plan 02: Asset Integration Summary

**18 custom design assets importerade och integrerade: 14 SVG väderikoner med WeatherIconMapper, ny app-ikon, horisontell logotyp på LoginView, och EmptyState-illustrationer i FriendListView/ConversationListView**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-04T22:26:41Z
- **Completed:** 2026-03-04T22:33:02Z
- **Tasks:** 8 av 8
- **Files modified:** 11

## Accomplishments

- 14 SVG väderikoner importerade som imagesets med `preserves-vector-representation` — inga SF Symbols för väder längre
- `WeatherIconMapper` skapar en central, testbar plats för WeatherKit → custom asset-mapping med SF Symbol fallback
- App-ikon genererad via rsvg-convert + JPEG round-trip som 1024×1024 PNG utan alfakanal
- Horisontell logotyp (LogoHorizontal) visas på LoginView istället för Text("Hot & Cold Friends")
- Empty state-illustrationer i FriendListView (EmptyStateFriends) och ConversationListView (EmptyStateChat) med titel + subtitle
- Projektet kompilerar utan fel (BUILD SUCCEEDED)

## Task Commits

1. **Task 1: Importera 14 SVG väderikoner** - `1458577` (feat)
2. **Task 2: WeatherIconMapper** - `1af0c07` (feat)
3. **Task 3: Ny app-ikon PNG** - `bc1b1cd` (feat)
4. **Task 4: Logotyp + empty states till asset catalog** - `e51a8e2` (feat)
5. **Task 5: WeatherIconMapper i FriendRowView** - `a9b09e5` (feat)
6. **Task 6: Logotyp på LoginView** - `a798b67` (feat)
7. **Task 7: Empty state-illustrationer i vyer** - `14b2815` (feat)
8. **Task 8: Xcode-registrering + kompilering** - `b30ba49` (chore)

## Files Created/Modified

- `HotAndColdFriends/DesignSystem/WeatherIconMapper.swift` - Central mapping WeatherKit symbolName → custom asset, med @ViewBuilder icon(for:size:)
- `HotAndColdFriends/Resources/Assets.xcassets/WeatherIcons/` - 14 imagesets: sun-clear, cloud-sun, cloud-overcast, cloud-moon, moon-clear, rain, heavy-rain, drizzle, snow, sleet, hail, thunderstorm, fog, wind
- `HotAndColdFriends/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` - Ny app-ikon 1024x1024, hasAlpha: no
- `HotAndColdFriends/Resources/Assets.xcassets/LogoHorizontal.imageset/` - logo-horizontal.svg
- `HotAndColdFriends/Resources/Assets.xcassets/EmptyStateFriends.imageset/` - empty-state-no-friends.svg
- `HotAndColdFriends/Resources/Assets.xcassets/EmptyStateChat.imageset/` - empty-state-no-chat.svg
- `HotAndColdFriends/Features/FriendList/FriendRowView.swift` - Ersatt Image(systemName:) med WeatherIconMapper.icon(for:size:)
- `HotAndColdFriends/Features/Login/LoginView.swift` - Image("LogoHorizontal") istället för Text("Hot & Cold Friends")
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` - emptyStateFriends-vy med EmptyStateFriends-illustration
- `HotAndColdFriends/Features/Chat/ConversationListView.swift` - Ersatt ContentUnavailableView med EmptyStateChat-illustration
- `HotAndColdFriends.xcodeproj/project.pbxproj` - WeatherIconMapper.swift registrerad i main target och widget target

## Decisions Made

- **rsvg-convert för app-ikon:** cairosvg saknade cairo-bibliotek på systemet. Installerade librsvg via brew istället. JPEG round-trip garanterar att alfakanal tas bort.
- **FriendListView empty state-villkor:** `others.isEmpty && favorites.isEmpty && !showDemoBanner` — undviker att dölja listan under initial laddning eller demo-läge.
- **ContentUnavailableView ersatt i ConversationListView:** Custom VStack ger mer kontroll och möjliggör EmptyStateChat-illustrationen.

## Deviations from Plan

None - plan executed exactly as written. rsvg-convert valdes som alternativ A istället för cairosvg (alternativ B) men båda alternativ fanns dokumenterade i planen.

## Issues Encountered

- `cairosvg` saknade `libcairo` på systemet. Löst via `brew install librsvg` och `rsvg-convert`.
- `xcodebuild` destination `iPhone 16` fanns inte (systemet har Xcode 26.2 beta med iOS 26 simulatorer). Löst med `name=iPhone 17`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Alla design assets importerade och integrerade — redo för fas 10 (design polish)
- FriendRowView migrerad till WeatherIconMapper — övriga vyer som använder symbolName kan migreras i fas 10
- WeatherIconMapper-mönstret etablerat och kan utökas med fler ikoner vid behov

## Self-Check: PASSED

All critical files exist and all 8 task commits verified.

---
*Phase: 09-design-foundation*
*Completed: 2026-03-04*
