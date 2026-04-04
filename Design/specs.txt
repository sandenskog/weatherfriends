# Design Assets Specification — Hot & Cold Friends

**Syfte:** Detta dokument beskriver alla design assets som behövs för att göra appen visuellt komplett och redo för App Store-lansering. Skicka detta till designern.

**App-koncept:** En iOS-app som visar vädret hos dina vänner, sorterat efter temperatur. Vädret blir en naturlig samtalsöppnare. Varm, social känsla — inte kall/teknisk.

---

## 1. App-ikon (KRITISK — krävs för TestFlight)

**Format:** 1024x1024 px, PNG, utan alfakanal, utan rundade hörn (iOS lägger till automatiskt)

**Koncept-riktning:**
- Ska kommunicera "väder + vänskap" i en enda bild
- Varm, inbjudande känsla — inte en generisk väderikon
- Temperaturgradienten (blått → grönt → orange → rött) är appens visuella signum
- Undvik: generiska molnikoner, termometrar, jordglober

**Idéer att utforska:**
- Stiliserade ansikten/silhuetter med väderelement
- Temperaturgradienten som bakgrund med en social symbol
- En "varm" och en "kall" figur som interagerar

**Leverans:** En fil, `AppIcon.png`, 1024x1024 px

---

## 2. Färgpalett

Appen använder idag en temperaturbaserad färgskala som behöver förfinas till en komplett designpalett.

### Nuvarande temperaturfärger (att förfina)
| Temperatur | Nuvarande RGB | Syfte |
|------------|---------------|-------|
| < 0°C (Arctic) | (0.2, 0.4, 1.0) — isblå | Kalla vänner |
| 0–10°C (Cold) | (0.4, 0.6, 0.9) — kylig blå | Svala vänner |
| 10–20°C (Cool) | (0.5, 0.7, 0.5) — neutral grön | Lagom vänner |
| 20–28°C (Warm) | (1.0, 0.6, 0.2) — varm orange | Varma vänner |
| > 28°C (Tropical) | (0.9, 0.2, 0.2) — het röd | Heta vänner |

