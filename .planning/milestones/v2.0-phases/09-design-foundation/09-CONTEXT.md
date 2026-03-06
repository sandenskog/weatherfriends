# Phase 9: Design Foundation - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Komplett visuellt fundament — Bubble Pop färgpalett, Baloo 2 typsnitt, spacing-grid, shadows och alla grafiska assets (14 väderikoner, app-ikon, logotyp, 2 empty state-illustrationer) registrerade och tillgängliga som SwiftUI-extensions och asset catalog-resurser. Fas 10 bygger komponenter med dessa tokens.

</domain>

<decisions>
## Implementation Decisions

### Färgtoken-strategi
- Gradient per temperaturzon (tvåfärgs-gradient för avatarer, widgets, bakgrunder) — inte bara solid färg
- Använd design-specen (ui-spec-and-components.html) rakt av — alla brand-färger, UI-färger och semantiska färger implementeras exakt som specificerat
- SwiftUI Color-extensions (ej Asset Catalog ColorSets) — Color.bubblePrimary, Color.tempTropical etc.
- Temperaturzoner: Tropical (#FF6B6B), Warm (#FFB347), Cool (#6BCB77), Cold (#6B9FE8), Arctic (#4A6CF7)
- Brand: Primary (#FF6B8A), Secondary (#FF8E6B), Accent (#FFD93D)
- UI: bg (#F0F4FF), surface (#FFFFFF), border (#E8ECF4), text-primary (#2D3142), text-secondary (#8892A8)
- Chat: Mine = gradient (primary → secondary), Other = vit med border
- Semantic: success (#6BCB77), warning (#FFB347), error (#FF6B6B), favorite (#FF6B8A)

### Typografi-integration
- Baloo 2 för rubriker (H1–H3), knappar, temperaturvärden och tab-labels — fullt ut enligt spec
- SF Pro (system-font) för brödtext och captions — Inter bundlas INTE
- Mappa till SwiftUI Dynamic Type-storlekar (.largeTitle, .title2, .body) för tillgänglighet — ej pixelperfekta storlekar
- Baloo 2 laddas ner som TTF och bundlas i Xcode-projektet (Google Fonts, OFL-licens)

### Asset-pipeline
- SVG direkt i Assets.xcassets — ingen konvertering till PDF eller PNG
- 14 väderikoner från Design/friendscast-design-pack/svg-icons/ → asset catalog
- Central WeatherIcon-enum/helper som mappar WeatherKit-symbolnamn till custom assets — alla vyer använder detta istället för Image(systemName:)
- App-ikon: SVG → 1024x1024 PNG utan alfakanal — samma ikon för app och widget
- Horisontell logotyp: SVG → asset catalog
- 2 empty state-illustrationer (no-friends, no-chat): SVG → asset catalog

### Spacing & shadows
- CGFloat-konstanter i Spacing-enum: xs=4, sm=8, md=16, lg=24, xl=32 (8pt grid)
- Border radius-skala: CornerRadius.sm=12, md=20, lg=28, xl=50, round=9999
- Shadow-skala: sm, md, lg, glow-primary, glow-accent — som SwiftUI ViewModifiers
- Shadows definieras exakt enligt spec

### Claude's Discretion
- Migrering av befintliga vyer: Claude avgör om fas 9 byter ut hårdkodade färger/fonts/spacing i befintliga vyer eller om det görs i fas 10
- Glow-shadows: Claude väljer om glow ska vara temperaturzon-medveten eller använda fasta brand-färger
- Logotyp-placering: Claude avgör var horisontell logotyp visas (login, onboarding eller båda)
- Exakt organisation av SwiftUI-extensions (en fil vs flera filer, namespace-strategi)

</decisions>

<specifics>
## Specific Ideas

- Design-paketet finns komplett i `Design/friendscast-design-pack/` med HTML-spec, SVG-ikoner och SVG-UI-assets
- Befintlig Color.temperatureColor(celsius:) i FriendRowView.swift ska ersättas med det nya token-systemet
- Appen har redan WeatherAnimationView med kodade animationer — dessa rörs inte i fas 9
- Widget-target (HotAndColdFriendsWidget) behöver också tillgång till färg- och spacing-tokens

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Design/friendscast-design-pack/svg-icons/`: 14 SVG väderikoner (sun-clear, cloud-sun, rain, snow etc.)
- `Design/friendscast-design-pack/svg-ui/`: app-icon.svg, logo-horizontal.svg, empty-state-no-chat.svg, empty-state-no-friends.svg
- `Design/friendscast-design-pack/specs/ui-spec-and-components.html`: Komplett design-spec med alla tokens

### Established Patterns
- Färger: Hårdkodade Color(red:green:blue:) och Color(.systemGray*) — inga centrala tokens
- Typografi: Standard SwiftUI .font(.body), .font(.title3) — ingen custom font
- Layout: .padding(.vertical, 4), .frame(width: 40, height: 40) — inga spacing-konstanter
- Väderikoner: Image(systemName: symbolName) via WeatherKit SF Symbols

### Integration Points
- `FriendRowView.swift`: Color.temperatureColor(celsius:) — central färg-extension att ersätta
- `WeatherAnimationView.swift`: Väderanimationer — refererar ej till färgsystem, oberoende
- `Assets.xcassets`: Bara AppIcon idag — ska expanderas med alla SVG-assets
- Widget-target: Delar modeller men har egen Info.plist — behöver tillgång till tokens
- `project.pbxproj`: Font-filer måste registreras här + Info.plist UIAppFonts

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-design-foundation*
*Context gathered: 2026-03-04*
