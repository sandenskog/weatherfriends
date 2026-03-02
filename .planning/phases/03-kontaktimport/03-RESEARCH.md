# Phase 3: Kontaktimport - Research

**Researched:** 2026-03-02
**Domain:** iOS Contacts (CNContactStore), Firebase Cloud Functions v2, OpenAI API, Firebase Storage
**Confidence:** HIGH (Core iOS/Firebase APIs verified via official sources and SDK)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Import-flöde**
- Multi-select lista med checkboxar — användaren bockar i vilka kontakter som ska importeras
- Sökfält överst + alfabetiska sektioner med snabb-scroll (som iOS Kontakter-appen)
- Tillgänglig BÅDE i onboarding (steg 4) OCH i vänlistan (FriendListView) via "+"-knapp
- Kontakter utan platsdata visas ändå — importeras med "Okänd plats", användaren kan lägga till stad manuellt efteråt via stad-autocomplete

**AI-platsgissning UX**
- Auto-accept: AI:ns förslag accepteras automatiskt vid import, sedan visas sammanfattning där användaren kan korrigera fel
- Färgkodning av konfidens: grönt = hög (adress), gult = medel (landsnummer), rött = låg/saknar data
- Redigering via befintlig stad-autocomplete (LocationService) — konsekvent med onboarding
- AI-gissning körs direkt vid import (inte som separat steg) — sömlös upplevelse med laddningsindikator

**Manuellt tillägg**
- "+"-knapp i FriendListView visar meny: "Lägg till manuellt" / "Importera kontakter"
- Manuellt formulär: bara namn + stad (med autocomplete) — matchar befintlig Friend-modell
- Onboarding steg 4 utökas med "Importera från kontakter"-knapp bredvid manuellt tillägg
- Demo-vänner auto-rensas vid första riktiga vän (manuell eller import)

**Kontaktvisning**
- Importlistan visar: namn, profilbild (från kontaktkortet), stad-hint (flagga/landsnummer eller "Adress finns")
- Redan tillagda kontakter visas gråmarkerade med "Redan tillagd" — transparent dubbletthantering
- Kontaktens profilbild sparas till Firebase Storage och används som photoURL på Friend-modellen

### Claude's Discretion
- Övre gräns för antal kontakter per import-batch (balans mellan AI-kostnad och UX)
- Exakt layout och spacing i import-vyn
- Laddningsindikator-design under AI-gissning
- Felhantering vid CNContactStore-nekat tillstånd
- Firebase Cloud Function-arkitektur för AI-proxyn

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FRND-01 | Användare kan manuellt lägga till vän med stad/land | Befintlig AddFriendSheet utökas via meny-knapp; LocationService.resolveLocation() ger koordinater |
| FRND-02 | Användare kan importera vänner från iOS-kontakter | CNContactStore med NSContactsUsageDescription i Info.plist; enumerateContacts ger namn/telefon/e-post/adress/foto |
| FRND-03 | AI gissar stad/land vid import baserat på adress, telefonnummer, e-post | Firebase Cloud Functions v2 onCall + OpenAI gpt-4o-mini; phone prefix → land; postalAddress.city/country → direkt; AI-batch per import-session |
</phase_requirements>

---

## Summary

Fasen har tre tekniska pelare: (1) iOS Contacts-access via CNContactStore med korrekt tillståndshantering för iOS 17/18, (2) en Firebase Cloud Function v2 som proxar OpenAI-anrop för AI-platsgissning, och (3) Firebase Storage för kontaktprofilbilder. Alla tre pelarna stöds av stabila, väldefinierade API:er.

CNContactStore är den primära mekanismen för att hämta kontakter. På iOS 18+ introducerades `.limited`-tillståndet (användaren väljer vilka kontakter appen får se) och `contactAccessPicker`-modifier för att utöka åtkomsten. Projektet riktar iOS 17+ som deployment target, så `.limited` är en reell status att hantera med grace.

