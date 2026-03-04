---
phase: 05-utokade-vyer
plan: 01
subsystem: ui
tags: [mapkit, swiftui, segmented-control, annotations, image-cache]

# Dependency graph
requires:
  - phase: 02-karnupplevelse
    provides: FriendListView, FriendListViewModel, FriendWeather-modell och WeatherDetailSheet
  - phase: 04.5-vanprofil-docs
    provides: FriendProfileView via WeatherDetailSheet
provides:
  - FriendsTabView med segmented control (Lista/Karta/Kategorier)
  - FriendMapView med MapKit Annotation-nålar per vän
  - FriendMapViewModel med UIImage-bildcache för kartnålar
  - FriendMapPin med temperaturfärgad border, storleksskillnad favorit/övrig
affects:
  - 05-02 (kategorier-placeholder redan på plats, FriendsTabView klar att utöka)

# Tech tracking
tech-stack:
  added: [MapKit (SwiftUI Map + Annotation + CLLocationCoordinate2D)]
  patterns:
    - Wrapper-vy (FriendsTabView) äger state och lyfter ner data till child-vyer
    - UIImage-cache i ViewModel för synkron rendering i MapKit Annotations
    - Segmented Picker med CaseIterable enum för flikhantering

key-files:
  created:
    - HotAndColdFriends/Features/FriendList/FriendsTabView.swift
    - HotAndColdFriends/Features/FriendList/FriendMapView.swift
    - HotAndColdFriends/Features/FriendList/FriendMapViewModel.swift
  modified:
    - HotAndColdFriends/Features/FriendList/FriendListView.swift
    - HotAndColdFriends/Core/Navigation/MainTabView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "FriendsTabView äger FriendListViewModel (inte FriendListView) — data laddas en gång och delas med karta och kategorier"
  - "FriendListView refaktoreras till dum vy med parametrar (viewModel, uid, friendService, weatherService, authManager)"
  - "UIImage-cache i FriendMapViewModel — undviker AsyncImage-renderingsproblem i MapKit Annotation-closure"
  - "ContentUnavailableView som empty state på kartan — visas om inga vänner har koordinater"
  - "MainTabView tar bort NavigationStack-wrapping runt Vänner-fliken — FriendsTabView hanterar NavigationStack internt"

patterns-established:
  - "Segmented control-vy: CaseIterable enum + Picker(.segmented) + switch i body"
  - "MapKit iOS 17+: Map(position:) { Annotation() { customView } } — ej deprecated MapAnnotation"
  - "Bildcache för MapKit: preloadImages() i ViewModel med URLSession, synkron UIImage i Annotation"

requirements-completed: [VIEW-03]

# Metrics
duration: 4min
completed: 2026-03-04
---

# Phase 05 Plan 01: FriendsTabView och FriendMapView Summary

**MapKit-kartvy med segmented control (Lista/Karta/Kategorier) — kartnålar med UIImage-cache, temperaturfärgade borders och storlek baserad på favorit-status**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-04T08:42:28Z
- **Completed:** 2026-03-04T08:46:28Z
- **Tasks:** 2
- **Files modified:** 5 (3 nya, 2 modifierade)

## Accomplishments

- FriendsTabView med segmented control ersätter FriendListView i MainTabView — all state och toolbar lyfts hit
- FriendListView refaktorerades till ren UI-komponent som tar viewModel och services som parametrar
- FriendMapView med MapKit Annotation-nålar renderar profilbild (UIImage) eller initialer med temperaturfärgad border
- Favoriter visas med 48pt nålar och 3pt border, övriga 36pt och 2pt — automatisk zoom via MapCameraPosition.automatic
- Vänner utan koordinater filtreras tyst, tom karta visar ContentUnavailableView

## Task Commits

Varje task committades atomärt:

1. **Task 1: FriendsTabView + refaktorerad FriendListView + MainTabView** - `deeaed1` (feat)
2. **Task 2: FriendMapView + FriendMapViewModel med bildcache** - `0af4690` (feat)

## Files Created/Modified

- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` - Wrapper-vy med FriendsTab-enum, Picker(.segmented), all toolbar/sheet-logik
- `HotAndColdFriends/Features/FriendList/FriendMapView.swift` - MapKit Map med Annotation + FriendMapPin (profilbild/initialer + temperatur)
- `HotAndColdFriends/Features/FriendList/FriendMapViewModel.swift` - Asynkron UIImage-cache via URLSession, @Observable @MainActor
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` - Refaktorerad till dum vy, tar viewModel+tjänster som parametrar
- `HotAndColdFriends/Core/Navigation/MainTabView.swift` - Ersätter FriendListView med FriendsTabView, tar bort NavigationStack-wrapping

## Decisions Made

- FriendsTabView äger FriendListViewModel — data laddas EN gång och skickas ner till karta och kategorier via parametrar, undviker triplerade nätverksanrop
- UIImage-cache i FriendMapViewModel — AsyncImage i Map Annotation ger renderingsproblem (research pitfall 1), synkron UIImage undviker det
- FriendListView tar authManager som parameter istället för @Environment — konsekvent med att alla services skickas explicit

## Deviations from Plan

Inga — planen exekverades exakt som skriven.

## Issues Encountered

Inga.

## User Setup Required

Inga — inga externa tjänster krävs. MapKit är inbyggt i iOS SDK.

## Next Phase Readiness

- FriendsTabView är klar med `.categories`-placeholder (`Text("Kategorier kommer snart")`) — Plan 05-02 kan direkt ersätta placeholdern med FriendCategoryView
- All data-delning mellan vyer är på plats: viewModel.favorites + viewModel.others skickas som parametrar
- WeatherDetailSheet återanvänds korrekt i kartvyn vid tap på nål

---
*Phase: 05-utokade-vyer*
*Completed: 2026-03-04*

## Self-Check: PASSED

**Files verified:**
- FOUND: HotAndColdFriends/Features/FriendList/FriendsTabView.swift
- FOUND: HotAndColdFriends/Features/FriendList/FriendMapView.swift
- FOUND: HotAndColdFriends/Features/FriendList/FriendMapViewModel.swift

**Commits verified:**
- FOUND: deeaed1 (feat(05-01): skapa FriendsTabView med segmented control)
- FOUND: 0af4690 (feat(05-01): implementera FriendMapView med MapKit-nalar)
