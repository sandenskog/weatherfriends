# Feature Research

**Domain:** Social weather / friend-location social app (iOS)
**Researched:** 2026-03-02
**Confidence:** MEDIUM

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Väderdata i realtid per vän | Kärnupplevelsen — utan detta är appen en adressbok | LOW | API-kall mot OpenWeatherMap/WeatherAPI per lokation, cachas. Kräver att plats finns lagrad per vän |
| Visning av vänners stad/land | Utan kontext vet man inte vem som har vilket väder | LOW | Statisk text, lagras vid onboarding/import |
| Temperatur + väderikon | Minsta väderinformation användare förväntar sig se | LOW | Temperatur i °C/°F + ikon (soligt, regn, snö etc.) |
| Profil per användare | Grundläggande socialt kontrakt — vem är vem? | LOW | Namn, profilbild, stad. Enkelt men nödvändigt |
| Social inloggning (Apple/Google) | App Store-användare förväntar sig Sign in with Apple; friction med e-post och lösenord tappar folk | LOW | Apple Sign In krävs av Apple om sociala inlogg erbjuds. Google är standardväntan på iOS |
| Push-notiser för extremväder | Fair Weather Friends gör detta som kärnfeature — användare förväntar sig att bli upplyst om vänner har storm/extrem kyla | MEDIUM | Kräver FCM/APNs-integration, webhook eller polling mot väder-API |
| Favorit-/nära vänner-lista | Alla location-sociala appar (Life360, Snap Map, Zenly) har en primär "circle" — utan urval är listan oanvändbar vid 100+ vänner | LOW | Enkel markering + sortering, lagras lokalt/i backend |
| Chatt / direktmeddelanden | Appen positionerar sig som social trigger att höra av sig — om man inte kan skriva direkt i appen tappar man loopen | HIGH | Realtidschatt med push. Kräver socket eller Firebase Realtime/Firestore |
| Onboarding som inte är tom | Research bekräftar: "your empty state should never feel empty" — tom vy vid first run = omedelbar avinstallation | MEDIUM | Live exempeldata (fiktiva vänner med riktigt väder) visas tills egna vänner är inlagda |
| iOS-widget (hemskärm) | Fair Weather Friends har detta som premium-feature, men konkurrenter gör det till förväntning. WeatherUp och Apple Weather satt standarden | MEDIUM | WidgetKit med SwiftUI. Minst en storlek (medium 2x2) |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI-driven platsgissning vid kontaktimport | Löser "unknown weather"-problemet vid massimport. Unik position — ingen konkurrent gör detta. Avgörande för att appen ska kännas användbar direkt | HIGH | LLM-anrop (GPT-4o/Claude) per kontakt. Input: namn, telefonnummer, landsnummer, e-postdomän, ev. Facebook-stad. Output: gissad stad/land med konfidensgrad |
| Tre vyer: lista, karta, grupperade kort | Olika användare konsumerar information på olika sätt. Lista = snabb scan, karta = geografisk kontext, grupperade kort (t.ex. "Heta vänner" / "Iskalla vänner") = engagerande och delbart | HIGH | Tre separata SwiftUI-vyer med delade data. Kartvy kräver MapKit eller Google Maps SDK |
| Vädersorterad lista med temperaturgradering | Primär differentiator — istället för alfabetisk lista ser man direkt vem som badar i solen och vem som fryser | LOW | Sorteringslogik i ViewModel; visuell gradering (färg, gradient) |
| Animerade väderillustrationer | Känslan av en levande, varm app vs. en statisk informations-widget. Zenly fick enorm kärlek för sina animerade avatarer och ikoner | MEDIUM | Lottie-animationer eller SwiftUI-animationer. En illustration per vädertyp (8-12 typer) |
| Daglig vädersammanfattning-notis | "Idag har Nina 28 grader och sol i Barcelona, Erik -12 i Luleå" — konversationsstarter levererad direkt | MEDIUM | Schemalagd push (APNs) med personaliserad text genererad från väderdata. Timing: morgon |
| Grupperade väderkort ("Hot & Cold"-vy) | Visuell humor och engagemang — kontrasten -15° vs +30° är underhållningsvärdet som PROJECT.md nämner | MEDIUM | Gruppering i SwiftUI (LazyVGrid). Kategorier: Tropical, Warm, Cool, Cold, Arctic |
| Import från kontakter + AI-gissning | Sänker tröskel drastiskt — istället för att manuellt lägga till vänner en i taget kan man importera hela adressboken | HIGH | iOS Contacts-ramverket + CNContactStore. Ingen social API behövs för kontaktimport |
| Vädervarning-notis för specifik vän | "Tobias har just fått ett åskvarnings-alarm i Madrid" — personlig och handlingsdrivande | MEDIUM | Polling mot väder-API för severe alerts (t.ex. OpenWeatherMap One Call API 3.0 har alerts) |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Facebook/Instagram/Snapchat vänimport via API | Verkar som naturlig källa för vänner | Facebooks Graph API ger inte tillgång till vänlistor sedan 2015. Instagrams API är starkt begränsat. Snapchat har inget public API. Att bygga för dessa APIs leder till ständiga brott och potentiell App Store-rejection | Importera från iOS-kontakter (fungerar, inga API-begränsningar). Social login (Facebook/Google/Apple) för autentisering — inte för vänimport |
| Realtids-GPS-spårning av vänner | Snap Map och Zenly gör detta | Massiv privacy-risk, Apple App Store-review är strikt kring alltid-på plats-åtkomst, kräver bakgrundslokalisering, och är felpositionerat för det här konceptet. Appen handlar om väder på känd stad — inte exakt position | Låt varje vän ange sin stad/land manuellt eller via onboarding. Plats = stad, inte GPS-koordinat |
| Video- och röstsamtal | Nästa steg efter chatt | Scope-creep, kräver WebRTC-infrastruktur, licensiering, dyrt att drifta, Apple kräver CallKit-integration. Adderar ingenting till kärnvärdet | Textchatt räcker för v1. Länk till FaceTime/WhatsApp om röst behövs |
| Oändlig social feed | Alla sociala appar har en feed | Tappar appens fokus — "se hur det är hos dina vänner" är en vy, inte ett flöde. Feed-logik kräver ranking, moderation, spam-hantering | Håll huvudvyn kontaktbaserad. Väderhändelser kan loggas per vän men visas som notiser, inte feed |
| Crowdsourcad väderrapportering (Weddar-modellen) | Verkar socialt och engagerande | Weddar visade att det kräver kritisk massa — "frustrerande när det bara är 4-5 rapporterare i Manhattan". Appen behöver fungera även med 0 aktiva rapporterare | Använd pålitlig väder-API-data (OpenWeatherMap, WeatherAPI) som alltid fungerar |
| Gamification (poäng, leaderboards, streaks) | Ökar engagement | Weddar testade leaderboards — det fungerar inte för väder-kontext. Känslan blir gamified och trist istället för varm och social | Engagemang via social push ("Hör av dig till Nina!") är mer i linje med appens känsla |
| Mörk bakgrund / weather drama-design | "Ser coolt ut" | Går emot appens varma, sociala känsla. Svart bakgrund associeras med teknisk väderapp, inte social app | Ljus, varm design med subtila färggradienter baserade på vädertyp och tid på dygnet |

