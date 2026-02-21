# DREADMOOR — Codex Handoff Brief

This repository is for **Dreadmoor**, a cinematic noir mystery game in Flutter.

If you are using OpenAI Codex (or any coding agent), copy the prompt in `docs/CODEX_SYSTEM_PROMPT.md` and treat it as the implementation contract.

## Project Intent

Dreadmoor is not a generic app UI. It is an interactive noir film with messenger gameplay, hidden intercept chats, detective board progression, diary reconstruction, and episodic narrative delivery.

The visual identity must feel:
- dark-web intercept terminal
- glass-noir overlays
- muted but high-contrast typography
- cinematic transitions
- reactive, scheduler-driven chat pacing

## Current Repository Shape

- Flutter app shell with route + screen stubs.
- Core game systems include persistence (Drift), scripting/content loading, and scheduler/state foundations.
- Local assets include branding, backgrounds, UI overlays, map/location media, and character art.

## For Codex / Agent Use

1. Read `docs/CODEX_SYSTEM_PROMPT.md` first.
2. Follow every hard UI rule in that prompt (anti-material, glass-noir, typography, GoRouter-only navigation, asset usage).
3. Keep style and architecture consistent with the existing codebase.
4. Validate changes with formatting + analysis/tests where practical.

## Quick Start

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Core Design Constraints (Summary)

- **No default Material-feeling components** (avoid AppBar/ListTile/FAB/etc. in UI composition).
- **All screens use the same cinematic black base** (`0xFF0A0A0A`) with glitch overlay texture.
- **Every route transition is controlled by custom GoRouter page transitions.**
- **Typography is explicit** (`GoogleFonts.michroma`, `GoogleFonts.inter`, and local `mono_glitch` for diary/terminal moments).
- **All media is local assets**; no `Image.network()`.

## Feature Surfaces

- Studio intro + initialization gate
- Immutable player setup
- Welcome/title hub
- Messenger thread list
- Main group/private chat with choices and typing simulation
- Secret intercept chat (read-only)
- Detective board (diary + evidence)
- Diary viewer (fragment recovery)
- Character profile + player profile
- Dreadmoor map + location sheet
- Episode select + recap
- Settings / Save-Load / Credits / Legal / Update / Error
- Debug/dev utility screen

## Content Model

Narrative content lives under `content/episodes/<episode>/...` and is consumed by scripting + scheduler systems. Keep schema compatibility when extending content.

---

If you hand this project to Codex, always provide the system prompt file and ask for strict compliance.