Firebase Cloud Functions v2 `onCall` med TypeScript och `defineSecret` är det etablerade mönstret för säker OpenAI-proxying — det finns väl dokumenterat och matchar den befintliga Firebase-stacken exakt. Ingen ny backend-infrastruktur behövs utöver functions-katalogen och Blaze-plan (som redan identifierats som ett krav i STATE.md). På iOS-sidan läggs `FirebaseFunctions` till som nytt SPM-beroende i project.yml, och anropet görs med `httpsCallable(_:).call(_:resultAs:)`.

Firebase Storage används redan i projektet (se project.yml — FirebaseStorage är redan länkad). Mönstret för uppladdning av CNContact.imageData är: `storageRef.putDataAsync(imageData)` följt av `storageRef.downloadURL()`. Resultatet sparas som `photoURL` på Friend-modellen som redan har fältet.

**Primary recommendation:** Bygg ContactImportService som @Observable @MainActor class med tre metoder: fetchContacts(), guessCityViaCF([ContactBatch]) och saveImportedFriends(). Cloud Function skrivs i TypeScript med defineSecret och returnerar strukturerad JSON med city, country, confidence per kontakt.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Contacts (system) | iOS 17+ | CNContactStore, CNContact, CNContactFetchRequest | Apple-inbyggd, inga externa beroenden |
| FirebaseFunctions | Firebase SDK 11.x | httpsCallable till Cloud Function proxy | Redan i Firebase-paketet, bara ny product att länka |
| FirebaseStorage | Firebase SDK 11.x | Upload CNContact.imageData | Redan länkad i project.yml |
| openai (npm) | ^4.x | OpenAI API-anrop från Cloud Function | De facto standard; typade svar |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ContactsUI (system) | iOS 17+ | CNContactPickerViewController | Alternativ om custom UI visar sig för komplex — men CONTEXT.md låser custom UI |
| firebase-functions/v2 (npm) | ^6.x | Cloud Functions v2 runtime | Node.js 20, moderna onCall-API:er |
| firebase-admin (npm) | ^12.x | Auth-verifiering i Cloud Function | Verifiera att anropet kommer från autentiserad app-användare |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| OpenAI gpt-4o-mini | Google Gemini Flash | gpt-4o-mini är valt av projektet (STATE.md); Gemini hade krävt ny API-integration |
| Firebase Cloud Function | Direct OpenAI från iOS | STATE.md beslut: OpenAI-anrop ALDRIG direkt från iOS — API-nyckelsäkerhet |
| CNContactStore (custom UI) | CNContactPickerViewController | CONTEXT.md låser custom multi-select UI — CNContactPickerViewController stöder inte multi-select med checkboxar |

**Installation (project.yml):**
```yaml
# Lägg till i targets.HotAndColdFriends.dependencies:
- package: Firebase
  product: FirebaseFunctions
```

**Cloud Functions (ny katalog `functions/`):**
```bash
firebase init functions  # Välj TypeScript, Node.js 20
npm install openai       # I functions/-katalogen
```

---

## Architecture Patterns

### Recommended Project Structure

```
HotAndColdFriends/
├── Features/
│   └── ContactImport/
│       ├── ContactImportView.swift          # Fullskärms sheet med sökfält + lista
│       ├── ContactImportViewModel.swift     # @Observable @MainActor, orchestrerar flöde
│       └── ContactImportRow.swift          # Rad med checkbox, bild, namn, stad-hint
├── Services/
│   └── ContactImportService.swift          # CNContactStore + CF-anrop + Storage-upload
functions/
├── src/
│   └── index.ts                           # Cloud Function: guessContactLocations
├── package.json
└── tsconfig.json
```

### Pattern 1: CNContactStore — tillståndshantering och hämtning

**What:** Begär tillstånd, kontrollera status (inkl. `.limited` på iOS 18+), hämta kontakter med specificerade nycklar.
**When to use:** I ContactImportService.fetchContacts() — anropas när importvyn öppnas.

