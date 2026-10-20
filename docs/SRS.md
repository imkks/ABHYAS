# ABHYAS — SRS & BUILD PROMPT FOR AUTOMATED AGENT

> Paste this entire document to the agent as its task brief. Version 0.1 (closed-circle pilot).

---

## 0. YOUR ROLE AND OPERATING RULES

You are a senior full-stack/mobile engineer building **Abhyas**, a traditional Pranayama and Dhyan practice app for a **closed pilot** reviewed by experienced yoga teachers.

Operating rules:
1. **Do not ask clarifying questions.** Where this document is silent, choose the simplest reasonable option, record it in `/docs/ASSUMPTIONS.md`, and continue.
2. **Build in the phases defined in section 12.** Finish and test each phase before starting the next. At the end of each phase, output a short report: what was built, what was tested, what is open.
3. **All practice parameters are DRAFT HYPOTHESES.** Ratios, step sizes, caps, unlock rules, and mantra sets must live in **remote-editable configuration**, never hard-coded in app logic. Teachers will change them without a new app release.
4. **Safety requirements (section 7) override every other requirement**, including UX convenience and engagement.
5. **Never invent religious/spiritual content.** Mantras, invocations, instructions, and texts are supplied as content files (section 9). Where content is missing, create clearly marked placeholders (`[CONTENT PENDING – TEACHER REVIEW]`), never fabricate Sanskrit, translations, or doctrine.
6. Write clean, typed, tested, documented code. Commit in small, logical steps.

---

## 1. PRODUCT SUMMARY

**Purpose:** Teach a complete, traditional daily cycle of pranayama and dhyan to a beginner, and **gradually make the app unnecessary** so the user can practice independently.

**Audience:** Global Indian diaspora. Strictly traditional (Vedic/yogic) presentation. No secular toggle in this pilot.

**Pilot context:** Closed circle of students and teachers. Teachers review and shape the product iteratively.

**Core ideas:**
- Guided practice with a breath pacer, retention (kumbhaka) timer, and live counts.
- A **7-level traditional progression ("Sopanas")** presented as a calm, non-competitive game.
- **Teacher approval (Guru Anumati)** gates advanced levels.
- A **5-stage weaning ladder** that removes app guidance over time.
- A **Vedic ritual layer**: Brahma muhurta, Sandhya times, Panchang, sankalp, invocations.
- **Teacher console** with remote configuration, student visibility, and a change log.

**North-star metric:** % of users who reach independent practice (weaning stages 4–5) by week 12.

---

## 2. USERS AND ROLES

| Role | Capabilities |
|---|---|
| **Student** | Onboard, complete health screening, practice, view own progress, give feedback, request level unlock |
| **Teacher** | View assigned students, approve/deny unlocks, view session history and strain flags, message students, edit configuration within permission |
| **Admin** | Manage teachers, content, config versions, pilot cohorts, data export/deletion |

---

## 3. RECOMMENDED STACK (override only with written justification in ASSUMPTIONS.md)

- **Mobile:** Flutter (iOS + Android), offline-first. One codebase.
- **Teacher/Admin console:** Web app (React or Flutter Web).
- **Backend:** Supabase (Postgres + Auth + Storage + Row Level Security) or Firebase equivalent.
- **Remote config:** versioned JSON stored in DB, served via API, cached locally, with schema validation.
- **Audio:** pre-recorded guidance and bells; local playback; no runtime TTS.
- **Haptics:** platform haptic APIs.
- **Sunrise/sunset:** a tested astronomical library. **Tithi/nakshatra:** an ephemeris-based library or API (Swiss Ephemeris recommended). Panchang is Phase 3 and must be teacher-validated.
- **Notifications:** local scheduled notifications for practice reminders (must work offline).
- **Analytics:** privacy-minimal, first-party only. No third-party ad or tracking SDKs.

---

## 4. CORE CONCEPTS AND DEFINITIONS

