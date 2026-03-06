# Feature Landscape

**Domain:** Viral sharing, invite experience & engagement loops for social weather app (iOS)
**Researched:** 2026-03-06
**Existing app:** FriendsCast v2.0 with invite links, chat, weather list, map, categories, widgets, Bubble Pop design system

---

## Table Stakes

Features users expect once sharing/invite functionality exists. Missing = feels half-baked.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| One-tap invite sharing (iMessage, WhatsApp, etc.) | Users expect native share sheet with contextual message, not just a bare URL | Low | Existing InviteService, ShareLink | Current implementation shares a bare `hotandcold://invite/TOKEN` URL. Needs pre-populated text: "Check the weather where I am! Join me on FriendsCast" |
| Invite link that works without app installed | Current `hotandcold://` custom scheme fails silently if app not installed -- this kills viral growth completely | Med | Apple Universal Links, AASA file, web landing page | Firebase Dynamic Links shut down Aug 2025. Must use Universal Links with web fallback to App Store. Requires a domain (e.g. invite.friendscast.app) |
| Rich link preview (Open Graph) | When shared in iMessage/WhatsApp, links must show image + title, not a bare URL. Bare links look spammy and get ignored | Med | Web landing page with OG meta tags | Requires a tiny HTML page per invite token that serves OG tags. Can be static template on Firebase Hosting |
| Shareable weather card (static image) | People share weather screenshots constantly. Instagram has a built-in weather sticker. Without branded cards, users screenshot the app -- ugly, no branding, no download link | Med | ImageRenderer (iOS 16+), Bubble Pop design tokens | Render SwiftUI view to UIImage: temperature, weather icon, city, avatar, app branding. Share via ShareLink. CARROT Weather does this as table stakes |
| Share card for specific friend | User wants to share "It's 32C in Bangkok where Lisa is!" -- not just own weather | Low | Existing friend + weather data, weather card component | Tap a friend row or profile -> share button -> generates card for that friend's weather |
| Invite success confirmation with celebration | Both sender and receiver need clear feedback that friendship was created -- current UX is functional but flat | Low | Existing InviteService.redeemInvite, spring animations | Use existing Bubble Pop spring animations (confetti, heart-pop) for celebration moment |

## Differentiators

Features that set FriendsCast apart. Not expected, but create delight and virality.

| Feature | Value Proposition | Complexity | Dependencies | Notes |
|---------|-------------------|------------|--------------|-------|
| "Me vs You" comparison card | "It's 32C where Lisa is but only 5C where I am!" -- the app's unique value as a shareable image. No weather app does friend-to-friend comparison cards | Med | Friend weather data, ImageRenderer | Two-panel card: both avatars with temperature zone gradients, temps, weather icons, cities. THIS is the viral differentiator -- embodies the app's core concept |
| Weather reaction nudges | Push: "It's snowing where Emma is! Send her a message?" with deep link to chat | Med | FCM, existing chat + WeatherAlertService | Contextual nudges tied to weather events feel helpful, not spammy. Builds on existing extreme weather alerts infrastructure |
| "Weather twins" notification | "You and 3 friends all have sunshine today!" -- creates shared experience moment | Med | Cloud Function comparing friend weather data | Social proof + connection trigger. Good engagement loop that feels natural, not gamified |
| Share to Instagram Stories | Direct Instagram Stories sharing via URL scheme with weather card as background sticker | Med | Instagram URL scheme (`instagram-stories://share`), pasteboard image | Instagram is THE platform for weather sharing. Custom card format that looks native to Stories |
| Invite social proof | "3 of your contacts are already on FriendsCast" shown during invite/onboarding | Med | Cloud Function cross-referencing contacts with user database | Privacy-sensitive: show count only, never names, until mutual friendship. Powerful conversion trigger |
| Daily weather digest as shareable card | Auto-generated morning card: "Your friends' weather today" -- shareable group summary | Med | Existing daily summary push, ImageRenderer | Could be the daily open trigger. Pairs perfectly with existing daily summary notification -- add "Share" button to the in-app digest view |
| Friend weather check-in streak | "You've checked on Lisa's weather 5 days in a row" -- tracks natural behavior subtly | Low | Local tracking (UserDefaults or SwiftData) | NOT gamification (no points, no rewards, no leaderboard). Just a gentle observation: "Day 5 checking on Lisa" shown inline. Respect PROJECT.md anti-gamification stance |
| Animated weather card (video/GIF) | Animated rain, snow particles etc. as shareable video for Instagram/TikTok | High | AVFoundation or Lottie-to-video rendering | Visually stunning but significantly more complex than static cards. Defer unless static cards prove high share volume |