```swift
// Source: Apple Developer Documentation CNContactStore, verified 2026-03
import Contacts

@Observable
@MainActor
class ContactImportService {
    private let store = CNContactStore()

    static let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor
    ]

    func requestAccessAndFetch() async throws -> [CNContact] {
        // Kontrollera befintlig status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            break
        case .limited:
            // iOS 18+: vi har partiell access — returnera de kontakter vi har
            break
        case .notDetermined:
            // Triggar system-dialog
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else { return [] }
        case .denied, .restricted:
            throw ContactImportError.accessDenied
        @unknown default:
            throw ContactImportError.accessDenied
        }

        let request = CNContactFetchRequest(keysToFetch: Self.keysToFetch)
        request.sortOrder = .userDefault

        var contacts: [CNContact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        return contacts
    }
}
```

**Viktigt:** `enumerateContacts(with:)` är SYNKRON och blockerande — kör den i en `Task { }` eller `Task.detached` för att inte blockera MainActor. Alternativt: wrappa i `withCheckedThrowingContinuation`.

### Pattern 2: Firebase Cloud Function — guessContactLocations

**What:** En v2 `onCall`-funktion som tar en array av kontakter och returnerar platsgissningar per kontakt.
**When to use:** Anropas efter att användaren valt kontakter men innan importbekräftelse.

```typescript
// Source: codewithandrea.com/articles/api-keys-2ndgen-cloud-functions-firebase/ + Firebase docs
import { onCall, HttpsError } from "firebase-functions/v2/https"
import { defineSecret } from "firebase-functions/params"
import OpenAI from "openai"

const openaiKey = defineSecret("OPENAI_API_KEY")

interface ContactInput {
  identifier: string
  givenName: string
  familyName: string
  phoneNumbers: string[]     // E.g. ["+46701234567", "08-123456"]
  emailAddresses: string[]
  postalCity: string         // From CNPostalAddress.city
  postalCountry: string      // From CNPostalAddress.country
}

interface LocationGuess {
  identifier: string
  city: string
  country: string
  confidence: "high" | "medium" | "low" | "unknown"
  reason: string             // Förklaring för färgkodning
}

export const guessContactLocations = onCall(
  { secrets: [openaiKey], region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Requires authentication")
    }

    const contacts: ContactInput[] = request.data.contacts
    if (!contacts || contacts.length === 0) {
      return { results: [] }
    }

    const client = new OpenAI({ apiKey: openaiKey.value() })

    // Batch-prompt — en anrop för alla kontakter
    const prompt = buildBatchPrompt(contacts)

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "You are a location inference assistant. Return only valid JSON."
        },
        { role: "user", content: prompt }
      ],
      max_tokens: 1000
    })

    const raw = response.choices[0].message.content ?? "{}"
    const parsed = JSON.parse(raw) as { results: LocationGuess[] }
    return parsed
  }
)

function buildBatchPrompt(contacts: ContactInput[]): string {
  const list = contacts.map(c => {
    const parts = []
    if (c.postalCity) parts.push(`city: ${c.postalCity}`)
    if (c.postalCountry) parts.push(`country: ${c.postalCountry}`)
    c.phoneNumbers.forEach(p => parts.push(`phone: ${p}`))
    c.emailAddresses.forEach(e => parts.push(`email: ${e}`))
    return `- id: ${c.identifier}, name: ${c.givenName} ${c.familyName}, ${parts.join(", ")}`
  }).join("\n")

  return `For each contact below, infer the most likely city and country.
Use postal address if present (high confidence), phone country code if no address (medium confidence),
email domain if phone is local format (low confidence), or "Unknown" if nothing found.

Return JSON: {"results": [{"identifier": "...", "city": "...", "country": "...", "confidence": "high|medium|low|unknown", "reason": "..."}]}

Contacts:
${list}`
}
```

### Pattern 3: iOS — anropa Cloud Function

