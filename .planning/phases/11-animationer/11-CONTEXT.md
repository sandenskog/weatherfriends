# Phase 11: Animationer - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementera spring-animationer som ger appen liv: hjart-pop, konfetti vid ny van, sticker-bounce, tab-glow, staggerad listanimation, custom pull-to-refresh och en central Reduce Motion-fallback. Alla animationer faller tillbaka till crossfade for anvandare med Reduce Motion aktiverat.

</domain>

<decisions>
## Implementation Decisions

### Animationskaensla
- Lekfull pop genomgaende — tydliga overshoots, studsiga spring-animationer. Matchar Bubble Pop-temat (Duolingo/Headspace-kaensla)
- Befintlig BubblePopButton spring (.spring response: 0.25, dampingFraction: 0.6) aer referenspunkten for hela appens animationsspraak

### Hjaert-favorit animation
- Stor pop: shrink till 0.6x -> overshoot till 1.3x -> settle till 1.0x
- Snabb spring-animation, klar feedback — ska kaennas belaenande (Instagram/Twitter-referens)
- Ingen partikeleffekt, bara scale-animation

### Sticker-bounce i chatt
- Bounce-in underfran: fade + slide upp fran ~20pt -> overshoot uppat -> settle
- Duration ~0.4s med spring-damping
- Kaenns som att stickern "poppar upp" i konversationen

### Tab-switch
- Behaell befintlig matchedGeometryEffect + spring i FriendsTabView
- Laegg till subtil glow-shadow pa aktiv tab som foeljer med pill-markern
- Inget extra pa innehallet (lista/karta/kategorier)

### Konfetti
- Triggas ENBART nar en ny vaen laeggs till (manuellt eller kontaktimport)
- Kort burst: 1.5-2 sekunder, snabb explosion som daempas
- Faerger: vaennens temperaturzon-gradient (Tropical = orange/gult, Arctic = blatt/lila etc.)
- Partiklar: mix av former — cirklar, rektanglar OCH smaa vaederikoner (sol, snoeflinga, droppe)
- Ska inte blockera interaktion — overlay som tonar ut

### Listanimationer
- Sortering: staggered slide med 50ms delay per rad (vaag-effekt uppifran och ner)
- Ny vaen i listan: slide + fade fran hoeger med spring-overshoot
- 10 rader tar 0.5s att starta alla — responsivt men synligt staggerat

### Pull-to-refresh
- Custom moln-animation: ett litet moln som drar ner, "regnar" under laddning, foersvinner nar klart
- Ersaetter standard iOS .refreshable-spinner
- Vaedertematiskt och on-brand

### Reduce Motion
- Crossfade everywhere: alla spring/bounce/slide-animationer ersaetts med enkel crossfade (opacity 0->1, ~0.25s)
- Central MotionReducer ViewModifier/wrapper som alla animerade vyer anvaender — konsekvens pa ett staelle
- Konfetti doeljs helt med Reduce Motion (ingen ersaettning)
- WeatherAnimationView migreras till centrala modifieren (istaellet foer egen reduceMotion-check)

### Claude's Discretion
- Exakta spring-parametrar (response, dampingFraction) foer varje animation
- Konfettipartikelantal och spridningsmonster
- Moln-animationens exakta visuella design
- Implementationsdetaljer foer MotionReducer-modifieren

</decisions>

<specifics>
## Specific Ideas

- Hjaert-pop inspirerad av Instagram/Twitter like-animation — tydlig shrink-overshoot-settle
- Konfetti ska kaennas personlig genom att anvaenda vaennens temperaturzon-faerger
- Konfettipartiklar med vaederikoner (sol, snoeflinga, droppe) blandat med geometriska former — unikt foer appen
- Pull-to-refresh moln som "regnar" aer en on-brand vaederreferens
- Tab-glow foeljer pill-markern — foerstaerker den befintliga matchedGeometryEffect

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- BubblePopButton: Redan har spring-animation (.spring response: 0.25, dampingFraction: 0.6) — referens foer animationsspraak
- WeatherAnimationView: Partikelanimation (regn/snoe) med TimelineView — kan informera konfetti-implementation
- TemperatureZone: 5 zoner med gradient-faerger — anvaends foer konfettifaerger
- Custom vaederikoner i Assets.xcassets: sol, snoeflinga, droppe etc. — anvaends som konfettipartiklar

### Established Patterns
- matchedGeometryEffect + @Namespace i FriendsTabView foer tab-switch
- .refreshable pa FriendListView foer pull-to-refresh
- @Environment(\.accessibilityReduceMotion) i WeatherAnimationView — enda staellet idag
- DragGesture(minimumDistance:0) + simultaneousGesture foer tryckkansla i BubblePopButton

### Integration Points
- FriendRowView: hjaert-favorit toggle — laeg till pop-animation haer
- FriendListView: .refreshable — ersaett med custom moln-animation
- FriendsTabView: tab-switch — laeg till glow-shadow
- ChatBubbleView/WeatherStickerView: sticker — laeg till bounce-in
- Kontaktimport-floedet: trigger konfetti nar van skapas

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-animationer*
*Context gathered: 2026-03-06*
