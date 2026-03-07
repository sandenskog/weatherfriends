# Phase 17: Shareable Weather Cards - Research

**Researched:** 2026-03-07
**Domain:** SwiftUI image rendering, iOS sharing (Share Sheet + Instagram Stories)
**Confidence:** HIGH

## Summary

Denna fas handlar om att generera snygga vaderbilder fran SwiftUI-vyer och dela dem via systemets share sheet samt direkt till Instagram Stories. Tekniskt vilar implementationen pa tre pelare: (1) SwiftUI `ImageRenderer` for att konvertera en vy till `UIImage`, (2) SwiftUI `ShareLink` med `Transferable` for share sheet, och (3) Instagram Stories URL scheme (`instagram-stories://share`) med `UIPasteboard` for direkt Stories-delning.

Kodbasen har redan alla byggstenar: `AvatarView`, `TemperatureZone`, `WeatherIconMapper`, `FriendWeather`-modellen med varderbeskrivning, och `InviteService` for invite-lankar. Swipe actions anvands redan i vanlistan (favorit-toggle) sa monstret ar bekant. Nya assets behovs: helskarms vaderillustrationerna som bakgrund per vadertyp.

**Primary recommendation:** Bygg kortets SwiftUI-vy som en fristaaende `WeatherCardView`, rendera till `UIImage` med `ImageRenderer`, dela via `ShareLink` (share sheet) och `UIPasteboard` + URL scheme (Instagram Stories). Anvand bakgrundsbild-approachen (`com.instagram.sharedSticker.backgroundImage`) for Instagram Stories -- kortet fyller hela storyn.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Portrattformat kort (vertikalt, typ 9:16) -- funkar i bade share sheet och Instagram Stories
- Nya helskarms vaderillustrationer som bakgrund per vadertyp (sol, moln, regn, sno etc) -- kraver nya grafiska assets
- Information pa kortet: avatar, namn, temperatur, vaderikon, stad, vaderbeskrivning, datum/tid
- Subtil FriendsCast-logotyp i nederkant (LogoHorizontal-asset finns)
- Ingen invite-lank eller QR-kod pa sjalva bilden -- kortet ska vara rent
- Swipe-action at vanster pa en vanrad i vanlistan -- standard iOS-monster
- Swipe visar "Share"-knapp som oppnar en preview-sheet
- Preview-sheet visar forhandsvisning av kortet + knappar for Share Sheet och Instagram Stories
- Inget anpassningssteg -- kortet genereras automatiskt
- Instagram Stories-knapp visas bara om Instagram ar installerat (canOpenURL-check)
- Dolj knappen helt om Instagram saknas
- Bara tva delningsalternativ: Instagram Stories + generell Share Sheet
- Ett enda kortformat for alla kanaler
- Share sheet bifogar invite-lank (apps.sandenskog.se/invite/<token>) i texten
- Forskriva text bifogas, t.ex. "It's 23deg and sunny in Stockholm" + invite-lank
- Texten genereras dynamiskt baserat pa vannens aktuella vader och stad

### Claude's Discretion
- Exakt kortdimensioner och proportioner
- Instagram Stories API-approach (sticker vs bakgrund)
- Vaderillustrationer -- stil och antal kategorier
- ImageRenderer vs UIGraphicsImageRenderer for bildgenerering
- Preview-sheetens layout och knappar
- Animationer i preview-sheeten
- Forskrivna textens exakta formulering och format

