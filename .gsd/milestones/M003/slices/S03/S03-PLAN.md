# S03: Comparison Cards & Invite Polish

**Goal:** User can generate Me vs You comparison cards, daily digest cards, and sees a Bubble Pop celebration when an invited friend accepts.
**Demo:** Swipe-to-share on a friend row shows preview sheet with "Compare" option generating a side-by-side card. Long-press on friend list header generates a daily digest card. Invite redemption triggers confetti animation with toast.

## Must-Haves

- ComparisonCardView showing two friends side-by-side (user + friend) with weather, avatars, temperatures
- DailyDigestCardView showing a grid/list of all friends' weather as a single shareable image
- Both card types render via ImageRenderer and share via ShareLink (reuse S02 pattern)
- Invite redemption triggers ConfettiOverlay (reuse existing animation) with enhanced toast
- Xcode build succeeds with zero warnings in new files

## Proof Level

- This slice proves: contract + integration
- Real runtime required: yes (Xcode build + simulator)
- Human/UAT required: yes (visual quality of cards)

## Verification

- `xcodebuild -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds
- ComparisonCardView renders in Xcode preview with sample data showing two friends side-by-side
- DailyDigestCardView renders in Xcode preview with 5+ friends
- WeatherCardPreviewSheet shows "Compare" button that generates comparison card
- Invite redemption in HotAndColdFriendsApp.swift triggers confetti + enhanced toast
- Both new card types export via WeatherCardRenderer (ImageRenderer) at Retina scale

## Integration Closure

- Upstream surfaces consumed: `WeatherCardRenderer`, `WeatherCardCategory`, `WeatherCardPreviewSheet`, `ConfettiOverlay`, `InviteService.redeemInvite`, `FriendListViewModel.myWeather`
- New wiring introduced: ComparisonCardView + DailyDigestCardView integrated into preview sheet, confetti wired to invite redemption in app root
- What remains: S04 (engagement loops), S05 (visual polish + haptics)

## Tasks

- [x] **T01: ComparisonCardView — side-by-side weather comparison card** `est:20m`
  - Why: Core deliverable — CARD-03 requires a Me vs You comparison card
  - Files: `HotAndColdFriends/Features/WeatherCard/ComparisonCardView.swift`
  - Do:
    1. Create ComparisonCardView taking two FriendWeather (user + friend). Layout: landscape-ish 16:9 (693×390) with weather background from the friend's weather category. Left side shows user avatar+name+city+temp, right side shows friend avatar+name+city+temp. VS divider in center. FriendsCast branding at bottom. Same cardTextStyle pattern as WeatherCardView.
    2. Reuse AvatarView (gradient+initials, no photoURL — same ImageRenderer constraint as S02).
    3. Reuse WeatherCardCategory.background(for:) for the background.
  - Verify: Xcode build succeeds. Preview renders with sample FriendWeather data for both sides.
  - Done when: ComparisonCardView compiles and renders a visually balanced side-by-side card with both friends' weather data

- [x] **T02: DailyDigestCardView — all friends weather summary card** `est:20m`
  - Why: CARD-05 requires a daily digest shareable card showing all friends' weather
  - Files: `HotAndColdFriends/Features/WeatherCard/DailyDigestCardView.swift`
  - Do:
    1. Create DailyDigestCardView taking `[FriendWeather]`. Layout: portrait 9:16 (390×693). Header: "Today's Weather" + date. Body: vertical list of friend rows (avatar 32pt, name, city, temp, weather icon) — up to 8 friends visible, scroll-clip if more. Warm gradient background (BubblePopColors primary). FriendsCast branding at bottom.
    2. Each row: AvatarView (gradient+initials, 32pt), name left-aligned, temp right-aligned, small weather icon.
    3. Reuse cardTextStyle for text readability.
  - Verify: Xcode build succeeds. Preview renders with 5+ sample friends.
  - Done when: DailyDigestCardView compiles and renders a clean summary of multiple friends' weather

- [x] **T03: Wire comparison and digest cards into sharing flow** `est:20m`
  - Why: Cards must be accessible to users through the existing sharing UI
  - Files: `HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift`, `HotAndColdFriends/Features/WeatherCard/WeatherCardRenderer.swift`, `HotAndColdFriends/Features/FriendList/FriendListView.swift`, `HotAndColdFriends/Features/FriendList/FriendsTabView.swift`
  - Do:
    1. Extend WeatherCardRenderer with `renderComparison(user:friend:) -> UIImage?` and `renderDigest(friends:) -> UIImage?`.
    2. Update WeatherCardPreviewSheet: add a "Compare" button that renders ComparisonCardView using the current friend + user's own weather (from FriendListViewModel.myWeather passed via environment or parameter). Show comparison card preview when tapped, with ShareLink for the rendered image.
    3. Add a digest share action in FriendsTabView toolbar (or long-press) that opens a new DigestPreviewSheet showing DailyDigestCardView with all friends, plus ShareLink.
  - Verify: Xcode build succeeds. Compare button visible in WeatherCardPreviewSheet. Digest action visible in toolbar.
  - Done when: Both card types are shareable via the existing share flow with rendered images and invite URLs

- [x] **T04: Invite celebration — confetti + enhanced toast on friend acceptance** `est:15m`
  - Why: INVT-05 requires a Bubble Pop celebration when an invited friend accepts
  - Files: `HotAndColdFriends/App/HotAndColdFriendsApp.swift`, `HotAndColdFriends/Services/InviteService.swift`
  - Do:
    1. Add a `@State private var showInviteCelebration = false` and `@State private var celebrationZone: TemperatureZone = .warm` to HotAndColdFriendsApp.
    2. After successful `redeemInvite` in the onOpenURL handler, set `showInviteCelebration = true`. Determine zone from the new friend's city weather if available, otherwise default to `.warm`.
    3. Add `.confettiOverlay(isActive: $showInviteCelebration, zone: celebrationZone)` to the app root (same pattern as existing ConfettiOverlay usage).
    4. Enhance the existing clipboard toast: when invite is redeemed via onOpenURL (not clipboard), show a richer toast with the friend's name and a brief celebration message. Use the existing toast pattern but with a slightly longer display (4 seconds instead of 3).
    5. Also trigger celebration when ClipboardInviteService successfully redeems (update the `.task` block and clipboard toast overlay).
  - Verify: Xcode build succeeds. Confetti overlay wired to invite redemption. Toast shows friend name on successful redemption.
  - Done when: Both onOpenURL and clipboard invite redemption trigger confetti animation and enhanced toast

## Files Likely Touched

- `HotAndColdFriends/Features/WeatherCard/ComparisonCardView.swift` (new)
- `HotAndColdFriends/Features/WeatherCard/DailyDigestCardView.swift` (new)
- `HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift` (modified)
- `HotAndColdFriends/Features/WeatherCard/WeatherCardRenderer.swift` (modified)
- `HotAndColdFriends/Features/FriendList/FriendListView.swift` (modified)
- `HotAndColdFriends/Features/FriendList/FriendsTabView.swift` (modified)
- `HotAndColdFriends/App/HotAndColdFriendsApp.swift` (modified)
