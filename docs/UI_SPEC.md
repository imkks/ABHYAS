# ABHYAS: UI LAYOUT SPEC FOR AGENT (companion to the SRS)

> Give this to the agent together with `Abhyas_SRS_Agent_Prompt.md`. The SRS defines behavior and safety; this document defines screens, layout, components and states. Requirement IDs (FR-xx, SR-xx) refer to the SRS.

---

## 0. AGENT RULES FOR UI WORK

1. Build the **design tokens and shared components first (section 2 and 3)**, then screens. No screen may hard-code colors, spacing or text styles.
2. Every screen must implement **all listed states**: loading, empty, error, offline, and locked (where relevant).
3. **Tone:** calm, minimal, traditional. No confetti, popups for rewards, streak-loss warnings, red alerts for missed days, or urgency copy. Rewards appear quietly (a bead fills, a seal is added).
4. **Safety UI is never hidden, collapsed or dismissible-forever**: the "Return to natural breath" control, the rules checklist and the lock reasons.
5. Text comes from a localization file; never inline strings. Sanskrit/Devanagari content comes only from the content manifest.
6. Build mobile-first (360-430 dp wide, portrait). Tablet is a stretched layout, not a redesign. The teacher console is desktop web (1280+ px, responsive down to 1024).
7. Create a **widget/component gallery screen** (dev only) that shows every component in every state, for teacher review.

---

## 1. NAVIGATION MAP

### 1.1 Student app

```
Splash
 └─ Onboarding flow (first run only)
     ├─ O1 Welcome + language
     ├─ O2 Consent and privacy
     ├─ O3 Health screening
     ├─ O4 Tradition and location
     ├─ O5 Teacher code
     └─ O6 Matra calibration + Comfort Hold Test
 └─ Main shell (bottom navigation, 5 tabs)
     ├─ Tab 1  AAJ (Today)
     ├─ Tab 2  ABHYAS (Practice)
     ├─ Tab 3  SOPANA (Path)
     ├─ Tab 4  PUSTAKALAYA (Library)
     └─ Tab 5  MERA (Me)
```

Bottom nav labels: **Aaj, Abhyas, Sopana, Pustakalaya, Mera** (each with a small English subtitle in the selected state: Today, Practice, Path, Library, Me).

### 1.2 Routes

```
/onboarding/{welcome|consent|health|tradition|teacher|calibration}
/today
/practice
/practice/:practiceId/preflight
/practice/:practiceId/play
/practice/session/:sessionId/checkin
/practice/cycle/:variant            (10|20|30|45 min composer)
/mala
/nidra/:duration
/path
/path/level/:levelId
/path/level/:levelId/request
/library
/library/mantra/:id
/library/lesson/:id
/library/mudra/:id
/me
/me/progress
/me/health
/me/weaning
/me/settings
/me/teacher
```

### 1.3 Teacher/Admin console (web)

```
Sidebar:  Students | Requests | Config | Content | Reports | Change log | (Admin) Teachers & Cohorts
```

---

## 2. DESIGN TOKENS

Provide as a single theme file (Flutter `ThemeData` extension) with light and dark variants. Dark theme is auto-suggested for evening and is the default for Yoga Nidra.

### 2.1 Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | #FBF6EC (warm cream) | #14121F (deep indigo-black) | App background |
| `surface` | #FFFFFF | #1E1B2E | Cards |
| `surfaceAlt` | #F3EAD6 | #27233B | Secondary cards |
| `ink` | #2B2118 | #F1EBDD | Primary text |
| `inkSoft` | #6B5B4B | #B9B0A0 | Secondary text |
| `saffron` | #D9822B | #E89A47 | Primary accent, mala, active tab |
| `saffronSoft` | #F6DDBA | #4A3320 | Accent backgrounds |
| `leaf` | #5E7F5A | #86A882 | Positive/complete (calm green) |
| `sky` | #4B6F8C | #7FA3C0 | Inhale phase |
| `clay` | #B5543B | #D77E66 | Safety/attention (muted, never alarm red) |
| `hold` | #7A5C99 | #A68BC4 | Kumbhaka (retention) phase |
| `line` | #E5D8BF | #34304A | Dividers |

Phase colors in the pacer: **Puraka = sky, Antar kumbhaka = hold, Rechaka = saffron, Bahya kumbhaka = clay (soft)**. Never rely on color alone: each phase also has a text label and a distinct shape cue (section 4.1).

