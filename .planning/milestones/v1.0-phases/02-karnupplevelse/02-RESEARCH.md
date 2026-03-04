# Phase 02: Kärnupplevelse - Research

**Researched:** 2026-03-02
**Domain:** Apple WeatherKit, SwiftUI List/Sections, MVVM @Observable, Demo-data, Onboarding extension
**Confidence:** HIGH (WeatherKit API-mönster verifierade via officiell dok och Kodeco-tutorial; SwiftUI-mönster verifierade via Hacking with Swift och Apple officiell dok)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Väderkortens design**
- Kompakta rader i listan: profilbild, namn, stad, temperatur + väderikon
- Minimal info i listvy — temperatur och ikon räcker
- Tap på rad öppnar expanderad vädervy som sheet (prognos, vind, fuktighet etc.)
- Temperaturtext färgkodad: röd/orange för varmt, blå för kallt — gradient baserat på temperatur

**Demo-upplevelsen (first run)**
- 8–10 fiktiva vänner med internationell mix av städer (Tokyo, Kapstaden, New York, Sydney, Stockholm etc.)
- Riktigt väder hämtas för demo-vännernas städer via WeatherKit
- Transparent markering — tydlig "Exempeldata"-indikator så användaren vet att det inte är riktiga vänner
- Manuell borttagning via en "Ta bort exempeldata"-knapp — användaren bestämmer själv
- Demo-data visas som fallback om användaren hoppar över favorit-steget i onboarding

**Favoriter & sortering**
- Separat sektion "Favoriter" överst i listan med egen rubrik
- Övriga vänner listas under i en andra sektion
- Båda sektionerna sorteras varmast → kallast (temperatursortering genomgående)
- Swipe på rad för att lägga till/ta bort som favorit (iOS-standardgest)
- Max 6 favoriter — vid försök att lägga till 7:e visas meddelande: "Du har redan 6 favoriter. Ta bort en för att lägga till en ny."

**Onboarding för favoriter**
- Eget steg i befintlig onboarding-wizard (efter namn/foto/stad)
- Namn + stad-autocomplete per vän (återanvänder befintlig LocationService med MKLocalSearchCompleter)
- Valfritt steg — "Hoppa över"-knapp tillgänglig (demo-data visas istället)
- Valfritt antal vänner att lägga till, de 6 första blir automatiskt favoriter

### Claude's Discretion
- Exakt färgskala för temperaturfärgkodning (gradient-intervall)
- Design av den expanderade vädervyn (sheet-layout, vilken detaljinfo som visas)
- Demo-vännernas namn och exakta städer
- Loading states och skeletons
- Väder-ikonval (SF Symbols eller anpassade)
- Swipe-action-design (färg, ikon, animation)
- "Ta bort exempeldata"-knappens placering och design

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WTHR-01 | Realtidsväder visas per vän (temperatur, ikon, vind, fuktighet, prognos) | WeatherKit CurrentWeather ger temperature (Measurement<UnitTemperature>), symbolName, wind.speed, humidity, condition. Hourly/daily forecast för sheet-vy. |
| WTHR-02 | Animerade väderillustrationer bakom vännens profilbild | Notis: REQUIREMENTS.md mappar WTHR-02 till Phase 6, INTE Phase 2. Ska EJ implementeras i denna fas. |
| WTHR-03 | Väderdata uppdateras automatiskt med caching | Actor-baserad cache med TTL-dictionary. WeatherKit anropas asynkront; 30-min TTL implementeras i WeatherService-lagret. |
| VIEW-01 | Vädersorterad listvy (varmast/kallast) | SwiftUI List med Section (favoriter/övriga), sorterad med .sorted(by:) på temperature.value. |
| VIEW-04 | Live exempeldata vid first run innan användaren konfigurerat | DemoFriendService med hårdkodade FriendWeather-objekt. Koordinater för demo-städer hårdkodas — WeatherKit anropas med riktiga koordinater. |
| FRND-04 | Användare uppmanas ange stad/land för favoriter vid onboarding | Nytt steg (steg 4 av 4) i OnboardingView — återanvänder LocationService och OnboardingLocationView-mönster. |
| FRND-05 | Användare kan välja 6 favoriter som visas överst | FavoriteService (eller FriendService) i Firestore med max-6-logik. swipeActions på List-rader. |

