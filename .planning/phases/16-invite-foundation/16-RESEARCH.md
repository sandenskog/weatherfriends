# Phase 16: Invite Foundation - Research

**Researched:** 2026-03-07
**Domain:** iOS Universal Links, Web fallback, Deferred deep linking, Firestore invite persistence
**Confidence:** HIGH

## Summary

Fasen handlar om att migrera invite-systemet fran custom URL scheme (`hotandcold://`) till Universal Links (HTTPS), bygga en dynamisk web fallback-sida for mottagare utan appen, gora invite-koder persistenta (multi-use), och implementera deferred deep linking via clipboard for nya anvandare.

Projektet har redan en fungerande `InviteService.swift` med token-skapande, Firestore-lagring och redemption-logik. Den befintliga `onOpenURL`-handlern i `HotAndColdFriendsApp.swift` fungerar aven for Universal Links (iOS skickar Universal Links som URL, inte NSUserActivity). Den stora forandringen ar att (1) AASA-filen maste hostas pa `apps.sandenskog.se`, (2) webbsidan maste uppgraderas fran statisk nginx till en Node.js-server for dynamiska OpenGraph-taggar och Firestore-uppslag, och (3) invite-dokumentets datamodell maste utvidgas.

**Primary recommendation:** Uppgradera `apps.sandenskog.se` fran statisk nginx till en Node.js (Express) server i Docker som servar bade statiska sidor och dynamiska `/invite/<token>`-routes med server-side Firestore-uppslag for OpenGraph-meta-taggar. Anvand `firebase-admin` SDK for server-side Firestore-access.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Universal Links pa `apps.sandenskog.se` (redan konfigurerad med reverse proxy + SSL pa Synology)
- URL-format: `apps.sandenskog.se/invite/<token>`
- Bara token i URL -- inbjudarens namn visas via dynamiska OpenGraph-meta-tags
- Associated Domains entitlement behovs (saknas idag)
- Web fallback visar inbjudarens namn + stad + app-branding
- Dynamiska OpenGraph-meta-tags per invite-token for snygga link previews
- Clipboard-copy av invite-token innan redirect till App Store (for deferred deep link)
- Plattformsdetektering: iOS far App Store-knapp, Android/desktop ser "FriendsCast finns bara for iPhone just nu"
- Implementeras som ny /invite route i befintliga apps.sandenskog.se-appen
- En permanent invite-kod per anvandare (skapas vid account creation)
- Invite-dokument raderas INTE efter redemption -- behlls med redeemed-lista (array av UIDs)
- Koden tillganglig pa tre stallen: Profilvyn, AddFriendSheet, dedicated share-knapp i header
- Befintlig InviteService.swift refaktoreras: ta bort delete-on-redeem, lagg till redeemed-array, andra URL-schema till HTTPS
- Web fallback kopierar invite-token till clipboard innan App Store-redirect
- Appen kollar clipboard vid forsta start efter installation (iOS paste-banner sedan iOS 16)
- Auto-redeem direkt efter signup-completion (profil skapad)
- Kort toast/banner-bekraftelse: "Du ar nu van med [namn]!" -- inte blockerande
- Sparad invite-token giltig i 7 dagar (ignorera aldre clipboard-data)

### Claude's Discretion
- AASA-filens exakta konfiguration (apple-app-site-association)
- Web fallback-sidans visuella design och layout
- Clipboard-detekteringslogik och edge cases
- Migrering av befintliga invite-dokument till ny persistent modell
- Toast/banner-komponentens implementation

