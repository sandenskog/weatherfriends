# Roadmap: Hot & Cold Friends

## Milestones

- ✅ **v1.0 MVP** — Phases 1-8 (shipped 2026-03-04) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Bubble Pop Design + Tech Debt** — Phases 9-15 (shipped 2026-03-06) — [archive](milestones/v2.0-ROADMAP.md)
- 🚧 **v3.0 Virality & Polish** — Phases 16-20 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-8) — SHIPPED 2026-03-04</summary>

- [x] Phase 1: Foundation (3/3 plans) — completed 2026-03-02
- [x] Phase 2: Karnupplevelse (4/4 plans) — completed 2026-03-02
- [x] Phase 3: Kontaktimport (2/2 plans) — completed 2026-03-03
- [x] Phase 4: Chatt och Push (4/4 plans) — completed 2026-03-03
- [x] Phase 4.1: Fixa onboarding-kontaktimport (1/1 plan) — completed 2026-03-03
- [x] Phase 4.2: Fixa chatt-UID-mismatch (1/1 plan) — completed 2026-03-03
- [x] Phase 4.3: Fixa push deep link + tech debt (1/1 plan) — completed 2026-03-03
- [x] Phase 4.4: Fixa authUid-population (1/1 plan) — completed 2026-03-03
- [x] Phase 4.5: Vanprofil-nav + docs (1/1 plan) — completed 2026-03-03
- [x] Phase 5: Utokade Vyer (2/2 plans) — completed 2026-03-04
- [x] Phase 6: Polish och App Store (2/2 plans) — completed 2026-03-04
- [x] Phase 7: Tech Debt Cleanup (1/1 plan) — completed 2026-03-04
- [x] Phase 8: Integration Fixes (1/1 plan) — completed 2026-03-04

</details>

<details>
<summary>✅ v2.0 Bubble Pop Design + Tech Debt (Phases 9-15) — SHIPPED 2026-03-06</summary>

- [x] Phase 9: Design Foundation (2/2 plans) — completed 2026-03-04
- [x] Phase 10: Komponenter (3/3 plans) — completed 2026-03-05
- [x] Phase 11: Animationer (2/2 plans) — completed 2026-03-06
- [x] Phase 12: Tech Debt (2/2 plans) — completed 2026-03-06
- [x] Phase 13: BubblePopButton Adoption (1/1 plan) — completed 2026-03-06
- [x] Phase 14: Phase 10 Verify + Avatar Fix (2/2 plans) — completed 2026-03-06
- [x] Phase 15: Design System Cleanup (1/1 plan) — completed 2026-03-06

</details>

### 🚧 v3.0 Virality & Polish (In Progress)

**Milestone Goal:** Goer appen visuellt komplett, bygg invite-upplevelse som driver viralitet, och skapa delnings- och engagemangs-loopar.

- [x] **Phase 16: Invite Foundation** - Universal Links, web fallback, persistent codes och deferred deep link (completed 2026-03-07)
- [ ] **Phase 17: Shareable Weather Cards** - Generera och dela vaederkort via share sheet och Instagram Stories
- [ ] **Phase 18: Comparison Cards & Invite Polish** - Me vs You-kort, daglig digest och invite-celebration
- [ ] **Phase 19: Engagement Loops** - Vaeder-nudges, re-engagement push och notification budget
- [ ] **Phase 20: Visual Polish** - Full BubblePop-adoption i alla vyer och haptics

## Phase Details

### Phase 16: Invite Foundation
**Goal**: Invite-laenkar fungerar oeverallt daer laenkar kan delas och leder nya anvaendare hela vaegen till appen och vaenskapen
**Depends on**: Nothing (first phase in v3.0)
**Requirements**: INVT-01, INVT-02, INVT-03, INVT-04
**Success Criteria** (what must be TRUE):
  1. User kan skicka en invite-laenk via iMessage/WhatsApp och mottagaren kan klicka den foer att oeppna appen direkt
  2. User utan appen installerad ser en webbsida med App Store-laenk och app-branding naer de klickar invite-laenken
  3. User som installerar appen via invite-laenk blir automatiskt vaen med inbjudaren efter signup (deferred deep link)
  4. Invite-kod kan anvaendas av flera personer utan att bli ogiltig
**Plans**: 2 plans

Plans:
- [ ] 16-01-PLAN.md — Web: AASA-fil, Express-server och dynamisk invite-fallback-sida
- [ ] 16-02-PLAN.md — iOS: Persistent invite-koder, Universal Links, clipboard deferred deep link

### Phase 17: Shareable Weather Cards
**Goal**: Anvaendare kan skapa snygga vaederbilder och dela dem utanfoer appen foer att driva organisk synlighet
**Depends on**: Phase 16
**Requirements**: CARD-01, CARD-02, CARD-04
**Success Criteria** (what must be TRUE):
  1. User kan generera ett vaederkort med vaeder, stad och avatar foer en vaen
  2. User kan dela vaederkortet via systemets share sheet till valfri app
  3. User kan dela ett vaederkort direkt till Instagram Stories med ett tap
