using System;
using System.Collections;
using System.Linq;
using UnityEngine;

namespace Dreadmoor.Core
{
    /// <summary>
    /// Executes the data-driven episode graph. Only one coroutine owns the
    /// cursor, and every transition is persisted before the next node runs.
    /// This prevents duplicate messages and broken continuation loops.
    /// </summary>
    public sealed class StoryScheduler : MonoBehaviour
    {
        public event Action StateChanged;
        public event Action<NotificationData> NotificationRaised;
        public event Action<ArticleData> ArticleRequested;
        public event Action<StoryNode> ChoiceRequested;
        public event Action<StoryNode> IncomingCallRequested;
        public event Action<StoryNode> ActiveCallRequested;
        public event Action<string, string> DiaryRequested;
        public event Action<string> ThreadFocusRequested;
        public event Action<string, float> GlitchRequested;
        public event Action<string> CreditsRequested;
        public event Action<string> SoundRequested;
        public event Action<string> FatalError;

        public StoryGraph Graph { get; private set; }
        public bool IsRunning => _runner != null;
        public bool IsWaitingForInteraction { get; private set; }
        public string TypingThreadId { get; private set; } = "";

        private GameStore _store;
        private Coroutine _runner;
        private int _generation;

        public void Initialize()
        {
            _store = GameStore.Instance;
            try
            {
                Graph = StoryGraph.LoadEpisodeOne();
                var validation = Graph.Validate();
                if (!validation.IsValid)
                    throw new InvalidOperationException("Story link validation failed:\n" + validation);
                Debug.Log($"Dreadmoor story ready: {Graph.OrderedNodes.Count} linked nodes.");
            }
            catch (Exception exception)
            {
                Debug.LogException(exception);
                FatalError?.Invoke(exception.Message);
            }
        }

        public void Suspend()
        {
            _generation++;
            if (_runner != null) StopCoroutine(_runner);
            _runner = null;
            TypingThreadId = "";
            IsWaitingForInteraction = false;
        }

        public void StartNewStory()
        {
            Suspend();
            _store.Data.currentNodeId = GameStore.StartNodeId;
            _store.Data.activeChoiceNodeId = "";
            _store.Data.episodeComplete = false;
            _store.Save();
            ContinueAt(GameStore.StartNodeId);
        }

        public void Resume()
        {
            if (_runner != null || _store.Data.episodeComplete) return;
            var nodeId = _store.Data.currentNodeId;
            if (!string.IsNullOrWhiteSpace(nodeId)) ContinueAt(nodeId);
        }

        public void OpenThread(string threadId)
        {
            if (string.IsNullOrWhiteSpace(threadId)) return;
            _store.Data.activeThreadId = threadId;
            var thread = _store.GetThread(threadId);
            if (thread != null) thread.unreadCount = 0;
            _store.Save();

            if (_runner == null && !_store.Data.episodeComplete)
                Resume();
        }

        public void LeaveThread()
        {
            _store.Data.activeThreadId = "";
            _store.Save();
        }

        public void SubmitChoice(string choiceText, string targetNodeId)
        {
            var choiceId = _store.Data.activeChoiceNodeId;
            var choiceNode = Graph?.Get(choiceId);
            if (choiceNode == null || string.IsNullOrWhiteSpace(targetNodeId)) return;
            var validChoice = choiceNode.options != null && choiceNode.options.Any(option => option != null && option.Target == targetNodeId && option.text == choiceText);
            if (!validChoice)
            {
                Debug.LogError($"Rejected invalid choice target '{targetNodeId}' for '{choiceId}'.");
                return;
            }

            var threadId = ResolveThread(choiceNode);
            _store.EnsureThread(threadId);
            _store.AddMessage(new MessageData
            {
                nodeId = "choice_" + choiceNode.id,
                threadId = threadId,
                senderId = "player",
                content = _store.Sanitize(choiceText),
                gameMinutes = _store.Data.gameClockMinutes,
                isPlayerMessage = true,
                isSecret = _store.GetThread(threadId)?.isSecret == true
            });
            _store.MarkProcessed(choiceNode.id);
            _store.Data.activeChoiceNodeId = "";
            _store.Data.currentNodeId = targetNodeId;
            _store.Save();
            StateChanged?.Invoke();
            ContinueAt(targetNodeId);
        }

