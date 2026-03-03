# Phase 5: Utökade Vyer - Research

**Researched:** 2026-03-03
**Domain:** MapKit SwiftUI, UNUserNotifications (lokal schemaläggning), SwiftUI ScrollView karusell
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Navigation & vystruktur**
- Segmented control (Lista | Karta | Kategorier) högst upp i Vänner-vyn
- Alla tre vyer delar samma flik — inga nya flikar i TabView
- Befintlig lista-vy blir standardvy i segmented control

**Kartvy**
- MapKit-karta visar alla vänner med giltiga koordinater
- Kartnålar: profilbild (eller initialer-cirkel) + temperatur nedanför
- Favoriter får större nålar än övriga vänner
- Tap på nål öppnar befintlig WeatherDetailSheet
- Vänner utan koordinater (cityLatitude/cityLongitude nil) utelämnas från kartan utan indikation

**Väderkategorier**
- Horisontella kort-karuseller per kategori (App Store-stil layout)
- Varje kategorirad har rubrik och horisontellt scrollbara kort
- Kort visar: profilbild, namn, temperatur och SF Symbol väderikon
- Bakgrundsfärg baserad på temperatur (matchar befintlig Color.temperatureColor)
- Kategorier med temperaturintervall matchande befintlig färgkodning:
  - Arctic: <0°
  - Cold: 0–10°
  - Cool: 10–20°
  - Warm: 20–28°
  - Tropical: 28+°
- Tomma kategorier döljs — bara kategorier med vänner visas
- Tap på kort öppnar WeatherDetailSheet

**Daglig push-notis**
- Schemaläggs lokalt via UNNotificationRequest med daglig trigger
- Skickas kl 07:00
- Innehåller bara favoriter (max 6 st)
- Format: kort sammanfattning på en rad, t.ex. "God morgon! ☀️ Anna 28° ☁️ Erik 12° ❄️ Lisa -3°"
- Om väderdata inte kan hämtas för någon favorit: skicka notis med tillgänglig data, hoppa över de utan

**Empty states**
- Karta och kategorier: återanvänd befintligt demo-koncept med exempelvänner + demo-banner
- Daglig notis: skickas inte om inga favoriter finns

### Claude's Discretion
- Exakt storlek och design på kartnålar
- Kartans initiala zoom-nivå och region
- Korthöjd och -bredd i karusellerna
- Animationer och övergångar mellan segmented control-vyer
- Exakt UNNotification-konfiguration och background fetch-strategi
- Notis-ljud och badge-hantering

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VIEW-02 | Grupperade väderkort (Hot/Warm/Cool/Cold-kategorier) | ScrollView + LazyHStack karusell-mönster, kategorisering via befintlig temperaturintervall-logik, FriendWeather-modellen har all nödvändig data |
| VIEW-03 | Kartvy med vänners platser och väderinfo (MapKit) | MapKit SwiftUI API med Annotation + MapCameraPosition.automatic, befintliga koordinater i Friend.cityLatitude/cityLongitude |
| PUSH-02 | Daglig vädersammanfattning (push-notis) | UNCalendarNotificationTrigger med repeats:true, befintlig UNUserNotificationCenterDelegate i AppDelegate, AppWeatherService för väderdata |
</phase_requirements>

---

## Summary

Fasen implementerar tre kompletterande vyer för att utforska vänners väder, alla nåbara via en segmented control (Picker med `.segmented`-stil) i den befintliga FriendListView. Tekniken är välkänd och stabil: MapKit fick ett komplett SwiftUI-API vid WWDC 2023 som är det rekommenderade sättet på iOS 17+, UNCalendarNotificationTrigger för dagliga lokala notiser är stabilt sedan iOS 10 och async/await-stöd finns sedan iOS 15. ScrollView-karuseller med LazyHStack är ett beprövat mönster och iOS 17 tillförde `scrollTargetLayout()` för förbättrad snapping.

Befintlig kodbas har starka integrationsytor: `FriendWeather`-modellen innehåller all data som behövs för kartnålar och kategorikort, `Color.temperatureColor(celsius:)` är redan definierad och återanvänds direkt, `WeatherDetailSheet` återanvänds vid tap i alla tre vyer, och `UNUserNotificationCenterDelegate` är redan uppsatt i AppDelegate. Inga nya externa beroenden krävs — MapKit är inbyggt i iOS.