### 2.2 Typography

- Latin: a humanist sans (e.g., Noto Sans / Inter).
- Devanagari and Sanskrit: **Noto Serif Devanagari** (or Tiro Devanagari Hindi), minimum 20 sp for mantras.
- Scale: Display 32, Title 22, Heading 18, Body 16, Caption 13, Mantra 24-28 (user-adjustable), Counter 72-96 (tabular figures, thin weight).
- Text scales with system font size up to 200%.

### 2.3 Spacing, shape, motion

- 4 dp grid; spacing tokens 4/8/12/16/24/32.
- Radius: card 20, button 28 (pill), chip 12.
- Elevation: flat with 1 px `line` borders; soft shadow only on floating elements.
- Motion: slow and gentle, 300-500 ms ease-in-out; pacer animation is exactly synchronized to the engine clock. Honor "reduce motion" (replace animation with a stepped bar and text countdown).
- Touch targets ≥ 48 dp; the stop control ≥ 64 dp.

### 2.4 Iconography and ornament

- Line icons, 2 dp stroke. Subtle traditional ornament allowed: a faint lotus or mandala watermark on empty states and the splash only, never behind text. Om symbol only in approved places (Sankalp and Om chanting screens).

---

## 3. SHARED COMPONENT LIBRARY

Build each as a reusable widget with variants and a gallery entry.

| Component | Variants / states |
|---|---|
| `PrimaryButton` / `SecondaryButton` / `TextButton` | enabled, pressed, disabled, loading |
| `StopButton` ("Return to natural breath") | always-visible, large; pressed feedback within 200 ms |
| `Card` | default, locked (shows lock + reason), completed |
| `LockBadge` | teacher-gated, guru-only, safety-blocked (with reason text) |
| `PhasePill` | puraka, antar kumbhaka, rechaka, bahya kumbhaka |
| `BreathPacer` | circle mode, bar mode (reduce motion), minimal mode (stage 3) |
| `BigCounter` | seconds held, seconds remaining, strokes |
| `RoundIndicator` | dots or beads for rounds/total |
| `MalaBead` / `MalaRing` | 108-bead ring, linear mini mala, bead fill states |
| `SopanaStep` | locked, current, completed, awaiting-teacher |
| `SealBadge` | mudra/bandha seals: unearned, earned |
| `MantraCard` | Devanagari, transliteration, meaning (collapsible), audio button, language switch |
| `MuhurtaCard` | upcoming, active, passed |
| `ChecklistItem` | unchecked/checked (rules acknowledgment) |
| `CheckinChips` | calm, neutral, agitated, strained + dizziness toggle |
| `InfoSheet` | bottom sheet for explanations |
| `EmptyState` | illustration + one line + one action |
| `OfflineBanner` | slim, non-blocking |
| `ConfigField` (console) | number, ratio tuple, enum, toggle, with help text and validation message |
| `AuditRow` (console) | who, when, what, why |

---

## 4. KEY SCREEN WIREFRAMES (STUDENT APP)

ASCII wireframes show structure and hierarchy, not final visuals.

### 4.1 Practice Player (the most critical screen) `/practice/:id/play`

Full-screen, no bottom nav, keep-screen-awake while visible (optional dim after 20 s), works with screen off via audio + haptics.

```
┌────────────────────────────────────┐
│ ✕ (confirm)      Nadi Shodhana  ⋮  │  ← top bar: exit (with confirm), title, options
│ Round 3 / 10          Level 3 · 1:2:2│  ← RoundIndicator + current ratio
│                                    │
│            ┌──────────┐            │
│          ╱              ╲          │
│         │    BREATH     │          │  ← BreathPacer (circle expands/contracts)
│         │     PACER     │          │
│          ╲              ╱          │
│            └──────────┘            │
│                                    │
│        ◉ ANTAR KUMBHAKA            │  ← PhasePill (text + shape + color)
│           Hold in                  │
│                                    │
│               08                   │  ← BigCounter (seconds held)
│           of 8 sec max             │  ← cap shown calmly
│                                    │
│  Nostril: ◐ Left in   Mudra: Nasika│  ← technique cue strip (config-driven)
│  Bandha: Jalandhara ▢▢▣            │
│                                    │
│  ┌────────────────────────────────┐│
│  │   RETURN TO NATURAL BREATH     ││  ← StopButton, always visible, ≥64 dp
│  └────────────────────────────────┘│
│  🔊 Voice   📳 Haptic   ⏸ Pause    │  ← quick toggles per weaning stage
└────────────────────────────────────┘
```

