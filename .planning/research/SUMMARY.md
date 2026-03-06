# Project Research Summary

**Project:** FriendsCast v3.0 -- Virality & Polish
**Domain:** iOS social weather app -- viral sharing, invite deep linking, engagement loops
**Researched:** 2026-03-06
**Confidence:** HIGH

## Executive Summary

FriendsCast v3.0 is about transforming a functional social weather app into one that grows organically. The core problem is clear: the current invite system uses custom URL schemes (`hotandcold://`) that are invisible to the outside world -- links fail in iMessage, get stripped by Instagram, and offer zero fallback for users without the app. Every sharing and viral growth feature is hobbled until this foundation is fixed. The recommended approach is Universal Links with a simple web fallback page, hosted on existing Synology infrastructure.

The good news: all v3.0 capabilities can be built with zero new third-party dependencies. SwiftUI's `ImageRenderer` handles weather card generation natively, Apple's TipKit provides contextual feature discovery, and Universal Links replace the broken custom scheme. The existing Bubble Pop design system, Firebase backend, and WeatherKit integration provide everything needed. The only infrastructure addition is a web domain with an AASA file and a landing page for invite link fallback.

The key risks are (1) ImageRenderer's silent failure modes -- it produces blank images when views use AsyncImage, ScrollView, or environment dependencies, requiring carefully self-contained card views; (2) engagement notification spam driving uninstalls -- research shows 3-6 weekly pushes cause 40% opt-out; and (3) deep link loss for unauthenticated users -- the current `onOpenURL` handler silently drops invite tokens when the user isn't signed in, breaking the entire viral acquisition funnel. All three are avoidable with the patterns documented in the research.

## Key Findings

### Recommended Stack

No new packages or third-party SDKs are needed. All capabilities map to built-in iOS 17 / SwiftUI APIs already available at the app's deployment target. See [STACK.md](STACK.md) for full details.

**Core technologies:**
- **ImageRenderer (SwiftUI):** Client-side weather card image generation -- native, zero-latency, renders all Bubble Pop components
- **Universal Links + AASA:** HTTPS-based invite deep links -- replaces broken custom URL scheme, works everywhere links are shared
- **TipKit (iOS 17):** Contextual in-app tips for feature discovery -- handles persistence, frequency throttling, and eligibility rules automatically
- **Instagram Stories URL scheme:** Direct share to Instagram Stories via pasteboard -- ~20 lines of code, no SDK
- **sensoryFeedback (SwiftUI):** Haptic feedback on social interactions -- native modifier, exact iOS 17 match

### Expected Features

See [FEATURES.md](FEATURES.md) for full feature landscape including dependency graph.

**Must have (table stakes):**
- Universal Links with web fallback -- without this, shared invite links are dead for new users
- One-tap invite sharing with contextual message text
- Shareable weather card (static image) with app branding
- Rich link preview (Open Graph meta tags) so links look good in iMessage/WhatsApp
- Invite success celebration with Bubble Pop animations

**Should have (differentiators):**
- "Me vs You" comparison card -- the unique viral differentiator, no other app does friend-to-friend weather comparison as a shareable image
- Share to Instagram Stories -- weather content gets massive engagement on Instagram
- Weather reaction nudges -- "It's snowing where Emma is! Send her a message?"
- Daily weather digest as shareable card

**Defer (v4+):**
- Animated weather cards (video/GIF) -- high complexity, only if static cards prove share volume
- "Weather twins" notification -- extension of nudge logic, needs proven engagement first
- Invite social proof ("3 contacts already here") -- requires backend contact cross-reference
- Friend weather check-in streak -- low impact on virality

### Architecture Approach

The architecture extends the existing MVVM + `@Observable` service pattern with two new services (`ShareService`, `NudgeService`) injected via SwiftUI `.environment()`. Weather card rendering is entirely client-side. Engagement nudges use a hybrid client + server model: in-app nudge display is client-side (NudgeService), while re-engagement push notifications are server-side (new `engagementNudgeScheduler` Cloud Function). See [ARCHITECTURE.md](ARCHITECTURE.md) for component details and data flows.

**Major components:**
1. **WeatherCardView + WeatherCardRenderer** -- Self-contained SwiftUI view rendered to UIImage via ImageRenderer at 3x scale. Two formats: story (9:16) and square (1:1)
2. **ShareService** -- Coordinates all sharing flows (weather cards, invite cards, Instagram Stories). Owns rendering pipeline and caching
3. **InviteService (modified)** -- Persistent invite codes (not deleted on use), Universal Link URL generation, redemption count tracking
4. **NudgeService** -- Client-side nudge state tracking with UserDefaults persistence. Three nudge types: invite friends, share weather, enable notifications
5. **engagementNudgeScheduler (Cloud Function)** -- Server-side scheduled push for inactive users (3+ days). Rate-limited to max 1 nudge per 3 days

