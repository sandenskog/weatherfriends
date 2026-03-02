# Pitfalls Research

**Domain:** Social weather iOS app with friend-import, AI location inference, real-time chat, push notifications
**Researched:** 2026-03-02
**Confidence:** HIGH (social API restrictions, App Store rules) / MEDIUM (weather API cost patterns, Firebase scaling) / LOW (AI inference cost at scale)

---

## Critical Pitfalls

### Pitfall 1: Social Platform Friend-Import Is Effectively Dead

**What goes wrong:**
The app is designed around importing friends from Facebook, Instagram, and Snapchat. In practice, none of these platforms expose a friend list or contact discovery API to third-party apps. Instagram Basic Display API was killed December 4, 2024. Meta Graph API only works with Business/Creator accounts — not regular consumer accounts. Snapchat Kit gives OAuth login and Bitmoji but no friend list access. Building the import flow assuming API access works leads to a dead-end and a complete pivot in the middle of development.

**Why it happens:**
Developers read outdated tutorials or assume "login with X" equals "read friends from X." These are entirely separate permission scopes. Meta tightened access after Cambridge Analytica, and the 2024 Basic Display EOL removed the last consumer-facing read access.

**How to avoid:**
Design the friend-import flow around what is actually available today:
- **Facebook/Instagram Login:** You can authenticate the user and get their name + email only. Use this as identity verification, not contact discovery.
- **Phone contacts import** (iOS Contacts framework): The user's phone contact book can be cross-referenced against registered users in your own database. This is how WhatsApp, Snapchat, and Telegram actually work. Build this as the primary import path.
- **Manual invite by email/link:** Fallback for contacts not yet registered.
- **"Connect accounts" as identity linking:** Social login verifies identity; your own database stores who knows whom.

Validate this design before writing a single line of import logic.

**Warning signs:**
- Any plan referencing `friends` endpoint from Meta Graph API
- Designs that show "import your friends from Instagram" as a single-step action
- No mention of iOS Contacts framework or manual invite flow

**Phase to address:** Phase 1 (foundation/architecture) — before any social feature is built.

---

### Pitfall 2: AI Location Inference Creates Privacy and Legal Exposure

**What goes wrong:**
The app uses AI to guess a friend's city/country from their social profile data (phone number country code, bio text, post locations, etc.). This creates two compounding problems: (1) privacy regulation exposure — inferring location from social data about another person without their consent is legally sensitive in GDPR, CCPA, and growing number of US state laws; (2) App Store rejection — Apple will ask why the app collects and processes social profile data of third parties, and "to guess where they live" is a hard answer to defend.

**Why it happens:**
The value proposition is compelling — fill in unknown locations automatically — so developers implement it without running it past a privacy lawyer or the App Store guidelines. The inference feels technical and innocuous. It is neither.

**How to avoid:**
- The AI guessing should run on data the **user themselves provided or consented to share** — not scraped or inferred from third-party profiles without explicit user consent.
- The correct architecture: **invite friends into the app**, and when they join, they declare their own city. AI-assisted suggestion ("we think you're in Stockholm — correct?") is fine for the joining user, not for passively guessing about non-users.
- For friends who haven't joined yet, show "location unknown" with an invite prompt — this is the correct UX.
- Document in the privacy policy exactly what data is used and for what inference.

**Warning signs:**
- Any code that reads a friend's Instagram bio/location tag to infer city without that friend's consent
- No per-user location consent flow
- AI inference described as "automatic" with no opt-in or correction step

**Phase to address:** Phase 1 (architecture and data model) — consent model must be baked in from the start.

---

### Pitfall 3: App Store Rejection for Missing "Sign in with Apple"