**Notering om WTHR-02:** Traceability-tabellen i REQUIREMENTS.md mappar WTHR-02 (animerade illustrationer) till Phase 6. Planerna för fas 2 (02-01, 02-02, 02-03) nämner "DemoWeatherService" och "animerad illustration" i rubrikform — men phasens Success Criteria nämner inte animerade illustrationer. Forskningen rekommenderar att WTHR-02 INTE implementeras i fas 2 och att "animerad illustration" i planrubrikerna tolkas som SF Symbol-ikon (symbolName) roterad/tonad, inte riktig animation.
</phase_requirements>

---

## Summary

Fas 2 handlar om tre sammanhängande delar: (1) en WeatherService som hämtar data från Apple WeatherKit med TTL-cache, (2) en vädersorterad listvy med sektioner och swipe-favorit-hantering, och (3) ett utökat onboarding-flöde med valfritt vän-steg plus demo-data för first run.

WeatherKit är ett Apple-systemramverk (inte SPM-paket) som kräver aktivering i Apple Developer Portal och en entitlements-fil i projektet. Ramverket erbjuder `WeatherService.shared.weather(for:including:)` med async/await-stöd och returnerar välstrukturerad data via `CurrentWeather` — inklusive `temperature` (Measurement<UnitTemperature>), `symbolName` (direkt kompatibelt med SF Symbols), `condition`, `humidity` och `wind`. WeatherKit kräver att `WeatherAttribution` visas i appen (Apple Weather-logotyp + legal-länk).

Projektets etablerade mönster (@Observable + @MainActor + async/await + .task{}) är fullt kompatibelt med WeatherKit-integrationen och ska återanvändas genomgående. Onboardingflödet utökas från 3 till 4 steg genom att lägga till ett valfritt steg i befintlig `OnboardingView` — TabView-strukturen stöder detta utan arkitekturella ändringar.

**Primary recommendation:** Bygg WeatherService som en `@Observable @MainActor class` med en Actor-baserad TTL-cache. Följa exakt samma mönster som befintlig UserService. Lägg WeatherKit-entitlements i en separat `.entitlements`-fil och referera den i project.yml via `entitlements: path:`.

---

## Standard Stack

### Core
| Bibliotek | Version | Syfte | Varför standard |
|-----------|---------|-------|-----------------|
| WeatherKit | System (iOS 16+) | Hämta väderdata från Apple | Gratis 500K anrop/mån, ingen API-nyckel, inbyggt i iOS |
| SwiftUI List + Section | System (iOS 17+) | Vädersorterad listvy med favoriter/övriga | Native iOS-pattern, bäst prestanda och tillgänglighet |
| Swift Concurrency (async/await) | Inbyggt Swift | Asynkrona WeatherKit-anrop | Används redan genomgående i projektet |

### Supporting
| Bibliotek | Version | Syfte | När används |
|-----------|---------|-------|-------------|
| CoreLocation (CLLocation) | System | Skapa plats-objekt för WeatherKit-anrop | Krävs av WeatherKit API — tar latitude/longitude |
| Foundation (Measurement<UnitTemperature>) | System | Temperaturvärde och enhetkonvertering | WeatherKit returnerar Measurement — konvertera med .converted(to: .celsius) |
| SwiftUI swipeActions | System (iOS 15+) | Swipe-åtgärd för favorit-hantering | iOS-standardgest enligt beslut |
| SwiftUI AsyncImage | System | Ladda WeatherAttribution-logotyp | Krävs för Apple Weather attribution |

### Alternatives Considered
| Istället för | Kunde använt | Tradeoff |
|--------------|--------------|----------|
| WeatherKit (system) | Open-Meteo REST API | Open-Meteo är gratis utan konto, men saknar Apple-symbol-mappning, kräver manuell nyckelhantering och ger sämre iOS-integration |
| Actor + Dictionary TTL-cache | NSCache | NSCache evictar under minnespress men har ingen TTL. Dictionary i Actor ger explicit 30-min TTL och full kontroll |
| SwiftUI List+Section | LazyVStack | List ger automatisk swipeActions och iOS-standardbeteende; LazyVStack är mer manuell och saknar inbyggd swipe |

