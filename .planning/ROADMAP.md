# Roadmap: Hot & Cold Friends

## Overview

Sex faser levererar en komplett iOS-app: autentisering och profil skapar grunden, kärnupplevelsen (vädervy och favoriter) validerar konceptet, kontaktimport fyller appen med vänner via AI, chatt och push skapar den sociala triggern (med App Store-obligatorisk moderering), utökade vyer lägger till differentiering, och sista fasen polerar och skickar till App Store.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Auth, profil och datamodell — allt annat beror på detta (completed 2026-03-02)
- [x] **Phase 2: Kärnupplevelse** - Vädervy, favoriter, onboarding med live exempeldata (completed 2026-03-02)
- [x] **Phase 3: Kontaktimport** - iOS Contacts-import med AI-driven platsgissning (completed 2026-03-03)
- [x] **Phase 4: Chatt och Push** - Realtidschatt, push-notiser och UGC-moderering (completed 2026-03-03)
- [x] **Phase 4.1: Fixa onboarding-kontaktimport** - INSERTED: Onboarding-wrapper anropar guessLocations() och sparar koordinater (Gap Closure) (completed 2026-03-03)
- [x] **Phase 4.2: Fixa chatt-UID-mismatch** - INSERTED: Använd Auth UID istället för Friend.id vid chatt-skapande (Gap Closure) (completed 2026-03-03)
- [x] **Phase 4.3: Fixa push deep link och tech debt** - INSERTED: Deep link-handler för weatherAlert + fcmToken i AppUser (Gap Closure) (completed 2026-03-03)
- [x] **Phase 4.4: Fixa authUid-population vid Friend-skapande** - INSERTED: Sätt authUid i alla Friend-skapande kodvägar (Gap Closure) (completed 2026-03-03)
- [x] **Phase 4.5: Vänprofil-navigation och dokumentationsfix** - INSERTED: Tappbar profil-vy + SUMMARY/traceability-fix (Gap Closure) (completed 2026-03-03)
- [x] **Phase 5: Utökade Vyer** - Kartvy, grupperade väderkort och daglig sammanfattning (completed 2026-03-04)
- [x] **Phase 6: Polish och App Store** - Widget, animationer och App Store-lansering (completed 2026-03-04)
- [ ] **Phase 7: Tech Debt Cleanup** - DI-fix, dead code removal och dokumentationsfix (Gap Closure)

## Phase Details

### Phase 1: Foundation
**Goal**: Användare kan skapa konto, logga in och ange sin plats — den autentiserade och platsbekräftade användaren som allt annat bygger på
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, PROF-01, PROF-02, PROF-03
**Success Criteria** (what must be TRUE):
  1. Användare kan logga in med Sign in with Apple, Google Sign-In eller Facebook Login
  2. Inloggad session bevaras när appen stängs och öppnas igen
  3. Användare kan skapa profil med namn, profilbild och sin stad/land
  4. Användare kan se en annan användares profil
**Plans:** 3/3 plans complete

Plans:
- [x] 01-01-PLAN.md — Xcode-projekt, Firebase/SPM-setup, AuthManager, AppUser-modell och UserService
- [x] 01-02-PLAN.md — Social login (Sign in with Apple + Google + Facebook) och LoginView
- [x] 01-03-PLAN.md — Onboarding-wizard, stad-autocomplete, profilvisning och profilredigering

### Phase 2: Kärnupplevelse
**Goal**: Appen visar vädret hos vänner, sorterat och levande, med live exempeldata redan vid first run — kärnvärdet demonstrerat utan att behöva importera kontakter
**Depends on**: Phase 1
**Requirements**: WTHR-01, WTHR-02, WTHR-03, VIEW-01, VIEW-04, FRND-04, FRND-05
**Success Criteria** (what must be TRUE):
  1. Vid first run visas live exempeldata med fiktiva vänner och riktigt väder — aldrig en tom vy
  2. Användare ser en lista med vänner sorterad från varmast till kallast med temperatur, ikon och animerad illustration
  3. Väderdata uppdateras automatiskt och cachas i 30 minuter utan att användaren behöver göra något
  4. Användare kan välja 6 favoriter som alltid visas överst i listan
  5. Användare uppmanas under onboarding att ange stad/land för sina favoriter
**Plans:** 4/4 plans complete

