# Roadmap: Hot & Cold Friends

## Milestones

- ✅ **v1.0 MVP** — Phases 1-8 (shipped 2026-03-04) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Bubble Pop Design + Tech Debt** — Phases 9-13 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-8) — SHIPPED 2026-03-04</summary>

- [x] Phase 1: Foundation (3/3 plans) — completed 2026-03-02
- [x] Phase 2: Kärnupplevelse (4/4 plans) — completed 2026-03-02
- [x] Phase 3: Kontaktimport (2/2 plans) — completed 2026-03-03
- [x] Phase 4: Chatt och Push (4/4 plans) — completed 2026-03-03
- [x] Phase 4.1: Fixa onboarding-kontaktimport (1/1 plan) — completed 2026-03-03
- [x] Phase 4.2: Fixa chatt-UID-mismatch (1/1 plan) — completed 2026-03-03
- [x] Phase 4.3: Fixa push deep link + tech debt (1/1 plan) — completed 2026-03-03
- [x] Phase 4.4: Fixa authUid-population (1/1 plan) — completed 2026-03-03
- [x] Phase 4.5: Vänprofil-nav + docs (1/1 plan) — completed 2026-03-03
- [x] Phase 5: Utökade Vyer (2/2 plans) — completed 2026-03-04
- [x] Phase 6: Polish och App Store (2/2 plans) — completed 2026-03-04
- [x] Phase 7: Tech Debt Cleanup (1/1 plan) — completed 2026-03-04
- [x] Phase 8: Integration Fixes (1/1 plan) — completed 2026-03-04

</details>

### 🚧 v2.0 Bubble Pop Design + Tech Debt (In Progress)

**Milestone Goal:** Implementera det kompletta Bubble Pop design systemet och åtgärda v1.0 tech debt — appen ska kännas levande, varm och distinkt med konsekvent visuell identitet i alla vyer.

- [x] **Phase 9: Design Foundation** — Bubble Pop tokens (färger, typsnitt, grid, shadows) och alla visuella assets på plats (completed 2026-03-04)
- [x] **Phase 10: Komponenter** — Alla UI-komponenter byggda med Bubble Pop-systemet (kort, knappar, bubblor, tabs, avatarer, widgets) (completed 2026-03-05)
- [x] **Phase 11: Animationer** — Alla rörelser implementerade med spring-animationer och Reduce Motion-stöd (completed 2026-03-06)
- [x] **Phase 12: Tech Debt** — lookupAuthUid ersatt med unik identifierare, WeatherAlertService i environment, orphaned messages städade (completed 2026-03-06)

## Phase Details

### Phase 9: Design Foundation
**Goal**: Appen har ett komplett visuellt fundament — Bubble Pop färgpalett, typsnitt, spacing-grid, shadows och alla grafiska assets är registrerade och tillgängliga för alla vyer
**Depends on**: Phase 8
**Requirements**: DSGN-01, DSGN-02, DSGN-03, DSGN-04, DSGN-05, ASSET-01, ASSET-02, ASSET-03, ASSET-04
**Success Criteria** (what must be TRUE):
  1. Appen använder Bubble Pop-färgpalett med 5 temperaturzoner synliga i listvy — inte standard SwiftUI-blått
  2. Rubriker, knappar och temperaturer renderas i Baloo 2, brödtext i Inter/SF Pro
  3. Väderikoner i alla vyer är de 14 custom SVG-ikonerna, inte SF Symbols-standardikoner
  4. Ny app-ikon visas på hemskärmen och horisontell logotyp visas på login/onboarding-vy
  5. Empty state-illustrationer visas när vänlistan och chattlistan är tomma
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Bubble Pop color tokens, Baloo 2 font-integration, 8pt spacing grid och shadow-skala
- [x] 09-02-PLAN.md — SVG vaderikoner, app-ikon, logotyp och empty state-illustrationer

### Phase 10: Komponenter
**Goal**: Varje UI-komponent i appen speglar Bubble Pop-designsystemet — vänkort, knappar, chattbubblor, stickers, tab-switcher, avatarer och widgets är alla byggda med tokens från fas 9
**Depends on**: Phase 9
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04, COMP-05, COMP-06, COMP-07
**Success Criteria** (what must be TRUE):
  1. Vänkort visar gradient-avatar baserad på vännens temperaturzon (Tropical/Warm/Cool/Cold/Arctic)
  2. Knappar har pill-form med gradient-bakgrund och ger visuell respons vid tryck
  3. Egna chattbubblor har gradient, andras är vita med border — med asymmetrisk border radius
  4. Väder-stickers kan skickas i chatt och visas som kort med temperaturzon-gradient
  5. Widgets på hemskärmen (small/medium/large) har temperaturzon-gradient bakgrund
**Plans**: 3 plans