- **Matra:** the base counting unit in seconds. Default 1 sec; user-adjustable (0.8–1.5) and calibrated during onboarding.
- **Ratio notation:** `puraka : antar kumbhaka : rechaka : bahya kumbhaka` (inhale : hold-in : exhale : hold-out). Example `1:4:2:0`. Concrete counts in seconds are `ratio × base_count × matra`.
- **Sopana:** a numbered level (1–7).
- **Pariksha:** a gate assessment required to complete a level.
- **Guru Anumati:** teacher approval needed to unlock gated levels.
- **Comfort Hold Test (CHT):** user-measured comfortable breath hold (after a normal exhale, no strain). **All training holds are capped at a configurable fraction (default 50–60%) of CHT.**
- **Vishrama:** a rest/grace day that does not break progress.
- **Weaning stage:** how much app guidance is active (section 6.4).

---

## 5. PRACTICE DOMAIN MODEL

### 5.1 Practices (all content configurable)

**Pranayama:** Kapalbhati, Nadi Shodhana (Anuloma Viloma), Ujjayi, Bhramari, Sheetali, Sheetkari, Bhastrika, Surya Bhedana. (Teacher-gated: antar kumbhaka, bahya kumbhaka.)

**Bandhas:** Jalandhara, Mula, Uddiyana, Maha Bandha (tri-bandha).

**Mudras:** Gyan, Chin, Dhyana, Nasika (Vishnu), Shanmukhi, Prana, Apana, Maha Mudra, Maha Bheda, Viparita Karani, Shambhavi. **Khechari is information-only; never a trainable exercise.**

**Dhyan:** Breath awareness (Anapana), Naam jap with 108-bead digital mala, Ajapa Japa, Trataka, Antar Mouna, Yoga Nidra (20/30/45 min).

**Preparatory ritual and closing:** Sankalp, achamana, invocation, Om chanting, shanti path.

### 5.2 Default daily cycle (30 min, configurable per level)

1. Sankalp and invocation (2)
2. Warm-up / loosening (2)
3. Om chanting ×3–5 (3)
4. Kapalbhati (3–4)
5. Nadi Shodhana (5)
6. Ujjayi (3)
7. Bhramari (2)
8. Naam jap or breath meditation (8–10)
9. Shanti path and close (2)

Also provide 10-, 20- and 45-minute variants. Yoga Nidra is a separate evening/bedtime session.

---

## 6. FUNCTIONAL REQUIREMENTS

Each requirement has an ID. Priority: **M** = must (pilot), **S** = should, **C** = could.

### 6.1 Onboarding and safety screening
- **FR-ON-01 (M)** Create account (email or phone + passwordless), with explicit **pilot consent** and privacy terms.
- **FR-ON-02 (M)** Health screening: pregnancy, hypertension, heart condition, epilepsy, glaucoma/eye pressure, hernia, ulcer, asthma/respiratory, panic/anxiety disorder, recent surgery, menstruation (for Kapalbhati and Uddiyana rules). Editable at any time.
- **FR-ON-03 (M)** Screening results produce a **safety profile** that **hides or locks** practices per rules in section 7. Locked practices show a clear reason and "talk to your teacher/doctor."
- **FR-ON-04 (M)** Select sampradaya/tradition (Smarta, Vaishnava, Shaiva, Shakta, Arya Samaj, Other), ishta devata (optional), preferred language, location (for time calculations), and time zone.
- **FR-ON-05 (M)** Assign student to a teacher (invite code).
- **FR-ON-06 (M)** Guided matra calibration and first **Comfort Hold Test** (with safety instruction and a prominent stop button).

