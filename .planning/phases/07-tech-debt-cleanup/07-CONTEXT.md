# Phase 7: Tech Debt Cleanup - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminera ackumulerad tech debt identifierad av milestone audit — DI-brott, dead code removal och dokumentationsfix. Alla ändringar är exakt specificerade i success criteria.

</domain>

<decisions>
## Implementation Decisions

### DI-fixar
- ConversationListView ska använda `@Environment` FriendService istället för throwaway-instans
- ConversationListViewModel ska ta emot UserService via parameter-injection (skapar idag egen `UserService()` på rad 14)

### Dead code
- Debug-print i FriendListViewModel.swift ska bort (kan redan vara fixad — verifieras vid execution)
- `from(friendWeather:)` i WidgetFriendEntry+AppExtension.swift ska bort

### Dokumentation
- 05-02-SUMMARY.md ska inkludera VIEW-02 och PUSH-02 i frontmatter (redan fixat — verifieras)

### Claude's Discretion
- Hela implementationen — alla ändringar är exakt specificerade, inga designval behövs

</decisions>

<specifics>
## Specific Ideas

No specific requirements — alla ändringar är exakt definierade i success criteria.

</specifics>

<code_context>
## Existing Code Insights

### Filer att ändra
- `HotAndColdFriends/Features/Chat/ConversationListView.swift`: Saknar `@Environment(FriendService.self)`, viewModel skapas med `@State`
- `HotAndColdFriends/Features/Chat/ConversationListViewModel.swift`: Rad 14 `private var userService = UserService()` — ska injiceras
- `HotAndColdFriends/Models/WidgetFriendEntry+AppExtension.swift`: Innehåller `from(friendWeather:)` dead code
- `.planning/phases/05-utokade-vyer/05-02-SUMMARY.md`: VIEW-02 och PUSH-02 redan i frontmatter

### Established Patterns
- Appen använder `@Environment` för DI av services (ChatService, AuthManager, AppWeatherService redan i ConversationListView)
- ViewModels skapas med `@State` och `@Observable` macro

### Integration Points
- FriendService finns redan som `@Environment`-objekt i andra vyer

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-tech-debt-cleanup*
*Context gathered: 2026-03-04*
