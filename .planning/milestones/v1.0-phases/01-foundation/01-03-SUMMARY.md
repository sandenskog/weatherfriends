---
phase: 01-foundation
plan: 03
subsystem: onboarding
tags: [swiftui, maplkit, cllocationmanager, photospicker, firestore, firebase-storage, ios17, observable]

# Dependency graph
requires:
  - 01-01: AuthManager, AppUser model, UserService (createUserProfile, uploadProfileImage, fetchUser)
  - 01-02: Fungerande auth-session med authState.needsOnboarding som ingångspunkt
provides:
  - Onboarding-wizard med tre steg (namn, foto, stad) som producerar fullständig AppUser med koordinater
  - LocationService med MKLocalSearchCompleter autocomplete och CLLocationManager GPS
  - ProfileView som halvmodal sheet (.medium detent) med rund profilbild, namn och stad
  - EditProfileView för att redigera namn, foto och stad med autocomplete + GPS
  - ProfileViewModel med loadProfile och updateProfile mot Firestore
  - MainTabView (temporär) med profilknapp och utloggning — ersätts i fas 2
  - AppRouter kopplad till OnboardingView och MainTabView baserat på authState
affects:
  - Fas 2+: koordinater i AppUser.cityLatitude/cityLongitude används av WeatherKit-anrop
  - Fas 2+: ProfileView och EditProfileView återanvänds för att visa vänners profiler

# Tech tracking
tech-stack:
  added:
    - MapKit (MKLocalSearchCompleter, MKLocalSearch)
    - CoreLocation (CLLocationManager, CLLocationUpdate.liveUpdates iOS 17+)
    - PhotosUI (PhotosPicker, PhotosPickerItem)
  patterns:
    - "@Observable class conformerar till MKLocalSearchCompleterDelegate via nonisolated extension"
    - "CLLocationUpdate.liveUpdates() async stream (iOS 17+) för GPS-position"
    - "OnboardingViewModel.completeOnboarding injicerar AuthManager och UserService som parametrar"
    - "TabView med .page(indexDisplayMode: .never) + extern currentStep-binding för wizard-navigation"
    - "Initial-avatar (initialer i cirkel) som fallback när profilbild saknas"
    - "ProfileView tar uid som parameter — kan visa vilken användares profil som helst"

key-files:
  created:
    - HotAndColdFriends/Services/LocationService.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingNameView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingPhotoView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingLocationView.swift
    - HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift
    - HotAndColdFriends/Features/Profile/ProfileView.swift
    - HotAndColdFriends/Features/Profile/EditProfileView.swift
    - HotAndColdFriends/Features/Profile/ProfileViewModel.swift
  modified:
    - HotAndColdFriends/Core/Navigation/AppRouter.swift
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "OnboardingViewModel använder direkt Firestore.firestore() för att spara profil (undviker @DocumentID nil-problem med UserService.createUserProfile)"
  - "LocationService.requestCurrentLocation() använder CLLocationUpdate.liveUpdates() (iOS 17+) — enkel for-await-in loop, returnerar vid första lyckade position"
  - "UserService injiceras som @Environment i appen-roten (HotAndColdFriendsApp) och skickas ner via SwiftUI-miljön"
  - "MKLocalSearchCompleter filtrerar resultat till subtitle.contains(',') || subtitle.isEmpty — städer/orter, inte gator"
  - "OnboardingPhotoView visar initial-avatar (initialer i cirkel) som default — ingen generisk person-ikon"
  - "MainTabView är temporär — ersätts med riktig TabView med väder och vänner i fas 2"

patterns-established:
  - "LocationService-mönster: @Observable NSObject med MKLocalSearchCompleterDelegate i nonisolated extension + Task @MainActor för state-uppdateringar"
  - "Wizard-mönster: TabView med .page-stil + extern currentStep-state + separata done-criteria per steg"
  - "Profil-mönster: ProfileView(uid:) + ProfileViewModel.loadProfile — återanvändbart för alla användare"

