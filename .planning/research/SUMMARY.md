# Project Research Summary

**Project:** Hot & Cold Friends — social weather iOS app
**Domain:** Social iOS app med vänners väder i realtid, kontaktimport, AI-platsgissning och realtidschatt
**Researched:** 2026-03-02
**Confidence:** MEDIUM-HIGH

## Executive Summary

Hot & Cold Friends är en nativ iOS-app (SwiftUI + Firebase) som visar vänners väder i realtid sorterat efter temperatur — det sociala formatet som skiljer den från vanliga väderapplikationer. Forskning bekräftar att produktkonceptet har en tydlig nisch mellan Fair Weather Friends (närmaste konkurrent, men saknar chatt och avancerad import) och nedlagda Zenly (stark social känsla men platsbaserad). Den rekommenderade stacken är Swift 6 / SwiftUI (iOS 16+), Firebase som helhetsplattform (Auth + Firestore + Realtime DB + FCM), Apple WeatherKit för väderdata och OpenAI via backend-proxy för AI-driven platsgissning. MVVM med `@Observable` (iOS 17+) är arkitekturstandarden 2025-2026 för SwiftUI-appar.

Det finns ett fundamentalt designbeslut som måste fattas tidigt och som påverkar hela onboarding-flödet: det går inte att importera vänner från Facebook, Instagram eller Snapchat via officiella API:er. Facebook ger bara ömsesidiga app-användare tillbaka (ej hela vänlistan), Instagrams consumer API stängdes december 2024, och Snapchat Kit har inga vänskapslistor. Den enda pålitliga importvägen är iOS Contacts-ramverket kombinerat med AI-driven platsgissning baserat på kontaktdata användaren själv äger. Denna pivit är inte ett hinder — den är faktiskt mer integritetsrespekterande och undviker plattformsberoende.

De tre mest kritiska riskerna är: (1) Firebase-kostnadsbomb om Firestore-lyssnare används fel (väderdata ska INTE drivas av realtidslyssnare), (2) App Store-avvisning om chatt saknar moderationsmekanism (rapport/blockering krävs av Guideline 1.2 sedan November 2025) och (3) privacy-exponering om AI-inferens gissar en väns plats utan det vänens samtycke. Alla tre är arkitekturella beslut som måste låsas i fas 1, inte retroaktivt.

---

## Key Findings

### Recommended Stack

Firebase är rätt val över Supabase för detta projekt: lägre RTT för chatt (600 ms Realtime DB vs 1500 ms Firestore för meddelandeströmmar), FCM-integration för push, och social auth i samma SDK. WeatherKit (iOS 16+) är inkluderat i Apple Developer-memberskapet och ger 500 000 anrop/månad utan kostnad — mer än tillräckligt för tidigt stadium. AI-platsgissning ska alltid gå via en backend-proxy (Firebase Cloud Function) och aldrig anropa OpenAI direkt från appen.

**Core technologies:**
- **Swift 6 / SwiftUI (iOS 16+):** Primärt språk och UI-ramverk. iOS 16 sätts av WeatherKit. Swift 6 eliminerar data races via strict concurrency. @Observable (iOS 17+) förenklar state.
- **Firebase (Auth + Firestore + Realtime DB + FCM):** Helhetsplattform. Firestore för profiler och vänlistor; Realtime DB för chat (lägre latens); FCM för push via APNs.
- **Apple WeatherKit:** Nativt Swift-API, 500K anrop/mån gratis med developer-membership, ingen nyckelhantering, privacy-first. Kräver obligatorisk Apple-attribution i UI.
- **OpenAI API (via Cloud Function proxy):** AI-platsgissning vid kontaktimport. Får ALDRIG anropas direkt från iOS-appen — API-nyckel kan extraheras ur .ipa.
- **Swift Package Manager:** Beroendehantering. CocoaPods är deprecated och ska undvikas.
- **Firebase Emulator Suite:** Lokal utveckling utan att belasta produktionskvoter.

Se `.planning/research/STACK.md` för fullständig version-, alternativ- och kompatibilitetsmatris.

