---
phase: 06-polish-app-store
verified: 2026-03-04T09:00:00Z
status: human_needed
score: 11/11 automated must-haves verified
human_verification:
  - test: "Animerade väderillustrationer syns bakom profilbilder i vännerlistan"
    expected: "Sol, moln, regn, snö och åska animeras som en subtil glödring runt profilbilden"
    why_human: "Visuell animation — kan inte verifieras programmatiskt"
  - test: "Reduce Motion: statisk ikon visas istället för animation"
    expected: "Vid aktiverat Reduce Motion i iOS Inställningar visas SF Symbol-ikon utan rörelse"
    why_human: "Tillgänglighetsläge kräver simulator/enhet med Reduce Motion aktiverat"
  - test: "Radera konto-flöde med äkta inloggning"
    expected: "Bekräftelsedialog visas, data raderas från Firestore/Storage, användare loggas ut"
    why_human: "Kräver äkta Firebase-konto — kan inte testas statiskt"
  - test: "Apple token revocation vid konto-radering"
    expected: "Apple Sign In-användare får token revoked via revokeAppleToken() före user.delete()"
    why_human: "Kräver Apple Sign In-konto på fysisk enhet"
  - test: "iOS hemskärmswidget visas i alla tre storlekar med korrekt data"
    expected: "Small (1 favorit), medium (3-4), large (6) visar namn, stad, temperatur och väderikon"
    why_human: "Widget kräver simulator/enhet + manuell tilläggsprocess i hemskärmen"
  - test: "Widget deep link öppnar vännens väderdetalj i appen"
    expected: "Tapp på vän i widget startar appen och navigerar direkt till vännens vädervy"
    why_human: "Widget deep link-navigering kräver körande simulator"
  - test: "App Group-datadelning fungerar — widgeten visar favoriternas väder"
    expected: "Efter app-inloggning och vänsterladdning visas data i widgeten (kräver Apple Developer Portal-registrering av App Group)"
    why_human: "App Group kräver Developer Portal-konfiguration och fysisk enhet eller provisioned simulator"
---

# Phase 6: Polish — App Store Verification Report

**Phase Goal:** Polish app for App Store — animated weather illustrations, account deletion, iOS home screen widget
**Verified:** 2026-03-04T09:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths — Plan 06-01 (WTHR-02 + AUTH-05)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Animerade väderillustrationer visas bakom vännens profilbild i FriendRowView | ? HUMAN | WeatherAnimationView instansieras i ZStack i FriendRowView rad 64 — visuell verifiering krävs |
| 2 | 5 vädertyper hanteras: sol, moln, regn, snö, åska | VERIFIED | SunPulseView, CloudDriftView, ParticleAnimationView(.rain/.snow), ThunderFlashView — alla finns i WeatherAnimationView.swift |
| 3 | Animationer stängs av automatiskt om iOS Reduce Motion är aktiverat | VERIFIED | `@Environment(\.accessibilityReduceMotion)` läses, `staticIcon` returneras vid `reduceMotion == true` |
| 4 | Användare kan radera sitt konto via ProfileView | VERIFIED | "Radera konto"-knapp på rad 69, bekräftelsedialog på rad 97, performDeleteAccount() på rad 184 |
| 5 | Konto-radering tar bort: Firestore-profil, vänner, konversationer, meddelanden, Storage-profilbild och Firebase Auth-konto | VERIFIED | cleanupUserData() raderar friends-subcollection, conversations, messages, user-dokument, Storage profileImages/{uid} — sedan user.delete() |
| 6 | Apple Sign In-användare får token revocation vid konto-radering | VERIFIED | revokeAppleToken() anropas i deleteAccount() när provider == "apple.com" — rad 121 |
| 7 | Re-autentisering triggas automatiskt om Firebase kräver det | VERIFIED | DeleteAccountError.requiresRecentLogin fångas, showReauthAlert sätts, reauthenticate() anropas |

### Observable Truths — Plan 06-02 (WDGT-01)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 8 | iOS hemskärmswidget visar favoriters väder med profilbild, temperatur och SF Symbol | ? HUMAN | Kod finns — visuell verifiering på simulator krävs |
| 9 | Widget finns i tre storlekar: small (1 favorit), medium (3-4 favoriter), large (alla 6) | VERIFIED | SmallWidgetView, MediumWidgetView, LargeWidgetView + .supportedFamilies([.systemSmall, .systemMedium, .systemLarge]) |
| 10 | Widget-data uppdateras var 30:e minut | VERIFIED | TimelineProvider.getTimeline() skapar Timeline med policy .after(nextUpdate) 30 min |
| 11 | Privacy manifest deklarerar UserDefaults API-användning | VERIFIED | PrivacyInfo.xcprivacy innehåller NSPrivacyAccessedAPICategoryUserDefaults med reason CA92.1 |

