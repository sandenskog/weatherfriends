# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| 1 | 2026-03-02 | M001 | Platform choice | Native Swift/SwiftUI | Best performance and native iOS feel | No |
| 2 | 2026-03-02 | M001 | Backend | Firebase (Auth, Firestore, Storage, Functions, FCM) | Fast to start, FCM integration, social auth | No |
| 3 | 2026-03-02 | M001 | Contact import strategy | iOS Contacts with AI location guessing | Facebook/Instagram/Snapchat lack friend import APIs | No |
| 4 | 2026-03-02 | M001 | Weather API | Apple WeatherKit | Free 500K calls/month, no key management | No |
| 5 | 2026-03-02 | M001 | Deployment target | iOS 17+ | @Observable, async/await, CLLocationUpdate | No |
| 6 | 2026-03-02 | M001 | AI proxy | OpenAI via Cloud Function | Protects API key, server-side validation | No |
| 7 | 2026-03-02 | M001 | Project generation | xcodegen with project.yml | CLI-based, version controlled | No |
| 8 | 2026-03-03 | M001 | Chat participant IDs | Auth UID in conversations (not Friend.id) | Correct participant matching | No |
| 9 | 2026-03-03 | M001 | Conversation ID format | Deterministic sorted UIDs joined with _ | No duplicates, no lookup needed | No |
| 10 | 2026-03-04 | M002 | Design system | Bubble Pop with 5 temperature zones | Warm, social feel with temperature gradients | No |
| 11 | 2026-03-04 | M002 | Avatar component | AvatarView as single avatar component everywhere | Consistent gradient avatars across all views | No |
| 12 | 2026-03-05 | M002 | Animation accessibility | MotionReducer pattern | Centralized Reduce Motion support for all animations | No |
| 13 | 2026-03-06 | M002 | Friend lookup | Invite link system replacing displayName match | displayName is not unique — invite codes are | No |
| 14 | 2026-03-07 | M003/S01 | Invite URL format | Universal Links on apps.sandenskog.se | HTTPS links work everywhere, no custom scheme | No |
| 15 | 2026-03-07 | M003/S01 | Invite code lifecycle | Permanent multi-use with redeemedBy array | Codes never expire, track who used them | Yes |
| 16 | 2026-03-07 | M003/S01 | Deferred deep link | Clipboard with friendscast-invite:token:timestamp format | Works without app installed, 7-day TTL | Yes |
| 17 | 2026-03-07 | M003/S01 | Web fallback | Inline CSS in invite.ejs | Single-page simplicity | Yes |
| 18 | 2026-03-07 | M003/S01 | Firebase Admin init | applicationDefault() credentials | GOOGLE_APPLICATION_CREDENTIALS env var at runtime | No |
| 19 | 2026-03-07 | M003/S02 | Weather card avatar | Gradient+initials only (no photoURL) | ImageRenderer compatibility | No |
| 20 | 2026-03-07 | M003/S02 | Instagram Stories | UIPasteboard with 5-minute expiration | Undocumented API — guard with canOpenURL | Yes |
| 21 | 2026-03-13 | M003/S03 | Comparison card background | Use friend's weather category | Friend is the interesting comparison target | No |
| 22 | 2026-03-13 | M003/S03 | Digest card friend limit | Show up to 8 friends | ImageRenderer memory + visual readability | Yes |
| 23 | 2026-03-13 | M003/S03 | Card mode UI | Mode picker in preview sheet | Single sheet with toggle, not separate sheets | No |
| 24 | 2026-03-13 | M003/S03 | Celebration zone | Default to .warm | Warm social feel, complexity not worth per-friend zone | Yes |
| 25 | 2026-03-13 | M003/S04 | Nudge threshold | Only extreme/interesting weather | Should feel special, not appear on every row | Yes |
| 26 | 2026-03-13 | M003/S04 | Re-engagement cooldown | 7 days between sends | Avoid spam, respect user attention | Yes |
| 27 | 2026-03-13 | M003/S04 | Notification budget | 5 non-chat pushes/week, chat exempt | Real-time messages always delivered, scheduled pushes capped | Yes |
| 28 | 2026-03-13 | M003/S04 | Budget week boundary | Monday 00:00 UTC | Simple, consistent, aligns with ISO 8601 week | No |