### Deferred Ideas (OUT OF SCOPE)
- Me vs You-jamforelsekort -- Phase 18 (CARD-03)
- Daglig digest-kort -- Phase 18 (CARD-05)
- Animerade vaderkort (video/GIF) -- v4+ (CARD-06)
- Snapchat/TikTok-dedikerade delningsknappar -- framtida fas
- Anpassningsbara kort (valj bakgrund, lagg till meddelande) -- framtida iteration
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CARD-01 | User kan generera ett statiskt vaderkort (bild) for en van med vader, stad och avatar | ImageRenderer + SwiftUI WeatherCardView med AvatarView, TemperatureZone, WeatherIconMapper |
| CARD-02 | User kan dela vaderkort via systemets share sheet | ShareLink med Transferable-protocol, bifoga UIImage + text med invite-lank |
| CARD-04 | User kan dela vaderkort direkt till Instagram Stories | UIPasteboard + instagram-stories:// URL scheme, bakgrundsbild-approach |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI ImageRenderer | iOS 16+ | Rendera SwiftUI-vy till UIImage | Apple's officiella API, ingen tredjepart behovs |
| SwiftUI ShareLink | iOS 16+ | Share sheet-integration | Redan anvands pa 3 stallen i kodbasen |
| CoreTransferable | iOS 16+ | Transferable protocol for ShareLink | Apple standard for datadelning |
| UIPasteboard | iOS 2+ | Instagram Stories data-overforing | Enda sattet att dela till Instagram Stories |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UIKit (UIApplication) | iOS 2+ | canOpenURL + open for Instagram | For Instagram Stories URL scheme |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ImageRenderer | UIGraphicsImageRenderer | UIKit-baserad, mer kontroll men kraver UIHostingController-wrapping av SwiftUI-vyer. ImageRenderer ar renare for SwiftUI-projekt |
| ShareLink | UIActivityViewController | UIKit-baserad, kraver UIViewControllerRepresentable wrapper. ShareLink ar redan etablerat monster i kodbasen |

**Recommendation: ImageRenderer** -- renare SwiftUI-integration, tillrackligt for statiska vaderbilder, och hela kodbasen ar SwiftUI-baserad. UIGraphicsImageRenderer behovs bara om ImageRenderer visar sig otillrackligt (osannolikt for detta use case).

## Architecture Patterns

### Recommended Project Structure
```
Features/
  WeatherCard/
    WeatherCardView.swift          # Den delbara kortets SwiftUI-vy
    WeatherCardPreviewSheet.swift  # Preview-sheet med kort + delningsknappar
    WeatherCardRenderer.swift      # ImageRenderer-logik, renderar kort till UIImage
    InstagramStoriesService.swift  # Instagram Stories-delning via UIPasteboard
```

### Pattern 1: WeatherCardView (SwiftUI-vy for kortet)
**What:** En fristaaende SwiftUI-vy som representerar det delbara kortet. Tar emot FriendWeather-data och renderar komplett kort med bakgrund, avatar, vader och branding.
**When to use:** Bade for preview i sheeten OCH for rendering till bild.
**Example:**
```swift
// Source: Projekt-monster (AvatarView, TemperatureZone)
struct WeatherCardView: View {
    let friendWeather: FriendWeather

    private var zone: TemperatureZone {
        TemperatureZone(celsius: friendWeather.temperatureCelsius ?? -99)
    }

    var body: some View {
        ZStack {
            // Bakgrundillustration baserat pa vadertyp
            weatherBackground(for: friendWeather.symbolName)

            VStack(spacing: 0) {
                Spacer()
                // Avatar, namn, stad
                AvatarView(
                    displayName: friendWeather.friend.displayName,
                    temperatureCelsius: friendWeather.temperatureCelsius,
                    size: 80,
                    photoURL: friendWeather.friend.photoURL
                )
                Text(friendWeather.friend.displayName)
                    .font(.bubbleH1)
                Text(friendWeather.friend.city)
                    .font(.bubbleBody)
                // Temperatur + vaderikon
                Text(friendWeather.temperatureFormatted)
                    .font(.bubbleTemperature)
                Text(friendWeather.conditionDescription)
                    .font(.bubbleCaption)
                Spacer()
                // FriendsCast logotyp
                Image("LogoHorizontal")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
        .frame(width: 390, height: 693) // 9:16 ratio
    }
}
```

### Pattern 2: ImageRenderer for Bildgenerering
**What:** Renderar WeatherCardView till UIImage med korrekt skala.
**When to use:** Nar anvandaren vill dela kortet.
**Example:**
```swift
// Source: Apple ImageRenderer docs
@MainActor
func renderCard(friendWeather: FriendWeather) -> UIImage? {
    let renderer = ImageRenderer(content: WeatherCardView(friendWeather: friendWeather))
    renderer.scale = UIScreen.main.scale // 2x eller 3x
    return renderer.uiImage
}
```