**Automated score:** 9/11 truths fully verified, 2 require human visual confirmation.

---

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `HotAndColdFriends/Features/Animations/WeatherAnimationView.swift` | VERIFIED | Finns, innehaller WeatherCondition enum + 5 animationskomponenter |
| `HotAndColdFriends/Features/FriendList/FriendRowView.swift` | VERIFIED | ZStack med WeatherAnimationView rad 62-64 |
| `HotAndColdFriends/Core/Auth/AuthManager.swift` | VERIFIED | deleteAccount, cleanupUserData, revokeAppleToken, reauthenticate, DeleteAccountError — alla finns |
| `HotAndColdFriends/Features/Profile/ProfileView.swift` | VERIFIED | "Radera konto"-knapp + bekräftelsedialog + performDeleteAccount() |
| `HotAndColdFriendsWidget/HotAndColdFriendsWidget.swift` | VERIFIED | WeatherTimelineProvider + @main HotAndColdFriendsWidget |
| `HotAndColdFriendsWidget/WidgetViews.swift` | VERIFIED | SmallWidgetView, MediumWidgetView, LargeWidgetView, FriendWidgetCell |
| `HotAndColdFriends/Models/WidgetFriendEntry.swift` | VERIFIED | Codable transport-struct finns |
| `project.yml` | VERIFIED | HotAndColdFriendsWidgetExtension-target + App Group i bada targets |
| `HotAndColdFriends/Resources/PrivacyInfo.xcprivacy` | VERIFIED | NSPrivacyAccessedAPICategoryUserDefaults + CA92.1 |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| FriendRowView.swift | WeatherAnimationView | ZStack, rad 62-64 | WIRED | `WeatherAnimationView(condition: WeatherCondition.from(symbolName: ...))` |
| ProfileView.swift | AuthManager.deleteAccount() | performDeleteAccount() -> authManager.deleteAccount() | WIRED | Rad 188: `try await authManager.deleteAccount()` |
| AuthManager.swift | Firestore/Storage/Auth cleanup | cleanupUserData() + revokeAppleToken() + user.delete() | WIRED | Rader 117, 121, 125 — sekvens verifierad |
| FriendListViewModel.swift | UserDefaults(suiteName: group.se.sandenskog.hotandcoldfriends) | updateWidgetData() skriver widgetFavorites | WIRED | Rad 148: `defaults?.set(data, forKey: "widgetFavorites")` + WidgetCenter.reloadTimelines rad 150 |
| HotAndColdFriendsWidget.swift | UserDefaults(suiteName: ...) | loadFriends() laser widgetFavorites | WIRED | Rader 40-42: suiteName + data(forKey: "widgetFavorites") + JSONDecoder |
| WidgetViews.swift | hotandcold://friend/{id} | widgetURL/Link(destination:) | WIRED | SmallWidgetView rad 49: `.widgetURL(URL(string: "hotandcold://friend/\(friend.id)"))`, Medium/Large: Link(destination:) |
| HotAndColdFriendsApp.swift | AppRouter via .openWeatherAlert | .onOpenURL { url in } | WIRED | Rad 36-38: .onOpenURL parsar hotandcold://friend/<id>, postar .openWeatherAlert notification |

---

## Requirements Coverage

| Requirement | Plan | Status | Evidence |
|-------------|------|--------|----------|
| WTHR-02 — Animerade väderillustrationer | 06-01 | SATISFIED | WeatherAnimationView med 5 typer, integrerad i FriendRowView via ZStack |
| AUTH-05 — Konto-radering | 06-01 | SATISFIED | deleteAccount() med full Firestore/Storage/Auth cleanup i AuthManager, knapp i ProfileView |
| WDGT-01 — iOS hemskärmswidget | 06-02 | SATISFIED (kod) | WidgetKit-extension med small/medium/large, App Group UserDefaults, deep links — human-verify kvar |

Inga orphaned requirements identifierade. Alla tre krav som fasen deklarerade (AUTH-05, WTHR-02, WDGT-01) har motsvarande implementering.