Plans:
- [ ] 02-01-PLAN.md — Friend/FriendWeather-modeller, AppWeatherService (WeatherKit + 30-min TTL-cache), FriendService (Firestore CRUD), DemoFriendService (8 demo-vänner) och WeatherKit-entitlements
- [ ] 02-02-PLAN.md — Vädersorterad listvy (FriendListView) med sektioner, FriendRowView, WeatherDetailSheet, swipe-favoriter, demo-banner, temperaturfärgkodning och Apple Weather-attribution
- [ ] 02-03-PLAN.md — Utökat onboarding-flöde (steg 4: lägg till vänner med stad-autocomplete), automatiska favoriter (de 6 första)
- [ ] 02-04-PLAN.md — Gap closure: korrigera WTHR-02 dokumentation och fixa svenska tecken i FriendListView

### Phase 3: Kontaktimport
**Goal**: Användare kan snabbt fylla appen med vänner via iOS-kontakter där AI gissar plats — och alltid ha manuellt tillägg som fallback
**Depends on**: Phase 2
**Requirements**: FRND-01, FRND-02, FRND-03
**Success Criteria** (what must be TRUE):
  1. Användare kan importera kontakter från iOS-adressboken (med begärt tillstånd)
  2. AI ger ett platsförslag (stad/land) per importerad kontakt baserat på adress, telefonnummer och e-post
  3. Användare kan bekräfta, justera eller avvisa AI:ns platsförslag innan vännen sparas
  4. Användare kan manuellt lägga till en vän med namn och stad/land utan att importera kontakter
**Plans:** 2/2 plans complete

Plans:
- [x] 03-01-PLAN.md — ContactImportService (CNContactStore + Firebase Storage), ContactImportView (multi-select + sökfält), meny-integration i FriendListView och OnboardingFavoritesView
- [ ] 03-02-PLAN.md — Firebase Cloud Function (guessContactLocations + OpenAI gpt-4o-mini), ImportReviewView (konfidens-färger + stad-korrigering), uppdaterat importflöde

### Phase 4: Chatt och Push
**Goal**: Användare kan chatta med vänner i realtid och ta emot push-notiser — med rapport och blockering inbyggt (App Store Guideline 1.2-krav)
**Depends on**: Phase 3
**Requirements**: CHAT-01, CHAT-02, CHAT-03, CHAT-04, CHAT-05, PUSH-01, PUSH-03
**Success Criteria** (what must be TRUE):
  1. Användare kan skicka och ta emot 1-till-1-meddelanden i realtid
  2. Användare kan skapa gruppchattar och delta i dem
  3. Användare kan skicka väderreaktioner (emoji kopplad till vänens aktuella väder)
  4. Användare kan rapportera olämpligt innehåll och blockera en annan användare
  5. Användare får push-notis vid nytt chattmeddelande och vid extremväder hos en vän
**Plans:** 4/4 plans complete

Plans:
- [x] 04-01-PLAN.md — Conversation/ChatMessage/Report-modeller, ChatService (Firestore listeners + CRUD), MainTabView, AppRouter-uppdatering, FCM-setup (AppDelegate + project.yml)
- [x] 04-02-PLAN.md — ConversationListView, ChatView (iMessage-stil bubblor + väder-header), NewConversationSheet (1-till-1 + grupp), WeatherStickerView, rapport/blockering-UI
- [x] 04-03-PLAN.md — Cloud Functions (chatPushTrigger + weatherAlertScheduler), APNs-nyckeluppladdning
- [ ] 04-04-PLAN.md — Gap closure: WeatherAlertService (iOS WeatherKit alerts -> Firestore), weatherAlertTrigger (Cloud Function FCM push), PUSH-01 komplett

### Phase 4.1: Fixa onboarding-kontaktimport (INSERTED — Gap Closure)
**Goal**: Kontakter importerade via onboarding-flödet får AI-platsgissning och koordinater — så att WeatherKit kan visa väder för alla vänner
**Depends on**: Phase 4
**Requirements**: FRND-03, FRND-04, WTHR-01 (partial → satisfied)
**Gap Closure**: Closes gaps from audit — onboarding-wrapper hoppar över guessLocations()
**Success Criteria** (what must be TRUE):
  1. ContactImportOnboardingWrapper anropar guessLocations() för importerade kontakter
  2. Användare ser ImportReviewView med AI-platsförslag innan kontakter sparas via onboarding
  3. Alla sparade vänner har cityLatitude/cityLongitude — WeatherKit returnerar data