### Deferred Ideas (OUT OF SCOPE)
- Invite celebration med Bubble Pop-animation -- Phase 18 (INVT-05)
- Mejl-signup for Android-anvandare som besoker fallback-sidan -- framtida fas
- Invite-statistik ("Du har bjudit in 5 vanner") -- framtida fas

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INVT-01 | Invite-lankar anvander Universal Links (HTTPS) istallet for custom URL scheme | AASA-fil pa apps.sandenskog.se, Associated Domains entitlement, onOpenURL handler redan kompatibel |
| INVT-02 | Web fallback-sida visas for anvandare utan appen installerad, med App Store-redirect | Node.js Express server med dynamisk HTML-rendering, Firestore-uppslag via firebase-admin |
| INVT-03 | Invite-koder ar persistenta och kan anvandas flera ganger | InviteDocument utvidgas med `redeemedBy: [String]` array, delete-logik tas bort |
| INVT-04 | Deferred deep link -- invite-token sparas och loses in efter signup for ej inloggade anvandare | Clipboard-copy pa web, UIPasteboard-check i app, auto-redeem efter onboarding completion |

</phase_requirements>

## Standard Stack

### Core (iOS)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI-framework | Redan i bruk, onOpenURL hanterar Universal Links |
| FirebaseFirestore | 11.x | Invite-dokument lagring | Redan i bruk, Codable-stod |
| UIPasteboard | iOS 16+ | Deferred deep link clipboard-check | Systemets API, ingen tredjepartsberoenede |

### Core (Web/Server)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js | 20 LTS | Server-runtime | Stabilt, Docker-vanligt, JS-ekosystem |
| Express | 4.x | HTTP-routing | De facto standard for Node.js webbservrar |
| firebase-admin | 12.x | Server-side Firestore-access | Officiellt SDK for backend Firestore |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ejs | 3.x | HTML template-rendering | Dynamiska OpenGraph-taggar per invite-token |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Node.js/Express | nginx sub_filter + lua | Enklare men kan inte gora Firestore-uppslagningar server-side |
| firebase-admin | Firestore REST API | Enklare men saknar auth/caching, mer boilerplate |
| ejs | Handlebars | Likvardig -- ejs ar enklare for enstaka templates |

**Installation (web):**
```bash
npm init -y && npm install express firebase-admin ejs
```

## Architecture Patterns

### Recommended Project Structure (web)
```
website/
  server.js            # Express server med routes
  views/
    invite.ejs         # Invite fallback-sida med dynamiska OG-tags
  public/
    index.html         # Befintlig statisk startsida
    privacy.html       # Befintlig
    support.html       # Befintlig
  .well-known/
    apple-app-site-association   # AASA-fil (JSON, utan .json-andelse)
  firebase-service-account.json  # Service account for Firestore (ALDRIG committa!)
  Dockerfile           # Uppgraderad fran nginx:alpine till node:20-alpine
  package.json
```

### Pattern 1: AASA-fil (Apple App Site Association)
**What:** JSON-fil som talar om for iOS vilka URL-sokvagar som ska oppna appen
**When to use:** Alltid -- kravs for Universal Links
**Example:**
```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["A473BQKT8M.se.sandenskog.hotandcoldfriends"],
        "components": [
          {
            "/": "/invite/*",
            "comment": "Invite deep links"
          }
        ]
      }
    ]
  }
}
```
**Confidence:** HIGH -- Apple's dokumenterade format for iOS 13+/`details` array med `components`.

**Viktigt:** Filen MASTE:
- Serveras pa `https://apps.sandenskog.se/.well-known/apple-app-site-association`
- Ha Content-Type `application/json`
- INTE ha `.json`-andelse
- INTE returnera redirect (maste vara direkt 200-svar)

### Pattern 2: Associated Domains Entitlement
**What:** Entitlement i Xcode-projektet som kopplar appen till domanen
**When to use:** Kravs for att AASA ska fungera
**Example i project.yml:**
```yaml
entitlements:
  properties:
    com.apple.developer.associated-domains:
      - applinks:apps.sandenskog.se
```
**Och i .entitlements plist:**
```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:apps.sandenskog.se</string>
</array>
```

