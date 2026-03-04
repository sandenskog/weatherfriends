# Phase 10: Komponenter - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Alla UI-komponenter omformas till Bubble Pop-designsystemet — vänkort, knappar, chattbubblor, stickers, tab-switcher, avatarer och widgets applicerar tokens från fas 9. Inga nya funktioner läggs till, bara visuell uppgradering av befintliga komponenter.

</domain>

<decisions>
## Implementation Decisions

### Vänkort-design
- Gradient-fill avatar: hela avatar-cirkeln fylls med temperaturzon-gradient, initialer i vitt ovanpå
- Weather badge placeras till höger i raden (befintlig layout behålls men stylas om med Bubble Pop-tokens)
- Slide-hover: subtil skala (scale ~1.02) + mjuk skugga vid tryck — professionell känsla
- Kortet renderas som kort med bubbleSurface-bakgrund, rundade hörn och BubblePop-shadow

### Knapp- & bubblestil
- Pill-knappar (Capsule) med brand-gradient (bubblePrimary → bubbleSecondary)
- Bounce-effekt vid tryck — Claude's discretion på exakt scale-nivå
- Egna chattbubblor: chatMine-gradient (FF6B8A → FF8E6B) med asymmetrisk border radius
- Asymmetrisk radius: mjuk variation (alla hörn rundade men olika storlekar, t.ex. 20/20/20/8) för lekfull känsla
- Andras chattbubblor: vit bakgrund med tunn border (bubbleSurface + bubbleBorder strokeBorder)

### Tab-switcher & stickers
- Claude's discretion på om standard-TabView ersätts helt eller får custom pill-header
- Aktiv tab får brand-färgad glow (bubblePrimary) under pill-formen
- Väder-stickers: ljus bakgrund med gradient-accent (vit/ljus bakgrund + gradient-border + gradient-temperaturtext)
- Sticker-info: behåll nuvarande info (stad, temperatur, ikon) — koncist och tydligt

### Avatarer & widgets
- Universell AvatarView-komponent som används konsekvent överallt (vänlista, profil, chatt-header)
- 52pt standardstorlek men konfigurerbar (skalas för olika kontexter)
- Small widget: bakgrund baseras på den visade vännens temperaturzon
- Medium/large widgets: gradient per vän-cell — varje cell får sin temperaturzon-gradient

### Claude's Discretion
- Exakt bounce-scale för knappar (subtil vs tydlig)
- Tab-switcher implementation (ersätt TabView helt eller custom header)
- Exakt shadow-intensitet och spacing på vänkort
- Loading states och edge cases i widget-gradient

</decisions>

<specifics>
## Specific Ideas

- Vänkorten ska kännas som moderna kort med yta och skugga — matcha Bubble Pop-designsystemets varma, sociala känsla
- Chattbubblorna ska ha en lekfull asymmetrisk radius, inte spetsiga hörn
- Widget-gradienterna ska tydligt visa temperaturzoner — varje vän-cell i sin egen zon-färg

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TemperatureZone`: enum med `.color` och `.gradient` per zon — bas för alla gradient-komponenter
- `BubblePopColors`: komplett palette inkl. `chatMineStart/End`, `bubbleSurface/Border`, `bubblePrimary/Secondary`
- `BubblePopTypography`: typsnitt-extensions (Baloo 2 + Inter/SF Pro)
- `BubblePopSpacing`: 8pt spacing-grid
- `BubblePopShadows`: shadow-skala
- `WeatherIconMapper`: custom väderikoner

### Established Patterns
- `FriendRowView` har redan initialer-cirkel och WeatherAnimationView-glöd — behöver gradient-fill och kort-form
- `ChatBubbleView` använder `Color.blue`/`systemGray5` — behöver chatMine-gradient + vit/border
- `WeatherStickerView` har grundlayout — behöver gradient-accent styling
- `MainTabView` är standard SwiftUI TabView — behöver custom pill-switcher
- Widget-vyerna har `initialsCircle` och `temperatureColor` helpers — behöver gradient-bakgrunder

### Integration Points
- `FriendRowView` i `FriendsTabView` — vänkort-omformning
- `ChatBubbleView` i `ChatView` — bubbla-omformning
- `WeatherStickerView` i `ChatBubbleView` — sticker-omformning
- `MainTabView` — tab-switcher
- `WidgetViews.swift` — alla tre widget-storlekar
- Ny `AvatarView` bör ersätta alla `initialsCircle`-implementationer

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-komponenter*
*Context gathered: 2026-03-04*