requirements-completed: [PROF-01, PROF-02, PROF-03]

# Metrics
duration: 10min
completed: 2026-03-02
---

# Phase 01 Plan 03: Onboarding och profil Summary

**Onboarding-wizard (namn, foto, stad med MKLocalSearchCompleter + GPS) och profilvisning/-redigering som halvmodal sheet — sparar AppUser med koordinater i Firestore**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-02T13:35:17Z
- **Completed:** 2026-03-02T13:45:00Z
- **Tasks:** 3/3 (Tasks 1-2 auto, Task 3 checkpoint:human-verify — GODKÄND)
- **Files modified:** 12 filer (9 skapade, 3 uppdaterade) + 1 buggfix-commit

## Accomplishments

- LocationService wrappas runt MKLocalSearchCompleter (autocomplete) och CLLocationManager (GPS) som @Observable NSObject
- OnboardingViewModel.completeOnboarding sparar AppUser med koordinater till Firestore och sätter authState = .authenticated
- OnboardingView: TabView-wizard med progress-indikator (3 dots + "Steg X av 3"), foto kan hoppas över, namn + stad krävs
- ProfileView: halvmodal sheet med .medium detent, rund profilbild (AsyncImage + initial-avatar fallback), "Redigera"-knapp för egen profil
- EditProfileView: NavigationStack med "Spara"-knapp i toolbar, autocomplete + GPS identisk med onboarding
- AppRouter: placeholders ersatta med OnboardingView och MainTabView baserat på authState
- UserService injiceras som @Environment i appens rot för enkel åtkomst i hela hierarkin

## Task Commits

| Task | Namn | Commit | Filer |
|------|------|--------|-------|
| 1 | LocationService och onboarding wizard | `dc7c197` | LocationService.swift, 5x Onboarding-filer, HotAndColdFriendsApp.swift, project.pbxproj |
| 2 | ProfileView, EditProfileView, AppRouter | `ee82c9a` | ProfileView.swift, EditProfileView.swift, ProfileViewModel.swift, AppRouter.swift, project.pbxproj |
| 3 | Checkpoint:human-verify GODKÄND — buggar fixade | `e7c3d24` | HotAndColdFriendsApp.swift, LocationService.swift |

## Files Created/Modified