**Firestore schema changes:**
- `users/{uid}`: add `inviteCode`, `lastActiveAt`, `lastNudgeSentAt`
- `invites/{code}`: stop deleting on redemption, add `redemptionCount`

### Critical Pitfalls

See [PITFALLS.md](PITFALLS.md) for all 8 pitfalls with recovery strategies.

1. **Custom URL scheme links are unclickable outside the app** -- Migrate to Universal Links before building any sharing features. This is the foundation everything depends on.
2. **ImageRenderer silently produces blank images** -- Build weather card as fully self-contained view (all data as parameters, no AsyncImage, no environment dependencies). Test by saving to Photos, not just previewing.
3. **Deep link lost for unauthenticated users** -- Store pending invite token in UserDefaults when received before auth. Auto-redeem after sign-up. The current `guard let uid` silently drops the invite.
4. **Engagement notifications become spam** -- Implement notification budget (max 1 nudge/day, 4/week across all non-chat types). Build throttling infrastructure BEFORE adding notification types.
5. **Share sheet fires without viral content** -- Always share image + URL together. Instagram Stories requires separate pasteboard code path. Embed invite link as watermark on the image itself.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Invite Foundation (Universal Links + Persistent Codes)
**Rationale:** Every sharing and viral feature depends on working invite links. The current custom URL scheme is the single biggest blocker for growth. This must come first -- all subsequent phases build on it.
**Delivers:** Working HTTPS invite links that are clickable everywhere, web fallback page with App Store redirect, rich link previews via OG meta tags, persistent invite codes that don't expire after single use.
**Addresses:** Table stakes (invite link works without app, rich link preview, one-tap invite sharing), deferred deep link handling for fresh installs.
**Avoids:** Pitfall 1 (unclickable custom scheme), Pitfall 6 (deep link lost for unauthenticated users), Pitfall 5 (invite incentive as gamification).
**Infrastructure:** Requires domain setup, AASA file hosting, web landing page on Synology. Follow existing reverse proxy + Let's Encrypt pattern.

### Phase 2: Shareable Weather Cards
**Rationale:** Once invite links work, the next highest-value feature is shareable content that drives organic discovery. Weather cards are the primary viral payload -- they make the app visible on Instagram, iMessage, and WhatsApp.
**Delivers:** Static weather card images (story + square formats), share button in WeatherDetailSheet, context menu sharing from friend list, Instagram Stories direct share.
**Addresses:** Table stakes (shareable weather card, share card for specific friend), differentiators (Instagram Stories sharing).
**Avoids:** Pitfall 2 (ImageRenderer blank output -- self-contained views), Pitfall 3 (share sheet wrong metadata -- image + URL together), Pitfall 7 (main thread blocking -- async rendering pipeline with caching).

### Phase 3: Comparison Cards + Invite Polish
**Rationale:** The "Me vs You" comparison card is THE viral differentiator -- no other weather app does friend-to-friend comparison as a shareable image. Combined with invite flow polish (prominent placement, celebration animation, visual invite card), this phase maximizes viral coefficient.
**Delivers:** Two-panel comparison weather card, visual invite card for sharing, prominent invite placement in toolbar + empty state, invite success celebration with Bubble Pop animations.
**Addresses:** Differentiator ("Me vs You" comparison card), table stakes (invite success celebration), invite discoverability.

### Phase 4: Engagement Loops
**Rationale:** Engagement features come last because they depend on the invite and sharing foundation being solid. Building nudges before the viral loop works is premature optimization.
**Delivers:** TipKit contextual tips, NudgeService with in-app banners, engagementNudgeScheduler Cloud Function, notification budget/throttling system, lastActiveAt tracking.
**Addresses:** Differentiators (weather reaction nudges), in-app feature discovery via TipKit.
**Avoids:** Pitfall 4 (notification spam -- throttling built first), Pitfall 5 (gamification -- social framing, not rewards).

### Phase 5: Visual Polish + Haptics
**Rationale:** Polish comes after all functional features are in place. Avoids the risk of breaking layouts during feature development, and ensures polish work covers all new views.
**Delivers:** sensoryFeedback on key interactions, final Bubble Pop design system alignment across all new views, visual regression testing.
**Avoids:** Pitfall 8 (visual polish breaks existing layouts -- incremental changes with testing checklist).

### Phase Ordering Rationale