### 6.2 Practice player
- **FR-PL-01 (M)** Visual breath pacer (expanding/contracting circle) for puraka, antar kumbhaka, rechaka and bahya kumbhaka phases, driven by the active ratio config.
- **FR-PL-02 (M)** Audio cues (voice + soft tones) and haptic pulses per phase change; both individually toggleable; works with screen off.
- **FR-PL-03 (M)** **Live retention timer** showing seconds held, round counter, and total elapsed.
- **FR-PL-04 (M)** **Hold cap enforcement:** the player must never schedule a hold above the user's cap (fraction of CHT, and level cap in config).
- **FR-PL-05 (M)** Always-visible **"Return to natural breath"** control that immediately ends retention and plays a calming cue.
- **FR-PL-06 (M)** Kapalbhati mode: stroke-rate pacing (configurable strokes/min), stroke counter, round breaks with natural breathing.
- **FR-PL-07 (M)** Bhramari, Ujjayi, Sheetali/Sheetkari modes with appropriate pacing and cue text.
- **FR-PL-08 (M)** Mudra and bandha cue overlays (image/animation + one-line instruction) at the points configured for the practice.
- **FR-PL-09 (M)** Pre-practice rules checklist shown each session (empty stomach, posture, quiet place) with acknowledgment.
- **FR-PL-10 (M)** **Post-session check-in:** one tap (calm / neutral / agitated / strained), optional dizziness flag, optional voice or text note.
- **FR-PL-11 (S)** Session composer: build the daily cycle from config; allow 10/20/30/45-minute variants.
- **FR-PL-12 (C)** Optional microphone-based breath detection (Phase 4, off by default, on-device only).

### 6.3 Dhyan features
- **FR-DH-01 (M)** Breath-awareness meditation with count mode (1–10) and silent "witness" mode, plus end bell.
- **FR-DH-02 (M)** **Digital mala (108 beads):** tap/swipe to advance, haptic on each bead, special haptic at the 108th (meru), aloud/whisper/mental mode labels, mantra selectable from the user's tradition set.
- **FR-DH-03 (M)** Yoga Nidra player with 20/30/45 min audio, sleep-friendly UI, optional auto-fade and sankalp reminder.
- **FR-DH-04 (S)** Trataka (on-screen candle flame with timer), Ajapa Japa, Antar Mouna as guided audio.

### 6.4 Weaning ladder (**FR-WN**)
- **FR-WN-01 (M)** Implement the 5 weaning stages, each a config profile of which guidance channels are active:

| Stage | Name | Visual pacer | Voice | Haptics | Counts display | Bell |
|---|---|---|---|---|---|---|
| 1 | Guided | On | Every cue | On | On | Start/end |
| 2 | Cued | On | Phase changes only | On | On | Start/end |
| 3 | Silent timer | Off | Off | Per-round pulse | Minimal | Start/end |
| 4 | Self-led | Off | Off | Off | Off | Start/end only |
| 5 | Independent | Off | Off | Off | Off | Optional self-check |

- **FR-WN-02 (M)** Stage advancement rules are configurable (default: minimum weeks and consecutive completed sessions at current stage). The student may always step back down.
- **FR-WN-03 (M)** **Self-check mode (Stage 5):** the user practices unaided and taps start/stop; the app compares their self-timed durations with the target and shows steadiness over time. This trains internal rhythm.
- **FR-WN-04 (M)** Teach a portable counting method (finger-segment counting, mental Om, heartbeat) as a lesson module.
- **FR-WN-05 (M)** Graduation event ("Swatantra") after N consecutive sessions in stages 4–5 (config).

### 6.5 Progression game: Seven Sopanas (**FR-GM**)
- **FR-GM-01 (M)** Implement levels 1–7 loaded from the level config (section 8). Each level defines: unlocked practices, ratio ladder, step size, caps, required mudras/bandhas, Pariksha criteria, and gate type (`self`, `streak`, `teacher`, `guru_only`).
- **FR-GM-02 (M)** **Mala progress:** each completed practice adds a bead; completing 108 practices marks a milestone and reveals a teaching. Show as a mala, not a points counter.
- **FR-GM-03 (M)** **Mudra/bandha seals:** earned when the teacher or the Pariksha criteria confirm mastery, not for time spent.
- **FR-GM-04 (M)** **Tapas points** for practice at configured times (Brahma muhurta, Sandhya) and consistency. Points are private to the user.
- **FR-GM-05 (M)** **Vishrama grace days:** configurable number per week; never show "streak lost" messaging.
- **FR-GM-06 (M)** **No leaderboards, no comparisons between users, no reward for hold length.** Rewards are for correct ratio adherence, steadiness, consistency and teacher confirmation only.
- **FR-GM-07 (M)** **Guru Anumati workflow:** the student requests an unlock → the teacher receives a request with the student's recent sessions, CHT, flags and notes → approves, denies or adds conditions → the student is notified. Levels with gate `teacher` or `guru_only` cannot be unlocked any other way.
- **FR-GM-08 (M)** **Ratio ladder progression:** advance one config step at a time, only after a configurable number of consecutive comfortable sessions (no strain flag). Never skip steps.
- **FR-GM-09 (M)** **Auto-regression:** if the post-session check-in reports strain or dizziness, the next session drops one ratio step (or one level of retention), and the teacher is notified.