**Installation:** Ingen — WeatherKit är ett Apple-systemramverk. Lägg till capability i Xcode/portal, skapa entitlements-fil.

---

## Architecture Patterns

### Recommended Project Structure

```
HotAndColdFriends/
├── Models/
│   ├── AppUser.swift              (befintlig)
│   ├── Friend.swift               (ny — vän med stad/koordinater, isFavorite, isDemo)
│   └── FriendWeather.swift        (ny — Friend + CurrentWeather sammanslagna för listvy)
├── Services/
│   ├── UserService.swift          (befintlig)
│   ├── LocationService.swift      (befintlig, återanvänds i onboarding-steg 4)
│   ├── WeatherService.swift       (ny — WeatherKit + TTL-cache)
│   ├── FriendService.swift        (ny — Firestore CRUD för Friend-modellen)
│   └── DemoFriendService.swift    (ny — hårdkodade demo-vänner med riktiga koordinater)
├── Features/
│   ├── FriendList/
│   │   ├── FriendListView.swift       (ny — huvud-listvy)
│   │   ├── FriendListViewModel.swift  (ny — @Observable, sortering, favorit-logik)
│   │   ├── FriendRowView.swift        (ny — kompakt rad: foto, namn, stad, temp, ikon)
│   │   └── WeatherDetailSheet.swift   (ny — expanderad vädervy i sheet)
│   └── Onboarding/
│       ├── OnboardingView.swift           (modifierad — utökas med steg 4)
│       ├── OnboardingViewModel.swift      (modifierad — favorit-vänner läggs till state)
│       ├── OnboardingFavoritesView.swift  (ny — steg 4: lägg till vänner med stad)
│       └── ... (befintliga steg 1-3 oförändrade)
└── Core/
    └── Navigation/
        └── AppRouter.swift   (modifierad — MainTabView ersätts med FriendListView)
```

### Pattern 1: WeatherService med TTL-cache (Actor)

**What:** En `@Observable @MainActor class` hanterar WeatherKit-anrop externt. En intern `actor WeatherCache` håller en dictionary med tidsstämplar för 30-min TTL.
**When to use:** Varje gång väder behövs för en koordinat — returnerar cachad data om < 30 min gammal.

```swift
// Source: Kodeco WeatherKit tutorial + Swift Forums caching pattern
import WeatherKit
import CoreLocation

actor WeatherCache {
    private struct CachedEntry {
        let weather: CurrentWeather
        let cachedAt: Date
    }
    private var store: [String: CachedEntry] = [:]
    private let ttl: TimeInterval = 30 * 60  // 30 minuter

    func get(key: String) -> CurrentWeather? {
        guard let entry = store[key],
              Date().timeIntervalSince(entry.cachedAt) < ttl else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.weather
    }

    func set(key: String, weather: CurrentWeather) {
        store[key] = CachedEntry(weather: weather, cachedAt: Date())
    }
}

@Observable
@MainActor
class WeatherService {
    static let shared = WeatherService()
    private let service = WKWeatherService.shared  // WeatherKit: WeatherService.shared
    private let cache = WeatherCache()

    func currentWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        let key = "\(latitude.rounded(toPlaces: 3)),\(longitude.rounded(toPlaces: 3))"
        if let cached = await cache.get(key: key) {
            return cached
        }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await service.weather(for: location, including: .current)
        await cache.set(key: key, weather: weather)
        return weather
    }

    /// Hämtar attribution (krävs av Apple WeatherKit-villkor)
    var attribution: WeatherAttribution {
        get async throws {
            try await WeatherService.shared.attribution
        }
    }
}
```

**Obs:** `WeatherService` i WeatherKit-ramverket heter faktiskt `WeatherService` — undvik namnkollision med projektets service-klass. Namnge projektets klass `AppWeatherService` eller `FriendWeatherService` för tydlighet.

### Pattern 2: FriendListViewModel med @Observable

**What:** ViewModel hanterar hämtning av alla vänners väderdata parallellt, sorterar och exponerar två listor (favoriter, övriga).
**When to use:** FriendListView — laddas med `.task{}` vid mount.

