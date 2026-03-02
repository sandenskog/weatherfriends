---
phase: 01-foundation
plan: 01
subsystem: auth
tags: [firebase, fireauth, firestore, swiftui, xcodegen, spm, googleSignIn, facebook, ios]

# Dependency graph
requires: []
provides:
  - Xcode-projekt HotAndColdFriends (iOS 17+, se.sandenskog.hotandcoldfriends)
  - Firebase, GoogleSignIn och Facebook SDK via SPM (xcodegen/project.yml)
  - AppDelegate med URL-hantering för Google och Facebook OAuth
  - @Observable @MainActor AuthManager med Firebase addStateDidChangeListener
  - AuthState enum (unauthenticated/authenticating/needsOnboarding/authenticated)
  - AppRouter med auth-baserad routing (switch på authState)
  - AppUser Firestore Codable model med @DocumentID och @ServerTimestamp
  - UserService med createUserProfile, fetchUser, updateUser, uploadProfileImage
  - Firestore Security Rules (auth-baserad read, owner-baserad write)
affects:
  - 01-02: Behöver AuthManager stubs för signInWithApple/Google/Facebook
  - 01-03: Behöver UserService.createUserProfile och AppUser.displayName/city
  - 02: Behöver AppUser.cityLatitude/cityLongitude för WeatherKit

# Tech tracking
tech-stack:
  added:
    - Firebase iOS SDK 11.15.0 (FirebaseAuth, FirebaseFirestore, FirebaseStorage)
    - GoogleSignIn-iOS 7.1.0 (GoogleSignIn, GoogleSignInSwift)
    - Facebook iOS SDK 17.4.0 (FacebookCore, FacebookLogin)
    - xcodegen (projekt-generering via project.yml)
  patterns:
    - "@Observable @MainActor class för state-hantering (iOS 17+)"
    - "addStateDidChangeListener i init, removeStateDidChangeListener i deinit"
    - "AuthState enum som state machine för auth-routing"
    - "AppRouter switch:ar på authState — separerar auth-flöde från main-flöde"
    - "Firestore Codable med @DocumentID och @ServerTimestamp"

key-files:
  created:
    - HotAndColdFriends.xcodeproj/project.pbxproj
    - project.yml
    - HotAndColdFriends/App/HotAndColdFriendsApp.swift
    - HotAndColdFriends/App/AppDelegate.swift
    - HotAndColdFriends/Core/Auth/AuthManager.swift
    - HotAndColdFriends/Core/Auth/AuthState.swift
    - HotAndColdFriends/Core/Navigation/AppRouter.swift
    - HotAndColdFriends/Features/Login/LoginView.swift
    - HotAndColdFriends/Models/AppUser.swift
    - HotAndColdFriends/Services/UserService.swift
    - firestore.rules
    - .gitignore
  modified: []

key-decisions:
  - "FirebaseFirestoreSwift är integrerat i FirebaseFirestore från SDK 11.x — ej ett separat SPM-paket"
  - "nonisolated(unsafe) används för listenerHandle i AuthManager för att tillåta deinit-åtkomst"
  - "AuthManager.fetchOrCreateUserProfile kontrollerar displayName.isEmpty för needsOnboarding-routing"
  - "xcodegen valdes för att generera Xcode-projektet via CLI (project.yml)"

patterns-established:
  - "Pattern: @Observable @MainActor class med Firebase auth listener"
  - "Pattern: AuthState enum som root-level state machine"
  - "Pattern: AppRouter switch på authState — fyra cases"
  - "Pattern: Firestore Codable med @DocumentID och cityLatitude/cityLongitude för WeatherKit"

requirements-completed:
  - AUTH-04

# Metrics
duration: 7min
completed: 2026-03-02
---

# Phase 01 Plan 01: Foundation Setup Summary

**Xcode-projekt med Firebase Auth, Firestore och social login-SDK:er via SPM, @Observable AuthManager med auth state listener, AuthState routing och AppUser Firestore-modell**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-02T11:55:31Z
- **Completed:** 2026-03-02T12:02:00Z
- **Tasks:** 2/2 auto-tasks (Task 3 = checkpoint:human-verify, pausad)
- **Files modified:** 12 filer skapade

## Accomplishments

- Byggbart Xcode-projekt med alla SPM-beroenden resolved (Firebase 11.15.0, GoogleSignIn 7.1.0, Facebook 17.4.0)
- @Observable AuthManager med Firebase auth state listener — reagerar automatiskt på auth-förändringar
- AppRouter visar LoginView (placeholder) när authState = .unauthenticated
- AppUser Firestore-modell med @DocumentID, @ServerTimestamp och koordinatfält för WeatherKit (fas 2)
- Firestore Security Rules med auth-baserade regler satta innan data börjar skrivas

## Task Commits

Varje task committades atomärt:

1. **Task 1: Xcode-projekt med Firebase och SPM-beroenden** - `a97f432` (feat)
2. **Task 2: AuthManager, AuthState, AppRouter, AppUser och UserService** - `03b8416` (feat)

_Task 3 är checkpoint:human-verify — väntar på användargodkännande_

## Files Created/Modified

