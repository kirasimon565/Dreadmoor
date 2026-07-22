# Flutter-to-Unity parity matrix

This document tracks the original hand-written Flutter systems against their Unity/C# equivalents. The generated `drift_database.g.dart` file (9,187 lines) is represented by serializable records and `GameStore`; generated ORM boilerplate is not copied line-for-line.

## Core and persistence

| Original Dart source | Unity/C# replacement | Status |
|---|---|---|
| `core/models/script_models.dart` | `Core/DreadmoorModels.cs`, `Core/StoryGraph.cs` | Complete |
| `core/persistence/tables.dart` | `Core/DreadmoorModels.cs`, `Core/ExtendedGameModels.cs` | Complete |
| `core/persistence/drift_database.dart` | `Core/GameStore.cs`, `Core/GameStoreExtensions.cs` | Complete |
| `core/persistence/drift_database.g.dart` | Unity `JsonUtility` generated serialization + `GameStore` queries | Replaced, not copied |
| `core/persistence/seed_characters.dart` | `CharacterRegistry` in `DreadmoorModels.cs` | Complete |
| `core/scripting/episode_manifest.dart` | `StoryGraph.EpisodeOneResources` | Complete |
| `core/scripting/script_loader.dart` | `StoryGraph.LoadEpisodeOne` | Complete |
| `core/scheduler/global_scheduler.dart` | `Core/StoryScheduler.cs` | Complete |
| `core/time/game_clock.dart` | `GameStore` clock methods + `LiveStatusBar.cs` | Complete |
| `core/state/game_state.dart` | `GameStore`, `StoryScheduler`, `DreadmoorApp` | Complete |
| `core/state/player_state.dart` | `PlayerData`, `GameStore.SetPlayer` | Complete |
| `core/state/character_state.dart` | character registry, notes, photos and media queries | Complete |
| `core/state/episode_state.dart` | `EpisodeProgressData`, `GameStore.Episode` | Complete |
| `core/state/recap_state.dart` | `Core/RecapBuilder.cs` | Complete |
| `core/state/scheduler_state.dart` | persisted scheduler cursor and wait state | Complete |

The C# save document preserves all original logical tables: players, characters, character notes, character photos, threads, members, messages, notifications, story state, diary state, episodes, story nodes, media items, minigame results and call history.

## App shell and navigation

| Original Dart source | Unity/C# replacement | Status |
|---|---|---|
| `main.dart` | runtime bootstrap in `DreadmoorApp.cs` | Complete |
| `ui/navigation/routes.dart` | `AppView` and screen methods | Complete |
| `ui/navigation/app_router.dart` | guarded startup/welcome/OS routing | Complete |
| `ui/os/dreadmoor_os.dart` | `BuildOsShell` and call overlays | Complete |
| `ui/os/dreadmoor_app_container.dart` | `AppView` screen switch | Complete |
| `ui/os/dreadmoor_navigation_bar.dart` | OS navigation builder | Complete |
| `ui/os/dreadmoor_status_bar.dart` | `LiveStatusBar.cs` | Complete |
| `ui/os/components/os_header.dart` | `AddHeader` | Complete |
| `ui/os/os_state.dart` | `_view`, active thread and persisted state | Complete |

## Story-facing screens

| Original Dart source | Unity/C# replacement | Status |
|---|---|---|
| Studio intro | `ShowStudio`, fade/breathing effects | Complete |
| Player setup | `ShowSetup` | Complete |
| Welcome | `ShowWelcome`, looping fog video and music | Complete |
| Intro trailer | `PlayCinematic` | Complete |
| Title cinematic | `PlayCinematic` | Complete |
| Content update gate | `ShowContentUpdate` with real graph checks | Complete |
| Fatal error | `DreadmoorErrorScreen.cs`, scanlines, pulse, scramble, reboot | Complete |
| Episode selection | `ShowEpisodes`, `EpisodeTeaserView.cs` | Complete |
| Recap | `RecapBuilder`, `RecapSequenceController` | Complete |
| Credits | `ShowCredits` | Complete |
| Legal | `ShowLegal` | Complete |
| Settings | `ShowSettings` | Complete |
| Save/load | three independent snapshots in `ShowSaveLoad` | Complete |
| Debug console | `ShowDebug`, graph/database inspector and jump tools | Complete, debug builds only |

## Messenger

| Original Dart source | Unity/C# replacement | Status |
|---|---|---|
| Messenger state/providers | `GameStore` thread/message queries | Complete |
| Messenger navigator | `ShowMessenger`, `ShowChat`, `ShowCharacterProfile` | Complete |
| Messenger list | thread ordering, previews, unread state, add contact | Complete |
| Chat screen | `ShowChat` | Complete |
| Secret chat | secret thread styling and forced intercept routing | Complete |
| Chat header | `ChatHeaderView.cs` with stacked member avatars | Complete |
| Intercept banner | secret warning inside `ShowChat` | Complete |
| Chat bubble | `ChatBubbleView.cs` | Complete |
| Choice overlay | `ChoiceOverlayView.cs` | Complete |
| Typing indicator | `TypingDotsAnimator` | Complete |

## Browser, diary, profile, phone and store

| Original feature | Unity/C# replacement | Status |
|---|---|---|
| Browser home | `ShowBrowserHome` | Complete |
| Article viewer | `ShowArticle` | Complete |
| Diary controller/DAO/state | diary records and `StoryScheduler.CompleteDiary` | Complete |
| Diary grid/page/lock | `ShowDiary` | Complete |
| Letter/keyboard input | validated keyword input | Complete |
| Player profile | `ShowProfile`, Android avatar picker, local notes | Complete |
| Character profile | dossiers, recovered media and per-character notes | Complete |
| Profile media gallery | `ShowGallery`, `MediaViewerController` | Complete |
| Phone state | call cursor and `CallEntryData` | Complete |
| Dialer | keypad, direct calls and history | Complete |
| Incoming call | decline rules, forced answer and ringtone | Complete |
| Active call | timer, waveform, mute, speaker and story audio | Complete |
| Store | original procurement catalogue and billing placeholder | Complete |

## Reusable visual systems

| Original Flutter widget | Unity/C# replacement |
|---|---|
| `audio_waveform_glitch.dart` | `AudioWaveformGraphic` |
| `chat_bubble.dart` | `ChatBubbleView` |
| `choice_overlay.dart` | `ChoiceOverlayView` |
| `custom_screen_header.dart` | `AddHeader` |
| `episode_teaser_card.dart` | `EpisodeTeaserView` |
| `fog_video_background.dart` | looping Unity `VideoPlayer` background |
| `glitch_overlay.dart` | `GlitchOverlayAnimator` |
| `glitch_text.dart` | `GlitchTextAnimator` |
| `gun_typing_indicator.dart` | `TypingDotsAnimator` |
| `media_viewer.dart` | `MediaViewerController` |
| `notification_banner.dart` | `NotificationBannerView` |
| `notification_overlay.dart` | persistent `_overlayRoot` |
| `shared_screen_painters.dart` | scanline, vignette and film-grain graphics |
| `video_thumbnail_image.dart` | `VideoThumbnailView` |

## Verification

The Unity tests and pre-build validator enforce:

- exactly 391 unique Episode 1 nodes;
- every node reachable from the configured entry;
- every node capable of reaching the episode ending;
- every choice and decline target present;
- exactly one intentional Episode 1 terminal;
- all story media and required interface assets importable;
- extended persistence records round-trip through Unity JSON;
- the startup scene enabled before any APK or AAB build.
