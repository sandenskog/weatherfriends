---
phase: 06-polish-app-store
plan: 01
subsystem: ui
tags: [swiftui, animation, canvas, timelineview, firebase-auth, firebase-firestore, firebase-storage, apple-sign-in, account-deletion]

requires:
  - phase: 05-utokade-vyer
    provides: FriendListViewModel, FriendRowView, FriendWeather-modell

provides:
  - WeatherAnimationView med 5 vädertyper (sol, moln, regn, snö, åska) via Canvas+TimelineView
  - WeatherCondition enum med from(symbolName:) factory
  - FriendRowView med animationslager (ZStack) bakom profilbild
  - AuthManager.deleteAccount() med full Firestore/Storage-cleanup + Apple token revocation
  - AuthManager.reauthenticate() för requiresRecentLogin-fallet
  - ProfileView med "Radera konto"-knapp, bekräftelsedialog och re-auth-alert
  - DeleteAccountError enum med lokaliserade meddelanden

affects:
  - 06-02-PLAN.md (widget, screenshots, App Store)

tech-stack:
  added: []
  patterns:
    - Canvas+TimelineView för energisnåla partikelanimationer utan UIKit
    - ZStack-lager: animation (40x40) bakom profilbild (34x34) — glöd-effekt runt kanten
    - App-only extension (WidgetFriendEntry+AppExtension.swift) för modell-metoder som kräver app-scope-typer

key-files:
  created:
    - HotAndColdFriends/Features/Animations/WeatherAnimationView.swift
    - HotAndColdFriends/Models/WidgetFriendEntry+AppExtension.swift
  modified:
    - HotAndColdFriends/Features/FriendList/FriendRowView.swift
    - HotAndColdFriends/Core/Auth/AuthManager.swift
    - HotAndColdFriends/Features/Profile/ProfileView.swift
    - HotAndColdFriends/Models/WidgetFriendEntry.swift

key-decisions:
  - "WeatherAnimationView visas som 40x40-ring bakom en 34x34 profilbild i ZStack — animationen syns som en glödande ram"
  - "WidgetFriendEntry.from(friendWeather:) flyttad till app-only extension — FriendWeather är ej tillgänglig i widget-target"
  - "cleanupUserData körs FÖRE user.delete() — säkerställer att Firestore-data raderas även om Auth-radering lyckas"
  - "revokeAppleToken() anropas innan user.delete() för Apple Sign In-användare — App Store-krav"
  - "if case DeleteAccountError.requiresRecentLogin pattern-matching — undviker Equatable-krav på enum med associated value"

patterns-established:
  - "Reduce Motion: @Environment(\\.accessibilityReduceMotion) — statisk SF Symbol-ikon vid aktiverat"
  - "Destructive actions: bekräftelsedialog -> ProgressView under körning -> authState-uppdatering vid lyckat utfall"

requirements-completed:
  - WTHR-02
  - AUTH-05

duration: 7min
completed: 2026-03-04
---

# Phase 6 Plan 1: WeatherAnimationView + Konto-radering Summary

**Canvas/TimelineView-animationer för 5 vädertyper bakom profilbild (WTHR-02) och full Firestore/Storage/Auth-radering med Apple token revocation (AUTH-05)**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-04T08:09:14Z
- **Completed:** 2026-03-04T08:16:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- WeatherAnimationView implementerar 5 vädertyper: SunPulseView (pulsande gul glöd), CloudDriftView (drivande moln via Canvas), ParticleAnimationView (regn/snö med Canvas+TimelineView), ThunderFlashView (periodiska blixtar)
- FriendRowView uppdaterad med ZStack — animationen (40x40) syns som en glödande ram runt profilbilden (34x34)
- AuthManager.deleteAccount() raderar all användardata: vänner, konversationer, meddelanden, Firestore-profil, Storage-profilbild, Apple token revocation, Firebase Auth-konto
- ProfileView visar "Radera konto"-knapp med bekräftelsedialog och re-auth-alert

## Task Commits

1. **Task 1: WeatherAnimationView + FriendRowView** - `d3eec34` (feat)
2. **Task 2: konto-radering AuthManager + ProfileView** - `43a2ac8` (feat)

## Files Created/Modified
- `HotAndColdFriends/Features/Animations/WeatherAnimationView.swift` - WeatherCondition enum + 5 animationskomponenter
- `HotAndColdFriends/Features/FriendList/FriendRowView.swift` - ZStack med WeatherAnimationView bakom profilbild
- `HotAndColdFriends/Core/Auth/AuthManager.swift` - deleteAccount, cleanupUserData, revokeAppleToken, reauthenticate, DeleteAccountError
- `HotAndColdFriends/Features/Profile/ProfileView.swift` - "Radera konto"-knapp, bekräftelsedialog, re-auth-alert, performDeleteAccount
- `HotAndColdFriends/Models/WidgetFriendEntry.swift` - from(friendWeather:) metod borttagen (widget-kompilering)
- `HotAndColdFriends/Models/WidgetFriendEntry+AppExtension.swift` - app-only extension med from(friendWeather:)

## Decisions Made
- WeatherAnimationView visas som 40x40-ring bakom profilbild (34x34) i en ZStack — animationen syns som en subtil, levande ram
- WidgetFriendEntry.from(friendWeather:) separerades till en app-only extension-fil för att lösa widget-kompileringsfel
- cleanupUserData körs FÖRE Firebase Auth-radering för att säkerställa att data raderas även vid timing-fel
- revokeAppleToken() kallas före user.delete() för Apple-användare — detta är Apples krav i App Store Review Guidelines

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] WidgetFriendEntry.from(friendWeather:) kompilerade inte i widget-target**
- **Found during:** Task 1 (xcodegen + build)
- **Issue:** WidgetFriendEntry.swift kompileras av widget-extension-targeten, men metoden refererade FriendWeather som inte finns i widget-scope
- **Fix:** Tog bort metoden från den delade filen och skapade WidgetFriendEntry+AppExtension.swift som en app-only fil
- **Files modified:** HotAndColdFriends/Models/WidgetFriendEntry.swift, HotAndColdFriends/Models/WidgetFriendEntry+AppExtension.swift
- **Verification:** BUILD SUCCEEDED efter fix
- **Committed in:** d3eec34 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Nödvändig fix för kompilering. Ingen scope creep.

## Issues Encountered
- xcodebuild returnerade "device not found" för iPhone 16 — bytte till iPhone 17 Simulator (OS 26.2)

## User Setup Required
None - ingen extern konfiguration krävs för dessa funktioner.

## Next Phase Readiness
- WTHR-02 och AUTH-05 uppfyllda — projektet redo för Plan 06-02
- WeatherAnimationView tillgänglig för eventuell widget-användning (utan FriendWeather-beroende)
- Konto-radering testad via kompilering — kräver manuell testning med riktig inloggning

---
*Phase: 06-polish-app-store*
*Completed: 2026-03-04*

## Self-Check: PASSED

- FOUND: HotAndColdFriends/Features/Animations/WeatherAnimationView.swift
- FOUND: HotAndColdFriends/Features/FriendList/FriendRowView.swift
- FOUND: HotAndColdFriends/Core/Auth/AuthManager.swift
- FOUND: HotAndColdFriends/Features/Profile/ProfileView.swift
- FOUND: HotAndColdFriends/Models/WidgetFriendEntry+AppExtension.swift
- FOUND commit d3eec34 (Task 1)
- FOUND commit 43a2ac8 (Task 2)
