# Pitfalls Research

**Domain:** Viral sharing, invite experience, shareable weather cards, and engagement loops for existing iOS social weather app
**Researched:** 2026-03-06
**Confidence:** HIGH (deep linking, ImageRenderer, push notification patterns) / MEDIUM (engagement loop design, share sheet behavior) / LOW (Instagram Stories sharing API changes)

---

## Critical Pitfalls

### Pitfall 1: Custom URL Scheme Invite Links Are Unclickable Outside the App

**What goes wrong:**
The current invite system generates `hotandcold://invite/<token>` URLs. When shared via iMessage, WhatsApp, Instagram DM, or email, these custom URL scheme links have critical problems: (1) they only work if the app is already installed -- new users see an error or nothing happens, (2) social platforms and email clients often strip or block custom scheme URLs as potential phishing vectors, (3) iMessage renders them as plain text rather than tappable rich link previews. The entire viral invite flow breaks for the most important audience: people who don't have the app yet.

**Why it happens:**
Custom URL schemes were the original deep linking mechanism and work perfectly for internal navigation (widgets, notifications). Developers who've only tested within the app ecosystem don't realize the scheme is invisible to the outside world. The v2.0 invite system was built for existing-user-to-existing-user flows, not for viral acquisition.

**How to avoid:**
Migrate invite links to Universal Links using an HTTPS domain (e.g., `https://friendscast.app/invite/<token>` or `https://apps.sandenskog.se/invite/<token>`). This requires:
1. An `apple-app-site-association` (AASA) file hosted on the domain
2. Associated Domains entitlement in the app (`applinks:friendscast.app`)
3. A web fallback page at the same URL that redirects to App Store if the app isn't installed
4. Keep `hotandcold://` scheme for internal navigation (widgets, local notifications) but never expose it in shared content

Firebase Dynamic Links shut down August 25, 2025. Do NOT use them. Build your own simple AASA + fallback page, or use a lightweight alternative like Branch if attribution analytics are needed.

**Warning signs:**
- Invite share text contains `hotandcold://` anywhere
- No AASA file hosted on any domain
- No web fallback page for invite URLs
- Testing invite flow only between two devices that both have the app installed

**Phase to address:** Invite Experience phase -- this is the foundation that all sharing features depend on. Must be the first thing built.

---

### Pitfall 2: SwiftUI ImageRenderer Silently Produces Blank or Incomplete Images

**What goes wrong:**
SwiftUI's `ImageRenderer` (iOS 16+) is used to generate shareable weather card images. It has several undocumented limitations that cause blank or partial renders: (1) any view inside a `ScrollView` renders as blank, (2) `AsyncImage` content doesn't render (images from URLs are missing), (3) UIKit-backed views like `ProgressView`, `Picker`, and `Map` are omitted, (4) custom fonts sometimes fail to render in the image context, (5) the renderer doesn't respect `@Environment` values from the parent view hierarchy. The generated image looks perfect in-app preview but the exported PNG is broken.

**Why it happens:**
ImageRenderer works by snapshotting the SwiftUI render tree, but it creates its own isolated rendering context. Views that depend on UIKit hosting, async loading, or environment injection from parent views fail silently -- no crash, no error, just missing content. Developers build the card view in a regular SwiftUI preview (where everything works) and only discover the issue when testing the actual export.

**How to avoid:**
- Build the shareable weather card as a **self-contained view** that takes all data as parameters (temperature, city, weather icon, friend name, avatar image as `UIImage`). No `AsyncImage`, no environment dependencies.
- Pre-load all images (avatar, weather icons) as `UIImage` before passing to the card view.
- Use bundled SVG/PDF weather icons (already available in the asset catalog) rather than loading from network.
- Wrap ImageRenderer usage in `@MainActor` context -- the `scale` property is MainActor-isolated and will crash or silently fail if set from a background thread.
- Test the generated image by saving to Photos and inspecting, not by previewing in SwiftUI.
- Fallback: if ImageRenderer output is unexpectedly small or blank, use `UIHostingController` + `UIGraphicsImageRenderer` as backup rendering path.

**Warning signs:**
- Weather card view uses `AsyncImage` or `@Environment` values
- ImageRenderer code runs outside `@MainActor`
- Testing only in SwiftUI preview, never exporting actual PNG
- Generated image file size is suspiciously small (< 10KB for a card)

