# Phase 13: BubblePopButton Adoption - Research

**Researched:** 2026-03-06
**Domain:** SwiftUI component adoption / design system consistency
**Confidence:** HIGH

## Summary

BubblePopButton existerar i `HotAndColdFriends/DesignSystem/BubblePopButton.swift` som en fullt fungerande komponent med pill-form (Capsule), gradient-bakgrund (bubblePrimary till bubbleSecondary) och bounce-effekt (spring animation via DragGesture). Problemet ar att komponenten har noll konsumenter utanfor sin egen `#Preview` -- den byggdes i Phase 10 men adopterades aldrig i nagon user-facing vy.

Appen har flera stallen dar vanliga `Button`-element med manuell styling (RoundedRectangle, systemGray bakgrund) anvands for primara actions. De basta kandidaterna for BubblePopButton-adoption ar: **AddFriendSheet** ("Redeem invite"-knappen), **ProfileView** ("Generate invite link"-knappen) och **OnboardingFavoritesView** ("Importera fran kontakter" / "Lagg till en van"-knapparna). Dessa ar alla user-facing CTAs dar gradient + bounce ger tydlig visuell forbattring.

**Primary recommendation:** Byt ut minst en primar action-knapp (forslagsvis "Redeem invite" i AddFriendSheet) mot BubblePopButton, och overvig att adopta i ytterligare 1-2 vyer for konsekvent design.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| COMP-02 | Knappar har pill-form (Capsule), gradient-bakgrund och bounce-effekt vid tryck | BubblePopButton har alla tre egenskaper implementerade. Adoption i minst en user-facing vy uppfyller kravet. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Projektets UI-framework |
| BubblePopButton | local | Pill-shaped gradient button | Redan byggd i DesignSystem/ |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BubblePopColors | local | Brand gradient colors (.bubblePrimary, .bubbleSecondary) | Anvands av BubblePopButton |
| BubblePopTypography | local | .bubbleButton font | Anvands av BubblePopButton |
| BubblePopSpacing | local | Spacing.lg, Spacing.sm, Spacing.xs | Anvands av BubblePopButton |
| BubblePopShadows | local | .shadowGlowPrimary() | Anvands av BubblePopButton |

## Architecture Patterns

### BubblePopButton API
```swift
// Befintlig API - enkel att anvanda
BubblePopButton(title: "Redeem invite") {
    // action
}

// Destructive variant
BubblePopButton(title: "Delete Account", action: {
    // action
}, isDestructive: true)
```

### Adoption Pattern: Direkt ersattning
**What:** Byt ut `Button { } label: { Text(...).padding().background().clipShape() }` mot `BubblePopButton(title:action:)`
**When to use:** Primara action-knappar (CTAs) i formulair, sheets, och onboarding-floden

**Example - AddFriendSheet (fore):**
```swift
Button {
    Task { await redeemInvite() }
} label: {
    if isRedeeming {
        ProgressView().frame(maxWidth: .infinity).padding()
    } else {
        Text("Redeem invite")
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding()
    }
}
.background(canRedeem ? Color.primary : Color(.systemGray4))
.foregroundStyle(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.disabled(!canRedeem || isRedeeming)
```

**Example - AddFriendSheet (efter):**
```swift
BubblePopButton(title: "Redeem invite") {
    Task { await redeemInvite() }
}
.opacity(canRedeem ? 1.0 : 0.5)
// OBS: BubblePopButton saknar loading state och disabled state -- se "Don't Hand-Roll"
```

### Kandidatvyer for adoption

| Vy | Knapp | Prioritet | Kommentar |
|----|-------|-----------|-----------|
| AddFriendSheet | "Redeem invite" | HÖG | Primar CTA, tydlig forbattring |
| ProfileView | "Generate invite link" | MEDIUM | Primar action, social kontext |
| OnboardingFavoritesView | "Importera fran kontakter" | MEDIUM | Forsta-intryck-knapp |
| OnboardingFavoritesView | "Lagg till en van" | LAG | Sekundar action |

### Knappar som INTE ska bytas

| Vy | Knapp | Anledning |
|----|-------|-----------|
| LoginView | Apple/Google/Facebook login | Brandade login-knappar med specifika Apple/Google-riktlinjer |
| Toolbar | "Cancel"/"Save" | Systemkonvention -- toolbar-knappar ska vara textlainkar |
| Alert | "OK"/"Cancel" | System-alerts har egen styling |
| ProfileView | "Radera konto" | Destructive role-knapp, system-styling laimplig |
| ChatBubbleView | Rapportera/Blockera | Alert-knappar, system-styling |

### Anti-Patterns to Avoid
- **Overadoption:** Anvand INTE BubblePopButton for sekundara/tertiaira actions, toolbar-items, eller destructive-only knappar dar iOS system-styling ar mer laimplig
- **Bryta tillganglighet:** BubblePopButton saknar reduceMotion-check for sin bounce-animation -- detta bor fixas vid adoption

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pill-shaped gradient button | Custom Button med gradient + capsule | BubblePopButton | Redan byggd, testad, anvander design tokens |
| Button bounce animation | Egen spring-animation pa Button | BubblePopButton's inbyggda DragGesture bounce | Konsekvent beteende |