Behavior and states:
- **Phase shapes:** puraka = circle growing, antar kumbhaka = circle steady with a ring, rechaka = circle shrinking, bahya kumbhaka = small circle steady with a dashed ring.
- **Weaning stage drives visibility:** Stage 1 all elements; Stage 2 voice at phase changes; Stage 3 hides pacer, keeps a minimal ring + haptic per round; Stage 4 shows only a blank calm screen with elapsed time hidden, start/end bell; Stage 5 optional self-check controls (section 4.9). `StopButton` is visible in every stage.
- **Kapalbhati variant:** replace the circle with a stroke pulse (soft pulse per stroke), `BigCounter` = strokes in this round, a round-break screen with "Breathe naturally" and a gentle timer.
- **Bhramari / Ujjayi / Sheetali variants:** same pacer; add a short technique cue line (e.g. "Hum softly", "Soft throat sound") from content.
- **Interruption (call, app backgrounded):** auto-pause to natural-breath state with a calm message; resume only by user tap (re-start the current round).
- **Hold-cap reached:** the counter turns calm, the engine cues exhale automatically; no "failure" language.
- **Error:** if audio fails, show a small inline notice; the pacer and haptics continue.

### 4.2 Pre-flight screen `/practice/:id/preflight`

```
┌────────────────────────────────────┐
│ ←                Nadi Shodhana     │
│ Level 3 · 1:2:2 · 4 sec unit       │
│ ~10 min · 10 rounds                │
│                                    │
│ Before you begin                   │
│ ☐ Empty stomach (3-4 hours)        │
│ ☐ Seated, spine upright            │
│ ☐ Quiet, clean place               │
│ ☐ I will never force my breath     │
│                                    │
│ Mudra: Nasika     [see how ▸]      │
│ Bandha: Jalandhara [see how ▸]     │
│                                    │
│ Guidance: Stage 2 · Cued   [change]│
│                                    │
│ [        Begin practice         ]  │  ← disabled until all boxes checked
└────────────────────────────────────┘
```

States: **blocked** (safety/teacher lock) shows a `LockBadge` card in place of the checklist with the reason and "Talk to your teacher" action; `Begin` is absent.

### 4.3 Post-session check-in `/practice/session/:id/checkin`

```
┌────────────────────────────────────┐
│ Session complete                   │
│ 10 min · 10 rounds                 │
│ (a mala bead fills quietly)        │
│                                    │
│ How do you feel?                   │
│ [Calm] [Neutral] [Agitated] [Strained]
│                                    │
│ ☐ I felt dizzy or lightheaded      │
│                                    │
│ Add a note (optional)  [text/voice]│
│                                    │
│ [            Save                ] │
└────────────────────────────────────┘
```

If "Strained" or dizziness is selected, show a calm, supportive sheet: "We'll go gently next time. Your teacher has been informed." (SR-08, FR-GM-09). Do not show scores.

### 4.4 Aaj (Today) `/today`

```
┌────────────────────────────────────┐
│ Namaste, <name>           ⚙ (Mera) │
│ Sunday · Ekadashi (Phase 3)        │
│                                    │
│ ┌ MuhurtaCard ─────────────────────┐
│ │ Brahma muhurta   4:52 – 5:40 AM  │
│ │ Sunrise 6:28 AM · London         │
│ │ [Remind me]                      │
│ └──────────────────────────────────┘
│ ┌ Sankalp ─────────────────────────┐
│ │ "Today my intention is…" [edit]  │
│ └──────────────────────────────────┘
│ ┌ Today's practice ────────────────┐
│ │ Full cycle · 30 min              │
│ │ Kapalbhati → Nadi Shodhana → …   │
│ │ [Begin]  [10 | 20 | 30 | 45]     │
│ └──────────────────────────────────┘
│ ┌ Mala ────────────────────────────┐
│ │ ◯◯◯◯◯◯◉◉◉ 41 of 108 beads        │
│ └──────────────────────────────────┘
│ ┌ Evening ─────────────────────────┐
│ │ Yoga Nidra · 30 min      [Play]  │
│ └──────────────────────────────────┘
│ Aaj  Abhyas  Sopana  Pustak.  Mera │
└────────────────────────────────────┘
```

States: empty (first day: a single "Begin your first practice" card), offline banner, rest day (Vishrama: calm message "Rest is part of practice", no negative language).

