# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Hot & Cold Friends MVP

**Shipped:** 2026-03-04
**Phases:** 13 | **Plans:** 24 | **Timeline:** 3 dagar

### What Was Built
- Komplett iOS-app med social login, vänlista med realtidsväder, kontaktimport med AI-platsgissning
- Tre vyer (sorterad lista, MapKit-karta, väderkategorier) + hemskärmswidget
- Realtidschatt (1-till-1 + grupp) med push-notiser och App Store-obligatorisk moderering
- Animerade väderillustrationer, daglig vädersammanfattning, kontoborttagning

### What Worked
- **Snabb iteration:** 13 faser och 24 planer på 3 dagar — GSD-workflow höll takten
- **Gap-closure-mönstret:** 5 decimalfaser (4.1–4.5) identifierade och stängde integrationsgap direkt efter varje huvudfas
- **Milestone audit:** Fångade tech debt och integrationsproblem systematiskt — ledde till Phase 7 och 8
- **Service-injection via parameter:** Konsekvent mönster genom hela appen (ej @Environment i ViewModels)
- **xcodegen:** CLI-baserat projektunderhåll fungerade smidigt utan Xcode GUI

### What Was Inefficient
- **Auth UID vs Friend.id-förvirring:** Krävde tre gap-closure-faser (4.2, 4.3, 4.4) som kunde undvikits med bättre datamodell-design i Phase 1
- **Dokumentationsfix i separata faser:** SUMMARY-frontmatter och traceability-fixar tog egna planer (4.5, 7, 8) — borde automatiseras
- **lookupAuthUid via displayName:** Medvetet pragmatiskt val men tech debt som måste lösas i v2

### Patterns Established
- **@Observable @MainActor** på alla services och ViewModels — konsekvent genom hela appen
- **Service-injection via parameter** (ej @Environment i ViewModels) — testbart och explicit
- **Cloud Function proxy** för tredje-parts-API:er (OpenAI) — skyddar nycklar
- **Deterministiskt konversations-ID** (sorterade UIDs joined med _)
- **ImportReviewMode enum** (.standard/.onboarding) för delad vy med olika flöden
- **Dubbel onChange** för deep link timing vid cold start

### Key Lessons
1. **Datamodellen sätter takten:** Auth UID borde funnits på Friend-modellen från dag 1 — sparar 3+ gap-closure-faser
2. **WeatherKit SDK-namn avviker:** Metoder heter .hourly/.daily (inte .hourlyForecast), AppWeatherService behövs för att undvika namnkollision
3. **Firebase v2 API:** defineSecret() istf deprecated functions.config(), FirebaseFirestoreSwift integrerat i huvudpaketet
4. **iOS 17+ möjliggör:** @Observable, CLLocationUpdate.liveUpdates(), stackade sheets
5. **Audit-driven cleanup fungerar:** Systematisk granskning → konkreta fixfaser → hög kvalitet vid milstolpe

### Cost Observations
- Model mix: Balanced profil (GSD-default)
- Sessions: ~10 sessioner över 3 dagar
- Notable: Yolo-mode sparade tid på bekräftelser utan att offra kvalitet

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Timeline | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 3 dagar | 13 (8 planned + 5 gap-closure) | Audit-driven gap closure |

### Top Lessons (Verified Across Milestones)

1. Datamodell-beslut i Phase 1 propagerar genom hela projektet — investera tid tidigt
2. Gap-closure-faser är effektiva men bör minimeras genom bättre upfront-design
3. Milestone audit fångar problem som per-fas-verifiering missar
