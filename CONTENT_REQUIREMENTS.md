# Abhyas Audio & Content Asset Specification

This document defines the two distinct audio paradigms used in the Abhyas app, their target folders, naming conventions, and file formats.

---

## 1. Exercise Audio Paradigms

| Exercise Type | Examples | Audio Guidance Style | Playback Engine | Assets Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Pranayama (Breathwork)** | Nadi Shodhana, Sama Vritti, Kapalbhati, Bhastrika, Sheetali | **Minimalist Tonal Cues**: Single-word cues (*"Inhale"*, *"Hold"*, *"Exhale"*) + Tibetan Bowls / Bells + progressive weaning to boundary chimes. | `PracticeAudioService` (dual audio channel) | Short acoustic bell WAVs & voice WAVs in `app/assets/audio/` and `app/assets/audio/voice/` *(bundled)*. |
| **Dhyan / Deep Relaxation** | Yoga Nidra (20m, 30m, 45m), Bodyscan | **Continuous Spoken Guided Stream**: Unbroken long-form audio track with media scrubber, 15s forward/rewind, stage tracking (Sankalpa, Nyasa, Prana Dharana). | `AudioService` (long-form track stream) | Large audio files in `app/assets/audio/` *(listed below)*. |
| **Mantra Japa** | Om Chanting, 108 Bead Japa, Bhramari | **Looping Drone / Chants**: Repetitive peaceful drone or 108 interval chime counter. | `AudioService` | Continuous drone/chant files in `app/assets/audio/`. |

---

## 2. Large Audio Files Required for Generation / Placement

Please place finalized studio recordings into `app/assets/audio/`. Both `.mp3` and `.wav` formats are supported (128kbps+ MP3 or 16-bit 44.1kHz WAV).

### A. Guided Yoga Nidra Sessions
- **`app/assets/audio/yoga_nidra_20min.mp3`** (or `.wav`)
  - **Duration**: ~20 minutes.
  - **Content**: 7-stage guided relaxation: Preparation, Sankalpa, Rotation of Consciousness (Nyasa), Breath Awareness, Opposites (Heavy/Light), Visualization, Externalization.
- **`app/assets/audio/yoga_nidra_30min.mp3`** (or `.wav`)
  - **Duration**: ~30 minutes.
- **`app/assets/audio/yoga_nidra_45min.mp3`** (or `.wav`)
  - **Duration**: ~45 minutes (full traditional Bihar School of Yoga format).

### B. Continuous Chants & Drones
- **`app/assets/audio/om_chant.mp3`** (or `.wav`)
  - **Content**: Authentic 136.1 Hz Cosmic Om chant loop.
- **`app/assets/audio/bhramari.mp3`** (or `.wav`)
  - **Content**: Sustained humming bee breath guidance tone/drone.

---

## 3. Bundled Short Voice & Bell Assets (Already Generated)

Located in `app/assets/audio/` and `app/assets/audio/voice/`:
- **Pranayama Voice Prompts**: `voice_settle.wav`, `voice_begin.wav`, `voice_puraka.wav` (*"Inhale"*), `voice_kumbhaka.wav` (*"Hold"*), `voice_rechaka.wav` (*"Exhale"*), `voice_bahya.wav` (*"Suspend"*), `voice_rest.wav`, `voice_complete.wav`, `voice_open_eyes.wav`.
- **Meditation Voice Prompts**:
  - Progressive Japa: `voice_japa_vaikhari.wav`, `voice_japa_upamshu.wav`, `voice_japa_manasika.wav`, `voice_japa_laya.wav`
  - Breath Awareness: `voice_breath_intro.wav`, `voice_breath_nostril.wav`, `voice_breath_pause.wav`, `voice_breath_return.wav`, `voice_breath_complete.wav`
- **Ambient Soundscapes**: `tanpura_drone.wav` (432Hz Sa-Pa meditative chord), `yoga_nidra_ambient.wav`.
- **Acoustic Singing Bowls & Bells**: 40 harmonic WAV files across 4 palettes (Singing Bowl, Temple Bell, Woodblock, Flute Harmonic).
