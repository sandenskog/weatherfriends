# Project

## What This Is

En iOS-app (FriendsCast / Hot & Cold Friends) som visar din vänlista organiserad utifrån vädret där dina vänner befinner sig. Importera vänner från iOS-kontakter (med AI-driven platsgissning) eller via invite-länk, se deras väder i realtid, och chatta med dem — med vädret som naturlig samtalsöppnare. Appen har tre vyer (sorterad lista, karta, kategorier), push-notiser, hemskärmswidget och ett komplett Bubble Pop design system med temperaturzon-gradienter, spring-animationer och custom väderikoner.

Shipped v2.0 med 8 846 rader Swift + Firebase Cloud Functions (TypeScript). v3.0 in progress — invite foundation and shareable weather cards complete, comparison cards/engagement loops/visual polish remaining.

## Core Value

Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## Current State

- **v1.0 shipped** (2026-03-04): Social login, vädersorterad vänlista, kontaktimport med AI, realtidschatt, push, widget
- **v2.0 shipped** (2026-03-06): Bubble Pop Design System, custom väderikoner, spring-animationer, invite-länk-system
- **v3.0 in progress** (started 2026-03-07): Phases 16-17 complete (invite foundation, shareable weather cards). Phases 18-20 remaining (comparison cards, engagement loops, visual polish).

## Architecture / Key Patterns

- **Tech stack:** SwiftUI (iOS 17+), Firebase (Auth, Firestore, Storage, Cloud Functions, FCM), WeatherKit, MapKit, WidgetKit
- **AI:** OpenAI gpt-4o-mini via Firebase Cloud Function proxy for contact location guessing
- **Build:** xcodegen with project.yml, fastlane for distribution
- **Services:** `@Observable @MainActor` services injected via `.environment()` or parameter injection
- **Design:** Bubble Pop Design System — 5 temperature zones with gradients, Baloo 2 typography, 8pt spacing grid
- **Invite system:** Persistent multi-use invite codes, Universal Links on apps.sandenskog.se, clipboard deferred deep link
- **Sharing:** WeatherCardView + ImageRenderer for shareable weather card images
- **Web:** Express server on apps.sandenskog.se (Docker/Synology) for AASA, invite pages, OG tags

## Capability Contract

See `.gsd/REQUIREMENTS.md` for the explicit capability contract, requirement status, and coverage mapping.

## Milestone Sequence

- [x] M001: v1.0 MVP — Social login, weather-sorted friend list, contact import, chat, push, widget
- [x] M002: v2.0 Bubble Pop Design + Tech Debt — Design system, custom icons, animations, invite links, cleanup
- [x] M003: v3.0 Virality & Polish — Visual polish, invite experience, shareable cards, engagement loops
