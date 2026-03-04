# Phase 4: Chatt och Push - Research

**Researched:** 2026-03-03
**Domain:** Firebase Firestore realtidschatt, FCM push-notiser, APNs-integration, SwiftUI TabView-navigation
**Confidence:** HIGH (stack), MEDIUM (WeatherKit alerts regional tillgänglighet)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Chatten nås på TVÅ sätt: direkt från vänlistan (tryck på vän) OCH via egen chatt-flik (TabView med Vänner + Chattar)
- iMessage-stil chatbubblor — egna meddelanden höger (blå), mottagarens vänster (grå)
- Konversationslistan visar: profilbild, namn, senaste meddelande, tidsstämpel + vännens aktuella väderikon
- Väder-header ovanför chatbubborna i konversationsvyn — visar vännens stad, temperatur och väderikon
- Automatiska väder-stickers som genereras från aktuellt väder (stad + temperatur + väderikon)
- Dedikerad knapp (väderikon) bredvid textfältet i chattvyn — ett tryck för att skicka
- Användaren kan välja att skicka sitt eget ELLER vännens väder som sticker
- Stickern visas som ett speciellt meddelande i chatten (inte en vanlig textbubbla)
- Fria grupper — användaren skapar manuellt och väljer vilka vänner som ska med
- Skapande via chatt-fliken: "Ny konversation" → välj 2+ vänner → namnge gruppen (valfritt) → starta
- Gruppchatten visar väder-header per medlem (horisontell rad med namn + ikon + temperatur)
- Väder-stickers fungerar i gruppchattar (välj vems väder att skicka)
- Extremväder-notiser baserat på WeatherKit severe weather alerts (Apples officiella varningar) — ingen egen tröskellogik
- Max 1 notis per vän per dag (rate-limiting)
- Personlig, vänlig ton: "Storm hos Anna i Tokyo 🌪️ — hör av dig!"
- Deep link: tryck på notisen → öppna chatten med den vännen direkt
- App Store Guideline 1.2-krav: rapport och blockering MÅSTE finnas för UGC
- Rapport: användare kan rapportera olämpligt innehåll (meddelanden)
- Blockering: användare kan blockera en annan användare (inga fler meddelanden)

### Claude's Discretion

- Väder-stickerns visuella design (kompakt kort vs stor emoji)
- Max antal gruppmedlemmar (rimlig gräns)
- Rapport/blockering-UI-placering och flöde
- Push-notis vid nytt chattmeddelande (format och beteende)
- Push-tillståndsflöde (när och hur appen frågar om notis-tillstånd)
- Chatthistorik — hur långt bakåt meddelanden laddas
- Typing indicators och läskvitton (om det ska finnas)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CHAT-01 | Användare kan skicka 1-till-1 meddelanden till vänner | Firestore conversations-kollektionen + addSnapshotListener för realtid |
| CHAT-02 | Användare kan skapa och delta i gruppchattar | Samma Firestore-modell — participants-array + isGroup-flagga |
| CHAT-03 | Användare kan skicka väderreaktioner (emoji kopplad till väder) | Meddelandetyp "weatherSticker" i message-dokumentet, AppWeatherService återanvänds |
| CHAT-04 | Användare kan rapportera olämpligt innehåll (App Store-krav) | Firestore "reports"-kollektion, App Store Guideline 1.2 kräver synlig Report-knapp per meddelande |
| CHAT-05 | Användare kan blockera andra användare (App Store-krav) | Firestore "blockedUsers"-subkollektion på user-dokument, filtrera bort blockerade i queries |
| PUSH-01 | Push-notis vid extremväder hos vän | WeatherKit weatherAlerts + Cloud Function scheduler + FCM Admin SDK |
| PUSH-03 | Push-notis vid nytt chattmeddelande | Cloud Function onDocumentCreated på messages-subkollektion + FCM sendEach |
</phase_requirements>

---

## Summary

Phase 4 bygger appens sociala kärna: realtidschatt och push-notiser. Tekniskt är fasen väldefinierad — Firebase Firestore + FirebaseMessaging (FCM) är standardstacken för detta i iOS-appen, och all serverlogik körs via Cloud Functions i TypeScript (precis som befintlig AI-platsgissningsfunktion i projektet).