- **Dependency chain:** Universal Links (Phase 1) -> Weather Cards with working links (Phase 2) -> Comparison cards reusing card infrastructure (Phase 3) -> Engagement nudges referencing invites and shares (Phase 4) -> Polish on all completed views (Phase 5)
- **Risk front-loading:** The highest-risk item (Universal Links with domain setup + AASA) is Phase 1, giving maximum time for Apple CDN propagation and testing
- **Value delivery:** Each phase delivers a usable, shippable increment. Phase 1 alone fixes the broken invite funnel. Phase 2 alone enables organic sharing.
- **No backend changes until Phase 1:** Phase 1's Firestore schema changes (persistent invite codes) are the only migration, and Phase 4's Cloud Function is additive

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1 (Invite Foundation):** Domain setup, AASA hosting, and Apple CDN propagation timing need careful testing. The web fallback page needs OG meta tag design. Research-phase recommended.
- **Phase 4 (Engagement Loops):** Notification throttling architecture across multiple Cloud Functions is non-trivial. TipKit rule design needs UX input. Research-phase recommended.

Phases with standard patterns (skip research-phase):
- **Phase 2 (Weather Cards):** ImageRenderer is well-documented with clear patterns. The rendering pipeline is straightforward.
- **Phase 3 (Comparison Cards):** Extension of Phase 2's card infrastructure. Standard SwiftUI layout work.
- **Phase 5 (Visual Polish):** Uses existing Bubble Pop design system. Standard design token application.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are native Apple APIs with official documentation. Zero third-party dependencies. Every API is verified available at iOS 17 deployment target. |
| Features | HIGH | Feature prioritization backed by dependency analysis and competitive research. Clear table stakes vs differentiators. Anti-features well-justified by PROJECT.md constraints. |
| Architecture | HIGH | Extends proven existing patterns (MVVM + @Observable + environment injection). All new components follow established codebase conventions. Data flows are straightforward. |
| Pitfalls | HIGH | Critical pitfalls (broken deep links, ImageRenderer quirks, notification spam) backed by Apple Developer Forums posts and industry statistics. Recovery strategies documented. |

**Overall confidence:** HIGH

### Gaps to Address

- **Domain for Universal Links:** No domain is confirmed for the AASA file. Existing `apps.sandenskog.se` could work, or a new `friendscast.app` domain. Decision needed before Phase 1 implementation.
- **Instagram Stories API stability:** Instagram's URL scheme for Stories sharing is undocumented officially and could change. LOW confidence on long-term stability. Mitigation: guard with `canOpenURL` and degrade gracefully to standard share sheet.
- **OG image generation for link previews:** The web fallback page needs an OG preview image. Options: static generic image, or server-side per-invite image generation. Decision needed during Phase 1 planning.
- **Invite redemption security:** Current client-side Firestore writes for invite redemption should move to a Cloud Function for server-side validation. Not researched in depth -- address during Phase 1 planning.
- **Notification permission prompt timing:** When to ask for notification permission in the context of new engagement nudges. UX decision needed during Phase 4.

## Sources

### Primary (HIGH confidence)
- [Apple ImageRenderer documentation](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Apple TipKit documentation](https://developer.apple.com/documentation/tipkit/)
- [Apple Universal Links documentation](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Apple Developer Forums -- ImageRenderer blank render issues](https://developer.apple.com/forums/thread/725196)
- [Apple Developer Forums -- AsyncImage + ImageRenderer](https://developer.apple.com/forums/thread/728114)
- [Firebase Dynamic Links shutdown FAQ](https://firebase.google.com/support/dynamic-links-faq)
- [Firebase Cloud Messaging iOS docs](https://firebase.google.com/docs/cloud-messaging/ios/get-started)
- [Firebase Schedule Functions docs](https://firebase.google.com/docs/functions/schedule-functions)
- [Push notification statistics 2025 (Business of Apps)](https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/)

### Secondary (MEDIUM confidence)
- [SwiftLee -- Universal Links implementation](https://www.avanderlee.com/swiftui/universal-links-ios/)
- [Hacking with Swift -- ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image)
- [Hacking with Swift -- ShareLink](https://www.hackingwithswift.com/books/ios-swiftui/sharing-an-image-using-sharelink)
- [Universal Deep Links 2026 guide (DEV Community)](https://dev.to/marko_boras_64fe51f7833a6/universal-deep-links-2026-complete-guide-36c4)
- [Mastering TipKit (Fat Bob Man)](https://fatbobman.com/en/posts/mastering-tipkit-basic/)
- [Instagram Stories sharing from iOS (Medium)](https://medium.com/@danielcrompton5/share-content-to-an-instagram-story-from-an-ios-app-d55b1e10e68a)
- [CARROT Weather share flow (Mobbin)](https://mobbin.com/explore/flows/0a4dc1d9-69e5-41d4-b16c-6568d2dd387b)
- Existing codebase analysis: InviteService.swift, HotAndColdFriendsApp.swift, AddFriendSheet.swift

---
*Research completed: 2026-03-06*
*Ready for roadmap: yes*