**Plans:** 1/1 plans complete

Plans:
- [ ] 04.1-01-PLAN.md — Refaktorera ImportReviewView med mode-enum + auto-geocoding, uppdatera ContactImportView, utöka ContactImportOnboardingWrapper med guessLocations() och ImportReviewView

### Phase 4.2: Fixa chatt-UID-mismatch (INSERTED — Gap Closure)
**Goal**: Chattar skapas med korrekt Firebase Auth UID — så att mottagaren ser konversationen i sin lista
**Depends on**: Phase 4.1
**Requirements**: CHAT-01, CHAT-02 (partial → satisfied)
**Gap Closure**: Closes gaps from audit — Friend.id (Firestore doc-ID) skickas istället för Auth UID
**Success Criteria** (what must be TRUE):
  1. NewConversationSheet skickar vännens Auth UID (inte Friend.id) till getOrCreateDirectConversation()
  2. Mottagaren ser konversationen i sin konversationslista
**Plans:** 1/1 plans complete

Plans:
- [ ] 04.2-01-PLAN.md — Lägg till authUid på Friend-modellen och uppdatera NewConversationSheet att använda Auth UID istället för Friend.id

### Phase 4.3: Fixa push deep link och tech debt (INSERTED — Gap Closure)
**Goal**: Tap på extremväder-push navigerar till rätt vy, och latenta risker (fcmToken, dead code) åtgärdas
**Depends on**: Phase 4.2
**Requirements**: PUSH-01 (partial → satisfied)
**Gap Closure**: Closes gaps from audit — deep link, fcmToken, tech debt
**Success Criteria** (what must be TRUE):
  1. Tap på extremväder-push navigerar till vännens väderdetalj (AppDelegate hanterar type=weatherAlert)
  2. fcmToken finns i AppUser Codable-modell (förhindrar att token skrivs över)
  3. Debug-print och dead code (saveImportedContacts, uploadContactPhoto) borttagna
**Plans:** 1/1 plans complete

Plans:
- [ ] 04.3-01-PLAN.md — Deep link-handler for weatherAlert push + fcmToken i AppUser + dead code/debug-print cleanup

### Phase 4.4: Fixa authUid-population vid Friend-skapande (INSERTED — Gap Closure)
**Goal**: Alla Friend-dokument får korrekt authUid via lookup mot users-kollektionen — så att chatt fungerar för alla vänner
**Depends on**: Phase 4.3
**Requirements**: CHAT-01, CHAT-02 (unsatisfied → satisfied)
**Gap Closure**: Closes gaps from audit — Friend.authUid aldrig satt av skrivvägar
**Success Criteria** (what must be TRUE):
  1. AddFriendSheet sätter authUid vid Friend-skapande via lookup mot users-kollektionen
  2. ContactImportService.saveReviewedContacts() sätter authUid via lookup
  3. OnboardingViewModel.completeOnboarding() sätter authUid via lookup
  4. NewConversationSheet kan öppna direktchatt utan "inget konto"-felmeddelande
  5. Gruppchattar kan skapas med vänner som har matchande Auth-konto
**Plans:** 1/1 plans

Plans:
- [ ] 04.4-01-PLAN.md — UserService.lookupAuthUid + authUid-population i AddFriendSheet, ContactImportService och OnboardingViewModel

### Phase 4.5: Vänprofil-navigation och dokumentationsfix (INSERTED — Gap Closure)
**Goal**: Användare kan navigera till en väns profil från UI + dokumentationsgap fixade
**Depends on**: Phase 4.4
**Requirements**: PROF-03 (partial → satisfied), AUTH-01, AUTH-02, AUTH-03 (doc fix)
**Gap Closure**: Closes gaps from audit — ProfileView ej nåbar + SUMMARY-doc saknas
**Success Criteria** (what must be TRUE):
  1. Användare kan tappa på en vän i FriendListView/WeatherDetailSheet för att se vännens profil
  2. ProfileView visar korrekt data för vännen (namn, profilbild, stad)
  3. AUTH-01, AUTH-02, AUTH-03 finns i 01-02-SUMMARY.md frontmatter
  4. REQUIREMENTS.md traceability-tabell visar korrekt status för alla lösta krav
**Plans:** 1 plan

