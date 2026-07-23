using System;
using System.Collections;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Video;
using TMPro;

namespace Dreadmoor.UI
{
    public enum AppView
    {
        Studio, Setup, Welcome, Messenger, Chat, Apps, Diary, Profile, Browser, Phone,
        Notifications, Settings, SaveLoad, Episodes, Recap, Store, Credits, Legal, CharacterProfile,
        Gallery, ContentUpdate, Debug, Fatal
    }

    public sealed partial class DreadmoorApp : MonoBehaviour
    {
        private Canvas _canvas;
        private RectTransform _safeRoot;
        private RectTransform _screen;
        private RectTransform _overlayRoot;
        private StoryScheduler _scheduler;
        private GameStore _store;
        private AudioSource _music;
        private AudioSource _effects;
        private AppView _view;
        private string _openThread = "";
        private string _openCharacter = "";
        private Coroutine _flow;
        private RenderTexture _videoTexture;
        private int _callToken;
        private bool _resumeAfterPause;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Bootstrap()
        {
            if (FindFirstObjectByType<DreadmoorApp>() != null) return;
            var host = new GameObject("DreadmoorApplication");
            DontDestroyOnLoad(host);
            host.AddComponent<DreadmoorApp>();
        }

        private void Awake()
        {
            Application.targetFrameRate = 60;
            Screen.orientation = ScreenOrientation.Portrait;
            Screen.fullScreen = true;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
            
            DiaryCatalog.Initialize();

            _store = GameStore.Instance;
            _canvas = UIFactory.CreateCanvas();
            DontDestroyOnLoad(_canvas.gameObject);

            _safeRoot = UIFactory.Stretch(_canvas.transform, "SafeArea");
            _safeRoot.gameObject.AddComponent<SafeAreaFitter>();
            _overlayRoot = UIFactory.Stretch(_safeRoot, "Overlays");
            _overlayRoot.SetAsLastSibling();

            _music = gameObject.AddComponent<AudioSource>();
            _music.loop = true;
            _music.playOnAwake = false;
            _effects = gameObject.AddComponent<AudioSource>();
            _effects.playOnAwake = false;

            _scheduler = gameObject.AddComponent<StoryScheduler>();
            SubscribeScheduler();
            _scheduler.Initialize();
            if (_scheduler.Graph != null) ShowStudio();
        }

        private void OnDestroy()
        {
            if (_scheduler != null) UnsubscribeScheduler();
            ReleaseVideoTexture();
        }

        private void OnApplicationPause(bool paused)
        {
            if (_store == null || _scheduler == null) return;
            if (paused)
            {
                _resumeAfterPause = _store.HasActiveGame && !_store.Data.episodeComplete &&
                                    !string.IsNullOrWhiteSpace(_store.Data.currentNodeId);
                _scheduler.Suspend();
                _store.Save(false);
            }
            else if (_resumeAfterPause)
            {
                _resumeAfterPause = false;
                _scheduler.Resume();
            }
        }

        public void OnAvatarPicked(string result)
        {
            if (string.IsNullOrWhiteSpace(result)) return;
            if (result.StartsWith("ERROR:", StringComparison.OrdinalIgnoreCase))
            {
                ShowNotificationBanner(new NotificationData { title = "PROFILE", message = result.Substring(6) });
                return;
            }
            _store.Data.player.profilePath = result;
            _store.Save();
            if (_view == AppView.Profile) ShowProfile();
        }

        private void Update()
        {
            if (!Input.GetKeyDown(KeyCode.Escape)) return;
            if (_view == AppView.Chat || _view == AppView.CharacterProfile) ShowMessenger();
            else if (_view != AppView.Studio && _view != AppView.Setup && _view != AppView.Welcome) ShowApps();
        }

        private void SubscribeScheduler()
        {
            _scheduler.StateChanged += RefreshCurrentView;
            _scheduler.NotificationRaised += ShowNotificationBanner;
            _scheduler.ArticleRequested += ShowBrowserHome;
            _scheduler.ChoiceRequested += _ => RefreshCurrentView();
            _scheduler.IncomingCallRequested += ShowIncomingCall;
            _scheduler.ActiveCallRequested += ShowActiveCall;
            _scheduler.DiaryRequested += (word, page) => ShowDiary(page, true);
            _scheduler.ThreadFocusRequested += ShowChat;
            _scheduler.GlitchRequested += ShowGlitch;
            _scheduler.CreditsRequested += ShowCredits;
            _scheduler.SoundRequested += PlayEffect;
            _scheduler.FatalError += ShowFatal;
        }