### Expected Features

**Must have (table stakes / v1):**
- Social inloggning: Sign in with Apple (OBLIGATORISK om Google/Facebook erbjuds) + Google Sign-In
- Användarprofil med stad/land
- Kontaktimport från iOS Contacts + AI-driven platsgissning (den kritiska differentiator som ersätter social API-import)
- Väderdata i realtid per vän (temperatur + ikon)
- Vädersorterad listvy med temperaturgradering (primär differentiator, låg komplexitet)
- Favoriter (6 vänner överst — explicit krav i PROJECT.md)
- Onboarding med live exempeldata (fiktiva vänner med riktigt väder — "aldrig tom vy")
- Realtidschatt med push-notiser INKL rapport/blockering (App Store-krav)
- Push-notis för extremväder hos vän

**Should have (differentiators, v1.x):**
- Grupperade väderkort — "Hot & Cold"-vy (visuell humor, unikt bland konkurrenter)
- Kartvy med vänners platser (MapKit, beror på att vän+plats-data finns)
- Daglig vädersammanfattnings-notis (morgon-push, konversationsstarter)
- iOS-widget hemskärm (WidgetKit)
- Animerade väderillustrationer (Lottie eller SwiftUI-animationer)

**Defer (v2+):**
- Facebook/Instagram login (Apple + Google räcker för v1)
- Apple Watch-komplikation
- Vädervarning per specifik vän (kräver polling-infrastruktur och kalibrering)
- Flerspråksstöd (engelska först)

**Anti-features att undvika:** realtids-GPS-spårning, video/röstsamtal, social feed, crowdsourcad väderrapportering, gamification (leaderboards/streaks).

Se `.planning/research/FEATURES.md` för fullständig prioriteringsmatris och konkurrentanalys.

### Architecture Approach

MVVM med `@Observable` (iOS 17) är standardarkitekturen. Varje feature-modul (Onboarding, FriendList, Chat, Map, FriendImport, Auth) är självständig under `Features/`. Delade tjänster (`WeatherService`, `ChatService`, `AuthService`, etc.) i `Services/` är protokollbaserade och injiceras via `DependencyContainer` — kritiskt för testbarhet och för att kunna byta live-tjänster mot demo-implementationer vid first-run. Väderdata hämtas lazy per kort (inte bulk på listvyn) med 30-minuters TTL-cache.

**Major components:**
1. **Features/ (Onboarding, FriendList, Chat, Map, FriendImport, Auth)** — self-contained feature-moduler, Views + ViewModels
2. **Services/ (WeatherService, ChatService, AuthService, FriendService, AILocationService, NotificationService)** — protokollbaserade externa integrationer
3. **Firebase (Auth + Firestore + Realtime DB + FCM + Cloud Functions)** — backend; Cloud Functions är obligatoriska för FCM-trigger vid chat och OpenAI-proxy
4. **DemoWeatherService + DemoFriendService** — mock-implementationer som delar protokoll med live-tjänster; aktiveras vid first-run onboarding
5. **Firestore datamodell:** `users/{uid}/friends/{friendId}` + `conversations/{id}/messages/{messageId}` (subcollection, ALDRIG array-fält — 1MB-gräns)

Bygg-ordning baserad på komponentberoenden: Auth → Firestore-lager → WeatherService + Listvy → Onboarding+DemoData → Kartvy → Chatt → Push → AI-import → (social platform-import).

Se `.planning/research/ARCHITECTURE.md` för dataflöden, kodexempel och skalningsgränser.

### Critical Pitfalls

1. **Social API-vänimport är omöjlig** — Facebook ger bara ömsesidiga app-användare, Instagram consumer API avvecklades december 2024, Snapchat har inga vänlistscopesa. Ersätt med iOS Contacts + manuell inbjudan. Besluta detta INNAN någon importkod skrivs.