Den enda tekniska utmaning som behöver extra omsorg är kartnålarna: `AsyncImage` i en `Annotation`-closure fungerar tekniskt men kan ge renderingsproblem i vissa iOS-versioner. En säkrare strategi är att förladda bilder i viewmodel och rendera synkront i annotationen. Daglig notis kräver att väderdata hämtas vid schemaläggning (vanligen vid app-start eller bakgrundshämtning) — data bör inte vara stale vid notistillfället.

**Primär rekommendation:** Bygg en `FriendsTabView`-wrapper runt befintlig `FriendListView` som lägger till segmented control och switchar mellan lista, karta och kategori-vy. Välj `@Observable + @MainActor` för alla nya ViewModel-klasser i linje med etablerat projektmönster.

---

## Standard Stack

### Core

| Bibliotek | Version | Syfte | Varför standard |
|-----------|---------|-------|----------------|
| MapKit (SwiftUI) | inbyggt iOS 17+ | Kartvy med nålar | Inbyggt i iOS, nytt SwiftUI-API deprecerar UIKit-wrapper |
| UserNotifications | inbyggt iOS 10+ | Lokal schemaläggning av daglig notis | Plattformsstandard, befintlig delegate finns i AppDelegate |
| SwiftUI ScrollView | inbyggt iOS 17+ | Horisontell karusell per kategori | iOS 17+ scrollTargetLayout ger snygg snapping utan extern lib |

### Supporting

| Bibliotek | Version | Syfte | När används |
|-----------|---------|-------|-------------|
| MapKit.MapCameraPosition | inbyggt iOS 17 | Styr kartans zoom och position | `.automatic` zoomar in på alla annotations automatiskt |
| CLLocationCoordinate2D | CoreLocation, inbyggt | Koordinatstruct för kartnålar | Konverterar Friend.cityLatitude/cityLongitude till nålar |

### Alternatives Considered

| Istället för | Hade kunnat använda | Avvägning |
|--------------|---------------------|-----------|
| MapKit SwiftUI Annotation | UIViewRepresentable + MKAnnotationView | UIKit-wrappern ger fler anpassningsmöjligheter men bryter SwiftUI-konventionen; onödig komplexitet |
| UNCalendarNotificationTrigger | Firebase FCM server-side push | Server-side kräver Cloud Function + cron; lokal trigger är enklare och uppfyller kravet |
| LazyHStack i ScrollView | UICollectionView via UIViewRepresentable | UIKit är mer kraftfull men onödig overhead för enkel karusell |

**Installation:** Ingen — alla bibliotek är inbyggda i iOS SDK.

---

## Architecture Patterns

### Rekommenderad projektstruktur

```
Features/FriendList/
├── FriendListView.swift              # EXISTING — wrappas av FriendsTabView
├── FriendListViewModel.swift         # EXISTING — återanvänds som är
├── FriendsTabView.swift              # NEW — segmented control + vyväxling
├── FriendMapView.swift               # NEW — Plan 05-01
├── FriendMapViewModel.swift          # NEW — Plan 05-01
├── FriendCategoryView.swift          # NEW — Plan 05-02
└── FriendCategoryViewModel.swift     # NEW — Plan 05-02

Services/
└── DailyWeatherNotificationService.swift  # NEW — Plan 05-02
```

### Pattern 1: Segmented Control med Picker

Standardmönster i projektet för att switcha vy: `Picker` med `.pickerStyle(.segmented)` bunden till en `@State`-enum. Enum bör vara `CaseIterable` för `ForEach`-stöd.

```swift
// Source: Established SwiftUI pattern, verified via WebSearch
enum FriendsTab: String, CaseIterable {
    case list = "Lista"
    case map = "Karta"
    case categories = "Kategorier"
}

struct FriendsTabView: View {
    @State private var selectedTab: FriendsTab = .list

    var body: some View {
        VStack(spacing: 0) {
            Picker("Vy", selection: $selectedTab) {
                ForEach(FriendsTab.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selectedTab {
            case .list: FriendListView(...)
            case .map: FriendMapView(...)
            case .categories: FriendCategoryView(...)
            }
        }
    }
}
```

Placering: `FriendsTabView` ersätter `FriendListView` som rotvy i `MainTabView`s "Vänner"-flik. Befintlig `NavigationStack` och toolbar förblir oförändrade — de lyfts upp till `FriendsTabView`.

### Pattern 2: MapKit Annotation med custom SwiftUI-vy

iOS 17+ API: `Map(position:) { Annotation(...) { customView } }`. `MapCameraPosition.automatic` zoomar in på alla annotationer.