---

## Feature Dependencies

```
[Social inloggning (Apple/Google)]
    └──krävs av──> [Användarprofil]
                       └──krävs av──> [Chatt]
                       └──krävs av──> [Favoriter]
                       └──krävs av──> [Push-notiser]

[Vän + plats lagrad]
    └──krävs av──> [Väderdata i realtid per vän]
                       └──krävs av──> [Vädersorterad lista]
                       └──krävs av──> [Grupperade väderkort]
                       └──krävs av──> [Karta-vy]
                       └──krävs av──> [Vädervarning-notis]
                       └──krävs av──> [iOS-widget]

[Kontaktimport (iOS Contacts)]
    └──förbättras av──> [AI-driven platsgissning]

[Väder-API-integration]
    └──krävs av──> [Daglig sammanfattnings-notis]
    └──krävs av──> [Vädervarning-notis för vän]

[Push-notiser (APNs)]
    └──krävs av──> [Vädervarning-notis]
    └──krävs av──> [Daglig sammanfattnings-notis]
    └──krävs av──> [Chatt-notiser]

[Chatt]
    └──konfliktar ej med──> [Push-notiser]
    (båda behövs parallellt)
```

### Dependency Notes

- **Social inloggning krävs av Användarprofil:** Utan autentisering kan man inte lagra vänner, preferenser eller chat-historik i backend
- **Vän + plats krävs av allt väder:** Plats är data-grunden. AI-platsgissning löser bootstrapping-problemet vid import
- **iOS Contacts krävs ej av AI-gissning men förstärks av den:** Man kan ha kontaktimport utan AI (manuell stad-inmatning), men AI-gissning gör upplevelsen dramatiskt bättre
- **Chatt och push är parallellt beroende:** Chatt utan push = notiser missas. Bygg dem i samma fas
- **Karta-vy beror på plats men kräver MapKit:** Separat beroende från listvyn — kan isoleras till en senare fas utan att blockera MVP

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] Social inloggning (Apple Sign In + Google) — utan detta kan ingenting lagras
- [ ] Användarprofil med stad/land — grunden för all väderdata
- [ ] Manuellt lägga till vänner med stad/land — enklaste vägen till väderdata utan API-beroenden
- [ ] Kontaktimport från iOS-kontakter — sänker tröskel drastiskt, standardfunktionalitet
- [ ] AI-driven platsgissning — kritisk för att appen ska kännas användbar direkt vid import
- [ ] Väderdata i realtid per vän (OpenWeatherMap) — kärnupplevelsen
- [ ] Vädersorterad listvy med temperaturgradering — primär differentiator, låg komplexitet
- [ ] Favoriter (6 vänner överst) — fokuserar upplevelsen, nämns specifikt i PROJECT.md
- [ ] Onboarding med live exempeldata — ingen tom vy, bekräftat best practice
- [ ] Realtidschatt med push-notiser — social trigger är kärnvärdet, måste finnas v1
- [ ] Push-notiser: extremväder hos vän — tablestake från Fair Weather Friends-kategorin

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Grupperade väderkort ("Hot & Cold"-vy) — trigger: core list view är validerad, vill öka engagemang
- [ ] Karta-vy med vänners platser — trigger: användare efterfrågar geografisk kontext
- [ ] Daglig vädersammanfattnings-notis — trigger: retention-data visar behov av daglig återaktivering
- [ ] iOS-widget (hemskärm) — trigger: power-users vill se väder utan att öppna appen
- [ ] Animerade väderillustrationer (Lottie) — trigger: app-känslan poleras, produkt-market fit nådd

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Facebook/Instagram social login (ej vänimport) — defer: Apple och Google räcker för v1
- [ ] Vädervarning-notis per specifik vän — defer: kräver polling-infrastruktur, fine-tune alert-trösklar
- [ ] Apple Watch-komplikation — defer: nischad men väl anpassad till "glance" use case
- [ ] Localization / flerspråksstöd — defer: lansera på engelska, lägg till svenska och andra vid behov

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Social inloggning (Apple/Google) | HIGH | LOW | P1 |
| Väderdata per vän | HIGH | LOW | P1 |
| Vädersorterad lista | HIGH | LOW | P1 |
| Favoriter (6 vänner) | HIGH | LOW | P1 |
| Kontaktimport + AI-platsgissning | HIGH | HIGH | P1 |
| Onboarding med exempeldata | HIGH | MEDIUM | P1 |
| Realtidschatt + push | HIGH | HIGH | P1 |
| Extremväder-push-notis | MEDIUM | MEDIUM | P1 |
| Grupperade väderkort | MEDIUM | MEDIUM | P2 |
| Karta-vy | MEDIUM | MEDIUM | P2 |
| Daglig sammanfattnings-notis | MEDIUM | LOW | P2 |
| iOS-widget | MEDIUM | MEDIUM | P2 |
| Animerade illustrationer | LOW | MEDIUM | P2 |
| Apple Watch-komplikation | LOW | HIGH | P3 |
| Flerspråksstöd | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Fair Weather Friends | Weddar | Zenly (nedlagd) | Life360 | Vår approach |
|---------|---------------------|--------|-----------------|---------|--------------|
| Vänners väder i realtid | Ja, kärnfeature | Nej (crowdsource) | Nej (plats, ej väder) | Nej | Ja, kärnfeature |
| Socialt ursprung / kontaktimport | Manuellt | Facebook/Twitter login | Telefonkontakter | Manuellt | iOS-kontakter + AI-gissning |
| Karta-vy | Ja | Ja (världskarta) | Ja (primär vy) | Ja | v1.x |
| Chatt / meddelanden | Nej | Nej | Ja (stark feature) | Ja (gruppchatt) | Ja (v1, differentiator) |
| Push-notiser | Ja (extremväder) | Nej | Nej | Ja (geofence) | Ja (extremväder + daglig) |
| iOS-widget | Ja (premium) | Nej | Nej | Nej | v1.x |
| Animationer / levande känsla | Sky-bakgrund | Nej | Ja (ikon-animationer) | Nej | v1.x (Lottie) |
| Onboarding med exempeldata | Okänt | Okänt | Inte nödvändigt (kräver vänner) | Okänt | Ja (v1, explicit krav) |
| AI-driven platsgissning | Nej | Nej | Nej | Nej | Ja (unik differentiator) |
| Grupperingsvyer (Hot/Cold) | Nej | Nej | Nej | Nej | Ja (v1.x) |