### Pattern 3: Instagram Stories Delning
**What:** Kopiera bild till UIPasteboard och oppna Instagram Stories via URL scheme.
**When to use:** Nar anvandaren trycker "Share to Instagram Stories".
**Example:**
```swift
// Source: Instagram developer docs, codakuma.com
@MainActor
class InstagramStoriesService {
    static var canShareToStories: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func shareToStories(image: UIImage) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")"),
              let imageData = image.pngData() else { return }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]
        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300)
        ]

        UIPasteboard.general.setItems([pasteboardItems], options: options)
        UIApplication.shared.open(url)
    }
}
```

### Pattern 4: Swipe Action + Preview Sheet
**What:** Lagg till en andra swipe action pa FriendRowView som oppnar preview-sheet.
**When to use:** Befintlig swipe action for favorit finns redan -- lagg till "Share" pa `.leading` edge.
**Example:**
```swift
// Source: Befintlig FriendListView-monster
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button {
        shareTarget = fw // trigger .sheet
    } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }
    .tint(.bubblePrimary)
}
```

### Anti-Patterns to Avoid
- **Rendera async med ImageRenderer utanfor MainActor:** ImageRenderer maste anvandas pa @MainActor. Forsok att anvanda det i bakgrundstrad orsakar krasch.
- **Anvanda AsyncImage i kort som ska renderas:** AsyncImage laddar bilder asynkront, men ImageRenderer tar en snapshot omedelbart. Om profilbilden inte ar inladdad syns den inte. Forhemta bilden forst eller anvand en redan inladdad UIImage.
- **Harda skalvardet till 1.0:** Ger suddig bild pa Retina-skarmar. Anvand alltid `UIScreen.main.scale`.
- **Skicka invite-lank i bilden:** Kontexten specificerar att lanken ska vara i texten, inte pa kortet.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SwiftUI vy till bild | Custom UIKit rendering pipeline | `ImageRenderer` | Apple's inbyggda losning, hanterar layout korrekt |
| Share sheet | Custom UIActivityViewController wrapper | `ShareLink` | Redan 3 etablerade anvandningar i kodbasen |
| Instagram Stories API | Egen deep link-hantering | UIPasteboard + URL scheme | Enda officiella sattet Instagram stodjer |
| Vadertyp-kategorisering | Egen weatherType enum | Utoka `WeatherIconMapper` | Befintlig mappning av WeatherKit-symboler till kategorier |

**Key insight:** Nastan all infrastruktur finns redan. Det tunga arbetet ar den visuella designen av kortet och vaderillustrationer -- inte den tekniska plumbing:en.

## Common Pitfalls

### Pitfall 1: AsyncImage i Renderad Vy
**What goes wrong:** Profilbilden visas inte pa det delade kortet -- bara fallback-initialer.
**Why it happens:** `ImageRenderer` tar en omedelbar snapshot. `AsyncImage` kan inte ha laddat klart bilden.
**How to avoid:** Forhemta profilbilden till `UIImage` innan rendering, eller anvand en cachad version. Alternativt: acceptera att avatar visar gradient + initialer (enklare, konsekvent).
**Warning signs:** Kort ser bra ut i preview men saknar foto vid delning.

### Pitfall 2: Felaktig Skala ger Suddiga Bilder
**What goes wrong:** Delade bilder ser suddiga/pixliga ut.
**Why it happens:** `ImageRenderer` default-skala ar 1.0, inte skarmens densitet.
**How to avoid:** Satt `renderer.scale = UIScreen.main.scale` (normalt 3.0).
**Warning signs:** Bilder ser bra ut pa enheten men daliga i Instagram/iMessage.

### Pitfall 3: Instagram Stories Knapp Syns men Fungerar Inte
**What goes wrong:** Appen kraschar eller visar ingen story-editor.
**Why it happens:** `LSApplicationQueriesSchemes` saknar `instagram-stories` i Info.plist. `canOpenURL` returnerar alltid false utan ratt plist-konfiguration.
**How to avoid:** Lagg till `instagram-stories` i `LSApplicationQueriesSchemes` i Info.plist. Testa bade med och utan Instagram installerat.
**Warning signs:** Instagram Stories-knappen visas aldrig, aven nar Instagram ar installerat.