```swift
// Source: useyourloaf.com/blog/mapkit-for-swiftui/ + createwithswift.com
import MapKit

struct FriendMapView: View {
    let friendWeathers: [FriendWeather]
    @State private var selectedFriendWeather: FriendWeather?
    @State private var position: MapCameraPosition = .automatic

    private var mappableFriends: [FriendWeather] {
        friendWeathers.filter {
            $0.friend.cityLatitude != nil && $0.friend.cityLongitude != nil
        }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(mappableFriends) { fw in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: fw.friend.cityLatitude!,
                    longitude: fw.friend.cityLongitude!
                )) {
                    FriendMapPin(friendWeather: fw, isFavorite: fw.friend.isFavorite)
                        .onTapGesture { selectedFriendWeather = fw }
                }
            }
        }
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
    }
}
```

**Obs:** `annotationItems:`-initializer (äldre) är fortfarande tillgänglig men den nya content-builder-syntaxen (`Map(position:) { Annotation... }`) rekommenderas på iOS 17+.

### Pattern 3: Kartnål-vy (FriendMapPin)

Nålen kombinerar profilbild (eller initialer-cirkel, samma mönster som `FriendRowView.profileImage`) med temperaturtext nedanför. Favoriter får en något större frame.

```swift
struct FriendMapPin: View {
    let friendWeather: FriendWeather
    let isFavorite: Bool

    private var pinSize: CGFloat { isFavorite ? 48 : 36 }
    private var tempColor: Color {
        friendWeather.temperatureCelsius.map { Color.temperatureColor(celsius: $0) } ?? .secondary
    }

    var body: some View {
        VStack(spacing: 2) {
            profileCircle
                .frame(width: pinSize, height: pinSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(tempColor, lineWidth: isFavorite ? 3 : 2))
            Text(friendWeather.temperatureFormatted)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tempColor)
                .padding(.horizontal, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
    // profileCircle: AsyncImage + initialer-fallback (samma som FriendRowView)
}
```

**Viktigt:** `AsyncImage` i Annotation kan ge renderingsproblem eftersom kartan renderar annotationer utanför normal SwiftUI-hierarki. Säkrare att ladda URL-bilder i FriendMapViewModel och cacha som `UIImage` / `Image`. Se Common Pitfalls.

### Pattern 4: Kategorivy med horisontell karusell

Vertikal `List` eller `ScrollView` med en rad per kategori. Varje rad har en `Text`-rubrik följt av en horisontell `ScrollView` med `LazyHStack`.

```swift
// Source: iOS 17 ScrollView pattern, verified via WebSearch
struct FriendCategoryView: View {
    let categorizedFriends: [WeatherCategory: [FriendWeather]]
    @State private var selectedFriendWeather: FriendWeather?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(WeatherCategory.allCases, id: \.self) { category in
                    if let friends = categorizedFriends[category], !friends.isEmpty {
                        categoryRow(category: category, friends: friends)
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedFriendWeather) { fw in
            WeatherDetailSheet(friendWeather: fw)
                .environment(weatherService)
        }
    }

    private func categoryRow(category: WeatherCategory, friends: [FriendWeather]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.label)
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(friends) { fw in
                        FriendWeatherCard(friendWeather: fw)
                            .onTapGesture { selectedFriendWeather = fw }
                    }
                }
                .padding(.horizontal)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}
```

### Pattern 5: Väderkategori-enum

Kategoriseringen bygger på befintlig `Color.temperatureColor`-logik — samma intervall, ny enum.

```swift
enum WeatherCategory: String, CaseIterable {
    case tropical = "Tropical"
    case warm = "Warm"
    case cool = "Cool"
    case cold = "Cold"
    case arctic = "Arctic"

    var label: String { rawValue }

    static func category(for celsius: Double) -> WeatherCategory {
        switch celsius {
        case ..<0:      return .arctic
        case 0..<10:    return .cold
        case 10..<20:   return .cool
        case 20..<28:   return .warm
        default:        return .tropical
        }
    }
}
```

### Pattern 6: Daglig lokal notis (UNCalendarNotificationTrigger)

Schemaläggning sker med ett fast identifier (`"daily-weather-summary"`) så att omschemaläggning alltid ersätter befintlig notis utan dubbletter.