**Phase to address:** Shareable Weather Cards phase -- establish the rendering pipeline early, test export before building elaborate card designs.

---

### Pitfall 3: Share Sheet Fires Without Useful Content or With Wrong Metadata

**What goes wrong:**
The iOS share sheet (`UIActivityViewController` or SwiftUI `ShareLink`) is used to share weather cards to Instagram Stories, iMessage, etc. Common failures: (1) sharing a `UIImage` without also sharing a URL means no link back to the app -- the shared image is a dead end with zero viral value, (2) Instagram Stories sharing requires the `instagram-stories://` URL scheme and specific `UIPasteboard` items (not the standard share sheet), (3) sharing text + image + URL together causes some share targets to only use one item and discard the rest, (4) Open Graph metadata missing from the link means iMessage/WhatsApp show a bare URL instead of a rich preview.

**Why it happens:**
The share sheet is deceptively simple to invoke but each share target (iMessage, Instagram, WhatsApp, Twitter) handles the shared content differently. Developers test with one target and assume it works universally.

**How to avoid:**
- Always share **image + URL** together. The URL should be a Universal Link that works even without the app installed.
- For Instagram Stories specifically: use the `instagram-stories://share` URL scheme with pasteboard items (`com.instagram.sharedSticker.backgroundImage`, etc.). This is a separate code path from the general share sheet.
- Add Open Graph meta tags to the web fallback page so shared URLs render rich previews in iMessage, WhatsApp, Slack, etc.
- Test sharing to at least: iMessage, WhatsApp, Instagram Stories, Instagram DM, and "Save Image." Each has different behavior.
- Embed the invite link as text overlay or watermark on the image itself -- this ensures the link survives platforms that strip metadata.

**Warning signs:**
- Share sheet only shares an image with no associated URL
- No separate Instagram Stories sharing implementation
- Web fallback page has no `og:image`, `og:title`, `og:description` meta tags
- Only tested sharing to one platform

**Phase to address:** Shareable Weather Cards phase -- but depends on Universal Links from the Invite Experience phase being complete first.

---

### Pitfall 4: Engagement Loop Notifications Become Spam and Drive Uninstalls

**What goes wrong:**
The app adds engagement nudges: "Your friend Anna has snow today!", "3 friends are experiencing a heatwave!", "You haven't checked the weather in 2 days." These sound valuable in a product spec but in practice: (1) one weekly push notification causes 10% of users to disable push, (2) 3-6 weekly pushes cause 40% to opt out, (3) 71% of all app uninstalls are triggered by a push notification. The engagement loop designed to increase retention actively drives churn.

**Why it happens:**
Product teams optimize for short-term engagement metrics (DAU, open rate) without measuring notification fatigue. Each individual notification seems justified ("it's relevant -- their friend has extreme weather!"), but the cumulative volume across all notification types (chat messages, weather alerts, daily summary, engagement nudges, invite reminders) overwhelms users.

**How to avoid:**
- Implement a **notification budget** per user: maximum 1 engagement nudge per day, maximum 4 per week across ALL non-chat notification types combined. Chat message notifications are exempt (user-initiated).
- Use a server-side notification throttling system (Cloud Function) that tracks recent notifications sent to each user and suppresses if budget is exceeded.
- Make nudge notifications opt-in per category in app settings, not just a global on/off.
- Prioritize by signal strength: extreme weather alert > weather change for favorite friend > general engagement nudge. If budget is spent on a high-priority notification, suppress the lower-priority ones.
- Never send "come back" re-engagement notifications in the first 7 days. Let the user establish their own usage pattern first.

**Warning signs:**
- No per-user notification throttling logic
- Multiple Cloud Functions that each independently send notifications without awareness of each other
- No notification settings screen in the app beyond the system-level toggle
- Product discussions framing notification count as "engagement opportunities"

**Phase to address:** Engagement Loops phase -- the throttling infrastructure should be built BEFORE any new notification types are added.

---

### Pitfall 5: Invite Incentive Creates Spam or Abuse Without Adding Real Value

**What goes wrong:**
The app adds incentives to invite friends (e.g., "Invite 5 friends to unlock weather stickers" or "See your invite count"). This creates perverse incentives: (1) users spam their entire contact list to hit the threshold, annoying non-users and damaging brand perception, (2) users create fake accounts to redeem their own invites, (3) the incentive becomes the goal rather than the social connection, which conflicts with the app's "warm, social" design philosophy. The feature explicitly contradicts the "no gamification" constraint in PROJECT.md.

