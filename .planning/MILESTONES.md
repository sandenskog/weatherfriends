# Milestones

## v2.0 Bubble Pop Design + Tech Debt (Shipped: 2026-03-06)

**Phases completed:** 7 phases, 13 plans
**Timeline:** 5 dagar (2026-03-02 -> 2026-03-06)
**Codebase:** 8 846 rader Swift, 125 filer andrade (+8 147 / -708)
**Git range:** feat(09-01) -> feat(15-01)

**Key accomplishments:**
- Bubble Pop Design System med komplett fargpalett, Baloo 2 typografi, 8pt spacing grid, shadow-skala och 5 temperaturzoner
- Custom vaderikoner (14 SVG), ny app-ikon, logotyp och empty state-illustrationer
- UI-komponenter: AvatarView, BubblePopButton, chattbubblor med gradient, tab-switcher med glow, vader-stickers
- Spring-animationer: hjart-pop, konfetti, sticker-bounce, tab-glow, pull-to-refresh moln -- alla med Reduce Motion-stod
- Tech debt: Invite-lank-system ersatte displayName-match, WeatherAlertService i environment, robust kontoborttagning
- Design system cleanup: AvatarView adopterad i alla vyer, MotionReducer dead code borttagen

**Tech debt (info-niva, framtida backlog):**
- BubblePopTypography bara adopterad i 3 av ~11 feature-vyer
- BubblePopSpacing/CornerRadius bara adopterad i 2 vyer
- FriendMapView anvander initials() istallet for AvatarView (MapAnnotation-begransning)
- lookupAuthUid markerad deprecated men kvar for backward compat
- Firestore collectionGroup("friends") composite index maste verifieras i Firebase console

**Archives:** `milestones/v2.0-ROADMAP.md`, `milestones/v2.0-REQUIREMENTS.md`, `milestones/v2.0-MILESTONE-AUDIT.md`

---

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