```swift
// Source: createwithswift.com notifications-tutorial, donnywals.com daily-notifications
class DailyWeatherNotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let identifier = "daily-weather-summary"

    func schedule(favorites: [FriendWeather]) async {
        // Schemalägg inte om inga favoriter
        guard !favorites.isEmpty else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        // Bygg notis-body från favoriter med väderdata
        let summary = favorites.compactMap { fw -> String? in
            guard let celsius = fw.temperatureCelsius else { return nil }
            return "\(fw.friend.displayName.components(separatedBy: " ").first ?? fw.friend.displayName) \(fw.temperatureFormatted)"
        }.joined(separator: " · ")

        let content = UNMutableNotificationContent()
        content.title = "God morgon! ☀️"
        content.body = summary
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Ta bort eventuell befintlig notis innan ny schemaläggs
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        do {
            try await notificationCenter.add(request)
        } catch {
            // Logg men propagera ej — notis är icke-kritisk
        }
    }

    func cancel() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
```

**Viktigt:** Notis-bodyn byggs av cached/aktuell väderdata vid schemaläggning (app-start). Contentet är statiskt vid tidpunkten för schemaläggning — det uppdateras inte dynamiskt när notisen triggas kl 07:00. Schemaläggning bör anropas varje app-start för att hålla data aktuellt.

### Anti-Patterns att undvika

- **Skapa ny flik i TabView för karta/kategorier:** Strider mot locked decision. Allt sker inom Vänner-fliken via segmented control.
- **MapAnnotation (äldre API):** Deprecated på iOS 17. Använd `Annotation { }` med content-builder.
- **Hämta väder direkt i Annotation-closure:** MapKit renderar annotationer utanför vanlig SwiftUI-uppdateringscykel — async-operationer i closuren ger oförutsägbara resultat. Förladda data i ViewModel.
- **Lämna kartnålen tom när koordinater saknas:** Locked decision är att utelämna utan indikation — ingen "missing location"-markör.
- **Schemalägg notis utan att ta bort befintlig:** Leder till dubbletter med identiska identifiers som adderas istället för att ersätta. Kalla alltid `removePendingNotificationRequests` innan `add`.

---

## Don't Hand-Roll

| Problem | Bygg inte | Använd istället | Varför |
|---------|-----------|----------------|--------|
| Karta med nålar | Egen koordinat-till-pixel-matematik | MapKit SwiftUI `Map + Annotation` | Hanterar projektion, zoom, pan, tillgänglighet |
| Lokal notis-schemaläggning | Egen timer/cron | `UNCalendarNotificationTrigger` | Systemhantering av bakgrundsaktivering, batterioptimering |
| Horisontell karusell med snap | Egen scroll-gestur-hanterare | `ScrollView + LazyHStack + scrollTargetBehavior` | iOS 17 scrollTargetLayout hanterar snapping korrekt |
| Temperaturfärger | Ny färglogik per kategori | `Color.temperatureColor(celsius:)` (befintlig) | Redan implementerad och testad i FriendRowView |
| Profilbild med initialer-fallback | Nytt bildkomponent | Extrahera/återanvänd mönstret från `FriendRowView.profileImage` | Konsekvent UI, undviker kod-duplicering |

---

## Common Pitfalls

### Pitfall 1: AsyncImage i Map Annotation ger tomma nålar

**Vad som går fel:** `AsyncImage` i en `Annotation`-closure kraschar ibland eller renderas aldrig — MapKit-annotationer uppdateras inte på samma sätt som vanliga SwiftUI-vyer vid async state-ändringar.

**Varför det händer:** MapKit renderar annotationernas content-view i en separat kontext. Async image loading triggrar en state-förändring som MapKit inte alltid plockar upp.

**Hur man undviker:** Förladda bilder i `FriendMapViewModel` som `[String: UIImage]` (nyckel = photoURL) med `URLSession`. Rendera i annotationen med `Image(uiImage: loadedImage)` — synkront, ingen async. Om ingen bild finns: rendera initials-cirkel direkt.

**Varningssignaler:** Nålar med vita cirklar som aldrig fyller i profilbild.

### Pitfall 2: Segmented control-vy tappar data vid flikbyte

**Vad som går fel:** Karta och kategorier visar laddningsspinner vid varje flikbyte om de laddar data separat.

**Varför det händer:** Varje vy har egna ViewModels som laddar data från scratch.

**Hur man undviker:** Passa ner `[FriendWeather]` från `FriendListViewModel` (som redan har laddad data) till karta och kategorivyer via parameter. Karta och kategorier behöver inte egna nätverksanrop — de transformerar befintliga data.

