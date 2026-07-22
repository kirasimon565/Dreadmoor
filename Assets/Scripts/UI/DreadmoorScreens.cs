using System;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    public sealed partial class DreadmoorApp
    {
        private void ShowSetup()
        {
            var root = NewScreen(AppView.Setup, UIFactory.SlateBackground);
            UIFactory.Background(root, "assets/characters/rebecca_silhouette.png", new Color(0.32f, 0.34f, 0.36f, 0.22f));
            UIFactory.Background(root, "assets/ui/glitch_overlay.png", new Color(1, 1, 1, 0.045f));
            var veil = UIFactory.Panel(root, new Color(0.02f, 0.04f, 0.05f, 0.75f), "Veil");
            UIFactory.Stretch(veil.rectTransform);

            var form = UIFactory.Rect(root, "IdentityForm", new Vector2(0.08f, 0.12f), new Vector2(0.92f, 0.88f), Vector2.zero, Vector2.zero);
            var layout = form.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.spacing = 24;
            layout.padding = new RectOffset(18, 18, 18, 18);
            layout.childControlHeight = true;
            layout.childControlWidth = true;
            layout.childForceExpandHeight = false;
            layout.childForceExpandWidth = true;

            var heading = UIFactory.Text(form, "IDENTITY VERIFICATION", 42, Color.white, TextAnchor.MiddleCenter, true);
            UIFactory.Preferred(heading.gameObject, 100);
            var copy = UIFactory.Text(form,
                "DREADMOOR INVESTIGATION NETWORK\nCreate the identity that will appear in encrypted conversations.",
                22, UIFactory.SlateDim, TextAnchor.MiddleCenter);
            UIFactory.Preferred(copy.gameObject, 110);
            var name = UIFactory.Input(form, "Your name");
            var phone = UIFactory.Input(form, "Phone number", true);
            var genderLabel = UIFactory.Text(form, "IDENTITY", 18, UIFactory.SlateDim, TextAnchor.MiddleLeft);
            UIFactory.Preferred(genderLabel.gameObject, 44);

            var gender = "female";
            var genderRow = UIFactory.Rect(form, "Gender", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            UIFactory.Preferred(genderRow.gameObject, 84);
            var male = UIFactory.Button(genderRow, "MALE", null, UIFactory.SlateSurface, Color.white, 84, 22);
            var female = UIFactory.Button(genderRow, "FEMALE", null, UIFactory.Cyan, Color.white, 84, 22);
            SetHalf(male.GetComponent<RectTransform>(), 0, 0.48f);
            SetHalf(female.GetComponent<RectTransform>(), 0.52f, 1);
            male.onClick.AddListener(() =>
            {
                gender = "male";
                male.GetComponent<Image>().color = UIFactory.Cyan;
                female.GetComponent<Image>().color = UIFactory.SlateSurface;
            });
            female.onClick.AddListener(() =>
            {
                gender = "female";
                female.GetComponent<Image>().color = UIFactory.Cyan;
                male.GetComponent<Image>().color = UIFactory.SlateSurface;
            });

            var error = UIFactory.Text(form, "", 19, new Color(1f, 0.42f, 0.42f), TextAnchor.MiddleCenter);
            UIFactory.Preferred(error.gameObject, 55);
            UIFactory.Button(form, "CONFIRM IDENTITY", () =>
            {
                if (string.IsNullOrWhiteSpace(name.text))
                {
                    error.text = "Please enter your name.";
                    return;
                }
                if (string.IsNullOrWhiteSpace(phone.text))
                {
                    error.text = "Please enter your phone number.";
                    return;
                }
                _store.SetPlayer(name.text, gender, phone.text);
                ShowWelcome();
            }, UIFactory.EvidenceRed, Color.white, 100, 28);
        }

        private void ShowApps()
        {
            BuildOsShell(AppView.Apps, true, out var content);
            var clock = UIFactory.Text(content, _store.FormatGameTime(), 108, Foreground, TextAnchor.MiddleCenter, true);
            clock.rectTransform.anchorMin = new Vector2(0.05f, 0.65f);
            clock.rectTransform.anchorMax = new Vector2(0.95f, 0.9f);
            clock.rectTransform.offsetMin = Vector2.zero;
            clock.rectTransform.offsetMax = Vector2.zero;
            var date = UIFactory.Text(content, _store.FormatGameDate(), 22, Dim, TextAnchor.UpperCenter);
            date.rectTransform.anchorMin = new Vector2(0.05f, 0.58f);
            date.rectTransform.anchorMax = new Vector2(0.95f, 0.68f);
            date.rectTransform.offsetMin = Vector2.zero;
            date.rectTransform.offsetMax = Vector2.zero;

            var buttons = new (string label, Action action)[]
            {
                ("DIALER", ShowPhone), ("BROWSER", ShowBrowserHome),
                ("LOGS", ShowNotifications), ("GALLERY", ShowGallery),
                ("EPISODES", ShowEpisodes), ("SAVE / LOAD", ShowSaveLoad),
                ("STORE", ShowStore), ("SETTINGS", ShowSettings)
            };
            for (var i = 0; i < buttons.Length; i++)
            {
                var column = i % 3;
                var row = i / 3;
                var button = UIFactory.Button(content, buttons[i].label, buttons[i].action,
                    IsLight ? new Color(1, 1, 1, 0.55f) : new Color(0, 0, 0, 0.25f),
                    i == 1 && !_store.Flag("article_read") ? Dim : Foreground, 150, 20);
                button.interactable = i != 1 || _store.Flag("article_read");
                var rect = button.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(0.055f + column * 0.315f, 0.37f - row * 0.16f);
                rect.anchorMax = new Vector2(0.315f + column * 0.315f, 0.48f - row * 0.16f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
            }
        }

        private void ShowSettings()
        {
            BuildOsShell(AppView.Settings, false, out var content);
            AddHeader(content, "SETTINGS", ShowApps);
            var body = UIFactory.Rect(content, "SettingsBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 15, 34);
            AddSection(list, "THEME");
            AddToggle(list, "LIGHT MODE — THE ARCHIVE", _store.Data.settings.lightTheme, value =>
            {
                _store.Data.settings.lightTheme = value; _store.Save(); ShowSettings();
            });
            AddSection(list, "GAMEPLAY");
            AddToggle(list, "FAST MESSAGE PACING", _store.Data.settings.textSpeed > 1f, value =>
            {
                _store.Data.settings.textSpeed = value ? 1.6f : 1f; _store.Save();
            });
            AddToggle(list, "HAPTIC FEEDBACK", _store.Data.settings.haptics, value =>
            {
                _store.Data.settings.haptics = value; _store.Save();
            });
            AddToggle(list, "REDUCED MOTION", _store.Data.settings.reducedMotion, value =>
            {
                _store.Data.settings.reducedMotion = value; _store.Save();
            });
            AddSection(list, "AUDIO");
            AddToggle(list, "SOUND EFFECTS", _store.Data.settings.soundEffects, value =>
            {
                _store.Data.settings.soundEffects = value; _store.Save();
            });
            AddToggle(list, "MUSIC", _store.Data.settings.music, value =>
            {
                _store.Data.settings.music = value; _store.Save();
            });
            AddSection(list, "SAVE / LOAD");
            UIFactory.Button(list, "SAVE GAME  •  " + LastSaveLabel(), () =>
            {
                _store.Save(); ShowNotificationBanner(new NotificationData { title = "SYSTEM", message = "Progress saved." });
            }, Surface, Foreground, 92, 21);
            UIFactory.Button(list, "MANAGE THREE SAVE SLOTS", ShowSaveLoad, Surface, Foreground, 92, 21);
            AddSection(list, "INFORMATION");
            UIFactory.Button(list, "LEGAL & PRIVACY", ShowLegal, Surface, Foreground, 82, 20);
            UIFactory.Button(list, "CREDITS", ShowCredits, Surface, Foreground, 82, 20);
            if (Debug.isDebugBuild || Application.isEditor)
                UIFactory.Button(list, "DEBUG CONSOLE", ShowDebug, UIFactory.Hex("#0C190C"), UIFactory.Hex("#69F06D"), 82, 18);
            UIFactory.Button(list, "RESET ALL PROGRESS", ConfirmReset, new Color(0.3f, 0.03f, 0.03f, 0.9f), Color.white, 92, 20);
        }

        private void AddToggle(Transform parent, string label, bool value, Action<bool> changed)
        {
            UIFactory.Button(parent, label + "      " + (value ? "[ ON ]" : "[ OFF ]"), () => changed(!value),
                Surface, value ? UIFactory.Cyan : Dim, 82, 19);
        }

        private void AddSection(Transform parent, string label)
        {
            var heading = UIFactory.Text(parent, label, 18, UIFactory.EvidenceRed, TextAnchor.LowerLeft, true);
            UIFactory.Preferred(heading.gameObject, 62);
        }

        private string LastSaveLabel()
        {
            if (string.IsNullOrWhiteSpace(_store.Data.lastSavedUtc)) return "NO SAVE";
            return DateTime.TryParse(_store.Data.lastSavedUtc, out var date) ? date.ToLocalTime().ToString("dd/MM HH:mm") : "AUTO";
        }

        private void ConfirmReset()
        {
            var overlay = UIFactory.Panel(_overlayRoot, new Color(0, 0, 0, 0.9f), "ResetConfirmation");
            UIFactory.Stretch(overlay.rectTransform);
            var title = UIFactory.Text(overlay.transform, "RESET PROGRESS?", 42, Color.white, TextAnchor.MiddleCenter, true);
            title.rectTransform.anchorMin = new Vector2(0.08f, 0.58f);
            title.rectTransform.anchorMax = new Vector2(0.92f, 0.7f);
            title.rectTransform.offsetMin = Vector2.zero;
            title.rectTransform.offsetMax = Vector2.zero;
            var copy = UIFactory.Text(overlay.transform, "This erases every message, choice and case file. This cannot be undone.", 23,
                UIFactory.SlateDim, TextAnchor.MiddleCenter);
            copy.rectTransform.anchorMin = new Vector2(0.1f, 0.44f);
            copy.rectTransform.anchorMax = new Vector2(0.9f, 0.58f);
            copy.rectTransform.offsetMin = Vector2.zero;
            copy.rectTransform.offsetMax = Vector2.zero;
            var cancel = UIFactory.Button(overlay.transform, "CANCEL", () => Destroy(overlay.gameObject), UIFactory.SlateSurface, Color.white, 90, 22);
            cancel.GetComponent<RectTransform>().anchorMin = new Vector2(0.1f, 0.31f);
            cancel.GetComponent<RectTransform>().anchorMax = new Vector2(0.47f, 0.38f);
            cancel.GetComponent<RectTransform>().offsetMin = Vector2.zero;
            cancel.GetComponent<RectTransform>().offsetMax = Vector2.zero;
            var reset = UIFactory.Button(overlay.transform, "CONFIRM", () =>
            {
                _scheduler.Suspend();
                _store.Reset(); ShowSetup();
            }, UIFactory.EvidenceRed, Color.white, 90, 22);
            reset.GetComponent<RectTransform>().anchorMin = new Vector2(0.53f, 0.31f);
            reset.GetComponent<RectTransform>().anchorMax = new Vector2(0.9f, 0.38f);
            reset.GetComponent<RectTransform>().offsetMin = Vector2.zero;
            reset.GetComponent<RectTransform>().offsetMax = Vector2.zero;
        }

        private void ShowNotifications()
        {
            BuildOsShell(AppView.Notifications, false, out var content);
            AddHeader(content, "LOGS", ShowApps, "RECENT ACTIVITY");
            var body = UIFactory.Rect(content, "LogBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 18, 30);
            if (_store.Data.notifications.Count == 0)
            {
                var empty = UIFactory.Text(list, "SYSTEM CLEAR", 24, Dim, TextAnchor.MiddleCenter);
                UIFactory.Preferred(empty.gameObject, 500);
                return;
            }
            foreach (var notification in _store.Data.notifications)
            {
                notification.isRead = true;
                var captured = notification;
                UIFactory.Button(list,
                    $"{notification.title.ToUpperInvariant()}     {FormatTime(notification.gameMinutes)}\n{notification.message}",
                    () =>
                    {
                        if (!string.IsNullOrWhiteSpace(captured.threadId)) ShowChat(captured.threadId);
                        else if (captured.type == "article") ShowArticle(_store.Data.article);
                    }, Surface, Foreground, 126, 18);
            }
            _store.Save(false);
        }

        private void ShowProfile()
        {
            BuildOsShell(AppView.Profile, true, out var content);
            UIFactory.Background(content, "assets/media/images/moon_tower_hero.png", new Color(0.32f, 0.32f, 0.32f, 1));
            var card = UIFactory.Panel(content, new Color(1, 1, 1, 0.94f), "ProfileCard", true).rectTransform;
            card.anchorMin = new Vector2(0.06f, 0.05f);
            card.anchorMax = new Vector2(0.94f, 0.7f);
            card.offsetMin = Vector2.zero;
            card.offsetMax = Vector2.zero;
            var avatarPath = string.IsNullOrWhiteSpace(_store.Data.player.profilePath)
                ? "assets/icon/icon.png" : _store.Data.player.profilePath;
            var avatar = UIFactory.ContentImage(card, avatarPath, 180);
            SetAnchors(avatar.rectTransform, 0.38f, 0.62f, 0.76f, 0.98f);
            var changeAvatar = UIFactory.Button(card, "CHANGE PHOTO", () => AvatarPicker.PickImage(error =>
                ShowNotificationBanner(new NotificationData { title = "PROFILE", message = error })),
                new Color(0, 0, 0, 0.58f), Color.white, 54, 14);
            SetAnchors(changeAvatar.GetComponent<RectTransform>(), 0.65f, 0.92f, 0.8f, 0.89f);
            var name = UIFactory.Text(card, _store.HasPlayer ? _store.Data.player.name : "Investigator", 43,
                UIFactory.Ink, TextAnchor.MiddleCenter, true);
            SetAnchors(name.rectTransform, 0.08f, 0.92f, 0.64f, 0.76f);
            var details = UIFactory.Text(card,
                "INVESTIGATOR DOSSIER\n\nPHONE  " + _store.Data.player.phoneNumber +
                "\nIDENTITY  " + _store.Data.player.gender.ToUpperInvariant() +
                "\n\nMy internal notes and findings.", 23, UIFactory.Ink, TextAnchor.UpperLeft);
            details.rectTransform.anchorMin = new Vector2(0.09f, 0.27f);
            details.rectTransform.anchorMax = new Vector2(0.91f, 0.63f);
            details.rectTransform.offsetMin = Vector2.zero;
            details.rectTransform.offsetMax = Vector2.zero;
            var playerNoteCount = _store.NotesFor("player").Count;
            var notes = UIFactory.Button(card, $"INVESTIGATION NOTES  [{playerNoteCount}]", ShowNotes,
                UIFactory.Ink, Color.white, 70, 18);
            SetAnchors(notes.GetComponent<RectTransform>(), 0.13f, 0.87f, 0.16f, 0.25f);
            var contacts = UIFactory.Button(card, "OPEN CONTACT DOSSIERS", () => ShowCharacterProfile("unknown"),
                UIFactory.EvidenceRed, Color.white, 70, 18);
            SetAnchors(contacts.GetComponent<RectTransform>(), 0.13f, 0.87f, 0.05f, 0.14f);
        }

        private void ShowNotes()
        {
            BuildOsShell(AppView.Profile, false, out var content);
            AddHeader(content, "INVESTIGATION NOTES", ShowProfile, "PRIVATE / LOCAL ONLY");
            var body = UIFactory.Rect(content, "NotesBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, UIFactory.PaperBackground, 16, 36);
            var input = UIFactory.Input(list, "Write a case note...");
            UIFactory.Button(list, "ADD NOTE", () =>
            {
                var value = input.text.Trim();
                if (value.Length == 0) return;
                _store.AddCharacterNote("player", value);
                ShowNotes();
            }, UIFactory.EvidenceRed, Color.white, 78, 18);
            var notes = _store.NotesFor("player");
            if (notes.Count == 0)
            {
                var empty = UIFactory.Text(list, "NO NOTES ON FILE", 22, new Color(0.35f, 0.35f, 0.35f), TextAnchor.MiddleCenter);
                UIFactory.Preferred(empty.gameObject, 180);
            }
            foreach (var note in notes)
            {
                var capturedId = note.id;
                var capturedText = note.noteText;
                UIFactory.Button(list, capturedText + "\n\nTAP TO DELETE", () =>
                {
                    _store.DeleteCharacterNote(capturedId);
                    ShowNotes();
                }, UIFactory.PaperCard, UIFactory.Ink, Mathf.Max(100, capturedText.Length * 1.3f), 20);
            }
        }

        private void ShowCharacterProfile(string characterId)
        {
            _openCharacter = characterId;
            BuildOsShell(AppView.CharacterProfile, false, out var content);
            var character = _store.Character(characterId);
            AddHeader(content, "CASE FILE", () =>
            {
                if (!string.IsNullOrWhiteSpace(_openThread)) ShowChat(_openThread);
                else ShowProfile();
            });
            var body = UIFactory.Rect(content, "Dossier", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, UIFactory.PaperBackground, 18, 34);
            if (!string.IsNullOrWhiteSpace(character.avatarPath)) UIFactory.ContentImage(list, character.avatarPath, 560);
            var name = UIFactory.Text(list, character.name.ToUpperInvariant(), 45, UIFactory.Ink, TextAnchor.MiddleCenter, true);
            UIFactory.Preferred(name.gameObject, 90);
            var phone = UIFactory.Text(list, "CONTACT  " + character.phoneNumber, 22, UIFactory.EvidenceRed, TextAnchor.MiddleCenter);
            UIFactory.Preferred(phone.gameObject, 58);
            var bio = UIFactory.Text(list, character.bio, 24, UIFactory.Ink, TextAnchor.UpperLeft);
            UIFactory.Preferred(bio.gameObject, 130);
            var mediaHeading = UIFactory.Text(list, "RECOVERED MEDIA", 22, UIFactory.EvidenceRed, TextAnchor.MiddleLeft, true);
            UIFactory.Preferred(mediaHeading.gameObject, 64);
            var recovered = _store.Data.messages.Where(message => message.senderId == characterId &&
                (message.mediaType == "video" || message.mediaType == "image")).ToArray();
            if (recovered.Length == 0)
            {
                var empty = UIFactory.Text(list, "NO MEDIA RECOVERED", 19, new Color(0.4f, 0.4f, 0.4f), TextAnchor.MiddleCenter);
                UIFactory.Preferred(empty.gameObject, 100);
            }
            foreach (var item in recovered)
            {
                var media = item;
                UIFactory.Button(list, media.mediaType == "video" ? "PLAY VIDEO EVIDENCE" : "OPEN IMAGE EVIDENCE",
                    () => ShowProfileMedia(media.mediaPath, media.mediaType == "video", characterId),
                    UIFactory.Ink, Color.white, 76, 17);
            }
            var notesHeading = UIFactory.Text(list, "INVESTIGATION NOTES", 22, UIFactory.EvidenceRed, TextAnchor.MiddleLeft, true);
            UIFactory.Preferred(notesHeading.gameObject, 64);
            foreach (var note in _store.NotesFor(characterId))
            {
                var noteId = note.id;
                UIFactory.Button(list, note.noteText + "\nTAP TO DELETE", () =>
                {
                    _store.DeleteCharacterNote(noteId);
                    ShowCharacterProfile(characterId);
                }, UIFactory.PaperCard, UIFactory.Ink, Mathf.Max(82, note.noteText.Length * 1.25f), 18);
            }
            var noteInput = UIFactory.Input(list, "Add a private note...");
            UIFactory.Button(list, "ADD NOTE", () =>
            {
                if (_store.AddCharacterNote(characterId, noteInput.text) != null) ShowCharacterProfile(characterId);
            }, UIFactory.EvidenceRed, Color.white, 72, 17);
            var characters = CharacterRegistry.All.Where(item => item.id != characterId && item.id != "system").ToArray();
            foreach (var item in characters)
            {
                var captured = item.id;
                UIFactory.Button(list, "NEXT FILE  /  " + item.name.ToUpperInvariant(), () => ShowCharacterProfile(captured),
                    UIFactory.PaperCard, UIFactory.Ink, 72, 18);
            }
        }

        private void ShowDiary()
        {
            ShowDiary("page_01", false);
        }

        private void ShowDiary(string pageId, bool forcedPuzzle)
        {
            BuildOsShell(AppView.Diary, !forcedPuzzle, out var content);
            AddHeader(content, "REBECCA'S DIARY", forcedPuzzle ? null : ShowApps, "RECOVERED PAGES");
            var body = UIFactory.Rect(content, "DiaryBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var pageAsset = UIFactory.LoadText("assets/story/ep01/diary/page_01.json");
            var page = pageAsset != null ? JsonUtility.FromJson<DiaryPageFile>(pageAsset.text) : new DiaryPageFile { word = "ECHO" };
            var state = _store.GetDiary(pageId, page.word);
            var list = UIFactory.ScrollList(body, UIFactory.Hex("#E9DFC4"), 18, 42);
            var paper = UIFactory.ContentImage(list, "assets/ui/notebook_paper.jpg", 420);
            paper.color = new Color(1, 1, 1, 0.42f);
            var title = UIFactory.Text(list, $"PAGE {page.page:00}  /  {page.episode.ToUpperInvariant()}", 24,
                UIFactory.EvidenceRed, TextAnchor.MiddleCenter, true);
            UIFactory.Preferred(title.gameObject, 72);
            if (!state.isUnlocked)
            {
                var locked = UIFactory.Text(list, "ENCRYPTED PAGE\nEnter the recovered keyword.", 28, UIFactory.Ink,
                    TextAnchor.MiddleCenter, true);
                UIFactory.Preferred(locked.gameObject, 130);
                var input = UIFactory.Input(list, "KEYWORD");
                input.characterLimit = Math.Max(4, page.word.Length);
                var feedback = UIFactory.Text(list, "", 20, UIFactory.EvidenceRed, TextAnchor.MiddleCenter);
                UIFactory.Preferred(feedback.gameObject, 52);
                UIFactory.Button(list, "UNLOCK", () =>
                {
                    if (_scheduler.CompleteDiary(pageId, input.text)) ShowDiary(pageId, false);
                    else feedback.text = "ACCESS DENIED — INCORRECT KEYWORD";
                }, UIFactory.EvidenceRed, Color.white, 88, 22);
            }
            else
            {
                foreach (var paragraph in page.content ?? Array.Empty<string>())
                {
                    var text = UIFactory.Text(list, paragraph, 25, UIFactory.Ink, TextAnchor.UpperLeft);
                    UIFactory.Preferred(text.gameObject, Mathf.Max(105, paragraph.Length * 1.45f));
                }
            }
        }

        private void ShowEpisodes()
        {
            BuildOsShell(AppView.Episodes, false, out var content);
            AddHeader(content, "EPISODES", ShowApps, "CASE ARCHIVE");
            var body = UIFactory.Rect(content, "EpisodeBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 24, 38);
            var episode = _store.Episode("ep01");
            AddEpisodeCard(list, "EPISODE 01", "THE DISAPPEARANCE",
                "A missing woman. A false timeline. Someone is watching.", "assets/media/headers/default_case.jpg",
                false, episode.completed, episode.NormalizedProgress, 0,
                () => { if (_store.Data.episodeComplete) ShowRecap(); else BeginEpisode(); });
            AddEpisodeCard(list, "EPISODE 02", "CLASSIFIED",
                "Additional case files have not been released.", "assets/media/headers/default_header.jpg",
                true, false, 0, 1, null);
            AddEpisodeCard(list, "EPISODE 03", "CLASSIFIED",
                "Authorization required. Coming soon.", "assets/media/headers/default_header.jpg",
                true, false, 0, 2, null);
        }

        private void AddEpisodeCard(Transform parent, string episodeId, string title, string description,
            string imagePath, bool locked, bool completed, float progress, int index, Action action)
        {
            var host = UIFactory.Rect(parent, episodeId.Replace(" ", ""), Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var card = host.gameObject.AddComponent<EpisodeTeaserView>();
            card.Initialize(episodeId, title, description, imagePath, locked, completed, progress, index, action);
        }

        private void BeginEpisode()
        {
            ShowMessenger();
            if (_store.HasActiveGame) _scheduler.Resume();
            else _scheduler.StartNewStory();
        }

        private void ShowRecap()
        {
            var root = NewScreen(AppView.Recap, Color.black);
            var sequence = root.gameObject.AddComponent<RecapSequenceController>();
            sequence.Initialize(RecapBuilder.Build(_store, "ep01"), ShowApps);
        }

        private void ShowStore()
        {
            BuildOsShell(AppView.Store, false, out var content);
            AddHeader(content, "PROCUREMENT", ShowApps, "AUTHORIZED PERSONNEL ONLY");
            var body = UIFactory.Rect(content, "StoreBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 18, 34);
            AddSection(list, "OPERATIONAL UPGRADES");
            StoreItem(list, "TRACE SIGNAL UNIT", "Real-time indicators for encrypted channels.", "€1.99");
            StoreItem(list, "DREADMOOR DAILY: ARCHIVE", "Permanent access to the newspaper archive theme.", "€0.99");
            AddSection(list, "ADDITIONAL DOSSIERS");
            StoreItem(list, "THE VOSS CONSPIRACY", "Four new characters and twenty secret files.", "€4.99");
            var note = UIFactory.Text(list, "Purchases are display-only in this build. Connect your platform billing implementation before release.",
                18, Dim, TextAnchor.MiddleCenter);
            UIFactory.Preferred(note.gameObject, 110);
        }

        private void StoreItem(Transform parent, string title, string description, string price)
        {
            UIFactory.Button(parent, title + "     " + price + "\n" + description,
                () => ShowNotificationBanner(new NotificationData { title = "STORE", message = "Platform billing is not configured." }),
                Surface, Foreground, 132, 19);
        }

        private void ShowLegal()
        {
            BuildOsShell(AppView.Legal, false, out var content);
            AddHeader(content, "LEGAL", ShowSettings);
            var body = UIFactory.Rect(content, "LegalBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, UIFactory.PaperBackground, 20, 42);
            AddDocumentText(list, "DREADMOOR — LEGAL NOTICE", 34, true);
            AddDocumentText(list, "Dreadmoor is a work of fiction. Characters, locations, organizations, phone numbers and events are fictional. Any resemblance to real persons or events is coincidental.", 23);
            AddDocumentText(list, "CONTENT NOTICE", 25, true);
            AddDocumentText(list, "This mystery experience includes threatening calls, disappearance themes, flashing/glitch effects, simulated private messages and suspense audio. Reduced Motion and audio controls are available in Settings.", 23);
            AddDocumentText(list, "PRIVACY", 25, true);
            AddDocumentText(list, "Player identity and story progress are stored only in the app's local persistent-data directory. This Unity port contains no analytics SDK and sends no personal data to Blackmoon Studio.", 23);
            AddDocumentText(list, "This game is provided “as is” without warranties of any kind. © 2026 Blackmoon Studio. All rights reserved.", 23);
        }

        private void AddDocumentText(Transform parent, string value, int size, bool heading = false)
        {
            var text = UIFactory.Text(parent, value, size, UIFactory.Ink, TextAnchor.UpperLeft, heading);
            UIFactory.Preferred(text.gameObject, Mathf.Max(76, value.Length * 1.5f));
        }

        private void ShowCredits()
        {
            ShowCredits("");
        }

        private void ShowCredits(string closing)
        {
            var root = NewScreen(AppView.Credits, Color.black);
            UIFactory.Background(root, "assets/media/images/skull_noir_bg.png", new Color(0.48f, 0.48f, 0.48f, 1));
            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.7f), "Shade");
            UIFactory.Stretch(shade.rectTransform);
            var list = UIFactory.ScrollList(root, Color.clear, 26, 64);
            AddCredit(list, "DREADMOOR", 58, Color.white, true);
            AddCredit(list, string.IsNullOrWhiteSpace(closing) ? "A REBECCA STONE MYSTERY" : closing, 23, UIFactory.EvidenceRed, true);
            AddCredit(list, "CREATED BY\nBLACKMOON STUDIO", 30, Color.white, true);
            AddCredit(list, "UNITY C# PORT\nNarrative systems • Mobile OS interface • Save architecture", 22, UIFactory.SlateText);
            AddCredit(list, "STORY & DESIGN\nBlackmoon Studio", 23, UIFactory.SlateText);
            AddCredit(list, "THANK YOU FOR PLAYING", 32, Color.white, true);
            AddCredit(list, "TO BE CONTINUED IN EPISODE 2", 24, UIFactory.EvidenceRed, true);
            UIFactory.Button(list, "RETURN", () => { if (_store.Data.episodeComplete) ShowRecap(); else ShowWelcome(); },
                UIFactory.EvidenceRed, Color.white, 90, 22);
        }

        private void AddCredit(Transform parent, string value, int size, Color color, bool display = false)
        {
            var text = UIFactory.Text(parent, value, size, color, TextAnchor.MiddleCenter, display);
            UIFactory.Preferred(text.gameObject, 150);
        }

        private static string FormatTime(int gameMinutes)
        {
            var date = new DateTime(2016, 6, 12, 23, 42, 0).AddMinutes(gameMinutes - GameStore.InitialGameMinutes);
            return date.ToString("HH:mm");
        }

        private static void SetHalf(RectTransform rect, float min, float max)
        {
            rect.anchorMin = new Vector2(min, 0);
            rect.anchorMax = new Vector2(max, 1);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }
    }
}