## Common Pitfalls

### Pitfall 1: BubblePopButton saknar loading/disabled state
**What goes wrong:** BubblePopButton har ingen inbyggd `isLoading` eller `isDisabled` property. Vyer som AddFriendSheet behover visa ProgressView och disabla knappen under async-operationer.
**Why it happens:** Komponenten designades enkelt i Phase 10.
**How to avoid:** Utoka BubblePopButton med optionella `isLoading: Bool = false` och `isDisabled: Bool = false` parametrar, eller hantera loading/disabled i den anropande vyn med `.opacity()` och `.allowsHitTesting()`.
**Warning signs:** Knappen ar klickbar under pagaende naitverksanrop.

### Pitfall 2: BubblePopButton saknar full-width support
**What goes wrong:** Befintliga knappar i AddFriendSheet och ProfileView anvander `.frame(maxWidth: .infinity)` for att ta full bredd. BubblePopButton ar storleksanpassad efter textinnehall.
**Why it happens:** BubblePopButton anvander padding-baserad storlek, inte frame-baserad.
**How to avoid:** Lagg till `.frame(maxWidth: .infinity)` pa BubblePopButton, eller lagg till en `isFullWidth: Bool` parameter.

### Pitfall 3: Reduce Motion compliance (ANIM-07)
**What goes wrong:** BubblePopButton har `.animation(.spring(...), value: isPressed)` men checkar INTE `@Environment(\.accessibilityReduceMotion)`. ANIM-07 kraver att animationer respekterar Reduce Motion.
**Why it happens:** Oversigt i Phase 10.
**How to avoid:** Lagg till reduceMotion-check i BubblePopButton: om reduceMotion ar aktivt, skippa bounce-animationen eller anvand en subtil crossfade.

### Pitfall 4: DragGesture-konflikt med ScrollView
**What goes wrong:** BubblePopButton anvander `DragGesture(minimumDistance: 0)` via `.simultaneousGesture()` for bounce-effekten. I en ScrollView kan detta ibland interferera med scroll-gester.
**Why it happens:** minimumDistance: 0 fangar alla touch-events.
**How to avoid:** `simultaneousGesture` (som redan anvands) hanterar detta korrekt i de flesta fall. Testa i faktiska ScrollView-kontexter (AddFriendSheet ar wrappat i ScrollView).

## Code Examples

### Minimal adoption i AddFriendSheet
```swift
// Ersatt den manuella Button med BubblePopButton
BubblePopButton(title: "Redeem invite") {
    Task { await redeemInvite() }
}
.frame(maxWidth: .infinity)  // Full bredd som befintlig knapp
.opacity(canRedeem && !isRedeeming ? 1.0 : 0.5)
.allowsHitTesting(canRedeem && !isRedeeming)
.overlay {
    if isRedeeming {
        ProgressView()
    }
}
```

### BubblePopButton med loading state (utokad)
```swift
struct BubblePopButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false
    var isLoading: Bool = false
    var isDisabled: Bool = false

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // ... existing body with:
        .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled && !isLoading)
    }
}
```

## Open Questions

1. **Full-width vs. content-width**
   - What we know: Befintliga knappar i AddFriendSheet/ProfileView ar full-width. BubblePopButton ar content-sized.
   - What's unclear: Ska BubblePopButton alltid vara full-width i formulairkontext, eller ska det styras av callsite?
   - Recommendation: Lagg till modifier i callsite (`.frame(maxWidth: .infinity)`) -- enklast och mest flexibelt.

2. **Hur manga vyer ska adopteras?**
   - What we know: COMP-02 kraver "minst en user-facing vy". Success criteria sager samma.
   - What's unclear: Om vi bor passa pa att adopta i flera vyer for konsistens.
   - Recommendation: Adopta i 2-3 vyer (AddFriendSheet + ProfileView + ev. OnboardingFavoritesView) for att fa verklig designkonsistens utan over-scope.

## Sources

### Primary (HIGH confidence)
- `HotAndColdFriends/DesignSystem/BubblePopButton.swift` - komponentens implementation
- `HotAndColdFriends/Features/FriendList/AddFriendSheet.swift` - kandidatvy
- `HotAndColdFriends/Features/Profile/ProfileView.swift` - kandidatvy
- `HotAndColdFriends/Features/Onboarding/OnboardingFavoritesView.swift` - kandidatvy
- `.planning/v2.0-MILESTONE-AUDIT.md` - audit som identifierar gapet
- `.planning/REQUIREMENTS.md` - COMP-02 kravdefinition

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all components exist in codebase
- Architecture: HIGH - straightforward component substitution
- Pitfalls: HIGH - identified from actual code review (loading state, reduce motion, full-width)

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable -- internal codebase, no external dependencies)