**Why it happens:**
Viral growth mechanics from gaming and e-commerce apps are borrowed without considering context. Weather-friends is a relationship-based app, not a transactional one. Incentive mechanics that work for Dropbox ("get free storage") feel manipulative in a social context.

**How to avoid:**
- Frame invites around **social value, not rewards**: "Share your weather with Anna" rather than "Invite 5 friends to unlock X."
- The invite flow should be embedded in natural social moments: viewing a friend's weather and wanting to share it, seeing an extreme weather event, or wanting to add a specific person -- not a standalone "invite friends" CTA.
- No invite counters, no unlock thresholds, no leaderboards. These are gamification.
- The "incentive" should be the relationship itself: the app becomes more valuable with more friends, and this should be the messaging.
- Rate-limit invite sending per user per day (max 10) to prevent contact list spam.

**Warning signs:**
- Any design that includes invite counters or unlock thresholds
- A standalone "Invite Friends" tab or prominent CTA unrelated to a social context
- Invite flow that encourages selecting many contacts at once rather than individual invites
- No rate limiting on invite creation

**Phase to address:** Invite Experience phase -- design review before implementation. Cross-reference with PROJECT.md "no gamification" constraint.

---

### Pitfall 6: Deep Link Handling Fails for Unauthenticated Users

**What goes wrong:**
A new user taps an invite Universal Link, the app opens (or installs and opens), but the deep link payload is lost because: (1) the user hasn't signed in yet so `authManager.currentUser?.id` is nil, and the current `onOpenURL` handler silently returns, (2) on fresh install, iOS delivers the Universal Link before the app finishes initialization, so Firebase Auth hasn't restored the session yet, (3) the user signs up (creating a new account) and the invite token is completely forgotten -- they need to manually paste the invite code.

**Why it happens:**
The current `onOpenURL` handler (line 47 of `HotAndColdFriendsApp.swift`) has a `guard let uid = authManager.currentUser?.id else { return }` that silently drops the invite if the user isn't authenticated. This was acceptable for v2.0 where both users already had the app, but breaks the viral acquisition flow entirely.

**How to avoid:**
- Store the pending invite token in a `@State` or persistent storage (UserDefaults) when received before authentication.
- After successful sign-in/sign-up, check for pending invite tokens and redeem them automatically.
- Show the invite context during onboarding: "Anna invited you to see her weather! Sign up to connect."
- Handle the timing issue: `onOpenURL` can fire before `@State` is initialized. Use `AppDelegate` `application(_:continue:)` for Universal Links as a more reliable entry point.
- Test the complete flow: tap link -> App Store -> install -> first launch -> sign up -> auto-redeem invite.

**Warning signs:**
- `onOpenURL` handler that requires authentication before processing
- No persistent storage for pending deep link payloads
- Testing invite flow only between two already-authenticated users
- No "deferred deep link" handling for fresh installs

**Phase to address:** Invite Experience phase -- this is the single most important fix for viral growth. Without it, the entire invite funnel leaks at the most critical point.

---

### Pitfall 7: Weather Card Image Generation Blocks the Main Thread

**What goes wrong:**
Generating a shareable weather card image involves rendering a SwiftUI view to a `UIImage`, then encoding it as PNG/JPEG. If done synchronously on the main thread (which ImageRenderer requires for the render step), the UI freezes for 200-500ms. Users tap "Share" and experience a visible hang before the share sheet appears. On older devices (iPhone SE, iPad mini), this can exceed 1 second and feel broken.

**Why it happens:**
`ImageRenderer.render()` and `.uiImage` must be called on the MainActor. Developers do the entire pipeline (render + encode + create share items) synchronously in a button tap handler because "it has to be on MainActor anyway."

**How to avoid:**
- Split the pipeline: render to `UIImage` on MainActor (fast, <50ms), then dispatch PNG encoding to a background task.
- Show an immediate loading state (spinner on the share button, or a preview with progress indicator) while the image is being prepared.
- Pre-render the share image when the weather card view appears (not on tap), so it's ready instantly when the user taps share. Cache the rendered image and invalidate when weather data changes.
- Set `ImageRenderer.proposedSize` to a fixed size (e.g., 1080x1920 for Instagram Stories) rather than letting it auto-size, which is slower.

