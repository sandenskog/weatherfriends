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

## Milestone: v2.0 — Bubble Pop Design + Tech Debt

**Shipped:** 2026-03-06
**Phases:** 7 | **Plans:** 13 | **Timeline:** 5 dagar

### What Was Built
- Komplett Bubble Pop design system med fargpalett, Baloo 2 typografi, 8pt spacing grid och 5 temperaturzoner
- 14 custom SVG vaderikoner, ny app-ikon, logotyp och empty state-illustrationer
- UI-komponenter: AvatarView, BubblePopButton, chattbubblor med gradient, tab-switcher med glow, vader-stickers
- Spring-animationer med Reduce Motion-stod: hjart-pop, konfetti, sticker-bounce, tab-glow, cloud refresh
- Invite-lank-system som ersatter displayName-match, robust kontoborttagning, WeatherAlertService i environment

### What Worked
- **Design pack som input:** HTML-spec med Swift-referenskod gjorde implementation smidig och minska tolkningsutrymme
- **Milestone audit mitt i arbetet:** Fangade 6 verifieringsgap, BubblePopButton-adoption, AvatarView-konsistens — ledde till 3 gap-closure-faser (13, 14, 15)
- **TemperatureZone som central abstraktion:** En enum driver gradient, farger och avatarer konsekvent genom hela appen
- **MotionReducer pattern:** Centralt Reduce Motion-stod via ViewModifier — enkelt att applicera pa alla animationer
- **Yolo-mode:** Snabb exekvering utan onodiga bekraftelsesteg

### What Was Inefficient
- **Design-token adoption ojamn:** BubblePopTypography/Spacing bara adopterade i 3/2 av ~11 vyer — fasernas scope var for snava for full adoption
- **Tre gap-closure-faser:** Phase 13, 14 och 15 var reaktiva fixar — Phase 10:s scope borde inkluderat BubblePopButton-adoption och Phase 10 VERIFICATION.md
- **WeatherAnimationView dead code:** Skapades i Phase 10 men blev overfloding nar AvatarView tog over — upptacktes forst i audit

### Patterns Established
- **AvatarView som enda avatar-komponent:** Alla vyer anvander AvatarView, inga manuella initialsCircle()
- **MotionReducer + spring-animationer:** ViewModifier-baserad animation med automatisk Reduce Motion fallback
- **InviteService med UUID-prefix tokens:** 12-char tokens i Firestore 'invites' collection, deep link via onOpenURL
- **@Observable + @Environment for services:** WeatherAlertService injiceras i SwiftUI-tradet (iOS 17+ pattern)
- **Design system tokens i enum:** BubblePopColors, BubblePopTypography, BubblePopSpacing, BubblePopShadows som SwiftUI-extensions

### Key Lessons
1. **Verifiering bor ske i samma fas som implementation:** Att skapa VERIFICATION.md i efterhand (Phase 14) ar slodigt — bygg in i exekveringssteget
2. **Design-token adoption kraver explicit scope:** "Bygg token" och "adopta i alla vyer" ar tva separata uppgifter — planera bada
3. **Audit tidigt, audit ofta:** v2.0-auditen ledde till 3 extra faser — hade den gjorts efter Phase 10 hade gap-closure blivit mindre
4. **Dead code upptacks sent:** WeatherAnimationView och MotionReducer-metoder blev overflodiga utan att nagon noterade det — audit fangade det
5. **MapAnnotation-begransningar:** SwiftUI MapAnnotation stodjer inte AvatarView fullt — FriendMapView behover workaround

### Cost Observations
- Model mix: Balanced profil (GSD-default)
- Sessions: ~8 sessioner over 5 dagar
- Notable: Design-implementation med HTML-spec som referens var effektivt — minimalt tolkningsarbete

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Timeline | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 3 dagar | 13 (8 planned + 5 gap-closure) | Audit-driven gap closure |
| v2.0 | 5 dagar | 7 (4 planned + 3 gap-closure) | Design system + tech debt |

### Top Lessons (Verified Across Milestones)

1. Datamodell-beslut i Phase 1 propagerar genom hela projektet — investera tid tidigt
2. Gap-closure-faser ar effektiva men bor minimeras genom battre upfront-design
3. Milestone audit fangar problem som per-fas-verifiering missar
4. Verifiering bor ske i samma fas som implementation — inte i separata faser (bekraftat i bada milestones)
5. Design-token adoption kraver explicit "adopta i alla vyer"-scope, inte bara "bygg token"