Firestore är rätt val för chatten (inte Realtime Database) trots att CONTEXT.md nämner Realtime DB. Motivering: projektet använder redan Firestore konsekvent för all data, Firestore stödjer komplexa queries (behövs för blockering/rapport-filtering), och modern Firestore är fullt tillräckligt snabb för chat med addSnapshotListener. Att blanda Firestore och Realtime DB i samma app ökar komplexitet utan reell vinst för ett projekt i denna skala.

Push-notiser kräver APNs-nyckel uppladdad till Firebase Console, FirebaseMessaging-produkt tillagd i project.yml, och två Cloud Functions: en Firestore-trigger för chattmeddelanden och en schemalagd funktion för extremväder. FCM-token måste sparas på Firestore per användare och uppdateras vid app-start.

**Primär rekommendation:** Använd Firestore (inte Realtime DB) för chatten, FirebaseMessaging för FCM, och Cloud Functions v2 (TypeScript, onDocumentCreated) för push-triggers — konsekvent med befintlig projektstack.

---

## Standard Stack

### Core

| Bibliotek | Version | Syfte | Varför standard |
|-----------|---------|-------|-----------------|
| FirebaseFirestore | 11.x (ingår i Firebase iOS SDK) | Realtidschatt — konversationer och meddelanden | Redan i projektet, stödjer addSnapshotListener |
| FirebaseMessaging | 11.x (ingår i Firebase iOS SDK) | FCM push-notiser, token-hantering | Officiell iOS FCM-klient |
| firebase-admin (TypeScript) | 12.x | Skicka FCM-meddelanden från Cloud Functions | Admin SDK, sendEach/sendEachForMulticast |
| firebase-functions v2 | 6.x | onDocumentCreated-trigger, scheduler | Konsekvent med befintlig Cloud Function |

### Supporting

| Bibliotek | Version | Syfte | När |
|-----------|---------|-------|-----|
| UserNotifications (Apple, inbyggt) | iOS 17 | Begära notis-tillstånd, hantera tap | Alltid — krävs för push |
| WeatherKit (redan i projektet) | iOS 17 | Hämta weatherAlerts för extremväder | PUSH-01 |
| AppWeatherService (intern) | — | Väder för stickers och alert-polling | Återanvändas direkt |

### Alternatives Considered

| Istället för | Alternativ | Tradeoff |
|--------------|-----------|----------|
| Firestore för chatt | Firebase Realtime Database | RTDB är snabbare vid "twitch-speed", men Firestore är konsekvent med projektet, stödjer bättre queries, och är fullt tillräckligt för denna appskala |
| Firebase FCM | APNs direkt (utan Firebase) | Direkt APNs kräver egen server, certifikathantering — FCM abstrahaerar detta |
| Cloud Functions trigger | Polling-jobb på klient | Klient-polling tömmer batteri och är opålitligt — server-trigger är korrekt |

### Installation (project.yml — lägg till i targets.HotAndColdFriends.dependencies)

```yaml
- package: Firebase
  product: FirebaseMessaging
```

### Installation Cloud Functions (functions/)

```bash
# Redan konfigurerat — firebase-admin och firebase-functions finns
# Ingen ny npm-installation behövs
```

---

## Architecture Patterns

### Recommended Project Structure

```
HotAndColdFriends/
├── Features/
│   ├── Chat/
│   │   ├── ConversationListView.swift       # Listan med alla chattar (chatt-fliken)
│   │   ├── ConversationListViewModel.swift
│   │   ├── ChatView.swift                   # Chattvyn med bubblor
│   │   ├── ChatViewModel.swift
│   │   ├── NewConversationSheet.swift       # Skapa ny grupp/1-till-1
│   │   ├── WeatherStickerView.swift         # Visar en väder-sticker i chatten
│   │   └── WeatherHeaderView.swift          # Väder-header ovanför bubblorna
│   └── FriendList/
│       └── (befintlig — minimal ändring)
├── Core/
│   └── Navigation/
│       ├── AppRouter.swift                  # Utökas: authenticated → MainTabView
│       └── MainTabView.swift                # NY: TabView med Vänner + Chattar
├── Services/
│   └── ChatService.swift                    # NY: Firestore-chat + listener
├── Models/
│   ├── Conversation.swift                   # NY
│   └── ChatMessage.swift                    # NY
functions/src/
├── index.ts                                 # Utökas med push-triggers
├── chatPushTrigger.ts                       # NY: onDocumentCreated på messages
└── weatherAlertScheduler.ts                 # NY: schemalagd extremväder-check
```