- `HotAndColdFriends/Services/LocationService.swift` — @Observable NSObject wrapper runt MKLocalSearchCompleter + CLLocationManager
- `HotAndColdFriends/Features/Onboarding/OnboardingView.swift` — wizard container med TabView och progress-indikator
- `HotAndColdFriends/Features/Onboarding/OnboardingNameView.swift` — steg 1: TextField med @FocusState autofokus
- `HotAndColdFriends/Features/Onboarding/OnboardingPhotoView.swift` — steg 2: PhotosPicker med initial-avatar, "Hoppa över"-knapp
- `HotAndColdFriends/Features/Onboarding/OnboardingLocationView.swift` — steg 3: autocomplete, GPS-knapp, vald stad-visning
- `HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift` — @Observable @MainActor, completeOnboarding sparar till Firestore
- `HotAndColdFriends/Features/Profile/ProfileView.swift` — halvmodal sheet (.medium detent) med profilinfo
- `HotAndColdFriends/Features/Profile/EditProfileView.swift` — Form-baserad redigeringsskärm med autocomplete + GPS
- `HotAndColdFriends/Features/Profile/ProfileViewModel.swift` — loadProfile och updateProfile mot Firestore
- `HotAndColdFriends/Core/Navigation/AppRouter.swift` — ersätter placeholders med OnboardingView och MainTabView
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` — lägger till UserService som @Environment
- `HotAndColdFriends.xcodeproj/project.pbxproj` — regenererat av xcodegen (2 ggr)

## Decisions Made

- **Direktskrivning till Firestore i OnboardingViewModel:** `UserService.createUserProfile` kräver `user.id` (som är `@DocumentID`) vilket inte kan sättas vid skapande utan en existerande dokument-referens. Lösning: skriv direkt via `Firestore.firestore().collection("users").document(uid).setData()` i OnboardingViewModel, identiskt med hur AuthManager gör det.
- **CLLocationUpdate.liveUpdates() (iOS 17+):** Modern async-stream-baserad API istället för delegate-baserad CLLocationManager. Enklare, await-vänlig, och matchar deployment target iOS 17.
- **UserService som @Environment:** Ger alla vyer i hierarkin tillgång till en enda instans av UserService utan prop drilling. Instansen skapas i HotAndColdFriendsApp.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Lade till `import SwiftUI` i OnboardingViewModel.swift**
- **Found during:** Task 1 (xcodebuild-verifiering)
- **Issue:** `PhotosPickerItem` kunde inte hittas i scope med enbart `import PhotosUI` — typen kräver SwiftUI-ramverket
- **Fix:** Lade till `import SwiftUI` i OnboardingViewModel.swift
- **Files modified:** HotAndColdFriends/Features/Onboarding/OnboardingViewModel.swift
- **Verification:** xcodebuild BUILD SUCCEEDED
- **Committed in:** dc7c197

---

**2. [Rule 1 - Bug] Firebase SIGABRT-krasch vid cold start**
- **Found during:** Task 3 (checkpoint:human-verify — manuell simulatortest)
- **Issue:** FirebaseApp.configure() anropades i body-computed property, vilket orsakade SIGABRT-krasch vid cold start i simulatorn
- **Fix:** Flyttade FirebaseApp.configure() till explicit App.init() i HotAndColdFriendsApp.swift
- **Files modified:** HotAndColdFriends/App/HotAndColdFriendsApp.swift
- **Verification:** Appen startade stabilt i simulator utan krasch
- **Committed in:** e7c3d24

**3. [Rule 1 - Bug] Geo-sökresultat prioriterade inte städer**
- **Found during:** Task 3 (checkpoint:human-verify — manuell simulatortest)
- **Issue:** MKLocalSearchCompleter returnerade blandade resultat (gator, adresser) utan prioritering av städer och kommuner
- **Fix:** LocationService sorterar nu resultat efter location score — städer (subtitle innehåller land) lyfts fram före gator
- **Files modified:** HotAndColdFriends/Services/LocationService.swift
- **Verification:** "Stock" returnerade "Stockholm, Sverige" som förstaalternativ i autocomplete
- **Committed in:** e7c3d24

---

**Total deviations:** 3 auto-fixed (3 x Rule 1)
**Impact on plan:** Alla tre buggar nödvändiga att åtgärda för korrekt funktion. Ingen scope-creep.

## Issues Encountered

- iPhone 16 Simulator saknas i Xcode 26.2 — byggverktyget använder iPhone 17 istället. Ingen påverkan på koden.
- Två buggar hittades vid manuell verifiering i simulator (Task 3): Firebase init-ordning och geo-sökprioritering. Båda fixade i e7c3d24.

## Next Phase Readiness

- Projektet bygger utan kompileringsfel (verifierat med xcodebuild BUILD SUCCEEDED)
- Hela onboarding- och profilflödet testat end-to-end i simulator och GODKÄNT
- Onboarding-wizard producerar AppUser med koordinater (nödvändigt för WeatherKit i fas 2)
- Profil-CRUD är komplett och testad (uppdatering, visning, session-persistens)
- LocationService kan återanvändas i fas 2+ för stad-hantering
- Fas 1 komplett: AUTH-01 till AUTH-04, PROF-01 till PROF-03 uppfyllda

## Self-Check: PASSED

- FOUND: LocationService.swift
- FOUND: OnboardingView.swift
- FOUND: OnboardingViewModel.swift
- FOUND: ProfileView.swift
- FOUND: EditProfileView.swift
- FOUND: ProfileViewModel.swift
- FOUND: dc7c197 (Task 1 commit)
- FOUND: ee82c9a (Task 2 commit)
- FOUND: e7c3d24 (bugfix commit efter checkpoint-godkännande)

---
*Phase: 01-foundation*
*Completed: 2026-03-02*
