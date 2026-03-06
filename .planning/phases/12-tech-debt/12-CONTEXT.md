# Phase 12: Tech Debt - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Tre identifierade v1.0 tech debt-items atgardas: (1) lookupAuthUid ersatts med invite-lank-baserad van-koppling sa att displayName-kollisioner elimineras, (2) WeatherAlertService injiceras i SwiftUI environment sa att pull-to-refresh kan trigga alert-check, (3) orphaned messages-cleanup vid kontoborttagning gors robust mot partiella raderingar.

</domain>

<decisions>
## Implementation Decisions

### Van-identifiering (DEBT-01)
- Invite-lank ersatter displayName-match i lookupAuthUid
- Anvandaren delar en unik lank (hotandcold://invite/<token>) via standard iOS Share Sheet
- "Share my invite link"-knapp placeras i profilvyn
- Mottagaren oppnar lanken och bada blir vanner direkt (omsesidigt, ingen bekraftelse-prompt)
- Om mottagaren inte har appen -> App Store-sida
- Invite-lank kompletterar befintlig kontaktimport (inte ersatter) -- kontaktimport med AI-platsgissning behalls for bulk-import
- Manuell "Add friend" (AddFriendSheet) byter fran namn-sok till invite-lank-flode
- Befintliga vanner tillagda via kontaktimport kan lankas till riktiga konton i efterhand -- om en kontaktimport-van sen registrerar sig och oppnar en invite-lank, kopplas till befintlig van-entry istallet for att skapa dubblett

### WeatherAlert-trigger (DEBT-02)
- WeatherAlertService injiceras i SwiftUI environment (saknas idag -- skapas som @State men laggs inte i .environment())
- Alert-check triggas automatiskt vid pull-to-refresh i vanlistan (utover befintlig cold-start-trigger)
- Ingen periodisk bakgrundscheck -- cold-start + pull-to-refresh racker

### Orphaned data-cleanup (DEBT-03)
- Befintligt beteende behalls: hela konversationen (inkl. alla meddelanden) raderas nar ett konto tas bort
- Tyst radering for den andra parten -- konversationen forsvinner fran chattlistan nasta gang data laddas, ingen notis
- Fokus pa robusthet: sakerstall att cleanup ar resilient mot partiella raderingar (nätverksfel mitt i batch-operationer)

### Claude's Discretion
- Invite-token-format och langd (UUID, nanoid, eller liknande)
- Firestore-struktur for invite-dokument (invites-collection med token som nyckel)
- Merge-logik for att koppla kontaktimport-vanner till riktiga konton
- Felhantering vid partiella raderingar i cleanupUserData
- Exakt integration av alert-check i pull-to-refresh-flodet

</decisions>

<specifics>
## Specific Ideas

- Invite-lank ska anvanda iOS Share Sheet -- latt att skicka via Messages, AirDrop, WhatsApp etc.
- Vid merge av kontaktimport-van med riktigt konto: behalll befintlig chathistorik och vandata, uppdatera authUid
- lookupAuthUid-metoden pa UserService ska antingen tas bort eller refaktoreras till att soka pa invite-token istallet for displayName

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserService.lookupAuthUid(byDisplayName:)`: Metoden som ska ersattas -- anropas fran AddFriendSheet, OnboardingViewModel, ContactImportService
- `AuthManager.cleanupUserData(uid:)`: Befintlig cleanup som redan raderar konversationer + meddelanden + vanner + profil + profilbild
- `WeatherAlertService`: Redan skapad som @State i HotAndColdFriendsApp -- behover bara laggas till i .environment()
- `CloudRefreshModifier`: Custom pull-to-refresh med moln-animation (fas 11) -- alert-check integreras har

### Established Patterns
- SwiftUI @Observable + .environment() for services (AuthManager, UserService, FriendService, ChatService, AppWeatherService)
- Firestore batch-operationer i chunks om 400 dokument for bulk-raderingar
- Universal Links / custom URL scheme (hotandcold://) redan konfigurerat for widget deep links

### Integration Points
- `HotAndColdFriendsApp.swift`: Lagg till `.environment(weatherAlertService)` (rad 31-35)
- `AddFriendSheet.swift`: Byt fran displayName-sok till invite-lank-flode
- `OnboardingViewModel.swift`: Uppdatera lookupAuthUid-anrop
- `ContactImportService.swift`: Uppdatera lookupAuthUid-anrop (eller behalll for kontaktimport-context)
- `ProfileView.swift`: Lagg till "Share my invite link"-knapp
- `FriendListView.swift` / `CloudRefreshModifier`: Integrera alert-check i pull-to-refresh

</code_context>

<deferred>
## Deferred Ideas

- **"Chat about XXX"-knappar med viral SMS-invite** -- Exponera weather-triggered chat affordances pa varje van (t.ex. "Chat about the snowstorm!"). Om vannen inte anvander appen, triggar chat-forsoket en invite via SMS/iOS Messages. Stark viral growth-feature -- egen fas.

</deferred>

---

*Phase: 12-tech-debt*
*Context gathered: 2026-03-06*