### 6.6 Vedic ritual layer
- **FR-RT-01 (M)** Compute local **Brahma muhurta** (default 96 minutes before local sunrise, configurable), sunrise, solar noon and sunset **by the user's actual location and date** (diaspora).
- **FR-RT-02 (M)** Practice reminders scheduled around Brahma muhurta and Sandhya times, working offline.
- **FR-RT-03 (M)** Optional pre-practice ritual flow: achamana, asana sthapana, virtual diya (with notes for users lacking physical items), direction guidance (east/north), Guru vandana, sankalp (spoken or typed and stored).
- **FR-RT-04 (M)** Mantra and invocation library: Devanagari, transliteration, meaning, native audio, per tradition. Content from section 9 only.
- **FR-RT-05 (S, Phase 3)** **Panchang:** tithi, nakshatra, Ekadashi, Purnima, Amavasya for the user's location, validated by teachers before release. Observance plans (extended jap, specific practices) are config-driven.
- **FR-RT-06 (S, Phase 3)** Ritucharya (seasonal adjustment) suggestions, config-driven and teacher-approved.
- **FR-RT-07 (C)** Festival modes: Navratri, Shivaratri, Guru Purnima.

### 6.7 Teacher console (**FR-TC**)
- **FR-TC-01 (M)** Student list with level, weaning stage, last practice date, flags.
- **FR-TC-02 (M)** Student detail: session history, ratios used, hold times, CHT history, check-in results, notes, flagged strain events.
- **FR-TC-03 (M)** Approve, deny or condition unlock requests with a note.
- **FR-TC-04 (M)** Manually adjust a student's ratio step, level, or restrictions.
- **FR-TC-05 (M)** Send messages and one-way practice instructions to students.
- **FR-TC-06 (M)** **Config editor** (teachers with permission; admins always): edit ratio ladders, caps, gates, weaning rules, practice sequences, with **schema validation, draft/publish, versioning and rollback**.
- **FR-TC-07 (M)** **Change log:** every config change and approval records who, when, what and why.
- **FR-TC-08 (S)** Weekly review report: cohort-level aggregates (completion, strain rate, auto-regressions, progression), exportable CSV.

### 6.8 Content management (**FR-CM**)
- **FR-CM-01 (M)** Content items (mantra, invocation, lesson, practice instruction, audio, video, image) have: id, type, language, tradition tags, status (`placeholder | draft | teacher_approved`), and reviewer.
- **FR-CM-02 (M)** The app **only presents `teacher_approved` content** in pilot builds; others show a placeholder state in dev builds.
- **FR-CM-03 (S)** Admin UI for uploading and tagging content.

### 6.9 Progress and history (student)
- **FR-PR-01 (M)** Calendar of practice days, mala progress, current level and sopana map, weaning stage, mudra/bandha seals.
- **FR-PR-02 (M)** History of CHT measurements and ratio steps (informational, never competitive).
- **FR-PR-03 (S)** Gentle weekly reflection summary (private).

---

## 7. SAFETY REQUIREMENTS (HIGHEST PRIORITY)

