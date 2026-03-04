---
phase: 06-polish-app-store
plan: 02
subsystem: ui
tags: [widgetkit, ios-widget, app-group, userdefaults, deep-link, privacy-manifest]

# Dependency graph
requires:
  - phase: 02-karnupplevelse
    provides: AppWeatherService, FriendListViewModel, FriendWeather-modell
  - phase: 04-chatt-och-push
    provides: NotificationCenter deep link-mönster (.openWeatherAlert)
provides:
  - iOS hemskärmswidget med small/medium/large-storlekar
  - App Group UserDefaults-datadelning mellan app och widget
  - hotandcold:// URL-schema för widget deep links
  - PrivacyInfo.xcprivacy för App Store-submission
affects: [app-store-submission, 06-polish-app-store]

# Tech tracking
tech-stack:
  added: [WidgetKit, App Group UserDefaults]
  patterns: [TimelineProvider-mönster för 30-min uppdatering, Codable transport-struct för cross-target data]

key-files:
  created:
    - HotAndColdFriendsWidget/HotAndColdFriendsWidget.swift
    - HotAndColdFriendsWidget/WidgetViews.swift
    - HotAndColdFriendsWidget/HotAndColdFriendsWidget.entitlements
    - HotAndColdFriendsWidget/Info.plist
    - HotAndColdFriends/Models/WidgetFriendEntry.swift
    - HotAndColdFriends/Resources/PrivacyInfo.xcprivacy
  modified:
    - project.yml
    - HotAndColdFriends/Resources/HotAndColdFriends.entitlements
    - HotAndColdFriends/Resources/Info.plist
    - HotAndColdFriends/Features/FriendList/FriendListViewModel.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift

key-decisions:
  - "WidgetFriendEntry är ren Codable-struct utan FriendWeather-referens — konverteringslogiken ligger i FriendListViewModel.updateWidgetData() eftersom widget-target inte kan se FriendWeather"
  - "Profilbilder exkluderas från widget i v1 — AsyncImage fungerar ej i WidgetKit, initialer visas istället"
  - "Återanvänder .openWeatherAlert Notification.Name för deep link från widget — navigerar till väderdetalj, precis vad widgeten behöver"
  - "Widget uppdateras var 30:e minut i TimelineProvider — synkat med AppWeatherService 30-min TTL-cache"

patterns-established:
  - "App Group UserDefaults med suiteName group.se.sandenskog.hotandcoldfriends — standard för cross-target data"
  - "WidgetCenter.shared.reloadTimelines() anropas efter varje datauppdatering i FriendListViewModel"

requirements-completed: [WDGT-01]

# Metrics
duration: 5min
completed: 2026-03-04
---

# Phase 6 Plan 02: iOS Widget Summary

**WidgetKit hemskärmswidget med small/medium/large-storlekar, App Group UserDefaults-datadelning och hotandcold:// deep links — WDGT-01 implementerat**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-04T07:29:13Z
- **Completed:** 2026-03-04T07:34:xx Z
- **Tasks:** 1 av 2 (Task 2 är checkpoint:human-verify)
- **Files modified:** 11

## Accomplishments

- WidgetKit-extension med WeatherTimelineProvider och 30-min uppdateringspolicy
- Tre widgetstorlekar: small (1 favorit), medium (3-4), large (6) — alla med djuplänkar
- App Group UserDefaults-datadelning: FriendListViewModel skriver, widget läser synkront
- hotandcold://friend/{id} URL-schema med .onOpenURL-hantering i HotAndColdFriendsApp
- PrivacyInfo.xcprivacy med UserDefaults CA92.1-reason för App Store-submission
- Projektet kompilerar utan fel (BUILD SUCCEEDED)

## Task Commits

1. **Task 1: WidgetKit-infrastruktur, datadelning och privacy manifest** - `4d1cf74` (feat)

## Files Created/Modified