2. **Firebase Firestore-kostnadsbomb via felaktig lyssnarkonfiguration** — Väderdata får INTE drivas av realtidslyssnare (math: 1000 användare × 20 vänner × 48 uppdateringar/dag = ~1M läsningar/dag). Realtidslyssnare ENBART för chatt. Konfigurera alltid Firebase-budgetvarning.

3. **App Store-avvisning för saknad Sign in with Apple** — Obligatorisk om Google eller Facebook-login erbjuds (Guideline 4.8). Implementeras i fas 2, inte retroaktivt.

4. **App Store-avvisning för saknad UGC-moderering i chat** — Guideline 1.2 (skärpt november 2025) kräver rapport-mekanism, blockering och synlig kontaktinfo. Måste byggas TILLSAMMANS med chattfunktionen.

5. **AI-platsgissning utan samtycke skapar legal exponering** — GDPR/CCPA-risk om AI infererar en annan persons plats utan deras samtycke. Korrekt modell: AI ger FÖRSLAG till den inloggade användaren; vännen deklarerar sin egen plats när hen går med i appen. Aldrig tyst lagra AI-inferens om en icke-registrerad person.

6. **Saknade privacy manifests för tredjepartsSDK:er** — Apple kräver `PrivacyInfo.xcprivacy` sedan februari 2025. Kör `Product → Archive → Validate` innan TestFlight-submission.

Se `.planning/research/PITFALLS.md` för fullständig checklista, recovery-strategier och integrations-gotchas.

---

## Implications for Roadmap

Baserat på komponentberoenden, pitfall-fas-mappningar och feature-prioriteringar rekommenderas följande fasstruktur:

### Phase 1: Foundation — Auth, Profil, Datamodell och Samtyckesstrategi
**Rationale:** Allt annat beror på en autentiserad användare och en fastlåst datamodell. Samtyckesstrategi för AI-platsgissning och vänimport MÅSTE beslutas nu — inte retroaktivt.
**Delivers:** Fungerande Sign in with Apple + Google. Användarprofil med stad/land. Firestore-struktur för vänner och konversationer. Dokumenterad samtyckesmodell för plats.
**Addresses:** Social login (tabell-stakes), användarprofil (grund för allt)
**Avoids:** Pitfall 3 (Sign in with Apple saknas), Pitfall 2 (AI utan samtycke), öppna Firestore-regler i produktion

### Phase 2: Kärnupplevelse — Väderdata, Vänlista och Onboarding
**Rationale:** Appens kärnvärde. WeatherService + FriendList är den minimala produkt som kan visa att konceptet fungerar. DemoWeatherService/DemoFriendService byggs parallellt för onboarding.
**Delivers:** Vädersorterad listvy med temperaturgradering. Favoriter (6 vänner). Onboarding med live exempeldata (aldrig tom vy). WeatherService med 30-min TTL-cache (lazy per kort, ej bulk).
**Uses:** Apple WeatherKit, Firestore, MVVM + @Observable
**Implements:** FriendListViewModel, WeatherService, DemoWeatherService, DemoFriendService
**Avoids:** N+1 API-anrop vid listladdning (Pitfall 4), tom vy vid first-run (UX-pitfall)

### Phase 3: Kontaktimport och AI-Platsgissning
**Rationale:** Den primära onboarding-mekanismen för att snabbt fylla appen med vänner. Bygger på fas 2 (vän + plats-modellen). AI-proxy-arkitekturen måste vara säker från start.
**Delivers:** iOS Contacts-import med CNContactStore. AI-platsgissning via säker Cloud Function-proxy. Presentationsflöde för bekräftelse/justering av gissad plats. Manuell "lägg till vän"-fallback.
**Uses:** iOS Contacts framework, OpenAI API via Firebase Cloud Function proxy
**Implements:** FriendImportViewModel, AILocationService (protokollbaserad), ImportSourceView
**Avoids:** Direkt OpenAI-anrop från app (Pitfall — API-nyckel i .ipa), tyst lagring av AI-inferens om icke-registrerade (Pitfall 2)

