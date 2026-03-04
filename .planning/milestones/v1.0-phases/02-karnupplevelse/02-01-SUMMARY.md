---
phase: 02-karnupplevelse
plan: "01"
subsystem: data-layer
tags: [weatherkit, firestore, services, models, swift]
dependency_graph:
  requires: [01-01, 01-02, 01-03]
  provides: [AppWeatherService, FriendService, DemoFriendService, Friend, FriendWeather]
  affects: [02-02, 02-03]
tech_stack:
  added: [WeatherKit, CoreLocation]
  patterns: [Actor-cache, Observable, Firestore-subcollection]
key_files:
  created:
    - HotAndColdFriends/Models/Friend.swift
    - HotAndColdFriends/Models/FriendWeather.swift
    - HotAndColdFriends/Services/AppWeatherService.swift
    - HotAndColdFriends/Services/FriendService.swift
    - HotAndColdFriends/Services/DemoFriendService.swift
    - HotAndColdFriends/Resources/HotAndColdFriends.entitlements
  modified:
    - project.yml
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
decisions:
  - WeatherKit-metoderna heter .hourly/.daily (inte .hourlyForecast/.dailyForecast) i den version som används
  - Firestore count-aggregation returnerar NSNumber — .intValue används istället för Int(truncatingIfNeeded:)
  - AppWeatherService (ej WeatherService) för att undvika namnkollision med WeatherKit.WeatherService
  - detailedWeather returnerar Forecast<DayWeather>? (optional) pga API-kompabilitet
metrics:
  duration: "4 min"
  completed_date: "2026-03-02"
  tasks_completed: 2
  files_created: 6
  files_modified: 2
---

# Phase 2 Plan 1: Data-lager — WeatherKit + Firestore-vänner Summary

**One-liner:** WeatherKit Actor-TTL-cache (30 min), Friend/FriendWeather-modeller och Firestore CRUD-service med max-6-favorit-logik plus 8 internationella demo-vänner.

## Vad byggdes

### Task 1: Friend-modell, FriendWeather-modell och FriendService (commit: 9095a84)

**Friend.swift** — Codable+Identifiable med Firestore `@DocumentID` och `@ServerTimestamp`. Fält: displayName, photoURL, city, cityLatitude, cityLongitude, isFavorite, isDemo.

**FriendWeather.swift** — Sammansatt värde-objekt (Friend + CurrentWeather) med:
- `temperatureCelsius: Double` för sortering
- `temperatureFormatted: String` för visning ("7°")
- `symbolName`, `conditionDescription`, `humidity`, `windSpeed`

**FriendService.swift** — `@Observable @MainActor class` med Firestore CRUD i `users/{uid}/friends`:
- `fetchFriends` — sorterat på displayName
- `addFriend` — kontrollerar max 6 favoriter
- `updateFriend`, `removeFriend`
- `toggleFavorite` — atomisk, kastar `maxFavoritesReached` vid 7:e
- `removeDemoFriends` — rensar isDemo-flaggade vänner
- `favoritesCount` — Firestore count-aggregation
- `FriendServiceError`: `maxFavoritesReached` och `missingFriendID` med lokaliserade felmeddelanden

**DemoFriendService.swift** — Statisk struct med 8 internationella demo-vänner (riktiga koordinater). Tre favoriter: Tokyo, Kapstaden, New York. Fem ej-favoriter: Sydney, Dubai, Stockholm, Paris, Buenos Aires.

### Task 2: AppWeatherService, entitlements och service-injection (commit: ea26d09)

**AppWeatherService.swift** — `@Observable @MainActor class` med intern `private actor WeatherCache`:
- `currentWeather(latitude:longitude:)` — primär, använder 30-min TTL-cache med koordinatnyckel (3 decimaler = ca 100m precision)
- `detailedWeather(latitude:longitude:)` — utan cache, för expanderat vädersheet
- `attribution` — Apple Weather-krav
- `clearCache()` — för pull-to-refresh

**HotAndColdFriends.entitlements** — WeatherKit capability (`com.apple.developer.weatherkit: true`)

**project.yml** — Entitlements-referens tillagd i target-block

**HotAndColdFriendsApp.swift** — AppWeatherService och FriendService läggs till som `@State`-properties och injiceras via `.environment()` på AppRouter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Int(truncatingIfNeeded:) fungerar inte med NSNumber**
- **Found during:** Task 1, FriendService.favoritesCount
- **Issue:** Firestore count-aggregations `snapshot.count` är `NSNumber` (inte `BinaryInteger`) — `Int(truncatingIfNeeded:)` kompilerar inte
- **Fix:** Byttes till `snapshot.count.intValue`
- **Files modified:** HotAndColdFriends/Services/FriendService.swift
- **Commit:** 9095a84

**2. [Rule 1 - Bug] WeatherKit API-metodnamn .hourlyForecast/.dailyForecast existerar inte**
- **Found during:** Task 2, AppWeatherService.detailedWeather
- **Issue:** WeatherKit query-typer heter `.hourly` och `.daily`, inte `.hourlyForecast` och `.dailyForecast` som angavs i plan
- **Fix:** Byttes till `.hourly` och `.daily` i API-anropet
- **Files modified:** HotAndColdFriends/Services/AppWeatherService.swift
- **Commit:** ea26d09

## Verifiering

- xcodegen generate: LYCKADES
- xcodebuild build (iPhone 17 Simulator): BUILD SUCCEEDED
- Friend.swift i Models/: FINNS
- FriendWeather.swift i Models/: FINNS
- AppWeatherService.swift i Services/: FINNS
- FriendService.swift i Services/: FINNS
- DemoFriendService.swift i Services/: FINNS
- HotAndColdFriends.entitlements med WeatherKit-nyckel: FINNS
- project.yml med entitlements-referens: FINNS
- HotAndColdFriendsApp injicerar AppWeatherService och FriendService: KLART

## User Setup Required

**WeatherKit kräver manuell aktivering i Apple Developer Portal:**
1. Gå till Apple Developer Portal -> Certificates, Identifiers & Profiles -> Identifiers
2. Välj `se.sandenskog.hotandcoldfriends`
3. Under App Services, aktivera WeatherKit (bocka i rutan)
4. Spara och vänta 30 minuter innan test på device

WeatherKit fungerar utan detta i simulatorn (returnerar mockdata).

## Self-Check: PASSED