**Warning signs:**
- Share button handler that synchronously creates ImageRenderer, renders, encodes, and presents share sheet
- No loading indicator between tap and share sheet appearance
- No image caching -- re-renders on every share tap

**Phase to address:** Shareable Weather Cards phase -- establish the async rendering pipeline from the start.

---

### Pitfall 8: Visual Polish Phase Breaks Existing Layouts Without Automated Regression

**What goes wrong:**
The visual polish phase updates all views to fully adopt `BubblePopTypography`, `BubblePopSpacing`, and `BubblePopCornerRadius`. These changes propagate through the entire UI. Without visual regression testing, subtle layout breaks go unnoticed: text truncation in friend list cells, avatar clipping in chat bubbles, widget layout overflow, incorrect spacing on smaller screens (iPhone SE), or Dynamic Type accessibility breakage at larger text sizes.

**Why it happens:**
SwiftUI's layout system recalculates automatically when spacing/typography values change. A spacing change in one component can cascade to parent views. Developers test on their primary device size and miss edge cases. The Bubble Pop design system has 5 temperature zones with different gradient colors, meaning bugs may only appear in certain weather conditions.

**How to avoid:**
- Create a **visual test checklist** covering all screen sizes (SE, standard, Pro Max) and all temperature zones before starting polish work.
- Test with Dynamic Type at maximum size -- BubblePopTypography should respect accessibility scaling.
- Test with Reduce Motion enabled -- all spring animations should degrade gracefully (already implemented but could regress).
- Make typography/spacing changes incrementally (one view at a time) rather than a bulk find-and-replace.
- Screenshot each view before and after changes for manual comparison.

**Warning signs:**
- Bulk replacement of `Font.system` with `BubblePopTypography` across all files in one commit
- No testing on iPhone SE screen size
- No testing with Dynamic Type large sizes
- Changes to spacing constants in the design system without checking all consumers