```swift
// Source: Established project pattern (UserService, ProfileViewModel) + Swift concurrency
@Observable
@MainActor
class FriendListViewModel {
    var favorites: [FriendWeather] = []
    var others: [FriendWeather] = []
    var isLoading = false
    var errorMessage: String?
    var showDemoBanner = false

    func load(friends: [Friend], weatherService: AppWeatherService) async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Parallell hämtning med TaskGroup
            var results: [FriendWeather] = []
            try await withThrowingTaskGroup(of: FriendWeather?.self) { group in
                for friend in friends {
                    group.addTask {
                        guard let lat = friend.cityLatitude,
                              let lon = friend.cityLongitude else { return nil }
                        let weather = try await weatherService.currentWeather(latitude: lat, longitude: lon)
                        return FriendWeather(friend: friend, weather: weather)
                    }
                }
                for try await result in group {
                    if let fw = result { results.append(fw) }
                }
            }
            let sorted = results.sorted { $0.temperatureCelsius > $1.temperatureCelsius }
            favorites = sorted.filter { $0.friend.isFavorite }
            others = sorted.filter { !$0.friend.isFavorite }
            showDemoBanner = friends.contains { $0.isDemo }
        } catch {
            errorMessage = "Kunde inte hämta väderdata: \(error.localizedDescription)"
        }
    }
}
```

### Pattern 3: SwiftUI List med Section och swipeActions

**What:** Standardmönster för tvåsektionslista med swipe-åtgärd för favorit-hantering.
**When to use:** FriendListView — direkt implementation.

```swift
// Source: Apple official SwiftUI docs + Hacking with Swift swipeActions tutorial
List {
    if !viewModel.favorites.isEmpty {
        Section("Favoriter") {
            ForEach(viewModel.favorites) { fw in
                FriendRowView(friendWeather: fw)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            viewModel.removeFavorite(fw.friend)
                        } label: {
                            Label("Ta bort favorit", systemImage: "star.slash")
                        }
                        .tint(.orange)
                    }
            }
        }
    }

    Section(viewModel.favorites.isEmpty ? "Vänner" : "Övriga") {
        ForEach(viewModel.others) { fw in
            FriendRowView(friendWeather: fw)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        viewModel.addFavorite(fw.friend)
                    } label: {
                        Label("Favorit", systemImage: "star")
                    }
                    .tint(.yellow)
                }
        }
    }
}
```

### Pattern 4: Temperaturfärgkodning

**What:** Beräkna färg från temperaturvärde — Claude's Discretion, men ett väldefinierat intervall rekommenderas.
**Recommendation:** Använd en linjär interpolation från blå (< 0°C) via neutral (15°C) till röd (> 30°C).

```swift
// Source: Claude's recommendation — ingen extern biblioteksdependency
extension Color {
    static func temperatureColor(celsius: Double) -> Color {
        switch celsius {
        case ..<0:       return Color(red: 0.2, green: 0.4, blue: 1.0)   // isblå
        case 0..<10:     return Color(red: 0.4, green: 0.6, blue: 0.9)   // kylig blå
        case 10..<20:    return Color(red: 0.5, green: 0.7, blue: 0.5)   // neutral grön
        case 20..<28:    return Color(red: 1.0, green: 0.6, blue: 0.2)   // varm orange
        default:         return Color(red: 0.9, green: 0.2, blue: 0.2)   // het röd
        }
    }
}
```

### Pattern 5: DemoFriendService

**What:** Levererar hårdkodade demo-vänner med riktiga koordinater. WeatherKit anropas med dessa koordinater för att hämta levande väder — aldrig mock-data.
**When to use:** Om `friends.isEmpty` i FriendListViewModel — visa demo-vänner istället.

