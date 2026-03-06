# Requirements: FriendsCast

**Defined:** 2026-03-06
**Core Value:** Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## v3.0 Requirements

Requirements for v3.0 Virality & Polish. Each maps to roadmap phases.

### Invite & Deep Linking

- [ ] **INVT-01**: Invite-länkar använder Universal Links (HTTPS) istället för custom URL scheme
- [ ] **INVT-02**: Web fallback-sida visas för användare utan appen installerad, med App Store-redirect
- [ ] **INVT-03**: Invite-koder är persistenta och kan användas flera gånger
- [ ] **INVT-04**: Deferred deep link — invite-token sparas och löses in efter signup för ej inloggade användare
- [ ] **INVT-05**: Invite-celebration med Bubble Pop-animation när en vän accepterar invite

### Shareable Weather Cards

- [ ] **CARD-01**: User kan generera ett statiskt väderkort (bild) för en vän med väder, stad och avatar
- [ ] **CARD-02**: User kan dela väderkort via systemets share sheet
- [ ] **CARD-03**: User kan generera "Me vs You" jämförelsekort med två vänner sida vid sida
- [ ] **CARD-04**: User kan dela väderkort direkt till Instagram Stories
- [ ] **CARD-05**: User kan generera daglig digest som delbart kort med alla vänners väder

### Engagement Loops

- [ ] **ENGM-01**: User ser kontextuella väder-nudges i appen ("Det snöar hos Emma!")
- [ ] **ENGM-02**: Inaktiva användare (3+ dagar) får re-engagement push-notis
- [ ] **ENGM-03**: Notification budget begränsar push till max-gräns per vecka (ej chatt)

### Visual Polish

- [ ] **PLSH-01**: BubblePopTypography adopterad i alla feature-vyer
- [ ] **PLSH-02**: BubblePopSpacing och CornerRadius adopterad i alla feature-vyer
- [ ] **PLSH-03**: sensoryFeedback (haptics) på sociala interaktioner (like, invite, share, chat-send)

## Future Requirements

Deferred to v4+. Tracked but not in current roadmap.

### Sharing Extensions

- **CARD-06**: Animerade väderkort (video/GIF)
- **CARD-07**: Daglig digest som push-notis med delbart kort

### Engagement

- **ENGM-04**: "Weather twins" notification — du och en vän har samma väder
- **ENGM-05**: TipKit kontextuella tips för feature discovery
- **ENGM-06**: Invite social proof ("3 kontakter använder redan appen")

### Retention

- **RETN-01**: Friend weather check-in streak

## Out of Scope

| Feature | Reason |
|---------|--------|
| Gamification (poäng, leaderboards) | Strider mot varm/social känsla — explicit constraint i PROJECT.md |
| Animated cards (video/GIF) | Hög komplexitet — bevisa statiska kort först |
| Contact cross-reference ("X redan här") | Kräver backend contact matching — v4+ |
| Mörkt tema | Strider mot design constraint |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INVT-01 | — | Pending |
| INVT-02 | — | Pending |
| INVT-03 | — | Pending |
| INVT-04 | — | Pending |
| INVT-05 | — | Pending |
| CARD-01 | — | Pending |
| CARD-02 | — | Pending |
| CARD-03 | — | Pending |
| CARD-04 | — | Pending |
| CARD-05 | — | Pending |
| ENGM-01 | — | Pending |
| ENGM-02 | — | Pending |
| ENGM-03 | — | Pending |
| PLSH-01 | — | Pending |
| PLSH-02 | — | Pending |
| PLSH-03 | — | Pending |

**Coverage:**
- v3.0 requirements: 16 total
- Mapped to phases: 0
- Unmapped: 16

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-06 after initial definition*