Plans:
- [x] 10-01-PLAN.md — FriendRowView med gradient-avatar, WeatherBadge och AvatarView
- [x] 10-02-PLAN.md — BubblePopButton, ChatBubbleView, WeatherStickerCard
- [x] 10-03-PLAN.md — TabSwitcherView med pill + glow-shadow, widget-bakgrunder

### Phase 11: Animationer
**Goal**: Appen känns levande med spring-animationer som förstärker interaktioner — och alla animationer faller tillbaka till crossfade för användare med Reduce Motion aktiverat
**Depends on**: Phase 10
**Requirements**: ANIM-01, ANIM-02, ANIM-03, ANIM-04, ANIM-05, ANIM-06, ANIM-07
**Success Criteria** (what must be TRUE):
  1. Trycka på favorit-hjärtat ger en tydlig pop-animation (shrink → overshoot → settle)
  2. Lägga till en ny vän triggar konfetti i temperaturzon-färger
  3. Skicka en sticker animeras med bounce-in (fade + slide upp → overshoot → settle)
  4. Byta tab animeras med scale + glow, sortera vänlistan animeras med staggerad slide
  5. Med "Reduce Motion" aktiverat i iOS visas crossfade istället för slide/bounce i alla animationer
**Plans**: 2 plans

Plans:
- [x] 11-01-PLAN.md — MotionReducer, HeartPopModifier (favorit-animation) och StickerBounceModifier (chatt-sticker bounce-in)
- [x] 11-02-PLAN.md — ConfettiOverlay (ny van), tab-glow, staggerad listanimation och CloudRefresh (pull-to-refresh moln)

### Phase 12: Tech Debt
**Goal**: Tre identifierade v1.0 tech debt-items är åtgärdade — lookupAuthUid är robust, WeatherAlertService är tillgänglig i hela SwiftUI-trädet och orphaned messages rensas när ett konto raderas
**Depends on**: Phase 11
**Requirements**: DEBT-01, DEBT-02, DEBT-03
**Success Criteria** (what must be TRUE):
  1. Att lägga till eller chatta med en vän som har samma displayName som en annan användare fungerar korrekt — fel konto matchas inte
  2. Pull-to-refresh i vänlistan triggar WeatherAlertService.checkAlertsForFriends() — inte bara vid cold-start
  3. När ett konto raderas finns inga orphaned messages kvar i Firestore för de konversationer där användaren deltog
**Plans**: 2 plans

Plans:
- [ ] 12-01-PLAN.md — Invite-link-system ersatter displayName-match (InviteService, AddFriendSheet, ProfileView share)
- [ ] 12-02-PLAN.md — WeatherAlertService i environment + robust cleanupUserData med reverse friend cleanup

### Phase 13: BubblePopButton Adoption
**Goal**: BubblePopButton-komponenten adopteras i minst en user-facing vy sa att COMP-02 ar fullt uppfyllt — knappen ar inte bara byggd utan faktiskt anvands i appen
**Depends on**: Phase 10
**Requirements**: COMP-02
**Gap Closure**: Closes gaps from audit (COMP-02 partial, BubblePopButton integration)
**Success Criteria** (what must be TRUE):
  1. BubblePopButton anvands i minst en user-facing vy (inte bara #Preview)
  2. Knappens gradient, pill-form och bounce-effekt syns for anvandaren vid interaktion
**Plans**: 1 plan

Plans:
- [ ] 13-01-PLAN.md — Utoka BubblePopButton med loading/disabled/reduceMotion och adopta i AddFriendSheet + ProfileView

## Progress

**Execution Order:**
Phases execute in numeric order: 9 → 10 → 11 → 12 → 13

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-03-02 |
| 2. Kärnupplevelse | v1.0 | 4/4 | Complete | 2026-03-02 |
| 3. Kontaktimport | v1.0 | 2/2 | Complete | 2026-03-03 |
| 4. Chatt och Push | v1.0 | 4/4 | Complete | 2026-03-03 |
| 4.1 Onboarding-fix | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.2 Chatt-UID-fix | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.3 Push deep link | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.4 authUid-population | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.5 Vänprofil + docs | v1.0 | 1/1 | Complete | 2026-03-03 |
| 5. Utökade Vyer | v1.0 | 2/2 | Complete | 2026-03-04 |
| 6. Polish + App Store | v1.0 | 2/2 | Complete | 2026-03-04 |
| 7. Tech Debt | v1.0 | 1/1 | Complete | 2026-03-04 |
| 8. Integration Fixes | v1.0 | 1/1 | Complete | 2026-03-04 |
| 9. Design Foundation | v2.0 | 2/2 | Complete | 2026-03-04 |
| 10. Komponenter | v2.0 | 3/3 | Complete | 2026-03-05 |
| 11. Animationer | v2.0 | 2/2 | Complete | 2026-03-06 |
| 12. Tech Debt | 2/2 | Complete    | 2026-03-06 | - |
| 13. BubblePopButton Adoption | 1/1 | Complete    | 2026-03-06 | - |