### Phase 4: Realtidschatt med Push-notiser och Moderering
**Rationale:** Social trigger är kärnvärdet — utan chatt är appen ett informationswidget. Chatt, push och moderering byggs TILLSAMMANS (App Store-krav, och push utan chatt är meningslöst).
**Delivers:** Firebase Realtime DB-baserad chatt. FCM-push via Cloud Function-trigger. Rapport + Blockering-UI (Guideline 1.2). Support-kontakt i inställningar. Extremväder-push-notis.
**Uses:** Firebase Realtime Database, FCM, APNs, Cloud Functions
**Implements:** ChatService med snapshot listener (detach vid onDisappear), NotificationService, rapport/block-UI
**Avoids:** Pitfall 5 (UGC-moderering saknas), Pitfall 6 (silent push istället för visible alerts), listener-läckor vid SwiftUI-navigering

### Phase 5: Utökade Vyer — Kartvy och Grupperade Kort
**Rationale:** Differentierande vyer som bygger på att fas 2-3 är stabila. Karta kräver MapKit men är i övrigt straightforward när vän+plats-data finns. Hot/Cold-vy är låg komplexitet men hög underhållningsfaktor.
**Delivers:** MapKit-kartvy med vänners platser och väderprops. Grupperade väderkort ("Tropical/Warm/Cool/Cold/Arctic"-vy). Daglig vädersammanfattnings-notis (lokal schemalagd notis).
**Uses:** MapKit (native, ingen extern SDK), SwiftUI LazyVGrid, schemalagda lokala notiser (mer pålitliga än server-push)
**Implements:** FriendMapView, FriendMapViewModel, Grouped weather cards-vy

### Phase 6: Polish, Widget och App Store-Prep
**Rationale:** Sista fasen före lansering. Privacy manifests, konto-borttagning och TestFlight-validering är icke-förhandlingsbara App Store-krav. iOS-widget är en power-user-funktion som kräver WidgetKit.
**Delivers:** iOS-hemskärmswidget (WidgetKit, medium 2x2 minimum). Animerade väderillustrationer (Lottie). In-app "Radera konto"-flöde (App Store-krav sedan 2023). Privacy manifest-audit (`Product → Archive → Validate` utan ITMS-91061). TestFlight-betaperiod.
**Avoids:** Pitfall 7 (saknade privacy manifests), konto-borttagning saknas, Privacy-policy missmatch

### Phase Ordering Rationale

- **Auth-first** är icke-förhandlingsbart: Firestore-säkerhetsregler, FCM-tokens och samtyckesmodell bygger alla på autentiserad användare.
- **Väder + listvy före import** validerar kärnkonceptet utan extern API-osäkerhet. DemoWeatherService möjliggör visuellt genombrott tidigt.
- **Import i fas 3** (efter kärnupplevelse) innebär att man kan bevisa att produkten fungerar även med manuellt tillagda vänner — minskar risken om iOS Contacts-tillståndet nekas.
- **Chatt + push + moderering i en fas** är obligatoriskt: App Store-granskning ser dessa som ett paket. Att leverera chatt utan moderering garanterar avvisning.
- **Vyer och widget sist** — de beror på stabil data-grund men blockerar inte MVP-validering.

### Research Flags

Faser som sannolikt behöver fördjupad research under planering:
- **Fas 3 (AI-import):** OpenAI API-promptstrategi för platsgissning, Cloud Function-arkitektur för proxy, batching-strategi för stora kontaktlistor. Kostnadsbild per import-session är okänd.
- **Fas 4 (Chatt + Push):** Firebase Cloud Functions-triggers för FCM vid ny chatt-message, APNs-konfiguration för visible vs. silent push, rate-limiting via Firebase App Check.
- **Fas 6 (App Store):** Age-gating-frågeformuläret (Apple-deadline januari 2026 för uppdaterat formulär — kontrollera status).

