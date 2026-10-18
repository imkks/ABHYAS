# Abhyas: Content Asset Requirements

This document acts as a checklist and guide for the Product Owner to gather, record, and format the necessary multimedia files required to populate the Abhyas application.

All content files must be placed directly into the `content/` folder at the root of the repository as detailed below.

---

## 1. Mantras and Invocations
These require a `.json` manifest containing the text (Devanagari, transliteration, meaning) and a corresponding `.mp3` audio file of the chant.

*   **Om Chanting**
    *   **Text File:** `content/mantras/om.json` (Provide translation and text).
    *   **Audio File:** `content/mantras/audio/om.mp3` (Calm, traditional chanting voice).
*   **Gayatri Mantra**
    *   **Text File:** `content/mantras/gayatri.json`
    *   **Audio File:** `content/mantras/audio/gayatri.mp3`
*   **Patanjali Invocation**
    *   **Text File:** `content/mantras/patanjali.json`
    *   **Audio File:** `content/mantras/audio/patanjali.mp3`
*   **Guru Vandana**
    *   **Text File:** `content/mantras/guru_vandana.json`
    *   **Audio File:** `content/mantras/audio/guru_vandana.mp3`
*   **Shanti Path (Om Sahana Vavatu)**
    *   **Text File:** `content/mantras/shanti_path.json`
    *   **Audio File:** `content/mantras/audio/shanti_path.mp3`

---

## 2. Practice Instructions & Audio Cues
Used by the `PlayerEngine` to guide the user without them needing to look at the screen.

*   **Voice Cues (Short MP3s):**
    *   `content/audio/cues/inhale.mp3`
    *   `content/audio/cues/hold.mp3` (Antar Kumbhaka)
    *   `content/audio/cues/exhale.mp3`
    *   `content/audio/cues/hold_out.mp3` (Bahya Kumbhaka)
    *   `content/audio/cues/return_to_natural_breath.mp3`
*   **Bells and Chimes (Short MP3s):**
    *   `content/audio/bells/start_bell.mp3`
    *   `content/audio/bells/end_bell.mp3`
    *   `content/audio/bells/meru_chime.mp3` (Special chime for the 108th bead in the Mala)
    *   `content/audio/bells/pulse.mp3` (Subtle tone for Stage 3 weaning)

---

## 3. Mudras & Bandhas (Visuals)
Visual aids displayed during practice instruction overlays.

*   **Mudras (Images or short looping video)**
    *   *Examples:* Gyan, Chin, Dhyana, Nasika (Vishnu), Shanmukhi, Prana, Apana, Shambhavi.
    *   *Path:* `content/mudras/images/gyan.png`, `content/mudras/images/nasika.webp`, etc.
*   **Bandhas (Images or diagrams)**
    *   *Examples:* Jalandhara, Mula, Uddiyana, Maha Bandha.
    *   *Path:* `content/bandhas/images/jalandhara.png`, etc.

---

## 4. Dhyan & Yoga Nidra (Long-form Audio)
Long continuous sessions for the meditation screens.

*   **Yoga Nidra Audio:**
    *   `content/yoga_nidra/audio/nidra_20m.mp3`
    *   `content/yoga_nidra/audio/nidra_30m.mp3`
    *   `content/yoga_nidra/audio/nidra_45m.mp3`
*   **Guided Meditations:**
    *   `content/dhyan/audio/trataka_guided.mp3`
    *   `content/dhyan/audio/antar_mouna_guided.mp3`
    *   `content/dhyan/audio/ajapa_japa_guided.mp3`

---

## 5. Lesson Modules (Long Text)
Educational content for learning counting or reading rules. Provide these as standard Markdown files.

*   **Counting Methods:** `content/lessons/counting_methods.md` (Explain finger-segment counting).
*   **Posture & Rules:** `content/lessons/posture_rules.md`
*   **Contraindications:** `content/lessons/contraindications.md`