**Phase to address:** Visual Polish phase -- establish the testing protocol before making changes, not after.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep `hotandcold://` scheme for invite links instead of Universal Links | Zero infrastructure work | Invite links don't work for new users, killed by messaging platforms | Never for external sharing -- must migrate |
| Render weather card image synchronously in button handler | Simpler code | UI freeze on every share tap, worse on older devices | Never -- use async pipeline from start |
| Skip Open Graph meta tags on fallback page | Faster shipping | Shared links show as bare URLs in iMessage/WhatsApp -- no viral preview effect | Acceptable for first iteration, but must add within same milestone |
| Single notification Cloud Function without throttling | Faster to ship each notification type | Users overwhelmed, uninstall rate spikes | Only for chat notifications (user-initiated), never for engagement nudges |
| Store pending invite token in memory only | Simpler than UserDefaults | Lost on app termination between install and sign-up | Never -- use UserDefaults or Keychain |
| Hardcode weather card dimensions for one platform | Fewer layout variants | Looks bad on Instagram Stories (9:16) vs iMessage (1:1) | Acceptable if you pick 9:16 (works reasonably everywhere) |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Universal Links (AASA) | Serving AASA file with wrong Content-Type or via redirect | Must be `application/json`, served directly (no redirects), at `/.well-known/apple-app-site-association` exactly |
| Universal Links (testing) | Testing by pasting URL in Safari address bar | Universal Links don't activate from the address bar. Test by tapping link in Notes app, iMessage, or a webpage |
| Instagram Stories API | Using standard `UIActivityViewController` for Instagram Stories | Must use `instagram-stories://share` URL scheme with pasteboard items. Different code path entirely |
| SwiftUI ImageRenderer | Setting `.scale` from background thread | `scale` is MainActor-isolated. Must configure ImageRenderer entirely within MainActor context |
| Firebase Cloud Messaging | Sending engagement notification without checking user's in-app preference | Check both APNs permission AND in-app notification settings document before sending. Users expect granular control |
| Share sheet on iPad | Presenting `UIActivityViewController` without `popoverPresentationController` source | Crashes on iPad. Always set `sourceView`/`sourceRect` or use SwiftUI `ShareLink` which handles this |
| Open Graph previews | Expecting instant preview updates after changing meta tags | iMessage, WhatsApp, Slack all cache OG previews aggressively. Use unique URLs or cache-busting query params during testing |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Generating weather card image on every share tap | 200-500ms UI freeze, user taps twice thinking it didn't work | Pre-render and cache; invalidate on weather data change | Immediately on older devices |
| Loading all friend avatars as UIImage for card generation | Memory spike, potential OOM on devices with many friends | Only load avatar for the specific friend being shared | At 20+ friends with high-res avatars |
| Universal Links AASA file not cached by CDN | Slow deep link resolution, especially first tap | Host AASA on a CDN (Cloudflare, etc.) with appropriate cache headers | At scale, but even single-user latency matters for first impression |
| Multiple independent notification Cloud Functions all querying same user document | Redundant Firestore reads, higher cost, race conditions | Single notification orchestrator function that batches and throttles | At 1000+ users with multiple notification types |
| Rendering weather card at device screen resolution instead of fixed export size | Inconsistent image quality across devices, oversized files on 3x Retina | Fix export at 2x scale, 1080px wide | Immediately -- 3x Retina generates unnecessarily large files |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Invite tokens predictable or enumerable | Attacker generates valid tokens, adds themselves as friend of any user | Current 12-char UUID prefix has sufficient entropy. Keep it. Add rate limiting on redemption attempts per IP |
| No server-side validation of invite redemption | Client could forge invite redemption, adding arbitrary users as friends | Move invite redemption to a Cloud Function with server-side validation (currently client-side Firestore writes) |
| Shareable weather card contains precise friend location | Shared image reveals where someone's friend lives to anyone who sees the image | Only show city name on card, never coordinates. Don't embed EXIF location data in generated images |
| Universal Link fallback page leaks invite token to analytics | Third-party analytics on fallback page captures invite tokens from URL | Don't load third-party scripts on fallback page, or strip token before analytics fire |
| Push notification content visible on lock screen reveals friend's weather/location | Privacy breach if someone else sees the notification | Use notification category with `.hiddenPreviewsBodyPlaceholder` for sensitive content |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Share button on every friend card creates decision fatigue | Users ignore share because it's everywhere | Show share prominently only on extreme/interesting weather events. Subtle share icon elsewhere |
| Weather card design is generic and not worth sharing | Users don't share because the image is boring | The card must be visually distinctive -- use Bubble Pop gradients, temperature zone colors, and playful weather icons. It should look like something users are proud to post |
| Invite flow requires too many steps (copy token, send message, explain to friend) | Drop-off at each step kills viral coefficient | One-tap share that opens iMessage/WhatsApp with pre-composed message including Universal Link and friendly text |
| "Come back" push notification after 1 day of inactivity | Feels desperate, users associate app with nagging | Minimum 3-day quiet period. Frame as value ("Snow just started in Stockholm where Anna is!") not guilt ("You haven't opened the app") |
| Engagement nudge shown as modal popup on app open | Blocks the user from their intended action, creates resentment | Use inline banners or subtle indicators in the friend list, never modals |
| No feedback after sharing (did it work? did they join?) | User feels uncertain, stops sharing | Show "Invite sent!" confirmation and later "Anna joined!" notification when invite is redeemed |

---

## "Looks Done But Isn't" Checklist