        private void UnsubscribeScheduler()
        {
            _scheduler.StateChanged -= RefreshCurrentView;
            _scheduler.NotificationRaised -= ShowNotificationBanner;
            _scheduler.ArticleRequested -= ShowBrowserHome;
            _scheduler.IncomingCallRequested -= ShowIncomingCall;
            _scheduler.ActiveCallRequested -= ShowActiveCall;
            _scheduler.ThreadFocusRequested -= ShowChat;
            _scheduler.GlitchRequested -= ShowGlitch;
            _scheduler.CreditsRequested -= ShowCredits;
            _scheduler.SoundRequested -= PlayEffect;
            _scheduler.FatalError -= ShowFatal;
        }

        private RectTransform NewScreen(AppView view, Color background)
        {
            if (_flow != null)
            {
                StopCoroutine(_flow);
                _flow = null;
            }
            ReleaseVideoTexture();
            if (_screen != null) Destroy(_screen.gameObject);
            _view = view;
            _screen = UIFactory.Panel(_safeRoot, background, view.ToString()).rectTransform;
            UIFactory.Stretch(_screen);
            _screen.SetSiblingIndex(0);
            return _screen;
        }

        private void ShowStudio()
        {
            var root = NewScreen(AppView.Studio, Color.black);
            UIFactory.Background(root, "assets/backgrounds/studio_intro_bg.png", new Color(0.45f, 0.45f, 0.48f, 1));
            UIFactory.Background(root, "assets/ui/glitch_overlay.png", new Color(1, 1, 1, 0.08f));
            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.52f), "Vignette");
            UIFactory.Stretch(shade.rectTransform);

            var logo = UIFactory.ContentImage(root, "assets/branding/blackmoon_logo.png");
            logo.color = new Color(1, 1, 1, 0.9f);
            var logoRect = logo.rectTransform;
            logoRect.anchorMin = new Vector2(0.18f, 0.44f);
            logoRect.anchorMax = new Vector2(0.82f, 0.67f);
            logoRect.offsetMin = Vector2.zero;
            logoRect.offsetMax = Vector2.zero;
            var breathing = logo.gameObject.AddComponent<BreathingAnimator>();
            breathing.speed = 0.24f;
            breathing.startDelay = 1.8f;
            var logoEntrance = logo.gameObject.AddComponent<CanvasFadeAnimator>();
            logoEntrance.duration = 1.8f;
            logoEntrance.fromScale = 0.94f;

            var disclaimer = UIFactory.Text(root,
                "These characters and places are purely fictional.\nAny resemblance to actual persons or events is purely coincidental.",
                18, new Color(1, 1, 1, 0.34f), TextAnchor.MiddleCenter);
            disclaimer.rectTransform.anchorMin = new Vector2(0.08f, 0.27f);
            disclaimer.rectTransform.anchorMax = new Vector2(0.92f, 0.4f);
            disclaimer.rectTransform.offsetMin = Vector2.zero;
            disclaimer.rectTransform.offsetMax = Vector2.zero;
            var disclaimerEntrance = disclaimer.gameObject.AddComponent<CanvasFadeAnimator>();
            disclaimerEntrance.delay = 1.4f;
            disclaimerEntrance.duration = 1.2f;
            disclaimerEntrance.fromScale = 1f;

            var loading = UIFactory.Text(root, "LOADING  • • •", 18, new Color(1, 1, 1, 0.42f), TextAnchor.MiddleLeft);
            loading.rectTransform.anchorMin = new Vector2(0.06f, 0.025f);
            loading.rectTransform.anchorMax = new Vector2(0.55f, 0.09f);
            loading.rectTransform.offsetMin = Vector2.zero;
            loading.rectTransform.offsetMax = Vector2.zero;
            var version = UIFactory.Text(root, "BLACKMOON  /  UNITY EDITION 1.0.0", 15, new Color(1, 1, 1, 0.25f), TextAnchor.MiddleRight);
            version.rectTransform.anchorMin = new Vector2(0.45f, 0.025f);
            version.rectTransform.anchorMax = new Vector2(0.94f, 0.09f);
            version.rectTransform.offsetMin = Vector2.zero;
            version.rectTransform.offsetMax = Vector2.zero;

