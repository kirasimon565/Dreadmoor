# Unity Port Feature Map

## Runtime flow

| Original feature | Unity implementation |
|---|---|
| Studio intro | Blackmoon branding, textured backdrop, disclaimer and timed initialization |
| Player setup | Name, phone and identity selection persisted locally |
| Welcome | Dreadmoor artwork, Start/Continue logic, theme music and settings |
| Intro/title films | Unity `VideoPlayer`, skip control and automatic continuation |
| Phone OS | Status bar, notification log, Messenger/Diary/Profile/Apps navigation |
| Messenger | Thread list, unread state, character/group headers, chat bubbles, typing state, choice cards, media evidence |
| Secret intercept | Secret-thread styling, VPN warning and hacked context routing |
| Browser | Dreadmoor Daily article, photograph, caption and full story body |
| Phone | Dialer, call history, incoming/forced call rules, ringtone, active-call audio and timer |
| Diary | ECHO lock puzzle, persisted unlock and complete recovered page |
| Profiles | Player dossier and all seeded character dossiers |
| Episodes/recap | Episode progress, completion state, evidence-aware Episode 1 recap |
| Settings/save | Theme, message pace, haptics, reduced motion, SFX/music, explicit save/load and reset |
| Store | Original procurement catalogue as a platform-billing placeholder |
| Credits/legal | Fiction notice, local-data privacy note, content notice and episode credits |

## Scheduler guarantees

`StoryScheduler` owns a single coroutine and cursor. It writes the continuation before executing the next node. A node is marked processed only when its side effect has completed:

- Messages are deduplicated by source node ID.
- Choices are completed only after a validated option target is selected.
- Diary nodes remain active until the correct word is entered.
- Incoming calls remain active until accepted or validly declined.
- Active calls remain active until audio completes or the player ends the call.
- Thread changes and app process termination preserve the exact continuation.

The graph loader keeps compatibility with Episode 1 aliases (`Private_Unknown`, `Video_Node`, `Force_Ringing`) while new content can use the generic node names documented in the existing scene format.

## Persistence

The former relational Drift tables are represented by serializable C# records in one versioned save document. The save includes:

- player and settings;
- current node, active thread and active choice;
- processed nodes and story flags;
- threads, messages and notifications;
- game clock, call history and diary progress;
- recovered article and episode completion.

Writes use a temporary file followed by a move to avoid leaving half-written JSON. An unreadable save is backed up and replaced with a clean state.

## Extending episodes

1. Put scene JSON and referenced content under `Assets/Resources/assets/story/<episode>/`.
2. Register scene resource paths in `StoryGraph` (or add an episode manifest when multiple playable episodes are available).
3. Use supported generic node types and provide explicit thread metadata when starting a context.
4. Run **Dreadmoor → Validate Complete Game** and all EditMode tests.
5. Add tests for the new entry point, terminal nodes and episode-specific gates.

Never bypass graph validation in a release build: the pre-build validator exists specifically to prevent dead choices, missing media and continuation errors.