**Plans**: 2 plans

Plans:
- [ ] 17-01-PLAN.md — WeatherCardView, WeatherCardRenderer och vaederbakgrunder (kortgenerering)
- [ ] 17-02-PLAN.md — Preview-sheet, swipe-action, share sheet och Instagram Stories-delning

### Phase 18: Comparison Cards & Invite Polish
**Goal**: Unika delbara kort som differentierar appen, plus en invite-upplevelse som belonar inbjudan
**Depends on**: Phase 17
**Requirements**: CARD-03, CARD-05, INVT-05
**Success Criteria** (what must be TRUE):
  1. User kan generera ett "Me vs You"-jaemfoerelsekort med sig sjaelv och en vaen sida vid sida
  2. User kan generera ett dagligt digest-kort som visar alla vaenners vaeder
  3. User ser en Bubble Pop-celebration med animation naer en inbjuden vaen accepterar invite
**Plans**: TBD

Plans:
- [ ] 18-01: TBD
- [ ] 18-02: TBD

### Phase 19: Engagement Loops
**Goal**: Appen ger anvaendare anledningar att oeppna den och interagera med vaenner genom kontextuella vaeder-triggers
**Depends on**: Phase 16
**Requirements**: ENGM-01, ENGM-02, ENGM-03
**Success Criteria** (what must be TRUE):
  1. User ser kontextuella vaeder-nudges i appen som uppmuntrar att kontakta vaenner baserat paa deras vaeder
  2. User som inte oeppnat appen paa 3+ dagar faar en re-engagement push-notis
  3. Push-notiser (exkl. chatt) begraensas till en max-graens per vecka saa att anvaendare inte spammas
**Plans**: TBD

Plans:
- [ ] 19-01: TBD
- [ ] 19-02: TBD

### Phase 20: Visual Polish
**Goal**: Appen ser visuellt konsekvent ut med Bubble Pop Design System fullt adopterat i alla vyer, med taktil feedback paa sociala interaktioner
**Depends on**: Phase 17, Phase 18, Phase 19
**Requirements**: PLSH-01, PLSH-02, PLSH-03
**Success Criteria** (what must be TRUE):
  1. Alla feature-vyer anvaender BubblePopTypography (Baloo 2) konsekvent utan system-typsnitt
  2. Alla feature-vyer anvaender BubblePopSpacing (8pt grid) och CornerRadius konsekvent
  3. User kaenner haptic feedback vid like, invite, share och chat-send
**Plans**: TBD

Plans:
- [ ] 20-01: TBD
- [ ] 20-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 16 -> 17 -> 18 -> 19 -> 20

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-03-02 |
| 2. Karnupplevelse | v1.0 | 4/4 | Complete | 2026-03-02 |
| 3. Kontaktimport | v1.0 | 2/2 | Complete | 2026-03-03 |
| 4. Chatt och Push | v1.0 | 4/4 | Complete | 2026-03-03 |
| 4.1 Onboarding-fix | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.2 Chatt-UID-fix | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.3 Push deep link | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.4 authUid-population | v1.0 | 1/1 | Complete | 2026-03-03 |
| 4.5 Vanprofil + docs | v1.0 | 1/1 | Complete | 2026-03-03 |
| 5. Utokade Vyer | v1.0 | 2/2 | Complete | 2026-03-04 |
| 6. Polish + App Store | v1.0 | 2/2 | Complete | 2026-03-04 |
| 7. Tech Debt | v1.0 | 1/1 | Complete | 2026-03-04 |
| 8. Integration Fixes | v1.0 | 1/1 | Complete | 2026-03-04 |
| 9. Design Foundation | v2.0 | 2/2 | Complete | 2026-03-04 |
| 10. Komponenter | v2.0 | 3/3 | Complete | 2026-03-05 |
| 11. Animationer | v2.0 | 2/2 | Complete | 2026-03-06 |
| 12. Tech Debt | v2.0 | 2/2 | Complete | 2026-03-06 |
| 13. BubblePopButton Adoption | v2.0 | 1/1 | Complete | 2026-03-06 |
| 14. Phase 10 Verify + Avatar Fix | v2.0 | 2/2 | Complete | 2026-03-06 |
| 15. Design System Cleanup | v2.0 | 1/1 | Complete | 2026-03-06 |
| 16. Invite Foundation | 2/2 | Complete    | 2026-03-07 | - |
| 17. Shareable Weather Cards | v3.0 | 0/2 | Not started | - |
| 18. Comparison Cards & Invite Polish | v3.0 | 0/? | Not started | - |
| 19. Engagement Loops | v3.0 | 0/? | Not started | - |
| 20. Visual Polish | v3.0 | 0/? | Not started | - |