### 7.1 Rules (config-driven but with mandatory defaults)
- **SR-01** Users flagged with **heart condition, hypertension, epilepsy, glaucoma, pregnancy, recent surgery, or hernia** cannot access **Kapalbhati, Bhastrika, retention (antar or bahya), or Uddiyana/Maha bandha** unless a **teacher explicitly clears** the specific practice for that student.
- **SR-02** **Pregnancy** blocks Kapalbhati, Bhastrika, all retention, and all bandhas except as explicitly cleared by teacher; show a prompt to consult a doctor.
- **SR-03** **Menstruation:** Kapalbhati, Uddiyana and Maha bandha are suggested-off during menstruation (user-indicated, private).
- **SR-04** **Uddiyana and Maha bandha** are only enabled on an empty stomach (user confirms) and only at Level 6+.
- **SR-05** **Bahya kumbhaka hold must never exceed antar kumbhaka hold** in the same session, and has a separate hard cap.
- **SR-06** **No level 3+ unlock without teacher approval.**
- **SR-07** Hold durations are capped by `min(level_cap, user_CHT × cap_fraction)`.
- **SR-08** **Auto-regression** on any strain/dizziness flag (FR-GM-09). Two flags within 7 days lock retention practices until a teacher reviews.
- **SR-09** Every session shows rules (empty stomach, posture, never force) and a one-tap stop that returns to natural breath.
- **SR-10** Display a visible "not medical advice, consult your physician" statement in onboarding and settings.
- **SR-11** Safety rules are enforced **server-side and in the player engine**, not only in the UI.

### 7.2 Safety testing
- Unit tests for every rule above (a rule-matrix test: each condition × each practice × expected allowed/blocked).
- Property tests proving the player never schedules a hold above the cap, for any config within the validated schema.

---

## 8. CONFIGURATION SCHEMA (REMOTE, VERSIONED, VALIDATED)

Implement JSON Schema validation. Reject any config that violates safety invariants (e.g., bahya hold > antar hold; caps missing; gates missing). Example (**all numbers are draft placeholders for teacher review**):

```json
{
  "config_version": "0.1.0",
  "matra_default_seconds": 1.0,
  "hold_cap_fraction_of_cht": 0.6,
  "comfort_streak_required_for_step": 5,
  "vishrama_days_per_week": 1,
  "levels": [
    {
      "id": 1, "name": "Prarambha", "gate": "self",
      "practices": ["breath_awareness", "om_chant", "bhramari", "nadi_shodhana_basic"],
      "ratio_ladder": [[1,0,1,0]], "base_count": 4,
      "mudras": ["gyan", "chin", "dhyana"], "bandhas": [],
      "pariksha": { "min_sessions": 21 }
    },
    {
      "id": 2, "name": "Abhyasa", "gate": "streak",
      "practices": ["kapalbhati", "ujjayi", "nadi_shodhana_nasika"],
      "ratio_ladder": [[1,0,1,0],[1,0,2,0]], "base_count": 4,
      "kapalbhati": { "strokes_per_min": 60, "strokes_per_round_ladder": [30, 45, 60], "rounds": 3 },
      "mudras": ["nasika", "shanmukhi"], "bandhas": [],
      "pariksha": { "min_sessions": 42, "consecutive_days_window": 21 }
    },
    {
      "id": 3, "name": "Antar", "gate": "teacher",
      "practices": ["sheetali", "sheetkari", "antar_kumbhaka_short"],
      "ratio_ladder": [[1,1,2,0],[1,2,2,0]], "base_count": 4,
      "mudras": ["prana", "apana"], "bandhas": ["jalandhara"],
      "pariksha": { "cht_required": true, "teacher_signoff": true }
    },
    {
      "id": 4, "name": "Shakti", "gate": "teacher",
      "practices": ["bhastrika", "surya_bhedana", "kapalbhati_advanced"],
      "ratio_ladder": [[1,2,2,0],[1,3,2,0]], "base_count": 4,
      "bandhas": ["jalandhara", "mula"],
      "pariksha": { "teacher_signoff": true }
    },
    {
      "id": 5, "name": "Kumbhaka", "gate": "teacher",
      "practices": ["nadi_shodhana_full"],
      "ratio_ladder": [[1,2,2,0],[1,3,2,0],[1,4,2,0]], "base_count": 4,
      "bandhas": ["jalandhara", "mula"],
      "pariksha": { "teacher_signoff": true, "teacher_observes_early_sessions": true }
    },
    {
      "id": 6, "name": "Bahya", "gate": "teacher",
      "practices": ["bahya_kumbhaka", "uddiyana_kriya", "maha_bandha"],
      "bahya_start_seconds": 4, "bahya_never_exceeds_antar": true,
      "bandhas": ["uddiyana", "maha_bandha"],
      "pariksha": { "teacher_signoff": true, "live_or_video_review": true }
    },
    {
      "id": 7, "name": "Dhyana", "gate": "guru_only",
      "practices": ["trataka", "antar_mouna", "ajapa_japa", "yoga_nidra_advanced"],
      "mudras": ["maha_mudra", "maha_bheda", "viparita_karani", "shambhavi"],
      "ratio_cap_default": [6,24,12,0],
      "pariksha": { "guru_only": true }
    }
  ],
  "weaning": {
    "stage_min_weeks": [3, 3, 3, 3, 0],
    "stage_min_consecutive_sessions": [10, 10, 10, 10, 0],
    "graduation_consecutive_sessions": 3
  }
}
```