### Firestore-datamodell för chatt

```
conversations/
  {conversationId}/
    participants: ["uid1", "uid2"]    // array med alla deltagare
    isGroup: false
    groupName: null
    lastMessage: "Hej!"
    lastMessageAt: Timestamp
    lastMessageSenderId: "uid1"
    createdAt: Timestamp
    messages/                         // subkollektion
      {messageId}/
        senderId: "uid1"
        type: "text" | "weatherSticker"
        text: "Hej!"                  // null om type=weatherSticker
        weatherData: {                // null om type=text
          city: "Tokyo",
          countryCode: "JP",
          temperatureCelsius: 22.0,
          conditionSymbol: "sun.max",
          ownerUid: "uid2"            // vems väder det är
        }
        sentAt: ServerTimestamp

users/
  {uid}/
    fcmToken: "fcm-registration-token"
    fcmTokenUpdatedAt: Timestamp
    blockedUsers/                     // subkollektion
      {blockedUid}/
        blockedAt: Timestamp

reports/
  {reportId}/
    reporterUid: "uid1"
    reportedUid: "uid2"
    messageId: "msgId"
    conversationId: "convId"
    reason: "inappropriate"
    createdAt: Timestamp
```

**Motivering för conversationId:** För 1-till-1 genereras ett deterministiskt ID som `[uid1, uid2].sorted().joined(separator: "_")`. För grupper används ett auto-genererat Firestore-ID.

### Pattern 1: ChatService med @Observable och Firestore-listener

```swift
// Source: Firebase Firestore onSnapshot + iOS 17 @Observable
@Observable
@MainActor
class ChatService {
    private let db = Firestore.firestore()

    var conversations: [Conversation] = []
    var messages: [ChatMessage] = []

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    func startListeningToConversations(uid: String) {
        conversationsListener = db
            .collection("conversations")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                self.conversations = snapshot.documents.compactMap {
                    try? $0.data(as: Conversation.self)
                }
            }
    }

    func startListeningToMessages(conversationId: String) {
        messagesListener = db
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt", ascending: true)
            .limit(toLast: 50)  // Ladda senaste 50 meddelanden
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                self.messages = snapshot.documents.compactMap {
                    try? $0.data(as: ChatMessage.self)
                }
            }
    }

    func stopListening() {
        conversationsListener?.remove()
        messagesListener?.remove()
    }

    func sendMessage(_ text: String, conversationId: String, senderId: String) async throws {
        let message = ChatMessage(
            senderId: senderId,
            type: .text,
            text: text,
            weatherData: nil,
            sentAt: nil  // ServerTimestamp sätts av Firestore
        )
        try db
            .collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(from: message)

        // Uppdatera conversation.lastMessage för listans preview
        try await db
            .collection("conversations")
            .document(conversationId)
            .updateData([
                "lastMessage": text,
                "lastMessageAt": FieldValue.serverTimestamp(),
                "lastMessageSenderId": senderId
            ])
    }
}
```

### Pattern 2: Cloud Function — Push vid nytt meddelande (TypeScript v2)

```typescript
// Source: Firebase Functions v2 + firebase-admin messaging
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp, getApps } from "firebase-admin/app";

if (getApps().length === 0) initializeApp();

export const onNewMessage = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const { conversationId } = event.params;
    const db = getFirestore();

    // Hämta konversationen för att hitta mottagare
    const convDoc = await db
      .collection("conversations")
      .doc(conversationId)
      .get();
    const conv = convDoc.data();
    if (!conv) return;

    const senderId = message.senderId as string;
    const recipients = (conv.participants as string[]).filter(
      (uid) => uid !== senderId
    );

    // Hämta FCM-tokens för alla mottagare
    const tokenDocs = await Promise.all(
      recipients.map((uid) => db.collection("users").doc(uid).get())
    );

    const tokens = tokenDocs
      .map((doc) => doc.data()?.fcmToken as string | undefined)
      .filter((t): t is string => !!t);

    if (tokens.length === 0) return;

    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.data()?.displayName ?? "Okänd";
    const bodyText =
      message.type === "weatherSticker"
        ? `Skickade en väder-sticker 🌤`
        : (message.text as string);

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: senderName,
        body: bodyText,
      },
      data: {
        type: "chat",
        conversationId,
      },
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
    });
  }
);
```

