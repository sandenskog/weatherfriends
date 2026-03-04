# Phase 6: Polish och App Store - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Appen passerar App Store-granskning och når riktiga användare via TestFlight och lansering — med hemskärmswidget, animerade väderillustrationer och alla obligatoriska krav (konto-radering, privacy manifests) uppfyllda. Inga nya features — enbart polish, compliance och submission.

</domain>

<decisions>
## Implementation Decisions

### Widget-design
- Visar enbart favoriter (konsekvent med appens favoritlogik)
- Tre storlekar: small (1 favorit), medium (3–4 favoriter), large (alla 6 favoriter)
- Per vän visas: profilbild, temperatur och SF Symbol väderikon
- Tappbar per vän — deep link öppnar den vännens väderdetalj i appen
- WidgetKit-target behöver läggas till i project.yml med App Group för delad data

### Väderanimationer
- Subtila SwiftUI-native animationer (inga externa beroenden som Lottie)
- Visas bakom profilbilden i FriendRowView (40x40 cirkel-area)
- Grundläggande 5 vädertyper: sol, moln, regn, snö, åska
- Respektera iOS "Reduce Motion" accessibility-inställning automatiskt (UIAccessibility.isReduceMotionEnabled)

### Konto-radering
- Full radering: Firestore-profil (users/), vänner (friends/), chattar/meddelanden (conversations/ + messages/), profilbild i Firebase Storage, Firebase Auth-konto
- Enkel bekräftelse: "Vill du verkligen radera ditt konto?"-dialog med röd knapp
- Placering: längst ner i befintlig ProfilView
- Re-autentisering: bara vid behov — försök radera, om Firebase ger "requires-recent-login"-fel, be användaren logga in igen

### App Store-metadata
- App-namn: "Hot & Cold Friends"
- Kategorier: Primär: Väder, Sekundär: Social Networking
- Åldersmärkning: Claude bedömer vad Apple godtar givet chatt med rapport/blockering

### Claude's Discretion
- Exakt animationsimplementation (partikelsystem, timing, easing)
- Privacy manifest-innehåll (baserat på faktiska API-anrop)
- Widget uppdateringsfrekvens (TimelineProvider-policy)
- App Store-åldersmärkning (bedömning av Apples riktlinjer)
- Skärmdumpar och marknadsföringstext (manuellt steg — inte del av kodfasen)

</decisions>

<specifics>
## Specific Ideas

- Widget ska följa samma temperatur-färgkodning som FriendRowView redan använder (Color.temperatureColor)
- Animationerna ska vara subtila och diskreta — inte distrahera från innehållet
- Konto-radering ska fungera oavsett login-provider (Apple/Google/Facebook)
- Skärmdumpar och App Store-beskrivning görs som manuellt steg när appen är testad

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FriendRowView` (Features/FriendList/FriendRowView.swift): Profilbild 40x40 + temperatur + ikon — animationer läggs bakom profileImage
- `Color.temperatureColor(celsius:)`: Färgkodning som widgeten kan återanvända
- `FriendWeather` (Models/FriendWeather.swift): temperatureCelsius, symbolName, conditionDescription — widgetens datamodell
- `AppWeatherService` (Services/AppWeatherService.swift): WeatherKit-integration med 30-min cache
- `FriendService` (Services/FriendService.swift): Firestore CRUD för vänner
- `AuthManager` (Core/Auth/AuthManager.swift): signOut() finns, deleteAccount() saknas
- `UserService` (Services/UserService.swift): CRUD för AppUser-profiler
- `ProfileView` (Features/Profile/ProfileView.swift): Befintlig profilvy — konto-radering läggs här

### Established Patterns
- `@Observable` + `@MainActor` för alla services och view models
- `@Environment` för dependency injection (AuthManager, AppWeatherService, FriendService)
- `project.yml` (XcodeGen) för projektgenerering — widget-target läggs till här
- Firebase SDK 11.x via SPM, WeatherKit via entitlements
- iOS 17.0 deployment target — stödjer alla moderna SwiftUI/WidgetKit features

### Integration Points
- Widget: Ny WidgetKit-target i project.yml, App Group för delad data, URL-schema för deep links
- Animationer: Modifiering av FriendRowView.profileImage
- Konto-radering: Utökning av AuthManager + ProfilView
- Privacy manifests: PrivacyInfo.xcprivacy i Resources/
- App Store: Archive → Validate via Xcode

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-polish-app-store*
*Context gathered: 2026-03-04*
