---
phase: 02-karnupplevelse
plan: "03"
subsystem: ui
tags: [swiftui, onboarding, firestore, locationservice, mklocalsearch, friendservice]

requires:
  - phase: 02-01
    provides: FriendService.addFriend(), Friend-modell med isFavorite/isDemo, Firestore subcollection users/{uid}/friends/

provides:
  - OnboardingFavoritesView — steg 4 med namn + stad-autocomplete per vän
  - PendingFriend-struct för temporär vänner-data under onboarding
  - 4-stegs onboarding-wizard med korrekt progress-indikator
  - Vänner sparas som Friend-dokument i Firestore vid slutförande
  - De 6 första vännerna markeras automatiskt som favoriter

affects: [03-kontakter-import, fas-2-friendlist]

tech-stack:
  added: []
  patterns:
    - "PendingFriend-struct (lokal state) → Friend-model (Firestore) konvertering vid commit"
    - "LocationService återanvänd i OnboardingFavoritesView via @State private var locationService = LocationService()"
    - "isAddingFriend: Bool togglar formulär — döljer/visar med withAnimation"

key-files:
  created:
    - HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift
  modified:
    - HotAndColdFriends/Features/Onboarding/OnboardingView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift
    - HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift

key-decisions:
  - "PendingFriend-struct definieras inuti OnboardingFavoritesView.swift — ingen separat fil behövs"
  - "Samma LocationService-instans återanvänds per tillägg (rensas mellan tillägg) — undviker N instanser"
  - "OnboardingViewModel.completeOnboarding() tar FriendService som parameter — håller injektionsmönstret konsekvent"

patterns-established:
  - "Onboarding-steg: isAddingFriend-toggle separerar listvy från formulärvy"
  - "Index-baserad isFavorite-logik: index < 6 = favorit automatiskt"

requirements-completed: [FRND-04, FRND-05]

duration: 5min
completed: "2026-03-02"
---

# Phase 2 Plan 3: Onboarding Favoriter Summary

**4-stegs onboarding-wizard med valfritt vänner-steg: namn + stad-autocomplete via LocationService, automatisk favoritmarkering för 6 forsta, sparas till Firestore via FriendService**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-02T15:48:51Z
- **Completed:** 2026-03-02T15:53:40Z
- **Tasks:** 2
- **Files modified:** 4 (1 skapad, 3 modifierade)

## Accomplishments

- OnboardingFavoritesView skapad: formulär med namn-fält + stad-autocomplete (LocationService), lista med tillagda vänner, favoritstjärna för de 6 första
- OnboardingView utökad till 4 steg: progress-bar (4 capsules), steg-räknare "Steg X av 4", steg 2 (stad) nav till steg 4, steg 4 har "Hoppa över" + "Slutför"
- OnboardingViewModel utökad: pendingFriends: [PendingFriend], completeOnboarding() sparar vänner med korrekt isFavorite-markering

## Task Commits

Varje task committades atomiskt:

1. **Task 1: OnboardingFavoritesView** - `2d29d60` (feat)
2. **Task 2: Utöka OnboardingView och OnboardingViewModel** - `1136570` (feat)

## Files Created/Modified

- `HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift` — Steg 4: vänner-formulär med PendingFriend-struct, stad-autocomplete, lista med X-ta-bort
- `HotAndColdFriends/Features/Onboarding/OnboardingView.swift` — 4-stegs wizard, progress-bar, steg-logik med Hoppa över/Slutför
- `HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift` — pendingFriends-state, uppdaterad completeOnboarding-signatur med FriendService
- `HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift` — Bug-fix (se nedan)

## Decisions Made

- PendingFriend-struct definieras i OnboardingFavoritesView.swift — ingen separat fil behövs för en lokalt scoped struct
- Samma LocationService-instans per formulär-session (rensas vid tillägg) — undviker memory-overhead av N instanser
- completeOnboarding() tar FriendService som parameter för att hålla konsekvent injektionsmönster med authManager/userService

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fix WeatherDetailSheet: Forecast<DayWeather>? konverteras till [DayWeather]**
- **Found during:** Task 1 (xcodebuild-verifiering)
- **Issue:** `Array(daily ?? [])` kompilerade inte: `Forecast<DayWeather>?` är inte `[DayWeather]?`. WeatherKit-typfel från tidigare plan.
- **Fix:** Ersatt med `daily.map { Array($0) } ?? []` — nil-safe map på optional Forecast
- **Files modified:** HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift
- **Verification:** Projektet kompilerade utan fel efter ändringen
- **Committed in:** 2d29d60 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bugg)
**Impact on plan:** Bugg-fixen var nödvändig för att bygget skulle lyckas. Ingen scope creep.

## Issues Encountered

- iPhone 16-simulator existerar inte i nuvarande Xcode-miljö — använde iPhone 17 som destination istället. Inga konsekvenser för koden.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Onboarding-flödet är komplett (4 steg: namn, foto, stad, vänner)
- Vänner sparas korrekt i Firestore vid slutförande av onboarding
- FriendService-integrationen testad via bygget
- Redo för fas 3: Kontakter-import (kan nu lägga till vänner manuellt eller via import)

---
*Phase: 02-karnupplevelse*
*Completed: 2026-03-02*