        public void AcceptIncomingCall()
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node == null || !IsIncomingType(node.type)) return;
            _store.Data.callHistory.Insert(0, new CallEntryData
            {
                name = CallerName(node), number = CallerNumber(node), gameMinutes = _store.Data.gameClockMinutes,
                direction = "incoming"
            });
            CompleteInteractionNode(node, node.next);
        }

        public void DeclineIncomingCall()
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node == null || !IsIncomingType(node.type)) return;
            var forced = node.disable_decline || string.Equals(node.type, "Force_Ringing", StringComparison.OrdinalIgnoreCase) ||
                         string.Equals(node.type, "S6_Ringing_Final", StringComparison.OrdinalIgnoreCase);
            if (forced || node.next_on_decline == null) return;

            _store.Data.callHistory.Insert(0, new CallEntryData
            {
                name = CallerName(node), number = CallerNumber(node), gameMinutes = _store.Data.gameClockMinutes,
                direction = "missed"
            });
            _store.MarkProcessed(node.id);
            _store.Data.currentNodeId = node.next_on_decline.target;
            _store.Save();
            StateChanged?.Invoke();
            StartOwnedCoroutine(ContinueAfter(Mathf.Max(0, node.next_on_decline.delay_seconds), node.next_on_decline.target));
        }

        public void EndActiveCall(int durationSeconds)
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node == null || !IsAcceptType(node.type)) return;
            if (_store.Data.callHistory.Count > 0)
                _store.Data.callHistory[0].durationSeconds = Mathf.Max(0, durationSeconds);
            CompleteInteractionNode(node, node.next);
        }

        public bool CompleteDiary(string pageId, string enteredWord)
        {
            var node = Graph?.Get(_store.Data.currentNodeId);
            if (node == null || node.action != "Open_Diary_Lock") return false;
            var word = node.meta?.word ?? "";
            var expectedPage = node.meta?.pageId ?? "";
            if (!string.Equals(expectedPage, pageId, StringComparison.OrdinalIgnoreCase)) return false;
            var normalized = (enteredWord ?? "").Trim().ToUpperInvariant();
            if (normalized != word.Trim().ToUpperInvariant()) return false;

            var diary = _store.GetDiary(pageId, word);
            diary.enteredWord = normalized;
            diary.isUnlocked = true;
            diary.isCompleted = true;
            _store.SetFlag("diaryUnlocked");
            CompleteInteractionNode(node, node.next);
            return true;
        }

        public StoryNode ActiveChoice()
        {
            return Graph?.Get(_store.Data.activeChoiceNodeId);
        }

        public bool DebugJumpTo(string nodeId, bool clearNarrative = false)
        {
            if (!Debug.isDebugBuild && !Application.isEditor) return false;
            if (Graph?.Get(nodeId) == null) return false;
            Suspend();
            if (clearNarrative) _store.ClearNarrativeProgress(true);
            _store.Data.processedNodeIds.Remove(nodeId);
            _store.Data.currentNodeId = nodeId;
            _store.Data.activeChoiceNodeId = "";
            _store.Data.episodeComplete = false;
            _store.Save();
            ContinueAt(nodeId);
            return true;
        }

        public void DebugUnlockAllFlags()
        {
            if (!Debug.isDebugBuild && !Application.isEditor) return;
            var flags = new[]
            {
                "found_factory_phone", "confronted_amelia", "visited_factory", "saw_highway_crash",
                "found_diary_01", "trusted_detective", "contacted_informant", "found_recording",
                "confronted_mayor", "found_factory_clip", "intercepted_chat", "article_read", "diaryUnlocked"
            };
            foreach (var flag in flags) _store.SetFlag(flag);
            _store.Save();
        }

        public bool CanDecline(StoryNode node)
        {
            if (node == null) return false;
            return !node.disable_decline && node.next_on_decline != null &&
                   !string.Equals(node.type, "Force_Ringing", StringComparison.OrdinalIgnoreCase) &&
                   !string.Equals(node.type, "S6_Ringing_Final", StringComparison.OrdinalIgnoreCase);
        }

        private void ContinueAt(string nodeId)
        {
            if (string.IsNullOrWhiteSpace(nodeId) || Graph == null) return;
            StartOwnedCoroutine(Run(nodeId, ++_generation));
        }

        private void StartOwnedCoroutine(IEnumerator routine)
        {
            if (_runner != null) StopCoroutine(_runner);
            _runner = StartCoroutine(routine);
        }

        private IEnumerator Run(string startNodeId, int generation)
        {
            // Ensure StartCoroutine has returned and _runner has been assigned
            // before any branch can complete synchronously.
            yield return null;
            IsWaitingForInteraction = false;
            var nodeId = startNodeId;
            var immediateSteps = 0;

            while (!string.IsNullOrWhiteSpace(nodeId) && generation == _generation)
            {
                var node = Graph.Get(nodeId);
                if (node == null)
                {
                    StopWithError($"Story node '{nodeId}' was not found.");
                    yield break;
                }

                if (_store.IsProcessed(node.id))
                {
                    // A completed node left in the cursor after process termination.
                    // The cursor normally already points at its continuation.
                    if (string.IsNullOrWhiteSpace(node.next))
                    {
                        _runner = null;
                        yield break;
                    }
                    nodeId = node.next;
                    SetCursor(nodeId, false);
                    continue;
                }

                SetCursor(node.id, false);
                if (!_store.Data.settings.reducedMotion) yield return new WaitForSecondsRealtime(0.12f);

                if (node.IsTyping)
                {
                    var typingThread = ResolveThread(node);
                    _store.EnsureThread(typingThread, node.thread_title, node.thread_members, node.thread_secret);
                    TypingThreadId = typingThread;
                    StateChanged?.Invoke();
                    yield return WaitMilliseconds(node.duration > 0 ? node.duration : 1200);
                    TypingThreadId = "";
                    StateChanged?.Invoke();
                }

                Debug.Log($"Dreadmoor -> {node.id} [{node.type}] action={node.action}");

                if (IsChatType(node.type))
                {
                    var threadId = ResolveThread(node);
                    var thread = _store.EnsureThread(threadId, node.thread_title, node.thread_members, node.thread_secret);
                    var isVideo = node.type == "Video_Message" || node.type == "Video_Node" || node.type == "S4_VIDEO_NODE";
                    var isImage = node.type == "Image_Message";
                    if (!_store.HasMessageForNode(node.id))
                    {
                        if (node.time_passed > 0) _store.Data.gameClockMinutes += node.time_passed;
                        _store.Data.messages.Add(new MessageData
                        {
                            id = Guid.NewGuid().ToString("N"), nodeId = node.id, threadId = threadId,
                            senderId = node.SenderId, content = _store.Sanitize(!string.IsNullOrWhiteSpace(node.text) ? node.text : node.file_asset),
                            mediaType = isVideo ? "video" : isImage ? "image" : "text", mediaPath = node.file_asset,
                            gameMinutes = _store.Data.gameClockMinutes, isSecret = thread.isSecret
                        });
                        if ((isVideo || isImage) && !string.IsNullOrWhiteSpace(node.file_asset))
                            _store.AddMedia(threadId, node.SenderId, isVideo ? "video" : "image", node.file_asset);
                    }
                    if (_store.Data.activeThreadId != threadId)
                    {
                        thread.unreadCount++;
                        RaiseNotification(new NotificationData
                        {
                            id = "msg_" + node.id, type = "chat", title = thread.title,
                            message = _store.Sanitize(node.text), gameMinutes = _store.Data.gameClockMinutes, threadId = threadId
                        });
                    }
                    SoundRequested?.Invoke("assets/media/sfx/message_receive.mp3");
                    MarkAndSetNext(node, node.next);
                    StateChanged?.Invoke();

                    if (_store.Data.activeThreadId != threadId)
                    {
                        IsWaitingForInteraction = true;
                        _runner = null;
                        yield break;
                    }
                    nodeId = node.next;
                }
                else if (node.type == "Pause")
                {
                    if (node.time_passed > 0) _store.Data.gameClockMinutes += node.time_passed;
                    yield return WaitMilliseconds(node.duration > 0 ? node.duration : 2000);
                    MarkAndSetNext(node, node.next);
                    nodeId = node.next;
                }
                else if (node.type == "Player_Choice")
                {
                    var threadId = ResolveThread(node);
                    _store.EnsureThread(threadId, node.thread_title, node.thread_members, node.thread_secret);
                    _store.Data.activeThreadId = threadId;
                    _store.Data.activeChoiceNodeId = node.id;
                    _store.Save();
                    IsWaitingForInteraction = true;
                    ChoiceRequested?.Invoke(node);
                    ThreadFocusRequested?.Invoke(threadId);
                    StateChanged?.Invoke();
                    _runner = null;
                    yield break;
                }
                else if (node.type == "News_Module")
                {
                    var article = new ArticleData
                    {
                        nodeId = node.id, headline = node.headline, subheadline = node.subheadline,
                        photo = node.image_asset, caption = node.caption, body = node.body ?? Array.Empty<string>()
                    };
                    _store.Data.article = article;
                    _store.SetFlag(string.IsNullOrWhiteSpace(node.flag_name) ? "article_read" : node.flag_name);
                    RaiseNotification(new NotificationData
                    {
                        id = "news_" + node.id, type = "article", title = "NEWS ALERT",
                        message = node.headline, gameMinutes = _store.Data.gameClockMinutes
                    });
                    MarkAndSetNext(node, node.next);
                    ArticleRequested?.Invoke(article);
                    nodeId = node.next;
                }
                else if (IsIncomingType(node.type))
                {
                    IsWaitingForInteraction = true;
                    IncomingCallRequested?.Invoke(node);
                    _runner = null;
                    yield break;
                }
                else if (IsAcceptType(node.type))
                {
                    IsWaitingForInteraction = true;
                    ActiveCallRequested?.Invoke(node);
                    _runner = null;
                    yield break;
                }
                else if (node.type == "Secret_Hacked")
                {
                    var threadId = ResolveThread(node);
                    _store.EnsureThread(threadId, node.thread_title, node.thread_members, true);
                    _store.Data.activeThreadId = threadId;
                    MarkAndSetNext(node, node.next);
                    ThreadFocusRequested?.Invoke(threadId);
                    nodeId = node.next;
                }
                else if (node.type == "Glitch_Effect" || node.type == "S5_CONNECTION_GLITCH")
                {
                    var seconds = Mathf.Max(0.2f, (node.duration > 0 ? node.duration : 1000) / 1000f);
                    GlitchRequested?.Invoke(node.text, seconds);
                    yield return new WaitForSecondsRealtime(seconds);
                    MarkAndSetNext(node, node.next);
                    nodeId = node.next;
                }
                else if (node.type == "System_Event" || node.type == "System_Notification")
                {
                    if (node.action == "Push_Notification")
                    {
                        RaiseNotification(new NotificationData
                        {
                            id = node.id, type = "system",
                            title = string.IsNullOrWhiteSpace(node.sender) ? "SYSTEM" : node.sender,
                            message = _store.Sanitize(node.text), gameMinutes = _store.Data.gameClockMinutes,
                            threadId = !string.IsNullOrWhiteSpace(node.chat) ? node.chat :
                                (node.SenderId != "system" ? node.SenderId : "")
                        });
                    }
                    else if (node.action == "Switch_Context")
                    {
                        var threadId = !string.IsNullOrWhiteSpace(node.target) ? node.target : node.thread_id;
                        if (!string.IsNullOrWhiteSpace(threadId))
                        {
                            _store.Data.activeThreadId = threadId;
                            ThreadFocusRequested?.Invoke(threadId);
                        }
                    }
                    else if (node.action == "Add_To_Group")
                    {
                        var threadId = !string.IsNullOrWhiteSpace(node.thread_id) ? node.thread_id : ResolveThread(node);
                        _store.EnsureThread(threadId, node.thread_title, node.thread_members, node.thread_secret);
                    }
                    else if (node.action == "Open_Diary_Lock")
                    {
                        var word = node.meta?.word ?? "";
                        var pageId = node.meta?.pageId ?? "";
                        _store.GetDiary(pageId, word);
                        _store.Save();
                        IsWaitingForInteraction = true;
                        DiaryRequested?.Invoke(word, pageId);
                        _runner = null;
                        yield break;
                    }
                    else if (node.action == "Trigger_Credits")
                    {
                        _store.MarkProcessed(node.id);
                        if (!string.IsNullOrWhiteSpace(node.flag_name)) _store.SetFlag(node.flag_name);
                        _store.Data.episodeComplete = true;
                        _store.Data.currentNodeId = "";
                        _store.Save();
                        CreditsRequested?.Invoke(node.text);
                        StateChanged?.Invoke();
                        _runner = null;
                        yield break;
                    }
                    else if (string.IsNullOrWhiteSpace(node.action) && !string.IsNullOrWhiteSpace(node.text))
                    {
                        var threadId = ResolveThread(node);
                        _store.EnsureThread(threadId);
                        _store.Data.messages.Add(new MessageData
                        {
                            id = Guid.NewGuid().ToString("N"), nodeId = node.id, threadId = threadId,
                            senderId = "system", content = _store.Sanitize(node.text), mediaType = "system_label",
                            gameMinutes = _store.Data.gameClockMinutes
                        });
                    }
                    MarkAndSetNext(node, node.next);
                    StateChanged?.Invoke();
                    nodeId = node.next;
                }
                else
                {
                    StopWithError($"Unhandled story node type '{node.type}' on '{node.id}'.");
                    yield break;
                }

                immediateSteps++;
                if (immediateSteps >= 100)
                {
                    immediateSteps = 0;
                    yield return null;
                }
            }

            _runner = null;
            IsWaitingForInteraction = false;
        }

        private IEnumerator ContinueAfter(float seconds, string target)
        {
            yield return null;
            if (seconds > 0) yield return new WaitForSecondsRealtime(seconds);
            _runner = null;
            ContinueAt(target);
        }

        private object WaitMilliseconds(int milliseconds)
        {
            var speed = Mathf.Clamp(_store.Data.settings.textSpeed, 0.5f, 2f);
            return new WaitForSecondsRealtime(Mathf.Max(0.01f, milliseconds / 1000f / speed));
        }

        private void CompleteInteractionNode(StoryNode node, string next)
        {
            MarkAndSetNext(node, next);
            IsWaitingForInteraction = false;
            StateChanged?.Invoke();
            ContinueAt(next);
        }

        private void MarkAndSetNext(StoryNode node, string next)
        {
            _store.MarkProcessed(node.id);
            _store.Data.currentNodeId = next ?? "";
            _store.Save();
        }

        private void SetCursor(string nodeId, bool notify)
        {
            _store.Data.currentNodeId = nodeId ?? "";
            _store.Save(notify);
        }

        private string ResolveThread(StoryNode node)
        {
            if (!string.IsNullOrWhiteSpace(node.chat)) return node.chat;
            if (!string.IsNullOrWhiteSpace(node.thread_id)) return node.thread_id;
            if (!string.IsNullOrWhiteSpace(_store.Data.activeThreadId)) return _store.Data.activeThreadId;
            return node.SenderId;
        }

        private void RaiseNotification(NotificationData notification)
        {
            _store.AddNotification(notification);
            NotificationRaised?.Invoke(notification);
        }

        private void StopWithError(string message)
        {
            Debug.LogError(message);
            _runner = null;
            IsWaitingForInteraction = false;
            FatalError?.Invoke(message);
        }

        private static bool IsChatType(string type)
        {
            return type == "Chat_Event" || type == "Video_Message" || type == "Image_Message" ||
                   type == "Private_Unknown" || type == "Video_Node" || type == "S4_VIDEO_NODE";
        }

        private static bool IsIncomingType(string type)
        {
            return type == "IncomingCall" || type == "Phone_Call_Event" || type == "Force_Ringing" || type == "S6_Ringing_Final";
        }

        private static bool IsAcceptType(string type)
        {
            return type == "Accept_Call" || type == "S6_Accept_Call";
        }

        public static string CallerName(StoryNode node) => string.IsNullOrWhiteSpace(node.caller_name) ? "Unknown" : node.caller_name;
        public static string CallerNumber(StoryNode node) => string.IsNullOrWhiteSpace(node.caller_id) ? "Unknown Number" : node.caller_id;
    }
}