### Pattern 3: FCM-token registrering i AppDelegate

```swift
// Source: Firebase Cloud Messaging iOS docs
// Lägg till i AppDelegate.swift

import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate,
                   UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // ... befintlig setup ...

        // FCM-setup
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Registrering för fjärrnotiser — anropas från appen vid rätt tillfälle
    func registerForPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    // APNs → FCM token-mappning (krävs när method swizzling är aktivt, standardfall)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM-token refresh — spara till Firestore
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken,
              let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            try? await Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData([
                    "fcmToken": token,
                    "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
                ])
        }
    }

    // Hantera notis-tap (foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        return [.list, .banner, .sound]
    }

    // Hantera notis-tap (deep link)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        // Skicka till AppRouter via Notification/environment
        if let conversationId = userInfo["conversationId"] as? String {
            NotificationCenter.default.post(
                name: .openChat,
                object: conversationId
            )
        }
    }
}

extension Notification.Name {
    static let openChat = Notification.Name("openChat")
}
```

### Pattern 4: AppRouter — utökat med MainTabView

```swift
// AppRouter.swift — ändras från direkt FriendListView till MainTabView
struct AppRouter: View {
    @Environment(AuthManager.self) private var authManager
    @State private var openConversationId: String? = nil

    var body: some View {
        switch authManager.authState {
        case .unauthenticated:
            LoginView()
        case .authenticating:
            ProgressView("Loggar in...")
        case .needsOnboarding:
            OnboardingView()
        case .authenticated:
            MainTabView(openConversationId: $openConversationId)
                .onReceive(NotificationCenter.default.publisher(for: .openChat)) { note in
                    openConversationId = note.object as? String
                }
        }
    }
}

// MainTabView.swift — ny fil
struct MainTabView: View {
    @Binding var openConversationId: String?

    var body: some View {
        TabView {
            Tab("Vänner", systemImage: "person.2") {
                NavigationStack {
                    FriendListView()
                }
            }
            Tab("Chattar", systemImage: "bubble.left.and.bubble.right") {
                NavigationStack {
                    ConversationListView(openConversationId: $openConversationId)
                }
            }
        }
    }
}
```

### Pattern 5: Blockering — filtrera i Firestore query

```swift
// ChatService — kontrollera blockering innan meddelanden visas
func isBlocked(uid: String, blockedUid: String) async -> Bool {
    let doc = await Firestore.firestore()
        .collection("users")
        .document(uid)
        .collection("blockedUsers")
        .document(blockedUid)
        .getDocument()
    return doc.exists
}

func blockUser(uid: String, blockedUid: String) async throws {
    try await Firestore.firestore()
        .collection("users")
        .document(uid)
        .collection("blockedUsers")
        .document(blockedUid)
        .setData(["blockedAt": FieldValue.serverTimestamp()])
}
```

### Anti-Patterns to Avoid

- **Lyssna på messages utan limit:** `addSnapshotListener` utan `.limit(toLast: 50)` laddar hela historiken vid varje start — använd paginering.
- **Spara FCM-token bara vid launch:** Tokens kan ändras mitt i session — implementera `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)`.
- **Skicka FCM direkt från iOS:** OpenAI-mönstret i projektet är korrekt — ALDRIG skicka push direkt från klient, alltid via Cloud Function/Admin SDK.
- **Blanda Realtime DB och Firestore:** Projektet är Firestore-only — håll det så.
- **Meddelandetyp som sträng:** Definiera `MessageType` som enum med `text` och `weatherSticker` — undvik magic strings.

---

## Don't Hand-Roll