```swift
// Source: Project design decision (CONTEXT.md)
struct DemoFriendService {
    static let demoFriends: [Friend] = [
        Friend(id: "demo-1", displayName: "Yuki Tanaka", city: "Tokyo, Japan",
               cityLatitude: 35.6762, cityLongitude: 139.6503, isFavorite: true, isDemo: true),
        Friend(id: "demo-2", displayName: "Amara Nkosi", city: "Kapstaden, Sydafrika",
               cityLatitude: -33.9249, cityLongitude: 18.4241, isFavorite: true, isDemo: true),
        Friend(id: "demo-3", displayName: "Emma Sullivan", city: "New York, USA",
               cityLatitude: 40.7128, cityLongitude: -74.0060, isFavorite: true, isDemo: true),
        Friend(id: "demo-4", displayName: "Oliver Chen", city: "Sydney, Australien",
               cityLatitude: -33.8688, cityLongitude: 151.2093, isFavorite: false, isDemo: true),
        Friend(id: "demo-5", displayName: "Fatima Al-Rashid", city: "Dubai, UAE",
               cityLatitude: 25.2048, cityLongitude: 55.2708, isFavorite: false, isDemo: true),
        Friend(id: "demo-6", displayName: "Lars Eriksson", city: "Stockholm, Sverige",
               cityLatitude: 59.3293, cityLongitude: 18.0686, isFavorite: false, isDemo: true),
        Friend(id: "demo-7", displayName: "Marie Dubois", city: "Paris, Frankrike",
               cityLatitude: 48.8566, cityLongitude: 2.3522, isFavorite: false, isDemo: true),
        Friend(id: "demo-8", displayName: "Carlos Mendez", city: "Buenos Aires, Argentina",
               cityLatitude: -34.6037, cityLongitude: -58.3816, isFavorite: false, isDemo: true),
    ]
}
```

### Anti-Patterns to Avoid

- **Anropa WeatherKit i View-body direkt:** Aldrig `await WeatherService.shared.weather(...)` direkt i en SwiftUI-vy. Alltid via ViewModel och `.task{}`.
- **Caching i NSCache utan TTL:** NSCache evictar slumpmässigt under minnespress — explicit TTL i Actor-dictionary är mer förutsägbart för 30-min-krav.
- **WeatherService som global singleton utan cache:** Varje List-scroll kan trigga nya API-anrop. Cache är obligatorisk för att inte nå 500K-gränsen.
- **Ignorera WeatherAttribution:** Apple kräver att `WeatherAttribution.combinedMarkLightURL` (eller Dark) visas med en länk till `WeatherAttribution.legalPageURL`. Saknas detta kan appen refuseras i App Store-granskning.
- **Temperatur utan enhetomvandling:** WeatherKit returnerar `Measurement<UnitTemperature>` — använd `.converted(to: .celsius).value` för att alltid få Celsius som beslutats.
- **nonisolated-problem i Actor:** Om WeatherCache definieras som `actor` kan den inte nås direkt från `@MainActor class` utan `await`. Alla anrop till cache måste vara `await cache.get(...)`.

---

## Don't Hand-Roll

| Problem | Bygg INTE | Använd istället | Varför |
|---------|-----------|-----------------|--------|
| Väder-API med plats | Egen REST-klient mot Open-Meteo/OpenWeather | WeatherKit (system) | Inget API-nyckelhantering, gratis 500K/mån, SF Symbol-mappning inbyggd |
| SF Symbol-mappning för väder | Custom icon-mapper | `symbolName` från `CurrentWeather` | WeatherKit returnerar rätt SF Symbol direkt, inkl. dag/natt-variant |
| Temperaturformatering | Manuell string-interpolation | `Measurement<UnitTemperature>.formatted(.measurement(width: .narrow))` | Hanterar lokalisering, enheter, avrundning korrekt |
| Platsautocompletion för vän-onboarding | Ny implementation | Befintlig `LocationService` med `MKLocalSearchCompleter` | Återanvänds direkt — sparar implementation av ett helt flöde |

---

## Common Pitfalls

### Pitfall 1: WeatherKit-entitlements aktiverade i portalen men inte i Xcode

**What goes wrong:** Appen kompilerar men kaschar med `WeatherDaemonError` eller returnerar ingen data vid första körning.
**Why it happens:** WeatherKit kräver BÅDE aktivering i Apple Developer Portal (App Services → WeatherKit) och en `.entitlements`-fil med `com.apple.developer.weatherkit = YES` i Xcode-projektet.
**How to avoid:** Skapa `HotAndColdFriends/Resources/HotAndColdFriends.entitlements` och lägg till referens i `project.yml`. Vänta 30 minuter efter portalaktivering innan test.
**Warning signs:** Fel `"WeatherKit is not enabled for this app ID"` eller `"The WeatherKit service isn't available"`.