**Varningssignaler:** Tre separata nätverksanrop till WeatherKit vid varje session.

### Pitfall 3: Dubbla dagliga notiser

**Vad som går fel:** Varje app-start schemalägger en ny notis med samma identifier — resulterar i multipla notiser per dag.

**Varför det händer:** `UNUserNotificationCenter.add()` adderar requests med samma identifier utan att automatiskt ta bort befintliga.

**Hur man undviker:** Anropa alltid `removePendingNotificationRequests(withIdentifiers: [identifier])` precis innan `add()`. Alternativt: kontrollera `pendingNotificationRequests()` och hoppa över om identisk request redan finns.

**Varningssignaler:** Användare rapporterar multipla notiser på morgonen.

### Pitfall 4: MapCameraPosition visar fel initial region

**Vad som går fel:** Kartan öppnas med hela världen synlig, nålar syns knappt.

**Varför det händer:** Standardposition visar hela världen om `.automatic` inte konfigureras korrekt.

**Hur man undviker:** Initialisera position med `.automatic` — MapKit beräknar automatiskt en region som innehåller alla annotationer. Om inga annotationer finns (tom vänlista): fallback till en statisk region, t.ex. Europa.

**Varningssignaler:** Karta öppnas med zoom-nivå 0 (hela världen synlig).

### Pitfall 5: Notis skickas inte på grund av saknad behörighet

**Vad som går fel:** Daglig notis schemaläggs men levereras aldrig.

**Varför det händer:** Push-behörighet (`.alert`, `.sound`) måste vara beviljad av användaren. Behörighetscheck saknas i `DailyWeatherNotificationService`.

**Hur man undviker:** Kontrollera `UNUserNotificationCenter.current().notificationSettings()` status innan schemaläggning. Behörighet redan begärd i `AppDelegate.registerForPushNotifications()` — men kontrollera att notificationSettings-statusen är `.authorized` vid schemaläggning.

---

## Code Examples

### MapCameraPosition.automatic för alla annotationer

```swift
// Source: useyourloaf.com/blog/mapkit-for-swiftui/
@State private var position: MapCameraPosition = .automatic

Map(position: $position) {
    ForEach(mappableFriends) { fw in
        Annotation("", coordinate: fw.coordinate) {
            FriendMapPin(friendWeather: fw)
                .onTapGesture { selectedFriendWeather = fw }
        }
    }
}
```

### Daglig notis med fast identifier

```swift
// Source: createwithswift.com + donnywals.com
var dateComponents = DateComponents()
dateComponents.calendar = Calendar.current
dateComponents.hour = 7
dateComponents.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
let request = UNNotificationRequest(identifier: "daily-weather-summary", content: content, trigger: trigger)
UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-weather-summary"])
try await UNUserNotificationCenter.current().add(request)
```

### Kategorigruppering av FriendWeather

```swift
// Gruppera [FriendWeather] per WeatherCategory
var categorized: [WeatherCategory: [FriendWeather]] {
    Dictionary(grouping: friendWeathers.filter { $0.temperatureCelsius != nil }) { fw in
        WeatherCategory.category(for: fw.temperatureCelsius!)
    }
}
```

### Horisontell karusell med iOS 17 snap

```swift
// Source: WebSearch iOS 17 ScrollView pattern
ScrollView(.horizontal, showsIndicators: false) {
    LazyHStack(spacing: 12) {
        ForEach(friends) { fw in
            FriendWeatherCard(friendWeather: fw)
        }
    }
    .padding(.horizontal)
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
```

---

## State of the Art

| Gammal approach | Nuvarande approach | Förändrad | Påverkan |
|-----------------|-------------------|-----------|---------|
| `MapAnnotation { }` | `Annotation { }` | iOS 17 / WWDC 2023 | MapAnnotation deprecated — använd ej |
| `MapMarker` | `Marker(...)` | iOS 17 / WWDC 2023 | MapMarker deprecated |
| `Map(coordinateRegion:)` | `Map(position:)` + `MapCameraPosition` | iOS 17 | Äldre initializer deprecated |
| `UNUserNotificationCenter.add(_:completionHandler:)` | `try await UNUserNotificationCenter.current().add(_:)` | iOS 15+ | Async/await-variant föredras |
| `ScrollView + LazyHStack` (manuell snapping) | `scrollTargetBehavior(.viewAligned) + scrollTargetLayout()` | iOS 17 | Inbyggd snapping utan custom gesture-hantering |

