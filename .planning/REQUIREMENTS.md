# Requirements: FriendsCast

**Defined:** 2026-03-06
**Core Value:** Oeppna appen och omedelbart se hur vaedret aer hos dina vaenner -- sorterat, visuellt och levande -- saa att vaedret blir en naturlig anledning att hoera av sig.

## v3.0 Requirements

Requirements for v3.0 Virality & Polish. Each maps to roadmap phases.

### Invite & Deep Linking

- [x] **INVT-01**: Invite-laenkar anvaender Universal Links (HTTPS) istaellet foer custom URL scheme
- [x] **INVT-02**: Web fallback-sida visas foer anvaendare utan appen installerad, med App Store-redirect
- [x] **INVT-03**: Invite-koder aer persistenta och kan anvaendas flera gaanger
- [x] **INVT-04**: Deferred deep link — invite-token sparas och loeses in efter signup foer ej inloggade anvaendare
- [ ] **INVT-05**: Invite-celebration med Bubble Pop-animation naer en vaen accepterar invite

### Shareable Weather Cards

- [x] **CARD-01**: User kan generera ett statiskt vaederkort (bild) foer en vaen med vaeder, stad och avatar
- [ ] **CARD-02**: User kan dela vaederkort via systemets share sheet
- [ ] **CARD-03**: User kan generera "Me vs You" jaemfoerelsekort med tvaa vaenner sida vid sida
- [ ] **CARD-04**: User kan dela vaederkort direkt till Instagram Stories
- [ ] **CARD-05**: User kan generera daglig digest som delbart kort med alla vaenners vaeder

### Engagement Loops

- [ ] **ENGM-01**: User ser kontextuella vaeder-nudges i appen ("Det snoear hos Emma!")
- [ ] **ENGM-02**: Inaktiva anvaendare (3+ dagar) faar re-engagement push-notis
- [ ] **ENGM-03**: Notification budget begraensar push till max-graens per vecka (ej chatt)

### Visual Polish

- [ ] **PLSH-01**: BubblePopTypography adopterad i alla feature-vyer
- [ ] **PLSH-02**: BubblePopSpacing och CornerRadius adopterad i alla feature-vyer
- [ ] **PLSH-03**: sensoryFeedback (haptics) paa sociala interaktioner (like, invite, share, chat-send)

## Future Requirements

Deferred to v4+. Tracked but not in current roadmap.

### Sharing Extensions

- **CARD-06**: Animerade vaederkort (video/GIF)
- **CARD-07**: Daglig digest som push-notis med delbart kort

### Engagement

- **ENGM-04**: "Weather twins" notification — du och en vaen har samma vaeder
- **ENGM-05**: TipKit kontextuella tips foer feature discovery
- **ENGM-06**: Invite social proof ("3 kontakter anvaender redan appen")

### Retention

- **RETN-01**: Friend weather check-in streak

## Out of Scope

| Feature | Reason |
|---------|--------|
| Gamification (poaeng, leaderboards) | Strider mot varm/social kaensla — explicit constraint i PROJECT.md |
| Animated cards (video/GIF) | Hoeg komplexitet — bevisa statiska kort foerst |
| Contact cross-reference ("X redan haer") | Kraever backend contact matching — v4+ |
| Moerkt tema | Strider mot design constraint |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INVT-01 | Phase 16 | Complete |
| INVT-02 | Phase 16 | Complete |
| INVT-03 | Phase 16 | Complete |
| INVT-04 | Phase 16 | Complete |
| INVT-05 | Phase 18 | Pending |
| CARD-01 | Phase 17 | Complete |
| CARD-02 | Phase 17 | Pending |
| CARD-03 | Phase 18 | Pending |
| CARD-04 | Phase 17 | Pending |
| CARD-05 | Phase 18 | Pending |
| ENGM-01 | Phase 19 | Pending |
| ENGM-02 | Phase 19 | Pending |
| ENGM-03 | Phase 19 | Pending |
| PLSH-01 | Phase 20 | Pending |
| PLSH-02 | Phase 20 | Pending |
| PLSH-03 | Phase 20 | Pending |

**Coverage:**
- v3.0 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-06 after roadmap creation*