- `HotAndColdFriendsWidget/HotAndColdFriendsWidget.swift` — WeatherTimelineProvider + HotAndColdFriendsWidget @main
- `HotAndColdFriendsWidget/WidgetViews.swift` — SmallWidgetView, MediumWidgetView, LargeWidgetView + FriendWidgetCell
- `HotAndColdFriendsWidget/HotAndColdFriendsWidget.entitlements` — App Group-entitlement för widget
- `HotAndColdFriendsWidget/Info.plist` — Widget extension NSExtensionPointIdentifier
- `HotAndColdFriends/Models/WidgetFriendEntry.swift` — Codable transport-struct delad av app och widget
- `HotAndColdFriends/Resources/PrivacyInfo.xcprivacy` — UserDefaults API-deklaration CA92.1
- `project.yml` — HotAndColdFriendsWidgetExtension-target + App Group i HotAndColdFriends-target
- `HotAndColdFriends/Resources/HotAndColdFriends.entitlements` — App Group-entitlement tillagd
- `HotAndColdFriends/Resources/Info.plist` — hotandcold URL-schema tillagd
- `HotAndColdFriends/Features/FriendList/FriendListViewModel.swift` — updateWidgetData() + WidgetKit-import
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` — .onOpenURL för widget deep links

## Decisions Made

- WidgetFriendEntry är ren Codable-struct utan FriendWeather-referens. Konverteringslogiken (temperaturFärg-beräkning) finns i `FriendListViewModel.updateWidgetData()` — detta eftersom widget-target inkluderar WidgetFriendEntry.swift via xcodegen source-path och FriendWeather inte är tillgänglig i widget-extension.
- Profilbilder exkluderas från widgeten i v1. AsyncImage fungerar inte i WidgetKit-kontext. Widgeten visar initialer i en färgad cirkel baserat på temperaturfärg. Bildcache via FileManager till App Group container är möjlig utvidgning i v2.
- Återanvänder `.openWeatherAlert` Notification.Name (från AppRouter) för widget deep links — navigerar till väderdetalj för given vän-ID, precis det widgeten behöver utan ny NotificationCenter-hantering.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] WidgetFriendEntry.from(friendWeather:) flyttades till FriendListViewModel**

- **Found during:** Task 1 (widget-target kompilering)
- **Issue:** Planen inkluderade `from(friendWeather:)` som statisk metod i WidgetFriendEntry. Men widget-extension inkluderar WidgetFriendEntry.swift (delad fil) och FriendWeather är inte tillgänglig i widget-target — kompilering av widgeten skulle misslyckas.
- **Fix:** WidgetFriendEntry behåller ren Codable-struct. Konverteringslogiken med RGB-beräkning lades inline i `updateWidgetData()` i FriendListViewModel (huvud-app-target, har tillgång till FriendWeather).
- **Files modified:** HotAndColdFriends/Models/WidgetFriendEntry.swift, HotAndColdFriends/Features/FriendList/FriendListViewModel.swift
- **Verification:** BUILD SUCCEEDED för båda targets
- **Committed in:** 4d1cf74 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical för korrekt kompilering)
**Impact on plan:** Nödvändig fix för att widget-extension ska kompilera. Ingen scope-förändring.

## User Setup Required

App Group-registrering i Apple Developer Portal krävs innan widget-datadelning fungerar på fysisk enhet:

1. Registrera App Group ID: `group.se.sandenskog.hotandcoldfriends`
   - Apple Developer Portal → Identifiers → App Groups → + → `group.se.sandenskog.hotandcoldfriends`

2. Lägg till App Group-capability på App ID `se.sandenskog.hotandcoldfriends`
   - Apple Developer Portal → Identifiers → se.sandenskog.hotandcoldfriends → Capabilities → App Groups → Edit → välj `group.se.sandenskog.hotandcoldfriends`

3. Skapa nytt App ID för widget-extension: `se.sandenskog.hotandcoldfriends.widget`
   - Apple Developer Portal → Identifiers → + → App IDs → App → Bundle ID: `se.sandenskog.hotandcoldfriends.widget` → Capabilities: App Groups

4. Generera nya provisioning profiles för båda App IDs
   - Apple Developer Portal → Profiles → + → iOS App Development → välj respektive App ID

## Next Phase Readiness

- Widget-kod är komplett och kompilerar korrekt
- Väntar på manuell verifiering (Task 2: checkpoint:human-verify)
- App Group-registrering i Apple Developer Portal krävs för full funktionalitet

---
*Phase: 06-polish-app-store*
*Completed: 2026-03-04*