### 4.5 Abhyas (Practice) `/practice`

```
┌────────────────────────────────────┐
│ Abhyas                             │
│ [Daily cycle] [Pranayama] [Dhyan]  │  ← segmented control
│                                    │
│ Pranayama                          │
│ ┌ Kapalbhati        Level 2  ▸ ┐   │
│ ┌ Nadi Shodhana     Level 1  ▸ ┐   │
│ ┌ Ujjayi            Level 2  ▸ ┐   │
│ ┌ Bhramari          Level 1  ▸ ┐   │
│ ┌ Sheetali  🔒 Teacher approval  ┐   │
│ ┌ Bhastrika 🔒 Not available (health)┐│
│                                    │
│ Dhyan                              │
│ ┌ Breath awareness ┐ ┌ Naam jap ┐  │
│ ┌ Yoga Nidra ┐                     │
│ Bandha & Mudra (learn)             │
└────────────────────────────────────┘
```

Locked cards show lock type and a one-line reason; tapping opens an `InfoSheet` with "Why is this locked?" and the actions "Ask my teacher" (sends an unlock request where allowed) or "Learn about this" (info-only).

### 4.5.1 Daily Cycle Composer `/practice/cycle/:variant`

Vertical timeline of the day's sequence (section 5.2 of the SRS): each step is a card with duration and a reorder-disabled lock (the order is traditional; users can only skip optional steps). Top: variant tabs 10/20/30/45. Bottom: `Begin cycle`, and transitions between steps use a gentle interstitial (5 s "Settle", skippable).

### 4.6 Sopana (Path) `/path`

A vertical, winding path (like a mountain trail) with seven stations:

```
┌────────────────────────────────────┐
│ Your Path                          │
│                                    │
│        ⑦ Dhyana    🔒 Guru only    │
│         ╲                          │
│     ⑥ Bahya        🔒 Teacher      │
│       ╱                            │
│     ⑤ Kumbhaka     🔒 Teacher      │
│         ╲                          │
│      ④ Shakti      🔒 Teacher      │
│        ╱                           │
│     ③ Antar        ◉ Current       │
│         ╲           ratio 1:1:2    │
│       ② Abhyasa    ✓ Complete      │
│        ╱                           │
│     ① Prarambha    ✓ Complete      │
└────────────────────────────────────┘
```

Each `SopanaStep` shows state: locked, current, completed, awaiting-teacher (after a request). Tap opens level detail.

**Level detail `/path/level/:id`:** description, practices unlocked, ratio ladder shown as steps with the user's current step highlighted (never a "faster is better" display), mudras/bandhas as seals, Pariksha checklist (items ticked as satisfied), gate info ("Requires your teacher's approval"), and the primary action:
- `self`/`streak` gate satisfied → "Begin this level".
- `teacher` gate → "Request Guru Anumati" (opens `/request`).
- `guru_only` → "Learn about this level" only.

**Unlock request `/path/level/:id/request`:** summary of your recent sessions (read-only), CHT history, an optional note to the teacher, a consent line ("Share my practice data with my teacher"), and `Send request`. After sending: status chip "Awaiting teacher".

### 4.7 Mala `/mala`

```
┌────────────────────────────────────┐
│ ✕           Naam Jap               │
│ Mantra: Om Namah Shivaya   [change]│
│ Mode: [Aloud][Whisper][Mental]     │
│                                    │
│        ◯◯◯◯◯◯◯◯◯◯◯◯◯               │
│      ◯◯               ◯◯           │  ← 108-bead ring, current bead glows
│     ◯◯     ॐ  42 / 108   ◯◯        │
│      ◯◯               ◯◯           │
│        ◯◯◯◯◯◯◯◯◯◯◯◯◯               │
│                                    │
│   (tap anywhere or swipe to advance)│
│                                    │
│   Rounds completed: 2              │
│   [ End ]                          │
└────────────────────────────────────┘
```

Haptic on each bead; a distinct slower haptic at the 108th (meru/sumeru), then a quiet prompt: "Turn back, do not cross the meru" (content-managed; placeholder until teachers approve text). Left-handed and one-handed layouts supported via settings.

### 4.8 Yoga Nidra `/nidra/:duration`

Dark theme forced. Minimal UI: title, a slow-breathing gradient background, a progress line (no numbers by default), play/pause, a sleep timer, volume. Sankalp is shown at the start and end. The screen dims automatically.

