# S05: Visual Polish

**Goal:** All feature views use BubblePopTypography/Spacing/CornerRadius consistently, and social interactions trigger haptic feedback.
**Demo:** Every screen uses Baloo 2 headings instead of system fonts, consistent 8pt spacing grid, and the user feels haptic taps on like, invite, share, and chat-send.

## Must-Haves

- BubblePopTypography adopted in all major feature views (headings, buttons, body text)
- BubblePopSpacing and CornerRadius used consistently across views
- sensoryFeedback haptics on: favorite toggle, invite share, weather card share, chat message send
- Xcode build succeeds with zero warnings in modified files

## Verification

- `xcodebuild -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds
- `grep -rL "bubbleH\|bubbleButton\|bubbleBody\|bubbleCaption" HotAndColdFriends/Features/ --include="*.swift" | grep -v ViewModel | grep -v Modifier | grep -v Model` returns only animation files and view models (no user-facing views)
- sensoryFeedback modifiers present on favorite toggle, share actions, chat send

## Tasks

- [x] **T01: BubblePopTypography adoption in core views** `est:25m`
  - Why: PLSH-01 — all feature views should use Baloo 2 consistently
  - Files: `HotAndColdFriends/Features/Login/LoginView.swift`, `HotAndColdFriends/Features/Onboarding/OnboardingView.swift`, `HotAndColdFriends/Features/Onboarding/OnboardingNameView.swift`, `HotAndColdFriends/Features/Onboarding/OnboardingLocationView.swift`, `HotAndColdFriends/Features/Onboarding/OnboardingPhotoView.swift`, `HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift`, `HotAndColdFriends/Features/Profile/ProfileView.swift`, `HotAndColdFriends/Features/Profile/EditProfileView.swift`, `HotAndColdFriends/Features/Profile/FriendProfileView.swift`
  - Do:
    1. Replace `.title`, `.title2`, `.title3` headings with `.bubbleH1`, `.bubbleH2`, `.bubbleH3`.
    2. Replace `.headline`, `.subheadline` used for buttons/labels with `.bubbleButton`.
    3. Keep `.body`/`.caption`/`.footnote` as-is — they're already `.bubbleBody`/`.bubbleCaption`/`.bubbleFootnote` (system fonts per design spec).
    4. Apply to: LoginView (title, button labels), all Onboarding views (step titles, button labels), ProfileView (name, section headers), EditProfileView (field labels), FriendProfileView (name, city).
  - Verify: Xcode build succeeds. grep confirms these files now use bubble typography.
  - Done when: Login, onboarding, and profile views use Baloo 2 for headings and buttons

- [x] **T02: BubblePopTypography + Spacing in chat and list views** `est:20m`
  - Why: PLSH-01 + PLSH-02 — chat and list views are the most-used screens
  - Files: `HotAndColdFriends/Features/Chat/ChatView.swift`, `HotAndColdFriends/Features/Chat/ConversationListView.swift`, `HotAndColdFriends/Features/Chat/NewConversationSheet.swift`, `HotAndColdFriends/Features/Chat/WeatherHeaderView.swift`, `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift`, `HotAndColdFriends/Features/FriendList/FriendCategoryView.swift`, `HotAndColdFriends/Features/FriendList/WeatherDetailSheet.swift`, `HotAndColdFriends/Features/ContactImport/ContactImportView.swift`, `HotAndColdFriends/Features/ContactImport/ContactImportRow.swift`, `HotAndColdFriends/Features/ContactImport/ImportReviewView.swift`
  - Do:
    1. Same typography replacement as T01: headings → bubbleH*, button labels → bubbleButton.
    2. Replace hardcoded padding values (10, 12, 14, 15, 20, 24, 32) with nearest Spacing constants (xs=4, sm=8, md=16, lg=24, xl=32).
    3. Replace hardcoded corner radius values with CornerRadius constants (sm=12, md=20, lg=28, xl=50).
    4. Don't change values that are already correct or within 2pt of a grid value.
  - Verify: Xcode build succeeds.
  - Done when: Chat, conversation list, add friend, weather detail, contact import views use design tokens

- [x] **T03: Haptic feedback on social interactions** `est:15m`
  - Why: PLSH-03 — tactile feedback enhances the social feel
  - Files: `HotAndColdFriends/Features/FriendList/FriendListView.swift`, `HotAndColdFriends/Features/FriendList/FriendsTabView.swift`, `HotAndColdFriends/Features/WeatherCard/WeatherCardPreviewSheet.swift`, `HotAndColdFriends/Features/Chat/ChatView.swift`
  - Do:
    1. Add `.sensoryFeedback(.impact(weight: .medium), trigger: ...)` on favorite toggle in FriendListView (both sections).
    2. Add `.sensoryFeedback(.impact(weight: .light), trigger: ...)` on share actions: invite ShareLink tap in FriendsTabView, share button in WeatherCardPreviewSheet.
    3. Add `.sensoryFeedback(.impact(weight: .light), trigger: ...)` on chat message send in ChatView.
    4. Use a `@State private var hapticTrigger` pattern: toggle trigger value in the action closure, sensoryFeedback modifier watches the trigger.
  - Verify: Xcode build succeeds. sensoryFeedback modifiers present in all 4 files.
  - Done when: Favorite toggle, share, and chat-send trigger haptic feedback

## Files Likely Touched

- `HotAndColdFriends/Features/Login/LoginView.swift`
- `HotAndColdFriends/Features/Onboarding/*.swift`
- `HotAndColdFriends/Features/Profile/*.swift`
- `HotAndColdFriends/Features/Chat/*.swift`
- `HotAndColdFriends/Features/FriendList/*.swift`
- `HotAndColdFriends/Features/ContactImport/*.swift`