            _flow = StartCoroutine(StudioFlow());
        }

        private IEnumerator StudioFlow()
        {
            yield return new WaitForSecondsRealtime(_store.Data.settings.reducedMotion ? 0.5f : 4f);
            _flow = null;
            ShowContentUpdate(() =>
            {
                if (_store.HasPlayer) ShowWelcome();
                else ShowSetup();
            });
        }

        private void ShowWelcome()
        {
            var root = NewScreen(AppView.Welcome, Color.black);

            // Flutter-style Stack: the fog video/still fills the screen behind every UI layer.
            if (!AddLoopingVideoBackground(root, "assets/backgrounds/welcome_fog_loop.mp4"))
                UIFactory.Background(root, "assets/backgrounds/welcome_bg_still.png", Color.white);

            var glitch = UIFactory.Background(root, "assets/ui/glitch_overlay.png", new Color(1, 1, 1, 0.055f));
            if (_store == null || !_store.Data.settings.reducedMotion)
                glitch.gameObject.AddComponent<GlitchOverlayAnimator>().intensity = 0.12f;

            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.58f), "DarkGlassShade");
            UIFactory.Stretch(shade.rectTransform);
            shade.raycastTarget = false;

            var vignetteObject = new GameObject("WelcomeVignette", typeof(RectTransform), typeof(CanvasRenderer), typeof(VignetteGraphic));
            vignetteObject.transform.SetParent(root, false);
            var vignetteRect = vignetteObject.GetComponent<RectTransform>();
            UIFactory.Stretch(vignetteRect);
            var vignette = vignetteObject.GetComponent<VignetteGraphic>();
            vignette.color = Color.black;
            vignette.intensity = 0.38f;
            vignette.borderFraction = 0.24f;
            vignette.raycastTarget = false;

            // Flutter Column equivalent: top/bottom padding, child control size enabled, spacer-driven layout.
            var column = UIFactory.Rect(root, "WelcomeContentColumn", Vector2.zero, Vector2.one,
                Vector2.zero, Vector2.zero);
            var columnLayout = column.gameObject.AddComponent<VerticalLayoutGroup>();
            columnLayout.padding = new RectOffset(72, 72, 110, 54);
            columnLayout.spacing = 24f;
            columnLayout.childAlignment = TextAnchor.UpperCenter;
            columnLayout.childControlWidth = true;
            columnLayout.childControlHeight = true;
            columnLayout.childForceExpandWidth = true;
            columnLayout.childForceExpandHeight = false;

            var logoSlot = UIFactory.Rect(column, "LogoSlot", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var logoSlotLayout = logoSlot.gameObject.AddComponent<LayoutElement>();
            logoSlotLayout.minHeight = 280f;
            logoSlotLayout.preferredHeight = 380f;
            logoSlotLayout.flexibleHeight = 0f;

            var logo = UIFactory.ContentImage(logoSlot, "assets/branding/dreadmoor_logo.png", 340f);
            logo.gameObject.name = "DreadmoorLogo";
            var logoRect = logo.rectTransform;
            var logoAspect = logo.texture != null && logo.texture.height > 0
                ? (float)logo.texture.width / logo.texture.height
                : 1f;
            var logoHeight = 340f;
            logoRect.anchorMin = new Vector2(0.5f, 0.52f);
            logoRect.anchorMax = new Vector2(0.5f, 0.52f);
            logoRect.pivot = new Vector2(0.5f, 0.5f);
            logoRect.sizeDelta = new Vector2(Mathf.Min(820f, logoHeight * logoAspect), logoHeight);
            logo.gameObject.AddComponent<CanvasFadeAnimator>().duration = 0.9f;
            if (Debug.isDebugBuild || Application.isEditor)
            {
                logo.raycastTarget = true;
                var hold = logo.gameObject.AddComponent<LongPressHandler>();
                hold.Triggered = ShowDebug;
            }

            WelcomeSpacer(column, "HeroUpperSpacer", 80f, 0.45f);

            var heroSlot = UIFactory.Rect(column, "HeroActionSlot", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var heroSlotLayout = heroSlot.gameObject.AddComponent<LayoutElement>();
            heroSlotLayout.minHeight = 122f;
            heroSlotLayout.preferredHeight = 142f;
            heroSlotLayout.flexibleHeight = 0f;

            // Use the new styled Hero Action Button (dark bg rgba(10,18,24,0.7), cyan outline, ▶ icon + label)
            var action = UIFactory.CreateHeroActionButton(heroSlot, _store.HasActiveGame ? "CONTINUE" : "START GAME", BeginFromWelcome);
            var actionRect = action.GetComponent<RectTransform>();
            actionRect.anchorMin = new Vector2(0.08f, 0.08f);
            actionRect.anchorMax = new Vector2(0.92f, 0.92f);
            actionRect.offsetMin = Vector2.zero;
            actionRect.offsetMax = Vector2.zero;

            WelcomeSpacer(column, "HeroLowerSpacer", 80f, 1f);

            var bottomBar = UIFactory.Rect(column, "BottomBar", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var bottomLayoutElement = bottomBar.gameObject.AddComponent<LayoutElement>();
            bottomLayoutElement.minHeight = 84f;
            bottomLayoutElement.preferredHeight = 96f;
            bottomLayoutElement.flexibleHeight = 0f;
            var bottomLayout = bottomBar.gameObject.AddComponent<HorizontalLayoutGroup>();
            bottomLayout.padding = new RectOffset(28, 28, 12, 12);
            bottomLayout.spacing = 0f; // spaceBetween handled via flexible spacers
            bottomLayout.childAlignment = TextAnchor.MiddleCenter;
            bottomLayout.childControlWidth = true;
            bottomLayout.childControlHeight = true;
            bottomLayout.childForceExpandWidth = false;
            bottomLayout.childForceExpandHeight = false;

            // Far Left: BLACKMOON in faint grey
            var blackmoon = UIFactory.Text(bottomBar, "BLACKMOON", 18, new Color(0.65f, 0.68f, 0.72f, 0.75f), TextAnchor.MiddleLeft, false, "BlackmoonLabel");
            blackmoon.font = UIFactory.SpaceFont;
            blackmoon.horizontalOverflow = HorizontalWrapMode.Overflow;
            var blackmoonLayout = blackmoon.gameObject.AddComponent<LayoutElement>();
            blackmoonLayout.minWidth = 160f;
            blackmoonLayout.preferredWidth = 180f;
            blackmoonLayout.flexibleWidth = 0f;
            blackmoonLayout.minHeight = 52f;
            blackmoonLayout.preferredHeight = 52f;

            // Spacer to push center and right to spaceBetween
            var leftSpacer = bottomBar.gameObject.AddComponent<LayoutElement>();
            leftSpacer.flexibleWidth = 1f;

            // Center: Settings gear icon button
            var settingsContainer = UIFactory.Rect(bottomBar, "SettingsContainer", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var settingsLayoutEl = settingsContainer.gameObject.AddComponent<LayoutElement>();
            settingsLayoutEl.minWidth = 72f;
            settingsLayoutEl.preferredWidth = 72f;
            settingsLayoutEl.flexibleWidth = 0f;
            settingsLayoutEl.minHeight = 64f;
            settingsLayoutEl.preferredHeight = 64f;

            var settingsGo = new GameObject("SettingsButton", typeof(RectTransform), typeof(CanvasRenderer), typeof(TextMeshProUGUI));
            settingsGo.transform.SetParent(settingsContainer, false);
            var settingsText = settingsGo.GetComponent<TextMeshProUGUI>();
            settingsText.text = "⚙";
            settingsText.fontSize = 38;
            settingsText.color = new Color(1, 1, 1, 0.75f);
            settingsText.alignment = TextAlignmentOptions.Center;
            settingsText.fontStyle = FontStyles.Bold;
            UIFactory.Stretch(settingsText.rectTransform);

            var settings = settingsGo.AddComponent<Button>();
            var settingsColors = settings.colors;
            settingsColors.normalColor = Color.white;
            settingsColors.highlightedColor = new Color(0.88f, 0.94f, 1f, 1f);
            settingsColors.pressedColor = new Color(0.72f, 0.8f, 0.84f, 1f);
            settingsColors.disabledColor = new Color(0.5f, 0.5f, 0.5f, 0.45f);
            settings.colors = settingsColors;
            settings.onClick.AddListener(() =>
            {
                DreadmoorHaptics.Selection();
                ShowSettings();
            });

            // Spacer to separate center from right
            var rightSpacer = bottomBar.gameObject.AddComponent<LayoutElement>();
            rightSpacer.flexibleWidth = 1f;

            // Far Right: 3-bar vertical music equalizer indicator (static visual)
            var equalizerContainer = UIFactory.Rect(bottomBar, "EqualizerContainer", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var eqLayout = equalizerContainer.gameObject.AddComponent<LayoutElement>();
            eqLayout.minWidth = 68f;
            eqLayout.preferredWidth = 78f;
            eqLayout.flexibleWidth = 0f;
            eqLayout.minHeight = 52f;
            eqLayout.preferredHeight = 52f;

            var equalizer = UIFactory.Rect(equalizerContainer, "MusicEqualizer", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var eqHGroup = equalizer.gameObject.AddComponent<HorizontalLayoutGroup>();
            eqHGroup.childAlignment = TextAnchor.MiddleCenter;
            eqHGroup.spacing = 5f;
            eqHGroup.childControlWidth = true;
            eqHGroup.childControlHeight = true;
            eqHGroup.childForceExpandWidth = false;
            eqHGroup.childForceExpandHeight = false;

            // Create 3 vertical bars for equalizer
            for (int i = 0; i < 3; i++)
            {
                var bar = UIFactory.Panel(equalizer, new Color(0.55f, 0.58f, 0.62f, 0.65f), $"EqBar{i}", false);
                var barRect = bar.rectTransform;
                barRect.sizeDelta = new Vector2(7f, (i == 1) ? 38f : (i == 0 ? 26f : 32f));
                var barLE = bar.gameObject.AddComponent<LayoutElement>();
                barLE.minWidth = 7f;
                barLE.preferredWidth = 7f;
                barLE.minHeight = barRect.sizeDelta.y;
                barLE.preferredHeight = barRect.sizeDelta.y;
            }

            PlayMusic("assets/music/welcome_theme.mp3");

            // Explicit welcome music config (in case PlayMusic path changes):
            // loop infinitely, 2D audio, never cut off by timers/clip length
            if (_music != null)
            {
                _music.loop = true;
                _music.spatialBlend = 0f;
            }
        }

        private static RectTransform WelcomeSpacer(Transform parent, string name, float minHeight, float flexibleHeight)
        {
            var spacer = UIFactory.Rect(parent, name, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var layout = spacer.gameObject.AddComponent<LayoutElement>();
            layout.minHeight = minHeight;
            layout.preferredHeight = minHeight;
            layout.flexibleHeight = flexibleHeight;
            return spacer;
        }

        private void StyleWelcomeButton(Button button, bool primary)
        {
            var image = button.GetComponent<Image>();
            image.raycastTarget = true;
            var outline = image.gameObject.AddComponent<Outline>();
            outline.effectColor = primary ? new Color(0f, 0.85f, 1f, 0.78f) : new Color(1f, 1f, 1f, 0.24f);
            outline.effectDistance = primary ? new Vector2(2.5f, -2.5f) : new Vector2(1.2f, -1.2f);
            var shadow = image.gameObject.AddComponent<Shadow>();
            shadow.effectColor = primary ? new Color(0f, 0.82f, 1f, 0.18f) : new Color(0f, 0f, 0f, 0.25f);
            shadow.effectDistance = primary ? new Vector2(0f, -10f) : new Vector2(0f, -4f);

            var label = button.GetComponentInChildren<Text>();
            if (label == null) return;
            label.font = UIFactory.SpaceFont;
            label.fontStyle = primary ? FontStyle.Bold : FontStyle.Normal;
            label.color = primary ? UIFactory.Cyan : new Color(1f, 1f, 1f, 0.7f);
        }

        private string WelcomeVersionAndMusic()
        {
            var version = string.IsNullOrWhiteSpace(Application.version) ? "1.0.0" : Application.version;
            var music = _store != null && _store.Data.settings.music ? "MUSIC ON" : "MUSIC OFF";
            return $"v{version}  •  {music}";
        }

        private void BeginFromWelcome()
        {
            // Immediately stop welcome music (or quick fade if desired) before any navigation
            // so background music never bleeds into game/cinematic audio
            if (_music != null)
            {
                _music.Stop();
            }

            if (_store.HasActiveGame)
            {
                ShowMessenger();
                _scheduler.Resume();
                return;
            }

            if (_store.Data.introCinematicSeen)
            {
                ShowMessenger();
                _scheduler.StartNewStory();
                return;
            }

            _store.Data.introCinematicSeen = true;
            _store.Save();
            PlayCinematic("assets/media/videos/intro_teaser.mp4", () =>
                PlayCinematic("assets/media/videos/title_intro.mp4", () =>
                {
                    ShowMessenger();
                    _scheduler.StartNewStory();
                }));
        }

        private bool AddLoopingVideoBackground(RectTransform root, string path)
        {
            var clip = UIFactory.LoadVideo(path);
            if (clip == null) return false;
            _videoTexture = new RenderTexture(1080, 1920, 0, RenderTextureFormat.ARGB32);
            _videoTexture.Create();
            var image = new GameObject("FogVideo", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage)).GetComponent<RawImage>();
            image.transform.SetParent(root, false);
            image.transform.SetAsFirstSibling();

            var rect = image.rectTransform;
            rect.anchorMin = new Vector2(0, 0);
            rect.anchorMax = new Vector2(1, 1);
            rect.offsetMin = new Vector2(0, 0);
            rect.offsetMax = new Vector2(0, 0);
            rect.pivot = new Vector2(0.5f, 0.5f);

            image.texture = _videoTexture;
            image.color = Color.white;
            image.raycastTarget = false;
            var player = image.gameObject.AddComponent<VideoPlayer>();
            player.clip = clip;
            player.isLooping = true;
            player.playOnAwake = true;
            player.renderMode = VideoRenderMode.RenderTexture;
            player.targetTexture = _videoTexture;
            player.audioOutputMode = VideoAudioOutputMode.None;
            player.Play();
            return true;
        }

        private void PlayCinematic(string path, Action complete)
        {
            var root = NewScreen(AppView.Welcome, Color.black);
            var videoObject = new GameObject("CinematicPlayer", typeof(VideoPlayer), typeof(AudioSource));
            videoObject.transform.SetParent(root, false);
            var player = videoObject.GetComponent<VideoPlayer>();
            var clip = UIFactory.LoadVideo(path);
            if (clip == null)
            {
                Debug.LogWarning("Missing cinematic: " + path);
                complete?.Invoke();
                return;
            }

            _videoTexture = new RenderTexture(1080, 1920, 0, RenderTextureFormat.ARGB32);
            _videoTexture.Create();
            var image = new GameObject("Video", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage)).GetComponent<RawImage>();
            image.transform.SetParent(root, false);
            UIFactory.Stretch(image.rectTransform);
            image.texture = _videoTexture;
            image.color = Color.white;

            player.clip = clip;
            player.playOnAwake = false;
            player.isLooping = false;
            player.renderMode = VideoRenderMode.RenderTexture;
            player.targetTexture = _videoTexture;
            player.audioOutputMode = VideoAudioOutputMode.AudioSource;
            player.SetTargetAudioSource(0, videoObject.GetComponent<AudioSource>());
            var finished = false;
            Action finish = () =>
            {
                if (finished) return;
                finished = true;
                complete?.Invoke();
            };
            player.loopPointReached += _ => finish();
            player.errorReceived += (_, error) => { Debug.LogWarning(error); finish(); };
            player.Prepare();
            player.Play();

            var skip = UIFactory.Button(root, "SKIP", finish, new Color(0, 0, 0, 0.55f), Color.white, 64, 20);
            var skipRect = skip.GetComponent<RectTransform>();
            skipRect.anchorMin = new Vector2(0.76f, 0.9f);
            skipRect.anchorMax = new Vector2(0.94f, 0.95f);
            skipRect.offsetMin = Vector2.zero;
            skipRect.offsetMax = Vector2.zero;
        }

        private RectTransform BuildOsShell(AppView view, bool showNavigation, out RectTransform content)
        {
            var background = IsLight ? UIFactory.PaperBackground : UIFactory.SlateBackground;
            var root = NewScreen(view, background);

            var status = UIFactory.Panel(root, IsLight ? UIFactory.PaperCard : UIFactory.SlateHeader, "StatusBar").rectTransform;
            status.anchorMin = new Vector2(0, 0.955f);
            status.anchorMax = Vector2.one;
            status.offsetMin = Vector2.zero;
            status.offsetMax = Vector2.zero;
            var time = UIFactory.Text(status, DateTime.Now.ToString("HH:mm"), 20, Foreground, TextAnchor.MiddleLeft);
            time.gameObject.AddComponent<LiveClockText>();
            time.rectTransform.anchorMin = new Vector2(0.04f, 0);
            time.rectTransform.anchorMax = new Vector2(0.24f, 1);
            time.rectTransform.offsetMin = Vector2.zero;
            time.rectTransform.offsetMax = Vector2.zero;
            var title = UIFactory.Text(status, "DREADMOOR OS", 18, Foreground, TextAnchor.MiddleCenter, true);
            title.rectTransform.anchorMin = new Vector2(0.24f, 0);
            title.rectTransform.anchorMax = new Vector2(0.58f, 1);
            title.rectTransform.offsetMin = Vector2.zero;
            title.rectTransform.offsetMax = Vector2.zero;
            var device = UIFactory.Text(status, "VPN  •  --%", 13, Dim, TextAnchor.MiddleCenter);
            device.gameObject.AddComponent<DeviceStatusText>();
            device.rectTransform.anchorMin = new Vector2(0.58f, 0);
            device.rectTransform.anchorMax = new Vector2(0.75f, 1);
            device.rectTransform.offsetMin = Vector2.zero;
            device.rectTransform.offsetMax = Vector2.zero;
            var logs = UIFactory.Button(status, "LOGS " + UnreadCount, ShowNotifications, Color.clear, Foreground, 50, 16, false);
            var logsRect = logs.GetComponent<RectTransform>();
            logsRect.anchorMin = new Vector2(0.75f, 0);
            logsRect.anchorMax = new Vector2(0.98f, 1);
            logsRect.offsetMin = Vector2.zero;
            logsRect.offsetMax = Vector2.zero;

            var bottom = showNavigation ? 0.075f : 0f;
            content = UIFactory.Rect(root, "Content", new Vector2(0, bottom), new Vector2(1, 0.955f), Vector2.zero, Vector2.zero);

            if (showNavigation)
            {
                var nav = UIFactory.Panel(root, IsLight ? UIFactory.PaperCard : UIFactory.SlateSurface, "Navigation").rectTransform;
                nav.anchorMin = Vector2.zero;
                nav.anchorMax = new Vector2(1, 0.075f);
                nav.offsetMin = Vector2.zero;
                nav.offsetMax = Vector2.zero;
                AddNavButton(nav, 0, "MESSENGER", ShowMessenger, view == AppView.Messenger || view == AppView.Chat);
                AddNavButton(nav, 1, "DIARY", () => ShowDiary(), view == AppView.Diary);
                AddNavButton(nav, 2, "PROFILE", ShowProfile, view == AppView.Profile);
                AddNavButton(nav, 3, "APPS", ShowApps, view == AppView.Apps);
            }
            return root;
        }

        private void AddNavButton(RectTransform nav, int index, string label, Action action, bool active)
        {
            var button = UIFactory.Button(nav, label, action, Color.clear, active ? UIFactory.Cyan : Foreground,
                100, 17, false);
            var rect = button.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(index * 0.25f, 0);
            rect.anchorMax = new Vector2((index + 1) * 0.25f, 1);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private void AddHeader(RectTransform parent, string title, Action back = null, string subtitle = "")
        {
            var panel = UIFactory.Panel(parent, IsLight ? UIFactory.PaperCard : UIFactory.SlateHeader, "Header").rectTransform;
            panel.anchorMin = new Vector2(0, 0.9f);
            panel.anchorMax = Vector2.one;
            panel.offsetMin = Vector2.zero;
            panel.offsetMax = Vector2.zero;
            if (back != null)
            {
                var backButton = UIFactory.Button(panel, "< BACK", back, Color.clear, Foreground, 70, 18, false);
                var rect = backButton.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(0.015f, 0.08f);
                rect.anchorMax = new Vector2(0.25f, 0.92f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
            }
            var text = UIFactory.Text(panel, title.ToUpperInvariant(), 28, Foreground, TextAnchor.MiddleCenter, true);
            text.rectTransform.anchorMin = new Vector2(0.2f, string.IsNullOrEmpty(subtitle) ? 0 : 0.28f);
            text.rectTransform.anchorMax = new Vector2(0.8f, 1);
            text.rectTransform.offsetMin = Vector2.zero;
            text.rectTransform.offsetMax = Vector2.zero;
            if (!string.IsNullOrEmpty(subtitle))
            {
                var sub = UIFactory.Text(panel, subtitle.ToUpperInvariant(), 14, Dim, TextAnchor.UpperCenter);
                sub.rectTransform.anchorMin = new Vector2(0.2f, 0);
                sub.rectTransform.anchorMax = new Vector2(0.8f, 0.38f);
                sub.rectTransform.offsetMin = Vector2.zero;
                sub.rectTransform.offsetMax = Vector2.zero;
            }
        }

        private void RefreshCurrentView()
        {
            switch (_view)
            {
                case AppView.Messenger: ShowMessenger(); break;
                case AppView.Chat: if (!string.IsNullOrEmpty(_openThread)) ShowChat(_openThread); break;
                case AppView.Notifications: ShowNotifications(); break;
                case AppView.Diary: ShowDiary(); break;
                case AppView.Phone: ShowPhone(); break;
            }
        }

        private void PlayEffect(string assetPath)
        {
            if (!_store.Data.settings.soundEffects) return;
            var clip = UIFactory.LoadAudio(assetPath);
            if (clip != null) _effects.PlayOneShot(clip);
        }

        private void PlayMusic(string assetPath)
        {
            if (!_store.Data.settings.music) return;
            var clip = UIFactory.LoadAudio(assetPath);
            if (clip == null) return;
            _music.clip = clip;
            _music.loop = true;
            _music.spatialBlend = 0f; // 2D audio
            _music.volume = 0.72f;
            _music.Play();
        }

        private void StopMusic()
        {
            _music.Stop();
            _music.clip = null;
        }

        private void ReleaseVideoTexture()
        {
            if (_videoTexture == null) return;
            _videoTexture.Release();
            Destroy(_videoTexture);
            _videoTexture = null;
        }

        private bool IsLight => _store.Data.settings.lightTheme;
        private Color Foreground => IsLight ? UIFactory.Ink : UIFactory.SlateText;
        private Color Dim => IsLight ? new Color(0.36f, 0.36f, 0.36f, 1) : UIFactory.SlateDim;
        private Color Surface => IsLight ? UIFactory.PaperCard : UIFactory.SlateSurface;
        private Color Background => IsLight ? UIFactory.PaperBackground : UIFactory.SlateBackground;
        private int UnreadCount => _store.Data.notifications.FindAll(item => !item.isRead).Count;
    }

    public sealed class SafeAreaFitter : MonoBehaviour
    {
        private Rect _last;
        private void Update()
        {
            if (_last == Screen.safeArea) return;
            _last = Screen.safeArea;
            var rect = transform as RectTransform;
            if (rect == null || Screen.width <= 0 || Screen.height <= 0) return;
            rect.anchorMin = new Vector2(_last.xMin / Screen.width, _last.yMin / Screen.height);
            rect.anchorMax = new Vector2(_last.xMax / Screen.width, _last.yMax / Screen.height);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }
    }
}