**What:** SwiftUI/Swift-sida anropar `guessContactLocations` via httpsCallable.
**When to use:** I ContactImportViewModel efter kontakturval.

```swift
// Source: Firebase iOS SDK discussion #8927 + firebase-functions docs
import FirebaseFunctions

struct ContactLocationRequest: Encodable {
    let contacts: [ContactPayload]
}

struct ContactPayload: Encodable {
    let identifier: String
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let postalCity: String
    let postalCountry: String
}

struct LocationGuessResponse: Decodable {
    let results: [LocationGuess]
}

struct LocationGuess: Decodable {
    let identifier: String
    let city: String
    let country: String
    let confidence: String    // "high" | "medium" | "low" | "unknown"
    let reason: String
}

// I ContactImportService:
func guessLocations(for contacts: [CNContact]) async throws -> [LocationGuess] {
    let functions = Functions.functions(region: "europe-west1")
    let callable = functions.httpsCallable("guessContactLocations")

    let payload = ContactLocationRequest(contacts: contacts.map { c in
        let phones = c.phoneNumbers.map { $0.value.stringValue }
        let emails = c.emailAddresses.map { $0.value as String }
        let address = c.postalAddresses.first?.value
        return ContactPayload(
            identifier: c.identifier,
            givenName: c.givenName,
            familyName: c.familyName,
            phoneNumbers: phones,
            emailAddresses: emails,
            postalCity: address?.city ?? "",
            postalCountry: address?.country ?? ""
        )
    })

    let result = try await callable.call(payload, resultAs: LocationGuessResponse.self)
    return result.results
}
```

### Pattern 4: Firebase Storage — spara kontaktbild

**What:** Ladda upp CNContact.thumbnailImageData och spara downloadURL som Friend.photoURL.
**When to use:** Vid sparande av importerad vän om kontakten har en bild.

```swift
// Source: Firebase Storage AsyncAwait.swift (firebase-ios-sdk main branch)
import FirebaseStorage

func uploadContactPhoto(uid: String, friendId: String, imageData: Data) async throws -> String {
    let storage = Storage.storage()
    let ref = storage.reference().child("users/\(uid)/friends/\(friendId).jpg")

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    // putDataAsync returnerar StorageMetadata — sedan hämtar vi URL
    _ = try await ref.putDataAsync(imageData, metadata: metadata)
    let url = try await ref.downloadURL()
    return url.absoluteString
}
```

### Pattern 5: iOS 18 — limited access med contactAccessPicker

**What:** Om status är `.limited`, erbjud användaren att utöka åtkomst via `.contactAccessPicker`.
**When to use:** Om authorization == .limited och användaren vill se fler kontakter.

```swift
// Source: Apple WWDC24 "Meet the Contact Access Button" + Apple docs
.contactAccessPicker(isPresented: $showContactAccessPicker) { identifiers in
    // identifiers = nyligen tillagda kontakter — fetcha och lägg till i listan
    Task {
        await viewModel.appendContactsWithIdentifiers(identifiers)
    }
}
```

### Anti-Patterns to Avoid

