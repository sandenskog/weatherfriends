# Phase 1: Foundation - Context

**Gathered:** 2026-03-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Användare kan skapa konto, logga in och ange sin plats — den autentiserade och platsbekräftade användaren som allt annat bygger på. Stödjer Sign in with Apple, Google Sign-In och Facebook Login. Inkluderar profilskapande med namn, profilbild och stad/land, samt möjligheten att se andra användares profiler.

</domain>

<decisions>
## Implementation Decisions

### Login-skärmen
- Kort splash med appnamn/logga och tagline, sedan login-knappar nedanför
- Mjuk gradient (vitt till ljusblått) som antyder vädertema
- Tre login-knappar staplade vertikalt: Apple först, sedan Google, sedan Facebook
- Alla knappar lika framträdande (Apple HIG-krav)

### Onboarding-flöde
- Stegvis wizard med separata skärmar: 1) Namn, 2) Profilbild, 3) Stad/land
- Profilbild är valfri — en generisk avatar/initial visas som default
- Namn och stad/land krävs för att slutföra onboarding

### Profilvisning
- Andras profiler visas som halvmodal (sheet) som glider upp från botten
- Minimal info i Fas 1: rund profilbild + namn + stad/land
- Edit-knapp visas på egen profil för att redigera
- Profilbilder visas som runda cirklar genomgående i appen

### Platsinmatning
- Sökfält med autocomplete (börja skriva → få förslag)
- Specificitetnivå: stad + land (t.ex. "Stockholm, Sverige")
- GPS som hjälp: be om platstillstånd, förifyll förslaget, användaren bekräftar
- Plats kan ändras fritt via profilredigering utan bekräftelsedialog

### Claude's Discretion
- Tagline-text på login-skärmen
- Fotoval-metod för profilbild (kamerarulle och/eller kamera)
- Progress-indikator-stil i onboarding-wizarden
- Felhantering vid misslyckad login
- Default-avatar/initial-design

</decisions>

<specifics>
## Specific Ideas

- Appen heter "Hot & Cold Friends" — tagline bör matcha den sociala vädertonen
- Ljus, minimalistisk design genomgående — undvik mörka bakgrunder
- Mjuk gradient på login ger en väderkänsla utan att vara övertydlig

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- Inga — projektet är helt nytt, ingen befintlig kod

### Established Patterns
- Inga mönster etablerade ännu — Fas 1 sätter standarden

### Integration Points
- Firebase Auth som backend för alla tre login-providers
- Firestore för användar- och profildata
- Apple MapKit/CLGeocoder eller liknande för plats-autocomplete

</code_context>

<deferred>
## Deferred Ideas

Ingen — diskussionen höll sig inom fasens scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-02*
