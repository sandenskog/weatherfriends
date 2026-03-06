# Requirements: FriendsCast

**Defined:** 2026-03-04
**Core Value:** Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## v2.0 Requirements

Requirements for Bubble Pop Design + Tech Debt milestone.

### Design Tokens

- [x] **DSGN-01**: Appen använder Bubble Pop färgpalett (temperaturzoner, brand, UI, semantiska färger) konsekvent i alla vyer
- [x] **DSGN-02**: Baloo 2 custom font används för rubriker, knappar och temperaturvärden
- [x] **DSGN-03**: Inter/SF Pro används för brödtext och captions
- [x] **DSGN-04**: 8pt spacing grid och border radius-skala (sm/md/lg/xl/round) tillämpas
- [x] **DSGN-05**: Shadow-skala (sm/md/lg/glow) implementerad

### Komponenter

- [x] **COMP-01**: Vänkort har gradient-avatar baserad på temperaturzon, weather badge och slide-hover-effekt
- [x] **COMP-02**: Knappar har pill-form (Capsule), gradient-bakgrund och bounce-effekt vid tryck
- [x] **COMP-03**: Chattbubblor har gradient (egna) respektive vit med border (andras) med asymmetrisk border radius
- [x] **COMP-04**: Väder-stickers kan skickas i chatt som interaktiva kort med temperaturzon-gradient
- [x] **COMP-05**: Tab-switcher har pill-form med glow-shadow och scale-animation på aktiv tab
- [x] **COMP-06**: Avatarer visar initialer med temperaturzon-gradient och 52x52pt storlek
- [x] **COMP-07**: Widgets (small/medium/large) har temperaturzon-gradient bakgrund enligt spec

### Animationer

- [x] **ANIM-01**: Favorit-markering har heart-pop animation (shrink → overshoot → settle, 0.6s spring)
- [x] **ANIM-02**: Ny vän tillagd triggar konfetti-animation med temperaturzon-färger
- [x] **ANIM-03**: Sticker skickad visas med bounce-in animation (fade + slide up → overshoot → settle)
- [x] **ANIM-04**: Tab-byte animeras med scale + glow (0.35s spring)
- [x] **ANIM-05**: Temperatursortering animeras med staggered slide (50ms delay per item)
- [x] **ANIM-06**: Pull-to-refresh har moln-animation (bounce → spin → sol-pop)
- [x] **ANIM-07**: Animationer respekterar "Reduce Motion" (crossfade istället för slide/bounce)

### Assets

- [x] **ASSET-01**: 14 SVG väderikoner konverterade till iOS assets och används i alla vyer
- [x] **ASSET-02**: Ny app-ikon från SVG implementerad i Assets.xcassets
- [x] **ASSET-03**: Horisontell logotyp används på lämplig plats (t.ex. login, onboarding)
- [x] **ASSET-04**: Empty state-illustrationer (no friends, no chat) visas i tomma listor

### Tech Debt

- [x] **DEBT-01**: lookupAuthUid ersätts med invite-länk eller annan unik identifierare (ej displayName-match)
- [x] **DEBT-02**: WeatherAlertService injiceras i SwiftUI environment så vyer kan trigga alert-check
- [x] **DEBT-03**: Orphaned messages i konversationer rensas vid kontoborttagning

## Future Requirements

### v2.1+

- **SOCIAL-01**: Statusuppdateringar ("Snöstorm här!")
- **SOCIAL-02**: Reactions på vänners väder
- **ONBOARD-01**: Förbättrad onboarding med tutorial
- **SETTINGS-01**: Notis-inställningar per kategori

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dark mode | Strider mot varm, social Bubble Pop-känsla |
| Android | iOS-first, eventuellt Flutter/React Native i framtiden |
| Nya funktioner (social feed, video) | v2.0 fokuserar på design + tech debt |
| Ny backend-arkitektur | Firebase fungerar bra, ingen anledning att byta |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DSGN-01 | Phase 9 | Complete |
| DSGN-02 | Phase 9 | Complete |
| DSGN-03 | Phase 9 | Complete |
| DSGN-04 | Phase 9 | Complete |
| DSGN-05 | Phase 9 | Complete |
| ASSET-01 | Phase 9 | Complete |
| ASSET-02 | Phase 9 | Complete |
| ASSET-03 | Phase 9 | Complete |
| ASSET-04 | Phase 9 | Complete |
| COMP-01 | Phase 10 | Complete |
| COMP-02 | Phase 10 | Complete |
| COMP-03 | Phase 10 | Complete |
| COMP-04 | Phase 10 | Complete |
| COMP-05 | Phase 10 | Complete |
| COMP-06 | Phase 10 | Complete |
| COMP-07 | Phase 10 | Complete |
| ANIM-01 | Phase 11 | Complete |
| ANIM-02 | Phase 11 | Complete |
| ANIM-03 | Phase 11 | Complete |
| ANIM-04 | Phase 11 | Complete |
| ANIM-05 | Phase 11 | Complete |
| ANIM-06 | Phase 11 | Complete |
| ANIM-07 | Phase 11 | Complete |
| DEBT-01 | Phase 12 | Complete |
| DEBT-02 | Phase 12 | Complete |
| DEBT-03 | Phase 12 | Complete |

**Coverage:**
- v2.0 requirements: 26 total (22 current + DEBT mapped explicitly)
- Mapped to phases: 26
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-04*
*Last updated: 2026-03-04 — traceability mapped after v2.0 roadmap creation*