The config editor must display the teacher-facing explanation of every field.

---

## 9. CONTENT (SUPPLIED, NOT GENERATED)

Create a `/content` directory with a manifest and the following **placeholder** entries that teachers will fill:

- Mantras/invocations: Om, Gayatri, Patanjali invocation, Guru vandana, "Om Sahana Vavatu", "Asato Ma Sad Gamaya", naam jap sets per tradition.
- Practice instruction scripts and audio per practice and language.
- Mudra and bandha demonstration videos/animations.
- Yoga Nidra audio (20/30/45 min).
- Lesson modules (counting methods, posture, rules, contraindications).

Each entry follows the CM status workflow. **Do not generate Sanskrit text, translations, or spiritual claims yourself.** Languages for pilot: English, Hindi, Sanskrit (text and audio).

---

## 10. NON-FUNCTIONAL REQUIREMENTS

- **NFR-01 Offline-first:** the full practice flow works without a network; sync when available. Config and content cache with version checks.
- **NFR-02 Timing accuracy:** pacer and timers drift < 50 ms per minute; use monotonic clocks; survive app backgrounding and screen lock; handle interruptions (calls) by pausing safely to natural breath.
- **NFR-03 Privacy:** health data is sensitive. Encrypt at rest and in transit; row-level security so students see only their own data and teachers only assigned students; explicit consent; data export and delete on request; comply with GDPR and India DPDP principles; no third-party ad/tracking SDKs; no sale of data.
- **NFR-04 Accessibility:** large touch targets, screen-reader labels, adjustable text, color-independent cues, reduced motion option.
- **NFR-05 Performance:** cold start < 3 s on mid-range devices; low battery impact during 45-min sessions.
- **NFR-06 Localization:** i18n architecture ready for added languages and RTL; date/time/zone-correct everywhere.
- **NFR-07 Auditability:** all approvals, config changes and safety overrides are immutably logged.
- **NFR-08 UX tone:** calm, minimal, traditional visual language; no gamified popups, confetti, urgency, or guilt messaging.

---

## 11. DATA MODEL (MINIMUM)

Tables/collections: `users`, `profiles` (tradition, language, location, tz), `health_flags`, `safety_profiles`, `teacher_students`, `config_versions`, `levels_progress`, `unlock_requests`, `sessions`, `session_rounds` (phase timings, ratio used, hold seconds, caps applied), `checkins` (calm/neutral/agitated/strained, dizziness flag, note), `cht_measurements`, `mala_progress`, `seals`, `tapas_points`, `vishrama_log`, `weaning_state`, `sankalps`, `content_items`, `audit_log`, `consents`.