- [ ] **Universal Links:** AASA file hosted and app opens from link -- verify it also works for FRESH INSTALL (deferred deep link with pending token storage)
- [ ] **Weather card sharing:** Image generates and share sheet opens -- verify the image actually contains all elements (avatar, weather icon, temperature, city) by saving to Photos and inspecting
- [ ] **Instagram Stories sharing:** Share sheet includes Instagram option -- verify it actually opens Instagram Stories composer with the image, not just the Instagram app
- [ ] **Invite flow for new users:** Invite link works between two test devices -- verify the COMPLETE flow: non-user taps link -> App Store -> install -> sign up -> auto-friend connection
- [ ] **Notification throttling:** Engagement notifications send correctly -- verify a user with 20 friends during extreme weather doesn't receive 20 separate notifications
- [ ] **Visual polish:** All views updated to BubblePopTypography -- verify on iPhone SE (smallest screen) AND with Dynamic Type at largest setting
- [ ] **Share preview:** Universal Link shared in iMessage -- verify it shows rich preview with app icon, title, and description (not bare URL)
- [ ] **iPad share sheet:** Share button works on iPhone -- verify it doesn't crash on iPad (popover requirement)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Custom URL scheme invite links don't work for new users | MEDIUM | Set up Universal Links (domain, AASA, entitlement, fallback page). 3-5 days including testing. Old `hotandcold://` links for widgets keep working. |
| ImageRenderer produces blank images | LOW | Switch to `UIHostingController` + `UIGraphicsImageRenderer` fallback. 1-2 days. Well-documented pattern. |
| Engagement notifications cause uninstalls | MEDIUM | Add throttling Cloud Function and per-category settings. 2-3 days. Requires new app version for settings UI. |
| Deep link lost for unauthenticated users | LOW | Add UserDefaults pending token storage + post-auth redemption check. 1 day. |
| Visual polish breaks existing layouts | MEDIUM | Revert to pre-polish commit, apply changes incrementally with testing. Cost depends on how many views were changed in bulk. |
| Share sheet crashes on iPad | LOW | Add `popoverPresentationController` configuration. 1 hour fix. |
| Instagram Stories sharing doesn't work | LOW | Implement dedicated `instagram-stories://` code path. 1 day. |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Custom URL scheme unusable for sharing | Invite Experience | Universal Link opens app from iMessage on device without app installed |
| ImageRenderer blank output | Shareable Weather Cards | Exported PNG saved to Photos contains all visual elements |
| Share sheet wrong metadata | Shareable Weather Cards | Links shared in iMessage show rich preview; Instagram Stories opens correctly |
| Notification spam drives uninstalls | Engagement Loops | Cloud Function throttling tested: user with 30 friends gets max 1 nudge/day |
| Invite incentive becomes gamification | Invite Experience | Design review against PROJECT.md "no gamification" constraint before implementation |
| Deep link lost for new users | Invite Experience | Complete fresh-install flow tested: link -> install -> sign up -> auto-friend |
| Image generation blocks main thread | Shareable Weather Cards | Share button shows loading state; no UI freeze measurable on iPhone SE |
| Visual polish breaks layouts | Visual Polish | Screenshot comparison on SE, standard, Pro Max before and after; Dynamic Type large tested |
| Invite redemption client-side vulnerability | Invite Experience | Redemption moved to Cloud Function with server-side validation |

---

## Sources

- [Apple ImageRenderer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) -- HIGH confidence
- [ImageRenderer fails to render content (Apple Developer Forums)](https://developer.apple.com/forums/thread/725196) -- HIGH confidence, documents blank render issues
- [AsyncImage not rendering with ImageRenderer (Apple Developer Forums)](https://developer.apple.com/forums/thread/728114) -- HIGH confidence
- [Universal & Deep Links: 2026 Complete Guide (DEV Community)](https://dev.to/marko_boras_64fe51f7833a6/universal-deep-links-2026-complete-guide-36c4) -- MEDIUM confidence
- [Firebase Dynamic Links Shutdown Alternatives (Airbridge)](https://www.airbridge.io/blog/firebase-dynamic-links-alternatives) -- HIGH confidence, confirms August 2025 shutdown
- [Push Notification Best Practices 2026 (Appbot)](https://appbot.co/blog/app-push-notifications-2026-best-practices/) -- MEDIUM confidence
- [Push Notification Statistics 2025 (Business of Apps)](https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/) -- HIGH confidence, source for uninstall/opt-out statistics
- [Rethinking Mobile App Retention 2026 (OneSignal)](https://onesignal.com/blog/how-leading-mobile-teams-are-rethinking-retention-for-2026/) -- MEDIUM confidence
- [How to Implement iOS Deep Linking Using Universal Links (Medium)](https://medium.com/@sonerkaraevli/how-to-implement-ios-deep-linking-using-universal-links-step-by-step-deep-dive-guide-2024-fe3882b3017c) -- MEDIUM confidence
- [Firebase Dynamic Links Replacement with Custom Server (Medium)](https://medium.com/@azaikin/firebase-dynamic-links-is-shutting-down-heres-how-i-replaced-it-with-a-custom-deep-link-server-e8dfeb7ec6b3) -- MEDIUM confidence
- [ImageRenderer in SwiftUI (Swift with Majid)](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/) -- MEDIUM confidence
- Existing codebase analysis: `InviteService.swift`, `HotAndColdFriendsApp.swift`, `AddFriendSheet.swift` -- HIGH confidence

---
*Pitfalls research for: Viral sharing, invite experience, shareable weather cards, and engagement loops (FriendsCast v3.0)*
*Researched: 2026-03-06*