```yaml
# project.yml tillägg
targets:
  HotAndColdFriends:
    entitlements:
      path: HotAndColdFriends/Resources/HotAndColdFriends.entitlements
      properties:
        com.apple.developer.weatherkit: true
```

```xml
<!-- HotAndColdFriends.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.weatherkit</key>
    <true/>
</dict>
</plist>
```

### Pitfall 2: Namnkollision mellan WeatherKit.WeatherService och projektets service-klass

**What goes wrong:** Kompileringsfel `"ambiguous use of 'WeatherService'"` om projektets service-klass heter samma som WeatherKit-ramverkets klass.
**Why it happens:** WeatherKit exporterar `WeatherService` — om man skapar en `class WeatherService` i projektet kolliderar namnen.
**How to avoid:** Döp projektets service-klass till `AppWeatherService` eller `FriendWeatherService` och referera WeatherKit-klassen explicit via `WeatherKit.WeatherService.shared`.

### Pitfall 3: Parallella WeatherKit-anrop utan throttling

**What goes wrong:** Om 8-10 demo-vänner laddas simultant utan cache kan det trigga rate-limiting eller fördröja UI-render märkbart.
**Why it happens:** `withThrowingTaskGroup` startar alla Task:ar direkt och WeatherKit hanterar inte intern köning synligt.
**How to avoid:** TTL-cachen löser upprepade anrop. Visa skeleton/loading-state under initial laddning. Begränsa TaskGroup till maximalt 5 parallella anrop vid behov med en Semaphore-actor om problem uppstår.

### Pitfall 4: Onboarding-steg-räknare är hårdkodad till 3

**What goes wrong:** `OnboardingView.stepTitles` och progress-bar-logiken är hårdkodad till 3 steg (`ForEach(0..<3)`). Att lägga till steg 4 kräver att BÅDA uppdateras.
**Why it happens:** Befintlig implementation har `let stepTitles = ["Ditt namn", "Profilbild", "Din stad"]` och `ForEach(0..<3)` i progress-bar.
**How to avoid:** Refaktorera `stepTitles` till att styra loop-count: `ForEach(0..<stepTitles.count)`. Uppdatera "Steg X av Y"-text och TabView-taggar (nu 0, 1, 2, 3).

### Pitfall 5: Demo-data syns kvar efter att användaren lagt till riktiga vänner

**What goes wrong:** Om `isDemo: true`-vänner lagras i Firestore och blandas med riktiga vänner visas de i listan trots att användaren har riktiga vänner.
**Why it happens:** Demo-data skrivs aldrig till Firestore — de hålls enbart i minnet. Men om session-state inte hanteras korrekt kan demo-data visas trots att riktiga vänner finns.
**How to avoid:** `FriendListViewModel.load()` kontrollerar Firestore-vänner FÖRST. Om `friends.isEmpty` används `DemoFriendService.demoFriends`. Demo-vänner skrivs ALDRIG till Firestore. "Ta bort exempeldata"-knappen sätter ett UserDefaults-flag `hideDemoData = true`.

### Pitfall 6: WeatherAttribution saknas → App Store-avvisning

**What goes wrong:** Apple kan avvisa appen om Weather-logotyp och legal-länk inte visas.
**Why it happens:** WeatherKit-villkoren kräver att `WeatherAttribution` visas i appen.
**How to avoid:** Hämta `attribution` via `WeatherKit.WeatherService.shared.attribution` (async). Visa `AsyncImage(url: attribution.combinedMarkLightURL)` och en `Link("Juridisk information", destination: attribution.legalPageURL)` i FriendListView (t.ex. i footer av List eller i Settings-vy).

---

## Code Examples

Verified patterns från officiella sources:

### WeatherKit — Hämta aktuellt väder

