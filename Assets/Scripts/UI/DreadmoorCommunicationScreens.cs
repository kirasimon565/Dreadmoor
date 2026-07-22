using System;
using System.Collections;
using System.Linq;
using Dreadmoor.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Dreadmoor.UI
{
    public sealed partial class DreadmoorApp
    {
        private void ShowMessenger()
        {
            _scheduler.LeaveThread();
            _openThread = "";
            BuildOsShell(AppView.Messenger, true, out var content);
            AddHeader(content, "MESSENGER", ShowSettings, "ENCRYPTED CONNECTIONS");
            var body = UIFactory.Rect(content, "Threads", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            UIFactory.Background(body, "assets/backgrounds/messenger_bg_texture.png", new Color(0.42f, 0.48f, 0.52f, 0.35f));
            var list = UIFactory.ScrollList(body, new Color(0.08f, 0.14f, 0.18f, 0.82f), 18, 28);
            UIFactory.Button(list, "+  NEW CONNECTION", ShowAddContact, new Color(0.03f, 0.16f, 0.21f, 0.94f),
                UIFactory.Cyan, 76, 18);

            if (_store.Data.threads.Count == 0)
            {
                var empty = UIFactory.Text(list, "NO CONNECTIONS FOUND\nNew transmissions will appear here.", 23,
                    UIFactory.SlateDim, TextAnchor.MiddleCenter);
                UIFactory.Preferred(empty.gameObject, 600);
                return;
            }

            foreach (var thread in _store.Data.threads.OrderByDescending(ThreadSortIndex))
            {
                var captured = thread.id;
                var last = _store.LastMessage(thread.id);
                var preview = last == null ? "No messages yet." : last.content;
                if (preview.Length > 65) preview = preview.Substring(0, 62) + "...";
                var unread = thread.unreadCount > 0 ? $"   [{thread.unreadCount} NEW]" : "";
                var prefix = thread.isSecret ? "[INTERCEPT] " : "";
                UIFactory.Button(list,
                    prefix + thread.title.ToUpperInvariant() + unread + "\n" + preview,
                    () => ShowChat(captured), thread.isSecret ? new Color(0.24f, 0.03f, 0.04f, 0.95f) : UIFactory.Hex("#466774"),
                    Color.white, 130, 21);
            }
        }

        private void ShowAddContact()
        {
            var overlay = UIFactory.Panel(_overlayRoot, new Color(0, 0, 0, 0.9f), "NewConnection");
            UIFactory.Stretch(overlay.rectTransform);
            var box = UIFactory.Panel(overlay.transform, UIFactory.SlateHeader, "ConnectionBox", true).rectTransform;
            SetAnchors(box, 0.08f, 0.92f, 0.32f, 0.68f);
            var heading = UIFactory.Text(box, "NEW CONNECTION", 32, Color.white, TextAnchor.MiddleCenter, true);
            SetAnchors(heading.rectTransform, 0.05f, 0.95f, 0.72f, 0.94f);
            var input = UIFactory.Input(box, "ENTER FREQUENCY / NUMBER", true);
            SetAnchors(input.GetComponent<RectTransform>(), 0.08f, 0.92f, 0.46f, 0.66f);
            var feedback = UIFactory.Text(box, "", 18, new Color(1, 0.4f, 0.4f), TextAnchor.MiddleCenter);
            SetAnchors(feedback.rectTransform, 0.08f, 0.92f, 0.34f, 0.45f);
            var cancel = UIFactory.Button(box, "CANCEL", () => Destroy(overlay.gameObject), UIFactory.SlateSurface, Color.white, 74, 18);
            SetAnchors(cancel.GetComponent<RectTransform>(), 0.08f, 0.44f, 0.08f, 0.29f);
            var connect = UIFactory.Button(box, "ESTABLISH", () =>
            {
                var character = CharacterRegistry.All.FirstOrDefault(item => item.phoneNumber == input.text.Trim());
                if (character == null)
                {
                    feedback.text = "FREQUENCY NOT FOUND";
                    return;
                }
                _store.EnsureThread(character.id, character.name, new[] { character.id });
                _store.Save();
                Destroy(overlay.gameObject);
                ShowChat(character.id);
            }, UIFactory.Cyan, Color.white, 74, 18);
            SetAnchors(connect.GetComponent<RectTransform>(), 0.56f, 0.92f, 0.08f, 0.29f);
        }

        private int ThreadSortIndex(ThreadData thread)
        {
            for (var i = _store.Data.messages.Count - 1; i >= 0; i--)
                if (_store.Data.messages[i].threadId == thread.id) return i;
            return -1;
        }

        private void ShowChat(string threadId)
        {
            if (string.IsNullOrWhiteSpace(threadId)) return;
            var thread = _store.EnsureThread(threadId);
            if (_store.Data.activeThreadId != threadId || thread.unreadCount > 0)
                _scheduler.OpenThread(threadId);
            _openThread = threadId;

            BuildOsShell(AppView.Chat, false, out var content);
            UIFactory.Background(content, thread.isSecret ? "assets/media/images/skull_noir_bg.png" : "assets/media/images/forest_moon_bg.png",
                thread.isSecret ? new Color(0.38f, 0.18f, 0.18f, 1) : new Color(0.58f, 0.65f, 0.72f, 1));
            var shade = UIFactory.Panel(content, thread.isSecret ? new Color(0.09f, 0, 0, 0.7f) : new Color(0.01f, 0.05f, 0.09f, 0.45f), "ChatShade");
            UIFactory.Stretch(shade.rectTransform);

            var header = UIFactory.Panel(content, Color.clear, "ChatHeader", true).rectTransform;
            header.anchorMin = new Vector2(0, 0.9f);
            header.anchorMax = Vector2.one;
            header.offsetMin = Vector2.zero;
            header.offsetMax = Vector2.zero;
            var headerView = header.gameObject.AddComponent<ChatHeaderView>();
            headerView.Initialize(thread, _store, ShowMessenger, ShowCharacterProfile);

            var body = UIFactory.Rect(content, "Messages", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Color.clear, 14, 22);
            if (thread.isSecret)
            {
                var intercept = UIFactory.Text(list, "SIGNAL INTERCEPTED  /  IDENTITY HIDDEN  /  DO NOT REPLY", 17,
                    new Color(1f, 0.35f, 0.3f), TextAnchor.MiddleCenter);
                UIFactory.Preferred(intercept.gameObject, 70);
            }

            foreach (var message in _store.MessagesFor(threadId)) AddChatBubble(list, message, thread);

            if (_scheduler.TypingThreadId == threadId)
            {
                var typingRow = UIFactory.Rect(list, "TypingIndicator", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
                UIFactory.Preferred(typingRow.gameObject, 70);
                var dots = UIFactory.Rect(typingRow, "Dots", new Vector2(0.02f, 0.15f), new Vector2(0.2f, 0.85f), Vector2.zero, Vector2.zero);
                dots.gameObject.AddComponent<TypingDotsAnimator>();
                var typing = UIFactory.Text(typingRow, "TRANSMISSION IN PROGRESS", 17,
                    new Color(1, 1, 1, 0.65f), TextAnchor.MiddleLeft);
                SetAnchors(typing.rectTransform, 0.22f, 0.95f, 0.1f, 0.9f);
            }

            var choice = _scheduler.ActiveChoice();
            if (choice != null && _store.Data.activeChoiceNodeId == choice.id &&
                (choice.chat == threadId || string.IsNullOrWhiteSpace(choice.chat)))
            {
                var choiceHost = UIFactory.Rect(list, "ChoiceOverlay", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
                var overlay = choiceHost.gameObject.AddComponent<ChoiceOverlayView>();
                overlay.Initialize(choice, thread, (choiceText, target) => _scheduler.SubmitChoice(choiceText, target));
            }
        }

        private void AddChatBubble(Transform list, MessageData message, ThreadData thread)
        {
            var row = UIFactory.Rect(list, "Message_" + message.id, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var bubble = row.gameObject.AddComponent<ChatBubbleView>();
            bubble.Initialize(message, thread, _store.Character(message.senderId), media =>
                ShowMedia(media.mediaPath, media.mediaType == "video", media.threadId));
        }

        private void ShowMedia(string path, bool video, string returnThread)
        {
            var items = _store.MediaForThread(returnThread).Select(MediaViewerItem.From).ToList();
            if (items.All(item => item.path != path))
                items.Add(new MediaViewerItem { path = path, mediaType = video ? "video" : "image" });
            var index = Mathf.Max(0, items.FindIndex(item => item.path == path));
            var root = NewScreen(AppView.Chat, Color.black);
            var viewer = root.gameObject.AddComponent<MediaViewerController>();
            viewer.Initialize(items, index, () => ShowChat(returnThread));
        }

        private void ShowProfileMedia(string path, bool video, string characterId)
        {
            var items = _store.MediaForCharacter(characterId).Select(MediaViewerItem.From).ToList();
            if (items.All(item => item.path != path))
                items.Add(new MediaViewerItem { path = path, mediaType = video ? "video" : "image", sender = characterId });
            var index = Mathf.Max(0, items.FindIndex(item => item.path == path));
            var root = NewScreen(AppView.CharacterProfile, Color.black);
            var viewer = root.gameObject.AddComponent<MediaViewerController>();
            viewer.Initialize(items, index, () => ShowCharacterProfile(characterId));
        }

        private void ShowBrowserHome()
        {
            ShowBrowserHome(_store.Data.article);
        }

        private void ShowBrowserHome(ArticleData article)
        {
            BuildOsShell(AppView.Browser, false, out var content);
            var address = UIFactory.Panel(content, Surface, "AddressBar").rectTransform;
            address.anchorMin = new Vector2(0, 0.91f);
            address.anchorMax = Vector2.one;
            address.offsetMin = Vector2.zero;
            address.offsetMax = Vector2.zero;
            var back = UIFactory.Button(address, "<", ShowApps, Color.clear, Foreground, 70, 28, false);
            SetAnchors(back.GetComponent<RectTransform>(), 0.01f, 0.12f, 0.1f, 0.9f);
            var url = UIFactory.Text(address, "●  dreadmoor-daily.local", 20, Foreground, TextAnchor.MiddleCenter);
            SetAnchors(url.rectTransform, 0.14f, 0.94f, 0.16f, 0.84f);
            var body = UIFactory.Rect(content, "BrowserHome", Vector2.zero, new Vector2(1, 0.91f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 20, 34);
            var masthead = UIFactory.Text(list, "DREADMOOR DAILY", 38, Foreground, TextAnchor.MiddleCenter, true);
            UIFactory.Preferred(masthead.gameObject, 92);
            if (!_store.Flag("article_read") || article == null || string.IsNullOrWhiteSpace(article.headline))
            {
                var empty = UIFactory.Text(list, "CONNECTION TIMEOUT\nNO RECOVERED ARTICLES", 24, Dim, TextAnchor.MiddleCenter, true);
                UIFactory.Preferred(empty.gameObject, 520);
                return;
            }
            var card = UIFactory.Panel(list, Surface, "ArticleCard", true).rectTransform;
            UIFactory.Preferred(card.gameObject, 620);
            if (!string.IsNullOrWhiteSpace(article.photo))
            {
                var image = UIFactory.ContentImage(card, article.photo, 300);
                SetAnchors(image.rectTransform, 0, 1, 0.48f, 1);
            }
            var category = UIFactory.Text(card, "BREAKING / LOCAL", 15, UIFactory.EvidenceRed, TextAnchor.UpperLeft, true);
            SetAnchors(category.rectTransform, 0.05f, 0.95f, 0.4f, 0.48f);
            var headline = UIFactory.Text(card, article.headline.ToUpperInvariant(), 27, Foreground, TextAnchor.UpperLeft, true);
            SetAnchors(headline.rectTransform, 0.05f, 0.95f, 0.16f, 0.41f);
            var sub = UIFactory.Text(card, article.subheadline, 18, Dim, TextAnchor.UpperLeft);
            SetAnchors(sub.rectTransform, 0.05f, 0.95f, 0.05f, 0.17f);
            var button = card.gameObject.AddComponent<Button>();
            button.onClick.AddListener(() => ShowArticle(article));
        }

        private void ShowArticle(ArticleData article)
        {
            BuildOsShell(AppView.Browser, false, out var content);
            var address = UIFactory.Panel(content, Surface, "AddressBar").rectTransform;
            address.anchorMin = new Vector2(0, 0.91f);
            address.anchorMax = Vector2.one;
            address.offsetMin = Vector2.zero;
            address.offsetMax = Vector2.zero;
            var back = UIFactory.Button(address, "<", ShowBrowserHome, Color.clear, Foreground, 70, 28, false);
            SetAnchors(back.GetComponent<RectTransform>(), 0.01f, 0.12f, 0.1f, 0.9f);
            var url = UIFactory.Text(address, "●  dreadmoor-daily.local", 20, Foreground, TextAnchor.MiddleCenter);
            SetAnchors(url.rectTransform, 0.14f, 0.94f, 0.16f, 0.84f);

            var body = UIFactory.Rect(content, "Article", Vector2.zero, new Vector2(1, 0.91f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, UIFactory.PaperBackground, 18, 38);
            if (article == null || string.IsNullOrWhiteSpace(article.headline))
            {
                var offline = UIFactory.Text(list, "CONNECTION TIMEOUT\nNo recovered articles.", 27, UIFactory.Ink, TextAnchor.MiddleCenter, true);
                UIFactory.Preferred(offline.gameObject, 600);
                return;
            }
            var masthead = UIFactory.Text(list, "THE DREADMOOR DAILY", 39, UIFactory.Ink, TextAnchor.MiddleCenter, true);
            UIFactory.Preferred(masthead.gameObject, 90);
            var rule = UIFactory.Panel(list, UIFactory.Ink, "Rule");
            UIFactory.Preferred(rule.gameObject, 3);
            var headline = UIFactory.Text(list, article.headline, 39, UIFactory.Ink, TextAnchor.UpperLeft, true);
            UIFactory.Preferred(headline.gameObject, Mathf.Max(220, article.headline.Length * 2.3f));
            var sub = UIFactory.Text(list, article.subheadline, 25, new Color(0.2f, 0.2f, 0.2f), TextAnchor.UpperLeft);
            sub.fontStyle = FontStyle.Italic;
            UIFactory.Preferred(sub.gameObject, Mathf.Max(120, article.subheadline.Length * 1.4f));
            if (!string.IsNullOrWhiteSpace(article.photo)) UIFactory.ContentImage(list, article.photo, 430);
            var caption = UIFactory.Text(list, article.caption, 17, new Color(0.3f, 0.3f, 0.3f), TextAnchor.UpperLeft);
            UIFactory.Preferred(caption.gameObject, 75);
            foreach (var paragraph in article.body ?? Array.Empty<string>())
            {
                var copy = UIFactory.Text(list, paragraph, 24, UIFactory.Ink, TextAnchor.UpperLeft);
                UIFactory.Preferred(copy.gameObject, Mathf.Max(130, paragraph.Length * 1.35f));
            }
        }

        private void ShowPhone()
        {
            BuildOsShell(AppView.Phone, false, out var content);
            AddHeader(content, "DIALER", ShowApps, "SECURE LINE");
            var body = UIFactory.Rect(content, "PhoneBody", Vector2.zero, new Vector2(1, 0.9f), Vector2.zero, Vector2.zero);
            var list = UIFactory.ScrollList(body, Background, 16, 38);
            var number = UIFactory.Input(list, "ENTER NUMBER", true, 100);
            AddDialRow(list, number, "1", "2", "3");
            AddDialRow(list, number, "4", "5", "6");
            AddDialRow(list, number, "7", "8", "9");
            AddDialRow(list, number, "*", "0", "#");
            UIFactory.Button(list, "PLACE CALL", () =>
            {
                if (string.IsNullOrWhiteSpace(number.text)) return;
                var character = CharacterRegistry.All.FirstOrDefault(item => item.phoneNumber == number.text);
                ShowDirectCall(character?.name ?? number.text, number.text);
            }, UIFactory.Cyan, Color.white, 88, 22);
            var history = UIFactory.Text(list, "CALL HISTORY", 21, UIFactory.EvidenceRed, TextAnchor.MiddleLeft, true);
            UIFactory.Preferred(history.gameObject, 72);
            if (_store.Data.callHistory.Count == 0)
            {
                var empty = UIFactory.Text(list, "NO CALLS RECORDED", 21, Dim, TextAnchor.MiddleCenter);
                UIFactory.Preferred(empty.gameObject, 160);
            }
            foreach (var call in _store.Data.callHistory)
            {
                UIFactory.Button(list,
                    $"{call.name.ToUpperInvariant()}   {call.number}\n{call.direction.ToUpperInvariant()}  •  {FormatTime(call.gameMinutes)}  •  {call.durationSeconds}s",
                    () => ShowDirectCall(call.name, call.number), Surface, Foreground, 105, 18);
            }
        }

        private void AddDialRow(Transform parent, InputField input, string left, string center, string right)
        {
            var row = UIFactory.Rect(parent, "DialRow", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            UIFactory.Preferred(row.gameObject, 88);
            var labels = new[] { left, center, right };
            for (var i = 0; i < labels.Length; i++)
            {
                var digit = labels[i];
                var button = UIFactory.Button(row, digit, () => input.text += digit, Surface, Foreground, 84, 27);
                var rect = button.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(i / 3f + 0.015f, 0.04f);
                rect.anchorMax = new Vector2((i + 1) / 3f - 0.015f, 0.96f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
            }
        }

        private void ShowIncomingCall(StoryNode node)
        {
            _callToken++;
            var root = NewScreen(AppView.Phone, Color.black);
            UIFactory.Background(root, "assets/media/images/moon_tower_hero.png", new Color(0.55f, 0.55f, 0.55f, 1));
            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.54f), "CallShade");
            UIFactory.Stretch(shade.rectTransform);
            AddCallIdentity(root, "INCOMING CALL", StoryScheduler.CallerName(node), StoryScheduler.CallerNumber(node));
            var decline = UIFactory.Button(root, "DECLINE", () =>
            {
                StopCallAudio();
                _scheduler.DeclineIncomingCall();
                ShowPhone();
            }, UIFactory.EvidenceRed, Color.white, 110, 22);
            SetAnchors(decline.GetComponent<RectTransform>(), 0.08f, 0.43f, 0.12f, 0.2f);
            decline.gameObject.SetActive(_scheduler.CanDecline(node));
            var answer = UIFactory.Button(root, "ANSWER", () =>
            {
                StopCallAudio();
                _scheduler.AcceptIncomingCall();
            }, UIFactory.Hex("#198754"), Color.white, 110, 22);
            SetAnchors(answer.GetComponent<RectTransform>(), _scheduler.CanDecline(node) ? 0.57f : 0.28f,
                _scheduler.CanDecline(node) ? 0.92f : 0.72f, 0.12f, 0.2f);
            StartRingtone(node.audio_loop);
        }

        private void ShowActiveCall(StoryNode node)
        {
            var token = ++_callToken;
            var root = NewScreen(AppView.Phone, Color.black);
            UIFactory.Background(root, "assets/media/images/moon_tower_hero.png", new Color(0.48f, 0.48f, 0.48f, 1));
            var shade = UIFactory.Panel(root, new Color(0, 0, 0, 0.58f), "CallShade");
            UIFactory.Stretch(shade.rectTransform);
            AddCallIdentity(root, "CONNECTED", StoryScheduler.CallerName(node), StoryScheduler.CallerNumber(node));
            var timer = UIFactory.Text(root, "00:00", 32, UIFactory.Cyan, TextAnchor.MiddleCenter);
            SetAnchors(timer.rectTransform, 0.2f, 0.8f, 0.47f, 0.55f);
            var waveformObject = new GameObject("AudioWaveform", typeof(RectTransform), typeof(CanvasRenderer), typeof(AudioWaveformGraphic));
            waveformObject.transform.SetParent(root, false);
            var waveform = waveformObject.GetComponent<AudioWaveformGraphic>();
            waveform.color = new Color(0.7f, 0.9f, 1f, 0.9f);
            waveform.bars = 48;
            waveform.glitch = true;
            SetAnchors(waveform.rectTransform, 0.05f, 0.95f, 0.34f, 0.45f);
            var started = Time.realtimeSinceStartup;
            var muted = false;
            var speaker = false;
            Button muteButton = null;
            Button speakerButton = null;
            muteButton = UIFactory.Button(root, "MUTE", () =>
            {
                muted = !muted;
                _effects.mute = muted;
                muteButton.GetComponent<Image>().color = muted ? Color.white : new Color(0, 0, 0, 0.38f);
                muteButton.GetComponentInChildren<Text>().color = muted ? Color.black : Color.white;
            }, new Color(0, 0, 0, 0.38f), Color.white, 82, 17);
            SetAnchors(muteButton.GetComponent<RectTransform>(), 0.18f, 0.43f, 0.23f, 0.3f);
            speakerButton = UIFactory.Button(root, "SPEAKER", () =>
            {
                speaker = !speaker;
                _effects.volume = speaker ? 1f : 0.78f;
                speakerButton.GetComponent<Image>().color = speaker ? Color.white : new Color(0, 0, 0, 0.38f);
                speakerButton.GetComponentInChildren<Text>().color = speaker ? Color.black : Color.white;
            }, new Color(0, 0, 0, 0.38f), Color.white, 82, 17);
            SetAnchors(speakerButton.GetComponent<RectTransform>(), 0.57f, 0.82f, 0.23f, 0.3f);
            var end = UIFactory.Button(root, "END CALL", () => FinishStoryCall(token, started), UIFactory.EvidenceRed, Color.white, 110, 22);
            SetAnchors(end.GetComponent<RectTransform>(), 0.32f, 0.68f, 0.1f, 0.18f);
            StartCoroutine(UpdateCallTimer(token, started, timer));
            var audio = UIFactory.LoadAudio(node.audio_asset);
            if (audio != null)
            {
                _effects.loop = false;
                _effects.clip = audio;
                _effects.Play();
                StartCoroutine(AutoEndStoryCall(token, started, audio.length));
            }
        }

        private void ShowDirectCall(string name, string number)
        {
            var token = ++_callToken;
            var root = NewScreen(AppView.Phone, Color.black);
            UIFactory.Background(root, "assets/media/images/moon_tower_hero.png", new Color(0.45f, 0.45f, 0.45f, 1));
            AddCallIdentity(root, "OUTGOING CALL", name, number);
            var started = Time.realtimeSinceStartup;
            var timer = UIFactory.Text(root, "00:00", 32, UIFactory.Cyan, TextAnchor.MiddleCenter);
            SetAnchors(timer.rectTransform, 0.2f, 0.8f, 0.42f, 0.52f);
            StartCoroutine(UpdateCallTimer(token, started, timer));
            var end = UIFactory.Button(root, "END CALL", () =>
            {
                if (token != _callToken) return;
                _callToken++;
                _store.Data.callHistory.Insert(0, new CallEntryData
                {
                    name = name, number = number, direction = "outgoing", gameMinutes = _store.Data.gameClockMinutes,
                    durationSeconds = Mathf.RoundToInt(Time.realtimeSinceStartup - started)
                });
                _store.Save();
                ShowPhone();
            }, UIFactory.EvidenceRed, Color.white, 110, 22);
            SetAnchors(end.GetComponent<RectTransform>(), 0.32f, 0.68f, 0.1f, 0.18f);
        }

        private void AddCallIdentity(RectTransform root, string state, string name, string number)
        {
            var status = UIFactory.Text(root, state, 20, new Color(1, 1, 1, 0.65f), TextAnchor.MiddleCenter);
            SetAnchors(status.rectTransform, 0.12f, 0.88f, 0.77f, 0.84f);
            var caller = UIFactory.Text(root, name.ToUpperInvariant(), 48, Color.white, TextAnchor.MiddleCenter, true);
            SetAnchors(caller.rectTransform, 0.06f, 0.94f, 0.65f, 0.78f);
            var id = UIFactory.Text(root, number, 24, new Color(1, 1, 1, 0.72f), TextAnchor.MiddleCenter);
            SetAnchors(id.rectTransform, 0.12f, 0.88f, 0.59f, 0.67f);
        }

        private IEnumerator UpdateCallTimer(int token, float started, Text target)
        {
            while (token == _callToken && target != null)
            {
                var seconds = Mathf.Max(0, Mathf.FloorToInt(Time.realtimeSinceStartup - started));
                target.text = $"{seconds / 60:00}:{seconds % 60:00}";
                yield return new WaitForSecondsRealtime(0.25f);
            }
        }

        private IEnumerator AutoEndStoryCall(int token, float started, float duration)
        {
            yield return new WaitForSecondsRealtime(Mathf.Max(0.25f, duration));
            FinishStoryCall(token, started);
        }

        private void FinishStoryCall(int token, float started)
        {
            if (token != _callToken) return;
            _callToken++;
            StopCallAudio();
            _scheduler.EndActiveCall(Mathf.RoundToInt(Time.realtimeSinceStartup - started));
            ShowPhone();
        }

        private void StartRingtone(string path)
        {
            StopCallAudio();
            if (!_store.Data.settings.soundEffects) return;
            var clip = UIFactory.LoadAudio(path);
            if (clip == null) return;
            _effects.clip = clip;
            _effects.loop = true;
            _effects.Play();
        }

        private void StopCallAudio()
        {
            _effects.Stop();
            _effects.loop = false;
            _effects.mute = false;
            _effects.volume = 1f;
            _effects.clip = null;
        }

        private void ShowNotificationBanner(NotificationData notification)
        {
            if (notification == null || string.IsNullOrWhiteSpace(notification.message)) return;
            var host = new GameObject("NotificationBanner", typeof(RectTransform));
            host.transform.SetParent(_overlayRoot, false);
            var banner = host.AddComponent<NotificationBannerView>();
            banner.Initialize(notification, opened =>
            {
                if (!string.IsNullOrWhiteSpace(opened.threadId)) ShowChat(opened.threadId);
                else if (opened.type == "article") ShowArticle(_store.Data.article);
            }, id =>
            {
                var record = _store.Data.notifications.FirstOrDefault(item => item.id == id);
                if (record != null) record.isRead = true;
                _store.Save(false);
            });
        }

        private IEnumerator RemoveAfter(GameObject target, float delay)
        {
            yield return new WaitForSecondsRealtime(delay);
            if (target != null) Destroy(target);
        }

        private void ShowGlitch(string message, float duration)
        {
            var overlay = UIFactory.Panel(_overlayRoot, new Color(0.15f, 0, 0, 0.62f), "GlitchOverlay");
            UIFactory.Stretch(overlay.rectTransform);
            var texture = UIFactory.Background(overlay.transform, "assets/ui/glitch_overlay.png", new Color(1, 1, 1, 0.68f));
            texture.gameObject.AddComponent<GlitchOverlayAnimator>().intensity = 0.9f;
            var text = UIFactory.Text(overlay.transform, string.IsNullOrWhiteSpace(message) ? "[ SIGNAL LOST ]" : message,
                30, Color.white, TextAnchor.MiddleCenter, true);
            UIFactory.Stretch(text.rectTransform, 50);
            StartCoroutine(RemoveAfter(overlay.gameObject, duration));
        }

        private static void SetAnchors(RectTransform rect, float xMin, float xMax, float yMin, float yMax)
        {
            rect.anchorMin = new Vector2(xMin, yMin);
            rect.anchorMax = new Vector2(xMax, yMax);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }
    }
}
