# Phase 4: Chatt och Push - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Realtidschatt (1-till-1 och grupp), väderreaktioner, rapport/blockering (App Store Guideline 1.2-krav), och push-notiser (chattmeddelanden + extremväder hos vän). Chatten är appens sociala trigger — den kopplar ihop väderfokuset med kommunikation.

</domain>

<decisions>
## Implementation Decisions

### Chattens roll i appen
- Chatten nås på TVÅ sätt: direkt från vänlistan (tryck på vän) OCH via egen chatt-flik (TabView med Vänner + Chattar)
- iMessage-stil chatbubblor — egna meddelanden höger (blå), mottagarens vänster (grå)
- Konversationslistan visar: profilbild, namn, senaste meddelande, tidsstämpel + vännens aktuella väderikon
- Väder-header ovanför chatbubborna i konversationsvyn — visar vännens stad, temperatur och väderikon

### Väderreaktioner
- Automatiska väder-stickers som genereras från aktuellt väder (stad + temperatur + väderikon)
- Dedikerad knapp (väderikon) bredvid textfältet i chattvyn — ett tryck för att skicka
- Användaren kan välja att skicka sitt eget ELLER vännens väder som sticker
- Stickern visas som ett speciellt meddelande i chatten (inte en vanlig textbubbla)

### Gruppchattar
- Fria grupper — användaren skapar manuellt och väljer vilka vänner som ska med
- Skapande via chatt-fliken: "Ny konversation" → välj 2+ vänner → namnge gruppen (valfritt) → starta
- Gruppchatten visar väder-header per medlem (horisontell rad med namn + ikon + temperatur)
- Väder-stickers fungerar i gruppchattar (välj vems väder att skicka)

### Extremväder-notiser
- Baserat på WeatherKit severe weather alerts (Apples officiella varningar) — ingen egen tröskellogik
- Max 1 notis per vän per dag (rate-limiting)
- Personlig, vänlig ton: "Storm hos Anna i Tokyo 🌪️ — hör av dig!"
- Deep link: tryck på notisen → öppna chatten med den vännen direkt

### Rapport och blockering
- App Store Guideline 1.2-krav: rapport och blockering MÅSTE finnas för UGC
- Rapport: användare kan rapportera olämpligt innehåll (meddelanden)
- Blockering: användare kan blockera en annan användare (inga fler meddelanden)

### Claude's Discretion
- Väder-stickerns visuella design (kompakt kort vs stor emoji)
- Max antal gruppmedlemmar (rimlig gräns)
- Rapport/blockering-UI-placering och flöde
- Push-notis vid nytt chattmeddelande (format och beteende)
- Push-tillståndsflöde (när och hur appen frågar om notis-tillstånd)
- Chatthistorik — hur långt bakåt meddelanden laddas
- Typing indicators och läskvitton (om det ska finnas)

</decisions>

<specifics>
## Specific Ideas

- Konversationslistan ska ha väderikon per konversation — kopplar ihop chatt med appens kärnvärde
- Väder-headern i chatten påminner om varför man pratar: "Så här är det hos din vän just nu"
- Extremväder-notisen fungerar som social trigger: varning + uppmaning att höra av sig → deep link till chatt
- Gruppchatten med väder-header per medlem skapar en unik "väder-dashboard" för vängruppen

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FriendRowView`: Profilbild + namn + stad + väderikon — kan återanvändas/anpassas för konversationslistan
- `AppWeatherService`: WeatherKit-integration med 30-min cache — behövs för väder-stickers och alerts
- `FriendService`: Firestore CRUD för vänner under `users/{uid}/friends/` — chatt-modellen kan följa samma mönster
- `Color.temperatureColor(celsius:)`: Temperaturfärgkodning — återanvändbar i väder-stickers och headers
- `Friend`-modellen: Har city, cityLatitude, cityLongitude — allt som behövs för väder-lookups

### Established Patterns
- SwiftUI med `@Observable`-mönster (modern Swift observation)
- Environment injection av services (`AuthManager`, `FriendService`, `AppWeatherService`)
- Sheet-baserad navigation för detaljer och formulär
- Firebase Firestore för data, Cloud Functions (TypeScript) för serverlogik
- `NavigationStack` i `FriendListView` — behöver omstruktureras till `TabView`

### Integration Points
- `AppRouter.swift`: Behöver utökas — `authenticated`-caset måste gå till TabView istället för direkt till FriendListView
- `HotAndColdFriendsApp.swift`: Ny ChatService behöver injiceras som environment
- `AppDelegate.swift`: Behöver utökas med push-notis-registrering (APNs)
- `functions/src/index.ts`: Befintlig Cloud Functions — utökas med push-triggers

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-chatt-och-push*
*Context gathered: 2026-03-03*