```swift
// Source: Kodeco WeatherKit Tutorial (verified), Apple documentation
import WeatherKit
import CoreLocation

let location = CLLocation(latitude: 59.3293, longitude: 18.0686)  // Stockholm
let weather = try await WeatherKit.WeatherService.shared.weather(
    for: location,
    including: .current
)

// Tillgängliga fält på CurrentWeather:
let tempCelsius = weather.temperature.converted(to: .celsius).value   // Double
let condition   = weather.condition          // WeatherCondition enum
let symbolName  = weather.symbolName         // String — direkt SF Symbol-namn
let humidity    = weather.humidity           // Double 0–1, multiplicera med 100 för %
let windSpeed   = weather.wind.speed.value   // Double (m/s eller mph beroende på locale)
let windDir     = weather.wind.compassDirection  // Wind.CompassDirection enum
let uvIndex     = weather.uvIndex.value      // Int
let feelsLike   = weather.apparentTemperature.converted(to: .celsius).value
```

### WeatherKit — Hämta nuläge + prognos i ett anrop

```swift
// Source: Kodeco WeatherKit Tutorial (verified)
let (current, hourly, daily) = try await WeatherKit.WeatherService.shared.weather(
    for: location,
    including: .current, .hourlyForecast, .dailyForecast
)
// current: CurrentWeather
// hourly: Forecast<HourWeather>
// daily: Forecast<DayWeather>
```

### WeatherKit — Temperaturformatering

```swift
// Source: Apple Developer Forum (verified)
let temp = weather.temperature.converted(to: .celsius)
let formatted = temp.formatted(.measurement(width: .narrow))  // t.ex. "7°"

// Eller enbart värdet som Double:
let celsius = temp.value  // 7.3
```

### WeatherKit — Attribution

```swift
// Source: Apple documentation (WeatherAttribution)
let attribution = try await WeatherKit.WeatherService.shared.attribution

// I SwiftUI:
AsyncImage(url: attribution.combinedMarkLightURL)  // för ljus bakgrund
    .frame(height: 20)
Link("Väderdata", destination: attribution.legalPageURL)
    .font(.caption)
    .foregroundStyle(.secondary)
```

### SwiftUI swipeActions för favoriter

```swift
// Source: Apple official SwiftUI documentation + Hacking with Swift (verified)
FriendRowView(friendWeather: fw)
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        Button {
            Task { await viewModel.toggleFavorite(fw.friend) }
        } label: {
            Label("Favorit", systemImage: fw.friend.isFavorite ? "star.slash" : "star")
        }
        .tint(fw.friend.isFavorite ? .orange : .yellow)
    }
```

### OnboardingView — Utöka från 3 till 4 steg

```swift
// Modifiering av befintlig OnboardingView.swift
// Nuläge: stepTitles.count == 3, ForEach(0..<3)
// Ändra till:
private let stepTitles = ["Ditt namn", "Profilbild", "Din stad", "Dina vänner"]

// Progress-bar (nuvar: ForEach(0..<3)) → ForEach(0..<stepTitles.count)
// Steg-räknare: "Steg \(viewModel.currentStep + 1) av \(stepTitles.count)"

// Nytt steg i TabView (tag: 3):
OnboardingFavoritesView(friends: $viewModel.favoriteFriends)
    .tag(3)
```

---

## State of the Art

| Gammalt mönster | Nuläge (2025) | Ändrat | Påverkan |
|-----------------|---------------|--------|----------|
| `@StateObject` + `ObservableObject` | `@Observable` + `@State private var vm` | iOS 17/WWDC23 | Projektet använder redan @Observable — konsekvent |
| `@Published` på varje property | Alla stored properties observerbara automatiskt | iOS 17 | Inga @Published behövs i nya services |
| `WeatherService` (tredje-part) | Apple WeatherKit (native) | WWDC22 | WeatherKit är korrekt val — beslutat |
| `CLLocationManager` delegate | `CLLocationUpdate.liveUpdates()` async stream | iOS 17 | Projektet använder redan iOS 17-mönstret |

**Deprecated/outdated:**
- `@EnvironmentObject`: Ersatt av `.environment()` + `@Observable` i projektet — använd INTE `@EnvironmentObject`
- Separat `FirebaseFirestoreSwift`-paket: Inbyggt i `FirebaseFirestore` från SDK 11.x (dokumenterat i STATE.md)

---

## Open Questions

