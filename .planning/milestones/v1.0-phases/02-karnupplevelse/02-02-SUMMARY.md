---
phase: 02-karnupplevelse
plan: "02"
subsystem: ui
tags: [swiftui, weatherkit, friendlist, favorites, temperature-color, demo-data]

# Dependency graph
requires:
  - phase: 02-01
    provides: FriendWeather, FriendService, AppWeatherService, DemoFriendService
  - phase: 01-03
    provides: AuthManager, ProfileView, OnboardingView
provides:
  - FriendListView som primär vy efter inloggning
  - FriendListViewModel med parallell väderhämtning och sortering
  - FriendRowView med färgkodad temperatur och SF Symbol-väderikon
  - WeatherDetailSheet med tim- och dagsprognos, vind, fuktighet, UV-index
  - Color.temperatureColor(celsius:) extension — blå→grön→orange→röd
affects:
  - 02-03-lagg-till-van (vill lägga till vänner från FriendListView)
  - 02-04-notifikationer (FriendListView är receptorn för notis-navigering)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Observable ViewModel med parallell async/await via withThrowingTaskGroup"
    - "FriendListView injicerar @Environment-tjänster, skickar vidare till ViewModel"
    - "Swipe-favoriter med optimistisk lokal uppdatering (utan reload)"
    - "Apple Weather-attribution via WeatherKit.WeatherService.shared.attribution"

key-files:
  created:
    - HotAndColdFriends/Features/FriendList/FriendListViewModel.swift
    - HotAndColdFriends/Features/FriendList/FriendRowView.swift
    - HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift
    - HotAndColdFriends/Features/FriendList/FriendListView.swift
  modified:
    - HotAndColdFriends/Core/Navigation/AppRouter.swift

key-decisions:
  - "Color.temperatureColor placerades i FriendRowView.swift som extension — ingen extra fil behövdes"
  - "Logga ut-knapp i .topBarLeading i FriendListView (inte i profil-sheet) — enklare UX"
  - "iPhone 17 simulator används istället för iPhone 16 (ej tillgänglig i detta Xcode)"
  - "WeatherDetailSheet tar @Environment(AppWeatherService.self) — gör den testbar och oberoende"

patterns-established:
  - "FriendListViewModel: parallell väderhämtning via withThrowingTaskGroup, optimistisk lokal uppdatering vid toggle"
  - "Temperaturfärgkodning: <0°=isblå, 0-10°=kylig blå, 10-20°=neutral grön, 20-28°=orange, 28+°=röd"

requirements-completed: [VIEW-01, VIEW-04]

# Metrics
duration: 5min
completed: 2026-03-02
---

# Phase 2 Plan 02: FriendListView Summary

**Vädersorterad värdlista som primär vy — sektioner (Favoriter/Övriga), swipe-favoriter, expanderad vädersheet med prognos, färgkodad temperatur och Apple Weather-attribution**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-02T15:48:57Z
- **Completed:** 2026-03-02T15:53:57Z
- **Tasks:** 2 av 3 (Task 3 är manuell verifiering — checkpoint)
- **Files modified:** 5

## Accomplishments
- FriendListViewModel med parallell WeatherKit-hämtning via withThrowingTaskGroup, sortering varmast till kallast och separat favorites/others
- FriendListView som primär vy: sektionerad lista, swipe-favoriter, demo-banner, pull-to-refresh och Apple Weather-attribution
- WeatherDetailSheet med profilbild, stor temperaturvisning, detaljrader (feels-like, vind, fuktighet, UV) plus tim- och dagsprognos
- AppRouter: MainTabView borttagen, FriendListView är nu authenticated-state

## Task Commits

Varje task committades atomiskt:

1. **Task 1: FriendListViewModel, FriendRowView, WeatherDetailSheet** - `aa4eff9` (feat)
2. **Task 2: FriendListView och AppRouter** - `99ef103` (feat)
3. **Task 3: Manuell verifiering** - Checkpoint — inväntar godkännande

## Files Created/Modified
- `HotAndColdFriends/Features/FriendList/FriendListViewModel.swift` - @Observable ViewModel med parallell väderhämtning, sortering, demo-logik, toggle-favorit
- `HotAndColdFriends/Features/FriendList/FriendRowView.swift` - Kompakt rad med profilbild/initialer, namn, stad, färgkodad temp + SF Symbol-ikon; Color.temperatureColor extension
- `HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift` - Expanderad vädervy i sheet med tim/dagsprognos, feels-like, vind, fuktighet, UV-index
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` - Huvud-listvy med sektioner, swipe-favoriter, demo-banner, attribution-footer
- `HotAndColdFriends/Core/Navigation/AppRouter.swift` - Ersatt MainTabView med FriendListView i .authenticated case

## Decisions Made
- `Color.temperatureColor` placerades som extension i `FriendRowView.swift` — samma fil som använder den, ingen extra fil behövdes
- Logga ut-knapp i `.topBarLeading` i FriendListView — mer direkt åtkomst än att gömma i profil-sheet
- iPhone 17 simulator används för kompilering (iPhone 16 ej tillgänglig i aktuellt Xcode)
- `WeatherDetailSheet` tar `@Environment(AppWeatherService.self)` och injiceras explicit vid sheet-presentering

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] iPhone 16 simulator ej tillgänglig**
- **Found during:** Task 1 verifiering
- **Issue:** Planens verify-kommando använde `name=iPhone 16` men inga iPhone 16-simulatorer finns installerade
- **Fix:** Använde `name=iPhone 17` istället — iOS 26.2, identisk funktionalitet
- **Verification:** BUILD SUCCEEDED med iPhone 17
- **Committed in:** aa4eff9 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Trivial — enbart simulator-namnbyte, ingen kodändring.

## Issues Encountered
Inga blockande problem. Bygget kompilerade rent i båda tasks.

## User Setup Required
None — ingen extern konfiguration krävs för denna plan.

## Self-Check: PASSED

Alla filer existerar, båda commits verifierade (aa4eff9, 99ef103), SUMMARY.md skapad.

## Next Phase Readiness
- FriendListView är redo som primär vy i appen
- Kräver manuell verifiering på device (Task 3-checkpoint) — WeatherKit fungerar ej i simulator
- Plan 02-03 (lägg till vän) kan börja byggas mot FriendListView när checkpoint är godkänt

---
*Phase: 02-karnupplevelse*
*Completed: 2026-03-02*