### Pitfall 4: Custom Fonts Renderas Inte i ImageRenderer
**What goes wrong:** Baloo 2-fonten ersatts med systemfont i renderade bilder.
**Why it happens:** Font-registrering kan ibland inte finnas tillganglig i rendering-kontexten.
**How to avoid:** Verifiera att fonter ar korrekt registrerade i `UIAppFonts` (redan gjort i Info.plist). Testa bildutdata specifikt.
**Warning signs:** Preview ser bra ut men delad bild har fel typsnitt.

### Pitfall 5: UIPasteboard Overskrider Clipboard
**What goes wrong:** Anvandardata som var kopierad forvinner nar kort delas till Instagram.
**Why it happens:** `UIPasteboard.general.setItems` overskriver befintligt clipboard-innehall.
**How to avoid:** Angepassad `expirationDate` (5 min) sa att clipboard aterstalls. Dokumenterat och forvantad behavior.
**Warning signs:** Anvandare klagar over att kopierad text forsvunnit.

## Code Examples

### Komplett Sharing Text Generator
```swift
// Source: Projekt-monster (InviteService.inviteURL)
func shareText(for friendWeather: FriendWeather, inviteToken: String) -> String {
    let temp = friendWeather.temperatureFormatted
    let condition = friendWeather.conditionDescription
    let city = friendWeather.friend.city
    let inviteURL = "https://apps.sandenskog.se/invite/\(inviteToken)"
    return "It's \(temp) and \(condition.lowercased()) in \(city) \(inviteURL)"
}
```

### ShareLink med Bild + Text
```swift
// Source: Befintlig ShareLink-anvandning i ProfileView.swift
ShareLink(
    item: Image(uiImage: renderedImage),
    subject: Text("Weather in \(friendWeather.friend.city)"),
    message: Text(shareText),
    preview: SharePreview(
        friendWeather.friend.displayName,
        image: Image(uiImage: renderedImage)
    )
) {
    Label("Share", systemImage: "square.and.arrow.up")
}
```