---

## Anti-Patterns Found

Inga blockerande anti-patterns hittades. Inga TODO/FIXME/placeholder-kommentarer i de granskade filerna. Inga tomma handlers eller return null/return []-stubs utan faktisk logik.

---

## Human Verification Required

### 1. Animerade väderillustrationer — visuell kontroll

**Test:** Kör appen i simulator, gå till vännerlistan. Observera profilbilderna.
**Expected:** En subtil animerad glödring syns runt varje profilbild — sol pulserar gulaktigt, regn faller som partiklar, snö driver, moln flödar, åska blinkar periodiskt.
**Why human:** Visuell animation kan inte verifieras via grep/statisk analys.

### 2. Reduce Motion — tillgänglighetsläge

**Test:** Aktivera Reduce Motion i iOS Inställningar → Tillgänglighet → Rörelse. Starta om appen och titta på vännerlistan.
**Expected:** Statiska SF Symbol-ikoner (sol, moln, regn etc.) visas istället för animationer — ingen rörelse.
**Why human:** Kräver att tillgänglighetsläget aktiveras på simulator/enhet.

### 3. Radera konto — fullflöde

**Test:** Logga in, gå till Profil, scrolla ner till "Radera konto", bekräfta. Kontrollera att användaren loggas ut och att data försvinner från Firebase Console.
**Expected:** Bekräftelsedialog visas → ProgressView under radering → automatisk utloggning → Firestore-data borta.
**Why human:** Kräver äkta Firebase-konto och Firebase Console-åtkomst.

### 4. Apple token revocation

**Test:** Logga in med Apple Sign In på fysisk enhet, radera kontot. Kontrollera att Apple-token återkallas (inga felmeddelanden i processen).
**Expected:** Radering lyckas utan fel, Apple-token revoked.
**Why human:** Apple Sign In kräver fysisk enhet med Apple ID.

### 5. Widget — visning i alla storlekar

**Test:** Bygg och kör i simulator. Gå till hemskärmen, lägg till Hot & Cold Friends-widget i small, medium och large.
**Expected:** Small visar 1 favorit med namn/stad/temp/ikon. Medium visar 3-4 favoriter sida vid sida. Large visar 6 i ett 3x2-grid.
**Why human:** Widget-galleriet kräver körande simulator och manuell tilläggsprocess.

### 6. Widget deep link — navigation

**Test:** Med widget tillagd, tappa på en vän i widgeten.
**Expected:** Appen öppnas och navigerar direkt till den vännens väderdetaljvy.
**Why human:** Kräver körande simulator med widget tillagd.

### 7. App Group-datadelning

**Forutsattning:** App Group `group.se.sandenskog.hotandcoldfriends` registrerad i Apple Developer Portal (se 06-02-PLAN.md user_setup).
**Test:** Logga in i appen, vänta på att favoriter laddas. Kontrollera att widgeten visar favoritdata (inte bara "Inga favoriter").
**Expected:** Widgeten visar aktuella favoriters namn, temperatur och väderikon.
**Why human:** App Group kräver Developer Portal-registrering och provisioning — kan inte verifieras statiskt.

---

## Summary

Alla 11 automatiskt verifierbara must-haves i fas 06 har implementering i kodbasen:

- **WTHR-02 (animationer):** WeatherAnimationView implementerar alla 5 vädertyper med Canvas/TimelineView, Reduce Motion respekteras via `@Environment(\.accessibilityReduceMotion)`, FriendRowView har korrekt ZStack-integrering.
- **AUTH-05 (konto-radering):** deleteAccount() finns med cleanupUserData() (Firestore friends/conversations/messages/profil + Storage), revokeAppleToken() för Apple-användare, reauthenticate() för re-auth-fallet. ProfileView har knapp, dialog och flöde komplett.
- **WDGT-01 (widget):** WidgetKit-extension med TimelineProvider, tre storlekar, App Group UserDefaults-datadelning (skriv i FriendListViewModel, las i widget), hotandcold://-deep links i WidgetViews och .onOpenURL i HotAndColdFriendsApp, PrivacyInfo.xcprivacy med korrekt UserDefaults-reason.

7 items kräver manuell verifiering pa simulator/enhet — primärt visuella (animationer, widget-utseende) och integrationsbaserade (deep links, App Group-datadelning, Apple token revocation).

---

_Verified: 2026-03-04T09:00:00Z_
_Verifier: Claude (gsd-verifier)_