### Behöver definieras
| Element | Beskrivning | Nuvarande |
|---------|-------------|-----------|
| **Primary** | Huvudfärg för knappar, accent | Svart (#000) |
| **Secondary** | Sekundär interaktionsfärg | System gray |
| **Background** | Appens bakgrund | Vit/systemBackground |
| **Surface** | Kort-bakgrunder, modaler | systemGroupedBackground |
| **Chat bubble (egen)** | Användarens egna chattbubblor | Systemblå |
| **Chat bubble (andra)** | Andras chattbubblor | systemGray5 |
| **Favorit-markering** | Stjärna/hjärta för favoriter | Orange/gul |
| **Success** | Bekräftelser, framgång | Grön |
| **Warning** | Varningar | Orange |
| **Error/Danger** | Fel, destruktiva åtgärder | Röd |

**Leverans:** Färgpalett med HEX-koder, namn, och användningsområde. Gärna i Figma eller som en färgguide-PDF.

---

## 3. Typografi

Appen använder idag **SF Pro** (iOS-standard) utan egna fonts.

**Beslut att ta:**
- Ska vi ha en custom font för rubriker/logotyp? (t.ex. display font med personlighet)
- Eller behålla SF Pro genomgående? (renare, mer iOS-nativt)

**Om custom font väljs, behöver vi:**
| Användning | Nuvarande | Storlek |
|------------|-----------|---------|
| App-namn/logotyp | SF Pro Bold | Display |
| Rubriker (H1) | .largeTitle | 34pt |
| Underrubriker (H2) | .title2 semibold | 22pt |
| Underrubriker (H3) | .title3 | 20pt |
| Brödtext | .body | 17pt |
| Knappar | .body medium | 17pt |
| Bildtext | .caption | 12pt |
| Temperaturvisning | .body bold | 17pt |

**Leverans:** Font-filer (OTF/TTF), licensiering klarlagd för iOS-app

---

## 4. Väderillustrationer / Ikoner

### 4a. Nuvarande väderikoner (WeatherKit SF Symbols)
Appen använder idag **SF Symbols med multicolor-rendering** från WeatherKit. Dessa fungerar men är generiska.

**Alternativ att överväga:**
1. **Behåll SF Symbols** — gratis, konsekvent, snabbt. Fokusera designinsatsen på annat.
2. **Custom väderikoner** — unik identitet, men kräver 15–20 ikoner:

| Ikon | SF Symbol idag | Beskrivning |
|------|---------------|-------------|
| Klart (dag) | `sun.max.fill` | Sol |
| Klart (natt) | `moon.stars.fill` | Måne med stjärnor |
| Delvis molnigt (dag) | `cloud.sun.fill` | Sol bakom moln |
| Delvis molnigt (natt) | `cloud.moon.fill` | Måne bakom moln |
| Molnigt | `cloud.fill` | Moln |
| Regn | `cloud.rain.fill` | Regn |
| Kraftigt regn | `cloud.heavyrain.fill` | Skyfall |
| Snö | `cloud.snow.fill` | Snöfall |
| Åska | `cloud.bolt.fill` | Blixtar |
| Dimma | `cloud.fog.fill` | Dimma |
| Vind | `wind` | Vindbyar |
| Hagel | `cloud.hail.fill` | Hagel |
| Duggregn | `cloud.drizzle.fill` | Lätt regn |
| Snöblandat regn | `cloud.sleet.fill` | Blandat |

**Leverans (om custom):** SVG + PDF (för Xcode asset catalog), varje ikon i minst 2 varianter (dag/natt)

### 4b. Väderanimationer (bakgrund)
Appen har idag **kodade animationer** i SwiftUI:

| Animation | Nuvarande implementation | Förfining? |
|-----------|--------------------------|------------|
| **Sol** | Pulserande cirkel, 2 lager | Kan bli snyggare med Lottie-animation |
| **Moln** | Canvas-baserad drift | Funkar bra |
| **Regn** | 18 fallande partiklar | Kan bli mer realistiskt |
| **Snö** | 18 driftande cirklar | Kan bli mer realistiskt |
| **Åska** | Dubbla blixtflashar | Funkar bra |

**Alternativ:**
1. **Behåll kodade animationer** — lätta, snabba, redan implementerade
2. **Lottie-animationer** — snyggare, men kräver After Effects-arbete

**Om Lottie väljs:** Leverans som `.json`-filer, varje animation max 5s loop, transparent bakgrund

---

## 5. Interaktionsanimationer

Animationer som gör appen "levande" vid användarinteraktion:

| Interaktion | Nuvarande | Önskat beteende |
|-------------|-----------|-----------------|
| **Favoritmarkering** | Ingen animation | Hjärta/stjärna som "poppar" med fjädereffekt |
| **Pull-to-refresh** | Standard iOS | Custom animation med vädertema? |
| **Tab-byte** | Standard iOS | Mjuk övergång |
| **Väder-sticker skickad** | Ingen | Kort "bounce" eller "float in" |
| **Ny vän tillagd** | Ingen | Konfetti eller välkomst-animation |
| **Temperatursortering** | Standard list reorder | Smooth slide med färgövergång |
| **Kontaktimport (AI-gissning)** | Progress bar | Mer visuell feedback? |

**Leverans:** Beskrivning av timing, easing och visuellt beteende räcker — implementation görs i kod.

---

## 6. Onboarding-illustrationer

Appen har en 4-stegs onboarding som idag saknar illustrationer:

| Steg | Innehåll | Illustration behövs |
|------|----------|---------------------|
| 1. Namn | Skriv ditt namn | Välkomstbild / app-maskot |
| 2. Foto | Ladda upp profilbild | Kamera/foto-illustration |
| 3. Stad | Var bor du? | Karta/plats-illustration |
| 4. Favoriter | Importera vänner | Vänner/grupp-illustration |

**Stil:** Matcha appens ton — varm, social, inte corporate. Platta illustrationer eller mjuka 3D-ikoner.

**Leverans:** 4 illustrationer, minst 600x600 px, PNG med transparent bakgrund (eller SVG)

---

## 7. Widget-design

Tre widget-storlekar finns redan med grundläggande layout:

| Storlek | Innehåll | Designinsats |
|---------|----------|-------------|
| **Small** | 1 favorit + temperatur | Bakgrundsgradient, typografi |
| **Medium** | 3–4 favoriter i rad | Separator-styling, kompakt layout |
| **Large** | 2x3 grid av favoriter | Grid-spacing, visuell hierarki |

**Önskat:** Widgets ska kännas som "mini-konstverk", inte bara datalista. Temperaturgradienten i bakgrunden, profilbilder som fokuspunkt.

**Leverans:** Skisser/mockups för alla tre storlekar

---

## 8. Launch Screen

**Nuvarande:** Ingen custom launch screen konfigurerad (standard vit).

**Behövs:** En enkel launch screen med:
- App-logotyp centrerad
- Eventuell bakgrundsgradient (matcha app-ikonen)
- Ingen animation (iOS-begränsning för launch screens)

**Leverans:** Designskiss + logotyp som separat asset

---

## 9. Logotyp / Ordmärke

Appen heter **Hot & Cold Friends** (arbetsnamn, kan ändras).

**Behövs:**
- Horisontell logotyp (för headers, launch screen)
- Ikon-version (kan vara samma som app-ikonen)
- Eventuellt ett "& Cold" med temperatureffekt i texten?

**Leverans:** SVG + PNG i olika storlekar (1x, 2x, 3x för iOS)

---

## 10. Chat-assets

| Asset | Beskrivning | Nuvarande |
|-------|-------------|-----------|
| **Väder-stickers** | Väderkort att skicka i chatt | Kodgenererade med gradient + ikon |
| **Tom chatt-illustration** | "Ingen konversation ännu" | Saknas |
| **Tom vänlista** | "Lägg till din första vän" | Saknas |
| **Profilbild-placeholder** | Initialer i cirkel | Kodgenererad (text i grå cirkel) |

**Väder-stickers:** Idag kodgenererade kort med temperaturgradient, WeatherKit-ikon och temperaturtext. Kan bli snyggare med designade kort.

**Leverans:** Illustrationer för tomma tillstånd (minst 300x300 px). Sticker-design om vi vill uppgradera.

---

## 11. Sammanfattning — Prioritetsordning

### Måste ha (före TestFlight)
1. **App-ikon** (1024x1024) — krävs av Apple

### Bör ha (före App Store-lansering)
2. **Färgpalett** — förfinad temperaturskala + UI-färger
3. **Onboarding-illustrationer** (4 st)
4. **Launch screen** med logotyp
5. **Logotyp/ordmärke**
6. **Tomma tillstånd-illustrationer** (tom chatt, tom vänlista)

### Trevligt att ha (kan komma efter lansering)
7. **Custom väderikoner** (15–20 st)
8. **Lottie-animationer** för väder
9. **Interaktionsanimationer** (favoritmarkering, etc.)
10. **Widget-design** (förfinad)
11. **Custom font**
12. **Designade väder-stickers**

---

## 12. Tekniska krav

| Krav | Detalj |
|------|--------|
| **Filformat ikoner** | SVG (primärt) + PNG (export). PDF för Xcode asset catalogs |
| **Filformat illustrationer** | PNG med transparent bakgrund, minst 2x retina (600+ px) |
| **Filformat animationer** | Lottie JSON (om Lottie) eller beskrivning för kodimplementation |
| **Färger** | HEX + RGB, med Light/Dark mode-varianter om tillämpligt |
| **App-ikon** | 1024x1024 PNG, utan alfa, utan rundade hörn |
| **Tillgänglighet** | Tillräcklig kontrast (WCAG AA), ej enbart färgberoende |

---

*Skapat: 2026-03-04*
*Projekt: Hot & Cold Friends v1.0*
