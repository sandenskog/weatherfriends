# Requirements: Hot & Cold Friends

**Defined:** 2026-03-02
**Core Value:** Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication

- [x] **AUTH-01**: Användare kan logga in med Sign in with Apple
- [x] **AUTH-02**: Användare kan logga in med Google Sign-In
- [x] **AUTH-03**: Användare kan logga in med Facebook Login
- [x] **AUTH-04**: Användarsession bevaras mellan app-starter
- [ ] **AUTH-05**: Användare kan radera sitt konto (App Store-krav)

### Profil

- [x] **PROF-01**: Användare kan skapa profil med namn och profilbild
- [x] **PROF-02**: Användare kan ange sin stad/land
- [x] **PROF-03**: Användare kan visa andra användares profiler

### Vänner & Import

- [ ] **FRND-01**: Användare kan manuellt lägga till vän med stad/land
- [ ] **FRND-02**: Användare kan importera vänner från iOS-kontakter
- [ ] **FRND-03**: AI gissar stad/land vid import baserat på adress, telefonnummer, e-post
- [ ] **FRND-04**: Användare uppmanas ange stad/land för favoriter vid onboarding
- [ ] **FRND-05**: Användare kan välja 6 favoriter som visas överst

### Väder

- [ ] **WTHR-01**: Realtidsväder visas per vän (temperatur, ikon, vind, fuktighet, prognos)
- [ ] **WTHR-02**: Animerade väderillustrationer bakom vännens profilbild
- [ ] **WTHR-03**: Väderdata uppdateras automatiskt med caching

### Vyer

- [ ] **VIEW-01**: Vädersorterad listvy (varmast/kallast)
- [ ] **VIEW-02**: Grupperade väderkort (Hot/Warm/Cool/Cold-kategorier)
- [ ] **VIEW-03**: Kartvy med vänners platser och väderinfo (MapKit)
- [ ] **VIEW-04**: Live exempeldata vid first run innan användaren konfigurerat

### Chatt

- [ ] **CHAT-01**: Användare kan skicka 1-till-1 meddelanden till vänner
- [ ] **CHAT-02**: Användare kan skapa och delta i gruppchattar
- [ ] **CHAT-03**: Användare kan skicka väderreaktioner (emoji kopplad till väder)
- [ ] **CHAT-04**: Användare kan rapportera olämpligt innehåll (App Store-krav)
- [ ] **CHAT-05**: Användare kan blockera andra användare (App Store-krav)

### Notiser

- [ ] **PUSH-01**: Push-notis vid extremväder hos vän
- [ ] **PUSH-02**: Daglig vädersammanfattning
- [ ] **PUSH-03**: Push-notis vid nytt chattmeddelande

### Widget

- [ ] **WDGT-01**: iOS hemskärmswidget visar favoriters väder

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Social Import

- **SIMP-01**: Utred och eventuellt implementera vänimport från Facebook Graph API
- **SIMP-02**: Utred och eventuellt implementera vänimport från Instagram API
- **SIMP-03**: Utred och eventuellt implementera vänimport från Snapchat Kit

### Utökade Features

- **EXTD-01**: Vädervarning-notis per specifik vän (personaliserade trösklar)
- **EXTD-02**: Apple Watch-komplikation med favoriters väder
- **EXTD-03**: Flerspråksstöd (svenska, engelska m.fl.)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Realtids-GPS-spårning av vänner | Privacy-risk, App Store-strikt, appen handlar om väder på känd stad — inte exakt position |
| Video/röstsamtal | Kräver WebRTC-infrastruktur, adderar inget till kärnvärdet |
| Social feed/flöde | Tappar appens fokus — vyn är kontaktbaserad, inte flödesbaserad |
| Crowdsourcad väderrapportering | Kräver kritisk massa som aldrig nås (Weddar-problemet) |
| Gamification (poäng, streaks) | Strider mot varm/social känsla — blir gamifierat och trist |
| Android-version | iOS-first, eventuellt senare med Flutter/React Native |
| Mörk designtema | Strider mot varm, social känsla — ljus design |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 1 | Complete |
| AUTH-03 | Phase 1 | Complete |
| AUTH-04 | Phase 1 | Complete (01-01) |
| AUTH-05 | Phase 6 | Pending |
| PROF-01 | Phase 1 | Complete |
| PROF-02 | Phase 1 | Complete |
| PROF-03 | Phase 1 | Complete |
| FRND-01 | Phase 3 | Pending |
| FRND-02 | Phase 3 | Pending |
| FRND-03 | Phase 3 | Pending |
| FRND-04 | Phase 2 | Pending |
| FRND-05 | Phase 2 | Pending |
| WTHR-01 | Phase 2 | Pending |
| WTHR-02 | Phase 6 | Pending |
| WTHR-03 | Phase 2 | Pending |
| VIEW-01 | Phase 2 | Pending |
| VIEW-02 | Phase 5 | Pending |
| VIEW-03 | Phase 5 | Pending |
| VIEW-04 | Phase 2 | Pending |
| CHAT-01 | Phase 4 | Pending |
| CHAT-02 | Phase 4 | Pending |
| CHAT-03 | Phase 4 | Pending |
| CHAT-04 | Phase 4 | Pending |
| CHAT-05 | Phase 4 | Pending |
| PUSH-01 | Phase 4 | Pending |
| PUSH-02 | Phase 5 | Pending |
| PUSH-03 | Phase 4 | Pending |
| WDGT-01 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

---
*Requirements defined: 2026-03-02*
*Last updated: 2026-03-02 after roadmap creation*