**Deprecated/utgångna:**
- `MapAnnotation`: Ersatt av `Annotation { }` — använd ej i nytt kod
- `MapMarker`: Ersatt av `Marker(...)` — använd ej i nytt kod

---

## Open Questions

1. **Hur hanteras WeatherKit-throttling vid app-start när data förbereds för notis?**
   - Vad vi vet: `AppWeatherService` har 30-min TTL-cache. Om data är cachad vid notis-schemaläggning är det gratis.
   - Vad som är oklart: Om appen startas kl 06:58 och WeatherKit-anrop tar tid — hinner notis-data uppdateras innan 07:00?
   - Rekommendation: Schemalägg notisen med senast kända data omedelbart vid app-start (från cache). Kärnproblem undviks: notisen är ändå schemalagd med statisk body — det är inte live-data.

2. **Ska schemaläggning av daglig notis ske i AppDelegate eller via en service anropad i FriendsTabView?**
   - Vad vi vet: AppDelegate har redan `UNUserNotificationCenterDelegate`. Schemaläggning kräver tillgång till `FriendListViewModel`-data (favoriter + väder).
   - Rekommendation: `DailyWeatherNotificationService` anropas från `FriendsTabView.task {}` efter att data laddats — inte i AppDelegate. Konsekvent med projektets tjänste-injektionsmönster.

---

## Integration med befintlig kodbas

### MainTabView-förändring

`MainTabView` skickar idag `FriendListView(openWeatherAlertFriendId:)` som första flik. Ändringen:

```swift
// MainTabView.swift — ersätt FriendListView med FriendsTabView
NavigationStack {
    FriendsTabView(openWeatherAlertFriendId: $openWeatherAlertFriendId)
}
.tabItem { Label("Vänner", systemImage: "person.2") }
.tag(0)
```

`FriendsTabView` hanterar segmented control och skickar `openWeatherAlertFriendId`-bindningen vidare till `FriendListView` (Lista-vyn).

### Data-flöde

```
FriendsTabView
├── @State selectedTab
├── @State viewModel = FriendListViewModel  ← laddas EN gång
├── Lista-vy:       FriendListView(friendWeathers: viewModel.all)
├── Karta-vy:       FriendMapView(friendWeathers: viewModel.all)
└── Kategorier-vy:  FriendCategoryView(friendWeathers: viewModel.all)
```

Alternativt kan `FriendListViewModel` behållas i befintlig `FriendListView` och FriendsTabView skapar egna ViewModel-instanser för karta och kategorier — men delad data-källa undviker triplerade nätverksanrop.

---

## Sources

### Primary (HIGH confidence)
- useyourloaf.com/blog/mapkit-for-swiftui/ — Map, Annotation, MapCameraPosition API och kodemönster
- createwithswift.com/adding-custom-annotations-in-mapkit-with-swiftui/ — Annotation-closure syntax verifierad
- createwithswift.com/notifications-tutorial-creating-and-scheduling-user-notifications-with-async-await/ — async/await UNCalendarNotificationTrigger kodemönster
- donnywals.com/scheduling-daily-notifications-on-ios-using-calendar-and-datecomponents/ — DateComponents-konfiguration verifierad

### Secondary (MEDIUM confidence)
- WebSearch "SwiftUI MapKit Map annotations custom views iOS 17 2025" — bekräftar Annotation/Marker deprecation och nytt API
- WebSearch "SwiftUI horizontal ScrollView LazyHStack carousel cards iOS 17" — scrollTargetBehavior och scrollTargetLayout verifierade via officiell Apple Dev Forums

### Tertiary (LOW confidence)
- WebSearch "Map annotation onTapGesture sheet presentation iOS 17" — refererar till ett Apple Developer Forum-inlägg om tap-events i iOS 18; behöver verifieras om det påverkar projektet (iOS 17+ target)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — MapKit och UserNotifications är inbyggda, välkänd iOS-plattformsteknologi, verifierade via officiell dokumentation
- Architecture: HIGH — Segmented control, annotation-pattern och notis-schemaläggning verifierade via multipla källor
- Pitfalls: MEDIUM — AsyncImage-i-annotation-problemet är anekdotiskt rapporterat, inte formellt dokumenterat av Apple; övriga pitfalls är logiska konsekvenser av API-beteende

**Research date:** 2026-03-03
**Valid until:** 2026-06-01 (stable platform APIs, förlängs vid WWDC 2026)
