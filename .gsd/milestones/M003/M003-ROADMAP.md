# M003: v3.0 Virality & Polish

**Vision:** Gör appen visuellt komplett, bygg invite-upplevelse som driver viralitet, och skapa delnings- och engagemangs-loopar.

## Success Criteria

- User can send an invite link via iMessage/WhatsApp and recipient opens the app directly
- User can generate and share weather cards (single friend, comparison, daily digest)
- User sees contextual weather nudges encouraging friend interaction
- All feature views use Bubble Pop design tokens consistently
- Haptic feedback on social interactions (like, invite, share, chat-send)

## Key Risks / Unknowns

- Instagram Stories URL scheme is undocumented — may break with updates
- Universal Links require AASA deployment to work end-to-end on device
- Notification budget enforcement needs careful Cloud Functions implementation

## Proof Strategy

- Instagram Stories → retired in S02 by proving share works with canOpenURL guard
- Universal Links → retired in S01 by deploying AASA and testing on physical device
- Notification budget → retire in S04 by implementing Cloud Function with per-user weekly counter

## Verification Classes

- Contract verification: Xcode build + simulator verification per slice
- Integration verification: Firebase Firestore operations, push notification delivery
- Operational verification: Express server deployment on Synology, Universal Links end-to-end
- UAT / human verification: Visual design quality, animation feel, haptic feedback timing

## Milestone Definition of Done

This milestone is complete only when all are true:

- All 5 slices shipped and verified
- Invite flow works end-to-end (send link → install → auto-friend)
- All shareable card types generate and share correctly
- Engagement nudges appear contextually
- All feature views use BubblePopTypography/Spacing/CornerRadius
- Haptic feedback fires on like, invite, share, chat-send

## Requirement Coverage

- Covers: INVT-05, CARD-03, CARD-05, ENGM-01, ENGM-02, ENGM-03, PLSH-01, PLSH-02, PLSH-03
- Partially covers: none
- Leaves for later: CARD-06, CARD-07, ENGM-04, ENGM-05, ENGM-06, RETN-01
- Orphan risks: none

## Slices

- [x] **S01: Invite Foundation** `risk:high` `depends:[]`
  > After this: Invite links work via Universal Links with web fallback, persistent codes, and clipboard deferred deep link

- [x] **S02: Shareable Weather Cards** `risk:medium` `depends:[S01]`
  > After this: User can generate weather card images and share via share sheet or Instagram Stories

- [x] **S03: Comparison Cards & Invite Polish** `risk:medium` `depends:[S02]`
  > After this: User can generate Me vs You comparison cards and daily digest cards, invite acceptance triggers celebration animation

- [x] **S04: Engagement Loops** `risk:medium` `depends:[S01]`
  > After this: Contextual weather nudges appear in-app, inactive users get re-engagement push, notification budget enforced

- [x] **S05: Visual Polish** `risk:low` `depends:[S02,S03,S04]`
  > After this: All feature views use BubblePopTypography/Spacing/CornerRadius consistently, haptic feedback on social interactions

## Boundary Map

### S01 → S02

Produces:
- Invite link sharing UI (ShareLink) on Profile, AddFriend, FriendsTabView header
- InviteService with persistent multi-use codes
- ClipboardInviteService for deferred deep link
- Express server with AASA, invite pages, OG tags

Consumes:
- nothing (first slice)

### S02 → S03

Produces:
- WeatherCardView + WeatherCardRenderer for image generation
- Share sheet integration with UIActivityViewController
- Instagram Stories sharing via UIPasteboard

Consumes:
- InviteService from S01 (invite URL in card footer)

### S01 → S04

Produces:
- Push notification infrastructure (FCM tokens, Cloud Functions)

Consumes:
- nothing (first slice)

### S03, S04 → S05

Produces:
- All new views and components from S03 and S04

Consumes:
- BubblePopTypography, BubblePopSpacing, BubblePopCornerRadius tokens from M002
