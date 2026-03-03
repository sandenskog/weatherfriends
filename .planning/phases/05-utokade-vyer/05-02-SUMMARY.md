---
phase: 05-utokade-vyer
plan: "02"
subsystem: ui-views, notifications
tags: [category-view, carousel, notifications, weather-categories]
dependency_graph:
  requires: ["05-01"]
  provides: ["VIEW-02", "PUSH-02"]
  affects: ["FriendsTabView", "FriendListViewModel"]
tech_stack:
  added: ["UNUserNotificationCenter", "UNCalendarNotificationTrigger"]
  patterns: ["WeatherCategory enum", "horizontal-carousel", "ScrollTargetBehavior", "MainActor service without @Observable"]
key_files:
  created:
    - HotAndColdFriends/Features/FriendList/FriendCategoryView.swift
    - HotAndColdFriends/Services/DailyWeatherNotificationService.swift
  modified:
    - HotAndColdFriends/Features/FriendList/FriendsTabView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj
decisions:
  - "WeatherCategory.allCases ordning: tropical first (varmast) till arctic sist (kallast) — matchar befintlig FriendListView sortering"
  - "DailyWeatherNotificationService är @MainActor men ej @Observable — bakgrundstjänst utan UI-binding (samma mönster som WeatherAlertService)"
  - "schedule() anropas i slutet av befintligt .task{} i FriendsTabView — enklare än onChange(of: isLoading)"
  - "FriendWeatherCard är privat struct i FriendCategoryView.swift — ingen extra fil behövs för lokalt scoped komponent"
metrics:
  duration: "3 min"
  completed_date: "2026-03-04"
  tasks_completed: 2
  files_changed: 4
requirements:
  - VIEW-02
  - PUSH-02
---

# Phase 05 Plan 02: FriendCategoryView och DailyWeatherNotificationService Summary

**One-liner:** Kategorivy med horisontella karuseller per temperaturgrupp (tropical/warm/cool/cold/arctic) och daglig lokal notis kl 07:00 med favoriters vädersammanfattning.

## What Was Built

### Task 1: FriendCategoryView med WeatherCategory-karuseller (commit: 2f48c58)

Skapade `FriendCategoryView.swift` med:

- `WeatherCategory` enum med fem fall: tropical (28+°), warm (20-28°), cool (10-20°), cold (0-10°), arctic (<0°)
- Vertikal ScrollView med `LazyVStack` — en rad per kategori
- Horisontella karuseller med `LazyHStack` + `.scrollTargetBehavior(.viewAligned)` (iOS 17)
- `FriendWeatherCard` (privat struct) med profilbild (AsyncImage/initialer-fallback), förnamn, temperatur och SF Symbol
- Kortens bakgrundsfärg: `Color.temperatureColor(celsius:).opacity(0.12)` — subtil men kategorisignifikant
- `ContentUnavailableView` som empty state när inga vänner har temperaturdata
- Tomma kategorier döljs automatiskt via `categorized[category]?.isEmpty`-villkor
- Tap på kort sätter `selectedFriendWeather` — FriendsTabView:s `.sheet(item:)` öppnar WeatherDetailSheet

FriendsTabView uppdaterades: `case .categories` renderar nu `FriendCategoryView` i stället för placeholder-text.

### Task 2: DailyWeatherNotificationService (commit: 53e9cd3)

Skapade `DailyWeatherNotificationService.swift` med:

- `schedule(favorites:)` — schemalägger `UNCalendarNotificationTrigger` kl 07:00 med `repeats: true`
- Kontrollerar `notificationSettings().authorizationStatus == .authorized` innan schemaläggning
- Bygger notis-body: `"Anna 28° · Erik 12° · Lisa -3°"` (förnamn + temperatur, middle-dot separator)
- `removePendingNotificationRequests(withIdentifiers:)` + `add(_:)` — garanterar inga dubbletter
- Guard: om inga favoriter finns → `cancel()` och returnera
- `cancel()` — tar bort schemalagd notis explicit

FriendsTabView uppdaterades: `dailyNotificationService.schedule(favorites: viewModel.favorites)` anropas i slutet av `.task{}` efter `viewModel.load()`.

## Decisions Made

| Beslut | Motivering |
|--------|-----------|
| `WeatherCategory.allCases` ordning: tropical first | Matchar värma-till-kall sortering i FriendListView |
| `@MainActor` utan `@Observable` på DailyWeatherNotificationService | Bakgrundstjänst utan UI-binding — samma mönster som WeatherAlertService |
| schedule() i .task{} (ej onChange) | Enklare — data laddas en gång, notis schemaläggs direkt efter |
| `FriendWeatherCard` som privat struct i FriendCategoryView.swift | Lokalt scoped komponent, ingen extra fil behövs |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- FriendCategoryView.swift: FOUND
- DailyWeatherNotificationService.swift: FOUND
- Commit 2f48c58 (Task 1): FOUND
- Commit 53e9cd3 (Task 2): FOUND