### Pattern 3: Universal Link Handling i SwiftUI
**What:** iOS skickar Universal Links till `.onOpenURL` (INTE `.onContinueUserActivity`)
**When to use:** For att ta emot HTTPS-lankar nar appen ar installerad
**Example:**
```swift
.onOpenURL { url in
    // Universal Links kommer hit med https://apps.sandenskog.se/invite/<token>
    if url.host == "apps.sandenskog.se",
       url.pathComponents.count >= 3,
       url.pathComponents[1] == "invite" {
        let token = url.pathComponents[2]
        // Redeem token...
    }
}
```
**Confidence:** HIGH -- Verifierat via flera kallor att iOS skickar Universal Links som URL till onOpenURL, inte som NSUserActivity.

### Pattern 4: Dynamisk Web Fallback med Server-Side Rendering
**What:** Express-server som gor Firestore-uppslag och renderar personlig HTML
**When to use:** Nar anvandare utan appen klickar en invite-lank
**Example:**
```javascript
app.get('/invite/:token', async (req, res) => {
  const doc = await db.collection('invites').doc(req.params.token).get();
  if (!doc.exists) return res.status(404).render('invite', { valid: false });
  const data = doc.data();
  res.render('invite', {
    valid: true,
    senderName: data.senderDisplayName,
    senderCity: data.senderCity,
    token: req.params.token,
    appStoreUrl: 'https://apps.apple.com/app/id6760045281'
  });
});
```

### Pattern 5: Clipboard Deferred Deep Link
**What:** Web-sidan kopierar token till clipboard, appen laser det vid forsta start
**When to use:** For anvandare som installerar appen efter att ha klickat en invite-lank
**JavaScript (web-sida):**
```javascript
// Kopiera token till clipboard innan App Store redirect
async function redirectToAppStore(token, appStoreUrl) {
  try {
    await navigator.clipboard.writeText(`friendscast-invite:${token}`);
  } catch {
    // Fallback for aldre browsers
    const ta = document.createElement('textarea');
    ta.value = `friendscast-invite:${token}`;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  }
  window.location.href = appStoreUrl;
}
```
**Swift (app-sida):**
```swift
func checkClipboardForInviteToken() -> String? {
    guard let content = UIPasteboard.general.string,
          content.hasPrefix("friendscast-invite:") else { return nil }
    let token = String(content.dropFirst("friendscast-invite:".count))
    guard !token.isEmpty else { return nil }
    return token
}
```
**Confidence:** HIGH -- Etablerat monster for deferred deep linking. iOS 16+ visar paste-banner ("App vill klistra in fran X").

