# S04: Engagement Loops

**Goal:** In-app weather nudges prompt users to message friends, inactive users get re-engagement push, and a notification budget prevents spam.
**Demo:** Friend list shows contextual nudge chips ("It's snowing!" / "Heatwave!") on friends with interesting weather. Users inactive 3+ days receive a push. Non-chat push notifications are capped per user per week.

## Must-Haves

- WeatherNudgeService generates contextual nudge text from weather conditions
- Nudge chips displayed inline on FriendRowView for qualifying friends
- Cloud Function: re-engagement push for users inactive 3+ days
- Cloud Function: notification budget tracking with weekly per-user cap
- Existing push senders (weatherAlertTrigger, daily notification) respect the budget

## Verification

- `xcodebuild -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds
- `cd functions && npm run build` succeeds
- WeatherNudgeService returns non-nil nudge text for extreme/interesting weather conditions
- FriendRowView shows nudge chip when nudge text is present
- Re-engagement Cloud Function compiles and exports correctly
- Notification budget Cloud Function compiles and exports correctly

## Tasks

- [x] **T01: WeatherNudgeService and nudge chips on friend rows** `est:20m`
  - Why: ENGM-01 — contextual weather nudges encourage users to contact friends
  - Files: `HotAndColdFriends/Services/WeatherNudgeService.swift`, `HotAndColdFriends/Features/FriendList/FriendRowView.swift`
  - Do:
    1. Create WeatherNudgeService with a static `nudge(for: FriendWeather) -> String?` method. Return a short nudge string for interesting weather conditions: temperature extremes (>35° "🔥 Heatwave!", <-10° "🥶 Freezing!"), precipitation ("🌧️ Rainy day", "❄️ It's snowing!"), thunderstorm ("⛈️ Thunderstorm!"), clear hot day ("☀️ Perfect beach weather!"). Return nil for unremarkable weather (10-25°, partly cloudy, etc.). Keep nudges short (2-4 words + emoji).
    2. Add an optional nudge chip to FriendRowView: below the city name, show the nudge text in a small capsule with the temperature zone's color as background. Only render when WeatherNudgeService.nudge returns non-nil. Use `.bubbleFootnote` font, padding xs/sm, Capsule clip.
  - Verify: Xcode build succeeds. FriendRowView shows nudge for extreme temperatures/weather.
  - Done when: Friends with interesting weather show a contextual nudge chip in the list

- [x] **T02: Re-engagement push Cloud Function** `est:20m`
  - Why: ENGM-02 — bring back users who haven't opened the app in 3+ days
  - Files: `functions/src/reEngagementPush.ts`, `functions/src/index.ts`
  - Do:
    1. Create `functions/src/reEngagementPush.ts` exporting a scheduled Cloud Function `sendReEngagementPush` running daily at 10:00 CET.
    2. Query all users with `lastActiveAt` older than 3 days (or missing) who have a valid `fcmToken`.
    3. For each qualifying user, fetch their top favorite friend's weather info (displayName only — no weather API call from server). Send a push: title "Miss your friends? 👋", body "See what the weather is like for [friendName] today". Include `data: { type: "reEngagement" }`.
    4. Track `lastReEngagementPushAt` on the user document to avoid sending more than once per 7 days.
    5. Export from index.ts.
  - Verify: `cd functions && npm run build` succeeds. Function exported in index.ts.
  - Done when: Scheduled function compiles, queries inactive users, sends push with friend name

- [x] **T03: Notification budget Cloud Function** `est:20m`
  - Why: ENGM-03 — prevent notification fatigue by capping non-chat push per user per week
  - Files: `functions/src/notificationBudget.ts`, `functions/src/index.ts`, `functions/src/weatherAlertTrigger.ts`, `functions/src/reEngagementPush.ts`
  - Do:
    1. Create `functions/src/notificationBudget.ts` exporting `canSendNotification(uid: string): Promise<boolean>` and `recordNotification(uid: string): Promise<void>`. Budget tracked in Firestore `users/{uid}` document field `notificationBudget: { count: number, weekStart: Timestamp }`. Max 5 non-chat notifications per week. Week resets on Monday 00:00 UTC.
    2. Update `weatherAlertTrigger.ts`: before sending push, call `canSendNotification(uid)`. If budget exhausted, skip push. After successful send, call `recordNotification(uid)`.
    3. Update `reEngagementPush.ts`: same budget check before sending.
    4. Chat push (`chatPushTrigger.ts`) is NOT subject to budget — real-time messages are always delivered.
    5. Update `functions/src/index.ts` — `notificationBudget` helper is not exported as a Cloud Function (it's an internal module).
  - Verify: `cd functions && npm run build` succeeds. Budget functions imported in weatherAlertTrigger and reEngagementPush.
  - Done when: Non-chat push notifications check and respect per-user weekly budget

- [x] **T04: Track lastActiveAt on user document** `est:10m`
  - Why: Re-engagement push depends on knowing when the user last opened the app
  - Files: `HotAndColdFriends/App/HotAndColdFriendsApp.swift`, `HotAndColdFriends/Services/UserService.swift`
  - Do:
    1. Add a `updateLastActive(uid: String)` method to UserService that sets `lastActiveAt: FieldValue.serverTimestamp()` on the user document.
    2. Call it from HotAndColdFriendsApp's `.task` block after the existing startup logic — fire-and-forget, no error handling needed.
    3. This provides the data the re-engagement Cloud Function reads.
  - Verify: Xcode build succeeds. UserService has updateLastActive method.
  - Done when: User's lastActiveAt is updated on each app launch

## Files Likely Touched

- `HotAndColdFriends/Services/WeatherNudgeService.swift` (new)
- `HotAndColdFriends/Features/FriendList/FriendRowView.swift` (modified)
- `HotAndColdFriends/Services/UserService.swift` (modified)
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` (modified)
- `functions/src/reEngagementPush.ts` (new)
- `functions/src/notificationBudget.ts` (new)
- `functions/src/weatherAlertTrigger.ts` (modified)
- `functions/src/index.ts` (modified)