### Instagram canOpenURL Check
```swift
// Source: Instagram developer docs
// Info.plist kraver:
// <key>LSApplicationQueriesSchemes</key>
// <array><string>instagram-stories</string></array>

var canShareToInstagram: Bool {
    guard let url = URL(string: "instagram-stories://share") else { return false }
    return UIApplication.shared.canOpenURL(url)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIGraphicsBeginImageContext | ImageRenderer (SwiftUI) | iOS 16 (2022) | Rent SwiftUI API, ingen UIKit-wrapping |
| UIActivityViewController | ShareLink | iOS 16 (2022) | Deklarativt, redan anvant i kodbasen |
| Document Interaction Controller | UIPasteboard + URL scheme (Instagram) | 2019 | Enda officiella Instagram Stories API |

**Deprecated/outdated:**
- `UIGraphicsBeginImageContext`: Deprecated sedan iOS 17, anvand `ImageRenderer` eller `UIGraphicsImageRenderer`
- Custom URL schemes for delning: Instagram Stories anvander fortfarande URL scheme, men for generell delning anvand `ShareLink`

## Discretion Recommendations

### Kortdimensioner
**Recommendation:** 390x693 pixlar (logisk), 9:16 ratio. Renderat med `scale = 3.0` ger 1170x2079 output -- nara Instagram Stories optimala 1080x1920 men med extra marginal. Alternativt 360x640 logiskt for exakt 1080x1920 vid 3x.

### Instagram Stories: Bakgrundsbild (inte Sticker)
**Recommendation:** Anvand `com.instagram.sharedSticker.backgroundImage` (bakgrundsbild). Kortet ar designat for att ta hela utrymmet och innehaller redan all relevant information. Sticker-approachen skulle lagga kortet som liten overlay pa en tom bakgrund -- inte optimalt for ett "share-worthy" vaderintyg.

### Vaderillustrationer -- Kategorier
**Recommendation:** 7 kategorier, mappade fran WeatherIconMapper:
1. **Clear Day** (sun-clear) -- sol pa klar himmel
2. **Clear Night** (moon-clear, cloud-moon) -- maane/stjarnor
3. **Partly Cloudy** (cloud-sun) -- sol bakom moln
4. **Overcast** (cloud-overcast) -- gratt/moldigt
5. **Rain** (rain, heavy-rain, drizzle) -- regn
6. **Snow** (snow, sleet, hail) -- vinter
7. **Thunderstorm** (thunderstorm) -- askovader

Fog och wind kan mappas till Overcast som fallback.

### Preview-sheet Layout
**Recommendation:** `.sheet` med kortets preview centrerat, darunder tva knappar horisontellt: primartknapp "Share" (Share Sheet) och Instagram-ikon-knapp (Instagram Stories, villkorligt synlig). Enkel, ren layout i linje med appens design.

## Open Questions

1. **Vaderillustrationer -- Grafiska Assets**
   - What we know: CONTEXT.md specificerar "helt nya helskarms vaderillustrationer" -- inte forstorade ikoner
   - What's unclear: Vem skapar dessa? Richard (via designer) eller genereras de programmatiskt?
   - Recommendation: Skapa placeholder-gradients per vadertyp som fungerar som bakgrund. Riktiga illustrationer kan bytas in som assets nar de ar klara. Planera sa att bakgrunden ar en enkel `Image("weather-bg-clear")` som later assets bytas ut.

2. **Profilbild i Avatar pa Kortet**
   - What we know: AvatarView stodjer `photoURL` med AsyncImage
   - What's unclear: Om profilbilden laddas i tid for ImageRenderer snapshot
   - Recommendation: Anvand gradient + initialer (AvatarView utan photoURL) for enkelhet och konsistens. Alternativt forhemta med URLSession och passa in UIImage.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (inget konfigurerat) |
| Config file | none -- see Wave 0 |
| Quick run command | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CARD-01 | Generera vaderkort med vader, stad, avatar | unit | Manual preview verification | No -- Wave 0 |
| CARD-02 | Dela via share sheet | manual-only | Manual -- share sheet kraver anvandardialog | No |
| CARD-04 | Dela till Instagram Stories | manual-only | Manual -- kraver Instagram installerad pa enhet | No |

### Sampling Rate
- **Per task commit:** SwiftUI Preview-verifiering av WeatherCardView
- **Per wave merge:** Manual testning av delningsflode pa enhet/simulator
- **Phase gate:** Manuell testning av bade Share Sheet och Instagram Stories pa riktig enhet

### Wave 0 Gaps
- CARD-01 kan testas med unit test for WeatherCardRenderer (verifiera att UIImage returneras, inte nil)
- CARD-02 och CARD-04 kraver manuell testning (systemets share sheet och Instagram ar externa beroenden)
- Inget testramverk konfigurerat -- behovs for framtida faser men denna fas ar primart visuell/integration

## Sources

### Primary (HIGH confidence)
- [Apple ImageRenderer docs](https://developer.apple.com/documentation/swiftui/imagerenderer) -- API, skala, MainActor-krav
- [Swift with Majid - ImageRenderer](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/) -- Praktiska examples, scale-konfiguration
- [Codakuma - Instagram Stories SwiftUI](https://codakuma.com/instagram-stories-sharing-swiftui/) -- Komplett implementation med pasteboard
- Befintlig kodbas: FriendListView.swift, InviteService.swift, AvatarView.swift, WeatherIconMapper.swift

### Secondary (MEDIUM confidence)
- [Ishan Chhabra - Instagram Stories guide](https://www.ishanchhabra.com/thoughts/sharing-to-instagram-stories) -- Alla pasteboard-nycklar, sticker vs bakgrund
- [Hacking with Swift - ShareLink](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) -- ShareLink + ImageRenderer integration

### Tertiary (LOW confidence)
- Instagram Stories URL scheme dokumentation ar inte officiellt publicerad av Meta -- implementationen bygger pa community-kuggade exempel som fungerar sedan 2019+

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- ImageRenderer, ShareLink och UIPasteboard ar valkanda Apple API:er
- Architecture: HIGH -- Monstret ar rakt fram, alla byggstenar finns i kodbasen
- Pitfalls: HIGH -- Valkanda problem (AsyncImage + rendering, skala, plist)
- Instagram Stories: MEDIUM -- URL scheme ar odokumenterat officiellt men valbeprovat i community

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stabil teknik, inga snabba forandringar forvantade)