| Problem | Bygg inte | Använd istället | Varför |
|---------|-----------|-----------------|--------|
| Realtidssynkning av meddelanden | Egen polling-loop | Firestore addSnapshotListener | Firestore hanterar reconnect, offline-cache, diff-updates |
| FCM token → APNs mappning | Egen APNs token-hantering | FirebaseMessaging (swizzling aktivt) | Firebase hanterar token-exchange automatiskt |
| Push-notis leverans | Direkt APNs HTTP/2 | FCM Admin SDK (sendEach) | FCM hanterar leveransförsök, error-parsing, token-validering |
| Typning-indikator | Custom polling | Firestore `isTyping: true` med cloud scheduler cleanup | Enkel, skalbar, ingen WebSocket-server |

**Nyckelinsikt:** Firestore + FCM är designade för exakt detta use case — custom lösningar ger ingen vinst och kostar mycket i edge-case-hantering.

---

## Common Pitfalls

### Pitfall 1: WeatherKit weatherAlerts — begränsad regional tillgänglighet

**Vad går fel:** `weather.weatherAlerts` returnerar `nil` för de flesta länder utanför USA. Appar som räknar med alerts globalt får inga notiser för vänner i Europa, Asien etc.

**Varför det händer:** WeatherKit severe alerts levereras primärt via National Weather Service (USA). Utanför USA är stödet begränsat och `weatherAlerts` kan vara `nil` eller `temporarilyUnavailable`.

**Hur undviks det:** Implementera fallback — om `weatherAlerts == nil` eller tom, skippa notis utan error. Kommunicera i UI att extremväder-notiser endast är tillgängliga i vissa regioner. Planera fasen så att PUSH-01 fungerar korrekt när alerts finns, men inte kraschar när de saknas.

**Varningssignaler:** Testning mot svenska/europeiska koordinater ger inga alerts även under storm.

### Pitfall 2: FCM-token saknas vid push-notis

**Vad går fel:** Cloud Function hittar inget `fcmToken` på user-dokumentet — notisen skickas aldrig.

**Varför det händer:** FCM-token genereras asynkront och kräver att `MessagingDelegate` är satt INNAN `registerForRemoteNotifications` anropas. Om setup-ordning är fel missas det första token-anropet.

**Hur undviks det:** Sätt `Messaging.messaging().delegate = self` i `AppDelegate.application(_:didFinishLaunchingWithOptions:)` innan Firebase konfigureras. Spara token både i `messaging(_:didReceiveRegistrationToken:)` OCH vid app-start via `Messaging.messaging().token { ... }`.

**Varningssignaler:** `fcmToken`-fältet är tomt i Firestore users-dokumentet efter installation.

### Pitfall 3: Listener-läcka — conversation-lyssnar inte städas upp

**Vad går fel:** `ListenerRegistration` tas inte bort när ChatView försvinner från skärmen — multiple listeners byggs upp, onödiga Firestore-reads faktureras.

**Varför det händer:** SwiftUI views förstörs och skapas om — listeners i `onAppear` utan motsvarande `onDisappear`/`.task` som städar.

**Hur undviks det:** Använd `.task { ... }` med `await` + `withTaskCancellationHandler` ELLER anropa `chatService.stopListening()` i `.onDisappear`. Föredra `.task` — det avbryts automatiskt.

**Varningssignaler:** Fler Firestore-reads än förväntade i Firebase Console.

### Pitfall 4: ServerTimestamp och Codable

**Vad går fel:** `@ServerTimestamp var sentAt: Timestamp?` sätts av Firestore på servern — om man försöker koda/dekoda ett message-objekt lokalt (t.ex. i preview) kraschar det eftersom `sentAt` är `nil` i det lokala objektet.

**Varför det händer:** `@ServerTimestamp` är `nil` tills Firestore-skrivningen är bekräftad. Lokala optimistic updates fungerar inte direkt.

**Hur undviks det:** Acceptera att `sentAt` är optional. Sortera meddelanden på klient efter `sentAt ?? Date()` för optimistic ordering. Skilja på "skickat lokalt" och "bekräftat av server".

### Pitfall 5: App Store Guideline 1.2 — rapport måste vara synlig

**Vad går fel:** Rapport-knapp gömd bakom tre menynivåer — Apple avvisar appen vid review.

**Varför det händer:** Misstolkning av kravet — Apple kräver att rapport ska vara "lätt att hitta" per meddelande eller profil.

