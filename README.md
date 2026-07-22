# Dreadmoor — Unity C# Edition

Dreadmoor has been converted from Flutter/Dart into a native **Unity 6 / C#** project while retaining the original story, visual assets, phone-OS presentation, choices, calls, diary puzzle, browser article, profiles, store mock-up, saves, and episode flow.

## Requirements

- Unity **6000.0.38f1** with Android Build Support
- Android SDK/NDK and OpenJDK installed through Unity Hub
- Portrait Android device (Android 8 / API 26 or newer)

Open the repository root in Unity Hub. The startup scene is `Assets/Scenes/Main.unity`; the application UI is bootstrapped automatically.

## Game architecture

- `Assets/Scripts/Core/StoryGraph.cs` imports and validates all six Episode 1 scene files.
- `Assets/Scripts/Core/StoryScheduler.cs` executes the 391-node graph with one persisted cursor. Choices, calls, diary gates, context switches, pauses, typing, media, glitches and credits are data-driven.
- `Assets/Scripts/Core/GameStore.cs` provides atomic local JSON persistence under Unity's `Application.persistentDataPath`.
- `Assets/Scripts/UI/` builds the portrait phone interface with Unity uGUI and the original image, video, font, music and sound assets.
- `Assets/Tests/EditMode/StoryGraphTests.cs` checks every narrative edge, branch, terminal, call target, diary link and media reference.
- `Assets/Editor/DreadmoorBuildValidator.cs` runs the same checks before every player build. A broken link fails the build rather than shipping.

All original content is now under `Assets/Resources/assets/`, so Unity includes it in Android builds and existing story asset paths remain compatible.

## Local validation and build

In Unity:

1. Select **Dreadmoor → Validate Complete Game**.
2. Open **Window → General → Test Runner** and run EditMode tests.
3. Use **File → Build Profiles**, select Android, and build the APK or App Bundle.

The build validator configures:

- Application ID: `com.blackmoonstudio.dreadmoor`
- Product/company: Dreadmoor / Blackmoon Studio
- Portrait-only orientation
- ARM64
- Minimum Android API 26

## GitHub Actions with your Unity account

The ready-to-install workflow is stored at [`Documentation/github-actions/unity-android.yml`](Documentation/github-actions/unity-android.yml). Arena's GitHub App cannot modify protected workflow paths, so after opening the PR, copy this template to `.github/workflows/build.yaml` using GitHub's web editor and remove the obsolete Flutter `build_runner.yml`. The Unity workflow validates the graph, runs EditMode tests, and creates signed APK and AAB artifacts with GameCI.

Add these repository secrets in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Purpose |
|---|---|
| `UNITY_LICENSE` | Unity license file contents used by GameCI |
| `UNITY_EMAIL` | Email for your Unity account |
| `UNITY_PASSWORD` | Password for your Unity account |
| `ANDROID_KEYSTORE_BASE64` | Release keystore encoded as one-line base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing key alias |
| `ANDROID_KEY_PASSWORD` | Signing key password |

Encode a keystore on Linux/macOS with:

```bash
base64 -w 0 dreadmoor-release.keystore
```

On macOS, where `-w` is unavailable:

```bash
base64 < dreadmoor-release.keystore | tr -d '\n'
```

Do not commit a Unity license, account password, or Android keystore. The workflow reads them only from encrypted GitHub secrets.

After activation, the workflow runs on pushes to `Production_Dreadmoor` and this Arena conversion branch, on pull requests to production, and via manual dispatch. Download outputs from the workflow run's **Artifacts** section.

## Story authoring

Episode 1 remains JSON-driven in `Assets/Resources/assets/story/ep01/`. A scene node may link through:

- `next`
- every `options[].next` or legacy `options[].target`
- `next_on_decline.target`

The validator requires every target to exist and every node to be reachable from `SCENE_1_NEWS_ARTICLE`. Future loops are accepted only when they contain a yielding interaction or delay; a zero-delay system loop is rejected because it would lock the game.

See [`Documentation/UNITY_PORT.md`](Documentation/UNITY_PORT.md) for architecture details and [`Documentation/PARITY_MATRIX.md`](Documentation/PARITY_MATRIX.md) for the original-file-to-Unity feature audit.
