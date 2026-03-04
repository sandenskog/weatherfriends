---
phase: 01-foundation
plan: 02
subsystem: auth
tags: [firebase, apple-sign-in, google-sign-in, facebook-login, swiftui, cryptokit, ios]

# Dependency graph
requires:
  - 01-01: AuthManager stubs, AppUser model, UserService
provides:
  - signInWithApple med SHA256 CryptoKit nonce-flöde och ASAuthorizationController
  - signInWithGoogle med GIDSignIn async/await
  - signInWithFacebook med LoginManager och CheckedThrowingContinuation
  - Apple-namn sparas vid första inloggning (skickas bara en gång av Apple)
  - LoginView med gradient bakgrund (vit → ljusblå), appnamn och tagline
  - Tre login-knappar staplade vertikalt (Apple, Google, Facebook) — alla lika framträdande
  - LoginViewModel med isLoading/loadingProvider/errorMessage och svenska felmeddelanden
  - AuthError enum med LocalizedError
affects:
  - 01-03: Behöver fungerande auth-session och AppUser.displayName för onboarding-routing

# Tech tracking
tech-stack:
  added:
    - CryptoKit (SHA256 för Apple Sign-In nonce)
    - AuthenticationServices (ASAuthorizationAppleIDProvider, ASAuthorizationController)
  patterns:
    - "Apple nonce-flöde: randomNonceString → SHA256(nonce) till Apple, raw nonce till Firebase"
    - "ASAuthorizationController wrappas i CheckedThrowingContinuation via delegate"
    - "GIDSignIn.sharedInstance.signIn(withPresenting:) med async/await"
    - "LoginManager.logIn wrappas i withCheckedThrowingContinuation"
    - "LoginViewModel delegerar till AuthManager — hanterar loading state och felmeddelanden"

key-files:
  created:
    - HotAndColdFriends/Features/Login/LoginViewModel.swift
  modified:
    - HotAndColdFriends/Core/Auth/AuthManager.swift
    - HotAndColdFriends/Features/Login/LoginView.swift
    - HotAndColdFriends.xcodeproj/project.pbxproj

key-decisions:
  - "NSObject-arv krävs i AuthManager för ASAuthorizationControllerDelegate och ASAuthorizationControllerPresentationContextProviding"
  - "rootViewController() är @MainActor utan async — direktanrop utan await i signInWithGoogle/Facebook"
  - "Facebook-cancelled hanteras tyst — AuthError.cancelled visar inget felmeddelande till användaren"
  - "xcodegen behöver köras om när nya .swift-filer skapas — projekt plockar inte upp dem automatiskt"

# Metrics
duration: 16min
completed: 2026-03-02
requirements-completed:
  - AUTH-01
  - AUTH-02
  - AUTH-03
---

# Phase 01 Plan 02: Social Login Implementation Summary

**Fullständiga Apple/Google/Facebook login-flöden med Firebase Auth-integration, CryptoKit nonce-hantering och LoginView med gradient, appnamn och tre lika framträdande login-knappar**

## Performance

- **Duration:** 16 min
- **Started:** 2026-03-02T13:07:36Z
- **Completed:** 2026-03-02T13:23:32Z
- **Tasks:** 2/2 auto-tasks
- **Files modified:** 4 filer (1 skapad, 3 uppdaterade)

## Accomplishments

- AuthManager implementerar alla tre login-metoder med korrekt Firebase Auth credential-flöde
- Apple Sign-In använder SHA256-nonce korrekt: raw nonce till Firebase, hashad nonce till Apple
- Apple-namn sparas i Firebase Auth user profile vid första inloggning (Apple skickar fullName bara en gång)
- Google Sign-In med GIDSignIn async/await och korrekt clientID-hämtning från FirebaseApp
- Facebook Login wrappas i async/await via CheckedThrowingContinuation
- LoginView visar gradient bakgrund (vit → ljusblå), appnamn "Hot & Cold Friends", tagline "Se vädret hos dina vänner"
- Tre login-knappar staplade vertikalt — Apple (svart, Apple HIG), Google (vit med border), Facebook (Facebook-blå)
- Loading state per knapp: spinner visas på aktiv knapp, övriga inaktiveras
- LoginViewModel hanterar alla loading states och felmeddelanden på svenska