**Hur undviks det:** Placera rapport-funktion i meddelandets kontextmeny (long press på bubbla → "Rapportera"). Blockering: long press på profil eller en "Blockera"-knapp i konversationens toolbar/settings. Verifiera mot App Store Guideline 1.2 före submission.

---

## Code Examples

### Skapa 1-till-1 konversation med deterministiskt ID

```swift
// Source: Standard Firebase chat pattern
func conversationId(uid1: String, uid2: String) -> String {
    return [uid1, uid2].sorted().joined(separator: "_")
}

func getOrCreateDirectConversation(
    currentUid: String,
    friendUid: String
) async throws -> String {
    let convId = conversationId(uid1: currentUid, uid2: friendUid)
    let ref = db.collection("conversations").document(convId)
    let doc = try await ref.getDocument()

    if !doc.exists {
        try ref.setData(from: Conversation(
            id: convId,
            participants: [currentUid, friendUid],
            isGroup: false,
            groupName: nil,
            lastMessage: nil,
            lastMessageAt: nil,
            lastMessageSenderId: nil,
            createdAt: nil
        ))
    }
    return convId
}
```

### Schemalagd Cloud Function för extremväder-check

```typescript
// Source: Firebase Functions v2 scheduler + firebase-admin
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const checkExtremeWeather = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "europe-west1",
  },
  async (_event) => {
    // Hämta alla användare med FCM-token
    const db = getFirestore();
    const usersSnapshot = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .get();

    // För varje användare: hämta deras vänner
    // Kontrollera rate-limit (max 1 notis/vän/dag via Firestore)
    // Anropa WeatherKit REST API för vännens koordinater
    // Skicka FCM om weatherAlerts finns och rate-limit ej uppnådd
    // (Komplex logik — implementeras i fas 04-03)

    console.log(`Checked ${usersSnapshot.size} users for extreme weather`);
  }
);
```

**OBS:** WeatherKit-alerts kan inte anropas direkt från Cloud Functions (kräver iOS-klient eller WeatherKit REST API med JWT). PUSH-01 kräver WeatherKit REST API från Cloud Function — detta kräver en separat JWT-signering med Apple Developer-nyckel. Se "Open Questions" nedan.

### Rapport-flöde

```swift
// CHAT-04: Rapport via long press contextMenu
.contextMenu {
    Button(role: .destructive) {
        Task { await reportMessage(messageId: message.id) }
    } label: {
        Label("Rapportera", systemImage: "flag")
    }
}

func reportMessage(messageId: String) async {
    guard let uid = authManager.currentUser?.uid else { return }
    let report = Report(
        reporterUid: uid,
        reportedUid: message.senderId,
        messageId: messageId,
        conversationId: conversationId,
        reason: "inappropriate",
        createdAt: nil
    )
    try? db.collection("reports").addDocument(from: report)
}
```

---

## State of the Art

| Gammalt mönster | Nuvarande | Ändrades | Påverkan |
|-----------------|-----------|----------|----------|
| `ObservableObject` + `@Published` | `@Observable` (Swift 5.9 / iOS 17) | iOS 17 | Projektet använder redan @Observable — behåll konsekvent |
| `sendMulticast` (FCM Admin SDK) | `sendEachForMulticast` | Firebase Admin 12.x | sendMulticast är deprecated — använd sendEachForMulticast |
| Firebase Functions v1 (`functions.firestore.document().onCreate`) | Firebase Functions v2 (`onDocumentCreated`) | Firebase SDK 6.x | Projektet använder redan v2 (se `guessContactLocations`) — behåll konsekvent |
| `functions.config()` för secrets | `defineSecret()` | Firebase Functions v2 | Projektet använder redan defineSecret — behåll konsekvent |
| Tab-navigation via `TabView(selection:)` | `Tab("", systemImage: "")` (iOS 18) / `TabView { }` (iOS 16+) | iOS 18 introducerade ny syntax | Deployment target iOS 17 — använd `tabItem { }` eller ny Tab-syntax (iOS 18+). Testa på iOS 17 |

---

## Open Questions