**Analys:** Fair Weather Friends är närmaste konkurrent men saknar chatt, AI-import och avancerade vyer. Weddar visade att crowdsource-modellen kräver kritisk massa — vi undviker det. Zenly visade att social karta + chatt skapar stark retention men stängdes av Snap. Vår app kombinerar Fair Weather Friends kärnkoncept med Zenlys sociala känsla och chatt, plus en unik AI-importmekanism.

---

## Sources

- [Fair Weather Friends — App Store](https://apps.apple.com/us/app/fair-weather-friends/id1633831488) — Närmaste konkurrent, analyserades direkt
- [Weddar — App Store](https://apps.apple.com/us/app/weddar-social-weather/id431659526) — Social weather pioneer, crowdsource-modellen
- [Zenly Was the Best Social App — TechCrunch (2022)](https://techcrunch.com/2022/12/05/zenly-was-the-best-social-app-and-it-will-sadly-shut-down-on-february-3rd/) — Vad användare älskade med Zenly
- [How Zenly Made Social Maps Cool Again — TechCrunch (2022)](https://techcrunch.com/2022/04/22/how-zenly-made-social-maps-cool-again-and-whats-next/) — Features och engagemang
- [Snap Map: Making Location Social — Strategy Breakdowns](https://strategybreakdowns.com/p/snap-map-social-location) — Vad driver retention i location-sociala appar
- [Life360 — Wikipedia](https://en.wikipedia.org/wiki/Life360) — Feature-referens för social location app
- [Empty States in User Onboarding — Smashing Magazine](https://www.smashingmagazine.com/2017/02/user-onboarding-empty-states-mobile-apps/) — Onboarding best practices
- [Push Notifications in Chat Apps — ConnectyCube (2025)](https://connectycube.com/2025/12/18/push-notifications-in-chat-apps-best-practices-for-android-ios/) — Chat + push best practices
- [AccuWeather Push Notification Strategy — Airship](https://www.airship.com/blog/accuweather-uses-tailored-push-notifications-to-drive-mobile-engagement/) — Väder-push patterns

---
*Feature research for: Social weather / friend-location iOS app (Hot & Cold Friends)*
*Researched: 2026-03-02*