### 4.9 Weaning and self-check `/me/weaning`

```
┌────────────────────────────────────┐
│ Practicing without the app         │
│ Stage 3 of 5 · Silent timer        │
│ ●━━━━●━━━━◉━━━━○━━━━○              │
│ Guided · Cued · Silent · Self-led · Independent
│                                    │
│ You've completed 7 of 10 sessions  │
│ needed for the next stage.         │
│                                    │
│ Counting method lesson  [open ▸]   │
│ Self-check practice    [start ▸]   │
│ Return to an earlier stage [change]│
└────────────────────────────────────┘
```

**Self-check practice:** the user sees only `Start round` / `End round`; they time their own hold or exhale with no guidance, then see a calm comparison ("Your 12 s hold: aim was 12 s"), a steadiness trend over time, never a ranking.

### 4.10 Pustakalaya (Library) `/library`

Segmented: **Mantras | Lessons | Mudras & Bandhas | Rituals**. `MantraCard` list filtered by the user's tradition. Mantra detail: large Devanagari, transliteration, meaning (collapsible), play audio with line-by-line highlight, language toggle. Mudra/bandha detail: video/animation, purpose, common mistakes, level where it's introduced, teacher notes, and "Khechari: information only" displays with no practice action.

### 4.11 Mera (Me)

```
┌────────────────────────────────────┐
│ Mera                               │
│ <name> · Level 3 · Stage 3         │
│ ┌ Progress           ▸ ┐           │
│ ┌ My teacher: <name> ▸ ┐           │
│ ┌ Health & safety    ▸ ┐           │
│ ┌ Practice ritual    ▸ ┐           │
│ ┌ Reminders          ▸ ┐           │
│ ┌ Language & tradition▸ ┐           │
│ ┌ Privacy & data     ▸ ┐           │
│ ┌ Help & disclaimer  ▸ ┐           │
└────────────────────────────────────┘
```

- **Progress:** calendar of practice days (filled = practiced, soft outline = Vishrama, empty = nothing, no red marks), mala count, seals earned, CHT history chart (informational), gentle weekly reflection.
- **Health & safety:** edit screening; changes re-evaluate locks immediately and notify the teacher if retention practices are affected.
- **Privacy & data:** consent management, export, delete account.

### 4.12 Onboarding screens

- **O1 Welcome:** lotus watermark, one sentence on purpose, language picker.
- **O2 Consent:** plain-language summary, "Pilot participant" checkbox, separate checkbox for sharing data with my teacher, "not medical advice" text.
- **O3 Health screening:** one question per card, Yes/No/Prefer not to say, a progress dot row; "Prefer not to say" is treated as flagged (safe default). Ends with a summary: "Practices adjusted for you" listing what is hidden/locked and why.
- **O4 Tradition and location:** sampradaya chips, ishta devata optional, location via permission or manual city search, time zone auto-detected.
- **O5 Teacher code:** 6-character code entry; "Skip for now" allowed but advanced levels remain locked.
- **O6 Calibration:** (a) Matra: tap along to a metronome to calibrate base unit; (b) CHT: instruction card, a large single "Start" and "I need to breathe" button, time shown after; a result card explaining the safe training fraction. Always allow skip, which defaults to the conservative cap.

---

## 5. TEACHER / ADMIN CONSOLE LAYOUT (WEB)

Layout: left sidebar (240 px), top bar (search, teacher name, notifications), content area (max 1200 px). Same tokens as the app but in a denser variant.

### 5.1 Students list `/students`

Table columns: Name, Level, Ratio step, Weaning stage, Last practice, Flags (strain, pending request), Actions. Filters: flagged, inactive 7+ days, pending request. Row click → detail.

### 5.2 Student detail `/students/:id`

```
┌ Header: name · tradition · level · stage · health flags (chips) ──────────┐
│ [Overview] [Sessions] [Check-ins] [Requests] [Notes]                      │
├───────────────────────────────┬───────────────────────────────────────────┤
│ Overview                      │ Quick actions                             │
│ • Current ratio step          │ [Adjust ratio step] [Change level]        │
│ • CHT history (small chart)   │ [Restrict practice] [Send message]        │
│ • Strain events (list)        │ [Clear practice for health flag]          │
│ • Sessions this week          │                                           │
└───────────────────────────────┴───────────────────────────────────────────┘
```

Session list expands to per-round detail (ratio used, hold seconds, caps applied, check-in). Every manual adjustment requires a "reason" field and writes to the audit log.