Plans:
- [ ] 04.5-01-PLAN.md — FriendProfileView, tappbar WeatherDetailSheet-header, SUMMARY-frontmatter och REQUIREMENTS-traceability fix

### Phase 5: Utökade Vyer
**Goal**: Appen erbjuder tre komplementära sätt att utforska vänners väder — kartvy, grupperade kort och daglig sammanfattning — som differentierar mot konkurrenter
**Depends on**: Phase 4.5
**Requirements**: VIEW-02, VIEW-03, PUSH-02
**Success Criteria** (what must be TRUE):
  1. Användare kan se vänners platser på en karta med väderinfo per nål (MapKit)
  2. Användare kan bläddra vänner grupperade i väderkategorier (Tropical/Warm/Cool/Cold/Arctic)
  3. Användare får en daglig push-notis med vädersammanfattning för sina favoriter
**Plans:** 2 plans

Plans:
- [ ] 05-01-PLAN.md — FriendsTabView (segmented control Lista/Karta/Kategorier), FriendMapView med MapKit-nålar, FriendMapViewModel med bildcache, FriendListView-refaktorering
- [ ] 05-02-PLAN.md — FriendCategoryView med WeatherCategory-karuseller, DailyWeatherNotificationService med lokal notis kl 07:00

### Phase 6: Polish och App Store
**Goal**: Appen passerar App Store-granskning och når riktiga användare via TestFlight och lansering — med widget, animationer och alla obligatoriska krav uppfyllda
**Depends on**: Phase 5
**Requirements**: AUTH-05, WTHR-02, WDGT-01
**Success Criteria** (what must be TRUE):
  1. iOS hemskärmswidget visar favoriters väder (WidgetKit, minst 2x2 medium)
  2. Animerade väderillustrationer visas bakom vänners profilbilder i listvyn
  3. Användare kan radera sitt konto via inställningar (App Store-krav sedan 2023)
  4. Appen passerar `Product → Archive → Validate` utan ITMS-91061 (privacy manifests)
**Plans:** 2 plans

Plans:
- [x] 06-01-PLAN.md — Animerade väderillustrationer (SwiftUI Canvas/TimelineView) och konto-radering (AuthManager + ProfileView)
- [x] 06-02-PLAN.md — iOS hemskärmswidget (WidgetKit), App Group-datadelning, deep links och privacy manifest

### Phase 7: Tech Debt Cleanup (Gap Closure)
**Goal**: Eliminera ackumulerad tech debt identifierad av milestone audit — DI-brott, dead code och dokumentationsgap
**Depends on**: Phase 6
**Requirements**: CHAT-01, CHAT-02 (integration quality)
**Gap Closure**: Closes tech_debt gaps from v1.0 audit
**Success Criteria** (what must be TRUE):
  1. ConversationListView använder `@Environment` FriendService istf throwaway-instans
  2. ConversationListViewModel tar emot UserService via parameter-injection
  3. Debug-print borttagen ur FriendListViewModel.swift
  4. Dead code `from(friendWeather:)` borttagen ur WidgetFriendEntry+AppExtension.swift
  5. 05-02-SUMMARY.md inkluderar VIEW-02 och PUSH-02 i frontmatter
**Plans:** 1 plan

Plans:
- [ ] 07-01-PLAN.md — DI-fix (ConversationListView/ViewModel), dead code removal (WidgetFriendEntry+AppExtension) och verifiering av redan fixade items

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete    | 2026-03-02 |
| 2. Kärnupplevelse | 4/4 | Complete   | 2026-03-02 |
| 3. Kontaktimport | 2/2 | Complete   | 2026-03-03 |
| 4. Chatt och Push | 4/4 | Complete   | 2026-03-03 |
| 4.1 Fixa onboarding-kontaktimport | 1/1 | Complete   | 2026-03-03 |
| 4.2 Fixa chatt-UID-mismatch | 1/1 | Complete   | 2026-03-03 |
| 4.3 Fixa push deep link + tech debt | 1/1 | Complete   | 2026-03-03 |
| 4.4 Fixa authUid-population | 1/1 | Complete | 2026-03-03 |
| 4.5 Vänprofil-nav + docs | 1/1 | Complete | 2026-03-03 |
| 5. Utökade Vyer | 2/2 | Complete | 2026-03-04 |
| 6. Polish och App Store | 2/2 | Complete | 2026-03-04 |
| 7. Tech Debt Cleanup | 0/1 | Not started | - |
