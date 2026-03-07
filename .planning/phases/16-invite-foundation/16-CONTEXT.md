# Phase 16: Invite Foundation - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Invite-länkar fungerar överallt där länkar kan delas och leder nya användare hela vägen till appen och vänskapen. Omfattar: Universal Links (HTTPS), web fallback-sida, persistenta invite-koder, och deferred deep link för ej installerade användare. Celebration-animation (INVT-05) tillhör Phase 18.

</domain>

<decisions>
## Implementation Decisions

### Domän & URL-format
- Universal Links på `apps.sandenskog.se` (redan konfigurerad med reverse proxy + SSL på Synology)
- URL-format: `apps.sandenskog.se/invite/<token>`
- Bara token i URL — inbjudarens namn visas via dynamiska OpenGraph-meta-tags istället
- Associated Domains entitlement behöver läggas till (saknas idag)

### Web fallback-sida
- Visar inbjudarens namn + stad + app-branding ("Richard från Stockholm bjuder in dig till FriendsCast")
- Dynamiska OpenGraph-meta-tags per invite-token för snygga link previews i iMessage/WhatsApp
- Clipboard-copy av invite-token innan redirect till App Store (för deferred deep link)
- Plattformsdetektering: iOS får App Store-knapp, Android/desktop ser "FriendsCast finns bara för iPhone just nu"
- Implementeras som ny /invite route i befintliga apps.sandenskog.se-appen

### Invite-kodens livscykel
- En permanent invite-kod per användare (skapas vid account creation)
- Invite-dokument raderas INTE efter redemption — behålls med redeemed-lista (array av UIDs som använt koden)
- Koden är tillgänglig på tre ställen: Profilvyn (befintlig), AddFriendSheet (ny), dedicated share-knapp i header (ny)
- Befintlig InviteService.swift refaktoreras: ta bort delete-on-redeem, lägg till redeemed-array, ändra URL-schema från `hotandcold://` till HTTPS Universal Link

### Deferred deep link-strategi
- Web fallback-sidan kopierar invite-token till clipboard innan App Store-redirect
- Appen kollar clipboard vid första start efter installation (iOS paste-banner sedan iOS 16)
- Auto-redeem direkt efter signup-completion (profil skapad)
- Kort toast/banner-bekräftelse: "Du är nu vän med [namn]!" — inte blockerande
- Sparad invite-token giltig i 7 dagar (ignorera äldre clipboard-data)

### Claude's Discretion
- AASA-filens exakta konfiguration (apple-app-site-association)
- Web fallback-sidans visuella design och layout
- Clipboard-detekteringslogik och edge cases
- Migrering av befintliga invite-dokument till ny persistent modell
- Toast/banner-komponentens implementation

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `InviteService.swift`: Befintlig service med token-creation (12-char UUID prefix), Firestore lookup och redemption. Behöver refaktoreras för persistent koder men grundstrukturen finns.
- `InviteDocument`: Codable struct med senderUid, senderDisplayName, senderCity, createdAt. Behöver utökas med redeemed-array.
- `ProfileView.swift`: Redan har ShareLink-integration med invite-URL. Behöver uppdateras till permanent kod + HTTPS URL.
- `HotAndColdFriendsApp.swift`: `onOpenURL` handler finns redan för custom scheme — behöver utökas med Universal Links-hantering.

### Established Patterns
- `@Observable` + `@MainActor` services injicerade via `.environment()` i app root
- Firestore som datastore med Codable structs
- `@ServerTimestamp` för automatiska tidsstämplar
- SwiftUI `ShareLink` för delning

### Integration Points
- `HotAndColdFriends.entitlements`: Behöver `com.apple.developer.associated-domains` med `applinks:apps.sandenskog.se`
- `HotAndColdFriendsApp.swift`: onOpenURL-handler behöver hantera HTTPS Universal Links
- `AddFriendSheet.swift`: Ny invite-länk-knapp
- `apps.sandenskog.se` web-app: Ny /invite/<token> route med server-side Firestore-lookup
- Onboarding/signup-flöde: Clipboard-check + auto-redeem hook

</code_context>

<specifics>
## Specific Ideas

- Fallback-sidan ska kännas som en del av appen — varm, social känsla med app-branding (inte generisk)
- Link preview i iMessage ska vara personlig: "[Namn] bjuder in dig till FriendsCast" med app-ikon
- Share-knapp i header ska vara lättillgänglig — viralitet kräver minimal friktion

</specifics>

<deferred>
## Deferred Ideas

- Invite celebration med Bubble Pop-animation — Phase 18 (INVT-05)
- Mejl-signup för Android-användare som besöker fallback-sidan — framtida fas
- Invite-statistik ("Du har bjudit in 5 vänner") — framtida fas

</deferred>

---

*Phase: 16-invite-foundation*
*Context gathered: 2026-03-07*