### Anti-Patterns to Avoid
- **Lasa clipboard tyst vid varje app-start:** Gor bara vid forsta start efter installation, eller efter signup. Annars ser anvandaren paste-banner varje gang.
- **Anvanda `onContinueUserActivity` for Universal Links pa iOS:** Fungerar INTE -- iOS skickar Universal Links via `onOpenURL`.
- **Radera AASA-cache manuellt:** Apple cachar AASA via CDN. Andrar du den kan det ta 24-48 timmar innan iOS ser uppdateringen. Gor ratt fran borjan.
- **Token i URL-fragmentet (#):** Sociala plattformar skickar inte fragment till servern -- anvand path-parameter (`/invite/<token>`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Server-side Firestore-access | Raw REST API-anrop | firebase-admin SDK | Hanterar auth, retries, connection pooling |
| HTML template rendering | String concatenation | ejs templates | Undviker XSS, renare kod |
| Platform detection (web) | Regex pa User-Agent | navigator.userAgent + standard checks | Behover bara skilja iOS/Android/desktop, inte exakt modell |
| Clipboard API | document.execCommand('copy') | navigator.clipboard.writeText() med fallback | Modernt API, asynkront, battre sakerhet |

## Common Pitfalls

### Pitfall 1: AASA-fil cachas av Apples CDN
**What goes wrong:** Du andrar AASA-filen men iOS-enheter ser fortfarande gamla versionen
**Why it happens:** Apple cachar AASA via sitt eget CDN (app-site-association.cdn-apple.com), uppdateras inom 24-48h
**How to avoid:** Gor AASA-filen ratt fran borjan. Testa med Apples valideringsverktyg: `https://app-site-association.cdn-apple.com/a/v1/apps.sandenskog.se`
**Warning signs:** Universal Links fungerar inte trots korrekt konfiguration

### Pitfall 2: iOS paste-banner storning
**What goes wrong:** Anvandaren ser "Appen vill klistra in fran Safari" varje gang de oppnar appen
**Why it happens:** `UIPasteboard.general.string` triggar iOS 16+ paste-bannern vid varje laming
**How to avoid:** Lasa clipboard BARA en gang efter forsta installation/signup. Anvand UserDefaults-flagga `hasCheckedClipboardInvite`. Anvand ett unikt prefix (`friendscast-invite:`) for att snabbt filtrera irrelevant clipboard-data.
**Warning signs:** Anvandare klagar pa upprepade paste-dialoger

### Pitfall 3: Token-expiry i clipboard
**What goes wrong:** Anvandare kopierar token, installerar appen veckor senare, token ar for gammal
**Why it happens:** Clipboard-data har inget inbyggt TTL
**How to avoid:** Web-sidan lagrar timestamp together med token: `friendscast-invite:<token>:<unix_timestamp>`. Appen validerar att timestamp ar <7 dagar gammal.
**Warning signs:** Anvandare rapporterar att invite inte fungerade

### Pitfall 4: OpenGraph-cache i sociala plattformar
**What goes wrong:** Lanken visar gammal/generisk preview i iMessage/WhatsApp
**Why it happens:** iMessage och WhatsApp cachar OpenGraph-data fran forsta fetch
**How to avoid:** Se till att server-side rendering fungerar korrekt INNAN lankar borjar delas. OpenGraph-taggar maste finnas i initial HTML-respons (inte injiceras med JavaScript).
**Warning signs:** Link preview visar "apps.sandenskog.se" istallet for personligt meddelande

### Pitfall 5: Firebase service account i Docker
**What goes wrong:** Appen kan inte anslutas till Firestore fran servern
**Why it happens:** Service account JSON-fil maste finnas i containern men far INTE committas till git
**How to avoid:** Kopiera service account-filen separat vid deploy, eller anvand Docker secrets/environment variables. Lagg till i `.gitignore`.
**Warning signs:** "Could not load the default credentials" error i server-loggar

### Pitfall 6: Associated Domains kravs i Apple Developer Portal
**What goes wrong:** Universal Links fungerar inte trots korrekt AASA och entitlement
**Why it happens:** Associated Domains capability maste AVEN vara aktiverad i Apple Developer Portal for app ID:t
**How to avoid:** Ga till developer.apple.com > Certificates, Identifiers & Profiles > App ID > markera "Associated Domains"
**Warning signs:** Xcode-build lyckas men Universal Links ignoreras pa enhet

## Code Examples

### InviteDocument -- Ny persistent modell
```swift
struct InviteDocument: Codable {
    var senderUid: String
    var senderDisplayName: String
    var senderCity: String
    var redeemedBy: [String]  // Array av UIDs som anvant koden
    @ServerTimestamp var createdAt: Timestamp?
}
```

### InviteService -- Uppdaterad URL-generering
```swift
func inviteURL(token: String) -> URL {
    URL(string: "https://apps.sandenskog.se/invite/\(token)")!
}
```

### InviteService -- Uppdaterad redemption (ingen delete)
```swift
func redeemInvite(token: String, redeemerUid: String, ...) async throws {
    // ... befintlig logik for vanskapsskapande ...

    // Istallet for delete: lagg till redeemer i redeemedBy-array
    try await db.collection("invites").document(token).updateData([
        "redeemedBy": FieldValue.arrayUnion([redeemerUid])
    ])
}
```

### onOpenURL -- Utokad for Universal Links
```swift
.onOpenURL { url in
    if url.scheme == "hotandcold" {
        // Befintlig custom scheme-hantering (behall for bakatkompatibilitet)
        handleCustomScheme(url)
    } else if url.host == "apps.sandenskog.se",
              url.pathComponents.count >= 3,
              url.pathComponents[1] == "invite" {
        let token = url.pathComponents[2]
        handleInviteToken(token)
    }
}
```

### Express invite route (web)
```javascript
const express = require('express');
const admin = require('firebase-admin');
const path = require('path');

const app = express();
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Statiska filer (index.html, privacy.html, support.html)
app.use(express.static(path.join(__dirname, 'public')));

// AASA-fil (MASTE serveras utan redirect, med application/json)
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.sendFile(path.join(__dirname, '.well-known', 'apple-app-site-association'));
});

// Dynamisk invite-sida
app.get('/invite/:token', async (req, res) => {
  try {
    const doc = await admin.firestore()
      .collection('invites').doc(req.params.token).get();

    if (!doc.exists) {
      return res.status(404).render('invite', { valid: false });
    }

    const data = doc.data();
    const ua = req.headers['user-agent'] || '';
    const isIOS = /iPhone|iPad|iPod/.test(ua);
    const isAndroid = /Android/.test(ua);

    res.render('invite', {
      valid: true,
      senderName: data.senderDisplayName,
      senderCity: data.senderCity,
      token: req.params.token,
      isIOS,
      isAndroid,
      appStoreUrl: 'https://apps.apple.com/app/id6760045281'
    });
  } catch (err) {
    console.error('Invite lookup error:', err);
    res.status(500).render('invite', { valid: false });
  }
});

app.listen(80, () => console.log('Server running on port 80'));
```

### EJS invite template (views/invite.ejs)
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <% if (valid) { %>
  <meta property="og:title" content="<%= senderName %> invited you to FriendsCast">
  <meta property="og:description" content="See the weather where <%= senderName %> is in <%= senderCity %>">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://apps.sandenskog.se/invite/<%= token %>">
  <% } else { %>
  <meta property="og:title" content="FriendsCast - Weather + Friends">
  <% } %>
  <title>FriendsCast Invite</title>
</head>
<body>
  <!-- Invite content here -->
</body>
</html>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom URL schemes (`hotandcold://`) | Universal Links (HTTPS) | iOS 9+, men best practice sedan iOS 14 | Battre sakerhet, fungerar i fler kontexter |
| Silent clipboard reading | UIPasteboard med paste-banner | iOS 16 (2022) | Anvandaren maste godkanna paste |
| Firebase Dynamic Links | Egen implementation / Branch.io | Firebase Dynamic Links deprecated 2025 | Maste bygga eget eller anvanda tredjepartstjanst |
| AASA med `paths` array | AASA med `components` array i `details` | iOS 13+ | Mer flexibel path-matchning |

**Deprecated/outdated:**
- **Firebase Dynamic Links:** Avvecklade 2025. Projektet bygger ratt genom att implementera egna Universal Links + clipboard-baserad deferred deep linking.
- **`paths` i AASA:** Fortfarande fungerande men `details` + `components` ar det moderna formatet.

## Open Questions

1. **Firebase service account for server-side Firestore**
   - What we know: firebase-admin SDK kraver en service account JSON-fil
   - What's unclear: Finns det redan en service account for projektet? Maste skapas i Firebase Console.
   - Recommendation: Skapa en ny service account med enbart Firestore-lasratigheter. Konfigureras vid deploy, committas aldrig.

2. **Associated Domains i Apple Developer Portal**
   - What we know: Capability maste aktiveras i bade project.yml/entitlements OCH i Apple Developer Portal
   - What's unclear: Kan detta goras via CLI/Fastlane eller kravs manuellt?
   - Recommendation: Richard behovs for att aktivera capability i Apple Developer Portal (developer.apple.com > Identifiers > App ID > Associated Domains)

3. **Invite-token skapande vid account creation**
   - What we know: Idag skapas token on-demand nar anvandaren klickar "Generate invite link"
   - What's unclear: Hur migrera befintliga anvandare som redan har konton men ingen permanent invite-kod?
   - Recommendation: Skapa invite-token lazily -- vid forsta anrop, inte vid account creation. Spara token pa user-dokumentet for snabb uppslagning.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (inbyggt i Xcode) |
| Config file | Inget separat -- XCTest ar integrerat i Xcode |
| Quick run command | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HotAndColdFriendsTests` |
| Full suite command | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INVT-01 | Universal Link URL parsed correctly by onOpenURL | unit | Manual test via Xcode deep link simulation | No -- Wave 0 |
| INVT-02 | Web fallback renders correct OG tags per token | integration | `curl -s https://apps.sandenskog.se/invite/testtoken \| grep og:title` | No -- Wave 0 |
| INVT-03 | Invite doc preserved after redemption, redeemedBy updated | unit | XCTest for InviteService.redeemInvite | No -- Wave 0 |
| INVT-04 | Clipboard token extracted and redeemed after signup | unit | XCTest for clipboard parsing logic | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Manual test av specifik funktionalitet
- **Per wave merge:** Full test av invite-flode (skapa token -> dela -> oppna lank -> fallback/app)
- **Phase gate:** End-to-end test: skicka invite via iMessage, oppna pa enhet utan appen, installera, verifiera vanskap skapas

### Wave 0 Gaps
- [ ] Testinfrastruktur saknas helt -- inget test-target existerar i projektet
- [ ] For denna fas ar manuell testning mest relevant (Universal Links, clipboard, web fallback)
- [ ] Enhetstester for InviteService-refaktoreringen kan skrivas men kraver test-target i project.yml
- [ ] Web-server-tester kan skrivas med `supertest` (Node.js) for Express-routes

## Sources

### Primary (HIGH confidence)
- Befintlig kod: `InviteService.swift`, `HotAndColdFriendsApp.swift`, `AddFriendSheet.swift`, `ProfileView.swift` -- direkt lasning
- `project.yml` -- Xcode-projektstruktur, entitlements, dependencies
- `website/` -- Befintlig statisk webbsida-struktur

### Secondary (MEDIUM confidence)
- [Apple Developer: Supporting Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app) -- AASA-format, entitlements
- [Apple Developer: Supporting Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains) -- Associated Domains konfiguration
- [Hacking with Swift: onContinueUserActivity](https://www.hackingwithswift.com/quick-start/swiftui/how-to-continue-an-nsuseractivity-in-swiftui) -- Verifierat att iOS Universal Links gar via onOpenURL
- [Branch: iOS 16 Pasteboard](https://www.branch.io/resources/blog/everything-you-need-to-know-about-ios-16-and-pasteboard-opt-ins/) -- Paste-banner beteende
- [Medium: Deferred Deep Links with Clipboard](https://medium.com/@jongchanko/ios-implementing-deferred-deep-links-with-clipboard-5aad094d0edb) -- Clipboard-baserad deferred deep link implementering

### Tertiary (LOW confidence)
- Ingen -- alla kritiska pastaenden ar verifierade med officiella kallor eller befintlig kod

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Befintlig Swift/Firebase-stack, Express ar standard for Node.js
- Architecture: HIGH -- AASA-format, Universal Links, clipboard-monster ar val dokumenterade
- Pitfalls: HIGH -- Baserat pa Apples dokumentation och community-erfarenhet
- Web server: MEDIUM -- Migrering fran nginx till Node.js pa Synology NAS ar projketspecifik

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stabil -- Universal Links och AASA ar stabila API:er)
