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
- [ ] **Phase 3: Kontaktimport** - iOS Contacts-import med AI-driven platsgissning
- [ ] **Phase 4: Chatt och Push** - Realtidschatt, push-notiser och UGC-moderering
- [ ] **Phase 5: Utökade Vyer** - Kartvy, grupperade väderkort och daglig sammanfattning
- [ ] **Phase 6: Polish och App Store** - Widget, animationer och App Store-lansering

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
**Plans:** 1/2 plans complete

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
**Plans**: TBD

Plans:
- [ ] 04-01: Firebase Realtime DB-baserad chatt (1-till-1 och grupp) med ChatService
- [ ] 04-02: Väderreaktioner och rapport/blockering-UI
- [ ] 04-03: FCM push-notiser (chat + extremväder) via Cloud Function-trigger och APNs

### Phase 5: Utökade Vyer
**Goal**: Appen erbjuder tre komplementära sätt att utforska vänners väder — kartvy, grupperade kort och daglig sammanfattning — som differentierar mot konkurrenter
**Depends on**: Phase 4
**Requirements**: VIEW-02, VIEW-03, PUSH-02
**Success Criteria** (what must be TRUE):
  1. Användare kan se vänners platser på en karta med väderinfo per nål (MapKit)
  2. Användare kan bläddra vänner grupperade i väderkategorier (Tropical/Warm/Cool/Cold/Arctic)
  3. Användare får en daglig push-notis med vädersammanfattning för sina favoriter
**Plans**: TBD

Plans:
- [ ] 05-01: Kartvy med MapKit (FriendMapView + FriendMapViewModel)
- [ ] 05-02: Grupperade väderkort och daglig schemalagd notis

### Phase 6: Polish och App Store
**Goal**: Appen passerar App Store-granskning och når riktiga användare via TestFlight och lansering — med widget, animationer och alla obligatoriska krav uppfyllda
**Depends on**: Phase 5
**Requirements**: WDGT-01, AUTH-05
**Success Criteria** (what must be TRUE):
  1. iOS hemskärmswidget visar favoriters väder (WidgetKit, minst 2x2 medium)
  2. Animerade väderillustrationer visas bakom vänners profilbilder i listvyn
  3. Användare kan radera sitt konto via inställningar (App Store-krav sedan 2023)
  4. Appen passerar `Product → Archive → Validate` utan ITMS-91061 (privacy manifests)
**Plans**: TBD

Plans:
- [ ] 06-01: iOS hemskärmswidget (WidgetKit) och animerade väderillustrationer (Lottie/SwiftUI)
- [ ] 06-02: Konto-borttagningsflöde, privacy manifest-audit och TestFlight-submission

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete    | 2026-03-02 |
| 2. Kärnupplevelse | 4/4 | Complete   | 2026-03-02 |
| 3. Kontaktimport | 1/2 | In Progress | - |
| 4. Chatt och Push | 0/3 | Not started | - |
| 5. Utökade Vyer | 0/2 | Not started | - |
| 6. Polish och App Store | 0/2 | Not started | - |