## Anti-Features

Features to explicitly NOT build. Based on PROJECT.md constraints and domain research.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Gamification / points / badges / leaderboards | PROJECT.md explicitly excludes: "strider mot varm/social kansla". Research confirms weather+gamification feels forced (Weddar tried leaderboards, didn't work) | Subtle behavioral observation (streak counter) without scores or competition. "Day 5 checking on Lisa" not "You earned 50 points!" |
| Reward-based referral program ("Invite 5, unlock premium") | Transactional incentives poison the warm, social tone. The app is about caring about friends' weather, not earning rewards | Natural incentive: "your friend list gets better with more friends on the app" IS the reward. No artificial incentives needed |
| Social feed / timeline of weather updates | Out of scope per PROJECT.md. Adding a feed changes the product from "glance at friends' weather" to "scroll through weather posts" | Keep weather list as primary view. Shareable cards go OUT of the app to social platforms, not into an internal feed |
| Firebase Dynamic Links | Shut down August 2025. Dead technology. Must not depend on it | iOS Universal Links with AASA file + web fallback page. Simple, free, no third-party dependency |
| Third-party deep link services (Branch, Adjust, Kochava) | Overkill for current scale. Adds SDK dependency, tracking complexity, cost. Deferred deep linking is nice but not critical for a free social app | iOS Universal Links + web landing page that redirects to App Store. Add attribution tooling later if growth demands it |
| Auto-posting to social media | Users hate apps that post on their behalf. Immediate trust violation | Always require explicit user tap to share. Never auto-share. Never pre-check "also post to..." |
| Heavy notification volume (>3/day) | Research shows >3 pushes/day dramatically increases notification opt-out rate. Weather apps especially risk "notification fatigue" | Cap at 1 daily digest + max 1 contextual nudge per day. Existing extreme weather alerts are separate (rare, high-value). Let users control categories |
| Cross-platform invite handling (Android) | iOS-only app. Building Android deep link handling wastes effort | Web fallback page shows App Store link for all platforms. Android users see "Available on iOS" |
| Dark mode weather cards | Conflicts with warm, social brand. Dark cards look like generic weather apps | Bubble Pop's warm gradients and temperature zone colors work better on light backgrounds. Keep cards on-brand |

---

## Feature Dependencies

```
Universal Links + web landing page
    --> Invite link works without app installed
    --> Rich link preview (OG meta tags)
    --> All sharing features benefit (links in shared cards)

ImageRenderer weather card component
    --> Share single friend's weather card
    --> "Me vs You" comparison card
    --> Share to Instagram Stories
    --> Daily weather digest card

Weather reaction nudges (Cloud Function)
    --> Builds on existing WeatherAlertService
    --> Requires existing FCM + chat infrastructure
    --> "Weather twins" notification (extension of same logic)

Invite flow visual polish
    --> Depends on Bubble Pop design system (already built)
    --> Invite success celebration uses existing spring animations

Friend weather streak
    --> Local only, no backend dependencies
    --> Independent of all other features
```

### Key Dependency Insight

Universal Links + web landing page is the **foundation** that unlocks viral growth. Without it, every shared link is dead for non-users. Build this first, then layer shareable cards and engagement nudges on top.

---

## MVP Recommendation

Prioritize in this order for v3.0:

### Phase 1: Fix the Viral Foundation

1. **Universal Links + web landing page** -- Without this, shared invite links don't work for new users. This is the #1 blocker for any viral growth. Every other sharing feature is hobbled without working links.

2. **Improved invite flow with contextual share text** -- Upgrade from bare URL to "Check the weather where I am -- 24C and sunny in Stockholm! Join me on FriendsCast: [link]". Low effort, immediate impact.

3. **Invite success celebration** -- Use existing Bubble Pop animations (confetti, heart-pop) when friendship is created via invite. Makes the moment feel rewarding.

### Phase 2: Shareable Content

4. **Shareable weather card (static image)** -- The minimum viable sharing feature. Bubble Pop-styled card with temperature, weather icon, city, avatar, app branding. Render with ImageRenderer, share with ShareLink.

5. **"Me vs You" comparison card** -- THE unique differentiator. Two friends, two cities, two weather conditions, one card. This is the feature that makes FriendsCast shares instantly recognizable. No other app does this.

6. **Share to Instagram Stories** -- Dedicated Instagram share target since weather content gets massive engagement on Instagram.

### Phase 3: Engagement Loops

7. **Weather reaction nudges** -- "It's snowing where Emma is!" push with deep link to chat. Drives daily opens and re-engagement.

8. **Daily weather digest as shareable card** -- Extends existing daily summary push with in-app card that can be shared.

### Defer to Later

- **Animated weather cards**: High complexity, marginal uplift over static cards. Only build if static cards prove share volume.
- **"Weather twins" notification**: Extension of nudge logic but requires new Cloud Function. Add after basic nudges prove effective.
- **Invite social proof ("3 contacts already here")**: Requires backend cross-reference. Useful but not critical for v3.0.
- **Friend weather streak**: Nice-to-have, low effort but also low impact on virality. Polish feature.

---

## Technical Notes

### ImageRenderer for Weather Cards
- Available iOS 16+ (app targets iOS 17+, safe)
- Must run on @MainActor
- Set `renderer.scale = UIScreen.main.scale` to avoid blurry 1x output on Retina screens
- Cannot render UIKit/AppKit views (not an issue -- all views are SwiftUI)
- Combine with ShareLink for native share sheet
- For Instagram Stories: write image to pasteboard, open `instagram-stories://share?source_application=BUNDLE_ID`

### Universal Links Migration from Custom Scheme
- Current: `hotandcold://invite/TOKEN` -- fails if app not installed
- Target: `https://invite.friendscast.app/TOKEN` -- works everywhere
- Requires: AASA (Apple App Site Association) file on web domain
- Web page serves OG meta tags (title, description, image) for rich previews
- Falls back to App Store redirect for users without app
- Token extraction via SwiftUI `.onOpenURL` modifier (already partially implemented)
- Can use Firebase Hosting (free tier) for the landing page -- simple static HTML

### Notification Budget
- iOS allows per-app notification control
- Research: >3 pushes/day causes significant opt-out increase
- Budget: 1 daily digest (existing) + max 1 contextual nudge/day (new)
- Existing extreme weather alerts are rare and high-value -- keep separate
- Use UNNotificationCategory to let users pick which nudge types they want

---

## Sources

- [Firebase Dynamic Links deprecation FAQ](https://firebase.google.com/support/dynamic-links-faq) -- Confidence: HIGH (official Firebase docs)
- [Firebase Dynamic Links alternatives guide](https://leancode.co/blog/firebase-dynamic-links-deprecated) -- Confidence: MEDIUM
- [ImageRenderer Apple documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) -- Confidence: HIGH (official Apple docs)
- [Activity Views HIG](https://developer.apple.com/design/human-interface-guidelines/activity-views) -- Confidence: HIGH (official Apple docs)
- [CARROT Weather share flow (Mobbin)](https://mobbin.com/explore/flows/0a4dc1d9-69e5-41d4-b16c-6568d2dd387b) -- Confidence: MEDIUM
- [Viral loops best practices (CleverTap)](https://clevertap.com/blog/viral-loops/) -- Confidence: MEDIUM
- [Mobile app referral programs (Viral Loops)](https://viral-loops.com/blog/mobile-app-referral-program/) -- Confidence: MEDIUM
- [Referral program best practices 2025 (Viral Loops)](https://viral-loops.com/blog/referral-program-best-practices-in-2025/) -- Confidence: MEDIUM
- [Streaks gamification patterns (Plotline)](https://www.plotline.so/blog/streaks-for-gamification-in-mobile-apps) -- Confidence: MEDIUM
- [In-app nudges guide 2026 (Plotline)](https://www.plotline.so/blog/in-app-nudges-ultimate-guide) -- Confidence: MEDIUM
- [Push notification examples 2026 (Netcore)](https://netcorecloud.com/blog/push-notifications-examples/) -- Confidence: MEDIUM
- [App retention trends 2026 (OneSignal)](https://onesignal.com/blog/how-leading-mobile-teams-are-rethinking-retention-for-2026/) -- Confidence: MEDIUM
- [SwiftUI ImageRenderer guide (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) -- Confidence: HIGH

---
*Feature research for: FriendsCast v3.0 — Virality & Polish milestone*
*Researched: 2026-03-06*
