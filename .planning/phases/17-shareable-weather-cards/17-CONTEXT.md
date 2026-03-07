# Phase 17: Shareable Weather Cards - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Användare kan generera snygga väderbilder för en vän och dela dem utanför appen via share sheet och Instagram Stories för att driva organisk synlighet. Omfattar: kortgenerering (bild), preview-flöde, share sheet-delning och Instagram Stories-integration. Me vs You-kort (CARD-03) och daglig digest (CARD-05) tillhör Phase 18.

</domain>

<decisions>
## Implementation Decisions

### Kortets visuella design
- Porträttkort (vertikalt, typ 9:16-format) — funkar bra i både share sheet och Instagram Stories
- Nya helskärms-väderillustrationer som bakgrund per vädertyp (sol, moln, regn, snö etc) — kräver nya grafiska assets
- Information på kortet: avatar, namn, temperatur, väderikon, stad, väderbeskrivning (t.ex. "Sunny"), datum/tid
- Subtil FriendsCast-logotyp i nederkant (LogoHorizontal-asset finns)
- Ingen invite-länk eller QR-kod på själva bilden — kortet ska vara rent

### Var i appen skapas kort
- Swipe-action åt vänster på en vänrad i vänlistan — standard iOS-mönster
- Swipe visar "Share"-knapp som öppnar en preview-sheet
- Preview-sheet visar förhandsvisning av kortet + knappar för Share Sheet och Instagram Stories
- Inget anpassningssteg — kortet genereras automatiskt med vännens aktuella väder, redo att dela

### Instagram Stories-delning
- Instagram Stories-knapp visas bara om Instagram är installerat (canOpenURL-check)
- Dölj knappen helt om Instagram saknas — inget felmeddelande
- Bara två delningsalternativ i preview-sheeten: Instagram Stories + generell Share Sheet
- Ett enda kortformat för alla kanaler — inget kanalspecifikt format
- Sticker vs helskärmsbild: Claude's discretion baserat på teknisk research

### Delningstext och viralitet
- Share sheet bifogar invite-länk (apps.sandenskog.se/invite/<token>) i texten tillsammans med bilden
- Förskriven text bifogas, t.ex. "It's 23° and sunny in Stockholm" + invite-länk
- Texten genereras dynamiskt baserat på vännens aktuella väder och stad

### Claude's Discretion
- Exakt kortdimensioner och proportioner
- Instagram Stories API-approach (sticker vs bakgrund, teknisk implementation)
- Väderillustrationer — stil och antal kategorier (gruppering av vädertyper)
- ImageRenderer vs UIGraphicsImageRenderer för bildgenerering
- Preview-sheetens layout och knappar
- Animationer i preview-sheeten
- Förskrivna textens exakta formulering och format

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AvatarView`: Gradient-avatar med temperaturzon-färger och initialer/foto. Kan renderas i kortet för vännens avatar.
- `TemperatureZone`: 5 zoner (Tropical/Warm/Cool/Cold/Arctic) med gradienter och färger. Kan styra kortets färgschema.
- `WeatherIconMapper`: Mappar WeatherKit-symboler till 14 custom SVG-ikoner. Kan användas för väderikon på kortet.
- `BubblePopTypography/Spacing/Shadows`: Design system-tokens för konsekvent typografi och layout.
- `LogoHorizontal`: Befintlig asset för app-branding på kortet.
- `InviteService.swift`: Har redan invite-token tillgängligt för share-texten.

### Established Patterns
- `ShareLink` används redan i 3 ställen (AddFriendSheet, FriendsTabView, ProfileView) — bekant mönster
- `@Observable` + `@MainActor` services via `.environment()`
- SwiftUI-baserat UI genomgående

### Integration Points
- `FriendRowView` / vänlistan: Lägg till swipe-action för kortgenerering
- `InviteService`: Hämta invite-token för share-texten
- `AppWeatherService` / väderdata: Hämta aktuellt väder för vännen
- `Info.plist`: Behöver `LSApplicationQueriesSchemes` med `instagram-stories` för canOpenURL-check

</code_context>

<specifics>
## Specific Ideas

- Bakgrundsillustrationerna ska vara helt nya helskärmsbilder per vädertyp — inte förstorade versioner av befintliga ikoner
- Kortet ska kännas "share-worthy" — något man faktiskt vill posta, inte bara en screenshot
- Warm, social känsla i linje med appens design — inte kliniskt/minimalistiskt

</specifics>

<deferred>
## Deferred Ideas

- Me vs You-jämförelsekort — Phase 18 (CARD-03)
- Daglig digest-kort — Phase 18 (CARD-05)
- Animerade väderkort (video/GIF) — v4+ (CARD-06)
- Snapchat/TikTok-dedikerade delningsknappar — framtida fas
- Anpassningsbara kort (välj bakgrund, lägg till meddelande) — framtida iteration

</deferred>

---

*Phase: 17-shareable-weather-cards*
*Context gathered: 2026-03-07*
