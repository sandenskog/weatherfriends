---
phase: 17
slug: shareable-weather-cards
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-07
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | none — no test target configured yet |
| **Quick run command** | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme HotAndColdFriends -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** SwiftUI Preview verification of WeatherCardView
- **After every plan wave:** Manual testing of sharing flow on simulator/device
- **Before `/gsd:verify-work`:** Full manual test on real device (Share Sheet + Instagram Stories)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | CARD-01 | unit | `WeatherCardRendererTests` — verify UIImage not nil | No — W0 | pending |
| 17-01-02 | 01 | 1 | CARD-01 | manual | SwiftUI Preview — visual check | N/A | pending |
| 17-02-01 | 02 | 2 | CARD-02 | manual | Manual — share sheet requires user dialog | N/A | pending |
| 17-02-02 | 02 | 2 | CARD-04 | manual | Manual — requires Instagram on device | N/A | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] Unit test stub for `WeatherCardRenderer` — verify ImageRenderer produces non-nil UIImage
- [ ] Add `LSApplicationQueriesSchemes` with `instagram-stories` to Info.plist

*No test framework install needed — XCTest is built-in.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Share via share sheet | CARD-02 | Share sheet is a system UI requiring user interaction | 1. Swipe left on friend row 2. Tap Share 3. Tap Share Sheet button 4. Verify image appears in share sheet |
| Share to Instagram Stories | CARD-04 | Requires Instagram installed on real device | 1. Swipe left on friend row 2. Tap Share 3. Tap Instagram Stories button 4. Verify story opens with weather card as background |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
