# Phase 5: Utökade Vyer - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Appen erbjuder tre komplementära sätt att utforska vänners väder — kartvy, grupperade kort och daglig sammanfattning. Alla tre vyer samlas under befintlig Vänner-flik via en segmented control (Lista | Karta | Kategorier).

</domain>

<decisions>
## Implementation Decisions

### Navigation & vystruktur
- Segmented control (Lista | Karta | Kategorier) högst upp i Vänner-vyn
- Alla tre vyer delar samma flik — inga nya flikar i TabView
- Befintlig lista-vy blir standardvy i segmented control

### Kartvy
- MapKit-karta visar alla vänner med giltiga koordinater
- Kartnålar: profilbild (eller initialer-cirkel) + temperatur nedanför
- Favoriter får större nålar än övriga vänner
- Tap på nål öppnar befintlig WeatherDetailSheet
- Vänner utan koordinater (cityLatitude/cityLongitude nil) utelämnas från kartan utan indikation

### Väderkategorier
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

### Daglig push-notis
- Schemaläggs lokalt via UNNotificationRequest med daglig trigger
- Skickas kl 07:00
- Innehåller bara favoriter (max 6 st)
- Format: kort sammanfattning på en rad, t.ex. "God morgon! ☀️ Anna 28° ☁️ Erik 12° ❄️ Lisa -3°"
- Om väderdata inte kan hämtas för någon favorit: skicka notis med tillgänglig data, hoppa över de utan

### Empty states
- Karta och kategorier: återanvänd befintligt demo-koncept med exempelvänner + demo-banner
- Daglig notis: skickas inte om inga favoriter finns

### Claude's Discretion
- Exakt storlek och design på kartnålar
- Kartans initiala zoom-nivå och region
- Korthöjd och -bredd i karusellerna
- Animationer och övergångar mellan segmented control-vyer
- Exakt UNNotification-konfiguration och background fetch-strategi
- Notis-ljud och badge-hantering

</decisions>

<specifics>
## Specific Ideas

- Segmented control-approach håller navigationen kompakt — inga nya flikar
- Karusell-layouten ska ge en känsla liknande App Store med tydliga kategorisektioner
- Konsekvent tap-beteende: WeatherDetailSheet öppnas överallt (lista, karta, kategorier)
- Favoriter lyfts fram på kartan med större nålar — motiverar att använda favorit-funktionen

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FriendWeather`: Modell med temperaturCelsius, temperatureFormatted, symbolName — perfekt för kartnålar och kategorikort
- `Color.temperatureColor(celsius:)`: Befintlig temperaturfärgkodning i FriendRowView — återanvänd för kartnålar och kort
- `WeatherDetailSheet`: Komplett väderdetaljvy med timprognos och dagsprognos — återanvänds vid tap
- `FriendListViewModel`: Laddar vänner med väder parallellt via TaskGroup — kan utökas eller återanvändas
- `AppWeatherService`: WeatherKit-wrapper med cache — används för att hämta väder till notis
- `FriendRowView.profileImage`: AsyncImage + initialer-fallback — mönstret kan återanvändas i kartnålar

### Established Patterns
- `@Observable` + `@MainActor` för ViewModels (FriendListViewModel-mönster)
- `@Environment` för service-injection (AuthManager, AppWeatherService, FriendService)
- `.sheet(item:)` för att visa detaljer
- `.listStyle(.insetGrouped)` för listor
- Firebase FCM redan uppsatt i AppDelegate med token-hantering
- UNUserNotificationCenterDelegate redan implementerad i AppDelegate

### Integration Points
- `MainTabView`: Segmented control läggs till i FriendListView (eller en wrapper-vy)
- `FriendListView`: Befintlig vy som blir en av vyerna i segmented control
- `AppDelegate`: Push-notis-registrering redan på plats — daglig lokal notis kopplas in här
- `Friend.cityLatitude/cityLongitude`: Koordinater för kartnålar
- `Friend.isFavorite`: Styr vilka som inkluderas i daglig notis och får större nålar

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-utokade-vyer*
*Context gathered: 2026-03-03*
