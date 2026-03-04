# Milestones

## v1.0 Hot & Cold Friends MVP (Shipped: 2026-03-04)

**Phases completed:** 13 phases, 24 plans
**Timeline:** 3 dagar (2026-03-02 → 2026-03-04)
**Codebase:** 7 576 rader Swift, 178 filer

**Key accomplishments:**
- Social login (Apple/Google/Facebook) med onboarding, profil och stad-autocomplete
- Vädersorterad vänlista med realtidsväder via WeatherKit och 30-min TTL-cache
- Kontaktimport från iOS med AI-driven platsgissning (OpenAI via Firebase Cloud Function)
- Realtidschatt (1-till-1 + grupp) med push-notiser, moderering och väderreaktioner
- Tre vyer: sorterad lista, MapKit-karta och väder-kategorier + daglig sammanfattning
- iOS-widget, animerade väderillustrationer och kontoborttagning (App Store-krav)

**Tech debt (info-nivå, v2 backlog):**
- WeatherAlertService.checkAlertsForFriends bara vid cold-start
- lookupAuthUid baserat på displayName (ej unikt)
- Orphaned messages vid kontoborttagning (edge case)

**Archives:** `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md`, `milestones/v1.0-MILESTONE-AUDIT.md`

---

