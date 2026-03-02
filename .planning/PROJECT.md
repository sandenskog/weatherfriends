# Hot & Cold Friends

## What This Is

En iOS-app som visar din vänlista organiserad utifrån vädret där dina vänner befinner sig. Importera vänner från sociala plattformar (Facebook, Instagram, Snapchat), se deras väder i realtid, och chatta med dem — med vädret som naturlig samtalsöppnare. Appen ska kännas varm, social och personlig.

## Core Value

Öppna appen och omedelbart se hur vädret är hos dina vänner — sorterat, visuellt och levande — så att vädret blir en naturlig anledning att höra av sig.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Importera vänner från Facebook, Instagram, Snapchat m.fl.
- [ ] AI-driven platsgissning vid import (adress, telefonnummer/landsnummer, profilinfo)
- [ ] Användare uppmanas ange stad/land för favoriter vid onboarding
- [ ] Tre vyer: vädersorterad lista, väderkarta, grupperade väderkort
- [ ] Default-vy med val av 6 favoriter som visas överst
- [ ] Live-exempeldata vid first run (inte tom vy innan konfiguration)
- [ ] Rik vädervisning: temperatur, ikon, animerad illustration, vind/fuktighet/prognos
- [ ] Fullständig inbyggd chatt
- [ ] Social login (Facebook/Google/Apple)
- [ ] Push-notiser: vädervarningar hos vänner + daglig sammanfattning
- [ ] Native iOS med SwiftUI
- [ ] Managed backend (Firebase/Supabase)
- [ ] App Store-lansering

### Out of Scope

- Android-version — iOS-first, eventuellt senare
- Video/röstsamtal — fokus på textchatt i v1
- Egenutvecklad backend — managed tjänst för snabbhet och skalbarhet

## Context

- Appen fyller tre behov: nyfikenhet (vad har vännerna för väder?), underhållning (kontrasten -15° vs +30°), och social trigger (anledning att höra av sig)
- Känslan ska vara varm och social — som att hälsa på vänner, inte en väder-widget
- Platsdata är kritiskt: utan plats = "unknown weather" = värdelös upplevelse. AI-gissningsmodellen vid import är nyckeln till att appen känns användbar direkt
- Onboarding-flödet med 6 favoriter + manuell stad/land är det primära use caset
- First-run måste visa live-exempeldata så appen inte känns tom

## Constraints

- **Plattform**: iOS only, SwiftUI — kräver Xcode och Apple Developer Account
- **Backend**: Firebase eller Supabase — managed, inte self-hosted
- **Väder-API**: Behöver ett tillförlitligt väder-API med global täckning (t.ex. OpenWeatherMap, WeatherAPI)
- **Sociala API:er**: Facebook, Instagram, Snapchat har begränsade vän-import-API:er — behöver utredas under research
- **App Store**: Måste uppfylla Apples review-riktlinjer (privacy, data handling)
- **Design**: Varm, social känsla — ej minimalistisk/monokromatisk som övriga projekt

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native Swift/SwiftUI | Bäst prestanda och native iOS-känsla för App Store-lansering | — Pending |
| Firebase/Supabase backend | Snabbt att komma igång, skalbart, kräver ingen serverhantering | — Pending |
| Social login | Naturligt val då appen importerar från sociala plattformar | — Pending |
| AI-driven platsgissning | Löser "unknown weather"-problemet vid massimport av kontakter | — Pending |
| 6 favoriter som default | Fokuserar upplevelsen och gör onboarding konkret | — Pending |

---
*Last updated: 2026-03-02 after initialization*