**What goes wrong:**
The app offers Facebook Login and Google Sign-In. Apple requires that any app offering a third-party login must also offer an equivalent privacy-respecting alternative (Sign in with Apple, or another option that limits data collection to name and email and doesn't track for advertising). Submitting without Sign in with Apple when Facebook/Google login are present is a near-certain rejection under Guideline 4.8.

**Why it happens:**
Developers prioritize social logins because they give access to social identity data, and treat Sign in with Apple as optional. It is not optional when third-party logins exist.

**How to avoid:**
Implement Sign in with Apple as a required auth method from the start. Apple's hidden email relay feature (which gives users a masked email) must be handled correctly — the app must accept apple-relay-format email addresses and not reject them during account creation.

**Warning signs:**
- Auth implementation only covers Facebook + Google
- Account creation that validates email format too strictly (rejecting `@privaterelay.appleid.com`)
- Any plan to "add Apple login later before submission"

**Phase to address:** Phase 2 (authentication) — must be in the initial auth implementation, not retrofitted.

---

### Pitfall 4: Firebase Firestore Real-Time Listener Cost Explosion

**What goes wrong:**
The chat feature uses Firestore real-time listeners. Each listener fires a read charge every time any document in the query result set changes. In a social app where users have 10-50 friends each with live weather data updating every 30 minutes, the listener math is brutal: 1,000 users × 20 friends × 48 weather updates/day = nearly 1 million reads/day before a single chat message is sent. On paid tier this costs hundreds of dollars per month at scale.

**Why it happens:**
Firestore listeners feel "free" in development with a handful of test users. The billing only becomes visible at real user counts. Additionally, if offline persistence is enabled and a listener reconnects after >30 minutes offline, Firestore charges for a full re-read as if it's a brand new query.

**How to avoid:**
- Keep weather data out of Firestore real-time listeners. Weather data is **not** user-generated and doesn't need to propagate instantly to friends. Fetch it on-demand or via scheduled Cloud Functions.
- Use Firestore real-time listeners only for actual real-time events: new chat messages, online presence.
- Cache aggressively on device — weather doesn't change meaningfully in 30 minutes.
- Set Firebase budget alerts before going to production (non-negotiable).
- Architect chat subcollections so each user only listens to their active conversations, not all conversations.

**Warning signs:**
- Single top-level listener on a users collection that includes weather fields
- No budget alerts configured in Firebase console
- Weather data updating more than once per hour per friend via listeners
- Offline persistence enabled without understanding the reconnect re-read billing behavior

**Phase to address:** Phase 3 (backend/data architecture) — architecture must be designed before chat is implemented.

---

### Pitfall 5: App Store Rejection for Missing UGC Moderation in Chat

**What goes wrong:**
The app has in-app chat (user-generated content). Apple Guideline 1.2 requires that apps with UGC include: (1) a mechanism to filter or flag objectionable material, (2) a way to report abusive content/users, (3) a way to block users, and (4) published developer contact information for reporting. Missing any of these causes rejection. Guideline 1.2.1(a) (effective November 2025) also requires age-gating mechanisms for UGC apps.

**Why it happens:**
Chat is often built as a pure communication feature. Developers build the message sending/receiving flow and consider it done. The moderation layer is invisible to users in happy-path testing.

**How to avoid:**
Design the report/block system as part of the initial chat feature, not as a post-launch add-on. Minimum viable implementation:
- Long-press message → "Report" option
- User profile → "Block [name]" option
- Support email visible in settings
- Age rating questionnaire completed before submission (Apple deadline was January 31, 2026 for updated questionnaire)

**Warning signs:**
- Chat implementation with no block/report UI
- App info screen with no contact information
- Age rating set to 4+ on a social chat app

**Phase to address:** Phase 4 (chat feature) — moderation must ship with the chat, not after.

---

### Pitfall 6: Push Notifications for Weather Alerts Are Unreliable by Design

**What goes wrong:**
Weather alerts and daily weather summaries are implemented as silent/background push notifications. Silent pushes ("content-available: 1") are explicitly not guaranteed by APNs — iOS can throttle, delay, or drop them based on battery state, whether the user force-quit the app, time of day, and historical app engagement. Users see weather notifications arriving hours late or not at all, with no obvious cause.

**Why it happens:**
Silent push delivery feels reliable in testing (developer device, plugged in, app recently active). Production conditions are far more varied. Additionally, sending more than 2-3 background notifications per hour per user causes APNs to start throttling.

**How to avoid:**
- Use **visible push notifications** for weather alerts (not silent), which have guaranteed delivery.
- For daily summaries, use scheduled notifications fired locally from the app (no server round-trip needed) — more reliable than server push.
- Request notification permissions at a contextually appropriate moment (not on first launch — this kills permission grant rate).
- Test on real devices in airplane mode, then reconnect, to simulate real-world delivery conditions.
- Always set `apns-push-type` header correctly (`alert` vs `background`); missing this causes APNs to drop notifications on iOS 13+.

**Warning signs:**
- Notification permission request on app first launch (before user understands the value)
- Weather update logic that relies exclusively on silent push to trigger
- No fallback for when background refresh is disabled by the user
- Tests only run on simulator or plugged-in developer device

**Phase to address:** Phase 4-5 (notifications) — architecture decision before implementation.

---

### Pitfall 7: Privacy Manifest Missing for Third-Party SDKs

**What goes wrong:**
The app includes SDKs (Firebase, Facebook SDK, potentially analytics tools). Since May 2024, and strictly enforced from February 2025, Apple requires every included third-party SDK to have a privacy manifest file (`PrivacyInfo.xcprivacy`). Apps submitted without these manifests are rejected with `ITMS-91061`. Approximately 12% of App Store submissions in Q1 2025 were rejected for this reason.

**Why it happens:**
Privacy manifests are a new requirement many developers aren't aware of. Older SDK versions don't include them. The error only appears at submission time, not during local testing.

**How to avoid:**
- Use the latest versions of all SDKs (Firebase, FacebookSDK, etc.) — privacy manifests were added in late 2024 versions.
- Run `Xcode → Product → Archive → Validate App` before submitting to catch manifest violations early.
- Audit every third-party dependency with the Apple required SDK list.
- Do a test submission to TestFlight before final App Store submission to surface manifest issues without affecting launch timelines.

**Warning signs:**
- Using Firebase SDK versions older than late 2024 releases
- Any SDK added without checking if it's on Apple's required privacy manifest list
- First submission to App Store being the actual launch version

**Phase to address:** Phase 6 (App Store submission prep) — dedicate a pre-submission audit phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode weather API key in app bundle | Faster setup | Key exposed in binary, can be extracted and abused — rotated key breaks all old versions | Never — use server-side proxy or environment config |
| Store all chat messages in one Firestore document | Simpler queries | Firestore documents have 1MB limit; message history is unbounded | Never for chat history — use subcollections |
| Skip location consent and use device GPS as "your location" | Simpler onboarding | Apple review rejects "Always On" location without justification; battery drain | Acceptable for "While Using" location only |
| Use one weather API key shared by all users | Zero backend cost | Rate limit hit by aggregate traffic; single key abuse locks out everyone | Never in production — proxy through backend |
| Implement invite-only via deep link without server validation | Fast to build | Invite links can be shared publicly, bypassing intended social graph | Acceptable in MVP if abuse is low risk |
| Open Firestore security rules during development | Faster iteration | Rules often never get locked — production data becomes public | Never — use Firebase Emulator Suite instead |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Facebook Login | Expecting to read `friends` list after login | Facebook only returns the subset of friends who also have your specific app installed AND granted friends permission — effectively zero for a new app. Use for identity only. |
| Instagram Graph API | Assuming it works for consumer accounts | Only works for Business/Creator accounts linked to a Facebook Page. Useless for personal account friend discovery. |
| Sign in with Apple | Rejecting `@privaterelay.appleid.com` email format | Accept all email formats at account creation. Never use email as a unique key — use the Apple user ID (`sub` field) instead. |
| Firebase Authentication + Firestore | Assuming auth UID is stable across social re-logins | If a user logs in with Google then later with Apple (same email), Firebase creates two separate users. Implement account linking or enforce single auth provider. |
| OpenWeatherMap free tier | Fetching weather for 50 friends on app open | Free tier is 60 calls/minute. 50 friends × several users simultaneously = rate limit hit immediately. Batch or stagger requests, cache aggressively. |
| APNs device tokens | Storing token once and never updating | APNs tokens change after reinstalls and iOS updates. Always update token on app launch; handle `UNREGISTERED` errors to clean stale tokens. |
| WeatherAPI.com free tier | Assuming unlimited calls | Free tier stops serving data for the entire billing month once the call limit is exceeded. Set up cost alerts and implement graceful degradation. |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Fetching weather for all friends on every app open | Slow load, rate limit errors, battery drain | Cache weather data per friend with 30-minute TTL; only refresh on foreground after TTL expires | At 20+ friends per user |
| Real-time Firestore listener on entire users collection | Massive read counts, high Firebase bill | Scope listeners to only documents the current user owns or is directly involved in | At 500+ users |
| Synchronous geocoding in AI location inference | UI freeze during onboarding import | Run geocoding/AI inference in background Task; show progress UI | Immediately — geocoding is always slow |
| Unmanaged Firestore listeners | Memory leaks, duplicate chat messages appearing | Store listener handles in @StateObject or view model; call `remove()` in `onDisappear` | In complex SwiftUI navigation flows |
| No weather data pagination | Loading all weather history at once | Only load current conditions + 24h forecast; load extended forecast on demand | N/A — architecture decision |
| Sending one push notification per friend's weather change | APNs throttling, notification spam | Batch weather alerts into a daily digest notification; only alert on extreme weather events | At 10+ friends with active weather |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Weather API key in iOS app binary | Key extracted from .ipa file, abused by third parties — you pay the bill | Route all weather API calls through a backend Cloud Function or edge function. Never embed paid API keys in client code. |
| Firestore security rules open to authenticated users | Any authenticated user can read any other user's data, chat messages, location | Write and test security rules from day one. Rule: users can only read/write documents they own or are explicitly listed as participants. |
| Storing friend's inferred location without their knowledge | GDPR violation, App Store privacy policy mismatch, user trust destruction if discovered | Only store location data that the user themselves confirmed or entered. AI inference is a suggestion UI tool only, never silently persisted. |
| No rate limiting on chat messages | Spam/abuse floods other users, Firestore write costs spike | Implement Firebase App Check + server-side rate limiting via Cloud Functions |
| Logging chat message content to analytics | User content in analytics tools violates privacy expectations and potentially GDPR | Never log message content — log only events (message_sent, conversation_opened) with no content payload |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Empty friend list on first open | User sees a blank screen, immediately uninstalls | Show live example data with fictional friends and real weather — PROJECT.md explicitly requires this. Replace with real data as friends join. |
| Requesting notification permission on first launch | ~40% grant rate vs. ~70% if asked at value moment | Ask after user has set up first favorite friend and seen the weather — contextual ask with clear value proposition |
| Requesting "Always On" location permission | High deny rate and App Store scrutiny | Only request "While Using" — you don't need device location in background. Use city input instead of precise GPS for the friend weather use case. |
| Showing "Location Unknown" with no call to action | User confusion, feature feels broken | Turn unknown location into an engagement mechanic: "Tap to invite [name] and see their weather" |
| Friend list sorted alphabetically | Context-free list that misses the core value | Default view must be sorted by weather contrast/temperature delta — the more extreme the difference vs. user's weather, the higher the friend appears |
| Asking for all permissions at onboarding before showing value | Permission fatigue, users deny everything | Show value first (example data), then progressively ask for contacts, notifications, and location as user engages |

---

## "Looks Done But Isn't" Checklist

- [ ] **Friend import:** "Import friends" works in demo — verify it works for real users with zero existing app users in their network (chicken-and-egg check)
- [ ] **Sign in with Apple:** Login appears to work — verify it handles the hidden email relay address and doesn't create duplicate accounts on re-login
- [ ] **Chat moderation:** Chat sends and receives messages — verify Report and Block actions actually exist and function in the UI
- [ ] **Push notifications:** Notifications arrive in simulator — verify delivery on real device with app force-quit and background refresh disabled
- [ ] **Weather caching:** Weather loads correctly — verify what happens when the API is down or rate-limited (graceful degradation, not crash)
- [ ] **Privacy manifest:** App builds and runs — verify `Product → Archive → Validate` passes without ITMS-91061 errors
- [ ] **Account deletion:** App has settings — verify there is an in-app "Delete Account" flow (required by App Store since 2023)
- [ ] **Location consent:** App shows friend weather — verify no friend's location was stored without that friend's explicit consent
- [ ] **Firebase rules:** App works in development — verify security rules reject unauthorized reads before TestFlight

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Social API friend import built wrong | HIGH | Pivot to phone contacts import (iOS Contacts framework) + manual invite. Requires UX redesign but no backend changes. |
| App Store rejected for missing Sign in with Apple | LOW | Add Sign in with Apple (1-2 days). Resubmit. Common and well-documented. |
| App Store rejected for missing UGC moderation | MEDIUM | Build report/block UI (3-5 days). Common, Apple will provide specific guidance in rejection notes. |
| Firebase cost explosion from listener overuse | HIGH | Requires architecture refactor — move weather data to pull model, redesign listener scope. 1-3 weeks. |
| Privacy manifest rejection | LOW | Update SDK versions, add missing manifests (1-2 days). Well-documented fix. |
| AI location inference causes privacy complaint | HIGH | Remove inference feature, replace with user-declared location only. Potential legal exposure if not caught before launch. |
| APNs token stale — push notifications stop working | MEDIUM | Add token refresh on login and app launch. 1 day fix, but requires resubmission. |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Social API friend-import dead end | Phase 1: Architecture | Confirm import strategy uses Contacts framework + invite flow before any code written |
| AI location inference without consent | Phase 1: Architecture | Data model shows location is user-declared, not inferred about non-consenting third parties |
| Missing Sign in with Apple | Phase 2: Authentication | Auth PR checklist includes Apple login; test with hidden email relay address |
| Firebase listener cost explosion | Phase 3: Backend architecture | Firestore usage design reviewed; weather data is cached/polled, not listener-driven |
| Missing UGC moderation in chat | Phase 4: Chat feature | Chat feature includes Report + Block UI in initial implementation |
| Push notification unreliability | Phase 4-5: Notifications | Notification architecture uses visible alerts (not silent push) for weather alerts |
| Missing privacy manifests for SDKs | Phase 6: App Store prep | Xcode Archive → Validate runs clean before TestFlight submission |
| Account deletion missing | Phase 6: App Store prep | Settings screen includes in-app delete account flow |
| Firebase security rules open | All phases | Firebase Emulator Suite used for local development; rules reviewed before each environment promotion |

---

## Sources

- [Instagram API Deprecation and 2026 API Rules — Storrito](https://storrito.com/resources/Instagram-API-2026/) — HIGH confidence
- [Facebook Unofficial API Overview — Data365](https://data365.co/blog/facebook-unofficial-api) — MEDIUM confidence
- [Apple App Store Rejection Reasons 2025 — twinr.dev](https://twinr.dev/blogs/apple-app-store-rejection-reasons-2025/) — HIGH confidence
- [Apple App Store Review Guidelines (official) — Apple Developer](https://developer.apple.com/app-store/review/guidelines/) — HIGH confidence
- [Sign in with Apple requirement change — 9to5Mac 2024](https://9to5mac.com/2024/01/27/sign-in-with-apple-rules-app-store/) — HIGH confidence
- [Top 10 Firebase Mistakes 2025 — DEV Community](https://dev.to/mridudixit15/top-10-mistakes-developers-still-make-with-firebase-in-2025-53ah) — MEDIUM confidence
- [Firebase Firestore Real-Time Queries at Scale — Firebase Official Docs](https://firebase.google.com/docs/firestore/real-time_queries_at_scale) — HIGH confidence
- [Silent Push Notifications Not Guaranteed — Medium/Mohsin Khan](https://mohsinkhan845.medium.com/silent-push-notifications-in-ios-opportunities-not-guarantees-2f18f645b5d5) — HIGH confidence
- [Apple Privacy Manifest Requirements — Apple Developer Docs](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk) — HIGH confidence
- [UGC Moderation Requirements for App Store — Apple Developer Forum](https://developer.apple.com/forums/thread/62186) — HIGH confidence
- [AI and Location Privacy Regulation 2025 — CSA Blog](https://cloudsecurityalliance.org/blog/2025/04/22/ai-and-privacy-2024-to-2025-embracing-the-future-of-global-legal-developments) — MEDIUM confidence
- [iOS Location Services Battery Optimization — Rangle.io](https://rangle.io/blog/optimizing-ios-location-services) — MEDIUM confidence
- [Push Notification Architecture Failures — Netguru](https://www.netguru.com/blog/why-mobile-push-notification-architecture-fails) — MEDIUM confidence

---
*Pitfalls research for: Social weather iOS app (Hot & Cold Friends)*
*Researched: 2026-03-02*