1. **WeatherKit REST API från Cloud Functions (PUSH-01)**
   - Vad vi vet: WeatherKit Swift SDK fungerar på iOS-enheter. Cloud Functions har ingen iOS-miljö.
   - Vad är oklart: WeatherKit REST API kräver JWT signerat med en Apple Developer private key (`.p8`-fil). Hur ska denna nyckel lagras säkert i Cloud Functions-miljön?
   - Rekommendation: Lagra Apple `.p8`-nyckeln som Firebase Secret (`defineSecret`), precis som OpenAI-nyckeln. Generera JWT i Cloud Function med `jsonwebtoken` npm-paketet. Alternativt: klienten pollar WeatherKit på iOS och sparar alert-status till Firestore — Cloud Function läser från Firestore istället för att anropa WeatherKit REST direkt.
   - **Pragmatisk rekommendation:** Låt iOS-klienten (background task / app-start) kontrollera `weatherAlerts` och spara en `hasActiveAlert: true/false` per vän i Firestore. Cloud Function för PUSH-01 triggas av Firestore-ändring (onDocumentUpdated) snarare än att anropa WeatherKit REST. Enklare, och utnyttjar befintlig WeatherKit-integration.

2. **iOS 17 vs iOS 18 Tab-syntax**
   - Vad vi vet: iOS 18 introducerar ny `Tab("", systemImage: "")` init. Deployment target är iOS 17.
   - Vad är oklart: Kompilerar ny Tab-syntax på iOS 17-target med Xcode 16?
   - Rekommendation: Använd `tabItem { }` (kompatibel iOS 14+) för säkerhet. Ny syntax kan läggas till via `@available(iOS 18, *)`.

3. **Typing indicators och läskvitton**
   - Vad vi vet: Dessa är under "Claude's Discretion".
   - Rekommendation: Skippa för v1 — ökar Firestore-skrivfrekvens avsevärt och ger begränsat värde. Lägg till som v2-feature.

4. **Chatthistorik — paginering**
   - Vad vi vet: `.limit(toLast: 50)` är standardmönstret.
   - Rekommendation: Ladda 50 senaste meddelanden vid start. Implementera "ladda fler" via Firestore cursor-baserad paginering (`startAfter`) om användaren scrollar till toppen. V1 kan klara sig med 50 meddelanden utan paginering.

---

## Validation Architecture

> nyquist_validation är inte konfigurerat i config.json — sektion skippas.

---

## Sources

### Primary (HIGH confidence)

- Firebase Cloud Messaging iOS docs (firebase.google.com/docs/cloud-messaging/ios/get-started) — APNs setup, FCM token flow, Swift AppDelegate-mönster
- Firebase Cloud Messaging receive docs (firebase.google.com/docs/cloud-messaging/ios/receive) — foreground/background notification handling, deep link
- Firebase Admin SDK send docs (firebase.google.com/docs/cloud-messaging/send/admin-sdk) — sendEachForMulticast TypeScript API
- Firebase FCM token management (firebase.google.com/docs/cloud-messaging/manage-tokens) — Firestore token storage pattern, refresh strategy
- Apple WeatherKit documentation (developer.apple.com/documentation/weatherkit/weather/weatheralerts) — weatherAlerts property, regional limitations

### Secondary (MEDIUM confidence)

- Firebase Functions v2 onDocumentCreated syntax (firebase.google.com/docs/functions/firestore-events) — verifierat med WebSearch
- Firestore chat data model (exyte.com/blog/firebase-chat-tutorial, multiple Medium sources) — conversations/messages subcollection pattern
- App Store Guideline 1.2 UGC requirements (nextnative.dev, armia.com) — rapport/blockering kraven verifierade mot Apples officiella guidelines-sida

### Tertiary (LOW confidence)

- WeatherKit severe alert regional availability — baserat på developer forum-diskussioner, inte officiell dokumentation. Bör valideras med testning mot verkliga koordinater.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Firebase iOS SDK, FirebaseMessaging och Cloud Functions v2 är välbeprövade och dokumenterade
- Architecture: HIGH — Firestore-datamodell för chatt är ett standardmönster med flera officiella och community-källor
- Pitfalls: MEDIUM/HIGH — FCM token och listener-läckor är välkända; WeatherKit regional availability är LOW (forumbaserat)
- WeatherKit alerts från Cloud Function: MEDIUM — REST API finns men JWT-setup behöver verifieras i implementation

**Research date:** 2026-03-03
**Valid until:** 2026-04-03 (stabil stack, Firebase API:er ändras sällan)