- **Anropa OpenAI direkt från iOS:** API-nyckel exponeras. STATE.md: "OpenAI-anrop MÅSTE gå via Firebase Cloud Function proxy — aldrig direkt från iOS-appen."
- **enumerateContacts på MainActor utan Task:** Blockerar UI-tråden. Kör alltid på bakgrundstask.
- **Hämta alla CNContactKeys:** Tar lång tid och mycket minne. Specificera exakt vilka nycklar som behövs.
- **Spara CNContact.imageData (full):** Använd `CNContactThumbnailImageDataKey` för listan, bara ladda upp om kontakten faktiskt väljs för import.
- **En OpenAI-anrop per kontakt:** Extremt kostsamt och långsamt. Batch alla valda kontakter i ett enda Cloud Function-anrop.
- **functions.config() för API-nyckeln:** Deprecated API, tas bort mars 2027. Använd `defineSecret` + Cloud Secret Manager.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Kontakttillståndshantering | Egen permission flow | CNContactStore.authorizationStatus + requestAccess | Systemdialog hanterar iOS 18 limited, retries, Settings-redirect |
| Telefonnummer-parsing | Regex för +46, 08- etc. | Skicka rå `stringValue` till OpenAI | AI klarar alla format; libPhoneNumber är ett tungt beroende för detta ändamål |
| Adress-normalisering | Parsing av CNPostalAddress | Skicka city/country direkt till OpenAI | AI klarar stavfel, alternativa namn, historiska namn |
| API-nyckelskydd | iOS Keychain för OpenAI-nyckel | Firebase Cloud Function | Keychain skyddar på enheten men nyckel skulle fortfarande behöva distribueras i app-bundle |
| Bild-cache för kontaktbilder | Custom URL-cache | AsyncImage + Firebase Storage URL | AsyncImage cachelagrar automatiskt |

**Key insight:** AI:n i Cloud Function hanterar det mesiga arbetet med normalisering, formatsäkerhet och flerspråkiga adresser. iOS-sidan skickar rådata och hanterar bara UX.

---

## Common Pitfalls

### Pitfall 1: enumerateContacts blockerar MainActor

**What goes wrong:** `store.enumerateContacts(with:)` är synkron och kan ta 1-5 sekunder på stora adressböcker. Om den körs på MainActor fryser UI:t.
**Why it happens:** API:et är gammalt och har inget async-alternativ.
**How to avoid:** Wrappa alltid i `Task.detached(priority: .userInitiated) { }` eller `await Task { }.value`.
**Warning signs:** UI-freeze när importvyn öppnas för första gången.

### Pitfall 2: CNContactStore kräver korrekt nyckelspecifikation

**What goes wrong:** `NSError: A property was not requested when contact was fetched` — crash vid access av `contact.phoneNumbers` om `CNContactPhoneNumbersKey` inte är med i `keysToFetch`.
**Why it happens:** CNContact är lazy-loaded; nycklar som inte begärdes är tomma.
**How to avoid:** Definiera alltid hela keysToFetch-listan statiskt som konstant i servicen.
**Warning signs:** Runtime-krasch vid iteration av kontaktfält.

### Pitfall 3: Firebase Functions Blaze-plan krävs

**What goes wrong:** `functions.https.onCall` kan inte deployas på Spark (gratis) plan.
**Why it happens:** Utgående nätverksanrop (till OpenAI) kräver Blaze-plan.
**How to avoid:** Bekräfta att Firebase-projektet är uppgraderat till Blaze innan deploy. STATE.md noterar detta som känd concern.
**Warning signs:** Deploy misslyckas med "Billing account not configured".

### Pitfall 4: Cloud Function region måste matcha iOS-klienten

**What goes wrong:** Hög latens eller CORS-fel om region inte är explicit satt på båda sidor.
**Why it happens:** Default-region är `us-central1`; om Functions deployas i `europe-west1` men iOS-klienten pekar på default, anropas fel endpoint.
**How to avoid:** Sätt `region: "europe-west1"` i både TypeScript-funktionen och `Functions.functions(region: "europe-west1")` i Swift.
**Warning signs:** Timeout-fel, oväntat lång latens.

### Pitfall 5: iOS 18 .limited-status = inte ett fel

**What goes wrong:** App behandlar `.limited` som `.denied` och visar felmeddelande.
**Why it happens:** `.limited` är ny i iOS 18 — `@unknown default`-gren fångar den som fel utan explicit hantering.
**How to avoid:** Hantera `.limited` explicit — presentera `contactAccessPicker` som valfri åtgärd, visa inte felmeddelande.
**Warning signs:** Användare på iOS 18 ser "Åtkomst nekad" fast de valt "Begränsad åtkomst".

### Pitfall 6: NSContactsUsageDescription saknas i Info.plist