- `HotAndColdFriends.xcodeproj/project.pbxproj` - Genererat Xcode-projekt (via xcodegen)
- `project.yml` - xcodegen-konfiguration med SPM-beroenden
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` - @main med UIApplicationDelegateAdaptor och AuthManager i environment
- `HotAndColdFriends/App/AppDelegate.swift` - Firebase.configure(), GIDSignIn URL-hantering, Facebook ApplicationDelegate
- `HotAndColdFriends/Core/Auth/AuthManager.swift` - @Observable @MainActor med addStateDidChangeListener
- `HotAndColdFriends/Core/Auth/AuthState.swift` - Enum med unauthenticated/authenticating/needsOnboarding/authenticated
- `HotAndColdFriends/Core/Navigation/AppRouter.swift` - Root routing via switch på authState
- `HotAndColdFriends/Features/Login/LoginView.swift` - Placeholder LoginView (ersätts i Plan 02)
- `HotAndColdFriends/Models/AppUser.swift` - Firestore Codable med @DocumentID, @ServerTimestamp och koordinater
- `HotAndColdFriends/Services/UserService.swift` - CRUD (createUserProfile/fetchUser/updateUser/uploadProfileImage)
- `firestore.rules` - Produktionsregler (read=auth, write=owner)
- `.gitignore` - GoogleService-Info.plist exkluderad

## Decisions Made

- **FirebaseFirestoreSwift separat paket:** I Firebase SDK 11.x är `FirebaseFirestoreSwift`-modulen integrerad direkt i `FirebaseFirestore` — den existerar inte längre som separat SPM-produkt. Import-satserna uppdaterades till bara `import FirebaseFirestore`.
- **nonisolated(unsafe) för listenerHandle:** `@MainActor`-isolerade klasser kan inte referera isolerade egenskaper från `deinit` (nonisolated context). Lösningen är `nonisolated(unsafe)` på `listenerHandle`.
- **xcodegen för projektgenerering:** Xcode-projekt kan inte skapas via CLI utan ett verktyg. xcodegen hittades installerat och valdes — projekt.yml är versionsstyrd och kan regenereras.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FirebaseFirestoreSwift är inte längre ett separat SPM-paket i Firebase 11.x**
- **Found during:** Task 1 (build-verifiering)
- **Issue:** project.yml refererade `FirebaseFirestoreSwift` som separat SPM-produkt, men det existerar inte i Firebase SDK 11.x (integrerat i FirebaseFirestore)
- **Fix:** Tog bort `FirebaseFirestoreSwift` från project.yml dependencies; uppdaterade AppUser.swift och UserService.swift att bara importera `FirebaseFirestore`
- **Files modified:** project.yml, HotAndColdFriends/Models/AppUser.swift, HotAndColdFriends/Services/UserService.swift
- **Verification:** xcodebuild BUILD SUCCEEDED
- **Committed in:** a97f432, 03b8416

**2. [Rule 1 - Bug] @MainActor-isolering av listenerHandle blockerar deinit**
- **Found during:** Task 2 (build-verifiering)
- **Issue:** `@MainActor`-klass kan inte referera isolerade egenskaper från nonisolated `deinit` — kompileringsfel
- **Fix:** Lade till `nonisolated(unsafe)` på `listenerHandle`-egenskapen
- **Files modified:** HotAndColdFriends/Core/Auth/AuthManager.swift
- **Verification:** xcodebuild BUILD SUCCEEDED
- **Committed in:** 03b8416

---

**Total deviations:** 2 auto-fixed (2 x Rule 1 - Bug)
**Impact on plan:** Nödvändiga fixar för att projektet ska bygga. Ingen scope-creep.

## Issues Encountered

- iPhone 16-simulatorn existerar inte (Xcode kör iOS 26.2 SDK) — build-verifiering kördes med iPhone 17 istället

## User Setup Required

**Kräver manuell konfiguration av Firebase och Facebook innan Plan 02 kan köras.**

Se Task 3 checkpoint för exakta steg:

1. Skapa Firebase-projekt på https://console.firebase.google.com
2. Aktivera Authentication med Apple, Google och Facebook providers
3. Ladda ned `GoogleService-Info.plist` och lägg i `HotAndColdFriends/Resources/` (ej i git)
4. Skapa Facebook-app på https://developers.facebook.com
5. Lägg till `FacebookAppID`, `FacebookClientToken`, `FacebookDisplayName` i `Info.plist`
6. Lägg till URL scheme `fb{APP_ID}` i Xcode URL Types
7. Lägg till `REVERSED_CLIENT_ID` från `GoogleService-Info.plist` som URL Type

## Next Phase Readiness

- Projektet bygger utan kompileringsfel (verifierat med xcodebuild)
- Alla SPM-beroenden resolvade: Firebase 11.15.0, GoogleSignIn 7.1.0, Facebook 17.4.0
- AuthManager-mönstret etablerat som arkitekturgrund för fas 1 och 2
- AppUser-modell redo med koordinatfält för WeatherKit i fas 2
- Kvarvarande: Firebase-projekt och Facebook-app måste skapas av användaren (Task 3 checkpoint)

---
*Phase: 01-foundation*
*Completed: 2026-03-02*