Apply row-level security on every table. Provide migrations and seed data.

---

## 12. DELIVERY PHASES

**Phase 1: Foundations and safety (build first)**
Repo structure, CI, auth, consent, onboarding + health screening, safety rules engine with the full rule-matrix tests, config schema + validation, player engine with pacer/timers/hold-cap enforcement, Levels 1–2 practices (breath awareness, Om, Bhramari, Nadi Shodhana basic, Ujjayi, Kapalbhati), post-session check-in, weaning stages 1–2.
*Exit criteria:* all SR rules pass automated tests; player never exceeds caps in property tests; a student can complete a full Level 1–2 session offline.

**Phase 2: Game, teachers, and dhyan**
Level engine and Pariksha, mala, seals, tapas, vishrama, Guru Anumati workflow, auto-regression, teacher console (students, approvals, adjustments), config editor with versioning and change log, digital mala (108), Yoga Nidra player, weaning stages 3–5 with self-check mode, Levels 3–5 practices behind teacher gates.
*Exit criteria:* a teacher can approve an unlock, edit a ratio step, and the student's player reflects it without an app update.

**Phase 3: Ritual layer and advanced**
Location-aware sunrise/Brahma muhurta/Sandhya, reminders, ritual flow, mantra library, Panchang, observance plans, Level 6 practices (bahya kumbhaka, Uddiyana, Maha bandha), Level 7 content as guru-led, weekly review reports and CSV export.

**Phase 4: Hardening and extras**
Optional mic-based breath detection (on-device), wearables, performance, accessibility audit, pilot analytics, data export/delete tooling.

---

## 13. ACCEPTANCE CRITERIA (SAMPLE, EXTEND PER FR)

- **AC-1** Given a user with `hypertension=true` and no teacher clearance, when they open the practice list, then Kapalbhati, Bhastrika, all retention and Uddiyana are not startable and show the reason.
- **AC-2** Given CHT = 20 s and `hold_cap_fraction=0.6`, when the ratio would schedule a 16 s hold, then the engine caps it at 12 s.
- **AC-3** Given a strain flag in a session, when the user starts the next session, then the ratio is one ladder step lower and the teacher has a notification.
- **AC-4** Given a Level 3 unlock request, when no teacher has approved, then Level 3 practices remain locked regardless of streak or points.
- **AC-5** Given a config where bahya hold > antar hold, when a teacher tries to publish it, then validation rejects it with an explanatory error.
- **AC-6** Given the device is offline, when a student starts a session, then all cues, timers and logging work and sync later without data loss.
- **AC-7** Given a Level 6 user who has not confirmed an empty stomach, when they open Uddiyana, then it is blocked until confirmed.
- **AC-8** Given a user in London, when they open the reminder settings, then Brahma muhurta is computed from London sunrise for that date, not a fixed time.
- **AC-9** Given any session, when the user taps "Return to natural breath," then retention ends within 200 ms and the calming cue plays.
- **AC-10** Given a Stage 4 session, then no pacer, voice, haptic or count appears, only start and end bells.

---

## 14. OUT OF SCOPE FOR THIS PILOT

Public app-store release, payments, social features, leaderboards, secular mode, AI-generated spiritual content, Khechari or other guru-only techniques as trainable exercises, ratios above the teacher-set cap.

---

## 15. FIRST ACTIONS (DO THESE NOW)

1. Create the repo structure: `/app`, `/console`, `/backend`, `/content`, `/docs`, `/tests`.
2. Write `/docs/ASSUMPTIONS.md` and `/docs/ARCHITECTURE.md` (include a diagram of player engine, rules engine and config flow).
3. Implement the **safety rules engine and its rule-matrix tests first**, before any UI.
4. Implement the config JSON schema and validator, load the section 8 example as seed config.
5. Build the player engine (timer, pacer state machine, hold-cap enforcement) as a pure, unit-tested module independent of UI.
6. Then proceed through Phase 1 and report.