Faser med välkända mönster (kan hoppa över research-fas):
- **Fas 1 (Auth):** Firebase Auth med Apple/Google är välbeskriven i officiella docs. Inga kunskapsluckor.
- **Fas 2 (WeatherKit + listvy):** Apple WeatherKit-dokumentation är fullständig. MVVM-mönster är standardiserat.
- **Fas 5 (MapKit):** Native MapKit för SwiftUI har officiell Apple-dokumentation, inga externa beroenden.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Firebase SDK-versioner bekräftade från officiella release notes (feb 2026). WeatherKit iOS 16-krav är officiell Apple-doc. Social API-begränsningar bekräftade från flera oberoende källor. |
| Features | MEDIUM | Konkurrentanalys baserad på App Store + medieartiklar (inte direkt API-åtkomst). Fair Weather Friends-features observerade men inte verifierade internt. Competitor retention-data är inference. |
| Architecture | MEDIUM | MVVM + @Observable är bekräftat mönster (officiella Apple docs + community). Firestore-datamodell baserad på Firebase-docs + community best practices. Skalningstal för listener-kost är community-inference, inte Firebase-officiellt. |
| Pitfalls | HIGH | Social API-begränsningar är officiellt dokumenterade och bekräftade. App Store-avvisningsregler är från officiella Apple Developer guidelines. Firebase-kostnadsbild är MEDIUM (community-uppskattningar, inte exakta fakturor). |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **AI-platsgissningskostnad:** Okänd kostnad per kontaktimport-session med OpenAI. Behöver kostnadsuppskattning och eventuellt rate-limiting-strategi tidigt i fas 3-planering.
- **Facebook SDK 17.x iOS 16-krav:** Noterat "verifiera" i STACK.md — bekräfta exakt iOS-minimum mot Facebook Developer Portal innan fas 1.
- **@Observable iOS 17 vs. iOS 16-deploymål:** ARCHITECTURE.md rekommenderar @Observable (iOS 17+) men WeatherKit sätter minimum till iOS 16. Beslut behövs: är iOS 16-stöd viktigt eller är iOS 17+ acceptabelt? ~90%+ av aktiva enheter kör iOS 16+, men iOS 17+ är lägre andel. Rekommendation: sätt deployment target iOS 17 för att kunna använda @Observable fullt ut.
- **Age-gating-formulär status:** Apple satte deadline januari 2026 för uppdaterat formulär för UGC-appar. Verifiera att detta är genomfört korrekt i App Store Connect.
- **Firebase Cloud Functions-kostnad:** Proxy för OpenAI och FCM-trigger kräver Blaze (betalplan). Kostnadsuppskattning behövs i fas 3-4 planering.

---

## Sources

### Primary (HIGH confidence)
- Firebase iOS SDK release notes v12.10.0 — https://firebase.google.com/support/release-notes/ios
- Apple WeatherKit documentation — https://developer.apple.com/weatherkit/
- Apple App Store Review Guidelines — https://developer.apple.com/app-store/review/guidelines/
- Apple Privacy Manifest requirements — https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Snapchat Login Kit scopes — https://developers.snap.com/snap-kit/login-kit/overview
- Instagram Basic Display API EOL — officiell avveckling december 2024
- Firebase Firestore real-time queries at scale — https://firebase.google.com/docs/firestore/real-time_queries_at_scale
- Silent push notifications not guaranteed (APNs) — mohsinkhan845.medium.com + Apple documentation

### Secondary (MEDIUM confidence)
- Firebase vs Supabase real-time comparison — latenstal (600 ms / 1500 ms) från multiple community sources
- MVVM + @Observable iOS 17 pattern — medium.com/@csmax, medium.com/@sayefeddineh
- Facebook Graph API user_friends limitation — multiple corroborating sources post-Cambridge Analytica
- Fair Weather Friends App Store listing — direkt analys
- Zenly post-mortem coverage — TechCrunch 2022
- AI and location privacy regulation 2025 — cloudsecurityalliance.org

### Tertiary (LOW confidence)
- AI location inference cost at scale — inga exakta siffror tillgängliga, baserat på OpenAI pricing models
- Firebase Firestore listener cost calculations — community-uppskattningar, inte officiella Firebase-siffror

---
*Research completed: 2026-03-02*
*Ready for roadmap: yes*
