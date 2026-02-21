# DREADMOOR — CODEX SYSTEM PROMPT

Use this document as the **source-of-truth implementation brief** for the Dreadmoor codebase.

## Prime Directive

Build Dreadmoor as a **cinematic noir mystery game UI**, not a default mobile app.
If output looks like standard Material Design, it is incorrect and must be reworked.

## Hard Rules

### 1) Anti-Material
- Do not use default-feeling `AppBar`, `ListTile`, `BottomNavigationBar`, `Card`, `ElevatedButton`, etc. for final UI composition.
- Use composed primitives: `Container`, `Stack`, `Positioned`, `GestureDetector`, `ClipRRect`, `CustomPaint`.
- `Scaffold` is allowed only as root shell with dark background.
- Disable ink splash/highlight where interactive surfaces use Ink widgets.

### 2) Glass-Noir Visual System
- Base background: `#0A0A0A`.
- Every screen includes glitch/grain overlay (`assets/ui/glitch_overlay.png`) with subtle opacity.
- Interactive surfaces use clipped blur + thin translucent border.
- Accent cyan: `#00FFD1` for active/glow.
- Accent red: `#FF003C` for danger/locked/intercept states.

### 3) Typography
- Headers/nav labels/titles: `GoogleFonts.michroma`, wide letter spacing.
- Body/chat text: `GoogleFonts.inter`.
- Metadata/timestamps: compact uppercase inter style.
- Terminal/glitch text areas: local `mono_glitch` font.
- Do not rely on generic theme text styles in widgets; declare explicit styles or use project constants.

### 4) Navigation & Motion
- Use `GoRouter` only. No direct `Navigator.push/pop` calls.
- Every route should use a custom page transition wrapper (`DreadmoorPage`) with fade + subtle scale.
- Use `context.go/push/pop` from GoRouter.

### 5) Assets
- Use local assets from `assets/` only.
- Required assets include studio/welcome backgrounds, logos, glitch overlays, messenger/chat backgrounds, map assets, character art, and lottie animations.

## Required Theming Contracts

### `lib/ui/theme/colors.dart`
Implement a constants class with:
- background/surface/glass/border
- accent cyan/red
- primary/secondary/meta text
- cyan/red glow helpers

### `lib/ui/theme/dreadmoor_theme.dart`
- Dark scaffold background
- Dark color scheme with cyan primary/red error
- Disable default page transitions (GoRouter handles them)
- No splash/highlight
- Cyan cursor selection theme

## Route Map (Expected)

- `/` studio intro gate
- `/setup`
- `/welcome`
- `/messenger`
- `/chat/:threadId`
- `/secret/:threadId`
- `/board`
- `/board/diary/:diaryId`
- `/board/evidence/:evidenceId`
- `/profiles/:characterId`
- `/profile/player`
- `/map`
- `/episodes`
- `/recap/:episodeId`
- `/settings`
- `/save`
- `/credits`
- `/legal`
- `/update`
- `/error`

## Screen-Level Direction

Implement each major screen using cinematic layering:
- full-screen atmospheric background (image/video)
- low-opacity glitch overlay
- clipped blurred glass panels for headers/cards/modals
- deliberate typography hierarchy and restrained color use
- animated motion that is subtle, moody, and non-cartoonish

Critical gameplay screens:
- Studio intro initialization gate
- Player setup (immutable identity)
- Welcome menu hub
- Messenger list (unread/typing/locked states)
- Chat screen (custom cloud bubble, choices, intercept banner)
- Secret intercept screen (read-only + glitch intensity)
- Detective board + diary viewer
- Profiles, map, episodes, recap, settings/save-load/legal/credits

## Global Engineering Rules

- Keep files maintainable; extract subwidgets as needed.
- Put `BackdropFilter` inside `ClipRect/ClipRRect`.
- Avoid hardcoding random colors throughout widgets; prefer central constants.
- Explicit text styles on every `Text`.
- Use local assets; do not introduce network image dependencies.

## Dependencies (Expected)
- `go_router`
- `google_fonts`
- `lottie`
- `video_player`
- `drift` + `sqlite3_flutter_libs`
- `riverpod` / `flutter_riverpod`

## Why this exists

This prompt lets Codex generate implementation work that preserves a single creative direction across all screens and avoids generic Flutter defaults.