## Task Commits

| Task | Namn | Commit | Filer |
|------|------|--------|-------|
| 1 | Tre login-metoder i AuthManager | `91b5958` | AuthManager.swift |
| 2 | LoginView och LoginViewModel | `b95ffc2` | LoginView.swift, LoginViewModel.swift, project.pbxproj |

## Files Created/Modified

- `HotAndColdFriends/Core/Auth/AuthManager.swift` — fullständiga signInWithApple/Google/Facebook, NSObject-arv, AuthError enum
- `HotAndColdFriends/Features/Login/LoginView.swift` — gradient, tre knappar, loading state, error alert
- `HotAndColdFriends/Features/Login/LoginViewModel.swift` — @Observable @MainActor, delegerar till AuthManager
- `HotAndColdFriends.xcodeproj/project.pbxproj` — regenererat av xcodegen med LoginViewModel.swift inkluderad

## Decisions Made

- **NSObject-arv:** `AuthManager` måste ärva från `NSObject` för att conformera till `ASAuthorizationControllerDelegate` och `ASAuthorizationControllerPresentationContextProviding`. `@Observable`-klasser kan vara NSObject-subklasser utan konflikt.
- **Cancelled hanteras tyst:** `AuthError.cancelled` (Facebook/Apple avbruten av användaren) visar inget felmeddelande — det är ett medvetet val, inte ett fel.
- **xcodegen vid nya filer:** `project.yml` inkluderar hela `HotAndColdFriends`-mappen men Xcode-projektet (`project.pbxproj`) måste regenereras med xcodegen varje gång nya Swift-filer läggs till.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] xcodegen krävdes för att registrera LoginViewModel.swift**
- **Found during:** Task 2 (build-verifiering)
- **Issue:** Xcode-projektet plockar inte upp nya Swift-filer automatiskt — `LoginViewModel` kunde inte hittas i scope
- **Fix:** Körde `xcodegen generate` för att regenerera `project.pbxproj`
- **Files modified:** `HotAndColdFriends.xcodeproj/project.pbxproj`
- **Verification:** xcodebuild BUILD SUCCEEDED
- **Committed in:** b95ffc2

**2. [Rule 1 - Bug] FirebaseApp inte i scope utan FirebaseCore-import**
- **Found during:** Task 1 (build-verifiering)
- **Issue:** `FirebaseApp.app()?.options.clientID` kompilerade inte utan explicit `import FirebaseCore`
- **Fix:** Lade till `import FirebaseCore` i AuthManager.swift
- **Files modified:** HotAndColdFriends/Core/Auth/AuthManager.swift
- **Verification:** xcodebuild BUILD SUCCEEDED
- **Committed in:** 91b5958

---

**Total deviations:** 2 auto-fixed (1 x Rule 3, 1 x Rule 1)
**Impact:** Nödvändiga fixar, ingen scope-creep.

## Requirements Completed

- AUTH-01: Användare kan logga in med Sign in with Apple
- AUTH-02: Användare kan logga in med Google Sign-In
- AUTH-03: Användare kan logga in med Facebook Login

## Next Phase Readiness

- Projektet bygger utan kompileringsfel (verifierat med xcodebuild)
- Alla tre login-metoder implementerade med Firebase Auth credential-flöde
- LoginView redo med korrekt design och UX
- Kvarvarande: Kräver GoogleService-Info.plist och Facebook-konfiguration i Info.plist för faktisk körning (konfigurerades av användaren som del av Plan 01 checkpoint)

## Self-Check: PASSED

- FOUND: AuthManager.swift
- FOUND: LoginView.swift
- FOUND: LoginViewModel.swift
- FOUND: 91b5958 (Task 1 commit)
- FOUND: b95ffc2 (Task 2 commit)