**What goes wrong:** App kraschar vid runtime med `This app has crashed because it attempted to access privacy-sensitive data without a usage description`.
**Why it happens:** iOS kräver att nyckeln finns i Info.plist innan `requestAccess` anropas.
**How to avoid:** Lägg till `NSContactsUsageDescription` i `HotAndColdFriends/Resources/Info.plist` som **första åtgärd** i fas 03-01.
**Warning signs:** Omedelbar crash vid öppnande av importvyn.

### Pitfall 7: Batch-storlek för AI-anrop

**What goes wrong:** Enorma prompt-tokens om användaren väljer 200+ kontakter → hög kostnad och potentiell timeout.
**Why it happens:** Ingen övre gräns på valda kontakter.
**How to avoid:** Begränsa till max 50 kontakter per import-session (Claude's Discretion). Vid större urval: dela upp i batchar om 50 och anropa Cloud Function sekventiellt.
**Warning signs:** OpenAI-timeout (30s standard i Cloud Functions), oväntat hög Firebase-faktura.

---

## Code Examples

### Extrahera platsdata från CNContact

```swift
// Source: Apple CNPostalAddress docs, verified 2026-03
func locationHint(from contact: CNContact) -> (city: String, country: String, phonePrefix: String?) {
    // Adress (högst konfidens)
    if let addr = contact.postalAddresses.first?.value {
        return (addr.city, addr.country, nil)
    }
    // Telefonnummer — extrahera landsnummer
    if let phone = contact.phoneNumbers.first?.value.stringValue {
        let prefix = extractCountryCode(from: phone)
        return ("", "", prefix)
    }
    return ("", "", nil)
}

func extractCountryCode(from phone: String) -> String? {
    // Enkel extrahering av +XX eller +XXX prefix
    guard phone.hasPrefix("+") else { return nil }
    let digits = phone.dropFirst()
    if let match = digits.prefix(3).first(where: { $0.isNumber }) {
        // Returnera de 1-3 initiala siffrorna som en ledtråd till AI:n
        _ = match
        return "+" + String(digits.prefix(3))
    }
    return nil
}
```

### Konfidensfärg baserat på AI-svar

```swift
// Används i ContactImportRow.swift för att visualisera AI-säkerhet
extension String {
    var confidenceColor: Color {
        switch self {
        case "high":    return .green
        case "medium":  return .yellow
        case "low":     return .orange
        default:        return .red  // "unknown"
        }
    }
}
```

### project.yml — lägga till FirebaseFunctions

```yaml
# I targets.HotAndColdFriends.dependencies, lägg till:
- package: Firebase
  product: FirebaseFunctions
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AddressBook framework | Contacts framework (CNContactStore) | iOS 9 | CNContact är modernt, stabilt |
| `functions.config()` för secrets | `defineSecret()` + Cloud Secret Manager | Firebase Functions v2 (2022) | Gammal API deprecated, tas bort mars 2027 |
| FirebaseFunctionsSwift (separat modul) | Integrerat i FirebaseFunctions | Firebase SDK 11.x | Bara ett SPM-beroende behövs |
| Inga contact-privacy val | `.limited` access + `contactAccessPicker` | iOS 18 (2024) | Måste hanteras explicit eller behandlas gracefully |
| Callback-based Firebase Storage | `putDataAsync` + `downloadURL()` async | Firebase SDK ~10.x | Modern async/await fullt stödd |

**Deprecated/outdated:**
- `firebase.functions.config()`: Deprecated, decommissioned mars 2027. Använd `defineSecret`.
- `AddressBook` / `ABAddressBook`: Borttaget i iOS 9. Ska aldrig användas.
- `FirebaseFunctionsSwift` (separat SPM-produkt): Integrerat i `FirebaseFunctions` sedan SDK 11.x.

---

## Open Questions

1. **Kostnadstak för AI-gissning**
   - What we know: gpt-4o-mini kostar $0.15/1M input + $0.60/1M output tokens. En batch om 50 kontakter med ledtrådar ≈ ~1000 input-tokens → ca $0.00015 per session.
   - What's unclear: Hur ofta importerar en typisk användare? Om det sker sällan är kostnaden försumbar.
   - Recommendation: Sätt batch-max till 50 kontakter per import (Claude's Discretion-beslut). Logga token-användning i Cloud Function för kostnadsövervakning.

2. **Firebase projekt — Blaze-plan status**
   - What we know: STATE.md noterar "Firebase Cloud Functions kräver Blaze-plan" som concern.
   - What's unclear: Är projektet redan på Blaze, eller behöver det uppgraderas?
   - Recommendation: Verifiera i Firebase Console innan Cloud Function-deploy i plan 03-02. Lägg till verifikationscheck i plan-tasen.

3. **Dubblettdetektering — exakt matching**
   - What we know: CONTEXT.md: redan tillagda kontakter visas gråmarkerade. FriendService.fetchFriends() returnerar befintliga vänner med displayName.
   - What's unclear: Ska matchning vara exakt namn-match? Vad händer om "Kalle Karlsson" i kontakter matchar "Karl Karlsson" i Firestore?
   - Recommendation: Enkel exakt match på `displayName` == `contact.fullName`. Fuzzy matching är overkill för v1.

4. **xcodegen och Contacts-entitlement**
   - What we know: Contacts-framework kräver ingen entitlement — bara NSContactsUsageDescription i Info.plist.
   - What's unclear: Behöver project.yml uppdateras med något contacts-specifikt utöver Info.plist-nyckeln?
   - Recommendation: Nej — Contacts-access styrs enbart av Info.plist-nyckeln och CNContactStore.requestAccess-anropet. Ingen entitlement-ändring i project.yml.

---

## Validation Architecture

> `workflow.nyquist_validation` är inte konfigurerat i `.planning/config.json` — sektion utelämnad.

---

## Sources

### Primary (HIGH confidence)

- Apple Developer Documentation, CNContactStore — requestAccess, enumerateContacts, authorizationStatus, iOS 18 limited access
- Apple WWDC24 "Meet the Contact Access Button" (developer.apple.com/videos/play/wwdc2024/10121/) — contactAccessPicker iOS 18 API
- Firebase iOS SDK Package.swift (github.com/firebase/firebase-ios-sdk) — FirebaseFunctions produktnamn bekräftat
- Firebase iOS SDK AsyncAwait.swift (github.com/firebase/firebase-ios-sdk/blob/main/FirebaseStorage/Sources/AsyncAwait.swift) — putDataAsync, downloadURL async API
- Firebase SDK Discussion #8927 (github.com/firebase/firebase-ios-sdk/discussions/8927) — httpsCallable async/await med `resultAs:` parameter
- CNPostalAddress Apple docs — city, country, street properties

### Secondary (MEDIUM confidence)

- codewithandrea.com/articles/api-keys-2ndgen-cloud-functions-firebase/ — defineSecret TypeScript-mönster, bekräftat mot Firebase docs
- createwithswift.com/listing-contacts-with-the-contacts-framework/ — CNContactStore fetch-mönster, bekräftat mot Apple docs
- firebase.google.com/docs/functions/callable — onCall API-struktur

### Tertiary (LOW confidence)

- OpenAI pricing: $0.15/1M input för gpt-4o-mini (från WebSearch-resultat, priser ändras — verifiera vid implementation)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — bekräftat via officiella SDK:er och Firebase Package.swift
- Architecture: HIGH — CNContactStore och Firebase Functions-mönster är välbeprövade och verifierade
- Pitfalls: HIGH — baserade på kända API-kontrakt och Swift concurrency-regler
- Kostnadsuppskattning: MEDIUM — OpenAI-priser är rörliga

**Research date:** 2026-03-02
**Valid until:** 2026-09-02 (stabila Apple/Firebase API:er; OpenAI-priser kan ändras)