1. **WeatherKit aktivering i Developer Portal**
   - What we know: WeatherKit kräver manuell aktivering i portalen och 30 min väntetid.
   - What's unclear: Om aktivering redan gjorts för App ID `se.sandenskog.hotandcoldfriends`.
   - Recommendation: Verifiera i portalen INNAN implementation påbörjas. Om ej aktiverat — gör det genast (det tar tid).

2. **Friend-modellens Firestore-struktur**
   - What we know: `AppUser` finns i `users/{uid}`. Favorit-vänner behöver lagras i Firestore.
   - What's unclear: Ska vänner lagras som subcollection `users/{uid}/friends/{friendId}` eller som top-level collection `friends/{friendId}`?
   - Recommendation: Subcollection `users/{uid}/friends/{friendId}` — enklare Firestore security rules och logiskt kopplat till ägaren. En `Friend`-struct med `displayName`, `city`, `cityLatitude`, `cityLongitude`, `isFavorite`, `isDemo: false`.

3. **Autorefresh-mekanism**
   - What we know: Kravet är automatisk uppdatering med 30-min caching.
   - What's unclear: Ska refresh triggas via en Timer i ViewModel eller via pull-to-refresh?
   - Recommendation: `.refreshable{}` för pull-to-refresh (användarkontrollerat) + automatisk refresh via `.task(id: refreshToken)` med en Timer som invaliderar cachen var 30:e minut. Undvik bakgrundsapp-fetch i fas 2.

4. **Entitlements-fil och DEVELOPMENT_TEAM i project.yml**
   - What we know: `project.yml` har `DEVELOPMENT_TEAM: ""` (tom). WeatherKit-signerning kräver ett Development Team.
   - What's unclear: Om Richard behöver sätta Development Team för att köra WeatherKit i simulator/device.
   - Recommendation: WeatherKit fungerar INTE i simulator — det kräver ett riktigt Apple Developer-konto och device. Richard måste sätta `DEVELOPMENT_TEAM` i project.yml eller direkt i Xcode för att testa WeatherKit.

---

## Sources

### Primary (HIGH confidence)
- Kodeco WeatherKit Tutorial (https://www.kodeco.com/41376031-weatherkit-tutorial-getting-started) — verifierade WeatherService API, CurrentWeather-fält, entitlements-setup
- Apple Developer: WeatherKit Get Started (https://developer.apple.com/weatherkit/) — 500K/mån-gräns, systemramverk, capability-krav
- Apple Developer: WeatherAttribution docs (https://developer.apple.com/documentation/weatherkit/weatherattribution) — attribution-krav, URL-properties
- Hacking with Swift: swipeActions (https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-custom-swipe-action-buttons-to-a-list-row) — verifierat swipeActions API
- XcodeGen fixture project.yml (https://github.com/yonaskolb/XcodeGen/blob/master/Tests/Fixtures/TestProject/project.yml) — verifierat entitlements-syntax

### Secondary (MEDIUM confidence)
- WebSearch-resultat om WeatherKit temperature Measurement<UnitTemperature> — verifierat mot Apple forum-posts
- Swift Forums: Structured caching in an actor (https://forums.swift.org/t/structured-caching-in-an-actor/65501) — actor-cache-mönster, stöds av Swift Concurrency-dokumentation

### Tertiary (LOW confidence)
- WebSearch om temperaturfärgkodning — inga officiella riktlinjer finns, rekommenderat intervall baseras på allmän UX-praxis

---

## Metadata

**Confidence breakdown:**
- Standard stack (WeatherKit): HIGH — officiell Apple dok + Kodeco-tutorial
- Architecture (@Observable + Actor cache): HIGH — projektets egna etablerade mönster + Swift Forums
- WeatherKit API-fält: HIGH — verifierat i Kodeco tutorial från officiell source
- Entitlements/xcodegen-syntax: MEDIUM — verifierat i XcodeGen fixtures, men WeatherKit-specifik kombination ej testad
- Pitfalls (namnkollision, attribution): MEDIUM — härledd från dokumentation + developer forum-posts
- Temperaturfärgkodning: LOW — ingen officiell standard, Claude's Discretion

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (stabilt API — WeatherKit, SwiftUI List, Swift Concurrency ändras sällan)