### 5.3 Unlock requests `/requests`

Queue of pending requests. Detail pane: student summary, last 10 sessions, CHT, flags, their note, level gate requirements with satisfied/unsatisfied ticks. Actions: **Approve**, **Approve with conditions** (cap, probation sessions), **Deny with note**, **Ask for a live/video check**. 

### 5.4 Config editor `/config`

```
┌ Left: tree (Global | Levels 1-7 | Weaning | Sequences | Safety rules) ─────┐
│ Right: form for the selected node                                          │
│   Ratio ladder  [1:0:1:0] [1:0:2:0] [+ step]                               │
│   Base count (sec) [4]                                                     │
│   Hold cap fraction of CHT [0.6]                                           │
│   Help text per field                                                      │
│   Validation panel (live)  ✓ Bahya ≤ antar   ✓ Caps present               │
│ [Save draft] [Preview as student] [Publish…] [Version history ▸ Rollback]  │
└────────────────────────────────────────────────────────────────────────────┘
```

Publishing requires a change note; the safety-invariant validator blocks publish with a clear error. "Preview as student" runs the player with the draft config in a sandbox.

### 5.5 Content manager `/content`

Table of content items with status chips (placeholder, draft, teacher_approved), filters by type/language/tradition, detail editor with preview (Devanagari render, audio player), and a reviewer sign-off button.

### 5.6 Reports and Change log

- **Reports:** weekly cohort view (practice days, completion, strain rate, auto-regressions, progression per level), CSV export.
- **Change log:** filterable timeline of config changes, approvals, safety overrides (who, when, what, why).

### 5.7 Admin only

Teachers and cohorts management, invite codes, content permissions, data export/delete requests queue.

---

## 6. CROSS-CUTTING UI BEHAVIOR

| Topic | Requirement |
|---|---|
| **Locked states** | Three distinct lock types (teacher-gated, guru-only, safety-blocked) with different icons and copy; every lock explains why and offers a next step |
| **Offline** | Slim `OfflineBanner`; all practice flows work; sync status shown in Mera |
| **Empty states** | Every list has an `EmptyState` with one gentle action |
| **Errors** | Plain language, no codes shown to students; retry option |
| **Notifications** | Local reminders (Brahma muhurta, Sandhya, evening Nidra); teacher messages and approvals arrive as in-app inbox items plus optional push |
| **Haptics** | Distinct patterns: phase change (light), round complete (medium), mala bead (tick), meru (long soft), safety stop (single firm) |
| **Audio** | Separate volume sliders for voice, tones, music; a "silent practice" preset |
| **Accessibility** | Screen-reader labels on all controls including pacer phases ("Hold in, 8 of 8 seconds"), keyboard navigation in console, color-independent cues, reduce motion, font scaling, high contrast mode |
| **Localization** | All strings externalized; Devanagari rendering tested; layouts tolerate 30% longer text |
| **Dark mode** | Full support; auto-suggest after sunset |

---

## 7. SUGGESTED FLUTTER STRUCTURE (agent may adjust, document in ARCHITECTURE.md)

```
/app/lib
  /core        theme (tokens), l10n, routing, haptics, audio, clock
  /engine      player_engine (pure Dart), safety_rules, config_models
  /features
    /onboarding
    /today
    /practice   (list, preflight, player, checkin, cycle_composer)
    /dhyan      (mala, nidra)
    /path       (path_map, level_detail, unlock_request)
    /library
    /me         (progress, health, weaning, settings)
  /widgets     shared components from section 3
  /data        repositories, local db (offline), sync
/console       web app mirroring the tokens
```

The UI layer **only renders state from the engine**; it never computes holds, caps or locks itself.

---

## 8. BUILD ORDER FOR THIS UI

1. Tokens, theme (light/dark), typography, component library and gallery screen.
2. Main shell, navigation, routes, and stub screens for every route.
3. **Practice player + preflight + check-in** against the engine (the core experience).
4. Onboarding flow, including health screening and CHT.
5. Today, Practice list, Path and level detail with lock states.
6. Mala, Yoga Nidra, Library, Me and weaning screens.
7. Teacher console: students, requests, config editor, content, change log.
8. Accessibility, localization and reduce-motion pass; component gallery review with teachers.

**Definition of done for each screen:** matches the wireframe hierarchy, implements all states, uses only tokens and shared components, passes screen-reader and large-text checks, and has widget tests for each state.
